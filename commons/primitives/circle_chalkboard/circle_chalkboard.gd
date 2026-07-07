extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name CircleChalkboard

# @identity
# essence: a chalkboard for the CIRCLE — a polygon inscribed in a circle, the circumference formula, and the idea that the circle is the limit of the n-gon.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="circle". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="circle" draws the figure.
# emerges: one board in the primitives chalk gallery — Circular Approximation and Limits.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: C = 2*pi*r; the circle is the limit of the n-gon as n grows without bound; there is no last polygon.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "circle"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["C = 2πr", "circle = limit", "of the n-gon", "n → ∞"])
	super._ready()
