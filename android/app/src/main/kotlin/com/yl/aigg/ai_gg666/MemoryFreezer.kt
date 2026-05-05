package com.yl.aigg.ai_gg666

/**
 * 内存冻结器
 * 后台线程持续写入目标值，防止游戏自动修改数据
 */
object MemoryFreezer {

    private val frozenAddresses = mutableMapOf<Int, Map<String, Any>>()
    private var freezeThread: Thread? = null
    private var isRunning = false

    /**
     * 冻结内存地址
     */
    fun freeze(address: Int, value: Any, type: String): Boolean {
        frozenAddresses[address] = mapOf(
            "address" to address,
            "value" to value,
            "type" to type
        )
        startFreezingIfNeeded()
        return true
    }

    /**
     * 解除冻结
     */
    fun unfreeze(address: Int): Boolean {
        frozenAddresses.remove(address)
        if (frozenAddresses.isEmpty()) {
            stopFreezing()
        }
        return true
    }

    /**
     * 获取所有冻结地址
     */
    fun getFrozenAddresses(): List<Map<String, Any>> {
        return frozenAddresses.values.toList()
    }

    /**
     * 启动冻结守护线程
     */
    private fun startFreezingIfNeeded() {
        if (isRunning) return

        isRunning = true
        freezeThread = Thread {
            while (isRunning && frozenAddresses.isNotEmpty()) {
                for ((address, info) in frozenAddresses) {
                    val value = info["value"] ?: continue
                    val type = info["type"] as? String ?: "dword"
                    try {
                        MemoryEngine.writeMemory(address, value, type)
                    } catch (e: Exception) {
                        // 写入失败，跳过
                    }
                }
                try {
                    Thread.sleep(100) // 每 100ms 写入一次
                } catch (e: InterruptedException) {
                    break
                }
            }
            isRunning = false
        }
        freezeThread?.isDaemon = true
        freezeThread?.start()
    }

    /**
     * 停止冻结
     */
    private fun stopFreezing() {
        isRunning = false
        freezeThread?.interrupt()
        freezeThread = null
    }
}
