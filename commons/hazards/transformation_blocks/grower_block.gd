# @identity
# essence: scale(block) -> changing occupied clearance — a cube whose visible and physical size cycle together
# desire: to make scale felt as pressure — the world growing into your body, stealing your space
# critical_parameter: grow_speed / min_scale / max_scale / anchor — timing, occupied volume and the fixed reference for growth
# triggers: elapsed time drives the size cycle, independently of visitor approach; anchor=floor starts small and keeps the bottom face fixed
# emerges: the uncanny transformation — you don't move, the world moves into you
# needs: AnimatableBody3D and matching mesh/shape sizes [has]; any hazards, level ground and bypass routes are authored by the containing map
# relationships: sibling to pusher_block (translation) and sweeper_block (rotation); the scale lesson
# truth: scale is the transformation that changes everything while appearing to change nothing.

# GrowerBlock.gd
# A cube that pulses between configured sizes, changing the space beside it.
# Legacy hazard placements can use it to squeeze a body toward external pits.
# Trans_Pit instead authors level ground and observation/bypass routes around
# floor-anchored growers; that staging is not supplied by anchor=floor alone.
#
# Uses AnimatableBody3D with a resized collision shape matching the visible cube.
# Actual passage and contact depend on the surrounding geometry and player body.

extends Node3D
class_name GrowerBlock

@export var min_scale: float = 0.1             ## Smallest size (fraction of grid cell)
@export var max_scale: float = 2.5             ## Largest size (multiple of grid cell)
@export var grow_speed: float = 0.5            ## Cycles per second (full breathe cycle)
@export var block_size: float = 1.0            ## Grid cube size for alignment
@export_enum("center", "floor") var anchor: String = "center"

var _body: AnimatableBody3D = null
var _mesh: MeshInstance3D = null
var _col_shape: CollisionShape3D = null
var _box_shape: BoxShape3D = null
var _time: float = 0.0


func _ready() -> void:
	_build_body()
	_update_size()


func _physics_process(delta: float) -> void:
	_time += delta * grow_speed * TAU
	_update_size()


func _update_size() -> void:
	# Sine wave: 0..1 range
	# The floor-anchored lesson begins small: there is time to see the gap.
	var t: float = (1.0 - cos(_time)) * 0.5 if anchor == "floor" else (sin(_time) + 1.0) * 0.5
	var current_scale: float = lerpf(min_scale, max_scale, t)

	# Scale the collision shape (AnimatableBody3D uses shape size for push)
	var s: float = block_size * current_scale
	_box_shape.size = Vector3(s, s, s)
	if _mesh and _mesh.mesh is BoxMesh:
		(_mesh.mesh as BoxMesh).size = Vector3(s, s, s)
	# Keep the AnimatableBody's origin fixed. Its physics synchronization can
	# restore an old body transform while the resized shape has already changed.
	# Seat the visible and physical geometry within that body instead.
	var centre_y: float = s * 0.5 if anchor == "floor" else 0.0
	_col_shape.position.y = centre_y
	_mesh.position.y = centre_y

	# Color shifts from cool (small) to hot (large)
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		var hot: float = clampf((current_scale - min_scale) / maxf(max_scale - min_scale, 0.001), 0.0, 1.0)
		mat.albedo_color = Color(0.3 + hot * 0.6, 0.8 - hot * 0.5, 0.2, 0.9)
		mat.emission = Color(0.3 + hot * 0.7, 0.6 - hot * 0.4, 0.1)
		mat.emission_energy_multiplier = 0.5 + hot * 1.5


func _build_body() -> void:
	_body = AnimatableBody3D.new()
	_body.name = "GrowerBody"
	add_child(_body)

	# Collision — starts at min_scale, resized every frame
	_col_shape = CollisionShape3D.new()
	_box_shape = BoxShape3D.new()
	_box_shape.size = Vector3.ONE * block_size * min_scale
	_col_shape.shape = _box_shape
	_body.add_child(_col_shape)

	# Visual mesh — starts small, resized every frame
	_mesh = MeshInstance3D.new()
	_mesh.name = "GrowerMesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3.ONE * block_size * min_scale
	_mesh.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.8, 0.2, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 0.1)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh.material_override = mat
	_body.add_child(_mesh)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("min"):
		min_scale = float(config_data["min"])
	if config_data.has("max"):
		max_scale = float(config_data["max"])
	if config_data.has("speed"):
		grow_speed = float(config_data["speed"])
	if str(config_data.get("anchor", "")) in ["center", "floor"]:
		anchor = str(config_data["anchor"])
	min_scale = maxf(min_scale, 0.01)
	max_scale = maxf(max_scale, min_scale)
	grow_speed = maxf(grow_speed, 0.0)
	if is_instance_valid(_body):
		_update_size()
