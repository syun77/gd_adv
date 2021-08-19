extends CanvasLayer

# =====================================
# バックログ
# =====================================

onready var _text = $Bg/Text

func _ready() -> void:
	layer = Global.PRIO_ADV_LOGS
	
	#Global.load_data()
	
	# ログテキストを設定する
	var logs = Global.get_backlog()
	if logs.size() == 0:
		return # ログテキストなし
	
	var text = ""
	var idx = 0
	for s in logs:
		if idx > 0:
			text += "\n"
		text += s
		idx += 1
	_text.bbcode_text = text
	_text.scroll_to_line(logs.size() - 1)

func _on_Button_pressed() -> void:
	# 閉じる
	queue_free()
