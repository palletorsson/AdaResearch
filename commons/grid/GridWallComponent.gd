# GridWallComponent.gd
# Generates perimeter walls around the grid map using SimpleGrid shader
# Walls are placed as 4 flat quads (N, S, E, W) around the grid boundary

extends Node
class_name GridWallComponent

# References
var grid_system: Node3D
var data_component: GridDataComponent

# Wall configuration
var wall_height: float = 2.0  # Wall height in meters
var wall_width: float = -1.0  # Coverage width in meters (-1 = auto from grid)
var wall_depth: float = -1.0  # Coverage depth in meters (-1 = auto from grid)
var wall_offset_x: float = -0.5  # X offset for wall placement
var wall_offset_z: float = -0.5  # Z offset for wall placement
var wall_thickness: float = 0.05  # Wall panel thickness
var cube_size: float = 1.0
var gutter: float = 0.0

# Shader configuration
var shader_path: String = "res://commons/resourses/shaders/WallGrid.gdshader"
var model_color: Color = Color(0.15, 0.15, 0.15, 1.0)
var wireframe_color: Color = Color(0.6, 0.6, 0.6, 1.0)
var emission_color: Color = Color(0.4, 0.4, 0.5, 1.0)
var wireframe_width: float = 1.0
var wireframe_blur: float = 1.0
var emission_strength: float = 1.0
var model_opacity: float = 1.0
var wireframe_opacity: float = 1.0
var global_opacity: float = 1.0
var show_interior: bool = true

# Light pattern on walls
var light_pattern: String = "sparse"

# State
var wall_objects: Array[Node3D] = []
var wall_material: ShaderMaterial

# Signals
signal wall_generation_complete(wall_count: int)

func _ready():
	print("GridWallComponent: Initialized")

# Initialize component
func initialize(grid_sys: Node3D, data_comp: GridDataComponent, settings: Dictionary = {}):
	grid_system = grid_sys
	data_component = data_comp

	cube_size = settings.get("cube_size", cube_size)
	gutter = settings.get("gutter", gutter)

	print("GridWallComponent: Ready to generate walls")

# Generate walls from configuration
func generate_walls(wall_config: Dictionary = {}):
	print("GridWallComponent: Generating perimeter walls...")

	# Parse config
	_parse_wall_config(wall_config)

	# Setup shader material
	_setup_wall_material()

	# Get grid dimensions
	var dimensions = data_component.get_grid_dimensions()
	if dimensions == Vector3i.ZERO:
		print("GridWallComponent: WARNING - No grid dimensions available")
		return

	# Clear existing walls
	clear_walls()

	# Calculate wall bounds in meters
	var grid_width_m: float
	var grid_depth_m: float

	if wall_width > 0:
		grid_width_m = wall_width
	else:
		grid_width_m = dimensions.x * (cube_size + gutter)

	if wall_depth > 0:
		grid_depth_m = wall_depth
	else:
		grid_depth_m = dimensions.z * (cube_size + gutter)

	print("GridWallComponent: Creating walls %.1fm x %.1fm, height %.1fm, offset (%.1f, %.1f)" % [grid_width_m, grid_depth_m, wall_height, wall_offset_x, wall_offset_z])

	# Create wall container
	var wall_container = Node3D.new()
	wall_container.name = "WallContainer"
	grid_system.add_child(wall_container)
	wall_objects.append(wall_container)

	# Generate 4 perimeter walls
	# North wall (far side, along X axis at max Z)
	var north = _create_wall_panel(grid_width_m, wall_height)
	north.position = Vector3(
		wall_offset_x + grid_width_m / 2.0,
		wall_height / 2.0,
		wall_offset_z + grid_depth_m
	)
	north.name = "WallNorth"
	wall_container.add_child(north)

	# South wall (near side, along X axis at Z=0)
	var south = _create_wall_panel(grid_width_m, wall_height)
	south.position = Vector3(
		wall_offset_x + grid_width_m / 2.0,
		wall_height / 2.0,
		wall_offset_z
	)
	south.rotation_degrees = Vector3(0, 180, 0)
	south.name = "WallSouth"
	wall_container.add_child(south)

	# East wall (right side, along Z axis at max X)
	var east = _create_wall_panel(grid_depth_m, wall_height)
	east.position = Vector3(
		wall_offset_x + grid_width_m,
		wall_height / 2.0,
		wall_offset_z + grid_depth_m / 2.0
	)
	east.rotation_degrees = Vector3(0, -90, 0)
	east.name = "WallEast"
	wall_container.add_child(east)

	# West wall (left side, along Z axis at X=0)
	var west = _create_wall_panel(grid_depth_m, wall_height)
	west.position = Vector3(
		wall_offset_x,
		wall_height / 2.0,
		wall_offset_z + grid_depth_m / 2.0
	)
	west.rotation_degrees = Vector3(0, 90, 0)
	west.name = "WallWest"
	wall_container.add_child(west)

	var wall_count = 4
	print("GridWallComponent: Walls complete - %d walls" % wall_count)
	wall_generation_complete.emit(wall_count)

# Create a single wall panel using PlaneMesh with UV-based grid shader
func _create_wall_panel(panel_width: float, panel_height: float) -> Node3D:
	var wall_root = Node3D.new()

	# PlaneMesh is horizontal by default (XZ plane), so we rotate it to be vertical
	var wall_mesh_node = MeshInstance3D.new()
	wall_mesh_node.name = "WallMesh"
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(panel_width, panel_height)

	wall_mesh_node.mesh = mesh

	# Each wall gets its own material — 1 grid cell per meter
	var mat = wall_material.duplicate() as ShaderMaterial
	var cells_x = panel_width
	var cells_y = panel_height
	mat.set_shader_parameter("grid_cells_x", cells_x)
	mat.set_shader_parameter("grid_cells_y", cells_y)
	wall_mesh_node.material_override = mat

	# Rotate plane from horizontal (XZ) to vertical (XY), facing +Z
	wall_mesh_node.rotation_degrees = Vector3(90, 0, 0)

	wall_root.add_child(wall_mesh_node)

	# Add static body for collision
	var static_body = StaticBody3D.new()
	static_body.name = "WallCollision"
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(panel_width, panel_height, wall_thickness)
	collision.shape = shape
	static_body.add_child(collision)
	wall_root.add_child(static_body)

	return wall_root

# Setup shader material for walls
func _setup_wall_material():
	wall_material = ShaderMaterial.new()

	var shader = load(shader_path)
	if shader:
		wall_material.shader = shader
		wall_material.set_shader_parameter("modelColor", model_color)
		wall_material.set_shader_parameter("wireframeColor", wireframe_color)
		wall_material.set_shader_parameter("emissionColor", emission_color)
		wall_material.set_shader_parameter("width", wireframe_width)
		wall_material.set_shader_parameter("blur", wireframe_blur)
		wall_material.set_shader_parameter("emission_strength", emission_strength)
		wall_material.set_shader_parameter("modelOpacity", model_opacity)
		wall_material.set_shader_parameter("wireframeOpacity", wireframe_opacity)
		wall_material.set_shader_parameter("globalOpacity", global_opacity)
		wall_material.set_shader_parameter("show_interior", show_interior)
		print("GridWallComponent: Shader loaded from %s" % shader_path)
	else:
		push_warning("GridWallComponent: Failed to load shader at %s, using fallback" % shader_path)
		_setup_fallback_material()

# Fallback if shader fails to load
func _setup_fallback_material():
	var mat = StandardMaterial3D.new()
	mat.albedo_color = model_color
	mat.roughness = 0.8
	mat.metallic = 0.1
	# Can't assign StandardMaterial3D to ShaderMaterial var, so wrap it
	# Just create a simple shader inline
	wall_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, cull_disabled;
uniform vec4 color : source_color = vec4(0.15, 0.15, 0.15, 1.0);
void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ROUGHNESS = 0.8;
}
"""
	wall_material.shader = shader
	wall_material.set_shader_parameter("color", model_color)

# Parse wall configuration from map data
func _parse_wall_config(config: Dictionary):
	if config.is_empty():
		return

	# Apply preset first
	var preset = config.get("preset", "")
	match preset:
		"office":
			wall_height = 3.5
			model_color = Color(0.12, 0.12, 0.14, 1.0)
			wireframe_color = Color(0.5, 0.5, 0.55, 1.0)
			emission_color = Color(0.3, 0.3, 0.4, 1.0)
			emission_strength = 0.8
			model_opacity = 0.9
			wireframe_width = 1.0
		"laboratory":
			wall_height = 4.5
			model_color = Color(0.1, 0.12, 0.15, 1.0)
			wireframe_color = Color(0.4, 0.6, 0.8, 1.0)
			emission_color = Color(0.3, 0.5, 0.7, 1.0)
			emission_strength = 1.5
			model_opacity = 0.85
			wireframe_width = 1.2
		"warehouse":
			wall_height = 6.0
			model_color = Color(0.08, 0.08, 0.08, 1.0)
			wireframe_color = Color(0.3, 0.3, 0.3, 1.0)
			emission_color = Color(0.2, 0.2, 0.2, 1.0)
			emission_strength = 0.5
			model_opacity = 1.0
			wireframe_width = 0.8
		"liminal":
			wall_height = 4.0
			model_color = Color(0.18, 0.17, 0.15, 1.0)
			wireframe_color = Color(0.7, 0.65, 0.5, 1.0)
			emission_color = Color(0.6, 0.55, 0.4, 1.0)
			emission_strength = 1.2
			model_opacity = 0.95
			wireframe_width = 1.0
		"void":
			wall_height = 4.0
			model_color = Color(0.02, 0.02, 0.02, 1.0)
			wireframe_color = Color(0.1, 0.1, 0.15, 1.0)
			emission_color = Color(0.05, 0.05, 0.1, 1.0)
			emission_strength = 0.3
			model_opacity = 1.0
			wireframe_width = 0.5

	# Custom overrides (override preset values)
	if config.has("height"):
		wall_height = config.get("height")
	if config.has("width"):
		wall_width = config.get("width")
	if config.has("depth"):
		wall_depth = config.get("depth")
	if config.has("size_x"):
		wall_width = config.get("size_x")
	if config.has("size_z"):
		wall_depth = config.get("size_z")
	if config.has("offset_x"):
		wall_offset_x = config.get("offset_x")
	if config.has("offset_z"):
		wall_offset_z = config.get("offset_z")
	if config.has("thickness"):
		wall_thickness = config.get("thickness")
	if config.has("pattern"):
		light_pattern = config.get("pattern")

	# Shader overrides
	if config.has("shader"):
		shader_path = config.get("shader")

	# Simple color shorthand — sets wireframe and emission from one value
	if config.has("color"):
		var c = config.get("color")
		if c is Array and c.size() >= 3:
			var base = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
			wireframe_color = base
			emission_color = base * 0.7
			model_color = base * 0.15

	# Fine-grained color overrides (override "color" shorthand if both present)
	if config.has("model_color"):
		var c = config.get("model_color")
		if c is Array and c.size() >= 3:
			model_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
	if config.has("wireframe_color"):
		var c = config.get("wireframe_color")
		if c is Array and c.size() >= 3:
			wireframe_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
	if config.has("emission_color"):
		var c = config.get("emission_color")
		if c is Array and c.size() >= 3:
			emission_color = Color(c[0], c[1], c[2], c[3] if c.size() > 3 else 1.0)
	if config.has("wireframe_width"):
		wireframe_width = config.get("wireframe_width")
	if config.has("wireframe_blur"):
		wireframe_blur = config.get("wireframe_blur")
	if config.has("emission_strength"):
		emission_strength = config.get("emission_strength")
	if config.has("model_opacity"):
		model_opacity = config.get("model_opacity")
	if config.has("wireframe_opacity"):
		wireframe_opacity = config.get("wireframe_opacity")
	if config.has("global_opacity"):
		global_opacity = config.get("global_opacity")
	if config.has("show_interior"):
		show_interior = config.get("show_interior")

# Update shader parameters at runtime
func update_shader_param(param_name: String, value) -> void:
	if wall_material:
		wall_material.set_shader_parameter(param_name, value)

# Update wall color at runtime
func set_wall_color(color: Color) -> void:
	update_shader_param("modelColor", color)

# Update wireframe color at runtime
func set_wireframe_color(color: Color) -> void:
	update_shader_param("wireframeColor", color)

# Update emission at runtime
func set_emission(color: Color, strength: float = -1.0) -> void:
	update_shader_param("emissionColor", color)
	if strength >= 0:
		update_shader_param("emission_strength", strength)

# Update opacity at runtime
func set_opacity(opacity: float) -> void:
	update_shader_param("globalOpacity", opacity)

# Get wall count
func get_wall_count() -> int:
	if wall_objects.size() > 0 and wall_objects[0] is Node3D:
		return wall_objects[0].get_child_count()
	return 0

# Cleanup
func clear_walls():
	for obj in wall_objects:
		if obj and is_instance_valid(obj):
			obj.queue_free()
	wall_objects.clear()
	print("GridWallComponent: Walls cleared")
