extends Node

const port = 3560

var connection # your connection (StreamPeerTCP) object
var peerstream # your data transfer (PacketPeerStream) object
var connected = false

# Bools for registering events
var cardPlayed = false
var takePressed = false
var carryPressed = false
#--------------------------------------------------

var timer
var pile
var hand
var takeButton
var carryButton
var leadIndicatorServer
var leadIndicatorClient
var player
var turnStatus

var is_server_leading
var did_server_win
var game_over = false
var no_more_cards_in_deck = false

func update_lead_indicator():
	if is_server_leading:
		leadIndicatorServer.show()
		leadIndicatorClient.hide()
	else:
		leadIndicatorServer.hide()
		leadIndicatorClient.show()

func _ready():
	timer = get_node("Timer")
	pile = get_node("DummyPile")
	takeButton = get_node("Take")
	carryButton = get_node("Carry")
	hand = get_node("DummyHand")
	leadIndicatorClient = get_node("LeadIndicator")
	leadIndicatorServer = get_node("LeadIndicator1")
	player = get_node("SamplePlayer")
	turnStatus = get_node("TurnStatus")
	carryButton.connect("pressed", self, "carry_button_pressed")
	takeButton.connect("pressed", self, "take_button_pressed")
	update_lead_indicator()

	while true:
		connection_check()
		if peerstream.get_available_packet_count() > 0:
			var packet = peerstream.get_var()
			if(packet[0] == "start"):
				for i in range(0,4):
					var v = load("res://Scenes/Card.tscn").instance()
					v.init_card(packet[1+i*2], packet[2+i*2], true)
					hand.add_to_hand(v)
				break;
		else:
			timer.start()
			yield(timer, "timeout")

	game_loop()


func init_client(v_connection, v_peerstream, server_win = true):
	# Initializes client and starts process
	# USE THIS ONLY AFTER CONNECTION IS ESTABLISHED
	connection = v_connection
	peerstream = v_peerstream
	connected = true
	did_server_win = server_win
	is_server_leading = server_win
	
func game_loop():
	while !(no_more_cards_in_deck and hand.is_empty() and pile.is_empty()) :
		var packet
		if did_server_win:
			# SERVER PLAYS
			turnStatus.set_text("Waiting for opponent...")
			while true:
				connection_check()
				if peerstream.get_available_packet_count() > 0:
					packet = peerstream.get_var()
					if packet[0] == "server":
						break;
				else:
					timer.start()
					yield(timer, "timeout")
			if packet[0] == "server":
				if packet[1] == "throw":
					get_node("DummyOpponentHand").throw_one()
					var v = load("res://Scenes/Card.tscn").instance()
					v.init_card(packet[2], packet[3], true)
					if v.rank == pile.get_lead_card() or v.rank == 7:
						is_server_leading = true
					update_lead_indicator()
					pile.throw_to_pile(v)
				elif packet[1] == "carry_pressed" or packet[1] == "take_pressed":
					player.play("cardShove3", true)
					pile.clean()
					if packet[2] == 0:
						no_more_cards_in_deck = true
					for i in range(0, packet[2]):
						var v = load("res://Scenes/Card.tscn").instance()
						v.init_card(packet[3+i*2], packet[4+i*2], true)
						hand.add_to_hand(v)
					get_node("DummyOpponentHand").add_n_cards(packet[2])
					if packet[1] == "take_pressed":
						if (no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
							break
						while true:
							connection_check()
							if peerstream.get_available_packet_count() > 0:
								packet = peerstream.get_var()
								if packet[0] == "server":
									break;
							else:
								timer.start()
								yield(timer, "timeout")
						if packet[0] == "server":
							if packet[1] == "throw":
								var v = load("res://Scenes/Card.tscn").instance()
								v.init_card(packet[2], packet[3], true)
								pile.throw_to_pile(v)
								get_node("DummyOpponentHand").throw_one()
		did_server_win = true
		if (no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
			break
		#---------------------------------------------------
		# CLIENT PLAYS
		turnStatus.set_text("Your turn.")
		if pile.is_empty(): # if pile is empty throw a card
			hand.connect("card_played", self, "play_card")
			while true:
				connection_check()
				if cardPlayed:
					break
				else:
					timer.start()
					yield(timer, "timeout")
			cardPlayed = false
			hand.disconnect("card_played", self, "play_card")
		else: # if not
			if pile.can_carry(): # if number of cards on pile is even
				if !is_server_leading: # if me(client) is leading
					# Take cards from pile or continue by playing another card
					takeButton.set_disabled(false)
					hand.connect("card_played", self, "play_card")
					while true:
						connection_check()
						if cardPlayed or takePressed:
							break
						else:
							timer.start()
							yield(timer, "timeout")
					takeButton.set_disabled(true)
					cardPlayed = false
					#---------------------------------
					# If we took the cards from the pile, immidiately begin the next round
					if (no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
						break
					if takePressed:
						player.play("cardShove3", true)
						pile.clean() # put cards from pile in your graveyard
						if (no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
							break
						while true:
							connection_check()
							if cardPlayed:
								break
							else:
								timer.start()
								yield(timer, "timeout")
						cardPlayed = false
					takePressed = false
					hand.disconnect("card_played", self, "play_card")
					#--------------------------------------------
				else: # if server is leading, tell him to take the cards or continue
					carryButton.set_disabled(false)
					hand.connect("card_played", self, "play_card")
					while true:
						connection_check()
						if cardPlayed or carryPressed:
							break
						else:
							timer.start()
							yield(timer, "timeout")
					if carryPressed: # if we clicked give
						player.play("cardShove3", true)
						pile.clean() # Clean the pile
					cardPlayed = false
					carryPressed = false
					hand.disconnect("card_played", self, "play_card")
					carryButton.set_disabled(true)
			else: # If the number is uneven, you have to throw a card
				hand.connect("card_played", self, "play_card")
				while true:
					connection_check()
					if cardPlayed:
						break;
					else:
						timer.start()
						yield(timer, "timeout")
				cardPlayed = false
				hand.disconnect("card_played", self, "play_card")
	# Game over, waiting for results
	var packet
	while true:
		connection_check()
		if peerstream.get_available_packet_count() > 0:
			packet = peerstream.get_var()
			if packet[0] == "result":
				break;
		else:
			timer.start()
			yield(timer, "timeout")
	var new_scene = load("res://Result.tscn").instance()
	new_scene.init_results(packet[1], packet[2], is_server_leading, false, null, connection)
	get_tree().get_root().get_node("Scene").add_child(new_scene)
	queue_free()
	
func carry_button_pressed():
	peerstream.put_var(["carry_pressed"])
	var packet
	player.play("cardShove3", true)
	pile.clean()
	if !(no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
		while true:
			connection_check()
			if peerstream.get_available_packet_count() > 0:
				packet = peerstream.get_var()
				if packet[0] == "confirm":
					break;
			else:
				timer.start()
				yield(timer, "timeout")
		if packet[1] == 0:
			no_more_cards_in_deck = true
		for i in range(0, packet[1]):
			var v = load("res://Scenes/Card.tscn").instance()
			v.init_card(packet[2+i*2], packet[3+i*2], true)
			hand.add_to_hand(v)
		get_node("DummyOpponentHand").add_n_cards(packet[1])
	carryButton.set_disabled(true)
	carryPressed = true

func take_button_pressed():
	peerstream.put_var(["take_pressed"])
	var packet
	player.play("cardShove3", true)
	pile.clean()
	if !(no_more_cards_in_deck and hand.is_empty() and pile.is_empty()):
		while true:
			connection_check()
			if peerstream.get_available_packet_count() > 0:
				packet = peerstream.get_var()
				if packet[0] == "confirm":
					break;
			else:
				timer.start()
				yield(timer, "timeout")
		if packet[1] == 0:
			no_more_cards_in_deck = true
		for i in range(0, packet[1]):
			var v = load("res://Scenes/Card.tscn").instance()
			v.init_card(packet[2+i*2], packet[3+i*2], true)
			hand.add_to_hand(v)
		get_node("DummyOpponentHand").add_n_cards(packet[1])
	takeButton.set_disabled(true)
	takePressed = true

func play_card(card):
	if pile.is_empty() or (pile.can_carry() and (card.rank == pile.get_lead_card()  or card.rank == 7)) or !pile.can_carry():
		peerstream.put_var(["throw", card.rank, card.suit])
		if card.rank == pile.get_lead_card() or card.rank == 7:
			is_server_leading = false
			update_lead_indicator()
		hand.remove_card(card)
		pile.throw_to_pile(card)
		cardPlayed = true

func connection_check():
	if connection.is_connected() == false:
		get_tree().get_root().get_node("Scene").reset_menu()
		get_tree().get_root().get_node("Scene/Menu").get_node("StatusLabel").set_text("Connection lost.")
		get_tree().get_root().get_node("Scene/Menu").get_node("StatusLabel").show()
		get_tree().get_root().get_node("Scene/Menu").show()
		queue_free()