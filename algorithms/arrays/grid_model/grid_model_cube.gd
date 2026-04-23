extends XRToolsPickable

## Grid Model Cube
## A miniature pickable cube that snaps to a 2D grid (XZ plane).
## When dropped, emits signals so GridModel can sync with the real GridSystem.
## Ported from GridEditorCube with key difference: no paired cube — the
## fullscale equivalent IS the GridSystem itself.

class_name GridModelCube

# Grid properties (set by GridModel at spawn time)
@export var cell_size: float = 0.1
@export var is_spawner: bool = false

# Visual feedback colors
@export var hover_color: Color = Color(0.5, 1.0, 1.0, 1.0)
@export var grab_color: Color = Color(1.0, 0.8, 0.0, 1.0)
@export var spawner_color: Color = Color(0.2, 1.0, 0.2, 1.0)
@export var snap_speed: float = 10.0

# Grid coordinates (set by GridModel)
var grid_x: int = 0
var grid_z: int = 0
var stack_y: int = 0
var map_width: int = 1
var map_depth: int = 1
var grid_model: Node = null

# Height-based colors: 0=dark → 5=red
const HEIGHT_COLORS: Array[Color] = [
	Color(0.15, 0.15, 0.2, 1.0),   # 0: dark
	Color(0.2, 0.4, 0.8, 1.0),     # 1: cool blue
	Color(0.2, 0.7, 0.3, 1.0),     # 2: green
	Color(0.9, 0.8, 0.2, 1.0),     # 3: yellow
	Color(0.9, 0.5, 0.1, 1.0),     # 4: orange
	Color(0.9, 0.2, 0.15, 1.0),    # 5: red
]

# Visual elements
var _mesh_instance: MeshInstance3D
var _original_material: Material
var _ghost_preview: MeshInstance3D
var _is_hovered: bool = false

# Snapping state
var _snap_target_pos: Vector3
var _is_snapping: bool = false

# Signals
signal cube_lifted(x: int, z: int, stack_y: int)
signal cube_dropped(from_x: int, from_z: int, to_x: int, to_z: int)

func _ready() -> void:
	super._ready()

	# Configure pickable
	enabled = true
	press_to_hold = true
	ranged_grab_method = RangedMethod.SNAP
	freeze = true
	gravity_scale = 0.0
	lock_rotation = true

	# Find and scale mesh
	_mesh_instance = find_child("MeshInstance3D", true, false)
	if _mesh_instance:
		_mesh_instance.scale = Vector3.ONE * cell_size
		if _mesh_instance.material_override:
			_original_material = _mesh_instance.material_override

	# Scale collision shape (slightly smaller for clearance)
	var collision_shape = find_child("CollisionShape3D", true, false)
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.size = Vector3.ONE * cell_size * 0.9

	# Create ghost preview
	_create_ghost_preview()

	# Connect signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)
	highlight_updated.connect(_on_highlight_updated)

	# Apply initial color
	if is_spawner:
		_apply_color_tint(spawner_color)
	else:
		_apply_height_color(stack_y)


func _create_ghost_preview() -> void:
	_ghost_preview = MeshInstance3D.new()
	_ghost_preview.name = "GhostPreview"
	_ghost_preview.visible = false

	if _mesh_instance:
		_ghost_preview.mesh = _mesh_instance.mesh
		_ghost_preview.scale = _mesh_instance.scale

		var ghost_mat = StandardMaterial3D.new()
		ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost_mat.albedo_color = Color(0.5, 1.0, 1.0, 0.3)
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_preview.material_override = ghost_mat

	if get_parent():
		get_parent().add_child(_ghost_preview)
	else:
		add_child(_ghost_preview)


func _physics_process(delta: float) -> void:
	# Smooth snap animation
	if _is_snapping:
		position = position.lerp(_snap_target_pos, delta * snap_speed)
		if position.distance_to(_snap_target_pos) < 0.001:
			position = _snap_target_pos
			_is_snapping = false

	# Update ghost preview while dragging
	if is_picked_up() and _ghost_preview:
		var target_grid = _local_to_grid_xz(position)
		var ghost_pos = _grid_to_local(target_grid.x, target_grid.y)
		_ghost_preview.position = ghost_pos
		_ghost_preview.visible = true


func _on_picked_up(_pickable) -> void:
	freeze = false
	collision_layer = 0
	collision_mask = 0

	var was_spawner = is_spawner
	if is_spawner:
		is_spawner = false
		# Tell GridModel to create a replacement spawner
		if grid_model and grid_model.has_method("_spawn_replacement_spawner"):
			grid_model._spawn_replacement_spawner(grid_x, grid_z)

	emit_signal("cube_lifted", grid_x, grid_z, stack_y)

	_apply_color_tint(grab_color)

	# Haptic feedback
	var controller = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0, 0.3, 0.1, 0)


func _on_dropped(_pickable) -> void:
	# Restore collisions
	collision_layer = 4
	collision_mask = 3

	# Reset rotation
	rotation = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Snap to nearest grid column (XZ only)
	var target = _local_to_grid_xz(position)
	var from_x = grid_x
	var from_z = grid_z

	# Clamp to map bounds
	var new_x = clampi(target.x, 0, map_width - 1)
	var new_z = clampi(target.y, 0, map_depth - 1)

	# Emit signal before updating position (GridModel will compute correct Y)
	emit_signal("cube_dropped", from_x, from_z, new_x, new_z)

	# Hide ghost
	if _ghost_preview:
		_ghost_preview.visible = false

	# Haptic snap feedback
	var controller = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0, 0.5, 0.05, 0)

	freeze = true


func _on_highlight_updated(_pickable, enable: bool) -> void:
	_is_hovered = enable
	if not is_picked_up():
		if enable:
			_apply_color_tint(hover_color)
		elif is_spawner:
			_apply_color_tint(spawner_color)
		else:
			_apply_height_color(stack_y)


func _apply_color_tint(color: Color) -> void:
	if _mesh_instance and _mesh_instance.material_override:
		var mat = _mesh_instance.material_override
		if mat is ShaderMaterial:
			mat.set_shader_parameter("modelColor", color)


func _apply_height_color(height: int) -> void:
	var idx = clampi(height, 0, HEIGHT_COLORS.size() - 1)
	_apply_color_tint(HEIGHT_COLORS[idx])


## Convert local position to grid column (XZ) — returns Vector2i(x, z)
func _local_to_grid_xz(local_pos: Vector3) -> Vector2i:
	var gx = roundi(local_pos.x / cell_size - 0.5)
	var gz = roundi(local_pos.z / cell_size - 0.5)
	return Vector2i(gx, gz)


## Convert grid column to local position (Y based on target column height)
func _grid_to_local(gx: int, gz: int) -> Vector3:
	# Ask GridModel for current height at target column
	var target_y = 0
	if grid_model and grid_model.has_method("get_column_height"):
		target_y = grid_model.get_column_height(gx, gz)

	return Vector3(
		(gx + 0.5) * cell_size,
		(target_y + 0.5) * cell_size,
		(gz + 0.5) * cell_size
	)


## Set position from grid coordinates
func snap_to_grid(x: int, z: int, y: int, animate: bool = false) -> void:
	grid_x = x
	grid_z = z
	stack_y = y
	var target = Vector3(
		(x + 0.5) * cell_size,
		(y + 0.5) * cell_size,
		(z + 0.5) * cell_size
	)
	if animate:
		_snap_target_pos = target
		_is_snapping = true
	else:
		position = target

	if not is_spawner:
		_apply_height_color(y)


func _exit_tree() -> void:
	if is_instance_valid(_ghost_preview) and _ghost_preview.get_parent():
		_ghost_preview.queue_free()
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
