extends Node

@onready var socket_io : SocketIO = $"."
var BASE_URL 

func _ready() -> void:
	#connect to socket
	BASE_URL = get_node("/root/Global").get_base_url()
	BASE_URL = "http://" + BASE_URL
	socket_io.base_url = BASE_URL
	socket_io.connect_socket()
	#socket_io.event_received.connect(_on_socket_event_received)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
