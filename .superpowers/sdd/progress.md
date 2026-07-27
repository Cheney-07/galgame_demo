Task 1: complete (no git, review by manual verify)
Task 2: complete (no git, review by manual verify)
Task 3: complete (no git, review by manual verify)
Task 4: complete (no git, review by manual verify)
Task 5: complete (no git, review by manual verify)
Task 6: complete (verify: project loads, 7 chars/12 skills/4 enemies/3 encounters)
Task 7: complete (verify: project loads clean, old files deleted)
ALL TASKS COMPLETE (plus bugfixes)

Task 1-9: all complete
Bugfix pass: Fixed space-vs-tab indentation across 14 battle .gd files
- class_name missing (ActionFactory)
- TargetScope bare references (ActionFactory)
- _process await deadlock (ActiveTurnQueue)
- battle_main.tscn not instancing CombatArena.tscn
- Mixed tab/space indentation (all action/queue/UI files)
- := type inference on Variant values
- preload → load for runtime resource resolution
