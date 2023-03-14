extends CanvasLayer
# ===================================
# 通知ボード管理
# ===================================
var InfoBoard = preload("res://src/common/util/InfoBoard.tscn")

var _idx:int = 0 # 表示用カウンタ

func warn(text:String) -> void:
	send(text, Color.YELLOW)
func error(text:String) -> void:
	send(text, Color.RED)
func script(text:String) -> void:
	send(text, Color.NAVY_BLUE)

func send(text:String, color:Color=Color.BLACK) -> void:
	print(text)
	
	if AdvConst.DEBUG == false:
		return # デバッグでなければ表示しない
	
	# すでに表示されている文字かどうか確認する
	for obj in get_children():
		if obj.is_same(text):
			# すでに表示されている文字
			obj.count_up()
			return
	
	var obj = InfoBoard.instantiate()
	add_child(obj)
	obj.start(text, _idx, color)
	_idx += 1

func _ready() -> void:
	pass # Replace with function body.


func _process(_delta: float) -> void:
	var idx_list = []
	for obj in get_children():
		idx_list.append(obj.get_yofs())

	var prev = -1
	idx_list.sort()
	for idx in idx_list:	
		if prev+1 != idx:
			# 空きを見つけたらそこに番号を設定する
			_idx = prev+1
			break
		prev = idx
	
	#_update_debug()
		
func _update_debug() -> void:
	# テスト用
	if Input.is_action_just_pressed("ui_accept"):
		var tbl = ["hoge", "piyo", "momo"]
		var text = tbl[_idx%3]
		send(text)
