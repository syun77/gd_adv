extends Node2D

# テキスト速度
const TEXT_SPEED := 50.0

# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")

# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

# 選択肢テキスト
const AdvSelectText = preload("res://src/common/adv/AdvSelectText.tscn")

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

# 選択肢情報
class SelectInfo:
	var index      = 0     # 選択肢番号
	var texts      = null  # テキスト
	var is_exclude = false # 除外するかどうか
	var addr       = 0     # 選択を選んだときのジャンプアドレス
	var button     = null  # 選択ボタン
	func _init(idx:int, txt) -> void:
		index = idx
		texts = txt
	func is_selected() -> bool:
		return button.selected
	func create_button(parent:Node2D, sel_count:int) -> void:
		clear()
		var d = 64
		var ofs_y = d * sel_count / 2
		var py = 240 - ofs_y + (d * index) 
		var pos = Vector2(64, py)
		button = AdvSelectText.instance()
		parent.add_child(button)
		button.start(pos, texts)
	func clear() -> void:
		if button:
			button.destroy()
			button = null

var _script:AdvScript = null
var _timer:float      = 0
var _text_timer:float = 0
var _state            = eState.INIT
var _next_state       = eState.INIT
var _msg              := AdvTextMgr.new()
var _sel_index        = 0 # 選択肢のカーソル
var _sel_list         = [] # 選択肢のテキスト

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
		eState.SEL_WAIT:
			_update_sel_wait(delta)
	
	
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
			if _sel_list.size() > 0:
				# 選択肢に進む
				# 選択肢生成
				for sel in _sel_list:
					sel.create_button(self, _sel_list.size())
				_next_state = eState.SEL_WAIT
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

# 更新・選択肢
func _update_sel_wait(delta:float):
	pass

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
	_sel_list.clear()
	return AdvConst.eRet.CONTINUE

func _SEL_ANS(args:PoolStringArray) -> int:
	var cnt = min(int(args[0]), AdvConst.MAX_SEL_ITEM)
	for i in range(cnt):
		var texts = args[1 + i]
		var info = SelectInfo.new(i, texts)
		_sel_list.append(info)
	
	_sel_index = 0 # カーソル初期化
	return AdvConst.eRet.CONTINUE

func _SEL_ANS2(args:PoolStringArray) -> int:
	var idx = int(args[0])
	var ret = _script.pop_stack()
	if !ret:
		 # 表示条件を満たさなかったので除外する
		_sel_list[idx].is_exclude = true
	return AdvConst.eRet.CONTINUE

func _SEL_GOTO(args:PoolStringArray) -> int:
	var idx = 0
	for info in _sel_list:
		# ジャンプアドレスを設定
		info.addr = int(args[idx])
		idx += 1
	
	var list = []
	for info in _sel_list:
		if info.is_exclude == false:
			# 選択対象
			list.append(info)
	_sel_list = list	
	
	# テキスト表示→選択肢へ
	_next_state = eState.KEY_WAIT
	return AdvConst.eRet.YIELD
		
