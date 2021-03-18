extends Node2D

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")
# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

const AdvLayerBg       = preload("res://src/common/adv/AdvLayerBg.gd")
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
	END,
}

# メッセージの種類
enum eCmdMesType {
	NONE   = 0, # 改行なし
	PF     = 1, # 改行する
	CLICK  = 2, # クリック待ち
	NOTICE = 9, # 通知
}

const FADE_TIME = 0.5

enum eChState {
	HIDE,
	TO_SHOW,
	SHOW,
	TO_HIDE,
}

enum eChPos {
	LEFT,
	CENTER,
	RIGHT,
}

class AdvCh:
	var ch:TextureRect = null
	var _pos:int  = 0 # 位置
	var _eft:int  = Adv.eConst.EF_NONE # 演出種別
	var _time     := 0.0 # 汎用タイマー
	var _state    = eChState.HIDE # 状態
	var _xbase    = 0 # 基準座標
	func _init(pos:int, ch_rect:TextureRect):
		_pos = pos
		ch = ch_rect
		_xbase = ch.rect_position.x
	func load_texture(id:int):
		ch.texture = load("res://assets/ch/ch%03d.png"%id)
	func dispose_texture():
		ch.texture = null
		_state = eChState.HIDE
	
	func is_appear() -> bool:
		if _state in [eChState.TO_SHOW, eChState.SHOW]:
			return true # 表示中
		return false
	
	func update(delta:float):
		match _state:
			eChState.HIDE:
				ch.texture = null
			eChState.TO_SHOW:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_in(rate)
				if _time >= FADE_TIME:
					ch.rect_position.x = _xbase
					_time = 0
					_state = eChState.SHOW
			eChState.SHOW:
				ch.modulate = Color.white
			eChState.TO_HIDE:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_out(rate)
				if _time >= FADE_TIME:
					_time = 0
					_state = eChState.HIDE
	
	# 表示演出開始
	func appear(eft:int):
		if _pos == eChPos.CENTER:
			# 中央揃えが必要
			var w = ch.texture.get_width()
			_xbase = AdvConst.WINDOW_CENTER_X - w/2
		ch.rect_position.x = _xbase
		
		_eft = eft
		if _state in [eChState.HIDE, eChState.TO_HIDE]:
			_state = eChState.TO_SHOW
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eChState.SHOW # 演出なし
		
	
	# 消滅演出開始
	func disappear(eft:int):
		_eft = eft
		if _state in [eChState.SHOW, eChState.TO_SHOW]:
			_state = eChState.TO_HIDE
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eChState.HIDE # 演出なし

	# フェードイン
	func _update_fade_in(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				ch.modulate = Color(1, 1, 1, rate)
				
			Adv.eConst.EF_SLIDE:
				ch.modulate = Color(1, 1, 1, rate)
				ch.rect_position.x = _xbase + AdvConst.CH_SLIDE_OFS_X * ease(1 - rate, 4.8) # expo in
			_:
				pass
	
	# フェードアウト
	func _update_fade_out(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				ch.modulate = Color(1, 1, 1, 1 - rate)
			Adv.eConst.EF_SLIDE:
				ch.modulate = Color(1, 1, 1, 1 - ease(rate, 0.2))
				ch.rect_position.x = _xbase + AdvConst.CH_SLIDE_OFS_X * ease(rate, 0.2) # expo out
			_:
				pass

class AdvLayerCh:
	var _ch_list = []
	func _init(ch_rect):
		var idx = 0
		for tex_rect in ch_rect:
			var ch = AdvCh.new(idx, tex_rect)
			_ch_list.append(ch)
			idx += 1
	func update(delta:float) -> void:
		for ch in _ch_list:
			ch.update(delta)
	func draw_ch(pos:int, id:int, eft:int) -> void:
		if pos < 0 or _ch_list.size() <= pos:
			print("不正なpos: %d"%pos)
			return
		var ch:AdvCh = _ch_list[pos]
		ch.load_texture(id)
		ch.appear(eft)
	
	func erase_ch(pos:int, eft:int) -> void:
		if pos < 0 or _ch_list.size() <= pos:
			print("不正なpos: %d"%pos)
			return
		var ch:AdvCh = _ch_list[pos]
		ch.disappear(eft)

var _script:AdvScript      = null
var _talk_text:AdvTalkText = null
var _bg_mgr:AdvLayerBg     = null
var _ch_mgr:AdvLayerCh     = null
var _msg              := AdvTextMgr.new()
var _state            = eState.INIT
var _next_state       = eState.INIT

# レイヤー
onready var _layer_bg   = $LayerBg
onready var _layer_talk = $LayerTalk

func _ready() -> void:
	_script = AdvScript.new(self)
	_talk_text = AdvTalkTextScene.instance()
	_layer_talk.add_child(_talk_text)
	_talk_text.hide()
	_bg_mgr = AdvLayerBg.new([$AdvLayerBg/BellowBg, $AdvLayerBg/AboveBg])
	_ch_mgr = AdvLayerCh.new([$AdvLayerCh/LeftCh, $AdvLayerCh/CenterCh, $AdvLayerCh/RightCh])

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
		eState.END:
			# TODO: デバッグ用
			get_tree().change_scene("res://src/common/adv/AdvMgr.tscn")
			#queue_free()


	# 背景管理更新
	_bg_mgr.update(delta)
	# キャラ管理更新
	_ch_mgr.update(delta)
	
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
		# スクリプト終了
		_next_state = eState.END

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

# キャラクターを表示
func _DRC(args:PoolStringArray) -> int:
	var pos = _script.pop_stack()
	var id  = _script.pop_stack()
	var eft = _script.pop_stack()
	_ch_mgr.draw_ch(pos, id, eft)
	
	return AdvConst.eRet.CONTINUE

# キャラクターを消去
func _ERC(args:PoolStringArray) -> int:
	var pos = _script.pop_stack()
	var eft = _script.pop_stack()
	_ch_mgr.erase_ch(pos, eft)
	
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
		
