extends TabBar

@onready var display_option = $HorzontalAlign/VSettings/DisplayOption
@onready var resolution_option = $HorzontalAlign/VSettings/ResolutionOptions
@onready var vsync_option = $HorzontalAlign/VSettings/VSyncOptions

var native_resolution = Vector2i(0, 0)

func _ready() -> void:
	# Get native resolution
	native_resolution = SettingsManager.get_native_resolution()
	
	# Setup resolution options
	setup_resolution_options()
	
	# Connect to settings changed signal
	SettingsManager.display_settings_changed.connect(update_ui_from_settings)
	
	# Load saved settings
	SettingsManager.load_settings()
	update_ui_from_settings()
	
	# Connect signals
	display_option.item_selected.connect(_on_display_option_item_selected)
	resolution_option.item_selected.connect(_on_resolution_options_item_selected)
	vsync_option.item_selected.connect(_on_v_sync_options_2_item_selected)

func setup_resolution_options():
	# Clear existing items
	resolution_option.clear()
	
	# Add standard resolutions
	resolution_option.add_item("1920 x 1080", 0)
	resolution_option.add_item("1152 x 648", 1)
	
	# Add native resolution if different from standard ones
	if native_resolution != Vector2i(1920, 1080) and native_resolution != Vector2i(1152, 648):
		resolution_option.add_item(str(native_resolution.x) + " x " + str(native_resolution.y) + " (native)", 2)

func _on_display_option_item_selected(index: int) -> void:
	var current_resolution = DisplayServer.window_get_size()
	
	match index:
		0: # Fullscreen
			get_window().mode = Window.MODE_FULLSCREEN
			# Résolution reste inchangée en fullscreen
		1: # Windowed
			var resolution_to_apply
			
			# Déterminer quelle résolution appliquer
			var selected_idx = resolution_option.selected
			if selected_idx == 0:
				resolution_to_apply = Vector2i(1920, 1080)
			elif selected_idx == 1:
				resolution_to_apply = Vector2i(1152, 648)
			elif selected_idx >= 2:
				# Pour la résolution native, on maximise au lieu d'utiliser le mode fenêtré
				get_window().mode = Window.MODE_MAXIMIZED
				SettingsManager.save_display_settings(
					Window.MODE_MAXIMIZED,
					native_resolution,
					DisplayServer.window_get_vsync_mode()
				)
				update_ui_from_settings()
				return
			
			# Appliquer la résolution et centrer la fenêtre
			get_window().mode = Window.MODE_WINDOWED
			DisplayServer.window_set_size(resolution_to_apply)
			var screen_size = DisplayServer.screen_get_size()
			var window_position = Vector2i((screen_size.x - resolution_to_apply.x) / 2, (screen_size.y - resolution_to_apply.y) / 2)
			DisplayServer.window_set_position(window_position)
		
		2: # Borderless Fullscreen
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	
	# Update resolution option enabled state
	resolution_option.disabled = index != 1 || get_window().mode == Window.MODE_MAXIMIZED
	
	# Save selection
	SettingsManager.save_display_settings(
		get_window().mode, 
		DisplayServer.window_get_size(), 
		DisplayServer.window_get_vsync_mode()
	)

func _apply_selected_resolution():
	var resolution
	var selected_idx = resolution_option.selected
	
	if selected_idx == 0:
		resolution = Vector2i(1920, 1080)
	elif selected_idx == 1:
		resolution = Vector2i(1152, 648)
	else:
		resolution = native_resolution
		# For native resolution, maximize the window
		get_window().mode = Window.MODE_MAXIMIZED
		
		# Save selection with native resolution and maximized mode
		SettingsManager.save_display_settings(
			get_window().mode, 
			native_resolution, 
			DisplayServer.window_get_vsync_mode()
		)
		return
	
	# Center the window on the screen
	DisplayServer.window_set_size(resolution)
	var screen_size = DisplayServer.screen_get_size()
	var window_position = Vector2i((screen_size.x - resolution.x) / 2, (screen_size.y - resolution.y) / 2)
	DisplayServer.window_set_position(window_position)

func _on_resolution_options_item_selected(index: int) -> void:
	if display_option.selected == 1:
		_apply_selected_resolution()
		
		# Save selection
		SettingsManager.save_display_settings(
			DisplayServer.window_get_mode(), 
			DisplayServer.window_get_size(), 
			DisplayServer.window_get_vsync_mode()
		)

func _on_v_sync_options_2_item_selected(index: int) -> void:
	var vsync_mode = DisplayServer.VSYNC_ENABLED if index == 0 else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)

	# Save selection
	SettingsManager.save_display_settings(
		DisplayServer.window_get_mode(), 
		DisplayServer.window_get_size(), 
		vsync_mode
	)

func update_ui_from_settings():
	var window = get_window()
	var mode = window.mode
	var resolution = DisplayServer.window_get_size()
	var vsync = DisplayServer.window_get_vsync_mode()
	
	# Set mode index
	match mode:
		Window.MODE_FULLSCREEN:
			display_option.select(0)
		Window.MODE_WINDOWED:
			display_option.select(1)
		Window.MODE_EXCLUSIVE_FULLSCREEN:
			display_option.select(2)
		Window.MODE_MAXIMIZED:
			display_option.select(1)  # Windowed mode, but maximized
	
	# Set resolution option enabled/disabled state
	resolution_option.disabled = mode != Window.MODE_WINDOWED || mode == Window.MODE_MAXIMIZED
	
	# Set resolution index
	if mode == Window.MODE_MAXIMIZED:
		# Si la fenêtre est maximisée, sélectionner l'option de résolution native
		for i in resolution_option.get_item_count():
			if i >= 2 && resolution_option.get_item_text(i).begins_with(str(native_resolution.x)):
				resolution_option.select(i)
				break
	elif resolution == Vector2i(1920, 1080):
		resolution_option.select(0)
	elif resolution == Vector2i(1152, 648):
		resolution_option.select(1)
	elif resolution == native_resolution:
		for i in resolution_option.get_item_count():
			if i >= 2 && resolution_option.get_item_text(i).begins_with(str(native_resolution.x)):
				resolution_option.select(i)
				break
	
	# Set vsync index
	vsync_option.select(0 if vsync == DisplayServer.VSYNC_ENABLED else 1)
