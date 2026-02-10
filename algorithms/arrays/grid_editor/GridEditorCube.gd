extends XRToolsPickable

## Grid Editor Cube (Improved)
## A cube that snaps to a grid and synchronizes with a paired cube in another grid
## Features: Visual feedback, ghost preview, smooth snapping, haptic feedback

class_name GridEditorCube

# Grid properties
# Grid properties
@export var grid_size: Vector3 = Vector3(8, 8, 8)  # 8x8x8 snap resolution
@export var cell_size: float = 0.125  # 1m / 8 = 0.125m for miniature
@export var is_miniature: bool = true
@export var is_spawner: bool = false # Infinite source of cubes

# Visual feedback
@export var hover_color: Color = Color(0.5, 1.0, 1.0, 1.0)
@export var grab_color: Color = Color(1.0, 0.8, 0.0, 1.0)
@export var spawner_color: Color = Color(0.2, 1.0, 0.2, 1.0) # Green for source
@export var snap_speed: float = 10.0  # Speed of snap animation

# Grid coordinates
var grid_position: Vector3i = Vector3i(0, 0, 0)
var paired_cube: GridEditorCube = null
var grid_manager: Node = null
var grid_origin: Vector3 = Vector3.ZERO

# Visual elements
var _mesh_instance: MeshInstance3D
var _original_material: Material
var _ghost_preview: MeshInstance3D
var _is_hovered: bool = false

# Snapping state
var _snap_target_pos: Vector3
var _is_snapping: bool = false

func _ready() -> void:
	super._ready()
	
	# Configure pickable properties
	enabled = is_miniature
	press_to_hold = true # Hold to grab - feels more natural
	ranged_grab_method = RangedMethod.SNAP if is_miniature else RangedMethod.NONE
	freeze = true  # Start frozen
	
	# Find and scale mesh instance based on cell_size
	_mesh_instance = find_child("MeshInstance3D", true, false)
	if _mesh_instance:
		_mesh_instance.scale = Vector3.ONE * cell_size
		if _mesh_instance.material_override:
			_original_material = _mesh_instance.material_override
	
	# Scale collision shape based on cell_size (slightly smaller to avoid snagging)
	var collision_shape = find_child("CollisionShape3D", true, false)
	if collision_shape and collision_shape.shape:
		collision_shape.shape = collision_shape.shape.duplicate()
		collision_shape.shape.size = Vector3.ONE * cell_size * 0.9 # 90% size for clearance
	
	# Create ghost preview (only for miniature)
	if is_miniature:
		_create_ghost_preview()
	
	# Connect signals
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)
	highlight_updated.connect(_on_highlight_updated)
	
	# Set initial position
	update_position_from_grid()
	
	# Initial visual state
	if is_spawner:
		_apply_color_tint(spawner_color)

func _create_ghost_preview() -> void:
	_ghost_preview = MeshInstance3D.new()
	_ghost_preview.name = "GhostPreview"
	_ghost_preview.visible = false
	
	# Copy mesh from main mesh instance
	if _mesh_instance:
		_ghost_preview.mesh = _mesh_instance.mesh
		_ghost_preview.scale = _mesh_instance.scale
		
		# Create ghost material
		var ghost_mat = StandardMaterial3D.new()
		ghost_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ghost_mat.albedo_color = Color(0.5, 1.0, 1.0, 0.3)
		ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_preview.material_override = ghost_mat
	
	get_parent().add_child(_ghost_preview) if get_parent() else add_child(_ghost_preview)

func _physics_process(delta: float) -> void:
	# Handle smooth snapping animation
	if _is_snapping:
		position = position.lerp(_snap_target_pos, delta * snap_speed)
		if position.distance_to(_snap_target_pos) < 0.001:
			position = _snap_target_pos
			_is_snapping = false
	
	# Update ghost preview position while dragging
	if is_picked_up() and _ghost_preview:
		var current_grid_pos = local_to_grid(position)
		var ghost_local_pos = grid_to_local(current_grid_pos)
		# Ghost preview is a sibling, so local position works if it's in the same coordinate space
		# However, if we are grabbed, we might be moving globally. 
		# We want the ghost to show where we would snap in the PARENT'S space.
		_ghost_preview.position = ghost_local_pos
		_ghost_preview.visible = true

func _on_picked_up(_pickable) -> void:
	freeze = false
	# Disable collisions while holding so we can reach through other cubes
	collision_layer = 0
	collision_mask = 0
	
	print("GridEditorCube: Picked up at grid position %s" % grid_position)
	
	if is_spawner:
		# I am now a real boy!
		is_spawner = false
		
		# Trigger manager to spawn a replacement spawner at my old spot
		if grid_manager and grid_manager.has_method("spawn_replacement_spawner"):
			grid_manager.spawn_replacement_spawner(grid_position)
			
		# And request a full-scale pair for myself (since spawners don't have one usually)
		if grid_manager and grid_manager.has_method("create_pair_for_cube"):
			grid_manager.create_pair_for_cube(self)
	
	# Visual feedback
	_apply_color_tint(grab_color)
	
	# Haptic feedback
	var controller = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0, 0.3, 0.1, 0)

func _on_dropped(_pickable) -> void:
	# Restore collisions (Layer 3 = Pickable)
	collision_layer = 4
	collision_mask = 3
	
	# Reset rotation immediately
	rotation = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	
	# Snap to nearest grid position
	var current_pos = position # Use local position
	var snapped_grid_pos = local_to_grid(current_pos)
	set_grid_position(snapped_grid_pos, true)  # true = animate
	
	# Hide ghost preview
	if _ghost_preview:
		_ghost_preview.visible = false
	
	# Visual feedback
	_apply_color_tint(hover_color if _is_hovered else Color.WHITE)
	
	# Haptic feedback on snap
	var controller = get_picked_up_by_controller()
	if controller:
		controller.trigger_haptic_pulse("haptic", 0, 0.5, 0.05, 0)
	
	freeze = true
	print("GridEditorCube: Dropped at grid position %s" % grid_position)

func _on_highlight_updated(_pickable, enable: bool) -> void:
	_is_hovered = enable
	if not is_picked_up():
		_apply_color_tint(hover_color if enable else Color.WHITE)

func _apply_color_tint(color: Color) -> void:
	if _mesh_instance and _mesh_instance.material_override:
		var mat = _mesh_instance.material_override
		if mat is ShaderMaterial:
			mat.set_shader_parameter("modelColor", color)

## Set grid position with optional animation
func set_grid_position(new_grid_pos: Vector3i, animate: bool = false) -> void:
	# UNLOCKED: No clamping. Build anywhere!
	# new_grid_pos.x = clampi(new_grid_pos.x, 0, int(grid_size.x) - 1) ...
	
	# Check if grid position actually changed
	var changed = (new_grid_pos != grid_position)
	grid_position = new_grid_pos
	
	if animate:
		_snap_target_pos = grid_to_local(grid_position)
		_is_snapping = true
	else:
		update_position_from_grid()
	
	# Synchronize with paired cube ONLY if position changed to avoid loops
	if changed and paired_cube and paired_cube != self:
		paired_cube.grid_position = grid_position
		paired_cube.update_position_from_grid()

func update_position_from_grid() -> void:
	var local_pos = grid_to_local(grid_position)
	position = local_pos

func grid_to_local(grid_pos: Vector3i) -> Vector3:
	var offset = Vector3(grid_pos) * cell_size
	# Center cube in its cell
	offset += Vector3.ONE * cell_size * 0.5
	return grid_origin + offset

func local_to_grid(local_pos: Vector3) -> Vector3i:
	var relative_pos = local_pos - grid_origin
	var grid_float = relative_pos / cell_size
	
	return Vector3i(
		roundi(grid_float.x),
		roundi(grid_float.y),
		roundi(grid_float.z)
	)

func set_paired_cube(cube: GridEditorCube) -> void:
	paired_cube = cube
	if cube:
		print("GridEditorCube: Paired with %s" % cube.name)

func set_grid_origin(origin: Vector3) -> void:
	grid_origin = origin
	update_position_from_grid()
