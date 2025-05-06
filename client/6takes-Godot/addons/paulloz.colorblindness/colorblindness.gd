@tool
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

func _on_viewport_size_changed():
	_update_rect_size()

func _update_rect_size():
	# Godot 4: get_viewport().size returns the current view size
	rect.custom_minimum_size = get_viewport().size
