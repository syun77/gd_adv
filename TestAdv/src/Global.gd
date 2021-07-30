extends CanvasLayer

# ===============================
# グローバル変数
# ===============================
const SAVE_FILE = "user://savedata.txt"
const ROOM_PATH = "res://src/escape/room/%3d/EscapeRoom.tscn"

# 現在のルーム番号
var now_room:int = 0 setget _set_now_room, _get_now_room
# 次男ルーム番号
var next_room:int = 0 setget _set_next_room, _get_next_room

var _bits = []
var _vars = []

# フラグと変数を初期化する
func init_bits_and_vars():
	for _i in range(AdvConst.MAX_BIT):
		_bits.append(false)
	for _i in range(AdvConst.MAX_VAR):
		_vars.append(0)

func bit_on(idx:int) -> void:
	bit_set(idx, true)
	
func bit_off(idx:int) -> void:
	bit_set(idx, false)

func bit_set(idx:int, b:bool) -> void:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		print("Error: 不正なフラグ番号 %d"%idx)
		return
	_bits[idx] = b

func bit_chk(idx:int) -> bool:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		print("Error: 不正なフラグ番号 %d"%idx)
		return false
	return _bits[idx]

func var_set(idx:int, val) -> void:
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		print("Error: 不正な変数番号 %d"%idx)
		return
	_vars[idx] = val
	
func var_get(idx:int):
	if idx < 0 or AdvConst.MAX_BIT <= idx:
		print("Error: 不正な変数番号 %d"%idx)
		return 0
	return _vars[idx]
	

# 初期化
func init() -> void:
	# フラグと変数の初期化
	init_bits_and_vars()
	
	# 開始ルーム番号を設定しておく
	now_room = 101
	next_room = now_room

# セーブ処理
func save_data() -> void:
	var f = File.new()
	f.open(SAVE_FILE, File.WRITE)
	var data = _get_save()
	var s = JSON.print(data)
	f.store_string(s)
	f.close()
	
# ロード処理
func load_data() -> void:
	var f:File = File.new()
	if f.file_exists(SAVE_FILE):
		# セーブデータが存在する
		f.open(SAVE_FILE, File.READ)
		var s = f.get_as_text()
		var j = JSON.parse(s)
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
		"bits" : _bits,
		"vars" : _vars,
		"now_room" : now_room,
	}
	return data
func _copy_load(data):
	_bits = data["bits"]
	_vars = data["vars"]
	next_room = data["now_room"]
	

# ルーム変更可能かどうか
func can_change_room() -> bool:
	return now_room != next_room

# スクリプトのパスを取得する
func get_script_path() -> String:
	return "res://assets/adv/adv%03d.txt"%now_room
	
# シーン名で次のシーンを設定する
func set_next_room(name:String) -> void:
	var data = CastleDB.search("scenes", name)
	var v = data["value"]
	if v < 0:
		print("無効なルーム名: %s"%name)
		return
	next_room = v

# ルーム移動を行う
func change_room() -> void:
	var res_name = ROOM_PATH%next_room
	now_room = next_room
	print("ルーム移動: %s"%res_name)
	get_tree().change_scene(res_name)

# 現在のルーム番号のsetter
func _set_now_room(v:int) -> void:
	now_room = v
# 現在のルーム番号のgetter
func _get_now_room() -> int:
	return now_room
# 次のルーム番号のsetter
func _set_next_room(v:int) -> void:
	next_room = v
# 次のルーム番号のgetter
func _get_next_room() -> int:
	return next_room
