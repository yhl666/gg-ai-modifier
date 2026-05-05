/// LLM 配置管理

/// LLM API 配置
class LlmConfig {
  /// API 基础地址
  final String baseUrl;

  /// API 密钥
  final String apiKey;

  /// 模型名称
  final String model;

  /// 温度参数 (0.0 - 2.0)
  final double temperature;

  /// 最大 token 数
  final int maxTokens;

  /// 是否启用流式响应
  final bool streamEnabled;

  /// 请求超时时间 (秒)
  final int timeoutSeconds;

  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.streamEnabled = true,
    this.timeoutSeconds = 60,
  });

  LlmConfig copyWith({
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? streamEnabled,
    int? timeoutSeconds,
  }) {
    return LlmConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamEnabled: streamEnabled ?? this.streamEnabled,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }

  /// 是否已配置
  bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty;

  /// API 完整地址
  String get chatEndpoint => '$baseUrl/chat/completions';

  Map<String, dynamic> toJson() {
    return {
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'streamEnabled': streamEnabled,
      'timeoutSeconds': timeoutSeconds,
    };
  }

  factory LlmConfig.fromJson(Map<String, dynamic> json) {
    return LlmConfig(
      baseUrl: json['baseUrl'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      streamEnabled: json['streamEnabled'] as bool? ?? true,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 60,
    );
  }

  /// 预设配置
  static const presets = {
    'deepseek': LlmConfig(
      baseUrl: 'https://api.deepseek.com',
      apiKey: '',
      model: 'deepseek-chat',
    ),
    'deepseek-reasoner': LlmConfig(
      baseUrl: 'https://api.deepseek.com',
      apiKey: '',
      model: 'deepseek-reasoner',
    ),
    'xiaomi-mimo': LlmConfig(
      baseUrl: 'https://api.xiaomimimo.com/v1',
      apiKey: '',
      model: 'mimo-v2.5-pro',
    ),
    'openai': LlmConfig(
      baseUrl: 'https://api.openai.com/v1',
      apiKey: '',
      model: 'gpt-4o',
    ),
  };

  /// 获取预设配置列表
  static List<MapEntry<String, LlmConfig>> get presetList {
    return presets.entries.toList();
  }

  @override
  String toString() {
    return 'LlmConfig(model: $model, baseUrl: $baseUrl)';
  }
}
