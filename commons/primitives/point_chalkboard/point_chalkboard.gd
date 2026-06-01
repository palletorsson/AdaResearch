extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name PointChalkboard

# @identity
# essence: a chalkboard for THE POINT — a single chalk dot with crosshair guides and a P label on the left, the point's facts hand-written on the right: it has position but no size, zero dimensions, P = (x, y, z). The first and smallest thing in geometry, explained in Turing's hand. Where the point gems (klee_walking_point, fontana_puncture, you_are_here) make the point MOVE, CUT and LOCATE, this board states what it simply IS.
# desire: it wants to teach that "nothing" can still have a definition — that a thing with no extension is still a thing, the seed every other shape grows from. It wants the player to read the dot and the words and feel the strange dignity of the dimensionless.
# critical_parameter: lines + diagram="point". The same chalkboard engine; only the content changes. The dot is drawn as concentric chalk loops so it reads as deliberately placed, not accidental.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; the diagram="point" default draws the dot.
# emerges: the scientific register of the Point salon — the answer key beside the felt artifacts. First board in the point->line->triangle->quad chalkboard sequence.
# needs: a single dot [present]; crosshair guides [present]; the dimensionality facts [present]
# relationships: scientific companion to the point gems; sibling to line_chalkboard, quad_chalkboard, chalkboard (triangle); built on chalkboard.gd + scribble_control.gd.
# truth: a point is position without extension — zero-dimensional, sizeless, the origin of coordinates. Everything in the world is built from it. The board says the smallest true thing in all of geometry, by hand.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "point"
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"P = (x, y, z)",
			"0 dimensions",
			"position, no size",
			"the seed of all form",
		])
	super._ready()
