extends Sprite

const HIT_RADIUS = 64 # クリック判定の半径
const PATH_ITEM = "res://assets/adv/item/item%03d.png"
const TIMER_CLICK = 1.0

enum eState {
	INIT,
	IDLE,
	CLICK,
	DRAG,
	RETURN,
}

enum eClick {
	JUST_PRESSED,
	PRESSED,
	JUST_RELEASED,
	RELEASED,
}

var item:int = 0 setget _set_item, _get_item

var _state = eState.INIT
var _timer_click = 0
var _start := Vector2()
var _drag_start := Vector2()
var _sprite:Sprite = null
var _item_id:int = 0

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
		eState.RETURN:
			_update_return(delta)
	
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
		_state = eState.IDLE
		return
	
	var d = (get_global_mouse_position() - _drag_start).length()
	if d > 32:
		_state = eState.DRAG

func _update_drag(delta:float) -> void:
	var d = get_global_mouse_position() - position
	position += d * 0.3
	if _is_click(eClick.RELEASED):
		_state = eState.RETURN

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
			check = Input.is_action_just_pressed("ui_click")
		eClick.PRESSED:
			check = Input.is_action_pressed("ui_click")
		eClick.JUST_RELEASED:
			return Input.is_action_just_released("ui_click")
		eClick.RELEASED:
			return (Input.is_action_pressed("ui_click") == false)
	if check == false:
		return false
	var rect = SpriteUtil.get_hitrect(self)
	var mouse_pos = get_global_mouse_position()
	var d = position - mouse_pos
	if d.length() < HIT_RADIUS:	
		return true
	return false

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
