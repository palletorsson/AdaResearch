@tool
extends Node3D
class_name EditableCurve

## Editable Curve - Interactive Bezier/Catmull-Rom curve with grabbable control points
## Extends the trace concept: from recorded gesture to deliberate construction

signal curve_changed(points: Array[Vector3])
signal control_point_grabbed(index: int)
signal control_point_released(index: int)

enum CurveType { BEZIER, CATMULL_ROM, LINEAR }

@export var curve_type: CurveType = CurveType.BEZIER:
	set(v):
		curve_type = v
		_rebuild_curve()

@export var curve_color: Color = Color(0.2, 0.8, 0.9, 1.0):
	set(v):
		curve_color = v
		_update_materials()

@export var control_point_color: Color = Color(1.0, 0.4, 0.2, 1.0):
	set(v):
		control_point_color = v
		_update_materials()

@export var tangent_color: Color = Color(0.5, 0.5, 0.5, 0.6):
	set(v):
		tangent_color = v
		_update_materials()

@export var curve_segments: int = 32:
	set(v):
		curve_segments = max(4, v)
		_rebuild_curve()

@export var control_point_size: float = 0.08:
	set(v):
		control_point_size = v
		_resize_control_points()

@export var show_tangents: bool = true:
	set(v):
		show_tangents = v
		_rebuild_curve()

@export var closed_curve: bool = false:
	set(v):
		closed_curve = v
		_rebuild_curve()

@export var initial_points: Array[Vector3] = [
	Vector3(-1, 0.5, 0),
	Vector3(-0.3, 1.2, 0),
	Vector3(0.3, 0.3, 0),
	Vector3(1, 0.8, 0)
]:
	set(v):
		initial_points = v
		_initialize_control_points()

var _control_points: Array[Node3D] = []
var _curve_mesh_instance: MeshInstance3D
var _tangent_mesh_instance: MeshInstance3D
var _curve_mesh: ImmediateMesh
var _tangent_mesh: ImmediateMesh
var _is_initialized: bool = false

func _ready() -> void:
	_setup_curve_rendering()
	_initialize_control_points()
	_is_initialized = true

func _setup_curve_rendering() -> void:
	# Curve line
	_curve_mesh = ImmediateMesh.new()
	_curve_mesh_instance = MeshInstance3D.new()
	_curve_mesh_instance.name = "CurveLine"
	_curve_mesh_instance.mesh = _curve_mesh
	
	var curve_mat = StandardMaterial3D.new()
	curve_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	curve_mat.albedo_color = curve_color
	curve_mat.emission_enabled = true
	curve_mat.emission = curve_color
	curve_mat.emission_energy_multiplier = 1.2
	_curve_mesh_instance.material_override = curve_mat
	add_child(_curve_mesh_instance)
	
	# Tangent lines (for Bezier)
	_tangent_mesh = ImmediateMesh.new()
	_tangent_mesh_instance = MeshInstance3D.new()
	_tangent_mesh_instance.name = "TangentLines"
	_tangent_mesh_instance.mesh = _tangent_mesh
	
	var tangent_mat = StandardMaterial3D.new()
	tangent_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tangent_mat.albedo_color = tangent_color
	tangent_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_tangent_mesh_instance.material_override = tangent_mat
	add_child(_tangent_mesh_instance)

func _initialize_control_points() -> void:
	# Clear existing
	for cp in _control_points:
		if is_instance_valid(cp):
			cp.queue_free()
	_control_points.clear()
	
	# Create new control points
	for i in range(initial_points.size()):
		var cp = _create_control_point(i, initial_points[i])
		_control_points.append(cp)
	
	if _is_initialized:
		_rebuild_curve()

func _create_control_point(index: int, pos: Vector3) -> Node3D:
	var cp_scene = _create_grabbable_point()
	cp_scene.name = "ControlPoint_%d" % index
	cp_scene.position = pos
	cp_scene.set_meta("cp_index", index)
	add_child(cp_scene)
	
	# Connect to movement
	if cp_scene.has_signal("position_changed"):
		cp_scene.position_changed.connect(_on_control_point_moved.bind(index))
	
	return cp_scene

func _create_grabbable_point() -> Node3D:
	# Try to load XR pickable, fallback to simple sphere
	var pickable_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	
	var point: Node3D
	if pickable_scene:
		point = pickable_scene.instantiate()
		point.set_script(load("res://commons/primitives/curves/curve_control_point.gd"))
	else:
		point = Node3D.new()
	
	# Add visual
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PointMesh"
	var sphere = SphereMesh.new()
	sphere.radius = control_point_size
	sphere.height = control_point_size * 2
	mesh_instance.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = control_point_color
	mat.emission_enabled = true
	mat.emission = control_point_color
	mat.emission_energy_multiplier = 0.8
	mesh_instance.material_override = mat
	
	point.add_child(mesh_instance)
	
	# Add collision for picking
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape"
	var shape = SphereShape3D.new()
	shape.radius = control_point_size * 1.5
	collision.shape = shape
	point.add_child(collision)
	
	return point

func _on_control_point_moved(_index: int) -> void:
	_rebuild_curve()
	curve_changed.emit(get_control_positions())

func _process(_delta: float) -> void:
	# Check if any control point moved (for non-signal-based movement)
	var changed = false
	for i in range(_control_points.size()):
		if _control_points[i].has_meta("last_position"):
			if _control_points[i].position != _control_points[i].get_meta("last_position"):
				changed = true
		_control_points[i].set_meta("last_position", _control_points[i].position)
	
	if changed:
		_rebuild_curve()
		curve_changed.emit(get_control_positions())

func _rebuild_curve() -> void:
	if not _curve_mesh or _control_points.size() < 2:
		return
	
	var positions = get_control_positions()
	var curve_points = _calculate_curve_points(positions)
	
	# Draw curve
	_curve_mesh.clear_surfaces()
	_curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in curve_points:
		_curve_mesh.surface_add_vertex(p)
	_curve_mesh.surface_end()
	
	# Draw tangent handles (for Bezier)
	_tangent_mesh.clear_surfaces()
	if show_tangents and curve_type == CurveType.BEZIER and positions.size() >= 4:
		_tangent_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		# Draw lines between control points to show Bezier structure
		for i in range(0, positions.size() - 1, 3):
			# P0 to P1 (first tangent)
			if i + 1 < positions.size():
				_tangent_mesh.surface_add_vertex(positions[i])
				_tangent_mesh.surface_add_vertex(positions[i + 1])
			# P2 to P3 (second tangent)
			if i + 2 < positions.size() and i + 3 < positions.size():
				_tangent_mesh.surface_add_vertex(positions[i + 2])
				_tangent_mesh.surface_add_vertex(positions[i + 3])
		_tangent_mesh.surface_end()

func _calculate_curve_points(control_positions: Array[Vector3]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	
	match curve_type:
		CurveType.LINEAR:
			result = control_positions.duplicate()
		
		CurveType.BEZIER:
			result = _calculate_bezier(control_positions)
		
		CurveType.CATMULL_ROM:
			result = _calculate_catmull_rom(control_positions)
	
	return result

func _calculate_bezier(points: Array[Vector3]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	
	if points.size() < 4:
		return points.duplicate() as Array[Vector3]
	
	# Process cubic Bezier segments (4 points each)
	var i = 0
	while i + 3 < points.size():
		var p0 = points[i]
		var p1 = points[i + 1]
		var p2 = points[i + 2]
		var p3 = points[i + 3]
		
		for s in range(curve_segments + 1):
			var t = float(s) / curve_segments
			var point = _cubic_bezier(p0, p1, p2, p3, t)
			result.append(point)
		
		i += 3  # Move to next segment (sharing endpoint)
	
	return result

func _cubic_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	var uuu = uu * u
	var ttt = tt * t
	
	var point = uuu * p0  # (1-t)^3 * P0
	point += 3 * uu * t * p1  # 3(1-t)^2 * t * P1
	point += 3 * u * tt * p2  # 3(1-t) * t^2 * P2
	point += ttt * p3  # t^3 * P3
	
	return point

func _calculate_catmull_rom(points: Array[Vector3]) -> Array[Vector3]:
	var result: Array[Vector3] = []
	
	if points.size() < 2:
		return points.duplicate() as Array[Vector3]
	
	# Add phantom points for open curve
	var extended = points.duplicate() as Array[Vector3]
	if not closed_curve:
		# Mirror first and last points
		extended.insert(0, points[0] * 2 - points[1])
		extended.append(points[-1] * 2 - points[-2])
	
	# Generate curve through each segment
	for i in range(1, extended.size() - 2):
		var p0 = extended[i - 1]
		var p1 = extended[i]
		var p2 = extended[i + 1]
		var p3 = extended[i + 2]
		
		for s in range(curve_segments):
			var t = float(s) / curve_segments
			var point = _catmull_rom_point(p0, p1, p2, p3, t)
			result.append(point)
	
	# Add final point
	if extended.size() >= 2:
		result.append(extended[-2])
	
	return result

func _catmull_rom_point(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 = t * t
	var t3 = t2 * t
	
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

func _update_materials() -> void:
	if _curve_mesh_instance and _curve_mesh_instance.material_override:
		_curve_mesh_instance.material_override.albedo_color = curve_color
		_curve_mesh_instance.material_override.emission = curve_color
	
	if _tangent_mesh_instance and _tangent_mesh_instance.material_override:
		_tangent_mesh_instance.material_override.albedo_color = tangent_color
	
	for cp in _control_points:
		var mesh = cp.get_node_or_null("PointMesh")
		if mesh and mesh.material_override:
			mesh.material_override.albedo_color = control_point_color
			mesh.material_override.emission = control_point_color

func _resize_control_points() -> void:
	for cp in _control_points:
		var mesh = cp.get_node_or_null("PointMesh")
		if mesh and mesh.mesh is SphereMesh:
			mesh.mesh.radius = control_point_size
			mesh.mesh.height = control_point_size * 2
		var collision = cp.get_node_or_null("CollisionShape")
		if collision and collision.shape is SphereShape3D:
			collision.shape.radius = control_point_size * 1.5

# Public API

func get_control_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for cp in _control_points:
		positions.append(cp.position)
	return positions

func set_control_positions(positions: Array[Vector3]) -> void:
	for i in range(min(positions.size(), _control_points.size())):
		_control_points[i].position = positions[i]
	_rebuild_curve()

func add_control_point(pos: Vector3) -> void:
	var index = _control_points.size()
	var cp = _create_control_point(index, pos)
	_control_points.append(cp)
	_rebuild_curve()

func remove_last_control_point() -> void:
	if _control_points.size() > 2:
		var cp = _control_points.pop_back()
		cp.queue_free()
		_rebuild_curve()

func get_point_on_curve(t: float) -> Vector3:
	"""Get a point on the curve at parameter t (0-1)"""
	var positions = get_control_positions()
	var curve_points = _calculate_curve_points(positions)
	
	if curve_points.is_empty():
		return Vector3.ZERO
	
	var index = int(t * (curve_points.size() - 1))
	index = clamp(index, 0, curve_points.size() - 1)
	return curve_points[index]

func get_curve_length() -> float:
	"""Approximate curve length"""
	var positions = get_control_positions()
	var curve_points = _calculate_curve_points(positions)
	
	var length = 0.0
	for i in range(1, curve_points.size()):
		length += curve_points[i].distance_to(curve_points[i - 1])
	return length

func save_to_trace_data() -> void:
	"""Save current curve to TraceData singleton"""
	if has_node("/root/TraceData"):
		var trace_data = get_node("/root/TraceData")
		var positions = get_control_positions()
		var curve_points = _calculate_curve_points(positions)
		# Convert to regular Array for TraceData
		var points_array: Array = []
		for p in curve_points:
			points_array.append(p)
		trace_data.add_trace(points_array)
