extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name TraceChalkboard

# @identity
# essence: a chalkboard for the TRACE — a point moving through time leaves residue; duration becomes a drawn line of fading marks.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="trace". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="trace" draws the figure.
# emerges: one board in the primitives chalk gallery — Duration and Residue.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: a point in time leaves a trace; duration is residue; the past is the line the present drew.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "trace"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["a point in time", "leaves a trace", "duration = residue", "the past is drawn"])
	super._ready()
