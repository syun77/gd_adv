extends Control

# =============================================
# アイテムメニュー
# =============================================
const MAX_LINE = 5
const START_X = 320
const START_Y = 192
const SIZE_W  = 160
const SIZE_H  = 160

enum eState {
	MAIN,       # メイン処理
	BTN_CLICK,  # アイテムボタンクリック中
	SCRIPT      # スクリプト実行中
	BTN_RETURN, # ボタン戻る処理
}

# アイテムボタン
const ItemButton = preload("res://src/common/escape/ItemButton.tscn")
# ADV管理
const AdvMgrObj = preload("res://src/common/adv/AdvMgr.tscn")

var _state = eState.MAIN
var _script:AdvMgr = null
var _closed = false
var _clicked_btn = null # クリックしているボタン
var _overlaped_btn = null # 重なっているボタン
var _menu_btn = null # メニューボタン

onready var _item_layer = $ItemLayer
onready var _bg = $Bg

func _ready() -> void:
	_bg.modulate.a = 0
	
	_item_layer.layer = Global.PRIO_ITEM_MENU
	
	_menu_btn = ItemButton.instance()
	_menu_btn.position = AdvConst.ITEM_MENU_BTN_POS
	_menu_btn.draggable = false # ドラッグ操作無効
	add_child(_menu_btn)
	
	if AdvConst.DEBUG:
		if Global.initialized() == false:
			# グローバル変数を初期化
			Global.init()
		
			# デバッグ用でアイテムを所持したい場合はここに追加する.
			#AdvUtil.item_add(Adv.eItem.ITEM_COLOR_RED)
		
		_update_item_list()

func _process(delta: float) -> void:
	#Infoboard.send("state:%d"%_state)
	
	_bg.modulate.a = min(0.9, _bg.modulate.a + (delta*2))
	
	if _closed:
		# 閉じたら何もせずに終了
		queue_free()
		return

	match _state:
		eState.MAIN:
			_update_main(delta)
		eState.BTN_CLICK:
			_update_btn_click(delta)
		eState.SCRIPT:
			_update_script(delta)
		eState.BTN_RETURN:
			_update_btn_return(delta)

	if _state != eState.SCRIPT:
		# スクリプト更新中でなければボタンを更新する
		for btn in _item_layer.get_children():
			btn.update_manual(delta)

func _update_main(delta:float) -> void:
	# メニューボタンを優先して更新
	# 装備中のアイテムを取得
	var item_id = Global.var_get(Adv.eVar.ITEM)
	_menu_btn.item = item_id
	_menu_btn.update_manual(delta)
	if _menu_btn.clicked:
		# メニューボタンが押されたら閉じる
		_closed = true
		return
	
	var clicked_idx = _get_clicked_idx()
	if clicked_idx >= 0:
		# ボタンクリック処理へ
		# クリックしているボタン以外はロックする
		var idx = 0
		for btn in _item_layer.get_children():
			if idx != clicked_idx:
				btn.locked = true
			idx += 1
		_state = eState.BTN_CLICK

func _update_btn_click(_delta:float) -> void:
	# 衝突判定
	_overlaped_btn = _get_nearest_collide_btn(_clicked_btn)
	
	# 点滅解除
	for btn in _item_layer.get_children():
		btn.blinked = false
	
	# クリックしているボタン番号を取得する
	if _clicked_btn.is_return_wait():
		# ボタンを離したのでロックを解除する
		for btn in _item_layer.get_children():
			btn.locked = false
			btn.blinked = false
		# スクリプトを実行する
		var item2 = AdvUtilObj.ITEM_INVALID
		if _overlaped_btn:
			item2 = _overlaped_btn.item
		_start_script(_clicked_btn.item, item2)
		_state = eState.SCRIPT
		return
	
	if _overlaped_btn:
		# 衝突していたら点滅
		_overlaped_btn.blinked = true
		

func _update_script(_delta:float) -> void:
	if is_instance_valid(_script) == false:
		# スクリプト終了
		# ボタンを更新
		_update_item_list()
		# ボタンを元の位置に戻す
		_clicked_btn.start_return()
		# 選んだボタンのアイテムを装備する
		var _can_equip = AdvUtil.item_equip(_clicked_btn.item)
		
		_state = eState.BTN_RETURN

func _update_btn_return(_delta:float) -> void:
	if is_instance_valid(_clicked_btn) == false:
		_state = eState.MAIN
	elif _clicked_btn.is_idle():
		_state = eState.MAIN
	
func _start_script(item1:int, item2:int) -> void:
	# アイテム用スクリプトを実行する
	Global.var_set(Adv.eVar.CRAFT1, item1) # 合成アイテム1
	Global.var_set(Adv.eVar.CRAFT2, item2) # 合成アイテム2
	
	var path = Global.get_item_script_path()
	_script = AdvMgrObj.instance()
	_script.start(path, "")
	add_child(_script)

func _get_nearest_collide_btn(this:Node2D) -> Node2D:
	var id = this.get_instance_id()
	var nearest_obj = null
	var length = 99999.0
	for btn in _item_layer.get_children():
		if id == btn.get_instance_id():
			continue
		var d = btn.position - this.position
		if d.length() < length:
			length = d.length()
			nearest_obj = btn
	
	if nearest_obj:
		# 衝突している
		if this.collide(nearest_obj):
			return nearest_obj
	
	return null

func _get_clicked_idx() -> int:
	var idx = 0
	for btn in _item_layer.get_children():
		if btn.clicked:
			_clicked_btn = btn
			return idx
		idx += 1
	
	# クリックしているボタンはない
	_clicked_btn = null
	return -1

func _idx_to_position(idx:int) -> Vector2:
	var px = START_X + SIZE_W * (idx % MAX_LINE)
	var py = START_Y + SIZE_H * floor(1.0 * idx / MAX_LINE)
	return Vector2(px, py)

func _update_item_list():
	var start = Adv.eItem.ITEM_DUMMY + 1
	
	# 存在しないアイテムを削除する
	for item_id in range(start, AdvConst.MAX_ITEM):
		if AdvUtil.item_has(item_id) == false:
			for btn in _item_layer.get_children():
				if btn.item == item_id:
					btn.queue_free()
	
	var idx = _item_layer.get_child_count()
	for item_id in range(start, AdvConst.MAX_ITEM):
		if AdvUtil.item_has(item_id):
			if _exists_item(item_id) == false:
				# 存在しなければ登録する
				var btn = ItemButton.instance()
				btn.position = _idx_to_position(idx)
				btn.timer_delay = 0.05 * idx
				_item_layer.add_child(btn)
				btn.item = item_id # _ready() をしないとSpriteが存在しない
				idx += 1

	idx = 0
	for btn in _item_layer.get_children():
		if btn.is_queued_for_deletion():
			continue
		var pos = _idx_to_position(idx)
		btn.start_return2(pos)
		idx += 1

func _exists_item(item_id:int) -> bool:
	for btn in _item_layer.get_children():
		if btn.item == item_id:
			return true
	return false

func _on_Button_pressed() -> void:
	_closed = true
