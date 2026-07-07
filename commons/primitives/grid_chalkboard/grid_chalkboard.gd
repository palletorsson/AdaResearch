extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name GridChalkboard

# @identity
# essence: a chalkboard for the GRID — a stair-step path against a straight intent, showing how a grid snaps continuous motion into discrete steps.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="grid". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="grid" draws the figure.
# emerges: one board in the primitives chalk gallery — Grid Quantizes Movement.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: the grid quantizes movement: steps, not slopes; intent is continuous, the path is discrete.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "grid"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["the grid snaps motion", "steps, not slopes", "movement is discrete", "intent vs path"])
	super._ready()
