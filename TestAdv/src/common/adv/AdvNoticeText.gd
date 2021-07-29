extends Control
###########################
# 通知テキスト (自動で消えるテキスト)
###########################
const CHANGE_TIME = 0.5
const DISPLAY_TIME = 3.0

enum eState {
	TO_SHOW,  # 表示開始
	SHOW,     # 表示中
	TO_HIDE,  # 消える
	
	HIDE,     # 非表示
}

onready var _bg:ColorRect       = $Bg
onready var _text:RichTextLabel = $Text
var _state = eState.HIDE
var _timer:float = 0

func _ready() -> void:
	#end() # 非表示にしておく
	start("やっほい")

# 表示開始
func start(text:String) -> void:
	_text.bbcode_text = "[center]" + text + "[/center]"
	_timer = CHANGE_TIME
	_bg.visible = true
	_text.visible = true
	_bg.color.a = 1.0
	_state = eState.TO_SHOW

# 表示終了
func end() -> void:
	_timer = 0
	_state = eState.HIDE
	_bg.visible = false
	_text.visible = false
	
func _process(delta: float) -> void:
	if _timer > 0:
		_timer -= delta
	
	var add_rate:float = 0
	var rate:float = 0
	var scale_y:float = 1
	match _state:
		eState.TO_SHOW:
			if _timer <= 0:
				_state = eState.SHOW
				_timer = DISPLAY_TIME
			else:
				rate = 1
				add_rate = _timer / CHANGE_TIME
		eState.SHOW:
			rate = 1
			if _timer <= 0:
				_state = eState.TO_HIDE
				_timer = CHANGE_TIME
		eState.TO_HIDE:
			if _timer <= 0:
				#end()
				start("ほげ")
			else:
				rate = _timer / CHANGE_TIME
				scale_y = ease(rate, 4.8)
	
	if rate > 0:
		_bg.color = Color.webgray
		_bg.color.a = rate
		_bg.rect_scale.y = scale_y
		if add_rate:
			_bg.color = _bg.color.linear_interpolate(Color.white, add_rate)
		_text.modulate.a = rate
	
