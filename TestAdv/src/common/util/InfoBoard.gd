extends Node2D
# ===================================
# 通知ボード
# ===================================
const MARGIN_Y = 0

const TIMER_INOUT = 0.5
const TIMER_WAIT  = 5.0
const MIN_WIDTH = 320 # 最低保証する幅.

enum eState {
	TO_SHOW,
	SHOW,
	TO_HIDE,
	HIDE,
}

var _label:Label
var _bg:ColorRect

var _state = eState.HIDE
var _timer:float = 0
var _count:int = 1 # 同じ文字を表示した回数
var _text:String = ""
var _yofs:int = 0

func start(s:String, yofs:int, col:Color) -> void:
	position.y = yofs * get_height()
	_yofs = yofs
	_text = s
	_label.text = s
	_state = eState.TO_SHOW
	_timer = TIMER_INOUT
	col.a = 0.5
	_bg.color = col

func count_up() -> void:
	_count += 1
	if _state > eState.TO_SHOW:
		_state = eState.SHOW
		_timer = TIMER_WAIT

func is_same(text:String) -> bool:
	return text == _text

func get_height() -> float:
	return _bg.rect_size.y + MARGIN_Y

func get_yofs() -> int:
	return _yofs

func _ready() -> void:
	_label = $Label
	_bg    = $Bg
	position.x = AdvConst.WINDOW_WIDTH
	#start("INFOBOARDテスト１２３４５６７８９", 0)

func _get_text() -> String:
	return _label.text

func _display_text() -> String:
	if _count > 1:
		return _text + "(%d)"%_count
	return _text

func _calc_width(text:String) -> float:
	# 文字幅を計算する
	var font = _label.get_font("font")
	return max(MIN_WIDTH, font.get_string_size(text).x)

func _process(delta: float) -> void:
	var text = _display_text()
	var w    = _calc_width(text)
	_label.text = text
	_timer = max(0, _timer-delta)
	
	var x2 = AdvConst.WINDOW_WIDTH + 32
	var x1 = AdvConst.WINDOW_WIDTH - w
	
	match _state:
		eState.TO_SHOW:
			var rate = _timer / TIMER_INOUT
			position.x = Ease.step(Easing.eType.EXPO_IN, x1, x2, rate)
			if _timer <= 0:
				_state = eState.SHOW
				_timer = TIMER_WAIT
		eState.SHOW:
			position.x = x1
			if _timer <= 0:
				_state = eState.TO_HIDE
				_timer = TIMER_INOUT
		eState.TO_HIDE:
			var rate = _timer / TIMER_INOUT
			position.x = Ease.step(Easing.eType.EXPO_OUT, x1, x2, 1 - rate)
			if _timer <= 0:
				_state = eState.HIDE
		eState.HIDE:
			# 消滅
			queue_free()
