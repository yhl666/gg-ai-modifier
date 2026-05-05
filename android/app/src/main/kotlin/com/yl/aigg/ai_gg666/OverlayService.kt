package com.yl.aigg.ai_gg666

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.ArrayAdapter
import android.widget.TextView

class OverlayService : Service() {

    companion object {
        private const val CHANNEL_ID = "overlay_channel"
        private const val NOTIFICATION_ID = 1
        var isRunning = false
    }

    private var wm: WindowManager? = null
    private var ballView: View? = null
    private var ballParams: WindowManager.LayoutParams? = null
    private var panel: View? = null
    private var panelParams: WindowManager.LayoutParams? = null
    private val handler = Handler(Looper.getMainLooper())

    // 搜索状态
    private var searchResults: List<Map<String, Any>> = emptyList()
    private var searchDataType = "dword"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        createBall()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int) = START_STICKY

    override fun onDestroy() {
        isRunning = false
        removeBall()
        super.onDestroy()
    }

    // ==================== 通知 ====================

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "GG-AI 悬浮窗", NotificationManager.IMPORTANCE_LOW)
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        }
    }

    private fun buildNotification(): Notification {
        val pi = PendingIntent.getActivity(this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID).setContentTitle("GG-AI").setContentText("悬浮窗运行中")
                .setSmallIcon(android.R.drawable.ic_dialog_info).setContentIntent(pi).build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setContentTitle("GG-AI").setContentText("悬浮窗运行中")
                .setSmallIcon(android.R.drawable.ic_dialog_info).setContentIntent(pi).build()
        }
    }

    // ==================== 悬浮球 ====================

    private fun createBall() {
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        ballView = TextView(this).apply {
            text = "🎮"; textSize = 22f; gravity = Gravity.CENTER
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.parseColor("#6C63FF")) }
        }
        
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        ballParams = WindowManager.LayoutParams(
            dp(50), 
            dp(50), 
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply { 
            gravity = Gravity.TOP or Gravity.START
            x = 0
            y = dp(200)
        }

        var ix = 0; var iy = 0; var tx = 0f; var ty = 0f; var dragging = false
        ballView?.setOnTouchListener { _, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> { ix = ballParams?.x ?: 0; iy = ballParams?.y ?: 0; tx = e.rawX; ty = e.rawY; dragging = false; true }
                MotionEvent.ACTION_MOVE -> {
                    if (kotlin.math.abs(e.rawX - tx) > 10 || kotlin.math.abs(e.rawY - ty) > 10) dragging = true
                    ballParams?.x = ix + (e.rawX - tx).toInt(); ballParams?.y = iy + (e.rawY - ty).toInt()
                    try { wm?.updateViewLayout(ballView, ballParams) } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> { if (!dragging) showMainMenu(); true }
                else -> false
            }
        }
        try { wm?.addView(ballView, ballParams) } catch (_: Exception) {}
    }

    private fun removeBall() {
        closePanel()
        try { ballView?.let { wm?.removeView(it) } } catch (_: Exception) {}
        ballView = null
    }

    // ==================== 面板管理 ====================

    private fun closePanel() {
        try { panel?.let { wm?.removeView(it) } } catch (_: Exception) {}
        panel = null; panelParams = null
    }

    private fun showPanel(view: View, w: Int = 280, h: Int = 400) {
        closePanel()
        val dm = resources.displayMetrics
        val screenW = dm.widthPixels
        val screenH = dm.heightPixels
        val panelW = dp(w).coerceAtMost(screenW - dp(20))
        val panelH = dp(h).coerceAtMost(screenH - dp(20))
        
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        panelParams = WindowManager.LayoutParams(
            panelW, 
            panelH, 
            type,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (screenW - panelW) / 2
            y = (screenH - panelH) / 2
        }
        panel = view
        try { wm?.addView(panel, panelParams) } catch (_: Exception) {}
    }
    
    // 创建可获得焦点的面板（用于输入法）
    private fun showFocusablePanel(view: View, w: Int = 280, h: Int = 400) {
        closePanel()
        val dm = resources.displayMetrics
        val screenW = dm.widthPixels
        val screenH = dm.heightPixels
        val panelW = dp(w).coerceAtMost(screenW - dp(20))
        val panelH = dp(h).coerceAtMost(screenH - dp(20))
        
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        panelParams = WindowManager.LayoutParams(
            panelW, 
            panelH, 
            type,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (screenW - panelW) / 2
            y = (screenH - panelH) / 2
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE
        }
        panel = view
        try { wm?.addView(panel, panelParams) } catch (_: Exception) {}
    }

    private fun overlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
    }

    // ==================== 可拖动面板包装 ====================

    private fun makeDraggablePanel(title: String, contentBuilder: (LinearLayout) -> Unit, w: Int = 280, h: Int = 400) {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable().apply {
                cornerRadius = dp(12).toFloat(); setColor(Color.parseColor("#1E1E1E")); setStroke(1, Color.parseColor("#6C63FF"))
            }
        }

        // 可拖动标题栏
        val titleBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(12), dp(10), dp(12), dp(10))
            setBackgroundColor(Color.parseColor("#2A2A2A"))
        }
        val titleText = TextView(this).apply {
            text = title; setTextColor(Color.WHITE); textSize = 15f
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        titleBar.addView(titleText)

        // 返回按钮（如果不是主菜单）
        if (title != "🎮 GG-AI Modifier") {
            titleBar.addView(Button(this).apply {
                text = "返回"; setTextColor(Color.WHITE); textSize = 11f
                background = GradientDrawable().apply { cornerRadius = dp(4).toFloat(); setColor(Color.parseColor("#555555")) }
                setPadding(dp(8), dp(2), dp(8), dp(2))
                setOnClickListener { showMainMenu() }
            })
        }

        root.addView(titleBar)

        // 分割线
        root.addView(View(this).apply {
            setBackgroundColor(Color.parseColor("#3A3A3A"))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(1))
        })

        // 内容区域
        val contentArea = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
        }
        contentBuilder(contentArea)
        root.addView(contentArea)

        // 标题栏拖动支持 - 修复横屏模式下的拖动问题
        var pix = 0; var piy = 0; var ptx = 0f; var pty = 0f; var isDragging = false
        val dm = resources.displayMetrics
        
        titleBar.setOnTouchListener { _, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    pix = panelParams?.x ?: 0
                    piy = panelParams?.y ?: 0
                    ptx = e.rawX
                    pty = e.rawY
                    isDragging = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    isDragging = true
                    val dx = (e.rawX - ptx).toInt()
                    val dy = (e.rawY - pty).toInt()
                    
                    // 计算新位置，确保不超出屏幕边界
                    val screenW = dm.widthPixels
                    val screenH = dm.heightPixels
                    val panelW = panelParams?.width ?: 0
                    val panelH = panelParams?.height ?: 0
                    
                    var newX = pix + dx
                    var newY = piy + dy
                    
                    // 限制在屏幕范围内
                    newX = newX.coerceIn(-panelW / 2, screenW - panelW / 2)
                    newY = newY.coerceIn(0, screenH - panelH)
                    
                    panelParams?.x = newX
                    panelParams?.y = newY
                    try { wm?.updateViewLayout(panel, panelParams) } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    isDragging
                }
                else -> false
            }
        }

        // 根据面板类型选择显示方式
        if (title == "🤖 AI 对话") {
            showFocusablePanel(root, w, h)
        } else {
            showPanel(root, w, h)
        }
    }

    // ==================== 主菜单 ====================

    private fun showMainMenu() {
        makeDraggablePanel("🎮 GG-AI Modifier", { content ->
            val sv = ScrollView(this).apply {
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
            }
            val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(12), dp(8), dp(12), dp(8)) }

            list.addView(menuBtn("📱 附加进程") { showProcessPanel() })
            list.addView(menuBtn("🔍 内存搜索") { showSearchPanel() })
            list.addView(menuBtn("🤖 AI 对话") { showAIChatPanel() })
            list.addView(menuBtn("📜 脚本库") { showScriptPanel() })
            list.addView(menuBtn("⚙️ 设置") { showSettingsPanel() })

            sv.addView(list); content.addView(sv)

            // 底部按钮
            val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(8), dp(12), dp(8)) }
            bar.addView(smallBtn("打开APP") { jumpToPage("home") }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            bar.addView(smallBtn("关闭悬浮窗") { stopSelf() }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            content.addView(bar)
        }, 250, 380)
    }

    // ==================== 进程面板 ====================

    private fun showProcessPanel() {
        makeDraggablePanel("📱 选择游戏进程", { content ->
            val status = TextView(this).apply { text = "正在扫描..."; setTextColor(Color.WHITE); textSize = 12f; setPadding(dp(12), dp(8), dp(12), dp(4)) }
            content.addView(status)

            val sv = ScrollView(this).apply { layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f) }
            val list = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(8), dp(4), dp(8), dp(4)) }
            sv.addView(list); content.addView(sv)

            // 刷新按钮
            val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(4), dp(12), dp(8)) }
            bar.addView(smallBtn("刷新") { loadProcs(list, status) }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            content.addView(bar)

            loadProcs(list, status)
        }, 300, 450)
    }

    private fun loadProcs(list: LinearLayout, status: TextView) {
        status.text = "正在扫描..."; list.removeAllViews()
        Thread {
            val procs = ProcessManager.getProcessList(this@OverlayService).filter {
                val p = it["packageName"] as String
                p.isNotEmpty() && p.contains(".") && !p.startsWith("com.android.") && !p.startsWith("android.") &&
                        p != "system" && p != "zygote" && p != "zygote64"
            }
            handler.post {
                status.text = "找到 ${procs.size} 个应用"
                for (proc in procs) {
                    val name = proc["processName"] as String; val pkg = proc["packageName"] as String; val pid = proc["pid"] as Int
                    val item = LinearLayout(this).apply {
                        orientation = LinearLayout.VERTICAL; setPadding(dp(12), dp(10), dp(12), dp(10))
                        background = GradientDrawable().apply { cornerRadius = dp(8).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
                        layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(4) }
                    }
                    item.addView(TextView(this).apply { text = name; setTextColor(Color.WHITE); textSize = 14f })
                    item.addView(TextView(this).apply { text = "$pkg | PID: $pid"; setTextColor(Color.parseColor("#888888")); textSize = 11f })
                    item.setOnClickListener {
                        Thread {
                            val ok = MemoryEngine.attachProcess(pid)
                            handler.post { 
                                status.text = if (ok) "✅ 已附加: $name" else "❌ 附加失败"
                                // 附加成功后，通知主应用更新状态
                                if (ok) {
                                    saveAttachedProcess(pid, pkg, name)
                                }
                            }
                        }.start()
                    }
                    list.addView(item)
                }
            }
        }.start()
    }
    
    // 保存附加的进程信息，供主应用读取
    private fun saveAttachedProcess(pid: Int, packageName: String, processName: String) {
        try {
            val prefs = getSharedPreferences("gg_overlay", Context.MODE_PRIVATE)
            prefs.edit().apply {
                putInt("attached_pid", pid)
                putString("attached_package", packageName)
                putString("attached_name", processName)
                putLong("attached_time", System.currentTimeMillis())
                apply()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==================== 搜索面板 ====================

    private fun showSearchPanel() {
        makeDraggablePanel("🔍 内存搜索", { content ->
            val pid = MemoryEngine.getAttachedPid()
            val status = TextView(this).apply {
                text = if (pid != null) "已附加 PID: $pid" else "⚠️ 请先附加进程"
                setTextColor(Color.WHITE); textSize = 12f; setPadding(dp(12), dp(8), dp(12), dp(4))
            }
            content.addView(status)

            // 数据类型选择
            val typeRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(4), dp(12), dp(4)) }
            typeRow.addView(TextView(this).apply { text = "类型:"; setTextColor(Color.WHITE); textSize = 12f; setPadding(0, dp(6), dp(8), 0) })
            val types = arrayOf("dword", "float", "double", "byte", "word", "qword")
            val typeSpinner = Spinner(this).apply {
                adapter = ArrayAdapter(this@OverlayService, android.R.layout.simple_spinner_dropdown_item, types)
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            typeRow.addView(typeSpinner)
            content.addView(typeRow)

            // 搜索输入
            val inputRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(4), dp(12), dp(4)) }
            val input = EditText(this).apply {
                hint = "输入数值"; setTextColor(Color.WHITE); setHintTextColor(Color.parseColor("#888888"))
                background = GradientDrawable().apply { cornerRadius = dp(8).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
                setPadding(dp(12), dp(8), dp(12), dp(8))
                inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL or android.text.InputType.TYPE_NUMBER_FLAG_SIGNED
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            inputRow.addView(input)
            
            // 结果列表（在搜索按钮之前创建，以便实时更新）
            val rsv = ScrollView(this).apply { layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f) }
            val rl = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(dp(8), dp(4), dp(8), dp(4)); tag = "rl" }
            rsv.addView(rl)
            
            inputRow.addView(smallBtn("搜索") {
                val v = input.text.toString()
                if (v.isEmpty()) { status.text = "❌ 请输入数值"; return@smallBtn }
                if (MemoryEngine.getAttachedPid() == null) { status.text = "❌ 请先附加进程"; return@smallBtn }
                val dtype = typeSpinner.selectedItem.toString()
                searchDataType = dtype
                status.text = "搜索中... 0 个结果"
                rl.removeAllViews()
                searchResults = emptyList()
                
                Thread {
                    val numValue: Any = when (dtype) {
                        "float", "double" -> v.toDoubleOrNull() ?: 0.0
                        else -> v.toLongOrNull() ?: 0
                    }
                    
                    // 实时搜索 - 边搜边显示
                    val results = mutableListOf<Map<String, Any>>()
                    val mapsResult = RootManager.executeRootCommand("cat /proc/${MemoryEngine.getAttachedPid()}/maps 2>/dev/null") ?: ""
                    val hexValue = when (dtype) {
                        "dword" -> {
                            val iv = (numValue as? Number)?.toInt() ?: 0
                            String.format("%02x%02x%02x%02x", iv and 0xFF, (iv shr 8) and 0xFF, (iv shr 16) and 0xFF, (iv shr 24) and 0xFF)
                        }
                        "float" -> {
                            val fv = (numValue as? Number)?.toFloat() ?: 0f
                            val bits = java.lang.Float.floatToIntBits(fv)
                            String.format("%02x%02x%02x%02x", bits and 0xFF, (bits shr 8) and 0xFF, (bits shr 16) and 0xFF, (bits shr 24) and 0xFF)
                        }
                        else -> ""
                    }
                    
                    if (hexValue.isNotEmpty()) {
                        var regionCount = 0
                        for (line in mapsResult.lines()) {
                            if (!line.contains("rw-p")) continue
                            val parts = line.split(" ")
                            if (parts.isEmpty()) continue
                            val addrRange = parts[0].split("-")
                            if (addrRange.size != 2) continue
                            val startAddr = addrRange[0].toLongOrNull(16) ?: continue
                            val endAddr = addrRange[1].toLongOrNull(16) ?: continue
                            val regionSize = endAddr - startAddr
                            if (regionSize > 50 * 1024 * 1024 || regionSize <= 0) continue
                            
                            regionCount++
                            handler.post { status.text = "搜索中... 区域 $regionCount | ${results.size} 个结果" }
                            
                            val searchResult = RootManager.executeRootCommand(
                                "xxd -s $startAddr -l $regionSize -p /proc/${MemoryEngine.getAttachedPid()}/mem 2>/dev/null | grep -bo '$hexValue' | head -50"
                            ) ?: continue
                            
                            for (resultLine in searchResult.lines()) {
                                if (resultLine.isBlank()) continue
                                val offset = resultLine.split(":").firstOrNull()?.toLongOrNull() ?: continue
                                val address = startAddr + offset
                                results.add(mapOf(
                                    "address" to "0x${address.toString(16).uppercase()}",
                                    "addressInt" to address.toInt(),
                                    "value" to numValue,
                                    "type" to dtype
                                ))
                                
                                // 每找到 10 个结果就更新一次界面
                                if (results.size % 10 == 0) {
                                    val currentResults = results.toList()
                                    handler.post {
                                        status.text = "搜索中... ${currentResults.size} 个结果"
                                        updateSearchResults(rl, currentResults)
                                    }
                                }
                                
                                if (results.size >= 500) break
                            }
                            if (results.size >= 500) break
                        }
                    }
                    
                    searchResults = results
                    handler.post {
                        status.text = "找到 ${results.size} 个结果"
                        updateSearchResults(rl, results)
                    }
                }.start()
            })
            content.addView(inputRow)

            // 缩小范围输入
            val refineRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(4), dp(12), dp(4)) }
            val refineInput = EditText(this).apply {
                hint = "新值(缩小范围)"; setTextColor(Color.WHITE); setHintTextColor(Color.parseColor("#888888"))
                background = GradientDrawable().apply { cornerRadius = dp(8).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
                setPadding(dp(12), dp(8), dp(12), dp(8))
                inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL or android.text.InputType.TYPE_NUMBER_FLAG_SIGNED
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            }
            refineRow.addView(refineInput)
            refineRow.addView(smallBtn("过滤") {
                val v = refineInput.text.toString()
                if (v.isEmpty() || searchResults.isEmpty()) { status.text = "❌ 请先搜索"; return@smallBtn }
                status.text = "过滤中..."
                Thread {
                    val numValue: Any = when (searchDataType) {
                        "float", "double" -> v.toDoubleOrNull() ?: 0.0
                        else -> v.toLongOrNull() ?: 0
                    }
                    val prevAddrs = searchResults.map { it["addressInt"] as Int }
                    val results = MemoryEngine.filterResults(prevAddrs, numValue, searchDataType)
                    searchResults = results
                    handler.post { status.text = "缩小到 ${results.size} 个结果"; updateSearchResults(rl, results) }
                }.start()
            })
            content.addView(refineRow)

            // 结果列表
            content.addView(rsv)

            // 重置按钮
            val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(4), dp(12), dp(8)) }
            bar.addView(smallBtn("重置") {
                searchResults = emptyList(); rl.removeAllViews(); status.text = "已重置"
            }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            content.addView(bar)
        }, 300, 500)
    }
    
    private fun updateSearchResults(rl: LinearLayout, results: List<Map<String, Any>>) {
        rl.removeAllViews()
        for (r in results.take(100)) {
            val addr = r["address"] as String
            val v = r["value"]
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL; setPadding(dp(10), dp(6), dp(10), dp(6))
                background = GradientDrawable().apply { cornerRadius = dp(6).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(3) }
            }
            row.addView(TextView(this).apply {
                text = "$addr = $v"; setTextColor(Color.WHITE); textSize = 11f
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            })
            row.addView(smallBtn("改") { showWriteDialog(addr, v) })
            row.addView(smallBtn("冻") {
                val ai = addr.removePrefix("0x").removePrefix("0X").toLongOrNull(16)?.toInt() ?: return@smallBtn
                Thread { if (v != null) MemoryFreezer.freeze(ai, v, searchDataType) }.start()
            })
            rl.addView(row)
        }
        if (results.isEmpty()) {
            rl.addView(TextView(this).apply { text = "未找到结果"; setTextColor(Color.parseColor("#888888")); textSize = 12f; setPadding(dp(12), dp(8), dp(12), dp(8)) })
        }
    }

    private fun showWriteDialog(addr: String, curVal: Any?) {
        makeDraggablePanel("✏️ 修改内存值", { content ->
            content.addView(TextView(this).apply { text = "地址: $addr"; setTextColor(Color.parseColor("#888888")); textSize = 12f; setPadding(dp(12), dp(8), dp(12), dp(4)) })
            content.addView(TextView(this).apply { text = "当前值: $curVal"; setTextColor(Color.parseColor("#888888")); textSize = 12f; setPadding(dp(12), dp(4), dp(12), dp(8)) })

            val inp = EditText(this).apply {
                hint = "输入新值"; setTextColor(Color.WHITE); setHintTextColor(Color.parseColor("#888888"))
                background = GradientDrawable().apply { cornerRadius = dp(8).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
                setPadding(dp(12), dp(8), dp(12), dp(8))
                inputType = android.text.InputType.TYPE_CLASS_NUMBER or android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL or android.text.InputType.TYPE_NUMBER_FLAG_SIGNED
                setText(curVal.toString())
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { marginStart = dp(12); marginEnd = dp(12) }
            }
            content.addView(inp)

            val bar = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; setPadding(dp(12), dp(12), dp(12), dp(8)) }
            bar.addView(smallBtn("取消") { showSearchPanel() }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            bar.addView(smallBtn("确认修改") {
                val nv = inp.text.toString()
                if (nv.isEmpty()) return@smallBtn
                val ai = addr.removePrefix("0x").removePrefix("0X").toLongOrNull(16)?.toInt() ?: return@smallBtn
                Thread {
                    val numVal: Any = when (searchDataType) {
                        "float", "double" -> nv.toDoubleOrNull() ?: 0.0
                        else -> nv.toLongOrNull() ?: 0
                    }
                    MemoryEngine.writeMemory(ai, numVal, searchDataType)
                    handler.post { showSearchPanel() }
                }.start()
            }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            content.addView(bar)
        }, 280, 280)
    }

    // ==================== 跳转到主应用 ====================

    private fun jumpToPage(page: String) {
        closePanel()
        try {
            // 保存到 SharedPreferences 作为备用
            val prefs = getSharedPreferences("gg_overlay", Context.MODE_PRIVATE)
            prefs.edit().putString("pending_page", page).apply()
            
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                putExtra("page", page)
            }
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==================== AI 对话面板 ====================

    private fun showAIChatPanel() {
        makeDraggablePanel("🤖 AI 对话", { content ->
            // AI 对话的完整功能直接在悬浮窗中实现
            
            // 获取附加进程信息
            val prefs = getSharedPreferences("gg_overlay", Context.MODE_PRIVATE)
            val attachedPid = prefs.getInt("attached_pid", -1)
            val attachedName = prefs.getString("attached_name", "")
            val attachedPackage = prefs.getString("attached_package", "")
            
            // 状态显示
            val status = TextView(this).apply {
                text = if (attachedPid != -1 && !attachedName.isNullOrEmpty()) {
                    "✅ 已附加: $attachedName"
                } else {
                    "⚠️ 未附加进程，请先附加游戏"
                }
                setTextColor(if (attachedPid != -1) Color.parseColor("#4CAF50") else Color.parseColor("#FF9800"))
                textSize = 11f
                setPadding(dp(12), dp(8), dp(12), dp(4))
            }
            content.addView(status)
            
            // 分割线
            content.addView(View(this).apply {
                setBackgroundColor(Color.parseColor("#3A3A3A"))
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(1))
            })

            // 消息显示区域（简化版）
            val messageArea = ScrollView(this).apply {
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
                background = GradientDrawable().apply {
                    cornerRadius = dp(8).toFloat()
                    setColor(Color.parseColor("#2A2A2A"))
                }
            }
            val messageList = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(8), dp(8), dp(8), dp(8))
            }
            
            // 添加欢迎消息
            val welcomeMsg = if (attachedPid != -1 && !attachedName.isNullOrEmpty()) {
                "🤖 AI 助手已就绪！\n\n当前已附加: $attachedName\n\n请告诉我你想修改什么游戏数据？"
            } else {
                "🤖 AI 助手\n\n⚠️ 请先附加游戏进程\n点击返回 → 附加进程"
            }
            messageList.addView(createMessageBubble("🤖 AI", welcomeMsg, false))
            
            messageArea.addView(messageList)
            content.addView(messageArea)

            // 输入区域
            val inputArea = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                setPadding(dp(12), dp(8), dp(12), dp(8))
            }
            
            val inputField = EditText(this).apply {
                hint = "输入你的需求..."
                setTextColor(Color.WHITE)
                setHintTextColor(Color.parseColor("#888888"))
                background = GradientDrawable().apply {
                    cornerRadius = dp(8).toFloat()
                    setColor(Color.parseColor("#3A3A3A"))
                }
                setPadding(dp(12), dp(8), dp(12), dp(8))
                layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                
                // 设置输入法相关属性
                isFocusable = true
                isFocusableInTouchMode = true
                
                // 点击时请求焦点并显示输入法
                setOnClickListener {
                    requestFocus()
                    post {
                        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
                        imm.showSoftInput(this, android.view.inputmethod.InputMethodManager.SHOW_FORCED)
                    }
                }
                
                setOnFocusChangeListener { _, hasFocus ->
                    if (hasFocus) {
                        post {
                            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
                            imm.showSoftInput(this, android.view.inputmethod.InputMethodManager.SHOW_FORCED)
                        }
                    }
                }
                
                // 自动获取焦点
                post {
                    requestFocus()
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
                    imm.showSoftInput(this, android.view.inputmethod.InputMethodManager.SHOW_FORCED)
                }
            }
            
            val sendBtn = Button(this).apply {
                text = "发送"
                setTextColor(Color.WHITE)
                textSize = 12f
                background = GradientDrawable().apply {
                    cornerRadius = dp(6).toFloat()
                    setColor(Color.parseColor("#6C63FF"))
                }
                setPadding(dp(12), dp(6), dp(12), dp(6))
                setOnClickListener {
                    val userInput = inputField.text.toString().trim()
                    if (userInput.isNotEmpty()) {
                        // 添加用户消息
                        messageList.addView(createMessageBubble("👤 我", userInput, true))
                        inputField.text.clear()
                        
                        // 隐藏输入法
                        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
                        imm.hideSoftInputFromWindow(inputField.windowToken, 0)
                        
                        // 模拟 AI 回复（这里可以集成真实的 AI API）
                        handler.postDelayed({
                            val aiResponse = generateAIResponse(userInput, attachedName ?: "")
                            messageList.addView(createMessageBubble("🤖 AI", aiResponse, false))
                            messageArea.post {
                                messageArea.fullScroll(ScrollView.FOCUS_DOWN)
                            }
                        }, 1000)
                        
                        messageArea.post {
                            messageArea.fullScroll(ScrollView.FOCUS_DOWN)
                        }
                    }
                }
            }
            
            inputArea.addView(inputField)
            inputArea.addView(sendBtn)
            content.addView(inputArea)
            
        }, 320, 500)
    }
    
    // 创建消息气泡
    private fun createMessageBubble(sender: String, message: String, isUser: Boolean): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(8), dp(6), dp(8), dp(6))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dp(8) }
            
            // 发送者标签
            addView(TextView(this@OverlayService).apply {
                text = sender
                setTextColor(if (isUser) Color.parseColor("#03DAC6") else Color.parseColor("#6C63FF"))
                textSize = 11f
                setPadding(0, 0, 0, dp(2))
            })
            
            // 消息内容
            addView(TextView(this@OverlayService).apply {
                text = message
                setTextColor(Color.WHITE)
                textSize = 12f
                background = GradientDrawable().apply {
                    cornerRadius = dp(8).toFloat()
                    setColor(if (isUser) Color.parseColor("#3A3A3A") else Color.parseColor("#2A2A2A"))
                }
                setPadding(dp(12), dp(8), dp(12), dp(8))
            })
        }
    }
    
    // 生成 AI 回复（简化版，实际应该调用真实 API）
    private fun generateAIResponse(userInput: String, attachedApp: String): String {
        return when {
            userInput.contains("金币") || userInput.contains("钱") -> {
                "我来帮你搜索${if (attachedApp.isNotEmpty()) attachedApp else "游戏"}中的金币地址：\n\n1. 请告诉我当前金币数量\n2. 我会搜索对应的内存地址\n3. 然后修改为你想要的数值\n\n请输入当前金币数量："
            }
            userInput.contains("血量") || userInput.contains("生命") || userInput.contains("HP") -> {
                "我来帮你修改${if (attachedApp.isNotEmpty()) attachedApp else "游戏"}中的血量：\n\n1. 请告诉我当前血量\n2. 我会搜索血量地址\n3. 然后冻结为最大值\n\n请输入当前血量："
            }
            userInput.contains("能量") || userInput.contains("MP") || userInput.contains("魔法") -> {
                "我来帮你修改${if (attachedApp.isNotEmpty()) attachedApp else "游戏"}中的能量值：\n\n1. 请告诉我当前能量值\n2. 我会搜索能量地址\n3. 然后修改为你想要的数值\n\n请输入当前能量值："
            }
            userInput.matches(Regex("\\d+")) -> {
                val value = userInput.toIntOrNull() ?: 0
                "收到数值：$value\n\n正在为${if (attachedApp.isNotEmpty()) attachedApp else "当前游戏"}搜索内存地址...\n\n🔍 搜索中，请稍候...\n\n💡 提示：你可以返回主菜单使用完整的内存搜索功能"
            }
            userInput.contains("帮助") || userInput.contains("help") -> {
                "🤖 GG-AI 助手使用指南：\n\n📱 当前状态：${if (attachedApp.isNotEmpty()) "已附加 $attachedApp" else "未附加进程"}\n\n🎯 我可以帮你：\n• 修改金币/钻石\n• 修改血量/生命值\n• 修改能量/魔法值\n• 生成修改脚本\n\n💬 直接告诉我你想修改什么即可！"
            }
            else -> {
                "我理解你想要：$userInput\n\n${if (attachedApp.isNotEmpty()) "✅ 当前已附加：$attachedApp" else "⚠️ 建议先附加游戏进程"}\n\n💡 常用操作：\n• 修改金币 → 直接说\"修改金币\"\n• 修改血量 → 直接说\"修改血量\"\n• 修改能量 → 直接说\"修改能量\"\n\n🔧 完整功能请使用主菜单中的内存搜索"
            }
        }
    }

    // ==================== 脚本库面板 ====================

    private fun showScriptPanel() {
        closePanel()
        try {
            val intent = OverlayFlutterActivity.withPage(this, "script")
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==================== 设置面板 ====================

    private fun showSettingsPanel() {
        closePanel()
        try {
            val intent = OverlayFlutterActivity.withPage(this, "settings")
            startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ==================== UI 工具 ====================

    private fun menuBtn(text: String, onClick: () -> Unit): TextView {
        return TextView(this).apply {
            this.text = text; setTextColor(Color.WHITE); textSize = 14f; setPadding(dp(12), dp(12), dp(12), dp(12))
            background = GradientDrawable().apply { cornerRadius = dp(8).toFloat(); setColor(Color.parseColor("#2A2A2A")) }
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(6) }
            setOnClickListener { onClick() }
        }
    }

    private fun smallBtn(text: String, onClick: () -> Unit): Button {
        return Button(this).apply {
            this.text = text; setTextColor(Color.WHITE); textSize = 11f
            background = GradientDrawable().apply { cornerRadius = dp(6).toFloat(); setColor(Color.parseColor("#6C63FF")) }
            setPadding(dp(10), dp(4), dp(10), dp(4))
            setOnClickListener { onClick() }
        }
    }

    private fun dp(v: Int): Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()
}
