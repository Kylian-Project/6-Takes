extends PanelContainer

@onready var icon = $PlayerInfoContainer/playerIcon
@onready var player_name = $PlayerInfoContainer/playerName
@onready var button = $PlayerInfoContainer/KickButton

const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass#player_name = ""

func create_player_visual(uname, icon_id: int, host := false):
	player_name.text = uname
	var icon_path = ICON_PATH + ICON_FILES[clamp(icon_id, 0, ICON_FILES.size() - 1)]
	icon.texture = load(icon_path)

	if host:
		button.icon = preload("res://assets/images/crown.png") 
		button.text = ""
		button.disabled = true
	else:
		button.text = "Kick"
		button.icon = null  
	

func _on_kick_button_pressed() -> void:
	print("player kicked : ", player_name)
	return player_name
