/// 进程信息数据模型

/// 进程信息
class ProcessInfo {
  /// 进程 ID
  final int pid;

  /// 包名
  final String packageName;

  /// 进程名称
  final String processName;

  /// 用户 ID
  final int uid;

  /// 是否为系统进程
  final bool isSystem;

  /// 进程图标路径 (可选)
  final String? iconPath;

  const ProcessInfo({
    required this.pid,
    required this.packageName,
    required this.processName,
    this.uid = 0,
    this.isSystem = false,
    this.iconPath,
  });

  ProcessInfo copyWith({
    int? pid,
    String? packageName,
    String? processName,
    int? uid,
    bool? isSystem,
    String? iconPath,
  }) {
    return ProcessInfo(
      pid: pid ?? this.pid,
      packageName: packageName ?? this.packageName,
      processName: processName ?? this.processName,
      uid: uid ?? this.uid,
      isSystem: isSystem ?? this.isSystem,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  /// 显示名称 (优先使用 processName，即 APP 名称)
  String get displayName => processName.isNotEmpty && processName != packageName
      ? processName
      : packageName;

  /// 简短显示名称 (取最后一段)
  String get shortName {
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last : packageName;
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'packageName': packageName,
      'processName': processName,
      'uid': uid,
      'isSystem': isSystem,
      'iconPath': iconPath,
    };
  }

  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      pid: json['pid'] as int,
      packageName: json['packageName'] as String? ?? '',
      processName: json['processName'] as String? ?? '',
      uid: json['uid'] as int? ?? 0,
      isSystem: json['isSystem'] as bool? ?? false,
      iconPath: json['iconPath'] as String?,
    );
  }

  @override
  String toString() {
    return 'ProcessInfo(pid: $pid, package: $packageName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessInfo && other.pid == pid;
  }

  @override
  int get hashCode => pid.hashCode;
}
