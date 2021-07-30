extends CanvasLayer

var now_room:int = 0 setget _set_now_room, _get_now_room
var next_room:int = 0 setget _set_next_room, _get_next_room

func init() -> void:
	# フラグの初期化
	AdvUtil.init()
	
	# 開始ルーム番号を設定しておく
	now_room = 101
	next_room = now_room

# ルーム変更可能かどうか
func can_change_room() -> bool:
	return now_room != next_room

# スクリプトのパスを取得する
func get_script_path() -> String:
	return "res://assets/adv/adv%03d.txt"%now_room
	
# シーン名で次のシーンを設定する
func set_next_room(name:String) -> void:
	var v = CastleDB.search("scenes", name)
	if v < 0:
		print("無効なルーム名: %s"%name)
		return
	next_room = v

func change_room() -> void:
	var res_name = "res://src/escape/room/%3d/EscapeRoom.tscn"%next_room
	next_room = now_room
	print("ルーム移動: %s"%res_name)
	get_tree().change_scene(res_name)

func _set_now_room(v:int) -> void:
	now_room = v
func _get_now_room() -> int:
	return now_room
func _set_next_room(v:int) -> void:
	next_room = v
func _get_next_room() -> int:
	return next_room
