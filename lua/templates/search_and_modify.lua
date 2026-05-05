-- AI 生成脚本模板: 搜索并修改
-- 此模板由 GG-AI 根据对话自动生成

require("gg_api")

-- 参数 (由 AI 填充)
local TARGET_VALUE = {{TARGET_VALUE}}
local DATA_TYPE = {{DATA_TYPE}}
local DESCRIPTION = "{{DESCRIPTION}}"

function main()
    gg.toast("开始搜索" .. DESCRIPTION .. "...")
    
    -- 第一次搜索
    local currentValue = gg.prompt("请输入当前" .. DESCRIPTION .. "数量:", {"0"})
    gg.searchNumber(tonumber(currentValue[1]), DATA_TYPE)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 1 then
        gg.alert("请在游戏中改变" .. DESCRIPTION .. "，然后点确定")
        local newValue = gg.prompt("请输入新的" .. DESCRIPTION .. "数量:", {"0"})
        gg.refineNumber(tonumber(newValue[1]))
        
        count = gg.getResultsCount()
        gg.toast("缩小到 " .. count .. " 个结果")
    end
    
    if count == 1 then
        local results = gg.getResults(1)
        gg.writeMemory(results[1].address, TARGET_VALUE, DATA_TYPE)
        gg.toast("✅ " .. DESCRIPTION .. "已修改为 " .. TARGET_VALUE)
    else
        gg.alert("未能精确定位，找到 " .. count .. " 个结果")
    end
end

main()
