extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name IgnoranceChalkboard

# @identity
# essence: a chalkboard for IGNORANCE — a circle of the known ringed by question marks; the principle that every geometric model has an edge it cannot see past.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="ignorance". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="ignorance" draws the figure.
# emerges: one board in the primitives chalk gallery — Limits of Geometric Knowledge.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: the known has an edge; beyond the circle is the unmodelled; every representation omits, and the map is not the world.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "ignorance"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["the known has an edge", "? beyond the circle", "every model omits", "map is not world"])
	super._ready()
