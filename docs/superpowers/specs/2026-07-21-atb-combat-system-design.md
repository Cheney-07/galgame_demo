# ATB 半即时战斗系统重构设计文档

> 日期：2026-07-21 | 状态：已确认
> 基于 [godot-open-rpg-0.4.0](https://github.com/AnidemDex/Godot-Open-RPG) 的 ATB 战斗架构思路重构

---

## 一、设计目标

将现有的纯回合制（按 AGI 排序）战斗系统，重构为 ATB（Active Time Battle）半即时制，同时：

1. **保留**：6 角色体系、6 维属性、12 个技能 Resource、Dialogic 战后剧情联动
2. **替换**：BattleController.gd / BattleUI.gd / SkillProcessor.gd — 三文件全删
3. **新增**：约 20 个新文件（场景/脚本/资源），采用组件化架构
4. **保持**：编队→战斗→胜利→Dialogic→返回日程 的完整玩家流程不变

---

## 二、核心架构

```
CombatArena (Control) — 战斗容器（.tscn 场景文件定义敌人）
│
├── Background (TextureRect)       ← 战斗背景图
├── Foreground (Control)
├── Battlers (ActiveTurnQueue)     ← ATB 回合管理器
│   ├── PlayerBattler1 (Battler)
│   │   ├── BattlerStats (Resource)
│   │   ├── Sprite2D
│   │   └── AnimationPlayer
│   ├── Enemy1 (Battler + CombatAI)
│   └── ...
└── UI (CanvasLayer)
    ├── TurnBar / BattlerIcon × N  ← ATB 行动顺序条
    ├── PlayerBattlerList / BattlerEntry × 3  ← 我方 HP 面板
    ├── ActionMenu / ActionButton × N  ← 行动菜单
    ├── TargetingCursor            ← 目标选择器
    ├── DamageLabelContainer       ← 伤害浮字
    └── ActionDescription          ← 技能描述
```

## 三、文件清单

### 3.1 新增文件

#### 战斗核心（5 文件）

| 文件 | 类型 | 说明 |
|------|------|------|
| `scenes/battle/arena/CombatArena.gd` | 脚本 | 战斗容器，管理初始化/UI联动/胜利/失败流程 |
| `scenes/battle/arena/CombatArena.tscn` | 场景 | 战斗容器场景模板 |
| `scenes/battle/battle_new.tscn` | 场景 | 战斗入口场景（MainScene 加载此场景） |
| `scenes/battle/battler/Battler.gd` | 脚本 | 战斗实体节点，管理 readiness/行动/受击 |
| `scenes/battle/battler/Battler.tscn` | 场景 | 战斗实体场景 |

#### 属性系统（1 文件）

| 文件 | 类型 | 说明 |
|------|------|------|
| `scenes/battle/battler/BattlerStats.gd` | 脚本(Resource) | 属性资源，含 modifier/multiplier buff 机制 |

#### ATB 核心（2 文件）

| 文件 | 类型 | 说明 |
|------|------|------|
| `scenes/battle/queue/ActiveTurnQueue.gd` | 脚本 | ATB 主循环，管理 readiness / time_scale / 行动队列 |
| `scenes/battle/queue/BattlerList.gd` | 脚本(RefCounted) | 参战者列表，检测胜利/失败条件 |

#### 行动系统（6 文件）

| 文件 | 类型 | 说明 |
|------|------|------|
| `scenes/battle/actions/BattlerAction.gd` | 脚本(Resource) | 行动基类，定义 execute / get_possible_targets |
| `scenes/battle/actions/AttackBattlerAction.gd` | 脚本(Resource) | 伤害型行动（普攻/弹幕/言灵等） |
| `scenes/battle/actions/HealBattlerAction.gd` | 脚本(Resource) | 治疗型行动（猫舔/煮白菜治愈领域） |
| `scenes/battle/actions/ModifyStatsBattlerAction.gd` | 脚本(Resource) | 增益型行动（算力增幅/超频链接） |
| `scenes/battle/actions/SpecialBattlerAction.gd` | 脚本(Resource) | 特殊行动（召唤世界书） |
| `scenes/battle/actions/ActionFactory.gd` | 脚本 | 从 SkillData.tres → BattlerAction 的工厂 |

#### UI 组件（7 组件，含场景+脚本）

| 文件 | 说明 |
|------|------|
| `scenes/battle/ui/UITurnBar.gd` + `.tscn` | ATB 行动顺序条（顶部横条） |
| `scenes/battle/ui/UIBattlerIcon.gd` + `.tscn` | 行动条上的角色图标（48×48） |
| `scenes/battle/ui/UIPlayerBattlerList.gd` + `.tscn` | 我方状态面板（左侧） |
| `scenes/battle/ui/UIBattlerEntry.gd` + `.tscn` | 单角色状态条目（HP条/名字） |
| `scenes/battle/ui/UIActionMenu.gd` + `.tscn` | 行动选择菜单（底部弹出） |
| `scenes/battle/ui/UIBattlerTargetingCursor.gd` + `.tscn` | 目标选择高亮 |
| `scenes/battle/ui/UIDamageLabel.gd` + `.tscn` | 伤害/治疗飘字 |

#### 敌人/遭遇战数据（6 文件）

| 文件 | 说明 |
|------|------|
| `scenes/battle/enemies/slime.tres` | 史莱姆模板 |
| `scenes/battle/enemies/diren_laocong.tres` | 邪恶汉堡牢聪模板 |
| `scenes/battle/enemies/bianbian.tres` | 便便模板 |
| `scenes/battle/encounters/explore_encounter.tres` | 探索战斗配置 |
| `scenes/battle/encounters/quest_encounter.tres` | 委托战斗配置 |
| `scenes/battle/encounters/default_encounter.tres` | 默认战斗配置 |

### 3.2 修改文件

| 文件 | 改动内容 |
|------|---------|
| `scenes/MainScene.gd` | `_create_battle_scene()` 改为加载 `battle_new.tscn`；`_get_enemies()` 替换为 `_get_encounter()` Resource 查表 |
| `autoload/PartyData.gd` | 添加 `EnemyRegistry`、`EncounterRegistry` 字典及加载方法 |

### 3.3 删除文件

```
scenes/battle/BattleController.gd
scenes/battle/BattleUI.gd
scenes/battle/SkillProcessor.gd
scenes/battle/battle.tscn
```

---

## 四、属性映射

### 6 维 → ATB 战斗属性

| 现有属性 | → 战斗属性 | 计算 |
|---------|-----------|------|
| **STR** 力量 | `ATTACK` | base_attack = STR |
| **MAG** 魔力 | `MAGIC_ATTACK` | base_magic_attack = MAG |
| **VIT** 耐力 | `MAX_HEALTH`, `DEFENSE` | max_health = 100 + VIT × 15 × (1 + (Lv-1)×0.1); defense = VIT |
| **AGI** 敏捷 | `SPEED` | speed = AGI（ATB 充能速度） |
| **TEC** 技术 | `HIT_CHANCE`, `CRIT_CHANCE` | hit_chance = 80 + TEC × 2（%） |
| **CHA** 魅力 | 治疗/辅助系数 | 在 HealAction 和 Buff 中计算 |

### Buff/Debuff 系统

modifier（加法）和 multiplier（乘法）分别管理：

```gdscript
# 加法修改器 — 适用于固定值增益
stats.add_modifier("attack", 10)      # 攻击 +10
stats.remove_modifier("attack", id)

# 乘法修改器 — 适用于百分比增减
stats.add_multiplier("speed", 0.3)   # 速度 +30%
stats.add_multiplier("speed", -0.5)  # 速度 -50%
```

---

## 五、ATB 核心循环

### Process 循环（每秒执行）

```
每帧 _process(delta):
    time_scale = 当前状态决定（1.0 / 0.05 / 0.0）

    for each 存活的 battler:
        readiness += speed × delta × time_scale

    while 有 readiness >= 100 的 battler:
        battler = readiness 最高的
        if battler 是玩家:
            time_scale = 0.05（超慢速）
            发出信号 player_needs_input(battler)
            return  # 等待 UI 回调
        else:  # 敌人
            AI 选行动 + 目标
            execute_action(battler, action, targets)

execute_action(battler, action, targets):
    time_scale = 0.0（暂停所有充能）
    执行 action.execute(battler, targets) 协程
    battler.readiness = action.readiness_saved（重置充能进度）
    检查胜利/失败条件
    time_scale = 1.0（恢复）
```

### 三档时间流速

| 状态 | time_scale | 表现 |
|------|-----------|------|
| 正常充能 | 1.0 | 所有 battler 正常涨条 |
| 玩家选行动 | 0.05 | 时间极慢，敌人条几乎不动但未停止 |
| 执行行动 | 0.0 | 完全暂停，播放行动动画 |

### readiness_saved 机制（替代能量限制）

由于无能量系统，技能限制通过行动后的剩余 readiness 控制：

| 行动 | readiness_saved | 再充能时间 |
|------|----------------|-----------|
| 普攻 | 30 | 充到 100 → 70 就满了 |
| 技能 | 0 | 完全重新充能 |
| 防御 | 50 | 只差 50 就能再动 |

---

## 六、UI 交互流程

```
1. 战斗开始
   → TurnBar 渐入，所有图标从左向右开始移动
   → PlayerBattlerList 显示我方 3 人 HP

2. 某玩家 battler readiness ≥ 100
   → TurnBar 对应图标闪烁
   → 时间变慢 (0.05x)
   → ActionMenu 从底部滑入
   → 显示：攻击 / 技能1 / 技能2 / ... / 防御

3. 玩家点击"攻击"（或某个技能）
   → ActionMenu 收起
   → TargetingCursor 覆盖画面
   → 可点击的敌人高亮（蓝色边框）
   → 不可点击的变暗

4. 玩家点击目标
   → 行动执行动画：
       角色向目标移动 → 攻击动作 → 目标受击闪白 → 伤害飘字 → 角色回原位
   → readiness 重置
   → 时间恢复正常 (1.0x)
   → TurnBar 图标回到左侧，重新充能

5. 敌人 battler readiness ≥ 100
   → AI 自动选行动/目标
   → 执行类似动画（敌人移动过来攻击玩家）

6. 一方全灭
   → 胜利：XP 结算 → Dialogic 战后演出 → 返回日程
   → 失败：死亡记录 → 返回日程
```

---

## 七、技能 → Action 映射

| .tres 文件 | skill_type | BattlerAction 子类 | 备注 |
|-----------|-----------|-------------------|------|
| weapon_attack | damage | `AttackBattlerAction` | readiness_saved=30，普攻 |
| weapon_skill | damage | `AttackBattlerAction` | |
| danmaku_rensha | damage | `AttackBattlerAction` | 多段 hit_count = 3 + AGI/5 |
| block_smash | damage | `AttackBattlerAction` | 3 段固定 |
| dream_seal | damage | `AttackBattlerAction` | 高威力 |
| yanling_spell | damage | `AttackBattlerAction` | stat_scale = MAG |
| heal_field | heal | `HealBattlerAction` | 全队 + HoT |
| boil_cabbage | heal | `HealBattlerAction` | 全队 |
| cat_lick | heal | `HealBattlerAction` | 单体 |
| calc_boost | buff | `ModifyStatsBattlerAction` | STR+5 |
| overclock_link | buff | `ModifyStatsBattlerAction` | 全队 TEC+4 |
| summon_world_book | special | `SpecialBattlerAction` | 额外 MAG 伤害 |

ActionFactory 读取 SkillData 中的 `skill_type`、`target_type`、`stat_scale`、`power` 等字段，动态创建对应的 BattlerAction 实例。

---

## 八、战斗流程（完整生命周期）

```
Schedule: 编队确定（formation_selected + battle_type）
    ↓
MainScene: _transition_to_battle()
    ↓ 淡入
CombatArena.start(squad, encounter)
    ├─ 从 PartyData 角色 → 创建 3 个 PlayerBattler 节点
    ├─ 从 EnemyTemplate 资源 → 创建 N 个 EnemyBattler 节点
    ├─ 整理 BattlerList
    ├─ 初始化 TurnBar / PlayerBattlerList / ActionMenu
    └─ ActiveTurnQueue.is_active = true → ATB 循环开始
    ↓
ATB 循环（若干次充能→行动→充能）
    ↓
BattlerList 检测一方全灭 → combat_finished
    ↓
CombatArena._on_battle_ended({won, exp, gold})
    ├─ 胜利: 结算 XP → 2s 延迟
    │   → GameState.set_game_phase("vn")
    │   → DialogicBridge.start_timeline("battle_results.dtl", scene_id)
    │   → Dialogic 演出 → 返回日程
    └─ 失败: GameState.record_death()
        → 2.5s 延迟 → GameState.set_game_phase("schedule")
```

---

## 九、Battler 动画

由于使用 Battler Sprite（小人）而非立绘，行为效果如下：

| 事件 | 动画 |
|------|------|
| ATB 充能中 | 待机呼吸 |
| 轮到行动 | 高亮/闪烁 |
| 攻击 | 向目标移动(Tween, 0.25s) → 攻击动画 → 回原位(Tween) |
| 受击 | 闪白 + 后仰 |
| 治疗 | 绿色光效 |
| 阵亡 | 淡出 |
| 胜利 | 跳跃/庆祝 |
| MISS | 目标闪避动作 |

---

## 十、数据流

```
PartyData.CharacterData
  ↓ init_from_character()
BattlerStats (Resource)
  ├─ max_health = 100 + VIT×15×(1+(Lv-1)×0.1)
  ├─ attack = STR
  ├─ defense = VIT
  ├─ speed = AGI
  ├─ hit_chance = 80 + TEC×2
  └─ health = max_health

SkillData.tres
  ↓ ActionFactory.from_skill_data()
BattlerAction (Resource)
  ├─ target_scope → 从 target_type 映射
  ├─ base_power → 从 power 字段
  ├─ stat_scale → 从 stat_scale 字段
  ├─ hit_count → 从 hit_count 字段
  └─ readiness_saved → 0（技能）/ 30（普攻）

GameState
  └─ formation_squad → 哪些角色参战
  └─ battle_type → 决定加载哪个 EncounterData
```

---

## 十一、增量实施计划

| 步骤 | 内容 | 估计时间 |
|------|------|---------|
| 1. 准备阶段 | BattlerStats, EnemyTemplate, EncounterData + .tres 文件, PartyData 扩展 | 1-2h |
| 2. 核心框架 | BattlerAction 基类及 4 个子类, ActionFactory, Battler, BattlerList, ActiveTurnQueue | 3-4h |
| 3. 核心 UI | TurnBar, BattlerIcon, PlayerBattlerList, BattlerEntry | 2-3h |
| 4. 行动 UI | ActionMenu, TargetingCursor, DamageLabel, ActionDescription | 2-3h |
| 5. 战斗容器 | CombatArena.gd + .tscn, 信号连接, 完整战斗循环 | 2-3h |
| 6. 集成 | MainScene 改造, 完整流程测试, 战后 Dialogic 联动 | 1-2h |
| 7. 收尾 | 删除旧文件, 数值平衡, 视觉细化 | 2-3h |

**总计：13-20 小时**

---

## 十二、注意事项

1. **无能量系统**：技能在战斗中免费使用，由 readiness_saved 控制技能频率
2. **旧文件可删**：BattleController.gd / BattleUI.gd / SkillProcessor.gd / battle.tscn 全部删除
3. **MainScene 改动最小**：只改 `_create_battle_scene()` 和 `_get_enemies()` 两处
4. **ScheduleHub 无需改动**：编队→战斗的流程已正确
5. **保存兼容**：战斗没有跨存档持久状态，无兼容问题
6. **Dialogic 联动**：战后流程与现有逻辑一致，直接复用 DialogicBridge
