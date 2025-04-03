extends Control

@onready var player_icon = $EditProfilePanel/MainVertical/HRow/PlayerIcon
@onready var icon_selection = $EditProfilePanel/MainVertical/IconSelection
@onready var save_button = $EditProfilePanel/MainVertical/SaveIconButton
@onready var close_button = $Close
@onready var logout_button = $EditProfilePanel/MainVertical/HRow/LogOutButton

const ICON_PATH = "res://assets/images/icons/"
const ICON_FILES = [
	"dark_grey.png", "blue.png", "brown.png", "green.png", 
	"orange.png", "pink.png", "purple.png", "red.png",
	"reversed.png", "cyan.png"
]

var selected_icon = "dark_grey.png"  # Default icon

func _ready():
	populate_icon_selection()
	save_button.connect("pressed", _on_save_icon)
	close_button.connect("pressed", _on_close_pressed)
	logout_button.connect("pressed", _on_logout_pressed)

func populate_icon_selection():
	for icon_file in ICON_FILES:
		var icon_button = Button.new()
		var texture = load(ICON_PATH + icon_file)
		
		icon_button.icon = texture  # Set the texture as the button icon
		icon_button.custom_minimum_size = Vector2(64, 64)  # Adjust size if needed
		icon_button.connect("pressed", _on_icon_selected.bind(icon_file))
		
		icon_selection.add_child(icon_button)

func _on_icon_selected(icon_name):
	selected_icon = icon_name
	player_icon.texture = load(ICON_PATH + selected_icon)

func _on_save_icon():
	print("Saving icon:", selected_icon)
	send_icon_to_database(selected_icon)

func send_icon_to_database(icon_name):
	#Implement database interaction
	print("Icon", icon_name, "sent to database")

func _on_close_pressed():
	self.queue_free()

func _on_logout_pressed():
	#Implement logout logic
	print("User logged out")
