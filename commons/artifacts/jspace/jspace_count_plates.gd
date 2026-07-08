extends Node3D
class_name JSpaceCountPlates

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the output strip made performable — five coral floor plates, ONE to FIVE, that must be stepped in order. Wrong order flashes and resets; the fifth plate emits exam_passed, so the ExamGate completes the map. The count is not printed; it is walked.
# desire: to be the sentence the room speaks on your way out — output as choreography.
# critical_parameter: next_index — the only state; the count is a protocol, not a picture.
# triggers: stepping a plate in order locks it lit; out of order resets all; plate five fires exam_passed.
# emerges: the player IS the decoder — the body performs autoregression, one token per stride.
# needs: player-body detection [layer 20, as DangerZone]; the ExamGate autoload listening for exam_passed.
# relationships: the output layer of [[jspace_zoom_chamber]]; gated by ExamGate like every prove-it exam; the coral row from the interpretability image, walkable.
# truth: a model's answer is a path taken one step at a time, each step conditioned on the last. So is yours across this floor.

signal exam_passed
signal plate_stepped(index: int)
signal count_reset

const WORDS := ["one", "two", "three", "four", "five"]
const CORAL_DIM := Color(0.55, 0.22, 0.14)
const CORAL_LIT := Color(0.95, 0.42, 0.24)

@export var spacing: float = 1.3

var next_index: int = 0
var _plates: Array = []     # {mat, tag}
var _done := false

func _ready() -> void:
	for i in WORDS.size():
		_plate(i)
	var tag: Node3D = BakedText.make_tag("say the count with your feet — in order", Color(0.9, 0.75, 0.65), 0.055)
	if tag:
		tag.position = Vector3(0, 1.5, 0)
		add_child(tag)

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

func _plate(i: int) -> void:
	var x := (float(i) - float(WORDS.size() - 1) * 0.5) * spacing
	var root := Node3D.new()
	root.name = "plate_%s" % WORDS[i]
	root.position = Vector3(x, 0, 0)
	add_child(root)

	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.07, 1.0)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = CORAL_DIM
	m.emission_enabled = true
	m.emission = CORAL_DIM
	m.emission_energy_multiplier = 0.25
	mi.material_override = m
	mi.position = Vector3(0, 0.035, 0)
	root.add_child(mi)

	# the word painted flat on the plate top
	var label: MeshInstance3D = BakedText.make_label_mesh(WORDS[i], Color(0.98, 0.92, 0.88), Vector2(0.8, 0.34), 1400, true)
	if label:
		label.rotation_degrees = Vector3(-90, 0, 0)
		label.position = Vector3(0, 0.076, 0)
		root.add_child(label)

	# step sensor — player body layer, as DangerZone/EdgeZone
	var area := Area3D.new()
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 0
	area.collision_mask = 524288
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.6, 1.0)
	col.shape = box
	col.position = Vector3(0, 0.8, 0)
	area.add_child(col)
	root.add_child(area)
	area.body_entered.connect(_on_step.bind(i))

	_plates.append({"mat": m, "root": root})

func _is_player(b: Node3D) -> bool:
	return b.is_in_group("player") or b.is_in_group("player_body") \
		or b.name.contains("Player") or b.name.contains("XR")

func _on_step(body: Node3D, i: int) -> void:
	if _done or not _is_player(body):
		return
	if i == next_index:
		_lock(i)
		plate_stepped.emit(i)
		next_index += 1
		if next_index >= WORDS.size():
			_complete()
	elif i > next_index:
		_reset()

func _lock(i: int) -> void:
	var m: StandardMaterial3D = _plates[i]["mat"]
	m.albedo_color = CORAL_LIT
	m.emission = CORAL_LIT
	m.emission_energy_multiplier = 1.8

func _reset() -> void:
	next_index = 0
	count_reset.emit()
	for p in _plates:
		var m: StandardMaterial3D = p["mat"]
		m.albedo_color = Color(0.7, 0.12, 0.12)
		m.emission = Color(0.7, 0.12, 0.12)
		m.emission_energy_multiplier = 1.2
	var timer := get_tree().create_timer(0.45)
	timer.timeout.connect(func():
		for p in _plates:
			var m: StandardMaterial3D = p["mat"]
			m.albedo_color = CORAL_DIM
			m.emission = CORAL_DIM
			m.emission_energy_multiplier = 0.25)

func _complete() -> void:
	_done = true
	exam_passed.emit()
	# a quiet column of light where the count ended
	var mote := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	mote.mesh = sm
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.3, 1.0, 0.45)
	mm.emission_enabled = true
	mm.emission = Color(0.3, 1.0, 0.45)
	mm.emission_energy_multiplier = 2.5
	mote.material_override = mm
	mote.position = Vector3(float(WORDS.size() - 1) * 0.5 * spacing, 1.2, 0)
	add_child(mote)
	var tag: Node3D = BakedText.make_tag("COUNT COMPLETE — the gate heard it", Color(0.75, 1.0, 0.8), 0.06)
	if tag:
		tag.position = Vector3(float(WORDS.size() - 1) * 0.5 * spacing, 1.7, 0)
		add_child(tag)
