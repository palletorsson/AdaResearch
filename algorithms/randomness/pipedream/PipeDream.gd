extends Node3D
## PipeScreensaver3D.gd
## Generates a neon "Windows Pipes"-style path with smoother materials and bounds-aware growth.

@export_group("Geometry")
@export var pipe_radius: float = 0.12
@export var segment_length: float = 0.95
@export var max_segments: int = 180
@export var bounds_extent: Vector3 = Vector3(6.0, 4.0, 6.0)

@export_group("Timing")
@export var turn_interval: float = 0.08
@export_range(0.0, 1.0, 0.01) var continue_straight_chance: float = 0.32
@export var growth_tween_time: float = 0.08

@export_group("Look")
@export var base_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var accent_color: Color = Color(1.0, 0.35, 0.9, 1.0)
@export var metallic: float = 0.62
@export var roughness: float = 0.2
@export var emission_energy: float = 2.2
@export var add_head_light: bool = true
@export var head_light_energy: float = 1.8

const CARDINAL_DIRECTIONS: Array[Vector3] = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.UP,
	Vector3.DOWN
]

var rng := RandomNumberGenerator.new()
var direction: Vector3 = Vector3.FORWARD
var current_position: Vector3 = Vector3.ZERO
var segment_timer: float = 0.0
var segment_count: int = 0

var _segment_root: Node3D
var _joint_root: Node3D
var _head_light: OmniLight3D

var _segment_mesh: CylinderMesh
var _joint_mesh: SphereMesh


func _ready() -> void:
	rng.randomize()
	_setup_meshes()
	_setup_roots()
	if add_head_light:
		_setup_head_light()
	_create_next_segment()


func _process(delta: float) -> void:
	if segment_count >= max_segments:
		return

	segment_timer += delta
	while segment_timer >= turn_interval and segment_count < max_segments:
		segment_timer -= turn_interval
		_create_next_segment()

	if _head_light:
		_head_light.position = current_position


func _setup_meshes() -> void:
	_segment_mesh = CylinderMesh.new()
	_segment_mesh.top_radius = pipe_radius
	_segment_mesh.bottom_radius = pipe_radius
	_segment_mesh.height = segment_length
	_segment_mesh.radial_segments = 18

	_joint_mesh = SphereMesh.new()
	_joint_mesh.radius = pipe_radius * 1.42
	_joint_mesh.height = pipe_radius * 2.84
	_joint_mesh.radial_segments = 18
	_joint_mesh.rings = 10


func _setup_roots() -> void:
	_segment_root = Node3D.new()
	_segment_root.name = "Segments"
	add_child(_segment_root)

	_joint_root = Node3D.new()
	_joint_root.name = "Joints"
	add_child(_joint_root)


func _setup_head_light() -> void:
	_head_light = OmniLight3D.new()
	_head_light.name = "HeadLight"
	_head_light.light_color = base_color
	_head_light.light_energy = head_light_energy
	_head_light.omni_range = 2.8
	_head_light.omni_attenuation = 0.9
	add_child(_head_light)


func _create_next_segment() -> void:
	var start_pos: Vector3 = current_position
	var tentative_end: Vector3 = start_pos + direction * segment_length

	# If we are about to leave bounds, force a turn toward valid space.
	if _is_outside_bounds(tentative_end):
		direction = _choose_next_direction(direction, true)
		tentative_end = start_pos + direction * segment_length

	var segment_color := _segment_color(segment_count)
	_add_segment(start_pos, tentative_end, segment_color)

	if segment_count > 0:
		_add_joint(start_pos, segment_color)

	current_position = tentative_end
	direction = _choose_next_direction(direction, false)
	segment_count += 1


func _add_segment(start_pos: Vector3, end_pos: Vector3, segment_color: Color) -> void:
	var segment := MeshInstance3D.new()
	segment.mesh = _segment_mesh
	segment.material_override = _build_pipe_material(segment_color)

	var midpoint := (start_pos + end_pos) * 0.5
	segment.transform = Transform3D(_basis_from_direction(direction), midpoint)
	segment.scale = Vector3(1.0, 0.06, 1.0)
	_segment_root.add_child(segment)

	if growth_tween_time > 0.0:
		var tw := create_tween()
		tw.tween_property(segment, "scale:y", 1.0, growth_tween_time)
	else:
		segment.scale.y = 1.0


func _add_joint(joint_pos: Vector3, segment_color: Color) -> void:
	var joint := MeshInstance3D.new()
	joint.mesh = _joint_mesh
	joint.position = joint_pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = segment_color.darkened(0.12)
	mat.metallic = min(1.0, metallic + 0.15)
	mat.roughness = roughness * 0.8
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.35
	mat.clearcoat_roughness = 0.05  # Godot 4: low roughness = high gloss
	mat.emission_enabled = true
	mat.emission = segment_color
	mat.emission_energy_multiplier = emission_energy * 0.75
	joint.material_override = mat

	_joint_root.add_child(joint)


func _build_pipe_material(segment_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = segment_color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.rim_tint = 0.35
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.25
	mat.clearcoat_roughness = 0.1  # Godot 4: low roughness = high gloss
	mat.emission_enabled = true
	mat.emission = segment_color
	mat.emission_energy_multiplier = emission_energy
	return mat


func _segment_color(index: int) -> Color:
	var denom: float = maxf(1.0, float(max_segments - 1))
	var t: float = float(index) / denom
	var blend := 0.5 + 0.5 * sin(t * TAU * 2.0)
	var color := base_color.lerp(accent_color, blend)
	color.s = clampf(color.s * 1.05, 0.0, 1.0)
	color.v = clampf(color.v * 1.1, 0.0, 1.0)
	return color


func _choose_next_direction(current_dir: Vector3, force_turn: bool) -> Vector3:
	if not force_turn and rng.randf() < continue_straight_chance:
		var straight_target := current_position + current_dir * segment_length
		if not _is_outside_bounds(straight_target):
			return current_dir

	var candidates: Array[Vector3] = []
	for d in CARDINAL_DIRECTIONS:
		if d == -current_dir:
			continue
		if d == current_dir and force_turn:
			continue
		candidates.append(d)

	candidates = _shuffled_directions(candidates)
	for candidate in candidates:
		var next_pos := current_position + candidate * segment_length
		if not _is_outside_bounds(next_pos):
			return candidate

	# Fallback if boxed in: keep current direction.
	return current_dir


func _is_outside_bounds(pos: Vector3) -> bool:
	return (
		abs(pos.x) > bounds_extent.x
		or abs(pos.y) > bounds_extent.y
		or abs(pos.z) > bounds_extent.z
	)


func _basis_from_direction(dir: Vector3) -> Basis:
	# Cylinder mesh uses +Y as its long axis; align Y to direction.
	var y_axis := dir.normalized()
	var reference := Vector3.FORWARD
	if abs(y_axis.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var x_axis := reference.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)


func _shuffled_directions(source: Array[Vector3]) -> Array[Vector3]:
	var out: Array[Vector3] = source.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp: Vector3 = out[i]
		out[i] = out[j]
		out[j] = temp
	return out

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
