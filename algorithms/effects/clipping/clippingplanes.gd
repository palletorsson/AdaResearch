# ClippingPlanesVR.gd
# A mesmerizing VR scene with objects being dynamically sliced by invisible planes
extends Node3D

@export var num_objects: int = 8
@export var clipping_speed: float = 1.0
@export var object_scale: float = 2.0

var clipping_planes: Array[Node3D] = []
var clipped_objects: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []

# 3D Clipping shader for mesh materials
const CLIPPING_3D_SHADER = """
shader_type spatial;
render_mode depth_draw_opaque, depth_prepass_alpha;

uniform float plane_distance : hint_range(-10.0, 10.0) = 0.0;
uniform vec3 plane_normal = vec3(1.0, 0.0, 0.0);
uniform vec3 plane_position = vec3(0.0, 0.0, 0.0);
uniform float edge_glow : hint_range(0.0, 1.0) = 0.2;
uniform vec4 edge_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 base_color : source_color = vec4(0.8, 0.3, 0.9, 1.0);
uniform float metallic : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	// Get world position
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Calculate distance from fragment to clipping plane  
	vec3 to_plane = world_pos - plane_position;
	float distance_to_plane = dot(to_plane, normalize(plane_normal));
	
	// Discard fragments on the negative side of the plane
	if (distance_to_plane < plane_distance) {
		discard;
	}
	
	// Create glowing edge effect near the clipping plane
	float edge_distance = abs(distance_to_plane - plane_distance);
	float edge_factor = 1.0 - smoothstep(0.0, edge_glow, edge_distance);
	
	// Mix colors for the cut surface glow
	vec3 final_color = mix(base_color.rgb, edge_color.rgb, edge_factor * 0.8);
	
	ALBEDO = final_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	
	// Add emission for the glowing edge
	EMISSION = edge_color.rgb * edge_factor * 2.0;
}
"""

func _ready():
	setup_scene()
	create_clipping_objects()
	create_clipping_planes()
	start_animation()

func setup_scene():
	# Add ambient lighting
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_energy = 0.3
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	
	# Add camera environment  
	var camera_env = get_viewport().get_camera_3d()
	if camera_env:
		camera_env.environment = env
	
	# Add directional light
	var light = DirectionalLight3D.new()
	light.position = Vector3(5, 10, 5)
	light.look_at(Vector3.ZERO, Vector3.UP)
	light.light_energy = 1.0
	add_child(light)

func create_clipping_objects():
	# Create various geometric objects to be clipped
	var geometries = [
		SphereMesh.new(),
		BoxMesh.new(), 
		CylinderMesh.new(),
		PrismMesh.new()
	]
	
	# Set up mesh properties
	for i in range(geometries.size()):
		if geometries[i] is SphereMesh:
			geometries[i].radius = 1.5
			geometries[i].height = 3.0
		elif geometries[i] is BoxMesh:
			geometries[i].size = Vector3(2.5, 2.5, 2.5)
		elif geometries[i] is CylinderMesh:
			geometries[i].top_radius = 1.2
			geometries[i].bottom_radius = 1.2
			geometries[i].height = 3.0
		elif geometries[i] is PrismMesh:
			geometries[i].left_to_right = 2.0
			geometries[i].size = Vector3(2.0, 3.0, 2.0)
	
	# Create objects in a circle
	for i in range(num_objects):
		var angle = (i * 2.0 * PI) / num_objects
		var radius = 6.0
		var pos = Vector3(cos(angle) * radius, sin(i * 0.5) * 2.0, sin(angle) * radius)
		
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = geometries[i % geometries.size()]
		mesh_instance.scale = Vector3.ONE * object_scale
		mesh_instance.position = pos
		
		# Create shader material with clipping
		var material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = CLIPPING_3D_SHADER
		material.shader = shader
		
		# Set random colors for variety
		material.set_shader_parameter("base_color", Color(
			randf_range(0.3, 1.0),
			randf_range(0.3, 1.0), 
			randf_range(0.3, 1.0),
			1.0
		))
		material.set_shader_parameter("edge_color", Color(
			randf_range(0.5, 1.0),
			randf_range(0.8, 1.0),
			randf_range(0.8, 1.0),
			1.0
		))
		material.set_shader_parameter("metallic", randf_range(0.1, 0.7))
		material.set_shader_parameter("roughness", randf_range(0.2, 0.8))
		material.set_shader_parameter("edge_glow", randf_range(0.1, 0.4))
		
		mesh_instance.set_surface_override_material(0, material)
		
		add_child(mesh_instance)
		clipped_objects.append(mesh_instance)
		materials.append(material)

func create_clipping_planes():
	# Create invisible clipping plane controllers
	for i in range(3):  # Three clipping planes for complex intersections
		var plane_controller = Node3D.new()
		plane_controller.name = "ClippingPlane_" + str(i)
		add_child(plane_controller)
		clipping_planes.append(plane_controller)
		
		# Position planes
		match i:
			0:  # Horizontal plane
				plane_controller.position = Vector3(0, -5, 0)
			1:  # Vertical plane  
				plane_controller.position = Vector3(-8, 0, 0)
			2:  # Diagonal plane
				plane_controller.position = Vector3(0, 0, -8)

func start_animation():
	# Animate the clipping planes
	animate_planes()

func animate_planes():
	# Create tweens for each clipping plane
	for i in range(clipping_planes.size()):
		var plane = clipping_planes[i]
		var tween = create_tween()
		tween.set_loops()
		
		match i:
			0:  # Horizontal sweeping plane
				var start_y = -8.0
				var end_y = 8.0
				plane.position.y = start_y
				tween.tween_property(plane, "position:y", end_y, 4.0 / clipping_speed)
				tween.tween_property(plane, "position:y", start_y, 4.0 / clipping_speed)
				
			1:  # Vertical sweeping plane
				var start_x = -12.0  
				var end_x = 12.0
				plane.position.x = start_x
				tween.tween_property(plane, "position:x", end_x, 6.0 / clipping_speed)
				tween.tween_property(plane, "position:x", start_x, 6.0 / clipping_speed)
				
			2:  # Diagonal/rotating plane
				var start_z = -12.0
				var end_z = 12.0  
				plane.position.z = start_z
				tween.tween_property(plane, "position:z", end_z, 5.0 / clipping_speed)
				tween.tween_property(plane, "position:z", start_z, 5.0 / clipping_speed)

func _process(_delta):
	# Update shader uniforms based on plane positions
	for i in range(materials.size()):
		var material = materials[i]
		
		# Update each clipping plane
		if clipping_planes.size() > 0:
			var plane = clipping_planes[i % clipping_planes.size()]
			
			# Set plane position and normal
			match i % clipping_planes.size():
				0:  # Horizontal plane (Y-normal)
					material.set_shader_parameter("plane_position", plane.position)
					material.set_shader_parameter("plane_normal", Vector3(0, 1, 0))
					material.set_shader_parameter("plane_distance", 0.0)
				1:  # Vertical plane (X-normal)  
					material.set_shader_parameter("plane_position", plane.position)
					material.set_shader_parameter("plane_normal", Vector3(1, 0, 0))
					material.set_shader_parameter("plane_distance", 0.0)
				2:  # Depth plane (Z-normal)
					material.set_shader_parameter("plane_position", plane.position)
					material.set_shader_parameter("plane_normal", Vector3(0, 0, 1))
					material.set_shader_parameter("plane_distance", 0.0)
