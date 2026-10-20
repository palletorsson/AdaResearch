extends "res://commons/hazards/catalyst_counterpart/counterpart_trial.gd"
## A direct-entry arena: one catalyst, one counterpart, three selectable operations.
const GOAL := 3
const HEAD_HOME := Vector3(0, 1.65, -3.5)
var head_home := HEAD_HOME
@export var open_landscape := false
var running := false
var round_hits := 0
var completed := false
var score_lights: Array[MeshInstance3D] = []
var start_button: Node3D
var rest_button: Node3D
var reset_button: Node3D

func _ready() -> void:
	name = "CatalystTestArena"
	# Visual floor inlay: the actual museum floor remains the walkable surface.
	_surface(Vector3(0, 0.008, -2.5), Vector3(7.5, 0.012, 8.5), Color(0.075, 0.075, 0.08))
	for x in [-3.75, 3.75]:
		_surface(Vector3(x, 0.02, -2.5), Vector3(0.035, 0.006, 8.5), Color(0.8, 0.8, 0.76))
	for z in [1.75, -6.75]:
		_surface(Vector3(0, 0.02, z), Vector3(7.5, 0.006, 0.035), Color(0.8, 0.8, 0.76))
	if open_landscape:
		_surface(Vector3(0, 2.85, -7.2), Vector3(8, 2.4, 0.12), Color(0.08, 0.08, 0.085))
		for x in [-3.8, 3.8]: _plinth(Vector3(x, 0.82, -7.2), Vector3(0.10, 1.64, 0.10))
	else:
		_surface(Vector3(0, 2.25, -7.2), Vector3(10, 4.5, 0.15), Color(0.08, 0.08, 0.085))
	_label("THE BIOME" if open_landscape else "ENDLESS MUSEUM", Vector3(0, 3.8, -7.10), 64, 0.004)
	_label("always another room", Vector3(0, 3.38, -7.10), 30, 0.003)
	_label("CATALYST / COUNTERPART", Vector3(0, 2.94, -7.10), 39, 0.003)
	readout = _label("", Vector3(0, 2.30, -7.09), 34, 0.003)
	for i in range(GOAL):
		var light := MeshInstance3D.new(); var mesh := SphereMesh.new()
		mesh.radius = 0.065; mesh.height = 0.13; mesh.radial_segments = 12; mesh.rings = 6
		light.mesh = mesh; light.position = Vector3((i - 1) * 0.30, 1.68, -7.05)
		add_child(light); score_lights.append(light)
	skull = Skull.new(); skull.position = head_home; skull.home_position = head_home; add_child(skull)
	skull.interrupted.connect(_on_interruption)
	catalyst = load("res://commons/artifacts/ignorance_gallery/resolution_catalyst.gd").new()
	catalyst.position = Vector3(-4.6, 1.18, 0.6)
	add_child(catalyst)
	_plinth(Vector3(-4.6, 0.49, 0.6), Vector3(0.60, 0.98, 0.60))
	_label("TAKE THE POINT", Vector3(-4.6, 1.78, 0.38), 32, 0.002)
	_label("Aim with the holding hand.\nTrigger sends a form.", Vector3(-4.6, 1.55, 0.38), 24, 0.0018)
	# A reachable console outside the head's bounds, with a clear centre entrance.
	_plinth(Vector3(4.7, 0.52, 0.6), Vector3(2.7, 1.04, 0.48))
	_surface(Vector3(4.7, 1.36, 0.70), Vector3(2.7, 1.0, 0.12), Color(0.81, 0.80, 0.76))
	for i in range(3):
		var power := i + 1
		var button := _control(["MOVE", "TURN", "SCALE"][i], Vector3(3.9 + i * 0.8, 1.14, 0.86), func(): set_operation(power))
		buttons.append(button)
	start_button = _control("START", Vector3(3.9, 1.5, 0.86), start_round)
	rest_button = _control("REST", Vector3(4.7, 1.5, 0.86), rest)
	reset_button = _control("RESET", Vector3(5.5, 1.5, 0.86), reset_round)
	_label("CHOOSE A MOTION. PRESS START.", Vector3(4.7, 1.92, 0.6), 25, 0.0017)
	_label("Sidestep the warning line.\nInterrupt the head three times.\nREST stops the encounter immediately.", Vector3(0, 1.5, 2.8), 25, 0.002)
	_update_score()

func _process(_delta: float) -> void:
	if not is_instance_valid(skull): return
	var mode: String = ["MOVE", "TURN", "SCALE"][skull.power - 1]
	var status := "ROUND COMPLETE — THE HEAD REMAINS" if completed else ("READ THE LINE / INTERRUPT THE MOTION" if running else "READY — TAKE THE POINT, THEN START")
	readout.text = "%s\n%s   ·   %d / %d interruptions   ·   %d touches" % [status, mode, round_hits, GOAL, skull.tags]

func set_operation(power: int) -> void:
	reset_round()
	skull.set_power(power)
	skull.advance(0, skull.target_position())

func start_round() -> void:
	if running: return
	_clear_shots()
	round_hits = 0; completed = false; skull.interruptions = 0; skull.tags = 0
	running = true
	skull.set_active(true)
	_update_score()

func rest() -> void:
	running = false
	skull.set_active(false)
	_clear_shots()

func reset_round() -> void:
	rest()
	round_hits = 0; completed = false
	skull.interruptions = 0; skull.tags = 0; skull.phase = 0.0
	skull.position = head_home
	catalyst._cooldown = 0.0
	if not catalyst.is_resolution_held(): catalyst._return_in = 0.08
	_update_score()

func _on_interruption() -> void:
	if not running: return
	round_hits += 1
	_update_score()
	if round_hits >= GOAL:
		running = false; completed = true
		skull.active = false
		_clear_shots.call_deferred()

func _clear_shots() -> void:
	for shot in catalyst.projectiles:
		if is_instance_valid(shot): shot.queue_free()
	catalyst.projectiles.clear()

func _update_score() -> void:
	for i in range(score_lights.size()):
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.92, 0.92, 0.84) if i < round_hits else Color(0.23, 0.23, 0.24)
		score_lights[i].material_override = material

func _control(caption: String, at: Vector3, action: Callable) -> Node3D:
	var button: Node3D = load("res://commons/interactables/cube_button.tscn").instantiate()
	button.position = at; button.scale = Vector3.ONE * 1.7
	button.label = caption; button.accent = Color(0.88, 0.88, 0.83)
	add_child(button); button.pressed.connect(action)
	for label in button.find_children("*", "Label3D", true, false):
		label.outline_size = 0
	return button

func _surface(at: Vector3, size: Vector3, color: Color) -> void:
	var view := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.75
	view.mesh = mesh; view.material_override = material; view.position = at; add_child(view)

static func mount_arena(hall: Node3D) -> Node3D:
	var arena := load("res://commons/hazards/catalyst_counterpart/test_arena.gd").new() as Node3D
	var at := hall.to_global(Vector3(8.5, 0, 11.5))
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3, at + Vector3.DOWN * 5, 1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		arena.free(); push_error("Arena requires the museum floor"); return null
	at.y = hit.position.y
	arena.position = hall.to_local(at); arena.rotation.y = PI
	hall.add_child(arena)
	return arena
