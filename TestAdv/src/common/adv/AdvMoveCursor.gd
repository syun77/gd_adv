extends Sprite

const MOVE_OFFSET:float = 8.0
const MOVE_SPEED:float = 3.0

# 開始座標.
var _start_position = Vector2(320, 320)
# アニメーション用タイマー
var _timer:float = 0
# 矢印の方向
var _dir = AdvUtilObj.eDir.DOWN
# クリック時に発生するイベント
var _click:String = ""
# 遷移するシーン
var _jump:String = ""
# ONフラグ名
var _on_bit:String = ""
# OFFフラグ名
var _off_bit:String = ""

# 初期化
func init(pos:Vector2, dir:int, jump:String, click:String, on_bit:String, off_bit:String) -> void:
	_start_position = pos
	_dir = dir
	_on_bit = on_bit
	_off_bit = off_bit

func get_jump() -> String:
	if visible == false:
		return ""
	return _jump
	
func get_click() -> String:
	if visible == false:
		return ""
	return _click

func _ready() -> void:
	_update_visible()

func update_manual(delta: float) -> void:
	_update_visible()
	
	_timer += delta
	var v = Vector2()
	match _dir:
		AdvUtilObj.eDir.DOWN:
			rotation_degrees = 90
			v.y = MOVE_OFFSET * abs(sin(_timer * MOVE_SPEED))
		AdvUtilObj.eDir.LEFT:
			rotation_degrees = 180
			v.x = -MOVE_OFFSET * abs(sin(_timer * MOVE_SPEED))
		AdvUtilObj.eDir.RIGHT:
			rotation_degrees = 0
			v.x = MOVE_OFFSET * abs(sin(_timer * MOVE_SPEED))
		AdvUtilObj.eDir.UP:
			rotation_degrees = -90
			v.y = -MOVE_OFFSET * abs(sin(_timer * MOVE_SPEED))
	
	position = _start_position + v

func _update_visible() -> void:
	visible = _check_enabled()

# 移動カーソルが有効かどうかを調べる
func _check_enabled() -> bool:
	var is_on = false
	if _on_bit != "":
		is_on = CastleDB.bit_chk(_on_bit)
	var is_off = false
	if _off_bit != "":
		is_off = CastleDB.bit_chk(_off_bit) 
	
	if is_off:
		return false # 無効
		
	if is_on == false:
		if _on_bit != "":
			return false # 無効
	
	return true # 有効	
