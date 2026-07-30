extends Node3D

# @identity
# essence: [100m, 10m, 1m, 10cm, 1mm] — a logarithmic ladder of reference lengths made tangible
# desire: learner viscerally understands the orders of magnitude separating human-scale from micro and macro
# critical_parameter: the 1m line — the human-body reference; all others derive meaning relative to it
# triggers: nothing — static configuration; the experience is spatial proximity and comparison
# emerges: the body as unit — standing next to 1m makes all other lengths relative to your own height
# needs: [missing VR controls — static reference display]
# relationships: sibling to perspective_lines; both configure existing line nodes for a specific lesson
# truth: every measurement is relative — scale only makes sense from a chosen reference

# Script to ensure scale lines are positioned correctly at different measurements
#
# DNA (stage 2, promoted by hand 2026-07-29). Two things were hard-coded in one
# literal array and are really the argument this object makes:
#
#   rungs        WHICH magnitudes hang on the ladder. The shipped set skips a
#                decade (10 cm straight to 1 mm) — that is a claim, not an
#                oversight, and it is only visible as a claim once the unbroken
#                decade ladder exists beside it.
#   arrangement  HOW the rungs sit in space. Stacked at fixed heights the ladder
#                says "these are different magnitudes"; placed by log10 it says
#                "equal steps in space are equal factors of ten" and the skipped
#                decade opens as an empty rung; anchored at a shared zero it stops
#                being a ladder and becomes a ruler — every length measured from
#                one origin instead of compared span to span.
#
# Defaults rungs="world", arrangement="ladder" reproduce the shipped numbers
# exactly (see SLOT_Y / RUNG_SETS["world"]).

## Slots — the line nodes this scene actually carries, longest first.
## Names are historical; the visible text comes from RUNG_LABELS.
const SLOTS := ["Line_100m", "Line_10m", "Line_1m", "Line_10cm", "Line_1mm"]

## Per-slot styling — unchanged by either axis (a rung's weight is its rank,
## not its magnitude).
const SLOT_THICKNESS := [0.02, 0.015, 0.01, 0.005, 0.003]
const SLOT_COLOR := [
	Color(1.0, 0.2, 0.4, 1.0),
	Color(1.0, 0.5, 0.2, 1.0),
	Color(1.0, 0.8, 0.2, 1.0),
	Color(0.4, 1.0, 0.4, 1.0),
	Color(0.6, 0.4, 1.0, 1.0),
]

## The shipped stacking heights — larger at top, smaller at bottom.
const SLOT_Y := [4.0, 2.0, 1.0, 0.5, 0.1]

## Which magnitudes are on show.
const RUNG_SETS := {
	"world": [100.0, 10.0, 1.0, 0.1, 0.001],
	"decade": [100.0, 10.0, 1.0, 0.1, 0.01],
	"body": [10.0, 2.0, 1.0, 0.5, 0.1],
}
const RUNG_LABELS := {
	"world": ["100 m", "10 m", "1 m", "10 cm", "1 mm"],
	"decade": ["100 m", "10 m", "1 m", "10 cm", "1 cm"],
	"body": ["10 m", "2 m", "1 m", "50 cm", "10 cm"],
}

## DNA axis — which ladder of magnitudes is on show.
@export_enum("world", "decade", "body") var rungs: String = "world"

## DNA axis — how the rungs are laid out in space.
@export_enum("ladder", "log", "ruler") var arrangement: String = "ladder"

var _built: bool = false


func _ready() -> void:
	setup_scale_lines()
	_built = true


func setup_scale_lines() -> void:
	var lengths: Array = RUNG_SETS.get(rungs, RUNG_SETS["world"])
	var labels: Array = RUNG_LABELS.get(rungs, RUNG_LABELS["world"])

	for i in range(SLOTS.size()):
		var slot_name: String = SLOTS[i]
		var distance: float = float(lengths[i])

		var line_node = get_node_or_null(slot_name + "/lineContainer")
		if line_node:
			var start_x: float = 0.0
			var end_x: float = distance
			if arrangement != "ruler":
				# Shipped reading: the span is centred on the object's axis.
				start_x = -distance / 2.0
				end_x = distance / 2.0
			line_node.set_positions(Vector3(start_x, 0, 0), Vector3(end_x, 0, 0))
			line_node.set_line_properties(SLOT_THICKNESS[i], SLOT_COLOR[i])

		# Position the parent line node at the correct Y position
		var parent_line = get_node_or_null(slot_name)
		if parent_line:
			parent_line.position.y = _rung_height(i, distance)
			var label_node = parent_line.get_node_or_null("Label")
			if label_node:
				label_node.text = str(labels[i])


## Where rung i hangs. "ladder" is the shipped fixed staircase; "log" places the
## rung by its own order of magnitude, so a skipped decade shows up as a gap.
func _rung_height(index: int, distance: float) -> float:
	if arrangement == "log":
		var safe: float = maxf(distance, 0.000001)
		return log(safe) / log(10.0) + 3.0
	return float(SLOT_Y[index])


func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("rungs"):
		var want_rungs: String = str(config_data["rungs"])
		if RUNG_SETS.has(want_rungs) and want_rungs != rungs:
			rungs = want_rungs
			changed = true

	if config_data.has("arrangement"):
		var want_arrangement: String = str(config_data["arrangement"])
		if want_arrangement in ["ladder", "log", "ruler"] and want_arrangement != arrangement:
			arrangement = want_arrangement
			changed = true

	# Only rebuild when a value actually moved AND _ready has built once —
	# an unguarded rebuild here breaks every shipped placement.
	if changed and _built:
		setup_scale_lines()
