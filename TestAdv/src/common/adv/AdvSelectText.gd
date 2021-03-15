extends Control

onready var text := $Text
onready var bg   := $Bg
var selected     := false

func _ready() -> void:
	# 中央揃えにする
	text.push_align(RichTextLabel.ALIGN_CENTER)

func _process(delta: float) -> void:
	if selected:
		bg.color = Color.red
	else:
		bg.color = Color.navyblue


func _on_Bg_mouse_entered() -> void:
	selected = true


func _on_Bg_mouse_exited() -> void:
	selected = false
