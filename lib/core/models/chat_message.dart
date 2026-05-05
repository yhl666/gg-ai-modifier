/// 聊天消息数据模型

/// 消息角色
enum MessageRole {
  system('system'),
  user('user'),
  assistant('assistant');

  final String value;
  const MessageRole(this.value);
}

/// 消息类型
enum MessageType {
  text, // 普通文本
  functionCall, // AI 调用函数
  functionResult, // 函数执行结果
  error, // 错误消息
  system, // 系统消息
}

/// 聊天消息
class ChatMessage {
  /// 消息 ID
  final String id;

  /// 消息角色
  final MessageRole role;

  /// 消息内容
  final String content;

  /// 消息类型
  final MessageType type;

  /// 时间戳
  final DateTime timestamp;

  /// 函数调用信息 (如果是 functionCall 类型)
  final FunctionCall? functionCall;

  /// 函数执行结果 (如果是 functionResult 类型)
  final FunctionResult? functionResult;

  /// 是否正在加载 (流式响应)
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    DateTime? timestamp,
    this.functionCall,
    this.functionResult,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    FunctionCall? functionCall,
    FunctionResult? functionResult,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      functionCall: functionCall ?? this.functionCall,
      functionResult: functionResult ?? this.functionResult,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 是否为用户消息
  bool get isUser => role == MessageRole.user;

  /// 是否为 AI 消息
  bool get isAssistant => role == MessageRole.assistant;

  /// 是否为系统消息
  bool get isSystem => role == MessageRole.system;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.value,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'functionCall': functionCall?.toJson(),
      'functionResult': functionResult?.toJson(),
      'isLoading': isLoading,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.value == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      functionCall: json['functionCall'] != null
          ? FunctionCall.fromJson(json['functionCall'] as Map<String, dynamic>)
          : null,
      functionResult: json['functionResult'] != null
          ? FunctionResult.fromJson(
              json['functionResult'] as Map<String, dynamic>,
            )
          : null,
      isLoading: json['isLoading'] as bool? ?? false,
    );
  }

  /// 创建用户消息
  factory ChatMessage.user(String content, {String? id}) {
    return ChatMessage(
      id: id ?? _generateId(),
      role: MessageRole.user,
      content: content,
    );
  }

  /// 创建 AI 消息
  factory ChatMessage.assistant(String content, {String? id}) {
    return ChatMessage(
      id: id ?? _generateId(),
      role: MessageRole.assistant,
      content: content,
    );
  }

  /// 创建系统消息
  factory ChatMessage.system(String content, {String? id}) {
    return ChatMessage(
      id: id ?? _generateId(),
      role: MessageRole.system,
      content: content,
      type: MessageType.system,
    );
  }

  /// 创建加载中消息
  factory ChatMessage.loading({String? id}) {
    return ChatMessage(
      id: id ?? _generateId(),
      role: MessageRole.assistant,
      content: '',
      isLoading: true,
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  String toString() {
    return 'ChatMessage(role: ${role.value}, content: ${content.length > 50 ? "${content.substring(0, 50)}..." : content})';
  }
}

/// 函数调用信息
class FunctionCall {
  /// 函数名称
  final String name;

  /// 函数参数
  final Map<String, dynamic> arguments;

  const FunctionCall({required this.name, required this.arguments});

  Map<String, dynamic> toJson() {
    return {'name': name, 'arguments': arguments};
  }

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      name: json['name'] as String,
      arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'FunctionCall(name: $name, args: $arguments)';
  }
}

/// 函数执行结果
class FunctionResult {
  /// 函数名称
  final String name;

  /// 执行结果
  final dynamic result;

  /// 是否成功
  final bool success;

  /// 错误信息
  final String? error;

  const FunctionResult({
    required this.name,
    this.result,
    this.success = true,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'result': result, 'success': success, 'error': error};
  }

  factory FunctionResult.fromJson(Map<String, dynamic> json) {
    return FunctionResult(
      name: json['name'] as String,
      result: json['result'],
      success: json['success'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }
}
