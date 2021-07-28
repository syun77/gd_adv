extends Node2D

# Adv管理シーン
const AdvMgr = preload("res://src/common/adv/AdvMgr.tscn")

enum eState {
	INIT,
	MAIN,
	SCRIPT,
}

# デバッグ用フォント
onready var _font:BitmapFont = Control.new().get_font("font")

# クリックできるオブジェクトのレイヤー
var _clickable_layer:CanvasLayer
var _state = eState.INIT
var _script = null

# 開始処理
func _ready() -> void:
	
	# TODO: ひとまずここでフラグを初期化
	AdvUtil.init()
	
	_clickable_layer = $"../../RoomLayer/ClickableLayer"
	for obj in _clickable_layer.get_children():
		obj.visible = false # いったんすべて非表示にしておく
		
	if AdvConst.DEBUG:
		# TODO: ウィンドウをリサイズ
		OS.set_window_size(Vector2(853, 480))
		#OS.set_window_size(Vector2(480, 270))

# 更新
func _process(delta: float) -> void:
	match _state:
		eState.INIT:
			_update_init(delta)
		eState.MAIN:
			_update_main(delta)
		eState.SCRIPT:
			_update_script(delta)
			
	if _state >= eState.MAIN:
		# オブジェクトの表示状態を更新する
		for obj in _clickable_layer.get_children():
			obj.visible = _obj_visibled(obj)

# 更新 > 初期化
func _update_init(delta:float) -> void:
	var room_id = 102
	var scene = CastleDB.search_from_value("scenes", room_id)
	for obj in _clickable_layer.get_children():
		CastleDB.scene_to_set_obj(scene, obj)
		
	_state = eState.MAIN

# 更新 > メイン
func _update_main(delta:float) -> void:
	
	var children = _clickable_layer.get_children()

	# クリックしたかどうか	
	var clicked = Input.is_action_just_pressed("ui_click")
	# マウスカーソルの位置を取得
	var mx = get_global_mouse_position().x
	var my = get_global_mouse_position().y
	
	# 前面から処理したいので逆順でループを回す
	for i in range(children.size()-1, -1, -1):
		if clicked == false:
			continue
		
		var spr:Sprite = children[i]
		# クリックしたので当たり判定チェック
		var hit_rect:Rect2 = _spr_to_hitrect(spr)
		var x1 = hit_rect.position.x
		var y1 = hit_rect.position.y
		var x2 = x1 + hit_rect.size.x
		var y2 = y1 + hit_rect.size.y
		
		if x1 <= mx and mx <= x2 and y1 <= my and my <= y2:
			if _obj_clickable(spr):
				var start_funcname = spr.get_meta("click")
				_script = AdvMgr.instance()
				_script.init(start_funcname)
				add_child(_script)
				_state = eState.SCRIPT
				return
		
	update()

# 更新 > スクリプト実行中
func _update_script(delta:float) -> void:
	if is_instance_valid(_script) == false:
		# スクリプト終了
		_state = eState.MAIN

# オブジェクトを更新
func _obj_visibled(obj:Node2D) -> bool:
	if obj.has_meta("hidden"):
		if obj.get_meta("hidden"):
			return false
	
	var is_on = false
	var is_off = false
	if obj.has_meta("on"):
		# ONフラグ
		var bit = CastleDB.bit_to_value(obj.get_meta("on"))
		is_on = AdvUtil.bit_chk(bit)
	if obj.has_meta("off"):
		# OFFフラグ
		var bit = CastleDB.bit_to_value(obj.get_meta("off"))
		is_off = AdvUtil.bit_chk(bit)
	
	if is_off:
		# 非表示
		return false
	
	if is_on == false:
		if obj.has_meta("on"):
			# 非表示
			return false
	
	# 表示する
	return true
	
	
func _obj_clickable(obj:Node2D) -> bool:
	if obj.has_meta("click") == false:
		return false
	
	var is_on = false
	var is_off = false
	if obj.has_meta("on"):
		# ONフラグ
		var bit = CastleDB.bit_to_value(obj.get_meta("on"))
		is_on = AdvUtil.bit_chk(bit)
	if obj.has_meta("off"):
		# OFFフラグ
		var bit = CastleDB.bit_to_value(obj.get_meta("off"))
		is_off = AdvUtil.bit_chk(bit)
	
	if is_off:
		# クリックできない
		return false
	
	if is_on == false:
		if obj.has_meta("on"):
			# クリックできない
			return false

	# クリックできる	
	return true

# 当たり判定の矩形を取得する	
func _spr_to_hitrect(spr:Sprite) -> Rect2:
	var pos:Vector2 = spr.position
	var rect:Rect2 = spr.get_rect()
	rect.size.x *= spr.scale.x
	rect.size.y *= spr.scale.y
	if spr.centered:
		pos.x -= rect.size.x/2
		pos.y -= rect.size.y/2
	rect.position = pos
	return rect

# デバッグ用描画.
func _draw() -> void:
	for obj in _clickable_layer.get_children():
		var spr:Sprite = obj
		var rect:Rect2 = _spr_to_hitrect(spr)
		draw_rect(rect, Color.red, false)
		var text = "%s: (%d,%d) (%d,%d)"%[obj.name, rect.position.x, rect.position.y, rect.size.x, rect.size.y]
		draw_string(_font, rect.position, text)
		rect.position.y += 24
		var text2 = ""
		if obj.has_meta("on"):
			text2 += "on:%s "%obj.get_meta("on")
		if obj.has_meta("off"):
			text2 += "off:%s "%obj.get_meta("off")
		draw_string(_font, rect.position, text2)
