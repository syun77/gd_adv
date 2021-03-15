extends Control

onready var _text := $Text
onready var _bg   := $Bg
var selected      := false

func _ready() -> void:
	# 中央揃えにする
	_text.push_align(RichTextLabel.ALIGN_CENTER)

func _process(delta: float) -> void:
	pass

func start(pos:Vector2, txt:String):
	rect_position = pos
	_text.text = txt

func destroy():
	queue_free()

func _on_Button_button_down() -> void:
	selected = true
