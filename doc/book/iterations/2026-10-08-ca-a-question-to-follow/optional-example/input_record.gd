extends RefCounted
## One author-made response to the optional composition task.
## Pass the existing presence.gd study explicitly; no prepared scene references.
var initial: Dictionary = {}
var entries: Array[Dictionary] = []
var first_tick := 0
var synchronous := true
var backwards := false

func begin(study: Node3D) -> void:
	initial = study.current.duplicate()
	first_tick = study.ticks
	synchronous = study.synchronous
	backwards = study.backwards
	entries.clear()

func take_step(study: Node3D) -> void:
	if study.ticks >= study.LIMIT:
		return
	assert(study.ticks == first_tick + entries.size(),
		"Begin another record after resetting or advancing outside this recorder.")
	assert(study.synchronous == synchronous and study.backwards == backwards,
		"Begin another record after changing the update settings.")
	entries.append({
		"at": study.input_position(),
		"present": study.point.held() and not study.chain
	})
	study.step()

func replay(study: Node3D) -> Array[Dictionary]:
	study.current = initial.duplicate()
	study.ticks = first_tick
	study.synchronous = synchronous
	study.backwards = backwards
	var history: Array[Dictionary] = []
	for entry in entries:
		study.current = study.evolve(study.current, entry.at, entry.present)
		study.ticks += 1
		history.append(study.current.duplicate())
	study.redraw()
	return history
