# ===============================
# テキスト管理
# ===============================

var msg_list = []

# コンストラクタ
func _init() -> void:
	msg_list = []

# 消去
func clear() -> void:
	msg_list.clear()
	
# テキストを追加
func add(texts) -> void:
	msg_list.append(texts)

# 連結したテキストを取得
func get_text() -> String:
	var ret = ""
	var idx = 0
	for msg in msg_list:
		if idx > 0:
			ret += "\n"
		ret += msg
		idx += 1
	
	return ret
