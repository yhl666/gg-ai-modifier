/// 悬浮窗专用的 Flutter 应用
/// 用于在悬浮窗中显示完整的功能页面

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/chat/chat_page.dart';
import 'features/script/script_page.dart';
import 'features/settings/settings_page.dart';

/// 当前显示的页面 Provider
final overlayPageProvider = StateProvider<String>((ref) => 'chat');

/// 悬浮窗应用
class OverlayApp extends ConsumerStatefulWidget {
  const OverlayApp({super.key});

  @override
  ConsumerState<OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends ConsumerState<OverlayApp> {
  static const platform = MethodChannel('com.yl.aigg/overlay');

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'navigateTo') {
      final page = call.arguments as String;
      if (mounted) {
        ref.read(overlayPageProvider.notifier).state = page;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(overlayPageProvider);

    return MaterialApp(
      title: 'GG-AI Overlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: kSurfaceColor,
          error: kErrorColor,
        ),
        scaffoldBackgroundColor: kBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: kSurfaceColor,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: _buildPage(currentPage),
    );
  }

  Widget _buildPage(String page) {
    switch (page) {
      case 'chat':
        return const ChatPage();
      case 'script':
        return const ScriptPage();
      case 'settings':
        return const SettingsPage();
      default:
        return const ChatPage();
    }
  }
}
