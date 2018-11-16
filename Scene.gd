extends Node

var port = 3560
var connect_cancel = false
var v_server

func _ready():
	OS.set_low_processor_usage_mode(true)
	get_node("Menu/StatusLabel").hide()
	get_node("Menu/CancelConnect").hide()
	get_node("Menu/IP").set_text("127.0.0.1")
	get_node("Menu/Host").connect("pressed", self, "_on_Button_Host_pressed")
	get_node("Menu/Connect").connect("pressed", self, "_on_Button_Connect_pressed")
	get_node("Menu/CancelConnect").connect("pressed", self, "stop_connecting")

func _on_Button_Host_pressed():
	get_node("Menu/SamplePlayer2D").play("button")
	if is_processing() == false:
		get_node("Menu/Connect").set_disabled(true)
		get_node("Menu/Host").set_text("Cancel")
		v_server = TCP_Server.new()
		if v_server.listen(port) == 0:
			set_process(true)
			get_node("Menu/StatusLabel").show()
			get_node("Menu/StatusLabel").set_text("Waiting for client...")
		else:
			get_node("Menu/StatusLabel").show()
			get_node("Menu/StatusLabel").set_text("Something is wrong with port 3560")
	else:
		set_process(false)
		v_server.stop()
		get_node("Menu/StatusLabel").hide()
		get_node("Menu/Connect").set_disabled(false)
		get_node("Menu/Host").set_text("Host")

func _on_Button_Connect_pressed():
	get_node("Menu/SamplePlayer2D").play("button")
	set_process(false)
	get_node("Menu/StatusLabel").hide()
	var ip_regex = RegEx.new()
	ip_regex.compile("\\b(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b")
	if ip_regex.is_valid() and ip_regex.find(get_node("Menu/IP").get_text()) == 0:
		get_node("Menu/StatusLabel").show()
		get_node("Menu/StatusLabel").set_text("Connecting...")
		get_node("Menu/CancelConnect").show()

		var v_ip = get_node("Menu/IP").get_text()

		var v_connection = StreamPeerTCP.new()
		
		var timer = Timer.new()
		timer.set_wait_time(0.25)
		timer.set_one_shot(true)
		self.add_child(timer)

		v_connection.connect(v_ip, port)
		get_node("Menu/Host").set_disabled(true)
		var i = 0
		while true and i < 20 && !connect_cancel:
			if v_connection.get_status() == v_connection.STATUS_CONNECTED:
				break
			else:
				i += 1
				timer.start()
				yield(timer, "timeout")

		var v_peerstream = PacketPeerStream.new()
		v_peerstream.set_stream_peer( v_connection )
		
		if v_connection.get_status() == v_connection.STATUS_CONNECTED:
			get_node("Menu/Host").set_disabled(false)
			var new_scene = load("res://Client.scn").instance()
			new_scene.init_client(v_connection, v_peerstream)
			get_node("Menu").hide()
			add_child(new_scene)
		elif !connect_cancel:
			get_node("Menu/StatusLabel").show()
			get_node("Menu/Host").set_disabled(false)
			get_node("Menu/CancelConnect").hide()
			get_node("Menu/StatusLabel").set_text("Connecting failed.")
		else:
			get_node("Menu/StatusLabel").hide()
			get_node("Menu/Host").set_disabled(false)
			get_node("Menu/CancelConnect").hide()
			connect_cancel = false

func _process(delta):
	if v_server.is_connection_available():
		var client = v_server.take_connection()
		var new_scene = load("res://Server.tscn").instance()
		new_scene.init_server(v_server, client)
		get_node("Menu").hide()
		set_process(false)
		add_child(new_scene)

func stop_connecting():
	connect_cancel = true

func reset_menu():
	get_node("Menu/StatusLabel").hide()
	get_node("Menu/CancelConnect").hide()
	get_node("Menu/Host").set_disabled(false)
	get_node("Menu/Host").set_text("Host")
	get_node("Menu/Connect").set_disabled(false)