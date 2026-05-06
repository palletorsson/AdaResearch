# GrabMengerSponge.gd - Grabbable Menger sponge fractal
@tool
extends XRToolsPickable

@export var alternate_material: Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

@export var base_color: Color = Color(0.4, 0.4, 0.8):
	set(value):
		base_color = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

@export var object_scale: float = 0.15:
	set(value):
		object_scale = value
		if Engine.is_editor_hint():
			_rebuild_mesh()

@export_range(0, 3) var fractal_level: int = 2:
	set(value):
		fractal_level = value
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
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_generate_menger(st, Vector3.ZERO, object_scale, fractal_level)
	st.generate_normals()
	mesh_instance.mesh = st.commit()
	mesh_instance.material_override = GridMaterialFactory.make(base_color)
	
	# Update collision
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		var box = BoxShape3D.new()
		box.size = Vector3.ONE * object_scale
		collision.shape = box

func _generate_menger(st: SurfaceTool, center: Vector3, size: float, depth: int) -> void:
	if depth == 0:
		_add_cube(st, center, size)
		return
	
	var new_size = size / 3.0
	var offset = new_size
	
	for x in range(3):
		for y in range(3):
			for z in range(3):
				var x_center = (x == 1)
				var y_center = (y == 1)
				var z_center = (z == 1)
				var centered = int(x_center) + int(y_center) + int(z_center)
				if centered >= 2:
					continue
				var pos = center + Vector3((x - 1) * offset, (y - 1) * offset, (z - 1) * offset)
				_generate_menger(st, pos, new_size, depth - 1)

func _add_cube(st: SurfaceTool, center: Vector3, size: float) -> void:
	var h = size / 2.0
	var v = [
		center + Vector3(-h, -h, -h), center + Vector3(h, -h, -h),
		center + Vector3(h, -h, h), center + Vector3(-h, -h, h),
		center + Vector3(-h, h, -h), center + Vector3(h, h, -h),
		center + Vector3(h, h, h), center + Vector3(-h, h, h)
	]
	var faces = [
		[0, 2, 1], [0, 3, 2], [4, 5, 6], [4, 6, 7],
		[3, 6, 2], [3, 7, 6], [0, 1, 5], [0, 5, 4],
		[1, 2, 6], [1, 6, 5], [0, 4, 7], [0, 7, 3]
	]
	for face in faces:
		var v0 = v[face[0]]
		var v1 = v[face[1]]
		var v2 = v[face[2]]
		var n = (v1 - v0).cross(v2 - v0).normalized()
		st.set_normal(n)
		st.add_vertex(v0)
		st.set_normal(n)
		st.add_vertex(v1)
		st.set_normal(n)
		st.add_vertex(v2)

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
