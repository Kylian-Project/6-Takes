extends Control

const DEFAULT_BRIGHTNESS = 1.0
const DEFAULT_CONTRAST   = 1.0

@onready var rules = preload("res://scenes/rules.tscn")
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


#validate token 
var API_URL 

var login_instance = null
var rules_instance = null 
var logged_in 

func _ready() -> void:
	rules_overlay.visible = false
	settings_overlay.visible = false
	accessibility_overlay.visible = false
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_layer.visible = false
	singleplayer_button.pressed.connect(go_to_singleplayer)
	settings_button.pressed.connect(show_settings)
	profile_button.pressed.connect(_on_profile_pressed)
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
	
	get_node("/root/Global").load_session()
	logged_in = get_node("/root/Global").getLogged_in()
	
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
	overlay_layer.visible = (
		settings_overlay.visible or
		rules_overlay.visible or
		accessibility_overlay.visible
	)
	

func _on_multi_player_button_pressed() -> void:
	#get_node("/root/Global").load_session()
	logged_in = get_node("/root/Global").getLogged_in()
	
	if logged_in == true:
		get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")
		
	else:
		if login_instance == null:
			login_instance = login_scene.instantiate()
			add_child(login_instance)

			# Centrer l'écran de pause
			await get_tree().process_frame  
			
		login_instance.move_to_front()  # S'assurer que l'écran de pause est tout en haut
		login_instance.visible = true  # Afficher la pause
	

func go_to_singleplayer():
	get_tree().change_scene_to_file("res://scenes/SPLobbyScene.tscn")

func _on_cancel_button_pressed() -> void:
	rules_overlay.visible = false


func open_overlay(panel: Control):
	 # 1) hide all panels
	settings_overlay.visible      = false
	rules_overlay.visible         = false
	accessibility_overlay.visible = false
	# 2) show & reorder the blocker (OverlayLayer)
	overlay_layer.visible = true
	# move OverlayLayer to be the last child so it draws on top
	move_child(overlay_layer, get_child_count() - 1)
	# 3) show & reorder your chosen panel above the blocker
	panel.visible = true
	move_child(panel, get_child_count() - 1)

	for b in overlay_buttons:
		b.disabled = true


func show_settings() -> void:
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
