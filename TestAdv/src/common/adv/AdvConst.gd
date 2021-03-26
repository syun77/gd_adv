# ===============================
# ADV定数定義
# ===============================
extends Node

class_name AdvConst

const DEBUG           := true # デバッグ有効
const WINDOW_WIDTH    := 1280 # 画面の幅
const WINDOW_HEIGHT   := 720  # 画面の高さ
const WINDOW_CENTER_X := WINDOW_WIDTH/2  # 画面の中央(X)
const WINDOW_CENTER_Y := WINDOW_HEIGHT/2 # 画面の中央(Y)

const MAX_LOG = 50 # ログの最大数

const CH_SLIDE_OFS_X := 64 # キャラクタースライド移動量

const MAX_BIT = 256 # フラグの最大数
const MAX_VAR = 128 # 変数の最大数

const MAX_SEL_ITEM = 8 # 選択肢の最大数

enum eRet {
	CONTINUE = 0, # 続行
	YIELD    = 1, # 一時停止
	EXIT     = 2, # 終了
}

