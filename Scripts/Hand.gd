extends Position2D

var limit = 0
var cards_in_hand = []
signal card_played

func add_to_hand(xCard):
	xCard.connect("im_clicked",self, "card_in_hand_clicked")
	cards_in_hand.append(xCard)
	add_child(xCard)
	update()

func is_empty():
	return cards_in_hand.size() == 0
	
func remove_card(tok):
	var cont = true
	for i in range(0, cards_in_hand.size()):
		if cont and cards_in_hand[i] == tok:
			remove_child(cards_in_hand[i])
			cards_in_hand.remove(i)
			cont = false
	tok.disconnect("im_clicked", self, "card_in_hand_clicked")
	update()

func card_in_hand_clicked(card):
	emit_signal("card_played", card)

func update():
	var offset_to_left = (cards_in_hand.size() - 1) * 36
	for i in range(0, cards_in_hand.size()):
		cards_in_hand[i].set_pos(Vector2(i*72, 0))
	for c in cards_in_hand:
		c.set_pos(c.get_pos() + Vector2(-offset_to_left, 0))

func _ready():
	pass

func turn_over():
	for card in cards_in_hand:
		card.set_face_up(true)

func is_in_hand(r, s):
	for card in cards_in_hand:
		if card.rank == r and card.suit == s:
			return card
	return null