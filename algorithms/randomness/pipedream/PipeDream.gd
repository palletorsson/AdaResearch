extends Node3D
## PipeScreensaver3D.gd
## A minimal 3D "Windows Pipes" screensaver clone.
## Grows a single colored pipe that changes direction every second for 100 rounds.

@export var pipe_radius: float = 0.1
@export var segment_length: float = 1.0
@export var turn_interval: float = 0.1   # seconds between new segments
@export var max_segments: int = 100
@export var color: Color = Color(0.2, 0.8, 1.0)

var rng := RandomNumberGenerator.new()
var direction := Vector3.FORWARD
var current_position := Vector3.ZERO
var segment_timer := 0.0
var segment_count := 0

func _ready():
	rng.randomize()
	_create_next_segment() # start with first segment

func _process(delta: float) -> void:
	segment_timer += delta
	if segment_timer >= turn_interval and segment_count < max_segments:
		segment_timer = 0.0
		_create_next_segment()

# ------------------------------------------------------------

func _create_next_segment():
	# 1️⃣ Create a cylinder pipe segment
	var segment := MeshInstance3D.new()
	segment.mesh = CylinderMesh.new()
	segment.mesh.top_radius = pipe_radius
	segment.mesh.bottom_radius = pipe_radius
	segment.mesh.height = segment_length
	segment.scale = Vector3.ONE

	# Material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy = 1.5
	segment.material_override = mat

	# Set position and rotation
	var end_pos := current_position + direction * segment_length
	var midpoint := (current_position + end_pos) / 2.0
	segment.position = midpoint

	# Rotate pipe to face direction
	segment.look_at_from_position(midpoint, end_pos, Vector3.UP)
	segment.rotation_degrees.x += 90.0

	add_child(segment)

	# 2️⃣ Occasionally add a spherical “joint”
	if segment_count > 0:
		var joint := MeshInstance3D.new()
		joint.mesh = SphereMesh.new()
		joint.scale = Vector3(pipe_radius, pipe_radius, pipe_radius) * 1.5

		var joint_mat := StandardMaterial3D.new()
		joint_mat.albedo_color = color.darkened(0.2)
		joint_mat.metallic = 0.8
		joint.material_override = joint_mat

		joint.position = current_position
		add_child(joint)

	# 3️⃣ Update position + direction for next turn
	current_position = end_pos
	direction = _random_turn(direction)

	segment_count += 1

func _random_turn(dir: Vector3) -> Vector3:
	# Choose a random new direction, perpendicular or opposite
	var possible_dirs = [
		Vector3.FORWARD,
		Vector3.BACK,
		Vector3.LEFT,
		Vector3.RIGHT,
		Vector3.UP,
		Vector3.DOWN
	]
	var new_dir = dir
	while new_dir == dir or new_dir == -dir:
		new_dir = possible_dirs[randi() % possible_dirs.size()]
	return new_dir
