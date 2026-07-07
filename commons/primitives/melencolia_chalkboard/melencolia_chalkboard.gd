extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name MelencoliaChalkboard

# @identity
# essence: a chalkboard for MELENCOLIA — Durer's 1514 magic square, every line summing 34, the date hidden in its cells; finitude made exact, and still melancholy.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="melencolia". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="melencolia" draws the figure.
# emerges: one board in the primitives chalk gallery — Melancholy of Finitude.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: Durer's 4x4 magic square (1514): every row, column and diagonal sums 34, the date sits in the bottom-middle cells; the finite can be exact and complete and still grieve its limit.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "melencolia"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["Durer, 1514", "every line = 34", "finite, exact, complete", "and still: melancholy"])
	super._ready()
