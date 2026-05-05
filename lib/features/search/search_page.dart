/// 内存搜索页面

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/memory_result.dart';
import '../process/process_selector.dart';

/// 搜索类型
enum SearchType { exact, fuzzy, range, unknown }

/// 当前搜索类型 Provider
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.exact);

/// 搜索结果 Provider
final searchResultsProvider = StateProvider<List<MemoryResult>>((ref) => []);

/// 数据类型 Provider
final dataTypeProvider = StateProvider<DataType>((ref) => DataType.dword);

/// 内存搜索页面
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final attachedProcess = ref.read(attachedProcessProvider);
    if (attachedProcess == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('⚠️ 请先在进程选择器中附加游戏进程')));
      return;
    }

    final searchType = ref.read(searchTypeProvider);
    final dataType = ref.read(dataTypeProvider);

    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      
      // 清空之前的结果
      ref.read(searchResultsProvider.notifier).state = [];

      if (searchType == SearchType.range) {
        final min = int.tryParse(_minController.text);
        final max = int.tryParse(_maxController.text);
        if (min == null || max == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请输入有效的范围值')));
          return;
        }

        // 显示搜索中提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔍 搜索中...'), duration: Duration(seconds: 1)),
        );

        final rawResults = await channel.invokeMethod('searchByRange', {
          'minValue': min,
          'maxValue': max,
          'type': dataType.name,
        });

        if (rawResults != null) {
          final results = (rawResults as List).map((item) {
            return MemoryResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
          }).toList();
          
          ref.read(searchResultsProvider.notifier).state = results;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ 找到 ${results.length} 个结果')),
          );
        }
      } else {
        final value = _valueController.text.trim();
        if (value.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请输入搜索值')));
          return;
        }

        // 解析值
        dynamic searchValue;
        switch (dataType) {
          case DataType.float:
          case DataType.double:
            searchValue = double.tryParse(value);
            break;
          default:
            searchValue = int.tryParse(value);
            break;
        }

        if (searchValue == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请输入有效的数值')));
          return;
        }

        // 显示搜索中提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔍 搜索中...'), duration: Duration(seconds: 1)),
        );

        final rawResults = await channel.invokeMethod('searchExact', {
          'value': searchValue,
          'type': dataType.name,
        });

        if (rawResults != null) {
          final results = (rawResults as List).map((item) {
            return MemoryResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
          }).toList();
          
          ref.read(searchResultsProvider.notifier).state = results;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ 找到 ${results.length} 个结果')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('搜索失败: $e')));
    }
  }

  Future<void> _writeMemory(MemoryResult result, dynamic newValue) async {
    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      final success = await channel.invokeMethod('writeMemory', {
        'address': result.addressInt,
        'value': newValue,
        'type': result.type.name,
      });

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ 已修改 ${result.address} = $newValue')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('❌ 写入失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 写入失败: $e')));
    }
  }

  Future<void> _freezeMemory(MemoryResult result, dynamic value) async {
    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      final success = await channel.invokeMethod('freezeMemory', {
        'address': result.addressInt,
        'value': value,
        'type': result.type.name,
      });

      if (success == true) {
        // 更新结果列表中的冻结状态
        final results = ref.read(searchResultsProvider);
        ref.read(searchResultsProvider.notifier).state = results.map((r) {
          if (r.addressInt == result.addressInt) {
            return r.copyWith(isFrozen: true, frozenValue: value);
          }
          return r;
        }).toList();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔒 已冻结 ${result.address} = $value')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 冻结失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final dataType = ref.watch(dataTypeProvider);
    final results = ref.watch(searchResultsProvider);
    final attachedProcess = ref.watch(attachedProcessProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.search, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Text('内存搜索'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 进程状态栏
          _buildProcessStatus(attachedProcess),
          // 搜索类型选择
          _buildSearchTypeSelector(searchType),
          // 搜索输入区域
          _buildSearchInput(searchType, dataType),
          // 搜索按钮
          _buildSearchButton(),
          // 结果统计
          if (results.isNotEmpty) _buildResultStats(results),
          // 搜索结果列表
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          attachedProcess == null
                              ? Icons.link_off
                              : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          attachedProcess == null ? '请先附加游戏进程' : '输入数值开始搜索',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildResultList(results),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStatus(dynamic attachedProcess) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProcessSelectorPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: const Color(0xFF2A2A2A),
        child: Row(
          children: [
            Icon(
              attachedProcess != null ? Icons.check_circle : Icons.circle,
              size: 8,
              color: attachedProcess != null ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachedProcess != null
                    ? '已附加: ${attachedProcess.packageName} (PID: ${attachedProcess.pid})'
                    : '未附加进程',
                style: TextStyle(
                  color: attachedProcess != null ? Colors.green : Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTypeSelector(SearchType currentType) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: SearchType.values.map((type) {
          final isSelected = type == currentType;
          final labels = {
            SearchType.exact: '精确',
            SearchType.fuzzy: '模糊',
            SearchType.range: '范围',
            SearchType.unknown: '未知',
          };
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(searchTypeProvider.notifier).state = type;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? const Color(0xFF6C63FF)
                      : const Color(0xFF2A2A2A),
                  foregroundColor: isSelected ? Colors.white : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(labels[type]!),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchInput(SearchType searchType, DataType dataType) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (searchType == SearchType.range) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: const InputDecoration(
                      hintText: '最小值',
                      prefixIcon: Icon(Icons.arrow_downward, size: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(
                      hintText: '最大值',
                      prefixIcon: Icon(Icons.arrow_upward, size: 16),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                hintText: searchType == SearchType.unknown ? '未知值搜索' : '输入数值',
                prefixIcon: const Icon(Icons.numbers, size: 16),
                suffixIcon: DropdownButton<DataType>(
                  value: dataType,
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2A2A2A),
                  items: DataType.values
                      .where((t) => t != DataType.string)
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            type.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) {
                      ref.read(dataTypeProvider.notifier).state = type;
                    }
                  },
                ),
              ),
              keyboardType: TextInputType.number,
              enabled: searchType != SearchType.unknown,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.search),
              label: const Text('搜索'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(searchResultsProvider.notifier).state = [];
              _valueController.clear();
              _minController.clear();
              _maxController.clear();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultStats(List<MemoryResult> results) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF2A2A2A),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '结果: ${results.length} 个地址',
            style: const TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          if (results.length > 100)
            const Text(
              '显示前 100 个',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildResultList(List<MemoryResult> results) {
    final displayResults = results.length > 100
        ? results.sublist(0, 100)
        : results;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: displayResults.length,
      itemBuilder: (context, index) {
        final result = displayResults[index];
        return _buildResultItem(result);
      },
    );
  }

  Widget _buildResultItem(MemoryResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              result.isFrozen ? Icons.lock : Icons.memory,
              color: result.isFrozen
                  ? const Color(0xFF03DAC6)
                  : result.isFavorite
                  ? Colors.amber
                  : Colors.grey,
              size: 20,
            ),
          ],
        ),
        title: Text(
          result.address,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        subtitle: Text(
          '值: ${result.value} (${result.type.displayName})',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 修改按钮
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(result),
            ),
            // 冻结按钮
            IconButton(
              icon: Icon(
                result.isFrozen ? Icons.lock_open : Icons.lock,
                color: result.isFrozen ? const Color(0xFF03DAC6) : Colors.grey,
                size: 20,
              ),
              onPressed: () {
                if (result.isFrozen) {
                  // 解冻
                  _unfreezeMemory(result);
                } else {
                  _showFreezeDialog(result);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(MemoryResult result) {
    final controller = TextEditingController(text: result.value.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('修改内存值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地址: ${result.address}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '新值',
                hintText: '输入要修改的值',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                dynamic value;
                switch (result.type) {
                  case DataType.float:
                  case DataType.double:
                    value = double.tryParse(newValue);
                    break;
                  default:
                    value = int.tryParse(newValue);
                    break;
                }
                if (value != null) {
                  _writeMemory(result, value);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('修改'),
          ),
        ],
      ),
    );
  }

  void _showFreezeDialog(MemoryResult result) {
    final controller = TextEditingController(text: result.value.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('冻结内存值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地址: ${result.address}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '冻结值',
                hintText: '输入要冻结的值',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final freezeValue = controller.text.trim();
              if (freezeValue.isNotEmpty) {
                dynamic value;
                switch (result.type) {
                  case DataType.float:
                  case DataType.double:
                    value = double.tryParse(freezeValue);
                    break;
                  default:
                    value = int.tryParse(freezeValue);
                    break;
                }
                if (value != null) {
                  _freezeMemory(result, value);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('冻结'),
          ),
        ],
      ),
    );
  }

  Future<void> _unfreezeMemory(MemoryResult result) async {
    try {
      const channel = MethodChannel('com.yl.aigg/bridge');
      await channel.invokeMethod('unfreezeMemory', {
        'address': result.addressInt,
      });

      final results = ref.read(searchResultsProvider);
      ref.read(searchResultsProvider.notifier).state = results.map((r) {
        if (r.addressInt == result.addressInt) {
          return r.copyWith(isFrozen: false);
        }
        return r;
      }).toList();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('🔓 已解冻 ${result.address}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 解冻失败: $e')));
    }
  }
}
