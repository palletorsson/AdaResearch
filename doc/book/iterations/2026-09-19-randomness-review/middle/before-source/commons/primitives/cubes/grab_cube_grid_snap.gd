@tool
extends XRToolsPickable

## Grid-based snapping with 90-degree rotation
@export var snap_to_grid: bool = true
@export var snap_max_distance: float = 0.15
@export var snap_falloff_distance: float = 1.0
@export var enable_rotation_snap: bool = true  # Snap to 90-degree increments

# Original material
var _original_material: Material

# Current controller holding this object
var _current_controller: XRController3D

func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)

	# Get the original material
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		_original_material = mesh.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_grid:
		return
	if _current_controller:
		return
	_snap_to_nearest_grid_point(true)

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	_current_controller = get_picked_up_by_controller()

# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	_current_controller = null
	_snap_to_nearest_grid_point()

func _snap_to_nearest_grid_point(force: bool = false) -> void:
	if not snap_to_grid:
		return

	var effective_max = snap_max_distance
	if force:
		effective_max = snap_falloff_distance if snap_falloff_distance > 0.0 else snap_max_distance
	elif snap_max_distance <= 0.0:
		return

	var snap_points = get_tree().get_nodes_in_group("shelf_snap_point")
	if snap_points.is_empty():
		return

	var best_point: Node3D = null
	var best_distance = effective_max if effective_max > 0.0 else INF

	for point in snap_points:
		if point is Node3D:
			var snap_node := point as Node3D
			if not is_instance_valid(snap_node):
				continue
			var distance = snap_node.global_position.distance_to(global_position)
			if distance <= best_distance:
				best_distance = distance
				best_point = snap_node

	if best_point == null:
		return

	if snap_falloff_distance > 0.0 and best_distance > snap_falloff_distance:
		return

	# Snap position
	var target_position = best_point.global_position

	# Snap rotation to 90-degree increments if enabled
	var target_basis := Basis.IDENTITY
	if enable_rotation_snap:
		var current_rotation = global_transform.basis.get_euler()

		# Snap each axis to nearest 90 degrees (PI/2 radians)
		var snapped_x = round(current_rotation.x / (PI / 2)) * (PI / 2)
		var snapped_y = round(current_rotation.y / (PI / 2)) * (PI / 2)
		var snapped_z = round(current_rotation.z / (PI / 2)) * (PI / 2)

		target_basis = Basis.from_euler(Vector3(snapped_x, snapped_y, snapped_z))
	else:
		target_basis = global_transform.basis

	# Preserve scale
	var current_scale = global_transform.basis.get_scale()
	target_basis = target_basis.scaled(current_scale)

	# Apply snapped transform
	global_transform = Transform3D(target_basis, target_position)
