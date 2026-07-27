# 《黎明之诗 ~星辰永夜~》
# 角色定义文件

# 主角
define tokito = Character("堂上时人", color="#8B7355")

# 攻略角色
define selena = Character("赛蕾娜", color="#9370DB")  # 银发紫眸王女
define elsia = Character("艾尔西娅", color="#CD5C5C")  # 红发金瞳龙骑士
define noel = Character("诺艾尔", color="#708090")  # 黑长直灰瞳禁书管理员
define lyra = Character("莉拉", color="#20B2AA")  # 海蓝长发翡翠瞳精灵
define vespera = Character("薇丝佩拉", color="#9932CC")  # 紫发金瞳暗精灵

# 其他角色
define arlan = Character("亚兰", color="#DAA520")  # 大祭司
define narrator = Character(None, what_color="#0099FF")  # 旁白

# 好感度变量初始化
default selena_affection = 0
default elsia_affection = 0
default noel_affection = 0
default lyra_affection = 0
default vespera_affection = 0

# 真相值
default truth_value = 0

# 路线标记
default selena_route = False
default elsia_route = False
default noel_route = False
default lyra_route = False
default vespera_route = False

# 分支标记
default chapter1_branch = False  # False = 信任王国, True = 怀疑王国

# 游戏状态
default hand_transparent = False  # 右手透明化标记
default day_count = 0  # 天数计数

# 新增剧情标记
default first_night_selena = False
default lyra_song_fragment = False
default noel_deep_truth = False
default vespera_assassination_avoided = False
default chapter3_unity_achieved = False
default chapter4_climax_trigger = False

# 结局解锁标记
default selena_ending_unlocked = False
default elsia_ending_unlocked = False
default noel_ending_unlocked = False
default lyra_ending_unlocked = False
default vespera_ending_unlocked = False
