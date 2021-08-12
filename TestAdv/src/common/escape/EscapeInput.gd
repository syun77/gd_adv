extends Control

class_name EscapeInputObj

const PRESS_OFS_Y = 8.0 # アニメーションでずらす値
const WIDTH = 96

var _idx = 0 # 選んでいる項目番号
var _char_tbl:PoolStringArray # 表示する文字の配列
var _label_pos:Vector2 # 文字の初期位置
var _label_yofs:float = 0.0 # 文字をアニメーションでずらす値
var _is_blink:bool = false
var _bg_color:Color
var _timer:float = 0

onready var _bg = $Bg
onready var _label = $Bg/Label

# 開始パラメータを設定
func start(tbl:PoolStringArray, idx:int) -> void:
	_char_tbl = tbl
	_idx = idx # 初期位置
	# 値の領域外チェック
	_clamp_idx()

# 点滅開始
func start_blink() -> void:
	_bg_color = _bg.color
	_is_blink = true

# 選択している番号を取得する
func get_idx() -> int:
	return _idx

# 選択している文字を取得する
func get_str() -> String:
	return _char_tbl[_idx]
	
# ボタンを非表示にする
func hide_button() -> void:
	$UpButton.hide()
	$DownButton.hide()

func _ready() -> void:
	#if Global.initialized() == false:
	#	# 初期化していなかったら初期化してしまう
	#	Global.init()
	
	# 初期位置を保存
	_label_pos = _label.rect_position

func _process(delta: float) -> void:
	_timer += delta
	
	# クリックアニメーション
	if _label_yofs > 0:
		_label_yofs = max(0, _label_yofs-delta*100)
	if _label_yofs < 0:
		_label_yofs = min(0, _label_yofs+delta*100)
	_label.rect_position = _label_pos + Vector2(0, _label_yofs)

	# テキストを設定
	if _idx >= _char_tbl.size():
		_label.text = "壱"
	else:
		_label.text = _char_tbl[_idx]
	
	if _is_blink:
		# 点滅させる
		_bg.color = _bg_color.linear_interpolate(Color.white, abs(sin(_timer*PI*1.5)))

# 領域外にならないように丸める
func _clamp_idx() -> void:
	var num = _char_tbl.size()
	if _idx < 0:
		_idx = num - 1
	if _idx >= num:
		_idx = 0

func _on_UpButton_pressed() -> void:
	# 上ボタンを押した
	_idx -= 1
	# 値の領域外チェック
	_clamp_idx()
	_label_yofs = -PRESS_OFS_Y


func _on_DownButton_pressed() -> void:
	# 下ボタンを押した
	_idx += 1
	# 値の領域外チェック
	_clamp_idx()
	_label_yofs = PRESS_OFS_Y
