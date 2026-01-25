# GlassRackController.gd - Modular Glass Apparatus System
# Like the audio rack but for laboratory glassware
# JSON config defines segments, connections, and layout
extends Node3D
class_name GlassRackController

signal apparatus_built
signal liquid_flow_started
signal liquid_flow_stopped

@export_file("*.json") var config_path: String = ""
@export var auto_build: bool = true
@export var rack_scale: float = 1.0

@export_group("Glass Material")
@export var glass_color: Color = Color(0.85, 0.92, 1.0, 0.25)
@export var glass_roughness: float = 0.0
@export var use_refraction: bool = true

@export_group("Liquid")
@export var liquid_color: Color = Color(0.2, 0.8, 0.4, 0.6)
@export var show_liquid: bool = true
@export var liquid_flow_speed: float = 1.0

# Segment scenes (procedurally generated)
const SEGMENT_SCRIPTS = {
	"straight": "res://commons/glass_rack/segments/glass_straight.gd",
	"spiral": "res://commons/glass_rack/segments/glass_spiral.gd",
	"wobbly": "res://commons/glass_rack/segments/glass_wobbly.gd",
	"flask": "res://commons/glass_rack/segments/glass_flask.gd",
	"junction": "res://commons/glass_rack/segments/glass_junction.gd",
	"corner": "res://commons/glass_rack/segments/glass_corner.gd",
}

var config_data: Dictionary = {}
var active_segments: Dictionary = {}  # id -> node
var glass_material: StandardMaterial3D
var liquid_material: StandardMaterial3D

# Turtle state for path-based building
var cursor_pos: Vector3 = Vector3.ZERO
var cursor_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	_setup_materials()
	if auto_build and config_path != "":
		load_config(config_path)

func _setup_materials() -> void:
	# Glass material
	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = glass_color
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.metallic = 0.0
	glass_material.roughness = glass_roughness
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if use_refraction:
		glass_material.refraction_enabled = true
		glass_material.refraction_scale = 0.05

	# Liquid material (glowing)
	liquid_material = StandardMaterial3D.new()
	liquid_material.albedo_color = liquid_color
	liquid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_material.emission_enabled = true
	liquid_material.emission = liquid_color
	liquid_material.emission_energy_multiplier = 0.5

func load_config(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("GlassRackController: Failed to open config: %s" % path)
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("GlassRackController: JSON parse error: %s" % json.get_error_message())
		return

	config_data = json.data
	build_apparatus()

func load_config_from_dict(data: Dictionary) -> void:
	config_data = data
	build_apparatus()

func build_apparatus() -> void:
	# Clear existing
	_clear_apparatus()

	if config_data.is_empty():
		return

	# Reset cursor
	cursor_pos = Vector3.ZERO
	cursor_basis = Basis.IDENTITY

	# Get rack info
	var rack_info = config_data.get("rack_info", {})
	var layout = config_data.get("layout", {})

	# Build using either path code or segment definitions
	if config_data.has("path"):
		_build_from_path(config_data["path"])
	elif config_data.has("segments"):
		_build_from_segments(config_data["segments"])

	# Apply layout settings
	if layout.has("position"):
		var pos = layout["position"]
		position = Vector3(pos[0], pos[1], pos[2]) if pos is Array else Vector3.ZERO

	apparatus_built.emit()

func _build_from_path(path_code: String) -> void:
	# Turtle-graphics style: "f,f,spiral,l,f,flask,r,f,wobbly"
	var commands = path_code.split(",")
	var segment_length = config_data.get("layout", {}).get("segment_length", 0.3) * rack_scale

	for i in range(commands.size()):
		var cmd = commands[i].strip_edges().to_lower()
		var segment_id = "seg_%d" % i

		match cmd:
			"f", "forward", "straight":
				_add_segment(segment_id, "straight", {"length": segment_length})
			"spiral", "coil":
				_add_segment(segment_id, "spiral", {"height": segment_length * 2})
			"wobbly", "wavy":
				_add_segment(segment_id, "wobbly", {"length": segment_length * 2})
			"flask", "bulb":
				_add_segment(segment_id, "flask", {"radius": segment_length * 0.5})
			"junction", "t", "tee":
				_add_segment(segment_id, "junction", {})
			"l", "left":
				_add_corner(segment_id, Vector3.UP, 90)
			"r", "right":
				_add_corner(segment_id, Vector3.UP, -90)
			"u", "up":
				_add_corner(segment_id, Vector3.RIGHT, 90)
			"d", "down":
				_add_corner(segment_id, Vector3.RIGHT, -90)

func _build_from_segments(segments: Array) -> void:
	# Grid-based or explicit position segments
	for seg_def in segments:
		var seg_id = seg_def.get("id", "seg_%d" % active_segments.size())
		var seg_type = seg_def.get("type", "straight")
		var params = seg_def.get("params", {})

		# Position modes
		if seg_def.has("position"):
			var pos = seg_def["position"]
			cursor_pos = Vector3(pos[0], pos[1], pos[2]) * rack_scale

		if seg_def.has("rotation"):
			var rot = seg_def["rotation"]
			cursor_basis = Basis.from_euler(Vector3(
				deg_to_rad(rot[0]) if rot.size() > 0 else 0,
				deg_to_rad(rot[1]) if rot.size() > 1 else 0,
				deg_to_rad(rot[2]) if rot.size() > 2 else 0
			))

		_add_segment(seg_id, seg_type, params)

		# Connect to previous if specified
		if seg_def.has("connect_to"):
			_connect_segments(seg_def["connect_to"], seg_id)

func _add_segment(id: String, type: String, params: Dictionary) -> Node3D:
	var segment: Node3D

	match type:
		"straight":
			segment = _create_straight_segment(params)
		"spiral":
			segment = _create_spiral_segment(params)
		"wobbly":
			segment = _create_wobbly_segment(params)
		"flask":
			segment = _create_flask_segment(params)
		"junction":
			segment = _create_junction_segment(params)
		"corner":
			segment = _create_corner_segment(params)
		_:
			push_warning("GlassRackController: Unknown segment type: %s" % type)
			return null

	if segment:
		segment.name = id
		segment.position = cursor_pos
		segment.transform.basis = cursor_basis
		add_child(segment)
		active_segments[id] = segment

		# Advance cursor based on segment
		_advance_cursor(type, params)

	return segment

func _add_corner(id: String, axis: Vector3, angle_deg: float) -> void:
	var segment = _create_corner_segment({"axis": axis, "angle": angle_deg})
	if segment:
		segment.name = id
		segment.position = cursor_pos
		segment.transform.basis = cursor_basis
		add_child(segment)
		active_segments[id] = segment

		# Update cursor for corner
		var radius = config_data.get("layout", {}).get("segment_length", 0.3) * rack_scale
		var forward = cursor_basis.z
		var up = cursor_basis.y
		var right = cursor_basis.x

		if axis == Vector3.UP:
			if angle_deg > 0:  # Left
				cursor_pos += forward * radius - right * radius
				cursor_basis = cursor_basis.rotated(cursor_basis.y, deg_to_rad(90))
			else:  # Right
				cursor_pos += forward * radius + right * radius
				cursor_basis = cursor_basis.rotated(cursor_basis.y, deg_to_rad(-90))
		elif axis == Vector3.RIGHT:
			if angle_deg > 0:  # Up
				cursor_pos += forward * radius + up * radius
				cursor_basis = cursor_basis.rotated(cursor_basis.x, deg_to_rad(-90))
			else:  # Down
				cursor_pos += forward * radius - up * radius
				cursor_basis = cursor_basis.rotated(cursor_basis.x, deg_to_rad(90))

func _advance_cursor(type: String, params: Dictionary) -> void:
	var segment_length = config_data.get("layout", {}).get("segment_length", 0.3) * rack_scale
	var forward = cursor_basis.z

	match type:
		"straight":
			var length = params.get("length", segment_length)
			cursor_pos += forward * length
		"spiral":
			var height = params.get("height", segment_length * 2)
			cursor_pos += Vector3.UP * height
		"wobbly":
			var length = params.get("length", segment_length * 2)
			cursor_pos += forward * length
		"flask":
			var radius = params.get("radius", segment_length * 0.5)
			cursor_pos += forward * radius * 2
		"junction":
			cursor_pos += forward * segment_length

# =============================================================================
# SEGMENT CREATION
# =============================================================================

func _create_straight_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.3) * rack_scale
	var radius = params.get("radius", 0.02) * rack_scale

	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = glass_material
	mesh_instance.rotation.x = PI / 2  # Align with Z forward
	mesh_instance.position.z = length / 2
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid = MeshInstance3D.new()
		var liquid_cyl = CylinderMesh.new()
		liquid_cyl.top_radius = radius * 0.7
		liquid_cyl.bottom_radius = radius * 0.7
		liquid_cyl.height = length
		liquid.mesh = liquid_cyl
		liquid.material_override = liquid_material
		liquid.rotation.x = PI / 2
		liquid.position.z = length / 2
		group.add_child(liquid)

	return group

func _create_spiral_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var height = params.get("height", 0.5) * rack_scale
	var spiral_radius = params.get("spiral_radius", 0.1) * rack_scale
	var tube_radius = params.get("tube_radius", 0.015) * rack_scale
	var turns = params.get("turns", 4)
	var resolution = params.get("resolution", 24)

	var mesh = _generate_spiral_mesh(height, spiral_radius, tube_radius, turns, resolution)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_spiral_mesh(height, spiral_radius, tube_radius * 0.7, turns, resolution)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	return group

func _create_wobbly_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", 0.5) * rack_scale
	var tube_radius = params.get("tube_radius", 0.02) * rack_scale
	var amplitude = params.get("amplitude", 0.05) * rack_scale
	var frequency = params.get("frequency", 3.0)

	var mesh = _generate_wobbly_mesh(length, tube_radius, amplitude, frequency)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_wobbly_mesh(length, tube_radius * 0.7, amplitude, frequency)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	return group

func _create_flask_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var flask_radius = params.get("radius", 0.08) * rack_scale
	var neck_radius = params.get("neck_radius", 0.02) * rack_scale
	var neck_length = params.get("neck_length", 0.1) * rack_scale

	# Flask body (sphere)
	var body = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = flask_radius
	sphere.height = flask_radius * 2
	body.mesh = sphere
	body.material_override = glass_material
	body.position.z = flask_radius
	group.add_child(body)

	# Flask neck (cylinder)
	var neck = MeshInstance3D.new()
	var neck_cyl = CylinderMesh.new()
	neck_cyl.top_radius = neck_radius
	neck_cyl.bottom_radius = neck_radius * 1.5
	neck_cyl.height = neck_length
	neck.mesh = neck_cyl
	neck.material_override = glass_material
	neck.rotation.x = PI / 2
	neck.position.z = flask_radius * 2 + neck_length / 2
	group.add_child(neck)

	if show_liquid:
		var liquid_body = MeshInstance3D.new()
		var liquid_sphere = SphereMesh.new()
		liquid_sphere.radius = flask_radius * 0.8
		liquid_sphere.height = flask_radius * 1.6
		liquid_body.mesh = liquid_sphere
		liquid_body.material_override = liquid_material
		liquid_body.position = body.position
		group.add_child(liquid_body)

	return group

func _create_junction_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var radius = params.get("radius", 0.02) * rack_scale
	var length = params.get("length", 0.15) * rack_scale

	# Main tube (forward)
	var main_tube = MeshInstance3D.new()
	var main_cyl = CylinderMesh.new()
	main_cyl.top_radius = radius
	main_cyl.bottom_radius = radius
	main_cyl.height = length
	main_tube.mesh = main_cyl
	main_tube.material_override = glass_material
	main_tube.rotation.x = PI / 2
	main_tube.position.z = length / 2
	group.add_child(main_tube)

	# Branch tube (right)
	var branch_tube = MeshInstance3D.new()
	branch_tube.mesh = main_cyl.duplicate()
	branch_tube.material_override = glass_material
	branch_tube.rotation.z = PI / 2
	branch_tube.position.x = length / 2
	branch_tube.position.z = length / 2
	group.add_child(branch_tube)

	# Junction sphere
	var junction_sphere = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius * 1.5
	junction_sphere.mesh = sphere
	junction_sphere.material_override = glass_material
	junction_sphere.position.z = length / 2
	group.add_child(junction_sphere)

	return group

func _create_corner_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var radius = params.get("radius", 0.02) * rack_scale
	var corner_radius = params.get("corner_radius", 0.1) * rack_scale

	var mesh = _generate_corner_mesh(radius, corner_radius)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = glass_material
	group.add_child(mesh_instance)

	if show_liquid:
		var liquid_mesh = _generate_corner_mesh(radius * 0.7, corner_radius)
		var liquid_instance = MeshInstance3D.new()
		liquid_instance.mesh = liquid_mesh
		liquid_instance.material_override = liquid_material
		group.add_child(liquid_instance)

	return group

# =============================================================================
# MESH GENERATION
# =============================================================================

func _generate_spiral_mesh(height: float, spiral_radius: float, tube_radius: float, turns: int, resolution: int) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var total_points = resolution * turns
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(total_points + 1):
		var t = float(i) / total_points
		var angle = t * TAU * turns

		var center = Vector3(
			cos(angle) * spiral_radius,
			t * height,
			sin(angle) * spiral_radius
		)

		var tangent = Vector3(
			-sin(angle) * spiral_radius,
			height / total_points,
			cos(angle) * spiral_radius
		).normalized()

		var binormal = tangent.cross(Vector3.UP).normalized()
		var normal = binormal.cross(tangent).normalized()

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = normal * cos(tube_angle) * tube_radius + binormal * sin(tube_angle) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _generate_wobbly_mesh(length: float, tube_radius: float, amplitude: float, frequency: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var resolution = 48
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(resolution + 1):
		var t = float(i) / resolution
		var z = t * length

		var center = Vector3(
			sin(t * TAU * frequency) * amplitude,
			cos(t * TAU * frequency * 0.7) * amplitude * 0.5,
			z
		)

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = Vector3(cos(tube_angle), sin(tube_angle), 0) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _generate_corner_mesh(tube_radius: float, corner_radius: float) -> ArrayMesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var resolution = 16
	var tube_sides = 8
	var all_rings: Array = []

	for i in range(resolution + 1):
		var t = float(i) / resolution
		var angle = t * PI / 2

		var center = Vector3(
			corner_radius * (1.0 - cos(angle)),
			0,
			corner_radius * sin(angle)
		)

		var tangent = Vector3(sin(angle), 0, cos(angle)).normalized()
		var binormal = Vector3(0, 1, 0)
		var normal = binormal.cross(tangent).normalized()

		var ring: Array = []
		for j in range(tube_sides):
			var tube_angle = TAU * j / tube_sides
			var offset = normal * cos(tube_angle) * tube_radius + binormal * sin(tube_angle) * tube_radius
			ring.append(center + offset)
		all_rings.append(ring)

	_add_tube_faces(surface_tool, all_rings, tube_sides)
	surface_tool.generate_normals()
	return surface_tool.commit()

func _add_tube_faces(st: SurfaceTool, rings: Array, sides: int) -> void:
	for i in range(rings.size() - 1):
		for j in range(sides):
			var j_next = (j + 1) % sides
			var v0 = rings[i][j]
			var v1 = rings[i][j_next]
			var v2 = rings[i + 1][j_next]
			var v3 = rings[i + 1][j]

			var face_normal = (v1 - v0).cross(v3 - v0).normalized()

			st.set_normal(face_normal)
			st.add_vertex(v0)
			st.set_normal(face_normal)
			st.add_vertex(v1)
			st.set_normal(face_normal)
			st.add_vertex(v2)

			st.set_normal(face_normal)
			st.add_vertex(v0)
			st.set_normal(face_normal)
			st.add_vertex(v2)
			st.set_normal(face_normal)
			st.add_vertex(v3)

func _connect_segments(_from_id: String, _to_id: String) -> void:
	# Future: Add connecting tube between segments
	pass

func _clear_apparatus() -> void:
	for child in get_children():
		child.queue_free()
	active_segments.clear()

# =============================================================================
# LIQUID ANIMATION
# =============================================================================

func start_liquid_flow() -> void:
	liquid_flow_started.emit()
	# Future: Animate liquid through segments

func stop_liquid_flow() -> void:
	liquid_flow_stopped.emit()

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	# Called by GridInteractablesComponent when placed on map
	# config format: {"config": "simple_tube"} from "GlassRack#config:simple_tube"
	if config.has("config"):
		var config_name = config["config"]
		var config_file = "res://commons/glass_rack/configs/%s.json" % config_name
		load_config(config_file)

	# Also support direct parameters
	if config.has("glass_color") and config["glass_color"] is Array:
		var c = config["glass_color"]
		glass_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.25)
		_setup_materials()

	if config.has("liquid_color") and config["liquid_color"] is Array:
		var c = config["liquid_color"]
		liquid_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 0.6)
		_setup_materials()

	if config.has("show_liquid"):
		show_liquid = config["show_liquid"]

	if config.has("rack_scale"):
		rack_scale = config["rack_scale"]
