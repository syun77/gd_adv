extends CanvasLayer

var InfoBoard = preload("res://src/common/util/InfoBoard.tscn")

var _idx:int = 0 # 表示用カウンタ

func warn(text:String) -> void:
	send(text, Color.yellow)
func error(text:String) -> void:
	send(text, Color.red)
func script(text:String) -> void:
	send(text, Color.navyblue)

func send(text:String, color:Color=Color.black) -> void:
	if AdvConst.DEBUG == false:
		return # デバッグでなければ表示しない
	
	# すでに表示されている文字かどうか確認する
	for obj in get_children():
		if obj.is_same(text):
			# すでに表示されている文字
			obj.count_up()
			return
	
	var obj = InfoBoard.instance()
	add_child(obj)
	obj.start(text, _idx, color)
	_idx += 1

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	var can_reset = true
	for obj in get_children():
		if obj.get_yofs() == 0:
			# リセットできない
			can_reset = false
			break
	
	if can_reset:
		# リセット
		_idx = 0
	
	#_update_debug()
		
func _update_debug() -> void:
	# テスト用
	if Input.is_action_just_pressed("ui_accept"):
		var tbl = ["hoge", "piyo", "momo"]
		var text = tbl[_idx%3]
		send(text)
