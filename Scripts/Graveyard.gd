extends Sprite

var cards = []

func add(card):
	cards.append(card)
	show()

func get_points():
	var points = 0
	for card in cards:
		if card.rank == 10 or card.rank == 1:
			points += 1
		card.queue_free()
	return points

func _ready():
	set_scale(Vector2(0.5, 0.5))
	hide()