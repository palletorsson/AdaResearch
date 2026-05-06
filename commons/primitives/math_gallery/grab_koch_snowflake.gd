# GrabKochSnowflake.gd - Grabbable Koch snowflake (extruded 3D version)
@tool
extends XRToolsPickable

@export var alternate_material: Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

@export var base_color: Color = Color(0.3, 0.6, 1.0):
	set(value):
		base_color = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

@export var object_scale: float = 0.15:
	set(value):
		object_scale = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

@export_range(0, 4) var fractal_depth: int = 3:
	set(value):
		fractal_depth = value
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
	
	# Generate Koch snowflake curve
	var vertices: Array[Vector3] = []
	var s = object_scale
	
	# Initial triangle
	var v1 = Vector3(0, 0, 0)
	var v2 = Vector3(s, 0, 0)
	var v3 = Vector3(s * 0.5, s * sqrt(3.0) / 2.0, 0)
	
	# Center the shape
	var center = (v1 + v2 + v3) / 3.0
	v1 -= center
	v2 -= center
	v3 -= center
	
	# Generate Koch curve for each edge
	_koch_edge(v1, v2, fractal_depth, vertices)
	_koch_edge(v2, v3, fractal_depth, vertices)
	_koch_edge(v3, v1, fractal_depth, vertices)
	
	# Build line mesh
	var immediate = ImmediateMesh.new()
	immediate.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(0, vertices.size(), 2):
		if i + 1 < vertices.size():
			immediate.surface_add_vertex(vertices[i])
			immediate.surface_add_vertex(vertices[i + 1])
	immediate.surface_end()
	mesh_instance.mesh = immediate
	
	# Apply material
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material
	
	# Update collision
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		var box = BoxShape3D.new()
		box.size = Vector3(s, s, s * 0.1)
		collision.shape = box

func _koch_edge(v1: Vector3, v2: Vector3, depth: int, vertices: Array[Vector3]) -> void:
	if depth == 0:
		vertices.append(v1)
		vertices.append(v2)
	else:
		var delta = v2 - v1
		var v3 = v1 + delta / 3.0
		var v5 = v1 + delta * 2.0 / 3.0
		var perp = Vector3(-delta.y, delta.x, 0).normalized()
		var height = delta.length() * sqrt(3.0) / 6.0
		var v4 = v3 + (v5 - v3) / 2.0 + perp * height
		
		_koch_edge(v1, v3, depth - 1, vertices)
		_koch_edge(v3, v4, depth - 1, vertices)
		_koch_edge(v4, v5, depth - 1, vertices)
		_koch_edge(v5, v2, depth - 1, vertices)

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
