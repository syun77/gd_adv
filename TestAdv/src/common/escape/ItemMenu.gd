extends Control

var _closed = false

func _ready() -> void:
	if AdvConst.DEBUG:
		# TODO: ウィンドウをリサイズ
		OS.set_window_size(Vector2(853, 480))
		#OS.set_window_size(Vector2(480, 270))
		
		# セーブデータをロードする


func _process(delta: float) -> void:
	if _closed:
		queue_free()


func _on_Button_pressed() -> void:
	_closed = true
