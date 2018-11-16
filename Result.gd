extends Node

var menu
var scene

var is_this_server

var server
var connection
var peerstream

var playAgainPressed
var menuPressed

var resultLabel
var resultString

var did_server_win

func init_results(serverPoints, clientPoints, server_leading ,am_I_server, vserver, vconnection):
	if serverPoints > clientPoints and !am_I_server:
		get_node("Sprite").set_texture(load("PNG/loss.png"))
		did_server_win = true
	elif serverPoints > clientPoints and am_I_server:
		did_server_win = true
	elif clientPoints > serverPoints and !am_I_server:
		did_server_win = false
	elif clientPoints > serverPoints and am_I_server:
		did_server_win = false
		get_node("Sprite").set_texture(load("PNG/loss.png"))
	elif serverPoints == clientPoints:
		if am_I_server:
			if server_leading:
				did_server_win = true
			else:
				did_server_win = false
				get_node("Sprite").set_texture(load("PNG/loss.png"))
		else:
			if server_leading:
				did_server_win = true
				get_node("Sprite").set_texture(load("PNG/loss.png"))
			else:
				did_server_win = false
	if !am_I_server:
		resultString = str(clientPoints, " : ", serverPoints)
	else:
		resultString = str(serverPoints, " : ", clientPoints)
	server = vserver
	connection = vconnection
	peerstream = PacketPeerStream.new()
	peerstream.set_stream_peer(connection)
	is_this_server = am_I_server

func _ready():
	menu = get_tree().get_root().get_node("Scene/Menu")
	scene = get_tree().get_root().get_node("Scene")
	get_node("Result").set_text(resultString)
	scene.reset_menu()
	get_node("MenuReturn").connect("pressed", self, "return_to_menu")
	get_node("PlayAgain").connect("pressed", self, "play_again")
	var timer = Timer.new()
	add_child(timer)
	timer.set_one_shot(true)
	timer.set_wait_time(0.1)

	while true:
		if playAgainPressed or menuPressed:
			break
		else:
			timer.start()
			yield(timer, "timeout")

	var packet
	while true and !menuPressed:
		if peerstream.get_available_packet_count() > 0:
			packet = peerstream.get_var()
			if packet[0] == "no" or packet[0] == "yes":
				break;
		else:
			timer.start()
			yield(timer, "timeout")
	
	if menuPressed:
		menu.show()
		queue_free()
	elif packet[0] == "no":
		menu.show()
		queue_free()
	else:
		if is_this_server:
			var new_scene = load("res://Server.tscn").instance()
			new_scene.init_server(server, connection, did_server_win)
			scene.add_child(new_scene)
			queue_free()
		else:
			var new_scene = load("res://Client.scn").instance()
			new_scene.init_client(connection, peerstream, did_server_win)
			scene.add_child(new_scene)
			queue_free()
	pass

func return_to_menu():
	peerstream.put_var(["no"])
	menuPressed = true

func play_again():
	get_node("PlayAgain").set_text("Waiting...")
	get_node("PlayAgain").set_disabled(true)
	peerstream.put_var(["yes"])
	playAgainPressed = true

	