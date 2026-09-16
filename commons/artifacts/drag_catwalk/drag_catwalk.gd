extends Node3D
## A level, joinable runway. Four performers follow a bounded stadium route,
## stop to pose at either end, and yield to the visitor and one another.
## No wardrobe/progression manager is created for the performers.
const Agent := preload("res://commons/artifacts/drag_catwalk/runway_agent.gd")
const Outfit := preload("res://commons/player/super_drag_outfit.gd")
const Controls := preload("res://commons/ui/control_panel.gd")
const RADIUS := 0.95
const STRAIGHT := 7.5
const NEAR_Z := 2.1
const FAR_Z := NEAR_Z + STRAIGHT
const PATH_LENGTH := 2.0 * STRAIGHT + TAU * RADIUS
const HALF_PATH := PATH_LENGTH * 0.5
const POSE_SECONDS := 2.4
const PLAYER_CLEARANCE := 0.95
const AGENT_CLEARANCE := 1.25
@export_range(0.25, 1.2) var walk_speed: float = 0.65
@export var viewer_path: NodePath
@export var running: bool = true
var agents: Array[Node3D] = []
var clocks: Array[float] = []
var travelled: Array[float] = []
var buttons: Array[Node3D] = []
var readout: Label
var viewer: Node3D
var look_offset: int = 0
var _inactive: bool = false

func _ready() -> void:
	_build_stage()
	if not viewer_path.is_empty():
		viewer = get_node_or_null(viewer_path) as Node3D
	for i in range(4):
		var agent := Agent.new()
		agent.name = "RunwayAgent_%d" % (i + 1)
		agent.look_index = i
		add_child(agent)
		agents.append(agent)
		clocks.append(period() * float(i) / 4.0)
		travelled.append(float(i) * HALF_PATH * 0.5)
		var sample := sample_clock(clocks[i])
		agent.position = sample.position
		agent.rotation.y = _yaw(sample.direction)
		agent.animate(travelled[i], not sample.posing)

func period() -> float:
	return PATH_LENGTH / maxf(0.25, walk_speed) + 2.0 * POSE_SECONDS

## Constant-speed straights and semicircles. Tangents are continuous at joins.
func route(distance: float) -> Dictionary:
	var s := fposmod(distance, PATH_LENGTH)
	var p: Vector3
	var tangent: Vector3
	if s < STRAIGHT:
		p = Vector3(-RADIUS, 0.02, NEAR_Z + s)
		tangent = Vector3.BACK
	elif s < STRAIGHT + PI * RADIUS:
		var a := PI - (s - STRAIGHT) / RADIUS
		p = Vector3(cos(a) * RADIUS, 0.02, FAR_Z + sin(a) * RADIUS)
		tangent = Vector3(sin(a), 0, -cos(a))
	elif s < 2.0 * STRAIGHT + PI * RADIUS:
		p = Vector3(RADIUS, 0.02, FAR_Z - (s - STRAIGHT - PI * RADIUS))
		tangent = Vector3.FORWARD
	else:
		var a := -(s - 2.0 * STRAIGHT - PI * RADIUS) / RADIUS
		p = Vector3(cos(a) * RADIUS, 0.02, NEAR_Z + sin(a) * RADIUS)
		tangent = Vector3(sin(a), 0, -cos(a))
	return {"position": p, "direction": tangent}

func sample_clock(clock: float) -> Dictionary:
	var half_time := HALF_PATH / maxf(0.25, walk_speed)
	var leg_time := half_time + POSE_SECONDS
	var t := fposmod(clock, 2.0 * leg_time)
	var leg := int(t / leg_time)
	var in_leg := fposmod(t, leg_time)
	var posing := in_leg >= half_time
	var distance := float(leg) * HALF_PATH + minf(in_leg, half_time) * walk_speed
	# Start at the near tip; a half circuit reaches the far tip.
	var sample := route(distance + 2.0 * STRAIGHT + 1.5 * PI * RADIUS)
	if posing:
		sample.direction = Vector3.BACK if leg == 0 else Vector3.FORWARD
	sample.posing = posing
	return sample

func _physics_process(delta: float) -> void:
	if not is_instance_valid(viewer):
		viewer = get_viewport().get_camera_3d()
	# The museum also suspends distant artifacts. This protects standalone uses.
	_inactive = is_instance_valid(viewer) and global_position.distance_to(viewer.global_position) > 35.0
	advance(minf(delta, 0.1))

func advance(delta: float) -> void:
	if agents.is_empty():
		return
	var old: Array[Vector3] = []
	for agent in agents:
		old.append(agent.position)
	var yielding_count := 0
	for i in range(agents.size()):
		var agent: Node3D = agents[i]
		var next := sample_clock(clocks[i] + delta)
		var blocked := false
		if is_instance_valid(viewer):
			var eye := to_local(viewer.global_position)
			if eye.y > -0.5 and eye.y < 3.0:
				blocked = _flat_distance(eye, next.position) < PLAYER_CLEARANCE
		for j in range(old.size()):
			if i == j:
				continue
			# Yield only when closing the gap, so two nearby agents can separate.
			var before := _flat_distance(old[i], old[j])
			var after := _flat_distance(next.position, old[j])
			if after < AGENT_CLEARANCE and after < before - 0.00001:
				blocked = true
		agent.yielding = blocked
		if blocked:
			yielding_count += 1
		if running and not _inactive and not blocked:
			clocks[i] += delta
		var sample := sample_clock(clocks[i])
		var moved := agent.position.distance_to(sample.position)
		travelled[i] += moved
		agent.position = sample.position
		agent.rotation.y = lerp_angle(agent.rotation.y, _yaw(sample.direction), 1.0 - exp(-7.0 * delta))
		agent.animate(travelled[i], moved > 0.00001)
	if readout != null:
		readout.text = "Show held / join the runway" if not running else ("Making room for you" if yielding_count > 0 else "Four looks / walk, turn, pose")

func toggle_show() -> void:
	running = not running

func next_looks() -> void:
	look_offset = (look_offset + 1) % Outfit.LOOKS.size()
	for i in range(agents.size()):
		agents[i].set_look(i + look_offset)

func _yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)

func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _build_stage() -> void:
	var dark := _material(Color("201327"), 0.32, 0.20)
	var metal := _material(Color("b68b62"), 0.30, 0.65)
	var pink := _material(Color("ed4b9d"), 0.30, 0.1, 0.45)
	var ivory := _material(Color("f0dcd2"), 0.5, 0.05)
	# Surface is only 18 mm above the existing floor and has no collision lip.
	_box("Runway", Vector3(0, 0.009, 5.85), Vector3(3.8, 0.018, 11.8), dark)
	for side in [-1.0, 1.0]:
		_box("LuminousHem", Vector3(side * 1.86, 0.022, 5.85), Vector3(0.045, 0.015, 11.8), pink)
		_box("AudienceMargin", Vector3(side * 2.55, 0.005, 5.85), Vector3(1.25, 0.01, 11.8), ivory)
	for z in [NEAR_Z - RADIUS, FAR_Z + RADIUS]:
		var mark := MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.44
		ring.outer_radius = 0.47
		ring.rings = 40
		ring.ring_segments = 6
		mark.mesh = ring
		mark.scale.y = 0.15
		mark.position = Vector3(0, 0.027, z)
		mark.material_override = pink
		add_child(mark)
	# Light arches stand outside the walking and passing lanes.
	for z in [0.0, 5.85, 11.7]:
		for side in [-1.0, 1.0]:
			_box("ArchPost", Vector3(side * 3.4, 1.6, z), Vector3(0.065, 3.2, 0.065), metal, true)
			var lamp := OmniLight3D.new()
			lamp.position = Vector3(side * 2.5, 2.8, z)
			lamp.light_color = Color("ffe2cd") if side < 0 else Color("ccddff")
			lamp.light_energy = 0.65
			lamp.omni_range = 5.0
			lamp.shadow_enabled = false
			add_child(lamp)
		_box("ArchLintel", Vector3(0, 3.2, z), Vector3(6.86, 0.07, 0.07), metal)
		_box("LightBar", Vector3(0, 3.14, z), Vector3(3.2, 0.025, 0.10), ivory)
	var panel := Controls.new()
	panel.name = "ShowControls"
	panel.title = "THE FLOOR IS YOURS"
	panel.position = Vector3(-2.65, 1.08, 11.2)
	panel.tilt_degrees = -20
	panel.spacing = 0.32
	add_child(panel)
	readout = panel.add_readout("Four looks / walk, turn, pose")
	var hold := panel.add_button("HOLD / PLAY")
	hold.pressed.connect(toggle_show)
	buttons.append(hold)
	var looks := panel.add_button("SWAP LOOKS")
	looks.pressed.connect(next_looks)
	buttons.append(looks)
	_box("ControlStand", Vector3(-2.65, 0.52, 11.1), Vector3(0.10, 1.04, 0.12), metal)

func _material(color: Color, roughness: float, metallic: float, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	mat.emission_enabled = emission > 0
	mat.emission = color
	mat.emission_energy_multiplier = emission
	return mat

func _box(label: String, pos: Vector3, size: Vector3, mat: Material, solid: bool = false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.position = pos
		body.add_child(collision)
		add_child(body)
