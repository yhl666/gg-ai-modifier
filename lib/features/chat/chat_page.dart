/// AI 对话记录页面
/// 显示历史对话记录，管理对话历史

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/models/chat_message.dart';
import '../../core/models/chat_session.dart';
import '../../core/llm/llm_config.dart';
import '../settings/settings_page.dart';
import '../process/process_selector.dart';

/// 聊天消息列表 Provider
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

/// 聊天会话列表 Provider
final chatSessionsProvider = StateProvider<List<ChatSession>>((ref) => []);

/// AI 对话记录页面
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  void _loadChatSessions() {
    // 这里可以从本地存储加载历史会话
    // 暂时创建一些示例数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessions = ref.read(chatSessionsProvider);
      if (sessions.isEmpty) {
        // 创建示例会话
        final exampleSessions = [
          ChatSession(
            id: '1',
            title: '💰 金币修改',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
            messages: [
              ChatMessage.user('我想修改游戏中的金币数量'),
              ChatMessage.assistant('好的，我来帮你修改金币。请告诉我当前的金币数量，我会搜索对应的内存地址。'),
            ],
            summary: '2 条用户消息，2 条 AI 回复',
          ),
          ChatSession(
            id: '2',
            title: '❤️ 血量修改',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            updatedAt: DateTime.now().subtract(const Duration(days: 1)),
            messages: [
              ChatMessage.user('怎么修改血量？'),
              ChatMessage.assistant('我可以帮你修改血量。首先需要附加游戏进程，然后搜索当前血量值。'),
            ],
            summary: '1 条用户消息，1 条 AI 回复',
          ),
        ];
        ref.read(chatSessionsProvider.notifier).state = exampleSessions;
      }
    });
  }

  void _clearAllSessions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('清空所有记录'),
        content: const Text('确定要清空所有对话记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatSessionsProvider.notifier).state = [];
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  void _exportAllSessions() {
    final sessions = ref.read(chatSessionsProvider);
    if (sessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有对话记录可导出')),
      );
      return;
    }

    // 生成导出文本
    final exportText = sessions.map((session) {
      final sessionText = '=== ${session.title} ===\n'
          '时间: ${session.createdAt.toString().substring(0, 19)}\n'
          '摘要: ${session.summary}\n\n';
      
      final messagesText = session.messages.map((msg) {
        final role = msg.isUser ? '用户' : 'AI助手';
        return '$role: ${msg.content}';
      }).join('\n');
      
      return sessionText + messagesText + '\n\n';
    }).join('');

    // 复制到剪贴板
    Clipboard.setData(ClipboardData(text: exportText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 所有对话记录已复制到剪贴板')),
    );
  }

  void _viewSession(ChatSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatSessionDetailPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(chatSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text('对话记录'),
          ],
        ),
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出所有记录',
            onPressed: _exportAllSessions,
          ),
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空所有记录',
            onPressed: _clearAllSessions,
          ),
          // 悬浮窗按钮
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            tooltip: '启动悬浮窗对话',
            onPressed: () {
              const channel = MethodChannel('com.yl.aigg/bridge');
              channel.invokeMethod('startOverlay');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('💡 悬浮窗已启动，点击悬浮球 → AI 对话'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 功能说明卡片
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      '使用说明',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• 实时对话：使用悬浮窗中的 AI 对话功能\n'
                  '• 历史记录：在此页面查看所有对话历史\n'
                  '• 游戏中使用：悬浮窗更适合游戏内快速对话',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          const channel = MethodChannel('com.yl.aigg/bridge');
                          channel.invokeMethod('startOverlay');
                        },
                        icon: const Icon(Icons.chat_bubble, size: 16),
                        label: const Text('启动悬浮窗对话'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 会话列表
          Expanded(
            child: sessions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无对话记录',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '使用悬浮窗开始与 AI 对话',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return _buildSessionCard(session);
                    },
                  ),
          ),

          // 统计信息
          if (sessions.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF2A2A2A),
              child: Row(
                children: [
                  const Icon(Icons.analytics, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '共 ${sessions.length} 个对话会话',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '最后更新: ${DateTime.now().toString().substring(0, 16)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF2A2A2A),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSessionIcon(session.title),
            color: const Color(0xFF6C63FF),
            size: 24,
          ),
        ),
        title: Text(
          session.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              session.previewText,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  session.formattedTime,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.messages.length} 条消息',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: () => _viewSession(session),
      ),
    );
  }

  IconData _getSessionIcon(String title) {
    if (title.contains('💰') || title.contains('金币')) {
      return Icons.monetization_on;
    } else if (title.contains('❤️') || title.contains('血量')) {
      return Icons.favorite;
    } else if (title.contains('⚡') || title.contains('能量')) {
      return Icons.flash_on;
    } else if (title.contains('📜') || title.contains('脚本')) {
      return Icons.code;
    } else if (title.contains('🔍') || title.contains('搜索')) {
      return Icons.search;
    } else if (title.contains('❓') || title.contains('帮助')) {
      return Icons.help;
    } else {
      return Icons.chat;
    }
  }
}

/// 对话会话详情页面
class ChatSessionDetailPage extends StatelessWidget {
  final ChatSession session;

  const ChatSessionDetailPage({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final exportText = '=== ${session.title} ===\n'
                  '时间: ${session.createdAt.toString().substring(0, 19)}\n\n'
                  '${session.messages.map((msg) {
                    final role = msg.isUser ? '用户' : 'AI助手';
                    return '$role: ${msg.content}';
                  }).join('\n\n')}';
              
              Clipboard.setData(ClipboardData(text: exportText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ 对话已复制到剪贴板')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 会话信息
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A2A2A),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.summary,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '创建时间: ${session.createdAt.toString().substring(0, 19)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: session.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(context, session.messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // 角色标签和时间
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) ...[
                    const Icon(
                      Icons.smart_toy,
                      size: 16,
                      color: Color(0xFF6C63FF),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'GG-AI',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF)),
                    ),
                  ],
                  if (isUser) ...[
                    const Text(
                      '我',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    message.timestamp.toString().substring(11, 16),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // 消息内容
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                      : const Color(0xFF3A3A3A),
                ),
              ),
              child: SelectableText(
                message.content,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}