################################################################################
## CG 画廊系统
##
## 工作原理:
##   - 使用 Ren'Py 内置 Gallery 类 + unlock_image() 自动追踪
##   - 当脚本中执行 show/scene cg_xxx 时，CG 自动标记为"已解锁"
##   - 玩家可在主菜单/游戏内菜单进入画廊查看已解锁的 CG
##   - 也提供手动 cg_unlock("id") 函数供脚本中的自定义场景使用
################################################################################

init python:
    # ---- CG 元数据 ----
    # (唯一ID, 图片标签, 显示标题)
    CG_LIST = [
        ("elsia_knockout",     "cg elsia knockout",         "艾尔希亚·击倒"),
        ("noel_bracelet",      "cg noel bracelet",          "诺艾尔·手环"),
        ("vespera_moonlight",  "cg vespera moonlight",      "薇丝佩拉·月光"),
        ("vespera_sword_drop", "cg vespera sword_drop",     "薇丝佩拉·落剑"),
        ("selena_sunset",      "cg selena sunset",          "瑟琳娜·黄昏"),
        ("selena_balcony",     "cg selena balcony oath",    "瑟琳娜·阳台誓约"),
        ("lyra_training",      "cg lyra training last night", "莱拉·训练之夜"),
        ("true_end_vigil",     "cg true end vigil",         "真结局·守夜"),
        ("bad_end_silhouette", "cg bad end silhouette",     "坏结局·剪影"),
        ("all_heroines",       "cg all heroines united",    "全员集结"),
        ("selena_hands",       "cg selena holding hands",   "瑟琳娜·牵手"),
    ]

    # 建立 id → title 映射
    cg_title = {}
    for cid, cimg, ctitle in CG_LIST:
        cg_title[cid] = ctitle

    # 手动解锁追踪 (配合 unlock_image，用于 debug 或自定义解锁逻辑)
    if persistent._cg_manual is None:
        persistent._cg_manual = set()

    def cg_unlock(cg_id):
        """手动解锁指定CG。参数为CG_LIST中定义的ID，如 cg_unlock('elsia_knockout')"""
        if cg_id not in persistent._cg_manual:
            persistent._cg_manual.add(cg_id)
            renpy.notify("CG已解锁！")

    # id → image 映射，供快速查找
    _cg_image_map = {cid: cimg for cid, cimg, ctitle in CG_LIST}

    def cg_is_unlocked(cg_id):
        """检查CG是否已解锁 (自动或手动)"""
        return cg_id in persistent._cg_manual or renpy.seen_image(
            _cg_image_map.get(cg_id, "")
        )

    def cg_unlock_all():
        """一键解锁全部CG (调试用)"""
        for cid, cimg, ctitle in CG_LIST:
            persistent._cg_manual.add(cid)
        renpy.notify("所有CG已解锁！")

    # ---- 构建 Gallery 对象 ----
    gallery = Gallery()
    gallery.transition = dissolve

    for cid, cimg, ctitle in CG_LIST:
        gallery.button(cid)
        gallery.unlock_image(cimg)  # 图片被 show/scene 过即自动解锁


# ---- 锁定占位图 ----
image gallery_locked = Fixed(
    Solid("#1a1a1a"),
    Text("{color=#555}{size=48}???{/size}{/color}", align=(0.5, 0.5)),
    xysize=(400, 225),
)


# ---- CG 画廊界面 ----
screen cg_gallery_screen():
    tag menu
    add gui.game_menu_background
    use game_menu(_("CG 画廊"), scroll="viewport"):
        vpgrid:
            cols 3
            spacing 24
            draggable True
            mousewheel True
            xfill True
            yinitial 0.0

            for cid, cimg, ctitle in CG_LIST:
                $ unlocked = cg_is_unlocked(cid)
                $ clr = "#ccc" if unlocked else "#555"
                frame:
                    background None
                    xpadding 0
                    ypadding 0
                    vbox:
                        spacing 8
                        add gallery.make_button(
                            cid,
                            "gallery_locked",
                            xsize=400,
                            ysize=225,
                        )
                        text ctitle:
                            xalign 0.5
                            size 20
                            color clr
