/// 本地存储服务
///
/// 使用 Hive 进行本地数据持久化

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/llm/llm_config.dart';
import '../core/models/chat_message.dart';
import '../core/models/script_model.dart';
import '../core/models/memory_result.dart';

/// 存储服务
class StorageService {
  static const String _llmConfigBox = 'llm_config';
  static const String _chatHistoryBox = 'chat_history';
  static const String _scriptsBox = 'scripts';
  static const String _favoritesBox = 'favorites';
  static const String _settingsBox = 'settings';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化存储
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    await Hive.openBox(_llmConfigBox);
    await Hive.openBox(_chatHistoryBox);
    await Hive.openBox(_scriptsBox);
    await Hive.openBox(_favoritesBox);
    await Hive.openBox(_settingsBox);

    _isInitialized = true;
  }

  // ==================== LLM 配置 ====================

  /// 保存 LLM 配置
  Future<void> saveLlmConfig(LlmConfig config) async {
    final box = Hive.box(_llmConfigBox);
    await box.put('current', jsonEncode(config.toJson()));
  }

  /// 获取 LLM 配置
  LlmConfig? getLlmConfig() {
    final box = Hive.box(_llmConfigBox);
    final json = box.get('current') as String?;
    if (json == null) return null;
    return LlmConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  // ==================== 聊天历史 ====================

  /// 保存聊天历史
  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final box = Hive.box(_chatHistoryBox);
    final jsonList = messages.map((m) => m.toJson()).toList();
    await box.put('history', jsonEncode(jsonList));
  }

  /// 获取聊天历史
  List<ChatMessage> getChatHistory() {
    final box = Hive.box(_chatHistoryBox);
    final json = box.get('history') as String?;
    if (json == null) return [];

    final List<dynamic> jsonList = jsonDecode(json) as List<dynamic>;
    return jsonList.map((item) {
      return ChatMessage.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  /// 清空聊天历史
  Future<void> clearChatHistory() async {
    final box = Hive.box(_chatHistoryBox);
    await box.delete('history');
  }

  // ==================== 脚本管理 ====================

  /// 保存脚本
  Future<void> saveScript(ScriptModel script) async {
    final box = Hive.box(_scriptsBox);
    await box.put(script.id, jsonEncode(script.toJson()));
  }

  /// 获取所有脚本
  List<ScriptModel> getAllScripts() {
    final box = Hive.box(_scriptsBox);
    return box.values.map((item) {
      final json = item as String;
      return ScriptModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }).toList();
  }

  /// 获取脚本
  ScriptModel? getScript(String id) {
    final box = Hive.box(_scriptsBox);
    final json = box.get(id) as String?;
    if (json == null) return null;
    return ScriptModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  /// 删除脚本
  Future<void> deleteScript(String id) async {
    final box = Hive.box(_scriptsBox);
    await box.delete(id);
  }

  // ==================== 收藏地址 ====================

  /// 保存收藏地址
  Future<void> saveFavorite(MemoryResult result) async {
    final box = Hive.box(_favoritesBox);
    await box.put(result.address, jsonEncode(result.toJson()));
  }

  /// 获取所有收藏地址
  List<MemoryResult> getFavorites() {
    final box = Hive.box(_favoritesBox);
    return box.values.map((item) {
      final json = item as String;
      return MemoryResult.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }).toList();
  }

  /// 删除收藏地址
  Future<void> deleteFavorite(String address) async {
    final box = Hive.box(_favoritesBox);
    await box.delete(address);
  }

  // ==================== 通用设置 ====================

  /// 保存设置
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  /// 获取设置
  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    final box = Hive.box(_settingsBox);
    await box.delete(key);
  }

  /// 释放资源
  Future<void> dispose() async {
    await Hive.close();
    _isInitialized = false;
  }
}
