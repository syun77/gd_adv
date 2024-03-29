extends CanvasLayer

# ===============================
# グローバル変数
# ===============================
const SAVE_FILE = "user://savedata.txt"
const ROOM_PATH = "res://src/escape/room/%3d/EscapeRoom.tscn"

const MAX_BACKLOG = 50 # バックログの最大数
const DUPLICATE_CNT = 10 # 10件前に存在する場合はログに追加しない

# 描画順.
const PRIO_CLICKABLE = 1
const PRIO_ITEM_MENU = 10
const PRIO_ADV       = 20
const PRIO_ADV_BG    = 21
const PRIO_ADV_CH    = 22
const PRIO_ADV_ITEM  = 23
const PRIO_ADV_FADE  = 24
const PRIO_ADV_TALK  = 25
const PRIO_ADV_NOTICE = 30
const PRIO_ADV_MENU = 31
const PRIO_ADV_HUD = 32
const PRIO_ADV_LOGS = 33

const LF_BEGIN = Adv.eBit.LF_00 # ローカルフラグ開始番号
const LF_END   = Adv.eBit.LF_15 # ローカルフラグ終了番号
const LVAR_BEGIN = Adv.eVar.LVAR_00 # ローカル変数開始番号
const LVAR_END   = Adv.eVar.LVAR_07 # ローカル変数終了番号

var _initialized := false
var _bits = [] # フラグ
var _vars = [] # 変数
var _items = [] # アイテム
var _local_bits = {} # ローカルフラグ(LF_##)
var _local_vars = {} # ローカル変数(LVAR_##)
var _logs = []

# アイテムの初期化
func init_items():
	for _i in range(AdvConst.MAX_ITEM):
		_items.append(AdvUtilObj.eItemState.NONE)

# フラグと変数を初期化する
func init_bits_and_vars():
	for _i in range(AdvConst.MAX_BIT):
		_bits.append(false)
	for _i in range(AdvConst.MAX_VAR):
		_vars.append(0)
	
	_local_bits.clear()
	_local_vars.clear()

# バックログの初期化
func init_backlog() -> void:
	_logs = []
# ------------------------------
# アイテム
# ------------------------------
func item_get(idx:int):
	return _items[idx]
func item_set(idx:int, state:int) -> void:
	_items[idx] = state

# ------------------------------
# フラグ
# ------------------------------
func bit_on(idx:int) -> void:
	if LF_BEGIN <= idx and idx <= LF_END:
		# ローカルフラグ
		lf_on(idx-LF_BEGIN)
		return
	bit_set(idx, true)
	
func bit_off(idx:int) -> void:
	if LF_BEGIN <= idx and idx <= LF_END:
		# ローカルフラグ
		lf_off(idx-LF_BEGIN)
		return
	bit_set(idx, false)

func bit_set(idx:int, b:bool) -> void:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		Infoboard.error("Error: 不正なフラグ番号 %d"%idx)
		return
	if LF_BEGIN <= idx and idx <= LF_END:
		# ローカルフラグ
		lf_set(idx-LF_BEGIN, b)
		return
	_bits[idx] = b

func bit_chk(idx:int) -> bool:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		Infoboard.error("Error: 不正なフラグ番号 %d"%idx)
		return false
	if LF_BEGIN <= idx and idx <= LF_END:
		# ローカルフラグ
		return lf_chk(idx-LF_BEGIN)
	return _bits[idx]

# ------------------------------
# 変数
# ------------------------------
func var_set(idx:int, val) -> void:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		Infoboard.error("Error: 不正な変数番号 %d"%idx)
		return
	if LVAR_BEGIN <= idx and idx <= LVAR_END:
		# ローカル変数
		lvar_set(idx-LVAR_BEGIN, val)
		return
	
	_vars[idx] = val
	
func var_get(idx:int):
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		Infoboard.error("Error: 不正な変数番号 %d"%idx)
		return 0
	if LVAR_BEGIN <= idx and idx <= LVAR_END:
		# ローカル変数
		return lvar_get(idx-LVAR_BEGIN)

	return _vars[idx]

# ------------------------------
# ローカルフラグ
# ------------------------------
func lf_on(idx:int) -> void:
	lf_set(idx, true)
func lf_off(idx:int) -> void:
	lf_set(idx, false)
func lf_set(idx:int, b:bool) -> void:
	var name = _make_lf_name(idx)
	_local_bits[name] = b
func lf_chk(idx:int) -> bool:
	var name = _make_lf_name(idx)
	return _local_bits.get(name, false)
	
func _make_lf_name(idx:int) -> String:
	return "S%03d_LF%02d"%[now_room, idx]
# ------------------------------
# ローカル変数
# ------------------------------
func lvar_set(idx:int, v) -> void:
	var name = _make_lvar_name(idx)
	_local_vars[name] = v
func lvar_get(idx:int):
	var name = _make_lvar_name(idx)
	return _local_vars.get(name, 0)	

func _make_lvar_name(idx:int) -> String:
	return "S%03d_LVAR%02d"%[now_room, idx]

# 初期化
func init() -> void:
	# フラグと変数の初期化
	init_bits_and_vars()
	# アイテムの初期化
	init_items()
	
	# バックログログの初期化
	init_backlog()
	
	# 開始ルーム番号を設定しておく
	now_room = 101
	next_room = now_room
	
	# 初期化済み
	_initialized = true
	
	if AdvConst.DEBUG:
		# TODO: ウィンドウをリサイズ
		DisplayServer.window_set_size(Vector2(1280*2, 720*2))
		#DisplayServer.window_set_size(Vector2(853, 480))
		#DisplayServer.window_set_size(Vector2(480, 270))

# バックログの追加
func add_backlog(s:String) -> void:
	var idx = _logs.find_last(s)
	if idx >= 0:
		if idx + DUPLICATE_CNT >= _logs.size():
			#Infoboard.send("重複テキスト:%s"%s)
			#Infoboard.send("idx=%d size=%d"%[idx, _logs.size()])
			return # 重複テキスト
	
	if _logs.size() >= MAX_BACKLOG:
		# 最大数を超えた
		_logs.pop_front()
	_logs.append(s)
	
# バックログの取得
func get_backlog():
	return _logs

# 初期化済みかどうか
func initialized() -> bool:
	return _initialized

# セーブ処理
func save_data() -> void:
	# FileAccess.open()はstatic関数
	var f = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	var data = _get_save()
	# JSON.print() は JSON.parse()になりインスタン関数になった.
	var json = JSON.new()
	var s = json.parse(data)
	f.store_string(s)
	f.close()
	
# ロード処理
func load_data() -> void:
	if FileAccess.file_exists(SAVE_FILE):
		# セーブデータが存在する
		var f = FileAccess.open(SAVE_FILE, FileAccess.READ)
		var s = f.get_as_text()
		var json = JSON.new()
		var j = json.parse(s)
		if j.error == OK:
			_copy_load(j.result)
		else:
			# セーブデータが破損していたら初期化する
			init()
	else:
		# 存在しない場合はいったん保存する
		init()
		save_data()

func _get_save():
	var data = {
		"now_room" : now_room,
		"items" : _items,
		"bits" : _bits,
		"vars" : _vars,
		"lf" : _local_bits,
		"lvar" : _local_vars,
		"logs" : _logs,
	}
	return data
func _copy_load(data):
	next_room = data["now_room"]
	_items = data["items"]
	_bits = data["bits"]
	_vars = data["vars"]
	_local_bits = data["lf"]
	_local_vars = data["lvar"]
	_logs = data["logs"]
	

# ルーム変更可能かどうか
func can_change_room() -> bool:
	return now_room != next_room

# スクリプトのパスを取得する
func get_script_path() -> String:
	return "res://assets/adv/adv%03d.txt"%now_room

# アイテムスクリプトのパスを取得する
func get_item_script_path() -> String:
	return "res://assets/adv/advitem.txt"
	
# シーン名で次のシーンを設定する
func set_next_room(name:String) -> void:
	var data = CastleDB.search("scenes", name)
	var v = data["value"]
	if v < 0:
		Infoboard.error("無効なルーム名: %s"%name)
		return
	next_room = v

# ルーム移動を行う
func change_room() -> void:
	var res_name = ROOM_PATH%next_room
	now_room = next_room
	Infoboard.send("ルーム移動: %s"%res_name)
	var _err = get_tree().change_scene_to_file(res_name)

# 現在のルーム番号
var now_room:int = 0:
	# 現在のルーム番号のsetter
	set(v):
		now_room = v
	# 現在のルーム番号のgetter
	get:
		return now_room

# 次のルーム番号
var next_room:int = 0:
	# 次のルーム番号のsetter
	set(v):
		next_room = v
	# 次のルーム番号のgetter
	get:
		return next_room
