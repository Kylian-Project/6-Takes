extends Control

@onready var start_button = $BottomButtons/StartButton
@onready var quit_button = $BottomButtons/QuitButton
@onready var add_bot_button = $MainVboxContainer/AddBotButton
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
@onready var bot_scene = preload("res://scenes/BotSlot.tscn")
@onready var message_control = $mssgControl
@onready var host_node = $MainVboxContainer/HBoxContainer/HostPlayer

#lobby info 
@onready var players_count_panel = $MainVboxContainer/HBoxContainer/playersCount/playersCount
@onready var lobby_code_panel = $MainVboxContainer/HBoxContainer/lobbyCode/codeValue
@onready var lobby_name_panel = $lobbyName

#confirmation control
@onready var confirm_panel = $ConfirmControl
@onready var notif_label 	= $SavePopupLabel

var player_username
var bot_count
var players_count
var players_limit
var id_lobby
var lobby_name
var is_host
var scene_changed
var is_public

var connection_timer: Timer
var connection_lost_handled := false
var ping_timer: Timer
var pong_timeout_timer: Timer

func _ready():
	settings_overlay.visible = false
	scene_changed = false 
	bot_count = 0
	
	player_username = Global.player_name
	players_count = GameState.players_count
	
	check_ban_status()
	
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
	add_bot_button.pressed.connect(SoundManager.play_click_sound)
	# Hover sounds for dropdowns
	player_limit_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	card_number_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	round_timer_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	end_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	rounds_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	max_points_dropdown.mouse_entered.connect(SoundManager.play_hover_sound)
	
	#connect to socket
	SocketManager.connect("event_received", Callable(self, "_on_socket_event"))
	# Ajout : gestion de la déconnexion websocket
	SocketManager.connect("disconnected", Callable(self, "_on_socket_disconnected"))
	
	id_lobby = GameState.id_lobby
	is_host = GameState.is_host
	is_public = GameState.is_public
	
	var code = ""
	for i in range(len(str(id_lobby))):
		code += (" " + str(id_lobby)[i])
		
	lobby_code_panel.text = str(code)
	settings_button.disabled = !is_host
	start_button.disabled = !is_host
	add_bot_button.disabled = !is_host
	
	if is_host:
		lobby_name = str(GameState.lobby_name) 
		lobby_name_panel.text = lobby_name + "  LOBBY"
		players_limit = GameState.players_limit
		
		quit_button.text = "Remove Lobby"
		if  players_count >= players_limit:
			add_bot_button.disabled = true
		
	SocketManager.emit("get-lobby-info", id_lobby)

	#var data = GameState.data
	#if data != null:
		#_refresh_player_list(GameState.data)
		#
	#else:
	get_users()

	#set confirmation panel
	confirm_panel.connect("confirmed", Callable(self, "_on_confirmed"))
	confirm_panel.connect("canceled",  Callable(self, "_on_canceled"))
	
	# Timer de vérification de connexion
	connection_timer = Timer.new()
	connection_timer.wait_time = 2.0
	connection_timer.one_shot = false
	connection_timer.autostart = true
	add_child(connection_timer)
	connection_timer.timeout.connect(_check_connection)
	connection_lost_handled = false

	# Timer pour ping manuel
	ping_timer = Timer.new()
	ping_timer.wait_time = 2.0
	ping_timer.one_shot = false
	ping_timer.autostart = true
	add_child(ping_timer)
	ping_timer.timeout.connect(_send_ping)

	# Timer pour timeout pong
	pong_timeout_timer = Timer.new()
	pong_timeout_timer.wait_time = 4.0
	pong_timeout_timer.one_shot = true
	pong_timeout_timer.autostart = false
	add_child(pong_timeout_timer)
	pong_timeout_timer.timeout.connect(_on_pong_timeout)
	
func get_users():
	if is_public:
		print("emit get users in public room :", id_lobby)
		await get_tree().create_timer(0.1).timeout  # Délai pour laisser le temps au serveur
		SocketManager.emit("users-in-public-room", id_lobby)
	else:
		print("emit get users in private room :", id_lobby)
		await get_tree().create_timer(0.1).timeout  # Délai pour laisser le temps au serveur
		SocketManager.emit("users-in-private-room", id_lobby)
		
func _on_raw_packet(packet):
	print("Raw packet bytes:", packet)
	print("Raw packet string:", packet.get_string_from_utf8())
	
func check_ban_status():
	if Global.is_banned():
		start_button.disabled = true
	else:
		start_button.disabled = false

func update_player_list():
	# Vider la liste actuelle des joueurs
	for child in players_container.get_children():
		child.queue_free()

	# Récupérer les informations des joueurs depuis GameState
	var players = GameState.other_players
	for player in players:
		var player_entry = player_entry_scene.instantiate()
		player_entry.get_node("PlayerInfoContainer/PlayerName").text = player["username"]
		player_entry.get_node("PlayerInfoContainer/Icon").texture = load("res://assets/icons/" + str(player["icon"]) + ".png")
		players_container.add_child(player_entry)

func _on_socket_event(event: String, data: Variant, ns: String):
	match event:
		"pong":
			pong_timeout_timer.stop()
			return
		"users-in-your-private-room", "users-in-your-public-room" :
			print("event users in room received ")
			_refresh_player_list(data)
			
		"user-left":
			print("user left room :", data)
			
			if is_public:
				SocketManager.emit("users-in-public-room", id_lobby) 
			else:
				SocketManager.emit("users-in-private-room", id_lobby)
				
		"game-starting":
			_handle_game_starting()
			
		"kicked":
			message_control.get_node("mssg").text = "\nYou have been kicked from this lobby!"
			message_control.visible = true

		"public-room-joined", "private-room-joined":
			_refresh_player_list(data)
			
		"remove-room", "remove-public-room", "remove-private-room":
			_handle_remove_room()
			
		"room-settings-updated":
			_handle_update_settings(data)
			
			notif_label.visible = true
			await get_tree().create_timer(2.5).timeout
			notif_label.visible = false
			
		"lobby-info":
			print("lobby info received ", data)
			if(data != null):
				GameState.lobby_name = data[0].get("room").get("settings").get("lobbyName")
				GameState.players_limit = data[0].get("room").get("settings").get("playerLimit")
				GameState.rounds = data[0].get("room").get("settings").get("rounds")
				
				#set lobby info
				lobby_name = str(GameState.lobby_name) + "  LOBBY"
				lobby_name_panel.text = lobby_name
				players_limit = GameState.players_limit
				players_count_panel.text = str(players_count) + " / " + str(players_limit)
		
		"remove-public-room", "remove-private-room":
			message_control.get_node("mssg").text = "\nThis lobby has been removed!"
			message_control.visible = true
			await get_tree().create_timer(2.5).timeout
			reinit_gameState()
			get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
			
		_:
			print("unhandled event received \n", event, data)


func _handle_update_settings(data):
	print("lobby settings updated ", data)
	if(data != null):
		GameState.players_limit = data[0].get("playerLimit")
		GameState.rounds = data[0].get("rounds")
		GameState.card_number = data[0].get("numberOfCards")
		GameState.timer = data[0].get("roundTimer")
		
		#set lobby info
		lobby_name = str(GameState.lobby_name) + "  LOBBY"
		lobby_name_panel.text = lobby_name
		players_limit = GameState.players_limit
		players_count_panel.text = str(players_count) + " / " + str(players_limit)

	
	
func _handle_remove_room():
	message_control.get_node("mssg").text = "\n Lobby has been removed"
	message_control.visible = true
	
func _handle_game_starting():
	if !is_host and !scene_changed:
		scene_changed = true
		get_tree().change_scene_to_file("res://scenes/gameboard.tscn")


func _refresh_player_list(data):
	var host_icon
	var host_uname
	var bot_slots := []
	
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
		print("error in users :", outer)
		return

	var players_count = int(payload.get("count", 0))
	var players       = payload.get("users", [])
	
	if players_count > 1 and is_host:
		start_button.disabled = false
	else:
		start_button.disabled = true
		
	players_count_panel.text = str(players_count) + " / " + str(players_limit)
	
	## Update HostPlayer node
	var host_user = players[0] as Dictionary
	for child in host_node.get_children():
		child.queue_free()
	
	var host_entry = player_entry_scene.instantiate()
	host_node.add_child(host_entry)

	var host_icon_id = host_user.get("icon", null)
	host_icon_id = host_icon_id if host_icon_id != null else 0
	
	host_entry.create_player_visual(
		host_user.get("username", "Unknown"),
		host_icon_id,
		true # is_host = true
	)
	
	#add players to scene
	for i in range(1, players_count):
		var user_dict = players[i] as Dictionary
		
		if user_dict.get("username", "").begins_with("Bot"):
			var bot_instance = bot_scene.instantiate()
			bot_instance.bot_index = bot_slots.size() +1 #i + 1 
			if !is_host:
				bot_instance.get_node("BotHContainer/RemoveBotButton").disabled = true 
			bot_instance.lobby_scene = self  # Provide reference to LobbyScene
			players_container.add_child(bot_instance)
			bot_slots.append(bot_instance)
			#update_bot_slots()
		else:
			var entry     = player_entry_scene.instantiate()
			entry.lobby_scene = self
			players_container.add_child(entry)

			var icon_id = user_dict.get("icon", null)
			icon_id = icon_id if icon_id != null else 0
			
			entry.create_player_visual(
				user_dict.get("username", "Unknown"),
				icon_id,
				false
			)
			entry.get_node("PlayerInfoContainer/KickButton").disabled = !is_host
			print("child added to scene")
			
		var max_bot_index := 0
		for bs in bot_slots:
		# parse “Bot23” → 23
			var idx = bs.bot_index
			max_bot_index = max(max_bot_index, idx)
			
		for bs in bot_slots:
			var idx = bs.bot_index
			var btn = bs.get_node("BotHContainer/RemoveBotButton")
			btn.disabled = not is_host or idx != max_bot_index


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/gameboard.tscn")

	
func _on_quit_button_pressed() -> void:
	confirm_panel.action_type    = "quit"
	confirm_panel.scene = self
	if is_host:
		confirm_panel.message = "Remove \""+ lobby_name+ "\" Lobby ?"
	else :
		confirm_panel.message = "Quit lobby ?"
	confirm_panel.action_payload = {}
	confirm_panel.show_panel()


func remove_bot(bot_instance):
	if bot_count > 0:
		bot_count -= 1
		players_count -= 1
		GameState.players_count = players_count
		GameState.bot_count = bot_count
		#send remove bot to server
		var bot_name = "Bot" + str(bot_instance.bot_index)
		kick_player(bot_name)
		#update_bot_slots()


func update_bot_slots():
	# Clear existing bot slots
	for child in players_container.get_children():
		if child.has_method("check_bot_removal"):
			child.queue_free()

	# Recreate bots with correct numbering
	for i in range(bot_count):
		var bot_instance = bot_scene.instantiate()
		bot_instance.bot_index = i + 1 
		if !is_host:
			bot_instance.get_node("BotHContainer/RemoveBotButton").disabled = true 
		bot_instance.lobby_scene = self  # Provide reference to LobbyScene
		players_container.add_child(bot_instance)


func _on_add_bot_button_pressed() -> void:
	bot_count += 1
	
	players_count += 1
	GameState.players_count = players_count
	GameState.bot_count = bot_count
	
	SocketManager.emit("join-room", 
	{
		"roomId" : id_lobby,
		"username" : "Bot" + str(bot_count)
	})
	
	if players_count >= players_limit:
		add_bot_button.disabled = true


func kick_player(player_username):
	if !player_username.begins_with("Bot"):
		confirm_panel.action_type    = "kick"
		confirm_panel.message = "Kick \"" + player_username+ "\" from Lobby ?"
		confirm_panel.action_payload = { "username": player_username }
		confirm_panel.show_panel()
		
	#no need for confirmation o remove bot
	else:
		SocketManager.emit("kick-player", {
		"roomId" : id_lobby,
		"username" : player_username
		})


func _on_confirmed(action_type:String, payload) -> void:
	match action_type:
		"quit":
			SocketManager.emit("leave-room", { "roomId": id_lobby })
			reinit_gameState()
			
			get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")

		"kick":
			SocketManager.emit("kick-player", {
				"roomId": id_lobby,
				"username": payload.username
			})
			get_users()
		_:
			push_error("Unknown action: %s" % action_type)


func _on_canceled():
	#hide panel handled in confirm panel script
	pass


func reinit_gameState():
	GameState.players_count = 0
	GameState.data = null
	GameState.id_lobby = ""
	GameState.lobby_name = ""
	GameState.other_players = []
	GameState.rankings = null 


func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")


func _on_settings_button_pressed() -> void:
	get_node("lobbySettings").visible = true

# Ajout : gestion de la déconnexion websocket
func _on_socket_disconnected():
	if connection_lost_handled == false:
		connection_lost_handled = true
	# Arrêter les timers
	connection_timer.stop()
	ping_timer.stop()
	pong_timeout_timer.stop()
	# Afficher le message d'erreur
	var popup_scene = preload("res://scenes/popUp.tscn")
	var popup_instance = popup_scene.instantiate()
	var label = popup_instance.get_node("message")
	if label:
		label.text = "Server connection error"
		get_tree().current_scene.add_child(popup_instance)
		popup_instance.make_visible()
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _check_connection():
	if connection_lost_handled:
		return
	if not SocketManager.cust_is_connected():
		connection_lost_handled = true
		_on_socket_disconnected()

func _send_ping():
	if connection_lost_handled:
		return
	SocketManager.emit("ping", {})
	pong_timeout_timer.start()

func _on_pong_timeout():
	if connection_lost_handled:
		return
	connection_lost_handled = true
	_on_socket_disconnected()
