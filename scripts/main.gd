extends Control

# ============================================================
# GESSOU / 月奏
# GESSOU v9.4 - expanded Pixel VFX integration / multi-format loader
# Godot 4.7.x / GDScript
#
# Flow:
#   Title -> 6人から3人選択 -> 5連戦 -> Clear
#
# Battle:
#   流動CTBで行動者が回る
#   -> 技ごとの待ち時間で次行動位置が変化
#   -> 8拍で奏譜完成 / 月奏 / BREAK / 敵大技
#
# Assets expected:
#   res://assets/aicon/samurai_idle.png
#   res://assets/aicon/samurai_hurt.png
#   res://assets/aicon/sennin_idle.png
#   res://assets/aicon/sennin_hurt.png
#   res://assets/aicon/kasa_idle.png
#   res://assets/aicon/kasa_hurt.png
#   res://assets/aicon/miko_idle.png
#   res://assets/aicon/miko_hurt.png
#   res://assets/aicon/chochin_idle.png
#   res://assets/aicon/chochin_hurt.png
#   res://assets/aicon/jusoshi_idle.png
#   res://assets/aicon/jusoshi_hurt.png
#
# Bosses:
#   res://assets/boss/boss1.png ... boss5.png
#
# Audio:
#   res://assets/audio/title.mp3
#   res://assets/audio/bgm.mp3
#   res://assets/audio/kougeki.wav
#   res://assets/audio/time.wav
#   res://assets/audio/damage.wav
#   res://assets/audio/break.wav
#   res://assets/audio/command.wav
#
# Optional slash FX:
#   res://assets/fx/slash/*.png
# ============================================================

const PHASES: Array[String] = [
	"新月", "三日月", "上弦", "十三夜",
	"満月", "十六夜", "下弦", "晦"
]

const PHASE_ROMAN: Array[String] = [
	"新月", "三日月", "上弦", "十三夜",
	"満月", "十六夜", "下弦", "晦"
]

const MOON_COLORS: Array[Color] = [
	Color("#707784"),
	Color("#9fa6b3"),
	Color("#c9c8c1"),
	Color("#e7dcc4"),
	Color("#f3df9d"),
	Color("#d9cfb8"),
	Color("#aeb4bf"),
	Color("#7e8490")
]

const PHASE_TAGLINES: Array[String] = [
	"静寂が奏力を満たす",
	"初動が研ぎ澄まされる",
	"敵の構えを砕く刻",
	"満月へ力を仕込む夜",
	"最大火力と最大危険",
	"呪いと炎が尾を引く",
	"守りと癒やしの夜",
	"終わりが次の朔を呼ぶ"
]

const BOSS_DIR := "res://assets/boss"

const ICON_DIRS: Array[String] = [
	"res://assets/aicon",
	"res://assets/icons"
]

const AUDIO_TITLE := "res://assets/audio/title.mp3"
const AUDIO_BATTLE := "res://assets/audio/bgm.mp3"
const AUDIO_ATTACK := "res://assets/audio/kougeki.wav"
const AUDIO_TIME := "res://assets/audio/time.wav"
const AUDIO_DAMAGE := "res://assets/audio/damage.wav"
const AUDIO_BREAK := "res://assets/audio/break.wav"
const AUDIO_COMMAND := "res://assets/audio/command.wav"
const CUSTOM_FONT := "res://assets/fonts/YujiSyuku-Regular.ttf"

const SCORE_LENGTH := 8
const SLASH_FX_DIR := "res://assets/fx/slash"
const CTB_ENEMY_KEY := "@enemy"

const COL_BG := Color("#06070a")
const COL_PANEL := Color("#0d0f14f2")
const COL_PANEL_2 := Color("#12141af0")
const COL_PANEL_3 := Color("#181a21e8")
const COL_BORDER := Color("#34353d")
const COL_GOLD := Color("#c9a85d")
const COL_GOLD_BRIGHT := Color("#efd484")
const COL_TEXT := Color("#efe8dc")
const COL_MUTED := Color("#92949e")
const COL_RED := Color("#984049")
const COL_RED_BRIGHT := Color("#db6a72")
const COL_BLUE := Color("#6d84ad")
const COL_GREEN := Color("#6f9a7e")
const COL_BREAK := Color("#d0ad55")
const COL_PURPLE := Color("#9278a6")

# 「奏」は技そのものに内部音程を持たせる。
# 画面ではドレミを出さず、和風の音紋として表示する。
const NOTE_ORDER: Array[String] = ["ド", "レ", "ミ", "ファ", "ソ", "ラ", "シ"]
const NOTE_VALUE: Dictionary = {
	"ド": 0,
	"レ": 1,
	"ミ": 2,
	"ファ": 3,
	"ソ": 4,
	"ラ": 5,
	"シ": 6
}

const NEGATIVE_STATUSES: Array[String] = [
	"poison", "burn", "atk_down", "def_down", "seal"
]

const STATUS_NAMES: Dictionary = {
	"poison": "毒",
	"burn": "火傷",
	"atk_down": "攻↓",
	"def_down": "防↓",
	"seal": "封技",
	"blessing": "祝詞",
	"ward": "結界",
	"rage": "昂揚"
}

const CHARACTERS: Dictionary = {
	"侍": {
		"slug": "samurai",
		"role": "斬撃 / 単体火力",
		"instrument": "三味線",
		"hp": 142,
		"mana": 9,
		"atk": 39,
		"mag": 12,
		"def": 24,
		"res": 18,
		"spd": 31,
		"break": 17,
		"regen": 1,
		"skills": [
			{
				"id": "samurai_moon_slash",
				"name": "月断ち",
				"cost": 3,
				"target": "enemy",
				"desc": "斬撃1.55倍 / 崩し1.45倍 / 次巡の月を1つ余分に進める"
			},
			{
				"id": "samurai_iai",
				"name": "居合・朔",
				"cost": 5,
				"target": "enemy",
				"desc": "斬撃2.15倍。崩壊中はさらに1.5倍"
			},
			{
				"id": "samurai_red_mist",
				"name": "血霞",
				"cost": 4,
				"target": "enemy",
				"desc": "斬撃1.15倍 / 敵の防御低下3巡"
			},
			{
				"id": "samurai_swallow_break",
				"name": "燕返し",
				"cost": 3,
				"target": "enemy",
				"desc": "斬撃0.95倍 / 大技準備中は崩し大幅上昇"
			},
			{
				"id": "samurai_aftermoon",
				"name": "残月",
				"cost": 4,
				"target": "enemy",
				"desc": "斬撃1.45倍 / 敵崩壊中なら自身の構え+18"
			}
		]
	},
	"仙人": {
		"slug": "sennin",
		"role": "月相 / 奏力支援",
		"instrument": "尺八",
		"hp": 108,
		"mana": 15,
		"atk": 19,
		"mag": 36,
		"def": 19,
		"res": 31,
		"spd": 27,
		"break": 12,
		"regen": 2,
		"skills": [
			{
				"id": "sennin_thunder",
				"name": "仙雷",
				"cost": 3,
				"target": "enemy",
				"desc": "術式1.50倍"
			},
			{
				"id": "sennin_moon_turn",
				"name": "月転",
				"cost": 4,
				"target": "none",
				"desc": "次巡の月相を3つ進める / 自身の奏力+2"
			},
			{
				"id": "sennin_spring",
				"name": "霊泉",
				"cost": 5,
				"target": "party",
				"desc": "味方全員の奏力+3 / 小回復"
			},
			{
				"id": "sennin_wind_read",
				"name": "風読み",
				"cost": 3,
				"target": "party",
				"desc": "味方全員の構え+12 / 次の行動位置を少し前へ"
			},
			{
				"id": "sennin_moon_hold",
				"name": "月留め",
				"cost": 4,
				"target": "none",
				"desc": "大技準備中なら敵の行動位置を後ろへ送る"
			}
		]
	},
	"傘使い": {
		"slug": "kasa",
		"role": "防御 / 崩し",
		"instrument": "和太鼓",
		"hp": 158,
		"mana": 10,
		"atk": 27,
		"mag": 16,
		"def": 37,
		"res": 26,
		"spd": 20,
		"break": 22,
		"regen": 1,
		"skills": [
			{
				"id": "kasa_pierce",
				"name": "雨穿ち",
				"cost": 3,
				"target": "enemy",
				"desc": "打撃1.25倍 / 崩し2.15倍"
			},
			{
				"id": "kasa_counter",
				"name": "傘返し",
				"cost": 4,
				"target": "self",
				"desc": "防御しつつ、被弾時に50%反撃"
			},
			{
				"id": "kasa_ward",
				"name": "豪雨円陣",
				"cost": 5,
				"target": "party",
				"desc": "味方全体に結界2巡。被ダメージ20%軽減"
			},
			{
				"id": "kasa_rain_armor",
				"name": "雨鎧",
				"cost": 3,
				"target": "party",
				"desc": "味方全員の構え+20 / 結界1巡"
			},
			{
				"id": "kasa_thunder_guard",
				"name": "雷傘",
				"cost": 4,
				"target": "enemy",
				"desc": "打撃0.85倍 / 大技準備中は崩し性能が急上昇"
			}
		]
	},
	"巫女": {
		"slug": "miko",
		"role": "回復 / 浄化",
		"instrument": "神楽鈴",
		"hp": 116,
		"mana": 14,
		"atk": 17,
		"mag": 39,
		"def": 21,
		"res": 35,
		"spd": 25,
		"break": 9,
		"regen": 2,
		"skills": [
			{
				"id": "miko_heal",
				"name": "神楽祓",
				"cost": 3,
				"target": "ally",
				"desc": "味方1人を大きく回復"
			},
			{
				"id": "miko_cleanse",
				"name": "禊",
				"cost": 4,
				"target": "party",
				"desc": "味方全体を小回復し、状態異常を解除"
			},
			{
				"id": "miko_bless",
				"name": "月詠祝詞",
				"cost": 5,
				"target": "party",
				"desc": "味方全体の攻撃・術式を20%強化 3巡"
			},
			{
				"id": "miko_bell_guard",
				"name": "鈴守",
				"cost": 3,
				"target": "ally",
				"desc": "味方1人を小回復 / 構え+35"
			},
			{
				"id": "miko_divine_descent",
				"name": "神降ろし",
				"cost": 6,
				"target": "party",
				"desc": "味方全体を回復 / 祝詞2巡 / 結界1巡 / 次巡の月を1つ余分に進める"
			}
		]
	},
	"提灯使い": {
		"slug": "chochin",
		"role": "妖火 / 継続火力",
		"instrument": "琵琶",
		"hp": 122,
		"mana": 12,
		"atk": 25,
		"mag": 35,
		"def": 18,
		"res": 24,
		"spd": 29,
		"break": 13,
		"regen": 1,
		"skills": [
			{
				"id": "chochin_foxfire",
				"name": "狐火",
				"cost": 3,
				"target": "enemy",
				"desc": "妖術1.35倍 / 火傷3巡"
			},
			{
				"id": "chochin_lantern_drop",
				"name": "灯籠落とし",
				"cost": 4,
				"target": "enemy",
				"desc": "妖術1.85倍。火傷中はさらに1.25倍 / 次巡の月を1つ余分に進める"
			},
			{
				"id": "chochin_dim",
				"name": "迷い火",
				"cost": 4,
				"target": "enemy",
				"desc": "妖術1.05倍 / 敵の攻撃低下3巡"
			},
			{
				"id": "chochin_ember_step",
				"name": "鬼火渡り",
				"cost": 3,
				"target": "enemy",
				"desc": "妖術1.00倍 / 火傷中なら追加発火し、火傷を1巡延長"
			},
			{
				"id": "chochin_burst",
				"name": "灯爆ぜ",
				"cost": 5,
				"target": "enemy",
				"desc": "妖術1.65倍 / 火傷を消費すると威力2.20倍・崩し強化"
			}
		]
	},
	"呪詛師": {
		"slug": "jusoshi",
		"role": "呪詛 / 弱体",
		"instrument": "鉦",
		"hp": 102,
		"mana": 16,
		"atk": 21,
		"mag": 41,
		"def": 16,
		"res": 28,
		"spd": 23,
		"break": 11,
		"regen": 1,
		"skills": [
			{
				"id": "jusoshi_poison",
				"name": "蝕呪",
				"cost": 3,
				"target": "enemy",
				"desc": "呪術1.10倍 / 毒4巡"
			},
			{
				"id": "jusoshi_bind",
				"name": "骨縛り",
				"cost": 4,
				"target": "enemy",
				"desc": "呪術0.85倍 / 攻撃・防御低下3巡"
			},
			{
				"id": "jusoshi_grudge",
				"name": "怨返し",
				"cost": 5,
				"target": "enemy",
				"desc": "呪術1.80倍。敵の弱体数に応じて最大+45% / 次巡の月を1つ余分に進める"
			},
			{
				"id": "jusoshi_extend",
				"name": "呪継ぎ",
				"cost": 4,
				"target": "enemy",
				"desc": "呪術0.80倍 / 敵の弱体をすべて1巡延長"
			},
			{
				"id": "jusoshi_abyss_mark",
				"name": "奈落印",
				"cost": 5,
				"target": "enemy",
				"desc": "呪術1.25倍 / 弱体数が多いほど崩し性能上昇"
			}
		]
	},
	"くノ一": {
		"slug": "kunoichi",
		"role": "迅術 / 撹乱",
		"instrument": "篠笛",
		"hp": 104,
		"mana": 12,
		"atk": 34,
		"mag": 20,
		"def": 18,
		"res": 22,
		"spd": 42,
		"break": 14,
		"regen": 1,
		"skills": [
			{"id":"kunoichi_shadow_bind", "name":"影縫い", "cost":3, "target":"enemy", "desc":"斬撃1.05倍 / 敵の次行動を遅らせる"},
			{"id":"kunoichi_poison_star", "name":"毒手裏剣", "cost":3, "target":"enemy", "desc":"斬撃0.90倍 / 毒3巡"},
			{"id":"kunoichi_mist_step", "name":"霞走り", "cost":2, "target":"enemy", "desc":"斬撃0.75倍 / 待ち極小 / 自身の構え+12"},
			{"id":"kunoichi_ninja_return", "name":"忍返し", "cost":4, "target":"self", "desc":"防御・反撃 / 次の行動を早める"},
			{"id":"kunoichi_scatter_star", "name":"乱れ星", "cost":5, "target":"enemy", "desc":"斬撃1.80倍 / 崩し1.55倍 / 次巡の月を1つ余分に進める"}
		]
	},
	"酒呑童子": {
		"slug": "shuten",
		"role": "豪腕 / 酔気",
		"instrument": "大太鼓",
		"hp": 178,
		"mana": 10,
		"atk": 43,
		"mag": 25,
		"def": 31,
		"res": 21,
		"spd": 18,
		"break": 24,
		"regen": 1,
		"skills": [
			{"id":"shuten_oni_smash", "name":"鬼砕き", "cost":4, "target":"enemy", "desc":"打撃1.75倍 / 崩し2.10倍"},
			{"id":"shuten_sake_flame", "name":"酒炎", "cost":3, "target":"enemy", "desc":"妖火1.25倍 / 火傷3巡 / 自身の構え+8"},
			{"id":"shuten_drink_dry", "name":"呑み干し", "cost":3, "target":"self", "desc":"生命18%・奏力2・構え30回復"},
			{"id":"shuten_drunk_barrage", "name":"酔狂乱打", "cost":5, "target":"enemy", "desc":"打撃2.15倍 / 昂揚中はさらに1.25倍"},
			{"id":"shuten_hyakki_feast", "name":"百鬼宴", "cost":5, "target":"party", "desc":"味方全体の構え+14 / 自身に昂揚3巡 / 次巡の月を1つ余分に進める"}
		]
	},
	"神楽師": {
		"slug": "kagurashi",
		"role": "舞 / 奏譜支援",
		"instrument": "龍笛",
		"hp": 112,
		"mana": 15,
		"atk": 18,
		"mag": 37,
		"def": 20,
		"res": 34,
		"spd": 32,
		"break": 10,
		"regen": 2,
		"skills": [
			{"id":"kagurashi_rhythm_dance", "name":"拍子舞", "cost":3, "target":"party", "desc":"味方全体の構え+8 / 次の行動を少し前へ"},
			{"id":"kagurashi_double_beat", "name":"重ね拍子", "cost":4, "target":"none", "desc":"同じ音紋を奏譜へ二拍刻む"},
			{"id":"kagurashi_repose", "name":"鎮魂舞", "cost":4, "target":"party", "desc":"味方全体を小回復 / 毒・火傷を祓う / 構え+10"},
			{"id":"kagurashi_moon_call", "name":"月招き", "cost":4, "target":"none", "desc":"次巡の月相を2つ進める / 味方全体の奏力+1"},
			{"id":"kagurashi_wild_kagura", "name":"荒神楽", "cost":6, "target":"enemy", "desc":"術式1.65倍 / 奏譜6拍以上なら2.25倍・崩し強化"}
		]
	},
	"猫又": {
		"slug": "nekomata",
		"role": "妖術 / 追撃",
		"instrument": "小鼓",
		"hp": 118,
		"mana": 13,
		"atk": 27,
		"mag": 38,
		"def": 19,
		"res": 26,
		"spd": 36,
		"break": 12,
		"regen": 1,
		"skills": [
			{"id":"nekomata_cat_fire", "name":"猫火", "cost":3, "target":"enemy", "desc":"妖術1.20倍 / 火傷3巡"},
			{"id":"nekomata_twin_tail", "name":"双尾裂き", "cost":3, "target":"enemy", "desc":"斬撃1.15倍 / 崩し1.20倍"},
			{"id":"nekomata_feint", "name":"猫騙し", "cost":4, "target":"enemy", "desc":"妖術0.70倍 / 敵の行動を遅らせ、攻撃低下2巡"},
			{"id":"nekomata_soul_lick", "name":"魂舐め", "cost":4, "target":"enemy", "desc":"妖術1.05倍 / 与えた傷の半分を回復 / 弱体中なら奏力+1"},
			{"id":"nekomata_bakeneko_dance", "name":"化生乱舞", "cost":6, "target":"enemy", "desc":"妖術2.00倍 / 弱体2種以上なら2.50倍 / 次巡の月を1つ余分に進める"}
		]
	}

}
const ENEMIES: Array[Dictionary] = [
	{
		"id": "moon_oni",
		"name": "月喰らいの鬼",
		"subtitle": "",
		"desc": "",
		"glyph": "鬼",
		"hp": 560,
		"mana": 0,
		"atk": 31,
		"mag": 18,
		"def": 22,
		"res": 18,
		"spd": 18,
		"break_max": 92,
		"status_resist": 0
	},
	{
		"id": "fire_spider",
		"name": "狐火蜘蛛",
		"subtitle": "",
		"desc": "",
		"glyph": "蛛",
		"hp": 690,
		"mana": 0,
		"atk": 29,
		"mag": 31,
		"def": 24,
		"res": 25,
		"spd": 28,
		"break_max": 108,
		"status_resist": 0
	},
	{
		"id": "bone_monk",
		"name": "骨笛法師",
		"subtitle": "",
		"desc": "",
		"glyph": "骨",
		"hp": 820,
		"mana": 0,
		"atk": 34,
		"mag": 35,
		"def": 28,
		"res": 35,
		"spd": 24,
		"break_max": 122,
		"status_resist": 1
	},
	{
		"id": "dark_tengu",
		"name": "常闇天狗",
		"subtitle": "",
		"desc": "",
		"glyph": "天",
		"hp": 960,
		"mana": 0,
		"atk": 39,
		"mag": 37,
		"def": 31,
		"res": 30,
		"spd": 39,
		"break_max": 138,
		"status_resist": 1
	},
	{
		"id": "eclipse_lady",
		"name": "月蝕ノ御前",
		"subtitle": "",
		"desc": "",
		"glyph": "蝕",
		"hp": 1380,
		"mana": 0,
		"atk": 43,
		"mag": 46,
		"def": 36,
		"res": 38,
		"spd": 33,
		"break_max": 168,
		"status_resist": 1
	}
]

var screen_mode: String = "title"

var title_player: AudioStreamPlayer
var battle_player: AudioStreamPlayer
var attack_player: AudioStreamPlayer
var time_player: AudioStreamPlayer
var damage_player: AudioStreamPlayer
var break_player: AudioStreamPlayer
var impact_player: AudioStreamPlayer
var command_player: AudioStreamPlayer

var screen_layer: Control
var effect_layer: Control

var selected_party: Array[String] = []
var party: Array[String] = []
var party_state: Dictionary = {}
var enemy_index: int = 0
var enemy_state: Dictionary = {}

var round_number: int = 1
var total_rounds: int = 0
var moon_index: int = 1
var round_moon_bonus: int = 0
var beat: int = 0
var measure: int = 1
var measure_notes: Array[Dictionary] = []
var last_measure_text: String = "まだ音は重なっていない。"

var pending_actions: Dictionary = {}
var command_cursor: int = 0
var planning_order: Array[String] = []
var busy: bool = false
var enemy_break_announced: bool = false

# 奏システム / 月奏印
var moon_seals: int = 0
var ultimate_ready: Dictionary = {}
var combo_damage_rounds: int = 0
var combo_break_rounds: int = 0
var last_combo_name: String = "未完成"
var active_score_note: String = ""

var motes: Array[Vector2] = []
var slash_alpha: float = 0.0
var flash_alpha: float = 0.0
var moon_pulse: float = 0.0
var shake_amount: float = 0.0

# Selection screen refs
var selection_counter_label: Label
var selection_start_button: Button
var selection_cards: Dictionary = {}

# Battle refs
var battle_root: Control
var battle_no_label: Label
var moon_label: Label
var moon_roman_label: Label
var moon_effect_label: Label
var phase_labels: Array[Label] = []

# 行動順バー
var turn_order_bar: Control
var turn_order_runtime: Array[Dictionary] = []
var turn_order_index: int = -1

# 流動CTB
var ctb_times: Dictionary = {}
var ctb_clock: float = 0.0
var ctb_current_actor: String = ""
var ctb_initialized: bool = false
var ctb_event_count: int = 0
var ctb_preview_action: Dictionary = {}
var ctb_last_wait: Dictionary = {}
var ctb_first_intro: bool = true
var score_banner_lock_until: int = 0
var ui_font: Font
var display_font: Font
var score_guide_overlay: Control
var skill_menu_overlay: Control
var skill_overlay_preview_label: Label
var moon_table_overlay: Control
var tactical_preview_label: Label
var score_panel_ref: PanelContainer
var beat_connectors: Array[ColorRect] = []
var enemy_state_fx_layer: Control
var enemy_state_fx_signature: String = ""
var enemy_hit_flash_until_msec: int = 0
var hit_stop_serial: int = 0
var enemy_phase_transition_running: bool = false

# 演出用の実行時生成素材
var particle_dot_texture: Texture2D
var pixel_vfx_cache: Dictionary = {}

var enemy_subtitle_label: Label
var enemy_name_label: Label
var enemy_desc_label: Label
var enemy_glyph_label: Label
var enemy_portrait: TextureRect
var enemy_portrait_frame: PanelContainer
var enemy_status_label: Label
var enemy_intent_label: Label
var enemy_hp_bar: ProgressBar
var enemy_break_bar: ProgressBar

var measure_label: Label
var composition_label: Label
var combo_forecast_label: Label
var resonance_label: Label
var moon_seal_label: Label
var beat_cells: Array[Dictionary] = []

var command_title_label: Label
var command_sub_label: Label
var moon_forecast_label: Label
var command_box: VBoxContainer
var log_label: RichTextLabel

var party_cards: Dictionary = {}
var battle_overlay: Control
var hurt_animating: Dictionary = {}
var moon_intro_running: bool = false


func _ready() -> void:
	randomize()
	setup_fonts()

	for i in range(90):
		motes.append(Vector2(randf(), randf()))

	build_audio()

	screen_layer = Control.new()
	screen_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen_layer)

	effect_layer = Control.new()
	effect_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(effect_layer)

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	show_title_screen()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			if skill_menu_overlay != null and is_instance_valid(skill_menu_overlay):
				close_skill_menu()
				get_viewport().set_input_as_handled()
				return

			if moon_table_overlay != null and is_instance_valid(moon_table_overlay):
				close_moon_table()
				get_viewport().set_input_as_handled()
				return

			if score_guide_overlay != null and is_instance_valid(score_guide_overlay):
				close_score_guide()
				get_viewport().set_input_as_handled()
				return

		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



# ============================================================
# FONTS
# ============================================================

func setup_fonts() -> void:
	# 主人が選んだ Yuji Syuku を最優先。
	# フォント本体は res://assets/fonts/YujiSyuku-Regular.ttf に置けば即反映。
	if ResourceLoader.exists(CUSTOM_FONT):
		var custom := load(CUSTOM_FONT) as Font
		if custom != null:
			ui_font = custom
			display_font = custom
			return

	# 未配置でもゲームが止まらないようOSフォントへフォールバック。
	var body := SystemFont.new()
	body.font_names = PackedStringArray([
		"Hiragino Kaku Gothic ProN",
		"Yu Gothic UI",
		"Yu Gothic",
		"Noto Sans CJK JP",
		"sans-serif"
	])
	body.allow_system_fallback = true
	body.font_weight = 500
	ui_font = body

	var display := SystemFont.new()
	display.font_names = PackedStringArray([
		"Hiragino Mincho ProN",
		"Yu Mincho",
		"Noto Serif CJK JP",
		"serif"
	])
	display.allow_system_fallback = true
	display.font_weight = 700
	display_font = display

func apply_body_font(control: Control) -> void:
	if ui_font != null:
		control.add_theme_font_override("font", ui_font)


func apply_display_font(control: Control) -> void:
	if display_font != null:
		control.add_theme_font_override("font", display_font)


# ============================================================
# AUDIO
# ============================================================

func build_audio() -> void:
	setup_runtime_audio_buses()

	title_player = make_audio_player(-8.0)
	battle_player = make_audio_player(-9.0)
	attack_player = make_audio_player(-2.0)
	time_player = make_audio_player(-5.0)
	damage_player = make_audio_player(-2.0)
	break_player = make_audio_player(-1.0)
	impact_player = make_audio_player(-9.0)
	command_player = make_audio_player(-7.0)

	title_player.bus = "音楽"
	battle_player.bus = "音楽"
	attack_player.bus = "打撃"
	damage_player.bus = "打撃"
	break_player.bus = "打撃"
	impact_player.bus = "演出"
	time_player.bus = "演出"
	command_player.bus = "操作"

	title_player.stream = load_audio(AUDIO_TITLE)
	battle_player.stream = load_audio(AUDIO_BATTLE)
	attack_player.stream = load_audio(AUDIO_ATTACK)
	time_player.stream = load_audio(AUDIO_TIME)
	damage_player.stream = load_audio(AUDIO_DAMAGE)
	break_player.stream = load_audio(AUDIO_BREAK)
	impact_player.stream = load_audio(AUDIO_ATTACK)
	command_player.stream = load_audio(AUDIO_COMMAND)

	set_stream_loop(title_player.stream)
	set_stream_loop(battle_player.stream)


func setup_runtime_audio_buses() -> void:
	ensure_audio_bus("音楽")
	ensure_audio_bus("打撃")
	ensure_audio_bus("演出")
	ensure_audio_bus("操作")

	# 打撃音は少し残響を足し、同じ素材でも重さを出す。
	var hit_index := AudioServer.get_bus_index("打撃")
	if hit_index >= 0 and AudioServer.get_bus_effect_count(hit_index) == 0:
		var hit_reverb := AudioEffectReverb.new()
		hit_reverb.room_size = 0.35
		hit_reverb.damping = 0.72
		hit_reverb.wet = 0.10
		hit_reverb.dry = 1.0
		AudioServer.add_bus_effect(hit_index, hit_reverb)

	# 月奏・BREAK・大技などの演出音は残響を長めにする。
	var fx_index := AudioServer.get_bus_index("演出")
	if fx_index >= 0 and AudioServer.get_bus_effect_count(fx_index) == 0:
		var fx_reverb := AudioEffectReverb.new()
		fx_reverb.room_size = 0.72
		fx_reverb.damping = 0.50
		fx_reverb.wet = 0.22
		fx_reverb.dry = 0.90
		AudioServer.add_bus_effect(fx_index, fx_reverb)


func ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)

func make_audio_player(volume_db_value: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = volume_db_value
	add_child(player)
	return player


func load_audio(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("Audio not found: " + path)
		return null
	return load(path) as AudioStream


func set_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return

	if stream is AudioStreamMP3:
		var mp3: AudioStreamMP3 = stream as AudioStreamMP3
		mp3.loop = true
	elif stream is AudioStreamOggVorbis:
		var ogg: AudioStreamOggVorbis = stream as AudioStreamOggVorbis
		ogg.loop = true


func play_one_shot(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()



func play_generated_sweep(
	start_hz: float,
	end_hz: float,
	duration: float = 0.30,
	amplitude: float = 0.16
) -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = maxf(0.20, duration + 0.08)

	var player := AudioStreamPlayer.new()
	player.stream = generator
	player.bus = "演出"
	player.volume_db = -5.0
	add_child(player)
	player.play()

	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		player.queue_free()
		return

	var frame_count := int(generator.mix_rate * duration)
	var phase := 0.0
	for i in range(frame_count):
		var progress := float(i) / maxf(1.0, float(frame_count - 1))
		var hz := lerpf(start_hz, end_hz, progress)
		phase += TAU * hz / generator.mix_rate
		var envelope := sin(PI * progress)
		envelope *= envelope
		var sample := sin(phase) * amplitude * envelope
		# 2倍音を薄く重ね、単純な電子音っぽさを減らす。
		sample += sin(phase * 2.0) * amplitude * 0.18 * envelope
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.12).timeout.connect(player.queue_free)


func play_generated_score_sound(is_moon_combo: bool) -> void:
	if is_moon_combo:
		play_generated_sweep(132.0, 660.0, 0.58, 0.18)
		play_generated_sweep(198.0, 990.0, 0.58, 0.08)
	else:
		play_generated_sweep(180.0, 460.0, 0.42, 0.14)


func play_generated_break_sound() -> void:
	play_generated_sweep(115.0, 52.0, 0.34, 0.20)


func play_generated_warning_sound() -> void:
	play_generated_sweep(96.0, 68.0, 0.48, 0.14)


# ============================================================
# SCREEN FLOW
# ============================================================

func clear_screen() -> void:
	# Signal callback中にControlをfree()するとGodot 4.7で
	# "Object is locked" -> editor/game crashになることがある。
	# そのフレームでは非表示・入力無効にし、queue_free()で安全に破棄する。
	for child in screen_layer.get_children():
		if child is Control:
			var control_child := child as Control
			control_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			control_child.hide()
		child.queue_free()

	for effect_child in effect_layer.get_children():
		if effect_child is Control:
			var effect_control := effect_child as Control
			effect_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			effect_control.hide()
		effect_child.queue_free()

	selection_cards.clear()
	phase_labels.clear()
	beat_cells.clear()
	party_cards.clear()

	battle_root = null
	battle_overlay = null
	log_label = null
	score_guide_overlay = null
	skill_menu_overlay = null
	skill_overlay_preview_label = null
	moon_table_overlay = null


func show_title_screen() -> void:
	clear_screen()
	screen_mode = "title"

	battle_player.stop()
	if title_player.stream != null and not title_player.playing:
		title_player.play()

	var shade := ColorRect.new()
	shade.color = Color("#05060878")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(center)

	var frame := make_panel(Color("#0b0d12f5"), Color("#55472f"), 24, 1)
	frame.custom_minimum_size = Vector2(920, 610)
	center.add_child(frame)

	var margin := MarginContainer.new()
	set_margins(margin, 78, 64, 78, 60)
	frame.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 15)
	margin.add_child(content)

	var small := make_label("高難易度・和風戦術戦闘", 12, Color("#88775b"))
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(small)

	var title := make_label("月　奏", 78, COL_TEXT)
	apply_display_font(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(title)

	var roman := make_label("月を奏で、五夜を越えよ", 15, Color("#b39763"))
	roman.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(roman)

	var rule := ColorRect.new()
	rule.color = Color("#665034")
	rule.custom_minimum_size = Vector2(430, 1)
	content.add_child(rule)

	var copy := make_label(
		"月と奏譜を読み、流れる行動順の中で八拍を組み上げる。\n"
		+ "技の重さで次の行動位置が変わる。",
		18,
		Color("#aaa69e")
	)
	copy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(copy)

	var system_text := make_label(
		"月相 × 奏譜 × 双方の崩し × 大技予兆",
		13,
		Color("#776f62")
	)
	system_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(system_text)

	var start_button := make_primary_button("はじめる", 300)
	start_button.pressed.connect(show_party_select_screen)
	content.add_child(start_button)

	var hint := make_label("F11：フルスクリーン切替", 10, Color("#555861"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)

	queue_redraw()


func show_party_select_screen() -> void:
	clear_screen()
	screen_mode = "select"
	selected_party.clear()

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 70
	root.offset_top = 42
	root.offset_right = -70
	root.offset_bottom = -48
	root.add_theme_constant_override("separation", 20)
	screen_layer.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)

	var head_box := VBoxContainer.new()
	head_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(head_box)

	var kicker := make_label("編　成", 11, Color("#8a7654"))
	head_box.add_child(kicker)

	var heading := make_label("三人を選ぶ", 40, COL_TEXT)
	head_box.add_child(heading)

	var explain := make_label(
		"10人から3人を選択。戦闘では行動順の早い者から作戦を決めます。",
		13,
		COL_MUTED
	)
	head_box.add_child(explain)

	var right_head := VBoxContainer.new()
	right_head.custom_minimum_size = Vector2(360, 0)
	right_head.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(right_head)

	selection_counter_label = make_label("0 / 3", 26, COL_GOLD_BRIGHT)
	selection_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_head.add_child(selection_counter_label)

	var counter_sub := make_label("選択人数", 10, COL_MUTED)
	counter_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_head.add_child(counter_sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)

	for char_name in CHARACTERS.keys():
		var card: Dictionary = build_selection_card(str(char_name))
		grid.add_child(card["panel"])
		selection_cards[str(char_name)] = card

	var footer := HBoxContainer.new()
	footer.custom_minimum_size = Vector2(0, 66)
	root.add_child(footer)

	var back_button := make_secondary_button("タイトルへ", 180)
	back_button.pressed.connect(show_title_screen)
	footer.add_child(back_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	selection_start_button = make_primary_button("この三人で五夜へ", 300)
	selection_start_button.disabled = true
	selection_start_button.pressed.connect(start_new_run)
	footer.add_child(selection_start_button)

	refresh_party_selection()
	queue_redraw()


func build_selection_card(char_name: String) -> Dictionary:
	var data: Dictionary = CHARACTERS[char_name]
	var panel := make_panel(Color("#0d0f15f5"), Color("#2d3038"), 16, 1)
	panel.custom_minimum_size = Vector2(0, 250)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	set_margins(margin, 16, 16, 16, 14)
	panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	outer.add_child(top)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(112, 136)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#17191f")
	portrait_style.border_color = Color("#413b31")
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(10)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	top.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = get_portrait_texture(char_name, false)
	portrait_frame.add_child(portrait)

	if portrait.texture == null:
		var fallback := make_label(char_name.left(1), 52, Color("#756b5a"))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait_frame.add_child(fallback)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	top.add_child(info)

	var char_label := make_label(char_name, 24, COL_TEXT)
	info.add_child(char_label)

	var role_label := make_label(
		str(data["role"]) + "　・　" + str(data["instrument"]),
		10,
		Color("#8f8f96")
	)
	info.add_child(role_label)

	var stats := make_label(
		"生命 %d　奏力 %d\n攻撃 %d　術式 %d\n防御 %d　耐術 %d　速さ %d　崩し %d"
		% [
			int(data["hp"]),
			int(data["mana"]),
			int(data["atk"]),
			int(data["mag"]),
			int(data["def"]),
			int(data["res"]),
			int(data["spd"]),
			int(data["break"])
		],
		11,
		Color("#9b9da5")
	)
	info.add_child(stats)

	var skill_names: Array[String] = []
	for skill_variant in data["skills"]:
		var skill_data: Dictionary = skill_variant
		skill_names.append("%s %s" % [get_note_display(get_skill_note_type(str(skill_data["id"]))), str(skill_data["name"])])

	var skills_label := make_label(
		"固有技　" + " / ".join(skill_names),
		10,
		Color("#726d63")
	)
	skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(skills_label)

	var select_button := make_secondary_button("選択", 0)
	select_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select_button.pressed.connect(toggle_character_selection.bind(char_name))
	outer.add_child(select_button)

	return {
		"panel": panel,
		"button": select_button,
		"portrait": portrait
	}


func toggle_character_selection(char_name: String) -> void:
	play_command_sound(1.02)
	if selected_party.has(char_name):
		selected_party.erase(char_name)
	elif selected_party.size() < 3:
		selected_party.append(char_name)

	refresh_party_selection()


func refresh_party_selection() -> void:
	selection_counter_label.text = "%d / 3" % selected_party.size()
	selection_start_button.disabled = selected_party.size() != 3

	for char_name in selection_cards.keys():
		var card: Dictionary = selection_cards[char_name]
		var panel: PanelContainer = card["panel"] as PanelContainer
		var select_button: Button = card["button"] as Button

		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

		if selected_party.has(str(char_name)):
			var order: int = selected_party.find(str(char_name)) + 1
			style.border_color = COL_GOLD
			style.set_border_width_all(2)
			style.bg_color = Color("#171611f3")
			select_button.text = "選択中　%02d" % order
		else:
			style.border_color = Color("#2d3038")
			style.set_border_width_all(1)
			style.bg_color = Color("#0d0f15f5")
			select_button.text = "選択"

		panel.add_theme_stylebox_override("panel", style)


func start_new_run() -> void:
	if selected_party.size() != 3:
		return

	party = selected_party.duplicate()
	enemy_index = 0
	round_number = 1
	total_rounds = 0
	moon_index = 1
	round_moon_bonus = 0
	beat = 0
	measure = 1
	measure_notes.clear()
	last_measure_text = "まだ音は重なっていない。"

	title_player.stop()
	if battle_player.stream != null:
		battle_player.play()

	prepare_party_for_battle()
	prepare_enemy(enemy_index)
	show_battle_screen()
	start_enemy_intro_sequence()


func show_battle_screen() -> void:
	clear_screen()
	screen_mode = "battle"

	battle_root = Control.new()
	battle_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(battle_root)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 30
	root.offset_top = 16
	root.offset_right = -30
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 9)
	battle_root.add_child(root)

	build_battle_header(root)
	build_battle_center(root)
	build_battle_party_row(root)

	refresh_battle_ui()
	queue_redraw()


func build_battle_header(root: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.custom_minimum_size = Vector2(0, 88)
	top.add_theme_constant_override("separation", 18)
	root.add_child(top)

	var brand := VBoxContainer.new()
	brand.custom_minimum_size = Vector2(190, 0)
	top.add_child(brand)

	var title := make_label("月　奏", 30, COL_TEXT)
	apply_display_font(title)
	brand.add_child(title)

	battle_no_label = make_label("", 11, Color("#89765a"))
	brand.add_child(battle_no_label)

	var order_box := VBoxContainer.new()
	order_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	order_box.add_theme_constant_override("separation", 5)
	top.add_child(order_box)

	var order_head := HBoxContainer.new()
	order_box.add_child(order_head)
	order_head.add_child(make_label("行動順", 12, Color("#b49a67")))

	var flow := make_label("　← 現在　　　　　　　　　　　　　　　未来 →", 9, Color("#62656d"))
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	order_head.add_child(flow)

	turn_order_bar = Control.new()
	turn_order_bar.custom_minimum_size = Vector2(0, 56)
	turn_order_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	turn_order_bar.clip_contents = true
	order_box.add_child(turn_order_bar)

	var moon_box := VBoxContainer.new()
	moon_box.custom_minimum_size = Vector2(270, 0)
	moon_box.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(moon_box)

	var current_label := make_label("今巡の月　／　巡終了まで固定", 9, Color("#6f727a"))
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moon_box.add_child(current_label)

	moon_roman_label = make_label("", 1, Color(0, 0, 0, 0))
	moon_roman_label.visible = false
	moon_box.add_child(moon_roman_label)

	moon_label = make_label("", 25, COL_GOLD_BRIGHT)
	moon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moon_box.add_child(moon_label)

	moon_effect_label = make_label("", 9, COL_MUTED)
	moon_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moon_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	moon_box.add_child(moon_effect_label)

	var moon_table_button := make_secondary_button("月相表", 76)
	moon_table_button.custom_minimum_size = Vector2(76, 28)
	moon_table_button.add_theme_font_size_override("font_size", 9)
	moon_table_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	moon_table_button.pressed.connect(show_moon_table)
	moon_box.add_child(moon_table_button)


func get_moon_effect_text_for_index(index: int) -> String:
	match index:
		0: return "自然奏力回復+2 / 到達時、奏力+1"
		1: return "速さ+15% / 通常攻撃の奏力回復+1"
		2: return "崩し+35% / 崩壊硬直延長"
		3: return "与ダメージ+12%"
		4: return "味方与ダメ+25% / 敵火力+25% / 崩壊追撃強化"
		5: return "毒・火傷+50% / 敵への状態異常+1巡"
		6: return "回復+30% / 防御性能強化"
		7: return "弱体中の敵への与ダメ+15%"
		_: return "特殊補正なし"


func show_moon_table() -> void:
	if moon_table_overlay != null and is_instance_valid(moon_table_overlay):
		return

	play_command_sound(1.0)

	moon_table_overlay = Control.new()
	moon_table_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	moon_table_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(moon_table_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.007, 0.012, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	moon_table_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	moon_table_overlay.add_child(center)

	var frame := make_panel(Color("#0b0d13fc"), Color("#65563d"), 18, 2)
	frame.custom_minimum_size = Vector2(1040, 650)
	center.add_child(frame)

	var margin := MarginContainer.new()
	set_margins(margin, 24, 20, 24, 20)
	frame.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)

	var title := make_label("月　相　表", 30, COL_GOLD_BRIGHT)
	apply_display_font(title)
	head.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)

	var close_button := make_secondary_button("閉じる", 96)
	close_button.pressed.connect(close_moon_table)
	head.add_child(close_button)

	var explanation := make_label(
		"月は一巡の開始時に確定し、その巡が終わるまで固定。通常は一巡ごとに一相進む。",
		11,
		Color("#aaa69e")
	)
	root.add_child(explanation)

	var next_phase := get_next_round_moon_index()
	var route := make_label(
		"今巡【%s】　→　次巡【%s】" % [PHASES[moon_index], PHASES[next_phase]],
		15,
		MOON_COLORS[moon_index]
	)
	apply_display_font(route)
	root.add_child(route)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	for i in range(PHASES.size()):
		var is_current := i == moon_index
		var is_next := i == next_phase
		var border := Color(MOON_COLORS[i], 0.88) if (is_current or is_next) else Color("#343740")
		var panel := make_panel(Color("#11141a"), border, 12, 2 if is_current else 1)
		panel.custom_minimum_size = Vector2(235, 215)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)

		var card_margin := MarginContainer.new()
		set_margins(card_margin, 13, 12, 13, 12)
		panel.add_child(card_margin)

		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 7)
		card_margin.add_child(v)

		var phase_title := make_label(PHASES[i], 21, MOON_COLORS[i])
		apply_display_font(phase_title)
		v.add_child(phase_title)

		var state_text := ""
		if is_current:
			state_text = "◆ 今巡"
		elif is_next:
			state_text = "◇ 次巡"
		else:
			state_text = "　"
		var state_label := make_label(state_text, 10, Color("#c8b47f"))
		v.add_child(state_label)

		var effect := make_label(get_moon_effect_text_for_index(i), 10, Color("#b9bbc2"))
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(effect)

		var resonance := make_label(
			"共鳴音紋　" + " / ".join(get_phase_resonant_displays(i)),
			9,
			Color("#7f8793")
		)
		resonance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(resonance)

	moon_table_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(moon_table_overlay, "modulate:a", 1.0, 0.10)


func get_phase_resonant_displays(phase_index: int) -> Array[String]:
	var result: Array[String] = []
	for note in NOTE_ORDER:
		if is_note_resonant(note, phase_index):
			result.append(get_note_display(note))
	return result


func close_moon_table() -> void:
	if moon_table_overlay == null or not is_instance_valid(moon_table_overlay):
		moon_table_overlay = null
		return

	play_command_sound(0.84)
	var overlay := moon_table_overlay
	moon_table_overlay = null
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.08)
	tween.tween_callback(overlay.queue_free)


func build_battle_center(root: VBoxContainer) -> void:
	var center := HBoxContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 14)
	root.add_child(center)

	var enemy_panel := make_panel(Color("#0a0c11ee"), Color("#323038"), 18, 1)
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_panel.size_flags_stretch_ratio = 1.65
	center.add_child(enemy_panel)

	var enemy_margin := MarginContainer.new()
	set_margins(enemy_margin, 22, 16, 22, 15)
	enemy_panel.add_child(enemy_margin)

	var enemy_v := VBoxContainer.new()
	enemy_v.add_theme_constant_override("separation", 9)
	enemy_margin.add_child(enemy_v)

	var enemy_top := HBoxContainer.new()
	enemy_v.add_child(enemy_top)

	var enemy_titles := VBoxContainer.new()
	enemy_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_top.add_child(enemy_titles)

	enemy_subtitle_label = make_label("", 1, Color(0, 0, 0, 0))
	enemy_subtitle_label.visible = false
	enemy_titles.add_child(enemy_subtitle_label)

	enemy_name_label = make_label("", 25, COL_TEXT)
	enemy_titles.add_child(enemy_name_label)

	enemy_desc_label = make_label("", 1, Color(0, 0, 0, 0))
	enemy_desc_label.visible = false
	enemy_titles.add_child(enemy_desc_label)

	enemy_intent_label = make_label("通常行動", 12, Color("#8a8d94"))
	enemy_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_intent_label.add_theme_color_override("font_outline_color", Color("#07080b"))
	enemy_intent_label.add_theme_constant_override("outline_size", 4)
	enemy_titles.add_child(enemy_intent_label)

	var danger := make_pill("第%d夜" % (enemy_index + 1), Color("#241518"), Color("#704047"), Color("#d58b8f"))
	enemy_top.add_child(danger)

	var enemy_visual := CenterContainer.new()
	enemy_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enemy_v.add_child(enemy_visual)

	enemy_portrait_frame = make_panel(Color("#0c0e13"), Color("#45343a"), 18, 1)
	enemy_portrait_frame.custom_minimum_size = Vector2(500, 270)
	enemy_visual.add_child(enemy_portrait_frame)

	enemy_portrait = TextureRect.new()
	enemy_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_portrait.texture = get_boss_texture(enemy_index)
	enemy_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_portrait_frame.add_child(enemy_portrait)

	# boss画像が未配置でも開発を止めないフォールバック。
	var fallback := make_enemy_sigil()
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.visible = enemy_portrait.texture == null
	enemy_portrait_frame.add_child(fallback)

	enemy_state_fx_layer = Control.new()
	enemy_state_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_state_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	enemy_portrait_frame.add_child(enemy_state_fx_layer)

	enemy_status_label = make_label("", 11, Color("#c8c0b3"))
	enemy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_v.add_child(enemy_status_label)

	var hp_head := make_dual_label_row("生命", "残生命")
	enemy_v.add_child(hp_head)

	enemy_hp_bar = make_bar(COL_RED, Color("#202229"), 13)
	enemy_v.add_child(enemy_hp_bar)

	var break_head := make_dual_label_row("崩し", "敵構え")
	enemy_v.add_child(break_head)

	enemy_break_bar = make_bar(COL_BREAK, Color("#202229"), 11)
	enemy_v.add_child(enemy_break_bar)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(630, 0)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	side.add_theme_constant_override("separation", 12)
	center.add_child(side)

	build_composition_panel(side)
	build_command_panel(side)


func build_composition_panel(parent: VBoxContainer) -> void:
	var panel := make_panel(Color("#0c0e13ef"), Color("#323039"), 14, 1)
	score_panel_ref = panel
	beat_cells.clear()
	beat_connectors.clear()
	parent.add_child(panel)

	var margin := MarginContainer.new()
	set_margins(margin, 12, 8, 12, 8)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	margin.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)

	var score_head_label := make_label("奏　譜　八拍", 11, Color("#a58b60"))
	apply_display_font(score_head_label)
	head.add_child(score_head_label)

	var guide_button := make_secondary_button("奏譜指南", 88)
	guide_button.custom_minimum_size = Vector2(88, 30)
	guide_button.add_theme_font_size_override("font_size", 10)
	guide_button.pressed.connect(show_score_guide)
	head.add_child(guide_button)

	var flex := Control.new()
	flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(flex)

	moon_seal_label = make_label("必殺　未解放", 11, Color("#7d7f87"))
	head.add_child(moon_seal_label)

	measure_label = make_label("", 11, COL_MUTED)
	measure_label.custom_minimum_size = Vector2(92, 0)
	measure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(measure_label)

	resonance_label = make_label("月共鳴　---", 10, Color("#aab0ba"))
	resonance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(resonance_label)

	var beats := HBoxContainer.new()
	beats.add_theme_constant_override("separation", 3)
	beats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(beats)

	var beat_names: Array[String] = ["壱", "弐", "参", "肆", "伍", "陸", "漆", "捌"]
	for i in range(SCORE_LENGTH):
		var cell := make_panel(Color("#13151b"), Color("#2c2e35"), 8, 1)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(50, 68)
		beats.add_child(cell)

		var cell_v := VBoxContainer.new()
		cell_v.alignment = BoxContainer.ALIGNMENT_CENTER
		cell_v.add_theme_constant_override("separation", 0)
		cell.add_child(cell_v)

		var count_label := make_label(beat_names[i], 8, Color("#62656d"))
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_v.add_child(count_label)

		var note_label := make_label("・", 20, Color("#555861"))
		note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_v.add_child(note_label)

		var action_label := make_label("", 7, Color("#9b927f"))
		action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		action_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cell_v.add_child(action_label)

		var actor_label := make_label("", 7, Color("#686b74"))
		actor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell_v.add_child(actor_label)

		beat_cells.append({
			"panel": cell,
			"count": count_label,
			"note": note_label,
			"action": action_label,
			"actor": actor_label
		})

		if i < SCORE_LENGTH - 1:
			var connector_holder := CenterContainer.new()
			connector_holder.custom_minimum_size = Vector2(8, 68)
			beats.add_child(connector_holder)
			var connector := ColorRect.new()
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			connector.color = Color("#272a31")
			connector.custom_minimum_size = Vector2(9, 2)
			connector_holder.add_child(connector)
			beat_connectors.append(connector)

	combo_forecast_label = make_label("奏式予測　---", 12, Color("#d1b873"))
	# 予測文が2行になって奏譜全体が上下にガタつかないよう、常に1行固定。
	combo_forecast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	combo_forecast_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	combo_forecast_label.custom_minimum_size = Vector2(0, 26)
	combo_forecast_label.clip_text = true
	v.add_child(combo_forecast_label)

	composition_label = make_label(
		"八拍で一つの奏譜。四拍目から兆しを表示し、八拍目で奏式が成立する。",
		9,
		Color("#858892")
	)
	composition_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(composition_label)


func show_score_guide() -> void:
	if score_guide_overlay != null and is_instance_valid(score_guide_overlay):
		return

	play_command_sound(1.0)

	score_guide_overlay = Control.new()
	score_guide_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	score_guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(score_guide_overlay)

	var shade := ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.color = Color(0.01, 0.012, 0.018, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_guide_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	score_guide_overlay.add_child(center)

	var frame := make_panel(Color("#0b0d12fa"), Color("#6f5b39"), 20, 2)
	frame.custom_minimum_size = Vector2(1320, 820)
	center.add_child(frame)

	var margin := MarginContainer.new()
	set_margins(margin, 28, 24, 28, 24)
	frame.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)

	var title := make_label("奏　譜　指　南", 32, COL_GOLD_BRIGHT)
	apply_display_font(title)
	top.add_child(title)

	var flex := Control.new()
	flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(flex)

	var close_button := make_secondary_button("閉じる", 96)
	close_button.pressed.connect(close_score_guide)
	top.add_child(close_button)

	var intro := make_label(
		"八拍で旋律を完成させる。条件は暗記しなくても戦闘中の「奏式予測」で確認できる。",
		12,
		Color("#aaa69e")
	)
	root.add_child(intro)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 18)
	root.add_child(body)

	var base_scroll := ScrollContainer.new()
	base_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(base_scroll)

	var base_box := VBoxContainer.new()
	base_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	base_box.add_theme_constant_override("separation", 8)
	base_scroll.add_child(base_box)

	var base_title := make_label("基本奏式", 20, Color("#d9dce3"))
	apply_display_font(base_title)
	base_box.add_child(base_title)

	var base_entries: Array[Dictionary] = [
		{"name":"昇奏", "condition":"音が全体として上がる", "effect":"攻撃と崩しを強化", "color":Color("#e0ad63")},
		{"name":"降奏", "condition":"音が全体として下がる", "effect":"生命と構えを回復", "color":Color("#8fb9d5")},
		{"name":"重奏", "condition":"同じ音紋を三回以上重ねる", "effect":"攻撃を増幅", "color":Color("#c8a56d")},
		{"name":"濁奏", "condition":"同じ音紋を四回以上重ねる", "effect":"強い攻撃強化。ただし味方の構えを消費", "color":Color("#9d6aa8")},
		{"name":"返奏", "condition":"A→B→Aの返しを二度作る", "effect":"守りと構え回復", "color":Color("#a9c7c0")},
		{"name":"静奏", "condition":"休符を二つ以上含める", "effect":"回復と立て直し", "color":Color("#d9dfda")},
		{"name":"彩奏", "condition":"六種類以上の音紋を使う", "effect":"奏力と構えを広く回復", "color":Color("#d8b8cf")},
		{"name":"合奏", "condition":"三人が参加し、四種類以上の音紋", "effect":"全員の奏力を補助", "color":Color("#d7bf84")},
		{"name":"余韻", "condition":"他の奏式に届かなかった時", "effect":"大きな追加効果なし", "color":Color("#777b84")}
	]

	for entry in base_entries:
		base_box.add_child(
			make_score_guide_entry(
				str(entry["name"]),
				str(entry["condition"]),
				str(entry["effect"]),
				entry["color"] as Color
			)
		)

	var lunar_scroll := ScrollContainer.new()
	lunar_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lunar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(lunar_scroll)

	var lunar_box := VBoxContainer.new()
	lunar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lunar_box.add_theme_constant_override("separation", 8)
	lunar_scroll.add_child(lunar_box)

	var lunar_title := make_label("月　奏", 20, COL_GOLD_BRIGHT)
	apply_display_font(lunar_title)
	lunar_box.add_child(lunar_title)

	var lunar_intro := make_label(
		"八拍のうち四拍以上が、その時の月の共鳴音紋なら基本奏式が月奏へ昇格する。",
		10,
		Color("#8f929b")
	)
	lunar_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lunar_box.add_child(lunar_intro)

	var lunar_entries: Array[Dictionary] = [
		{"name":"朔月・静奏", "condition":"新月で共鳴", "effect":"奏力・生命・構えを整える", "color":MOON_COLORS[0]},
		{"name":"三日月・疾奏", "condition":"三日月で共鳴", "effect":"軽快な立ち回りを強化", "color":MOON_COLORS[1]},
		{"name":"上弦・破奏", "condition":"上弦で共鳴", "effect":"崩し性能を大きく強化", "color":MOON_COLORS[2]},
		{"name":"十三夜・調奏", "condition":"十三夜で共鳴", "effect":"攻撃と支援を均す", "color":MOON_COLORS[3]},
		{"name":"望月・烈奏", "condition":"満月で共鳴", "effect":"攻撃性能を大きく引き上げる", "color":MOON_COLORS[4]},
		{"name":"十六夜・妖奏", "condition":"十六夜で共鳴", "effect":"毒・火傷・弱体を強める", "color":MOON_COLORS[5]},
		{"name":"下弦・守奏", "condition":"下弦で共鳴", "effect":"生命・構え・防御を立て直す", "color":MOON_COLORS[6]},
		{"name":"晦・葬奏", "condition":"晦で共鳴", "effect":"弱体中の敵へ追い打ち", "color":MOON_COLORS[7]}
	]

	for entry in lunar_entries:
		lunar_box.add_child(
			make_score_guide_entry(
				str(entry["name"]),
				str(entry["condition"]),
				str(entry["effect"]),
				entry["color"] as Color
			)
		)

	var finisher_rule := ColorRect.new()
	finisher_rule.color = Color("#5a4b35")
	finisher_rule.custom_minimum_size = Vector2(0, 1)
	lunar_box.add_child(finisher_rule)

	var finisher_title := make_label("必　殺　解　放", 18, COL_GOLD_BRIGHT)
	apply_display_font(finisher_title)
	lunar_box.add_child(finisher_title)

	for char_name in party:
		var ready_text := "解放済み" if is_ultimate_ready(char_name) else "未解放"
		lunar_box.add_child(
			make_score_guide_entry(
				char_name + "　" + get_ultimate_name(char_name),
				"「%s」を完成" % get_ultimate_requirement(char_name),
				ready_text + "　／　一度使用すると再び同じ奏譜が必要",
				COL_GOLD_BRIGHT if is_ultimate_ready(char_name) else Color("#8e7952")
			)
		)

	var foot := make_label(
		"※ 技ごとの音紋は特技選択画面に表示。月の共鳴音紋は奏譜上部に常時表示。",
		10,
		Color("#696d75")
	)
	root.add_child(foot)

	score_guide_overlay.modulate.a = 0.0
	frame.pivot_offset = frame.size * 0.5
	var tween := create_tween()
	tween.tween_property(score_guide_overlay, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(frame, "scale", Vector2.ONE, 0.18).from(Vector2(0.96, 0.96))


func make_score_guide_entry(
	title_text: String,
	condition_text: String,
	effect_text: String,
	tone: Color
) -> Control:
	var panel := make_panel(Color("#11131a"), Color(tone, 0.44), 10, 1)
	panel.custom_minimum_size = Vector2(0, 74)

	var margin := MarginContainer.new()
	set_margins(margin, 14, 9, 14, 9)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	margin.add_child(v)

	var title := make_label(title_text, 16, tone)
	apply_display_font(title)
	v.add_child(title)

	var condition := make_label("成立　" + condition_text, 10, Color("#b4b0a8"))
	condition.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(condition)

	var effect := make_label("効果　" + effect_text, 10, Color("#7f838c"))
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(effect)

	return panel


func close_score_guide() -> void:
	if score_guide_overlay == null or not is_instance_valid(score_guide_overlay):
		score_guide_overlay = null
		return

	play_command_sound(0.82)
	var overlay := score_guide_overlay
	score_guide_overlay = null

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.10)
	tween.tween_callback(overlay.queue_free)


func build_command_panel(parent: VBoxContainer) -> void:
	var panel := make_panel(Color("#11131af2"), Color("#3a3439"), 16, 1)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var margin := MarginContainer.new()
	set_margins(margin, 15, 12, 15, 12)
	panel.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	command_sub_label = make_label("", 9, Color("#89765a"))
	v.add_child(command_sub_label)

	command_title_label = make_label("", 18, COL_TEXT)
	v.add_child(command_title_label)

	moon_forecast_label = make_label("月路　---", 10, Color("#a9956b"))
	moon_forecast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	moon_forecast_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	moon_forecast_label.clip_text = true
	v.add_child(moon_forecast_label)

	tactical_preview_label = make_label("予測　技に触れると未来を表示", 10, Color("#8fa9c3"))
	tactical_preview_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tactical_preview_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tactical_preview_label.clip_text = true
	tactical_preview_label.custom_minimum_size = Vector2(0, 22)
	v.add_child(tactical_preview_label)

	var rule := ColorRect.new()
	rule.color = Color("#3d3328")
	rule.custom_minimum_size = Vector2(0, 1)
	v.add_child(rule)

	command_box = VBoxContainer.new()
	command_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	command_box.add_theme_constant_override("separation", 7)
	v.add_child(command_box)

	var log_head := HBoxContainer.new()
	v.add_child(log_head)

	log_head.add_child(make_label("戦闘記録", 12, Color("#9a9da5")))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_head.add_child(spacer)

	log_head.add_child(make_label("記録", 10, Color("#666a73")))

	log_label = RichTextLabel.new()
	if ui_font != null:
		log_label.add_theme_font_override("normal_font", ui_font)
		log_label.add_theme_font_override("bold_font", ui_font)
	log_label.bbcode_enabled = true
	log_label.fit_content = false
	log_label.custom_minimum_size = Vector2(0, 96)
	log_label.add_theme_color_override("default_color", Color("#d0d2d7"))
	log_label.add_theme_font_size_override("normal_font_size", 13)
	log_label.text = "[color=#646770]三人の行動を決めてください。[/color]"
	v.add_child(log_label)


func build_battle_party_row(root: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 168)
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)

	for char_name in party:
		var card: Dictionary = build_battle_party_card(char_name)
		row.add_child(card["panel"])
		party_cards[char_name] = card


func build_battle_party_card(char_name: String) -> Dictionary:
	var panel := make_panel(Color("#0d0f15f4"), Color("#2c2f38"), 14, 1)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	set_margins(margin, 10, 8, 10, 8)
	panel.add_child(margin)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	margin.add_child(content)

	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(96, 132)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#17191f")
	portrait_style.border_color = Color("#3b372f")
	portrait_style.set_border_width_all(1)
	portrait_style.set_corner_radius_all(9)
	portrait_frame.add_theme_stylebox_override("panel", portrait_style)
	content.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = get_portrait_texture(char_name, false)
	portrait_frame.add_child(portrait)

	if portrait.texture == null:
		var fallback := make_label(char_name.left(1), 46, Color("#756b5a"))
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		portrait_frame.add_child(fallback)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	content.add_child(info)

	var top := HBoxContainer.new()
	info.add_child(top)

	var char_label := make_label(char_name, 16, COL_TEXT)
	top.add_child(char_label)

	var flex := Control.new()
	flex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(flex)

	var role := make_label(str(CHARACTERS[char_name]["instrument"]), 9, Color("#797c84"))
	top.add_child(role)

	var hp_label := make_label("", 10, COL_MUTED)
	info.add_child(hp_label)

	var hp_bar := make_bar(Color("#873942"), Color("#22252c"), 9)
	info.add_child(hp_bar)

	var mana_label := make_label("", 10, COL_MUTED)
	info.add_child(mana_label)

	var mana_bar := make_bar(COL_BLUE, Color("#22252c"), 9)
	info.add_child(mana_bar)

	var stance_label := make_label("", 9, Color("#9a8b68"))
	info.add_child(stance_label)

	var stance_bar := make_bar(COL_BREAK, Color("#22252c"), 8)
	info.add_child(stance_bar)

	var status_label := make_label("", 9, Color("#8d8171"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(status_label)

	var planned_label := make_label("未選択", 10, Color("#666971"))
	planned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(planned_label)

	return {
		"panel": panel,
		"portrait": portrait,
		"hp_label": hp_label,
		"hp_bar": hp_bar,
		"mana_label": mana_label,
		"mana_bar": mana_bar,
		"stance_label": stance_label,
		"stance_bar": stance_bar,
		"status_label": status_label,
		"planned_label": planned_label
	}


func make_enemy_sigil() -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(440, 260)

	var outer := Panel.new()
	outer.set_anchors_preset(Control.PRESET_CENTER)
	outer.position = Vector2(-116, -116)
	outer.size = Vector2(232, 232)

	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color("#101116")
	outer_style.border_color = Color("#463237")
	outer_style.set_border_width_all(1)
	outer_style.set_corner_radius_all(116)
	outer.add_theme_stylebox_override("panel", outer_style)
	holder.add_child(outer)

	var inner := Panel.new()
	inner.set_anchors_preset(Control.PRESET_CENTER)
	inner.position = Vector2(-84, -84)
	inner.size = Vector2(168, 168)

	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color("#15161c")
	inner_style.border_color = Color("#3b272c")
	inner_style.set_border_width_all(2)
	inner_style.set_corner_radius_all(84)
	inner.add_theme_stylebox_override("panel", inner_style)
	holder.add_child(inner)

	enemy_glyph_label = make_label("鬼", 80, Color("#a44d54"))
	enemy_glyph_label.set_anchors_preset(Control.PRESET_CENTER)
	enemy_glyph_label.position = Vector2(-66, -72)
	enemy_glyph_label.size = Vector2(132, 144)
	enemy_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_glyph_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_glyph_label.add_theme_color_override("font_shadow_color", Color("#26080b"))
	enemy_glyph_label.add_theme_constant_override("shadow_offset_x", 4)
	enemy_glyph_label.add_theme_constant_override("shadow_offset_y", 4)
	holder.add_child(enemy_glyph_label)

	return holder


# ============================================================
# RUN / BATTLE STATE
# ============================================================

func prepare_party_for_battle() -> void:
	party_state.clear()
	moon_seals = 0
	ultimate_ready.clear()
	for char_name in party:
		ultimate_ready[char_name] = false
	combo_damage_rounds = 0
	combo_break_rounds = 0
	last_combo_name = "未完成"
	ctb_times.clear()
	ctb_clock = 0.0
	ctb_current_actor = ""
	ctb_initialized = false
	ctb_event_count = 0
	ctb_preview_action.clear()
	ctb_last_wait.clear()
	ctb_first_intro = true
	score_banner_lock_until = 0

	for char_name in party:
		var source: Dictionary = CHARACTERS[char_name]
		var state: Dictionary = source.duplicate(true)

		state["cur_hp"] = int(source["hp"])
		state["cur_mana"] = int(ceil(float(source["mana"]) * 0.50))
		state["statuses"] = {}
		state["guarding"] = false
		state["counter"] = false

		# 味方にもBREAKを導入。DEFが高いほど構え最大値が少し高い。
		state["stance_max"] = 80 + int(source["def"])
		state["cur_stance"] = int(state["stance_max"])
		state["broken_rounds"] = 0
		state["broken_on_round"] = -1
		state["break_guard_rounds"] = 0

		# 同じ特技の連打を完全禁止せず、奏力と構えの代償を増やす。
		state["last_skill_id"] = ""
		state["repeat_count"] = 0

		party_state[char_name] = state


func prepare_enemy(index_value: int) -> void:
	var source: Dictionary = ENEMIES[index_value]
	enemy_state = source.duplicate(true)

	enemy_state["cur_hp"] = int(source["hp"])
	enemy_state["cur_break"] = int(source["break_max"])
	enemy_state["statuses"] = {}
	enemy_state["broken_rounds"] = 0
	enemy_state["broken_on_round"] = -1
	enemy_state["break_guard_rounds"] = 0

	# 大技は突然撃たず、必ず一度「予兆」を見せる。
	enemy_state["big_state"] = 0 # 0通常 / 1予兆 / 2発動態勢
	enemy_state["next_big_round"] = 3
	enemy_state["big_target"] = ""
	enemy_state["big_charged_round"] = -1
	enemy_state["note_memory"] = {}
	enemy_state["phase2"] = false
	enemy_state["phase_name"] = ""
	enemy_state["mechanic_counter"] = 0
	enemy_state["score_disrupt_count"] = 0
	enemy_state["moon_shift_count"] = 0
	enemy_state_fx_signature = ""


func sort_planning_entries(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))


func rebuild_planning_order() -> void:
	planning_order.clear()
	var entries: Array[Dictionary] = []
	for char_name in party:
		if not party_state.has(char_name):
			continue
		var state: Dictionary = party_state[char_name]
		if int(state.get("cur_hp", 0)) <= 0:
			continue
		if int(state.get("broken_rounds", 0)) > 0:
			continue
		entries.append({
			"name": char_name,
			"time": float(ctb_times.get(char_name, 99999.0))
		})
	entries.sort_custom(sort_planning_entries)
	for entry in entries:
		planning_order.append(str(entry["name"]))


func get_planning_order_text() -> String:
	if planning_order.is_empty():
		return ""
	return " → ".join(planning_order)


func begin_command_phase() -> void:
	if is_party_defeated():
		show_game_over()
		return
	if int(enemy_state["cur_hp"]) <= 0:
		await show_battle_victory()
		return

	if not ctb_initialized:
		initialize_ctb()

	busy = true
	pending_actions.clear()
	ctb_preview_action.clear()
	enemy_break_announced = false
	command_cursor = -1

	# 敵の大技予兆は「選び終えた後」ではなく、作戦を考える前に見せる。
	prepare_enemy_intent()
	rebuild_planning_order()
	refresh_battle_ui()

	if ctb_first_intro:
		ctb_first_intro = false

	# 月は「この巡のルール」として、三人の行動を選ぶ前に確定。
	# 以降、この巡が終わるまで月相は一切変わらない。
	await show_round_moon_intro()

	var first_index := find_next_commandable_index(0)
	if first_index < 0:
		# 全員が崩壊中などで選べない場合も、敵側の時間は進む。
		command_sub_label.text = "第%02d巡" % round_number
		command_title_label.text = "行動できる者がいない"
		clear_container(command_box)
		command_box.add_child(make_label("敵の行動へ移る…", 11, COL_MUTED))
		call_deferred("resolve_round")
		return

	command_cursor = first_index
	ctb_current_actor = planning_order[command_cursor]
	busy = false
	show_main_commands(ctb_current_actor)
	refresh_battle_ui()


func find_next_commandable_index(start_index: int) -> int:
	for i in range(maxi(0, start_index), planning_order.size()):
		var char_name := planning_order[i]
		if not party_state.has(char_name):
			continue
		var state: Dictionary = party_state[char_name]
		if int(state["cur_hp"]) <= 0:
			continue
		if int(state.get("broken_rounds", 0)) > 0:
			continue
		if pending_actions.has(char_name):
			continue
		return i
	return -1


func get_current_planning_actor() -> String:
	if command_cursor < 0 or command_cursor >= planning_order.size():
		return ""
	return planning_order[command_cursor]


func initialize_ctb() -> void:
	ctb_times.clear()
	ctb_clock = 0.0
	ctb_event_count = 0

	for char_name in party:
		var speed := get_player_stat(char_name, "spd")
		ctb_times[char_name] = randf_range(4.0, 27.0) + maxf(0.0, 34.0 - float(speed)) * 0.55

	var enemy_speed := get_enemy_stat("spd")
	ctb_times[CTB_ENEMY_KEY] = randf_range(7.0, 30.0) + maxf(0.0, 34.0 - float(enemy_speed)) * 0.55
	ctb_initialized = true


func get_action_wait_base(action_data: Dictionary) -> int:
	var action_type := str(action_data.get("type", ""))
	if action_type == "attack":
		return 82
	if action_type == "guard":
		return 58
	if action_type == "ultimate":
		return 148
	if action_type != "skill":
		return 82

	var skill_data: Dictionary = action_data.get("skill", {})
	match str(skill_data.get("id", "")):
		"samurai_moon_slash": return 92
		"samurai_iai": return 132
		"samurai_red_mist": return 86
		"samurai_swallow_break": return 70
		"samurai_aftermoon": return 98
		"sennin_thunder": return 94
		"sennin_moon_turn": return 76
		"sennin_spring": return 106
		"sennin_wind_read": return 68
		"sennin_moon_hold": return 78
		"kasa_pierce": return 90
		"kasa_counter": return 66
		"kasa_ward": return 104
		"kasa_rain_armor": return 78
		"kasa_thunder_guard": return 88
		"miko_heal": return 80
		"miko_cleanse": return 88
		"miko_bless": return 110
		"miko_bell_guard": return 72
		"miko_divine_descent": return 126
		"chochin_foxfire": return 84
		"chochin_lantern_drop": return 118
		"chochin_dim": return 82
		"chochin_ember_step": return 76
		"chochin_burst": return 114
		"jusoshi_poison": return 84
		"jusoshi_bind": return 92
		"jusoshi_grudge": return 122
		"jusoshi_extend": return 90
		"jusoshi_abyss_mark": return 108
		"kunoichi_shadow_bind": return 66
		"kunoichi_poison_star": return 74
		"kunoichi_mist_step": return 48
		"kunoichi_ninja_return": return 56
		"kunoichi_scatter_star": return 108
		"shuten_oni_smash": return 112
		"shuten_sake_flame": return 88
		"shuten_drink_dry": return 64
		"shuten_drunk_barrage": return 126
		"shuten_hyakki_feast": return 102
		"kagurashi_rhythm_dance": return 70
		"kagurashi_double_beat": return 84
		"kagurashi_repose": return 86
		"kagurashi_moon_call": return 72
		"kagurashi_wild_kagura": return 116
		"nekomata_cat_fire": return 76
		"nekomata_twin_tail": return 72
		"nekomata_feint": return 64
		"nekomata_soul_lick": return 88
		"nekomata_bakeneko_dance": return 112
		_: return 92


func get_effective_action_wait(
	char_name: String,
	action_data: Dictionary,
	with_random: bool = false
) -> int:
	var base := get_action_wait_base(action_data)
	var speed := get_player_stat(char_name, "spd")
	var result := maxi(36, base - int(round(float(speed) * 0.62)))
	if with_random:
		result += randi_range(-7, 7)
	return maxi(32, result)


func get_enemy_ctb_wait(with_random: bool = false) -> int:
	var base := 92
	if int(enemy_state.get("big_state", 0)) == 2:
		base = 58

	if is_enemy_second_phase():
		match str(enemy_state.get("id", "")):
			"moon_oni": base -= 5
			"fire_spider": base -= 8
			"bone_monk": base -= 6
			"dark_tengu": base -= 16
			"eclipse_lady": base -= 13
	elif str(enemy_state.get("id", "")) == "eclipse_lady":
		var ratio := float(enemy_state["cur_hp"]) / maxf(1.0, float(enemy_state["hp"]))
		if ratio <= 0.45:
			base = 68

	var result := maxi(34, base - int(round(float(get_enemy_stat("spd")) * 0.48)))
	if with_random:
		result += randi_range(-8, 8)
	return maxi(30, result)

func set_ctb_action_preview(char_name: String, action_data: Dictionary) -> void:
	if busy:
		return
	if char_name != get_current_planning_actor():
		return

	ctb_preview_action = action_data.duplicate(true)
	ctb_preview_action["actor"] = char_name
	refresh_turn_order_bar()
	refresh_music_ui()
	refresh_moon_forecast()
	if tactical_preview_label != null and is_instance_valid(tactical_preview_label):
		tactical_preview_label.text = get_tactical_action_preview(char_name, ctb_preview_action)

func clear_ctb_action_preview() -> void:
	if ctb_preview_action.is_empty():
		return
	ctb_preview_action.clear()
	refresh_turn_order_bar()
	refresh_music_ui()
	refresh_moon_forecast()
	if tactical_preview_label != null and is_instance_valid(tactical_preview_label):
		tactical_preview_label.text = "予測　技に触れると行動順・月・奏譜・崩しを表示"

func bind_ctb_preview(button: Button, char_name: String, action_data: Dictionary) -> void:
	button.mouse_entered.connect(set_ctb_action_preview.bind(char_name, action_data))
	button.focus_entered.connect(set_ctb_action_preview.bind(char_name, action_data))
	button.mouse_exited.connect(clear_ctb_action_preview)


func get_action_break_preview(char_name: String, action_data: Dictionary) -> int:
	var action_type := str(action_data.get("type", ""))
	var multiplier := 0.0
	if action_type == "attack":
		multiplier = 1.00
	elif action_type == "ultimate":
		multiplier = 1.80
	elif action_type == "skill":
		var skill_data: Dictionary = action_data.get("skill", {})
		match str(skill_data.get("id", "")):
			"samurai_moon_slash": multiplier = 1.45
			"samurai_iai": multiplier = 0.75
			"samurai_red_mist": multiplier = 0.90
			"samurai_swallow_break": multiplier = 2.80 if int(enemy_state.get("big_state", 0)) > 0 else 1.20
			"samurai_aftermoon": multiplier = 0.85
			"sennin_thunder": multiplier = 0.85
			"kasa_pierce": multiplier = 2.15
			"kasa_thunder_guard": multiplier = 2.85 if int(enemy_state.get("big_state", 0)) > 0 else 1.65
			"chochin_foxfire": multiplier = 0.80
			"chochin_lantern_drop": multiplier = 1.05
			"chochin_dim": multiplier = 0.65
			"chochin_ember_step": multiplier = 0.70
			"chochin_burst": multiplier = 1.55 if has_status(enemy_state, "burn") else 0.90
			"jusoshi_poison": multiplier = 0.55
			"jusoshi_bind": multiplier = 0.60
			"jusoshi_grudge": multiplier = 0.75
			"jusoshi_extend": multiplier = 0.55
			"jusoshi_abyss_mark": multiplier = minf(2.20, 0.80 + float(count_enemy_negative_statuses()) * 0.35)
			"kunoichi_shadow_bind": multiplier = 1.05
			"kunoichi_poison_star": multiplier = 0.70
			"kunoichi_mist_step": multiplier = 0.55
			"kunoichi_scatter_star": multiplier = 1.55
			"shuten_oni_smash": multiplier = 2.10
			"shuten_sake_flame": multiplier = 0.85
			"shuten_drunk_barrage": multiplier = 1.30
			"kagurashi_wild_kagura": multiplier = 1.65 if beat >= 6 else 0.90
			"nekomata_cat_fire": multiplier = 0.70
			"nekomata_twin_tail": multiplier = 1.20
			"nekomata_feint": multiplier = 0.55
			"nekomata_soul_lick": multiplier = 0.65
			"nekomata_bakeneko_dance": multiplier = 1.25
			_: multiplier = 0.0

	if multiplier <= 0.0:
		return 0
	var result := calculate_break_damage(int(party_state[char_name]["break"]), multiplier)
	result = maxi(0, int(round(float(result) * get_enemy_break_taken_modifier())))
	return result


func get_actor_preview_slots(char_name: String) -> String:
	var entries := get_turn_order_preview()
	var found: Array[int] = []
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		if str(entry.get("side", "")) == "player" and str(entry.get("actor", "")) == char_name:
			found.append(i + 1)
	if found.is_empty():
		return "順外"
	if found.size() == 1:
		return "%d番" % found[0]
	return "%d番→次%d番" % [found[0], found[1]]


func get_tactical_action_preview(char_name: String, action_data: Dictionary) -> String:
	var order_text := get_actor_preview_slots(char_name)
	var action_steps := get_action_moon_steps(action_data)
	var action_bonus := maxi(0, action_steps - 1)
	var current_bonus := get_planned_moon_bonus(char_name, action_data)
	var next_phase := (moon_index + 1 + current_bonus) % PHASES.size()

	var score_notes := get_score_forecast_notes()
	var score_text := get_combo_forecast_text(score_notes)
	var break_estimate := get_action_break_preview(char_name, action_data)
	var break_text := "崩しなし"
	if break_estimate > 0:
		break_text = "崩し約%d→残%d" % [
			break_estimate,
			maxi(0, int(enemy_state.get("cur_break", 0)) - break_estimate)
		]

	var moon_note := "今巡 %s固定 → 次巡 %s" % [
		PHASES[moon_index],
		PHASES[next_phase]
	]
	if action_bonus > 0:
		moon_note += "（月操作+%d）" % action_bonus

	return "予測　順 %s　｜　%s　｜　奏 %s　｜　%s" % [
		order_text,
		moon_note,
		score_text,
		break_text
	]


func get_planned_moon_bonus(
	preview_actor: String = "",
	preview_action: Dictionary = {}
) -> int:
	var best_bonus := round_moon_bonus

	for char_name in party:
		var action: Dictionary = {}
		if pending_actions.has(char_name):
			action = pending_actions[char_name]
		elif char_name == preview_actor and not preview_action.is_empty():
			action = preview_action

		if action.is_empty():
			continue

		best_bonus = maxi(
			best_bonus,
			maxi(0, get_action_moon_steps(action) - 1)
		)

	return best_bonus



func show_commands_for_next_actor() -> void:
	var next_index := find_next_commandable_index(command_cursor + 1)
	if next_index < 0:
		busy = true
		call_deferred("resolve_round")
		return

	command_cursor = next_index
	ctb_current_actor = planning_order[command_cursor]
	busy = false
	show_main_commands(ctb_current_actor)
	refresh_battle_ui()

func show_main_commands(char_name: String) -> void:
	clear_container(command_box)
	ctb_preview_action.clear()

	var state: Dictionary = party_state[char_name]
	var char_data: Dictionary = CHARACTERS[char_name]

	command_sub_label.text = "第%02d巡　／　作戦入力 %d/%d　／　%s" % [round_number, pending_actions.size() + 1, count_commandable_party(), get_planning_order_text()]
	command_title_label.text = "%s　奏力 %d/%d　構え %d/%d" % [
		char_name,
		int(state["cur_mana"]),
		int(state["mana"]),
		int(state["cur_stance"]),
		int(state["stance_max"])
	]

	var attack_action := {"type": "attack", "target": ""}
	var attack_note := get_basic_attack_note(char_name)
	var attack_wait := get_effective_action_wait(char_name, attack_action)
	var attack_button := make_command_button(
		"%s　攻撃" % get_note_display(attack_note),
		"奏力+2　構え+10　月+1　／　待ち %d　／　%s" % [attack_wait, get_note_choice_hint(attack_note)]
	)
	attack_button.pressed.connect(queue_basic_attack.bind(char_name))
	bind_ctb_preview(attack_button, char_name, attack_action)
	command_box.add_child(attack_button)

	var sealed: bool = has_status(state, "seal")
	var skill_button := make_command_button(
		"特技",
		"技ごとに待ち時間が違う。三人の行動を決めてから、行動順に沿って一斉に動き出す。"
	)
	skill_button.disabled = sealed
	if sealed:
		skill_button.text += "\n封技中"
	skill_button.pressed.connect(show_skill_menu.bind(char_name))
	command_box.add_child(skill_button)

	var ultimate_action := {"type": "ultimate", "target": ""}
	var ultimate_wait := get_effective_action_wait(char_name, ultimate_action)
	var ultimate_is_ready := is_ultimate_ready(char_name)
	var ultimate_title := "◆ 必殺技　" + get_ultimate_name(char_name)
	var ultimate_detail := ""

	if ultimate_is_ready:
		ultimate_detail = "解放済み　／　戦術倍率 ×%.2f　／　待ち %d" % [
			get_ultimate_tactical_multiplier(char_name),
			ultimate_wait
		]
	else:
		ultimate_detail = "未解放　／　「%s」を完成すると使用可能" % get_ultimate_requirement(char_name)

	var ultimate_button := make_command_button(
		ultimate_title,
		ultimate_detail
	)
	ultimate_button.disabled = not ultimate_is_ready
	if ultimate_is_ready:
		ultimate_button.pressed.connect(queue_ultimate.bind(char_name))
		bind_ctb_preview(ultimate_button, char_name, ultimate_action)
	command_box.add_child(ultimate_button)

	var guard_action := {"type": "guard", "target": char_name}
	var guard_wait := get_effective_action_wait(char_name, guard_action)
	var guard_button := make_command_button(
		"〔休〕　防御",
		"被ダメージ軽減　構え+25　月+1　／　待ち %d　／　休符を奏譜へ置く" % guard_wait
	)
	guard_button.pressed.connect(queue_guard.bind(char_name))
	bind_ctb_preview(guard_button, char_name, guard_action)
	command_box.add_child(guard_button)

	if not pending_actions.is_empty():
		var undo_button := make_secondary_button("← 前の行動を選び直す", 0)
		undo_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		undo_button.pressed.connect(undo_last_action)
		command_box.add_child(undo_button)

	var role := make_label(
		str(char_data["role"]) + "　・　" + str(char_data["instrument"]),
		9,
		Color("#777a82")
	)
	command_box.add_child(role)
	refresh_moon_forecast()

func show_skill_menu(char_name: String) -> void:
	if skill_menu_overlay != null and is_instance_valid(skill_menu_overlay):
		return

	play_command_sound(1.06)
	ctb_preview_action.clear()

	var state: Dictionary = party_state[char_name]
	var skills: Array = CHARACTERS[char_name]["skills"]

	# 右側の小さいコマンド欄へ無理に5技を詰めず、
	# 特技だけは専用の大きい選択画面を重ねる。
	skill_menu_overlay = Control.new()
	skill_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	skill_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layer.add_child(skill_menu_overlay)

	var shade := ColorRect.new()
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.color = Color(0.005, 0.007, 0.012, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skill_menu_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	skill_menu_overlay.add_child(center)

	var frame := make_panel(Color("#0b0d13fb"), Color("#695538"), 20, 2)
	frame.custom_minimum_size = Vector2(1240, 760)
	center.add_child(frame)

	var margin := MarginContainer.new()
	set_margins(margin, 26, 22, 26, 22)
	frame.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 13)
	margin.add_child(root)

	# Header
	var head := HBoxContainer.new()
	root.add_child(head)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_box)

	var title := make_label("%s　特　技" % char_name, 28, COL_TEXT)
	apply_display_font(title)
	title_box.add_child(title)

	var resource_label := make_label(
		"奏力 %d / %d　　構え %d / %d　　現在月【%s】" % [
			int(state["cur_mana"]),
			int(state["mana"]),
			int(state["cur_stance"]),
			int(state["stance_max"]),
			PHASES[moon_index]
		],
		11,
		Color("#9b927f")
	)
	title_box.add_child(resource_label)

	var close_button := make_secondary_button("← 戻る", 110)
	close_button.custom_minimum_size = Vector2(110, 42)
	close_button.pressed.connect(close_skill_menu)
	head.add_child(close_button)

	var rule := ColorRect.new()
	rule.color = Color("#57452f")
	rule.custom_minimum_size = Vector2(0, 1)
	root.add_child(rule)

	# Fixed-height preview area so hovering never makes the layout jump.
	skill_overlay_preview_label = make_label(
		"技に触れると　行動順 / 月 / 奏譜 / 崩し　を予測",
		11,
		Color("#9bb5cf")
	)
	skill_overlay_preview_label.custom_minimum_size = Vector2(0, 48)
	skill_overlay_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_overlay_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(skill_overlay_preview_label)

	# 5技なら2列×3段。説明文はButtonへ詰めず、カード内Labelで折り返す。
	# これで縦方向・横方向どちらも見切れない。
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	for skill_variant in skills:
		var skill_data: Dictionary = skill_variant
		var cost: int = get_effective_skill_cost(char_name, skill_data)
		var strain: int = get_skill_stance_cost(char_name, skill_data)
		var note_type := get_skill_note_type(str(skill_data["id"]))
		var action_data := {
			"type": "skill",
			"skill": skill_data,
			"target": ""
		}
		var wait_value := get_effective_action_wait(char_name, action_data)

		var card := make_panel(
			Color("#11141b"),
			Color("#6c5a3f") if is_note_resonant(note_type, moon_index) else Color("#343842"),
			12,
			1
		)
		card.custom_minimum_size = Vector2(0, 164)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)

		var card_margin := MarginContainer.new()
		set_margins(card_margin, 14, 11, 14, 11)
		card.add_child(card_margin)

		var card_v := VBoxContainer.new()
		card_v.add_theme_constant_override("separation", 5)
		card_margin.add_child(card_v)

		var repeat_text := ""
		if str(state.get("last_skill_id", "")) == str(skill_data["id"]):
			repeat_text = "　残響過多"

		var resonance_text := "　月共鳴" if is_note_resonant(note_type, moon_index) else ""
		var choose_button := Button.new()
		apply_display_font(choose_button)
		choose_button.text = "%s　%s%s%s" % [
			get_note_display(note_type),
			str(skill_data["name"]),
			resonance_text,
			repeat_text
		]
		choose_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choose_button.custom_minimum_size = Vector2(0, 42)
		choose_button.add_theme_font_size_override("font_size", 17)
		choose_button.add_theme_color_override("font_color", Color("#eee5d6"))
		choose_button.add_theme_color_override("font_hover_color", COL_GOLD_BRIGHT)
		choose_button.add_theme_color_override("font_disabled_color", Color("#5f626b"))

		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("#171a22")
		normal.border_color = Color("#383b45")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(8)
		normal.content_margin_left = 12
		normal.content_margin_right = 10

		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#27221c")
		hover.border_color = Color("#8f724a")

		var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		disabled.bg_color = Color("#101219")
		disabled.border_color = Color("#252832")

		choose_button.add_theme_stylebox_override("normal", normal)
		choose_button.add_theme_stylebox_override("hover", hover)
		choose_button.add_theme_stylebox_override("pressed", hover)
		choose_button.add_theme_stylebox_override("disabled", disabled)
		card_v.add_child(choose_button)

		var stats := make_label(
			"奏力 %d　／　構え -%d　／　待ち %d" % [cost, strain, wait_value],
			10,
			Color("#b29b71")
		)
		card_v.add_child(stats)

		var desc := make_label(str(skill_data["desc"]), 11, Color("#c1c3c9"))
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(0, 40)
		card_v.add_child(desc)

		var hint := make_label(get_note_choice_hint(note_type), 9, Color("#777d88"))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_v.add_child(hint)

		choose_button.disabled = int(state["cur_mana"]) < cost
		choose_button.pressed.connect(
			select_skill_from_overlay.bind(char_name, skill_data)
		)
		choose_button.mouse_entered.connect(
			set_skill_overlay_preview.bind(char_name, action_data)
		)
		choose_button.focus_entered.connect(
			set_skill_overlay_preview.bind(char_name, action_data)
		)
		choose_button.mouse_exited.connect(clear_skill_overlay_preview)

	skill_menu_overlay.modulate.a = 0.0
	frame.pivot_offset = frame.size * 0.5
	var tween := create_tween()
	tween.tween_property(skill_menu_overlay, "modulate:a", 1.0, 0.10)
	tween.parallel().tween_property(frame, "scale", Vector2.ONE, 0.16).from(Vector2(0.97, 0.97))


func set_skill_overlay_preview(char_name: String, action_data: Dictionary) -> void:
	set_ctb_action_preview(char_name, action_data)

	if skill_overlay_preview_label != null and is_instance_valid(skill_overlay_preview_label):
		skill_overlay_preview_label.text = get_tactical_action_preview(
			char_name,
			action_data
		)


func clear_skill_overlay_preview() -> void:
	clear_ctb_action_preview()

	if skill_overlay_preview_label != null and is_instance_valid(skill_overlay_preview_label):
		skill_overlay_preview_label.text = "技に触れると　行動順 / 月 / 奏譜 / 崩し　を予測"


func close_skill_menu() -> void:
	clear_ctb_action_preview()

	if skill_menu_overlay == null or not is_instance_valid(skill_menu_overlay):
		skill_menu_overlay = null
		skill_overlay_preview_label = null
		return

	play_command_sound(0.84)

	var overlay := skill_menu_overlay
	skill_menu_overlay = null
	skill_overlay_preview_label = null

	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.08)
	tween.tween_callback(overlay.queue_free)


func select_skill_from_overlay(
	char_name: String,
	skill_data: Dictionary
) -> void:
	# signal発火中に即freeしない。まず非表示・入力無効化しqueue_free。
	if skill_menu_overlay != null and is_instance_valid(skill_menu_overlay):
		var overlay := skill_menu_overlay
		skill_menu_overlay = null
		skill_overlay_preview_label = null
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.hide()
		overlay.queue_free()

	clear_ctb_action_preview()
	select_skill(char_name, skill_data)


func return_to_skill_menu(char_name: String) -> void:
	show_main_commands(char_name)
	show_skill_menu(char_name)


func select_skill(char_name: String, skill_data: Dictionary) -> void:
	var target_mode: String = str(skill_data["target"])

	if target_mode == "ally":
		show_ally_target_menu(char_name, skill_data)
	elif target_mode == "self":
		queue_action(
			char_name,
			{
				"type": "skill",
				"skill": skill_data,
				"target": char_name
			}
		)
	else:
		queue_action(
			char_name,
			{
				"type": "skill",
				"skill": skill_data,
				"target": ""
			}
		)


func show_ally_target_menu(char_name: String, skill_data: Dictionary) -> void:
	play_command_sound(1.03)
	clear_container(command_box)

	command_sub_label.text = str(skill_data["name"]) + "　／　対象選択"
	command_title_label.text = "誰に使う？"

	for target_name in party:
		var target_state: Dictionary = party_state[target_name]
		if int(target_state["cur_hp"]) <= 0:
			continue

		var button := make_command_button(
			target_name,
			"生命 %d / %d　奏力 %d / %d" % [
				int(target_state["cur_hp"]),
				int(target_state["hp"]),
				int(target_state["cur_mana"]),
				int(target_state["mana"])
			]
		)
		button.pressed.connect(
			queue_action.bind(
				char_name,
				{
					"type": "skill",
					"skill": skill_data,
					"target": target_name
				}
			)
		)
		command_box.add_child(button)

	var back_button := make_secondary_button("← 特技へ", 0)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(return_to_skill_menu.bind(char_name))
	command_box.add_child(back_button)


func queue_basic_attack(char_name: String) -> void:
	queue_action(
		char_name,
		{
			"type": "attack",
			"target": ""
		}
	)


func queue_guard(char_name: String) -> void:
	queue_action(
		char_name,
		{
			"type": "guard",
			"target": char_name
		}
	)


func queue_ultimate(char_name: String) -> void:
	if not is_ultimate_ready(char_name):
		play_command_sound(0.72)
		append_log("%sの必殺技はまだ解放されていない。" % char_name)
		return

	queue_action(
		char_name,
		{
			"type": "ultimate",
			"target": ""
		}
	)


func queue_action(char_name: String, action_data: Dictionary) -> void:
	if busy:
		return
	if char_name != get_current_planning_actor():
		return

	var queued_type := str(action_data.get("type", ""))
	if queued_type not in ["attack", "guard", "skill", "ultimate"]:
		push_warning("Unknown queued action type: " + queued_type)
		return
	if queued_type == "skill" and not action_data.has("skill"):
		push_warning("Skill action was queued without skill data.")
		return

	play_command_sound(1.0)

	# 選択した内容をその場で完全コピーして固定する。
	# UIを次キャラへ作り直しても、前キャラの行動内容は変わらない。
	var stored_action: Dictionary = action_data.duplicate(true)
	stored_action["actor"] = char_name
	pending_actions[char_name] = stored_action
	ctb_preview_action.clear()

	# その場では実行しない。三人分を決め切ってから戦闘が流れ始める。
	var next_index := find_next_commandable_index(command_cursor + 1)
	if next_index >= 0:
		command_cursor = next_index
		ctb_current_actor = planning_order[command_cursor]
		show_main_commands(ctb_current_actor)
		refresh_battle_ui()
		return

	busy = true
	clear_container(command_box)
	command_sub_label.text = "第%02d巡　／　作戦確定" % round_number
	command_title_label.text = "行動開始"
	command_box.add_child(make_label("全員の行動が決まった。行動順に沿って戦闘を開始する。", 11, COL_MUTED))
	refresh_battle_ui()
	call_deferred("resolve_round")


func undo_last_action() -> void:
	if busy or pending_actions.is_empty():
		return

	play_command_sound(0.84)
	var previous_index := -1
	for i in range(mini(command_cursor - 1, planning_order.size() - 1), -1, -1):
		var name := planning_order[i]
		if pending_actions.has(name):
			previous_index = i
			break

	if previous_index < 0:
		return

	var previous_name := planning_order[previous_index]
	pending_actions.erase(previous_name)
	command_cursor = previous_index
	ctb_current_actor = previous_name
	ctb_preview_action.clear()
	show_main_commands(previous_name)
	refresh_battle_ui()

func resolve_round() -> void:
	# v7.1:
	# 先に操作可能な味方全員の行動を決め、その後にCTB上の順番でまとめて流す。
	# 「一人選ぶ→即実行」にはしない。
	busy = true
	ctb_preview_action.clear()
	clear_container(command_box)
	command_sub_label.text = "第%02d巡" % round_number
	command_title_label.text = "行動開始"
	command_box.add_child(make_label("決めた作戦を行動順に沿って実行している…", 11, COL_MUTED))

	# 全員が決めた作戦を開始時点で固定する。
	# 解決中にpending_actionsを書き換えても、別の行動へ化けない。
	var round_plan: Dictionary = pending_actions.duplicate(true)

	var remaining_players: Dictionary = {}
	for char_name in party:
		if not round_plan.has(char_name):
			continue
		if int(party_state[char_name]["cur_hp"]) <= 0:
			continue
		if int(party_state[char_name].get("broken_rounds", 0)) > 0:
			continue
		remaining_players[char_name] = true

	var force_enemy_event := remaining_players.is_empty()
	var enemy_event_done := false
	var safety := 0

	while (
		not remaining_players.is_empty()
		or (force_enemy_event and not enemy_event_done)
	):
		safety += 1
		if safety > 32:
			push_warning("CTB resolution safety break")
			break

		if is_party_defeated() or int(enemy_state["cur_hp"]) <= 0:
			break

		var next_key := ""
		var next_time := INF

		# 敵は何度でも候補に入る。味方はこの巡で選んだ行動を一度だけ実行する。
		if ctb_times.has(CTB_ENEMY_KEY):
			next_key = CTB_ENEMY_KEY
			next_time = float(ctb_times[CTB_ENEMY_KEY])

		for char_name_variant in remaining_players.keys():
			var char_name := str(char_name_variant)
			if not ctb_times.has(char_name):
				continue
			var candidate_time := float(ctb_times[char_name])
			if candidate_time < next_time:
				next_time = candidate_time
				next_key = char_name

		if next_key == "":
			break

		ctb_clock = next_time
		ctb_current_actor = next_key
		refresh_battle_ui()

		if next_key == CTB_ENEMY_KEY:
			var enemy_state_before := int(enemy_state.get("big_state", 0))
			await perform_enemy_action()
			enemy_event_done = true
			var enemy_wait := get_enemy_ctb_wait(true)
			if enemy_state_before == 1:
				enemy_wait = maxi(34, enemy_wait - 12)
			ctb_times[CTB_ENEMY_KEY] = ctb_clock + float(enemy_wait)
		else:
			var actor_name := next_key
			var action_data: Dictionary = round_plan[actor_name].duplicate(true)

			if int(party_state[actor_name]["cur_hp"]) <= 0:
				append_log("%sは倒れており、予定していた行動を失った。" % actor_name)
				ctb_times[actor_name] = ctb_clock + 80.0
			elif int(party_state[actor_name].get("broken_rounds", 0)) > 0:
				append_log(
					"[color=#b96a72]%sは崩壊し、予定していた%sを失った。[/color]"
					% [actor_name, get_action_score_name(action_data)]
				)
				ctb_times[actor_name] = ctb_clock + 72.0
			else:
				command_title_label.text = "%s　―　%s" % [
					actor_name,
					get_action_score_name(action_data)
				]
				command_sub_label.text = "選択した作戦を実行中"
				await perform_player_action(actor_name, action_data)

				# 奏譜成立演出が出た場合は、次の行動へ進まず少し見せる。
				var banner_wait_ms := score_banner_lock_until - Time.get_ticks_msec()
				if banner_wait_ms > 0:
					await get_tree().create_timer(float(banner_wait_ms) / 1000.0).timeout
					score_banner_lock_until = 0

				var wait_value := get_effective_action_wait(
					actor_name,
					action_data,
					true
				)
				ctb_last_wait[actor_name] = wait_value
				ctb_times[actor_name] = ctb_clock + float(wait_value)

			remaining_players.erase(actor_name)
			pending_actions.erase(actor_name)

		refresh_battle_ui()
		await get_tree().create_timer(0.18).timeout

	if not is_party_defeated() and int(enemy_state["cur_hp"]) > 0:
		await apply_end_of_round_effects()

	refresh_battle_ui()

	if int(enemy_state["cur_hp"]) <= 0:
		await show_battle_victory()
		return

	if is_party_defeated():
		show_game_over()
		return

	pending_actions.clear()
	ctb_preview_action.clear()
	ctb_current_actor = ""
	command_cursor = -1

	# この巡で予約された月操作をここでまとめて反映。
	# 次の巡の作戦入力が始まる前に月が確定する。
	commit_next_round_moon()

	round_number += 1
	total_rounds += 1
	begin_command_phase()


func sort_turns_descending(a: Dictionary, b: Dictionary) -> bool:
	var speed_a: int = int(a["speed"])
	var speed_b: int = int(b["speed"])

	if speed_a == speed_b:
		return str(a["side"]) == "player"

	return speed_a > speed_b


func perform_player_action(char_name: String, action_data: Dictionary) -> void:
	var action_type := str(action_data.get("type", ""))
	active_score_note = get_action_note_type(action_data)

	match action_type:
		"attack":
			await perform_basic_attack(char_name)
		"guard":
			await perform_guard_action(char_name)
		"skill":
			if not action_data.has("skill"):
				push_warning("Skill action missing data for " + char_name)
				append_log("[color=#b36c72]%sの特技情報が失われた。行動を中止。[/color]" % char_name)
			else:
				await perform_skill_action(char_name, action_data)
		"ultimate":
			await perform_ultimate_action(char_name)
		_:
			push_warning("Unknown player action: " + action_type)
			append_log("[color=#b36c72]%sの行動情報が不正。通常攻撃へ置換せず中止。[/color]" % char_name)

	active_score_note = ""


func perform_basic_attack(char_name: String) -> void:
	var state: Dictionary = party_state[char_name]
	var attack_stat: int = get_player_stat(char_name, "atk")
	var enemy_def: int = get_enemy_stat("def")

	var damage: int = calculate_damage(attack_stat, enemy_def, 1.00)
	var break_damage: int = calculate_break_damage(
		int(state["break"]),
		1.00
	)

	var attack_mana_gain := 3 if moon_index == 1 else 2
	state["cur_mana"] = mini(
		int(state["mana"]),
		int(state["cur_mana"]) + attack_mana_gain
	)
	state["last_skill_id"] = ""
	state["repeat_count"] = 0
	party_state[char_name] = state
	recover_player_stance(char_name, 10)

	advance_moon(1)
	advance_beat(char_name, get_basic_attack_note(char_name), "攻撃")

	play_layered_attack(1.0)
	play_character_attack_fx(char_name)
	trigger_slash()

	if screen_mode == "battle":
		var basic_enemy_center := Vector2(
			get_viewport_rect().size.x * 0.43,
			get_viewport_rect().size.y * 0.43
		)
		match char_name:
			"侍", "くノ一", "猫又":
				play_pixel_vfx("Hit Sparks/Slash Hit", basic_enemy_center, 3.1, 22.0)
			"傘使い", "酒呑童子":
				play_pixel_vfx("Hit Sparks/Blunt Thud", basic_enemy_center, 3.0, 20.0)
			_:
				play_pixel_vfx("Hit Sparks/Hit Spark", basic_enemy_center, 2.8, 22.0)

	deal_damage_to_enemy(damage, break_damage)

	append_log(
		"%sの攻撃　[color=#edcf80]%d[/color] ダメージ　崩し %d"
		% [char_name, damage, break_damage]
	)

	await get_tree().create_timer(0.22).timeout


func perform_guard_action(char_name: String) -> void:
	var state: Dictionary = party_state[char_name]
	state["guarding"] = true
	state["last_skill_id"] = ""
	state["repeat_count"] = 0
	party_state[char_name] = state
	recover_player_stance(char_name, 25)

	if screen_mode == "battle":
		var guard_center := get_party_effect_center(
			char_name,
			get_viewport_rect().size * Vector2(0.70, 0.80)
		)
		play_pixel_vfx("Magic/Shield Bubble", guard_center, 3.3, 18.0, Color("#c8d7e6"))
		play_pixel_vfx("Hit Sparks/Parry Flash", guard_center, 2.8, 20.0)

	advance_moon(1)
	advance_beat(char_name, "休", "防御")

	append_log(
		"%sは[color=#9bb5d0]防御[/color]の構えを取った。"
		% char_name
	)

	await get_tree().create_timer(0.18).timeout


func perform_skill_action(char_name: String, action_data: Dictionary) -> void:
	var state: Dictionary = party_state[char_name]
	var skill_data: Dictionary = action_data["skill"]
	var skill_id: String = str(skill_data["id"])
	var cost: int = get_effective_skill_cost(char_name, skill_data)
	var strain: int = get_skill_stance_cost(char_name, skill_data)
	var score_note: String = get_skill_note_type(skill_id)

	if int(state["cur_mana"]) < cost:
		append_log(
			"[color=#b36c72]%sは奏力不足で%sを使えなかった。[/color]"
			% [char_name, str(skill_data["name"])]
		)
		await get_tree().create_timer(0.16).timeout
		return

	if has_status(state, "seal"):
		append_log(
			"[color=#b36c72]%sは封技されている。[/color]"
			% char_name
		)
		await get_tree().create_timer(0.16).timeout
		return

	state["cur_mana"] = int(state["cur_mana"]) - cost
	var was_repeat := str(state.get("last_skill_id", "")) == skill_id
	state["repeat_count"] = int(state.get("repeat_count", 0)) + 1 if was_repeat else 1
	state["last_skill_id"] = skill_id
	party_state[char_name] = state

	apply_player_stance_damage(char_name, strain, "技の反動")
	if was_repeat:
		append_log("[color=#b68a67]%sは残響過多。奏力と構えの消費が増えた。[/color]" % char_name)

	await show_skill_cut_in(
		char_name,
		str(skill_data["name"]),
		skill_id
	)
	await play_skill_motion(skill_id, char_name, str(action_data.get("target", "")))

	match skill_id:
		"samurai_moon_slash":
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				1.55
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				1.45
			)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.94)
			trigger_slash()
			deal_damage_to_enemy(damage, break_damage)
			append_log(
				"%s「[b]月断ち[/b]」　[color=#f0d17f]%d[/color] ダメージ"
				% [char_name, damage]
			)

		"samurai_iai":
			var power := 2.15
			if int(enemy_state["broken_rounds"]) > 0:
				power *= 1.50
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				power
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.75
			)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.88)
			trigger_slash()
			flash_alpha = 0.12
			deal_damage_to_enemy(damage, break_damage)
			append_log(
				"%s「[b]居合・朔[/b]」　[color=#f0d17f]%d[/color] ダメージ"
				% [char_name, damage]
			)

		"samurai_red_mist":
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				1.15
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.90
			)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.97)
			trigger_slash()
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("def_down", adjusted_enemy_status_turns(3))
			append_log(
				"%s「[b]血霞[/b]」　敵の防御が低下。"
				% char_name
			)

		"samurai_swallow_break":
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				0.95
			)
			var break_power := 2.80 if int(enemy_state.get("big_state", 0)) > 0 else 1.20
			var break_damage := calculate_break_damage(int(state["break"]), break_power)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(1.08)
			trigger_slash()
			deal_damage_to_enemy(damage, break_damage)
			append_log(
				"%s「[b]燕返し[/b]」　崩し %d%s"
				% [
					char_name,
					break_damage,
					"　大技の構えを狙い撃ち" if int(enemy_state.get("big_state", 0)) > 0 else ""
				]
			)

		"samurai_aftermoon":
			var power := 1.45
			var was_broken := int(enemy_state.get("broken_rounds", 0)) > 0
			if was_broken:
				power = 1.65
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				power
			)
			var break_damage := calculate_break_damage(int(state["break"]), 0.85)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.91)
			trigger_slash()
			deal_damage_to_enemy(damage, break_damage)
			if was_broken:
				recover_player_stance(char_name, 18)
			append_log(
				"%s「[b]残月[/b]」　[color=#f0d17f]%d[/color] ダメージ%s"
				% [char_name, damage, "　構え+18" if was_broken else ""]
			)

		"sennin_thunder":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.50
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.85
			)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(1.06)
			flash_alpha = 0.08
			deal_damage_to_enemy(damage, break_damage)
			append_log(
				"%s「[b]仙雷[/b]」　[color=#c8d8ef]%d[/color] ダメージ"
				% [char_name, damage]
			)

		"sennin_moon_turn":
			var updated: Dictionary = party_state[char_name]
			updated["cur_mana"] = mini(
				int(updated["mana"]),
				int(updated["cur_mana"]) + 2
			)
			party_state[char_name] = updated
			advance_moon(3)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]月転[/b]」　月相を大きく進め、奏力+2。"
				% char_name
			)

		"sennin_spring":
			for ally_name in party:
				var ally_state: Dictionary = party_state[ally_name]
				if int(ally_state["cur_hp"]) <= 0:
					continue

				ally_state["cur_mana"] = mini(
					int(ally_state["mana"]),
					int(ally_state["cur_mana"]) + 3
				)

				var heal_amount: int = maxi(
					1,
					int(round(float(ally_state["hp"]) * 0.08))
				)
				ally_state["cur_hp"] = mini(
					int(ally_state["hp"]),
					int(ally_state["cur_hp"]) + heal_amount
				)

				party_state[ally_name] = ally_state

			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]霊泉[/b]」　味方全体の生命と奏力を回復。"
				% char_name
			)

		"sennin_wind_read":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				recover_player_stance(ally_name, 12)
				if ctb_times.has(ally_name) and ally_name != char_name:
					ctb_times[ally_name] = maxf(
						ctb_clock + 6.0,
						float(ctb_times[ally_name]) - 10.0
					)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]風読み[/b]」　味方の構えを整え、次の行動を引き寄せた。"
				% char_name
			)

		"sennin_moon_hold":
			if (
				int(enemy_state.get("big_state", 0)) > 0
				and ctb_times.has(CTB_ENEMY_KEY)
			):
				ctb_times[CTB_ENEMY_KEY] = float(ctb_times[CTB_ENEMY_KEY]) + 16.0
				append_log("[color=#9fc8e8]月留めが敵の大技の刻を遅らせた。[/color]")
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))

		"kasa_pierce":
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				1.25
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				2.15
			)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.92)
			trigger_slash()
			deal_damage_to_enemy(damage, break_damage)
			append_log(
				"%s「[b]雨穿ち[/b]」　崩し %d"
				% [char_name, break_damage]
			)

		"kasa_counter":
			var updated: Dictionary = party_state[char_name]
			updated["guarding"] = true
			updated["counter"] = true
			party_state[char_name] = updated
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]傘返し[/b]」　防御し、被弾に備えた。"
				% char_name
			)

		"kasa_ward":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				add_player_status(ally_name, "ward", 2)

			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]豪雨円陣[/b]」　味方全体に結界。"
				% char_name
			)

		"kasa_rain_armor":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				recover_player_stance(ally_name, 20)
				add_player_status(ally_name, "ward", 1)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]雨鎧[/b]」　味方全体の構えを20回復し、一巡の結界。"
				% char_name
			)

		"kasa_thunder_guard":
			var damage := calculate_damage(
				get_player_stat(char_name, "atk"),
				get_enemy_stat("def"),
				0.85
			)
			var break_power := 2.85 if int(enemy_state.get("big_state", 0)) > 0 else 1.65
			var break_damage := calculate_break_damage(int(state["break"]), break_power)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.86)
			append_log(
				"%s「[b]雷傘[/b]」　崩し %d"
				% [char_name, break_damage]
			)

		"miko_heal":
			var target_name: String = str(action_data["target"])
			if target_name == "" or int(party_state[target_name]["cur_hp"]) <= 0:
				target_name = find_lowest_hp_ally()

			if target_name != "":
				var heal_amount := calculate_heal(
					get_player_stat(char_name, "mag"),
					2.20,
					18
				)
				heal_player(target_name, heal_amount)
				append_log(
					"%s「[b]神楽祓[/b]」　%sの生命を[color=#8ec39b]%d[/color]回復。"
					% [char_name, target_name, heal_amount]
				)

			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))

		"miko_cleanse":
			for ally_name in party:
				var ally_state: Dictionary = party_state[ally_name]
				if int(ally_state["cur_hp"]) <= 0:
					continue

				var heal_amount := calculate_heal(
					get_player_stat(char_name, "mag"),
					0.95,
					8
				)

				heal_player(ally_name, heal_amount)
				clear_negative_statuses(ally_name)

			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]禊[/b]」　味方全体を回復し、状態異常を祓った。"
				% char_name
			)

		"miko_bless":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				add_player_status(ally_name, "blessing", 3)

			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]月詠祝詞[/b]」　味方全体の攻撃・術式が上昇。"
				% char_name
			)

		"miko_bell_guard":
			var target_name: String = str(action_data["target"])
			if target_name == "" or int(party_state[target_name]["cur_hp"]) <= 0:
				target_name = find_lowest_hp_ally()
			if target_name != "":
				var heal_amount := calculate_heal(
					get_player_stat(char_name, "mag"),
					0.90,
					6
				)
				heal_player(target_name, heal_amount)
				recover_player_stance(target_name, 35)
				append_log(
					"%s「[b]鈴守[/b]」　%sの生命を%d回復、構え+35。"
					% [char_name, target_name, heal_amount]
				)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))

		"miko_divine_descent":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				var heal_amount := calculate_heal(
					get_player_stat(char_name, "mag"),
					1.05,
					10
				)
				heal_player(ally_name, heal_amount)
				add_player_status(ally_name, "blessing", 2)
				add_player_status(ally_name, "ward", 1)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]神降ろし[/b]」　味方全体を癒し、祝詞と結界を重ねた。"
				% char_name
			)

		"chochin_foxfire":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.35
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.80
			)
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("burn", adjusted_enemy_status_turns(3))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(1.02)
			append_log(
				"%s「[b]狐火[/b]」　敵を火傷させた。"
				% char_name
			)

		"chochin_lantern_drop":
			var power := 1.85
			if has_status(enemy_state, "burn"):
				power *= 1.25

			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				power
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				1.05
			)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.90)
			trigger_slash()
			append_log(
				"%s「[b]灯籠落とし[/b]」　[color=#eebd75]%d[/color] ダメージ"
				% [char_name, damage]
			)

		"chochin_dim":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.05
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.65
			)
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("atk_down", adjusted_enemy_status_turns(3))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]迷い火[/b]」　敵の攻撃が低下。"
				% char_name
			)

		"chochin_ember_step":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.00
			)
			var break_damage := calculate_break_damage(int(state["break"]), 0.70)
			deal_damage_to_enemy(damage, break_damage)
			if has_status(enemy_state, "burn"):
				var echo_damage := maxi(1, int(round(float(enemy_state["hp"]) * 0.03)))
				enemy_state["cur_hp"] = maxi(0, int(enemy_state["cur_hp"]) - echo_damage)
				spawn_enemy_damage_popup(echo_damage, false)
				var statuses: Dictionary = enemy_state["statuses"]
				statuses["burn"] = int(statuses.get("burn", 0)) + 1
				enemy_state["statuses"] = statuses
				append_log("[color=#e88958]鬼火が燃え移り、%dの追加発火。[/color]" % echo_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))

		"chochin_burst":
			var burning := has_status(enemy_state, "burn")
			var power := 2.20 if burning else 1.65
			var break_power := 1.55 if burning else 0.90
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				power
			)
			var break_damage := calculate_break_damage(int(state["break"]), break_power)
			if burning:
				var statuses: Dictionary = enemy_state["statuses"]
				statuses.erase("burn")
				enemy_state["statuses"] = statuses
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			play_layered_attack(0.84)
			append_log(
				"%s「[b]灯爆ぜ[/b]」　[color=#eebd75]%d[/color] ダメージ%s"
				% [char_name, damage, "　火傷を爆ぜさせた" if burning else ""]
			)

		"jusoshi_poison":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.10
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.55
			)
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("poison", adjusted_enemy_status_turns(4))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]蝕呪[/b]」　敵に毒を刻んだ。"
				% char_name
			)

		"jusoshi_bind":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				0.85
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.60
			)
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("atk_down", adjusted_enemy_status_turns(3))
			add_enemy_status("def_down", adjusted_enemy_status_turns(3))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]骨縛り[/b]」　敵の攻撃・防御が低下。"
				% char_name
			)

		"jusoshi_grudge":
			var weak_count: int = count_enemy_negative_statuses()
			var bonus: float = minf(0.45, float(weak_count) * 0.15)
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.80 * (1.0 + bonus)
			)
			var break_damage := calculate_break_damage(
				int(state["break"]),
				0.75
			)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			flash_alpha = 0.10
			append_log(
				"%s「[b]怨返し[/b]」　弱体を喰らい[color=#cba1dc]%d[/color] ダメージ"
				% [char_name, damage]
			)

		"jusoshi_extend":
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				0.80
			)
			var break_damage := calculate_break_damage(int(state["break"]), 0.55)
			deal_damage_to_enemy(damage, break_damage)
			var extended := extend_enemy_negative_statuses(1)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]呪継ぎ[/b]」　敵の弱体を%d種延長。"
				% [char_name, extended]
			)

		"jusoshi_abyss_mark":
			var weak_count := count_enemy_negative_statuses()
			var damage := calculate_damage(
				get_player_stat(char_name, "mag"),
				get_enemy_stat("res"),
				1.25
			)
			var break_power := minf(2.20, 0.80 + float(weak_count) * 0.35)
			var break_damage := calculate_break_damage(int(state["break"]), break_power)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log(
				"%s「[b]奈落印[/b]」　弱体%d種を利用し崩し %d。"
				% [char_name, weak_count, break_damage]
			)

		"kunoichi_shadow_bind":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 1.05)
			var break_damage := calculate_break_damage(int(state["break"]), 1.05)
			deal_damage_to_enemy(damage, break_damage)
			if ctb_times.has(CTB_ENEMY_KEY):
				ctb_times[CTB_ENEMY_KEY] = float(ctb_times[CTB_ENEMY_KEY]) + 12.0
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]影縫い[/b]」　敵の刻を縫い止めた。" % char_name)

		"kunoichi_poison_star":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 0.90)
			var break_damage := calculate_break_damage(int(state["break"]), 0.70)
			deal_damage_to_enemy(damage, break_damage)
			add_enemy_status("poison", adjusted_enemy_status_turns(3))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]毒手裏剣[/b]」　敵に毒を刻んだ。" % char_name)

		"kunoichi_mist_step":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 0.75)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 0.55))
			recover_player_stance(char_name, 12)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]霞走り[/b]」　構え+12。" % char_name)

		"kunoichi_ninja_return":
			var updated: Dictionary = party_state[char_name]
			updated["guarding"] = true
			updated["counter"] = true
			party_state[char_name] = updated
			if ctb_times.has(char_name):
				ctb_times[char_name] = maxf(ctb_clock + 4.0, float(ctb_times[char_name]) - 10.0)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]忍返し[/b]」　身を伏せ、反撃の間合いへ。" % char_name)

		"kunoichi_scatter_star":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 1.80)
			var break_damage := calculate_break_damage(int(state["break"]), 1.55)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]乱れ星[/b]」　[color=#d8e2eb]%d[/color] ダメージ。" % [char_name, damage])

		"shuten_oni_smash":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 1.75)
			var break_damage := calculate_break_damage(int(state["break"]), 2.10)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]鬼砕き[/b]」　崩し %d。" % [char_name, break_damage])

		"shuten_sake_flame":
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 1.25)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 0.85))
			add_enemy_status("burn", adjusted_enemy_status_turns(3))
			recover_player_stance(char_name, 8)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]酒炎[/b]」　火傷を与え、構え+8。" % char_name)

		"shuten_drink_dry":
			var updated: Dictionary = party_state[char_name]
			var heal_amount := maxi(1, int(round(float(updated["hp"]) * 0.18)))
			updated["cur_hp"] = mini(int(updated["hp"]), int(updated["cur_hp"]) + heal_amount)
			updated["cur_mana"] = mini(int(updated["mana"]), int(updated["cur_mana"]) + 2)
			party_state[char_name] = updated
			recover_player_stance(char_name, 30)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]呑み干し[/b]」　生命・奏力・構えを立て直した。" % char_name)

		"shuten_drunk_barrage":
			var power := 2.15
			if has_status(party_state[char_name], "rage"):
				power *= 1.25
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), power)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 1.30))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]酔狂乱打[/b]」　[color=#e38970]%d[/color] ダメージ。" % [char_name, damage])

		"shuten_hyakki_feast":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) > 0:
					recover_player_stance(ally_name, 14)
			add_player_status(char_name, "rage", 3)
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]百鬼宴[/b]」　味方の構えを整え、自身は昂揚した。" % char_name)

		"kagurashi_rhythm_dance":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				recover_player_stance(ally_name, 8)
				if ctb_times.has(ally_name):
					ctb_times[ally_name] = maxf(ctb_clock + 5.0, float(ctb_times[ally_name]) - 8.0)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]拍子舞[/b]」　味方の刻を前へ寄せた。" % char_name)

		"kagurashi_double_beat":
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			# この技だけ二拍目を同じ音紋で刻む。
			advance_beat(char_name, score_note, "重ね拍子・追拍")
			append_log("%s「[b]重ね拍子[/b]」　同じ音紋を二拍重ねた。" % char_name)

		"kagurashi_repose":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) <= 0:
					continue
				var heal_amount := calculate_heal(get_player_stat(char_name, "mag"), 0.72, 5)
				heal_player(ally_name, heal_amount)
				recover_player_stance(ally_name, 10)
				var statuses: Dictionary = party_state[ally_name]["statuses"]
				statuses.erase("poison")
				statuses.erase("burn")
				party_state[ally_name]["statuses"] = statuses
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]鎮魂舞[/b]」　毒と火傷を鎮めた。" % char_name)

		"kagurashi_moon_call":
			for ally_name in party:
				var ally_state: Dictionary = party_state[ally_name]
				if int(ally_state["cur_hp"]) <= 0:
					continue
				ally_state["cur_mana"] = mini(int(ally_state["mana"]), int(ally_state["cur_mana"]) + 1)
				party_state[ally_name] = ally_state
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]月招き[/b]」　月を招き、味方の奏力+1。" % char_name)

		"kagurashi_wild_kagura":
			var charged := beat >= 6
			var power := 2.25 if charged else 1.65
			var break_power := 1.65 if charged else 0.90
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), power)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), break_power))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]荒神楽[/b]」　[color=#e1b8d6]%d[/color] ダメージ%s" % [char_name, damage, "　満ちた奏譜を解き放った" if charged else ""])

		"nekomata_cat_fire":
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 1.20)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 0.70))
			add_enemy_status("burn", adjusted_enemy_status_turns(3))
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]猫火[/b]」　青い火がまとわりついた。" % char_name)

		"nekomata_twin_tail":
			var damage := calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 1.15)
			var break_damage := calculate_break_damage(int(state["break"]), 1.20)
			deal_damage_to_enemy(damage, break_damage)
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]双尾裂き[/b]」　崩し %d。" % [char_name, break_damage])

		"nekomata_feint":
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 0.70)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 0.55))
			add_enemy_status("atk_down", adjusted_enemy_status_turns(2))
			if ctb_times.has(CTB_ENEMY_KEY):
				ctb_times[CTB_ENEMY_KEY] = float(ctb_times[CTB_ENEMY_KEY]) + 15.0
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]猫騙し[/b]」　敵の刻を乱した。" % char_name)

		"nekomata_soul_lick":
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 1.05)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 0.65))
			heal_player(char_name, maxi(1, int(round(float(damage) * 0.50))))
			if count_enemy_negative_statuses() > 0:
				var updated: Dictionary = party_state[char_name]
				updated["cur_mana"] = mini(int(updated["mana"]), int(updated["cur_mana"]) + 1)
				party_state[char_name] = updated
			advance_moon(1)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]魂舐め[/b]」　生命を吸い取った。" % char_name)

		"nekomata_bakeneko_dance":
			var weak_count := count_enemy_negative_statuses()
			var power := 2.50 if weak_count >= 2 else 2.00
			var damage := calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), power)
			deal_damage_to_enemy(damage, calculate_break_damage(int(state["break"]), 1.25))
			advance_moon(2)
			advance_beat(char_name, score_note, str(skill_data["name"]))
			append_log("%s「[b]化生乱舞[/b]」　[color=#83d0c7]%d[/color] ダメージ。" % [char_name, damage])

	await get_tree().create_timer(0.24).timeout


# ============================================================
# BOSS IDENTITIES / SECOND PHASES
# ============================================================

func is_enemy_second_phase() -> bool:
	return bool(enemy_state.get("phase2", false))


func get_enemy_second_phase_name() -> String:
	match str(enemy_state.get("id", "")):
		"moon_oni": return "砕月"
		"fire_spider": return "焔繭"
		"bone_monk": return "逆笛"
		"dark_tengu": return "迅天"
		"eclipse_lady": return "月蝕ノ相"
		_: return "第二相"


func get_enemy_mechanic_text() -> String:
	var phase_text := "第二相・%s　" % get_enemy_second_phase_name() if is_enemy_second_phase() else ""
	match str(enemy_state.get("id", "")):
		"moon_oni": return phase_text + "砕月　通常被害↓・崩し↑"
		"fire_spider": return phase_text + "火繭　味方の火傷が多いほど加速"
		"bone_monk": return phase_text + "逆笛　奏譜へ乱拍を差し込む"
		"dark_tengu": return phase_text + "迅天　行動順を押し流す"
		"eclipse_lady": return phase_text + "月蝕　月相を動かす"
		_: return phase_text


func get_enemy_damage_taken_modifier() -> float:
	if str(enemy_state.get("id", "")) == "moon_oni" and int(enemy_state.get("broken_rounds", 0)) <= 0:
		return 0.76 if is_enemy_second_phase() else 0.86
	return 1.0


func get_enemy_break_taken_modifier() -> float:
	if str(enemy_state.get("id", "")) == "moon_oni":
		return 1.55 if is_enemy_second_phase() else 1.30
	return 1.0


func count_burning_allies() -> int:
	var count := 0
	for char_name in party:
		if int(party_state[char_name].get("cur_hp", 0)) > 0 and has_status(party_state[char_name], "burn"):
			count += 1
	return count


func disturb_score_notes(amount: int) -> void:
	if measure_notes.is_empty():
		append_log("[color=#8d8196]逆笛は鳴ったが、乱す拍がまだない。[/color]")
		return
	var changed := 0
	for i in range(measure_notes.size() - 1, -1, -1):
		if changed >= amount:
			break
		var note: Dictionary = measure_notes[i]
		if str(note.get("mark", "")) == "休":
			continue
		note["mark"] = "休"
		note["action_name"] = "乱拍"
		measure_notes[i] = note
		changed += 1
	if changed > 0:
		append_log("[color=#ad91ba]逆笛：直前の%d拍が乱された。[/color]" % changed)
		refresh_music_ui()


func push_party_timeline(amount: float) -> void:
	for char_name in party:
		if ctb_times.has(char_name) and int(party_state[char_name].get("cur_hp", 0)) > 0:
			ctb_times[char_name] = float(ctb_times[char_name]) + amount
	refresh_turn_order_bar()


func pull_enemy_timeline(amount: float) -> void:
	if ctb_times.has(CTB_ENEMY_KEY):
		ctb_times[CTB_ENEMY_KEY] = maxf(ctb_clock + 3.0, float(ctb_times[CTB_ENEMY_KEY]) - amount)
	refresh_turn_order_bar()


func enemy_moon_shift(amount: int) -> void:
	if amount <= 0:
		return
	queue_enemy_moon_shift(amount)
	enemy_state["moon_shift_count"] = int(enemy_state.get("moon_shift_count", 0)) + amount
	append_log(
		"[color=#bba6c8]%sが次巡の月相を%dつ余分に進める。[/color]"
		% [str(enemy_state["name"]), amount]
	)


func check_enemy_second_phase() -> void:
	if enemy_state.is_empty() or is_enemy_second_phase():
		return
	if int(enemy_state.get("cur_hp", 0)) <= 0:
		return
	var ratio := float(enemy_state["cur_hp"]) / maxf(1.0, float(enemy_state["hp"]))
	if ratio > 0.50:
		return

	enemy_state["phase2"] = true
	enemy_state["phase_name"] = get_enemy_second_phase_name()
	enemy_state["big_state"] = 0
	enemy_state["big_target"] = ""
	enemy_state["next_big_round"] = mini(int(enemy_state.get("next_big_round", round_number + 2)), round_number + 2)
	# 第二相移行時は構えを全回復させず、最低45%だけ保証。崩し計画は無駄にならない。
	enemy_state["cur_break"] = maxi(
		int(enemy_state["cur_break"]),
		int(round(float(enemy_state["break_max"]) * 0.45))
	)
	enemy_state_fx_signature = ""
	call_deferred("show_enemy_phase_transition")


func show_enemy_phase_transition() -> void:
	if enemy_phase_transition_running or screen_mode != "battle":
		return
	enemy_phase_transition_running = true
	play_generated_warning_sound()
	duck_battle_bgm(-25.0, 0.90)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.76)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)

	var top := make_label("第　二　相", 24, Color("#b7a88b"))
	apply_display_font(top)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(top)
	var name := make_label(get_enemy_second_phase_name(), 82, COL_GOLD_BRIGHT)
	apply_display_font(name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_outline_color", Color("#08060a"))
	name.add_theme_constant_override("outline_size", 12)
	v.add_child(name)

	var center_point := get_viewport_rect().size * Vector2(0.43, 0.44)
	spawn_shader_wave(center_point, MOON_COLORS[moon_index], 0.54)
	spawn_ink_burst(center_point, Color("#5e4b42"), 58)
	spawn_gpu_sparks(center_point, COL_GOLD_BRIGHT, 70, 360.0)
	shake_amount = maxf(shake_amount, 10.0)

	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.09)
	tween.tween_interval(0.90)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	await tween.finished
	overlay.queue_free()
	enemy_phase_transition_running = false
	refresh_battle_ui()


func apply_enemy_identity_end_round() -> void:
	if int(enemy_state.get("cur_hp", 0)) <= 0:
		return
	match str(enemy_state.get("id", "")):
		"moon_oni":
			if int(enemy_state.get("broken_rounds", 0)) <= 0 and int(enemy_state.get("cur_break", 0)) > 0:
				var rate := 0.15 if is_enemy_second_phase() else 0.09
				enemy_state["cur_break"] = mini(
					int(enemy_state["break_max"]),
					int(enemy_state["cur_break"]) + int(round(float(enemy_state["break_max"]) * rate))
				)
		"fire_spider":
			var burning := count_burning_allies()
			if burning > 0:
				pull_enemy_timeline(float(burning) * (5.0 if is_enemy_second_phase() else 3.0))
			if is_enemy_second_phase() and burning >= 2:
				var heal := maxi(1, int(round(float(enemy_state["hp"]) * 0.025)))
				enemy_state["cur_hp"] = mini(int(enemy_state["hp"]), int(enemy_state["cur_hp"]) + heal)
				append_log("[color=#d7825d]焔繭が火傷を喰らい、%d回復。[/color]" % heal)
		"eclipse_lady":
			if is_enemy_second_phase():
				enemy_moon_shift(1)


# ============================================================
# ENEMY AI
# ============================================================

func get_enemy_action_count() -> int:
	# 崩壊中や大技の予兆/発動は1回行動として扱い、理不尽な多重処理を避ける。
	if int(enemy_state.get("broken_rounds", 0)) > 0:
		return 1
	if int(enemy_state.get("big_state", 0)) > 0:
		return 1
	if str(enemy_state["id"]) == "eclipse_lady":
		var hp_ratio: float = float(enemy_state["cur_hp"]) / float(enemy_state["hp"])
		if hp_ratio <= 0.45:
			return 2
	return 1


func perform_enemy_action() -> void:
	if int(enemy_state["broken_rounds"]) > 0:
		if not enemy_break_announced:
			append_log("[color=#d0ad55]崩壊中。%sは動けない。[/color]" % str(enemy_state["name"]))
			enemy_break_announced = true
		await get_tree().create_timer(0.22).timeout
		return

	var big_state := int(enemy_state.get("big_state", 0))
	if big_state == 1:
		await perform_enemy_charge()
		return
	if big_state == 2:
		await perform_enemy_ultimate()
		return

	var enemy_id := str(enemy_state["id"])
	var roll := randi_range(0, 99)
	var phase2 := is_enemy_second_phase()

	match enemy_id:
		"moon_oni":
			if phase2 and roll < 34:
				await enemy_single_attack("砕構", 0.90, "physical", "", 34)
			elif phase2 and roll < 58:
				await enemy_party_attack("鬼踏", 0.56, "physical", "", 22)
			elif moon_index == 4:
				await enemy_single_attack("月牙", 1.32, "physical", "", 24)
			elif roll < 35:
				await enemy_single_attack("鬼哭", 0.70, "physical", "atk_down", 18)
			else:
				await enemy_single_attack("爪撃", 1.00, "physical", "", 18)

		"fire_spider":
			var burning := count_burning_allies()
			if phase2 and burning >= 2 and roll < 48:
				await enemy_party_attack("焔糸", 0.70, "magic", "burn", 19)
				pull_enemy_timeline(8.0)
			elif roll < 35:
				await enemy_single_attack("毒牙", 0.92, "physical", "poison", 15)
			elif roll < 78:
				await enemy_single_attack("狐火糸", 1.10 if not phase2 else 1.20, "magic", "burn", 16)
			else:
				await enemy_single_attack("縛糸", 0.62, "physical", "def_down", 18)

		"bone_monk":
			if (phase2 and roll < 48) or (not phase2 and roll < 24):
				disturb_score_notes(2 if phase2 else 1)
				await enemy_single_attack("乱笛", 0.72 if not phase2 else 0.86, "magic", "seal", 14)
			elif roll < 62:
				await enemy_single_attack("骨笛", 1.05, "magic", "seal", 15)
			elif roll < 82:
				await enemy_single_attack("錫杖", 1.12, "physical", "", 20)
			else:
				await enemy_single_attack("亡呪", 0.82, "magic", "atk_down", 14)

		"dark_tengu":
			if (phase2 and roll < 48) or (not phase2 and roll < 22):
				push_party_timeline(18.0 if phase2 else 11.0)
				pull_enemy_timeline(10.0 if phase2 else 5.0)
				await enemy_party_attack("乱天", 0.58, "magic", "", 16)
			elif roll < 56:
				await enemy_party_attack("黒風", 0.76, "magic", "", 18)
			elif roll < 82:
				await enemy_single_attack("天狗礫", 1.22, "physical", "def_down", 22)
			else:
				await enemy_single_attack("裂風", 1.32, "magic", "", 18)

		"eclipse_lady":
			if phase2 and roll < 34:
				enemy_moon_shift(2)
				await enemy_party_attack("月奪い", 0.60, "magic", "atk_down", 16)
			elif moon_index == 4 or roll < 30:
				await enemy_party_attack("月蝕片", 0.72 if not phase2 else 0.80, "magic", "burn", 20)
			elif phase2 and roll < 58:
				enemy_self_empower()
				await get_tree().create_timer(0.24).timeout
			elif roll < 78:
				await enemy_single_attack("黒月圧", 1.28, "physical", "", 24)
			else:
				await enemy_single_attack("蝕祈", 1.05, "magic", "atk_down", 18)

func enemy_single_attack(
	action_name: String,
	power: float,
	damage_type: String,
	status_key: String,
	stance_break: int = 0
) -> void:
	var target_name: String = pick_random_living_ally()
	if target_name == "":
		return

	var attack_value: int
	var defense_value: int

	if damage_type == "magic":
		attack_value = get_enemy_stat("mag")
		defense_value = get_player_stat(target_name, "res")
	else:
		attack_value = get_enemy_stat("atk")
		defense_value = get_player_stat(target_name, "def")

	var damage: int = calculate_damage(
		attack_value,
		defense_value,
		power
	)

	damage = apply_enemy_moon_damage(damage)
	damage = apply_player_defense_modifiers(target_name, damage)
	var break_amount := stance_break if stance_break > 0 else maxi(10, int(round(10.0 + power * 10.0)))
	damage_player_character(target_name, damage, break_amount)

	if status_key != "" and int(party_state[target_name]["cur_hp"]) > 0:
		add_player_status(target_name, status_key, 2)

	append_log(
		"%s「[b]%s[/b]」 → %s　[color=#d66e76]%d[/color] ダメージ"
		% [
			str(enemy_state["name"]),
			action_name,
			target_name,
			damage
		]
	)

	play_one_shot(damage_player, randf_range(0.98, 1.02))
	shake_amount = 8.0
	flash_alpha = 0.10

	await show_hurt_state(target_name, damage)
	await maybe_counter(target_name)


func enemy_party_attack(
	action_name: String,
	power: float,
	damage_type: String,
	status_key: String,
	stance_break: int = 0
) -> void:
	append_log(
		"%s「[b]%s[/b]」　味方全体を襲う。"
		% [str(enemy_state["name"]), action_name]
	)

	for target_name in party:
		if int(party_state[target_name]["cur_hp"]) <= 0:
			continue

		var attack_value: int
		var defense_value: int

		if damage_type == "magic":
			attack_value = get_enemy_stat("mag")
			defense_value = get_player_stat(target_name, "res")
		else:
			attack_value = get_enemy_stat("atk")
			defense_value = get_player_stat(target_name, "def")

		var damage: int = calculate_damage(
			attack_value,
			defense_value,
			power
		)

		damage = apply_enemy_moon_damage(damage)
		damage = apply_player_defense_modifiers(target_name, damage)
		var break_amount := stance_break if stance_break > 0 else maxi(8, int(round(8.0 + power * 8.0)))
		damage_player_character(target_name, damage, break_amount)

		if status_key != "" and int(party_state[target_name]["cur_hp"]) > 0:
			add_player_status(target_name, status_key, 2)

		await show_hurt_state(target_name, damage)
		await maybe_counter(target_name)

	play_one_shot(damage_player)
	shake_amount = 11.0
	flash_alpha = 0.13


func enemy_self_empower() -> void:
	add_enemy_status("rage", 3)

	var heal: int = maxi(
		1,
		int(round(float(enemy_state["hp"]) * 0.06))
	)

	enemy_state["cur_hp"] = mini(
		int(enemy_state["hp"]),
		int(enemy_state["cur_hp"]) + heal
	)

	append_log(
		"%s「[b]黒祈[/b]」　生命を%d回復し、昂揚した。"
		% [str(enemy_state["name"]), heal]
	)


func maybe_counter(target_name: String) -> void:
	var state: Dictionary = party_state[target_name]

	if not bool(state["counter"]):
		return
	if int(state["cur_hp"]) <= 0:
		return

	var counter_damage: int = calculate_damage(
		get_player_stat(target_name, "atk"),
		get_enemy_stat("def"),
		0.50
	)

	enemy_state["cur_hp"] = maxi(
		0,
		int(enemy_state["cur_hp"]) - counter_damage
	)
	check_enemy_second_phase()

	append_log(
		"%sの[color=#d7ba70]傘返し[/color]　%d ダメージ"
		% [target_name, counter_damage]
	)

	trigger_slash()
	play_layered_attack(0.90)
	await get_tree().create_timer(0.18).timeout


# ============================================================
# DAMAGE / HEAL / BREAK
# ============================================================

func calculate_damage(
	attack_value: int,
	defense_value: int,
	power: float
) -> int:
	var base: float = maxf(
		1.0,
		(float(attack_value) * power * 1.90)
		- (float(defense_value) * 0.72)
	)

	var variance: float = randf_range(0.97, 1.03)
	return maxi(1, int(round(base * variance)))


func calculate_heal(
	magic_value: int,
	power: float,
	flat_value: int
) -> int:
	var value: float = float(magic_value) * power + float(flat_value)

	if moon_index == 6:
		value *= 1.30
	elif moon_index == 0:
		value *= 1.08

	value *= randf_range(0.98, 1.02)
	return maxi(1, int(round(value)))


func calculate_break_damage(
	base_break: int,
	multiplier: float
) -> int:
	var value: float = float(base_break) * multiplier

	if moon_index == 2:
		value *= 1.35
	if combo_break_rounds > 0:
		value *= 1.20
	if int(enemy_state.get("break_guard_rounds", 0)) > 0:
		value *= 0.55

	return maxi(1, int(round(value)))


func deal_damage_to_enemy(
	damage: int,
	break_damage: int
) -> void:
	var final_damage: int = damage
	var final_break: int = break_damage

	# 同じ音を続けると敵が「聴き慣れる」。禁止ではないが効率が落ちる。
	if NOTE_VALUE.has(active_score_note):
		var adapt := get_enemy_note_adaptation(active_score_note)
		if adapt < 0.999:
			final_damage = maxi(1, int(round(float(final_damage) * adapt)))
			final_break = maxi(1, int(round(float(final_break) * adapt)))
			append_log("[color=#9a8f81]%sは%sを見切り始めている（効果%d%%）[/color]" % [
				str(enemy_state["name"]),
				get_note_display(active_score_note),
				int(round(adapt * 100.0))
			])

		# 現在の月の共鳴音なら少し取り返せる。
		if is_note_resonant(active_score_note, moon_index):
			final_damage = int(round(float(final_damage) * 1.10))
			final_break = int(round(float(final_break) * 1.12))

	# 月相そのものが攻撃のルールを変える。
	if moon_index == 3:
		final_damage = int(round(float(final_damage) * 1.12))
	elif moon_index == 4:
		final_damage = int(round(float(final_damage) * 1.25))
	elif moon_index == 7 and count_enemy_negative_statuses() > 0:
		final_damage = int(round(float(final_damage) * 1.15))

	if combo_damage_rounds > 0:
		final_damage = int(round(float(final_damage) * 1.15))

	final_damage = maxi(1, int(round(float(final_damage) * get_enemy_damage_taken_modifier())))
	final_break = maxi(0, int(round(float(final_break) * get_enemy_break_taken_modifier())))

	if int(enemy_state["broken_rounds"]) > 0:
		var broken_multiplier := 1.60 if moon_index == 4 else 1.35
		final_damage = int(round(float(final_damage) * broken_multiplier))

	enemy_state["cur_hp"] = maxi(
		0,
		int(enemy_state["cur_hp"]) - final_damage
	)

	enemy_state["cur_break"] = maxi(
		0,
		int(enemy_state["cur_break"]) - final_break
	)

	if NOTE_VALUE.has(active_score_note):
		record_enemy_note(active_score_note)

	trigger_hit_stop_for_damage(final_damage)
	play_enemy_hit_reaction(final_damage)
	spawn_enemy_damage_popup(final_damage, false)
	check_enemy_second_phase()

	if final_break > 0:
		spawn_enemy_break_popup(final_break)

	if (
		int(enemy_state["cur_break"]) <= 0
		and int(enemy_state["cur_hp"]) > 0
		and int(enemy_state.get("broken_rounds", 0)) <= 0
	):
		trigger_enemy_break()


func trigger_enemy_break() -> void:
	# BREAKは「今の行動を止める」だけでなく、次の1ラウンドも攻撃不能。
	# 上弦で崩した場合はさらに長く拘束できる。
	enemy_state["broken_rounds"] = 2 if moon_index == 2 else 1
	enemy_state["broken_on_round"] = round_number
	enemy_state["cur_break"] = 0

	# 大技の予兆・発動態勢を崩壊で中断できる。
	if int(enemy_state.get("big_state", 0)) > 0:
		append_log("[color=#e2bd63][b]大技中断[/b]　%sの構えを砕いた。[/color]" % str(enemy_state["name"]))
		enemy_state["big_state"] = 0
		enemy_state["big_target"] = ""
		enemy_state["big_charged_round"] = -1
		enemy_state["next_big_round"] = round_number + 3

	append_log(
		"[color=#e2bd63][b]崩壊[/b]　%sは次の一巡、行動不能。[/color]"
		% str(enemy_state["name"])
	)

	play_one_shot(break_player)
	duck_battle_bgm(-21.0, 0.40)
	play_break_banner()
	play_enemy_break_reaction()
	shake_amount = 16.0
	flash_alpha = 0.34


func damage_player_character(
	char_name: String,
	damage: int,
	stance_damage: int = 0
) -> void:
	var state: Dictionary = party_state[char_name]

	state["cur_hp"] = maxi(
		0,
		int(state["cur_hp"]) - damage
	)
	party_state[char_name] = state

	if int(state["cur_hp"]) > 0 and stance_damage > 0:
		apply_player_stance_damage(char_name, stance_damage, "敵の攻撃")


func apply_player_stance_damage(char_name: String, amount: int, reason: String = "") -> void:
	if not party_state.has(char_name):
		return

	var state: Dictionary = party_state[char_name]
	if int(state["cur_hp"]) <= 0 or int(state.get("broken_rounds", 0)) > 0:
		return

	var final_amount := float(amount)
	if bool(state.get("guarding", false)):
		final_amount *= 0.45
	if has_status(state, "ward"):
		final_amount *= 0.80
	if int(state.get("break_guard_rounds", 0)) > 0:
		final_amount *= 0.55

	var dealt := maxi(1, int(round(final_amount)))
	state["cur_stance"] = maxi(0, int(state["cur_stance"]) - dealt)
	party_state[char_name] = state

	if int(state["cur_stance"]) <= 0:
		trigger_player_break(char_name, reason)


func recover_player_stance(char_name: String, amount: int) -> void:
	if not party_state.has(char_name):
		return
	var state: Dictionary = party_state[char_name]
	if int(state["cur_hp"]) <= 0 or int(state.get("broken_rounds", 0)) > 0:
		return
	state["cur_stance"] = mini(
		int(state["stance_max"]),
		int(state["cur_stance"]) + amount
	)
	party_state[char_name] = state


func trigger_player_break(char_name: String, reason: String = "") -> void:
	var state: Dictionary = party_state[char_name]
	if int(state.get("broken_rounds", 0)) > 0:
		return

	# 発生したラウンドでは減算せず、次の1ラウンドを丸ごと行動不能にする。
	state["broken_rounds"] = 1
	state["broken_on_round"] = round_number
	state["cur_stance"] = 0
	state["guarding"] = false
	state["counter"] = false
	party_state[char_name] = state

	var suffix := "" if reason == "" else "（" + reason + "）"
	append_log("[color=#d36f76][b]%s 崩壊[/b]　次の一巡、行動不能%s[/color]" % [char_name, suffix])
	play_player_break_banner(char_name)
	play_one_shot(break_player, 1.10)
	shake_amount = maxf(shake_amount, 10.0)


func heal_player(
	char_name: String,
	amount: int
) -> void:
	var state: Dictionary = party_state[char_name]

	state["cur_hp"] = mini(
		int(state["hp"]),
		int(state["cur_hp"]) + amount
	)

	party_state[char_name] = state


func apply_player_defense_modifiers(
	char_name: String,
	damage: int
) -> int:
	var state: Dictionary = party_state[char_name]
	var result: float = float(damage)

	if bool(state["guarding"]):
		var guard_rate := 0.32 if moon_index == 6 else 0.50
		result *= guard_rate

	if has_status(state, "ward"):
		result *= 0.80

	return maxi(1, int(round(result)))


# ============================================================
# STATS / STATUS
# ============================================================

func get_player_stat(
	char_name: String,
	stat_key: String
) -> int:
	var state: Dictionary = party_state[char_name]
	var value: float = float(state[stat_key])

	if stat_key == "atk" or stat_key == "mag":
		if has_status(state, "atk_down"):
			value *= 0.75
		if has_status(state, "burn"):
			value *= 0.90
		if has_status(state, "blessing"):
			value *= 1.20
		if has_status(state, "rage"):
			value *= 1.25

	elif stat_key == "def" or stat_key == "res":
		if has_status(state, "def_down"):
			value *= 0.75
		if has_status(state, "rage"):
			value *= 0.90
	elif stat_key == "spd" and moon_index == 1:
		value *= 1.15

	return maxi(1, int(round(value)))


func get_enemy_stat(stat_key: String) -> int:
	var value: float = float(enemy_state[stat_key])

	if stat_key == "atk" or stat_key == "mag":
		if has_status(enemy_state, "atk_down"):
			value *= 0.75
		if has_status(enemy_state, "burn"):
			value *= 0.90
		if has_status(enemy_state, "rage"):
			value *= 1.20
	elif stat_key == "def" or stat_key == "res":
		if has_status(enemy_state, "def_down"):
			value *= 0.75

	if is_enemy_second_phase():
		match str(enemy_state.get("id", "")):
			"moon_oni":
				if stat_key == "atk": value *= 1.14
			"fire_spider":
				if stat_key == "mag" or stat_key == "spd": value *= 1.12
			"bone_monk":
				if stat_key == "mag": value *= 1.12
				if stat_key == "res": value *= 1.10
			"dark_tengu":
				if stat_key == "spd": value *= 1.22
				if stat_key == "atk" or stat_key == "mag": value *= 1.08
			"eclipse_lady":
				if stat_key == "atk" or stat_key == "mag": value *= 1.14
				if stat_key == "spd": value *= 1.12

	return maxi(1, int(round(value)))

func add_player_status(
	char_name: String,
	status_key: String,
	turns: int
) -> void:
	var state: Dictionary = party_state[char_name]
	var statuses: Dictionary = state["statuses"]

	var current: int = 0
	if statuses.has(status_key):
		current = int(statuses[status_key])

	statuses[status_key] = maxi(current, turns)
	state["statuses"] = statuses
	party_state[char_name] = state

	if screen_mode == "battle":
		var center_point := get_party_effect_center(
			char_name,
			get_viewport_rect().size * Vector2(0.70, 0.80)
		)
		play_status_pixel_feedback(status_key, center_point, false)


func add_enemy_status(
	status_key: String,
	turns: int
) -> void:
	if turns <= 0:
		return

	var statuses: Dictionary = enemy_state["statuses"]

	var current: int = 0
	if statuses.has(status_key):
		current = int(statuses[status_key])

	statuses[status_key] = maxi(current, turns)
	enemy_state["statuses"] = statuses

	if screen_mode == "battle":
		var center_point := Vector2(
			get_viewport_rect().size.x * 0.43,
			get_viewport_rect().size.y * 0.43
		)
		play_status_pixel_feedback(status_key, center_point, true)


func adjusted_enemy_status_turns(base_turns: int) -> int:
	var turns := base_turns - int(enemy_state["status_resist"])

	# 十六夜では呪い・炎・毒の余波が長く残る。
	if moon_index == 5:
		turns += 1

	return maxi(1, turns)


func has_status(
	state: Dictionary,
	status_key: String
) -> bool:
	if not state.has("statuses"):
		return false

	var statuses: Dictionary = state["statuses"]
	return statuses.has(status_key) and int(statuses[status_key]) > 0


func clear_negative_statuses(char_name: String) -> void:
	var state: Dictionary = party_state[char_name]
	var statuses: Dictionary = state["statuses"]

	for status_key in NEGATIVE_STATUSES:
		statuses.erase(status_key)

	state["statuses"] = statuses
	party_state[char_name] = state


func count_enemy_negative_statuses() -> int:
	var count: int = 0

	for status_key in NEGATIVE_STATUSES:
		if has_status(enemy_state, status_key):
			count += 1

	return count


func extend_enemy_negative_statuses(amount: int) -> int:
	var statuses: Dictionary = enemy_state.get("statuses", {})
	var extended := 0
	for status_key in NEGATIVE_STATUSES:
		if statuses.has(status_key) and int(statuses[status_key]) > 0:
			statuses[status_key] = int(statuses[status_key]) + amount
			extended += 1
	enemy_state["statuses"] = statuses
	return extended


func status_text(state: Dictionary) -> String:
	if not state.has("statuses"):
		return "状態：正常"

	var statuses: Dictionary = state["statuses"]
	var parts: Array[String] = []

	for status_key in statuses.keys():
		var turns: int = int(statuses[status_key])
		if turns <= 0:
			continue

		var display_name: String = str(
			STATUS_NAMES.get(status_key, status_key)
		)

		parts.append("%s %d巡" % [display_name, turns])

	if parts.is_empty():
		return "状態：正常"

	return "状態：" + " / ".join(parts)


func decrement_statuses(state: Dictionary) -> Dictionary:
	var statuses: Dictionary = state["statuses"]
	var keys: Array = statuses.keys()

	for status_key_variant in keys:
		var status_key: String = str(status_key_variant)
		var turns: int = int(statuses[status_key]) - 1

		if turns <= 0:
			statuses.erase(status_key)
		else:
			statuses[status_key] = turns

	state["statuses"] = statuses
	return state


# ============================================================
# END OF ROUND
# ============================================================

func apply_end_of_round_effects() -> void:
	for char_name in party:
		var state: Dictionary = party_state[char_name]

		if int(state["cur_hp"]) <= 0:
			continue

		if has_status(state, "poison"):
			var poison_damage: int = maxi(
				1,
				int(round(float(state["hp"]) * (0.09 if moon_index == 5 else 0.06)))
			)
			state["cur_hp"] = maxi(
				0,
				int(state["cur_hp"]) - poison_damage
			)
			append_log(
				"%sは[color=#9e7ab1]毒[/color]で%d ダメージ"
				% [char_name, poison_damage]
			)

		if int(state["cur_hp"]) > 0 and has_status(state, "burn"):
			var burn_damage: int = maxi(
				1,
				int(round(float(state["hp"]) * (0.06 if moon_index == 5 else 0.04)))
			)
			state["cur_hp"] = maxi(
				0,
				int(state["cur_hp"]) - burn_damage
			)
			append_log(
				"%sは[color=#d9825d]火傷[/color]で%d ダメージ"
				% [char_name, burn_damage]
			)

		if int(state["cur_hp"]) > 0:
			var regen_amount: int = get_mana_regen_amount(state)
			state["cur_mana"] = mini(
				int(state["mana"]),
				int(state["cur_mana"]) + regen_amount
			)

		state = decrement_statuses(state)
		state["guarding"] = false
		state["counter"] = false

		if int(state.get("break_guard_rounds", 0)) > 0:
			state["break_guard_rounds"] = int(state["break_guard_rounds"]) - 1

		if (
			int(state.get("broken_rounds", 0)) > 0
			and int(state.get("broken_on_round", -1)) < round_number
		):
			state["broken_rounds"] = int(state["broken_rounds"]) - 1
			if int(state["broken_rounds"]) <= 0 and int(state["cur_hp"]) > 0:
				state["cur_stance"] = maxi(1, int(round(float(state["stance_max"]) * 0.60)))
				state["break_guard_rounds"] = 1
				state["broken_on_round"] = -1
				append_log("[color=#9aa9bf]%sが崩壊から再起。構え60%%で復帰。[/color]" % char_name)

		party_state[char_name] = state

	# Enemy DOT
	if has_status(enemy_state, "poison"):
		var enemy_poison: int = maxi(
			1,
			int(round(float(enemy_state["hp"]) * (0.0675 if moon_index == 5 else 0.045)))
		)
		enemy_state["cur_hp"] = maxi(
			0,
			int(enemy_state["cur_hp"]) - enemy_poison
		)
		append_log(
			"%sは[color=#9e7ab1]毒[/color]で%d ダメージ"
			% [str(enemy_state["name"]), enemy_poison]
		)

	if int(enemy_state["cur_hp"]) > 0 and has_status(enemy_state, "burn"):
		var enemy_burn: int = maxi(
			1,
			int(round(float(enemy_state["hp"]) * (0.0525 if moon_index == 5 else 0.035)))
		)
		enemy_state["cur_hp"] = maxi(
			0,
			int(enemy_state["cur_hp"]) - enemy_burn
		)
		append_log(
			"%sは[color=#d9825d]火傷[/color]で%d ダメージ"
			% [str(enemy_state["name"]), enemy_burn]
		)

	check_enemy_second_phase()
	apply_enemy_identity_end_round()
	enemy_state = decrement_statuses(enemy_state)
	decay_enemy_note_memory()

	if int(enemy_state.get("break_guard_rounds", 0)) > 0:
		enemy_state["break_guard_rounds"] = int(enemy_state["break_guard_rounds"]) - 1

	if (
		int(enemy_state["broken_rounds"]) > 0
		and int(enemy_state.get("broken_on_round", -1)) < round_number
	):
		enemy_state["broken_rounds"] = int(enemy_state["broken_rounds"]) - 1
		if int(enemy_state["broken_rounds"]) <= 0 and int(enemy_state["cur_hp"]) > 0:
			enemy_state["cur_break"] = int(enemy_state["break_max"])
			enemy_state["break_guard_rounds"] = 1
			enemy_state["broken_on_round"] = -1
			append_log("[color=#a89a7e]%sが立て直した。一巡の崩し耐性。[/color]" % str(enemy_state["name"]))

	if combo_damage_rounds > 0:
		combo_damage_rounds -= 1
	if combo_break_rounds > 0:
		combo_break_rounds -= 1

	await get_tree().create_timer(0.22).timeout


func get_mana_regen_amount(state: Dictionary) -> int:
	var amount: int = int(state["regen"])

	if moon_index == 0:
		amount += 2
	elif moon_index == 4:
		amount -= 1

	return maxi(0, amount)


func advance_moon(amount: int) -> void:
	# v9.3:
	# 月相は行動の途中では変えない。
	# 通常の「月+1」は、その巡終了時の自然進行1つに含める。
	# 月+2以上の技だけが「次巡を余分に進める」効果になる。
	if amount <= 0:
		return

	var bonus := maxi(0, amount - 1)
	round_moon_bonus = maxi(round_moon_bonus, bonus)
	refresh_moon_forecast()


func queue_enemy_moon_shift(amount: int) -> void:
	if amount <= 0:
		return
	round_moon_bonus = mini(5, round_moon_bonus + amount)
	refresh_moon_forecast()


func get_next_round_moon_index(extra_bonus: int = 0) -> int:
	var total_steps := 1 + maxi(0, round_moon_bonus + extra_bonus)
	return (moon_index + total_steps) % PHASES.size()


func commit_next_round_moon() -> void:
	var total_steps := 1 + maxi(0, round_moon_bonus)
	var old_index := moon_index

	moon_index = (moon_index + total_steps) % PHASES.size()
	round_moon_bonus = 0

	if moon_index != old_index:
		apply_moon_arrival_effect(moon_index)
		play_one_shot(time_player)
		moon_pulse = 1.0
		play_moon_shift_flash()



func play_score_progress_feedback(filled_count: int) -> void:
	if filled_count <= 0 or filled_count > beat_cells.size():
		return
	var cell: Dictionary = beat_cells[filled_count - 1]
	var panel: PanelContainer = cell["panel"] as PanelContainer
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.06, 1.06), 0.07)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.13)

	if filled_count >= 2 and filled_count - 2 < beat_connectors.size():
		var connector := beat_connectors[filled_count - 2]
		connector.color = Color("#c7a75d")
		connector.modulate.a = 0.0
		var link_tween := create_tween()
		link_tween.tween_property(connector, "modulate:a", 1.0, 0.16)

	if filled_count >= 6 and score_panel_ref != null and is_instance_valid(score_panel_ref):
		var center := score_panel_ref.global_position + score_panel_ref.size * 0.5
		spawn_shader_wave(center, Color("#c9ad69"), 0.18 + float(filled_count - 6) * 0.08)
		spawn_gpu_sparks(center, Color("#d2bc80"), 12 + filled_count * 2, 120.0 + float(filled_count) * 12.0)


func refresh_score_tension_style(display_count: int) -> void:
	if score_panel_ref == null or not is_instance_valid(score_panel_ref):
		return
	var style: StyleBoxFlat = score_panel_ref.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	if display_count >= 7:
		style.bg_color = Color("#17130def")
		style.border_color = Color("#b8944f")
		style.set_border_width_all(2)
	elif display_count >= 6:
		style.bg_color = Color("#10141aef")
		style.border_color = Color("#74694c")
		style.set_border_width_all(1)
	else:
		style.bg_color = Color("#0c0e13ef")
		style.border_color = Color("#323039")
		style.set_border_width_all(1)
	score_panel_ref.add_theme_stylebox_override("panel", style)


func advance_beat(
	char_name: String,
	mark: String,
	action_name: String = ""
) -> void:
	measure_notes.append({
		"actor": char_name,
		"mark": mark,
		"instrument": str(CHARACTERS[char_name]["instrument"]),
		"phase": moon_index,
		"action_name": action_name
	})

	beat += 1
	play_score_progress_feedback(beat)

	if beat >= SCORE_LENGTH:
		resolve_measure()
		beat = 0
		measure += 1
		measure_notes.clear()

func resolve_measure() -> void:
	if measure_notes.is_empty():
		return

	var completed_notes: Array[Dictionary] = []
	for note_variant in measure_notes:
		var completed_note: Dictionary = note_variant
		completed_notes.append(completed_note.duplicate(true))

	var combo := detect_score_combo(completed_notes)
	var combo_name := str(combo["name"])
	var is_moon_combo := bool(combo["moon_combo"])
	last_combo_name = combo_name

	apply_score_combo_effect(combo_name, is_moon_combo)

	var performer_set: Dictionary = {}
	for note_variant in completed_notes:
		var note: Dictionary = note_variant
		performer_set[str(note["actor"])] = true

	if performer_set.size() >= 3:
		for char_name in party:
			var state: Dictionary = party_state[char_name]
			if int(state["cur_hp"]) <= 0:
				continue
			state["cur_mana"] = mini(int(state["mana"]), int(state["cur_mana"]) + 1)
			party_state[char_name] = state

	var unlocked_finishers := unlock_finishers_from_score(combo_name)
	var finisher_unlock_text := get_finisher_unlock_text(unlocked_finishers)

	last_measure_text = "第%d奏譜「%s」" % [measure, combo_name]
	if performer_set.size() >= 3:
		last_measure_text += "　合奏：奏力 +1"

	if not finisher_unlock_text.is_empty():
		last_measure_text += "　" + finisher_unlock_text
		append_log("[color=#f0d486][b]%s[/b][/color]" % finisher_unlock_text)

	append_log("[color=#9fb5d2][b]%s[/b][/color]" % last_measure_text)
	score_banner_lock_until = Time.get_ticks_msec() + (2050 if is_moon_combo else 1650)
	show_score_completion_banner(
		combo_name,
		is_moon_combo,
		completed_notes,
		finisher_unlock_text
	)

func detect_score_combo(notes: Array) -> Dictionary:
	var marks: Array[String] = []
	var performers: Dictionary = {}
	var unique_pitches: Dictionary = {}
	var resonance_count := 0
	var final_phase := moon_index

	for note_variant in notes:
		var note: Dictionary = note_variant
		var mark := str(note.get("mark", ""))
		var phase := int(note.get("phase", moon_index))
		marks.append(mark)
		performers[str(note.get("actor", ""))] = true
		final_phase = phase
		if get_note_value(mark) >= 0:
			unique_pitches[mark] = true
			if is_note_resonant(mark, phase):
				resonance_count += 1

	var base_name := detect_melody_shape(marks, performers.size(), unique_pitches.size())
	var moon_combo := resonance_count >= 4 and base_name != "余韻"

	if moon_combo:
		return {
			"name": get_lunar_combo_name(final_phase, base_name),
			"moon_combo": true,
			"base": base_name,
			"resonance": resonance_count
		}

	return {
		"name": base_name,
		"moon_combo": false,
		"base": base_name,
		"resonance": resonance_count
	}


func detect_melody_shape(
	marks: Array[String],
	performer_count: int,
	unique_pitch_count: int
) -> String:
	var pitches: Array[int] = []
	var pitch_marks: Array[String] = []
	for mark in marks:
		var value := get_note_value(mark)
		if value >= 0:
			pitches.append(value)
			pitch_marks.append(mark)

	var rest_count := marks.count("休")
	if rest_count >= 2 and pitches.size() >= 3:
		return "静奏"

	var return_patterns := 0
	for i in range(maxi(0, pitch_marks.size() - 2)):
		if pitch_marks[i] == pitch_marks[i + 2] and pitch_marks[i] != pitch_marks[i + 1]:
			return_patterns += 1
	if return_patterns >= 2:
		return "返奏"

	var max_same := 0
	for pitch in NOTE_ORDER:
		max_same = maxi(max_same, pitch_marks.count(pitch))
	if max_same >= 4:
		return "濁奏"
	if max_same >= 3:
		return "重奏"

	# 八拍では完全な単調増減ではなく、旋律全体の「向き」を見る。
	var trend := 0
	for i in range(maxi(0, pitches.size() - 1)):
		if pitches[i + 1] > pitches[i]:
			trend += 1
		elif pitches[i + 1] < pitches[i]:
			trend -= 1

	if pitches.size() >= 5 and trend >= 3:
		return "昇奏"
	if pitches.size() >= 5 and trend <= -3:
		return "降奏"

	if unique_pitch_count >= 6:
		return "彩奏"
	if performer_count >= 3 and unique_pitch_count >= 4:
		return "合奏"
	return "余韻"

func get_lunar_combo_name(phase_index: int, _base_name: String) -> String:
	match phase_index:
		0: return "朔月・静奏"
		1: return "三日月・疾奏"
		2: return "上弦・破奏"
		3: return "十三夜・調奏"
		4: return "望月・烈奏"
		5: return "十六夜・妖奏"
		6: return "下弦・守奏"
		7: return "晦・葬奏"
		_: return "月奏"


func apply_score_combo_effect(combo_name: String, is_moon_combo: bool) -> void:
	match combo_name:
		"昇奏":
			combo_damage_rounds = maxi(combo_damage_rounds, 2)
			combo_break_rounds = maxi(combo_break_rounds, 2)
			append_log("昇奏：次の巡まで攻撃・崩しを強化")
		"降奏":
			restore_party_stance_and_hp(16, 0.05)
		"重奏":
			combo_damage_rounds = maxi(combo_damage_rounds, 2)
			append_log("重奏：同じ響きを増幅。ただし連打の残響負荷には注意")
		"濁奏":
			combo_damage_rounds = maxi(combo_damage_rounds, 2)
			for char_name in party:
				if int(party_state[char_name]["cur_hp"]) > 0:
					apply_player_stance_damage(char_name, 8, "濁奏の反動")
			append_log("[color=#bd84c8]濁奏：火力を得る代わり、味方全体の構えを削った。[/color]")
		"返奏":
			for char_name in party:
				if int(party_state[char_name]["cur_hp"]) > 0:
					add_player_status(char_name, "ward", 1)
			restore_party_stance_and_hp(8, 0.0)
		"静奏":
			restore_party_stance_and_hp(20, 0.04)
		"彩奏":
			restore_party_resources(2, 12)
		"合奏":
			restore_party_resources(1, 8)
		"朔月・静奏":
			restore_party_resources(2, 16)
		"三日月・疾奏":
			restore_party_resources(1, 10)
			combo_damage_rounds = maxi(combo_damage_rounds, 2)
		"上弦・破奏":
			combo_break_rounds = maxi(combo_break_rounds, 3)
			if int(enemy_state.get("broken_rounds", 0)) <= 0:
				enemy_state["cur_break"] = maxi(
					0,
					int(enemy_state["cur_break"]) - int(round(float(enemy_state["break_max"]) * 0.14))
				)
		"十三夜・調奏":
			restore_party_resources(2, 10)
			combo_damage_rounds = maxi(combo_damage_rounds, 2)
		"望月・烈奏":
			combo_damage_rounds = maxi(combo_damage_rounds, 3)
			combo_break_rounds = maxi(combo_break_rounds, 2)
		"十六夜・妖奏":
			trigger_enemy_dot_echo(0.85)
		"下弦・守奏":
			restore_party_stance_and_hp(26, 0.08)
		"晦・葬奏":
			var debuffs := count_enemy_negative_statuses()
			if debuffs > 0:
				var extra := maxi(1, int(round(float(enemy_state["hp"]) * 0.020 * float(debuffs))))
				enemy_state["cur_hp"] = maxi(0, int(enemy_state["cur_hp"]) - extra)
				spawn_enemy_damage_popup(extra, false)

	if is_moon_combo:
		append_log("[color=#e2c97e]月と旋律が共鳴――月奏成立。月奏印が灯る。[/color]")


func restore_party_resources(mana_amount: int, stance_amount: int) -> void:
	for char_name in party:
		var state: Dictionary = party_state[char_name]
		if int(state["cur_hp"]) <= 0:
			continue
		state["cur_mana"] = mini(int(state["mana"]), int(state["cur_mana"]) + mana_amount)
		party_state[char_name] = state
		recover_player_stance(char_name, stance_amount)


func restore_party_stance_and_hp(stance_amount: int, hp_ratio: float) -> void:
	for char_name in party:
		var state: Dictionary = party_state[char_name]
		if int(state["cur_hp"]) <= 0:
			continue
		var heal := maxi(1, int(round(float(state["hp"]) * hp_ratio)))
		state["cur_hp"] = mini(int(state["hp"]), int(state["cur_hp"]) + heal)
		party_state[char_name] = state
		recover_player_stance(char_name, stance_amount)


func trigger_enemy_dot_echo(multiplier: float) -> void:
	var total := 0
	if has_status(enemy_state, "poison"):
		total += maxi(1, int(round(float(enemy_state["hp"]) * 0.045 * multiplier)))
	if has_status(enemy_state, "burn"):
		total += maxi(1, int(round(float(enemy_state["hp"]) * 0.035 * multiplier)))
	if total > 0:
		enemy_state["cur_hp"] = maxi(0, int(enemy_state["cur_hp"]) - total)
		spawn_enemy_damage_popup(total, false)
		append_log("妖奏の余韻で状態異常が追加発火：%d ダメージ" % total)


func get_moon_effect_text() -> String:
	match moon_index:
		0:
			return "新月：自然奏力回復 +2 / 到達時、生存者の奏力 +1"
		1:
			return "三日月：速さ +15% / 通常攻撃の奏力回復 +1"
		2:
			return "上弦：崩し +35% / この月で崩壊させると硬直延長"
		3:
			return "十三夜：与ダメージ +12% / 満月への仕込み"
		4:
			return "満月：味方与ダメ +25% / 敵火力 +25% / 崩壊追撃強化"
		5:
			return "十六夜：毒・火傷 +50% / 敵への状態異常 +1巡"
		6:
			return "下弦：回復 +30% / 防御時の被害を32%まで軽減"
		7:
			return "晦：弱体中の敵への与ダメ +15% / 次の新月へ"
		_:
			return "月光：特殊補正なし"


# ============================================================
# V5 SCORE / ULTIMATE / TELEGRAPH HELPERS
# ============================================================

func count_commandable_party() -> int:
	var count := 0
	for char_name in party:
		var state: Dictionary = party_state[char_name]
		if int(state["cur_hp"]) > 0 and int(state.get("broken_rounds", 0)) <= 0:
			count += 1
	return count


func get_effective_skill_cost(char_name: String, skill_data: Dictionary) -> int:
	var state: Dictionary = party_state[char_name]
	var base_cost := int(skill_data["cost"])
	if str(state.get("last_skill_id", "")) == str(skill_data["id"]):
		base_cost += mini(2, maxi(1, int(state.get("repeat_count", 0))))
	return base_cost


func get_skill_stance_cost(char_name: String, skill_data: Dictionary) -> int:
	var state: Dictionary = party_state[char_name]
	var strain := 4 + int(skill_data["cost"]) * 2
	if str(state.get("last_skill_id", "")) == str(skill_data["id"]):
		strain += 8 + mini(8, int(state.get("repeat_count", 0)) * 2)
	return strain


func get_skill_note_type(skill_id: String) -> String:
	match skill_id:
		"samurai_moon_slash": return "ミ"
		"samurai_iai": return "ソ"
		"samurai_red_mist": return "ラ"
		"samurai_swallow_break": return "レ"
		"samurai_aftermoon": return "ファ"
		"sennin_thunder": return "ソ"
		"sennin_moon_turn": return "シ"
		"sennin_spring": return "ファ"
		"sennin_wind_read": return "ド"
		"sennin_moon_hold": return "ラ"
		"kasa_pierce": return "レ"
		"kasa_counter": return "ファ"
		"kasa_ward": return "ド"
		"kasa_rain_armor": return "ド"
		"kasa_thunder_guard": return "ミ"
		"miko_heal": return "ソ"
		"miko_cleanse": return "ファ"
		"miko_bless": return "シ"
		"miko_bell_guard": return "レ"
		"miko_divine_descent": return "ド"
		"chochin_foxfire": return "ラ"
		"chochin_lantern_drop": return "ミ"
		"chochin_dim": return "レ"
		"chochin_ember_step": return "ソ"
		"chochin_burst": return "シ"
		"jusoshi_poison": return "ラ"
		"jusoshi_bind": return "レ"
		"jusoshi_grudge": return "シ"
		"jusoshi_extend": return "ファ"
		"jusoshi_abyss_mark": return "ミ"
		"kunoichi_shadow_bind": return "レ"
		"kunoichi_poison_star": return "ラ"
		"kunoichi_mist_step": return "ド"
		"kunoichi_ninja_return": return "ファ"
		"kunoichi_scatter_star": return "ソ"
		"shuten_oni_smash": return "ミ"
		"shuten_sake_flame": return "ラ"
		"shuten_drink_dry": return "ファ"
		"shuten_drunk_barrage": return "ソ"
		"shuten_hyakki_feast": return "ド"
		"kagurashi_rhythm_dance": return "ド"
		"kagurashi_double_beat": return "ミ"
		"kagurashi_repose": return "ファ"
		"kagurashi_moon_call": return "シ"
		"kagurashi_wild_kagura": return "ソ"
		"nekomata_cat_fire": return "ラ"
		"nekomata_twin_tail": return "レ"
		"nekomata_feint": return "ド"
		"nekomata_soul_lick": return "ファ"
		"nekomata_bakeneko_dance": return "シ"
		_:
			return "ド"


func get_basic_attack_note(char_name: String) -> String:
	match char_name:
		"侍": return "ド"
		"仙人": return "ミ"
		"傘使い": return "レ"
		"巫女": return "ファ"
		"提灯使い": return "ソ"
		"呪詛師": return "ラ"
		"くノ一": return "レ"
		"酒呑童子": return "ミ"
		"神楽師": return "シ"
		"猫又": return "ソ"
		_: return "ド"


func get_action_note_type(action_data: Dictionary) -> String:
	var action_type := str(action_data.get("type", ""))
	if action_type == "attack":
		return get_basic_attack_note(str(action_data.get("actor", ""))) if action_data.has("actor") else "ド"
	if action_type == "guard":
		return "休"
	if action_type == "ultimate":
		return "月"
	if action_type == "skill":
		var skill_data: Dictionary = action_data.get("skill", {})
		return get_skill_note_type(str(skill_data.get("id", "")))
	return "・"


func get_action_note_for_actor(char_name: String, action_data: Dictionary) -> String:
	var action_type := str(action_data.get("type", ""))
	if action_type == "attack":
		return get_basic_attack_note(char_name)
	return get_action_note_type(action_data)


func get_action_score_name(action_data: Dictionary) -> String:
	var action_type := str(action_data.get("type", ""))
	if action_type == "attack":
		return "攻撃"
	if action_type == "guard":
		return "防御"
	if action_type == "ultimate":
		return "必殺技"
	if action_type == "skill":
		var skill_data: Dictionary = action_data.get("skill", {})
		return str(skill_data.get("name", "特技"))
	return ""


func get_note_color(note_type: String, planned: bool = false) -> Color:
	var color := Color("#b6b8bf")
	match note_type:
		"ド": color = Color("#c9d2df")
		"レ": color = Color("#97bfd0")
		"ミ": color = Color("#d8c16f")
		"ファ": color = Color("#9fc7a9")
		"ソ": color = Color("#e0a96b")
		"ラ": color = Color("#bd84c8")
		"シ": color = Color("#d6a1b2")
		"休": color = Color("#7f94aa")
		"月": color = COL_GOLD_BRIGHT
	if planned:
		color.a = 0.54
	return color


func get_phase_resonant_notes(phase_index: int) -> Array[String]:
	match phase_index:
		0: return ["ド", "シ"]
		1: return ["ド", "レ"]
		2: return ["レ", "ミ"]
		3: return ["ミ", "シ"]
		4: return ["ミ", "ソ"]
		5: return ["ラ", "ソ"]
		6: return ["ファ", "ソ"]
		7: return ["ラ", "シ"]
		_: return ["ド", "レ"]


func is_note_resonant(note_type: String, phase_index: int) -> bool:
	return get_phase_resonant_notes(phase_index).has(note_type)


func get_note_value(note_type: String) -> int:
	if NOTE_VALUE.has(note_type):
		return int(NOTE_VALUE[note_type])
	return -1


func get_note_display(note_type: String) -> String:
	# 内部の音程計算はそのまま使い、画面では和風の「音紋」に置き換える。
	match note_type:
		"ド": return "〔壱〕"
		"レ": return "〔弐〕"
		"ミ": return "〔参〕"
		"ファ": return "〔肆〕"
		"ソ": return "〔伍〕"
		"ラ": return "〔陸〕"
		"シ": return "〔漆〕"
		"休": return "〔休〕"
		"月": return "〔月〕"
		_: return "〔・〕"


func get_note_plain_name(note_type: String) -> String:
	match note_type:
		"ド": return "壱ノ音"
		"レ": return "弐ノ音"
		"ミ": return "参ノ音"
		"ファ": return "肆ノ音"
		"ソ": return "伍ノ音"
		"ラ": return "陸ノ音"
		"シ": return "漆ノ音"
		"休": return "休符"
		"月": return "月音"
		_: return "無音"


func get_note_choice_hint(note_type: String) -> String:
	var pieces: Array[String] = []
	if is_note_resonant(note_type, moon_index):
		pieces.append("現在月と共鳴")
	var display_notes := get_score_forecast_notes()
	var current_marks: Array[String] = []
	for note_variant in display_notes:
		var note: Dictionary = note_variant
		if not bool(note.get("planned", false)):
			current_marks.append(str(note.get("mark", "")))

	if not current_marks.is_empty():
		var previous := current_marks[current_marks.size() - 1]
		var previous_value := get_note_value(previous)
		var current_value := get_note_value(note_type)
		if previous_value >= 0 and current_value >= 0:
			if current_value > previous_value:
				pieces.append("昇奏候補")
			elif current_value < previous_value:
				pieces.append("降奏候補")
			else:
				pieces.append("重奏候補")
		if current_marks.size() >= 2 and current_marks[current_marks.size() - 2] == note_type:
			pieces.append("返奏候補")

	if pieces.is_empty():
		return "旋律を組み立てる"
	return " / ".join(pieces)


func get_enemy_note_adaptation(note_type: String) -> float:
	var memory: Dictionary = enemy_state.get("note_memory", {})
	var count := int(memory.get(note_type, 0))
	if count >= 3:
		return 0.72
	if count >= 2:
		return 0.84
	return 1.0


func record_enemy_note(note_type: String) -> void:
	if not NOTE_VALUE.has(note_type):
		return
	var memory: Dictionary = enemy_state.get("note_memory", {})
	memory[note_type] = mini(4, int(memory.get(note_type, 0)) + 1)
	enemy_state["note_memory"] = memory


func decay_enemy_note_memory() -> void:
	var memory: Dictionary = enemy_state.get("note_memory", {})
	var keys := memory.keys()
	for key_variant in keys:
		var key := str(key_variant)
		var value := int(memory.get(key, 0)) - 1
		if value <= 0:
			memory.erase(key)
		else:
			memory[key] = value
	enemy_state["note_memory"] = memory


func get_enemy_adaptation_text() -> String:
	var memory: Dictionary = enemy_state.get("note_memory", {})
	var pieces: Array[String] = []
	for note_type in NOTE_ORDER:
		var count := int(memory.get(note_type, 0))
		if count >= 2:
			pieces.append("%s見切り×%d" % [get_note_display(note_type), count])
	if pieces.is_empty():
		return ""
	return "　見切り：" + " / ".join(pieces)


func get_ultimate_requirement(char_name: String) -> String:
	match char_name:
		"侍": return "上弦・破奏"
		"仙人": return "朔月・静奏"
		"傘使い": return "下弦・守奏"
		"巫女": return "十三夜・調奏"
		"提灯使い": return "望月・烈奏"
		"呪詛師": return "十六夜・妖奏"
		"くノ一": return "三日月・疾奏"
		"酒呑童子": return "濁奏"
		"神楽師": return "合奏"
		"猫又": return "晦・葬奏"
		_: return ""


func is_ultimate_ready(char_name: String) -> bool:
	return bool(ultimate_ready.get(char_name, false))


func unlock_finishers_from_score(score_name: String) -> Array[String]:
	var unlocked: Array[String] = []

	for char_name in party:
		if is_ultimate_ready(char_name):
			continue
		if get_ultimate_requirement(char_name) != score_name:
			continue

		ultimate_ready[char_name] = true
		unlocked.append(char_name)

	return unlocked


func get_party_finisher_status_text() -> String:
	var parts: Array[String] = []
	for char_name in party:
		if is_ultimate_ready(char_name):
			parts.append("%s◆" % char_name)
		else:
			parts.append("%s◇" % char_name)
	return "必殺　" + "　".join(parts)


func get_finisher_unlock_text(unlocked_names: Array[String]) -> String:
	if unlocked_names.is_empty():
		return ""

	var pieces: Array[String] = []
	for char_name in unlocked_names:
		pieces.append("%s「%s」" % [char_name, get_ultimate_name(char_name)])
	return "必殺解放　" + " / ".join(pieces)


func get_ultimate_tactical_multiplier(char_name: String) -> float:
	var multiplier := 1.0
	if int(enemy_state.get("broken_rounds", 0)) > 0:
		multiplier += 0.25
	if char_name == "侍" and (moon_index == 3 or moon_index == 4):
		multiplier += 0.25
	elif char_name == "仙人" and (moon_index == 0 or moon_index == 7):
		multiplier += 0.20
	elif char_name == "傘使い" and (moon_index == 2 or moon_index == 6):
		multiplier += 0.20
	elif char_name == "巫女" and moon_index == 6:
		multiplier += 0.20
	elif char_name == "提灯使い" and (moon_index == 4 or moon_index == 5):
		multiplier += 0.20
	elif char_name == "呪詛師" and (moon_index == 5 or moon_index == 7):
		multiplier += 0.20
	elif char_name == "くノ一" and (moon_index == 1 or moon_index == 2):
		multiplier += 0.20
	elif char_name == "酒呑童子" and (moon_index == 4 or moon_index == 5):
		multiplier += 0.25
	elif char_name == "神楽師" and (moon_index == 0 or moon_index == 3):
		multiplier += 0.20
	elif char_name == "猫又" and (moon_index == 5 or moon_index == 7):
		multiplier += 0.20
	return multiplier


func get_skill_target_focus(skill_id: String) -> String:
	if skill_id in [
		"sennin_moon_turn",
		"sennin_spring",
		"sennin_wind_read",
		"kasa_counter",
		"kasa_ward",
		"kasa_rain_armor",
		"miko_heal",
		"miko_cleanse",
		"miko_bless",
		"miko_bell_guard",
		"miko_divine_descent",
		"kunoichi_ninja_return",
		"shuten_drink_dry",
		"shuten_hyakki_feast",
		"kagurashi_rhythm_dance",
		"kagurashi_double_beat",
		"kagurashi_repose",
		"kagurashi_moon_call"
	]:
		return "party"
	return "enemy"


func play_command_sound(pitch: float = 1.0) -> void:
	if command_player == null or command_player.stream == null:
		return
	command_player.pitch_scale = pitch
	command_player.play()


func get_ultimate_name(char_name: String) -> String:
	match char_name:
		"侍": return "天月一閃"
		"仙人": return "九天月輪"
		"傘使い": return "八重時雨"
		"巫女": return "天照神楽"
		"提灯使い": return "百鬼灯明"
		"呪詛師": return "百怨月葬"
		"くノ一": return "月影千刃"
		"酒呑童子": return "鬼宴・月呑"
		"神楽師": return "八百万神楽"
		"猫又": return "双月猫又火"
		_: return "必殺技"


func perform_ultimate_action(char_name: String) -> void:
	if not is_ultimate_ready(char_name):
		append_log("%sの必殺技はまだ解放されていない。" % char_name)
		return

	# 一度使ったら、その戦闘では対応する奏譜をもう一度完成させるまで再封印。
	ultimate_ready[char_name] = false

	var ultimate_name := get_ultimate_name(char_name)
	var tactical_bonus := get_ultimate_tactical_multiplier(char_name)
	await show_lunar_ultimate_cut_in(char_name, ultimate_name)
	await play_lunar_ultimate_motion(char_name)

	# 必殺技だけは着弾前に一瞬止め、通常技との差をはっきり出す。
	var old_time_scale := Engine.time_scale
	Engine.time_scale = 0.16
	await get_tree().create_timer(0.07, true, false, true).timeout
	Engine.time_scale = old_time_scale

	advance_moon(2)
	advance_beat(char_name, "月", ultimate_name)

	match char_name:
		"侍":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 3.20)) * tactical_bonus))
			var break_damage := calculate_break_damage(int(party_state[char_name]["break"]), 2.10)
			deal_damage_to_enemy(damage, break_damage)
		"仙人":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 2.35)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 1.15))
			restore_party_resources(3, 14)
		"傘使い":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 1.90)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 3.60))
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) > 0:
					add_player_status(ally_name, "ward", 2)
		"巫女":
			for ally_name in party:
				var state: Dictionary = party_state[ally_name]
				if int(state["cur_hp"]) <= 0:
					continue
				var heal := maxi(1, int(round(float(state["hp"]) * 0.55)))
				heal_player(ally_name, heal)
				clear_negative_statuses(ally_name)
				recover_player_stance(ally_name, 28)
		"提灯使い":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), 2.55)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 1.30))
			add_enemy_status("burn", adjusted_enemy_status_turns(4))
			add_enemy_status("atk_down", adjusted_enemy_status_turns(3))
		"呪詛師":
			var weak_count := count_enemy_negative_statuses()
			var power := 2.50 + minf(0.90, float(weak_count) * 0.18)
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), power)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 1.10))
		"くノ一":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 2.75)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 1.75))
			if ctb_times.has(CTB_ENEMY_KEY): ctb_times[CTB_ENEMY_KEY] = float(ctb_times[CTB_ENEMY_KEY]) + 18.0
		"酒呑童子":
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "atk"), get_enemy_stat("def"), 3.05)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 3.10))
			heal_player(char_name, maxi(1, int(round(float(party_state[char_name]["hp"]) * 0.18))))
		"神楽師":
			for ally_name in party:
				if int(party_state[ally_name]["cur_hp"]) > 0:
					heal_player(ally_name, maxi(1, int(round(float(party_state[ally_name]["hp"]) * 0.25))))
					recover_player_stance(ally_name, 24)
					if ctb_times.has(ally_name): ctb_times[ally_name] = maxf(ctb_clock + 4.0, float(ctb_times[ally_name]) - 12.0)
		"猫又":
			var power := 2.85 + minf(0.60, float(count_enemy_negative_statuses()) * 0.15)
			var damage := int(round(float(calculate_damage(get_player_stat(char_name, "mag"), get_enemy_stat("res"), power)) * tactical_bonus))
			deal_damage_to_enemy(damage, calculate_break_damage(int(party_state[char_name]["break"]), 1.45))
			add_enemy_status("burn", adjusted_enemy_status_turns(4))

	apply_player_stance_damage(char_name, 28, "必殺技の反動")
	append_log("[color=#f0d486][b]%s「%s」[/b]　戦術倍率 ×%.2f[/color]" % [char_name, ultimate_name, tactical_bonus])
	await get_tree().create_timer(0.28).timeout


func play_lunar_ultimate_motion(char_name: String) -> void:
	var viewport_size := get_viewport_rect().size
	var enemy_center := Vector2(viewport_size.x * 0.42, viewport_size.y * 0.46)
	var party_center := Vector2(viewport_size.x * 0.72, viewport_size.y * 0.62)
	var tone := MOON_COLORS[moon_index]

	# 第一段：溜め
	spawn_shader_wave(enemy_center, tone, 0.46)
	spawn_moon_halo(enemy_center, tone, 5)
	await get_tree().create_timer(0.16).timeout

	match char_name:
		"侍":
			play_pixel_vfx("Slashes/Katana Draw", enemy_center, 9.0, 18.0)
			play_pixel_vfx("Slashes/Wide Cleave", enemy_center, 7.0, 20.0, Color("#fff0ce"))
			await get_tree().create_timer(0.12).timeout
			for i in range(7):
				spawn_streak(
					enemy_center + Vector2(-470, -240 + i * 78),
					Vector2(940, 420 - i * 84),
					Color("#fff0ce"),
					4.0 + float(i % 3)
				)
			play_pixel_vfx("Slashes/Cross Slash", enemy_center, 10.0, 22.0)
			play_pixel_vfx("Hit Sparks/Critical Star", enemy_center, 4.2, 22.0, Color("#ffe1a4"))
			spawn_impact_glyph("斬", enemy_center, Color("#fff0ce"), 250)

		"仙人":
			play_pixel_vfx("Lightning/Charge Up", enemy_center, 5.0, 18.0, Color("#cfeaff"))
			play_pixel_vfx("Magic/Cast Circle", enemy_center, 10.0, 18.0, Color("#b8e4ff"))
			for radius in [110.0, 180.0, 260.0, 350.0]:
				spawn_ring(enemy_center, Color("#a9d8f3aa"), radius)
			await get_tree().create_timer(0.14).timeout
			play_pixel_vfx("Lightning/Thunder Impact", enemy_center, 10.0, 20.0)
			play_pixel_vfx("Lightning/Tesla Arc", enemy_center, 6.0, 22.0, Color("#d9f1ff"))
			spawn_lightning_storm(enemy_center, 8, Color("#d9f1ff"))
			spawn_impact_glyph("天", enemy_center, Color("#d5ecfa"), 245)

		"傘使い":
			play_pixel_vfx("Explosions/Shockwave", enemy_center, 9.0, 18.0, Color("#b8dff1"))
			play_pixel_vfx_on_party("Magic/Shield Bubble", 3.5, 18.0, Color("#c8e8f3"))
			spawn_rain_field(enemy_center, 1200.0, 110, Color("#9cc5dcaa"))
			spawn_barrier_dome(party_center, Color("#b7dcec"), 360.0)
			for i in range(7):
				spawn_water_bloom(
					enemy_center + Vector2(randf_range(-260, 260), randf_range(-80, 160)),
					Color("#c7e2ef"),
					24
				)
			spawn_impact_glyph("雨", enemy_center, Color("#d7eef7"), 240)

		"巫女":
			play_pixel_vfx("Magic/Holy Light", party_center, 10.0, 18.0, Color("#ffe9a8"))
			play_pixel_vfx_on_party("Magic/Buff Up", 3.2, 20.0, Color("#ffe5a5"))
			play_pixel_vfx_on_party("Pickups and UI/Save Sparkle", 2.6, 18.0, Color("#fff0bc"))
			spawn_holy_column(party_center, Color("#fff0b8"), 760.0)
			spawn_barrier_dome(party_center, Color("#f5d98e"), 390.0)
			spawn_particle_burst(party_center, Color("#f5df91"), 110, 500.0, "✦")
			spawn_impact_glyph("神", party_center, Color("#fff2b6"), 250)

		"提灯使い":
			play_pixel_vfx("Fire/Fire Ring", enemy_center, 11.0, 19.0)
			for i in range(7):
				var angle := TAU * float(i) / 7.0
				play_pixel_vfx(
					"Fire/Blue Flame",
					enemy_center + Vector2(cos(angle), sin(angle)) * 230.0,
					6.0,
					18.0
				)
			await get_tree().create_timer(0.15).timeout
			play_pixel_vfx("Fire/Phoenix Flare", enemy_center, 11.0, 20.0)
			play_pixel_vfx("Explosions/Big Boom", enemy_center, 7.2, 21.0, Color("#ffc17f"))
			spawn_fire_column(enemy_center, 760.0, 300.0, false)
			spawn_impact_glyph("灯", enemy_center, Color("#ffc080"), 250)

		"呪詛師":
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 10.0, 18.0, Color("#c38ad3"))
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 5.0, 20.0, Color("#b67cc4"))
			play_pixel_vfx("Lightning/Shock Aura", enemy_center, 5.5, 18.0, Color("#a86bbb"))
			spawn_curse_chains(enemy_center, Color("#a66abb"), 16)
			for radius in [90.0, 145.0, 210.0, 285.0, 370.0]:
				spawn_ring(enemy_center, Color("#a66abb99"), radius)
			spawn_ink_burst(enemy_center, Color("#43294a"), 68)
			spawn_impact_glyph("怨", enemy_center, Color("#e2afea"), 260)

		"くノ一":
			play_pixel_vfx("Magic/Teleport", enemy_center + Vector2(-250, 0), 7.5, 22.0, Color("#cfe5ef"))
			for i in range(10):
				play_pixel_vfx(
					"Projectiles/Shuriken",
					enemy_center + Vector2(randf_range(-330, 330), randf_range(-220, 220)),
					4.3,
					24.0
				)
			await get_tree().create_timer(0.12).timeout
			play_pixel_vfx("Slashes/Cross Slash", enemy_center, 10.5, 24.0)
			play_pixel_vfx("Hit Sparks/Critical Star", enemy_center, 4.0, 24.0, Color("#e9f7fb"))
			spawn_impact_glyph("影", enemy_center, Color("#edf7fb"), 250)

		"酒呑童子":
			play_pixel_vfx("Magic/Buff Up", party_center, 4.0, 20.0, Color("#e9896f"))
			play_pixel_vfx("Explosions/Shockwave", enemy_center, 11.0, 18.0, Color("#ef9a75"))
			spawn_vertical_impact(enemy_center, Color("#d85e47"), 760.0, 180.0)
			spawn_fire_particles(enemy_center, 120, 440.0, false)
			await get_tree().create_timer(0.14).timeout
			play_pixel_vfx("Hit Sparks/Heavy Hit", enemy_center, 11.0, 20.0)
			play_pixel_vfx("Hit Sparks/Critical Star", enemy_center, 4.5, 22.0, Color("#ffb08d"))
			spawn_impact_glyph("鬼", enemy_center, Color("#ff9b7f"), 270)

		"神楽師":
			play_pixel_vfx("Magic/Cast Circle", party_center, 11.0, 18.0, Color("#f1c6df"))
			play_pixel_vfx_on_party("Magic/Buff Up", 3.0, 20.0, Color("#f2cce1"))
			play_pixel_vfx("Pickups and UI/Star Burst", party_center, 5.0, 20.0, Color("#f7d9e9"))
			for i in range(5):
				spawn_moon_halo(
					party_center + Vector2((i - 2) * 92.0, sin(float(i)) * 55.0),
					Color("#efc7e1"),
					3
				)
			spawn_holy_column(party_center, Color("#f8d9eb"), 760.0)
			spawn_particle_burst(party_center, Color("#f4cfe5"), 105, 480.0, "✦")
			spawn_impact_glyph("舞", party_center, Color("#f5d7e9"), 255)

		"猫又":
			play_pixel_vfx("Magic/Summon", enemy_center, 10.0, 18.0, Color("#9ae1d9"))
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 4.2, 18.0, Color("#75c8c0"))
			for i in range(8):
				var angle := TAU * float(i) / 8.0
				play_pixel_vfx(
					"Fire/Blue Flame",
					enemy_center + Vector2(cos(angle), sin(angle)) * 240.0,
					5.8,
					20.0,
					Color("#9ae1d9")
				)
			await get_tree().create_timer(0.12).timeout
			play_pixel_vfx("Slashes/Triple Claw", enemy_center, 10.0, 22.0, Color("#d2fff9"))
			spawn_impact_glyph("妖", enemy_center, Color("#c9fff5"), 255)

	# 第二段：着弾
	spawn_gpu_sparks(enemy_center, COL_GOLD_BRIGHT, 105, 470.0)
	spawn_shader_wave(enemy_center, tone, 0.62)
	spawn_fullscreen_flash(Color(tone, 0.86), 0.30, 0.10)
	shake_amount = maxf(shake_amount, 18.0)
	await get_tree().create_timer(0.42).timeout



func play_enemy_ultimate_motion() -> void:
	var viewport_size := get_viewport_rect().size
	var center := Vector2(viewport_size.x * 0.43, viewport_size.y * 0.43)
	match str(enemy_state["id"]):
		"moon_oni":
			spawn_impact_glyph("砕", center, Color("#d76b62"), 190)
			spawn_ring(center, Color("#b54c45aa"), 310.0)
		"fire_spider":
			spawn_particle_burst(center, Color("#cf644d"), 58, 340.0, "●")
			spawn_ring(center, Color("#b06a80aa"), 260.0)
		"bone_monk":
			for radius in [100.0, 180.0, 270.0]:
				spawn_ring(center, Color("#c7becdaa"), radius)
			spawn_impact_glyph("封", center, Color("#d3c9d8"), 170)
		"dark_tengu":
			for i in range(12):
				spawn_streak(Vector2(-80, randf_range(80.0, viewport_size.y - 120.0)), Vector2(viewport_size.x + 160.0, randf_range(-80.0, 80.0)), Color("#a9c7d477"), 5.0)
		_:
			spawn_ring(center, Color("#9d6a83bb"), 360.0)
			spawn_impact_glyph("蝕", center, Color("#d18aa7"), 210)
			spawn_fullscreen_flash(Color("#6b263b"), 0.28, 0.14)
	shake_amount = maxf(shake_amount, 15.0)
	await get_tree().create_timer(0.22).timeout


func prepare_enemy_intent() -> void:
	if int(enemy_state.get("cur_hp", 0)) <= 0:
		return
	if int(enemy_state.get("broken_rounds", 0)) > 0:
		return
	if int(enemy_state.get("big_state", 0)) != 0:
		return
	if round_number < int(enemy_state.get("next_big_round", 3)):
		return

	enemy_state["big_state"] = 1
	var data := get_enemy_big_move_data()
	if str(data.get("target", "")) == "single":
		enemy_state["big_target"] = pick_random_living_ally()
	else:
		enemy_state["big_target"] = ""
	append_log("[color=#d58b8f]⚠ %sが大技の構えに入った：%s[/color]" % [str(enemy_state["name"]), str(data["name"])])


func get_enemy_big_move_data() -> Dictionary:
	var second := is_enemy_second_phase()
	match str(enemy_state["id"]):
		"moon_oni":
			return {"name": "鬼月・天砕" if second else "鬼月・地砕", "target": "single", "hint": "単体・崩し特大　対策：防御／敵を崩す／下弦"}
		"fire_spider":
			return {"name": "百狐焔繭" if second else "百狐火繭", "target": "party", "hint": "全体・火傷　対策：禊／新月／敵を崩す"}
		"bone_monk":
			return {"name": "亡笛・逆奏" if second else "亡笛・封奏", "target": "party", "hint": "二人・封技・奏譜妨害　対策：敵を崩す／禊"}
		"dark_tengu":
			return {"name": "天狗颪・迅" if second else "天狗颪", "target": "party", "hint": "全体・構え・行動順　対策：防御／静奏／敵を崩す"}
		_:
			return {"name": "真・月蝕" if second else "月蝕", "target": "party", "hint": "全体・月相干渉　対策：月を読む／敵を崩す／守奏"}

func perform_enemy_charge() -> void:
	var data := get_enemy_big_move_data()
	await show_enemy_big_move_banner(str(data["name"]), "予兆")
	append_log("[color=#c49273]%sは%sを準備している。[/color]" % [str(enemy_state["name"]), str(data["name"])])

	if int(enemy_state.get("broken_rounds", 0)) <= 0:
		enemy_state["cur_break"] = mini(
			int(enemy_state["break_max"]),
			int(enemy_state["cur_break"]) + int(round(float(enemy_state["break_max"]) * (0.15 if is_enemy_second_phase() else 0.12)))
		)

	# 御前の第二相だけは詠唱そのものが月を引く。未来の月を見て止める判断が必要。
	if str(enemy_state.get("id", "")) == "eclipse_lady" and is_enemy_second_phase():
		enemy_moon_shift(1)

	enemy_state["big_state"] = 2
	enemy_state["big_charged_round"] = round_number
	await get_tree().create_timer(0.25).timeout

func perform_enemy_ultimate() -> void:
	var data := get_enemy_big_move_data()
	await show_enemy_big_move_banner(str(data["name"]), "発動")
	await play_enemy_ultimate_motion()
	var second := is_enemy_second_phase()

	match str(enemy_state["id"]):
		"moon_oni":
			var target := str(enemy_state.get("big_target", ""))
			if target == "" or not party_state.has(target) or int(party_state[target]["cur_hp"]) <= 0:
				target = pick_random_living_ally()
			await enemy_forced_single_attack(str(data["name"]), target, 1.45 if moon_index == 6 else (1.85 if second else 1.65), "physical", "", 54 if moon_index == 6 else (74 if second else 62))
		"fire_spider":
			await enemy_party_attack(str(data["name"]), 0.74 if moon_index == 0 else (1.02 if second else 0.92), "magic", "burn", 24 if moon_index == 0 else (34 if second else 28))
		"bone_monk":
			disturb_score_notes(3 if second else 2)
			await enemy_two_target_attack(str(data["name"]), 1.10 if second else 1.02, "magic", "seal", 34 if second else 30)
		"dark_tengu":
			push_party_timeline(28.0 if second else 18.0)
			await enemy_party_attack(str(data["name"]), 0.94 if second else 0.82, "physical", "", 58 if second else 50)
		_:
			var power := 1.28 if moon_index == 4 else 0.92
			if second:
				power *= 1.12
			var break_power := 48 if moon_index == 4 else 30
			await enemy_party_attack(str(data["name"]), power, "magic", "burn", break_power)
			if second:
				enemy_moon_shift(2)

	enemy_state["big_state"] = 0
	enemy_state["big_target"] = ""
	enemy_state["big_charged_round"] = -1
	var interval := 2 if second else 3
	enemy_state["next_big_round"] = round_number + interval

func enemy_forced_single_attack(
	action_name: String,
	target_name: String,
	power: float,
	damage_type: String,
	status_key: String,
	stance_break: int
) -> void:
	if target_name == "":
		return
	var attack_value := get_enemy_stat("mag") if damage_type == "magic" else get_enemy_stat("atk")
	var defense_value := get_player_stat(target_name, "res") if damage_type == "magic" else get_player_stat(target_name, "def")
	var damage := calculate_damage(attack_value, defense_value, power)
	damage = apply_enemy_moon_damage(damage)
	damage = apply_player_defense_modifiers(target_name, damage)
	damage_player_character(target_name, damage, stance_break)
	if status_key != "" and int(party_state[target_name]["cur_hp"]) > 0:
		add_player_status(target_name, status_key, 2)
	append_log("%s「[b]%s[/b]」 → %s　[color=#df6f76]%d[/color] ダメージ" % [str(enemy_state["name"]), action_name, target_name, damage])
	play_one_shot(damage_player)
	shake_amount = 14.0
	await show_hurt_state(target_name, damage)


func enemy_two_target_attack(
	action_name: String,
	power: float,
	damage_type: String,
	status_key: String,
	stance_break: int
) -> void:
	var candidates: Array[String] = []
	for char_name in party:
		if int(party_state[char_name]["cur_hp"]) > 0:
			candidates.append(char_name)
	candidates.shuffle()
	var limit := mini(2, candidates.size())
	for i in range(limit):
		var target := candidates[i]
		var attack_value := get_enemy_stat("mag") if damage_type == "magic" else get_enemy_stat("atk")
		var defense_value := get_player_stat(target, "res") if damage_type == "magic" else get_player_stat(target, "def")
		var damage := calculate_damage(attack_value, defense_value, power)
		damage = apply_enemy_moon_damage(damage)
		damage = apply_player_defense_modifiers(target, damage)
		damage_player_character(target, damage, stance_break)
		if status_key != "" and int(party_state[target]["cur_hp"]) > 0:
			add_player_status(target, status_key, 2)
		await show_hurt_state(target, damage)
	append_log("%s「[b]%s[/b]」　2人を狙う。" % [str(enemy_state["name"]), action_name])


func get_enemy_intent_text() -> String:
	if int(enemy_state.get("broken_rounds", 0)) > 0:
		return "崩壊　／　行動不能"

	var big_state := int(enemy_state.get("big_state", 0))
	if big_state <= 0:
		return ""

	var data := get_enemy_big_move_data()
	var target_text := ""
	if str(data.get("target", "")) == "single" and str(enemy_state.get("big_target", "")) != "":
		target_text = "　対象：" + str(enemy_state["big_target"])

	if big_state == 1:
		return "⚠ 大技準備　" + str(data["name"]) + target_text

	return "‼ 発動待機　" + str(data["name"]) + target_text

func show_battle_victory() -> void:
	busy = true
	refresh_battle_ui()

	append_log(
		"[color=#e9dfca][b]%s 討伐。[/b][/color]"
		% str(enemy_state["name"])
	)

	await get_tree().create_timer(0.45).timeout

	if enemy_index >= ENEMIES.size() - 1:
		show_game_clear()
		return

	show_result_overlay(
		"夜を越えた",
		"%sを討伐。\n生命・奏力・状態異常は次の戦闘でリセット。\n月相だけは巡り続ける。"
		% str(enemy_state["name"]),
		"次の夜へ",
		advance_to_next_enemy
	)


func advance_to_next_enemy() -> void:
	remove_battle_overlay()

	enemy_index += 1
	round_number = 1
	round_moon_bonus = 0

	prepare_party_for_battle()
	prepare_enemy(enemy_index)

	refresh_battle_ui()
	start_enemy_intro_sequence()


func show_game_over() -> void:
	busy = true

	show_result_overlay(
		"全滅",
		"五夜を越えられなかった。",
		"編成からやり直す",
		retry_from_selection,
		"タイトルへ",
		show_title_screen
	)


func retry_from_selection() -> void:
	battle_player.stop()
	if title_player.stream != null:
		title_player.play()
	show_party_select_screen()


func show_game_clear() -> void:
	busy = true
	battle_player.stop()

	if title_player.stream != null:
		title_player.play()

	show_result_overlay(
		"五夜踏破",
		"月蝕ノ御前を討伐。\n"
		+ "総巡数 %d　／　第%d奏譜まで到達。\n"
		+ "五 夜 踏 破"
		% [total_rounds + round_number, measure],
		"もう一度編成する",
		retry_from_selection,
		"タイトルへ",
		show_title_screen
	)


func show_result_overlay(
	title_text: String,
	body_text: String,
	primary_text: String,
	primary_callback: Callable,
	secondary_text: String = "",
	secondary_callback: Callable = Callable()
) -> void:
	remove_battle_overlay()

	battle_overlay = Control.new()
	battle_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(battle_overlay)

	var shade := ColorRect.new()
	shade.color = Color("#030407cc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_overlay.add_child(center)

	var frame := make_panel(Color("#0d0f15f8"), Color("#5a4930"), 18, 1)
	frame.custom_minimum_size = Vector2(650, 360)
	center.add_child(frame)

	var margin := MarginContainer.new()
	set_margins(margin, 52, 42, 52, 42)
	frame.add_child(margin)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 16)
	margin.add_child(v)

	var result_title := make_label(title_text, 38, COL_TEXT)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(result_title)

	var result_body := make_label(body_text, 14, Color("#aaa69e"))
	result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(result_body)

	var primary_button := make_primary_button(primary_text, 300)
	primary_button.pressed.connect(primary_callback)
	v.add_child(primary_button)

	if secondary_text != "" and secondary_callback.is_valid():
		var secondary_button := make_secondary_button(secondary_text, 300)
		secondary_button.pressed.connect(secondary_callback)
		v.add_child(secondary_button)


func remove_battle_overlay() -> void:
	if battle_overlay != null and is_instance_valid(battle_overlay):
		battle_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		battle_overlay.hide()
		battle_overlay.queue_free()
		battle_overlay = null


# ============================================================
# HELPERS / TARGETING
# ============================================================

func count_living_party() -> int:
	var count: int = 0

	for char_name in party:
		if int(party_state[char_name]["cur_hp"]) > 0:
			count += 1

	return count


func is_party_defeated() -> bool:
	return count_living_party() <= 0


func pick_random_living_ally() -> String:
	var living: Array[String] = []

	for char_name in party:
		if int(party_state[char_name]["cur_hp"]) > 0:
			living.append(char_name)

	if living.is_empty():
		return ""

	return living[randi_range(0, living.size() - 1)]


func find_lowest_hp_ally() -> String:
	var best_name := ""
	var best_ratio := 2.0

	for char_name in party:
		var state: Dictionary = party_state[char_name]

		if int(state["cur_hp"]) <= 0:
			continue

		var ratio: float = (
			float(state["cur_hp"])
			/ float(state["hp"])
		)

		if ratio < best_ratio:
			best_ratio = ratio
			best_name = char_name

	return best_name


func get_action_display(
	char_name: String,
	action_data: Dictionary
) -> String:
	if action_data.is_empty():
		return "未選択"

	var action_type: String = str(action_data["type"])

	if action_type == "attack":
		return "予定：%s 攻撃" % get_note_display(get_basic_attack_note(char_name))
	elif action_type == "guard":
		return "予定：𝄽 防御"
	elif action_type == "ultimate":
		return "予定：必殺技"
	elif action_type == "skill":
		var skill_data: Dictionary = action_data["skill"]
		var text_value := "予定：%s %s" % [get_note_display(get_skill_note_type(str(skill_data.get("id", "")))), str(skill_data["name"])]

		if str(skill_data["target"]) == "ally":
			var target_name: String = str(action_data["target"])
			if target_name != "":
				text_value += " → " + target_name

		return text_value

	return "未選択"


# ============================================================
# 行動順バー
# ============================================================

func get_turn_order_preview() -> Array[Dictionary]:
	if not ctb_initialized:
		return []

	var simulated: Dictionary = {}
	for char_name in party:
		if (
			party_state.has(char_name)
			and int(party_state[char_name]["cur_hp"]) > 0
			and ctb_times.has(char_name)
		):
			simulated[char_name] = float(ctb_times[char_name])

	if int(enemy_state.get("cur_hp", 0)) > 0 and ctb_times.has(CTB_ENEMY_KEY):
		simulated[CTB_ENEMY_KEY] = float(ctb_times[CTB_ENEMY_KEY])

	var entries: Array[Dictionary] = []
	var local_big_state := int(enemy_state.get("big_state", 0))
	var big_data := get_enemy_big_move_data()
	var seen_players: Dictionary = {}

	for index in range(8):
		if simulated.is_empty():
			break

		var next_key := ""
		var next_time := INF
		for key_variant in simulated.keys():
			var key := str(key_variant)
			var value := float(simulated[key])
			if value < next_time:
				next_time = value
				next_key = key

		if next_key == "":
			break

		if next_key == CTB_ENEMY_KEY:
			var action_name := "敵行動"
			var warning := false
			var wait_value := get_enemy_ctb_wait(false)

			if int(enemy_state.get("broken_rounds", 0)) > 0:
				action_name = "崩壊中"
				wait_value = 72
			elif local_big_state == 1:
				action_name = "大技準備"
				warning = true
				local_big_state = 2
				wait_value = maxi(34, get_enemy_ctb_wait(false) - 12)
			elif local_big_state == 2:
				action_name = str(big_data.get("name", "大技"))
				warning = true
				local_big_state = 0

			entries.append({
				"side": "enemy",
				"actor": str(enemy_state.get("name", "敵")),
				"action_name": action_name,
				"time": next_time,
				"warning": warning,
				"planning": false
			})
			simulated[next_key] = next_time + float(wait_value)
			continue

		var first_occurrence := not seen_players.has(next_key)
		var action_name := "次巡"
		var wait_action: Dictionary = {}
		var is_planning_actor := false

		if first_occurrence:
			seen_players[next_key] = true

			if int(party_state[next_key].get("broken_rounds", 0)) > 0:
				action_name = "崩壊中"
				wait_action = {"type": "guard", "actor": next_key}
			elif pending_actions.has(next_key):
				wait_action = pending_actions[next_key]
				action_name = get_action_score_name(wait_action)
			elif (
				not busy
				and next_key == get_current_planning_actor()
				and not ctb_preview_action.is_empty()
			):
				wait_action = ctb_preview_action
				action_name = get_action_score_name(wait_action)
				is_planning_actor = true
			elif not busy and next_key == get_current_planning_actor():
				action_name = "選択中"
				is_planning_actor = true
			else:
				action_name = "未選択"

		var wait_value := 78
		if not wait_action.is_empty():
			wait_value = get_effective_action_wait(next_key, wait_action, false)
		elif ctb_last_wait.has(next_key):
			wait_value = int(ctb_last_wait[next_key])
		else:
			# 未選択の未来行動は通常攻撃と決めつけない。中立値で予測する。
			wait_value = maxi(48, 82 - int(round(float(get_player_stat(next_key, "spd")) * 0.55)))

		entries.append({
			"side": "player",
			"actor": next_key,
			"action_name": action_name,
			"time": next_time,
			"warning": false,
			"planning": is_planning_actor
		})
		simulated[next_key] = next_time + float(wait_value)

	return entries


func get_enemy_timeline_action_name() -> String:
	if int(enemy_state.get("broken_rounds", 0)) > 0:
		return "崩壊中"

	var big_state := int(enemy_state.get("big_state", 0))
	if big_state == 1:
		return "大技準備"
	if big_state == 2:
		var data := get_enemy_big_move_data()
		return str(data.get("name", "大技"))

	return "敵行動"


func refresh_turn_order_bar() -> void:
	if turn_order_bar == null or not is_instance_valid(turn_order_bar):
		return

	clear_container(turn_order_bar)

	var entries := get_turn_order_preview()
	if entries.is_empty():
		return

	var available := turn_order_bar.size.x
	if available < 640.0:
		available = 920.0

	var gap := 7.0
	var slot_width := clampf((available - gap * 7.0) / 8.0, 88.0, 126.0)

	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var is_enemy := str(entry.get("side", "")) == "enemy"
		var is_warning := bool(entry.get("warning", false))
		var is_planning := bool(entry.get("planning", false))
		var is_now := i == 0

		var bg := Color("#11131a")
		var border := Color("#343740")
		if is_enemy:
			bg = Color("#181013")
			border = Color("#66363d")
		if is_warning:
			bg = Color("#281114")
			border = Color("#d16269")
		if is_now:
			border = COL_GOLD_BRIGHT if not is_enemy else Color("#e07a76")
		if is_planning:
			bg = Color("#171c24")
			border = Color("#9fb8d8")

		var slot := make_panel(bg, border, 9, 2 if is_now or is_warning or is_planning else 1)
		slot.size = Vector2(slot_width, 60)
		slot.position = Vector2(float(i) * (slot_width + gap) + 34.0, 2)
		turn_order_bar.add_child(slot)

		var target_pos := Vector2(float(i) * (slot_width + gap), 2)
		slot.modulate.a = 0.65
		var move := create_tween()
		move.set_parallel(true)
		move.tween_property(slot, "position", target_pos, 0.18)
		move.tween_property(slot, "modulate:a", 1.0, 0.14)

		var margin := MarginContainer.new()
		set_margins(margin, 6, 5, 6, 4)
		slot.add_child(margin)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		margin.add_child(row)

		var icon_frame := PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(35, 35)
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color("#17191f")
		icon_style.border_color = border
		icon_style.set_border_width_all(1)
		icon_style.set_corner_radius_all(7)
		icon_frame.add_theme_stylebox_override("panel", icon_style)
		row.add_child(icon_frame)

		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if is_enemy:
			icon.texture = get_boss_texture(enemy_index)
		else:
			icon.texture = get_portrait_texture(str(entry.get("actor", "")), false)
		icon_frame.add_child(icon)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 0)
		row.add_child(info)

		var actor_text := str(entry.get("actor", ""))
		if actor_text.length() > 5:
			actor_text = actor_text.left(5)
		var actor_label := make_label(actor_text, 9, Color("#ded8cd"))
		actor_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(actor_label)

		var action_color := Color("#858892")
		if is_warning:
			action_color = Color("#e4b26e")
		elif is_planning:
			action_color = Color("#b8d5ef")
		elif is_now:
			action_color = COL_GOLD_BRIGHT

		var action_label := make_label(
			str(entry.get("action_name", "")),
			8,
			action_color
		)
		action_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		info.add_child(action_label)

		var delta := maxi(0, int(round(float(entry.get("time", ctb_clock)) - ctb_clock)))
		var time_label := make_label("あと %d" % delta, 7, Color("#5f626a"))
		info.add_child(time_label)

func clear_enemy_state_fx() -> void:
	if enemy_state_fx_layer == null or not is_instance_valid(enemy_state_fx_layer):
		return
	for child in enemy_state_fx_layer.get_children():
		child.queue_free()


func add_enemy_persistent_particles(
	color: Color,
	amount: int,
	rise_speed: float,
	spread_width: float,
	start_y: float
) -> void:
	if enemy_state_fx_layer == null or not is_instance_valid(enemy_state_fx_layer):
		return
	var particles := GPUParticles2D.new()
	particles.position = Vector2(enemy_portrait_frame.size.x * 0.5, enemy_portrait_frame.size.y * start_y)
	particles.amount = amount
	particles.lifetime = 1.15
	particles.one_shot = false
	particles.randomness = 0.75
	particles.texture = get_particle_dot_texture()
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(spread_width, 24.0, 0.0)
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 34.0
	material.initial_velocity_min = rise_speed * 0.55
	material.initial_velocity_max = rise_speed
	material.gravity = Vector3(0.0, -35.0, 0.0)
	material.scale_min = 0.24
	material.scale_max = 0.78
	material.color = color
	particles.process_material = material
	enemy_state_fx_layer.add_child(particles)
	particles.emitting = true


func add_enemy_break_cracks() -> void:
	if enemy_state_fx_layer == null or not is_instance_valid(enemy_state_fx_layer):
		return
	var size := enemy_portrait_frame.size
	for i in range(5):
		var line := Line2D.new()
		line.width = 2.0 + float(i % 2)
		line.default_color = Color("#e5c77a99")
		line.antialiased = true
		var start := Vector2(size.x * randf_range(0.28, 0.72), size.y * randf_range(0.18, 0.40))
		var points := PackedVector2Array([start])
		var current := start
		for p in range(4):
			current += Vector2(randf_range(-42.0, 42.0), randf_range(35.0, 72.0))
			points.append(current)
		line.points = points
		enemy_state_fx_layer.add_child(line)


func refresh_enemy_state_visuals() -> void:
	if enemy_state_fx_layer == null or not is_instance_valid(enemy_state_fx_layer):
		return
	var break_ratio := float(enemy_state.get("cur_break", 0)) / maxf(1.0, float(enemy_state.get("break_max", 1)))
	var signature := "%s|%s|%d|%d|%d" % [
		str(has_status(enemy_state, "burn")),
		str(has_status(enemy_state, "poison")),
		1 if break_ratio <= 0.25 else 0,
		int(enemy_state.get("big_state", 0)),
		1 if is_enemy_second_phase() else 0
	]
	if signature == enemy_state_fx_signature:
		return
	enemy_state_fx_signature = signature
	clear_enemy_state_fx()

	if has_status(enemy_state, "burn"):
		add_enemy_persistent_particles(Color("#ef7048cc"), 34, 150.0, 190.0, 0.88)
	if has_status(enemy_state, "poison"):
		add_enemy_persistent_particles(Color("#9a6ab6aa"), 28, 72.0, 210.0, 0.76)
	if break_ratio <= 0.25 and int(enemy_state.get("cur_break", 0)) > 0:
		add_enemy_break_cracks()
	if is_enemy_second_phase():
		var halo := ColorRect.new()
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		halo.color = Color(MOON_COLORS[moon_index], 0.055)
		halo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		enemy_state_fx_layer.add_child(halo)


func trigger_hit_stop_for_damage(damage: int) -> void:
	var ratio := float(damage) / maxf(1.0, float(enemy_state.get("hp", 1)))
	var duration := 0.0
	if ratio >= 0.11:
		duration = 0.085
	elif ratio >= 0.055:
		duration = 0.055
	if duration <= 0.0:
		return
	hit_stop_serial += 1
	var token := hit_stop_serial
	Engine.time_scale = 0.12
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(end_hit_stop.bind(token))


func end_hit_stop(token: int) -> void:
	if token != hit_stop_serial:
		return
	Engine.time_scale = 1.0


func refresh_battle_ui() -> void:
	if screen_mode != "battle":
		return
	if battle_root == null or not is_instance_valid(battle_root):
		return

	battle_no_label.text = "第%d夜 / 五夜　　第%02d巡" % [
		enemy_index + 1,
		round_number
	]

	moon_label.text = PHASES[moon_index]
	moon_roman_label.text = ""
	var next_phase := get_next_round_moon_index()
	moon_effect_label.text = get_moon_effect_text() + "\n次巡：" + PHASES[next_phase]
	moon_label.add_theme_color_override(
		"font_color",
		MOON_COLORS[moon_index]
	)

	refresh_turn_order_bar()

	enemy_subtitle_label.text = ""
	enemy_name_label.text = str(enemy_state["name"])
	enemy_desc_label.text = ""
	enemy_glyph_label.text = str(enemy_state["glyph"])
	if enemy_intent_label != null:
		enemy_intent_label.text = get_enemy_intent_text()
		var intent_color := Color("#8a8d94")
		if int(enemy_state.get("big_state", 0)) == 1:
			intent_color = Color("#d5a06e")
		elif int(enemy_state.get("big_state", 0)) == 2:
			intent_color = Color("#e46d72")
		elif int(enemy_state.get("broken_rounds", 0)) > 0:
			intent_color = COL_BREAK
		enemy_intent_label.add_theme_color_override("font_color", intent_color)
	if enemy_portrait != null and is_instance_valid(enemy_portrait):
		enemy_portrait.texture = get_boss_texture(enemy_index)

	enemy_hp_bar.max_value = float(enemy_state["hp"])
	enemy_hp_bar.value = float(enemy_state["cur_hp"])

	enemy_break_bar.max_value = float(enemy_state["break_max"])
	enemy_break_bar.value = float(enemy_state["cur_break"])

	var break_text := ""
	if int(enemy_state["broken_rounds"]) > 0:
		break_text = "　[color=#e1bd63]崩壊 / 行動不能[/color]"
	elif int(enemy_state.get("break_guard_rounds", 0)) > 0:
		break_text = "　[color=#8f99a8]立て直し / 崩し耐性[/color]"

	enemy_status_label.text = (
		"生命 %d / %d　　構え %d / %d　　%s%s%s　｜　%s"
		% [
			int(enemy_state["cur_hp"]),
			int(enemy_state["hp"]),
			int(enemy_state["cur_break"]),
			int(enemy_state["break_max"]),
			status_text(enemy_state),
			break_text,
			get_enemy_adaptation_text(),
			get_enemy_mechanic_text()
		]
	)

	refresh_enemy_state_visuals()
	refresh_music_ui()

	for char_name in party:
		var state: Dictionary = party_state[char_name]
		var card: Dictionary = party_cards[char_name]

		var panel: PanelContainer = card["panel"] as PanelContainer
		var hp_label: Label = card["hp_label"] as Label
		var hp_bar: ProgressBar = card["hp_bar"] as ProgressBar
		var mana_label: Label = card["mana_label"] as Label
		var mana_bar: ProgressBar = card["mana_bar"] as ProgressBar
		var stance_label: Label = card["stance_label"] as Label
		var stance_bar: ProgressBar = card["stance_bar"] as ProgressBar
		var status_label: Label = card["status_label"] as Label
		var planned_label: Label = card["planned_label"] as Label
		var portrait: TextureRect = card["portrait"] as TextureRect

		if not bool(hurt_animating.get(char_name, false)):
			var hp_ratio := float(state["cur_hp"]) / maxf(1.0, float(state["hp"]))
			portrait.texture = get_portrait_texture(char_name, hp_ratio <= 0.50)

		hp_bar.max_value = float(state["hp"])
		hp_bar.value = float(state["cur_hp"])

		mana_bar.max_value = float(state["mana"])
		mana_bar.value = float(state["cur_mana"])
		stance_bar.max_value = float(state["stance_max"])
		stance_bar.value = float(state["cur_stance"])

		hp_label.text = "生命　%d / %d" % [
			int(state["cur_hp"]),
			int(state["hp"])
		]

		mana_label.text = "奏力　%d / %d　回復+%d" % [
			int(state["cur_mana"]),
			int(state["mana"]),
			get_mana_regen_amount(state)
		]

		if int(state.get("broken_rounds", 0)) > 0:
			stance_label.text = "構え　崩壊　行動不能 %d巡" % maxi(1, int(state["broken_rounds"]) - 1)
			stance_label.add_theme_color_override("font_color", Color("#d76e76"))
		else:
			stance_label.text = "構え　%d / %d" % [int(state["cur_stance"]), int(state["stance_max"])]
			stance_label.add_theme_color_override("font_color", Color("#ad9a6d"))

		status_label.text = status_text(state)

		if int(state["cur_hp"]) <= 0:
			planned_label.text = "戦闘不能"
			planned_label.add_theme_color_override("font_color", Color("#8d555b"))
		elif int(state.get("broken_rounds", 0)) > 0:
			planned_label.text = "崩壊 / 行動不能"
			planned_label.add_theme_color_override("font_color", Color("#d76e76"))
		elif pending_actions.has(char_name):
			var planned_action: Dictionary = pending_actions[char_name]
			planned_label.text = "予定：" + get_action_score_name(planned_action)
			planned_label.add_theme_color_override("font_color", Color("#b8d5ef"))
		elif char_name == get_current_planning_actor() and not busy:
			planned_label.text = "行動選択中"
			planned_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
		elif ctb_times.has(char_name):
			var remaining := maxi(0, int(round(float(ctb_times[char_name]) - ctb_clock)))
			planned_label.text = "次行動まで %d" % remaining
			planned_label.add_theme_color_override("font_color", Color("#777b84"))
		else:
			planned_label.text = "待機"
			planned_label.add_theme_color_override("font_color", Color("#666971"))

		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

		var is_current: bool = (
			not busy
			and int(state["cur_hp"]) > 0
			and int(state.get("broken_rounds", 0)) <= 0
			and char_name == get_current_planning_actor()
		)

		if is_current:
			style.border_color = COL_GOLD
			style.set_border_width_all(2)
			style.bg_color = Color("#161610f4")
		else:
			style.border_color = Color("#2c2f38")
			style.set_border_width_all(1)
			style.bg_color = Color("#0d0f15f4")

		panel.add_theme_stylebox_override("panel", style)

	refresh_moon_forecast()
	queue_redraw()


func refresh_music_ui() -> void:
	measure_label.text = "第 %d 奏譜" % measure
	composition_label.text = "八拍奏式：昇奏・降奏・重奏・返奏・彩奏・静奏　｜　前奏譜：" + last_measure_text
	moon_seal_label.text = get_party_finisher_status_text()
	var any_finisher_ready := false
	for char_name in party:
		if is_ultimate_ready(char_name):
			any_finisher_ready = true
			break

	if any_finisher_ready:
		moon_seal_label.add_theme_color_override("font_color", COL_GOLD_BRIGHT)
	else:
		moon_seal_label.add_theme_color_override("font_color", Color("#858892"))

	var resonant := get_phase_resonant_notes(moon_index)
	resonance_label.text = "現在【%s】の共鳴音紋　%s　%s　｜　共鳴を重ねて奏式を完成すると「月奏」へ昇格" % [
		PHASES[moon_index],
		get_note_display(resonant[0]),
		get_note_display(resonant[1])
	]
	resonance_label.add_theme_color_override("font_color", MOON_COLORS[moon_index])

	var display_notes := get_score_forecast_notes()
	combo_forecast_label.text = "奏式予測　" + get_combo_forecast_text(display_notes)
	refresh_score_tension_style(display_notes.size())

	for connector_index in range(beat_connectors.size()):
		var connector := beat_connectors[connector_index]
		if connector_index < display_notes.size() - 1:
			var planned_link := bool(display_notes[connector_index].get("planned", false)) or bool(display_notes[connector_index + 1].get("planned", false))
			connector.color = Color("#6e6045") if planned_link else Color("#c3a45b")
		else:
			connector.color = Color("#272a31")

	for i in range(beat_cells.size()):
		var cell: Dictionary = beat_cells[i]
		var panel: PanelContainer = cell["panel"] as PanelContainer
		var count_label: Label = cell["count"] as Label
		var note_label: Label = cell["note"] as Label
		var action_label: Label = cell["action"] as Label
		var actor_label: Label = cell["actor"] as Label
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

		if i < display_notes.size():
			var note: Dictionary = display_notes[i]
			var planned := bool(note.get("planned", false))
			var mark := str(note.get("mark", "・"))
			note_label.text = get_note_display(mark)
			note_label.add_theme_color_override("font_color", get_note_color(mark, planned))
			action_label.text = str(note.get("action_name", ""))
			action_label.add_theme_color_override(
				"font_color",
				Color("#a99f89") if not planned else Color("#686760")
			)
			actor_label.text = str(note.get("actor", "")) + (" 予定" if planned else "")
			actor_label.add_theme_color_override("font_color", Color("#8f929a") if not planned else Color("#62656d"))
			count_label.add_theme_color_override("font_color", Color("#a58b60") if not planned else Color("#666970"))
			style.bg_color = Color("#211d17") if not planned else Color("#17171b")
			style.border_color = get_note_color(mark, planned)
		elif i == beat:
			note_label.text = "〔？〕"
			action_label.text = "次の技で音紋が決まる"
			actor_label.text = "次の拍"
			note_label.add_theme_color_override("font_color", Color("#8c7049"))
			action_label.add_theme_color_override("font_color", Color("#6a6257"))
			actor_label.add_theme_color_override("font_color", Color("#6a6257"))
			style.bg_color = Color("#171820")
			style.border_color = Color("#4d4638")
		else:
			note_label.text = "・"
			action_label.text = ""
			actor_label.text = ""
			note_label.add_theme_color_override("font_color", Color("#555861"))
			style.bg_color = Color("#13151b")
			style.border_color = Color("#2c2e35")

		panel.add_theme_stylebox_override("panel", style)


func get_score_forecast_notes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for note_variant in measure_notes:
		var note: Dictionary = note_variant.duplicate(true)
		note["planned"] = false
		result.append(note)

	if result.size() >= SCORE_LENGTH:
		return result

	# 三人分の作戦を、実際に動く予定順で半透明表示する。
	var planned: Array[Dictionary] = []
	var current_actor := get_current_planning_actor()

	for char_name in party:
		var action: Dictionary = {}
		if pending_actions.has(char_name):
			action = pending_actions[char_name].duplicate(true)
		elif (
			char_name == current_actor
			and not ctb_preview_action.is_empty()
		):
			action = ctb_preview_action.duplicate(true)

		if action.is_empty():
			continue

		planned.append({
			"actor": char_name,
			"action": action,
			"time": float(ctb_times.get(char_name, 9999.0))
		})

	planned.sort_custom(sort_planned_ctb_ascending)

	var simulated_phase := moon_index
	for planned_variant in planned:
		if result.size() >= SCORE_LENGTH:
			break

		var item: Dictionary = planned_variant
		var actor_name := str(item["actor"])
		var action_data: Dictionary = item["action"]
		simulated_phase = (
			simulated_phase + get_action_moon_steps(action_data)
		) % PHASES.size()

		result.append({
			"actor": actor_name,
			"mark": get_action_note_for_actor(actor_name, action_data),
			"phase": simulated_phase,
			"action_name": get_action_score_name(action_data),
			"planned": true
		})

	return result


func sort_planned_ctb_ascending(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 9999.0)) < float(b.get("time", 9999.0))


func get_combo_forecast_text(notes: Array[Dictionary]) -> String:
	# 音紋そのものは上の八拍セルで見えるため、ここでは候補だけを短く1行表示する。
	if notes.is_empty():
		return "形成前　最初の音紋を選ぶ"

	var remaining := SCORE_LENGTH - notes.size()

	if notes.size() >= SCORE_LENGTH:
		var combo := detect_score_combo(notes)
		var combo_name := str(combo["name"])
		return "【%s】%s" % [
			combo_name,
			"　→ 月奏" if bool(combo["moon_combo"]) else ""
		]

	if notes.size() < 4:
		return "形成中 %d / %d　／　あと%d拍" % [
			notes.size(),
			SCORE_LENGTH,
			remaining
		]

	var candidates := get_next_note_combo_candidates(notes)
	if candidates.is_empty():
		return "形成中 %d / %d　／　あと%d拍" % [
			notes.size(),
			SCORE_LENGTH,
			remaining
		]

	var stage := "兆し" if notes.size() <= 5 else "終止候補"
	return "%s　%s　／　あと%d拍" % [
		stage,
		"　".join(candidates),
		remaining
	]


func get_next_note_combo_candidates(notes: Array[Dictionary]) -> Array[String]:
	var results: Array[String] = []
	var current: Array[Dictionary] = []
	for note_variant in notes:
		current.append(note_variant.duplicate(true))

	for candidate in NOTE_ORDER:
		var simulated := current.duplicate(true)
		simulated.append({
			"actor": "候補",
			"mark": candidate,
			"phase": moon_index,
			"action_name": "",
			"planned": true
		})

		var marks: Array[String] = []
		var performers: Dictionary = {}
		var uniques: Dictionary = {}
		for note_variant in simulated:
			var note: Dictionary = note_variant
			var mark := str(note.get("mark", ""))
			marks.append(mark)
			performers[str(note.get("actor", ""))] = true
			if get_note_value(mark) >= 0:
				uniques[mark] = true

		var shape := detect_melody_shape(marks, performers.size(), uniques.size())
		if shape != "余韻":
			results.append("%s→%s" % [get_note_display(candidate), shape])
		if results.size() >= 3:
			break

	return results

func append_log(line: String) -> void:
	if log_label == null:
		return

	log_label.append_text("\n" + line)
	log_label.scroll_to_line(
		maxi(0, log_label.get_line_count() - 1)
	)


# ============================================================
# PORTRAITS / DAMAGE FEEDBACK
# ============================================================

func get_portrait_texture(
	char_name: String,
	hurt: bool
) -> Texture2D:
	if not CHARACTERS.has(char_name):
		return null

	var slug: String = str(CHARACTERS[char_name]["slug"])
	var suffix := "_hurt.png" if hurt else "_idle.png"

	for directory in ICON_DIRS:
		var path := directory + "/" + slug + suffix

		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			if texture != null:
				return texture

	return null


func show_hurt_state(
	char_name: String,
	damage: int
) -> void:
	if not party_cards.has(char_name):
		return

	hurt_animating[char_name] = true

	var card: Dictionary = party_cards[char_name]
	var panel: PanelContainer = card["panel"] as PanelContainer
	var portrait: TextureRect = card["portrait"] as TextureRect

	var hurt_texture: Texture2D = get_portrait_texture(
		char_name,
		true
	)

	if hurt_texture != null:
		portrait.texture = hurt_texture

	panel.modulate = Color(1.0, 0.67, 0.69, 1.0)
	portrait.modulate = Color(1.12, 0.72, 0.72, 1.0)

	spawn_damage_popup(panel, damage)

	await get_tree().create_timer(0.24).timeout

	var state: Dictionary = party_state[char_name]
	var hp_ratio := float(state["cur_hp"]) / maxf(1.0, float(state["hp"]))
	portrait.texture = get_portrait_texture(char_name, hp_ratio <= 0.50)

	panel.modulate = Color.WHITE
	portrait.modulate = Color.WHITE
	hurt_animating[char_name] = false


func spawn_damage_popup(
	panel: Control,
	damage: int
) -> void:
	var popup := Label.new()
	popup.text = "-%d" % damage
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_font_size_override("font_size", 27)
	popup.add_theme_color_override(
		"font_color",
		Color("#ff8f95")
	)
	popup.add_theme_color_override(
		"font_outline_color",
		Color("#160608")
	)
	popup.add_theme_constant_override("outline_size", 5)

	var popup_pos := panel.global_position + Vector2(
		panel.size.x * 0.54,
		16.0
	)

	popup.position = popup_pos
	effect_layer.add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		popup,
		"position:y",
		popup.position.y - 58.0,
		0.55
	)
	tween.tween_property(
		popup,
		"modulate:a",
		0.0,
		0.55
	)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)



# ============================================================
# V4 PRESENTATION / MOON CORE
# ============================================================

func start_enemy_intro_sequence() -> void:
	busy = true
	await show_boss_intro()
	begin_command_phase()


func show_boss_intro() -> void:
	if screen_mode != "battle" or battle_root == null:
		return

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.015, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 9)
	center.add_child(v)

	var night := make_label("第 %d 夜" % (enemy_index + 1), 18, Color("#98704f"))
	night.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(night)

	var boss_name := make_label(str(enemy_state["name"]), 54, COL_TEXT)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_color_override("font_outline_color", Color("#180b0e"))
	boss_name.add_theme_constant_override("outline_size", 9)
	v.add_child(boss_name)

	var line := ColorRect.new()
	line.color = Color("#8c4f50")
	line.custom_minimum_size = Vector2(420, 2)
	v.add_child(line)

	spawn_shader_wave(get_viewport_rect().size * 0.5, Color("#8c4f50"), 0.55)
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.16)
	tween.tween_interval(0.48)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.20)
	await tween.finished
	overlay.queue_free()

func show_round_moon_intro() -> void:
	if moon_intro_running or screen_mode != "battle" or battle_root == null:
		return

	moon_intro_running = true

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.012, 0.018, 0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var viewport_size := get_viewport_rect().size
	var moon := Panel.new()
	moon.size = Vector2(210, 210)
	moon.position = viewport_size * 0.5 - moon.size * 0.5 + Vector2(0, -52)

	var moon_style := StyleBoxFlat.new()
	moon_style.bg_color = Color(MOON_COLORS[moon_index], 0.22)
	moon_style.border_color = Color(MOON_COLORS[moon_index], 0.72)
	moon_style.set_border_width_all(2)
	moon_style.set_corner_radius_all(105)
	moon.add_theme_stylebox_override("panel", moon_style)
	overlay.add_child(moon)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 5)
	center.add_child(v)

	var round_label := make_label("第%02d巡" % round_number, 12, Color("#777b85"))
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(round_label)

	var phase_name := make_label(PHASES[moon_index], 58, MOON_COLORS[moon_index])
	phase_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_name.add_theme_color_override("font_outline_color", Color("#08090c"))
	phase_name.add_theme_constant_override("outline_size", 9)
	v.add_child(phase_name)

	var tag := make_label(PHASE_TAGLINES[moon_index], 15, Color("#d4c7ad"))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)

	var effect := make_label(get_moon_effect_text(), 10, Color("#858892"))
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(effect)

	var lock_text := make_label("この月相は第%02d巡の終了まで固定" % round_number, 11, Color("#d3b879"))
	lock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(lock_text)

	play_one_shot(time_player, 0.92 + float(moon_index) * 0.018)
	moon_pulse = 1.0
	overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(moon, "scale", Vector2(1.10, 1.10), 0.26).from(Vector2(0.72, 0.72))
	tween.tween_interval(0.42)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	await tween.finished

	overlay.queue_free()
	moon_intro_running = false



func get_particle_dot_texture() -> Texture2D:
	if particle_dot_texture != null:
		return particle_dot_texture

	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for x in range(12):
		for y in range(12):
			var distance := Vector2(float(x) - 5.5, float(y) - 5.5).length()
			var alpha := clampf(1.0 - distance / 6.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha * alpha))

	particle_dot_texture = ImageTexture.create_from_image(image)
	return particle_dot_texture


func spawn_gpu_sparks(
	center_point: Vector2,
	tone: Color,
	amount: int = 42,
	speed: float = 260.0
) -> void:
	var particles := GPUParticles2D.new()
	particles.position = center_point
	particles.amount = amount
	particles.lifetime = 0.62
	particles.one_shot = true
	particles.explosiveness = 0.96
	particles.texture = get_particle_dot_texture()

	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, -1.0, 0.0)
	material.spread = 180.0
	material.initial_velocity_min = speed * 0.45
	material.initial_velocity_max = speed
	material.gravity = Vector3(0.0, 125.0, 0.0)
	material.scale_min = 0.18
	material.scale_max = 0.72
	material.color = tone
	particles.process_material = material

	effect_layer.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.90).timeout.connect(particles.queue_free)


func spawn_shader_wave(
	center_point: Vector2,
	tone: Color,
	duration: float = 0.32
) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color.WHITE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.05;
uniform float width = 0.025;
uniform vec4 tint = vec4(1.0);

void fragment() {
	float d = distance(UV, center);
	float ring = 1.0 - smoothstep(width, width * 2.4, abs(d - radius));
	COLOR = vec4(tint.rgb, ring * tint.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(
		"center",
		Vector2(center_point.x / viewport_size.x, center_point.y / viewport_size.y)
	)
	material.set_shader_parameter("tint", Color(tone, 0.52))
	rect.material = material
	effect_layer.add_child(rect)

	for step in range(12):
		var progress := float(step) / 11.0
		material.set_shader_parameter("radius", 0.03 + progress * 0.42)
		rect.modulate.a = 1.0 - progress
		await get_tree().create_timer(maxf(0.012, duration / 12.0)).timeout

	rect.queue_free()


func get_slash_fx_files(style_key: String) -> Array[String]:
	var result: Array[String] = []
	var directory := DirAccess.open(SLASH_FX_DIR)
	if directory == null:
		return result

	var key := style_key.to_lower()
	for file_variant in directory.get_files():
		var file_name := str(file_variant)
		var lower := file_name.to_lower()
		if not lower.ends_with(".png"):
			continue

		var matches := false
		if key.begins_with("diagonal"):
			var number := key.trim_prefix("diagonal")
			matches = lower.begins_with("new slash diagonal " + number + "-")
		else:
			matches = lower.begins_with(key + " new slash ")

		if matches:
			result.append(SLASH_FX_DIR.path_join(file_name))

	result.sort()
	return result


func play_external_slash_fx(
	style_key: String,
	center_point: Vector2,
	scale_value: Vector2 = Vector2(1.0, 1.0),
	rotation_value: float = 0.0
) -> bool:
	var frames := get_slash_fx_files(style_key)
	if frames.is_empty():
		return false

	var slash := TextureRect.new()
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slash.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slash.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slash.size = Vector2(470, 470)
	slash.position = center_point - slash.size * 0.5
	slash.pivot_offset = slash.size * 0.5
	slash.scale = scale_value
	slash.rotation = rotation_value
	slash.add_theme_constant_override("outline_size", 0)
	effect_layer.add_child(slash)

	for frame_path in frames:
		if ResourceLoader.exists(frame_path):
			slash.texture = load(frame_path) as Texture2D
		await get_tree().create_timer(0.038).timeout

	var fade := create_tween()
	fade.tween_property(slash, "modulate:a", 0.0, 0.08)
	fade.tween_callback(slash.queue_free)
	return true


func show_skill_cut_in(_char_name: String, skill_name: String, skill_id: String) -> void:
	if screen_mode != "battle" or battle_root == null:
		return

	duck_battle_bgm(-21.0, 0.42)
	var tone := get_skill_color(skill_id)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var wash := ColorRect.new()
	wash.color = Color(tone, 0.075)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(wash)

	var viewport_size := get_viewport_rect().size

	# 人物も音紋も出さない。墨・技名・巨大漢字だけで見せる。
	for i in range(7):
		var ink := ColorRect.new()
		ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ink.color = Color(tone, 0.08 + float(i % 3) * 0.035)
		ink.size = Vector2(
			viewport_size.x * randf_range(0.62, 0.90),
			randf_range(2.0, 7.0)
		)
		ink.position = Vector2(
			viewport_size.x * randf_range(0.04, 0.18),
			viewport_size.y * (0.31 + float(i) * 0.060)
		)
		ink.rotation = deg_to_rad(randf_range(-5.0, 4.0))
		overlay.add_child(ink)

	var sigil := make_label(get_skill_sigil(skill_id), 270, Color(tone, 0.13))
	apply_display_font(sigil)
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil.set_anchors_preset(Control.PRESET_CENTER)
	sigil.position = Vector2(-450, -225)
	sigil.size = Vector2(900, 450)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.rotation = deg_to_rad(-8.0)
	overlay.add_child(sigil)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 9)
	center.add_child(v)

	var category := make_label(get_skill_category_text(skill_id), 14, Color(tone, 0.78))
	apply_display_font(category)
	category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(category)

	var upper_rule := ColorRect.new()
	upper_rule.color = Color(tone, 0.62)
	upper_rule.custom_minimum_size = Vector2(520, 2)
	v.add_child(upper_rule)

	var skill_label := make_label(skill_name, 78, tone)
	apply_display_font(skill_label)
	skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_label.add_theme_color_override("font_outline_color", Color("#050609"))
	skill_label.add_theme_constant_override("outline_size", 12)
	v.add_child(skill_label)

	var lower_rule := ColorRect.new()
	lower_rule.color = Color(tone, 0.36)
	lower_rule.custom_minimum_size = Vector2(360, 1)
	v.add_child(lower_rule)

	var sub_text := "月相共鳴" if is_note_resonant(get_skill_note_type(skill_id), moon_index) else "技発動"
	var sub := make_label(sub_text + "　・　" + PHASES[moon_index], 12, Color("#a8aab1"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	spawn_cut_in_marks(overlay, skill_id, tone)
	spawn_particle_burst(
		Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5),
		Color(tone, 0.72),
		28,
		280.0,
		"・"
	)

	overlay.modulate.a = 0.0
	v.pivot_offset = v.size * 0.5

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.045)
	tween.parallel().tween_property(v, "scale", Vector2.ONE, 0.16).from(Vector2(1.34, 0.68))
	tween.tween_interval(0.30)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.13)
	await tween.finished
	overlay.queue_free()


func get_skill_category_text(skill_id: String) -> String:
	if skill_id.begins_with("samurai"):
		return "斬撃術式"
	if skill_id.begins_with("sennin"):
		return "仙術"
	if skill_id.begins_with("kasa"):
		return "傘術"
	if skill_id.begins_with("miko"):
		return "神楽"
	if skill_id.begins_with("chochin"):
		return "妖火"
	if skill_id.begins_with("jusoshi"):
		return "呪詛"
	if skill_id.begins_with("kunoichi"):
		return "忍術"
	if skill_id.begins_with("shuten"):
		return "鬼術"
	if skill_id.begins_with("kagurashi"):
		return "神楽舞"
	if skill_id.begins_with("nekomata"):
		return "猫妖術"
	return "術式"


func get_skill_sigil(skill_id: String) -> String:
	match skill_id:
		"samurai_moon_slash": return "斬"
		"samurai_iai": return "朔"
		"samurai_red_mist": return "血"
		"samurai_swallow_break": return "燕"
		"samurai_aftermoon": return "残"
		"sennin_thunder": return "雷"
		"sennin_moon_turn": return "月"
		"sennin_spring": return "泉"
		"sennin_wind_read": return "風"
		"sennin_moon_hold": return "留"
		"kasa_pierce": return "穿"
		"kasa_counter": return "返"
		"kasa_ward": return "陣"
		"kasa_rain_armor": return "鎧"
		"kasa_thunder_guard": return "雷"
		"miko_heal": return "祓"
		"miko_cleanse": return "禊"
		"miko_bless": return "祝"
		"miko_bell_guard": return "鈴"
		"miko_divine_descent": return "神"
		"chochin_foxfire": return "狐"
		"chochin_lantern_drop": return "灯"
		"chochin_dim": return "迷"
		"chochin_ember_step": return "鬼"
		"chochin_burst": return "爆"
		"jusoshi_poison": return "蝕"
		"jusoshi_bind": return "縛"
		"jusoshi_grudge": return "怨"
		"jusoshi_extend": return "継"
		"jusoshi_abyss_mark": return "奈"
		"kunoichi_shadow_bind": return "影"
		"kunoichi_poison_star": return "毒"
		"kunoichi_mist_step": return "霞"
		"kunoichi_ninja_return": return "忍"
		"kunoichi_scatter_star": return "星"
		"shuten_oni_smash": return "鬼"
		"shuten_sake_flame": return "酒"
		"shuten_drink_dry": return "呑"
		"shuten_drunk_barrage": return "酔"
		"shuten_hyakki_feast": return "宴"
		"kagurashi_rhythm_dance": return "拍"
		"kagurashi_double_beat": return "重"
		"kagurashi_repose": return "鎮"
		"kagurashi_moon_call": return "招"
		"kagurashi_wild_kagura": return "荒"
		"nekomata_cat_fire": return "猫"
		"nekomata_twin_tail": return "尾"
		"nekomata_feint": return "騙"
		"nekomata_soul_lick": return "魂"
		"nekomata_bakeneko_dance": return "化"
		_: return "技"


func get_skill_color(skill_id: String) -> Color:
	if skill_id.begins_with("samurai"):
		return Color("#f0d6ae")
	if skill_id.begins_with("sennin"):
		return Color("#9fc8e8")
	if skill_id.begins_with("kasa"):
		return Color("#8fb5cf")
	if skill_id.begins_with("miko"):
		return Color("#f1d999")
	if skill_id.begins_with("chochin"):
		return Color("#e88958")
	if skill_id.begins_with("jusoshi"):
		return Color("#b58ac9")
	if skill_id.begins_with("kunoichi"):
		return Color("#9fb6c8")
	if skill_id.begins_with("shuten"):
		return Color("#c35f50")
	if skill_id.begins_with("kagurashi"):
		return Color("#e0b7d5")
	if skill_id.begins_with("nekomata"):
		return Color("#7fc4bf")
	return Color("#b6b8bf")


func spawn_cut_in_marks(parent: Control, skill_id: String, tone: Color) -> void:
	var viewport_size := get_viewport_rect().size
	var prefix := skill_id.get_slice("_", 0)

	for i in range(18):
		var mark := Label.new()
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.add_theme_font_size_override("font_size", 10 + (i % 4) * 3)
		mark.add_theme_color_override("font_color", Color(tone, 0.72))

		match prefix:
			"samurai": mark.text = "／"
			"sennin": mark.text = "○"
			"kasa": mark.text = "｜"
			"miko": mark.text = "✦"
			"chochin": mark.text = "●"
			"jusoshi": mark.text = "呪"
			"kunoichi": mark.text = "・"
			"shuten": mark.text = "鬼"
			"kagurashi": mark.text = "◇"
			"nekomata": mark.text = "猫"
			_: mark.text = "・"

		mark.position = Vector2(
			randf_range(viewport_size.x * 0.18, viewport_size.x * 0.82),
			randf_range(viewport_size.y * 0.24, viewport_size.y * 0.76)
		)
		parent.add_child(mark)

		var drift := Vector2(randf_range(-90.0, 90.0), randf_range(-80.0, 55.0))
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(mark, "position", mark.position + drift, 0.50)
		tween.tween_property(mark, "modulate:a", 0.0, 0.50)



func spawn_fire_particles(
	center_point: Vector2,
	amount: int = 72,
	radius_speed: float = 220.0,
	blue_fire: bool = false
) -> void:
	# 火の芯と火の粉を別パスで重ねる。
	var core_tone := Color("#7bd7ff") if blue_fire else Color("#ffb05c")
	var ember_tone := Color("#4f8cff") if blue_fire else Color("#e94f2f")

	for pass_index in range(2):
		var particles := GPUParticles2D.new()
		particles.position = center_point
		particles.amount = maxi(12, amount / 2)
		particles.lifetime = 0.72 + float(pass_index) * 0.16
		particles.one_shot = true
		particles.explosiveness = 0.92
		particles.texture = get_particle_dot_texture()

		var material := ParticleProcessMaterial.new()
		material.direction = Vector3(0.0, -1.0, 0.0)
		material.spread = 52.0
		material.initial_velocity_min = radius_speed * (0.35 + float(pass_index) * 0.12)
		material.initial_velocity_max = radius_speed * (0.85 + float(pass_index) * 0.22)
		material.gravity = Vector3(0.0, -165.0, 0.0)
		material.scale_min = 0.45 if pass_index == 0 else 0.18
		material.scale_max = 1.25 if pass_index == 0 else 0.62
		material.color = core_tone if pass_index == 0 else ember_tone
		particles.process_material = material

		effect_layer.add_child(particles)
		particles.emitting = true
		get_tree().create_timer(1.10).timeout.connect(particles.queue_free)


func spawn_fire_column(
	center_point: Vector2,
	height: float = 430.0,
	width: float = 130.0,
	blue_fire: bool = false
) -> void:
	var hot := Color("#a9e9ff") if blue_fire else Color("#ffd083")
	var outer := Color("#397de8") if blue_fire else Color("#e94e2f")

	for i in range(6):
		var tongue := ColorRect.new()
		tongue.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tongue.color = Color(
			hot if i % 2 == 0 else outer,
			0.74 - float(i) * 0.075
		)
		tongue.size = Vector2(
			width * randf_range(0.24, 0.70),
			height * randf_range(0.34, 0.72)
		)
		tongue.position = center_point + Vector2(
			randf_range(-width * 0.38, width * 0.38),
			randf_range(-8.0, 18.0)
		) - Vector2(tongue.size.x * 0.5, tongue.size.y)
		tongue.pivot_offset = Vector2(tongue.size.x * 0.5, tongue.size.y)
		tongue.rotation = deg_to_rad(randf_range(-8.0, 8.0))
		effect_layer.add_child(tongue)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(
			tongue,
			"scale",
			Vector2(randf_range(0.32, 0.70), randf_range(1.15, 1.55)),
			0.32
		).from(Vector2(0.15, 0.18))
		tween.tween_property(tongue, "modulate:a", 0.0, 0.42).set_delay(0.06)
		tween.set_parallel(false)
		tween.tween_callback(tongue.queue_free)

	spawn_fire_particles(center_point, 88, 255.0, blue_fire)
	spawn_shader_wave(center_point, outer, 0.32)


func spawn_lightning_bolt(
	start_point: Vector2,
	end_point: Vector2,
	tone: Color = Color("#d9efff"),
	width: float = 5.0,
	segments: int = 10
) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = tone
	line.antialiased = true

	var points := PackedVector2Array()
	for i in range(segments + 1):
		var progress := float(i) / float(segments)
		var point := start_point.lerp(end_point, progress)
		if i > 0 and i < segments:
			point += Vector2(
				randf_range(-24.0, 24.0),
				randf_range(-14.0, 14.0)
			)
		points.append(point)

	line.points = points
	effect_layer.add_child(line)

	var glow := Line2D.new()
	glow.width = width * 3.4
	glow.default_color = Color(tone, 0.18)
	glow.antialiased = true
	glow.points = points
	effect_layer.add_child(glow)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "modulate:a", 0.0, 0.20)
	tween.tween_property(glow, "modulate:a", 0.0, 0.24)
	tween.set_parallel(false)
	tween.tween_callback(line.queue_free)
	tween.tween_callback(glow.queue_free)


func spawn_lightning_storm(
	center_point: Vector2,
	count: int = 5,
	tone: Color = Color("#d9efff")
) -> void:
	var viewport_size := get_viewport_rect().size
	for i in range(count):
		var top := Vector2(
			center_point.x + randf_range(-190.0, 190.0),
			maxf(24.0, center_point.y - viewport_size.y * 0.46)
		)
		var end := center_point + Vector2(
			randf_range(-95.0, 95.0),
			randf_range(-35.0, 55.0)
		)
		spawn_lightning_bolt(top, end, tone, randf_range(3.0, 6.5), 9 + i % 4)

	spawn_fullscreen_flash(tone, 0.18, 0.08)
	spawn_gpu_sparks(center_point, tone, 52, 280.0)


func spawn_rain_field(
	center_point: Vector2,
	field_width: float = 720.0,
	count: int = 54,
	tone: Color = Color("#9dc5dd")
) -> void:
	var particles := GPUParticles2D.new()
	particles.position = center_point - Vector2(0.0, 300.0)
	particles.amount = count
	particles.lifetime = 0.75
	particles.one_shot = true
	particles.explosiveness = 0.20
	particles.texture = get_particle_dot_texture()

	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(field_width * 0.5, 22.0, 0.0)
	material.direction = Vector3(-0.12, 1.0, 0.0)
	material.spread = 8.0
	material.initial_velocity_min = 520.0
	material.initial_velocity_max = 820.0
	material.gravity = Vector3(-45.0, 360.0, 0.0)
	material.scale_min = 0.14
	material.scale_max = 0.32
	material.color = tone
	particles.process_material = material

	effect_layer.add_child(particles)
	particles.emitting = true
	get_tree().create_timer(1.10).timeout.connect(particles.queue_free)


func spawn_wind_arc(
	center_point: Vector2,
	tone: Color = Color("#cfe6f6"),
	count: int = 7
) -> void:
	for i in range(count):
		var line := Line2D.new()
		line.width = randf_range(1.4, 3.8)
		line.default_color = Color(tone, randf_range(0.28, 0.72))
		line.antialiased = true

		var radius := 100.0 + float(i) * 24.0
		var points := PackedVector2Array()
		for p in range(8):
			var angle := deg_to_rad(-115.0 + float(p) * 26.0)
			points.append(
				center_point + Vector2(cos(angle), sin(angle)) * radius
			)
		line.points = points
		effect_layer.add_child(line)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(line, "rotation", deg_to_rad(24.0), 0.42)
		tween.tween_property(line, "modulate:a", 0.0, 0.42)
		tween.set_parallel(false)
		tween.tween_callback(line.queue_free)


func spawn_holy_column(
	center_point: Vector2,
	tone: Color = Color("#fff0bd"),
	height: float = 520.0
) -> void:
	for i in range(5):
		var ray := ColorRect.new()
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ray.color = Color(tone, 0.10 + float(i) * 0.045)
		ray.size = Vector2(34.0 + float(i) * 22.0, height)
		ray.position = center_point - Vector2(ray.size.x * 0.5, height * 0.85)
		ray.pivot_offset = Vector2(ray.size.x * 0.5, height)
		effect_layer.add_child(ray)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ray, "scale:x", 1.0, 0.24).from(0.10)
		tween.tween_property(ray, "modulate:a", 0.0, 0.46).set_delay(0.12)
		tween.set_parallel(false)
		tween.tween_callback(ray.queue_free)

	spawn_gpu_sparks(center_point, tone, 62, 230.0)
	spawn_shader_wave(center_point, tone, 0.34)


func spawn_curse_chains(
	center_point: Vector2,
	tone: Color = Color("#b58ac9"),
	count: int = 7
) -> void:
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(1, count))
		var outer := center_point + Vector2(cos(angle), sin(angle)) * 330.0
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(tone, 0.58)
		line.antialiased = true

		var points := PackedVector2Array()
		for p in range(7):
			var t := float(p) / 6.0
			var point := outer.lerp(center_point, t)
			if p > 0 and p < 6:
				point += Vector2(randf_range(-18.0, 18.0), randf_range(-18.0, 18.0))
			points.append(point)
		line.points = points
		effect_layer.add_child(line)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(line, "modulate:a", 0.0, 0.46).set_delay(0.08)
		tween.tween_property(line, "width", 7.0, 0.30)
		tween.set_parallel(false)
		tween.tween_callback(line.queue_free)

	spawn_shader_wave(center_point, tone, 0.36)
	spawn_gpu_sparks(center_point, Color(tone, 0.76), 46, 240.0)


func spawn_water_bloom(
	center_point: Vector2,
	tone: Color = Color("#a9ddda"),
	count: int = 48
) -> void:
	for i in range(count):
		var start := center_point + Vector2(
			randf_range(-180.0, 180.0),
			randf_range(-30.0, 70.0)
		)
		spawn_rising_particle(
			start,
			Color(tone, randf_range(0.58, 0.94)),
			randf_range(110.0, 280.0),
			"・"
		)
	for r in range(3):
		spawn_ring(
			center_point,
			Color(tone, 0.48 - float(r) * 0.10),
			160.0 + float(r) * 100.0
		)


func spawn_moon_halo(
	center_point: Vector2,
	tone: Color,
	count: int = 4
) -> void:
	for i in range(count):
		spawn_ring(
			center_point,
			Color(tone, 0.62 - float(i) * 0.10),
			130.0 + float(i) * 84.0
		)
	spawn_shader_wave(center_point, tone, 0.34)


func spawn_barrier_dome(
	center_point: Vector2,
	tone: Color,
	radius: float = 210.0
) -> void:
	for i in range(4):
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.size = Vector2(radius * 2.0, radius * 1.15)
		ring.position = center_point - ring.size * 0.5
		ring.pivot_offset = ring.size * 0.5

		var style := StyleBoxFlat.new()
		style.bg_color = Color(tone, 0.025 + float(i) * 0.018)
		style.border_color = Color(tone, 0.38 - float(i) * 0.06)
		style.set_border_width_all(2)
		style.set_corner_radius_all(int(radius))
		ring.add_theme_stylebox_override("panel", style)
		effect_layer.add_child(ring)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(1.18, 1.18), 0.48).from(Vector2(0.72, 0.72))
		tween.tween_property(ring, "modulate:a", 0.0, 0.48)
		tween.set_parallel(false)
		tween.tween_callback(ring.queue_free)


func get_party_effect_center(
	char_name: String,
	fallback: Vector2
) -> Vector2:
	if party_cards.has(char_name):
		var card_data: Dictionary = party_cards[char_name]
		if card_data.has("panel"):
			var panel := card_data["panel"] as Control
			if panel != null and is_instance_valid(panel):
				return panel.global_position + panel.size * 0.5
	return fallback


func get_pixel_vfx_frame_roots() -> Array[String]:
	return [
		"res://assets/fx/pixel/Frames",
		"res://assets/fx/pixel/Pixel VFX Essentials/Frames",
		"res://assets/fx/Pixel VFX Essentials/Frames",
		"res://assets/fx/Frames"
	]


func get_pixel_vfx_sheet_roots() -> Array[String]:
	return [
		"res://assets/fx/pixel/Spritesheets",
		"res://assets/fx/pixel/Pixel VFX Essentials/Spritesheets",
		"res://assets/fx/Pixel VFX Essentials/Spritesheets",
		"res://assets/fx/Spritesheets"
	]


func build_pixel_vfx_frames(
	animation_path: String,
	fps: float
) -> SpriteFrames:
	var cache_key := animation_path + "|" + str(fps)
	if pixel_vfx_cache.has(cache_key):
		return pixel_vfx_cache[cache_key] as SpriteFrames

	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", false)
	frames.set_animation_speed("vfx", fps)

	# 連番PNG形式。
	for root in get_pixel_vfx_frame_roots():
		var base_path := root.path_join(animation_path)
		var frame_count := 0

		for i in range(1, 97):
			var path := base_path.path_join("frame%03d.png" % i)
			if not ResourceLoader.exists(path):
				break

			var texture := load(path) as Texture2D
			if texture != null:
				frames.add_frame("vfx", texture)
				frame_count += 1

		if frame_count > 0:
			pixel_vfx_cache[cache_key] = frames
			return frames

	# 横長/縦長のSpritesheet形式。
	for root in get_pixel_vfx_sheet_roots():
		var sheet_path := root.path_join(animation_path + ".png")
		if not ResourceLoader.exists(sheet_path):
			continue

		var sheet := load(sheet_path) as Texture2D
		if sheet == null:
			continue

		var width := sheet.get_width()
		var height := sheet.get_height()
		if width <= 0 or height <= 0:
			continue

		if width >= height and width % height == 0:
			var frame_size := height
			var count := int(width / frame_size)

			for i in range(count):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(
					float(i * frame_size),
					0.0,
					float(frame_size),
					float(frame_size)
				)
				frames.add_frame("vfx", atlas)

			pixel_vfx_cache[cache_key] = frames
			return frames

		if height > width and height % width == 0:
			var frame_size := width
			var count := int(height / frame_size)

			for i in range(count):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(
					0.0,
					float(i * frame_size),
					float(frame_size),
					float(frame_size)
				)
				frames.add_frame("vfx", atlas)

			pixel_vfx_cache[cache_key] = frames
			return frames

	return null


func play_pixel_vfx(
	animation_path: String,
	center_point: Vector2,
	scale_value: float = 5.0,
	fps: float = 18.0,
	tint: Color = Color.WHITE,
	rotation_value: float = 0.0
) -> void:
	var frames := build_pixel_vfx_frames(animation_path, fps)
	if frames == null:
		return
	if frames.get_frame_count("vfx") <= 0:
		return

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = "vfx"
	sprite.position = center_point
	sprite.scale = Vector2.ONE * scale_value
	sprite.rotation = rotation_value
	sprite.modulate = tint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.z_index = 40
	effect_layer.add_child(sprite)
	sprite.animation_finished.connect(sprite.queue_free)
	sprite.play("vfx")


func play_pixel_vfx_on_party(
	animation_path: String,
	scale_value: float = 3.0,
	fps: float = 18.0,
	tint: Color = Color.WHITE
) -> void:
	var viewport_size := get_viewport_rect().size
	for ally_name in party:
		if not party_state.has(ally_name):
			continue
		if int(party_state[ally_name].get("cur_hp", 0)) <= 0:
			continue

		var center_point := get_party_effect_center(
			ally_name,
			Vector2(viewport_size.x * 0.70, viewport_size.y * 0.80)
		)
		play_pixel_vfx(
			animation_path,
			center_point,
			scale_value,
			fps,
			tint
		)


func play_status_pixel_feedback(
	status_key: String,
	center_point: Vector2,
	is_enemy: bool
) -> void:
	match status_key:
		"blessing":
			play_pixel_vfx("Magic/Buff Up", center_point, 2.9, 20.0, Color("#ffe2a0"))
		"ward":
			play_pixel_vfx("Magic/Shield Bubble", center_point, 3.0, 18.0, Color("#c8e3ef"))
		"rage":
			play_pixel_vfx("Magic/Buff Up", center_point, 3.0, 20.0, Color("#ff9d83"))
		"poison":
			play_pixel_vfx("Magic/Poison Cloud", center_point, 2.8, 17.0, Color("#b890ca"))
		"burn":
			play_pixel_vfx("Fire/Ignite", center_point, 3.0, 20.0)
		"atk_down", "def_down":
			play_pixel_vfx("Magic/Debuff Down", center_point, 2.8, 20.0, Color("#b88bbf"))
		"seal":
			play_pixel_vfx("Magic/Dark Curse", center_point, 2.8, 18.0, Color("#a982b5"))

	if is_enemy:
		if status_key == "poison":
			play_pixel_vfx("Hit Sparks/Poison Hit", center_point, 2.4, 22.0)
		elif status_key == "burn":
			play_pixel_vfx("Hit Sparks/Fire Hit", center_point, 2.4, 22.0)


func play_pixel_skill_accent(
	skill_id: String,
	char_name: String,
	target_name: String,
	enemy_center: Vector2,
	party_center: Vector2
) -> void:
	var actor_center := get_party_effect_center(char_name, party_center)
	var ally_target_center := actor_center
	if target_name != "":
		ally_target_center = get_party_effect_center(target_name, actor_center)

	match skill_id:
		# 侍
		"samurai_moon_slash":
			play_pixel_vfx("Slashes/Wide Cleave", enemy_center, 5.2, 21.0, Color("#f2e3c5"))
			play_pixel_vfx("Hit Sparks/Slash Hit", enemy_center, 2.8, 23.0)
		"samurai_iai":
			play_pixel_vfx("Slashes/Katana Draw", enemy_center, 6.2, 20.0)
			play_pixel_vfx("Hit Sparks/Critical Star", enemy_center, 2.8, 22.0, Color("#ffe4ad"))
		"samurai_red_mist":
			play_pixel_vfx("Slashes/Dark Slash", enemy_center, 5.1, 20.0, Color("#d55f68"))
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 2.5, 20.0, Color("#b76572"))
		"samurai_swallow_break":
			play_pixel_vfx("Slashes/Double Slash", enemy_center, 5.4, 22.0)
			play_pixel_vfx("Hit Sparks/Parry Flash", enemy_center, 2.7, 22.0)
		"samurai_aftermoon":
			play_pixel_vfx("Slashes/Slash Left", enemy_center, 5.3, 21.0, Color("#e9d8b5"))
			play_pixel_vfx("Pickups and UI/Star Burst", enemy_center, 2.5, 19.0, Color("#e7d49f"))

		# 仙人
		"sennin_thunder":
			play_pixel_vfx("Lightning/Charge Up", enemy_center, 3.7, 19.0, Color("#d5efff"))
			play_pixel_vfx("Lightning/Thunder Impact", enemy_center, 5.7, 18.0)
		"sennin_moon_turn":
			play_pixel_vfx("Magic/Cast Circle", actor_center, 4.5, 17.0, Color("#b9dcf5"))
			play_pixel_vfx("Pickups and UI/Mana Orb", actor_center, 2.7, 18.0, Color("#c8e5f6"))
		"sennin_spring":
			play_pixel_vfx_on_party("Magic/Heal", 2.8, 19.0, Color("#b9e6dc"))
			play_pixel_vfx("Ambient/Waterfall Mist", party_center, 4.0, 15.0, Color("#c8eee7"))
		"sennin_wind_read":
			play_pixel_vfx_on_party("Magic/Buff Up", 2.4, 20.0, Color("#c9e5f3"))
			play_pixel_vfx("Magic/Wind Gust", party_center, 4.5, 17.0, Color("#d4edf7"))
		"sennin_moon_hold":
			play_pixel_vfx("Magic/Cast Circle", enemy_center, 4.4, 17.0, Color("#b3d5f1"))
			play_pixel_vfx("Lightning/Static Loop", enemy_center, 3.2, 18.0, Color("#d2e9fa"))

		# 傘使い
		"kasa_pierce":
			play_pixel_vfx("Slashes/Thrust", enemy_center, 5.0, 22.0, Color("#d9eef8"))
			play_pixel_vfx("Explosions/Shockwave", enemy_center, 3.1, 19.0, Color("#b7d4e4"))
		"kasa_counter":
			play_pixel_vfx("Magic/Shield Bubble", actor_center, 3.4, 18.0, Color("#bddbea"))
			play_pixel_vfx("Hit Sparks/Parry Flash", actor_center, 2.7, 22.0)
		"kasa_ward":
			play_pixel_vfx_on_party("Magic/Shield Bubble", 3.0, 18.0, Color("#b9d8e7"))
			play_pixel_vfx_on_party("Pickups and UI/Save Sparkle", 2.2, 18.0, Color("#d9edf5"))
		"kasa_rain_armor":
			play_pixel_vfx_on_party("Magic/Shield Bubble", 2.8, 18.0, Color("#b7d7e8"))
			play_pixel_vfx_on_party("Magic/Buff Up", 2.2, 20.0, Color("#c6e0ec"))
		"kasa_thunder_guard":
			play_pixel_vfx("Lightning/Storm Flash", enemy_center, 5.5, 18.0)
			play_pixel_vfx("Magic/Shield Bubble", actor_center, 3.0, 18.0, Color("#bdddea"))

		# 巫女
		"miko_heal":
			play_pixel_vfx("Magic/Heal", ally_target_center, 3.4, 19.0, Color("#fff0bc"))
			play_pixel_vfx("Pickups and UI/Heal Cross", ally_target_center, 2.6, 19.0, Color("#fff4ca"))
		"miko_cleanse":
			play_pixel_vfx_on_party("Magic/Holy Light", 2.9, 18.0, Color("#fff2c9"))
			play_pixel_vfx_on_party("Pickups and UI/Save Sparkle", 2.0, 18.0, Color("#f8e7b4"))
		"miko_bless":
			play_pixel_vfx_on_party("Magic/Buff Up", 2.9, 20.0, Color("#ffe19a"))
			play_pixel_vfx("Ambient/Sparkles Ambient", party_center, 4.0, 16.0, Color("#ffe7a9"))
		"miko_bell_guard":
			play_pixel_vfx("Magic/Shield Bubble", ally_target_center, 3.1, 18.0, Color("#f5e2a9"))
			play_pixel_vfx("Magic/Heal", ally_target_center, 2.6, 19.0, Color("#fff0bd"))
		"miko_divine_descent":
			play_pixel_vfx("Magic/Holy Light", party_center, 6.0, 17.0, Color("#ffe9a8"))
			play_pixel_vfx_on_party("Magic/Buff Up", 2.7, 20.0, Color("#ffe6a6"))
			play_pixel_vfx_on_party("Magic/Shield Bubble", 2.6, 18.0, Color("#fff0c0"))

		# 提灯使い
		"chochin_foxfire":
			play_pixel_vfx("Fire/Blue Flame", enemy_center, 5.3, 18.0)
			play_pixel_vfx("Hit Sparks/Fire Hit", enemy_center, 2.4, 22.0, Color("#8fdfff"))
		"chochin_lantern_drop":
			play_pixel_vfx("Explosions/Fireball Burst", enemy_center, 5.4, 21.0)
			play_pixel_vfx("Fire/Fire Puff", enemy_center, 4.0, 22.0)
		"chochin_dim":
			play_pixel_vfx("Fire/Blue Flame", enemy_center, 4.3, 18.0, Color("#8abfff"))
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 2.8, 20.0, Color("#b987a9"))
		"chochin_ember_step":
			play_pixel_vfx("Fire/Fire Trail", enemy_center, 5.0, 21.0)
			play_pixel_vfx("Fire/Ember Rise", enemy_center, 3.6, 18.0)
		"chochin_burst":
			play_pixel_vfx("Fire/Phoenix Flare", enemy_center, 6.4, 18.0)
			play_pixel_vfx("Explosions/Big Boom", enemy_center, 4.8, 20.0, Color("#ffc07c"))

		# 呪詛師
		"jusoshi_poison":
			play_pixel_vfx("Magic/Poison Cloud", enemy_center, 4.1, 17.0, Color("#ba8dcc"))
			play_pixel_vfx("Hit Sparks/Poison Hit", enemy_center, 2.7, 22.0)
		"jusoshi_bind":
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 4.4, 18.0, Color("#b788c7"))
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 2.8, 20.0, Color("#af78bd"))
		"jusoshi_grudge":
			play_pixel_vfx("Magic/Arcane Orb", enemy_center, 4.5, 18.0, Color("#b46fc4"))
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 4.0, 18.0, Color("#d19bdd"))
		"jusoshi_extend":
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 3.1, 20.0, Color("#b17bc0"))
			play_pixel_vfx("Smoke and Dust/Dissipate", enemy_center, 3.3, 19.0, Color("#9d6cac"))
		"jusoshi_abyss_mark":
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 4.8, 18.0, Color("#9e66b2"))
			play_pixel_vfx("Lightning/Shock Aura", enemy_center, 3.3, 18.0, Color("#b883c7"))

		# くノ一
		"kunoichi_shadow_bind":
			play_pixel_vfx("Slashes/Dagger Flick", enemy_center, 4.8, 23.0, Color("#d8e5ec"))
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 2.8, 19.0, Color("#8093a9"))
		"kunoichi_poison_star":
			play_pixel_vfx("Projectiles/Shuriken", enemy_center, 5.0, 22.0)
			play_pixel_vfx("Hit Sparks/Poison Hit", enemy_center, 2.7, 22.0)
		"kunoichi_mist_step":
			play_pixel_vfx("Magic/Teleport", actor_center, 3.8, 22.0, Color("#d8e8ee"))
			play_pixel_vfx("Smoke and Dust/Smoke Puff", actor_center, 3.1, 22.0, Color("#aeb9c0"))
		"kunoichi_ninja_return":
			play_pixel_vfx("Hit Sparks/Parry Flash", actor_center, 3.0, 23.0)
			play_pixel_vfx("Explosions/Smoke Burst", actor_center, 3.4, 20.0, Color("#c5cdd2"))
		"kunoichi_scatter_star":
			play_pixel_vfx("Projectiles/Shuriken", enemy_center, 5.4, 24.0)
			play_pixel_vfx("Slashes/Double Slash", enemy_center, 5.5, 20.0)
			play_pixel_vfx("Hit Sparks/Multi Hit", enemy_center, 2.8, 23.0)

		# 酒呑童子
		"shuten_oni_smash":
			play_pixel_vfx("Hit Sparks/Heavy Hit", enemy_center, 6.0, 18.0)
			play_pixel_vfx("Explosions/Shockwave", enemy_center, 4.4, 19.0, Color("#e7a17f"))
		"shuten_sake_flame":
			play_pixel_vfx("Fire/Fire Ring", enemy_center, 5.6, 18.0)
			play_pixel_vfx("Hit Sparks/Fire Hit", enemy_center, 2.8, 22.0)
		"shuten_drink_dry":
			play_pixel_vfx("Magic/Heal", actor_center, 3.1, 19.0, Color("#e5bf83"))
			play_pixel_vfx("Magic/Buff Up", actor_center, 3.0, 20.0, Color("#dc8b6f"))
		"shuten_drunk_barrage":
			play_pixel_vfx("Hit Sparks/Multi Hit", enemy_center, 4.2, 24.0, Color("#f0b08c"))
			play_pixel_vfx("Hit Sparks/Heavy Hit", enemy_center, 4.5, 19.0)
		"shuten_hyakki_feast":
			play_pixel_vfx_on_party("Magic/Buff Up", 2.8, 20.0, Color("#e6a27e"))
			play_pixel_vfx("Ambient/Embers Ambient", party_center, 4.2, 16.0, Color("#e7aa83"))

		# 神楽師
		"kagurashi_rhythm_dance":
			play_pixel_vfx_on_party("Magic/Buff Up", 2.6, 20.0, Color("#efc6df"))
			play_pixel_vfx("Ambient/Sparkles Ambient", party_center, 3.8, 16.0, Color("#f5d2e5"))
		"kagurashi_double_beat":
			play_pixel_vfx("Magic/Cast Circle", actor_center, 4.2, 18.0, Color("#efc6df"))
			play_pixel_vfx("Pickups and UI/Star Burst", actor_center, 2.7, 19.0, Color("#f3d4e6"))
		"kagurashi_repose":
			play_pixel_vfx_on_party("Magic/Heal", 2.7, 19.0, Color("#efd0e0"))
			play_pixel_vfx_on_party("Pickups and UI/Save Sparkle", 2.0, 18.0, Color("#f4dbe7"))
		"kagurashi_moon_call":
			play_pixel_vfx("Magic/Cast Circle", party_center, 4.8, 17.0, Color("#d8bce8"))
			play_pixel_vfx_on_party("Pickups and UI/Mana Orb", 2.5, 18.0, Color("#c9b8ed"))
		"kagurashi_wild_kagura":
			play_pixel_vfx("Magic/Holy Light", enemy_center, 5.8, 18.0, Color("#e4b7d8"))
			play_pixel_vfx("Explosions/Shockwave", enemy_center, 3.7, 19.0, Color("#d4a8cc"))

		# 猫又
		"nekomata_cat_fire":
			play_pixel_vfx("Fire/Blue Flame", enemy_center, 5.3, 18.0, Color("#a8eaff"))
			play_pixel_vfx("Hit Sparks/Fire Hit", enemy_center, 2.5, 22.0, Color("#a0e6e0"))
		"nekomata_twin_tail":
			play_pixel_vfx("Slashes/Triple Claw", enemy_center, 5.4, 20.0)
			play_pixel_vfx("Hit Sparks/Slash Hit", enemy_center, 2.7, 22.0, Color("#c9f4ef"))
		"nekomata_feint":
			play_pixel_vfx("Magic/Teleport", enemy_center, 5.0, 18.0, Color("#91d7cf"))
			play_pixel_vfx("Magic/Debuff Down", enemy_center, 2.8, 20.0, Color("#92b6b6"))
		"nekomata_soul_lick":
			play_pixel_vfx("Magic/Dark Curse", enemy_center, 3.5, 18.0, Color("#7fc9c1"))
			play_pixel_vfx("Magic/Heal", actor_center, 2.8, 19.0, Color("#a8e0d8"))
		"nekomata_bakeneko_dance":
			play_pixel_vfx("Magic/Summon", enemy_center, 6.0, 18.0, Color("#8fd7cf"))
			play_pixel_vfx("Fire/Blue Flame", enemy_center, 4.4, 19.0, Color("#9be5de"))
			play_pixel_vfx("Slashes/Triple Claw", enemy_center, 5.2, 21.0, Color("#d1fff9"))



func play_skill_motion(skill_id: String, char_name: String, target_name: String = "") -> void:
	var tone := get_skill_color(skill_id)
	var viewport_size := get_viewport_rect().size
	var enemy_center := Vector2(viewport_size.x * 0.43, viewport_size.y * 0.43)
	var party_center := Vector2(viewport_size.x * 0.57, viewport_size.y * 0.78)

	play_pixel_skill_accent(skill_id, char_name, target_name, enemy_center, party_center)

	match skill_id:
		# -----------------------------------------------------------
		# 侍
		# -----------------------------------------------------------
		"samurai_moon_slash":
			spawn_moon_halo(enemy_center, Color("#f0d6ae"), 3)
			spawn_ink_burst(enemy_center, Color("#bba17c"), 18)
			var used_slash := await play_external_slash_fx(
				"0",
				enemy_center,
				Vector2(1.70, 1.70),
				-0.18
			)
			if not used_slash:
				spawn_streak(
					enemy_center + Vector2(-360, -205),
					Vector2(720, 430),
					Color("#f5e5c8"),
					7.0
				)
			spawn_fullscreen_flash(Color("#fff1d2"), 0.20, 0.08)
			spawn_gpu_sparks(enemy_center, Color("#f2d6a3"), 54, 310.0)
			spawn_impact_glyph("月", enemy_center, Color("#f4ddba"), 132)
			await get_tree().create_timer(0.18).timeout

		"samurai_iai":
			await spawn_iai_sequence(enemy_center, tone)
			await play_external_slash_fx(
				"diagonal0",
				enemy_center,
				Vector2(1.90, 1.90),
				0.0
			)
			spawn_ink_burst(enemy_center, Color("#e3d4bb"), 26)
			spawn_gpu_sparks(enemy_center, Color("#fff3dd"), 64, 360.0)
			spawn_fullscreen_flash(Color("#fffaf0"), 0.36, 0.09)
			await get_tree().create_timer(0.16).timeout

		"samurai_red_mist":
			await play_external_slash_fx(
				"2",
				enemy_center,
				Vector2(1.65, 1.65),
				0.14
			)
			spawn_ink_burst(enemy_center, Color("#9e202b"), 34)
			spawn_fire_particles(enemy_center, 44, 160.0, false)
			spawn_ring(enemy_center, Color("#c23a45aa"), 255.0)
			spawn_impact_glyph("血", enemy_center, Color("#cb4652"), 148)
			await get_tree().create_timer(0.20).timeout

		"samurai_swallow_break":
			await play_external_slash_fx(
				"3",
				enemy_center,
				Vector2(1.60, 1.60),
				-0.28
			)
			spawn_streak(
				enemy_center + Vector2(300, -170),
				Vector2(-600, 340),
				Color("#f7e5c7"),
				5.0
			)
			spawn_streak(
				enemy_center + Vector2(-290, -165),
				Vector2(580, 330),
				Color("#d9bc8f"),
				5.0
			)
			spawn_gpu_sparks(enemy_center, Color("#f7e5c7"), 70, 390.0)
			spawn_impact_glyph("燕", enemy_center, Color("#f0d7ad"), 148)
			await get_tree().create_timer(0.18).timeout

		"samurai_aftermoon":
			spawn_moon_halo(enemy_center, Color("#d9c69f"), 4)
			await play_external_slash_fx(
				"4",
				enemy_center,
				Vector2(1.70, 1.70),
				0.10
			)
			spawn_ink_burst(enemy_center, Color("#736551"), 20)
			spawn_particle_burst(enemy_center, Color("#e6d5b5"), 32, 220.0, "・")
			spawn_impact_glyph("残", enemy_center, Color("#e5d4b4"), 154)
			await get_tree().create_timer(0.20).timeout

		# -----------------------------------------------------------
		# 仙人
		# -----------------------------------------------------------
		"sennin_thunder":
			spawn_moon_halo(enemy_center, Color("#8fc7ef"), 2)
			spawn_lightning_storm(enemy_center, 7, Color("#d9efff"))
			spawn_impact_glyph("雷", enemy_center, Color("#d9efff"), 148)
			shake_amount = maxf(shake_amount, 9.0)
			await get_tree().create_timer(0.21).timeout

		"sennin_moon_turn":
			var moon_center := Vector2(viewport_size.x * 0.50, viewport_size.y * 0.42)
			spawn_moon_halo(moon_center, Color("#a9d8ff"), 6)
			spawn_wind_arc(moon_center, Color("#d6ebff"), 5)
			spawn_particle_burst(moon_center, Color("#c4e4ff"), 40, 300.0, "・")
			spawn_impact_glyph("月転", moon_center, Color("#d7ecff"), 92)
			await get_tree().create_timer(0.24).timeout

		"sennin_spring":
			spawn_water_bloom(party_center, Color("#a9ddda"), 62)
			spawn_holy_column(party_center, Color("#c7ece7"), 360.0)
			spawn_impact_glyph("泉", party_center, Color("#d7f2ed"), 138)
			await get_tree().create_timer(0.24).timeout

		"sennin_wind_read":
			spawn_wind_arc(party_center, Color("#cfe6f6"), 10)
			spawn_gpu_sparks(party_center, Color("#e2f2ff"), 42, 240.0)
			spawn_particle_burst(party_center, Color("#cfe6f6"), 30, 250.0, "・")
			spawn_impact_glyph("風", party_center, Color("#dff3ff"), 148)
			await get_tree().create_timer(0.20).timeout

		"sennin_moon_hold":
			spawn_moon_halo(enemy_center, Color("#b8d8f5"), 6)
			spawn_curse_chains(enemy_center, Color("#9fc8e8"), 6)
			spawn_impact_glyph("留", enemy_center, Color("#d4e7fa"), 154)
			await get_tree().create_timer(0.22).timeout

		# -----------------------------------------------------------
		# 傘使い
		# -----------------------------------------------------------
		"kasa_pierce":
			spawn_rain_field(enemy_center, 760.0, 76, Color("#93bed9"))
			await get_tree().create_timer(0.07).timeout
			spawn_vertical_impact(enemy_center, Color("#d6efff"), 540.0, 42.0)
			spawn_ring(enemy_center, Color("#b7d8ea"), 175.0)
			spawn_gpu_sparks(enemy_center, Color("#d7f1ff"), 54, 300.0)
			spawn_impact_glyph("穿", enemy_center, Color("#d6efff"), 145)
			await get_tree().create_timer(0.21).timeout

		"kasa_counter":
			spawn_rain_field(party_center, 470.0, 34, Color("#729bb8"))
			spawn_barrier_dome(party_center, Color("#b7d5e8"), 190.0)
			spawn_ring(party_center, Color("#d3ebf7"), 160.0)
			spawn_impact_glyph("返", party_center, Color("#d3ebf7"), 138)
			await get_tree().create_timer(0.20).timeout

		"kasa_ward":
			spawn_rain_field(party_center, 850.0, 82, Color("#7fa9c5"))
			spawn_barrier_dome(party_center, Color("#9ec5da"), 310.0)
			for party_name in party:
				if party_cards.has(party_name):
					var card_panel: PanelContainer = party_cards[party_name]["panel"] as PanelContainer
					var center_pos := card_panel.global_position + card_panel.size * 0.5
					spawn_ring(center_pos, Color("#b8d8e9aa"), 112.0)
			spawn_impact_glyph("陣", party_center, Color("#d5edf8"), 152)
			await get_tree().create_timer(0.24).timeout

		"kasa_rain_armor":
			spawn_rain_field(party_center, 900.0, 94, Color("#8fb5cf"))
			for party_name in party:
				if party_cards.has(party_name):
					var card_panel: PanelContainer = party_cards[party_name]["panel"] as PanelContainer
					var center_pos := card_panel.global_position + card_panel.size * 0.5
					spawn_barrier_dome(center_pos, Color("#b6d8ea"), 92.0)
					spawn_gpu_sparks(center_pos, Color("#d5edf7"), 16, 100.0)
			spawn_impact_glyph("鎧", party_center, Color("#d7edf7"), 145)
			await get_tree().create_timer(0.22).timeout

		"kasa_thunder_guard":
			spawn_rain_field(enemy_center, 720.0, 58, Color("#89b6d0"))
			await get_tree().create_timer(0.05).timeout
			spawn_lightning_storm(enemy_center, 5, Color("#e0f5ff"))
			spawn_barrier_dome(party_center, Color("#91bdd4"), 180.0)
			spawn_impact_glyph("雷", enemy_center, Color("#e4f7ff"), 150)
			await get_tree().create_timer(0.21).timeout

		# -----------------------------------------------------------
		# 巫女
		# -----------------------------------------------------------
		"miko_heal":
			spawn_holy_column(party_center, Color("#fff0bd"), 420.0)
			spawn_particle_burst(party_center, Color("#f7e5aa"), 54, 230.0, "✦")
			spawn_ring(party_center, Color("#f3dfa188"), 250.0)
			spawn_impact_glyph("祓", party_center, Color("#fff0bd"), 145)
			await get_tree().create_timer(0.22).timeout

		"miko_cleanse":
			spawn_fullscreen_flash(Color("#fff8dc"), 0.15, 0.11)
			for party_name in party:
				if party_cards.has(party_name):
					var card_panel: PanelContainer = party_cards[party_name]["panel"] as PanelContainer
					var center_pos := card_panel.global_position + card_panel.size * 0.5
					spawn_holy_column(center_pos, Color("#fff2c7"), 250.0)
					spawn_particle_burst(center_pos, Color("#f7e8b0"), 22, 125.0, "✦")
			spawn_impact_glyph("禊", party_center, Color("#fff0c4"), 150)
			await get_tree().create_timer(0.24).timeout

		"miko_bless":
			spawn_moon_halo(party_center, Color("#e8cc78"), 5)
			spawn_holy_column(party_center, Color("#ffe69b"), 470.0)
			spawn_particle_burst(party_center, Color("#f0d98c"), 64, 360.0, "✦")
			spawn_impact_glyph("祝", party_center, Color("#ffeaa9"), 158)
			await get_tree().create_timer(0.25).timeout

		"miko_bell_guard":
			spawn_barrier_dome(party_center, Color("#f3dfa1"), 170.0)
			spawn_holy_column(party_center, Color("#fff2c7"), 300.0)
			spawn_particle_burst(party_center, Color("#f8e8ae"), 42, 180.0, "✦")
			spawn_impact_glyph("鈴", party_center, Color("#fff2c7"), 144)
			await get_tree().create_timer(0.21).timeout

		"miko_divine_descent":
			spawn_fullscreen_flash(Color("#fff4cf"), 0.18, 0.10)
			spawn_holy_column(party_center, Color("#fff1b5"), 620.0)
			spawn_moon_halo(party_center, Color("#efd67f"), 7)
			spawn_gpu_sparks(party_center, Color("#fff0bd"), 90, 390.0)
			spawn_particle_burst(party_center, Color("#fff4cf"), 70, 420.0, "✦")
			spawn_impact_glyph("神", party_center, Color("#fff2bd"), 188)
			await get_tree().create_timer(0.28).timeout

		# -----------------------------------------------------------
		# 提灯使い - 炎を明確に主役にする
		# -----------------------------------------------------------
		"chochin_foxfire":
			for i in range(5):
				var angle := TAU * float(i) / 5.0
				var flame_pos := enemy_center + Vector2(cos(angle), sin(angle)) * 145.0
				spawn_fire_column(flame_pos, 155.0, 58.0, true)
			await get_tree().create_timer(0.10).timeout
			spawn_fire_column(enemy_center, 330.0, 115.0, true)
			spawn_shader_wave(enemy_center, Color("#4b86e8"), 0.32)
			spawn_impact_glyph("狐", enemy_center, Color("#a8e8ff"), 154)
			await get_tree().create_timer(0.24).timeout

		"chochin_lantern_drop":
			spawn_impact_glyph("灯", enemy_center + Vector2(0, -210), Color("#ff8f58"), 176)
			await get_tree().create_timer(0.10).timeout
			spawn_fire_column(enemy_center, 610.0, 180.0, false)
			spawn_fire_particles(enemy_center, 110, 360.0, false)
			spawn_fullscreen_flash(Color("#ff9d5c"), 0.25, 0.09)
			spawn_shader_wave(enemy_center, Color("#e34f2f"), 0.38)
			shake_amount = maxf(shake_amount, 11.0)
			await get_tree().create_timer(0.26).timeout

		"chochin_dim":
			for i in range(7):
				var angle := TAU * float(i) / 7.0
				var flame_pos := enemy_center + Vector2(cos(angle), sin(angle)) * 185.0
				spawn_fire_particles(flame_pos, 18, 95.0, true)
			spawn_curse_chains(enemy_center, Color("#7d5075"), 5)
			spawn_shader_wave(enemy_center, Color("#7f4150"), 0.30)
			spawn_impact_glyph("迷", enemy_center, Color("#cb766b"), 148)
			await get_tree().create_timer(0.22).timeout

		"chochin_ember_step":
			spawn_fire_particles(enemy_center, 88, 250.0, true)
			for i in range(4):
				var step_pos := enemy_center + Vector2(-210.0 + float(i) * 140.0, 90.0 - float(i % 2) * 55.0)
				spawn_fire_column(step_pos, 210.0, 70.0, i % 2 == 0)
			spawn_shader_wave(enemy_center, Color("#d06d48"), 0.32)
			spawn_impact_glyph("鬼", enemy_center, Color("#ffc082"), 152)
			await get_tree().create_timer(0.24).timeout

		"chochin_burst":
			spawn_fire_column(enemy_center, 680.0, 250.0, false)
			spawn_fire_particles(enemy_center, 150, 430.0, false)
			spawn_gpu_sparks(enemy_center, Color("#ffd07f"), 96, 440.0)
			spawn_fullscreen_flash(Color("#ffb070"), 0.34, 0.10)
			spawn_shader_wave(enemy_center, Color("#e9472b"), 0.44)
			spawn_impact_glyph("爆", enemy_center, Color("#ffd08a"), 190)
			shake_amount = maxf(shake_amount, 15.0)
			await get_tree().create_timer(0.30).timeout

		# -----------------------------------------------------------
		# 呪詛師
		# -----------------------------------------------------------
		"jusoshi_poison":
			spawn_curse_chains(enemy_center, Color("#9b6ab1"), 6)
			spawn_particle_burst(enemy_center, Color("#9c6aad"), 54, 260.0, "呪")
			spawn_shader_wave(enemy_center, Color("#7d4b91"), 0.36)
			spawn_impact_glyph("蝕", enemy_center, Color("#c191d1"), 154)
			await get_tree().create_timer(0.23).timeout

		"jusoshi_bind":
			spawn_curse_chains(enemy_center, Color("#c4a4cf"), 10)
			for i in range(3):
				spawn_ring(enemy_center, Color("#8b6b9888"), 170.0 + float(i) * 72.0)
			spawn_impact_glyph("縛", enemy_center, Color("#d2b4dc"), 158)
			await get_tree().create_timer(0.23).timeout

		"jusoshi_grudge":
			var curse_count := maxi(1, count_enemy_negative_statuses())
			spawn_curse_chains(enemy_center, Color("#a46ab8"), 7 + curse_count)
			spawn_particle_burst(
				enemy_center,
				Color("#a36db7"),
				56 + curse_count * 10,
				330.0,
				"怨"
			)
			spawn_fullscreen_flash(Color("#6f367e"), 0.19, 0.10)
			spawn_impact_glyph("怨", enemy_center, Color("#d5a8e2"), 184)
			await get_tree().create_timer(0.27).timeout

		"jusoshi_extend":
			spawn_curse_chains(enemy_center, Color("#a775b8"), 8)
			spawn_moon_halo(enemy_center, Color("#7d4f8c"), 4)
			spawn_particle_burst(enemy_center, Color("#b88ac9"), 46, 245.0, "呪")
			spawn_impact_glyph("継", enemy_center, Color("#d4a8df"), 156)
			await get_tree().create_timer(0.23).timeout

		"jusoshi_abyss_mark":
			for i in range(8):
				spawn_ring(
					enemy_center,
					Color("#6d3a7a", 0.18 + float(i) * 0.045),
					80.0 + float(i) * 42.0
				)
			spawn_curse_chains(enemy_center, Color("#b777c8"), 12)
			spawn_gpu_sparks(enemy_center, Color("#b777c8"), 82, 350.0)
			spawn_fullscreen_flash(Color("#5c2d68"), 0.18, 0.10)
			spawn_impact_glyph("奈", enemy_center, Color("#ddaee8"), 194)
			await get_tree().create_timer(0.29).timeout

		"kunoichi_shadow_bind":
			spawn_streak(enemy_center + Vector2(-250, 0), Vector2(500, 0), Color("#b5cad8"), 3.0)
			spawn_curse_chains(enemy_center, Color("#829aaa"), 5)
			spawn_impact_glyph("影", enemy_center, Color("#c7d5df"), 142)
			await get_tree().create_timer(0.18).timeout

		"kunoichi_poison_star":
			spawn_particle_burst(enemy_center, Color("#9d74ad"), 38, 240.0, "・")
			spawn_ink_burst(enemy_center, Color("#66747d"), 22)
			spawn_impact_glyph("毒", enemy_center, Color("#c4a1d0"), 138)
			await get_tree().create_timer(0.18).timeout

		"kunoichi_mist_step":
			spawn_wind_arc(enemy_center, Color("#c7d9e4"), 7)
			spawn_particle_burst(enemy_center, Color("#bfcbd2"), 28, 180.0, "・")
			spawn_impact_glyph("霞", enemy_center, Color("#d9e3e9"), 134)
			await get_tree().create_timer(0.16).timeout

		"kunoichi_ninja_return":
			spawn_barrier_dome(party_center, Color("#aabfc9"), 150.0)
			spawn_wind_arc(party_center, Color("#c8d8df"), 5)
			spawn_impact_glyph("忍", party_center, Color("#dce5e9"), 140)
			await get_tree().create_timer(0.18).timeout

		"kunoichi_scatter_star":
			for i in range(8):
				spawn_streak(enemy_center + Vector2(randf_range(-260, 260), randf_range(-190, 190)), Vector2(randf_range(-150, 150), randf_range(-120, 120)), Color("#d5e0e7"), 2.0)
			spawn_gpu_sparks(enemy_center, Color("#e8eff3"), 62, 330.0)
			spawn_impact_glyph("星", enemy_center, Color("#e8eff3"), 150)
			await get_tree().create_timer(0.22).timeout

		"shuten_oni_smash":
			spawn_vertical_impact(enemy_center, Color("#d56c56"), 520.0, 100.0)
			spawn_gpu_sparks(enemy_center, Color("#efaa78"), 72, 390.0)
			spawn_shader_wave(enemy_center, Color("#a64034"), 0.42)
			spawn_impact_glyph("鬼", enemy_center, Color("#e6866d"), 170)
			shake_amount = maxf(shake_amount, 12.0)
			await get_tree().create_timer(0.24).timeout

		"shuten_sake_flame":
			spawn_fire_column(enemy_center, 410.0, 150.0, false)
			spawn_fire_particles(enemy_center, 70, 260.0, false)
			spawn_impact_glyph("酒", enemy_center, Color("#ef9a68"), 154)
			await get_tree().create_timer(0.22).timeout

		"shuten_drink_dry":
			spawn_ring(party_center, Color("#d59b71aa"), 190.0)
			spawn_particle_burst(party_center, Color("#e5b087"), 40, 190.0, "・")
			spawn_impact_glyph("呑", party_center, Color("#efbd91"), 152)
			await get_tree().create_timer(0.18).timeout

		"shuten_drunk_barrage":
			for i in range(5):
				spawn_vertical_impact(enemy_center + Vector2(randf_range(-120,120), randf_range(-70,70)), Color("#cf5f51"), 260.0, 46.0)
			spawn_gpu_sparks(enemy_center, Color("#f0a070"), 88, 400.0)
			spawn_impact_glyph("酔", enemy_center, Color("#e87a67"), 170)
			shake_amount = maxf(shake_amount, 13.0)
			await get_tree().create_timer(0.26).timeout

		"shuten_hyakki_feast":
			spawn_moon_halo(party_center, Color("#bd6d58"), 5)
			spawn_fire_particles(party_center, 62, 230.0, false)
			spawn_impact_glyph("宴", party_center, Color("#e8a47f"), 165)
			await get_tree().create_timer(0.22).timeout

		"kagurashi_rhythm_dance":
			spawn_wind_arc(party_center, Color("#e2bed8"), 8)
			spawn_particle_burst(party_center, Color("#f0cfe4"), 52, 260.0, "✦")
			spawn_impact_glyph("拍", party_center, Color("#f0cfe4"), 150)
			await get_tree().create_timer(0.20).timeout

		"kagurashi_double_beat":
			for i in range(4):
				spawn_ring(party_center, Color("#dfb4d2", 0.52-float(i)*0.08), 120.0+float(i)*80.0)
			spawn_impact_glyph("重", party_center, Color("#ecc6df"), 154)
			await get_tree().create_timer(0.20).timeout

		"kagurashi_repose":
			spawn_holy_column(party_center, Color("#f2d8e8"), 390.0)
			spawn_water_bloom(party_center, Color("#d5c4df"), 42)
			spawn_impact_glyph("鎮", party_center, Color("#f0d5e7"), 150)
			await get_tree().create_timer(0.22).timeout

		"kagurashi_moon_call":
			spawn_moon_halo(party_center, Color("#e1c3df"), 7)
			spawn_particle_burst(party_center, Color("#f1d8ec"), 54, 320.0, "✦")
			spawn_impact_glyph("招", party_center, Color("#f0d5e9"), 158)
			await get_tree().create_timer(0.23).timeout

		"kagurashi_wild_kagura":
			spawn_holy_column(enemy_center, Color("#eac1dd"), 500.0)
			spawn_wind_arc(enemy_center, Color("#d6a8cb"), 10)
			spawn_gpu_sparks(enemy_center, Color("#f0c9e2"), 76, 360.0)
			spawn_impact_glyph("荒", enemy_center, Color("#efc5df"), 174)
			await get_tree().create_timer(0.25).timeout

		"nekomata_cat_fire":
			spawn_fire_column(enemy_center, 300.0, 100.0, true)
			spawn_fire_particles(enemy_center, 58, 210.0, true)
			spawn_impact_glyph("猫", enemy_center, Color("#a8edf0"), 154)
			await get_tree().create_timer(0.21).timeout

		"nekomata_twin_tail":
			spawn_streak(enemy_center + Vector2(-250,-150), Vector2(500,300), Color("#a9ddd6"), 5.0)
			spawn_streak(enemy_center + Vector2(250,-150), Vector2(-500,300), Color("#7fc4bf"), 5.0)
			spawn_gpu_sparks(enemy_center, Color("#b5e6df"), 48, 280.0)
			spawn_impact_glyph("尾", enemy_center, Color("#b5e6df"), 150)
			await get_tree().create_timer(0.20).timeout

		"nekomata_feint":
			spawn_wind_arc(enemy_center, Color("#8fd3cc"), 6)
			spawn_shader_wave(enemy_center, Color("#659f9a"), 0.33)
			spawn_impact_glyph("騙", enemy_center, Color("#a9ddd6"), 144)
			await get_tree().create_timer(0.18).timeout

		"nekomata_soul_lick":
			spawn_curse_chains(enemy_center, Color("#759e9c"), 5)
			spawn_particle_burst(party_center, Color("#9bd8d0"), 36, 170.0, "・")
			spawn_impact_glyph("魂", enemy_center, Color("#b3e5df"), 152)
			await get_tree().create_timer(0.21).timeout

		"nekomata_bakeneko_dance":
			for i in range(5):
				var angle := TAU*float(i)/5.0
				spawn_fire_column(enemy_center+Vector2(cos(angle),sin(angle))*155.0, 170.0, 55.0, true)
			spawn_curse_chains(enemy_center, Color("#6eaaa4"), 7)
			spawn_impact_glyph("化", enemy_center, Color("#b1e5df"), 180)
			await get_tree().create_timer(0.26).timeout

		_:
			# 未定義技だけ最低限。通常技はここへ来ないよう全30技を個別定義する。
			spawn_shader_wave(enemy_center, tone, 0.24)
			spawn_gpu_sparks(enemy_center, tone, 30, 180.0)
			await get_tree().create_timer(0.15).timeout


func play_character_attack_fx(char_name: String) -> void:
	# 通常攻撃は意図的に簡素。
	# 特技との差を出すため、画面全体のShaderや大量Particleは使わない。
	var viewport_size := get_viewport_rect().size
	var center := Vector2(viewport_size.x * 0.43, viewport_size.y * 0.43)
	var slug := str(CHARACTERS[char_name]["slug"])

	match slug:
		"samurai":
			play_external_slash_fx("1", center, Vector2(1.18, 1.18), -0.08)
			spawn_streak(center + Vector2(-190, -90), Vector2(380, 190), Color("#e7cfaa"), 3.0)
		"sennin":
			spawn_lightning_bolt(center + Vector2(0, -180), center, Color("#b8ddf5"), 3.0, 7)
		"kasa":
			spawn_ring(center, Color("#8fb5cf77"), 110.0)
		"miko":
			spawn_particle_burst(center, Color("#f1d999"), 8, 80.0, "・")
		"chochin":
			spawn_fire_particles(center, 16, 90.0, false)
		"kunoichi":
			play_pixel_vfx("Projectiles/Shuriken", center, 3.8, 22.0)
		"shuten":
			play_pixel_vfx("Hit Sparks/Heavy Hit", center, 4.1, 18.0)
		"kagurashi":
			spawn_particle_burst(center, Color("#e1bad5"), 10, 90.0, "✦")
		"nekomata":
			play_pixel_vfx("Slashes/Dagger Flick", center, 3.8, 20.0, Color("#a8ddd7"))
		_:
			spawn_particle_burst(center, Color("#b58ac9"), 9, 80.0, "・")


func spawn_streak(origin: Vector2, vector: Vector2, color: Color, width: float) -> void:
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.color = color
	line.position = origin
	line.size = Vector2(vector.length(), width)
	line.rotation = vector.angle()
	line.pivot_offset = Vector2(0, width * 0.5)
	effect_layer.add_child(line)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(line, "modulate:a", 0.0, 0.28)
	tween.tween_property(line, "scale:x", 1.18, 0.28).from(0.15)
	tween.set_parallel(false)
	tween.tween_callback(line.queue_free)


func spawn_ring(center: Vector2, color: Color, diameter: float) -> void:
	var ring := Panel.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.size = Vector2(diameter, diameter)
	ring.position = center - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(diameter * 0.5))
	ring.add_theme_stylebox_override("panel", style)
	effect_layer.add_child(ring)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.65, 1.65), 0.44).from(Vector2(0.35, 0.35))
	tween.tween_property(ring, "modulate:a", 0.0, 0.44)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)


func spawn_particle_burst(center: Vector2, color: Color, count: int, radius: float, glyph: String) -> void:
	for i in range(count):
		var particle := Label.new()
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.text = glyph
		particle.position = center
		particle.add_theme_font_size_override("font_size", 8 + (i % 5) * 2)
		particle.add_theme_color_override("font_color", Color(color, 0.88))
		effect_layer.add_child(particle)

		var angle := randf_range(0.0, TAU)
		var distance := randf_range(radius * 0.35, radius)
		var destination := center + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", destination, randf_range(0.34, 0.52))
		tween.tween_property(particle, "modulate:a", 0.0, 0.52)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)


func spawn_impact_glyph(
	glyph_text: String,
	center_point: Vector2,
	color: Color,
	font_size: int
) -> void:
	var glyph := make_label(glyph_text, font_size, color)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.size = Vector2(360, 220)
	glyph.position = center_point - glyph.size * 0.5
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_color_override("font_outline_color", Color("#07070a"))
	glyph.add_theme_constant_override("outline_size", 8)
	glyph.pivot_offset = glyph.size * 0.5
	effect_layer.add_child(glyph)

	glyph.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(glyph, "modulate:a", 1.0, 0.045)
	tween.parallel().tween_property(glyph, "scale", Vector2.ONE, 0.11).from(Vector2(1.55, 0.62))
	tween.tween_interval(0.08)
	tween.tween_property(glyph, "modulate:a", 0.0, 0.18)
	tween.parallel().tween_property(glyph, "scale", Vector2(1.16, 1.16), 0.18)
	tween.tween_callback(glyph.queue_free)


func spawn_fullscreen_flash(
	color: Color,
	max_alpha: float,
	duration: float
) -> void:
	var flash := ColorRect.new()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(color.r, color.g, color.b, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(flash)

	var tween := create_tween()
	tween.tween_property(
		flash,
		"color:a",
		max_alpha,
		maxf(0.015, duration * 0.35)
	)
	tween.tween_property(
		flash,
		"color:a",
		0.0,
		maxf(0.025, duration * 0.65)
	)
	tween.tween_callback(flash.queue_free)


func spawn_vertical_impact(
	center_point: Vector2,
	color: Color,
	height: float,
	width: float
) -> void:
	var beam := ColorRect.new()
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.color = Color(color, 0.88)
	beam.size = Vector2(width, height)
	beam.position = center_point - Vector2(width * 0.5, height * 0.85)
	beam.pivot_offset = Vector2(width * 0.5, height)
	effect_layer.add_child(beam)

	beam.scale = Vector2(0.15, 1.0)
	var tween := create_tween()
	tween.tween_property(beam, "scale:x", 1.0, 0.055)
	tween.tween_property(beam, "modulate:a", 0.0, 0.16)
	tween.tween_callback(beam.queue_free)


func spawn_rising_particle(
	start_point: Vector2,
	color: Color,
	rise_amount: float,
	symbol: String
) -> void:
	var particle := Label.new()
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle.text = symbol
	particle.position = start_point
	particle.add_theme_font_size_override("font_size", randi_range(9, 17))
	particle.add_theme_color_override("font_color", Color(color, randf_range(0.55, 0.95)))
	effect_layer.add_child(particle)

	var destination := start_point + Vector2(
		randf_range(-35.0, 35.0),
		-rise_amount
	)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position", destination, randf_range(0.42, 0.72))
	tween.tween_property(particle, "modulate:a", 0.0, 0.72).set_delay(0.18)
	tween.set_parallel(false)
	tween.tween_callback(particle.queue_free)


func spawn_orbiting_symbols(
	center_point: Vector2,
	color: Color,
	symbol: String,
	count: int,
	radius: float
) -> void:
	for i in range(count):
		var angle := TAU * float(i) / float(maxi(1, count))
		var symbol_label := make_label(symbol, 18 + (i % 3) * 4, Color(color, 0.90))
		symbol_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		symbol_label.size = Vector2(40, 40)
		symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol_label.position = center_point + Vector2(cos(angle), sin(angle)) * radius - symbol_label.size * 0.5
		effect_layer.add_child(symbol_label)

		var destination := center_point - symbol_label.size * 0.5
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(symbol_label, "position", destination, 0.34 + float(i) * 0.012)
		tween.tween_property(symbol_label, "rotation", angle + PI, 0.34 + float(i) * 0.012)
		tween.tween_property(symbol_label, "modulate:a", 0.0, 0.18).set_delay(0.24)
		tween.set_parallel(false)
		tween.tween_callback(symbol_label.queue_free)


func spawn_iai_sequence(center_point: Vector2, tone: Color) -> void:
	# 居合だけは「静止→一本線→爆発」にする。
	var darkness := ColorRect.new()
	darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	darkness.color = Color(0.0, 0.0, 0.0, 0.0)
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(darkness)

	var fade_in := create_tween()
	fade_in.tween_property(darkness, "color:a", 0.78, 0.055)
	await fade_in.finished

	spawn_impact_glyph("朔", center_point, Color(tone, 0.20), 170)
	await get_tree().create_timer(0.095).timeout

	spawn_streak(
		center_point + Vector2(-390, -4),
		Vector2(780, 8),
		Color("#f8f4e8"),
		2.0
	)

	await get_tree().create_timer(0.095).timeout

	spawn_streak(
		center_point + Vector2(-430, -32),
		Vector2(860, 78),
		tone,
		8.0
	)
	spawn_streak(
		center_point + Vector2(-410, 28),
		Vector2(820, -64),
		Color(tone, 0.52),
		17.0
	)
	spawn_fullscreen_flash(Color("#fff7df"), 0.40, 0.095)
	shake_amount = maxf(shake_amount, 13.0)

	var fade_out := create_tween()
	fade_out.tween_property(darkness, "color:a", 0.0, 0.14)
	fade_out.tween_callback(darkness.queue_free)
	await get_tree().create_timer(0.15).timeout


func play_player_break_banner(char_name: String) -> void:
	var label := make_label("崩壊　" + char_name, 46, Color("#dc727a"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-290, 120)
	label.size = Vector2(580, 74)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#160608"))
	label.add_theme_constant_override("outline_size", 9)
	effect_layer.add_child(label)
	label.pivot_offset = label.size * 0.5
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.10).from(Vector2(1.42, 0.72))
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.06).from(0.0)
	tween.tween_interval(0.28)
	tween.tween_property(label, "modulate:a", 0.0, 0.20)
	tween.tween_callback(label.queue_free)


func play_lunar_combo_banner(combo_name: String) -> void:
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.025, 0.52)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var small := make_label("月　奏", 22, MOON_COLORS[moon_index])
	small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(small)
	var main := make_label(combo_name, 52, COL_GOLD_BRIGHT)
	main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_theme_color_override("font_outline_color", Color("#08080b"))
	main.add_theme_constant_override("outline_size", 9)
	v.add_child(main)

	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.08)
	tween.tween_interval(0.34)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	tween.tween_callback(overlay.queue_free)


func get_ultimate_sigil(char_name: String) -> String:
	match char_name:
		"侍": return "斬"
		"仙人": return "天"
		"傘使い": return "雨"
		"巫女": return "神"
		"提灯使い": return "灯"
		"呪詛師": return "怨"
		"くノ一": return "影"
		"酒呑童子": return "鬼"
		"神楽師": return "舞"
		"猫又": return "妖"
		_: return "月"


func get_ultimate_subtitle(char_name: String) -> String:
	match char_name:
		"侍": return "月を断つ一太刀"
		"仙人": return "九天を巡る月輪"
		"傘使い": return "八重に降る守護の時雨"
		"巫女": return "天照へ捧ぐ大祓"
		"提灯使い": return "百鬼を照らす妖火"
		"呪詛師": return "百の怨みを月へ葬る"
		"くノ一": return "月影に千の刃を隠す"
		"酒呑童子": return "鬼宴、月まで呑み干す"
		"神楽師": return "八百万を一夜へ招く"
		"猫又": return "双月に妖火が踊る"
		_: return "月光を極技へ変える"


func show_lunar_ultimate_cut_in(char_name: String, ultimate_name: String) -> void:
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.002, 0.003, 0.006, 0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var viewport_size := get_viewport_rect().size
	var tone := MOON_COLORS[moon_index]
	var center_point := viewport_size * 0.5

	# 背景の墨筋。人物絵を出さず、文字と月・墨で必殺感を作る。
	for i in range(9):
		var stroke := ColorRect.new()
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stroke.color = Color(tone, 0.045 + float(i % 3) * 0.02)
		stroke.size = Vector2(viewport_size.x * randf_range(0.45, 0.90), randf_range(3.0, 12.0))
		stroke.position = Vector2(
			viewport_size.x * randf_range(-0.08, 0.10),
			viewport_size.y * (0.20 + float(i) * 0.072)
		)
		stroke.rotation = deg_to_rad(randf_range(-5.0, 5.0))
		overlay.add_child(stroke)

	var sigil := make_label(get_ultimate_sigil(char_name), 390, Color(tone, 0.09))
	apply_display_font(sigil)
	sigil.set_anchors_preset(Control.PRESET_CENTER)
	sigil.position = Vector2(-440, -295)
	sigil.size = Vector2(880, 590)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.rotation = deg_to_rad(-7.0)
	overlay.add_child(sigil)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 9)
	center.add_child(v)

	var top := make_label("必　殺　解　放", 17, Color(tone, 0.86))
	apply_display_font(top)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(top)

	var owner := make_label(char_name, 24, Color("#d7d1c5"))
	apply_display_font(owner)
	owner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(owner)

	var line_top := ColorRect.new()
	line_top.color = Color(tone, 0.72)
	line_top.custom_minimum_size = Vector2(620, 2)
	v.add_child(line_top)

	var title := make_label(ultimate_name, 82, COL_GOLD_BRIGHT)
	apply_display_font(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#030407"))
	title.add_theme_constant_override("outline_size", 15)
	v.add_child(title)

	var subtitle := make_label(get_ultimate_subtitle(char_name), 15, Color("#c8bda8"))
	apply_display_font(subtitle)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(subtitle)

	var condition := make_label(
		"奏譜「%s」より解放" % get_ultimate_requirement(char_name),
		11,
		Color("#858a94")
	)
	condition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(condition)

	var line_bottom := ColorRect.new()
	line_bottom.color = Color(tone, 0.38)
	line_bottom.custom_minimum_size = Vector2(460, 1)
	v.add_child(line_bottom)

	spawn_moon_halo(center_point, tone, 8)
	spawn_shader_wave(center_point, tone, 0.56)
	spawn_gpu_sparks(center_point, COL_GOLD_BRIGHT, 76, 390.0)
	spawn_ink_burst(center_point, Color(tone, 0.44), 44)
	spawn_fullscreen_flash(Color(tone, 0.70), 0.16, 0.10)

	duck_battle_bgm(-30.0, 1.30)
	shake_amount = maxf(shake_amount, 7.0)

	overlay.modulate.a = 0.0
	v.pivot_offset = v.size * 0.5
	sigil.pivot_offset = sigil.size * 0.5

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.07)
	tween.parallel().tween_property(v, "scale", Vector2.ONE, 0.20).from(Vector2(1.22, 0.78))
	tween.parallel().tween_property(sigil, "scale", Vector2.ONE, 0.34).from(Vector2(0.68, 0.68))
	tween.tween_interval(0.82)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.18)
	await tween.finished
	overlay.queue_free()



func show_enemy_big_move_banner(move_name: String, stage: String) -> void:
	if stage == "予兆":
		play_generated_warning_sound()
	else:
		play_generated_sweep(86.0, 42.0, 0.42, 0.22)

	spawn_shader_wave(get_viewport_rect().size * 0.5, Color("#b94c54"), 0.42)
	spawn_gpu_sparks(get_viewport_rect().size * 0.5, Color("#b94c54"), 56, 300.0)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle_root.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.13, 0.015, 0.02, 0.62)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	var warning := make_label("大 技 " + stage, 16, Color("#d58b8f"))
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(warning)
	var title := make_label(move_name, 58, Color("#f0d7cf"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#1a0508"))
	title.add_theme_constant_override("outline_size", 11)
	v.add_child(title)
	overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.06)
	tween.tween_interval(0.28 if stage == "予兆" else 0.42)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.14)
	await tween.finished
	overlay.queue_free()


func spawn_skill_entry_wave(tone: Color, _note_type: String) -> void:
	var viewport_size := get_viewport_rect().size
	var center := viewport_size * Vector2(0.50, 0.48)

	for i in range(7):
		var line := ColorRect.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.color = Color(tone, 0.10 + float(i % 2) * 0.05)
		line.size = Vector2(viewport_size.x * randf_range(0.55, 0.90), randf_range(1.0, 4.0))
		line.position = Vector2(
			viewport_size.x * randf_range(0.04, 0.15),
			viewport_size.y * (0.31 + float(i) * 0.052)
		)
		line.rotation = deg_to_rad(randf_range(-4.0, 4.0))
		effect_layer.add_child(line)

		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(line, "position:x", line.position.x + randf_range(55.0, 130.0), 0.32)
		tween.tween_property(line, "modulate:a", 0.0, 0.32)
		tween.set_parallel(false)
		tween.tween_callback(line.queue_free)

	spawn_shader_wave(center, tone, 0.24)
	spawn_gpu_sparks(center, Color(tone, 0.72), 34, 210.0)

func spawn_ink_burst(center_point: Vector2, tone: Color, count: int) -> void:
	for i in range(count):
		var ink := ColorRect.new()
		ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ink.color = Color(
			tone.darkened(randf_range(0.18, 0.52)),
			randf_range(0.22, 0.58)
		)
		var length := randf_range(45.0, 180.0)
		ink.size = Vector2(length, randf_range(2.0, 8.0))
		ink.position = center_point
		var angle := randf_range(0.0, TAU)
		ink.rotation = angle
		ink.pivot_offset = Vector2(0.0, ink.size.y * 0.5)
		effect_layer.add_child(ink)

		var distance := randf_range(70.0, 230.0)
		var target := center_point + Vector2(cos(angle), sin(angle)) * distance
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ink, "position", target, randf_range(0.18, 0.34))
		tween.tween_property(ink, "modulate:a", 0.0, 0.30).set_delay(0.05)
		tween.set_parallel(false)
		tween.tween_callback(ink.queue_free)


func get_boss_texture(index_value: int) -> Texture2D:
	var file_name := "boss%d.png" % (index_value + 1)

	# 主人がどこに置いてもある程度拾えるよう、よくある配置を先に見る。
	var candidates: Array[String] = [
		"res://assets/boss/" + file_name,
		"res://assets/bosses/" + file_name,
		"res://assets/enemy/" + file_name,
		"res://assets/enemies/" + file_name,
		"res://assets/" + file_name,
		"res://" + file_name
	]

	for candidate in candidates:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D

	# assets配下ならフォルダ名が違っていても検索する。
	var discovered := find_resource_recursive("res://assets", file_name)
	if discovered != "" and ResourceLoader.exists(discovered):
		return load(discovered) as Texture2D

	push_warning("Boss image not found: " + file_name + " / assets配下を確認してください")
	return null


func find_resource_recursive(root_path: String, target_file: String) -> String:
	var files := DirAccess.get_files_at(root_path)
	for file_variant in files:
		var file_name := str(file_variant)
		if file_name.to_lower() == target_file.to_lower():
			return root_path.path_join(file_name)

	var directories := DirAccess.get_directories_at(root_path)
	for directory_variant in directories:
		var directory_name := str(directory_variant)
		if directory_name.begins_with("."):
			continue
		var found := find_resource_recursive(
			root_path.path_join(directory_name),
			target_file
		)
		if found != "":
			return found

	return ""


func play_enemy_hit_reaction(damage: int) -> void:
	if enemy_portrait == null or not is_instance_valid(enemy_portrait):
		return

	var ratio := float(damage) / maxf(1.0, float(enemy_state.get("hp", 1)))
	var heavy := ratio >= 0.07
	enemy_hit_flash_until_msec = Time.get_ticks_msec() + (210 if heavy else 150)
	enemy_portrait.pivot_offset = enemy_portrait.size * 0.5
	enemy_portrait.modulate = Color(1.75, 1.55, 1.30, 1.0) if heavy else Color(1.35, 0.82, 0.82, 1.0)
	enemy_portrait.rotation = deg_to_rad(randf_range(-3.2, 3.2) if heavy else randf_range(-1.8, 1.8))

	var squash := Vector2(1.075, 0.90) if heavy else Vector2(1.025, 0.965)
	var recoil := Vector2(0.96, 1.055) if heavy else Vector2(0.99, 1.025)
	var tween := create_tween()
	tween.tween_property(enemy_portrait, "scale", squash, 0.045 if heavy else 0.055)
	tween.tween_property(enemy_portrait, "scale", recoil, 0.060)
	tween.tween_property(enemy_portrait, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(enemy_portrait, "rotation", 0.0, 0.17)
	tween.parallel().tween_property(enemy_portrait, "modulate", Color.WHITE, 0.19)

	if heavy:
		spawn_fullscreen_flash(Color("#fff3d7"), 0.16, 0.06)
		shake_amount = maxf(shake_amount, 11.0)

func play_enemy_break_reaction() -> void:
	if enemy_portrait == null or not is_instance_valid(enemy_portrait):
		return

	enemy_portrait.pivot_offset = enemy_portrait.size * 0.5
	enemy_portrait.modulate = Color(1.8, 1.65, 1.2, 1.0)
	var tween := create_tween()
	tween.tween_property(enemy_portrait, "scale", Vector2(1.05, 0.95), 0.07)
	tween.tween_property(enemy_portrait, "scale", Vector2(0.97, 1.04), 0.07)
	tween.tween_property(enemy_portrait, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(enemy_portrait, "modulate", Color.WHITE, 0.24)


func spawn_enemy_damage_popup(value: int, is_critical: bool) -> void:
	if enemy_portrait_frame == null or not is_instance_valid(enemy_portrait_frame):
		return

	var ratio := float(value) / maxf(1.0, float(enemy_state.get("hp", 1)))
	var heavy := ratio >= 0.07 or is_critical
	var huge := ratio >= 0.12 or is_critical
	var popup := Label.new()
	apply_display_font(popup)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.text = ("会心　" if is_critical else "") + str(value)
	popup.add_theme_font_size_override("font_size", 52 if huge else (40 if heavy else 28))
	popup.add_theme_color_override("font_color", COL_GOLD_BRIGHT if heavy else Color("#f0e6d5"))
	popup.add_theme_color_override("font_outline_color", Color("#12090b"))
	popup.add_theme_constant_override("outline_size", 8 if heavy else 6)
	popup.position = enemy_portrait_frame.global_position + Vector2(enemy_portrait_frame.size.x * 0.58, 36)
	popup.pivot_offset = Vector2(40, 24)
	effect_layer.add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - (92.0 if heavy else 72.0), 0.66)
	tween.tween_property(popup, "modulate:a", 0.0, 0.66).set_delay(0.10 if heavy else 0.0)
	if heavy:
		tween.tween_property(popup, "scale", Vector2.ONE, 0.12).from(Vector2(1.45, 0.70))
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)

func spawn_enemy_break_popup(value: int) -> void:
	if enemy_portrait_frame == null or not is_instance_valid(enemy_portrait_frame):
		return

	var popup := Label.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.text = "構え -%d" % value
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", COL_BREAK)
	popup.position = enemy_portrait_frame.global_position + Vector2(enemy_portrait_frame.size.x * 0.54, 84)
	effect_layer.add_child(popup)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 45.0, 0.48)
	tween.tween_property(popup, "modulate:a", 0.0, 0.48)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)


func play_break_banner() -> void:
	if battle_root == null:
		return

	play_generated_break_sound()
	spawn_shader_wave(get_viewport_rect().size * 0.5, COL_BREAK, 0.34)
	spawn_gpu_sparks(get_viewport_rect().size * 0.5, COL_BREAK, 72, 360.0)

	var label := make_label("崩　壊", 62, COL_BREAK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.position = Vector2(-260, -46)
	label.size = Vector2(520, 92)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("#160f06"))
	label.add_theme_constant_override("outline_size", 10)
	effect_layer.add_child(label)

	label.modulate.a = 0.0
	label.pivot_offset = label.size * 0.5
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.12).from(Vector2(1.45, 0.70))
	tween.tween_interval(0.24)
	tween.tween_property(label, "modulate:a", 0.0, 0.18)
	tween.tween_callback(label.queue_free)

	spawn_particle_burst(get_viewport_rect().size * 0.5, COL_BREAK, 34, 250.0, "◆")


func play_measure_banner(phrase_name: String) -> void:
	# v7ではshow_score_completion_bannerが担当。
	return


func get_score_effect_text(phrase_name: String) -> String:
	match phrase_name:
		"昇奏": return "効果：次の巡まで攻撃・崩し強化"
		"降奏": return "効果：味方全体の生命5%・構え16回復"
		"重奏": return "効果：次の巡まで攻撃強化"
		"濁奏": return "効果：攻撃強化 / 反動で味方全体の構え-8"
		"返奏": return "効果：味方全体に結界1巡 / 構え8回復"
		"静奏": return "効果：味方全体の生命4%・構え20回復"
		"彩奏": return "効果：味方全体の奏力2・構え12回復"
		"合奏": return "効果：味方全体の奏力1・構え8回復"
		"朔月・静奏": return "効果：味方全体の奏力2・構え16回復"
		"三日月・疾奏": return "効果：奏力1・構え10回復 / 攻撃強化"
		"上弦・破奏": return "効果：崩し強化 / 敵構えを最大値の14%削る"
		"十三夜・調奏": return "効果：奏力2・構え10回復 / 攻撃強化"
		"望月・烈奏": return "効果：攻撃3巡・崩し2巡を強化"
		"十六夜・妖奏": return "効果：敵の毒・火傷を即時追加発動"
		"下弦・守奏": return "効果：味方全体の生命8%・構え26回復"
		"晦・葬奏": return "効果：敵の弱体数に応じて追加傷"
		_: return "効果：余韻のみ"


func get_score_visual_profile(
	phrase_name: String,
	is_moon_combo: bool
) -> Dictionary:
	if is_moon_combo:
		match phrase_name:
			"朔月・静奏":
				return {"tone":Color("#c6d0db"), "sigil":"朔", "sub":"静寂が満ちる", "kind":"newmoon"}
			"三日月・疾奏":
				return {"tone":Color("#b9def4"), "sigil":"疾", "sub":"細月、駆ける", "kind":"swift"}
			"上弦・破奏":
				return {"tone":Color("#e0bd72"), "sigil":"破", "sub":"刃、構えを断つ", "kind":"break"}
			"十三夜・調奏":
				return {"tone":Color("#d0b7df"), "sigil":"調", "sub":"乱れを整える", "kind":"harmony"}
			"望月・烈奏":
				return {"tone":Color("#ffd67a"), "sigil":"烈", "sub":"満ちた月が燃える", "kind":"fullmoon"}
			"十六夜・妖奏":
				return {"tone":Color("#c287c7"), "sigil":"妖", "sub":"余光に妖気が宿る", "kind":"yokai"}
			"下弦・守奏":
				return {"tone":Color("#a8d8e1"), "sigil":"守", "sub":"欠けゆく月が護る", "kind":"guard"}
			"晦・葬奏":
				return {"tone":Color("#8f719f"), "sigil":"葬", "sub":"闇へ沈める", "kind":"burial"}

	match phrase_name:
		"昇奏":
			return {"tone":Color("#dfb66c"), "sigil":"昇", "sub":"旋律、上る", "kind":"rise"}
		"降奏":
			return {"tone":Color("#8db9d6"), "sigil":"降", "sub":"旋律、鎮まる", "kind":"fall"}
		"重奏":
			return {"tone":Color("#c6a16d"), "sigil":"重", "sub":"響きを重ねる", "kind":"echo"}
		"濁奏":
			return {"tone":Color("#9d6caf"), "sigil":"濁", "sub":"歪んだ響きを力へ", "kind":"dissonance"}
		"返奏":
			return {"tone":Color("#a8cbc4"), "sigil":"返", "sub":"響きが返る", "kind":"return"}
		"静奏":
			return {"tone":Color("#d7dfdc"), "sigil":"静", "sub":"一拍の静寂", "kind":"still"}
		"彩奏":
			return {"tone":Color("#d8b2cf"), "sigil":"彩", "sub":"異なる響きが交わる", "kind":"color"}
		"合奏":
			return {"tone":Color("#d7c082"), "sigil":"合", "sub":"三つの音が重なる", "kind":"ensemble"}
		_:
			return {"tone":Color("#9aa2ad"), "sigil":"余", "sub":"響きだけが残る", "kind":"afterglow"}


func spawn_score_signature_fx(
	phrase_name: String,
	is_moon_combo: bool,
	center_point: Vector2
) -> void:
	var profile := get_score_visual_profile(phrase_name, is_moon_combo)
	var tone: Color = profile["tone"] as Color
	var kind := str(profile["kind"])

	match kind:
		"rise":
			for i in range(6):
				spawn_streak(
					center_point + Vector2(-360.0 + float(i) * 42.0, 170.0 - float(i) * 18.0),
					Vector2(620.0, -280.0 - float(i) * 18.0),
					Color(tone, 0.24 + float(i) * 0.06),
					2.0 + float(i % 2)
				)
			spawn_gpu_sparks(center_point, tone, 48, 280.0)

		"fall":
			spawn_rain_field(center_point, 860.0, 74, Color(tone, 0.70))
			spawn_water_bloom(center_point + Vector2(0, 110), tone, 36)

		"echo":
			for i in range(7):
				spawn_ring(center_point, Color(tone, 0.50 - float(i) * 0.055), 110.0 + float(i) * 72.0)
			spawn_shader_wave(center_point, tone, 0.44)

		"dissonance":
			spawn_curse_chains(center_point, tone, 9)
			spawn_ink_burst(center_point, Color("#5e4168"), 42)
			spawn_shader_wave(center_point, tone, 0.50)

		"return":
			spawn_wind_arc(center_point + Vector2(-140, 0), tone, 5)
			spawn_wind_arc(center_point + Vector2(140, 0), tone, 5)
			for i in range(3):
				spawn_ring(center_point, Color(tone, 0.45 - float(i) * 0.09), 150.0 + float(i) * 80.0)

		"still":
			for i in range(5):
				spawn_ring(center_point, Color(tone, 0.32 - float(i) * 0.045), 130.0 + float(i) * 95.0)
			spawn_particle_burst(center_point, Color(tone, 0.72), 24, 130.0, "・")

		"color":
			var tones: Array[Color] = [
				Color("#d9b579"),
				Color("#a7c8df"),
				Color("#c9a6d6"),
				Color("#b4d0b2")
			]
			for i in range(tones.size()):
				spawn_ring(center_point, Color(tones[i], 0.42), 130.0 + float(i) * 75.0)
				spawn_gpu_sparks(center_point, tones[i], 18, 220.0 + float(i) * 30.0)

		"ensemble":
			for offset in [Vector2(-140, 30), Vector2(0, -55), Vector2(140, 30)]:
				spawn_moon_halo(center_point + offset, tone, 2)
			spawn_gpu_sparks(center_point, tone, 62, 330.0)

		"afterglow":
			spawn_particle_burst(center_point, Color(tone, 0.55), 22, 150.0, "・")
			spawn_shader_wave(center_point, tone, 0.22)

		"newmoon":
			spawn_moon_halo(center_point, tone, 6)
			spawn_ink_burst(center_point, Color("#262934"), 46)
			spawn_particle_burst(center_point, Color("#d3d9df"), 34, 180.0, "・")

		"swift":
			for i in range(8):
				spawn_streak(
					center_point + Vector2(-420, -170 + float(i) * 48.0),
					Vector2(840, -60.0 + float(i) * 12.0),
					Color(tone, 0.32 + float(i) * 0.05),
					2.0 + float(i % 3)
				)
			spawn_wind_arc(center_point, tone, 8)

		"break":
			spawn_ink_burst(center_point, Color("#433019"), 50)
			spawn_gpu_sparks(center_point, tone, 96, 430.0)
			spawn_streak(center_point + Vector2(-420, -250), Vector2(840, 500), Color("#fff0c1"), 7.0)
			spawn_streak(center_point + Vector2(420, -230), Vector2(-840, 460), tone, 8.0)
			shake_amount = maxf(shake_amount, 12.0)

		"harmony":
			for i in range(8):
				spawn_ring(center_point, Color(tone, 0.44 - float(i) * 0.045), 100.0 + float(i) * 56.0)
			spawn_particle_burst(center_point, Color("#eadcf2"), 62, 300.0, "✦")

		"fullmoon":
			spawn_moon_halo(center_point, tone, 8)
			spawn_fire_particles(center_point, 110, 330.0, false)
			spawn_holy_column(center_point, Color("#ffe6a3"), 520.0)
			spawn_fullscreen_flash(Color("#ffe7a6"), 0.24, 0.11)

		"yokai":
			for i in range(7):
				var angle := TAU * float(i) / 7.0
				var p := center_point + Vector2(cos(angle), sin(angle)) * 210.0
				spawn_fire_column(p, 150.0, 54.0, true)
			spawn_curse_chains(center_point, tone, 8)
			spawn_shader_wave(center_point, tone, 0.46)

		"guard":
			spawn_barrier_dome(center_point, tone, 320.0)
			spawn_rain_field(center_point, 940.0, 72, Color(tone, 0.64))
			spawn_holy_column(center_point, Color("#d9f2f2"), 380.0)

		"burial":
			spawn_curse_chains(center_point, tone, 12)
			spawn_ink_burst(center_point, Color("#2a202e"), 62)
			for i in range(6):
				spawn_streak(
					center_point + Vector2(-310 + float(i) * 120.0, -300),
					Vector2(-40.0, 620.0),
					Color(tone, 0.18 + float(i) * 0.045),
					4.0
				)
			spawn_shader_wave(center_point, tone, 0.56)


func show_score_completion_banner(
	phrase_name: String,
	is_moon_combo: bool,
	notes: Array[Dictionary],
	finisher_unlock_text: String = ""
) -> void:
	if screen_mode != "battle":
		return

	duck_battle_bgm(-25.0 if is_moon_combo else -19.0, 1.0)
	play_generated_score_sound(is_moon_combo)

	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	effect_layer.add_child(overlay)

	var profile := get_score_visual_profile(phrase_name, is_moon_combo)
	var tone: Color = profile["tone"] as Color
	var sigil_text := str(profile["sigil"])
	var sub_text := str(profile["sub"])

	var shade := ColorRect.new()
	shade.color = Color(0.005, 0.007, 0.012, 0.90 if is_moon_combo else 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var viewport_size := get_viewport_rect().size
	var center_point := viewport_size * 0.5

	# 奏式ごとの専用演出。汎用火花だけで済ませない。
	spawn_score_signature_fx(phrase_name, is_moon_combo, center_point)

	var sigil := make_label(sigil_text, 360 if is_moon_combo else 300, Color(tone, 0.10))
	apply_display_font(sigil)
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil.set_anchors_preset(Control.PRESET_CENTER)
	sigil.position = Vector2(-450, -275)
	sigil.size = Vector2(900, 550)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.rotation = deg_to_rad(-6.0 if is_moon_combo else 5.0)
	overlay.add_child(sigil)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 11)
	center.add_child(v)

	var top_text := "月　奏" if is_moon_combo else "奏　譜　成　立"
	var top := make_label(top_text, 28 if is_moon_combo else 22, tone)
	apply_display_font(top)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(top)

	var rule_top := ColorRect.new()
	rule_top.color = Color(tone, 0.68)
	rule_top.custom_minimum_size = Vector2(620 if is_moon_combo else 540, 2)
	v.add_child(rule_top)

	var main := make_label(
		phrase_name,
		86 if is_moon_combo else 72,
		COL_GOLD_BRIGHT if is_moon_combo else Color("#e0e5ec")
	)
	apply_display_font(main)
	main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.add_theme_color_override("font_outline_color", Color("#040509"))
	main.add_theme_constant_override("outline_size", 14)
	v.add_child(main)

	var sub := make_label(sub_text, 15, Color(tone, 0.88))
	apply_display_font(sub)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var effect_text := make_label(get_score_effect_text(phrase_name), 14, Color("#e6dfcf"))
	apply_body_font(effect_text)
	effect_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_text.add_theme_color_override("font_outline_color", Color("#050609"))
	effect_text.add_theme_constant_override("outline_size", 5)
	v.add_child(effect_text)

	if not finisher_unlock_text.is_empty():
		var unlock_label := make_label(finisher_unlock_text, 18, COL_GOLD_BRIGHT)
		apply_display_font(unlock_label)
		unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_label.add_theme_color_override("font_outline_color", Color("#050609"))
		unlock_label.add_theme_constant_override("outline_size", 7)
		v.add_child(unlock_label)
		spawn_gpu_sparks(get_viewport_rect().size * 0.5, COL_GOLD_BRIGHT, 74, 360.0)
		spawn_fullscreen_flash(Color("#ffe6a3"), 0.16, 0.10)

	var note_row := HBoxContainer.new()
	note_row.alignment = BoxContainer.ALIGNMENT_CENTER
	note_row.add_theme_constant_override("separation", 10)
	v.add_child(note_row)

	for note_variant in notes:
		var note: Dictionary = note_variant
		var mark := str(note.get("mark", ""))
		var crest := make_panel(Color("#0d0f14cc"), Color(get_note_color(mark), 0.58), 8, 1)
		crest.custom_minimum_size = Vector2(68, 46)
		note_row.add_child(crest)

		var crest_label := make_label(get_note_display(mark), 18, get_note_color(mark))
		apply_display_font(crest_label)
		crest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		crest_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		crest.add_child(crest_label)

	var rule_bottom := ColorRect.new()
	rule_bottom.color = Color(tone, 0.36)
	rule_bottom.custom_minimum_size = Vector2(440, 1)
	v.add_child(rule_bottom)

	var phase_text := make_label(
		PHASES[moon_index] + ("　共鳴" if is_moon_combo else "　奏譜"),
		13,
		Color("#aaa8a2")
	)
	phase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(phase_text)

	overlay.modulate.a = 0.0
	v.pivot_offset = v.size * 0.5
	sigil.pivot_offset = sigil.size * 0.5

	var hold_time := 1.48 if is_moon_combo else 1.10
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.07)
	tween.parallel().tween_property(v, "scale", Vector2.ONE, 0.20).from(Vector2(1.28, 0.72))
	tween.parallel().tween_property(sigil, "scale", Vector2.ONE, 0.36).from(Vector2(0.72, 0.72))
	tween.tween_interval(hold_time)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.22)
	tween.tween_callback(overlay.queue_free)


func apply_moon_arrival_effect(phase_index: int) -> void:
	if party_state.is_empty():
		return

	if phase_index == 0:
		for char_name in party:
			var state: Dictionary = party_state[char_name]
			if int(state["cur_hp"]) <= 0:
				continue
			state["cur_mana"] = mini(int(state["mana"]), int(state["cur_mana"]) + 1)
			party_state[char_name] = state
		append_log("[color=#8298ad]新月到達。生存者の奏力 +1。[/color]")
	elif phase_index == 6:
		for char_name in party:
			var state: Dictionary = party_state[char_name]
			if int(state["cur_hp"]) <= 0:
				continue
			var recovery := maxi(1, int(round(float(state["hp"]) * 0.03)))
			state["cur_hp"] = mini(int(state["hp"]), int(state["cur_hp"]) + recovery)
			party_state[char_name] = state
		append_log("[color=#9cb5c4]下弦到達。月光が傷をわずかに癒やす。[/color]")
	elif phase_index == 7:
		var statuses: Dictionary = enemy_state.get("statuses", {})
		for status_key in statuses.keys():
			if NEGATIVE_STATUSES.has(str(status_key)):
				statuses[status_key] = int(statuses[status_key]) + 1
		enemy_state["statuses"] = statuses


func apply_enemy_moon_damage(damage: int) -> int:
	var result := float(damage)
	if moon_index == 4:
		result *= 1.25
	elif moon_index == 0:
		result *= 0.92
	return maxi(1, int(round(result)))


func play_moon_shift_flash() -> void:
	var label := make_label("→ " + PHASES[moon_index], 18, MOON_COLORS[moon_index])
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	label.position = Vector2(-330, 118)
	label.size = Vector2(280, 42)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_outline_color", Color("#08090c"))
	label.add_theme_constant_override("outline_size", 5)
	effect_layer.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:x", label.position.x - 22.0, 0.55)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.18)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


func get_action_moon_steps(action_data: Dictionary) -> int:
	if action_data.is_empty():
		return 0

	var action_type := str(action_data.get("type", ""))
	if action_type == "attack" or action_type == "guard":
		return 1
	if action_type == "ultimate":
		return 2
	if action_type != "skill":
		return 0

	var skill_data: Dictionary = action_data.get("skill", {})
	var skill_id := str(skill_data.get("id", ""))
	match skill_id:
		"samurai_moon_slash", "chochin_lantern_drop", "jusoshi_grudge":
			return 2
		"sennin_moon_turn":
			return 3
		_:
			return 1


func refresh_moon_forecast() -> void:
	if moon_forecast_label == null or not is_instance_valid(moon_forecast_label):
		return

	var preview_actor := get_current_planning_actor()
	var preview_action: Dictionary = {}
	if not ctb_preview_action.is_empty():
		preview_action = ctb_preview_action

	var bonus := get_planned_moon_bonus(preview_actor, preview_action)
	var next_phase := (moon_index + 1 + bonus) % PHASES.size()

	moon_forecast_label.text = "月路　今巡【%s】固定　→　次巡【%s】%s" % [
		PHASES[moon_index],
		PHASES[next_phase],
		("　月操作 +" + str(bonus)) if bonus > 0 else ""
	]



func sort_planned_players_descending(a: Dictionary, b: Dictionary) -> bool:
	return int(a["spd"]) > int(b["spd"])


func play_layered_attack(base_pitch: float) -> void:
	play_one_shot(attack_player, base_pitch)
	if impact_player != null and impact_player.stream != null:
		impact_player.pitch_scale = base_pitch * 0.78
		impact_player.play()


func duck_battle_bgm(target_db: float, hold_time: float) -> void:
	if battle_player == null or not battle_player.playing:
		return

	var tween := create_tween()
	tween.tween_property(battle_player, "volume_db", target_db, 0.05)
	tween.tween_interval(hold_time)
	tween.tween_property(battle_player, "volume_db", -9.0, 0.20)


func update_low_hp_pulse() -> void:
	if screen_mode != "battle":
		return

	var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5

	for char_name in party:
		if not party_cards.has(char_name):
			continue
		if bool(hurt_animating.get(char_name, false)):
			continue

		var state: Dictionary = party_state[char_name]
		var panel: PanelContainer = party_cards[char_name]["panel"] as PanelContainer
		var ratio := float(state["cur_hp"]) / maxf(1.0, float(state["hp"]))

		if ratio <= 0.25 and int(state["cur_hp"]) > 0:
			panel.modulate = Color(1.0, 0.78 + pulse * 0.16, 0.80 + pulse * 0.14, 1.0)
		else:
			panel.modulate = Color.WHITE


func update_boss_pressure_pulse() -> void:
	if enemy_portrait == null or not is_instance_valid(enemy_portrait):
		return
	if enemy_state.is_empty():
		return

	var pulse := (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
	if enemy_portrait_frame != null and is_instance_valid(enemy_portrait_frame):
		if int(enemy_state.get("big_state", 0)) > 0:
			enemy_portrait_frame.modulate = Color(1.0, 0.72 + pulse * 0.20, 0.72 + pulse * 0.16, 1.0)
		elif is_enemy_second_phase():
			enemy_portrait_frame.modulate = Color(1.0, 0.94 + pulse * 0.05, 0.86 + pulse * 0.08, 1.0)
		else:
			enemy_portrait_frame.modulate = Color.WHITE

	if Time.get_ticks_msec() < enemy_hit_flash_until_msec:
		return

	var ratio := float(enemy_state.get("cur_hp", 0)) / maxf(1.0, float(enemy_state.get("hp", 1)))
	if ratio <= 0.25 and int(enemy_state.get("cur_hp", 0)) > 0:
		enemy_portrait.modulate = Color(1.0, 0.80 + pulse * 0.14, 0.80 + pulse * 0.12, 1.0)
	elif is_enemy_second_phase():
		enemy_portrait.modulate = Color(1.04, 0.97, 0.90, 1.0)
	else:
		enemy_portrait.modulate = Color.WHITE

func make_label(
	text_value: String,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.text = text_value
	apply_body_font(label)
	label.add_theme_font_size_override(
		"font_size",
		font_size
	)
	label.add_theme_color_override(
		"font_color",
		color
	)
	return label


func make_panel(
	bg: Color,
	border: Color,
	radius: int,
	border_width: int
) -> PanelContainer:
	var panel := PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)

	panel.add_theme_stylebox_override(
		"panel",
		style
	)

	return panel


func make_bar(
	fill_color: Color,
	background_color: Color,
	height: int
) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, height)
	bar.show_percentage = false

	var background_style := StyleBoxFlat.new()
	background_style.bg_color = background_color
	background_style.set_corner_radius_all(int(round(float(height) / 2.0)))

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(int(round(float(height) / 2.0)))

	bar.add_theme_stylebox_override(
		"background",
		background_style
	)
	bar.add_theme_stylebox_override(
		"fill",
		fill_style
	)

	return bar


func make_primary_button(
	text_value: String,
	width: int
) -> Button:
	var button := Button.new()
	apply_body_font(button)
	button.text = text_value

	if width > 0:
		button.custom_minimum_size = Vector2(width, 54)
	else:
		button.custom_minimum_size = Vector2(0, 54)

	button.add_theme_font_size_override(
		"font_size",
		15
	)
	button.add_theme_color_override(
		"font_color",
		COL_TEXT
	)
	button.add_theme_color_override(
		"font_hover_color",
		COL_GOLD_BRIGHT
	)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#1a191b")
	normal.border_color = Color("#745f3e")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 20
	normal.content_margin_right = 20

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#292219")
	hover.border_color = COL_GOLD

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#111319")
	disabled.border_color = Color("#272930")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)

	return button


func make_secondary_button(
	text_value: String,
	width: int
) -> Button:
	var button := Button.new()
	apply_body_font(button)
	button.text = text_value

	if width > 0:
		button.custom_minimum_size = Vector2(width, 46)
	else:
		button.custom_minimum_size = Vector2(0, 46)

	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override(
		"font_color",
		Color("#b9b5ad")
	)
	button.add_theme_color_override(
		"font_hover_color",
		COL_TEXT
	)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#15171d")
	normal.border_color = Color("#31343c")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#202229")
	hover.border_color = Color("#675b49")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

	return button


func make_command_button(
	title_text: String,
	detail_text: String
) -> Button:
	var button := Button.new()
	apply_body_font(button)
	button.text = title_text + "\n" + detail_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 56)

	button.add_theme_font_size_override(
		"font_size",
		12
	)
	button.add_theme_color_override(
		"font_color",
		Color("#ddd6cb")
	)
	button.add_theme_color_override(
		"font_hover_color",
		Color("#fff1cb")
	)
	button.add_theme_color_override(
		"font_disabled_color",
		Color("#5d6068")
	)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#171920")
	normal.border_color = Color("#30333d")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 16
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#24201d")
	hover.border_color = Color("#806748")

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#111319")
	disabled.border_color = Color("#262831")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)

	return button


func make_pill(
	text_value: String,
	bg: Color,
	border: Color,
	text_color: Color
) -> Label:
	var pill := Label.new()
	pill.text = text_value
	pill.custom_minimum_size = Vector2(110, 32)
	pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_theme_font_size_override("font_size", 9)
	pill.add_theme_color_override(
		"font_color",
		text_color
	)

	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)

	pill.add_theme_stylebox_override(
		"normal",
		style
	)

	return pill


func make_dual_label_row(
	left_text: String,
	right_text: String
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(
		make_label(left_text, 9, COL_MUTED)
	)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	row.add_child(
		make_label(right_text, 8, Color("#5d6068"))
	)

	return row


func set_margins(
	container: MarginContainer,
	left_value: int,
	top_value: int,
	right_value: int,
	bottom_value: int
) -> void:
	container.add_theme_constant_override(
		"margin_left",
		left_value
	)
	container.add_theme_constant_override(
		"margin_top",
		top_value
	)
	container.add_theme_constant_override(
		"margin_right",
		right_value
	)
	container.add_theme_constant_override(
		"margin_bottom",
		bottom_value
	)


func clear_container(container: Node) -> void:
	if container == null:
		return

	# pressedシグナルを発火中のButtonを即free()しない。
	# get_children()のスナップショットを安全にqueue_freeする。
	for child in container.get_children():
		if child is Control:
			var control_child := child as Control
			control_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			control_child.hide()
		child.queue_free()


# ============================================================
# FX / DRAW
# ============================================================

func trigger_slash() -> void:
	slash_alpha = 1.0
	shake_amount = 6.0
	queue_redraw()


func _process(delta: float) -> void:
	if slash_alpha > 0.0:
		slash_alpha = maxf(
			0.0,
			slash_alpha - delta * 4.2
		)

	if flash_alpha > 0.0:
		flash_alpha = maxf(
			0.0,
			flash_alpha - delta * 3.4
		)

	if moon_pulse > 0.0:
		moon_pulse = maxf(
			0.0,
			moon_pulse - delta * 2.0
		)

	if shake_amount > 0.0:
		shake_amount = maxf(
			0.0,
			shake_amount - delta * 40.0
		)

		position = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
	else:
		position = Vector2.ZERO

	for i in range(motes.size()):
		motes[i].y -= delta * (
			0.010
			+ float(i % 5) * 0.0014
		)

		motes[i].x += sin(
			Time.get_ticks_msec() * 0.00028 + float(i)
		) * delta * 0.003

		if motes[i].y < -0.02:
			motes[i].y = 1.02
			motes[i].x = randf()

	update_low_hp_pulse()
	update_boss_pressure_pulse()
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size

	draw_rect(
		Rect2(Vector2.ZERO, viewport_size),
		COL_BG
	)

	for i in range(22):
		var y := float(i) / 22.0 * viewport_size.y

		draw_rect(
			Rect2(
				0,
				y,
				viewport_size.x,
				1
			),
			Color(
				0.95,
				0.90,
				0.80,
				0.011
			)
		)

	for i in range(motes.size()):
		var particle_pos := Vector2(
			motes[i].x * viewport_size.x,
			motes[i].y * viewport_size.y
		)

		var alpha: float = (
			0.025
			+ float(i % 5) * 0.009
		)

		var radius: float = (
			0.8
			+ float(i % 4) * 0.38
		)

		draw_circle(
			particle_pos,
			radius,
			Color(
				0.86,
				0.81,
				0.70,
				alpha
			)
		)

	var moon_center := Vector2(
		viewport_size.x * 0.82,
		viewport_size.y * 0.105
	)

	if screen_mode == "battle":
		draw_moon(
			moon_center,
			56.0 + moon_pulse * 6.0
		)
	else:
		draw_moon(
			Vector2(
				viewport_size.x * 0.78,
				viewport_size.y * 0.18
			),
			94.0
		)

	if slash_alpha > 0.0:
		var alpha: float = slash_alpha
		var start_point := Vector2(
			viewport_size.x * 0.23,
			viewport_size.y * 0.29
		)
		var end_point := Vector2(
			viewport_size.x * 0.67,
			viewport_size.y * 0.57
		)

		draw_line(
			start_point + Vector2(-8, 15),
			end_point + Vector2(10, -16),
			Color(
				0.96,
				0.88,
				0.70,
				alpha * 0.18
			),
			18.0
		)

		draw_line(
			start_point,
			end_point,
			Color(
				1.0,
				0.96,
				0.86,
				alpha * 0.96
			),
			3.0
		)

		draw_line(
			start_point + Vector2(15, -10),
			end_point + Vector2(19, -14),
			Color(
				0.82,
				0.63,
				0.38,
				alpha * 0.48
			),
			2.0
		)

	if flash_alpha > 0.0:
		draw_rect(
			Rect2(
				Vector2.ZERO,
				viewport_size
			),
			Color(
				0.32,
				0.07,
				0.08,
				flash_alpha * 0.32
			)
		)


func draw_moon(
	center_point: Vector2,
	radius: float
) -> void:
	var moon_color: Color = MOON_COLORS[moon_index]

	draw_circle(
		center_point,
		radius + 38.0,
		Color(
			moon_color.r,
			moon_color.g,
			moon_color.b,
			0.018 + moon_pulse * 0.018
		)
	)

	draw_circle(
		center_point,
		radius + 16.0,
		Color(
			moon_color.r,
			moon_color.g,
			moon_color.b,
			0.026 + moon_pulse * 0.024
		)
	)

	draw_circle(
		center_point,
		radius,
		Color(
			moon_color.r,
			moon_color.g,
			moon_color.b,
			0.78
		)
	)

	var mask_color := Color("#090a0e")

	match moon_index:
		0:
			draw_circle(
				center_point,
				radius - 2.0,
				mask_color
			)
		1:
			draw_circle(
				center_point + Vector2(
					radius * 0.42,
					0
				),
				radius,
				mask_color
			)
		2:
			draw_circle(
				center_point + Vector2(
					radius * 0.92,
					0
				),
				radius,
				mask_color
			)
		3:
			draw_circle(
				center_point + Vector2(
					radius * 1.48,
					0
				),
				radius,
				mask_color
			)
		4:
			pass
		5:
			draw_circle(
				center_point - Vector2(
					radius * 1.48,
					0
				),
				radius,
				mask_color
			)
		6:
			draw_circle(
				center_point - Vector2(
					radius * 0.92,
					0
				),
				radius,
				mask_color
			)
		7:
			draw_circle(
				center_point - Vector2(
					radius * 0.42,
					0
				),
				radius,
				mask_color
			)

	draw_arc(
		center_point,
		radius,
		0.0,
		TAU,
		128,
		Color(
			moon_color.r,
			moon_color.g,
			moon_color.b,
			0.55
		),
		1.2
	)
