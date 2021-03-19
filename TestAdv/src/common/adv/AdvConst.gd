# ===============================
# ADV定数定義
# ===============================
extends Node

class_name AdvConst

const DEBUG           := true # デバッグ有効
const WINDOW_WIDTH    := 1280
const WINDOW_HEIGHT   := 720
const WINDOW_CENTER_X := WINDOW_WIDTH/2
const WINDOW_CENTER_Y := WINDOW_HEIGHT/2

const CH_SLIDE_OFS_X := 64

const MAX_BIT = 256
const MAX_VAR = 128

const MAX_SEL_ITEM = 8

enum eRet {
	CONTINUE = 0, # 続行
	YIELD    = 1, # 一時停止
	EXIT     = 2, # 終了
}

