extends Control

@onready var bot_grid = $MainVbox/BotGrid 
@onready var add_bot_button = $MainVbox/AddBotButton
@onready var sp_start_button = $BottomButtons/SPStartButton
@onready var sp_return_button = $BottomButtons/SPReturnButton
@onready var sp_settings_button = $BottomButtons/SPSettingsButton
@onready var settings_overlay = $SettingsOverlay
@onready var settings_close_button = $SettingsOverlay/Close
@export var bot_scene: PackedScene

var bot_count = 1  # Start with 1 bot minimum
	
@onready var socket_io = $SocketIO

func _ready():
	socket_io.connect_socket()
	#socket_io.event_received.connect(_on_socket_io_event_received)
	#
	#socket_io.connect("connected",Callable(self, "_on_socket_connected"))
	#socket_io.connect("error", Callable(self, "_on_socket_error"))
	#
	## Listen to the events as defined in your Node.js server:
	#socket_io.connect("start-game", Callable( self, "_on_start_game"))
	#socket_io.connect("your-hand", Callable(self, "_on_your_hand"))
	#socket_io.connect("initial-table", Callable(self, "_on_initial_table"))
	#socket_io.connect("carte-invalide", Callable(self, "_on_invalid_card"))
	#
	#
	#add_bot_button.pressed.connect(add_bot)
	#sp_start_button.pressed.connect(start_game)
	#sp_return_button.pressed.connect(return_to_main_menu)
	#sp_settings_button.pressed.connect(show_settings)
	#settings_close_button.pressed.connect(hide_settings)
	#settings_overlay.visible = false
	update_bot_slots()



func _on_socket_io_event_received(event: String, data: Variant, ns: String) -> void:
	print("SocketIO event received: name=", event, " --- data = ", data, " --- namespace = ", ns)


func add_bot():
	if bot_count < 9:
		bot_count += 1
		update_bot_slots()

func remove_bot(bot_instance):
	if bot_count > 1:
		bot_count -= 1
		update_bot_slots()
	else:
		print("Cannot remove the last bot!")

func update_bot_slots():
	# Clear existing bot slots
	for child in bot_grid.get_children():
		child.queue_free()

	# Recreate bots with correct numbering
	for i in range(bot_count):
		var bot_instance = bot_scene.instantiate()
		bot_instance.bot_index = i + 1  # Set bot index correctly
		bot_instance.lobby_scene = self  # Provide reference to LobbyScene
		bot_grid.add_child(bot_instance)

	# Ensure bot removal button logic is updated
	for bot in bot_grid.get_children():
		bot.check_bot_removal(bot_count)  # Pass correct bot count

	# Hide Add Bot button if max bots are reached
	add_bot_button.visible = bot_count < 9

func start_game():
	#socket_io.connect_socket()
	print("Starting game with", bot_count, "bots.")
	

func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_settings():
	settings_overlay.visible = true

func hide_settings():
	settings_overlay.visible = false
