import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'overlay_app.dart';
import 'services/storage_service.dart';
import 'core/models/process_info.dart';
import 'features/process/process_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查是否是悬浮窗模式
  final args = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final isOverlayMode = args.contains('overlay');

  // 初始化存储服务
  final storageService = StorageService();
  await storageService.initialize();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: isOverlayMode ? const OverlayApp() : const GgModifierApp(),
    ),
  );
}

/// 存储服务 Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden at startup');
});

/// 应用启动时检查附加的进程
Future<void> checkAttachedProcessOnStartup(WidgetRef ref) async {
  try {
    const channel = MethodChannel('com.yl.aigg/bridge');
    final pid = await channel.invokeMethod('getAttachedPid');
    
    if (pid != null && pid > 0) {
      // 有附加的进程，获取进程信息
      final result = await channel.invokeMethod('getProcessList');
      if (result != null) {
        final List<dynamic> list = result as List<dynamic>;
        final processes = list.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProcessInfo.fromJson(map);
        }).toList();
        
        // 找到对应的进程
        try {
          final attachedProcess = processes.firstWhere((p) => p.pid == pid);
          ref.read(attachedProcessProvider.notifier).state = attachedProcess;
        } catch (_) {
          // 进程不存在，可能已关闭
        }
      }
    }
  } catch (e) {
    // 忽略错误
  }
}
