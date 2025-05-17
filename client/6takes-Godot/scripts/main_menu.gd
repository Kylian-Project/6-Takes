extends Control

const DEFAULT_BRIGHTNESS = 1.0
const DEFAULT_CONTRAST   = 1.0

@onready var login_scene = preload("res://scenes/logIn.tscn")
@onready var colorblind_option = $AccessibilityOverlay/TabContainer/Accessibility/Accessibility/VSettings/ColorBlindOptions
@onready var color_blind = get_node("/root/ColorBlindness")     
@onready var settings_overlay = $SettingsOverlay
@onready var settings_button = $SettingsButton
@onready var rules_button = $Rules
@onready var rules_overlay = $RulesOverlay
@onready var singleplayer_button = $VButtons/SinglePlayerButton
@onready var quit_button = $VButtons/QuitButton
@onready var multiplayer_button = $VButtons/MultiPlayerButton
@onready var profile_button = $Profile
@onready var overlay_layer = $OverlayLayer
@onready var accessibility_button = $AccessibilityButton
@onready var accessibility_overlay = $AccessibilityOverlay
@onready var brightness_slider = $AccessibilityOverlay/TabContainer/Accessibility/Accessibility/VSettings/MarginContainer/BrightnessSlider
@onready var contrast_slider = $AccessibilityOverlay/TabContainer/Accessibility/Accessibility/VSettings/MarginContainer2/ContrastSlider
@onready var reset_button = $AccessibilityOverlay/ResetButtonAccessibility
const USER_SETTINGS : String = "user://settings.cfg"

@onready var close_buttons = [
	$SettingsOverlay/Close,
	$RulesOverlay/MarginContainer/Control/Panel/CancelButton,
	$AccessibilityOverlay/Close,
]


@onready var overlay_buttons = [
	settings_button,
	rules_button,
	accessibility_button,
]

@onready var message_control = $mssgControl
@onready var closeButton = $mssgControl/closeButton
# CHECK BAN
var ban_time_left = 0  # Variable globale pour stocker le temps restant
var base_url = Global.get_base_url()
var base_http = Global.get_base_http()
var api_url = base_http + base_url + "/api/player/ban-status/"


var login_instance = null
var rules_instance = null 
var logged_in 
var timer = Timer.new()

func _ready() -> void:
	if OS.get_name() == "Web":
		quit_button.hide()
	
	# CHECK BAN
	check_ban_status()
	
	rules_overlay.visible = false
	settings_overlay.visible = false
	accessibility_overlay.visible = false
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.visible = false
	singleplayer_button.pressed.connect(go_to_singleplayer)
	settings_button.pressed.connect(show_settings)
	profile_button.pressed.connect(_on_profile_pressed)
	rules_button.pressed.connect(_on_rules_pressed)
	quit_button.pressed.connect(quit_game)
	accessibility_button.pressed.connect(_on_accessibility_button_pressed)	
	
	# Hover Soundboard
	singleplayer_button.mouse_entered.connect(SoundManager.play_hover_sound)
	multiplayer_button.mouse_entered.connect(SoundManager.play_hover_sound)
	quit_button.mouse_entered.connect(SoundManager.play_hover_sound)
	settings_button.mouse_entered.connect(SoundManager.play_hover_sound)
	profile_button.mouse_entered.connect(SoundManager.play_hover_sound)
	rules_button.mouse_entered.connect(SoundManager.play_hover_sound)
	accessibility_button.mouse_entered.connect(SoundManager.play_hover_sound)
	
	# Populate or verify your Off/On items have IDs 0/1,
	# connect the signal, then force one initial call:
	colorblind_option.clear()
	colorblind_option.add_item("Off", 0)
	colorblind_option.add_item("On",  1)

	 # 2) load whatever they last picked (default to “Off” → 0):
	# read the last-saved choice (default to 0)
	var last = 0
	var cfg = ConfigFile.new()
	if cfg.load(USER_SETTINGS) == OK:
		last = int(cfg.get_value("accessibility", "colorblind_mode", 0))
	colorblind_option.select(last)
	_on_color_blind_options_item_selected(last)

	colorblind_option.item_selected.connect(_on_color_blind_options_item_selected)
		
	# Click Soundboard
	singleplayer_button.pressed.connect(SoundManager.play_click_sound)
	multiplayer_button.pressed.connect(SoundManager.play_click_sound)
	quit_button.pressed.connect(SoundManager.play_click_sound)
	settings_button.pressed.connect(SoundManager.play_click_sound)
	profile_button.pressed.connect(SoundManager.play_click_sound)
	rules_button.pressed.connect(SoundManager.play_click_sound)
	accessibility_button.pressed.connect(SoundManager.play_click_sound)

	for close_button in close_buttons:
		close_button.pressed.connect(hide_settings)
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)
		
	# Background Music
	SoundManager.play_music()
	
	colorblind_option.item_selected.connect(_on_color_blind_options_item_selected)
	
	Global.load_session()
	logged_in = Global.getLogged_in()
	
	profile_button.visible = logged_in
	print("visibilty : ", profile_button.visible) 
	
	if logged_in == false:
		singleplayer_button.text ="Play As A Guest"
		multiplayer_button.text = "Log In"
		
	else :
		singleplayer_button.text ="Singleplayer"
		multiplayer_button.text = "Multiplayer"
		
	reset_button.pressed.connect(self._on_reset_button_accessibility_pressed)


func _process(_delta):
	overlay_layer.visible = overlay_layer.get_child_count() > 0
	#overlay_layer.visible = (
		#settings_overlay.visible or
		#rules_overlay.visible or
		#accessibility_overlay.visible
	#)
	
func check_ban_status():
	var username = Global.player_name  # Récupérer dynamiquement le nom de l'utilisateur
	if username == "":
		print("[ERREUR] Nom d'utilisateur non défini")
		return
	print("[DEBUG] Appel de check_ban_status pour l'ID: ", username)

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_ban_status_received"))
	
	var url = api_url + username
	print("[DEBUG] URL construite : ", url)
	var error = http_request.request(url)

	if error != OK:
		print("[ERREUR] Erreur lors de l'envoi de la requête : ", error)
	else:
		print("[DEBUG] Requête envoyée avec succès.")
	

func _on_ban_status_received(result, response_code, headers, body):
	print("[DEBUG] Réponse HTTP reçue : code =", response_code)
	print("[DEBUG] Réponse brute : ", body.get_string_from_utf8())
	if response_code == 200:
		var json = JSON.new()
		var parsed = json.parse(body.get_string_from_utf8())
		print("[DEBUG] Code de retour du parsing JSON : ", parsed)

		# Vérification si le parsing a réussi
		if parsed == OK:
			var response = json.get_data()
			print("[DEBUG] Parsing JSON réussi. Contenu : ", response)

			# Vérifier si la réponse contient les champs attendus
			if response.has("isBanned") and response.has("timeLeft"):
				if response["isBanned"]:
					show_ban_mssg()
					var time_left = response["timeLeft"]
					print("[INFO] Le joueur est banni pour encore ", time_left, " secondes.")
					# Désactiver le bouton multijoueur et afficher le timer
					if multiplayer_button:
						multiplayer_button.disabled = true
						multiplayer_button.text = str(time_left) + "sec"
					else:
						print("[ERREUR] Bouton Multijoueur non trouvé !")

					start_ban_timer(time_left)
				else:
					print("[INFO] Le joueur n'est pas banni.")
					multiplayer_button.disabled = false
					multiplayer_button.text = "Multiplayer"
			else:
				print("[DEBUG] Erreur : Champs 'isBanned' ou 'timeLeft' manquants dans la réponse.")
		else:
			print("[DEBUG] Erreur lors du parsing JSON : ", json.get_error_message())
			print("[DEBUG] Ligne de l'erreur : ", parsed)
	else:
		print("[DEBUG] Erreur HTTP : ", response_code)


func start_ban_timer(time_left):
	print("[DEBUG] Démarrage du timer de ban pour : ", time_left, " secondes.")
	ban_time_left = time_left
	add_child(timer)
	timer.wait_time = 1
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "_update_ban_timer"))
	timer.start()
	print("[DEBUG] Timer démarré avec intervalle de 1 seconde.")


func _format_time(seconds: int) -> String:
	var days = int(seconds / 86400)  # 86400 seconds in a day
	var hours = int((seconds % 86400) / 3600)  # 3600 seconds in an hour
	var minutes = int((seconds % 3600) / 60)  # 60 seconds in a minute
	var secs = seconds % 60

	if days > 0:
		return str(days) + "d:" + str(hours).pad_zeros(2) + "h:" + str(minutes).pad_zeros(2) + "m:" + str(secs).pad_zeros(2) + "s"
	elif hours > 0:
		return str(hours).pad_zeros(2) + "h:" + str(minutes).pad_zeros(2) + "m:" + str(secs).pad_zeros(2) + "s"
	elif minutes > 0:
		return str(minutes).pad_zeros(2) + "m:" + str(secs).pad_zeros(2) + "s"
	else:
		return str(secs) + "s"

func _update_ban_timer():
	ban_time_left -= 1
	if ban_time_left <= 0:
		print("[INFO] Fin du ban. Réactivation du bouton multijoueur.")
		# Arreter le timer
		timer.stop()
		timer.queue_free()
		# Réactiver le bouton multijoueur
		multiplayer_button.disabled = false
		multiplayer_button.text = "Multiplayer"
		get_tree().call_group("timers", "stop")
		get_tree().call_group("timers", "queue_free")
	else:
		multiplayer_button.text = _format_time(ban_time_left)
		# print("[DEBUG] Texte du bouton mis à jour : ", multiplayer_button.text)

func _on_multi_player_button_pressed() -> void:
	logged_in = Global.getLogged_in()
	var socket_manager = get_node("/root/SocketManager")
	if not socket_manager.cust_is_connected():
		socket_manager.reconnect()
		if not socket_manager.cust_is_connected():
			var popup_scene = preload("res://scenes/popUp.tscn")
			var popup_instance = popup_scene.instantiate()
			var label = popup_instance.get_node("message")
			if label:
				label.text = "Server connection error"
				await get_tree().process_frame
				add_child(popup_instance)
				popup_instance.make_visible()
			return
	if logged_in == true:
		get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
	else:
		if login_instance == null:
			login_instance = login_scene.instantiate()
			add_child(login_instance)
			await get_tree().process_frame  
		login_instance.move_to_front()
		login_instance.visible = true
	

func go_to_singleplayer():
	get_tree().change_scene_to_file("res://scenes/SPLobbyScene.tscn")

func _on_cancel_button_pressed() -> void:
	rules_overlay.visible = false


func open_overlay(overlay: Control):
	# Hide all overlays first
	settings_overlay.visible = false
	rules_overlay.visible = false
	accessibility_overlay.visible = false

	# Show the selected overlay
	overlay.visible = true
	overlay_layer.visible = true

	move_child(overlay_layer, get_child_count() - 1)

	for b in overlay_buttons:
		b.disabled = true



func show_settings() -> void:
	#settings_overlay.visible = true
	#overlay_layer.visible   = true  
	for b in overlay_buttons:
		b.disabled = true

	open_overlay(settings_overlay)

func hide_settings() -> void:
	settings_overlay.visible     = false
	accessibility_overlay.visible = false
	rules_overlay. visible = false
	overlay_layer.visible = false
	for b in overlay_buttons:
		b.disabled = false
	
func quit_game():
	get_tree().quit()


func _on_rules_pressed() -> void:
	open_overlay(rules_overlay)
	
	
func _on_profile_pressed():
	var edit_profile_scene = load("res://scenes/edit_profile.tscn")
	var edit_profile_instance = edit_profile_scene.instantiate()
	
	overlay_layer.add_child(edit_profile_instance)
	overlay_layer.visible = true
	
	await get_tree().process_frame

	# Récupère les boutons de l'instance ajoutée
	var save_button = edit_profile_instance.get_node("EditProfilePanel/MainVertical/SaveIconButton")
	var close_button = edit_profile_instance.get_node("Close")

	# Connecte les sons si les boutons existent
	if save_button:
		save_button.mouse_entered.connect(SoundManager.play_hover_sound)
		save_button.pressed.connect(SoundManager.play_click_sound)

	if close_button:
		close_button.mouse_entered.connect(SoundManager.play_hover_sound)
		close_button.pressed.connect(SoundManager.play_click_sound)

func _on_accessibility_button_pressed() -> void:
	var b = GlobalWorldEnvironment.environment.adjustment_brightness
	var c = GlobalWorldEnvironment.environment.adjustment_contrast

	brightness_slider.value = b
	contrast_slider.value   = c

	open_overlay(accessibility_overlay)


func _on_brightness_slider_value_changed(value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_brightness = value


func _on_contrast_slider_value_changed(value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_contrast = value

func _on_color_blind_options_item_selected(index: int) -> void:
	color_blind.visible = (index == 1)
	# persist it to user://settings.cfg
	var cfg = ConfigFile.new()
	# try to load existing so you don’t wipe out other keys
	if cfg.load(USER_SETTINGS) != OK:
		# no file yet — that’s fine
		pass

	cfg.set_value("accessibility", "colorblind_mode", index)
	cfg.save(USER_SETTINGS)


func _on_reset_button_accessibility_pressed() -> void:
	# 1) Reset slider positions
	brightness_slider.value = DEFAULT_BRIGHTNESS
	contrast_slider.value   = DEFAULT_CONTRAST
	# 2) Reset option button (ID 0 = Off)
	colorblind_option.select(0)
	
	# 3) Reapply each setting to the environment/filter	
	#    (you probably already have these handlers—call them directly)
	_on_brightness_slider_value_changed(DEFAULT_BRIGHTNESS)
	_on_contrast_slider_value_changed(DEFAULT_CONTRAST)
	_on_color_blind_options_item_selected(0)

func _on_close_button_pressed():
	message_control.visible = false

func show_ban_mssg():
	message_control.get_node("mssg").text = "\nYou have been banned from Multiplayer for not respecting game rules and leaving an active game! \nRemember, our game is designed to provide a fair and enjoyable experience for everyone.\n"
	message_control.visible = true
	closeButton.pressed.connect(_on_close_button_pressed)
