extends RefCounted
## Discrete construction events; rendering and clocks never draw random numbers.
const Model = preload("res://commons/artifacts/scaffold_workstation/model.gd")
const DIRECTIONS = [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]
const VERSION = 1
const LIMIT = 24
var model = Model.new()
var rng := RandomNumberGenerator.new()
var seed_value := 435
var endpoint := Vector3.ZERO
var events: Array = []

func _init(value: int = 435) -> void:
	reset(value)

func reset(value: int) -> void:
	seed_value = value
	rng.seed = value
	endpoint = Vector3.ZERO
	events.clear()
	model = Model.new()

func step() -> Dictionary:
	if events.size() >= LIMIT: return {}
	var before := str(rng.state)
	var direction := rng.randi_range(0, 3)
	var proposed: Vector3 = endpoint + DIRECTIONS[direction] * 0.5
	var event := {"step": events.size()+1, "from": Model.arr(endpoint), "proposal": Model.arr(proposed), "direction": direction, "rng_before": before, "rng_after": str(rng.state), "result": "boundary", "added": []}
	if Model.inside(proposed):
		# Commit only a legal complete edit. Model.add canonicalizes rod direction
		# through its candidate list, including walks towards negative axes.
		var trial = Model.new()
		trial.restore(model.records)
		var ok := true
		if not trial.points().has(Model.key(proposed)):
			ok = trial.add({"kind":"point", "at":Model.arr(proposed)}, 1)
		if ok and not trial.edge(endpoint, proposed):
			ok = false
			for candidate in trial.candidates("rod_short", 1):
				var a: Vector3 = Model.vec(candidate.at)
				var b: Vector3 = Model.vec(candidate.end)
				if (a == endpoint and b == proposed) or (b == endpoint and a == proposed):
					ok = trial.add(candidate, 1)
					break
		if ok:
			for r in trial.records.slice(model.records.size()): event.added.append(member_id(r))
			event.result = "added" if not event.added.is_empty() else "revisit"
			model = trial
			endpoint = proposed
		else: event.result = "illegal"
	event["endpoint"] = Model.arr(endpoint)
	events.append(event)
	return event

static func member_id(r: Dictionary) -> String:
	return str(r.kind)+":"+Model.key(Model.vec(r.at))+(":"+Model.key(Model.vec(r.end)) if r.has("end") else "")

func snapshot() -> Dictionary:
	return {"schema":"ada.constructive-walk", "version":VERSION, "engine":Engine.get_version_info().string, "grammar_hash":FileAccess.get_sha256("res://commons/artifacts/scaffold_workstation/model.gd"), "seed":str(seed_value), "rng_state":str(rng.state), "boundary":"reject-and-consume", "step_length":0.5, "limit":LIMIT, "endpoint":Model.arr(endpoint), "records":model.records.duplicate(true), "events":events.duplicate(true)}

func restore(data: Dictionary) -> bool:
	# Validate by replay into a temporary record; malformed files never mutate us.
	if data.get("schema") != "ada.constructive-walk" or data.get("version") != VERSION: return false
	if data.get("grammar_hash") != FileAccess.get_sha256("res://commons/artifacts/scaffold_workstation/model.gd"): return false
	if not data.get("events") is Array or data.events.size() > LIMIT: return false
	if not str(data.get("seed", "")).is_valid_int(): return false
	var trial = get_script().new(int(data.seed))
	for i in data.events.size(): trial.step()
	# JSON normalizes integers to floats; comparing serialized parsed values
	# avoids treating a valid on-disk numeric address as a different address.
	var expected: Dictionary = JSON.parse_string(JSON.stringify(trial.snapshot()))
	var actual: Dictionary = JSON.parse_string(JSON.stringify(data))
	if expected != actual: return false
	model = trial.model; rng = trial.rng; seed_value = trial.seed_value
	endpoint = trial.endpoint; events = trial.events
	return true
