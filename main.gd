extends Control

# Database
var database : SQLite

# Network setup
var peer = ENetMultiplayerPeer.new()
var port = 8910
var max_clients = 10
var ip = "172.31.1.75"

# Game states
var local_username: String
var is_host: bool = false
var connected: bool = false

# Kobler alle Nodes til koden
@onready var username_input: LineEdit = $VBoxContainer/Username/UsernameInput
@onready var join: Button = $VBoxContainer/ButtonContainer/Join
@onready var host: Button = $VBoxContainer/ButtonContainer/Host
@onready var connection_label: Label = $VBoxContainer/ConnectionLabel
@onready var ip_input: LineEdit = $VBoxContainer/IPContainer/IPInput
#Chat
@onready var chat_display: TextEdit = $ChatContainer/ChatDisplay
@onready var chat_input: LineEdit = $ChatContainer/ChatInputContainer/ChatInput
@onready var chat_send: Button = $ChatContainer/ChatInputContainer/ChatSend


func _ready() -> void:
	# Setup SQLite
	database = SQLite.new()
	database.path = "res://data.db"
	database.open_db()
	create_sql_table("users")
	
	# Kobler Signaler til funksjoner i koden
	join.pressed.connect(_on_join_pressed)
	host.pressed.connect(_on_host_pressed)
	chat_send.pressed.connect(_on_chat_send_pressed)
	
	# Chat Inputs
	chat_input.text_changed.connect(_on_chat_input_changed)
	
	# connecter multiplayer signaler til koden
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	
	# Setter defualt IP
	ip_input.text = ip

func _on_join_pressed() -> void:
	local_username = username_input.text.strip_edges()
	
	# Connect til server
	var error = peer.create_client(ip_input.text, port)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		print("Connecting to " + ip + ":" + str(port))
	else:
		printerr("Error: " + str(error))

func _update_ui():
	connection_label.text = "Status: " + ("Connected as " + ("Host" if is_host else "Client") if is_connected else "Disconnected")
	
	# Slå av/på UI Elementer
	username_input.editable = not connected
	host.disabled = connected or username_input.text.strip_edges().is_empty()
	join.disabled = connected or username_input.text.strip_edges().is_empty()
	
	# Chat
	chat_input.editable = connected
	chat_send.disabled = not connected or chat_input.text.strip_edges().is_empty()


func _on_chat_send_pressed() -> void:
	var message = chat_input.text.strip_edges()
	if message.is_empty():
		return
	
	# Send message to all peers
	_send_chat_to_all.rpc(local_username, message)
	chat_input.text = ""
	_update_ui()

@rpc("any_peer", "call_local", "reliable")
func _send_chat_to_all(username: String, message: String):
	_add_chat_message(username, message)

func _add_chat_message(username: String, message: String):
	# Formatter mellingen med local username og mellingen som skal sendes
	var formatted_message = username + ": " + message
	chat_display.text += formatted_message + "\n"
	
	# Auto-scroller til bunnen
	chat_display.scroll_vertical = chat_display.get_line_count()

func _on_host_pressed() -> void:
	local_username = username_input.text.strip_edges()
	
	var error = peer.create_server(port, max_clients)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		connected = true
		is_host = true
		print("Startet Server på: " + str(port))
		_update_ui()
	else:
		printerr("ERROR: " + str(error))

func _on_peer_connected(id: int) -> void:
	_add_chat_message("System", "Player " + str(id) + " connected")

func _on_peer_disconnected() -> void:
	pass

func _on_connected_to_server() -> void:
	connected = true
	_add_chat_message("System","Connected to server!")
	
	 # Send forespørsel om brukeren finnes
	_register_player.rpc_id(1, local_username)


func _on_chat_input_changed(_text: String):
	_update_ui()

func _on_connection_failed() -> void:
	pass
	
func _on_server_disconnected() -> void:
	pass

func create_sql_table(tablename: String) -> void:
	var table = {
		"id": {"data_type": "int", "primary_key": true, "not_null": true, "auto_increment": true},
		"username": {"data_type": "text"}
	}
	database.create_table(tablename, table)

#_add_chat_message("System", username + " joined the game")

func insert_data(username: String) -> void:
	var data = {
		"username": username
	}
	database.insert_row("users", data)

@rpc("any_peer", "call_remote", "reliable")
func _register_player(username: String):
	if is_host:
		insert_data(username)

@rpc("any_peer", "call_remote", "reliable")
func _request_player_id(username: String):
	# Bare host (authority) kjører denne
	if not is_host:
		return
	var exists = false  # lokalt bool
	var query = "SELECT COUNT(*) AS cnt FROM users WHERE username = ?"
	if database.query_with_bindings(query, [username]):
		var row = database.query_result[0]
		var count = int(row["cnt"])
		if count > 0:
			exists = true
	else:
		printerr("query Unsuccessful")
	
	var sender = multiplayer.get_remote_sender_id()
	# send svar tilbake til klient
	rpc_id(sender, "_on_player_exists_response", exists, username)

@rpc("any_peer", "call_local", "reliable")
func _on_player_exists_response(exists: bool, username: String):
	if exists:
		print("Bruker finnes!")
		# hent ID og sett
		_request_player_id.rpc_id(1, local_username)
		if not is_host:
			return
		var id = _get_id_of_user(username)
		var sender = multiplayer.get_remote_sender_id()
		rpc_id(sender, "_on_player_id_response", id)
	else:
		print("Ny bruker, registrerer")
		_register_player.rpc_id(1, local_username)
