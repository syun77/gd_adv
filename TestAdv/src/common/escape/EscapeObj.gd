extends Node2D
################################################
# 脱出シーン管理
################################################

# Adv管理シーン
const AdvMgr = preload("res://src/common/adv/AdvMgr.tscn")
# 移動カーソルオブジェクト
const AdvMoveCursor = preload("res://src/common/adv/AdvMoveCursor.tscn")
# アイテムボタン
const ItemButton = preload("res://src/common/escape/ItemButton.tscn")
# アイテムメニュー
const ItemMenu = preload("res://src/common/escape/ItemMenu.tscn")
# 状態
enum eState {
	INIT,
	MAIN,
	SCRIPT,
	NEXT_ROOM,
	ITEM_MENU,
}

# デバッグ用フォント
onready var _font:BitmapFont = Control.new().get_font("font")

# クリックできるオブジェクトのレイヤー
var _clickable_layer:CanvasLayer
var _moves = []
var _state = eState.INIT
var _script = null
var _script_timer = 0
var _is_init_event = false
var _item_button = null # アイテムボタン
var _item_menu = null # アイテムメニュー

# 開始処理
func _ready() -> void:
	
	_clickable_layer = $"../../RoomLayer/ClickableLayer"
	_clickable_layer.layer = Global.PRIO_CLICKABLE
	for obj in _clickable_layer.get_children():
		obj.visible = false # いったんすべて非表示にしておく

	_item_button = ItemButton.instance()
	_item_button.position = AdvConst.ITEM_MENU_BTN_POS
	_item_button.draggable = false # ドラッグ操作無効.
	_item_button.hide() # 非表示にしておく
	add_child(_item_button)

# 更新
func _process(delta: float) -> void:
	match _state:
		eState.INIT:
			_update_init(delta)
		eState.MAIN:
			_update_main(delta)
		eState.SCRIPT:
			_update_script(delta)
		eState.NEXT_ROOM:
			_update_next_room(delta)
		eState.ITEM_MENU:
			_update_item_menu(delta)
	
	if _state >= eState.MAIN:
		# オブジェクトの表示状態を更新する
		for obj in _clickable_layer.get_children():
			obj.visible = _obj_visibled(obj)
	
	# デバッグ用更新
	if AdvConst.DEBUG:
		_debug_update()

# 更新 > 初期化
func _update_init(_delta:float) -> void:
	var room_id = Global.now_room
	var scene = CastleDB.search_from_value("scenes", room_id)
	for obj in _clickable_layer.get_children():
		CastleDB.scene_to_set_obj(scene, obj)
	for move in scene["moves"]:
		var dir   = move["id"]
		var pos   = _dir_to_pos(dir)
		var jump  = move.get("jump", "")
		var on    = move.get("on", "")
		var off   = move.get("off", "")
		var click = move.get("click", "")
		var obj   = AdvMoveCursor.instance()
		obj.init(pos, dir, jump, click, on, off)
		obj.update_manual(_delta)
		obj.visible = false
		_moves.append(obj)
		add_child(obj)
		
	# ルーム開始イベントを開始
	_start_script("init")
	_is_init_event = true

# 更新 > メイン
func _update_main(delta:float) -> void:

	if AdvConst.DEBUG:
		# デバッグ表示
		update()
	
	# アイテムボタンの更新
	_update_item_button()

	# アイテムボタンを優先して処理
	_item_button.update_manual(delta)
	if _item_button.clicked:
		# アイテムメニューを表示
		_item_menu = ItemMenu.instance()
		add_child(_item_menu)
		
		# アイテムボタンを非表示にする
		_item_button.hide()
		
		_state = eState.ITEM_MENU
		return
	
	# 移動カーソル更新
	for move in _moves:
		move.update_manual(delta)
	
	# クリックしたかどうか	
	var clicked = Input.is_action_just_pressed("ui_click")
	if clicked == false:
		return # クリック判定不要
	# マウスカーソルの位置を取得
	var mx = get_global_mouse_position().x
	var my = get_global_mouse_position().y
	
	# シーン移動オブジェクトのクリック判定
	if _check_movable_obj(mx, my):
		return
	
	# 配置オブジェクトのクリックをチェックする
	if _check_clickable_obj(mx, my):
		return

func _update_item_button() -> void:
	if AdvUtil.item_no_have_any():
		# アイテム未所持の場合はボタンを消す
		_item_button.hide()
		return
	
	# 装備中のアイテムを取得
	var item_id = Global.var_get(Adv.eVar.ITEM)
	_item_button.item = item_id
	_item_button.show()
			
func _check_clickable_obj(mx:float, my:float) -> bool:
	# 前面から処理したいので逆順でループを回す
	var children = _clickable_layer.get_children()
	for i in range(children.size()-1, -1, -1):
		var spr:Sprite = children[i]
		# 当たり判定チェック
		var hit_rect:Rect2 = SpriteUtil.get_hitrect(spr)
		var x1 = hit_rect.position.x
		var y1 = hit_rect.position.y
		var x2 = x1 + hit_rect.size.x
		var y2 = y1 + hit_rect.size.y
		
		if x1 <= mx and mx <= x2 and y1 <= my and my <= y2:
			if _obj_clickable(spr):
				# スクリプト実行
				var start_funcname = spr.get_meta("click")
				_start_script(start_funcname)
				return true

	# 何も実行していない
	return false

# スクリプト開始
func _start_script(func_name:String) -> void:
	_script = AdvMgr.instance()
	var script_path = Global.get_script_path()
	# 開始パラメータを設定
	_script.start(script_path, func_name)
	add_child(_script)
	
	_state = eState.SCRIPT
	_script_timer = 0

func _check_movable_obj(mx:float, my:float) -> bool:
	for move in _moves:
		if move.visible == false:
			continue # 非表示なのでチェック不要
		
		# 当たり判定チェック
		var spr:Sprite = move
		var hit_rect:Rect2 = SpriteUtil.get_hitrect(spr)
		var x1 = hit_rect.position.x
		var y1 = hit_rect.position.y
		var x2 = x1 + hit_rect.size.x
		var y2 = y1 + hit_rect.size.y
		
		if x1 <= mx and mx <= x2 and y1 <= my and my <= y2:
			var jump:String = move.get_jump()
			if jump != "":
				# ルーム移動
				Global.set_next_room(jump)
				_state = eState.NEXT_ROOM
				return true
				
			var click:String = move.get_click()
			if click != "":
				# スクリプト実行
				_start_script(click)
				return true

	# 何も実行していない
	return false
		

# 更新 > スクリプト実行中
func _update_script(delta:float) -> void:
	_script_timer += delta
	
	for move in _moves:
		if _script_timer < 0.1:
			move.update_manual(delta)
		else:
			move.visible = false # 一定時間で非表示にする
		if _is_init_event:
			move.visible = false # ルーム開始イベント中は常に非表示
	
	if is_instance_valid(_script) == false:
		_is_init_event = false
		# スクリプト終了
		if Global.can_change_room():
			# ルーム移動
			_state = eState.NEXT_ROOM
		else:
			_state = eState.MAIN

# 更新 > 次のルームに移動する
func _update_next_room(_delta:float) -> void:
	Global.change_room()

# 更新 > アイテムメニュー
func _update_item_menu(_delta:float) -> void:
	if is_instance_valid(_item_menu) == false:
		# 閉じたのでメイン処理に戻る
		# アイテムボタンをリセットする
		_item_button.reset()
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
		is_on = CastleDB.bit_chk(obj.get_meta("on"))
	if obj.has_meta("off"):
		# OFFフラグ
		is_off = CastleDB.bit_chk(obj.get_meta("off"))
	
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
		is_on = Global.bit_chk(bit)
	if obj.has_meta("off"):
		# OFFフラグ
		var bit = CastleDB.bit_to_value(obj.get_meta("off"))
		is_off = Global.bit_chk(bit)
	
	if is_off:
		# クリックできない
		return false
	
	if is_on == false:
		if obj.has_meta("on"):
			# クリックできない
			return false

	# クリックできる	
	return true
	
func _dir_to_pos(dir:int) -> Vector2:
	var x_left   = 64
	var x_right  = AdvConst.WINDOW_WIDTH - 64
	var x_center = AdvConst.WINDOW_CENTER_X
	var y_top    = 64
	var y_bottom = 640
	var y_center = 320
	match dir:
		AdvUtilObj.eDir.LEFT:
			return Vector2(x_left, y_center)
		AdvUtilObj.eDir.UP:
			return Vector2(x_center, y_top)
		AdvUtilObj.eDir.RIGHT:
			return Vector2(x_right, y_center)
		AdvUtilObj.eDir.DOWN:
			return Vector2(x_center, y_bottom)
		_:
			return Vector2(x_center, y_center)

# デバッグ用描画.
func _draw() -> void:
	for obj in _clickable_layer.get_children():
		var spr:Sprite = obj
		var rect:Rect2 = SpriteUtil.get_hitrect(spr)
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

func _debug_update() -> void:
	if Input.is_action_just_pressed("ui_debug_save"):
		Infoboard.send("Saving...")
		Global.save_data()
	if Input.is_action_just_pressed("ui_debug_load"):
		Infoboard.send("Load Data")
		Global.load_data()
		Global.change_room()
	if Input.is_action_just_pressed("ui_debug_reset"):
		# ゲームをリセットする
		get_tree().change_scene("res://src/Boot.tscn")
		
