/// 对话会话模型
/// 用于管理和显示对话记录

import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final String summary;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    this.summary = '',
  });

  /// 从消息列表创建会话
  factory ChatSession.fromMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '空对话',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [],
      );
    }

    // 生成标题（基于第一条用户消息）
    String title = '新对话';
    final firstUserMessage = messages.firstWhere(
      (msg) => msg.isUser,
      orElse: () => messages.first,
    );
    
    if (firstUserMessage.content.isNotEmpty) {
      title = _generateTitle(firstUserMessage.content);
    }

    return ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: messages.first.timestamp ?? DateTime.now(),
      updatedAt: messages.last.timestamp ?? DateTime.now(),
      messages: messages,
      summary: _generateSummary(messages),
    );
  }

  /// 生成对话标题
  static String _generateTitle(String firstMessage) {
    // 移除多余的空白字符
    String cleaned = firstMessage.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // 根据内容生成合适的标题
    if (cleaned.contains('金币') || cleaned.contains('钱')) {
      return '💰 金币修改';
    } else if (cleaned.contains('血量') || cleaned.contains('生命') || cleaned.contains('HP')) {
      return '❤️ 血量修改';
    } else if (cleaned.contains('能量') || cleaned.contains('MP') || cleaned.contains('魔法')) {
      return '⚡ 能量修改';
    } else if (cleaned.contains('脚本') || cleaned.contains('代码')) {
      return '📜 脚本生成';
    } else if (cleaned.contains('搜索') || cleaned.contains('查找')) {
      return '🔍 内存搜索';
    } else if (cleaned.contains('帮助') || cleaned.contains('help')) {
      return '❓ 使用帮助';
    } else {
      // 截取前20个字符作为标题
      if (cleaned.length > 20) {
        return cleaned.substring(0, 20) + '...';
      }
      return cleaned;
    }
  }

  /// 生成对话摘要
  static String _generateSummary(List<ChatMessage> messages) {
    if (messages.isEmpty) return '';
    
    final userMessages = messages.where((msg) => msg.isUser).length;
    final aiMessages = messages.where((msg) => !msg.isUser).length;
    
    return '$userMessages 条用户消息，$aiMessages 条 AI 回复';
  }

  /// 格式化时间显示
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    
    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${updatedAt.month}/${updatedAt.day}';
    }
  }

  /// 获取预览文本
  String get previewText {
    if (messages.isEmpty) return '暂无消息';
    
    final lastMessage = messages.last;
    String preview = lastMessage.content.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (preview.length > 50) {
      preview = preview.substring(0, 50) + '...';
    }
    
    return preview;
  }

  /// 复制会话
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? summary,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      summary: summary ?? this.summary,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'summary': summary,
    };
  }

  /// 从 JSON 创建
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List)
          .map((msgJson) => ChatMessage.fromJson(msgJson))
          .toList(),
      summary: json['summary'] as String? ?? '',
    );
  }
}