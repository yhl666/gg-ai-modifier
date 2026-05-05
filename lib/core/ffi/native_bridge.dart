/// FFI 桥接层 - Flutter 与 C++ Native 代码通信
///
/// 由于 C++ Native 代码需要在 Android 端编译，
/// 这里提供 Dart 侧的接口定义和模拟实现。
/// 实际部署时通过 MethodChannel 或 dart:ffi 与 native 库通信。

import 'dart:async';
import 'package:flutter/services.dart';
import '../models/memory_result.dart';
import '../models/process_info.dart';

/// Native 桥接类
/// 通过 MethodChannel 与 Android 原生代码通信
class NativeBridge {
  static const MethodChannel _channel = MethodChannel('com.yl.aigg/bridge');

  static NativeBridge? _instance;
  static NativeBridge get instance => _instance ??= NativeBridge._();

  NativeBridge._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// 初始化桥接层
  Future<bool> initialize() async {
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('NativeBridge 初始化失败: $e');
      return false;
    }
  }

  /// 处理来自原生层的回调
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMemoryChanged':
        // 内存变化通知
        break;
      case 'onProcessDied':
        // 进程死亡通知
        break;
      default:
        throw MissingPluginException('未实现的方法: ${call.method}');
    }
  }

  // ==================== 进程管理 ====================

  /// 获取运行中的进程列表
  Future<List<ProcessInfo>> getProcessList() async {
    try {
      final result = await _channel.invokeMethod('getProcessList');
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return ProcessInfo.fromJson(map);
      }).toList();
    } catch (e) {
      print('获取进程列表失败: $e');
      return [];
    }
  }

  /// 附加到目标进程
  Future<bool> attachProcess(int pid) async {
    try {
      final result = await _channel.invokeMethod('attachProcess', {'pid': pid});
      return result == true;
    } catch (e) {
      print('附加进程失败: $e');
      return false;
    }
  }

  /// 分离当前进程
  Future<bool> detachProcess() async {
    try {
      final result = await _channel.invokeMethod('detachProcess');
      return result == true;
    } catch (e) {
      print('分离进程失败: $e');
      return false;
    }
  }

  /// 获取当前附加的进程 PID
  Future<int?> getAttachedPid() async {
    try {
      final result = await _channel.invokeMethod('getAttachedPid');
      return result as int?;
    } catch (e) {
      return null;
    }
  }

  // ==================== 内存搜索 ====================

  /// 精确搜索内存
  Future<List<MemoryResult>> searchExact(dynamic value, DataType type) async {
    try {
      final result = await _channel.invokeMethod('searchExact', {
        'value': value,
        'type': type.name,
      });
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MemoryResult.fromJson(map);
      }).toList();
    } catch (e) {
      print('精确搜索失败: $e');
      return [];
    }
  }

  /// 在之前的结果中过滤
  Future<List<MemoryResult>> filterResults(
    List<MemoryResult> previousResults,
    dynamic newValue,
    DataType type,
  ) async {
    try {
      final result = await _channel.invokeMethod('filterResults', {
        'previousAddresses': previousResults.map((r) => r.addressInt).toList(),
        'value': newValue,
        'type': type.name,
      });
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MemoryResult.fromJson(map);
      }).toList();
    } catch (e) {
      print('过滤结果失败: $e');
      return [];
    }
  }

  /// 范围搜索
  Future<List<MemoryResult>> searchByRange(
    int minValue,
    int maxValue,
    DataType type,
  ) async {
    try {
      final result = await _channel.invokeMethod('searchByRange', {
        'minValue': minValue,
        'maxValue': maxValue,
        'type': type.name,
      });
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MemoryResult.fromJson(map);
      }).toList();
    } catch (e) {
      print('范围搜索失败: $e');
      return [];
    }
  }

  // ==================== 内存读写 ====================

  /// 读取内存值
  Future<dynamic> readMemory(int address, DataType type) async {
    try {
      final result = await _channel.invokeMethod('readMemory', {
        'address': address,
        'type': type.name,
      });
      return result;
    } catch (e) {
      print('读取内存失败: $e');
      return null;
    }
  }

  /// 写入内存值
  Future<bool> writeMemory(int address, dynamic value, DataType type) async {
    try {
      final result = await _channel.invokeMethod('writeMemory', {
        'address': address,
        'value': value,
        'type': type.name,
      });
      return result == true;
    } catch (e) {
      print('写入内存失败: $e');
      return false;
    }
  }

  /// 批量写入
  Future<bool> writeBatch(List<WriteRequest> requests) async {
    try {
      final result = await _channel.invokeMethod('writeBatch', {
        'requests': requests.map((r) => r.toJson()).toList(),
      });
      return result == true;
    } catch (e) {
      print('批量写入失败: $e');
      return false;
    }
  }

  // ==================== 内存冻结 ====================

  /// 冻结内存地址
  Future<bool> freezeMemory(int address, dynamic value, DataType type) async {
    try {
      final result = await _channel.invokeMethod('freezeMemory', {
        'address': address,
        'value': value,
        'type': type.name,
      });
      return result == true;
    } catch (e) {
      print('冻结内存失败: $e');
      return false;
    }
  }

  /// 解除冻结
  Future<bool> unfreezeMemory(int address) async {
    try {
      final result = await _channel.invokeMethod('unfreezeMemory', {
        'address': address,
      });
      return result == true;
    } catch (e) {
      print('解除冻结失败: $e');
      return false;
    }
  }

  /// 获取所有冻结地址
  Future<List<MemoryResult>> getFrozenAddresses() async {
    try {
      final result = await _channel.invokeMethod('getFrozenAddresses');
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MemoryResult.fromJson(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== 内存区域 ====================

  /// 获取内存区域列表
  Future<List<MemoryRegion>> getMemoryRegions() async {
    try {
      final result = await _channel.invokeMethod('getMemoryRegions');
      if (result == null) return [];

      final List<dynamic> list = result as List<dynamic>;
      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return MemoryRegion.fromJson(map);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// 分析指定地址周围的内存区域
  Future<Map<String, dynamic>> analyzeMemoryRegion(
    int address, {
    int range = 256,
  }) async {
    try {
      final result = await _channel.invokeMethod('analyzeMemoryRegion', {
        'address': address,
        'range': range,
      });
      return Map<String, dynamic>.from(result as Map? ?? {});
    } catch (e) {
      return {};
    }
  }

  // ==================== Root 权限 ====================

  /// 检查 Root 权限
  Future<bool> checkRootAccess() async {
    try {
      final result = await _channel.invokeMethod('checkRootAccess');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 请求 Root 权限
  Future<bool> requestRootAccess() async {
    try {
      final result = await _channel.invokeMethod('requestRootAccess');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _isInitialized = false;
  }
}
