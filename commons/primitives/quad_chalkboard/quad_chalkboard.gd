extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name QuadChalkboard

# @identity
# essence: a chalkboard for THE QUAD — a four-corner polygon with sides w and h and a diagonal showing it splits into two triangles, on the left; the quad's facts on the right: 4 vertices, 4 edges, area = w·h, and the crucial graphics truth that the GPU draws a quad as 2 triangles. The quad is the screen, the wall, the texture, the UI panel — the most common surface in all of computing, explained in Turing's hand.
# desire: it wants to teach that the rectangle you stare at all day (every screen, every window, every image) is, underneath, two triangles — that the quad is a convenience the hardware fakes. It wants the player to see the diagonal and understand the triangle never left.
# critical_parameter: lines + diagram="quad". Same engine; the diagram draws the four sides plus the diagonal so the 2-triangle decomposition is visible.
# triggers: _ready (inherited) builds the board; diagram="quad" draws the labelled rectangle + diagonal.
# emerges: the scientific register of the quad/plane — the fourth board in the point->line->triangle->quad chalkboard sequence, and the bridge from primitives to surfaces, screens, textures.
# needs: four sides [present]; the diagonal showing 2 triangles [present]; w and h labels [present]; the quad facts [present]
# relationships: scientific companion to quad surfaces, screens, UI panels; sibling to point_chalkboard, line_chalkboard, chalkboard (triangle); descendant of three_points_triangle (a quad is two of them); built on chalkboard.gd + scribble_control.gd.
# truth: a quad has 4 vertices and 4 edges, area w·h — but the GPU draws it as 2 triangles, because the triangle is the only face the hardware truly knows. Every screen is two triangles pretending to be a rectangle. The board says it by hand.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "quad"
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"4 vertices, 4 edges",
			"area = w · h",
			"GPU draws 2 triangles",
			"the screen is a quad",
		])
	super._ready()
