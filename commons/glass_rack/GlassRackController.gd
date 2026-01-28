# GlassRackController.gd - Modular Glass Apparatus System
# Extends TurtlePipeBase for turtle-graphics pipe building
# Specialized for laboratory glassware with transparency and liquid flow
extends TurtlePipeBase
class_name GlassRackController

signal apparatus_built
signal liquid_flow_started
signal liquid_flow_stopped

@export_group("Glass Material")
@export var glass_color: Color = Color(0.85, 0.92, 1.0, 0.25)
@export var glass_roughness: float = 0.0
@export var use_refraction: bool = true

@export_group("Liquid")
@export var liquid_color: Color = Color(0.2, 0.8, 0.4, 0.6)
@export var show_liquid: bool = true
@export var liquid_flow_speed: float = 1.0

# Materials
var glass_material: StandardMaterial3D
var liquid_material: StandardMaterial3D

func _ready() -> void:
	# Set glass-appropriate defaults
	pipe_radius = 0.02
	segment_length = 0.3
	_setup_materials()
	super._ready()

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

# =============================================================================
# COMMAND REGISTRATION
# =============================================================================

func _register_custom_commands() -> void:
	_command_handlers["spiral"] = _cmd_spiral
	_command_handlers["coil"] = _cmd_spiral
	_command_handlers["wobbly"] = _cmd_wobbly
	_command_handlers["wavy"] = _cmd_wobbly
	_command_handlers["flask"] = _cmd_flask
	_command_handlers["bulb"] = _cmd_flask
	_command_handlers["junction"] = _cmd_junction
	_command_handlers["t"] = _cmd_junction
	_command_handlers["tee"] = _cmd_junction

func _cmd_spiral() -> void:
	var segment = _create_segment("spiral", {"height": segment_length * 2})
	if segment:
		_place_segment(segment)
		cursor_pos += Vector3.UP * segment_length * 2

func _cmd_wobbly() -> void:
	var segment = _create_segment("wobbly", {"length": segment_length * 2})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length * 2)

func _cmd_flask() -> void:
	var segment = _create_segment("flask", {"radius": segment_length * 0.5})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

func _cmd_junction() -> void:
	var segment = _create_segment("junction", {})
	if segment:
		_place_segment(segment)
		_advance_cursor_forward(segment_length)

# =============================================================================
# SEGMENT CREATION
# =============================================================================

func _create_segment(segment_type: String, params: Dictionary) -> Node3D:
	var scaled_params = _scale_params(params)

	match segment_type:
		"straight":
			return _create_straight_segment(scaled_params)
		"spiral":
			return _create_spiral_segment(scaled_params)
		"wobbly":
			return _create_wobbly_segment(scaled_params)
		"flask":
			return _create_flask_segment(scaled_params)
		"junction":
			return _create_junction_segment(scaled_params)
		"corner":
			return _create_corner_segment(scaled_params)
		_:
			push_warning("GlassRackController: Unknown segment type: %s" % segment_type)
			return null

func _scale_params(params: Dictionary) -> Dictionary:
	# Apply rack scale to dimension parameters
	var scaled = params.duplicate()
	for key in ["length", "height", "radius", "spiral_radius", "tube_radius", "corner_radius"]:
		if scaled.has(key):
			scaled[key] = scaled[key]
	return scaled

func _create_straight_segment(params: Dictionary) -> Node3D:
	var group = Node3D.new()
	var length = params.get("length", segment_length)
	var radius = params.get("radius", pipe_radius)

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
	var height = params.get("height", 0.5)
	var spiral_radius = params.get("spiral_radius", 0.1)
	var tube_radius = params.get("tube_radius", pipe_radius * 0.75)
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
	var length = params.get("length", 0.5)
	var tube_radius = params.get("tube_radius", pipe_radius)
	var amplitude = params.get("amplitude", 0.05)
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
	var flask_radius = params.get("radius", 0.08)
	var neck_radius = params.get("neck_radius", pipe_radius)
	var neck_length = params.get("neck_length", 0.1)

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
	var radius = params.get("radius", pipe_radius)
	var length = params.get("length", segment_length * 0.5)

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
	var radius = params.get("radius", pipe_radius)
	var corner_radius = params.get("corner_radius", segment_length)

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

# =============================================================================
# LIQUID ANIMATION
# =============================================================================

func start_liquid_flow() -> void:
	liquid_flow_started.emit()

func stop_liquid_flow() -> void:
	liquid_flow_stopped.emit()

# =============================================================================
# GRID SYSTEM INTEGRATION
# =============================================================================

func apply_grid_config(config: Dictionary) -> void:
	# Handle glass-specific config first
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

	# Call base class for path/config handling
	super.apply_grid_config(config)

func _get_config_directory() -> String:
	return "res://commons/glass_rack/configs"

# =============================================================================
# LEGACY COMPATIBILITY
# =============================================================================

## Load config from file path (legacy API)
func load_config(path: String) -> void:
	super.load_config(path)
	apparatus_built.emit()

## Load config from dictionary (legacy API)
func load_config_from_dict(data: Dictionary) -> void:
	super.load_config_from_dict(data)
	apparatus_built.emit()

## Build apparatus (legacy API - now calls generate_from_code)
func build_apparatus() -> void:
	# For backwards compatibility with old configs
	pass
