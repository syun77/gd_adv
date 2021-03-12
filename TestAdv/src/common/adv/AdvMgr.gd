extends Node2D

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

class AdvTextMgr:
	var msg_list = []
	func _init() -> void:
		msg_list = []
	func clear() -> void:
		msg_list.clear()
	func add(texts) -> void:
		msg_list.append(texts)
	func get_text() -> String:
		var ret = ""
		var idx = 0
		for msg in msg_list:
			if idx > 0:
				ret += "\n"
			ret += msg
			idx += 1
		return ret

var _msg  = AdvTextMgr.new()
var _data = null
var _timer:float      = 0
var _text_timer:float = 0
var _state            = eState.INIT
var _next_state       = eState.INIT
var _int_stack        = []
var _call_stack       = []
var _pc:int          = 0
var _max_pc:int      = 0
var _previous_pc:int = 0
var _diff_pc:float   = 0.0
var _script_data     = []
var _start_funcname  := "" # 開始関数名
var _funcname        := "" # 現在実行中の関数名

onready var _talk_text = $TalkText
onready var _cursor    = $Cursor

func _ready() -> void:
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
	# TODO: ファイル存在チェック
	# スクリプトを読み込む
	var file = File.new()
	file.open("res://assets/adv/adv000.txt", File.READ)
	# すべて読み込む
	var text = file.get_as_text()
	
	for line in text.split("\n"):
		var data = line.split(",")
		if data.size() <= 0:
			continue
		_script_data.append(data)
	_max_pc = _script_data.size()
	
	print(_script_data)
	file.close()
	
	# 各種変数を初期化
	_previous_pc = _pc
	_int_stack.clear()
	_call_stack.clear()
	
	_next_state = eState.EXEC

# 更新・実行
func _update_exec():
	for cnt in range(1000):
		if _pc >= _max_pc:
			# TODO: ジャンプ先がある場合は読み込みし直す
			# スクリプト終了
			queue_free()
			return
		
		# スクリプトデータ取得
		var line = _script_data[_pc]
		print("[SCRIPT]", line)
		
		# コマンドと引数を分割する
		var cmd = line[0]
		var args = []
		for i in range(1, line.size()):
			args.append(line[i])
		
		if _start_funcname != "":
			# 関数を直接呼び出す
			if cmd == "FUNC_START" and args[0] == _start_funcname:
				# 対象の関数が見つかった
				_start_funcname = ""
				_funcname = args[0]
			_pc += 1
			continue # 次の行に進む
		
		_pc += 1
		
		# コマンド解析
		var is_exit = _parse_command(cmd, args)
		if is_exit:
			break # yieldします

# 更新・キー待ち
func _update_key_wait(delta:float):
	if Input.is_action_just_pressed("ui_accept"):
		_cursor.hide()
		_msg.clear()
		_next_state = eState.EXEC
		return
	
	# 会話テキスト表示
	_talk_text.show()
	_talk_text.text = _msg.get_text()
	
	# カーソル表示
	_cursor.show()
	_cursor.rect_position.y = 500 + 8 * abs(sin(_timer * 4))

# コマンド解析
func _parse_command(cmd:String, args:PoolStringArray) -> bool:
	var is_exit = false
	match cmd:
		"MSG":
			is_exit = _parse_message(args)
	
	if _state != _next_state:
		# 状態遷移する
		is_exit = true
	return is_exit

# メッセージ解析
func _parse_message(args:PoolStringArray) -> bool:
	var is_exit = false
	var type = eCmdMesType.NONE
	if args[0] != "":
		type = int(args[0])
	if type == eCmdMesType.NOTICE:
		# TODO: 通知メッセージ
		return is_exit
	
	var texts = args[1]
	_msg.add(texts)
	match type:
		eCmdMesType.CLICK:
			# TODO: 未実装
			pass
		eCmdMesType.PF:
			_next_state = eState.KEY_WAIT
	
	return is_exit
