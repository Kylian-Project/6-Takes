extends Node

@onready var socket_io = SocketIO.new()

signal connected()
signal disconnected()
signal event_received(event: String, data: Variant, ns: String)

func _ready():
	add_child(socket_io)
	var base = Global.get_base_http() + Global.get_base_url()
	socket_io.base_url = base
	socket_io.connect_socket()

	socket_io.socket_connected.connect(_on_connected)
	socket_io.socket_disconnected.connect(_on_disconnected)
	socket_io.event_received.connect(_on_event)

func _on_connected(ns):
	emit_signal("connected", ns)

func _on_disconnected():
	emit_signal("disconnected")

func _on_event(event, data, ns):
	emit_signal("event_received", event, data, ns)

# helper to emit
func emit(event_name: String, payload):
	socket_io.emit(event_name, payload)

# Nouvelle méthode pour relancer la connexion websocket
func reconnect():
	socket_io.disconnect_socket()
	await get_tree().process_frame
	socket_io.base_url = Global.get_base_http() + Global.get_base_url()
	socket_io.connect_socket()

func cust_is_connected() -> bool:
	return socket_io.state == EngineIO.State.CONNECTED
