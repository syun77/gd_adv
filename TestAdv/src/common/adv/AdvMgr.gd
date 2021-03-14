extends Node2D

# テキスト速度
const TEXT_SPEED := 50.0

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")

# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

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

var _script:AdvScript = null
var _timer:float      = 0
var _text_timer:float = 0
var _state            = eState.INIT
var _next_state       = eState.INIT
var _msg              := AdvTextMgr.new()

onready var _talk_text = $TalkText
onready var _cursor    = $Cursor

func _ready() -> void:
	_script = AdvScript.new(self)
	_talk_text.hide()
	_cursor.hide()

func _process(delta: float) -> void:
	_timer += delta
	match _state:
		eState.INIT:
			_update_init()
		eState.EXEC:
			_update_exec()
		eState.KEY_WAIT:
			_update_key_wait(delta)
	
	
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
	var text = _msg.get_text()
	var text_length = text.length()
	if Input.is_action_just_pressed("ui_accept"):
		# テキスト送り
		if _text_timer < text_length:
			# テキストをすべて表示
			_text_timer = text_length
		else:
			# 次のテキストに進む
			_cursor.hide()
			_msg.clear()
			_text_timer = 0
			_next_state = eState.EXEC
			return
	
	# 会話テキスト表示
	_talk_text.show()
	_text_timer = min(text_length, _text_timer + delta * TEXT_SPEED)
	_talk_text.text = text.left(int(_text_timer))
	
	if _text_timer >= text_length:
		# カーソル表示
		_cursor.show()
		_cursor.rect_position.y = 500 + 8 * abs(sin(_timer * 4))


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
