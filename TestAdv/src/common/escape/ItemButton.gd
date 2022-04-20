extends Sprite
# ===================================
# アイテムボタン
# ===================================
const HIT_RADIUS = 64 # クリック判定の半径
const PATH_ITEM = "res://assets/adv/item/item%03d.png"
const TIMER_CLICK = 1.0

enum eState {
	INIT,
	IDLE,
	CLICK,
	DRAG,
	RETURN_WAIT,
	RETURN,
}

enum eClick {
	JUST_PRESSED,
	PRESSED,
	JUST_RELEASED,
	RELEASED,
}

var item:int = 0 setget _set_item, _get_item
var locked:bool setget _set_locked, _is_locked
var clicked:bool setget ,_is_clicked
var blinked:bool setget _set_blink, _is_blinked
var draggable:bool setget _set_draggable
var timer_delay:float setget _set_timer_delay

var _state = eState.INIT
var _timer_click = 0
var _start := Vector2()
var _drag_start := Vector2()
var _item_id:int = 0
var _locked:bool = false # クリックできない
var _timer_animation:float = 0
var _timer_delay:float = 0
var _blinked:bool = false  # 点滅フラグ
var _draggable:bool = true # ドラッグ操作可能かどうか

onready var _sprite:Sprite = $Item
onready var _btn_blink:Sprite = $ButtonBlink
onready var _label:Label = $Label

func reset() -> void:
	show()
	_state = eState.IDLE
func hide() -> void:
	visible = false
func show() -> void:
	visible = true

func is_return_wait() -> bool:
	return _state == eState.RETURN_WAIT
func is_idle() -> bool:
	return _state == eState.IDLE

func start_return() -> void:
	_state = eState.RETURN
func start_return2(pos:Vector2) -> void:
	_start = pos
	start_return()	

func collide(btn:Node2D) -> bool:
	var d = btn.position - position
	if d.length() < HIT_RADIUS + HIT_RADIUS:
		# 他のボタンと衝突
		return true
	return false

func _ready() -> void:
	_btn_blink.modulate.a = 0.0

func update_manual(delta: float) -> void:

	if _proc_delay(delta):
		return # ディレイ中	
	
	_timer_animation += delta
	match _state:
		eState.INIT:
			_updata_init(delta)
		eState.IDLE:
			_update_idle(delta)
		eState.CLICK:
			_update_click(delta)
		eState.DRAG:
			_update_drag(delta)
		eState.RETURN_WAIT:
			pass
		eState.RETURN:
			_update_return(delta)
	
	if _state >= eState.CLICK:
		# クリックすると最前面に移動する
		z_index = 100
		if _state in [eState.CLICK, eState.DRAG]:
			_btn_blink.modulate.a = 0.5
	else:
		z_index = 0
		if _blinked:
			# 点滅する
			_btn_blink.modulate.a = 0.5 * abs(sin(_timer_animation*4))
		else:
			_btn_blink.modulate.a = 0.0
	
	_proc_click_effect(delta)
	
	_label.text = "状態:%d"%_state
	
func _updata_init(delta:float) -> void:
	if _timer_delay > 0:
		# 遅延タイマーあり
		_timer_delay -= delta
		visible = false
		return
	visible = true
	_start = position
	_state = eState.IDLE

func _update_idle(delta:float) -> void:
	if _is_click(eClick.JUST_PRESSED):
		# クリック開始
		_drag_start = get_global_mouse_position()
		_state = eState.CLICK
		_timer_click = TIMER_CLICK

func _update_click(delta:float) -> void:
	if _is_click(eClick.RELEASED):
		_state = eState.RETURN_WAIT
		return
	
	if _draggable == false:
		return # ドラッグ操作無効.
	
	var d = (get_global_mouse_position() - _drag_start).length()
	if d > 32:
		_state = eState.DRAG

func _update_drag(delta:float) -> void:
	var d = get_global_mouse_position() - position
	position += d * 0.3
	if _is_click(eClick.RELEASED):
		_state = eState.RETURN_WAIT

func _update_return(delta:float) -> void:
	var d = _start - position
	if d.length() < 1:
		position = _start
		_state = eState.IDLE
		return
	
	position += d * 0.3

func _proc_delay(delta:float) -> bool:
	# クリック演出
	if _timer_delay > 0:
		# 遅延タイマーあり
		_timer_delay -= delta
		visible = false # 非表示にしておく
		return true # ディレイ中
	
	visible = true
	return false

func _proc_click_effect(delta:float) -> void:
	_timer_click = max(0, _timer_click-delta)
	scale = Vector2(1, 1)
	if _timer_click > 0:
		var v = 0.5 + 0.5 * Ease.elastic_out(1.0 - _timer_click/TIMER_CLICK)
		scale *= v
	else:
		if _state in [eState.CLICK, eState.DRAG]:
			# 拡縮アニメーション
			scale *= 1 + 0.02 * sin(_timer_animation * 12)

func _is_click(state:int) -> bool:
	var check = false
	match state:
		eClick.JUST_PRESSED:
			if locked:
				return false # ロック中は常に false
			check = Input.is_action_just_pressed("ui_click")
		eClick.PRESSED:
			if locked:
				return false # ロック中は常に false
			check = Input.is_action_pressed("ui_click")
		eClick.JUST_RELEASED:
			if locked:
				return true # ロック中は常に true
			return Input.is_action_just_released("ui_click")
		eClick.RELEASED:
			if locked:
				return true # ロック中は常に true
			return (Input.is_action_pressed("ui_click") == false)
	if check == false:
		return false
	var rect = SpriteUtil.get_hitrect(self)
	var mouse_pos = get_global_mouse_position()
	var d = position - mouse_pos
	if d.length() < HIT_RADIUS:	
		return true
	return false

# ------------------------------------
# setter / getter
# ------------------------------------
# アイテム
func _set_item(item_id:int) -> void:
	if item_id == AdvUtil.ITEM_INVALID:
		# 何も装備していない
		_sprite.visible = false
		_item_id = item_id
		return
	
	if _item_id == item_id:
		# 装備中のアイテム
		return
	
	var path = PATH_ITEM%item_id
	var f:File = File.new()
	if f.file_exists(path):
		_sprite.visible = true
		_sprite.texture = load(path)
		_item_id = item_id
		# クリックの演出のみ行う
		_timer_click = TIMER_CLICK
	else:
		Infoboard.error("%sが見つかりません"%path)
func _get_item() -> int:
	return _item_id

# ロックフラグ
func _set_locked(b:bool) -> void:
	_locked = b
func _is_locked() -> bool:
	return _locked

# クリックしているかどうか
func _is_clicked() -> bool:
	return _state == eState.CLICK

# 点滅フラグ
func _set_blink(b:bool) -> void:
	_blinked = b
func _is_blinked() -> bool:
	return _blinked

# ドラッグ可能かどうか
func _set_draggable(b:bool) -> void:
	_draggable = b

# 出現ディレイタイマーの設定
func _set_timer_delay(t:float) -> void:
	_timer_delay = t
	visible = false # 非表示にしておく
