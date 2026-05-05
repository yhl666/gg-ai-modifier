/// LLM API 调用服务
///
/// 支持 OpenAI 兼容 API，包括流式响应和 Function Calling

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_config.dart';
import '../models/chat_message.dart';
import 'function_handler.dart';
import 'prompt_builder.dart';

/// LLM 服务类
class LlmService {
  LlmConfig _config;
  final FunctionHandler _functionHandler;
  final PromptBuilder _promptBuilder;

  http.Client? _httpClient;
  bool _isStreaming = false;

  LlmService({
    required LlmConfig config,
    required FunctionHandler functionHandler,
    required PromptBuilder promptBuilder,
  }) : _config = config,
       _functionHandler = functionHandler,
       _promptBuilder = promptBuilder;

  /// 当前配置
  LlmConfig get config => _config;

  /// 是否正在流式响应
  bool get isStreaming => _isStreaming;

  /// 更新配置
  void updateConfig(LlmConfig newConfig) {
    _config = newConfig;
  }

  /// 发送聊天消息 (非流式)
  Future<ChatMessage> sendMessage(
    String userMessage, {
    List<ChatMessage> history = const [],
  }) async {
    if (!_config.isConfigured) {
      return ChatMessage.assistant('⚠️ 请先在设置中配置 LLM API');
    }

    try {
      final messages = _promptBuilder.buildMessages(
        userMessage: userMessage,
        history: history,
      );

      final response = await _makeRequest(messages, stream: false);

      if (response == null) {
        return ChatMessage.assistant('❌ 请求失败，请检查网络和 API 配置');
      }

      // 检查是否有函数调用
      final choice = response['choices']?[0];
      if (choice == null) {
        return ChatMessage.assistant('❌ 响应格式错误');
      }

      final message = choice['message'];
      final content = message['content'] as String? ?? '';

      // 检查是否有函数调用
      if (message['function_call'] != null) {
        final functionCall = message['function_call'];
        final funcName = functionCall['name'] as String;
        final funcArgs = jsonDecode(functionCall['arguments'] as String);

        // 执行函数调用
        final result = await _functionHandler.executeFunction(
          funcName,
          funcArgs,
        );

        // 将结果返回给 LLM 生成总结
        final summary = await _sendFunctionResult(
          funcName: funcName,
          arguments: funcArgs,
          result: result,
          history: history,
        );

        return summary;
      }

      return ChatMessage.assistant(content);
    } catch (e) {
      return ChatMessage.assistant('❌ 发生错误: $e');
    }
  }

  /// 发送聊天消息 (流式)
  Stream<String> sendMessageStream(
    String userMessage, {
    List<ChatMessage> history = const [],
  }) async* {
    if (!_config.isConfigured) {
      yield '⚠️ 请先在设置中配置 LLM API';
      return;
    }

    _isStreaming = true;

    try {
      final messages = _promptBuilder.buildMessages(
        userMessage: userMessage,
        history: history,
      );

      final request = http.Request('POST', Uri.parse(_config.chatEndpoint));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      });
      request.body = jsonEncode({
        'model': _config.model,
        'messages': messages,
        'temperature': _config.temperature,
        'max_tokens': _config.maxTokens,
        'stream': true,
        'tools': _functionHandler.getToolDefinitions(),
      });

      final streamedResponse = await _getClient().send(request);

      if (streamedResponse.statusCode != 200) {
        yield '❌ API 请求失败 (${streamedResponse.statusCode})';
        _isStreaming = false;
        return;
      }

      String buffer = '';

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        buffer += chunk;

        // 处理 SSE 格式
        final lines = buffer.split('\n');
        buffer = lines.last; // 保留未完成的行

        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty || !line.startsWith('data: ')) continue;

          final data = line.substring(6);
          if (data == '[DONE]') continue;

          try {
            final json = jsonDecode(data);
            final delta = json['choices']?[0]?['delta'];

            if (delta != null) {
              // 检查函数调用
              if (delta['function_call'] != null) {
                // 处理函数调用 (流式)
                final funcCall = delta['function_call'];
                if (funcCall['name'] != null) {
                  yield '\n\n🔧 正在执行: ${funcCall['name']}...\n';
                }
              }

              // 普通文本内容
              final content = delta['content'] as String?;
              if (content != null) {
                yield content;
              }
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    } catch (e) {
      yield '\n\n❌ 流式响应错误: $e';
    } finally {
      _isStreaming = false;
    }
  }

  /// 发送函数执行结果给 LLM
  Future<ChatMessage> _sendFunctionResult({
    required String funcName,
    required Map<String, dynamic> arguments,
    required dynamic result,
    required List<ChatMessage> history,
  }) async {
    try {
      final messages = _promptBuilder.buildFunctionResultMessages(
        funcName: funcName,
        arguments: arguments,
        result: result,
        history: history,
      );

      final response = await _makeRequest(messages, stream: false);

      if (response == null) {
        return ChatMessage.assistant('函数执行完成，但无法获取 AI 总结');
      }

      final content =
          response['choices']?[0]?['message']?['content'] as String? ?? '';
      return ChatMessage.assistant(content);
    } catch (e) {
      return ChatMessage.assistant('函数执行完成: $result');
    }
  }

  /// 发送 API 请求
  Future<Map<String, dynamic>?> _makeRequest(
    List<Map<String, dynamic>> messages, {
    bool stream = false,
  }) async {
    try {
      final response = await _getClient().post(
        Uri.parse(_config.chatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
        },
        body: jsonEncode({
          'model': _config.model,
          'messages': messages,
          'temperature': _config.temperature,
          'max_tokens': _config.maxTokens,
          'stream': stream,
          'tools': _functionHandler.getToolDefinitions(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('API 请求失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('API 请求异常: $e');
      return null;
    }
  }

  /// 获取 HTTP 客户端
  http.Client _getClient() {
    _httpClient ??= http.Client();
    return _httpClient!;
  }

  /// 释放资源
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _isStreaming = false;
  }
}
