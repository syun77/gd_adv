extends Control
# ==========================
# 会話テキスト管理
# ==========================
class_name AdvTalkText

# --------------------------
# exports
# --------------------------
# テキスト速度
export(float) var TEXT_SPEED := 40.0

# --------------------------
# const
# --------------------------
# 選択肢
const SEL_CENTER_Y := 240 # 中心座標
const SEL_HEIGHT   := 80  # ボタンの高さ

# --------------------------
# preload.
# --------------------------
# スクリプト管理
const AdvScriptObj = preload("res://src/common/adv/AdvScript.gd")

# 選択肢テキスト
const AdvSelectText = preload("res://src/common/adv/AdvSelectText.tscn")

# --------------------------
# class.
# --------------------------
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

# --------------------------
# setter/getter.
# --------------------------
var is_pagefeed setget ,_is_pagefeed # 改ページするかどうか

# --------------------------
# onready.
# --------------------------
onready var _face = $Window/Face
onready var _name = $Window/Name

# --------------------------
# vars.
# --------------------------
var _cursor_timer:float = 0 # カーソルタイマー
var _cursor_timer2:float = 0 # カーソルタイマー２
var _text_timer:float = 0 # テキストタイマー
var _sel_list = [] # 選択肢のテキスト
var _is_pf = true # 改ページするフラグ
var _msg_mode = AdvConst.eMsgMode.TALK # メッセージ表示モード.
var _pressed_logbutton = false # ログボタンを押した.

# --------------------------
# functions.
# --------------------------
## メッセージモードの設定.
func set_msg_mode(mode:int) -> void:
	_msg_mode = mode
	_window_hide()
	_get_window().show()
	
## ログボタンを押したかどうか.
func pressed_logbutton() -> bool:
	return _pressed_logbutton
func clear_pressed_logbutton() -> void:
	_pressed_logbutton = false

## 開始処理.
func _ready() -> void:
	_window_hide()
	_text_hide()
	_cursor_hide()
	_face.hide()
	_name.hide()
	
	set_msg_mode(AdvConst.eMsgMode.TALK)

## BBテキストの末尾を計算する.
func _calc_bbtext_length(var texts):
	var regex = RegEx.new()
	regex.compile("\\[[^\\]]+\\]") # BB Codeを除外した文字列の長さを求める
	
	var text2 = regex.sub(texts, "", true)
	
	# カーソルを文字の末尾に移動する
	var talk_text := _get_text()
	var font = talk_text.get_font("normal_font")
	var size := Vector2()
	
	# 文字の幅と高さを求める
	for text in text2.split("\n"):
		# 改行を判定しないので分割して最後のテキストの幅を求める
		size = font.get_string_size(text)
	# 行数を取得
	var line = talk_text.get_line_count() - 1
	
	# カーソルを文字の末尾に移動する
	var cursor := _get_cursor()
	cursor.position = talk_text.rect_position + Vector2(size.x+24, size.y*(line+0.5))
	
	return text2.length()

## 更新.
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
	
func start(is_pf:bool):
	var talk_text := _get_text()
	talk_text.show()
	if _is_pf:
		# 前回改ページしていたら初期化する
		talk_text.visible_characters = 0
	_is_pf = is_pf # 改ページするフラグ
	_get_cursor().hide()

## 会話テキスト更新.
func update_talk(delta:float, texts:String) -> String:
	
	# TODO: デバッグ文字描画
	#update()
	
	# ログボタンを押したフラグを消しておく.
	_pressed_logbutton = false
	
	var talk_text := _get_text()
	talk_text.bbcode_text = texts
	# テキストの長さを求める
	var total_text = _calc_bbtext_length(texts)
	
	# テキストが終端に到達したかどうか	
	var is_disp_all = (talk_text.visible_characters >= total_text)
	if _check_next_text():
		# テキスト送り
		if is_disp_all == false:
			# テキストをすべて表示
			talk_text.visible_characters = total_text
			_text_timer = talk_text.visible_characters
		else:
			if _sel_list.size() > 0:
				# 選択肢に進む
				# 選択肢生成
				_get_cursor().hide()
				for sel in _sel_list:
					sel.create_button(self, _sel_list.size())
				return "SEL_WAIT"
			else:
				# 次のテキストに進む
				_get_cursor().hide()
				if _is_pf:
					# 改ページする
					_text_timer = 0
					talk_text.visible_characters = 0
				return "EXEC"
	
	# 会話テキスト表示
	talk_text.show()
	# テキスト位置を更新
	_text_timer += delta * TEXT_SPEED
	_text_timer = min(total_text, _text_timer)
	talk_text.visible_characters = int(_text_timer)
	
	if is_disp_all:
		# すべてのテキストを表示したのでカーソル表示
		var cursor := _get_cursor()
		cursor.show()
		cursor.position.y += 8 * abs(sin(_cursor_timer * 3))
		cursor.scale.x = 1
		if _cursor_timer2 < 1:
			cursor.scale.x = abs(sin((0.5 + _cursor_timer2) * PI))
	return "NONE"

func update_select(_delta:float, script:AdvScript) -> String:
	var _idx = 0
	var sel_info:SelectInfo = null
	for sel in _sel_list:
		if sel.is_selected():
			sel_info = sel
			break
		_idx += 1
		
	if sel_info:
		# 選択肢を選んだ
		# アドレスジャンプ
		script._pc = sel_info.addr - 1
		# 選択肢を破棄する
		for sel in _sel_list:
			sel.clear()
		_sel_list.clear()
		_text_timer = 0
		_get_text().visible_characters = 0
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

func _window_hide() -> void:
	$Window.hide()
	$Novel.hide()

func _text_hide() -> void:
	$Window/Text.hide()
	$Novel/Text.hide()
func _cursor_hide() -> void :
	$Window/Cursor.hide()
	$Novel/Cursor.hide()

## テキスト送りするかどうか
func _check_next_text() -> bool:
	if Input.is_action_just_pressed("ui_next_text"):
		return true # テキスト送りのキーを押した.
	
	if Input.is_action_just_pressed("ui_click"):
		return true # クリックした.
	
	return false
	
# ---------------------------------------
# setter/getter
# ---------------------------------------
func _is_pagefeed() -> bool:
	return _is_pf

func _get_window() -> ColorRect:
	match _msg_mode:
		AdvConst.eMsgMode.NOVEL:
			return $Novel as ColorRect
		_:
			return $Window as ColorRect

func _get_text() -> RichTextLabel:
	match _msg_mode:
		AdvConst.eMsgMode.NOVEL:
			return $Novel/Text as RichTextLabel
		_:
			return $Window/Text as RichTextLabel

func _get_cursor() -> Sprite:
	match _msg_mode:
		AdvConst.eMsgMode.NOVEL:
			return $Novel/Cursor as Sprite
		_:
			return $Window/Cursor as Sprite

# ---------------------------------------
# デバッグ
# ---------------------------------------
func _draw():
	if true:
		return
	# デバッグ用描画処理
	var talk_text := _get_text()
	var cursor := _get_cursor()
	var font = talk_text.get_font("normal_font")
	var s = "show" if cursor.visible else "hide"
	var c = Color.red if cursor.visible else Color.white
	draw_string(font, Vector2(128, 300), "cursor:%s"%s, c)
	draw_string(font, Vector2(128, 340), "timer:%3.2f"%_text_timer, c)

## ログボタンを押した.
func _on_LogButton_button_down() -> void:
	_pressed_logbutton = true
