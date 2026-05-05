/// 设置页面

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/llm/llm_config.dart';
import '../../main.dart';

/// LLM 配置 Provider
final llmConfigProvider = StateProvider<LlmConfig>((ref) {
  // 从存储加载配置
  final storage = ref.read(storageServiceProvider);
  final saved = storage.getLlmConfig();
  return saved ??
      const LlmConfig(baseUrl: '', apiKey: '', model: 'deepseek-chat');
});

/// 设置页面
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  late TextEditingController _temperatureController;
  late TextEditingController _maxTokensController;

  String _selectedPreset = 'custom';
  bool _isTesting = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final config = ref.read(llmConfigProvider);
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
    _temperatureController = TextEditingController(
      text: config.temperature.toString(),
    );
    _maxTokensController = TextEditingController(
      text: config.maxTokens.toString(),
    );
    // 加载悬浮窗自动开启设置
    final storage = ref.read(storageServiceProvider);
    _autoStartOverlay =
        storage.getSetting('auto_start_overlay', defaultValue: false) as bool;
    if (_autoStartOverlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toggleOverlay(true);
      });
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _temperatureController.dispose();
    _maxTokensController.dispose();
    super.dispose();
  }

  void _applyPreset(String presetName) {
    final preset = LlmConfig.presets[presetName];
    if (preset != null) {
      setState(() {
        _selectedPreset = presetName;
        _baseUrlController.text = preset.baseUrl;
        _modelController.text = preset.model;
        if (presetName != 'custom') {
          _apiKeyController.text = preset.apiKey;
        }
      });
    }
  }

  void _saveConfig() {
    final config = LlmConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
      temperature: double.tryParse(_temperatureController.text) ?? 0.7,
      maxTokens: int.tryParse(_maxTokensController.text) ?? 4096,
    );

    ref.read(llmConfigProvider.notifier).state = config;

    // 持久化保存
    final storage = ref.read(storageServiceProvider);
    storage.saveLlmConfig(config);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('✅ 配置已保存')));
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final baseUrl = _baseUrlController.text.trim();
    final apiKey = _apiKeyController.text.trim();
    final model = _modelController.text.trim();

    if (baseUrl.isEmpty || apiKey.isEmpty) {
      setState(() {
        _isTesting = false;
        _testResult = '❌ 请先填写 API 地址和密钥';
      });
      return;
    }

    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': 'Hi'},
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['choices'] != null) {
          setState(() {
            _testResult = '✅ 连接成功！模型: $model';
          });
        } else {
          setState(() {
            _testResult = '⚠️ 响应格式异常: ${response.body.substring(0, 100)}';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _testResult = '❌ API Key 无效 (401)';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _testResult = '❌ 模型不存在或 API 地址错误 (404)';
        });
      } else {
        setState(() {
          _testResult =
              '❌ 请求失败 (${response.statusCode}): ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}';
        });
      }
    } catch (e) {
      setState(() {
        if (e.toString().contains('TimeoutException')) {
          _testResult = '❌ 连接超时，请检查网络';
        } else if (e.toString().contains('SocketException')) {
          _testResult = '❌ 网络不可用，请检查网络连接';
        } else {
          _testResult = '❌ 连接失败: $e';
        }
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.settings, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text('设置'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // LLM API 配置
          _buildSectionTitle('🤖 LLM API 配置'),
          const SizedBox(height: 12),

          // 预设选择
          _buildPresetSelector(),
          const SizedBox(height: 16),

          // API 地址
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'https://api.deepseek.com',
              prefixIcon: Icon(Icons.link, size: 16),
            ),
          ),
          const SizedBox(height: 12),

          // API Key
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              prefixIcon: Icon(Icons.key, size: 16),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),

          // 模型名称
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型名称',
              hintText: 'deepseek-chat',
              prefixIcon: Icon(Icons.smart_toy, size: 16),
            ),
          ),
          const SizedBox(height: 12),

          // 温度和最大 Token
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _temperatureController,
                  decoration: const InputDecoration(
                    labelText: '温度',
                    hintText: '0.7',
                    prefixIcon: Icon(Icons.thermostat, size: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxTokensController,
                  decoration: const InputDecoration(
                    labelText: '最大 Token',
                    hintText: '4096',
                    prefixIcon: Icon(Icons.token, size: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveConfig,
              icon: const Icon(Icons.save),
              label: const Text('保存配置'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 连接测试
          _buildSectionTitle('🔗 连接测试'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_isTesting ? '测试中...' : '测试连接'),
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testResult!.startsWith('✅')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _testResult!.startsWith('✅')
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                _testResult!,
                style: TextStyle(
                  color: _testResult!.startsWith('✅')
                      ? Colors.green
                      : Colors.red,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // 悬浮窗
          _buildSectionTitle('🎮 悬浮窗'),
          const SizedBox(height: 12),
          _buildOverlayCard(),
          const SizedBox(height: 24),

          // Root 权限
          _buildSectionTitle('🔐 Root 权限'),
          const SizedBox(height: 12),
          _buildRootStatusCard(),
          const SizedBox(height: 24),

          // 关于
          _buildSectionTitle('ℹ️ 关于'),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.info_outline,
            title: 'GG-AI Modifier',
            subtitle: '版本 1.0.0 | AI 驱动的游戏内存修改器',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ 本工具仅供学习研究和个人单机游戏使用，禁止用于在线竞技游戏。',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPresetSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择 API 提供商',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...LlmConfig.presets.entries.map((entry) {
                final isSelected = _selectedPreset == entry.key;
                final labels = {
                  'deepseek': 'DeepSeek',
                  'deepseek-reasoner': 'DeepSeek R1',
                  'xiaomi-mimo': '小米 MiMo',
                  'openai': 'OpenAI',
                };
                return ChoiceChip(
                  label: Text(labels[entry.key] ?? entry.key),
                  selected: isSelected,
                  onSelected: (_) => _applyPreset(entry.key),
                  selectedColor: const Color(0xFF6C63FF),
                );
              }),
              ChoiceChip(
                label: const Text('自定义'),
                selected: _selectedPreset == 'custom',
                onSelected: (_) => _applyPreset('custom'),
                selectedColor: const Color(0xFF6C63FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _rootStatus = '未检测';
  bool _isCheckingRoot = false;

  Future<void> _checkRootAccess() async {
    setState(() {
      _isCheckingRoot = true;
      _rootStatus = '检测中...';
    });

    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      final result = await channel.invokeMethod('checkRootAccess');
      setState(() {
        _rootStatus = result == true ? '已获取 Root 权限 ✅' : '未获取 Root 权限 ❌';
      });
    } catch (e) {
      setState(() {
        _rootStatus = '检测失败: $e';
      });
    } finally {
      setState(() {
        _isCheckingRoot = false;
      });
    }
  }

  Widget _buildRootStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _rootStatus.contains('✅')
                      ? Icons.check_circle
                      : Icons.security,
                  color: _rootStatus.contains('✅')
                      ? Colors.green
                      : const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 8),
                Text(
                  'Root 状态: $_rootStatus',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '需要 Root 权限才能读写其他进程内存。\n点击下方按钮会触发 Magisk 授权弹窗。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingRoot ? null : _checkRootAccess,
                icon: _isCheckingRoot
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isCheckingRoot ? '检测中...' : '检测 Root 权限'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _overlayEnabled = false;
  bool _autoStartOverlay = false;

  Future<void> _toggleOverlay(bool enable) async {
    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      if (enable) {
        final started = await channel.invokeMethod('startOverlay');
        setState(() {
          _overlayEnabled = started == true;
        });
        if (started != true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请授予悬浮窗权限')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ 悬浮窗已开启')));
        }
      } else {
        await channel.invokeMethod('stopOverlay');
        setState(() {
          _overlayEnabled = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('悬浮窗已关闭')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }

  void _toggleAutoStart(bool value) {
    setState(() {
      _autoStartOverlay = value;
    });
    final storage = ref.read(storageServiceProvider);
    storage.saveSetting('auto_start_overlay', value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? '✅ 启动时自动开启悬浮窗' : '已关闭自动开启悬浮窗')),
    );
  }

  Widget _buildOverlayCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bubble_chart, color: Color(0xFF6C63FF)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '游戏内悬浮窗',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: _overlayEnabled,
                  onChanged: _toggleOverlay,
                  activeColor: const Color(0xFF6C63FF),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '开启后会在屏幕上显示一个悬浮球，点击可快速打开 AI 对话、内存搜索等功能，无需切换窗口。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.autorenew, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('启动时自动开启悬浮窗', style: TextStyle(fontSize: 13)),
                ),
                Switch(
                  value: _autoStartOverlay,
                  onChanged: _toggleAutoStart,
                  activeColor: const Color(0xFF6C63FF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6C63FF)),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}
