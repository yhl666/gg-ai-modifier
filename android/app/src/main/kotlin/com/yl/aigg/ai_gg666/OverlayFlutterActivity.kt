package com.yl.aigg.ai_gg666

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * 悬浮窗专用的 Flutter Activity
 * 用于在悬浮窗中显示完整的 Flutter 页面
 */
class OverlayFlutterActivity : FlutterActivity() {
    
    companion object {
        private const val ENGINE_ID = "overlay_flutter_engine"
        const val EXTRA_PAGE = "page"
        
        fun withPage(context: Context, page: String): Intent {
            return Intent(context, OverlayFlutterActivity::class.java).apply {
                putExtra(EXTRA_PAGE, page)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
    }
    
    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        // 尝试从缓存获取引擎
        var engine = FlutterEngineCache.getInstance().get(ENGINE_ID)
        
        if (engine == null) {
            // 创建新引擎
            engine = FlutterEngine(context)
            
            // 启动 Dart 代码
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            // 缓存引擎
            FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        }
        
        return engine
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 获取要显示的页面
        val page = intent.getStringExtra(EXTRA_PAGE) ?: "chat"
        
        // 通过 MethodChannel 通知 Flutter 显示指定页面
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            val channel = io.flutter.plugin.common.MethodChannel(messenger, "com.yl.aigg/overlay")
            channel.invokeMethod("navigateTo", page)
        }
    }
    
    override fun onDestroy() {
        // 不销毁引擎，保持在缓存中
        super.onDestroy()
    }
}
