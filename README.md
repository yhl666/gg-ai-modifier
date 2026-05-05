# GG-AI Modifier 🎮

> AI 驱动的游戏内存修改器 - 让游戏修改变得智能而简单

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5-blue.svg)](https://flutter.dev/)
[![Android](https://img.shields.io/badge/Android-7.0+-green.svg)](https://www.android.com/)
[![License](https://img.shields.io/badge/License-Educational-orange.svg)](LICENSE)

## 🎯 项目概述

GG-AI Modifier 是一个基于 Flutter + Kotlin 开发的 AI 驱动游戏内存修改器，类似于 GG 修改器但具有更强大的 AI 功能。项目采用现代化架构，提供直观的用户界面和智能的操作体验。

### 核心特性
- **AI 智能对话**：自然语言交互，AI 自动执行内存操作
- **实时内存搜索**：边搜边显示，搜索速度提升 3-5 倍
- **完美悬浮窗**：支持横竖屏，功能完整，拖动流畅
- **现代化 UI**：Material Design 3，暗色主题
- **脚本系统**：Lua 脚本支持，AI 自动生成

## 🏗️ 技术架构

### 前端架构 (Flutter)
```
lib/
├── core/                       # 核心功能层
│   ├── models/                 # 数据模型
│   │   ├── chat_message.dart   # 聊天消息模型
│   │   ├── chat_session.dart   # 对话会话模型
│   │   └── memory_result.dart  # 内存搜索结果模型
│   ├── llm/                    # LLM 集成
│   │   ├── llm_config.dart     # LLM 配置管理
│   │   └── llm_service.dart    # LLM 服务接口
│   └── ffi/                    # FFI 桥接
├── features/                   # 功能模块
│   ├── home/                   # 主页面 (底部导航)
│   ├── chat/                   # AI 对话记录页面
│   ├── search/                 # 内存搜索页面
│   ├── script/                 # 脚本库页面
│   ├── settings/               # 设置页面
│   └── process/                # 进程选择页面
├── services/                   # 服务层
└── widgets/                    # 通用组件
```

### 后端架构 (Kotlin)
```
android/app/src/main/kotlin/com/yl/aigg/ai_gg666/
├── MainActivity.kt             # 主 Activity，处理 Flutter 通信
├── OverlayService.kt          # 悬浮窗服务 (核心功能)
├── MemoryEngine.kt            # 内存操作引擎
├── ProcessManager.kt          # 进程管理
├── MemoryFreezer.kt           # 内存冻结功能
└── RootManager.kt             # Root 权限管理
```

## 🚀 功能详解

### 1. AI 对话系统
- **主应用对话记录页面**：显示历史对话会话，按时间排序
- **悬浮窗实时对话**：游戏中直接与 AI 对话，实时操作
- **智能理解**：自然语言描述需求，AI 自动执行相应操作
- **上下文记忆**：记住对话历史，提供连续性体验

### 2. 内存搜索引擎
- **实时搜索显示**：边搜索边显示结果，无需等待
- **多数据类型支持**：byte/word/dword/qword/float/double
- **智能过滤**：自动跳过系统内存区域，提高搜索效率
- **批量操作**：支持批量修改和冻结

### 3. 悬浮窗系统
- **完整功能迁移**：AI 对话、脚本库、设置都可在悬浮窗中使用
- **横竖屏适配**：完美支持横屏模式，拖动流畅
- **智能边界检测**：窗口不会超出屏幕范围
- **状态同步**：悬浮窗与主应用状态实时同步

### 4. 进程管理
- **智能进程识别**：自动过滤系统进程，只显示用户应用
- **实时状态同步**：悬浮窗附加进程后，主应用同步显示
- **进程信息展示**：显示进程名、包名、PID 等详细信息

## 🔧 开发环境配置

### 系统要求
- Flutter 3.11.5+
- Android SDK 28+
- Kotlin 1.8.0+
- 测试设备需要 Root 权限

### 快速开始
```bash
# 1. 克隆项目
git clone https://github.com/yourusername/ai_gg666.git
cd ai_gg666

# 2. 安装依赖
flutter pub get

# 3. 编译调试版本
flutter run

# 4. 编译发布版本
flutter build apk --release
```

### 配置 LLM API
1. 打开应用，进入"设置"页面
2. 选择 API 提供商（推荐 DeepSeek）
3. 输入 API Key 和 Base URL
4. 测试连接并保存配置

## 🐛 已修复的关键 Bug

### Bug #1: 横屏模式悬浮窗拖动问题
**问题**：横屏模式下悬浮窗只能左右拖动，不能上下移动
**解决方案**：
- 修复了 `OverlayService.kt` 中的触摸事件处理逻辑
- 添加了屏幕边界检测，确保窗口不会超出屏幕
- 支持横竖屏自由拖动

### Bug #2: 悬浮窗功能缺失
**问题**：点击"AI对话"、"脚本库"、"设置"没有对应窗口
**解决方案**：
- 实现了完整的 AI 对话面板，支持实时聊天
- 添加了脚本库和设置面板的悬浮窗版本
- 实现了功能路由，确保悬浮窗功能与主应用一致

### Bug #3: 内存搜索性能问题
**问题**：内存搜索慢且不实时，搜索完成后才显示结果
**解决方案**：
- 实现了实时搜索显示，边搜索边更新结果
- 优化了搜索算法，跳过无关内存区域
- 添加了搜索进度显示，提升用户体验

### Bug #4: 输入法无法弹出
**问题**：悬浮窗输入框点击后输入法无法弹出
**解决方案**：
- 修改了悬浮窗的 WindowManager.LayoutParams 配置
- 添加了 FLAG_ALT_FOCUSABLE_IM 和 SOFT_INPUT_ADJUST_RESIZE
- 实现了强制显示输入法的逻辑

### Bug #5: 对话记录页面 UI 问题
**问题**：对话记录页面顶部有奇怪图标遮挡，功能不完善
**解决方案**：
- 重新设计了对话记录页面，采用会话列表模式
- 实现了对话会话分组，每个会话显示标题、时间、预览
- 添加了会话详情页面，可查看完整对话历史

## 📊 性能优化

### 内存搜索优化
- **实时显示**：搜索结果实时更新，无需等待
- **智能过滤**：自动跳过系统内存区域
- **批量处理**：每 10 个结果更新一次 UI，减少卡顿
- **内存限制**：单次搜索最多 500 个结果，防止内存溢出

### 悬浮窗优化
- **硬件加速**：启用硬件加速，提升渲染性能
- **内存管理**：及时释放不用的视图，防止内存泄漏
- **触摸优化**：优化触摸事件处理，提升响应速度

## 🎮 使用场景

### 场景 1: 快速修改金币
```
用户操作：
1. 启动悬浮窗
2. 附加游戏进程
3. 点击 AI 对话
4. 输入："把金币改成 999999"

AI 自动执行：
1. 搜索当前金币数值
2. 过滤搜索结果
3. 修改为目标数值
4. 验证修改结果
```

### 场景 2: 冻结血量
```
用户操作：
1. 在悬浮窗中说："冻结血量"

AI 自动执行：
1. 搜索当前血量值
2. 找到血量地址
3. 冻结该地址
4. 确认冻结成功
```

### 场景 3: 生成修改脚本
```
用户操作：
1. 描述需求："生成一个无限金币的脚本"

AI 自动执行：
1. 分析游戏内存结构
2. 生成对应的 Lua 脚本
3. 保存到脚本库
4. 提供使用说明
```

## 🔒 安全性考虑

### Root 权限管理
- 使用 `su` 命令执行内存操作
- 严格验证 Root 权限状态
- 错误处理和权限检查

### 内存操作安全
- 只操作目标进程内存
- 避免修改系统关键内存
- 实时监控操作结果

### 数据隐私
- 本地存储对话记录
- API Key 加密保存
- 不上传敏感信息

## 🧪 测试指南

### 功能测试
```bash
# 查看应用日志
adb logcat | grep -E "OverlayService|MemoryEngine|GG-AI"

# 查看内存使用
adb shell dumpsys meminfo com.yl.aigg.ai_gg666

# 查看悬浮窗权限
adb shell appops get com.yl.aigg.ai_gg666 SYSTEM_ALERT_WINDOW
```

### 性能测试
- 内存搜索速度：应在 3-5 秒内完成
- 悬浮窗响应：触摸响应时间 < 100ms
- AI 对话延迟：根据 API 响应时间，通常 2-5 秒

## 🛣️ 未来规划

### 短期目标 (1-2 周)
- [ ] 模糊搜索功能（未知值搜索）
- [ ] 搜索历史记录
- [ ] 批量操作界面优化
- [ ] 收藏常用地址功能

### 中期目标 (1 个月)
- [ ] AI 自动生成复杂脚本
- [ ] 云端脚本库同步
- [ ] 游戏自动识别和配置
- [ ] 内存快照对比功能

### 长期目标 (3 个月)
- [ ] C++ 内存搜索引擎重写
- [ ] SIMD 指令集加速
- [ ] 插件系统架构
- [ ] 远程控制和协作功能

## 📝 开发注意事项

### 代码规范
- Flutter: 遵循 Dart 官方代码规范
- Kotlin: 遵循 Android 官方代码规范
- 注释: 关键功能必须有详细注释

### 提交规范
```
feat: 新功能
fix: Bug 修复
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建过程或辅助工具的变动
```

### 分支管理
- `main`: 主分支，稳定版本
- `develop`: 开发分支，最新功能
- `feature/*`: 功能分支
- `hotfix/*`: 紧急修复分支

## 🤝 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'feat: Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目仅供学习和研究使用，请勿用于非法用途。使用本项目所造成的任何后果由使用者自行承担。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 跨平台 UI 框架
- [Riverpod](https://riverpod.dev/) - 状态管理解决方案
- [Material Design 3](https://m3.material.io/) - 设计系统
- GG 修改器 - 功能灵感来源
- 开源社区的所有贡献者
- 联系反馈邮箱me985211@qq.com
---

⭐ 如果这个项目对你有帮助，请给个 Star！

📧 有问题或建议？欢迎提交 Issue 或联系开发者。