# ===============================
# テキスト管理
# ===============================

var msg_list = [] # 会話テキスト用
var log_list = [] # ログ

# コンストラクタ
func _init() -> void:
	msg_list = []
	log_list = []

# 消去
func clear() -> void:
	msg_list.clear()
	
# テキストを追加
func add(texts) -> void:
	msg_list.append(texts)
	log_list.append(texts)
	if log_list.size() > AdvConst.MAX_LOG:
		# ログの最大数を超えたので先頭を削除
		log_list.pop_front()

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
	
# 連結したログテキストを取得する
func get_log_text() -> String:
	var ret = ""
	var idx = 0
	for msg in msg_list:
		if idx > 0:
			ret += "\n"
		ret += msg
		idx += 1
	
	return ret
	
