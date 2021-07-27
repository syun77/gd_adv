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
	_clickable_layer = $"../../RoomLayer/ClickableLayer"
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

# 更新 > 初期化
func _update_init(delta:float) -> void:
	_state = eState.MAIN

# 更新 > メイン
func _update_main(delta:float) -> void:
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
			#_clickable_layer.remove_child(spr)
			var start_funcname = spr.name
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
