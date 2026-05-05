package com.yl.aigg.ai_gg666

import android.os.Handler
import android.os.Looper

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

/**
 * 进程管理器
 * 使用 pm list packages 快速获取已安装应用，再查找对应 PID
 * 类似 GG 修改器的方式，瞬间出结果
 */
object ProcessManager {

    private var appInfoCache: Map<String, ApplicationInfo> = emptyMap()

    /**
     * 获取运行中的应用进程列表
     * 使用 pm + ps 快速获取，避免遍历 /proc
     */
    fun getProcessList(context: android.content.Context): List<Map<String, Any>> {
        val processes = mutableListOf<Map<String, Any>>()

        try {
            // 获取已安装的第三方应用信息（用于显示APP名称）
            val pm = context.packageManager
            val installedApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
            appInfoCache = installedApps.associateBy { it.packageName }

            // 使用 ps 命令快速获取运行中的进程
            val psResult = RootManager.executeRootCommand("ps -A -o PID,NAME")
            if (psResult != null) {
                for (line in psResult.lines()) {
                    if (line.isBlank() || line.startsWith("PID")) continue
                    val parts = line.trim().split(Regex("\\s+"), limit = 2)
                    if (parts.size < 2) continue

                    val pid = parts[0].toIntOrNull() ?: continue
                    val packageName = parts[1].trim()

                    if (packageName.isEmpty() || !packageName.contains(".")) continue

                    // 获取 APP 名称
                    val appName = getAppName(pm, packageName)
                    val isSystem = isSystemApp(packageName)

                    processes.add(
                        mapOf(
                            "pid" to pid,
                            "packageName" to packageName,
                            "processName" to appName,
                            "uid" to 0,
                            "isSystem" to isSystem
                        )
                    )
                }
            }

            // 如果 ps 命令失败，尝试备用方案
            if (processes.isEmpty()) {
                return getProcessListFallback(context)
            }
        } catch (e: Exception) {
            return getProcessListFallback(context)
        }

        return processes
            .distinctBy { it["packageName"] as String }
            .sortedWith(compareBy<Map<String, Any>> {
                val name = it["processName"] as String
                // 中文名称排前面
                if (name.isNotEmpty() && name[0].code > 127) 0 else 1
            }.thenBy { it["processName"] as String })
    }

    /**
     * 备用方案：使用 pm list packages + cat /proc/pid/cmdline
     */
    private fun getProcessListFallback(context: android.content.Context): List<Map<String, Any>> {
        val processes = mutableListOf<Map<String, Any>>()

        try {
            val pm = context.packageManager

            // 获取所有运行中的进程 PID 和包名
            val procResult = RootManager.executeRootCommand(
                "for pid in /proc/[0-9]*; do " +
                "p=\${pid##*/}; " +
                "c=\$(cat /proc/\$p/cmdline 2>/dev/null | tr '\\0' ' ' | sed 's/ *$//'); " +
                "[ -n \"\$c\" ] && echo \"\$p|\$c\"; " +
                "done"
            )

            if (procResult != null) {
                for (line in procResult.lines()) {
                    if (line.isBlank() || !line.contains("|")) continue
                    val parts = line.split("|", limit = 2)
                    if (parts.size < 2) continue

                    val pid = parts[0].trim().toIntOrNull() ?: continue
                    val packageName = parts[1].trim()

                    if (packageName.isEmpty()) continue

                    val appName = getAppName(pm, packageName)
                    val isSystem = isSystemApp(packageName)

                    processes.add(
                        mapOf(
                            "pid" to pid,
                            "packageName" to packageName,
                            "processName" to appName,
                            "uid" to 0,
                            "isSystem" to isSystem
                        )
                    )
                }
            }
        } catch (e: Exception) {}

        return processes
            .distinctBy { it["packageName"] as String }
            .sortedWith(compareBy<Map<String, Any>> {
                val name = it["processName"] as String
                if (name.isNotEmpty() && name[0].code > 127) 0 else 1
            }.thenBy { it["processName"] as String })
    }

    /**
     * 获取 APP 显示名称
     */
    private fun getAppName(pm: PackageManager, packageName: String): String {
        return try {
            val appInfo = appInfoCache[packageName]
            if (appInfo != null) {
                pm.getApplicationLabel(appInfo).toString()
            } else {
                packageName
            }
        } catch (e: Exception) {
            packageName
        }
    }

    /**
     * 判断是否为系统应用
     */
    private fun isSystemApp(packageName: String): Boolean {
        return packageName.startsWith("com.android.") ||
                packageName.startsWith("android.") ||
                packageName == "system" ||
                packageName == "zygote" ||
                packageName == "zygote64" ||
                packageName.startsWith("com.google.android.") ||
                packageName == "root" ||
                packageName == "shell"
    }
}
