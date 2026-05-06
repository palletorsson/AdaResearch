# ===========================================================================
# Friction Racer VR - Interactive Game Expansion of Example 2.4: Friction
# Race through surfaces with different friction coefficients!
# ===========================================================================

extends Node3D

const PARAMETER_CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const FORCES_UI := preload("res://algorithms/forces/forces_ui.gd")

# Track configuration
const TRACK_SEGMENTS := [
	{ "length": 0.4, "friction": 0.05, "color": Color(0.5, 0.7, 1.0), "name": "ICE" },
	{ "length": 0.3, "friction": 0.15, "color": Color(0.7, 0.7, 0.7), "name": "SMOOTH" },
	{ "length": 0.3, "friction": 0.35, "color": Color(0.9, 0.6, 0.4), "name": "ROUGH" },
	{ "length": 0.4, "friction": 0.08, "color": Color(0.6, 0.8, 1.0), "name": "ICE" },
	{ "length": 0.3, "friction": 0.25, "color": Color(0.8, 0.8, 0.5), "name": "SAND" },
]

# Game constants
const RACER_START_Z := -0.9
const FINISH_LINE_Z := 0.9
const BOOST_COOLDOWN := 2.0
const BOOST_FORCE := 1.5

# Physics
var gravity: Vector3 = Vector3(0, -0.9, 0)

# Game objects
var racer: Mover
var opponent: Mover
var checkpoint_areas: Array[Area3D] = []

# VR interaction
var can_boost: bool = true
var boost_timer: float = 0.0

# Game state
var race_active: bool = false
var race_time: float = 0.0
var best_time: float = INF
var checkpoints_passed: int = 0
var opponent_speed_base: float = 0.8

# UI
var info_label: Label3D
var time_label: Label3D
var boost_label: Label3D
var instructions_label: Label3D
var friction_info_labels: Array[Label3D] = []

# Settings
var show_friction_info: bool = true

func _ready() -> void:
	# Scale down for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	create_race_track()
	create_checkpoints()
	create_racers()
	create_ui()
	position_camera_overhead()

	print("Friction Racer VR - Master surface physics to win!")

func _process(delta: float) -> void:
	if race_active:
		race_time += delta

	update_boost_cooldown(delta)
	update_opponent_ai(delta)
	update_ui()
	check_race_completion()

func _physics_process(_delta: float):
	apply_racer_physics()
	apply_opponent_physics()

func create_race_track() -> void:
	var current_z: float = RACER_START_Z
	var lane_width: float = 0.25

	for segment in TRACK_SEGMENTS:
		var seg_length: float = segment["length"]
		var seg_friction: float = segment["friction"]
		var seg_color: Color = segment["color"]
		var seg_name: String = segment["name"]

		# Create segment visual
		create_track_segment(
			Vector3(0, -0.35, current_z + seg_length / 2),
			Vector3(lane_width, 0.02, seg_length),
			seg_color,
			seg_friction
		)

		# Create friction info label
		create_friction_label(
			Vector3(lane_width / 2 + 0.15, -0.33, current_z + seg_length / 2),
			"%s\nmu=%.2f" % [seg_name, seg_friction],
			seg_color
		)

		current_z += seg_length

	# Create side barriers
	create_barrier(Vector3(lane_width / 2 + 0.05, -0.25, 0), Vector3(0.02, 0.2, 2.4))
	create_barrier(Vector3(-lane_width / 2 - 0.05, -0.25, 0), Vector3(0.02, 0.2, 2.4))

	# Create finish line
	create_finish_line(Vector3(0, -0.33, FINISH_LINE_Z))

func create_track_segment(pos: Vector3, size: Vector3, color: Color, friction: float) -> void:
	var segment := StaticBody3D.new()
	segment.set_meta("friction", friction)

	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	segment.add_child(collider)
	segment.position = pos

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = clamp(friction * 2.0, 0.1, 1.0)
	mat.metallic = 0.1
	mesh_instance.material_override = mat
	segment.add_child(mesh_instance)

	add_child(segment)

func create_friction_label(pos: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	FORCES_UI.style_tag_label(label, pos, color, 14)
	FORCES_UI.set_label_text(label, text)
	add_child(label)
	friction_info_labels.append(label)

func create_barrier(pos: Vector3, size: Vector3) -> void:
	var barrier := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	barrier.add_child(collider)
	barrier.position = pos

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.4, 0.3, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	barrier.add_child(mesh_instance)

	add_child(barrier)

func create_finish_line(pos: Vector3) -> void:
	var finish := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.3, 0.1)
	finish.mesh = plane
	finish.rotation_degrees = Vector3(-90, 0, 0)
	finish.position = pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color.YELLOW * 0.5
	finish.material_override = mat
	add_child(finish)

func create_checkpoints() -> void:
	# Create invisible checkpoints along the track for progress tracking
	var checkpoint_positions := [-0.5, -0.1, 0.3, 0.7, FINISH_LINE_Z]

	for i in range(checkpoint_positions.size()):
		var checkpoint := Area3D.new()
		checkpoint.name = "Checkpoint_%d" % i

		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, 0.3, 0.05)
		collider.shape = box
		checkpoint.add_child(collider)
		checkpoint.position = Vector3(0, 0, checkpoint_positions[i])

		checkpoint.body_entered.connect(_on_checkpoint_entered.bind(i))
		add_child(checkpoint)
		checkpoint_areas.append(checkpoint)

func create_racers() -> void:
	# Player racer (blue)
	racer = Mover.new()
	racer.mass = 1.0
	racer.position_v = Vector3(-0.08, 0.0, RACER_START_Z)
	racer.velocity = Vector3.ZERO
	racer.bounce_damping = 0.5
	add_child(racer)
	racer.set_size(0.06)
	racer.set_color(Color.CYAN)

	# Opponent racer (red)
	opponent = Mover.new()
	opponent.mass = 1.0
	opponent.position_v = Vector3(0.08, 0.0, RACER_START_Z)
	opponent.velocity = Vector3.ZERO
	opponent.bounce_damping = 0.5
	add_child(opponent)
	opponent.set_size(0.06)
	opponent.set_color(Color.RED)

func apply_racer_physics() -> void:
	if not racer:
		return

	# Gravity
	racer.apply_force(gravity * racer.mass)

	# Friction based on current track segment
	var friction_coeff := get_friction_at_position(racer.position_v.z)
	if racer.velocity.length() > 0.02:
		var friction_dir := -racer.velocity.normalized()
		var normal_force: float = abs(gravity.y) * racer.mass
		var friction_force: Vector3 = friction_dir * friction_coeff * normal_force
		racer.apply_force(friction_force)

func apply_opponent_physics() -> void:
	if not opponent:
		return

	# Gravity
	opponent.apply_force(gravity * opponent.mass)

	# Friction
	var friction_coeff := get_friction_at_position(opponent.position_v.z)
	if opponent.velocity.length() > 0.02:
		var friction_dir := -opponent.velocity.normalized()
		var normal_force: float = abs(gravity.y) * opponent.mass
		var friction_force: Vector3 = friction_dir * friction_coeff * normal_force
		opponent.apply_force(friction_force)

func get_friction_at_position(z_pos: float) -> float:
	var current_z: float = RACER_START_Z
	for segment in TRACK_SEGMENTS:
		var seg_length: float = segment["length"]
		if z_pos >= current_z and z_pos <= current_z + seg_length:
			return segment["friction"]
		current_z += seg_length
	return 0.15  # Default friction

func update_opponent_ai(_delta: float) -> void:
	if not opponent or not race_active:
		return

	# AI opponent applies forward force based on friction
	var current_friction := get_friction_at_position(opponent.position_v.z)
	var forward_force := Vector3(0, 0, opponent_speed_base) * (1.2 - current_friction)
	opponent.apply_force(forward_force)

func update_boost_cooldown(delta: float) -> void:
	if not can_boost:
		boost_timer += delta
		if boost_timer >= BOOST_COOLDOWN:
			can_boost = true
			boost_timer = 0.0

func apply_boost() -> void:
	if not racer or not can_boost:
		return

	racer.apply_force(Vector3(0, 0, BOOST_FORCE))
	can_boost = false
	boost_timer = 0.0

	# Visual effect
	create_boost_effect(racer.position_v)

func create_boost_effect(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 25
	particles.lifetime = 0.4
	particles.position = pos
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.08
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.4
	particles.initial_velocity_max = 0.8
	particles.scale_amount_min = 0.02
	particles.scale_amount_max = 0.04
	particles.color = Color.YELLOW

	add_child(particles)

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func _on_checkpoint_entered(body: Node, checkpoint_index: int) -> void:
	if body == racer and checkpoint_index == checkpoints_passed:
		checkpoints_passed += 1

		if checkpoint_index == checkpoint_areas.size() - 1:
			# Crossed finish line
			complete_race()

func check_race_completion() -> void:
	# Also check if opponent finished
	if opponent and opponent.position_v.z >= FINISH_LINE_Z and race_active:
		race_active = false
		if info_label:
			FORCES_UI.set_label_text(info_label, "OPPONENT WON!")

func complete_race() -> void:
	if not race_active:
		return

	race_active = false

	if race_time < best_time:
		best_time = race_time

	if info_label:
		FORCES_UI.set_label_text(info_label, "YOU WON! Time: %.2fs" % race_time)

	await get_tree().create_timer(3.0).timeout
	reset_race()

func position_camera_overhead() -> void:
	# Helper to position a follow camera (if needed)
	pass

func create_ui() -> void:
	info_label = Label3D.new()
	FORCES_UI.style_title_label(info_label, Vector3(0, 0.7, 0), 32)
	add_child(info_label)

	time_label = Label3D.new()
	FORCES_UI.style_value_label(time_label, Vector3(0, 0.55, 0), Color.YELLOW, 28)
	add_child(time_label)

	boost_label = Label3D.new()
	FORCES_UI.style_value_label(boost_label, Vector3(0, 0.42, 0), Color.CYAN, 20)
	add_child(boost_label)

	instructions_label = Label3D.new()
	FORCES_UI.style_instruction_label(instructions_label, Vector3(0, 0.3, 0), 18)
	FORCES_UI.set_label_text(instructions_label, "[SPACE/TRIGGER] Boost | [R] Reset | [S] Start")
	add_child(instructions_label)

func update_ui() -> void:
	if info_label and not race_active:
		if best_time < INF:
			FORCES_UI.set_label_text(info_label, "FRICTION RACER\nBest: %.2fs" % best_time)
		else:
			FORCES_UI.set_label_text(info_label, "FRICTION RACER\nPress [S] to Start")

	if time_label:
		if race_active:
			FORCES_UI.set_label_text(time_label, "Time: %.2fs" % race_time)
		else:
			FORCES_UI.set_label_text(time_label, "")

	if boost_label:
		if can_boost:
			FORCES_UI.set_label_text(boost_label, "BOOST READY!")
		else:
			FORCES_UI.set_label_text(boost_label, "Boost: %.1fs" % (BOOST_COOLDOWN - boost_timer))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				reset_race()
			KEY_S:
				start_race()
			KEY_SPACE:
				apply_boost()

func start_race() -> void:
	race_active = true
	race_time = 0.0
	checkpoints_passed = 0

	if racer:
		racer.position_v = Vector3(-0.08, 0.0, RACER_START_Z)
		racer.velocity = Vector3.ZERO

	if opponent:
		opponent.position_v = Vector3(0.08, 0.0, RACER_START_Z)
		opponent.velocity = Vector3.ZERO

func reset_race() -> void:
	race_active = false
	race_time = 0.0
	checkpoints_passed = 0
	can_boost = true
	boost_timer = 0.0

	if racer:
		racer.position_v = Vector3(-0.08, 0.0, RACER_START_Z)
		racer.velocity = Vector3.ZERO
		racer.acceleration = Vector3.ZERO

	if opponent:
		opponent.position_v = Vector3(0.08, 0.0, RACER_START_Z)
		opponent.velocity = Vector3.ZERO
		opponent.acceleration = Vector3.ZERO

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
