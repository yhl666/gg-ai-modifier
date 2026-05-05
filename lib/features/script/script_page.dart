/// 脚本库页面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/script_model.dart';

/// 脚本列表 Provider
final scriptsProvider = StateProvider<List<ScriptModel>>((ref) => []);

/// 脚本库页面
class ScriptPage extends ConsumerStatefulWidget {
  const ScriptPage({super.key});

  @override
  ConsumerState<ScriptPage> createState() => _ScriptPageState();
}

class _ScriptPageState extends ConsumerState<ScriptPage> {
  @override
  void initState() {
    super.initState();
    // 加载内置脚本
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBuiltinScripts();
    });
  }

  void _loadBuiltinScripts() {
    final builtinScripts = [
      ScriptModel(
        id: 'builtin_auto_gold',
        name: '自动修改金币',
        description: '自动搜索并修改游戏金币',
        content:
            '-- 自动修改金币脚本\nfunction modifyGold(target)\n  gg.toast("搜索金币...")\nend',
        isBuiltin: true,
        tags: ['金币', '自动'],
      ),
      ScriptModel(
        id: 'builtin_auto_heal',
        name: '自动回血',
        description: '冻结血量值，实现无限生命',
        content:
            '-- 自动回血脚本\nfunction freezeHealth()\n  gg.toast("冻结血量...")\nend',
        isBuiltin: true,
        tags: ['血量', '冻结'],
      ),
      ScriptModel(
        id: 'builtin_speed_hack',
        name: '加速脚本',
        description: '修改游戏速度',
        content: '-- 加速脚本\nfunction speedHack()\n  gg.toast("加速中...")\nend',
        isBuiltin: true,
        tags: ['速度', '加速'],
      ),
    ];
    ref.read(scriptsProvider.notifier).state = builtinScripts;
  }

  @override
  Widget build(BuildContext context) {
    final scripts = ref.watch(scriptsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.code, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text('脚本库'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateScriptDialog();
            },
          ),
        ],
      ),
      body: scripts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无脚本', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    '点击右上角 + 创建新脚本',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: scripts.length,
              itemBuilder: (context, index) {
                return _buildScriptCard(scripts[index]);
              },
            ),
    );
  }

  Widget _buildScriptCard(ScriptModel script) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showScriptDetail(script);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    script.isBuiltin
                        ? Icons.inventory_2
                        : script.isAiGenerated
                        ? Icons.smart_toy
                        : Icons.person,
                    color: script.isBuiltin
                        ? const Color(0xFF03DAC6)
                        : script.isAiGenerated
                        ? const Color(0xFF6C63FF)
                        : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      script.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'run',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16),
                            SizedBox(width: 8),
                            Text('运行'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      if (!script.isBuiltin)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'run':
                          _runScript(script);
                          break;
                        case 'edit':
                          _showScriptEditor(script);
                          break;
                        case 'delete':
                          _deleteScript(script);
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                script.description,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...script.tags.map(
                    (tag) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (script.executionCount > 0)
                    Text(
                      '已执行 ${script.executionCount} 次',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _runScript(ScriptModel script) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('正在运行: ${script.name}')));
  }

  void _showScriptDetail(ScriptModel script) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // 拖动指示器
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      script.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _runScript(script);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('运行'),
                  ),
                ],
              ),
            ),
            // 脚本内容
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    script.content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Color(0xFF03DAC6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showScriptEditor(ScriptModel? script) {
    final nameController = TextEditingController(text: script?.name ?? '');
    final descController = TextEditingController(
      text: script?.description ?? '',
    );
    final contentController = TextEditingController(
      text: script?.content ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(script == null ? '创建脚本' : '编辑脚本'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '脚本名称'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: '描述'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Lua 代码',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final desc = descController.text.trim();
              final content = contentController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入脚本名称')));
                return;
              }
              if (content.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入脚本内容')));
                return;
              }

              final scripts = ref.read(scriptsProvider);
              if (script != null) {
                // 编辑现有脚本
                final updated = script.copyWith(
                  name: name,
                  description: desc,
                  content: content,
                  updatedAt: DateTime.now(),
                );
                ref.read(scriptsProvider.notifier).state = scripts.map((s) {
                  return s.id == script.id ? updated : s;
                }).toList();
              } else {
                // 创建新脚本
                final newScript = ScriptModel(
                  id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  description: desc,
                  content: content,
                );
                ref.read(scriptsProvider.notifier).state = [
                  ...scripts,
                  newScript,
                ];
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('✅ 脚本已保存: $name')));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showCreateScriptDialog() {
    _showScriptEditor(null);
  }

  void _deleteScript(ScriptModel script) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('删除脚本'),
        content: Text('确定要删除 "${script.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final scripts = ref.read(scriptsProvider);
              ref.read(scriptsProvider.notifier).state = scripts
                  .where((s) => s.id != script.id)
                  .toList();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
