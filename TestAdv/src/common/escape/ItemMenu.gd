extends Control

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
	var px = 320 + 160 * (idx % 4)
	var py = 64  + 160 * floor(idx / 4)
	return Vector2(px, py)

func _update_item_list():
	var start = Adv.eItem.ITEM_DUMMY + 1
	var idx = 0
	for item_id in range(start, AdvConst.MAX_ITEM):
		if AdvUtil.item_has(item_id):
			var btn = ItemButton.instance()
			btn.item = item_id
			btn.position = _idx_to_position(idx)
			add_child(btn)
			idx += 1

func _on_Button_pressed() -> void:
	_closed = true
