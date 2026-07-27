### Task 7: 集成 — MainScene 改造 + 旧文件删除

**Files:**
- Modify: `scenes/MainScene.gd`
- Delete: `scenes/battle/BattleController.gd`
- Delete: `scenes/battle/BattleUI.gd`
- Delete: `scenes/battle/SkillProcessor.gd`
- Delete: `scenes/battle/battle.tscn`

- [ ] **Step 1: Modify MainScene.gd**

Replace `_create_battle_scene()` and `_get_enemies()`:

```gdscript
# Replace _create_battle_scene() body entirely:
func _create_battle_scene() -> void:
    var btl_res: Resource = load("res://scenes/battle/battle_main.tscn")
    if btl_res:
        battle_scene = btl_res.instantiate()
        battle_scene.visible = false
        add_child(battle_scene)

        var squad: Array[String] = GameState.formation_squad
        if squad.is_empty():
            var chars := PartyData.get_all_character_ids()
            for i in min(3, chars.size()):
                squad.append(chars[i])

        var encounter: EncounterData = _get_encounter(GameState.battle_type)

        if battle_scene.has_method("start"):
            battle_scene.start(squad, encounter)
        else:
            _show_error("Battle scene missing start method")
    else:
        _show_error("无法加载战斗场景")


# Replace _get_enemies() entirely:
func _get_encounter(battle_type: String) -> EncounterData:
    return PartyData.get_encounter(battle_type)


# Remove the entire old _get_enemies() method body
```

- [ ] **Step 2: Delete old battle files**

```bash
rm "E:/gamedemo1/scenes/battle/BattleController.gd"
rm "E:/gamedemo1/scenes/battle/BattleUI.gd"
rm "E:/gamedemo1/scenes/battle/SkillProcessor.gd"
rm "E:/gamedemo1/scenes/battle/battle.tscn"
```

- [ ] **Step 3: Full integration test**

Run the project. Create a new game or load save. Verify:
1. Schedule → 编队 → 战斗 → 进入战斗场景
2. ATB 充能、TurnBar 显示、角色行动
3. 选行动 → 选目标 → 执行（动画 + 伤害）
4. 敌人 AI 行动
5. 胜利 → 经验结算 → Dialogic 剧情 → 返回日程
6. 失败 → 返回日程

---

