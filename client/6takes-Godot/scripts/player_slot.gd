extends PanelContainer

@onready var icon = $PlayerInfoContainer/playerIcon
@onready var player_name = $PlayerInfoContainer/playerName
@onready var button = $PlayerInfoContainer/QuickButton

const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func create_player_visual(uname: String, icon_id: int, host := false):
	player_name.text = uname
	var icon_path = ICON_PATH + ICON_FILES[clamp(icon_id, 0, ICON_FILES.size() - 1)]
	icon.texture = load(icon_path)

	if host:
		button.icon = preload("res://assets/images/crown.png") 
		button.text = ""
		button.icon.visible = true
	else:
		button.text = "quick"
		button.icon = null  
		button.icon.visible = false
	
