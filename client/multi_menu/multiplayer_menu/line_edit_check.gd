extends Control  # Attach this script to the JoinLobbyOverlay

@onready var join_code_input = $JoinLobbyOverlay/JoinPanel/MainVertical/JoinCodeContainer/LineEdit
@onready var join_button = $JoinLobbyOverlay/JoinPanel/MainVertical/JoinCodeContainer/JoinCodeButton

func _ready():
	join_code_input.text_changed.connect(_on_text_changed)
	join_button.pressed.connect(_on_join_pressed)

func _on_text_changed(new_text):
	# Remove non-numeric characters
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_integer():  # Allow only digits
			filtered_text += char

	# Ensure max length is 4 digits
	join_code_input.text = filtered_text.left(4)

func _on_join_pressed():
	if join_code_input.text.length() == 4:
		print("Joining lobby with code:", join_code_input.text)
	else:
		print("Invalid code! Must be exactly 4 digits.")
