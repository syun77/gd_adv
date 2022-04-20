extends CanvasLayer
# ===============================
# ADVアイテム
# ===============================

const FADE_TIME = 0.5
const BASE_POSITION = Vector2(AdvConst.WINDOW_CENTER_X, 128)

enum eItemState {
	HIDE,
	TO_SHOW,
	SHOW,
	TO_HIDE,
}

class AdvItem:
	var _tex:TextureRect = null
	var _eft:int  = Adv.eConst.EF_NONE # 演出種別
	var _time     := 0.0 # 汎用タイマー
	var _state    = eItemState.HIDE # 状態
	func _init(tex_rect:TextureRect):
		_tex = tex_rect
	func load_texture(id:int):
		var path = "res://assets/item/item%03d.png"%id
		var f = File.new()
		if f.file_exists(path) == false:
			Infoboard.error("[AdvItem]存在しない画像:%s"%path)
			return
		_tex.texture = load(path)
	func dispose_texture():
		_tex.texture = null
		_state = eItemState.HIDE
	
	func is_appear() -> bool:
		if _state in [eItemState.TO_SHOW, eItemState.SHOW]:
			return true # 表示中
		return false
	
	func update(delta:float):
		match _state:
			eItemState.HIDE:
				_tex.texture = null
			eItemState.TO_SHOW:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_in(rate)
				if _time >= FADE_TIME:
					_tex.rect_position.x = _get_position_x()
					_time = 0
					_state = eItemState.SHOW
			eItemState.SHOW:
				_tex.modulate = Color.white
			eItemState.TO_HIDE:
				_time = min(FADE_TIME, _time + delta)
				var rate = _time / FADE_TIME
				_update_fade_out(rate)
				if _time >= FADE_TIME:
					_time = 0
					_state = eItemState.HIDE
	
	# 表示演出開始
	func appear(eft:int):
		_tex.rect_position.x = _get_position_x()
		
		_eft = eft
		if _state in [eItemState.HIDE, eItemState.TO_HIDE]:
			_state = eItemState.TO_SHOW
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eItemState.SHOW # 演出なし
		
	
	# 消滅演出開始
	func disappear(eft:int):
		_eft = eft
		if _state in [eItemState.SHOW, eItemState.TO_SHOW]:
			_state = eItemState.TO_HIDE
			_time  = 0
			if _eft == Adv.eConst.EF_NONE:
				_state = eItemState.HIDE # 演出なし

	# フェードイン
	func _update_fade_in(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				_tex.modulate = Color(1, 1, 1, rate)
				
			Adv.eConst.EF_SLIDE:
				_tex.modulate = Color(1, 1, 1, rate)
				_tex.rect_position.x = _get_position_x() + AdvConst.CH_SLIDE_OFS_X * ease(1 - rate, 4.8) # expo in
			_:
				pass
	
	# フェードアウト
	func _update_fade_out(rate:float):
		match _eft:
			Adv.eConst.EF_ALPHA:
				_tex.modulate = Color(1, 1, 1, 1 - rate)
			Adv.eConst.EF_SLIDE:
				_tex.modulate = Color(1, 1, 1, 1 - ease(rate, 0.2))
				_tex.rect_position.x = _get_position_x() + AdvConst.CH_SLIDE_OFS_X * ease(rate, 0.2) # expo out
			_:
				pass
			
	func _get_position_x() -> float:
		return BASE_POSITION.x - _tex.texture.get_width()/2

# ----------------------------------
# メンバ変数
# ----------------------------------
var _item:AdvItem = null

# ----------------------------------
# メンバ関数
# ----------------------------------

# 初期化
func _init(tex):
	_item = AdvItem.new(tex)

# 更新
func update(delta:float) -> void:
	_item.update(delta)

# キャラ表示
func draw_item(id:int, eft:int) -> void:
	_item.load_texture(id)
	_item.appear(eft)

# キャラを消す
func erase_item(eft:int) -> void:
	_item.disappear(eft)
