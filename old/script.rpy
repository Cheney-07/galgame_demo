# 《黎明之诗 ~星辰永夜~》
# Ren'Py Galgame 脚本文件

# ============================================================
# 图像尺寸定义
# 背景/CG: 1920x1080 | 角色立绘: 600x900
# ============================================================

# 背景图像 - 1920x1080
image bg tokyo_sunset = im.Scale("images/bg tokyo_sunset.jpg", 1920, 1080)
image bg sky_crack = im.Scale("images/bg sky_crack.png", 1920, 1080)
image bg altar_room = im.Scale("images/bg altar_room.png", 1920, 1080)
image bg palace corridor = im.Scale("images/bg palace corridor.png", 1920, 1080)
image bg moonlight_balcony = im.Scale("images/bg moonlight_balcony.png", 1920, 1080)
image bg selena_crying = im.Scale("images/bg selena_crying.png", 1920, 1080)
image bg training_field = im.Scale("images/bg training_field.png", 1920, 1080)
image bg training_field crowd = im.Scale("images/bg training_field crowd.png", 1920, 1080)
image bg forbidden_library = im.Scale("images/bg forbidden_library.png", 1920, 1080)
image bg tavern = im.Scale("images/bg tavern.png", 1920, 1080)
image bg rooftop night = im.Scale("images/bg rooftop night.png", 1920, 1080)
image bg rooftop moonlight = im.Scale("images/bg rooftop moonlight.png", 1920, 1080)
image bg heart_vision_selena = im.Scale("images/bg heart_vision_selena.png", 1920, 1080)
image bg light_pillar = im.Scale("images/bg light_pillar.png", 1920, 1080)
image bg royal tomb = im.Scale("images/bg royal tomb.png", 1920, 1080)
image bg caravan = im.Scale("images/bg caravan.png", 1920, 1080)
image bg elven_ruins = im.Scale("images/bg elven_ruins.png", 1920, 1080)
image bg wasteland = im.Scale("images/bg wasteland.png", 1920, 1080)
image bg palace throne_room = im.Scale("images/bg palace throne_room.png", 1920, 1080)
image bg tokito_room = im.Scale("images/bg tokito_room.png", 1920, 1080)
image bg sunrise_shrinking = im.Scale("images/bg sunrise_shrinking.png", 1920, 1080)
image bg hand_transparent = im.Scale("images/bg hand_transparent.png", 1920, 1080)
image bg altar = im.Scale("images/bg altar.png", 1920, 1080)
image bg sunrise_dawn = im.Scale("images/bg sunrise_dawn.png", 1920, 1080)
image bg sunrise_full = im.Scale("images/bg sunrise_full.png", 1920, 1080)
image bg mountain_view years_later = im.Scale("images/bg mountain_view years_later.png", 1920, 1080)
image bg border_land = im.Scale("images/bg border_land.png", 1920, 1080)
image bg new_knights = im.Scale("images/bg new_knights.png", 1920, 1080)
image bg countryside = im.Scale("images/bg countryside.png", 1920, 1080)
image bg altar_top = im.Scale("images/bg altar_top.png", 1920, 1080)
image bg traveling = im.Scale("images/bg traveling.png", 1920, 1080)
image bg bounty_hunters = im.Scale("images/bg bounty_hunters.png", 1920, 1080)
image bg lakeside_cottage = im.Scale("images/bg lakeside_cottage.png", 1920, 1080)
image bg starry_sky = im.Scale("images/bg starry_sky.png", 1920, 1080)
image bg burning_tower = im.Scale("images/bg burning_tower.png", 1920, 1080)
image bg dark_map = im.Scale("images/bg dark_map.png", 1920, 1080)
image bg dark_alley = im.Scale("images/bg dark_alley.png", 1920, 1080)

# CG场景图 - 1920x1080
image cg elsia knockout = im.Scale("images/cg elsia knockout.png", 1920, 1080)
image cg noel bracelet = im.Scale("images/cg noel bracelet.png", 1920, 1080)
image cg vespera moonlight = im.Scale("images/cg vespera moonlight.png", 1920, 1080)
image cg vespera sword_drop = im.Scale("images/cg vespera sword_drop.png", 1920, 1080)

# 新增CG场景图
image cg selena sunset = im.Scale("images/cg selena_sunset.png", 1920, 1080)
image cg selena balcony oath = im.Scale("images/cg selena_balcony_oath.png", 1920, 1080)
image cg lyra training last night = im.Scale("images/cg lyra_training_last_night.png", 1920, 1080)
image cg true end vigil = im.Scale("images/cg true_end_vigil.png", 1920, 1080)
image cg bad end silhouette = im.Scale("images/cg bad_end_silhouette.png", 1920, 1080)
image cg all heroines united = im.Scale("images/cg all_heroines_united.png", 1920, 1080)
image cg selena holding hands = im.Scale("images/cg selena_holding_hands.png", 1920, 1080)

# 新增背景图像
image bg dream fog = im.Scale("images/bg dream_fog.png", 1920, 1080)
image bg tokyo room night = im.Scale("images/bg tokyo_room_night.png", 1920, 1080)
image bg tokyo room morning = im.Scale("images/bg tokyo_room_morning.png", 1920, 1080)
image bg city day = im.Scale("images/bg city_day.png", 1920, 1080)
image bg forest night = im.Scale("images/bg forest_night.png", 1920, 1080)
image bg forest transition = im.Scale("images/bg forest_transition.png", 1920, 1080)
image bg temple grand hall = im.Scale("images/bg temple_grand_hall.png", 1920, 1080)
image bg temple main hall = im.Scale("images/bg temple_main_hall.png", 1920, 1080)
image bg guest room night = im.Scale("images/bg guest_room_night.png", 1920, 1080)
image bg guest room door open = im.Scale("images/bg guest_room_door_open.png", 1920, 1080)
image bg forbidden library entrance = im.Scale("images/bg forbidden_library_entrance.png", 1920, 1080)
image bg forbidden library dim = im.Scale("images/bg forbidden_library_dim.png", 1920, 1080)
image bg wasteland campfire = im.Scale("images/bg wasteland_campfire.png", 1920, 1080)
image bg wasteland night camp = im.Scale("images/bg wasteland_night_camp.png", 1920, 1080)
image bg royalgarden_night = im.Scale("images/bg royal_garden_at_night.png", 1920, 1080)
image bg clocktower meeting = im.Scale("images/bg clocktower_meeting.png", 1920, 1080)
image bg altar burning = im.Scale("images/bg altar_burning.png", 1920, 1080)
image bg five heroines gathered = im.Scale("images/bg five_heroines_gathered.png", 1920, 1080)
image bg city square dawn = im.Scale("images/bg city_square_dawn.png", 1920, 1080)
image bg dragon roost sunset = im.Scale("images/bg dragon_roost_sunset.png", 1920, 1080)
image bg forbidden library final night = im.Scale("images/bg forbidden_library_final_night.png", 1920, 1080)
image bg wasteland campfire last night = im.Scale("images/bg wasteland_campfire_last_night.png", 1920, 1080)
image bg rooftop night before final = im.Scale("images/bg rooftop_night_before_final.png", 1920, 1080)
image bg mountain top = im.Scale("images/bg mountain_top.png", 1920, 1080)
image bg sunrise music swell = im.Scale("images/bg sunrise_music_swell.png", 1920, 1080)
image bg royal balcony night = im.Scale("images/bg royal_balcony_night.png", 1920, 1080)


# 赛蕾娜立绘 - 600x900
image selena sad = im.Scale("images/selena sad.png", 600, 900)
image selena surprised = im.Scale("images/selena surprised.png", 600, 900)
image selena gentle smile = im.Scale("images/selena gentle smile.png", 600, 900)
image selena crying = im.Scale("images/selena crying.png", 600, 900)
image selena resolved = im.Scale("images/selena resolved.png", 600, 900)
image selena happy = im.Scale("images/selena happy.png", 600, 900)

# 堂上时人立绘 - 600x900
image tokito normal = im.Scale("images/tokito normal.png", 600, 900)
image tokito concerned = im.Scale("images/tokito concerned.png", 600, 900)
image tokito surprised = im.Scale("images/tokito surprised.png", 600, 900)
image tokito happy = im.Scale("images/tokito happy.png", 600, 900)
image tokito thinking = im.Scale("images/tokito thinking.png", 600, 900)
image tokito sad = im.Scale("images/tokito sad.png", 600, 900)

# 亚兰立绘 - 600x900
image arlan stern = im.Scale("images/arlan stern.png", 600, 900)
image arlan surprised = im.Scale("images/arlan surprised.png", 600, 900)

# 艾尔西娅立绘 - 600x900
image elsia confident smile = im.Scale("images/elsia confident smile.png", 600, 900)
image elsia determined = im.Scale("images/elsia determined.png", 600, 900)
image elsia sad = im.Scale("images/elsia sad.png", 600, 900)
image elsia thinking = im.Scale("images/elsia thinking.png", 600, 900)
image elsia drunk = im.Scale("images/elsia drunk.png", 600, 900)
image elsia angry = im.Scale("images/elsia angry.png", 600, 900)
image elsia proud = im.Scale("images/elsia proud.png", 600, 900)
image elsia happy = im.Scale("images/elsia happy.png", 600, 900)
image elsia surprised = im.Scale("images/elsia surprised.png", 600, 900)

# 诺艾尔立绘 - 600x900
image noel reading = im.Scale("images/noel reading.png", 600, 900)
image noel look up = im.Scale("images/noel look up.png", 600, 900)
image noel writing = im.Scale("images/noel writing.png", 600, 900)
image noel hopeful = im.Scale("images/noel hopeful.png", 600, 900)
image noel thoughtful = im.Scale("images/noel thoughtful.png", 600, 900)
image noel warning = im.Scale("images/noel warning.png", 600, 900)
image noel handing_book = im.Scale("images/noel handing_book.png", 600, 900)
image noel resolved = im.Scale("images/noel resolved.png", 600, 900)
image noel smiling = im.Scale("images/noel smiling.png", 600, 900)

# 莉拉立绘 - 600x900
image lyra singing = im.Scale("images/lyra singing.png", 600, 900)
image lyra smiling = im.Scale("images/lyra smiling.png", 600, 900)
image lyra serious = im.Scale("images/lyra serious.png", 600, 900)
image lyra sad = im.Scale("images/lyra sad.png", 600, 900)
image lyra happy = im.Scale("images/lyra happy.png", 600, 900)

# 薇丝佩拉立绘 - 600x900
image vespera cold = im.Scale("images/vespera cold.png", 600, 900)
image vespera surprised = im.Scale("images/vespera surprised.png", 600, 900)
image vespera conflicted = im.Scale("images/vespera conflicted.png", 600, 900)
image vespera resolved = im.Scale("images/vespera resolved.png", 600, 900)
image vespera shocked = im.Scale("images/vespera shocked.png", 600, 900)
image vespera happy = im.Scale("images/vespera happy.png", 600, 900)

# ============================================================
# 启动画面 - 幻灯片动画（标题菜单之前播放）
# ============================================================

# 启动幻灯片图片 (请将实际图片放入 game/images/ 目录)
image splash_slide_01 = im.Scale("images/splash_slide_01.png", 1920, 1080)
image splash_slide_02 = im.Scale("images/splash_slide_02.png", 1920, 1080)
image splash_slide_03 = im.Scale("images/splash_slide_03.png", 1920, 1080)

label splashscreen:
    scene black
    $ renpy.pause(0.5, hard=True)

    # 第一张幻灯片
    scene splash_slide_01 with dissolve
    $ renpy.pause(3.0, hard=False)

    # 第二张幻灯片
    scene splash_slide_02 with dissolve
    $ renpy.pause(2.5, hard=False)

    # 第三张幻灯片
    scene splash_slide_03 with dissolve
    $ renpy.pause(2.5, hard=False)

    # 黑场过渡到标题画面
    scene black with dissolve
    $ renpy.pause(0.5, hard=True)

    return

# ============================================================
# 游戏入口
# ============================================================

label start:
    # 初始化
    call initialize_game

    # 从梦境开始
    jump prologue_dream

# 初始化游戏状态
label initialize_game:
    $ selena_affection = 0
    $ elsia_affection = 0
    $ noel_affection = 0
    $ lyra_affection = 0
    $ vespera_affection = 0
    $ truth_value = 0
    $ selena_route = False
    $ elsia_route = False
    $ noel_route = False
    $ lyra_route = False
    $ vespera_route = False
    $ chapter1_branch = False
    $ hand_transparent = False
    $ day_count = 0
    return

# ============================================================
# 新增场景：序章之前的梦境场景
# ============================================================

label prologue_dream:
    scene bg dream_fog with fade

    play music "dream_bell_01"

    narrator "你在梦里奔跑。"

    narrator "不是那种能清楚看见道路的奔跑，而是脚下永远踩不到实处的失重感。"

    play sound "bell_tinkle.wav"

    narrator "铃声。清脆、细小，一下一下敲在意识的边缘。"

    narrator "雾从地面涌起，灰白的潮水漫过膝盖。"

    narrator "雾里有影子晃动。城的剪影在远处燃烧。火焰是银白色的，不冒烟，只安静地舔舐着天际。"

    narrator "你胸口发紧，抬手想拨开雾，指尖却碰到一阵冰冷坚硬的东西——"

    narrator "那是一枚吊坠。"

    narrator "银色的链子缠绕在你的右手腕上，吊坠像一滴凝固的夜，里面有细碎的光点流动。"

    narrator "吊坠背面有一道浅浅的刻痕。大脑深处某个地方突然被点亮："

    narrator "「若你愿意，便将故事翻到下一页。」"

    scene black with fade

    jump tokyo_room_awaken

# ------------------------------------------------------------
# 场景：东京公寓·第一次醒来
# ------------------------------------------------------------

label tokyo_room_awaken:
    scene bg tokyo_room_night with fade

    play music "silence_01"

    narrator "你猛地睁开眼。"

    narrator "天花板上的灯没开。窗外是城市沉默的夜光。"

    narrator "你缓慢摊开掌心。空的。"

    narrator "没有银链，没有吊坠。只有掌心被指甲掐出的浅浅红痕。"

    narrator "你坐起来。手机屏幕显示：03:17。"

    narrator "房间里最响的声音，是你自己心跳渐渐归位的节拍。"

    narrator "你坐在床边，试图用它覆盖脑子里还在回响的铃声。"

    narrator "然后你发现了一件事——"

    narrator "你记不起梦里呼唤你的那个声音，用的是什么样的语气。"

    narrator "只有坠子背面那行字的记忆还在："

    narrator "「若你愿意，便将故事翻到下一页。」"

label tokyo_room_morning:
    scene bg tokyo_room_morning with fade

    play music "morning_ambient_01"

    narrator "清晨醒来时，你用了很久才把自己从那场梦里拔出来。"

    narrator "梦里的雾、铃声、城的剪影——它们不是一醒来就散去的那种梦。"

    narrator "手机显示：07:12。"

    narrator "阳光从窗帘缝里切进来一条细亮的线，安静地落在地板上。"

    narrator "你翻身下床，踩进拖鞋里，走到洗手间。"

    narrator "镜子里的人眼下有点青，像失眠了一整夜。"

    narrator "可当你低头擦脸时，脑子里忽然闪回梦里那句刻在吊坠背面的文字。"

    menu:
        "holy shit":
            jump tokyo_day_routine

label tokyo_day_routine:
    scene bg city_day with fade
    play music "everyday_01"

    narrator "一天就这样被生活推着走。"

    scene bg shang_ke with fade

    narrator "上午的课程填满了注意力。教授在讲量子力学的基本假设。"

    narrator "下午更忙。实验课上搭档问你有没有睡好，你说“还好”。"

    narrator "傍晚你收拾东西离开教室，天色已经开始转暗。"

    scene bg tokyo_sunset with fade
    narrator "你坐电车回家。车厢里人不多，你靠门站着，看窗外掠过的街景。"

    narrator "你告诉自己：梦而已。"

    narrator "可当你在门口掏钥匙时，手指却顿了一下。"

    narrator "钥匙串上有个小挂件，有一道细小的划痕——突然显得特别像某种『刻痕』。"

    narrator "你把钥匙插进锁孔，转动，开门。关上门的那一刻，外面的喧闹被隔绝，屋子里恢复成你熟悉的安静。"

    narrator "也就在这份安静里，梦的残影又慢慢浮上来。"

    jump tokyo_room_night_return

label tokyo_room_night_return:
    scene bg tokyo_room_night with fade

    play music "uneasy_01"

    narrator "你洗了澡。热水冲在肩上时你试图把注意力集中在水温上，但脑子会自动回到梦里那片雾。"

    narrator "你准备上床时，脚步却停住了。"

    narrator "床边地板上，多了一本书。"

    narrator "它安静地躺在那里。封面没有书名，只有压纹——那些纹路细密地交织，像藤蔓，又像天体运行的轨道。"

    narrator "你蹲下去，伸手。封皮触手微凉。"

    narrator "书脊的位置有一道细细的凹槽——大概大拇指宽，形状是拉长的椭圆。"

    narrator "你抱着书坐到桌前，开了台灯。暖黄的光落在封面上。"

    narrator "你深吸一口气，翻开它。"

    narrator "纸页很厚，第一页干净得过分，整页只有一行字，写在正中央，字迹工整，墨色却泛着银："

    narrator "「你已在梦中看见门。」"

    narrator "第二页：「醒来的人，决定是否跨过它。」"

    narrator "第三页：「在月光照不到的地方，有一座城，用镶银的钟声记录黎明。」"

    narrator "你合上书，盯着封面中央那滴『夜色』。里面的星点似乎比刚才更亮。"

    narrator "你再次翻开书。这一次，你的手指自己动了。"

    narrator "它沿着书页的边缘摸索，然后滑向书脊。指尖触到那道凹槽时——"

    play sound "click.wav"

    narrator "「咔哒」一声。"

    narrator "台灯的光抖了一下。书页边缘闪过一丝极细的银光。"

    narrator "凹槽里浮起了一枚东西——银色的链子。它绕过你的右手腕，冰冷、贴合。"

    narrator "坠子背面有一道浅浅的刻痕。意义像灼热的铁烙印在大脑里："

    narrator "「若你愿意，便将故事翻到下一页。」"

    menu:
        "继续翻页":
            jump book_pages_turn
        "放下书":
            jump book_pages_turn

label book_pages_turn:

    narrator "不是纸张摩擦的声音。是一种细微的、像薄冰裂开的轻响。"

    narrator "灯光在那一瞬间变暗。书页上，文字从无到有浮现出来。"

    narrator "「你所在的世界，安静而稳定，像一条笔直的路。可路尽头并不总是终点。」"

    narrator "你想合上书，却发现手指像被什么轻轻黏住。"

    narrator "你硬着头皮往下看。"

    narrator "「当你读到这里时，门已经打开了一道缝。」"

    narrator "台灯的光再次抖了一下。"

    narrator "你终于明白：这不是『书里写的故事』。这是『故事正从书里出来』。"

    narrator "你猛地站起，椅子腿在地面拖出刺耳的声响。"

    narrator "你的视线开始模糊。房间边缘像被人用手指抹开。"

    narrator "耳边响起你最不想再次听见的声音——"

    play sound "bell_tinkle.wav"

    narrator "铃声。"

    narrator "清脆、细小，却近得仿佛就在门外响起。"

    narrator "书页被风一样的力量哗啦哗啦翻动。"

    narrator "某一页猛地停住。那一页比其他的都更白，纸面几乎在发光。中央浮现出一行字："

    narrator "「欢迎来到记录开始之处。」"

    narrator "然后，黑暗合拢。"

    jump forest_night_arrival

# ------------------------------------------------------------
# 场景：异世界·降临
# ------------------------------------------------------------

label forest_night_arrival:
    scene bg forest_night with fade

    play music "forest_ambient_01"

    narrator "你以为自己会摔在地上。可当意识重新聚拢时，你闻到的不是房间里熟悉的洗衣液味。"

    narrator "而是湿润的泥土、苔藓被压碎后散出的清苦味，以及远处隐隐的烟火味。"

    narrator "你慢慢睁开眼。"

    narrator "头顶不是天花板，而是被风吹动的树冠。月色从叶隙洒下，像碎银落在草地上。"

    narrator "你身下是潮湿的草丛，指尖触到冰凉的露水。"

    narrator "远处传来规律的钟声——镶着银边、清脆而悠长。"

    narrator "你撑起身体。手肘发软，第一反应是寻找那本书。"

    narrator "它就在你旁边，安静地躺在草丛里，封面朝上。"

    narrator "你抬头望向钟声传来的方向。树影尽头，隐约可见城墙的轮廓。"

    narrator "草丛里有细响。不远，大概十米左右。"

    narrator "那是脚步声——轻而稳，踩在落叶上。不是动物的脚步，是人的步子。"

    narrator "你屏住呼吸，抱紧那本无名的书，望向黑暗里脚步声靠近的方向。"

    narrator "钟声再次响起。这次更近，更清，更亮。"

    narrator "你的故事，终于真正开始。"

    jump magic_activation_scene

# ------------------------------------------------------------
# 场景：从草地到神殿的传送
# ------------------------------------------------------------

label magic_activation_scene:
    scene bg forest_transition with fade

    play music "magic_activation_01"

    narrator "草丛里那串脚步声没有停在『靠近』，而是直接越过了你能反应的极限。"

    narrator "你刚来得及抱紧那本书，树影间就划出一道弧线——不是刀光，是一种更像『银线』的东西。"

    narrator "你下意识把书抱到胸前，整个人往后缩。脊背撞上一棵树干。"

    narrator "地面上亮起同心圆的纹路——细密、规整的几何图形，一层套一层。"

    narrator "钟声在远处敲了一下，沉重而悠长。"

    narrator "你眼前的月光被抽走。然后是一股『垂直下坠』的眩晕感。"

    narrator "在扭曲的间隙里，你听见一个人的声音从黑暗里传来："

    narrator "「抓到了。」"

    narrator "那声音很年轻。带着一种奇怪的笃定。"

    narrator "你被『光』按进了地面。不是坠落，是光本身裹住你，把你拖向某个固定的方向。"

    jump temple_grand_hall

label huijia_scene:
    scene bg tokyo_room_morning with fade
    narrator "你猛然睁开双眼，迅速环顾四周，发现自己躺在自己家里的床上，天还蒙蒙亮。"
    narrator "你扭头去找地上的书，却发现地上什么都没有。整理好衣服去洗漱，还是什么事情都没有发生"
    narrator "刚才发生的一切好像都是一场梦，却是无比的真实。"
    narrator "抬头看了眼时间。"
    arlan "「到时间了，该去上学了」"
    arlan "「居然还做了个连环梦，真是够刺激的」"
    narrator "开启了一天的新生活"
    scene bg city_day with fade
    narrator "上课"
    scene bg shang_ke with fade
    narrator "听讲"
    scene bg tokyo_sunset with fade
    narrator "放学"
    scene black with fade
    centered "日子日复一日的过着"
    scene black with fade
    centered "那天的梦也渐渐忘却"
    scene black with fade
    centered "如同奥菲斯大陆一样渐渐坠入永夜，在宇宙中消散"
    scene black with fade
    centered "【达成结局 Normal End「真的是？梦吗？」】"
    jump credits
label temple_grand_hall:
    # ---- 奥菲斯大陆 ----

    scene bg altar_room with dissolve

    play music "ceremonial_choir_01"

    narrator "黑场渐亮"
    narrator "巨大穹顶神殿 / 彩窗光柱 / 漂浮的咒文符号"
    narrator "数十名披袍祭司围成同心圆 / 中央魔法阵上跪着主角"

    tokito "（这里是什么地方。）"
    tokito "（——而且，怎么所有人都在看着我。）"
    narrator "（你的视线扫到自己左侧。那本无名书就躺在阵外半步远的地方，像被“规矩”地放在允许的距离之外——“你可以带着它，但仪式进行时它不能在你手里”。封面那滴夜色里，星点不紧不慢地旋转，像一个独立的、不受干扰的小宇宙。）"
    narrator "（更诡异的是：你右手腕上那道红痕比在草丛里时更清晰了。颜色没有加深，但边缘更锐了，像用极细的笔重新描了一遍轮廓。）"
    # 大祭司亚兰出场
    show arlan stern at center with dissolve
    narrator "站在最内圈的一个祭司上前一步。她的兜帽比其他人稍浅，袍子边缘有银线镶边。当她抬起头时，你看见一张年轻的脸——不是稚嫩的脸，而是一种像是经历过许多磨难，失去了年少稚气的脸。"
    narrator "声音不大，却压得住整个穹顶的回响"
    arlan "（降临者啊——历经百年，我等终于将您从星海彼端唤回。）"
    narrator "他停顿了一秒，等你消化这句话。"
    arlan "（您即是预言中的『星之守夜者』。请——为我等垂死的世界，重燃黎明。）"
    tokito "（你喉咙干得发疼。舔了舔嘴唇，嘴唇上有干裂的皮。「……你们把我“唤回”？先说清楚：我在哪里？你们是谁？我为什么会一睡醒就直接来到这里——」）"
    narrator "祭司群里响起一阵压低的骚动。有人明显松了口气——肩膀放松，呼吸变深；有人却露出迟疑——下巴微微抬起，从兜帽下方窥视你的角度变了。你的反应太“正常”，太像一个困惑的普通人类，不像他们想象里会立刻跪拜或痛哭流涕的救世主。"
    arlan "（他抬起一只手，骚动静止。「此地为奥菲斯大陆，星环圣庭之神殿。森林——不过是“降临落点”的误差。您能落在镶银钟城外，已经说明仪式成功。」他顿了顿。「至于为何是您……」）"
    narrator "亚兰抬手，指向阵纹一处最深的凹槽。那凹槽在大理石面上形成一个漆黑的凹陷，位置恰好在他脚边半步远。"
    narrator "（那凹槽的形状，与你梦中、书脊凹槽、以及此刻垂在你胸口那枚坠子的轮廓——吻合得过分了。不是相似，是对应的。像钥匙孔和钥匙。）"
    arlan "（「因为“记录之钥”选择了您。」）"
    narrator "你咽了一口几乎没有的唾沫，让声音尽量稳。"
    tokito "「如果这是一场召唤——我有选择权吗？能不能回去？」"
    narrator "这句话像在祭司圈里投下石子。有人皱眉，眉骨的阴影加深；有人露出“果然如此”的神色，几乎带着一丝疲惫的认可。"
    narrator "亚兰沉默了半秒。那半秒里你几乎能听见他在衡量“该说多少真话”——这不只是直觉，你在他的眼睛里看到了计算的痕迹：像一个人在脑中快速翻阅一本书，寻找最适合当下情况的那一页。"
    arlan "（「回去……并非不可能。但在此之前，永夜会先吞没这里。我们没有时间再等一个世纪，等下一位合适的降临者。」）"
    menu:
        "来都来了，先看看怎么个事":
            jump next_parse
        "……所以呢？管我比事":
            jump holy_shit
label holy_shit:
    show arlan surprised
    narrator "（亚兰表情错愕）"
    narrator "（群众低声喧哗）"
    jump next_parse
label next_parse:
    scene bg altar_room with dissolve
    narrator "就在这时，你感觉到一种熟悉的“铃声前兆”——不是声音，不是声音，而是意识边缘被轻轻敲了一下的那种微颤，像水面被投下一颗极小的石子后扩散开来的第一圈波纹。你抬起头。"
    narrator "神殿彩窗下站着一个人。"
    narrator "彩窗投下的光柱把彩色的光斑打在地上，而她就站在那道光里，像她这个人本来就应该站在光与暗的交界处。她穿着王族式样的深色礼服外袍，面料厚重，但在光下泛着细微的丝光。衣摆有细银线绣成的钟纹——不是装饰性的钟，是能辨认出钟楼、钟锤、钟绳的精密刺绣，每一针都细密规整。"
    narrator "银发在彩窗光柱里像被点亮——不是反射，是吸收光后发出一种柔和的、月白色的辉。紫色的眼睛却冷得出奇。那不是敌意的冷。那是“你已经见过太多次相同的情节，以至于不再感到惊讶”的平静。"
    # 赛蕾娜出场
    show selena gentle smile at right with dissolve
    tokito "「……。」"
    tokito "（银发，紫眼。我见过这张脸。在梦里。梦里的城有影子，有火焰，还有——在城的某扇窗后面，有一个人站在光里，头发被风吹起，紫色的眼睛看着我。是这个人。这个女孩。）"
    tokito "（梦里那个女孩。）"
    narrator "你的胸口一紧。某个“被扣住”的错觉再次出现——不是物理上的束缚，是一种关联。你和这个银发女孩之间有一条看不见的线，线的另一端拴在那本书上，而你们被绑在线的两头，都挣不开。"
    show selena gentle smile at right with dissolve
    narrator "她笑了笑。那个笑容不深，只是嘴角弯起一个很小的弧度，像在说“我知道你在想什么，没关系，很正常”。"
    # 心象之色启动
    show selena gentle smile at right with dissolve
    selena "「你在想是不是曾经梦到过我——还有，我是谁，对吧？」"
    narrator "她向你走近一步。靴跟踩在大理石上，声音清脆。"
    selena "「欢迎，时人大人。我是赛瑞斯王国第七王女，赛蕾娜。」"
    selena "「也是……今后会站在您身边，看着这一切结束的人。」"
    tokito "（「看着这一切结束」——）"
    tokito "（她说的不是『开始』,是『结束』。）"
    narrator "赛蕾娜向魔法阵走近第二步。阵纹立刻浮起更强的银光，像在警告“非召唤目标不得入内”——那些银色骨骼般嵌在大理石里的纹路骤然变亮，亮度足以让你眯了眯眼。可她并未被弹开。阵纹在短暂迟疑后，竟像承认了她的权限般慢慢沉下去，亮度恢复到之前的状态。"
    tokito "（）"
    show arlan stern at left with dissolve
    arlan "（语气明显收束，声线绷紧了一点点。「殿下，请勿靠近核心阵。」）"
    narrator "她没有停止走向你。只是偏头看了亚兰一眼，紫色的眼睛在彩窗光下闪了一下。"
    selena "「大祭司。既然人已经到了，就别再把他当成仪式的“结果”。告诉他规则。」"
    scene bg altar_room with dissolve
    show arlan stern
    narrator "亚兰的目光落到阵外的无名书上。那目光里有一种你读不懂的情绪——不是贪婪，不是恐惧。是更复杂的。像一个人看着自己多年前签下的欠条。"
    arlan "「……规则很简单，也很残酷。」"
    narrator "他深吸一口气。"
    arlan "「那本书会记录您的选择，也会推动“故事”发生。每翻一页，世界会更接近您所读到的叙述。而您要付出的代价——不是血，不是寿命。」"
    narrator "他顿了顿，像在避开某个词。嘴唇动了一下又闭上。"
    arlan "「是“确定性”。」"
    narrator "你皱起眉。"
    tokito "「什么意思？」"
    arlan "「您原来的世界稳定、因果牢固。您在那边做的每一件事，结果都不会轻易被改变。而在奥菲斯——故事能改写命运，也能抹去命运。您越频繁翻页，您就越难回忆起“原本的路”。」"
    narrator "他的声音沉下去。"
    arlan "「您从哪里来、要回到哪里去、回去之后还剩下什么——每一次翻页都会从您记忆里取走一小片确定性。一片一片，直到您分不清您自己是谁。」"
    narrator "你忽然明白为什么你一直记得梦的内容，却又像被雾糊住细节——不是睡眠质量的问题。是“翻页”已经开始收取第一笔费用。现在你试着回忆梦里呼唤你名字的那个声音的语气，你发现那片记忆已经模糊得只剩轮廓。"
    scene bg altar_room with dissolve
    show selena gentle smile
    narrator "她终于走到你面前。近看时她的紫色眼睛更深，瞳仁边缘有一圈极细的银环。"
    selena "「不过别担心。圣庭和王国都会保护您。至于您想不想在这里留下来帮助我们——」"
    narrator "她顿了顿，那个淡淡的微笑又出现了。"
    selena "「——那就是您的选择了。」"
    menu:
        "我要留下来拯救世界！！！":
            jump really_next
        "我想回家/(ToT)/~~":
            jump huijiajieju_sence

label huijiajieju_sence:
    selena "「好吧，我尊重您的选择」"
    selena "「亚兰，将降临者传送回原来的世界」"
    arlan "「可是，殿下...」"
    selena "「亚兰，这是降临者的选择，我们无权干预。至于目前的困境，我还有最后的办法...」"
    arlan "（无奈摇头，举起一旁的法杖将仪式重新启动）"
    narrator "召唤阵泛起剧烈白光，你感到眼前一阵晕眩。"
    jump huijia_scene

label really_next:
    show selena surprised
    narrator "「赛雷娜听后，平静的神情变得有些许激动」"
    selena "「感谢您做出这个决定」"
    narrator "「神殿穹顶上方，漂浮的咒文符号忽然排列成一行。不是之前那种零散、随机的分布，而是像有人在打字——十几个符号迅速汇聚、排列成一个句子。」"
    narrator "「**“守夜者”**，**“记录”**。」"
    narrator "「你只来得及捕捉到其中两个词，因为在那个句子形成不到一秒之后就迅速散开了」"
    narrator "「这时，你听见了那熟悉的清脆铃声——不是幻听。它是真实的，从神殿深处传来，经过穹顶的回响，变得更丰富、更饱满。像有人在很远的地方敲响了镶银的钟。」"
    selena "「钟响了。从这一刻起，你不是“被召唤的外来者”。你是被世界承认的角色。」"
    narrator "「她的声音在“角色”这个词上有极其微小的停顿，像她也正在理解这两个字的重量。」"
    $ selena_affection += 50
    # 标题画面
    scene black with fade

    centered "黎明之诗 ~星辰永夜~"

    pause 2.0

    scene black with fade

    jump temple_aftermath

# ------------------------------------------------------------
# 新增场景：序章尾·仪式之后
# ------------------------------------------------------------

label temple_aftermath:
    scene bg temple_main_hall with fade
    narrator "亚兰抬手。祭司们同时低头。衣料摩擦的声音整齐地响了一下。"

    narrator "魔法阵的银光完全褪去后，祭司们像退潮般散开。"

    narrator "你的膝盖仍然发软，站直的动作需要扶着大腿完成。"

    narrator "两名圣庭骑士从祭司圈的外围走上前，一左一右架起你的手臂。"

    show arlan stern at center with dissolve

    arlan "「降临者……请随我来。您需要休息，也需要知道一些真相。」"

    tokito "「真相？先告诉我——我要怎样才能回去？」"

    arlan "「这个问题……等您看过镶银钟城之后，再问不迟。」"

    narrator "你注意到赛蕾娜的目光扫了过来。那双紫色眼睛能感受到强烈的情绪——是担心。"

    show selena surprised at right with dissolve

    selena "「大祭司，我父王会安排住处。这件事……不该只由圣庭决定。」"

    tokito "（她不是第七王女吗？第七——说明有六个比她大的王族排在前面。她怎么敢用这种语气对圣庭大祭司说话？刚才亚兰的语气变化，阵纹对她的承认——）你吞了一口唾沫。（除非……她手里有圣庭也无法忽视的东西。）"

    narrator "空气突然凝了一下。亚兰和赛蕾娜之间的空间像有两道看不见的力量在角力。"

    arlan "「……如殿下所愿。仪式记录已封存。三日后，请王国派人来圣庭进行『登记确认』。」"

    narrator "你被那两个骑士带离神殿。走过祭司们让出的通道时，每一步都踩在大理石的血红色纹理上。"

    narrator "但你听见了——身后传来一个极轻的声音。"

    narrator "那本无名书仍躺在阵外的地板上。祭司们没人去碰它。"

    narrator "它在等你回去。"

    jump chapter1_first_night

# ------------------------------------------------------------
# 新增场景：第一章·被囚禁的第一夜
# ------------------------------------------------------------

label chapter1_first_night:
    scene bg guest_room_night with fade

    play music "distant_bell_01"

    narrator "跟随塞雷娜来到了王宫，住进了客房。"

    narrator "王宫的客房比你家客厅还大。"

    narrator "窗帘是厚重的天鹅绒，暗酒红色，触手柔软而沉重。"

    narrator "床柱上刻着繁复的藤蔓纹样。空气里有一股陈旧的熏香。"

    narrator "但你睡不着。床垫太软了，软到你觉得身体陷在里面像沉入泥沼。"

    narrator "你坐在床边，右手举到眼前。台灯的光照在你的手腕上。"

    narrator "那道红痕还在。不是幻觉，不是暂时的皮肤压痕。你用手指反复摩挲它。"

    tokito "「……该不会就这么留一辈子吧。」"

    play sound "knock_soft.wav"

    narrator "敲门声响起。不是叩叩，是一下——极轻的一声。"

    tokito "「谁？」"

    selena "「是我。能开门吗？」"

    menu:
        "开门":
            jump selena_night_visit
        "「这么晚了，有什么事？」":
            jump selena_night_refuse

# ------------------------------------------------------------
# 赛蕾娜深夜来访
# ------------------------------------------------------------
label selena_night_refuse:
    selena "「有些必须的事情想要告诉您一下」"
    $ selena_affection -= 20
    menu:
        "开门":
            jump selena_night_visit
        "拒绝":
            jump selena_refuse

label selena_refuse:
    narrator "不知是由于怀疑还是太累了，你并不打算开门。"

    tokito "「今天天色太晚了，没什么好聊的，有事明天再说吧，我要睡觉了。」"

    show selena gentle smile
    selena "「……也是。或许这样对你更安全。」"

    narrator "脚步声渐渐远去。"

    narrator "你坐回床边，却发现更睡不着了。"

    narrator "是因为那句话里面的关心不是修辞，是真实的。"

    jump chapter1_continue

label selena_night_visit:
    scene bg guest_room_door_open with fade

    play music "lonely_violin_01"

    narrator "你走到门边，压下门把手。门无声向内拉开。"

    show selena gentle smile with dissolve

    narrator "赛蕾娜站在门外。她没有穿白天那套王族外袍，只披着一件深色的斗篷。"

    narrator "银发从斗篷边缘漏出几缕，在走廊的烛光下泛着淡光。"

    selena "「我不是来监视你的。我只是……想确认一件事。」"

    tokito "「确认什么？」"

    selena "「那道红痕——你看得见它，对吗？」"

    narrator "她抬手指向你的右手手腕。"

    tokito "「你……怎么知道？」"

    tokito "「你下意识把右手从门把手上拿下来，用左手捂住了手腕。」"

    show selena sad

    selena "「因为我也有一道。」"

    narrator "她掀开斗篷的右袖口。手腕内侧有一道浅红色的痕迹。形状、颜色——和你右手腕上那道一模一样。"

    selena "「没有人在意过我的。我父王不看——他有六个比我大的孩子，第七个女儿的印记不重要。」"

    narrator "她抬起眼，紫色的眼睛在烛光里像凝固的夜色，中间有光在摇曳。"

    selena "「但你今天在神殿里，看见的……不只是书，对吧？」"

    menu:
        "「我看见了。你背上……有道印记。」":
            jump selena_honest_response
        "「我只是感觉到……一些东西。」":
            jump selena_cautious_response

label selena_honest_response:
    show selena surprised
    selena "「……果然。时人——从你被『召唤』的那一刻起，我就感觉到了。那本书选了你不是巧合。」"

    selena "「但我要提醒你——这个世界上，有些东西是看见了就必须负责的。」"

    tokito "「什么意思？」"

    selena "「意思是——如果你决定『看见』我，你就等于选择了与圣庭的谎言为敌。」"

    selena "「而圣庭的敌人，没有一个活过三个月的。」"

    show selena sad
    selena "「……不值得你这么选。」"

    narrator "她退后一步。斗篷重新遮住了那道红痕。"

    narrator "就在那个角度、那个瞬间——你看见了。"

    narrator "她背部的衣料下，有一丝极淡的光透出来。光在脉动——和她心跳同一个频率。"

    narrator "然后她走了。靴跟在石板走廊上敲出清脆的、逐渐远去的声响。"

    narrator "你瘫坐回床边，发现自己出了一身冷汗。"

    narrator "那语气，不像一个王女在和勇者说话。像一个溺水的人，在水面上看见另一只手伸出来。"

    $ selena_affection += 50

    jump chapter1_continue

label selena_cautious_response:
    show selena gentle smile
    selena "「……也是。或许这样对你更安全。」"

    narrator "脚步声渐渐远去。"

    narrator "你坐回床边，却发现更睡不着了。"

    narrator "是因为那句话里面的关心不是修辞，是真实的。"

    jump chapter1_continue
# ------------------------------------------------------------
# 新增场景：禁书阁初见诺艾尔
# ------------------------------------------------------------

label noel_first_meeting:
    scene bg forbidden_library_entrance with fade

    play music "silent_bell_01"

    narrator "亚兰带你去禁书阁的路上，故意放缓了脚步。"

    narrator "这条走廊很窄。两侧是密不透风的高墙，石材是深灰色的。"

    narrator "头顶只有一排狭窄的天窗，开在接近天花板的位置。"

    show arlan stern at center with dissolve

    arlan "「时人先生，您来自的世界……有一种学问，叫物理学，对吧？」"

    tokito "「是。你怎么知道？」"

    arlan "「并不是只有您跨过了世界之间的『缝』。两百年来，圣庭积累了足够的信息。」"

    narrator "他在一扇巨大的黑色铁门前停下。门没有锁孔，没有把手，只有一片银色的金属板。"

    arlan "「这扇门后面，是禁书阁。诺艾尔小姐已经等了您三天。」"

    arlan "「如果您在这座禁书阁里读到了『矛盾』——请您先来找我，而不是对外宣扬。」"

    tokito "「比如『过去12个勇者』的真相？」"

    narrator "亚兰的表情没有任何变化。但空气里的温度——在那一瞬间——降了几度。"

    arlan "「诺艾尔小姐教得很快。」"

    narrator "他把手掌按在银色金属板上。大门无声向内滑开。"

    narrator "他把手掌按在银色金属板上。没有口令，没有手势。就是把手掌贴上去，五指张开，像在盖一个看不见的印章。金属板在他掌心的温度下发出一声低沉的嗡鸣——然后大门无声向内滑开。门的底部擦过石板地面，发出一道极细的气流声。"

    tokito "亚兰果然不对劲，她到底在隐藏着些什么"

    jump forbidden_library_inside

label forbidden_library_inside:
    scene bg forbidden_library with fade

    play music "whisper_01"

    narrator "禁书阁的内部比外面看起来更大。书架从地面一直延伸到天花板。"

    narrator "书脊上的文字在黑暗中发出极其微弱的荧光。"

    narrator "在那些发光的书脊之间，你看见了她的背影。"

    show noel reading with dissolve

    narrator "她背对着你，站在一架活动梯的顶端。黑色的长发从肩头垂下。"

    narrator "她从书架里抽出一本书，夹在臂弯里，然后回头看了你一眼。"

    show noel look up
    narrator "那双灰色的眼睛。不是冷漠的灰——是一种被太多真相浸泡过的灰。"

    noel "「……」"
    narrator "（她只看了你一秒钟不到，就把目光收了回去。）"

    narrator "（她爬下梯子，把臂弯里的书放在旁边的书桌上。然后她取出一支笔，在一张小纸条上写了几个字，推到你面前。）"

    narrator "「第13位勇者。」"
    narrator "「比预计晚了两个月。原因？」"

    tokito "「……我犹豫了。」"

    show noel hopeful
    narrator "她抬起眼，灰瞳里有一瞬的闪动。她又写了一张纸条。"

    narrator "「犹豫是好事。前12个里，有9个没有犹豫。」"
    narrator "「他们没有犹豫的结果，都在那边的架子上。」"

    narrator "（她抬手指了一下禁书阁东侧最暗的那一片区域。那里有一排书架，上面不是书——是一排整齐排列的卷轴。）"

    narrator "（十二卷。每一卷都是一个勇者的记录。）"

    tokito "「诺艾尔——亚兰说你在这里等了我三天。为什么？」"

    show noel writing
    narrator "她沉默了很久。然后她抬起左手——你注意到她的左手腕上戴着一只银色的手环。"

    narrator "（她取下笔，在纸条上写下几个字。）"

    narrator "「因为你要教我。」"
    narrator "「你来自一个没有太阳在熄灭的世界。」"
    narrator "「我想知道——那里的人，是怎么写故事的。」"

    $ noel_affection += 5
    $ truth_value += 10
    jump chapter1_continue

# ------------------------------------------------------------
# 新增场景：莉拉酒馆的"启明歌片段"
# ------------------------------------------------------------

label lyra_tavern_meeting:
    scene bg tavern with fade

    play music "lyra_song_intro"

    narrator "王城东区的地下酒馆。名字叫『炉底』。"

    narrator "酒馆里永远弥漫着烤铁的气味、麦酒的酸味和汗味。"

    narrator "佣兵们在划拳。东南角的桌旁，两个商队护卫正在比谁的臂力大。"

    show lyra singing with dissolve

    narrator "她坐在吧台尽头的高脚凳上。海蓝色的长发编成一条松散的三股辫。"

    narrator "怀里抱着一把鲁特琴，琴身在烛光下泛着旧漆的温润光泽。"

    tokito "「……你是怎么知道钟声的？」"

    show lyra smiling
    lyra "「因为每个『被召唤者』都会听见。十三个。来自另一个世界的人，都说过同样的话。」"

    narrator "她把琴抱得更紧了一点，翡翠色的瞳孔在酒馆的烛光里像两块碎了的宝石。"

    lyra "「我叫莉拉。六十年前，我族因为一首歌被屠光。」"

    lyra "「那首歌的名字，叫《启明歌》。它能延缓太阳的死亡——不是拯救，只是延缓。」"

    tokito "「你唱过？」"

    lyra "摇头。「我只会唱开头。完整的版本……在我母亲死去的那个晚上，被烧掉了。」"

    narrator "她用大拇指在自己的喉咙上做了个极小的横切的手势。"

    lyra "「前12个……都死了。」"

    tokito "「怎么死的？」"

    lyra "「有的被圣庭『处决』。有的是被诅咒反噬——翻书翻得太快，手全透明了。」"

    lyra "「还有的是自己放弃了。最后变成一页书，啪嗒。」"

    narrator "她按下第三根手指。「而你——你的右手，现在还能握酒杯吗？」"

    narrator "（你低头。右手正握着粗陶杯。但在指甲盖的边缘，透出一丝不正常的光。）"

    tokito "「……什么时候开始的？」"

    lyra "「从你翻书的那一刻。翻到第五页——就会开始『变透明』。」"

    narrator "你盯着自己的手。指甲盖边缘的透明趋势非常缓慢——你用拇指搓了搓那片区域，它恢复了正常肤色，但只过了几秒，又透出那种不正常的薄光。"
    narrator "像墨迹渗入宣纸的速度。边缘缓慢地向外扩散，你不知道它什么时候会蔓延到手腕、手臂、胸口。"
    narrator "但你知道了一件事。那本书翻的不是页数。是你身体里存着的“时间”。"
    narrator "她一口喝完自己杯里的金色液体，站起身来。放下杯子时杯底在吧台上发出咚的一声。她站起身时的动作很利落——甩了一下辫子，把鲁特琴重新抱回怀里。"
    lyra "「我不会再唱完整的《启明歌》。除非有一天——」"
    lyra "「——有人能证明，这个世界值得被救。」"
    narrator "她望向窗外。酒馆的窗户是窄小的、嵌着铁栏杆的，外面没有月亮，只有薄薄的云层，被城内的灯火映得发黄。"
    narrator "她重新抱起鲁特琴，走向酒馆中央的小舞台。那个舞台就是一片稍微高出来的木地板，上面铺着一块磨秃了的地毯。当她拨出第一个和弦时，酒馆里的喧闹竟自动压低了——不是她唱了什么魔法咒语，她的声音里没有任何术式的痕迹。只是太干净了，干净到你不忍心弄出任何杂音来覆盖它。"
    narrator "她唱的是《启明歌》的开头几句。不是完整版——只是一段零散的旋律，四句词，每一句之间都有很长的间奏。你能听出那段旋律的结构：四句词里，有六个词的位置是留白——被间隔的太长的间奏空出来的。是被故意空在那里的。不是被烧掉了，是被掰掉。像从一串完整的项链中取下六颗珠子。"
    tokito "（少了六个词，整段旋律的气就断了。但即使如此——还是能感受到这首歌的反噬）你把手按在胸口。那道红痕的位置在发热。不是痛，是温度——像有人在红痕另一端点了一盏小灯，热量从书脊的那一侧传过来。"
    $ lyra_affection += 50
    $ truth_value += 10

    jump chapter1_continue

# ------------------------------------------------------------
# 第一章结尾·分歧点 A
# ------------------------------------------------------------

label chapter1_continue:

    menu:
        "继续探索":
            jump chapter1_explore_more

        "接下来去见谁呢":
            jump chapter1_branch_point

label chapter1_explore_more:
        menu:
            "赛蕾娜 · 月光走廊":
                jump section1_selena

            "艾尔西娅 · 训练场":
                jump section2_elsia

            "诺艾尔 · 禁书阁":
                jump section3_noel

            "莉拉 · 城外酒馆":
                jump section4_lyra

            "薇丝佩拉 · 屋顶":
                jump section5_vespera

            "结束探索":
                jump chapter1_branch_point

label chapter1_branch_point:
    scene bg tokito_room with dissolve

    play music "silent_decision_01"

    narrator "（这一周，我见了五个人。）"
    narrator "（赛蕾娜身上有诅咒。）"
    narrator "（艾尔西娅说『血统不正』。）"
    narrator "（诺艾尔说『过去 12 个勇者』。）"
    narrator "（莉拉说『唱完整版的人都死了』。）"
    narrator "（薇丝佩拉……来杀我。）"

    tokito "（这个王国，一定有事。）"
    tokito "（但是——晨曦塔说他们等了我一百年。）"
    tokito "（我也不能就这么背叛他们。）"

    tokito "（明天亚兰要带我巡视王都。）"
    tokito "（我得选一边站。）"

    menu:
        "表面信任王国，内部默默调查":
            $ chapter1_branch = False
            jump chapter2_palace_route

        "联络莉拉与『无星者』，假装失踪":
            $ chapter1_branch = True
            jump chapter2_underground_route

# ============================================================
# 第二章 · 双线分歧
# ============================================================

label chapter2_palace_route:
    scene bg palace throne_room with dissolve

    play music "royal_bgm_01"

    narrator "【第二章 · 王宫日常路线】"

    # 赛蕾娜带主角看王族陵墓
    if selena_route:
        call selena_tomb_scene

    # 艾尔西娅暴露半兽人身份
    if elsia_route:
        call elsia_discrimination_scene

    # 诺艾尔传递禁书
    if noel_route:
        call noel_forbidden_book_scene

    jump chapter3_revelation

label chapter2_underground_route:
    scene bg wasteland with dissolve

    play music "wanderer_bgm_01"

    narrator "【第二章 · 地下流浪路线】"

    # 莉拉带主角离开王都
    if lyra_route:
        call lyra_caravan_scene

    # 薇丝佩拉脱离教团
    if vespera_route:
        call vespera_defection_scene

    jump chapter3_revelation

# ------------------------------------------------------------
# 赛蕾娜陵墓场景
# ------------------------------------------------------------

label selena_tomb_scene:
    scene bg royal tomb with dissolve

    show selena sad

    selena "「这是王族陵墓。」"
    selena "「我带你来……是想让你看一块墓碑。」"

    narrator "（她指向一块刻着『第十八代王女』的墓碑）"

    tokito "「第十八代……？」"

    show selena crying
    selena "「我的姐姐们。都是 25 岁之前死的。」"
    selena "「这里埋的不是一个人……是一整个家族的诅咒。」"

    tokito "（她身上的诅咒纹路……）"
    tokito "（她是不是也……）"

    return

# ------------------------------------------------------------
# 艾尔西娅被排挤场景
# ------------------------------------------------------------

label elsia_discrimination_scene:
    scene bg training_field crowd with dissolve

    show elsia angry at center

    narrator "（同学甲）「杂种就是杂种，凭什么能当龙骑士？」"
    narrator "（同学乙）「还不是靠那张脸爬上去的。」"

    show elsia sad

    tokito "（艾尔西娅的拳头握紧，但一言不发）"

    menu:
        "站出来维护艾尔西娅":
            $ elsia_affection += 10
            jump elsia_stand_up

        "保持沉默观察":
            $ elsia_affection -= 5
            jump elsia_stand_down

# ------------------------------------------------------------
# 艾尔西娅站出来
# ------------------------------------------------------------

label elsia_stand_up:
    tokito "「血统不能定义一个人的价值。」"
    tokito "「她的拳头比你们所有人都硬——这就够了。」"

    show elsia surprised
    pause 0.5
    show elsia happy
    elsia "「……时人。」"

    return

# ------------------------------------------------------------
# 艾尔西娅沉默
# ------------------------------------------------------------

label elsia_stand_down:
    narrator "（艾尔西娅低着头离开训练场）"
    tokito "（她的背影……看起来很孤独）"

    return

# ------------------------------------------------------------
# 诺艾尔禁书场景
# ------------------------------------------------------------

label noel_forbidden_book_scene:
    scene bg forbidden_library with dissolve

    show noel handing_book with dissolve

    narrator "（诺艾尔将一本书偷偷塞到主角手中）"
    narrator "（书名：《永燃仪式真档》）"

    tokito "（这本书……）"

    menu:
        "当场阅读":
            $ truth_value += 15
            jump noel_book_read

        "带回房间仔细研究":
            $ truth_value += 20
            jump noel_book_take

label noel_book_read:
    narrator "（翻开第一页——）"
    narrator "「永燃仪式并非为了拯救太阳，而是为了独占永恒白昼。」"
    narrator "「仪式失败后，太阳开始缓慢死亡。」"
    narrator "「勇者召唤的真正目的——是用异界灵魂为太阳续命。」"

    tokito "（……每个勇者活不过三个月？）"
    tokito "（我的右手……）"

    show noel warning
    noel "「……」"
    narrator "（她指了指主角的右手）"
    narrator "（封咒环发出微弱的蓝光）"

    return

label noel_book_take:
    narrator "（主角将书藏在衣内带出禁书阁）"
    narrator "（当晚在房间里阅读——）"
    narrator "（内容与当场阅读相同）"

    return

# ------------------------------------------------------------
# 莉拉商队场景
# ------------------------------------------------------------

label lyra_caravan_scene:
    scene bg caravan with dissolve

    play music "wanderer_bgm_01"

    show lyra smiling

    lyra "「无星者……是边境流浪者、精灵难民、被王国驱逐的学者组成的组织。」"
    lyra "「我们保存着 200 年前的真相。」"

    tokito "「所以你们知道永燃仪式的真相？」"

    show lyra serious
    lyra "「比任何人都清楚。」"
    lyra "「但我们缺乏发声渠道……王国和晨曦塔封锁了一切。」"

    scene bg elven_ruins with dissolve

    show lyra sad
    lyra "「这里是六十年前精灵屠杀的废墟。」"
    lyra "「我的族人……全死在这里。」"
    lyra "「只因我们知道『启明歌』完整歌词。」"

    return

# ------------------------------------------------------------
# 薇丝佩拉脱教场景
# ------------------------------------------------------------

label vespera_defection_scene:
    scene bg rooftop moonlight with dissolve

    play music "cold_edge_style_01"

    show vespera conflicted

    vespera "「我跟踪你……一开始是为了杀你。」"
    vespera "「但现在……」"

    tokito "「你不必再当他们的工具。」"

    show vespera resolved
    vespera "「Vesper 教团高层……都是晨曦塔叛逃魔导师。」"
    vespera "「他们信奉永夜，却在暗中操控一切。」"


    return

# ============================================================
# 第三章 · 真相浮出
# ============================================================

label chapter3_revelation:
    scene black with fade

    narrator "【第三章 · 真相浮出】"

    play music "revelation_01"

    scene bg sunrise_shrinking with dissolve

    narrator "太阳不是自然死亡。"
    narrator "200 年前，初代国王 + 晨曦塔大长老用『永燃仪式』试图独占永恒白昼，失败后封锁了真相。"
    narrator "召唤勇者只是用异世界灵魂为『濒死的太阳』续命——每个勇者活不过三个月，因为他们的灵魂在被慢慢吃掉。"

    scene bg hand_transparent with dissolve

    show tokito concerned

    tokito "（我的右手已经开始透明化……）"

    $ hand_transparent = True
    $ truth_value += 20

    narrator "（倒计时正式开始。）"

    # 关键选项 - 是否公开真相
    menu:
        "将真相告诉所有人":
            $ truth_value += 40
            jump chapter3_truth_public

        "只告诉可信任的人":
            $ truth_value += 25
            jump chapter3_truth_private

        "独自寻找解决办法":
            jump chapter3_alone

label chapter3_truth_public:
        narrator "（主角在广场上公开了永燃仪式的真相）"
        narrator "（人群哗然，王国陷入混乱）"

        if selena_affection >= 80:
            call selena_truth_scene

        if elsia_affection >= 80:
            call elsia_rebellion

        jump chapter4_decisions

label chapter3_truth_private:
        narrator "（主角私下将真相告诉了几个信任的人）"

        if selena_route:
            call selena_truth_scene

        if noel_route:
            call noel_truth_scene

        jump chapter4_decisions

label chapter3_alone:
        narrator "（主角决定独自寻找解决办法）"
        narrator "（但时间……不多了）"

        jump chapter4_decisions

# ------------------------------------------------------------
# 第四章 · 五人各自抉择
# ------------------------------------------------------------

label chapter4_decisions:
    scene black with fade

    narrator "【第四章 · 五人各自抉择】"

    play music "final_chapter_01"

    # 赛蕾娜：背叛王族
    if selena_route and selena_affection >= 60:
        call selena_truth_scene

    # 艾尔西娅：发动起义
    if elsia_route and elsia_affection >= 60:
        call elsia_rebellion

    # 诺艾尔：撕毁封咒环
    if noel_route and noel_affection >= 60:
        call noel_sacrifice

    # 莉拉：教启明歌
    if lyra_route and lyra_affection >= 60:
        call lyra_sing

    # 薇丝佩拉：刺杀高层
    if vespera_route and vespera_affection >= 60:
        call vespera_assassin

    jump chapter5_final

# ------------------------------------------------------------
# 赛蕾娜真相场景
# ------------------------------------------------------------

label selena_truth_scene:
    scene bg palace throne_room with dissolve

    show selena resolved

    selena "「我决定公开诅咒纹路的真相。」"
    selena "「王族不需要靠谎言维生。」"

    return

# ------------------------------------------------------------
# 艾尔西娅起义
# ------------------------------------------------------------

label elsia_rebellion:
    scene bg training_field with dissolve

    show elsia determined

    elsia "「血统不能定义一个人——我要让所有人都知道这一点！」"
    elsia "「半兽人骑士团……成立！」"

    return

# ------------------------------------------------------------
# 诺艾尔牺牲
# ------------------------------------------------------------

label noel_truth_scene:
    scene bg forbidden_library with dissolve

    show noel resolved

    noel "「……」"
    narrator "（她开始写字，封咒环发出刺眼的光芒）"
    narrator "（突然吐血，但仍在写——）"

    narrator "（她用生命撕毁封咒环，写下完整真档）"

    return

label noel_sacrifice:
    scene bg forbidden_library with dissolve

    show noel resolved

    noel "「……」"
    narrator "（她开始写字，封咒环发出刺眼的光芒）"
    narrator "（突然吐血，但仍在写——）"

    narrator "（她用生命撕毁封咒环，写下完整真档）"

    return

# ------------------------------------------------------------
# 莉拉唱启明歌
# ------------------------------------------------------------

label lyra_sing:
    scene bg mountain_top with dissolve

    show lyra singing

    lyra "「我来教你唱完整版启明歌。」"
    lyra "「但要付出代价……你的声带可能会损毁。」"

    return

# ------------------------------------------------------------
# 薇丝佩拉刺杀
# ------------------------------------------------------------

label vespera_assassin:
    scene bg dark_alley with dissolve

    show vespera resolved

    vespera "「Vesper 教团高层……我会亲手解决他们。」"
    vespera "「这是我对你的承诺。」"

    return

# ============================================================
# 第五章 · 终焉之夜
# ============================================================

label chapter5_final:
    scene black with fade

    narrator "【第五章 · 终焉之夜】"

    play music "finale_01"

    scene bg altar with dissolve

    narrator "（晨曦塔核心：永燃祭坛）"
    narrator "（全员闯入，对决初代王后裔大祭司亚兰）"

    show arlan stern at center

    arlan "「你终于来了……第 13 位勇者。」"
    arlan "「但你的灵魂……已经不足以完成仪式了。」"

    tokito "「那就用别的东西来代替。」"

    # 根据好感度和真相值决定结局
    jump determine_ending

# ------------------------------------------------------------
# 新增场景：True End后日谈·七年后的黎明
# ------------------------------------------------------------

label true_end_epilogue:
    scene bg mountain_view_years_later with fade

    play music "morning_light_01"

    narrator "七年后的某个清晨。"

    narrator "镶银钟城已经重修了钟楼。钟声不再是记录黎明的倒数——只是报时。"

    narrator "你带着五个人，沿着城外那条你们七年前最后一次一起走过的山路，爬上城外的山顶。"

    narrator "山顶有一棵被雷劈过的老树——另一半却因为那次雷击激发了休眠芽，发出比原来更密的枝条。"

    show tokito normal at left with dissolve

    tokito "「七年前的今天，我在这里睁开眼，以为自己摔进了地狱。」"

    show selena happy at right with dissolve

    selena "「然后你看见了五段地狱里写出来的故事。」"

    show elsia proud at center_left with dissolve

    elsia "「别文绉绉的——七年了还是那味儿！快说重点！」"

    show lyra smiling at center_right with dissolve

    lyra "「哎呀哎呀，龙骑士还是这么没耐心——时人，你再不说重点，她真的会呼过来。」"

    show noel smiling at right_of_center with dissolve

    noel "「……」"
    narrator "（她现在能说话了。声音是哑的、轻的，像风铃在一片旧木窗上被风吹动时的声音。）"

    show vespera happy at far_right with dissolve

    vespera "「……你们都太肉麻了。我就一句——」"

    tokito "「我想说的重点是——物理学不接受用『爱』来解释恒星稳定。但这座山上的阳光，比任何理论都要温暖。」"

    noel "「书里最后一页。我写了这句话——『即便世界在熄灭，我也想最后一次看清你的脸。』」"

    noel "「现在不用『最后一次』了。现在可以——一直看。」"

    vespera "「……谢谢你不怕哭过的蓝。」"

    scene bg sunrise_music_swell with dissolve

    play music "vigil_final_01"

    narrator "山风拂过草地。草叶被风吹得倒伏，又弹起来，露出下面新发的嫩芽。"

    narrator "远处是镶银钟城的轮廓——钟楼在晨光里变成一道剪影。"

    narrator "六个人影在山顶的老树旁站成一排。太阳完整地升起来了——不是一百年来那种边缘溃烂的、病态的升起。"

    narrator "是健康的、完整的、已经七年没有再现过异常光轮的日出。"

    narrator "远处传来钟声。铜锡合金铸的新钟敲了一声。"

    narrator "那声音没有倒数，没有记录消耗的寿命。它只是……敲了一下。报晓。"

    narrator "「故事翻到这一页。下一页——」"

    narrator "「由我们一起来写。」"

    narrator "【True End「黎明之诗」达成】"

    jump credits

# ------------------------------------------------------------
# 新增场景：Bad End「被喂养的太阳」
# ------------------------------------------------------------

label bad_end_sequence:
    scene bg altar_alone with fade

    play music "tragic_end_01"

    narrator "决战当天。祭坛上。你一个人站着。"

    narrator "五芒星仍然是五芒星——但五个角是空的。"

    narrator "赛蕾娜没有来，她被父王下令囚禁在大殿下；"

    narrator "艾尔西娅没有来，她的半兽人驻军在临行前夜被圣庭骑士包围；"

    narrator "诺艾尔没有来，她在零号档案室被亚兰的人预先发现；"

    narrator "莉拉没有来，她的商队在边境被Vesper教团的封魔结界拦截；"

    narrator "薇丝佩拉没有来——她来了，但她一个人无法同时对抗整个教团高层。"

    narrator "你在祭坛中央，右手已经透明到肩膀。左手还能翻书——还能翻开最后一页。但这一页上只有你一个人的字迹。"

    show arlan stern at center with dissolve

    arlan "「你看到了吧——她们没有来。不是她们不想来，是因为『故事』不需要她们。」"

    arlan "「你只需要说两个字——然后一切就结束。两个世界的太阳会再亮二十年。翻吧。翻到最后一页。」"

    tokito "（你可以不翻。但那样她也会死。）"

    narrator "你翻了。"

    narrator "最后一页翻开。文字从纸面上浮出来："

    narrator "「第13位勇者。堂上时人。自愿献出所有故事。作为交换——两个世界获得二十年的太阳。」"

    narrator "你的右手开始从肩膀向胸口透明化。皮肤、肌肉、骨头——一层一层变成透光的薄膜。"

    narrator "你能看见自己的心跳——心脏隔着半透明的胸骨在跳。"

    narrator "然后钟声敲响了。太阳的边缘在仪式完成的瞬间亮了——两百年以来最亮的一次。"

    narrator "但这光只维持了片刻。然后太阳开始加速燃烧——不是被治愈，是被喂了错误的东西。"

    show arlan surprised

    arlan "「我又……又失败了……」"

    tokito "「……我没拯救世界。但我至少——没有一个人走。我回头看了。她们在窗外。在窗外看着……」"

    scene bg dark_map with fade

    narrator "你透明化的指尖最后能触到的是无名书的封面。"

    narrator "那空白里，隐约传来遥远的、不属此地的声音——五个声音叠在一起。"

    narrator "她们说——『我们不会让你一个人走的。』"

    narrator "【Bad End「被喂养的太阳」达成】"

    jump credits

# ------------------------------------------------------------
# 结局判定
# ------------------------------------------------------------

label determine_ending:
    # 计算总好感度
    $ total_affection = selena_affection + elsia_affection + noel_affection + lyra_affection + vespera_affection

    # True End 条件：5人羁绊≥80 + 真相值满
    if total_affection >= 400 and truth_value >= 100:
        jump ending_true

    # 各角色 Good End
    if selena_affection >= 90 and total_affection < 400:
        jump ending_selena

    if elsia_affection >= 90 and total_affection < 400:
        jump ending_elsia

    if noel_affection >= 90 and truth_value >= 80:
        jump ending_noel

    if lyra_affection >= 90 and total_affection < 400:
        jump ending_lyra

    if vespera_affection >= 90 and total_affection < 400:
        jump ending_vespera

    # Normal End 条件
    if total_affection >= 350:
        jump ending_normal

    # Bad End 条件
    jump ending_bad

# ------------------------------------------------------------
# True End「黎明之诗」
# ------------------------------------------------------------

label ending_true:
    scene bg sunrise_dawn with dissolve

    play music "vigil_true_end_01"

    narrator "（主角在祭坛上让 5 人围成五芒星）"
    narrator "（用各自的『心之火』代替主角灵魂喂太阳。）"
    narrator "（结果——产生超越仪式预期的反向共鸣）"

    scene bg sunrise_full with dissolve

    narrator "（太阳不是被续命，而是被治愈）"
    narrator "（黎明真正回归）"
    narrator "（所有人活下来）"

    scene bg mountain_view years_later with dissolve

    narrator "（片尾：七年后的某个清晨）"
    narrator "（主角带着 5 个朋友站在山顶看完整的日出）"

    tokito "「……物理学不接受这个结论。」"
    tokito "「但这次……我愿意接受。」"

    narrator "「即便世界在熄灭——」"
    narrator "「我也想最后一次，看清你的脸。」"

    narrator "【True End「黎明之诗」达成】"

    jump credits

# ------------------------------------------------------------
# Selena End「以星辰为名」
# ------------------------------------------------------------

label ending_selena:
    scene bg border_land with dissolve

    play music "selena_theme_01"

    narrator "（主角找到赛蕾娜诅咒解法）"
    narrator "（但代价是放弃晨曦塔）"
    narrator "（两人乔装离开王国）"

    show selena happy

    selena "「我们走到太阳还未落下的最后一片土地。」"
    selena "「在那里……耕一块田。」"

    narrator "（世界仍在缓慢入夜。）"
    narrator "（但赛蕾娜活了下来。）"

    narrator "【Selena End「以星辰为名」达成】"

    jump credits

# ------------------------------------------------------------
# Elsia End「赤鳞之誓」
# ------------------------------------------------------------

label ending_elsia:
    scene bg new_knights with dissolve

    play music "forge_01"

    narrator "（主角与艾尔西娅领导半兽人起义）"
    narrator "（建立一个不论血统的新骑士团）"

    show elsia proud

    elsia "「血统不能定义一个人——这是我们用拳头证明的！」"
    elsia "「迎接黎明吧！」"

    narrator "（世界仍会入夜。）"
    narrator "（但他们选择『在剩下的时间里，让活着的方式不一样』。）"

    narrator "【Elsia End「赤鳞之誓」达成】"

    jump credits

# ------------------------------------------------------------
# Noel End「沉默之书」
# ------------------------------------------------------------

label ending_noel:
    scene bg countryside with dissolve

    play music "whisper_01"

    narrator "（主角解开诺艾尔的封咒环）"
    narrator "（她写出史上第一本完整版《奥菲斯真档》）"
    narrator "（揭穿晨曦塔）"

    show noel smiling

    noel "「……谢谢你。」"
    noel "（她第一次用自己的声音说话）"
    noel "「现在……我可以写书了。」"

    narrator "（王国陷入动荡，但真相终于被人类知道。）"
    narrator "（两人隐居乡村，每天写书。）"

    narrator "【Noel End「沉默之书」达成】"

    jump credits

# ------------------------------------------------------------
# Lyra End「风之挽歌」
# ------------------------------------------------------------

label ending_lyra:
    scene bg altar_top with dissolve

    play music "winds_promise_01"

    narrator "（主角与莉拉登上晨曦塔顶）"
    narrator "（唱完整版启明歌）"
    narrator "（太阳的死亡被延后 7 年）"

    show lyra singing

    narrator "（代价：主角声带因共鸣而损毁，永远失声）"

    scene bg traveling with dissolve

    narrator "（但他们继续流浪，继续唱歌。）"
    narrator "（莉拉教会他用鲁特琴说话。）"

    show lyra happy

    lyra "「哎呀……你的琴声进步很大呢。」"
    lyra "「以后……我们一起唱。」"

    narrator "【Lyra End「风之挽歌」达成】"

    jump credits

# ------------------------------------------------------------
# Vespera End「破晓的刺客」
# ------------------------------------------------------------

label ending_vespera:
    scene bg bounty_hunters with dissolve

    play music "cold_edge_01"

    narrator "（主角与薇丝佩拉联手摧毁 Vesper 教团核心）"
    narrator "（她终于不必再杀任何人）"

    show vespera happy

    vespera "「我以为这把刀，只为杀你而存在。」"
    vespera "「但现在……它是为了保护你。」"

    narrator "（两人成为流浪赏金猎人）"
    narrator "（专门保护『被这个世界判了死刑的人』。）"

    narrator "【Vespera End「破晓的刺客」达成】"

    jump credits

# ------------------------------------------------------------
# Normal End「永夜共眠」
# ------------------------------------------------------------

label ending_normal:
    scene bg lakeside cottage with dissolve

    play music "last_light_01"

    narrator "（主角放弃拯救世界）"
    narrator "（在白昼最后熄灭的那一天）"
    narrator "（与心爱的人在湖畔搭了一间小屋）"

    tokito "「反正这世界本来就该结束了——"
    tokito "「能和你一起结束，已经够好。」"

    scene bg starry_sky with dissolve

    narrator "（星空降临的时候……）"

    narrator "【Normal End「永夜共眠」达成】"

    jump credits

# ------------------------------------------------------------
# Bad End「焚烬之塔」
# ------------------------------------------------------------

label ending_bad:
    scene bg burning_tower with dissolve
    play music "embers_01"
    narrator "（永燃祭坛失去最后的勇者灵魂）"
    narrator "（反向爆炸，太阳骤然熄灭）"
    scene bg dark_map with dissolve
    narrator "（世界提前 42 年陷入永夜）"
    narrator "（黑色的大陆地图上）"
    narrator "（只有 5 处微弱的光点——）"
    narrator "（那是最初遇到的那5位 ，活到最后一刻）"

    narrator "【Bad End「焚烬之塔」达成】"

    jump credits

# ------------------------------------------------------------
# 制作人员名单
# ------------------------------------------------------------

label credits:
    scene black with fade

    narrator "《黎明之诗 ~星辰永夜~》"
    narrator "Twilight Sonata: The Last Vigil"

    narrator "制作人员"
    narrator "企划：堂上时人"
    narrator "引擎：Ren'Py"

    narrator "感谢您的游玩"

    menu:
        "返回标题画面":
            return
