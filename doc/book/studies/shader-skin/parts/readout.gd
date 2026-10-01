extends Label3D
## Supplied here: the words over the body. It reads the node `Skin` beside it
## and says which exponent the rim has now, and which keys there are. It makes
## nothing and changes nothing. If Skin has no `rim_power` yet, as in the first
## steps of the lesson, it shows the keys only.

const Look := preload("res://supplied/look.gd")

func _ready() -> void:
	pixel_size = 0.004
	font_size = 30
	outline_size = 12
	modulate = Look.INK
	outline_modulate = Look.SHADE

func _process(_delta: float) -> void:
	var skin := get_node_or_null("../Skin")
	var power: Variant = skin.get("rim_power") if skin != null else null
	var first := "" if power == null else "rim exponent %s    Space: the next of 0.5, 1, 3, 8\n" % power
	text = first + "WASD or arrows walk    C your eyes or the fixed camera\nhold V or the right mouse button and move the mouse: look"
