extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name CubeChalkboard

# @identity
# essence: a chalkboard for the CUBE — a cube wireframe with its vertex/edge/face count, assembled from points, edges and quad faces.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="cube". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="cube" draws the figure.
# emerges: one board in the primitives chalk gallery — Cube Assembly from Primitives.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: a cube is 8 vertices, 12 edges, 6 faces; its 6 quads are 12 triangles; everything built from points.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "cube"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["8 vertices", "12 edges, 6 faces", "6 quads = 12 tris", "built from points"])
	super._ready()
