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

var selected_row := -1
var selected_area : Area2D
var row_selection_enabled := false

func _ready():
	# connect each area’s signals
	#for area in areas:
		#area.input_pickable = true
		#area.mouse_entered.connect(func (): _on_mouse_entered(area))
		#area.mouse_exited.connect(func (): _on_mouse_exited(area))
		#area.input_event.connect(func (viewport, event, shape_idx): _on_area_input_event(viewport, event, shape_idx, area))
		 
	for i in range(4):
		row_areas[i].connect("mouse_entered", Callable(self, "_on_row_hover").bind(i))
		row_areas[i].connect("mouse_exited", Callable(self, "_on_row_unhover").bind(i))
		row_areas[i].connect("input_event", Callable(self, "_on_row_input_event").bind(i))
		row_buttons[i].connect("pressed", Callable(self, "_on_row_button_pressed").bind(i))
	hide_all_buttons()
		#var btn = area.get_parent().get_node("selectRowButton")
		#btn.visible = false

#func _on_mouse_entered(area: Area2D):
	#_tween_scale(area, HOVER_SCALE)
#
#func _on_mouse_exited(area: Area2D):
	## only reset if it isn’t selected
	#var btn = area.get_parent().get_node("selectRowButton")
	#if btn and not btn.visible:
		#_tween_scale(area, NORMAL_SCALE)
#
#func _on_area_input_event(viewport, event: InputEvent, shape_idx, area: Area2D):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#_select_area(area)
#
#func _select_area(area: Area2D):
	## deselect previous
	#if selected_area and selected_area != area:
		#_reset_area(selected_area)
	## select this one
	#selected_area = area
	#var btn = area.get_parent().get_node("selectRowButton")
	#btn.visible = true
	#_tween_scale(area, HOVER_SCALE)
#
#func _reset_area(area: Area2D):
	#var btn = area.get_parent().get_node("selectRowButton")
	#btn.visible = false
	#_tween_scale(area, NORMAL_SCALE)
#
#func _tween_scale(area: Area2D, to_scale: Vector2):
	#var row_panel = area.get_parent()  # Node2D
	#var tw = Tween.new()
	#tw.kill()
	#tw.tween_property(row_panel, "scale", to_scale, 0.15)
	
func _on_row_hover(index):
	if not row_selection_enabled or selected_row == index:
		return
	row_panels[index].scale = Vector2(1.05, 1.05)

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
	row_selection_enabled = true
	for btn in row_buttons:
		btn.visible = false

func _on_row_input_event(viewport, event, shape_idx, index):
	if not row_selection_enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Player clicked a row → show button
		print("row selected input detected")
		if selected_row != -1:
			row_panels[selected_row].scale = Vector2(1, 1)
			row_buttons[selected_row].visible = false
		selected_row = index
		row_buttons[index].visible = true
		row_panels[index].scale = Vector2(1.1, 1.1)

func _on_row_button_pressed(index):
	row_selection_enabled = false
	emit_signal("row_selected", index)
	print("row button clicked and signal emitted")
	hide_all_buttons()
	row_panels[index].scale = Vector2(1, 1)
