extends Node

var client := WebSocketPeer.new()
var connected := false

func _ready():
    client.connect("connection_established", Callable(self, "_on_connection_established"))
    client.connect("connection_error", Callable(self, "_on_connection_error"))
    client.connect("connection_closed", Callable(self, "_on_connection_closed"))
    client.connect("data_received", Callable(self, "_on_data_received"))

    # Connecttion
    var url = "ws://185.155.93.105:14001"
    var err = client.connect_to_url(url)
    if err != OK:
        print("Erreur de connexion WebSocket : ", err)
    else:
        print("Tentative de connexion WebSocket à ", url)

    # Ajoute un client au process
    set_process(true)

# Update WebSocket
func _process(_delta):
    client.poll()


# === Signaux ===

func _on_connection_established():
    connected = true
    print("Connexion WebSocket établie.")

func _on_connection_error():
    print("Erreur lors de la tentative de connexion.")

func _on_connection_closed():
    connected = false
    print("Connexion WebSocket fermée.")

func _on_data_received():
    var pkt = client.get_packet().get_string_from_utf8()
    print("Données reçues :", pkt)