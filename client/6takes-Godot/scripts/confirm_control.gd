extends Control

@onready var confirm_button = $buttonContainer/confirmButton
@onready var cancel_button = $buttonContainer/cancelButton

signal confirmed(action_type: String, action_payload)
signal canceled()

#set by LobbyScene before showing
var action_type    := ""
var action_payload
var message = ""
var scene

func _ready():
	visible = false
	$mssg.text = message

	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func _update_message():
	$mssg.text = "\n" + message

func show_panel():
	_update_message()
	visible = true
	
func _on_confirm_pressed():
	hide()
	emit_signal("confirmed", action_type, action_payload)

func _on_cancel_pressed():
	#hide()
	print("cancel pressed")
	self.visible = false
	print("visibility :", self.visible)
	emit_signal("canceled")
