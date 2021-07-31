extends Sprite

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

var _state = eState.INIT
var _start := Vector2()
var _drag_start := Vector2()

func _ready() -> void:
	pass

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
	
func _updata_init(delta:float) -> void:
	_start = position
	_state = eState.IDLE

func _update_idle(delta:float) -> void:
	if _is_click(eClick.JUST_PRESSED):
		_drag_start = get_global_mouse_position()
		_state = eState.CLICK

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
	var mx = get_global_mouse_position().x
	var my = get_global_mouse_position().y
	var x1 = rect.position.x
	var y1 = rect.position.y
	var x2 = x1 + rect.size.x
	var y2 = y1 + rect.size.y
	if x1 <= mx and mx <= x2 and y1 <= my and my <= y2:
		return true
	return false
