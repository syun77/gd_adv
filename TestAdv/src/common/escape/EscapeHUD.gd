extends CanvasLayer

const LABEL_START_POS = Vector2(AdvConst.WINDOW_WIDTH+32, 16)

var _save_timer = 0.0

onready var _label_save := $LabelSave

func start_save() -> void:
	var tween = Tween.new()
	tween.interpolate_property(
		_label_save,
		"rect_position",
		LABEL_START_POS,
		LABEL_START_POS - Vector2(260, 0),
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	
	tween.interpolate_callback(self, tween.get_runtime(), "_end_save")
	
	add_child(tween)
	tween.start()

func _end_save():
	yield(get_tree().create_timer(3.0), "timeout")
	
	var tween = Tween.new()
	tween.interpolate_property(
		_label_save,
		"rect_position",
		_label_save.rect_position,
		LABEL_START_POS,
		0.5, Tween.TRANS_EXPO, Tween.EASE_IN
	)
	
	add_child(tween)
	tween.start()

func _ready() -> void:
	layer = Global.PRIO_ADV_HUD


func _process(delta:float) -> void:
	if _label_save.rect_position.x < AdvConst.WINDOW_WIDTH:
		# 表示中
		_update_save(delta)

# 更新 > セーブ
func _update_save(delta:float) -> void:
	_save_timer += delta
	var t = int(_save_timer * 4) % 4
	_label_save.text = "Saving"
	for _i in range(t):
		_label_save.text += "."
