extends "res://commons/artifacts/koch_sierpinski_lesson/koch_sierpinski_lesson.gd"
## Reuse the hall's compact physical buttons and transparent reading panel.
## This child is opt-in; the recursive object preserves it when rebuilding.

func _ready() -> void:
	source = get_parent()
	# The map scales the specimen, while the controls remain metre-sized.
	scale = Vector3.ONE / source.scale
	# Both recipes share the same lowest leaf. Stand the desk on that plane.
	var lowest_center: float = -source.size * (pow(2, source.depth) - 1.0) / 4.0
	var half_leaf: float = source.size * float(source.PACKING_FILL[source.packing]) / 2.0
	position.y = lowest_center - half_leaf
	_build_compact_console(["COMPARE", "RULE", "RESET"], "04 / WHAT DID ONE CALL ADD?")
	refresh()

func act(id: String) -> void:
	match id:
		"COMPARE":
			show_rule = false
			source.set_extra_crown(not source.extra_crown)
		"RULE": show_rule = not show_rule
		"RESET":
			show_rule = false
			source.set_extra_crown(true)
	refresh()

func refresh() -> void:
	if show_rule:
		readout.text = "%d calls per branch | depth %d\n%d leaf instances | same cube size" % [6 if source.extra_crown else 5, source.depth, source.leaf_count]
	else:
		readout.text = "A / inherited construction\nCOMPARE changes one recursive call" if source.extra_crown else "B / extra upper call held back\nWalk around the changed edge"
