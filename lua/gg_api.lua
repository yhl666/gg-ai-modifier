-- GG-AI Lua API 实现
-- 这个文件定义了 Lua 脚本可用的 API 接口

gg = {}

-- 数据类型常数
gg.TYPE_BYTE    = 1
gg.TYPE_WORD    = 2
gg.TYPE_DWORD   = 4
gg.TYPE_QWORD   = 8
gg.TYPE_FLOAT   = 16
gg.TYPE_DOUBLE  = 32
gg.TYPE_STRING  = 128

-- 进程操作
function gg.setProcess(packageName)
    -- 通过 JNI 调用原生代码附加进程
    print("[GG-AI] 附加进程: " .. packageName)
end

function gg.getProcess()
    return "current_process"
end

function gg.getProcessList()
    return {}
end

-- 搜索
function gg.searchNumber(value, type)
    print("[GG-AI] 搜索数值: " .. tostring(value))
    return {}
end

function gg.searchFuzzy(value, type)
    print("[GG-AI] 模糊搜索: " .. tostring(value))
    return {}
end

function gg.refineNumber(value)
    print("[GG-AI] 缩小范围: " .. tostring(value))
    return {}
end

function gg.getResults(count)
    return {}
end

function gg.getResultsCount()
    return 0
end

-- 读写
function gg.readMemory(address, type)
    return 0
end

function gg.writeMemory(address, value, type)
    print("[GG-AI] 写入: " .. tostring(address) .. " = " .. tostring(value))
    return true
end

function gg.freeze(address, value, type)
    print("[GG-AI] 冻结: " .. tostring(address) .. " = " .. tostring(value))
    return true
end

function gg.unfreeze(address)
    print("[GG-AI] 解冻: " .. tostring(address))
    return true
end

-- UI
function gg.toast(message)
    print("[GG-AI Toast] " .. message)
end

function gg.alert(title, content)
    print("[GG-AI Alert] " .. title .. ": " .. (content or ""))
    return 1
end

function gg.prompt(hint, defaults)
    print("[GG-AI Prompt] " .. hint)
    return defaults or {"0"}
end

-- 工具
function gg.sleep(ms)
    -- 模拟延时
end

function gg.loop(count, callback)
    for i = 1, count do
        callback(i)
    end
end

function gg.log(message)
    print("[GG-AI Log] " .. message)
end

return gg
