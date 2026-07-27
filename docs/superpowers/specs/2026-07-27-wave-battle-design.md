# 波次战斗系统 — 设计文档

**日期：** 2026-07-27
**状态：** 已确认

## 问题

战斗场景中怪物过多时（如 `special_day30` 有 10 个敌人），3列网格排列导致怪物溢出屏幕边界，用户无法选中底部怪物的目标光标，造成卡关。

## 解决方案

引入波次（Wave）系统：每场战斗由多个波次组成，每波在场敌人数量有限（由 `max_enemies_on_field` 控制），消灭当前波后自动刷新下一波。

---

## 一、数据结构

### 1.1 新增 WaveData Resource

文件：`scenes/battle/encounters/WaveData.gd`

```gdscript
class_name WaveData extends Resource
@export var enemy_ids: Array[String] = []    # 本波敌人ID列表
@export var enemy_counts: Array[int] = []     # 对应数量
@export var wave_message: String = ""         # 可选波次提示文字
```

### 1.2 修改 EncounterData

- 废弃 `enemy_ids` 和 `enemy_counts` 字段
- 新增 `waves: Array[WaveData]` 和 `max_enemies_on_field: int`

```gdscript
@export var waves: Array[WaveData] = []
@export var max_enemies_on_field: int = 4
```

### 1.3 现有 Encounter 迁移

所有 `.tres` 文件改为 waves 格式。示例 — `special_day30.tres`：
- 旧：10个敌人一次性出场
- 新：3波，每波最多4个，Boss 最后出场

---

## 二、CombatArena 改动

### 2.1 流程

```
start()
  ├── 记录 waves、max_enemies_on_field
  ├── current_wave = 0
  ├── 创建玩家 battler
  └── _spawn_wave(0)

_spawn_wave(index)
  ├── 读取 WaveData
  ├── 在右侧排列（≤ max_enemies_on_field 个）
  ├── 添加到 battler_list.enemies
  ├── 连接死亡信号
  └── 显示 wave_message（如有）

_on_wave_cleared()
  ├── current_wave += 1
  ├── 有下一波 → 延迟 0.8s → _spawn_wave()
  └── 无下一波 → 触发 _on_battle_ended()
```

### 2.2 敌人位置排列

以 `max_enemies_on_field` 决定网格，位于右侧 (700, 120) 区域。

### 2.3 波次切换

切换期间 `turn_queue.is_active = false`，新敌人就位后恢复。

---

## 三、BattlerList 改动

- `_check_enemy_status()`：当前波敌人全灭 → 发射 `wave_cleared` 信号
- `battlers_downed` 仅在全部波次完成后发射

---

## 四、TurnQueue 适配

- 新增 `pause()` / `resume()` 方法，波次切换时暂停
- 新敌人自动加入 readiness 充能循环

---

## 五、不变部分

- Battler / BattlerStats / 技能 / Buff-Debuff 系统
- ActionFactory / BattlerAction 体系
- UI 面板（TurnBar, PlayerList, ActionMenu, DamageLabel, TargetingCursor）
- 战后剧情流程（`_play_special_aftermath`）
- Boss AI（召唤/吃汉堡机制保持）

---

## 六、Encounter 迁移清单

| 文件 | 旧敌人总数 | 建议 waves |
|------|-----------|-----------|
| `default_encounter.tres` | 3 | 1波，max=4 |
| `explore_encounter.tres` | 7 | 2波，max=4 |
| `quest_encounter.tres` | 8 | 2波，max=4 |
| `special_day5.tres` | 7 | 2波，max=4 |
| `special_day10.tres` | 7 | 2波，max=4 |
| `special_day15.tres` | 10 | 2-3波，max=4 |
| `special_day20.tres` | — | — |
| `special_day25.tres` | 8 | 2波，max=4 |
| `special_day30.tres` | 10 | 3波，max=4 |
