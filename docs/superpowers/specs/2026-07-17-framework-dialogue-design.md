# 黎明之诗·改 — 阶段1+2：基础框架 + 对话系统 设计文档

> 日期：2026-07-17 | 状态：已确认 | 基于 `2026-07-17-hybrid-rpg-vn-design.md`

---

## 一、范围

阶段1：Godot 基础框架（Autoload + Resource + 存档）
阶段2：对话系统（DialogueManager + VN场景 + 序章移植）

后续阶段（日程/战斗/结局/内容填充）不在本次范围内。

---

## 二、项目结构

```
gamedemo1/
├── scenes/
│   ├── vn/
│   │   ├── vn_scene.tscn          # 通用VN场景
│   │   └── VnScene.gd
│   └── menu/
│       └── title_screen.tscn      # 标题画面
├── autoload/
│   ├── GameState.gd               # 章节/天数/flag
│   ├── PartyData.gd               # 角色属性/技能/装备
│   ├── StoryFlags.gd              # 好感度/结局条件
│   ├── DialogueManager.gd         # 对话解析+信号
│   └── SaveManager.gd             # 存档序列化
├── resources/
│   ├── characters/                # 角色 Resource (.tres)
│   ├── skills/                    # 技能 Resource (.tres)
│   ├── items/                     # 道具/装备 Resource (.tres)
│   └── dialogue/
│       └── prologue.json          # 序章对话脚本
├── scripts/
│   ├── vn/
│   └── components/
└── images/                        # 现有素材
```

---

## 三、Autoload 单例

| 单例 | 职责 | 关键信号 |
|---|---|---|
| GameState | 章节、天数、时间段、AP | `chapter_changed`, `day_advanced` |
| PartyData | 6角色六维属性、等级、装备 | `stat_changed(role, stat, new_val)` |
| StoryFlags | 好感度字典、结局flag、选项历史 | `flag_set(flag_name)` |
| DialogueManager | 读JSON→逐行解析→发信号 | `line_emit(line_data)`, `scene_changed(bg)`, `dialogue_end` |
| SaveManager | 序列化/反序列化全部状态 | 无（被动调用） |

---

## 四、对话JSON格式

```json
{
  "scenes": [
    {
      "id": "scene_id",
      "bg": "res://images/bg_xxx.png",
      "lines": [
        { "type": "narration", "text": "普通旁白，显示在对话框内" },
        { "type": "narration_full", "text": "特殊旁白，全屏黑底居中" },
        { "type": "dialogue", "speaker": "哈基佑", "expression": "default", "text": "..." },
        { "type": "scene_change", "bg": "res://images/bg_yyy.png" },
        { "type": "bgm", "file": "xxx" },
        { "type": "sfx", "file": "xxx" },
        { "type": "jump", "target": "scene_id" },
        { "type": "choice", "choices": [
          { "text": "选项1", "next": "scene_a" },
          { "text": "选项2", "next": "scene_b" }
        ]}
      ]
    }
  ]
}
```

### 行类型

| type | 渲染位置 | 说明 |
|---|---|---|
| `narration` | 对话框内 | 普通旁白，点击继续 |
| `narration_full` | 全屏黑底居中 | 特殊氛围旁白，点击继续 |
| `dialogue` | 对话框内 | 显示说话人名字 + 切换立绘 |
| `scene_change` | — | 淡入淡出切换背景 |
| `bgm` | — | 切换BGM（音频待补充，预留） |
| `sfx` | — | 播放音效（音频待补充，预留） |
| `jump` | — | 跳转到指定场景 |
| `choice` | 选项按钮组 | 玩家选择后跳转 |

无打字机效果——文字直接全部显示。

---

## 五、VN场景节点结构

```
VnScene (CanvasLayer)
├── Background (TextureRect)          # 全屏背景 1920×1080
├── CharacterSprite (TextureRect)     # 立绘
├── DialogueBox (Panel)               # 底部对话框
│   ├── SpeakerLabel (Label)          # 说话人
│   ├── DialogueText (RichTextLabel)  # 对话正文
│   └── ContinueIndicator (Label)     # ▼ 继续提示
├── FullScreenOverlay (ColorRect)     # 特殊旁白全屏层
│   └── NarrationLabel (Label)        # 旁白文字
├── ChoicePanel (VBoxContainer)       # 选项按钮组
└── HistoryPanel (ScrollContainer)    # 回看面板（默认隐藏）
```

---

## 六、素材映射

### 角色立绘

| 文件 | 角色 | 表情 |
|---|---|---|
| `chenli_smile.png` | 陈立 | 微笑 |
| `chenli_attack.png` | 陈立 | 战斗 |
| `hajiyou.png` | 哈基佑 | 默认 |
| `haijiyou_jingya.png` | 哈基佑 | 惊讶 |
| `hajiyou_superised.png` | 哈基佑 | 惊讶2 |
| `laocong_xiuxi.jpg` | 牢聪 | 休息 |
| `laoma_shangbanshen.png` | 牢马 | 上半身 |
| `laoxiang.png` | 牢翔 | 默认（待添加） |
| `hajilong_smile.png` | 哈基龙 | 微笑 |
| `hajilong_beiying.png` | 哈基龙 | 背影 |

### 背景

| 文件 | 用途 |
|---|---|
| `bg tokyo_sunset.jpg` | 东京傍晚 |
| `bg sky_crack.png` | 天空裂开 |
| `bg light_pillar.png` | 光柱 |
| `bg altar_room.png` | 神殿祭坛 |
| `bg city_day.png` | 白天城市 |
| `main_menu.png` | 标题画面备用 |

### 敌人

| 文件 | 用途 |
|---|---|
| `xieehanbaolaocong.png` | 邪恶汉堡牢聪 |
| `smoker.png` | 通用敌人 |

### UI（已有点击按钮素材可复用）

`icon_start_idle.png` / `duqu.png` / `shezhi.png` / `guanyu.png` / `bangzhu.png` / `tuichu.png` 及其高亮版本

---

## 七、实施步骤

1. 创建 autoload/ 目录 + 5个单例脚本骨架
2. 配置 project.godot 注册 Autoload
3. 通过 Godot MCP 创建 vn_scene.tscn 节点树
4. 编写 VnScene.gd（信号响应、逐行渲染）
5. 编写 DialogueManager.gd（JSON解析、场景播放）
6. 转写序章文本 → prologue.json
7. 创建标题画面 title_screen.tscn
8. 运行测试 + 修复
