extends CanvasLayer

const FADE_TIME = 0.5

enum eBgState {
	HIDE,
	TO_SHOW,
	SHOW,
	TO_HIDE,
}

class AdvBg:
	var bg:TextureRect = null
	var _eft:int  = Adv.eConst.EF_NONE # 演出種別
	var _time     := 0.0 # 汎用タイマー
	var _state    = eBgState.HIDE # 状態
	func _init(bg_rect:TextureRect):
		bg = bg_rect
	func load_texture(id:int):
		bg.texture = load("res://assets/bg/bg%03d.jpg"%id)
	func dispose_texture():
		bg.texture = null
		_state = eBgState.HIDE
	
	func is_appear() -> bool:
		if _state in [eBgState.TO_SHOW, eBgState.SHOW]:
			return true # 表示中
		return false
	
	func update(delta:float):
		match _state:
			eBgState.HIDE:
				bg.texture = null
			eBgState.TO_SHOW:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_in(rate)
				if _time >= FADE_TIME:
					_time = 0
					_state = eBgState.SHOW
			eBgState.SHOW:
				bg.modulate = Color.white
			eBgState.TO_HIDE:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_out(rate)
				if _time >= FADE_TIME:
					_time = 0
					_state = eBgState.HIDE
	
	# 表示演出開始
	func appear(eft:int):
		_eft = eft
		if _state in [eBgState.HIDE, eBgState.TO_HIDE]:
			_state = eBgState.TO_SHOW
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eBgState.SHOW # 演出なし
		
	
	# 消滅演出開始
	func disappear(eft:int):
		_eft = eft
		if _state in [eBgState.SHOW, eBgState.TO_SHOW]:
			_state = eBgState.TO_HIDE
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eBgState.HIDE # 演出なし

	# フェードイン
	func _update_fade_in(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				bg.modulate = Color(1, 1, 1, rate)
			_:
				pass
	
	# フェードアウト
	func _update_fade_out(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				bg.modulate = Color(1, 1, 1, 1 - rate)
			_:
				pass

# ----------------------------------
# メンバ変数
var _bg_list = []

# ----------------------------------
# メンバ関数
func _init(bg_rect):
	var bg1 = AdvBg.new(bg_rect[0])
	_bg_list.append(bg1)
	var bg2 = AdvBg.new(bg_rect[1])
	_bg_list.append(bg2)

func _copy_to_bellow(bg:AdvBg) -> void:
	var bellow:AdvBg = _bg_list[0]
	bellow.bg.texture = bg.bg.texture
	bg.dispose_texture()
	bellow._state = eBgState.SHOW

func draw_bg(id:int, eft:int) -> void:
	var bg:AdvBg = _bg_list[1] # 演出用BG
	if bg.is_appear():
		# 表示中の場合はすぐにコピーする
		_copy_to_bellow(bg)
	bg.load_texture(id)
	bg.appear(eft)
	
func erase_bg(eft:int) -> void:
	var bg:AdvBg = _bg_list[1] # 演出用BG
	if bg.is_appear():
		# 表示中の場合はすぐにコピーする
		_copy_to_bellow(bg)
	var bellow = _bg_list[0]
	bellow.disappear(eft) # 消滅演出開始
	
func update(delta:float) -> void:
	var bg = _bg_list[1] # 演出用BG
	bg.update(delta)
	if bg._state == eBgState.SHOW:
		_copy_to_bellow(bg)
	var bellow = _bg_list[0]
	bellow.update(delta)
