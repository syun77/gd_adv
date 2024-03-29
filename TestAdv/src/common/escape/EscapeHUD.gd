extends CanvasLayer
# ===================================
# 脱出HUD
# ===================================
const SAVE_START_POS = Vector2(AdvConst.WINDOW_WIDTH+32, 16)
const PLACE_START_POS = Vector2(-320, 16)
const PLACE_END_POS = Vector2(32, 16)

var _save_timer = 0.0

@onready var _label_save := $LabelSave
@onready var _label_place := $LabelPlace

# セーブ中演出の表示
func start_save() -> void:
	var tween = Tween.new()
	tween.interpolate_property(
		_label_save,
		"rect_position",
		SAVE_START_POS,
		SAVE_START_POS - Vector2(260, 0),
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	
	tween.interpolate_callback(self, tween.get_runtime(), "_end_save")
	
	add_child(tween)
	tween.start()

# セーブ中演出の終了
func _end_save():
	await get_tree().create_timer(3.0).timeout
	
	var tween = Tween.new()
	tween.interpolate_property(
		_label_save,
		"rect_position",
		_label_save.position,
		SAVE_START_POS,
		0.5, Tween.TRANS_EXPO, Tween.EASE_IN
	)
	
	add_child(tween)
	tween.start()

# 場所情報の表示開始
func start_place(name:String) -> void:
	_label_place.text = name
	
	if _label_place.position.x > PLACE_START_POS.x:
		return # 表示済みなので何もしない
	
	var tween = Tween.new()
	tween.interpolate_property(
		_label_place,
		"position",
		PLACE_START_POS,
		PLACE_END_POS,
		0.5, Tween.TRANS_EXPO, Tween.EASE_OUT
	)
	
	tween.interpolate_callback(self, tween.get_runtime(), "_end_save")
	
	add_child(tween)
	tween.start()

# 場所情報の表示をリセットする
func reset_place() -> void:
	_label_place.text = ""
	_label_place.position = PLACE_START_POS

# 場所情報の表示切り替え
func visible_place(b:bool) -> void:
	_label_place.visible = b

# 開始処理
func _ready() -> void:
	layer = Global.PRIO_ADV_HUD

# 更新
func _process(delta:float) -> void:
	if _label_save.position.x < AdvConst.WINDOW_WIDTH:
		# セーブ演出の表示中
		_update_save(delta)

# 更新 > セーブ
func _update_save(delta:float) -> void:
	_save_timer += delta
	var t = int(_save_timer * 4) % 4
	_label_save.text = "Saving"
	for _i in range(t):
		_label_save.text += "."
