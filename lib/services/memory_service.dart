/// 内存操作服务封装
///
/// 提供高层内存操作接口，封装 NativeBridge 的底层调用

import 'dart:async';
import '../core/ffi/native_bridge.dart';
import '../core/models/memory_result.dart';

/// 内存服务
class MemoryService {
  final NativeBridge _bridge;

  /// 当前搜索结果
  List<MemoryResult> _searchResults = [];

  /// 搜索结果流控制器
  final _searchResultsController =
      StreamController<List<MemoryResult>>.broadcast();

  /// 冻结地址列表
  final Map<int, MemoryResult> _frozenAddresses = {};

  /// 冻结列表流控制器
  final _frozenController = StreamController<List<MemoryResult>>.broadcast();

  MemoryService({required NativeBridge bridge}) : _bridge = bridge;

  /// 搜索结果流
  Stream<List<MemoryResult>> get searchResultsStream =>
      _searchResultsController.stream;

  /// 冻结列表流
  Stream<List<MemoryResult>> get frozenStream => _frozenController.stream;

  /// 当前搜索结果
  List<MemoryResult> get searchResults => List.unmodifiable(_searchResults);

  /// 冻结地址列表
  List<MemoryResult> get frozenAddresses =>
      List.unmodifiable(_frozenAddresses.values);

  /// 搜索结果数量
  int get searchResultCount => _searchResults.length;

  /// 冻结数量
  int get frozenCount => _frozenAddresses.length;

  // ==================== 搜索操作 ====================

  /// 精确搜索
  Future<List<MemoryResult>> searchExact(dynamic value, DataType type) async {
    _searchResults = await _bridge.searchExact(value, type);
    _searchResultsController.add(_searchResults);
    return _searchResults;
  }

  /// 在之前的结果中过滤
  Future<List<MemoryResult>> filterResults(
    dynamic newValue,
    DataType type,
  ) async {
    _searchResults = await _bridge.filterResults(
      _searchResults,
      newValue,
      type,
    );
    _searchResultsController.add(_searchResults);
    return _searchResults;
  }

  /// 范围搜索
  Future<List<MemoryResult>> searchByRange(
    int minValue,
    int maxValue,
    DataType type,
  ) async {
    _searchResults = await _bridge.searchByRange(minValue, maxValue, type);
    _searchResultsController.add(_searchResults);
    return _searchResults;
  }

  /// 重置搜索
  void resetSearch() {
    _searchResults = [];
    _searchResultsController.add(_searchResults);
  }

  // ==================== 读写操作 ====================

  /// 读取内存值
  Future<dynamic> readMemory(int address, DataType type) async {
    return await _bridge.readMemory(address, type);
  }

  /// 写入内存值
  Future<bool> writeMemory(int address, dynamic value, DataType type) async {
    return await _bridge.writeMemory(address, value, type);
  }

  /// 批量写入
  Future<bool> writeBatch(List<WriteRequest> requests) async {
    return await _bridge.writeBatch(requests);
  }

  // ==================== 冻结操作 ====================

  /// 冻结内存地址
  Future<bool> freezeMemory(int address, dynamic value, DataType type) async {
    final success = await _bridge.freezeMemory(address, value, type);
    if (success) {
      // 更新搜索结果中的冻结状态
      _searchResults = _searchResults.map((r) {
        if (r.addressInt == address) {
          return r.copyWith(isFrozen: true, frozenValue: value);
        }
        return r;
      }).toList();
      _searchResultsController.add(_searchResults);

      // 添加到冻结列表
      final result = _searchResults.firstWhere(
        (r) => r.addressInt == address,
        orElse: () => MemoryResult(
          address: '0x${address.toRadixString(16).toUpperCase()}',
          addressInt: address,
          value: value,
          type: type,
          isFrozen: true,
          frozenValue: value,
        ),
      );
      _frozenAddresses[address] = result;
      _frozenController.add(frozenAddresses);
    }
    return success;
  }

  /// 解除冻结
  Future<bool> unfreezeMemory(int address) async {
    final success = await _bridge.unfreezeMemory(address);
    if (success) {
      // 更新搜索结果
      _searchResults = _searchResults.map((r) {
        if (r.addressInt == address) {
          return r.copyWith(isFrozen: false);
        }
        return r;
      }).toList();
      _searchResultsController.add(_searchResults);

      // 从冻结列表移除
      _frozenAddresses.remove(address);
      _frozenController.add(frozenAddresses);
    }
    return success;
  }

  /// 切换收藏状态
  void toggleFavorite(int address) {
    _searchResults = _searchResults.map((r) {
      if (r.addressInt == address) {
        return r.copyWith(isFavorite: !r.isFavorite);
      }
      return r;
    }).toList();
    _searchResultsController.add(_searchResults);
  }

  /// 获取收藏的地址
  List<MemoryResult> get favorites =>
      _searchResults.where((r) => r.isFavorite).toList();

  // ==================== 内存区域 ====================

  /// 获取内存区域列表
  Future<List<MemoryRegion>> getMemoryRegions() async {
    return await _bridge.getMemoryRegions();
  }

  /// 分析内存区域
  Future<Map<String, dynamic>> analyzeMemoryRegion(
    int address, {
    int range = 256,
  }) async {
    return await _bridge.analyzeMemoryRegion(address, range: range);
  }

  /// 释放资源
  void dispose() {
    _searchResultsController.close();
    _frozenController.close();
  }
}
