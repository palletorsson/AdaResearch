# GrabTorus.gd - Grabbable torus
@tool
extends XRToolsPickable

@export var alternate_material: Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

@export var base_color: Color = Color(0.2, 0.8, 0.4):
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

var _original_material: Material
var _current_controller: XRController3D

func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		set_process(true)
	_rebuild_mesh()
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

func _rebuild_mesh() -> void:
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		if get_child_count() > 1:
			move_child(mesh_instance, 1)
	
	var torus = TorusMesh.new()
	torus.inner_radius = object_scale * 0.3
	torus.outer_radius = object_scale * 0.7
	torus.rings = 24
	torus.ring_segments = 16
	mesh_instance.mesh = torus
	mesh_instance.material_override = GridMaterialFactory.make(base_color)
	
	# Update collision with approximate sphere
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		var shape = SphereShape3D.new()
		shape.radius = object_scale * 0.7
		collision.shape = shape

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_shelf or _current_controller:
		return
	_snap_to_nearest_shelf_point(true)

func _on_picked_up(_pickable) -> void:
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_button_pressed)
		_current_controller.button_released.connect(_on_button_released)

func _on_dropped(_pickable) -> void:
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_button_pressed)
		_current_controller.button_released.disconnect(_on_button_released)
		_current_controller = null
	var mi = get_node_or_null("MeshInstance3D")
	if mi:
		mi.set_surface_override_material(0, _original_material)
	_snap_to_nearest_shelf_point()

func _on_button_pressed(button: String):
	if button == "ax_button" and alternate_material:
		var mi = get_node_or_null("MeshInstance3D")
		if mi:
			mi.set_surface_override_material(0, alternate_material)

func _on_button_released(button: String):
	if button == "ax_button":
		var mi = get_node_or_null("MeshInstance3D")
		if mi:
			mi.set_surface_override_material(0, _original_material)

func _snap_to_nearest_shelf_point(force: bool = false) -> void:
	if not snap_to_shelf:
		return
	var effective_max = snap_falloff_distance if force else snap_max_distance
	if effective_max <= 0.0:
		return
	var snap_points = get_tree().get_nodes_in_group("shelf_snap_point")
	var best_point: Node3D = null
	var best_dist = effective_max
	for point in snap_points:
		if point is Node3D:
			var d = point.global_position.distance_to(global_position)
			if d <= best_dist:
				best_dist = d
				best_point = point
	if best_point:
		global_position = best_point.global_position
