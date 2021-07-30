extends Control

onready var _text:RichTextLabel = $Text
onready var _bg   := $Bg
var selected      := false

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

func start(pos:Vector2, txt:String):
	rect_position = pos
	# 中央揃え
	_text.bbcode_text = "[center]" + txt + "[/center]"

func destroy():
	queue_free()

func _on_Button_pressed() -> void:
	selected = true
