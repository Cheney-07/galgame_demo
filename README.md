# 黎明之诗 (Dawn's Verse)

> Godot 4.7 · 回合制 RPG + 视觉小说混合游戏

## 游戏简介

《黎明之诗》是一款融合了 **ATB 回合制战斗** 与 **视觉小说叙事** 的独立游戏。玩家在末日背景中与各路角色相遇、交流、并肩作战，通过日程管理推进剧情，探索不同的故事走向。

## 核心特性

- **视觉小说对话系统** — 基于 [Dialogic 2.0](https://github.com/dialogic-godot/dialogic) 插件，支持分支剧情、角色立绘、CG 演出
- **ATB 回合制战斗** — 波次制敌人、技能系统、属性克制、编队策略
- **日程管理系统** — AP 行动力机制，训练/探索/委托/交流/做饭等多种日常活动
- **角色养成** — 6 维属性（STR/MAG/VIT/AGI/TEC/CHA）、等级成长、好感度系统
- **CG 画廊** — 达成条件解锁，随时回顾精彩画面
- **存档/读档** — 9 栏位存档，支持剧情中快捷存取

## 环境要求

| 工具 | 版本 |
|------|------|
| **Godot Engine** | 4.7（GL Compatibility 渲染模式） |
| **Dialogic 插件** | 2.0 Alpha-19（已内置于 `addons/`，无需额外安装） |
| **导出模板** | Windows（其他平台需自行配置） |

## 快速开始

```bash
# 1. 克隆仓库
git clone <repo-url>
cd gamedemo1

# 2. 用 Godot 4.7 打开项目
#    导入项目 → 选择 project.godot

# 3. 运行
#    按 F5 或点击右上角播放按钮
```

## 项目结构

```
├── project.godot              # 项目配置
├── autoload/                  # 全局单例
│   ├── GameState.gd           # 游戏状态（章节/天数/AP/阶段切换）
│   ├── PartyData.gd           # 角色数据（属性/技能/敌人/遭遇注册表）
│   ├── StoryFlags.gd          # 剧情标记（角色解锁/CG解锁/全局进度）
│   ├── SaveManager.gd         # 存档管理（多栏位/序列化）
│   ├── ImageUtils.gd          # 图片加载工具（缩放/裁剪）
│   ├── DialogicBridge.gd      # Dialogic 桥接（时间线启动/信号转发）
│   └── ExportManifest.gd      # 导出资源清单（确保动态资源被打包）
│
├── scenes/
│   ├── menu/                  # 启动画面 & 主菜单
│   ├── schedule/              # 日程界面（ScheduleHub）
│   ├── battle/                # 战斗系统
│   │   ├── arena/             # 战斗场景（CombatArena）
│   │   ├── battler/           # 战斗者（属性/状态）
│   │   ├── actions/           # 技能动作（攻击/治疗/特殊）
│   │   ├── enemies/           # 敌人模板（.tres 资源）
│   │   ├── encounters/        # 遭遇战配置 & 波次数据
│   │   ├── queue/             # ATB 回合队列
│   │   └── ui/                # 战斗 UI（菜单/血条/伤害数字）
│   └── MainScene.gd           # 场景管理器（VN/Schedule/Battle 切换）
│
├── resources/
│   ├── characters/            # 角色模板（.tres）
│   ├── skills/                # 技能数据（.tres）
│   └── dialogic/              # Dialogic 配置
│       ├── timelines/         # 时间线（剧情脚本）
│       ├── characters/        # 角色定义（立绘/名称）
│       └── layers/            # UI 层（快捷菜单等）
│
├── images/                    # 图片资源
│   ├── battle/                # 战斗相关（背景/精灵/图标）
│   ├── cg/                    # CG 画廊图片
│   └── icons/                 # 属性/技能图标
│
└── addons/dialogic/           # Dialogic 插件（无需手动修改）
```

## 游戏流程

```
启动 → Splash 动画 → 主菜单 → 开始新游戏
                                    ↓
              ┌──── 日程界面 ←───────┤
              │ (训练/探索/交流等)     │
              │        ↓              │
              ├── 编队 → 战斗 ←───────┤
              │   (胜利/失败)         │
              │        ↓              │
              └── VN 剧情 ←──────────┘
                       ↓
                    存档 / 章节推进
```

## 开发指南

### 添加新角色

1. 在 `resources/characters/` 创建 `角色id.tres`（参考现有模板）
2. 在 `PartyData.gd` 的 `_CHAR_FILES` 列表中添加文件名
3. 在 `ExportManifest.gd` 的 `_manifest()` 中添加对应的 `preload()`
4. 在 `resources/dialogic/characters/` 创建对应的 `.dch` 角色文件

### 添加新技能

1. 在 `resources/skills/` 创建 `skill_id.tres`
2. 在 `PartyData.gd` 的 `_SKILL_FILES` 中添加文件名
3. 在 `ExportManifest.gd` 中添加 `preload()`

### 添加新敌人/遭遇战

1. 敌人模板：`scenes/battle/enemies/` 创建 `.tres`
2. 波次数据：`scenes/battle/encounters/waves/` 创建 `.tres`
3. 遭遇战配置：`scenes/battle/encounters/` 创建 `.tres`
4. 在 `PartyData.gd` 对应的 `_ENEMY_FILES` / `_ENCOUNTER_FILES` 中添加文件名
5. 在 `ExportManifest.gd` 中添加 `preload()`

### 添加新 CG

1. 将图片放入 `images/cg/`
2. 在 `MainMenu.gd` 的 `CG_FILES` 数组中添加文件名（不含扩展名）
3. 在 `ExportManifest.gd` 中添加 `preload()`

### 导出注意事项

项目使用大量动态资源加载，导出前请确保：
- 所有动态资源路径已加入 `ExportManifest.gd` 和 `PartyData.gd` 的静态清单
- 导出时选择「导出全部资源」
- 图片资源使用 `ResourceLoader.exists()` 而非 `FileAccess.file_exists()` 检查存在性
- 目录扫描使用静态文件列表，而非 `DirAccess.open()`（导出包中不可用）

## 技术栈

- **引擎**: Godot 4.7（GDScript）
- **渲染**: GL Compatibility
- **对话系统**: Dialogic 2.0
- **物理**: Jolt Physics 3D
- **存档**: JSON + Dialogic 内置存档系统

## 许可证

待定

## 致谢

- [Dialogic](https://github.com/dialogic-godot/dialogic) — Godot 开源对话系统插件
- Godot Engine 社区
