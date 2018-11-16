extends Sprite

var cards_in_deck = []
var seven_deck = [1,7,8,9,10,11,12,13]

func create_full_deck():
	for j in seven_deck:
		for i in range(0, 4):
			var v = load("res://Scenes/Card.tscn").instance()
			v.init_card(j,i,false)
			cards_in_deck.append(v)

func cards_remaining():
	return cards_in_deck.size()

func shuffle():
	randomize()
	var temp = []
	while cards_in_deck.size() > 0:
		var i = randi()%cards_in_deck.size()
		temp.push_back( cards_in_deck[i] )
		cards_in_deck.remove(i)
	cards_in_deck = temp

func is_empty():
	if cards_in_deck.size() == 0:
		return true
	return false

func update():
	if cards_in_deck.size() == 0:
		hide()
	else:
		show()

func draw():
	if cards_in_deck.size() > 0:
		var c = cards_in_deck.back()
		cards_in_deck.pop_back()
		update()
		return c
	else:
		update()

func _ready():
	create_full_deck()
	shuffle()
	#set_texture(load("res://PNG/Cards/53.png"))
	set_scale(Vector2(0.5, 0.5))