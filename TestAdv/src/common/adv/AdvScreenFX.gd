extends CanvasLayer

# ==========================================
# ADVフェード
# ==========================================
const FADE_TIME = 0.5

# 動作モード
enum eMode {
	COLOR_RECT,
	SCREEN,
}

# 状態
enum eState {
	IDLE,
	TO_FADE_OUT,
	FADE_OUT,
	TO_FADE_IN,
}

var _state = eState.IDLE
var _timer = 0.0
var _timer_max = 1.0

onready var _screen:TextureRect = $Screen
onready var _color_rect:ColorRect = $ColorRect

func fade_in(color:Color=Color.black, time=FADE_TIME) -> void:
	if _state == eState.TO_FADE_IN:
		# フェードイン中は何もしない
		return
		
	if _state == eState.TO_FADE_OUT:
		# フェードアウト中
		_state = eState.TO_FADE_IN
	else:
		# フェードイン開始
		_color_rect.visible = true
		_color_rect.modulate = color
		_color_rect.modulate.a = 1
		_timer = time
		_timer_max = time
		_state = eState.TO_FADE_IN
	
func fade_out(color:Color=Color.black, time=FADE_TIME) -> void:
	if _state == eState.FADE_OUT:
		# フェードアウト中は何もしない
		return
		
	if _state == eState.TO_FADE_IN:
		# フェードイン中
		_state = eState.TO_FADE_OUT
	else:
		# フェードアウト開始
		_color_rect.visible = true
		_color_rect.modulate = color
		_color_rect.modulate.a = 0
		_timer = time
		_timer_max = time
		_state = eState.TO_FADE_OUT
	
func is_busy() -> bool:
	match _state:
		eState.IDLE, eState.FADE_OUT:
			return false
		_:
			# フェード中
			return true

func is_idle() -> bool:
	return is_busy() == false

func _ready() -> void:
	layer = Global.PRIO_ADV_FADE

# 更新
func _process(delta: float) -> void:
	"""	
	Infoboard.send("satate:%d"%_state)
	
	if Input.is_action_just_pressed("ui_accept"):
		fade_in()
	elif Input.is_action_just_pressed("ui_cancel"):
		fade_out()
	"""
	
	match _state:
		eState.IDLE, eState.FADE_OUT:
			pass # 何もしない
		eState.TO_FADE_IN:
			_update_fade_in(delta)
		eState.TO_FADE_OUT:
			_update_fade_out(delta)

# 更新 > フェードイン
func _update_fade_in(delta:float) -> void:
	_timer -= delta
	if _timer <= 0:
		_color_rect.visible = false
		_state = eState.IDLE
		_timer = 0
	
	_color_rect.modulate.a = (_timer / _timer_max)

# 更新 > フェードアウト
func _update_fade_out(delta:float) -> void:
	_timer -= delta
	if _timer <= 0:
		_state = eState.FADE_OUT
		_timer = 0
	
	_color_rect.modulate.a = 1 - (_timer / _timer_max)

func _capture() -> void:
	# 描画完了を待つ
	yield(VisualServer, "frame_post_draw")
	# ビューポートから画像を取得する
	var img = get_viewport().get_texture().get_data()
	# 上下を逆にする
	img.flip_y()
	# テクスチャを作成
	var tex = ImageTexture.new()
	# 画像データを設定
	tex.create_from_image(img)
	# TextureRectに設定
	_screen.set_texture(tex)
	
	# 画面をリサイズしているときはスケールを調整
	_screen.rect_scale.x = 1.0 * AdvConst.WINDOW_WIDTH/tex.get_width()
	_screen.rect_scale.y = 1.0 * AdvConst.WINDOW_HEIGHT/tex.get_height()
