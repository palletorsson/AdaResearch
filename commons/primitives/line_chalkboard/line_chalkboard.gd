extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name LineChalkboard

# @identity
# essence: a chalkboard for THE LINE — two endpoints A and B joined by a chalk segment with its midpoint M on the left, the line's facts on the right: a line is the shortest path between two points, length = |B − A|, the midpoint M = (A+B)/2, one dimension. Where the line gems (two_points_line, horizon_line, redline) make the line CONNECT, REACH and DIVIDE, this board states what it IS.
# desire: it wants to teach the line as pure relation — that two points imply a unique straight path, and that this path is measurable, halvable, directional. It wants the player to read the segment and feel the first relation in all of geometry.
# critical_parameter: lines + diagram="line". Same engine, different content. The endpoints are dots; the midpoint a small perpendicular tick.
# triggers: _ready (inherited) builds the board; diagram="line" draws A—B—M.
# emerges: the scientific register of the Line salon, the second board in the point->line->triangle->quad sequence.
# needs: two endpoints [present]; the joining segment [present]; the midpoint tick [present]; the line facts [present]
# relationships: scientific companion to the line gems; sibling to point_chalkboard, quad_chalkboard, chalkboard (triangle); built on chalkboard.gd + scribble_control.gd.
# truth: a line is the shortest path between two points — one-dimensional, the first relation, measurable as |B−A|, halvable at (A+B)/2. Two points make it; nothing fewer can. The board states it by hand.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "line"
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"shortest path A to B",
			"length = |B − A|",
			"M = (A + B) / 2",
			"1 dimension",
		])
	super._ready()
