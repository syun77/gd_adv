extends Control
# ===================================
# 入力メニュー
# ===================================
class_name EscapeInputMenuObj

# 入力オブジェクト
const EscapeInput = preload("res://src/common/escape/EscapeInput.tscn")

const DIAL_TOP_Y = 120 # 入力オブジェクトのY座標
const DIAL_MARGIN_W = 16
const TIMER_CORRECT = 1.5

# 動作モード
enum eMode {
	NUM, # 数値モード
	KANA, # 文字モード
	PIC, # 画像モード
}

# 状態
enum eState {
	INIT, # 初期化
	MAIN, # メイン
	CORRECT, # 正解
	END, # 終了
}

var _mode:int = eMode.NUM # 動作モード
var _state:int = eState.INIT # 初期化
var _timer:float = 0
var _digit:int = 0 # 桁数
var _var_idx:int = 0 # 保存する変数番号
var _answer_num:int = 0 # 数値の場合の正解
var _answer_kana:String = "" # 文字の場合の正解
var _auto_check:bool = false # 自動で正解チェックを行うかどうか
var _choices:PoolStringArray = [] # 文字入力時の選択文字
var _pic_id:int = 0 # 画像入力の場合のID
var _closed:bool = false # 閉じるボタンを押したかどうか

onready var _input_layer = $InputLayer

# 数値入力開始
func start_num_input(answer:int, var_idx:int, digit:int, auto_check:bool) -> void:
	_mode = eMode.NUM
	_answer_num = answer
	_var_idx = var_idx
	_digit = digit
	_auto_check = auto_check

# 文字入力の開始
func start_kana_input(kana_id:int) -> void:
	_mode = eMode.KANA
	var data = CastleDB.search("kanas", "kana_%03d"%kana_id)
	_answer_kana = data["answer"]
	_var_idx = CastleDB.var_to_value(data["ret"])
	_digit = _answer_kana.length()
	_auto_check = data["auto_check"]
	for choice in data["choices"]:
		_choices.append(choice["moji"])

# 画像入力の開始
func start_pic_input(pic_id:int, answer:int, var_idx:int, digit:int, auto_check:bool) -> void:
	_mode = eMode.PIC
	_pic_id = pic_id
	_answer_num = answer
	_var_idx = var_idx
	_digit = digit
	_auto_check = auto_check

func _ready() -> void:
	# テストデータ
	"""
	start_num_input(
		9
		, Adv.eVar.LVAR_00
		, 4
		, true)
	start_pic_input(
		1
		, 405312
		, Adv.eVar.LVAR_00
		, 6
		, true
	)
	
	if Global.initialized() == false:
		# 初期化していなかったら初期化してしまう
		Global.init()
	"""
	
	# 戻り値初期化
	Global.var_set(Adv.eVar.RET, 0)
	
	_input_layer.layer = Global.PRIO_ADV_MENU + 1

# 数値の生成
func _create_num_input() -> void:
	var tbl = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
	
	# 変数に保存した入力値
	var input_val = int(Global.var_get(_var_idx))
	
	var px = AdvConst.WINDOW_CENTER_X
	var py = DIAL_TOP_Y
	var w = EscapeInputObj.WIDTH
	px -= ((_digit * w) + (_digit - 1) * DIAL_MARGIN_W) * 0.5
	for i in range(_digit):
		var d = _digit - i - 1
		var mod = int(pow(10, _digit - i))
		var v = int((input_val % mod) / pow(10, d))
		
		var obj = EscapeInput.instance()
		obj.rect_position = Vector2(px, py)
		obj.start(tbl, v)
		_input_layer.add_child(obj)
		px += w + DIAL_MARGIN_W

# 文字の生成
func _create_kana_input() -> void:
	
	# 変数に保存した入力値
	var input_val = int(Global.var_get(_var_idx))
	
	var px = AdvConst.WINDOW_CENTER_X
	var py = DIAL_TOP_Y
	var w = EscapeInputObj.WIDTH
	px -= ((_digit * w) + (_digit - 1) * DIAL_MARGIN_W) * 0.5
	var i = 0
	for s in _choices:
		var d = _digit - i - 1
		var mod = int(pow(10, _digit - i))
		var v = int((input_val % mod) / pow(10, d))
		var tbl = []
		for c in s:
			tbl.append(c)
		var obj = EscapeInput.instance()
		obj.rect_position = Vector2(px, py)
		obj.start(tbl, v)
		_input_layer.add_child(obj)
		px += w + DIAL_MARGIN_W
		i += 1

func _create_pic_input() -> void:
	# 変数に保存した入力値
	var input_val = int(Global.var_get(_var_idx))
	
	var px = AdvConst.WINDOW_CENTER_X
	var py = DIAL_TOP_Y
	var w = EscapeInputObj.WIDTH
	px -= ((_digit * w) + (_digit - 1) * DIAL_MARGIN_W) * 0.5
	for i in range(_digit):
		var d = _digit - i - 1
		var mod = int(pow(10, _digit - i))
		var v = int((input_val % mod) / pow(10, d))
		
		var obj = EscapeInput.instance()
		obj.rect_position = Vector2(px, py)
		obj.start_pic(_pic_id, v)
		_input_layer.add_child(obj)
		px += w + DIAL_MARGIN_W
		
# 正解チェック
func _check_correct() -> bool:
	match _mode:
		eMode.NUM, eMode.PIC:
			var ret = _get_input_num()
			return ret == _answer_num
		eMode.KANA:
			var ret = _get_input_kana()
			return ret == _answer_kana
		_:
			# 未実装
			Infoboard.error("EscapeInputMenu._check_correct()が未実装 _mode=%d"%_mode)
			return false

func _get_input_num() -> int:
	var ret:int = 0
	var d = _digit - 1
	for obj in _input_layer.get_children():
		ret += obj.get_idx() * pow(10, d)
		d -= 1
	return ret

func _get_input_kana() -> String:
	var ret:String = ""
	for obj in _input_layer.get_children():
		ret += obj.get_str()
	return ret

func _process(delta: float) -> void:
	match _state:
		eState.INIT:
			_update_init(delta)
		eState.MAIN:
			_update_main(delta)
		eState.CORRECT:
			_update_correct(delta)
		eState.END:
			# 閉じたら終了
			queue_free()
	

# 更新 > 初期化
func _update_init(delta:float) -> void:
	match _mode:
		eMode.NUM:
			# 数値入力の生成
			_create_num_input()
		eMode.KANA:
			# 文字入力の生成
			_create_kana_input()
		eMode.PIC:
			# 画像入力の生成
			_create_pic_input()
	
	_state = eState.MAIN

# 更新 > メイン
func _update_main(delta:float) -> void:
	if _closed:
		if _check_correct():
			# 正解
			Global.var_set(Adv.eVar.RET, 1)
		_state = eState.END
		return
	
	match _mode:
		eMode.NUM, eMode.KANA, eMode.PIC:
			# 入力値を保存する
			if _var_idx >= 0:
				Global.var_set(_var_idx, _get_input_num())
		_:
			pass
	
	if _auto_check:
		# 自動正解判定
		if _check_correct():
			# 正解
			Global.var_set(Adv.eVar.RET, 1)
			_hide_all_buttons()
			for obj in _input_layer.get_children():
				obj.start_blink()
			# 正解演出
			_state = eState.CORRECT
			_timer = TIMER_CORRECT

# 更新 > 正解
func _update_correct(delta:float) -> void:
	_timer -= delta
		
	if _timer <= 0.0:
		_state = eState.END
		_closed = true

# 入力ボタンをすべて非表示にする
func _hide_all_buttons() -> void:
	$Button.hide()
	for obj in _input_layer.get_children():
		obj.hide_button()

func _on_Button_pressed() -> void:
	# 閉じるボタンを押した
	_closed = true
