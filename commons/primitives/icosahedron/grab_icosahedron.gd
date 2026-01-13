@tool
extends XRToolsPickable

## Alternate material when button pressed
@export var alternate_material : Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

## Icosahedron properties
@export var base_color: Color = Color(0.2, 1.0, 0.6)
@export var icosahedron_scale: float = 0.4:
	set(value):
		icosahedron_scale = value
		if Engine.is_editor_hint():
			_rebuild_icosahedron()

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)

	# Build the icosahedron mesh
	_rebuild_icosahedron()

	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _rebuild_icosahedron() -> void:
	var geometry := _icosahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	var mesh_instance = get_node_or_null("MeshInstance3D")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		move_child(mesh_instance, 1)  # Move after CollisionShape3D
	
	var mesh = PrimitiveMeshBuilder.build_mesh(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Icosahedron",
			"material": material
		}
	)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	# Update collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		var convex_shape = ConvexPolygonShape3D.new()
		convex_shape.points = geometry["vertices"]
		collision_shape.shape = convex_shape

func _icosahedron_geometry() -> Dictionary:
	var scale := icosahedron_scale
	var vertices: Array[Vector3] = [
		Vector3(0.85065, 0.52573, 0.0),
		Vector3(-0.85065, 0.52573, 0.0),
		Vector3(0.85065, -0.52573, 0.0),
		Vector3(-0.85065, -0.52573, 0.0),
		Vector3(0.52573, 0.0, 0.85065),
		Vector3(0.52573, 0.0, -0.85065),
		Vector3(-0.52573, 0.0, 0.85065),
		Vector3(-0.52573, 0.0, -0.85065),
		Vector3(0.0, 0.85065, 0.52573),
		Vector3(0.0, -0.85065, 0.52573),
		Vector3(0.0, 0.85065, -0.52573),
		Vector3(0.0, -0.85065, -0.52573)
	]
	for i in range(vertices.size()):
		vertices[i] *= scale
	var faces: Array = [
		[0, 8, 4], [0, 5, 10], [2, 4, 9], [2, 11, 5],
		[1, 6, 8], [1, 10, 7], [3, 9, 6], [3, 7, 11],
		[0, 10, 8], [1, 8, 10], [2, 9, 11], [3, 11, 9],
		[4, 2, 0], [5, 0, 2], [6, 1, 3], [7, 3, 1],
		[8, 6, 4], [9, 4, 6], [10, 5, 7], [11, 7, 5]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_shelf:
		return
	if _current_controller:
		return
	_snap_to_nearest_shelf_point(true)

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)

# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null

	# Restore original material when dropped
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)
	_snap_to_nearest_shelf_point()

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, alternate_material)

# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore original material when button released
		var mesh_instance = get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.set_surface_override_material(0, _original_material)

func _snap_to_nearest_shelf_point(force: bool = false) -> void:
	if not snap_to_shelf:
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

	var target = best_point.global_position
	var current_scale = global_transform.basis.get_scale()
	var basis := Basis.IDENTITY
	if snap_match_rotation:
		basis = best_point.global_transform.basis
	basis = basis.scaled(current_scale)
	global_transform = Transform3D(basis, target)
