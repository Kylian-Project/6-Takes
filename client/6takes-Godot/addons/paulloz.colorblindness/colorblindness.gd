@icon("res://addons/paulloz.colorblindness/colorblindness.svg")
class_name Colorblindness
extends CanvasLayer

enum TYPE { None, Protanopia, Deuteranopia, Tritanopia, Achromatopsia }

@export var Type: TYPE = TYPE.None:
	set(value):
		if rect.material:
			rect.material.set_shader_parameter("type", value)
		else:
			temp = value
		Type = value

var temp = null
var rect := ColorRect.new()

func _ready():
	# 1) Add the full-screen filter above all UI
	add_child(rect)
	# Forcer les anchors pour remplir tout le viewport
	rect.anchor_left = 0.0
	rect.anchor_top = 0.0
	rect.anchor_right = 1.0
	rect.anchor_bottom = 1.0

	# 2) Load its shader material
	rect.material = load("res://addons/paulloz.colorblindness/colorblindness.material")
	# Ignore mouse so it doesn’t block clicks
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3) Size it to exactly fill the viewport right now
	_update_rect_size()

	# 4) If someone set .Type before the material loaded, apply it now
	if temp != null:
		Type = temp
		temp = null

	# 5) Watch for window/viewport resizes
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _process(_delta):
	_update_rect_size()

func _on_viewport_size_changed():
	_update_rect_size()

func _update_rect_size():
	rect.position = Vector2.ZERO
	rect.size = Vector2(10000, 10000)
	rect.scale = Vector2.ONE
