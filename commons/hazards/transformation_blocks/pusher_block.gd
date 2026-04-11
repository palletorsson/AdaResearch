# @identity
# essence: translation(block) -> push(player) -> pit(death) — a cube that slides and shoves you into the void
# desire: to make translation felt in the body — not a number but a force that moves you
# critical_parameter: push_speed / push_distance — too slow is boring, too fast is unfair, the sweet spot teaches timing
# triggers: timer-driven translation cycle; player body contact applies physics impulse
# emerges: the player learns translation by being translated — the block does to you what you do to objects
# needs: AnimatableBody3D [has]; grid alignment [has]; DangerZone below [external]
# relationships: sibling to sweeper_block (rotation) and grower_block (scale); lives above pits in transformation sequence
# truth: translation is the simplest transformation and the most dangerous — everything that moves can push.

# PusherBlock.gd
# A cube that translates back and forth along one axis, pushing the player
# into a pit. Uses AnimatableBody3D so Godot's physics engine handles the
# player collision — the block physically shoves rigid bodies and characters.
#
# Place on a grid cell adjacent to a pit (void). The block slides across,
# pushing anything in its path. Player must time their crossing.

extends Node3D
class_name PusherBlock

@export var push_axis: Vector3 = Vector3.RIGHT  ## Direction of translation (normalized)
@export var push_distance: float = 3.0          ## How far the block travels (grid cells)
@export var push_speed: float = 2.0             ## Meters per second
@export var pause_time: float = 1.0             ## Seconds to pause at each end
@export var block_size: float = 1.0             ## Matches grid cube_size

var _body: AnimatableBody3D = null
var _mesh: MeshInstance3D = null
var _start_pos: Vector3 = Vector3.ZERO
var _end_pos: Vector3 = Vector3.ZERO
var _t: float = 0.0  # 0..1 normalized position along path
var _direction: float = 1.0  # +1 = forward, -1 = backward
var _paused: bool = false
var _pause_timer: float = 0.0


func _ready() -> void:
	_build_body()
	_start_pos = global_position
	_end_pos = _start_pos + push_axis.normalized() * push_distance


func _physics_process(delta: float) -> void:
	if _paused:
		_pause_timer -= delta
		if _pause_timer <= 0:
			_paused = false
			_direction *= -1.0
		return

	# Move along the path
	var speed_normalized: float = push_speed / push_distance
	_t += _direction * speed_normalized * delta
	_t = clampf(_t, 0.0, 1.0)

	var target_pos: Vector3 = _start_pos.lerp(_end_pos, _t)
	_body.global_position = target_pos

	# Pause at endpoints
	if _t >= 1.0 or _t <= 0.0:
		_paused = true
		_pause_timer = pause_time


func _build_body() -> void:
	# AnimatableBody3D: moves via code, pushes CharacterBody3D and RigidBody3D
	_body = AnimatableBody3D.new()
	_body.name = "PusherBody"
	add_child(_body)

	# Collision shape
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * block_size * 0.98
	col.shape = box
	_body.add_child(col)

	# Visual mesh
	_mesh = MeshInstance3D.new()
	_mesh.name = "PusherMesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE * block_size * 0.98
	_mesh.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.3, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.2, 0.1)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.5
	mat.roughness = 0.3
	_mesh.material_override = mat
	_body.add_child(_mesh)

	# Arrow indicator showing push direction
	var arrow := MeshInstance3D.new()
	arrow.name = "DirectionArrow"
	var arrow_mesh := PrismMesh.new()
	arrow_mesh.size = Vector3(block_size * 0.3, block_size * 0.15, block_size * 0.3)
	arrow.mesh = arrow_mesh
	arrow.position = push_axis.normalized() * block_size * 0.55
	# Rotate arrow to point in push direction
	if push_axis.normalized() != Vector3.UP and push_axis.normalized() != Vector3.DOWN:
		arrow.look_at(arrow.position + push_axis.normalized(), Vector3.UP)
		arrow.rotation.x += PI * 0.5
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 0.5, 0.3)
	arrow_mat.emission_enabled = true
	arrow_mat.emission = Color(1.0, 0.4, 0.2)
	arrow_mat.emission_energy_multiplier = 1.5
	arrow.material_override = arrow_mat
	_body.add_child(arrow)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("axis"):
		match str(config_data["axis"]):
			"x": push_axis = Vector3.RIGHT
			"-x": push_axis = Vector3.LEFT
			"z": push_axis = Vector3.BACK
			"-z": push_axis = Vector3.FORWARD
	if config_data.has("distance"):
		push_distance = float(config_data["distance"])
	if config_data.has("speed"):
		push_speed = float(config_data["speed"])
	if config_data.has("pause"):
		pause_time = float(config_data["pause"])
