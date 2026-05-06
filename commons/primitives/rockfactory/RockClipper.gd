# RockClipper.gd - Slices through rocks with a horizontal clipping plane
extends Node3D

@export var scan_height: float = 1.5
@export var scan_speed: float = 0.3
@export var scan_range: Vector2 = Vector2(0.5, 2.5)
@export var auto_scan: bool = true
@export var plane_size: float = 5.0
@export var debug_output: bool = false

var scan_plane: MeshInstance3D
var clipping_plane_position: Vector3 = Vector3.ZERO
var scan_direction: float = 1.0
var rocks: Array[MeshInstance3D] = []

# Clipping shader - inspired by water line shader technique
const CLIPPING_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_prepass_alpha;

uniform float plane_distance : hint_range(-10.0, 10.0) = 0.0;
uniform vec3 plane_normal = vec3(0.0, 1.0, 0.0);
uniform vec3 plane_position = vec3(0.0, 0.0, 0.0);
uniform float edge_sharpness : hint_range(0.1, 5.0) = 1.5;
uniform float edge_width : hint_range(0.0, 2.0) = 0.8;
uniform float intersection_width : hint_range(0.0, 1.0) = 0.15;
uniform vec4 edge_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 intersection_color : source_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform vec4 base_color : source_color = vec4(0.6, 0.6, 0.65, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float max_metallic : hint_range(0.0, 1.0) = 0.7;
uniform float max_specular : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	// Get world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Calculate distance from fragment to clipping plane
	vec3 to_plane = world_pos - plane_position;
	float distance_to_plane = dot(to_plane, normalize(plane_normal));

	// Discard fragments ABOVE the plane (show what's below/under the surface)
	if (distance_to_plane > plane_distance) {
		discard;
	}

	// Calculate distance from plane for edge effects (now measuring from below)
	float edge_distance = plane_distance - distance_to_plane;

	// Edge glow - wider, softer gradient like water foam
	float edge_factor = clamp(pow(edge_width / (edge_distance + 0.001), edge_sharpness), 0.0, 1.0);

	// Sharp intersection line at exact cut plane
	float intersection_factor = clamp(pow(intersection_width / (edge_distance + 0.0001), edge_sharpness * 3.0), 0.0, 1.0);

	// Three-layer color mixing: base -> cyan glow -> bright yellow intersection
	vec3 final_color = mix(base_color.rgb, edge_color.rgb, edge_factor * 0.9);
	final_color = mix(final_color, intersection_color.rgb, intersection_factor);

	ALBEDO = final_color;

	// Metallic/specular makes the cut surface shine
	METALLIC = mix(metallic, max_metallic, edge_factor);
	SPECULAR = mix(0.5, max_specular, edge_factor);
	ROUGHNESS = mix(roughness, 0.1, edge_factor * 0.7);

	// Very bright emission - should be visible in any lighting
	vec3 emission = edge_color.rgb * edge_factor * 12.0;
	emission += intersection_color.rgb * intersection_factor * 30.0;
	EMISSION = emission;
}
"""

func _ready():
	create_visual_plane()
	clipping_plane_position.y = scan_height
	# Wait multiple frames for rocks to fully generate their meshes
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	find_and_clip_rocks()

func create_visual_plane():
	"""Create visual plane that shows scan position"""
	scan_plane = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(plane_size, plane_size)
	scan_plane.mesh = plane_mesh

	# Semi-transparent cyan material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 0.9, 1.0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scan_plane.material_override = material

	add_child(scan_plane)

func find_and_clip_rocks():
	"""Find all rocks in scene and apply clipping shader"""
	rocks.clear()
	var root = get_tree().root
	find_rocks_recursive(root)

	if debug_output:
		print("RockClipper: Found ", rocks.size(), " rock meshes to clip")

	if rocks.size() == 0 and debug_output:
		print("RockClipper: WARNING - No rocks found! Searching for RigidBody3D nodes with 'Rock' in name...")
		debug_scene_tree(root, 0)

	# Apply clipping shader to each rock
	for rock_mesh in rocks:
		apply_clipping_shader(rock_mesh)

func find_rocks_recursive(node: Node):
	# Look for MeshInstance3D children of RigidBody3D rocks
	if node is RigidBody3D and node.name.contains("Rock"):
		if debug_output:
			print("RockClipper: Found RigidBody3D rock: ", node.name, " with ", node.get_child_count(), " children")
		for child in node.get_children():
			if debug_output:
				print("  - Child: ", child.name, " (", child.get_class(), ")")
			if child is MeshInstance3D:
				if debug_output:
					print("    -> Adding MeshInstance3D to clip list")
				rocks.append(child)

	for child in node.get_children():
		find_rocks_recursive(child)

func debug_scene_tree(node: Node, depth: int):
	"""Debug function to print scene tree"""
	var indent = ""
	for i in range(depth):
		indent += "  "
	print(indent, node.name, " (", node.get_class(), ")")
	for child in node.get_children():
		debug_scene_tree(child, depth + 1)

func apply_clipping_shader(mesh_inst: MeshInstance3D):
	"""Apply clipping shader material to a mesh"""
	if debug_output:
		print("RockClipper: Applying clipping shader to: ", mesh_inst.name)

	var material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = CLIPPING_SHADER
	material.shader = shader

	# Set shader parameters
	material.set_shader_parameter("base_color", Color(0.6, 0.6, 0.65, 1.0))
	material.set_shader_parameter("edge_color", Color(0.0, 1.0, 1.0, 1.0))  # Cyan glow
	material.set_shader_parameter("intersection_color", Color(1.0, 0.8, 0.0, 1.0))  # Bright yellow at cut
	material.set_shader_parameter("metallic", 0.0)
	material.set_shader_parameter("roughness", 0.9)
	material.set_shader_parameter("edge_sharpness", 1.5)  # Softer for wider visibility
	material.set_shader_parameter("edge_width", 0.8)  # Wide glow area
	material.set_shader_parameter("intersection_width", 0.15)  # Sharp bright line
	material.set_shader_parameter("max_metallic", 0.7)  # More metallic at cut
	material.set_shader_parameter("max_specular", 1.0)  # Maximum specular
	material.set_shader_parameter("plane_position", clipping_plane_position)
	material.set_shader_parameter("plane_normal", Vector3(0, 1, 0))
	material.set_shader_parameter("plane_distance", 0.0)

	mesh_inst.set_surface_override_material(0, material)
	if debug_output:
		print("RockClipper: Shader applied successfully")

func _process(delta):
	if auto_scan:
		# Move scan plane up and down
		scan_height += scan_speed * scan_direction * delta

		# Reverse at boundaries
		if scan_height >= scan_range.y:
			scan_height = scan_range.y
			scan_direction = -1.0
		elif scan_height <= scan_range.x:
			scan_height = scan_range.x
			scan_direction = 1.0

		clipping_plane_position.y = scan_height
		update_clipping_plane()

func update_clipping_plane():
	"""Update visual plane and shader uniforms"""
	if scan_plane:
		scan_plane.position.y = scan_height

	# Update shader parameters for all rocks
	for rock_mesh in rocks:
		var material = rock_mesh.get_surface_override_material(0)
		if material is ShaderMaterial:
			material.set_shader_parameter("plane_position", clipping_plane_position)
