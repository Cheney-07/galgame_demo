# 日程+战斗系统完整设计 Spec

> 日期：2026-07-18 | 状态：已确认 | 方案：Plan B — Resource 驱动重构

---

## 一、架构总览

```
游戏启动
  ├── Autoload 初始化
  │     ├── GameState     — 章节/天数/AP/阶段管理（已有，小幅扩展）
  │     ├── PartyData     — 重写：从 .tres 加载角色模板，运行时实例化
  │     ├── StoryFlags    — 剧情标记/好感度/结局条件（已有）
  │     ├── DialogueManager — 对话系统（已有，添加 phase_change 支持）
  │     └── SaveManager   — 存档序列化（已有，适配新 PartyData 结构）
  │
  ├── 资源层（Resource .tres 文件）
  │     ├── CharacterTemplate  — 角色初始值/成长率/技能池/立绘
  │     ├── SkillData          — 技能定义（伤害公式/消耗/效果）
  │     └── ItemData           — 装备/道具定义
  │
  ├── 场景层
  │     ├── Splash → MainMenu（已有）
  │     ├── MainScene（场景管理器，已有）
  │     │     ├── VnScene（已有，VN 对话 + 序章）
  │     │     ├── ScheduleHubScene（新建）
  │     │     │     ├── 角色立绘交互区
  │     │     │     ├── 动作面板
  │     │     │     ├── CharacterPanel（队员详情）
  │     │     │     └── FormationPanel（编队）
  │     │     └── BattleScene（新建）
  │     │           ├── BattleController（回合逻辑）
  │     │           ├── BattleUI（侧视对决渲染）
  │     │           └── SkillProcessor（技能计算）
  │     └── 日程子面板（训练/交流/做饭/探索/委托/购物/休息）
  │
  └── 素材层
        ├── 日程背景、战斗背景
        ├── 角色立绘（已有6人）
        ├── 敌人立绘
        ├── 技能/属性/装备图标
        └── BGM/SFX（可选）
```

---

## 二、Resource 系统设计

### 2.1 CharacterTemplate（角色模板 .tres）

每个角色一个 `.tres` 文件，放在 `resources/characters/`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `char_id` | String | 内部ID，如 "chenli" |
| `char_name` | String | 中文名，如 "陈立" |
| `portrait_path` | String | 立绘路径，如 "res://images/chenli_smile.png" |
| `base_stats` | Dictionary | 初始六维 {"STR":12, "MAG":15, "VIT":8, "AGI":15, "TEC":12, "CHA":8} |
| `growth_rates` | Dictionary | 升级成长率 {"STR":0.8, "MAG":1.5, ...} |
| `skill_pool` | Array[String] | 初始解锁技能ID列表 |
| `battle_role` | String | 战斗定位："attacker" / "caster" / "support" / "healer" / "tank" |
| `description` | String | 角色一句话描述 |

**6个角色初始值设定：**

| 角色 | STR | MAG | VIT | AGI | TEC | CHA | 定位 |
|------|-----|-----|-----|-----|-----|-----|------|
| 主角 | 10 | 10 | 10 | 10 | 10 | 10 | 均衡（武器决定） |
| 陈立 | 8 | 15 | 8 | 16 | 12 | 8 | 远程多段 |
| 哈基佑 | 10 | 15 | 10 | 10 | 10 | 12 | 输出/辅助切换 |
| 牢聪 | 7 | 16 | 8 | 10 | 15 | 10 | 召唤师 |
| 牢马 | 8 | 12 | 10 | 10 | 16 | 10 | 辅助增益 |
| 牢翔 | 7 | 12 | 12 | 12 | 10 | 15 | 治疗 |
| 哈基龙 | 18 | 5 | 13 | 8 | 7 | 8 | 物理输出 |

### 2.2 SkillData（技能模板 .tres）

每个技能一个 `.tres`，放在 `resources/skills/`。

| 字段 | 类型 | 说明 |
|------|------|------|
| `skill_id` | String | 内部ID，如 "danmaku_rensha" |
| `skill_name` | String | 显示名，如 "弹幕连射" |
| `skill_type` | String | "damage" / "heal" / "buff" / "debuff" / "special" |
| `target_type` | String | "single_enemy" / "all_enemies" / "single_ally" / "all_allies" / "self" |
| `power` | float | 威力倍率（伤害=ATK×power，治疗=MAG×power） |
| `cost_mp` | int | 消耗（预留，目前用次数制） |
| `cost_hp` | int | HP消耗（部分技能） |
| `stat_scale` | String | 伤害关联属性："STR" / "MAG" / "AGI" / "TEC" / "CHA" |
| `effects` | Array[Dictionary] | Buff/Debuff 效果列表 |
| `hit_count` | int | 多段攻击段数（陈立专属，默认1） |
| `cooldown` | int | 冷却回合数（0=无冷却） |
| `description` | String | 技能描述文字 |
| `icon_path` | String | 技能图标路径 |

**技能效果（effects）格式：**
```
{ "type": "buff", "stat": "STR", "value": 5, "duration": 3, "target": "self" }
{ "type": "debuff", "stat": "VIT", "value": -3, "duration": 2, "target": "enemy" }
{ "type": "hot", "value": 5, "duration": 3 }  # 持续回血
{ "type": "dot", "value": 3, "duration": 3 }  # 持续伤害
```

### 2.3 ItemData（道具/装备 .tres）— 预留，本期不做

---

## 三、PartyData 重写设计

### 3.1 CharacterData 运行时类

```
class CharacterData:
    # 身份
    var char_id: String
    var char_name: String
    var portrait_path: String
    
    # 等级
    var level: int = 1
    var current_exp: int = 0
    
    # 属性
    var stats: Dictionary = {}       # 当前值
    var growth_rates: Dictionary = {}# 成长率
    
    # 战斗
    var current_hp: int = 100
    var max_hp: int = 100
    var skills: Array[String] = []   # 已解锁技能ID列表
    var equipment: Dictionary = {}
    var active_buffs: Array = []
    
    # 养成
    var affection: int = 0
    
    # 方法
    func init_from_template(template: CharacterTemplate)
    func get_stat(stat: String) -> int  # 含装备+buff
    func get_base_stat(stat: String) -> int  # 不含加成
    func add_exp(amount: int) -> bool
    func level_up() -> void
    func take_damage(amount: int) -> void
    func heal(amount: int) -> void
```

### 3.2 PartyData 职责变化

- `_ready()` 时从 `resources/characters/` 加载所有 `.tres` 模板
- 按模板创建 CharacterData 实例
- 提供查询和管理方法
- 序列化/反序列化时保存运行时状态（等级/经验/好感度/已解锁技能），不保存模板数据

---

## 四、日程主界面（ScheduleHub）设计

### 4.1 布局

```
┌──────────────────────────────────────────────────┐
│  [顶部栏] 序章 | 第N天 | 早晨    剩余行动力: 7/10 │
├──────────────────────────────────────────────────┤
│                                                    │
│   [背景场景]                                       │
│                                                    │
│   [陈立]  [哈基佑]  [牢聪]                         │
│   (立绘)  (立绘)    (立绘)      ← 点击选中        │
│                                                    │
│   [牢马]  [牢翔]  [哈基龙]                         │
│   (立绘)  (立绘)    (立绘)                         │
│                                                    │
├──────────────────────────────────────────────────┤
│ [训练] [交流] [做饭] [探索] [委托] [购物] [休息]    │
│                                          [队员] [战斗]│
└──────────────────────────────────────────────────┘
```

- 角色立绘 2行×3列，锚点定位
- 尺寸约 180×320 每个
- 选中后高亮（金色边框）
- 未招募角色灰色半透明

### 4.2 操作流程

**训练**：点击[训练]→选中角色→确认→AP-3→属性+2~3→Toast  
**交流**：点击[交流]→选中角色→确认→AP-1→好感度+1→每角色每日上限3次  
**做饭**：点击[做饭]→选中角色→确认→AP-2→效果  
**探索/委托**：点击→打开编队面板→选3人→确认→AP-3→（未来接战斗/掉落）  
**购物**：0AP，打开商店占位面板  
**休息**：确认→黑屏过渡→日期+1→AP恢复10  

### 4.3 队员面板（CharacterPanel）

点击[队员]按钮打开覆盖面板：

- 横向滑动/翻页卡片，每页显示1个角色
- 左侧: 角色大半身立绘
- 右侧: 等级 + 属性列表（STR/MAG/VIT/AGI/TEC/CHA 的数值 + 进度条）
- 底部: 好感度、已解锁技能列表
- 左右箭头切换角色

### 4.4 编队面板（FormationPanel）

点击[探索]/[委托]/[战斗]时打开：

- 标题："选择出战队员（3人）"
- 6个角色卡片（头像+名字+等级），点击选中/取消
- 已选3人高亮，最多选3人
- 确认按钮 → 开始对应活动
- 返回按钮 → 取消

---

## 五、战斗系统设计

### 5.1 布局（侧视对决）

```
┌──────────────────────────────────────────────────┐
│  [战斗BGM播放中]            [回合数/敌人信息]      │
├──────────────────────────────────────────────────┤
│                                                    │
│  [角色A立绘]        [敌人A]  [敌人B]  [敌人C]     │
│  [角色B立绘]          (缩小立绘×N)                 │
│  [角色C立绘]          [HP条] [HP条] [HP条]        │
│                                                    │
│  [HP条+名字]                                        │
│                                                    │
├──────────────────────────────────────────────────┤
│  [当前行动角色名]                                   │
│  [攻击] [技能] [道具] [防御]                       │
│  选择目标: [敌人A] [敌人B] [敌人C]                 │
└──────────────────────────────────────────────────┘
```

### 5.2 回合流程

```
1. 回合开始
2. 按AGI从高到低排列行动顺序（含敌方）
3. 轮到玩家角色 → 选指令（攻击/技能/道具/防御）→ 选目标 → 确认
4. 轮到敌人 → AI自动行动
5. 所有人行动完毕 → 回合结束
6. 检查胜利/失败条件
7. 下一回合
```

### 5.3 战斗数值公式

```
物理伤害 = (攻击者STR × 1.5 + 技能威力) × (1 - 防御者VIT/100)
魔法伤害 = (攻击者MAG × 1.5 + 技能威力) × (1 - 防御者VIT/80)

治疗量   = 攻击者MAG × 技能威力 × (1 + CHA/50)

命中率   = 基础80% + TEC × 1.5%
暴击率   = 5% + TEC × 1%

HP 公式  = 100 + VIT × 15
闪避率   = 5% + AGI × 1%
行动顺序 = 按AGI降序，同AGI随机
```

### 5.4 Buff/Debuff 系统

Buff/Debuff 以字典形式存在角色的 `active_buffs` 数组中：

```
{
    "id": "atk_up_1",
    "name": "算力增幅",
    "stat": "STR",
    "value": 5,
    "duration": 3,    # 剩余回合
    "icon": "..."
}
```

每回合结束 duration-1，归零移除。同 stat 的 Buff 叠加（取最高值）。

### 5.5 6角色技能表

**主角**（武器驱动，按当前武器获得技能）：
- 普攻（武器类型决定）
- 技能1（武器决定）
- 无技能2

**陈立**（远程多段输出）：
- 普攻：灵符射击 — 单体 STR×1.0
- 技能1：弹幕连射 — 单体 STR×0.4 × Hit数(Hit = 3 + AGI/5)
- 技能2：梦想封印 — 单体 STR×2.5，CD 3回合

**哈基佑**（双形态切换）：
- 普攻：物理攻击 — 单体 STR×1.0（攻击形态）/ 单体 STR×0.6（辅助形态）
- 技能1：言灵术 — 单体 MAG×2.0（攻击形态可用）
- 技能2：煮白菜 — 全队回复 MAG×0.5（辅助形态可用）
- 机制：战斗中消耗1回合切换形态

**牢聪**（召唤师）：
- 普攻：书页飞击 — 单体 MAG×1.0
- 技能1：召唤·随机世界书 — 随机召唤助战2-3回合
- 召唤池随等级解锁模板
- 无技能2

**牢马**（辅助增益）：
- 普攻：算力冲击 — 单体 STR×0.8
- 技能1：算力增幅 — 单体 ATK↑ STR+5，持续3回合
- 技能2：超频链接 — 全队 TEC↑ TEC+4，持续3回合
- 羁绊：牢聪在场时，牢聪召唤数+1

**牢翔**（治疗）：
- 普攻：小猫抓挠 — 单体 STR×0.6
- 技能1：小猫舔舔 — 单体回血 CHA×0.8
- 技能2：治愈领域 — 全队持续回血3回合，每回合 CHA×0.3
- 回复量关联CHA

**哈基龙**（物理输出）：
- 普攻：土块砸击 — 单体 STR×1.3
- 技能1：方块连击 — 单体 STR×0.8 × 3段
- 无技能2

### 5.6 特殊敌人机制

**邪恶汉堡牢聪**：击败获得大量经验；失败触发"黄毛牢聪结局"  
**便便**：倒计时3回合自爆→全队大伤害，需在时限内击杀

### 5.7 战斗失败处理

- 选择"复活继续"→ `GameState.record_death()`，重新尝试战斗
- 选择"放弃"→ 触发坏结局
- 一周目使用过复活→ 锁死结局（不可进二周目）

---

## 六、数据流

```
训练 → PartyData.modify_stat() → 属性↑
交流 → PartyData.add_affection() → 好感度↑
日程结束 → GameState.advance_day() → AP重置
到达战斗日 → GameState.set_game_phase("battle")
战斗 → SkillProcessor 读取 PartyData 属性 → 计算伤害/治疗 → 经验/金币
存档 → SaveManager 序列化 GameState + PartyData + StoryFlags
读档 → PartyData 从模板重建+覆盖运行时数据
```

---

## 七、文件清单

### 新建文件（Resource）

| 文件 | 说明 |
|------|------|
| `resources/characters/character_template.gd` | CharacterTemplate Resource 类定义 |
| `resources/characters/chenli.tres` | 陈立 |
| `resources/characters/hajiyou.tres` | 哈基佑 |
| `resources/characters/laocong.tres` | 牢聪 |
| `resources/characters/laoma.tres` | 牢马 |
| `resources/characters/laoxiang.tres` | 牢翔 |
| `resources/characters/hajilong.tres` | 哈基龙 |
| `resources/characters/protagonist.tres` | 主角 |
| `resources/skills/skill_data.gd` | SkillData Resource 类定义 |
| `resources/skills/*.tres` | 各技能定义 |

### 新建文件（场景/脚本）

| 文件 | 说明 |
|------|------|
| `scenes/schedule/ScheduleHub.gd` | 重写日程主界面 |
| `scenes/schedule/CharacterPanel.gd` | 队员详情面板 |
| `scenes/schedule/FormationPanel.gd` | 编队选择面板 |
| `scenes/battle/BattleController.gd` | 战斗回合逻辑 |
| `scenes/battle/BattleUI.gd` | 战斗界面渲染 |
| `scenes/battle/SkillProcessor.gd` | 技能计算引擎 |
| `scenes/battle/battle.tscn` | 战斗场景 |

### 修改文件

| 文件 | 变更 |
|------|------|
| `autoload/PartyData.gd` | 重写，从 .tres 加载模板 |
| `autoload/GameState.gd` | 添加 daily_talks 追踪（已完成） |
| `autoload/DialogueManager.gd` | 添加 phase_change 支持（已完成） |
| `autoload/SaveManager.gd` | 适配新 PartyData 结构 |
| `scenes/MainScene.gd` | 场景管理器（已完成） |

### 需要你提供的素材

| 素材 | 用途 | 放哪里 | 规格 |
|------|------|--------|------|
| 日程主界面背景 | 角色陈列背景 | `images/schedule_bg.png` | 1920×1080 |
| 战斗背景 | 侧视对决背景 | `images/battle_bg.png` | 1920×1080 |
| 敌人立绘 × N | 战斗中显示 | `images/enemies/` | 透明PNG，~400×600 |
| 技能图标 | 技能列表显示 | `images/icons/skills/` | 64×64 PNG |
| 属性图标 × 6 | STR/MAG/VIT/AGI/TEC/CHA | `images/icons/stats/` | 32×32 PNG |
| 战斗BGM | 战斗背景音乐 | `audio/bgm_battle.ogg` | 可循环 |
| 技能SFX | 技能音效 | `audio/sfx/` | 短音频 |

**立即可复用**：6个角色立绘已在 `images/`、菜单背景 `main_menu.png` 可暂替代。

---

## 八、实现顺序

```
Phase A: Resource 系统
  1. CharacterTemplate Resource 类
  2. 6+1 个角色 .tres 文件
  3. SkillData Resource 类
  4. 技能 .tres 文件
  5. 重写 PartyData.gd

Phase B: 日程主界面重做
  1. ScheduleHub 主界面（背景+角色立绘排列+动作按钮）
  2. CharacterPanel（队员详情）
  3. FormationPanel（编队）
  4. 训练/交流/做饭/休息 子面板

Phase C: 战斗系统
  1. SkillProcessor（伤害计算引擎）
  2. BattleController（回合逻辑+AGI排序+AI）
  3. BattleUI（侧视布局渲染）
  4. 特殊敌人机制（汉堡牢聪/便便）
  5. 战斗→日程过渡

Phase D: 素材替换 + 打磨
  1. 替换用户提供的素材
  2. 动画/Tween 打磨
  3. 平衡性调整
```

---

## 九、不做的内容（本期 Scope 外）

- 装备系统（预留 .tres 定义，运行时装备槽已留）
- 购物/商店完整实现（占位）
- LLM 结局判定（阶段5）
- 二周目（阶段5）
- BGM/SFX 播放系统（预留 hook，不实现播放器）
- 技能动画特效（用文字+简单Tween代替）
