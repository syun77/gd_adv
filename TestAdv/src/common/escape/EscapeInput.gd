extends Control

const PRESS_OFS_Y = 8.0

var _idx = 0
var _char_tbl = []
var _label_pos:Vector2
var _label_yofs:float = 0.0

onready var _label = $Bg/Label

func _ready() -> void:
	_label_pos = _label.rect_position
	
	# テストデータ
	_char_tbl = [
		"1",
		"2",
		"3",
		"4",
		"5",
	]

func _process(delta: float) -> void:
	var num = _char_tbl.size()
	if _idx < 0:
		_idx = num - 1
	if _idx >= num:
		_idx = 0
	
	# クリックアニメーション
	if _label_yofs > 0:
		_label_yofs = max(0, _label_yofs-delta*100)
	if _label_yofs < 0:
		_label_yofs = min(0, _label_yofs+delta*100)
	_label.rect_position = _label_pos + Vector2(0, _label_yofs)

	# テキストを設定
	_label.text = _char_tbl[_idx]

func _on_UpButton_pressed() -> void:
	_idx -= 1
	_label_yofs = -PRESS_OFS_Y


func _on_DownButton_pressed() -> void:
	_idx += 1
	_label_yofs = PRESS_OFS_Y
