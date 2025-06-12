extends Control


# Network setup
var peer = ENetMultiplayerPeer.new()
var port = 8910111
var max_clients = 10
var ip = "172.31.1.75"

# Game states
var local_username: String
var is_host: bool
var is_connected: bool

# Kobler alle Nodes til koden
@onready var username_input: LineEdit = $VBoxContainer/Username/UsernameInput
@onready var join: Button = $VBoxContainer/ButtonContainer/Join
@onready var host: Button = $VBoxContainer/ButtonContainer/Host
@onready var connection_label: Label = $VBoxContainer/ConnectionLabel


func _ready() -> void:
	# Kobler Signaler til funksjoner i koden
	join.pressed.connect(_on_join_pressed)
	host.pressed.connect(_on_host_pressed)
	
	# Kobler tekst inputs
	username_input.text_changed.connect(_on_username_changed) 
	
	# connecter multiplayer signaler til koden
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _update_ui():
	connection_label.text = "Status: " + ("Connected as " + ("Host" if is_host else "Client") if is_connected else "Disconnected")
	
	# Slå av/på UI Elementer
	username_input.editable = not is_connected
	host.disabled = is_connected or username_input.text.strip_edges().is_empty()
	join.disabled = is_connected or username_input.text.strip_edges().is_empty()


func _on_join_pressed() -> void:
	local_username = username_input.text.strip_edges()
	
	# Connect til server
	var error = peer.create_client(ip, port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Connecting to " + ip + ":" + str(port))
	else:
		printerr("Error: " + str(error))

func _on_host_pressed() -> void:
	pass

func _on_peer_connected() -> void:
	pass

func _on_peer_disconnected() -> void:
	pass

func _on_connected_to_server() -> void:
	pass
	
func _on_connection_failed() -> void:
	pass
	
func _on_server_disconnected() -> void:
	pass

func _on_username_changed() -> void:
	_update_ui()
