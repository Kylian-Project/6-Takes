extends VBoxContainer

const HOVER_SCALE  = Vector2(1.1, 1.1)
const NORMAL_SCALE = Vector2(1, 1)

# Called in _ready — collect all the Area2Ds under row panels
@onready var areas := get_tree().get_nodes_in_group("row_areas")
@onready var row_buttons := [
	$"row1_panel/selectRowButton",
	$"row2_panel/selectRowButton",
	$"row3_panel/selectRowButton",
	$"row4_panel/selectRowButton"
]
@onready var row_areas := [
	$"row1_panel/Area2D",
	$"row2_panel/Area2D",
	$"row3_panel/Area2D",
	$"row4_panel/Area2D"
]
@onready var row_panels := [
	$"row1_panel",
	$"row2_panel",
	$"row3_panel",
	$"row4_panel"
]

signal row_selected(row_index : int)

var selected_row := -1
var selected_area : Area2D
var row_selection_enabled := false


func _ready():

	for i in range(4):
		row_areas[i].connect("mouse_entered", Callable(self, "_on_row_hover").bind(i))
		row_areas[i].connect("mouse_exited", Callable(self, "_on_row_unhover").bind(i))
		row_areas[i].connect("input_event", Callable(self, "_on_row_input_event").bind(i))
		row_buttons[i].connect("pressed", Callable(self, "_on_row_button_pressed").bind(i))
	hide_all_buttons()


func _on_row_hover(index):
	if not row_selection_enabled or selected_row == index:
		return
	row_panels[index].scale = Vector2(1.1, 1.1)

func _on_row_unhover(index):
	if not row_selection_enabled or selected_row == index:
		return
	row_panels[index].scale = Vector2(1, 1)

func show_row_selection_ui():
	row_selection_enabled = true
	for btn in row_buttons:
		btn.visible = false
	selected_row = -1

func hide_all_buttons():
	row_selection_enabled = false
	for btn in row_buttons:
		btn.visible = false
#
#func _on_row_input_event(viewport, event, shape_idx, index):
	#print("--- ROW ", index, " GOT EVENT:", event)
	#if not row_selection_enabled:
		#return
	#
	#
	#print("  → MouseButton: pressed=", event.pressed, "  button_index=", event.button_index)
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		## Player clicked a row → show button
		#print("row selected input detected")
		#
		#if selected_row != -1:
			#row_panels[selected_row].scale = Vector2(1, 1)
			#row_buttons[selected_row].visible = false
		#selected_row = index
		#row_buttons[index].visible = true
		#row_panels[index].scale = Vector2(1.1, 1.1)

func _on_row_input_event(viewport, event, shape_idx, index):

	if event is InputEventMouseButton:
		print("    → MouseButton event: pressed=", event.pressed, " button_index=", event.button_index)
		if row_selection_enabled and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_row_click(index)
		return  # we’re done with mouse events

func _handle_row_click(index):
	print("row selected input detected for row", index)
	# Deselect old
	if selected_row != -1 and selected_row != index:
		row_buttons[selected_row].visible = false
		row_panels[selected_row].scale = NORMAL_SCALE

	# Select new
	selected_row = index
	row_buttons[index].visible = true
	row_panels[index].scale = HOVER_SCALE

func _on_row_button_pressed(index):
	row_selection_enabled = false
	emit_signal("row_selected", index)
	print("row button clicked and signal emitted")
	hide_all_buttons()
	row_panels[index].scale = Vector2(1, 1)
