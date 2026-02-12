extends Node3D

@export var major_radius: float = 4.0
@export var tube_radius: float = 1.2
@export var height: float = 12.0
@export var turns: float = 2.5
@export_range(16, 400, 1) var segments: int = 150
@export_range(6, 64, 1) var tube_segments: int = 20
@export var generate_collision: bool = true
@export var auto_rotate: bool = false
@export var rotation_speed: float = 0.2

@export var pad_count: int = 3
@export var pad_radius: float = 0.6
@export var pad_height: float = 0.12
@export var pad_offset: float = 0.75
@export var pad_color: Color = Color(0.35, 0.85, 1.0, 0.8)
@export var rider_group: StringName = "players"
@export var ride_speed: float = 12.0
@export var rider_height_offset: float = 0.35
@export var exit_offset: Vector3 = Vector3(0, 0.5, 0)

@onready var static_body: StaticBody3D = _ensure_static_body()
@onready var mesh_instance: MeshInstance3D = _ensure_mesh_instance()
@onready var collision_shape: CollisionShape3D = _ensure_collision_shape()

var path_points := PackedVector3Array()
var path_normals := PackedVector3Array()
var path_binormals := PackedVector3Array()
var path_distances := PackedFloat32Array()
var ride_length: float = 0.0

var entry_pads: Array[Area3D] = []
var active_rider: Node3D = null
var ride_distance: float = 0.0
var saved_rider_processing: Dictionary = {}

func _ready():
	generate_slide()
	_update_process_state()
	set_physics_process(false)

func _update_process_state():
	set_process(auto_rotate and rotation_speed != 0.0)

func _process(delta):
	if auto_rotate:
		rotate_y(rotation_speed * delta)

func _physics_process(delta):
	if not active_rider or ride_length <= 0.0:
		return
	ride_distance += ride_speed * delta
	var finished: bool = ride_distance >= ride_length
	var clamped_distance: float = clamp(ride_distance, 0.0, ride_length)
	var frame: Dictionary = _sample_frame(clamped_distance)
	var frame_point: Vector3 = frame["point"]
	var frame_normal: Vector3 = frame["normal"]
	var frame_tangent: Vector3 = frame["tangent"]
	var local_point: Vector3 = frame_point + frame_normal * rider_height_offset
	var global_origin: Vector3 = to_global(local_point)
	var global_tangent: Vector3 = (global_transform.basis * frame_tangent).normalized()
	var global_normal: Vector3 = (global_transform.basis * frame_normal).normalized()
	var global_binormal: Vector3 = global_tangent.cross(global_normal).normalized()
	global_normal = global_binormal.cross(global_tangent).normalized()
	var rider_basis := Basis(global_tangent, global_normal, global_binormal).orthonormalized()
	active_rider.global_transform = Transform3D(rider_basis, global_origin)
	if finished:
		var exit_point: Vector3 = path_points[path_points.size() - 1] + exit_offset
		active_rider.global_position = to_global(exit_point)
		_stop_ride()

func generate_slide():
	_clear_entry_pads()
	path_points = PackedVector3Array()
	path_normals = PackedVector3Array()
	path_binormals = PackedVector3Array()
	path_distances = PackedFloat32Array()
	ride_length = 0.0

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var column_count := tube_segments + 1
	var row_count := segments + 1

	for i in range(row_count):
		var t: float = i / float(segments)
		var u: float = t * turns * TAU
		var center: Vector3 = Vector3(
			major_radius * cos(u),
			height * (1.0 - t),
			major_radius * sin(u)
		)

		var tangent: Vector3 = Vector3(
			-major_radius * sin(u),
			-height * turns * TAU / float(segments),
			major_radius * cos(u)
		).normalized()

		var normal: Vector3 = Vector3(cos(u), 0.0, sin(u)).normalized()
		var binormal: Vector3 = tangent.cross(normal).normalized()

		path_points.append(center)
		path_normals.append(normal)
		path_binormals.append(binormal)

		for j in range(column_count):
			var v: float = j / float(tube_segments) * TAU
			var offset: Vector3 = (cos(v) * normal + sin(v) * binormal) * tube_radius
			var vertex: Vector3 = center + offset
			st.set_uv(Vector2(t, j / float(tube_segments)))
			st.add_vertex(vertex)

	for i in range(segments):
		for j in range(tube_segments):
			var a := i * column_count + j
			var b := a + column_count

			st.add_index(a)
			st.add_index(b)
			st.add_index(a + 1)

			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(b + 1)

	st.generate_normals()
	st.generate_tangents()
	st.index()

	var mesh: ArrayMesh = st.commit()
	if mesh_instance:
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _build_water_material()

	if generate_collision and mesh:
		_update_collision_shape(mesh)
	elif collision_shape:
		collision_shape.shape = null
		collision_shape.disabled = true

	_bake_path_distances()
	_build_entry_pads()

func _bake_path_distances() -> void:
	if path_points.is_empty():
		path_distances = PackedFloat32Array()
		ride_length = 0.0
		return
	path_distances = PackedFloat32Array()
	path_distances.resize(path_points.size())
	path_distances[0] = 0.0
	var accum: float = 0.0
	for i in range(1, path_points.size()):
		accum += path_points[i - 1].distance_to(path_points[i])
		path_distances[i] = accum
	ride_length = accum

func _ensure_mesh_instance() -> MeshInstance3D:
	var node := get_node_or_null("SlideMesh") as MeshInstance3D
	if not node:
		node = MeshInstance3D.new()
		node.name = "SlideMesh"
		add_child(node)
	return node

func _ensure_static_body() -> StaticBody3D:
	var body := get_node_or_null("SlideStaticBody") as StaticBody3D
	if not body:
		body = StaticBody3D.new()
		body.name = "SlideStaticBody"
		add_child(body)
	return body

func _ensure_collision_shape() -> CollisionShape3D:
	if not static_body:
		return null
	var node := static_body.get_node_or_null("SlideCollision") as CollisionShape3D
	if not node:
		node = CollisionShape3D.new()
		node.name = "SlideCollision"
		node.disabled = true
		static_body.add_child(node)
	return node

func _build_water_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.5, 0.9, 0.6)
	material.metallic = 0.1
	material.roughness = 0.1
	material.specular = 0.8
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.subsurface_scattering_enabled = true
	material.subsurface_scattering_color = Color(0.2, 0.7, 1.0)
	return material

func _build_pad_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pad_color
	mat.metallic = 0.05
	mat.roughness = 0.25
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = pad_color * 0.6
	return mat

func _build_pad_mesh() -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments_count: int = 24
	for i in range(segments_count + 1):
		var angle: float = i / float(segments_count) * TAU
		var x: float = cos(angle) * pad_radius
		var z: float = sin(angle) * pad_radius
		st.add_vertex(Vector3(x, pad_height * 0.5, z))
		st.add_vertex(Vector3(x, -pad_height * 0.5, z))
	if segments_count >= 2:
		for i in range(0, (segments_count) * 2, 2):
			var next: int = (i + 2) % (segments_count * 2)
			st.add_index(i)
			st.add_index(i + 1)
			st.add_index(next)
			st.add_index(next)
			st.add_index(i + 1)
			st.add_index(next + 1)
	st.generate_normals()
	mesh = st.commit()
	return mesh

func _clear_entry_pads() -> void:
	for pad in entry_pads:
		if pad and is_instance_valid(pad):
			pad.queue_free()
	entry_pads.clear()

func _build_entry_pads() -> void:
	if pad_count <= 0 or path_points.size() == 0:
		return
	var step: int = max(1, path_points.size() / max(1, pad_count))
	for i in range(pad_count):
		var idx: int = clamp(i * step, 0, path_points.size() - 1)
		var pad: Area3D = Area3D.new()
		pad.name = "EntryPad_%d" % i
		pad.monitoring = true
		pad.monitorable = true
		pad.body_entered.connect(_on_entry_pad_body_entered.bind(pad))

		var pad_mesh: MeshInstance3D = MeshInstance3D.new()
		pad_mesh.mesh = _build_pad_mesh()
		pad_mesh.material_override = _build_pad_material()
		pad.add_child(pad_mesh)

		var pad_shape: CollisionShape3D = CollisionShape3D.new()
		var cyl: CylinderShape3D = CylinderShape3D.new()
		cyl.radius = pad_radius
		cyl.height = pad_height
		pad_shape.shape = cyl
		pad.add_child(pad_shape)

		var pad_pos: Vector3 = path_points[idx]
		if idx < path_normals.size():
			pad_pos += path_normals[idx] * (tube_radius + pad_offset)
		pad_pos += Vector3.UP * (pad_height + 0.05)
		# Build local transform before adding to tree; avoid global transforms/look_at() pre-tree.
		var to_slide: Vector3 = path_points[idx] - pad_pos
		pad.position = pad_pos
		if to_slide.length_squared() > 0.000001:
			var forward := to_slide.normalized()
			var up := Vector3.UP
			if abs(forward.dot(up)) > 0.98:
				up = Vector3.FORWARD
			pad.basis = Basis.looking_at(forward, up)
		add_child(pad)
		entry_pads.append(pad)

func _on_entry_pad_body_entered(body: Node3D, _pad: Area3D) -> void:
	if active_rider:
		return
	if not is_instance_valid(body):
		return
	if rider_group != StringName("") and not body.is_in_group(rider_group):
		return
	_start_ride(body)

func _start_ride(body: Node3D) -> void:
	if path_points.size() < 2:
		return
	active_rider = body
	ride_distance = 0.0
	saved_rider_processing = {
		"process": body.is_processing(),
		"physics": body.is_physics_processing()
	}
	body.set_process(false)
	body.set_physics_process(false)
	set_physics_process(true)

func _stop_ride() -> void:
	if not active_rider:
		return
	if saved_rider_processing.has("process"):
		active_rider.set_process(saved_rider_processing["process"])
	if saved_rider_processing.has("physics"):
		active_rider.set_physics_process(saved_rider_processing["physics"])
	active_rider = null
	saved_rider_processing.clear()
	set_physics_process(false)

func _sample_frame(distance_along: float) -> Dictionary:
	if path_points.is_empty():
		return {
			"point": Vector3.ZERO,
			"tangent": Vector3.FORWARD,
			"normal": Vector3.UP,
			"binormal": Vector3.RIGHT
		}
	var idx: int = _distance_to_index(distance_along)
	if idx <= 0:
		return {
			"point": path_points[0],
			"tangent": (path_points[1] - path_points[0]).normalized(),
			"normal": path_normals[0],
			"binormal": path_binormals[0]
		}
	var prev_idx: int = idx - 1
	var segment_len: float = max(0.001, path_distances[idx] - path_distances[prev_idx])
	var alpha: float = (distance_along - path_distances[prev_idx]) / segment_len
	var point: Vector3 = path_points[prev_idx].lerp(path_points[idx], alpha)
	var normal: Vector3 = path_normals[prev_idx].lerp(path_normals[idx], alpha).normalized()
	var binormal: Vector3 = path_binormals[prev_idx].lerp(path_binormals[idx], alpha).normalized()
	var tangent: Vector3 = (path_points[idx] - path_points[prev_idx]).normalized()
	binormal = tangent.cross(normal).normalized()
	normal = binormal.cross(tangent).normalized()
	return {
		"point": point,
		"tangent": tangent,
		"normal": normal,
		"binormal": binormal
	}

func _distance_to_index(distance_along: float) -> int:
	if path_distances.is_empty():
		return 0
	for i in range(1, path_distances.size()):
		if distance_along <= path_distances[i]:
			return i
	return path_distances.size() - 1

func _update_collision_shape(mesh: ArrayMesh) -> void:
	if not collision_shape:
		return
	if mesh.get_surface_count() == 0:
		return
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
	if vertices.is_empty():
		return
	if indices.is_empty():
		indices = PackedInt32Array()
		indices.resize(vertices.size())
		for i in range(indices.size()):
			indices[i] = i
	var faces: PackedVector3Array = PackedVector3Array()
	var triangle_count: int = indices.size() / 3
	for i in range(triangle_count):
		var base: int = i * 3
		var a := indices[base]
		var b := indices[base + 1]
		var c := indices[base + 2]
		if a < 0 or b < 0 or c < 0:
			continue
		if a >= vertices.size() or b >= vertices.size() or c >= vertices.size():
			continue
		var va: Vector3 = vertices[a]
		var vb: Vector3 = vertices[b]
		var vc: Vector3 = vertices[c]
		var normal: Vector3 = (vb - va).cross(vc - va).normalized()
		if normal.y > 0.15:
			continue
		faces.append(va)
		faces.append(vb)
		faces.append(vc)
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	if faces.is_empty():
		collision_shape.shape = null
		collision_shape.disabled = true
	else:
		shape.set_faces(faces)
		collision_shape.shape = shape
		collision_shape.disabled = false
