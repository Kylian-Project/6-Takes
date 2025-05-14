extends TabBar

var config_cfg = ConfigFile.new()
const CONFIG_PATH = "res://config/config.cfg"
const FILE_PATH = "user://settings.cfg"

# UI nodes
@onready var preset_option = $HorizontalAlign/VSettings/PresetOptionButton
@onready var url_edit = $HorizontalAlign/VSettings/LineEditSrvURL
@onready var port_edit = $HorizontalAlign/VSettings/LineEditSrvPORT
@onready var http_option = $HorizontalAlign/VSettings/HTTPOption

func _ready():
	# Charger les fichiers de config
	config_cfg.load(CONFIG_PATH)
	# Utilisation du SettingsManager pour la config utilisateur
	var settings_cfg = SettingsManager.config

	# Appliquer le preset sauvegardé ou default
	var saved_preset = settings_cfg.get_value("Server", "Preset", 0)
	preset_option.select(saved_preset)
	_apply_preset(saved_preset)

	# Connecter le signal
	preset_option.connect("item_selected", Callable(self, "_on_preset_selected"))
	url_edit.editable = (saved_preset == 2)
	port_edit.editable = (saved_preset == 2)
	http_option.disabled = (saved_preset != 2)

	# Charger les valeurs custom si besoin
	url_edit.text = settings_cfg.get_value("Server", "SRV_URL", "localhost")
	port_edit.value = int(settings_cfg.get_value("Server", "SRV_PORT", 80))
	http_option.select(settings_cfg.get_value("Server", "HTTP_IDX", 0))

	# Désactiver l'onglet server settings si déjà connecté
	if has_node("/root/Global") and get_node("/root/Global").logged_in:
		preset_option.disabled = true
		url_edit.editable = false
		port_edit.editable = false
		http_option.disabled = true


func _on_preset_selected(idx):
	_apply_preset(idx)
	SettingsManager.config.set_value("Server", "Preset", idx)
	SettingsManager.config.save(FILE_PATH)

func _apply_preset(idx):
	var settings_cfg = SettingsManager.config
	if idx == 0:
		# Default
		url_edit.editable = false
		port_edit.editable = false
		http_option.disabled = true
	elif idx == 1:
		# BASTION
		url_edit.editable = false
		port_edit.editable = false
		http_option.disabled = true
	elif idx == 2:
		# Custom
		url_edit.editable = true
		port_edit.editable = true
		http_option.disabled = false
		# Charger les valeurs custom si elles existent
		url_edit.text = settings_cfg.get_value("Server", "SRV_URL", "localhost")
		port_edit.value = int(settings_cfg.get_value("Server", "SRV_PORT", 80))
		http_option.select(settings_cfg.get_value("Server", "HTTP_IDX", 0))

func _process(_delta):
	pass


func _on_line_edit_srv_url_text_changed(new_text: String) -> void:
	# Save the URL to the settings
	SettingsManager.config.set_value("Server", "SRV_URL", new_text)
	SettingsManager.config.save(FILE_PATH)


func _on_line_edit_srv_port_value_changed(value: float) -> void:
	# Save the port to the settings
	SettingsManager.config.set_value("Server", "SRV_PORT", str(value))
	SettingsManager.config.save(FILE_PATH)


func _on_http_option_item_selected(index: int) -> void:
	# Save the HTTP index to the settings
	SettingsManager.config.set_value("Server", "HTTP_IDX", index)
	SettingsManager.config.save(FILE_PATH)


func _on_close_pressed() -> void:
	print("Close pressed")
	# Rafraîchir les infos serveur dans Global
	if has_node("/root/Global"):
		get_node("/root/Global")._ready()
		get_node("/root/SocketManager").reconnect()
