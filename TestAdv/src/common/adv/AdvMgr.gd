extends Node2D

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")
# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

const AdvLayerBg       = preload("res://src/common/adv/AdvLayerBg.gd")
const AdvLayerCh       = preload("res://src/common/adv/AdvLayerCh.gd")
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


var _script:AdvScript        = null
var _talk_text:AdvTalkText   = null
var _bg_mgr:AdvLayerBg       = null
var _ch_mgr:AdvLayerCh       = null
var _msg              := AdvTextMgr.new()
var _state            = eState.INIT
var _next_state       = eState.INIT
var _wait             = 0

# レイヤー
onready var _layer_bg   = $LayerBg
onready var _layer_talk = $LayerTalk

func _ready() -> void:
	_script = AdvScript.new(self)
	_talk_text = AdvTalkTextScene.instance()
	_layer_talk.add_child(_talk_text)
	_talk_text.hide()
	_bg_mgr  = AdvLayerBg.new([$AdvLayerBg/BellowBg, $AdvLayerBg/AboveBg])
	_ch_mgr  = AdvLayerCh.new([$AdvLayerCh/LeftCh, $AdvLayerCh/CenterCh, $AdvLayerCh/RightCh])
	
	if AdvConst.DEBUG:
		# TODO: ウィンドウをリサイズ
		OS.set_window_size(Vector2(853, 480))
		#OS.set_window_size(Vector2(480, 270))

func _process(delta: float) -> void:
	
	if AdvConst.DEBUG:
		if Input.is_action_just_pressed("ui_exit"):
			# ESC終了
			get_tree().quit()
	
	match _state:
		eState.INIT:
			_update_init()
		eState.EXEC:
			_update_exec()
		eState.KEY_WAIT:
			_update_key_wait(delta)
		eState.SEL_WAIT:
			_update_sel_wait(delta)
		eState.WAIT:
			_update_wait(delta)
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

# 更新・一時停止
func _update_wait(delta:float):
	_wait -= delta
	if _wait <= 0:
		_next_state = eState.EXEC	

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
	
# 顔ウィンドウ表示
func _FACE(args:PoolStringArray) -> int:
	var id = int(args[0])
	_talk_text.draw_face(id)
	return AdvConst.eRet.CONTINUE
	
# 話者名を表示
func _NAME(args:PoolStringArray) -> int:
	_talk_text.set_name(args[0])
	return AdvConst.eRet.CONTINUE
	
# 顔ウィンドウと話者名を消去する
func _CLS(args:PoolStringArray) -> int:
	_talk_text.erase_face()
	_talk_text.clear_name()
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
			_talk_text.show()
			_talk_text.start()
			_next_state = eState.KEY_WAIT
			ret = AdvConst.eRet.YIELD
	
	return ret

func _WAIT(args:PoolStringArray) -> int:
	_wait = _script.pop_stack() / 60.0
	_next_state = eState.WAIT
	return AdvConst.eRet.YIELD
	
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
		
