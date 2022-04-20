extends Control
# ===================================
# 通知テキスト (自動で消えるテキスト)
# ===================================
const APPEAR_TIME = 1.0
const HIDE_TIME = 0.5
const DISPLAY_TIME = 3.0

enum eState {
	TO_SHOW,  # 表示開始
	SHOW,     # 表示中
	TO_HIDE,  # 消える
	
	HIDE,     # 非表示
}

onready var _layer:CanvasLayer  = $Layer
onready var _bg:ColorRect       = $Layer/Bg
onready var _text:RichTextLabel = $Layer/Text
var _state = eState.HIDE
var _timer:float = 0

func _ready() -> void:
	_layer.layer = Global.PRIO_ADV_NOTICE
	end() # 非表示にしておく

# 表示開始
func start(text:String) -> void:
	# ログに追加
	Global.add_backlog(text)
	_text.bbcode_text = "[center]" + text + "[/center]"
	_timer = APPEAR_TIME
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
				add_rate = _timer / APPEAR_TIME
		eState.SHOW:
			rate = 1
			if _timer <= 0:
				_state = eState.TO_HIDE
				_timer = HIDE_TIME
		eState.TO_HIDE:
			if _timer <= 0:
				end()
			else:
				rate = _timer / HIDE_TIME
				scale_y = ease(rate, 4.8)
	
	if rate > 0:
		_bg.color = Color.black
		_bg.color.a = 0.5 * rate
		_bg.rect_scale.y = scale_y
		if add_rate:
			_bg.color = _bg.color.linear_interpolate(Color.webgray, add_rate)
		_text.modulate.a = rate
	
