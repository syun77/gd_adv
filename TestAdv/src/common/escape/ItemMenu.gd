extends Control

# =============================================
# アイテムメニュー
# =============================================

const MAX_LINE = 4
const START_X = 320
const START_Y = 160
const SIZE_W  = 160
const SIZE_H  = 160

const ItemButton = preload("res://src/common/escape/ItemButton.tscn")
const AdvMgr = preload("res://src/common/adv/AdvMgr.tscn")

var _script = null
var _closed = false
var _clicked_btn = null # クリックしているボタン
onready var _item_layer = $ItemLayer

func _ready() -> void:
	if AdvConst.DEBUG:
		# TODO: ウィンドウをリサイズ
		OS.set_window_size(Vector2(853, 480))
		#OS.set_window_size(Vector2(480, 270))
		
		# グローバル変数を初期化
		Global.init()
		
		# アイテムを所持していることにする
		AdvUtil.item_add(Adv.eItem.ITEM_COLOR_RED)
		AdvUtil.item_add(Adv.eItem.ITEM_COLOR_ORANGE)
		AdvUtil.item_add(Adv.eItem.ITEM_COLOR_INDIGO)
		AdvUtil.item_add(Adv.eItem.ITEM_COLOR_PURPLE)
		AdvUtil.item_add(Adv.eItem.ITEM_COLOR_GREEN)
		
		_update_item_list()


func _process(delta: float) -> void:
	if is_instance_valid(_script):
		# スクリプト実行中
		return
	
	if _closed:
		# 閉じたら何もしない
		queue_free()
		return
	
	var clicked_idx = _get_clicked_idx()
	if clicked_idx < 0:
		# ロックを解除する
		for btn in _item_layer.get_children():
			btn.locked = false
		return
		
	# クリックしているボタン以外はロックする
	var idx = 0
	for btn in _item_layer.get_children():
		if idx != clicked_idx:
			btn.locked = true
		idx += 1
	
	if _clicked_btn.is_return_wait():
		# リターン待ち
		# スクリプトを実行する
		_start_script()
		
		_clicked_btn.start_return()

func _start_script() -> void:
	# アイテム用スクリプトを実行する
	var path = Global.get_item_script_path()
	_script = AdvMgr.instance()
	_script.start(path, "")
	add_child(_script)

func _get_clicked_idx() -> int:
	var idx = 0
	for btn in _item_layer.get_children():
		if btn.clicked:
			_clicked_btn = btn
			return idx
		idx += 1
	
	# クリックしているボタンはない
	_clicked_btn = null
	return -1

func _idx_to_position(idx:int) -> Vector2:
	var px = START_X + SIZE_W * (idx % MAX_LINE)
	var py = START_Y + SIZE_H * floor(idx / MAX_LINE)
	return Vector2(px, py)

func _update_item_list():
	var start = Adv.eItem.ITEM_DUMMY + 1
	var idx = 0
	for item_id in range(start, AdvConst.MAX_ITEM):
		if AdvUtil.item_has(item_id):
			var btn = ItemButton.instance()
			btn.position = _idx_to_position(idx)
			_item_layer.add_child(btn)
			btn.item = item_id # _ready() をしないとSpriteが存在しない
			idx += 1

func _on_Button_pressed() -> void:
	_closed = true
