# ===============================
# スクリプト管理
# ===============================

class_name AdvScript

# 代入演算子
const ASSIGN_NON = 0x00
const ASSIGN_ADD = 0x01
const ASSIGN_SUB = 0x02
const ASSIGN_MUL = 0x03
const ASSIGN_DIV = 0x04
const ASSING_BIT = 0x10

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
var _parent           = null
var _func_tbl         = {}

# 初期化
func _init(parent) -> void:
	_parent = parent

# スクリプトファイルを読み込む
func open(path:String) -> bool:
	# ファイル存在チェック
	var file = File.new()
	if file.file_exists(path) == false:
		# 読み込み失敗
		return false
		
	# スクリプトを読み込む
	file.open(path, File.READ)
	# すべて読み込む
	var text = file.get_as_text()
	
	var addr = -1
	for line in text.split("\n"):
		addr += 1
		var data = line.split(",")
		if data.size() <= 0:
			continue
		_script_data.append(data)
		
		# 関数名と開始アドレスを保持しておく
		var cmd = data[0]
		if cmd == "FUNC_START":
			var name = data[1]
			_func_tbl[name] = addr
		
	_max_pc = _script_data.size()
	
	file.close()
	
	# 各種変数を初期化
	_previous_pc = _pc
	_int_stack.clear()
	_call_stack.clear()
	
	return true

# 指定の関数名にジャンプする
func jump_funcname(funcname:String) -> bool:
	if funcname in _func_tbl:
		# ジャンプできた
		_pc = _func_tbl[funcname]
		return true
	return false # 見つからなかった

# 終了したかどうか
func is_end() -> bool:
	return _is_end

# 更新
func update() -> void:
	while is_end() == false:
		var ret := _loop()
		match ret:
			AdvConst.eRet.CONTINUE: # 続行
				pass
			AdvConst.eRet.YIELD:    # いったん抜ける
				break
			AdvConst.eRet.EXIT:     # 強制終了
				_is_end = true
				break
			_:
				Infoboard.error("不正な戻り値: %d"%ret)
				_is_end = true # 強制終了

# ループ処理
func _loop() -> int:
	var cnt = 0 # 無限ループ防止用
	while cnt < 1000:
		cnt += 1
		if _pc >= _max_pc:
			# TODO: ジャンプ先がある場合は読み込みし直す
			# スクリプト終了
			return AdvConst.eRet.EXIT
		
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
		if ret != AdvConst.eRet.CONTINUE:
			return ret
		
	return AdvConst.eRet.CONTINUE

func push_stack(v) -> void:
	_int_stack.push_back(v)
func pop_stack():
	return _int_stack.pop_back()
func _push_callstack(v) -> void:
	_call_stack.push_back(v)
func _pop_callstack():
	return _call_stack.pop_back()
func _get_callstack_size():
	return _call_stack.size()

# コマンド解析
func _parse_command(cmd:String, args:PoolStringArray) -> int:
	var method = "_" + cmd
	if has_method(method):
		# システム関数
		call(method, args)
	else:
		# 親で実装したコマンドを呼び出す
		if _parent.has_method(method):
			return _parent.call(method, args)
		else:
			Infoboard.error("Error: 未実装のコマンド %s"%cmd)
	return AdvConst.eRet.CONTINUE

func _BOOL(args) -> void:
	var p0 = int(args[0]) != 0
	push_stack(p0)
func _INT(args) -> void:
	var p0 = int(args[0])
	push_stack(p0)
func _FLOAT(args) -> void:
	var p0 = float(args[0])
	push_stack(p0)
func _STRING(args) -> void:
	var p0 = args[0]
	push_stack(p0)
func _SET(args) -> void:
	var op  = int(args[0])
	var idx = int(args[1])
	var val = pop_stack()
	if op == ASSING_BIT:
		# フラグ
		Global.bit_set(idx, val)
		return
	
	# 変数
	var result = Global.var_get(idx)
	
	match op:
		ASSIGN_NON:
			result = val
		ASSIGN_ADD:
			result += val
		ASSIGN_SUB:
			result -= val
		ASSIGN_MUL:
			result *= val
		ASSIGN_DIV:
			result /= val
	
	Global.var_set(idx, result)

func _ADD(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left + right)
	
func _SUB(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left - right)

func _MUL(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left * right)
	
func _DIV(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left / right)

func _BIT(args) -> void:
	var idx = int(args[0])
	var bit = Global.bit_chk(idx)
	push_stack(bit)	
	
func _VAR(args) -> void:
	var idx = int(args[0])
	var val = Global.var_get(idx)
	push_stack(val)

# '=='
func _EQ(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left == right)

# '!='
func _NE(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left != right)

# '<'	
func _LE(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left < right)

# '<='	
func _LESS(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left <= right)

# '>'	
func _GE(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left > right)

# '>='	
func _GREATER(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left >= right)

# '&&'
func _AND(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left && right)

# '||'
func _OR(_args) -> void:
	var right = pop_stack()
	var left  = pop_stack()
	push_stack(left || right)

# '!'
func _NOT(_args) -> void:
	var right = pop_stack()
	push_stack(!right)

func _IF(args) -> void:
	var val = pop_stack()
	if !val:
		# 演算結果が偽なのでアドレスジャンプする
		var addr = int(args[0])
		_jump(addr)
func _ELIF(args) -> void:
	_IF(args)
	
func _GOTO(args) -> void:
	var addr = int(args[0])
	_jump(addr)

func _WHILE(_args) -> void:
	pass # 特に何もしない (後続するIF文で処理される)

func _CALL(args) -> void:
	var next = _pc # RETURN 後に +1 する
	_push_callstack(next)
	var addr = int(args[0])
	_pc = addr # アドレスジャンプ
	
func _FUNC_START(_args) -> void:
	pass # 何もしない	
	
func _RETURN(_args) -> void:
	if _get_callstack_size() > 0:
		# 呼び出し位置に戻る
		_pc = _pop_callstack()
	else:
		# 強制終了する
		_pc = _max_pc
		
func _FUNC_END(args) -> void:
	_RETURN(args)
	
func _END(_args) -> void:
	# 強制終了
	_pc = _max_pc
	
func _LABEL(_args) -> void:
	# 特に何もしない
	#var label = args[0]
	pass

func _jump(addr:int) -> void:
	# アドレスは -1 した値
	_pc = addr - 1
