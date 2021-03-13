# ===============================
# スクリプト管理
# ===============================

# 代入演算子
const ASSIGN_NON = 0x00
const ASSIGN_ADD = 0x01
const ASSIGN_SUB = 0x02
const ASSIGN_MUL = 0x03
const ASSIGN_DIV = 0x04
const ASSING_BIT = 0x10

var _bits = []
var _vars = []
var _int_stack        = []
var _call_stack       = []
var _pc:int           = 0
var _max_pc:int       = 0
var _previous_pc:int  = 0
var _diff_pc:float    = 0.0
var _script_data      = []
var _start_funcname   := "" # 開始関数名
var _funcname         := "" # 現在実行中の関数名
var _is_end           := false
var _parent           = null;

# 初期化
func _init(parent) -> void:
	for i in range(256):
		_bits.append(false)
	for i in range(128):
		_vars.append(0)
	_parent = parent

# スクリプトファイルを読み込む
func open(path:String) -> bool:
	# TODO: ファイル存在チェック
	# スクリプトを読み込む
	var file = File.new()
	file.open(path, File.READ)
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
	
	return true

# 終了したかどうか
func is_end() -> bool:
	return _is_end

# 更新
func update() -> void:
	while is_end() == false:
		var ret := _loop()
		match ret:
			Adv.eRet.CONTINUE: # 続行
				pass
			Adv.eRet.YIELD:    # いったん抜ける
				break
			Adv.eRet.EXIT:     # 強制終了
				_is_end = true
				break
			_:
				print("不正な戻り値: %d"%ret)
				_is_end = true # 強制終了

# ループ処理
func _loop() -> int:
	var cnt = 0 # 無限ループ防止用
	while cnt < 1000:
		cnt += 1
		if _pc >= _max_pc:
			# TODO: ジャンプ先がある場合は読み込みし直す
			# スクリプト終了
			return Adv.eRet.EXIT
		
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
		var ret = _parse_command(cmd, args)
		if ret != Adv.eRet.CONTINUE:
			return ret
		
	return Adv.eRet.CONTINUE

# コマンド解析
func _parse_command(cmd:String, args:PoolStringArray) -> int:
	match cmd:
		_:
			# 親で実装したコマンドを呼び出す
			var method = "_" + cmd
			if _parent.has_method(method):
				return _parent.call(method, args)
			else:
				print("Error: 未実装のコマンド %s"%cmd, args)
				return Adv.eRet.CONTINUE
	
