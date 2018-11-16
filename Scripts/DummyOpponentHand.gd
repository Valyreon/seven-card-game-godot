extends Position2D

var number_of_cards = 4
var children = []

func set_cards(cards):
	number_of_cards = cards
	update()

func add_n_cards(n):
	number_of_cards += n
	update()

func throw_one():
	number_of_cards -= 1
	update()

func update():
	var i = 0
	for child in get_children():
		child.hide()
		if i < number_of_cards:
			child.show()
			i += 1
		
	var offset_to_left = (number_of_cards - 1) * 36
	var i = 0
	for x in get_children():
		x.set_pos(Vector2(i*72, 0))
		i+=1
	for c in get_children():
		c.set_pos(c.get_pos() + Vector2(-offset_to_left, 0))

func _ready():
	for i in range(0,4):
		add_child( Sprite.new() )
	for i in get_children():
		i.set_texture(load("res://PNG/Cards/53.png"))
		i.set_scale(Vector2(0.5,0.5))
		children.append(i)
	update()