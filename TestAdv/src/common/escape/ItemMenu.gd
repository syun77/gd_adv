extends Control

const MAX_LINE = 4
const START_X = 320
const START_Y = 160
const SIZE_W  = 160
const SIZE_H  = 160

var ItemButton = preload("res://src/common/escape/ItemButton.tscn")

var _closed = false
var _items = []

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
	if _closed:
		queue_free()

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
			add_child(btn)
			btn.item = item_id # _ready() をしないとSpriteが存在しない
			idx += 1

func _on_Button_pressed() -> void:
	_closed = true
