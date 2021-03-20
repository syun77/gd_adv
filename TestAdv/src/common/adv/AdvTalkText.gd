extends Control
# 会話テキスト管理

# テキスト速度
export(float) var TEXT_SPEED := 40.0

# 選択肢
const SEL_CENTER_Y := 240 # 中心座標
const SEL_HEIGHT   := 80  # ボタンの高さ


# スクリプト管理
const AdvScript = preload("res://src/common/adv/AdvScript.gd")

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

onready var _talk_text = $Window/Text
onready var _cursor    = $Window/Cursor
onready var _face      = $Window/Face
onready var _name      = $Window/Name

var _cursor_timer:float  = 0 # カーソルタイマー
var _cursor_timer2:float = 0 # カーソルタイマー２
var _text_timer:float    = 0 # テキストタイマー
var _sel_list            = [] # 選択肢のテキスト

func _ready() -> void:
	_talk_text.hide()
	_cursor.hide()
	_face.hide()
	_name.hide()

func _calc_bbtext_length(var texts):
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]+\\]") # BB Codeを除外した文字列の長さを求める
	
	var text2 = regex.sub(texts, "", true)
	
	# カーソルを文字の末尾に移動する
	var font = _talk_text.get_font("normal_font")
	var size := Vector2()
	
	# 文字の幅と高さを求める
	for text in text2.split("\n"):
		# 改行を判定しないので分割して最大幅を決める
		var s = font.get_string_size(text)
		size.x = max(s.x, size.x)
		size.y = s.y
	# 行数を取得
	var line = _talk_text.get_line_count() - 1
	
	# カーソルを文字の末尾に移動する
	_cursor.position = _talk_text.rect_position + Vector2(size.x+24, size.y*(line+0.5))
	
	return text2.length()

func _process(delta: float) -> void:
	_cursor_timer += delta
	_cursor_timer2 += delta
	if _cursor_timer2 > 3:
		_cursor_timer2 = 0
	#update()

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

func update_talk(delta:float, texts:String) -> String:
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
				_text_timer = 0
				_talk_text.visible_characters = 0
				return "EXEC"
	
	# 会話テキスト表示
	_talk_text.show()
	# テキスト位置を更新
	_text_timer += delta * TEXT_SPEED
	_talk_text.visible_characters = min(total_text, _text_timer)
	
	if is_disp_all:
		# すべてのテキストを表示したのでカーソル表示
		_cursor.show()
		_cursor.position.y += 8 * abs(sin(_cursor_timer * 3))
		if _cursor_timer2 < 1:
			_cursor.scale.x = abs(sin((0.5 + _cursor_timer2) * PI))
	return "NONE"

func update_select(delta:float, script:AdvScript) -> String:
	var idx = 0
	var sel_info:SelectInfo = null
	for sel in _sel_list:
		if sel.is_selected():
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
		_text_timer = 0
		_talk_text.visible_characters = 0
		return "EXEC"
	
	return "NONE"

func draw_face(id:int) -> void:
	_face.texture = load("res://assets/face/face%03d.png"%id)
	_face.show()
func erase_face() -> void:
	_face.texture = null
	_face.hide()
	
func set_name(name:String) -> void:
	_name.text = name
	_name.show()
func clear_name() -> void:
	_name.hide()
	
func _draw():
	# デバッグ用描画処理
	var font = _talk_text.get_font("normal_font")
	var s = "show" if _cursor.visible else "hide"
	var c = Color.red if _cursor.visible else Color.white
	#draw_string(font, Vector2(128, 500), "cursor:%s"%s, c)
