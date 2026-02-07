# GrabbablePolyhedron.gd - Base class for grabbable math objects
@tool
extends XRToolsPickable
class_name GrabbablePolyhedron

## Alternate material when button pressed
@export var alternate_material: Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

## Common properties
@export var base_color: Color = Color(1.0, 0.0, 1.0):
	set(value):
		base_color = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

@export var object_scale: float = 0.15:
	set(value):
		object_scale = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

# Original material
var _original_material: Material

# Current controller holding this object
var _current_controller: XRController3D

func _ready() -> void:
	super()
	
	if not Engine.is_editor_hint():
		set_process(true)
	
	# Build the mesh
	_rebuild_mesh()
	
	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
	
	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

## Override this to provide geometry
func _get_geometry() -> Dictionary:
	return {"vertices": [], "faces": []}

## Override this to provide material overrides
func _get_material_overrides() -> Dictionary:
	return {}

func _rebuild_mesh() -> void:
	var geometry := _get_geometry()
	if geometry["vertices"].is_empty():
		return
	
	var overrides = _get_material_overrides()
	var material = GridMaterialFactory.make(base_color, overrides)
	var mesh_instance = get_node_or_null("MeshInstance3D")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		if get_child_count() > 1:
			move_child(mesh_instance, 1)
	
	var mesh = PrimitiveMeshBuilder.build_mesh(
		geometry["vertices"],
		geometry["faces"],
		{"name": _get_object_name()}
	)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	# Update collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		var convex_shape = ConvexPolygonShape3D.new()
		convex_shape.points = geometry["vertices"]
		collision_shape.shape = convex_shape

func _get_object_name() -> String:
	return "Polyhedron"

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_shelf:
		return
	if _current_controller:
		return
	_snap_to_nearest_shelf_point(true)

func _on_picked_up(_pickable) -> void:
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)

func _on_dropped(_pickable) -> void:
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null
	
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)
	_snap_to_nearest_shelf_point()

func _on_controller_button_pressed(button: String):
	if button == "ax_button":
		if alternate_material:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, alternate_material)

func _on_controller_button_released(button: String):
	if button == "ax_button":
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
