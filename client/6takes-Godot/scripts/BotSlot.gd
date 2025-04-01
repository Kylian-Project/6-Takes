extends PanelContainer

@export var bot_index: int = 0
@onready var remove_button = $BotHContainer/RemoveBotButton
@onready var bot_label = $BotHContainer/BotName

var lobby_scene = null  # Reference to LobbyScene

func _ready():
	remove_button.pressed.connect(_on_remove_pressed)
	bot_label.text = "Bot " + str(bot_index)  # Set bot name

func _on_remove_pressed():
	if lobby_scene:
		lobby_scene.remove_bot(self)  # Calls `remove_bot()` in `LobbyScene.gd`

func check_bot_removal(bot_count: int):
	if bot_count == 1:
		remove_button.disabled = true  # Disable button when only 1 bot remains
	else:
		remove_button.disabled = false  # Enable button otherwise
