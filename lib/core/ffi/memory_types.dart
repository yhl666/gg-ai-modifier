/// 内存数据类型定义和工具函数

import 'dart:typed_data';
import '../models/memory_result.dart';

/// 数据类型工具类
class MemoryTypeUtils {
  /// 获取数据类型的字节大小
  static int getSize(DataType type) {
    switch (type) {
      case DataType.byte:
        return 1;
      case DataType.word:
        return 2;
      case DataType.dword:
        return 4;
      case DataType.qword:
        return 8;
      case DataType.float:
        return 4;
      case DataType.double:
        return 8;
      case DataType.string:
        return 0; // 字符串大小不固定
    }
  }

  /// 将值转换为指定类型的字节表示
  static List<int> toBytes(dynamic value, DataType type) {
    switch (type) {
      case DataType.byte:
        return [value & 0xFF];
      case DataType.word:
        return [value & 0xFF, (value >> 8) & 0xFF];
      case DataType.dword:
        return [
          value & 0xFF,
          (value >> 8) & 0xFF,
          (value >> 16) & 0xFF,
          (value >> 24) & 0xFF,
        ];
      case DataType.qword:
        return [
          value & 0xFF,
          (value >> 8) & 0xFF,
          (value >> 16) & 0xFF,
          (value >> 24) & 0xFF,
          (value >> 32) & 0xFF,
          (value >> 40) & 0xFF,
          (value >> 48) & 0xFF,
          (value >> 56) & 0xFF,
        ];
      case DataType.float:
        // 使用 Float32List 进行转换
        final bytes = List<int>.filled(4, 0);
        final byteData = ByteData(4);
        byteData.setFloat32(0, value.toDouble());
        for (int i = 0; i < 4; i++) {
          bytes[i] = byteData.getUint8(i);
        }
        return bytes;
      case DataType.double:
        final bytes = List<int>.filled(8, 0);
        final byteData = ByteData(8);
        byteData.setFloat64(0, value.toDouble());
        for (int i = 0; i < 8; i++) {
          bytes[i] = byteData.getUint8(i);
        }
        return bytes;
      case DataType.string:
        return value.toString().codeUnits;
    }
  }

  /// 从字节表示转换为指定类型的值
  static dynamic fromBytes(List<int> bytes, DataType type) {
    if (bytes.isEmpty) return null;

    switch (type) {
      case DataType.byte:
        return bytes[0];
      case DataType.word:
        return bytes[0] | (bytes[1] << 8);
      case DataType.dword:
        return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
      case DataType.qword:
        int value = 0;
        for (int i = 0; i < 8 && i < bytes.length; i++) {
          value |= bytes[i] << (i * 8);
        }
        return value;
      case DataType.float:
        final byteData = ByteData(4);
        for (int i = 0; i < 4 && i < bytes.length; i++) {
          byteData.setUint8(i, bytes[i]);
        }
        return byteData.getFloat32(0);
      case DataType.double:
        final byteData = ByteData(8);
        for (int i = 0; i < 8 && i < bytes.length; i++) {
          byteData.setUint8(i, bytes[i]);
        }
        return byteData.getFloat64(0);
      case DataType.string:
        return String.fromCharCodes(bytes);
    }
  }

  /// 格式化值为可读字符串
  static String formatValue(dynamic value, DataType type) {
    if (value == null) return 'N/A';

    switch (type) {
      case DataType.byte:
        return '0x${(value as int).toRadixString(16).toUpperCase().padLeft(2, '0')}';
      case DataType.word:
        return '0x${(value as int).toRadixString(16).toUpperCase().padLeft(4, '0')}';
      case DataType.dword:
        return '0x${(value as int).toRadixString(16).toUpperCase().padLeft(8, '0')} ($value)';
      case DataType.qword:
        return '0x${(value as int).toRadixString(16).toUpperCase().padLeft(16, '0')}';
      case DataType.float:
        return (value as double).toStringAsFixed(4);
      case DataType.double:
        return (value as double).toStringAsFixed(8);
      case DataType.string:
        return '"$value"';
    }
  }

  /// 格式化地址为十六进制字符串
  static String formatAddress(int address) {
    return '0x${address.toRadixString(16).toUpperCase().padLeft(16, '0')}';
  }

  /// 格式化大小为可读字符串
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
