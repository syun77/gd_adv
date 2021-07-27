extends Node2D

# デバッグ用フォント
var _font:BitmapFont

# クリックできるオブジェクトのレイヤー
var _clickable_layer:CanvasLayer

# 開始処理
func _ready() -> void:
	_font = Control.new().get_font("font")
	_clickable_layer = $"../../RoomLayer/ClickableLayer"

# 更新
func _process(delta: float) -> void:
	var clicked = Input.is_action_just_pressed("ui_click")
	
	var mx = get_global_mouse_position().x
	var my = get_global_mouse_position().y
	var children = _clickable_layer.get_children()
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
			_clickable_layer.remove_child(spr)
			return
		
	update()

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
