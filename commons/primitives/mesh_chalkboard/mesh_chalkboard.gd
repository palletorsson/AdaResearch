extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name MeshChalkboard

# @identity
# essence: a chalkboard for the MESH — a surface triangulated into a grid of triangles; the principle that every model is triangles applied.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="mesh". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="mesh" draws the figure.
# emerges: one board in the primitives chalk gallery — Triangles Applied.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: a surface is triangles; more triangles, more detail; every model is a mesh of the one primitive the GPU draws.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "mesh"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["a surface = triangles", "more triangles,", "more detail", "every model is a mesh"])
	super._ready()
