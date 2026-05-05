package com.yl.aigg.ai_gg666

import java.io.File

/**
 * 内存引擎
 * 负责进程内存的读写和搜索操作
 * 通过 /proc/pid/mem 直接访问进程内存，需要 Root 权限
 */
object MemoryEngine {

    private var attachedPid: Int? = null

    /**
     * 附加到目标进程
     * 简单验证进程存在即可
     */
    fun attachProcess(pid: Int): Boolean {
        return try {
            // 检查进程是否存在
            val procDir = File("/proc/$pid")
            if (!procDir.exists()) {
                // 备用检查
                val result = RootManager.executeRootCommand("ls /proc/$pid/status")
                if (result == null || result.isEmpty()) return false
            }
            attachedPid = pid
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 分离当前进程
     */
    fun detachProcess() {
        attachedPid = null
    }

    /**
     * 获取当前附加的进程 PID
     */
    fun getAttachedPid(): Int? = attachedPid

    /**
     * 精确搜索内存
     */
    fun searchExact(value: Any, type: String): List<Map<String, Any>> {
        val pid = attachedPid ?: return emptyList()

        return try {
            val hexValue = valueToHex(value, type) ?: return emptyList()
            val byteSize = hexValue.length / 2

            // 获取内存映射，只搜索可读写的匿名区域
            val mapsResult = RootManager.executeRootCommand("cat /proc/$pid/maps 2>/dev/null") ?: return emptyList()
            val results = mutableListOf<Map<String, Any>>()

            for (line in mapsResult.lines()) {
                if (!line.contains("rw-p")) continue

                val parts = line.split(" ")
                if (parts.isEmpty()) continue

                val addrRange = parts[0].split("-")
                if (addrRange.size != 2) continue

                val startAddr = addrRange[0].toLongOrNull(16) ?: continue
                val endAddr = addrRange[1].toLongOrNull(16) ?: continue
                val regionSize = endAddr - startAddr

                // 跳过太大的区域
                if (regionSize > 50 * 1024 * 1024 || regionSize <= 0) continue

                // 使用 grep 搜索
                val searchResult = RootManager.executeRootCommand(
                    "xxd -s $startAddr -l $regionSize -p /proc/$pid/mem 2>/dev/null | grep -bo '$hexValue' | head -20"
                ) ?: continue

                for (resultLine in searchResult.lines()) {
                    if (resultLine.isBlank()) continue
                    val offset = resultLine.split(":").firstOrNull()?.toLongOrNull() ?: continue
                    val address = startAddr + offset

                    results.add(
                        mapOf(
                            "address" to "0x${address.toString(16).uppercase()}",
                            "addressInt" to address.toInt(),
                            "value" to value,
                            "type" to type,
                            "isFavorite" to false,
                            "isFrozen" to false
                        )
                    )

                    if (results.size >= 500) break
                }
                if (results.size >= 500) break
            }

            results
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * 在之前的结果中过滤
     */
    fun filterResults(previousAddresses: List<Int>, value: Any, type: String): List<Map<String, Any>> {
        val pid = attachedPid ?: return emptyList()

        return try {
            val results = mutableListOf<Map<String, Any>>()

            for (addr in previousAddresses) {
                val readValue = readMemory(addr, type)
                if (readValue != null && valuesEqual(readValue, value, type)) {
                    results.add(
                        mapOf(
                            "address" to "0x${addr.toString(16).uppercase()}",
                            "addressInt" to addr,
                            "value" to value,
                            "type" to type,
                            "isFavorite" to false,
                            "isFrozen" to false
                        )
                    )
                }
            }

            results
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * 范围搜索
     */
    fun searchByRange(minValue: Long, maxValue: Long, type: String): List<Map<String, Any>> {
        return emptyList()
    }

    /**
     * 读取内存值
     */
    fun readMemory(address: Int, type: String): Any? {
        val pid = attachedPid ?: return null

        return try {
            val size = getTypeSize(type)
            val hexAddr = address.toLong().toString(16)
            val result = RootManager.executeRootCommand(
                "xxd -s 0x$hexAddr -l $size -p /proc/$pid/mem 2>/dev/null"
            ) ?: return null

            val hexStr = result.trim().replace(" ", "").replace("\n", "")
            if (hexStr.length < size * 2) return null

            hexToValue(hexStr, type)
        } catch (e: Exception) {
            null
        }
    }

    /**
     * 写入内存值
     */
    fun writeMemory(address: Int, value: Any, type: String): Boolean {
        val pid = attachedPid ?: return false

        return try {
            val hexAddr = address.toLong().toString(16)
            val hexValue = valueToHex(value, type) ?: return false
            val byteCount = hexValue.length / 2

            // 使用 printf 写入
            val escapedHex = hexValue.chunked(2).joinToString("\\\\x") { "\\\\x$it" }
            val cmd = "printf '$escapedHex' | dd of=/proc/$pid/mem bs=1 seek=0x$hexAddr count=$byteCount conv=notrunc 2>/dev/null"
            val result = RootManager.executeRootCommand(cmd)
            result != null
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 批量写入
     */
    fun writeBatch(requests: List<Map<String, Any>>): Boolean {
        var allSuccess = true
        for (req in requests) {
            val address = req["address"] as? Int ?: continue
            val value = req["value"] ?: continue
            val type = req["type"] as? String ?: "dword"
            if (!writeMemory(address, value, type)) allSuccess = false
        }
        return allSuccess
    }

    /**
     * 获取内存区域列表
     */
    fun getMemoryRegions(): List<Map<String, Any>> {
        val pid = attachedPid ?: return emptyList()

        return try {
            val mapsResult = RootManager.executeRootCommand("cat /proc/$pid/maps 2>/dev/null") ?: return emptyList()
            val regions = mutableListOf<Map<String, Any>>()

            for (line in mapsResult.lines()) {
                if (line.isBlank()) continue
                val parts = line.split(" ")
                if (parts.isEmpty()) continue

                val addrRange = parts[0].split("-")
                if (addrRange.size != 2) continue

                val startAddr = addrRange[0].toLongOrNull(16) ?: continue
                val endAddr = addrRange[1].toLongOrNull(16) ?: continue
                val permissions = if (parts.size > 1) parts[1] else "----"
                val name = if (parts.size > 5) parts.subList(5, parts.size).joinToString(" ") else ""

                regions.add(
                    mapOf(
                        "startAddress" to startAddr.toInt(),
                        "endAddress" to endAddr.toInt(),
                        "size" to (endAddr - startAddr).toInt(),
                        "permissions" to permissions,
                        "isReadable" to permissions.contains('r'),
                        "isWritable" to permissions.contains('w'),
                        "isExecutable" to permissions.contains('x'),
                        "isAnonymous" to name.isEmpty(),
                        "name" to name
                    )
                )
            }

            regions
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * 分析指定地址周围的内存区域
     */
    fun analyzeMemoryRegion(address: Int, range: Int): Map<String, Any> {
        val pid = attachedPid ?: return emptyMap()

        return try {
            val startAddr = (address.toLong() - range).coerceAtLeast(0)
            val length = range * 2

            val result = RootManager.executeRootCommand(
                "xxd -s $startAddr -l $length -g 4 /proc/$pid/mem 2>/dev/null"
            ) ?: return emptyMap()

            mapOf("address" to address, "range" to range, "data" to result)
        } catch (e: Exception) {
            emptyMap()
        }
    }

    // ==================== 工具函数 ====================

    private fun getTypeSize(type: String): Int {
        return when (type) {
            "byte" -> 1
            "word" -> 2
            "dword" -> 4
            "qword" -> 8
            "float" -> 4
            "double" -> 8
            else -> 4
        }
    }

    private fun valueToHex(value: Any, type: String): String? {
        return try {
            when (type) {
                "dword" -> {
                    val v = (value as? Number)?.toInt() ?: return null
                    String.format("%02x%02x%02x%02x", v and 0xFF, (v shr 8) and 0xFF, (v shr 16) and 0xFF, (v shr 24) and 0xFF)
                }
                "float" -> {
                    val v = (value as? Number)?.toFloat() ?: return null
                    val bits = java.lang.Float.floatToIntBits(v)
                    String.format("%02x%02x%02x%02x", bits and 0xFF, (bits shr 8) and 0xFF, (bits shr 16) and 0xFF, (bits shr 24) and 0xFF)
                }
                "byte" -> {
                    val v = (value as? Number)?.toInt() ?: return null
                    String.format("%02x", v and 0xFF)
                }
                "word" -> {
                    val v = (value as? Number)?.toInt() ?: return null
                    String.format("%02x%02x", v and 0xFF, (v shr 8) and 0xFF)
                }
                "qword" -> {
                    val v = (value as? Number)?.toLong() ?: return null
                    val sb = StringBuilder()
                    for (i in 0 until 8) sb.append(String.format("%02x", ((v shr (i * 8)) and 0xFF).toInt()))
                    sb.toString()
                }
                "double" -> {
                    val v = (value as? Number)?.toDouble() ?: return null
                    val bits = java.lang.Double.doubleToLongBits(v)
                    val sb = StringBuilder()
                    for (i in 0 until 8) sb.append(String.format("%02x", ((bits shr (i * 8)) and 0xFF).toInt()))
                    sb.toString()
                }
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun hexToValue(hexStr: String, type: String): Any? {
        return try {
            val bytes = ByteArray(hexStr.length / 2)
            for (i in bytes.indices) {
                bytes[i] = hexStr.substring(i * 2, i * 2 + 2).toInt(16).toByte()
            }

            when (type) {
                "byte" -> bytes[0].toInt() and 0xFF
                "word" -> (bytes[0].toInt() and 0xFF) or ((bytes[1].toInt() and 0xFF) shl 8)
                "dword" -> (bytes[0].toInt() and 0xFF) or ((bytes[1].toInt() and 0xFF) shl 8) or
                        ((bytes[2].toInt() and 0xFF) shl 16) or ((bytes[3].toInt() and 0xFF) shl 24)
                "qword" -> {
                    var v = 0L
                    for (i in 0 until 8) v = v or ((bytes[i].toLong() and 0xFF) shl (i * 8))
                    v
                }
                "float" -> {
                    val bits = (bytes[0].toInt() and 0xFF) or ((bytes[1].toInt() and 0xFF) shl 8) or
                            ((bytes[2].toInt() and 0xFF) shl 16) or ((bytes[3].toInt() and 0xFF) shl 24)
                    java.lang.Float.intBitsToFloat(bits)
                }
                "double" -> {
                    var bits = 0L
                    for (i in 0 until 8) bits = bits or ((bytes[i].toLong() and 0xFF) shl (i * 8))
                    java.lang.Double.longBitsToDouble(bits)
                }
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun valuesEqual(a: Any, b: Any, type: String): Boolean {
        return try {
            when (type) {
                "float" -> Math.abs((a as Number).toFloat() - (b as Number).toFloat()) < 0.001
                "double" -> Math.abs((a as Number).toDouble() - (b as Number).toDouble()) < 0.0001
                else -> (a as? Number)?.toLong() == (b as? Number)?.toLong()
            }
        } catch (e: Exception) {
            false
        }
    }
}
