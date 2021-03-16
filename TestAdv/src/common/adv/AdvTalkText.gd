extends Control
# 会話テキスト管理

# テキスト速度
const TEXT_SPEED := 40.0

# 選択肢
const SEL_CENTER_Y := 240 # 中心座標
const SEL_HEIGHT   := 64  # ボタンの高さ


# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")

# テキスト管理
const AdvTextMgr = preload("res://src/common/adv/AdvTextMgr.gd")

# 選択肢テキスト
const AdvSelectText = preload("res://src/common/adv/AdvSelectText.tscn")

# 選択肢情報
class SelectInfo:
	var index      = 0     # 選択肢番号
	var texts      = null  # テキスト
	var is_exclude = false # 除外するかどうか
	var addr       = 0     # 選択を選んだときのジャンプアドレス
	var button     = null  # 選択ボタン
	func _init(idx:int, txt:String) -> void:
		index = idx
		texts = txt
	func is_selected() -> bool:
		return button.selected
	func create_button(parent:Control, sel_count:int) -> void:
		clear()
		var d = SEL_HEIGHT
		var ofs_y = d * sel_count / 2
		var py = SEL_CENTER_Y - ofs_y + (d * index) 
		var pos = Vector2(0, py)
		button = AdvSelectText.instance()
		parent.add_child(button)
		button.start(pos, texts)
	func clear() -> void:
		if button:
			button.destroy()
			button = null

onready var _talk_text = $Text
onready var _cursor    = $Cursor

var _timer:float      = 0
var _text_timer:float = 0
var _sel_index        = 0 # 選択肢のカーソル
var _sel_list         = [] # 選択肢のテキスト


func _ready() -> void:
	_talk_text.hide()
	_cursor.hide()

func _calc_bbtext_length(var texts):
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]+\\]") # BB Codeを除外した文字列の長さを求める
	var text2 = regex.sub(texts, "", true)
	return text2.length()

func _process(delta: float) -> void:
	_timer += delta

func sel_clear():
	_sel_list.clear()
func sel_add(idx:int, texts:String):
	var info = SelectInfo.new(idx, texts)
	_sel_list.append(info)
func sel_exclude(idx:int):
	_sel_list[idx].is_exclude = true
func sel_addr(args:PoolStringArray):
	var idx = 0
	for info in _sel_list:
		# ジャンプアドレスを設定
		info.addr = int(args[idx])
		idx += 1
	
	var list = []
	for info in _sel_list:
		if info.is_exclude == false:
			# 選択対象
			list.append(info)
	_sel_list = list	
	
func start():
	_talk_text.show()
	_talk_text.visible_characters = 0
	_cursor.hide()

func update_talk(delta:float, msg:AdvTextMgr) -> String:
	var texts = msg.get_text()
	_talk_text.bbcode_text = texts
	# テキストの長さを求める
	var total_text = _calc_bbtext_length(texts)

	# テキストが終端に到達したかどうか	
	var is_disp_all = (_talk_text.visible_characters >= total_text)
	if Input.is_action_just_pressed("ui_accept"):
		# テキスト送り
		if is_disp_all == false:
			# テキストをすべて表示
			_talk_text.visible_characters = total_text
			_text_timer = _talk_text.visible_characters
		else:
			if _sel_list.size() > 0:
				# 選択肢に進む
				# 選択肢生成
				_cursor.hide()
				for sel in _sel_list:
					sel.create_button(self, _sel_list.size())
				return "SEL_WAIT"
			else:
				# 次のテキストに進む
				_cursor.hide()
				msg.clear()
				_text_timer = 0
				return "EXEC"
	
	# 会話テキスト表示
	_talk_text.show()
	# テキスト位置を更新
	_text_timer += delta * TEXT_SPEED
	_talk_text.visible_characters = min(total_text, _text_timer)
	
	if is_disp_all:
		# すべてのテキストを表示したのでカーソル表示
		_cursor.show()
		_cursor.rect_position.y = 500 + 8 * abs(sin(_timer * 4))
	
	return "NONE"

func update_select(delta:float, script:AdvScript, msg:AdvTextMgr):
	var idx = 0
	var sel_info:SelectInfo = null
	for sel in _sel_list:
		if sel.is_selected():
			_sel_index = idx
			sel_info = sel
			break
		idx += 1
		
	if sel_info:
		# 選択肢を選んだ
		# アドレスジャンプ
		script._pc = sel_info.addr - 1
		# 選択肢を破棄する
		for sel in _sel_list:
			sel.clear()
		_sel_list.clear()
		msg.clear()
		_text_timer = 0
		return "EXEC"
	
	return "NONE"
