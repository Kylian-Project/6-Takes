extends Control

@onready var bot_grid = $MainVbox/BotGrid 
@onready var add_bot_button = $MainVbox/AddBotButton
@onready var sp_start_button = $BottomButtons/SPStartButton
@onready var sp_return_button = $BottomButtons/SPReturnButton
@export var bot_scene: PackedScene

var bot_count = 1  # Start with 1 bot minimum

func _ready():
	add_bot_button.pressed.connect(add_bot)
	sp_start_button.pressed.connect(start_game)
	sp_return_button.pressed.connect(return_to_main_menu)
	update_bot_slots()

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
	print("Starting game with", bot_count, "bots.")

func return_to_main_menu():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
