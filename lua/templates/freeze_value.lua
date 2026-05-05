-- AI 生成脚本模板: 冻结数值
-- 此模板由 GG-AI 根据对话自动生成

require("gg_api")

-- 参数 (由 AI 填充)
local FREEZE_VALUE = {{FREEZE_VALUE}}
local DATA_TYPE = {{DATA_TYPE}}
local DESCRIPTION = "{{DESCRIPTION}}"

function main()
    gg.toast("开始搜索" .. DESCRIPTION .. "...")
    
    local currentValue = gg.prompt("请输入当前" .. DESCRIPTION .. ":", {"0"})
    gg.searchNumber(tonumber(currentValue[1]), DATA_TYPE)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 1 then
        gg.alert("请在游戏中改变" .. DESCRIPTION .. "，然后点确定")
        local newValue = gg.prompt("请输入新的" .. DESCRIPTION .. ":", {"0"})
        gg.refineNumber(tonumber(newValue[1]))
        
        count = gg.getResultsCount()
        gg.toast("缩小到 " .. count .. " 个结果")
    end
    
    if count <= 5 then
        local results = gg.getResults(count)
        for i = 1, count do
            gg.freeze(results[i].address, FREEZE_VALUE, DATA_TYPE)
        end
        gg.toast("✅ " .. DESCRIPTION .. "已冻结为 " .. FREEZE_VALUE)
    else
        gg.alert("找到 " .. count .. " 个结果，请继续缩小范围")
    end
end

main()
