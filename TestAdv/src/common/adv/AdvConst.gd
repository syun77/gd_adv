# ===============================
# ADV定数定義
# ===============================
extends Node

class_name AdvConst

const MAX_BIT = 256
const MAX_VAR = 128

const MAX_SEL_ITEM = 8

enum eRet {
	CONTINUE = 0, # 続行
	YIELD    = 1, # 一時停止
	EXIT     = 2, # 終了
}

