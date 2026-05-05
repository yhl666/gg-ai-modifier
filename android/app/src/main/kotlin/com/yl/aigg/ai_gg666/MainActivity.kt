package com.yl.aigg.ai_gg666

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var channel: MethodChannel
    private val OVERLAY_PERMISSION_REQUEST = 1234
    private var pendingPage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.yl.aigg/bridge")
        
        // 检查启动时是否有页面参数
        val startPage = intent?.getStringExtra("page")
        if (startPage != null) {
            pendingPage = startPage
        }
        // 也检查 SharedPreferences
        if (pendingPage == null) {
            val prefs = getSharedPreferences("gg_overlay", Context.MODE_PRIVATE)
            pendingPage = prefs.getString("pending_page", null)
            prefs.edit().remove("pending_page").apply()
        }
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                // 获取悬浮窗传来的页面参数
                "getInitialPage" -> {
                    val page = pendingPage
                    pendingPage = null
                    result.success(page)
                }

                // 进程管理（后台线程执行，避免阻塞 UI）
                "getProcessList" -> {
                    Thread {
                        try {
                            val processes = ProcessManager.getProcessList(this@MainActivity as android.content.Context)
                            runOnUiThread { result.success(processes) }
                        } catch (e: Exception) {
                            runOnUiThread { result.error("PROCESS_LIST_ERROR", e.message, null) }
                        }
                    }.start()
                }
                "attachProcess" -> {
                    val pid = call.argument<Int>("pid")
                    if (pid == null) {
                        result.error("INVALID_PID", "PID is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(MemoryEngine.attachProcess(pid))
                    } catch (e: Exception) {
                        result.error("ATTACH_ERROR", e.message, null)
                    }
                }
                "detachProcess" -> {
                    try {
                        MemoryEngine.detachProcess()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DETACH_ERROR", e.message, null)
                    }
                }
                "getAttachedPid" -> {
                    // 优先从 SharedPreferences 读取（悬浮窗可能已附加）
                    val prefs = getSharedPreferences("gg_overlay", Context.MODE_PRIVATE)
                    val savedPid = prefs.getInt("attached_pid", -1)
                    val currentPid = MemoryEngine.getAttachedPid()
                    
                    // 如果有保存的 PID 且与当前不同，则重新附加
                    if (savedPid > 0 && currentPid != savedPid) {
                        try {
                            MemoryEngine.attachProcess(savedPid)
                        } catch (e: Exception) {
                            // 附加失败，清除保存的信息
                            prefs.edit().clear().apply()
                        }
                    }
                    
                    result.success(MemoryEngine.getAttachedPid())
                }

                // 内存搜索
                "searchExact" -> {
                    val value = call.argument<Any>("value")
                    if (value == null) {
                        result.error("INVALID_VALUE", "Value is required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryEngine.searchExact(value, type))
                    } catch (e: Exception) {
                        result.error("SEARCH_ERROR", e.message, null)
                    }
                }
                "filterResults" -> {
                    val prevAddresses = call.argument<List<Int>>("previousAddresses") ?: emptyList()
                    val value = call.argument<Any>("value")
                    if (value == null) {
                        result.error("INVALID_VALUE", "Value is required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryEngine.filterResults(prevAddresses, value, type))
                    } catch (e: Exception) {
                        result.error("FILTER_ERROR", e.message, null)
                    }
                }
                "searchByRange" -> {
                    val minValue = call.argument<Number>("minValue")
                    val maxValue = call.argument<Number>("maxValue")
                    if (minValue == null || maxValue == null) {
                        result.error("INVALID_RANGE", "Min and max values are required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryEngine.searchByRange(minValue.toLong(), maxValue.toLong(), type))
                    } catch (e: Exception) {
                        result.error("RANGE_SEARCH_ERROR", e.message, null)
                    }
                }

                // 内存读写
                "readMemory" -> {
                    val address = call.argument<Int>("address")
                    if (address == null) {
                        result.error("INVALID_ADDRESS", "Address is required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryEngine.readMemory(address, type))
                    } catch (e: Exception) {
                        result.error("READ_ERROR", e.message, null)
                    }
                }
                "writeMemory" -> {
                    val address = call.argument<Int>("address")
                    val value = call.argument<Any>("value")
                    if (address == null || value == null) {
                        result.error("INVALID_PARAMS", "Address and value are required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryEngine.writeMemory(address, value, type))
                    } catch (e: Exception) {
                        result.error("WRITE_ERROR", e.message, null)
                    }
                }
                "writeBatch" -> {
                    val requests = call.argument<List<Map<String, Any>>>("requests") ?: emptyList()
                    try {
                        result.success(MemoryEngine.writeBatch(requests))
                    } catch (e: Exception) {
                        result.error("BATCH_WRITE_ERROR", e.message, null)
                    }
                }

                // 内存冻结
                "freezeMemory" -> {
                    val address = call.argument<Int>("address")
                    val value = call.argument<Any>("value")
                    if (address == null || value == null) {
                        result.error("INVALID_PARAMS", "Address and value are required", null)
                        return@setMethodCallHandler
                    }
                    val type = call.argument<String>("type") ?: "dword"
                    try {
                        result.success(MemoryFreezer.freeze(address, value, type))
                    } catch (e: Exception) {
                        result.error("FREEZE_ERROR", e.message, null)
                    }
                }
                "unfreezeMemory" -> {
                    val address = call.argument<Int>("address")
                    if (address == null) {
                        result.error("INVALID_ADDRESS", "Address is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        result.success(MemoryFreezer.unfreeze(address))
                    } catch (e: Exception) {
                        result.error("UNFREEZE_ERROR", e.message, null)
                    }
                }
                "getFrozenAddresses" -> {
                    try {
                        result.success(MemoryFreezer.getFrozenAddresses())
                    } catch (e: Exception) {
                        result.error("GET_FROZEN_ERROR", e.message, null)
                    }
                }

                // 内存区域
                "getMemoryRegions" -> {
                    try {
                        result.success(MemoryEngine.getMemoryRegions())
                    } catch (e: Exception) {
                        result.error("REGIONS_ERROR", e.message, null)
                    }
                }
                "analyzeMemoryRegion" -> {
                    val address = call.argument<Int>("address")
                    if (address == null) {
                        result.error("INVALID_ADDRESS", "Address is required", null)
                        return@setMethodCallHandler
                    }
                    val range = call.argument<Int>("range") ?: 256
                    try {
                        result.success(MemoryEngine.analyzeMemoryRegion(address, range))
                    } catch (e: Exception) {
                        result.error("ANALYZE_ERROR", e.message, null)
                    }
                }

                // Root 权限
                "checkRootAccess" -> {
                    try {
                        result.success(RootManager.checkRootAccess())
                    } catch (e: Exception) {
                        result.error("ROOT_CHECK_ERROR", e.message, null)
                    }
                }
                "requestRootAccess" -> {
                    try {
                        result.success(RootManager.requestRootAccess())
                    } catch (e: Exception) {
                        result.error("ROOT_REQUEST_ERROR", e.message, null)
                    }
                }

                // 悬浮窗
                "startOverlay" -> {
                    try {
                        if (canDrawOverlays()) {
                            startOverlayService()
                            result.success(true)
                        } else {
                            requestOverlayPermission()
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }
                "stopOverlay" -> {
                    try {
                        stopOverlayService()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }
                "canDrawOverlays" -> {
                    result.success(canDrawOverlays())
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        channel.setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val page = intent.getStringExtra("page")
        if (page != null) {
            pendingPage = page
            // 延迟通知 Flutter 端，确保 channel 就绪
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                try {
                    if (::channel.isInitialized) {
                        channel.invokeMethod("onNavigate", page)
                    }
                } catch (_: Exception) {}
            }, 300)
        }
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST)
        }
    }

    private fun startOverlayService() {
        val intent = Intent(this, OverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopOverlayService() {
        val intent = Intent(this, OverlayService::class.java)
        stopService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST) {
            if (canDrawOverlays()) {
                startOverlayService()
            }
        }
    }
}
