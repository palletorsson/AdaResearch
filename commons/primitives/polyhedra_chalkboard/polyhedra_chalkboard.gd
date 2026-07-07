extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name PolyhedraChalkboard

# @identity
# essence: a chalkboard for POLYHEDRA — a tetrahedron wireframe beside Euler's formula, the first solid and the law that binds vertices, edges and faces.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="polyhedra". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="polyhedra" draws the figure.
# emerges: one board in the primitives chalk gallery — Trihedra and First Solids.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: V - E + F = 2 for any convex polyhedron (Euler); the tetrahedron is the first solid: 4 vertices, 6 edges, 4 faces.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "polyhedra"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["V - E + F = 2", "Euler's formula", "tetra: 4, 6, 4", "the first solid"])
	super._ready()
