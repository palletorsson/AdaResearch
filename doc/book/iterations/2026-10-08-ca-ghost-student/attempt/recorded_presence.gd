extends "reconstructed/CA_ExpandingSpace/presence.gd"
## Ghost-student optional response: Trace returns as ordered inputs, including pauses.
var inputs: Array[Dictionary] = []
var expected_fields: Array[Dictionary] = []
var beginning: Dictionary = {}
var start_tick := 0
var saved_sync := true
var saved_reverse := false

func begin_record() -> void:
	beginning = current.duplicate()
	start_tick = ticks
	saved_sync = synchronous
	saved_reverse = backwards
	inputs.clear()
	expected_fields.clear()

func step() -> void:
	if ticks >= LIMIT:
		return
	assert(not beginning.is_empty(), "Call begin_record before stepping the experiment.")
	assert(synchronous == saved_sync and backwards == saved_reverse)
	assert(ticks == start_tick + inputs.size())
	inputs.append({"position": input_position(), "present": point.held() and not chain})
	super.step()
	expected_fields.append(current.duplicate())

func play_record(reverse_inputs: bool = false) -> Array[Dictionary]:
	current = beginning.duplicate()
	ticks = start_tick
	synchronous = saved_sync
	backwards = saved_reverse
	var ordered := inputs.duplicate()
	if reverse_inputs:
		ordered.reverse()
	var fields: Array[Dictionary] = []
	for input in ordered:
		current = evolve(current, input.position, input.present)
		ticks += 1
		fields.append(current.duplicate())
	redraw()
	return fields
