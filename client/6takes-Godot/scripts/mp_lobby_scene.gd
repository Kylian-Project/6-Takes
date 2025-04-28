extends Control

@onready var start_button = $BottomButtons/StartButton
@onready var quit_button = $BottomButtons/QuitButton
@onready var settings_button = $BottomButtons/SettingsButton
@onready var settings_overlay = $SettingsOverlay
@onready var settings_close_button = $SettingsOverlay/Close

@onready var player_limit_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/PlayerLimitDropdown
@onready var card_number_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/CardNumberDropdown
@onready var round_timer_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundTimerDropdown
@onready var end_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/EndPointsDropdown
@onready var rounds_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/RoundsDropdown
@onready var max_points_dropdown = $SettingsOverlay/PanelContainer/MainVertical/AvailableOptions/Choices/MaxPointsDropdown

@onready var players_container = $MainVboxContainer/playersContainer
@onready var player_entry_scene = preload("res://scenes/Player_slot.tscn")

@onready var host_node = $MainVboxContainer/HBoxContainer/HostPlayer

#lobby info 
@onready var players_count_panel = $MainVboxContainer/HBoxContainer/playersCount/playersCount
@onready var lobby_code_panel = $MainVboxContainer/HBoxContainer/lobbyCode/codeValue
@onready var lobby_name_panel = $lobbyName

var player_username
var bot_count = 0
var id_lobby
var is_host
var scene_changed


func _ready():
	settings_overlay.visible = false
	scene_changed = false 
	
	player_username = get_node("/root/Global").player_name
	
	# Hover sounds
	start_button.mouse_entered.connect(SoundManager.play_hover_sound)
	quit_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_close_button.mouse_entered.connect(SoundManager.play_hover_sound)

	# Click sounds
	start_button.pressed.connect(SoundManager.play_click_sound)
	quit_button.pressed.connect(SoundManager.play_click_sound)
	settings_button.pressed.connect(SoundManager.play_click_sound)
	settings_close_button.pressed.connect(SoundManager.play_click_sound)
	
	# Hover sounds for dropdowns
	player_limit_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	card_number_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	round_timer_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	end_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	rounds_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	max_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	
	#connect to socket
	SocketManager.connect("event_received", Callable(self, "_on_socket_event"))

	id_lobby = get_node("/root/GameState").id_lobby
	is_host = get_node("/root/GameState").is_host
	
	print("emit get users in room :", id_lobby)
	SocketManager.emit("users-in-public-room", id_lobby)
	SocketManager.emit("users-in-private-room", id_lobby) #TO DO merge the two events
	
	lobby_name_panel.text = str(get_node("/root/GameState").lobby_name) + "  LOBBY"
	lobby_code_panel.text = str(id_lobby)


func _on_raw_packet(packet):
	print("Raw packet bytes:", packet)
	print("Raw packet string:", packet.get_string_from_utf8())
	
	
func _on_socket_event(event: String, data: Variant, ns: String):
	match event:
		"users-in-your-private-room":
			print("event users in private room received \n", data)
			_refresh_player_list(data)
		"users-in-your-public-room":
			print("event users in public room received \n", data)
			_refresh_player_list(data)
		"user-left-public", "user-left-private":
			print("user left room :", data)
			SocketManager.emit("users-in-private-room", id_lobby)
			SocketManager.emit("users-in-public-room", id_lobby) 
		"game-starting":
			_handle_game_starting()
		_:
			print("unhandled event received \n", event, data)


func _handle_game_starting():
	print("is host debug ", is_host)
	if !is_host and !scene_changed:
		scene_changed = true
		print("game starting received, moving to gameboard")
		get_tree().change_scene_to_file("res://scenes/gameboard.tscn")
		

func _refresh_player_list(data):
	var host_icon
	var host_uname
	
	print("refreshing players display")
	# Clear old entries
	for child in players_container.get_children():
		child.queue_free()

	var outer = data[0]
	var payload : Dictionary

	# Shape A: { "users": { count, users } }
	if outer.has("users") and typeof(outer["users"]) == TYPE_DICTIONARY:
		payload = outer["users"]
	# Shape B: { "count": X, "users": [ … ] }
	elif outer.has("count") and outer.has("users") and typeof(outer["users"]) == TYPE_ARRAY:
		payload = outer
	else:
		push_error("Unrecognized users-in room payload: %s" % outer)
		return

	var players_count = int(payload.get("count", 0))
	var players       = payload.get("users", [])

	print("players count ", players_count)
	players_count_panel.text = str(players_count)

	## Update HostPlayer node
	var host_user = players[0] as Dictionary
	for child in host_node.get_children():
		child.queue_free()
	
	var host_entry = player_entry_scene.instantiate()
	host_node.add_child(host_entry)
	
	print("host debug ", host_user)
	host_entry.create_player_visual(
		host_user.get("username", "Unknown"),
		0,#host_user.get("icon", 0), -------TO DO IN SERVER LINK PLAYERS WITH LIBBY USERS
		true # is_host = true
	)
	
	#disable buttons for non host players ----- TO DO IN SERVER LINK PLAYERS WITH LIBBY USERS
	#if host_user.get("username", "Unknown") != get_node("/root/Global").player_name:
		#start_button.disabled = true
		#settings_button.disabled = true 
		
		
	for i in range(1, players_count):
		var user_dict = players[i] as Dictionary
		
		var entry     = player_entry_scene.instantiate()
		players_container.add_child(entry)

		var icon_id = user_dict.get("icon", null)
		icon_id = icon_id if icon_id != null else 0
		
		entry.create_player_visual(
			user_dict.get("username", "Unknown"),
			icon_id,
			false
		)
		print("child added to scene")

	
func _on_start_button_pressed() -> void:
	print("emit start game and move to gameboard")
	SocketManager.emit("start-game", id_lobby)
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")
	
	#await get_tree().create_timer(0.1).timeout
	#SocketManager.emit("start-game", id_lobby)


func _on_quit_button_pressed() -> void:
	print("leave room event sent")
	SocketManager.emit("leave-room", {
		"roomId" : id_lobby
	})
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
	
