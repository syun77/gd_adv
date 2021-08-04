extends Sprite

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

var _state = eState.INIT
var _timer_click = 0
var _start := Vector2()
var _drag_start := Vector2()
var _sprite:Sprite = null
var _item_id:int = 0
var _locked:bool = false # クリックできない

func is_return_wait() -> bool:
	return _state == eState.RETURN_WAIT

func start_return() -> void:
	_state = eState.RETURN

func _ready() -> void:
	_sprite = $Item

func _process(delta: float) -> void:
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
	else:
		z_index = 0
	
	# クリック演出
	_timer_click = max(0, _timer_click-delta)
	scale = Vector2(1, 1)
	if _timer_click > 0:
		var v = 0.5 + 0.5 * Ease.elastic_out(1.0 - _timer_click/TIMER_CLICK)
		scale *= v
	
	
func _updata_init(delta:float) -> void:
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
	var path = PATH_ITEM%item_id
	var f:File = File.new()
	if f.file_exists(path):
		_sprite.texture = load(path)
		_item_id = item_id
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
	return _state != eState.IDLE
