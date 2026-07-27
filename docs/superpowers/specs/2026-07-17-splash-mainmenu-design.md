# 启动画面 + 主菜单界面 设计文档

> 日期：2026-07-17 | 状态：已确认 | 参照旧版 Ren'Py `gui.rpy` / `screens.rpy`

---

## 一、范围

实现启动画面（Splash）和主菜单（MainMenu）两个场景，布局和动画参照旧版 Ren'Py 设计。

---

## 二、场景流程

```
splash.tscn (3张图2秒间隔淡入淡出) → main_menu.tscn → "开始" → main.tscn (序章)
```

---

## 三、启动画面

- 3张图：splash_slide_01/02/03.png
- 每张2秒，Tween 淡出→换图→淡入
- 点击可跳过

## 四、主菜单

### 布局
- 全屏背景 `main_menu.png`
- 左侧 7 个图片按钮垂直排列
- 右侧 5 个角色立绘交错分布，依次淡入

### 按钮映射
| 按钮 | idle | hover | 动作 |
|---|---|---|---|
| 开始 | icon_start_idle.png | kaishi_gaoliang.png | 切换到 main.tscn |
| CG | icon_cg_idle.png.png | cg_gaoliang.png | 预留 |
| 读取 | duqu.png | duqu_gaoliang.png | 预留 |
| 设置 | shezhi.png | shezhi_gaoliang.png | 预留 |
| 关于 | guanyu.png | guanyu_gaoliang.png | 预留 |
| 帮助 | bangzhu.png | bangzhu_gaoliang.png | 预留 |
| 退出 | tuichu.png | tuichu_gaoliang.png | get_tree().quit() |

### 角色立绘
| 位置 | 角色 | 图片 |
|---|---|---|
| 左上 | 陈立 | chenli_smile.png |
| 右上 | 哈基佑 | hajiyou.png |
| 左下 | 牢聪 | laocong_xiuxi.jpg |
| 右下 | 哈基龙 | hajilong_smile.png |
| 中间 | 牢马 | laoma_shangbanshen.png |

### 动画
- 按钮 hover: Tween 上浮 10px
- 角色立绘: 依次从下方淡入，间隔 0.25 秒

---

## 五、文件清单

- `scenes/menu/splash.tscn` + `Splash.gd`
- `scenes/menu/main_menu.tscn` + `MainMenu.gd`
- 修改 `project.godot`: main_scene → splash.tscn
