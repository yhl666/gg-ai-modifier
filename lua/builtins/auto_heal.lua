-- 自动回血脚本
-- 冻结血量值实现无限生命

require("gg_api")

function freezeHealth()
    gg.toast("开始搜索血量...")
    
    local currentHealth = gg.prompt("请输入当前血量:", {"100"})
    gg.searchNumber(tonumber(currentHealth[1]), gg.TYPE_FLOAT)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 1 then
        gg.alert("请让角色受伤，然后点确定")
        local newHealth = gg.prompt("请输入受伤后的血量:", {"80"})
        gg.refineNumber(tonumber(newHealth[1]))
        
        count = gg.getResultsCount()
        gg.toast("缩小到 " .. count .. " 个结果")
    end
    
    if count <= 5 then
        local results = gg.getResults(count)
        for i = 1, count do
            gg.freeze(results[i].address, tonumber(currentHealth[1]), gg.TYPE_FLOAT)
        end
        gg.toast("✅ 血量已冻结为 " .. currentHealth[1])
    else
        gg.alert("找到 " .. count .. " 个结果，请继续缩小范围")
    end
end

freezeHealth()
