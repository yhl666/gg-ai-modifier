/// 内存搜索结果数据模型

/// 支持的数据类型
enum DataType {
  byte(1, 'Byte'),
  word(2, 'Word'),
  dword(4, 'DWord'),
  qword(8, 'QWord'),
  float(4, 'Float'),
  double(8, 'Double'),
  string(0, 'String');

  final int size;
  final String displayName;

  const DataType(this.size, this.displayName);

  /// 从字符串解析数据类型
  static DataType fromString(String value) {
    return DataType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DataType.dword,
    );
  }
}

/// 内存搜索结果
class MemoryResult {
  /// 内存地址 (十六进制)
  final String address;

  /// 地址的数值表示
  final int addressInt;

  /// 当前值
  final dynamic value;

  /// 数据类型
  final DataType type;

  /// 是否已收藏
  final bool isFavorite;

  /// 是否已冻结
  final bool isFrozen;

  /// 冻结的值 (如果已冻结)
  final dynamic frozenValue;

  /// 所属内存区域描述
  final String? regionName;

  const MemoryResult({
    required this.address,
    required this.addressInt,
    required this.value,
    required this.type,
    this.isFavorite = false,
    this.isFrozen = false,
    this.frozenValue,
    this.regionName,
  });

  MemoryResult copyWith({
    String? address,
    int? addressInt,
    dynamic value,
    DataType? type,
    bool? isFavorite,
    bool? isFrozen,
    dynamic frozenValue,
    String? regionName,
  }) {
    return MemoryResult(
      address: address ?? this.address,
      addressInt: addressInt ?? this.addressInt,
      value: value ?? this.value,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      isFrozen: isFrozen ?? this.isFrozen,
      frozenValue: frozenValue ?? this.frozenValue,
      regionName: regionName ?? this.regionName,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'addressInt': addressInt,
      'value': value,
      'type': type.name,
      'isFavorite': isFavorite,
      'isFrozen': isFrozen,
      'frozenValue': frozenValue,
      'regionName': regionName,
    };
  }

  /// 从 JSON 创建
  factory MemoryResult.fromJson(Map<String, dynamic> json) {
    return MemoryResult(
      address: json['address'] as String,
      addressInt: json['addressInt'] as int,
      value: json['value'],
      type: DataType.fromString(json['type'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isFrozen: json['isFrozen'] as bool? ?? false,
      frozenValue: json['frozenValue'],
      regionName: json['regionName'] as String?,
    );
  }

  @override
  String toString() {
    return 'MemoryResult(address: $address, value: $value, type: ${type.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryResult && other.addressInt == addressInt;
  }

  @override
  int get hashCode => addressInt.hashCode;
}

/// 内存区域信息
class MemoryRegion {
  /// 起始地址
  final int startAddress;

  /// 结束地址
  final int endAddress;

  /// 区域大小 (字节)
  final int size;

  /// 权限 (rwxp)
  final String permissions;

  /// 是否可读
  final bool isReadable;

  /// 是否可写
  final bool isWritable;

  /// 是否可执行
  final bool isExecutable;

  /// 是否为匿名映射
  final bool isAnonymous;

  /// 映射名称
  final String? name;

  const MemoryRegion({
    required this.startAddress,
    required this.endAddress,
    required this.size,
    required this.permissions,
    this.isReadable = false,
    this.isWritable = false,
    this.isExecutable = false,
    this.isAnonymous = false,
    this.name,
  });

  /// 起始地址的十六进制字符串
  String get startHex => '0x${startAddress.toRadixString(16).toUpperCase()}';

  /// 结束地址的十六进制字符串
  String get endHex => '0x${endAddress.toRadixString(16).toUpperCase()}';

  /// 是否适合搜索 (可读的匿名区域)
  bool get isSearchable => isReadable && isAnonymous;

  Map<String, dynamic> toJson() {
    return {
      'startAddress': startAddress,
      'endAddress': endAddress,
      'size': size,
      'permissions': permissions,
      'isReadable': isReadable,
      'isWritable': isWritable,
      'isExecutable': isExecutable,
      'isAnonymous': isAnonymous,
      'name': name,
    };
  }

  factory MemoryRegion.fromJson(Map<String, dynamic> json) {
    return MemoryRegion(
      startAddress: json['startAddress'] as int,
      endAddress: json['endAddress'] as int,
      size: json['size'] as int,
      permissions: json['permissions'] as String,
      isReadable: json['isReadable'] as bool? ?? false,
      isWritable: json['isWritable'] as bool? ?? false,
      isExecutable: json['isExecutable'] as bool? ?? false,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      name: json['name'] as String?,
    );
  }
}

/// 写入请求
class WriteRequest {
  /// 目标地址
  final int address;

  /// 要写入的值
  final dynamic value;

  /// 数据类型
  final DataType type;

  const WriteRequest({
    required this.address,
    required this.value,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'address': address, 'value': value, 'type': type.name};
  }
}
