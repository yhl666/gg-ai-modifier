-- 自动修改金币脚本
-- 由 GG-AI 内置提供

require("gg_api")

function modifyGold(targetValue)
    gg.toast("开始搜索金币...")
    
    -- 第一次搜索
    local currentGold = gg.prompt("请输入当前金币数量:", {"0"})
    gg.searchNumber(tonumber(currentGold[1]), gg.TYPE_DWORD)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 1 then
        -- 需要第二次搜索
        gg.alert("请在游戏中消费一些金币，然后点确定")
        local newGold = gg.prompt("请输入新的金币数量:", {"0"})
        gg.refineNumber(tonumber(newGold[1]))
        
        count = gg.getResultsCount()
        gg.toast("缩小到 " .. count .. " 个结果")
    end
    
    if count == 1 then
        local results = gg.getResults(1)
        gg.writeMemory(results[1].address, targetValue, gg.TYPE_DWORD)
        gg.toast("✅ 金币已修改为 " .. targetValue)
        
        -- 询问是否冻结
        local choice = gg.alert("是否冻结金币值？", "冻结")
        if choice == 1 then
            gg.freeze(results[1].address, targetValue, gg.TYPE_DWORD)
            gg.toast("🔒 金币已冻结")
        end
    else
        gg.alert("未能精确定位，找到 " .. count .. " 个结果，请手动确认")
    end
end

-- 执行
modifyGold(999999)
