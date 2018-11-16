extends Position2D

var LIMIT = 8
var cards_on_pile = []
var leading_card

func throw_to_pile(cardX):
	cardX.set_face_up(true)
	if cards_on_pile.size() == 0:
		leading_card = cardX.rank
	cards_on_pile.append(cardX)
	add_child(cardX)
	cardX.set_pos(cardX.get_pos()+Vector2(-cardX.get_pos().x, 0))
	update()

func clean():
	while cards_on_pile.size() > 0:
		remove_child(cards_on_pile.back())
		cards_on_pile.pop_back()

func is_empty():
	return cards_on_pile.size() == 0

func update():
	if LIMIT == 0 or cards_on_pile.size() <= LIMIT:
		for i in range(0, cards_on_pile.size()):
			if i != 0:
				cards_on_pile[i].set_pos(cards_on_pile[0].get_pos()+Vector2(i*20,0))
		if cards_on_pile.size() > 1:
			for c in cards_on_pile:
				c.set_pos(c.get_pos()+Vector2(-10, 0))

func get_lead_card():
	return leading_card

func can_carry():
	return cards_on_pile.size()%2 == 0

func _ready():
	pass