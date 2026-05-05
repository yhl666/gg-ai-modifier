/// Lua 脚本服务
///
/// 管理 Lua 脚本的加载、执行和存储

import 'dart:async';
import '../models/script_model.dart';
import '../ffi/native_bridge.dart';

/// Lua 服务
class LuaService {
  /// 脚本执行状态流控制器
  final _executionController = StreamController<LuaExecutionEvent>.broadcast();

  LuaService({required NativeBridge bridge});

  /// 执行状态流
  Stream<LuaExecutionEvent> get executionStream => _executionController.stream;

  /// 是否正在执行脚本
  bool _isExecuting = false;
  bool get isExecuting => _isExecuting;

  /// 加载内置脚本
  Future<List<ScriptModel>> loadBuiltinScripts() async {
    // 内置脚本列表
    return [
      ScriptModel(
        id: 'builtin_auto_gold',
        name: '自动修改金币',
        description: '自动搜索并修改游戏金币',
        content: _builtinAutoGoldScript,
        isBuiltin: true,
        tags: ['金币', '自动'],
      ),
      ScriptModel(
        id: 'builtin_auto_heal',
        name: '自动回血',
        description: '冻结血量值，实现无限生命',
        content: _builtinAutoHealScript,
        isBuiltin: true,
        tags: ['血量', '冻结'],
      ),
      ScriptModel(
        id: 'builtin_speed_hack',
        name: '加速脚本',
        description: '修改游戏速度',
        content: _builtinSpeedHackScript,
        isBuiltin: true,
        tags: ['速度', '加速'],
      ),
    ];
  }

  /// 执行 Lua 脚本
  Future<bool> executeScript(ScriptModel script) async {
    if (_isExecuting) {
      _executionController.add(
        LuaExecutionEvent(
          scriptId: script.id,
          status: LuaExecutionStatus.error,
          message: '已有脚本正在执行',
        ),
      );
      return false;
    }

    _isExecuting = true;
    _executionController.add(
      LuaExecutionEvent(
        scriptId: script.id,
        status: LuaExecutionStatus.running,
        message: '正在执行脚本: ${script.name}',
      ),
    );

    try {
      // 通过 MethodChannel 执行 Lua 脚本
      // 实际实现需要在 Android 端集成 LuaJIT
      await Future.delayed(const Duration(seconds: 1));

      _executionController.add(
        LuaExecutionEvent(
          scriptId: script.id,
          status: LuaExecutionStatus.completed,
          message: '脚本执行完成',
        ),
      );
      return true;
    } catch (e) {
      _executionController.add(
        LuaExecutionEvent(
          scriptId: script.id,
          status: LuaExecutionStatus.error,
          message: '脚本执行失败: $e',
        ),
      );
      return false;
    } finally {
      _isExecuting = false;
    }
  }

  /// 停止当前脚本
  void stopScript() {
    _isExecuting = false;
    _executionController.add(
      LuaExecutionEvent(
        scriptId: '',
        status: LuaExecutionStatus.stopped,
        message: '脚本已停止',
      ),
    );
  }

  /// 释放资源
  void dispose() {
    _executionController.close();
  }

  // ==================== 内置脚本 ====================

  static const String _builtinAutoGoldScript = '''
-- 自动修改金币脚本
-- 由 GG-AI 内置提供

function modifyGold(targetValue)
    gg.toast("开始搜索金币...")
    
    -- 第一次搜索
    local currentGold = gg.prompt("请输入当前金币数量:", {"0"})
    gg.searchNumber(tonumber(currentGold[1]), gg.TYPE_DWORD)
    
    local count = gg.getResultsCount()
    gg.toast("找到 " .. count .. " 个结果")
    
    if count > 1 then
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
    else
        gg.alert("未能精确定位，找到 " .. count .. " 个结果")
    end
end

modifyGold(999999)
''';

  static const String _builtinAutoHealScript = '''
-- 自动回血脚本
-- 冻结血量值实现无限生命

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
''';

  static const String _builtinSpeedHackScript = '''
-- 加速脚本
-- 修改游戏速度倍率

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
''';
}

/// Lua 执行事件
class LuaExecutionEvent {
  final String scriptId;
  final LuaExecutionStatus status;
  final String message;

  const LuaExecutionEvent({
    required this.scriptId,
    required this.status,
    required this.message,
  });
}

/// Lua 执行状态
enum LuaExecutionStatus { running, completed, error, stopped }
