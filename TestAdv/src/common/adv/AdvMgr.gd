extends Node2D

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")
# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

const AdvTalkText      = preload("res://src/common/adv/AdvTalkText.gd")
const AdvTalkTextScene = preload("res://src/common/adv/AdvTalkText.tscn")

# 状態
enum eState {
	INIT,
	EXEC,
	KEY_WAIT,
	SEL_WAIT,
	WAIT,
	OBJ_WAIT,
	FADE_WAIT,
	YIELD,
	YIELD2,	
}

# メッセージの種類
enum eCmdMesType {
	NONE   = 0, # 改行なし
	PF     = 1, # 改行する
	CLICK  = 2, # クリック待ち
	NOTICE = 9, # 通知
}

enum eBgState {
	HIDE,
	TO_SHOW,
	SHOW,
	TO_HIDE,
}

class AdvBg:
	var bg:TextureRect = null
	var time := 0.0
	var state = eBgState.HIDE
	func _init(bg_rect:TextureRect):
		bg = bg_rect
	func load_texture(id:int):
		bg.texture = load("res://assets/bg/bg%03d.jpg"%id)
	func dispose_texture():
		bg.texture = null
		state = eBgState.HIDE
	
	func is_appear() -> bool:
		if state in [eBgState.TO_SHOW, eBgState.SHOW]:
			return true # 表示中
		return false
	
	func update(delta:float):
		match state:
			eBgState.HIDE:
				bg.texture = null
			eBgState.TO_SHOW:
				time = min(0.5, time + delta)
				var rate = time / 0.5
				bg.modulate = Color(1, 1, 1, rate)
				if time >= 0.5:
					time = 0
					state = eBgState.SHOW
			eBgState.SHOW:
				bg.modulate = Color.white
			eBgState.TO_HIDE:
				time = min(0.5, time + delta)
				var rate = time / 0.5
				bg.modulate = Color(1, 1, 1, 1 - rate)
				if time >= 0.5:
					time = 0
					state = eBgState.HIDE
	func appear():
		if state in [eBgState.HIDE, eBgState.TO_HIDE]:
			state = eBgState.TO_SHOW
			time  = 0
	func disappear():
		if state in [eBgState.SHOW, eBgState.TO_SHOW]:
			state = eBgState.TO_HIDE
			time  = 0

class AdvBgMgr:
	var _bg_list = []
	func _init(bg_rect):
		var bg1 = AdvBg.new(bg_rect[0])
		_bg_list.append(bg1)
		var bg2 = AdvBg.new(bg_rect[1])
		_bg_list.append(bg2)
	
	func _copy_to_bellow(bg:AdvBg) -> void:
		var bellow:AdvBg = _bg_list[0]
		bellow.bg.texture = bg.bg.texture
		bg.dispose_texture()
		bellow.state = eBgState.SHOW
	
	func draw_bg(id:int, eft:int) -> void:
		var bg:AdvBg = _bg_list[1] # 演出用BG
		if bg.is_appear():
			# 表示中の場合はすぐにコピーする
			_copy_to_bellow(bg)
		bg.load_texture(id)
		bg.appear()
		
	func erase_bg(eft:int) -> void:
		var bg:AdvBg = _bg_list[1] # 演出用BG
		if bg.is_appear():
			# 表示中の場合はすぐにコピーする
			_copy_to_bellow(bg)
		var bellow = _bg_list[0]
		bellow.disappear() # 消滅演出開始
		
	func update(delta:float) -> void:
		var bg = _bg_list[1] # 演出用BG
		bg.update(delta)
		if bg.state == eBgState.SHOW:
			_copy_to_bellow(bg)
		var bellow = _bg_list[0]
		bellow.update(delta)

var _script:AdvScript      = null
var _talk_text:AdvTalkText = null
var _msg              := AdvTextMgr.new()
var _state            = eState.INIT
var _next_state       = eState.INIT
var _bg_mgr:AdvBgMgr  = null

# レイヤー
onready var _layer_bg   = $LayerBg
onready var _layer_talk = $LayerTalk

func _ready() -> void:
	_script = AdvScript.new(self)
	_talk_text = AdvTalkTextScene.instance()
	_layer_talk.add_child(_talk_text)
	_talk_text.hide()
	_bg_mgr = AdvBgMgr.new([$LayerBg/BellowBg, $LayerBg/AboveBg])

func _process(delta: float) -> void:
	match _state:
		eState.INIT:
			_update_init()
		eState.EXEC:
			_update_exec()
		eState.KEY_WAIT:
			_update_key_wait(delta)
		eState.SEL_WAIT:
			_update_sel_wait(delta)
	
	var idx = 0
	
	_bg_mgr.update(delta)
	
	if _state != _next_state:
		_state = _next_state

# 更新・初期化
func _update_init():
	_script.open("res://assets/adv/adv000.txt")
	_next_state = eState.EXEC

# 更新・実行
func _update_exec():
	_script.update()
	if _script.is_end():
		# 終了
		queue_free()

# 更新・キー待ち
func _update_key_wait(delta:float):
	var ret = _talk_text.update_talk(delta, _msg.get_text())
	match ret:
		"SEL_WAIT":
			_next_state = eState.SEL_WAIT
		"EXEC":
			_msg.clear()
			_next_state = eState.EXEC
		_:
			pass # 続行

# 更新・選択肢
func _update_sel_wait(delta:float):
	var ret = _talk_text.update_select(delta, _script)
	match ret:
		"EXEC":
			_msg.clear()
			_next_state = eState.EXEC
		_:
			pass # 続行

# 背景を表示
func _DRB(args:PoolStringArray) -> int:
	var id  = _script.pop_stack()
	var eft = _script.pop_stack()
	_bg_mgr.draw_bg(id, eft)
	return AdvConst.eRet.CONTINUE
	
# 背景を消去
func _ERB(args:PoolStringArray) -> int:
	var eft = _script.pop_stack()
	_bg_mgr.erase_bg(eft)
	return AdvConst.eRet.CONTINUE

# メッセージ解析
func _MSG(args:PoolStringArray) -> int:
	var is_exit = false
	var type = eCmdMesType.NONE
	if args[0] != "":
		type = int(args[0])
	if type == eCmdMesType.NOTICE:
		# TODO: 通知メッセージ
		return AdvConst.eRet.YIELD
	
	var ret = AdvConst.eRet.CONTINUE
	var texts = args[1]
	_msg.add(texts)
	match type:
		eCmdMesType.CLICK:
			# TODO: 未実装
			pass
		eCmdMesType.PF:
			_next_state = eState.KEY_WAIT
			ret = AdvConst.eRet.YIELD
	
	return ret

# 選択肢のメッセージテキスト
func _SEL(args:PoolStringArray) -> int:
	# テキストの行数
	var cnt = int(args[0])
	for i in range(cnt):
		var texts = args[1 + i]
		_msg.add(texts)
	_talk_text.sel_clear()
	return AdvConst.eRet.CONTINUE

func _SEL_ANS(args:PoolStringArray) -> int:
	var cnt = min(int(args[0]), AdvConst.MAX_SEL_ITEM)
	for i in range(cnt):
		var texts = args[1 + i]
		_talk_text.sel_add(i, texts)
	
	return AdvConst.eRet.CONTINUE

func _SEL_ANS2(args:PoolStringArray) -> int:
	var idx = int(args[0])
	var ret = _script.pop_stack()
	if !ret:
		 # 表示条件を満たさなかったので除外する
		_talk_text.set_exclude(idx)
	return AdvConst.eRet.CONTINUE

func _SEL_GOTO(args:PoolStringArray) -> int:
	_talk_text.sel_addr(args)
	
	# テキスト表示→選択肢へ
	_next_state = eState.KEY_WAIT
	_talk_text.show()
	_talk_text.start()
	return AdvConst.eRet.YIELD
		
