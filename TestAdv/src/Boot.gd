extends Node2D

###################################
# ゲーム起動シーン
###################################

func _ready() -> void:
	# ゲームデータを初期化
	Global.init()
	Global.change_room()

