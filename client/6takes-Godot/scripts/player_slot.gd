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

var lobby_scene
var username

func _ready() -> void:
	pass#player_name = ""

func create_player_visual(uname, icon_id: int, host := false):
	username = uname
	player_name.text = username
	
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
	if lobby_scene:
		lobby_scene.kick_player(username)
