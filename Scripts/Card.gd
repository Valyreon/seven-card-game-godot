extends Area2D

const R_JOKER = 0
const R_ACE = 1
const R_TWO = 2
const R_THREE = 3
const R_FOUR = 4
const R_FIVE = 5
const R_SIX = 6
const R_SEVEN = 7
const R_EIGHT = 8
const R_NINE = 9
const R_TEN = 10
const R_JACK = 11
const R_QUEEN = 12
const R_KING = 13

const S_CLUBS = 0
const S_DIAMONDS = 1
const S_HEARTS = 2
const S_SPADES = 3

export(bool) var joker = true;
export(int, 1, 13) var rank = R_TWO
export(int, 0, 3) var suit = S_CLUBS
export(bool) var face_up = true

signal im_clicked

func is_face_up():
	return face_up

func set_face_up(face_up):
	self.face_up = face_up
	apply()

func set_rank(rank):
	self.rank = rank
	if rank == 0:
		joker = true
	else:
		joker = false
	apply()


func set_suit(suit):
	self.suit = suit
	apply()
	
func init_card(rank, suit, face_up):
	self.rank = rank
	self.suit = suit
	self.face_up = face_up
	if rank == 0:
		joker = true
	else:
		joker = false
	apply()
	
func flip():
	face_up = !face_up
	apply()
	
func equals(CardX):
	if CardX.rank == rank and CardX.suit == suit:
		return true
	else:
		return false

func apply():
	if is_face_up():
		if(joker == true):
			while has_node("CardSprite")==false:
				pass
			get_node("CardSprite").set_texture(load("res://PNG/Cards/0.png"))
		else:
			var idx = suit*13 + rank
			while has_node("CardSprite")==false:
				pass
			get_node("CardSprite").set_texture(load(str("res://PNG/Cards/", idx, ".png")))
	else:
		while has_node("CardSprite")==false:
				pass
		get_node("CardSprite").set_texture(load("res://PNG/Cards/53.png"))

func _ready():
	get_node("CardSprite").set_scale(Vector2(0.5, 0.5))
	apply()
	pass

func _input_event(viewport, event, shape_idx):
	if event.type == InputEvent.MOUSE_BUTTON \
	and event.button_index == BUTTON_LEFT \
	and event.pressed:
		emit_signal("im_clicked", self)