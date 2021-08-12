extends CanvasLayer

const FADE_TIME = 0.5

enum eChState {
	HIDE,
	TO_SHOW,
	SHOW,
	TO_HIDE,
}

enum eChPos {
	LEFT,
	CENTER,
	RIGHT,
}

class AdvCh:
	var ch:TextureRect = null
	var _pos:int  = 0 # 位置
	var _eft:int  = Adv.eConst.EF_NONE # 演出種別
	var _time     := 0.0 # 汎用タイマー
	var _state    = eChState.HIDE # 状態
	var _xbase    = 0 # 基準座標
	func _init(pos:int, ch_rect:TextureRect):
		_pos = pos
		ch = ch_rect
		_xbase = ch.rect_position.x
	func load_texture(id:int):
		var path = "res://assets/ch/ch%03d.png"%id
		var f = File.new()
		if f.file_exists(path) == false:
			Infoboard.error("[AdvCh]存在しない画像:%s"%path)
			return
		ch.texture = load(path)
	func dispose_texture():
		ch.texture = null
		_state = eChState.HIDE
	
	func is_appear() -> bool:
		if _state in [eChState.TO_SHOW, eChState.SHOW]:
			return true # 表示中
		return false
	
	func update(delta:float):
		match _state:
			eChState.HIDE:
				ch.texture = null
			eChState.TO_SHOW:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_in(rate)
				if _time >= FADE_TIME:
					ch.rect_position.x = _xbase
					_time = 0
					_state = eChState.SHOW
			eChState.SHOW:
				ch.modulate = Color.white
			eChState.TO_HIDE:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_out(rate)
				if _time >= FADE_TIME:
					_time = 0
					_state = eChState.HIDE
	
	# 表示演出開始
	func appear(eft:int):
		match _pos:
			eChPos.CENTER:
				# 中央揃えが必要
				var w = ch.texture.get_width()
				_xbase = AdvConst.WINDOW_CENTER_X - w/2
			eChPos.RIGHT:
				# 右揃えが必要
				var w = ch.texture.get_width()
				_xbase = AdvConst.WINDOW_WIDTH - w
			
		ch.rect_position.x = _xbase
		
		_eft = eft
		if _state in [eChState.HIDE, eChState.TO_HIDE]:
			_state = eChState.TO_SHOW
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eChState.SHOW # 演出なし
		
	
	# 消滅演出開始
	func disappear(eft:int):
		_eft = eft
		if _state in [eChState.SHOW, eChState.TO_SHOW]:
			_state = eChState.TO_HIDE
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eChState.HIDE # 演出なし

	# フェードイン
	func _update_fade_in(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				ch.modulate = Color(1, 1, 1, rate)
				
			Adv.eConst.EF_SLIDE:
				ch.modulate = Color(1, 1, 1, rate)
				ch.rect_position.x = _xbase + AdvConst.CH_SLIDE_OFS_X * ease(1 - rate, 4.8) # expo in
			_:
				pass
	
	# フェードアウト
	func _update_fade_out(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				ch.modulate = Color(1, 1, 1, 1 - rate)
			Adv.eConst.EF_SLIDE:
				ch.modulate = Color(1, 1, 1, 1 - ease(rate, 0.2))
				ch.rect_position.x = _xbase + AdvConst.CH_SLIDE_OFS_X * ease(rate, 0.2) # expo out
			_:
				pass

# ----------------------------------
# メンバ変数
# ----------------------------------
var _ch_list = []

# ----------------------------------
# メンバ関数
# ----------------------------------

# 初期化
func _init(ch_rect):
	var idx = 0
	for tex_rect in ch_rect:
		var ch = AdvCh.new(idx, tex_rect)
		_ch_list.append(ch)
		idx += 1

# 更新
func update(delta:float) -> void:
	for ch in _ch_list:
		ch.update(delta)

# キャラ表示
func draw_ch(pos:int, id:int, eft:int) -> void:
	if pos < 0 or _ch_list.size() <= pos:
		Infoboard.error("不正なpos: %d"%pos)
		return
	var ch:AdvCh = _ch_list[pos]
	ch.load_texture(id)
	ch.appear(eft)

# キャラを消す
func erase_ch(pos:int, eft:int) -> void:
	if pos < 0 or _ch_list.size() <= pos:
		Infoboard.error("不正なpos: %d"%pos)
		return
	var ch:AdvCh = _ch_list[pos]
	ch.disappear(eft)
