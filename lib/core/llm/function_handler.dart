/// Function Calling 处理器
///
/// 定义 AI 可调用的函数，并执行实际的内存操作

import '../ffi/native_bridge.dart';
import '../models/memory_result.dart';

/// Function Calling 处理器
class FunctionHandler {
  final NativeBridge _bridge;

  FunctionHandler({required NativeBridge bridge}) : _bridge = bridge;

  /// 获取工具定义 (OpenAI Function Calling 格式)
  List<Map<String, dynamic>> getToolDefinitions() {
    return [
      {
        'type': 'function',
        'function': {
          'name': 'search_memory',
          'description': '搜索进程内存中指定值。用于查找游戏数据（金币、血量等）的内存地址。',
          'parameters': {
            'type': 'object',
            'properties': {
              'value': {'type': 'number', 'description': '要搜索的数值'},
              'data_type': {
                'type': 'string',
                'enum': ['dword', 'qword', 'float', 'double', 'byte', 'word'],
                'description': '数据类型，游戏金币/血量通常用 dword',
              },
            },
            'required': ['value', 'data_type'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'write_memory',
          'description': '向指定内存地址写入数值。用于修改游戏数据。',
          'parameters': {
            'type': 'object',
            'properties': {
              'address': {
                'type': 'string',
                'description': '内存地址 (十六进制，如 "0x7F3A4B2C80")',
              },
              'value': {'type': 'number', 'description': '要写入的值'},
              'data_type': {'type': 'string', 'description': '数据类型'},
            },
            'required': ['address', 'value', 'data_type'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'freeze_memory',
          'description': '冻结内存地址的值（持续写入），防止游戏自动修改。',
          'parameters': {
            'type': 'object',
            'properties': {
              'address': {'type': 'string', 'description': '内存地址'},
              'value': {'type': 'number', 'description': '要冻结的值'},
              'data_type': {'type': 'string', 'description': '数据类型'},
            },
            'required': ['address', 'value', 'data_type'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'get_process_list',
          'description': '获取当前运行中的进程列表，用于选择要修改的游戏。',
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'attach_process',
          'description': '附加到目标游戏进程，附加后才能读写其内存。',
          'parameters': {
            'type': 'object',
            'properties': {
              'pid': {'type': 'integer', 'description': '进程 ID'},
              'package_name': {'type': 'string', 'description': '应用包名'},
            },
            'required': ['package_name'],
          },
        },
      },
      {
        'type': 'function',
        'function': {
          'name': 'analyze_memory_region',
          'description': '分析指定地址周围的内存区域，帮助识别数据结构。',
          'parameters': {
            'type': 'object',
            'properties': {
              'address': {'type': 'string', 'description': '内存地址'},
              'range': {
                'type': 'integer',
                'description': '分析范围 (前后多少字节)，默认 256',
                'default': 256,
              },
            },
            'required': ['address'],
          },
        },
      },
    ];
  }

  /// 执行函数调用
  Future<dynamic> executeFunction(
    String functionName,
    Map<String, dynamic> arguments,
  ) async {
    switch (functionName) {
      case 'search_memory':
        return _searchMemory(arguments);
      case 'write_memory':
        return _writeMemory(arguments);
      case 'freeze_memory':
        return _freezeMemory(arguments);
      case 'get_process_list':
        return _getProcessList();
      case 'attach_process':
        return _attachProcess(arguments);
      case 'analyze_memory_region':
        return _analyzeMemoryRegion(arguments);
      default:
        return {'error': '未知函数: $functionName'};
    }
  }

  /// 搜索内存
  Future<Map<String, dynamic>> _searchMemory(Map<String, dynamic> args) async {
    final value = args['value'];
    final dataTypeStr = args['data_type'] as String;
    final type = DataType.fromString(dataTypeStr);

    final results = await _bridge.searchExact(value, type);

    return {
      'success': true,
      'count': results.length,
      'results': results.take(100).map((r) => r.toJson()).toList(),
      'message': results.isEmpty ? '未找到匹配的内存地址' : '找到 ${results.length} 个匹配地址',
    };
  }

  /// 写入内存
  Future<Map<String, dynamic>> _writeMemory(Map<String, dynamic> args) async {
    final addressStr = args['address'] as String;
    final value = args['value'];
    final dataTypeStr = args['data_type'] as String;
    final type = DataType.fromString(dataTypeStr);

    // 解析十六进制地址
    final address = int.parse(
      addressStr.replaceFirst('0x', '').replaceFirst('0X', ''),
      radix: 16,
    );

    final success = await _bridge.writeMemory(address, value, type);

    return {
      'success': success,
      'message': success ? '写入成功' : '写入失败',
      'address': addressStr,
      'value': value,
    };
  }

  /// 冻结内存
  Future<Map<String, dynamic>> _freezeMemory(Map<String, dynamic> args) async {
    final addressStr = args['address'] as String;
    final value = args['value'];
    final dataTypeStr = args['data_type'] as String;
    final type = DataType.fromString(dataTypeStr);

    final address = int.parse(
      addressStr.replaceFirst('0x', '').replaceFirst('0X', ''),
      radix: 16,
    );

    final success = await _bridge.freezeMemory(address, value, type);

    return {
      'success': success,
      'message': success ? '冻结成功' : '冻结失败',
      'address': addressStr,
    };
  }

  /// 获取进程列表
  Future<Map<String, dynamic>> _getProcessList() async {
    final processes = await _bridge.getProcessList();

    return {
      'success': true,
      'count': processes.length,
      'processes': processes.map((p) => p.toJson()).toList(),
    };
  }

  /// 附加进程
  Future<Map<String, dynamic>> _attachProcess(Map<String, dynamic> args) async {
    final pid = args['pid'] as int?;
    final packageName = args['package_name'] as String;

    if (pid == null) {
      return {'success': false, 'message': '需要提供进程 ID (pid)'};
    }

    final success = await _bridge.attachProcess(pid);

    return {
      'success': success,
      'message': success ? '已附加到 $packageName (PID: $pid)' : '附加失败',
      'pid': pid,
      'package_name': packageName,
    };
  }

  /// 分析内存区域
  Future<Map<String, dynamic>> _analyzeMemoryRegion(
    Map<String, dynamic> args,
  ) async {
    final addressStr = args['address'] as String;
    final range = args['range'] as int? ?? 256;

    final address = int.parse(
      addressStr.replaceFirst('0x', '').replaceFirst('0X', ''),
      radix: 16,
    );

    final result = await _bridge.analyzeMemoryRegion(address, range: range);

    return {'success': true, 'address': addressStr, 'analysis': result};
  }
}
