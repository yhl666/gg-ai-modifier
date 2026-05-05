package com.yl.aigg.ai_gg666

import java.io.BufferedReader
import java.io.DataOutputStream
import java.io.InputStreamReader

/**
 * Root 权限管理器
 * 使用持久化 su shell，只建立一次连接，避免重复弹窗
 */
object RootManager {

    private var hasRootAccess: Boolean? = null
    private var suProcess: Process? = null
    private var suOutputStream: DataOutputStream? = null
    private var suReader: BufferedReader? = null

    /**
     * 检查并请求 Root 权限
     * 只在第一次调用时触发 Magisk 授权弹窗
     */
    fun checkRootAccess(): Boolean {
        if (hasRootAccess == true) return true
        return initSuShell()
    }

    /**
     * 初始化 su shell（只执行一次）
     */
    private fun initSuShell(): Boolean {
        if (hasRootAccess == true) return true

        try {
            suProcess = Runtime.getRuntime().exec("su")
            suOutputStream = DataOutputStream(suProcess!!.outputStream)
            suReader = BufferedReader(InputStreamReader(suProcess!!.inputStream))

            // 测试 root 权限
            val result = executeCommandInternal("id")
            hasRootAccess = result?.contains("uid=0") == true

            if (!hasRootAccess!!) {
                closeSuShell()
            }

            return hasRootAccess!!
        } catch (e: Exception) {
            hasRootAccess = false
            closeSuShell()
            return false
        }
    }

    /**
     * 请求 Root 权限
     */
    fun requestRootAccess(): Boolean {
        return checkRootAccess()
    }

    /**
     * 执行 root 命令（使用持久化 shell）
     */
    fun executeRootCommand(command: String): String? {
        if (hasRootAccess != true) {
            if (!initSuShell()) return null
        }
        return executeCommandInternal(command)
    }

    /**
     * 内部命令执行
     */
    private fun executeCommandInternal(command: String): String? {
        try {
            val os = suOutputStream ?: return null
            val reader = suReader ?: return null

            // 使用唯一标记分隔输出
            val marker = "CMD_DONE_${System.nanoTime()}"
            
            os.writeBytes("$command\n")
            os.writeBytes("echo $marker\n")
            os.flush()

            val output = StringBuilder()
            while (true) {
                val line = reader.readLine() ?: break
                if (line.contains(marker)) break
                output.appendLine(line)
            }

            return output.toString().trim()
        } catch (e: Exception) {
            // 连接断开，重新初始化
            closeSuShell()
            return null
        }
    }

    /**
     * 关闭 su shell
     */
    private fun closeSuShell() {
        try {
            suOutputStream?.writeBytes("exit\n")
            suOutputStream?.flush()
            suOutputStream?.close()
            suReader?.close()
            suProcess?.destroy()
        } catch (_: Exception) {}
        suProcess = null
        suOutputStream = null
        suReader = null
    }

    /**
     * 获取当前 Root 状态
     */
    fun getRootStatus(): String {
        return when (hasRootAccess) {
            true -> "已获取 Root 权限"
            false -> "未获取 Root 权限"
            null -> "未检测"
        }
    }

    /**
     * 重置 Root 状态
     */
    fun resetRootStatus() {
        closeSuShell()
        hasRootAccess = null
    }
}
