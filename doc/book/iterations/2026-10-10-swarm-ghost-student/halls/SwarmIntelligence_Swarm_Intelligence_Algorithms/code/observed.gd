extends "res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd"
## Observe the supplied model. Its movement, feeding, birth and care rules remain.
signal event_record(event: Dictionary)
var recording := false
var origin_kind := "supplied"
var tick := 0
var serial := 0
var arrivals: Array = []

func _ready() -> void:
	super._ready()
	set_process(false)
	hide()
	recording = true

func emit_record(kind: String, species: String, amount: int, at: Vector3, body_id: int = 0) -> void:
	if not recording: return
	serial += 1
	event_record.emit({"serial":serial,"tick":tick,"kind":kind,"species":species,
		"amount":amount,"at":at,"body_id":body_id})

func spawn_prey(pos: Vector3, values: Dictionary = {}) -> EcoPrey:
	var body = super.spawn_prey(pos,values)
	if recording: arrivals.append(body)
	body.set_meta("arrival",origin_kind if recording else "initial")
	emit_record(origin_kind,"prey",1,pos,body.get_instance_id())
	return body

func spawn_predator(pos: Vector3, values: Dictionary = {}) -> EcoPredator:
	var body = super.spawn_predator(pos,values)
	if recording: arrivals.append(body)
	body.set_meta("arrival",origin_kind if recording else "initial")
	emit_record(origin_kind,"predator",1,pos,body.get_instance_id())
	return body

func check_for_mate(creature, is_predator: bool = false) -> void:
	var previous := origin_kind
	origin_kind = "birth"
	super.check_for_mate(creature,is_predator)
	origin_kind = previous

func losses(before: Array, after: Array, species: String) -> void:
	# Nodes removed by the source remain valid until queue_free completes.
	for body in before:
		if not after.has(body):
			emit_record("loss",species,1,body.position,body.get_instance_id())

func update_prey(delta: float) -> void:
	var before := prey_list.duplicate()
	arrivals.clear()
	super.update_prey(delta)
	losses(before+arrivals,prey_list,"prey")

func update_predators(delta: float) -> void:
	var old_prey := prey_list.duplicate()
	var old_predators := predator_list.duplicate()
	arrivals.clear()
	super.update_predators(delta)
	losses(old_prey,prey_list,"prey")
	losses(old_predators+arrivals,predator_list,"predator")

func _record_care(kind: String, amount: int) -> void:
	super._record_care(kind,amount)
	# Supplied creatures are already counted at spawning; do not count twice.
	if kind == "food_added": emit_record("food","support",amount,Vector3.ZERO)
	if kind == "pressure_steps": emit_record("pressure","support",amount,Vector3.ZERO)

func advance(delta: float) -> void:
	tick += 1
	super._process(delta)

func restart() -> void:
	recording = false
	tick = 0
	serial = 0
	origin_kind = "supplied"
	arrivals.clear()
	_rebuild_now()
	recording = true
