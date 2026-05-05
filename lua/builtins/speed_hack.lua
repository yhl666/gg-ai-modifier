-- 加速脚本
-- 修改游戏速度倍率

require("gg_api")

function speedHack()
    local speed = gg.prompt("请输入速度倍率:", {"2.0"})
    local multiplier = tonumber(speed[1])
    
    gg.toast("搜索速度值...")
    
    -- 搜索速度相关的浮点数
    gg.searchNumber("1.0", gg.TYPE_FLOAT)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 0 and count <= 100 then
        local results = gg.getResults(count)
        for i = 1, count do
            gg.writeMemory(results[i].address, multiplier, gg.TYPE_FLOAT)
        end
        gg.toast("✅ 速度已修改为 " .. multiplier .. "x")
    else
        gg.alert("结果太多，请使用其他方法定位速度地址")
    end
end

speedHack()
