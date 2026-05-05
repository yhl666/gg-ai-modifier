/// 进程管理服务封装

import 'dart:async';
import '../core/ffi/native_bridge.dart';
import '../core/models/process_info.dart';

/// 进程服务
class ProcessService {
  final NativeBridge _bridge;

  /// 当前附加的进程
  ProcessInfo? _attachedProcess;

  /// 进程列表流控制器
  final _processListController =
      StreamController<List<ProcessInfo>>.broadcast();

  /// 附加状态流控制器
  final _attachStateController = StreamController<ProcessInfo?>.broadcast();

  ProcessService({required NativeBridge bridge}) : _bridge = bridge;

  /// 进程列表流
  Stream<List<ProcessInfo>> get processListStream =>
      _processListController.stream;

  /// 附加状态流
  Stream<ProcessInfo?> get attachStateStream => _attachStateController.stream;

  /// 当前附加的进程
  ProcessInfo? get attachedProcess => _attachedProcess;

  /// 是否已附加进程
  bool get isAttached => _attachedProcess != null;

  /// 获取运行中的进程列表
  Future<List<ProcessInfo>> getProcessList() async {
    final processes = await _bridge.getProcessList();
    _processListController.add(processes);
    return processes;
  }

  /// 附加到目标进程
  Future<bool> attachProcess(ProcessInfo process) async {
    final success = await _bridge.attachProcess(process.pid);
    if (success) {
      _attachedProcess = process;
      _attachStateController.add(_attachedProcess);
    }
    return success;
  }

  /// 分离当前进程
  Future<bool> detachProcess() async {
    final success = await _bridge.detachProcess();
    if (success) {
      _attachedProcess = null;
      _attachStateController.add(null);
    }
    return success;
  }

  /// 检查 Root 权限
  Future<bool> checkRootAccess() async {
    return await _bridge.checkRootAccess();
  }

  /// 请求 Root 权限
  Future<bool> requestRootAccess() async {
    return await _bridge.requestRootAccess();
  }

  /// 释放资源
  void dispose() {
    _processListController.close();
    _attachStateController.close();
  }
}
