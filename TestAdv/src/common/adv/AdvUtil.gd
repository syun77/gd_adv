# ===============================
# ADV共通
# ===============================
extends Node

class_name Adv

const MAX_BIT = 256
const MAX_VAR = 128

enum eRet {
	CONTINUE = 0, # 続行
	YIELD    = 1, # 一時停止
	EXIT     = 2, # 終了
}

var _bits = []
var _vars = []

func init():
	for i in range(MAX_BIT):
		_bits.append(false)
	for i in range(MAX_VAR):
		_vars.append(0)

func bit_on(idx:int) -> void:
	bit_set(idx, true)
	
func bit_off(idx:int) -> void:
	bit_set(idx, false)

func bit_set(idx:int, b:bool) -> void:
	if idx < 0 or MAX_BIT <= idx:
		print("Error: 不正なフラグ番号 %d"%idx)
		return
	_bits[idx] = b

func bit_chk(idx:int) -> bool:
	if idx < 0 or MAX_BIT <= idx:
		print("Error: 不正なフラグ番号 %d"%idx)
		return false
	return _bits[idx]

func var_set(idx:int, val) -> void:
	if idx < 0 or MAX_BIT <= idx:
		print("Error: 不正な変数番号 %d"%idx)
		return
	_vars[idx] = val
	
func var_get(idx:int):
	if idx < 0 or MAX_BIT <= idx:
		print("Error: 不正な変数番号 %d"%idx)
		return 0
	return _vars[idx]
	
