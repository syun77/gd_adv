extends Node2D

###################################
# ゲーム起動シーン
###################################

func _ready() -> void:
	Global.init()
	Global.change_room()

