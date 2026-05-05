/// Prompt 构建器
///
/// 构建发送给 LLM 的系统提示和消息上下文

import '../models/chat_message.dart';

/// Prompt 构建器
class PromptBuilder {
  /// 系统提示词
  static const String systemPrompt = '''
你是一个游戏内存修改助手，名为 GG-AI。你的能力：

1. **数值修改**: 用户描述想要修改的游戏数据，你引导他们通过搜索定位内存地址
2. **内存分析**: 分析搜索结果，帮助用户识别哪个地址对应目标数据
3. **脚本生成**: 根据用户需求自动生成 Lua 修改脚本
4. **教学引导**: 解释内存修改的原理，帮助用户学习

工作流程:
- 用户说"我想改金币为99999"
- 你引导用户: 先搜索当前金币值 → 消费金币 → 再搜索新值 → 缩小范围 → 确认地址 → 写入新值
- 每一步返回结构化指令，由 App 执行

安全规则:
- 不提供绕过在线验证的方法
- 不修改服务器端数据
- 提醒用户修改可能违反游戏服务条款
- 仅限单机游戏或学习研究使用

回复格式:
- 使用简洁友好的中文
- 操作步骤用编号列出
- 执行结果用 ✅ 或 ❌ 标记
- 地址用代码格式显示
''';

  /// 构建消息列表
  List<Map<String, dynamic>> buildMessages({
    required String userMessage,
    List<ChatMessage> history = const [],
  }) {
    final messages = <Map<String, dynamic>>[];

    // 系统提示
    messages.add({'role': 'system', 'content': systemPrompt});

    // 历史消息 (最近 20 条)
    final recentHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    for (final msg in recentHistory) {
      if (msg.isSystem) continue;

      messages.add({'role': msg.role.value, 'content': msg.content});
    }

    // 当前用户消息
    messages.add({'role': 'user', 'content': userMessage});

    return messages;
  }

  /// 构建函数执行结果消息
  List<Map<String, dynamic>> buildFunctionResultMessages({
    required String funcName,
    required Map<String, dynamic> arguments,
    required dynamic result,
    required List<ChatMessage> history,
  }) {
    final messages = <Map<String, dynamic>>[];

    // 系统提示
    messages.add({'role': 'system', 'content': systemPrompt});

    // 历史消息
    final recentHistory = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    for (final msg in recentHistory) {
      if (msg.isSystem) continue;

      messages.add({'role': msg.role.value, 'content': msg.content});
    }

    // 函数调用消息
    messages.add({
      'role': 'assistant',
      'content': null,
      'function_call': {'name': funcName, 'arguments': arguments},
    });

    // 函数结果
    messages.add({'role': 'tool', 'content': result.toString()});

    return messages;
  }
}
