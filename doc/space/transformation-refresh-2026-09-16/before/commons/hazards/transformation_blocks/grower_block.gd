# @identity
# essence: scale(block) -> grow(into_player) -> pit(death) — a cube that expands and squeezes you out
# desire: to make scale felt as pressure — the world growing into your body, stealing your space
# critical_parameter: grow_speed / max_scale — the breathing rhythm must be readable: small=safe, big=danger
# triggers: sine-wave scale cycle; AnimatableBody3D collision pushes player as it grows
# emerges: the uncanny transformation — you don't move, the world moves into you
# needs: AnimatableBody3D [has]; scale animation [has]; DangerZone on edges [external]
# relationships: sibling to pusher_block (translation) and sweeper_block (rotation); the scale lesson
# truth: scale is the transformation that changes everything while appearing to change nothing.

# GrowerBlock.gd
# A cube that pulses between tiny and huge, physically pushing the player
# as it grows. When small, you can pass. When large, it fills the corridor
# and squeezes you into the pit.
#
# Uses AnimatableBody3D so Godot physics handles the pushing.
# Place in a corridor with pits on one or both sides.

extends Node3D
class_name GrowerBlock

@export var min_scale: float = 0.1             ## Smallest size (fraction of grid cell)
@export var max_scale: float = 2.5             ## Largest size (multiple of grid cell)
@export var grow_speed: float = 0.5            ## Cycles per second (full breathe cycle)
@export var block_size: float = 1.0            ## Grid cube size for alignment

var _body: AnimatableBody3D = null
var _mesh: MeshInstance3D = null
var _col_shape: CollisionShape3D = null
var _box_shape: BoxShape3D = null
var _time: float = 0.0


func _ready() -> void:
	_build_body()


func _physics_process(delta: float) -> void:
	_time += delta * grow_speed * TAU
	# Sine wave: 0..1 range
	var t: float = (sin(_time) + 1.0) * 0.5
	var current_scale: float = lerpf(min_scale, max_scale, t)

	# Scale the collision shape (AnimatableBody3D uses shape size for push)
	var s: float = block_size * current_scale
	_box_shape.size = Vector3(s, s, s)
	if _mesh and _mesh.mesh is BoxMesh:
		(_mesh.mesh as BoxMesh).size = Vector3(s, s, s)

	# Color shifts from cool (small) to hot (large)
	if _mesh and _mesh.material_override:
		var mat: StandardMaterial3D = _mesh.material_override
		var hot: float = clampf((current_scale - min_scale) / (max_scale - min_scale), 0.0, 1.0)
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
