### Task 9: 收尾 — 旧文件删除 + 最终验证

- [ ] **Step 1: Verify no remaining references to old files**

```bash
grep -r "BattleController" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to BattleController"
grep -r "BattleUI" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to BattleUI"
grep -r "SkillProcessor" E:/gamedemo1/scenes/ --include="*.gd" || echo "No references to SkillProcessor"
grep -r "battle.tscn" E:/gamedemo1/ --include="*.gd" --include="*.tscn" || echo "No references to old battle.tscn"
```

- [ ] **Step 2: Full game flow test**

1. 启动游戏 → 序章剧情（Dialogic 正常）
2. 进入日程 → 查看角色状态
3. 编队 3 人 → 战斗
4. ATB 充能 → TurnBar 显示 → 选技能 → 攻击/治疗/增益
5. 敌人行动
6. 胜利 → Dialogic → 返回日程
7. 测试失败场景
8. BOSS 战测试召唤 + 吃汉堡机制
