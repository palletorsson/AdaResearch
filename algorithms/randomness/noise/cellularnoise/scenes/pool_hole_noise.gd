extends Node3D

@export var width: int = 50
@export var depth: int = 50
@export var height_scale: float = 0.2
@export var cell_size: float = 0.1
@export var num_cells: int = 50
@export var num_pools: int = 10
@export var min_pool_radius: float = 1.0
@export var max_pool_radius: float = 5.0
@export var wall_height: float = 0.4
@export var growth_speed: float = 0.1
@export var min_inner_circle_radius: float = 0.5
@export var max_inner_circle_radius: float = 2.0
@export var num_inner_circles: int = 8  # Number of circles per pool

var pools = []  # Stores pool data
var noise = FastNoiseLite.new()
var rng = RandomNumberGenerator.new()
var mesh_instance: MeshInstance3D

func _ready():
	# Create a MeshInstance3D child node if not already present
	mesh_instance = $PoolHoleNoiseMesh
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "PoolHoleNoiseMesh"
		add_child(mesh_instance)
	
	# Create and apply height-based color shader
	apply_height_shader()
	
	rng.randomize()
	create_noise()
	generate_pools()
	generate_grid()
	TimerHelper.create_timer(self, 0.5, Callable(self, "_grow_pools"), false)

func apply_height_shader():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = create_height_shader()
	mesh_instance.material_override = shader_material

func create_height_shader() -> Shader:
	var shader = Shader.new()
	shader.code = """
	shader_type spatial;
	
	// Height-based coloring parameters
	uniform vec4 deep_color : source_color = vec4(0.0, 0.1, 0.4, 1.0);    // Deep pool areas
	uniform vec4 shallow_color : source_color = vec4(0.0, 0.4, 0.8, 1.0);  // Shallow areas
	uniform vec4 shore_color : source_color = vec4(0.8, 0.7, 0.5, 1.0);    // Shore/wall areas
	uniform vec4 high_color : source_color = vec4(0.1, 0.5, 0.1, 1.0);     // High terrain
	
	uniform float deep_threshold = -0.01;
	uniform float shallow_threshold = -0.002;
	uniform float shore_threshold = 0.002;
	
	varying float world_y;
	
	void vertex() {
		// Store the actual world space Y position
		world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
	}
	
	void fragment() {
		// Use the world space height directly
		float height = world_y;
		
		// Calculate colors based on height thresholds
		vec4 color;
		if (height < deep_threshold) {
			color = deep_color;
		} else if (height < shallow_threshold) {
			// Blend between deep and shallow
			float t = (height - deep_threshold) / (shallow_threshold - deep_threshold);
			color = mix(deep_color, shallow_color, t);
		} else if (height < shore_threshold) {
			// Blend between shallow and shore
			float t = (height - shallow_threshold) / (shore_threshold - shallow_threshold);
			color = mix(shallow_color, shore_color, t);
		} else {
			// Blend between shore and high
			float t = min((height - shore_threshold) * 10.0, 1.0);
			color = mix(shore_color, high_color, t);
		}
		
		ALBEDO = color.rgb;
		
		// Add some specularity to the water
		if (height < shallow_threshold) {
			METALLIC = 0.3;
			ROUGHNESS = 0.1;
			SPECULAR = 0.7;
		} else {
			METALLIC = 0.0;
			ROUGHNESS = 0.8;
			SPECULAR = 0.2;
		}
	}
	"""
	return shader


func create_noise():
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.cellular_jitter = 10.0
	noise.frequency = 1.0 / cell_size

func generate_pools():
	pools.clear()
	for i in range(num_pools):
		var pool_center = Vector2(rng.randi_range(5, num_cells - 5), rng.randi_range(5, num_cells - 5))
		var pool_radius = rng.randf_range(min_pool_radius, min_pool_radius + 1.0)
		var inner_circles = generate_circle_packing(pool_center, pool_radius)
		pools.append({ "center": pool_center, "radius": pool_radius, "inner_circles": inner_circles })

func generate_circle_packing(pool_center: Vector2, pool_radius: float) -> Array:
	var circles = []
	var attempts = 0
	while circles.size() < num_inner_circles and attempts < 100:
		var new_circle = {
			"center": Vector2(
				pool_center.x + rng.randf_range(-pool_radius * 0.7, pool_radius * 0.7),
				pool_center.y + rng.randf_range(-pool_radius * 0.7, pool_radius * 0.7)
			),
			"radius": rng.randf_range(min_inner_circle_radius, max_inner_circle_radius)
		}
		# Ensure circles don't overlap too much
		var overlaps = false
		for existing in circles:
			if new_circle["center"].distance_to(existing["center"]) < (new_circle["radius"] + existing["radius"]) * 0.8:
				overlaps = true
				break
		if not overlaps:
			circles.append(new_circle)
		attempts += 1
	return circles

func _grow_pools():
	for pool in pools:
		pool["radius"] = min(pool["radius"] + growth_speed, max_pool_radius)
		for circle in pool["inner_circles"]:
			circle["radius"] = min(circle["radius"] + growth_speed * 0.5, max_inner_circle_radius)
	generate_grid()

func mask_pool_area(x: int, y: int) -> float:
	var min_factor = 1.0
	for pool in pools:
		var pool_center = pool["center"]
		var pool_radius = pool["radius"]
		var distance = Vector2(x, y).distance_to(pool_center)
		if distance < pool_radius:
			min_factor = min(min_factor, 0.2)
		elif distance < pool_radius + 2:
			min_factor = min(min_factor, wall_height)
		# Apply inner circle influence
		for circle in pool["inner_circles"]:
			var circle_distance = Vector2(x, y).distance_to(circle["center"])
			if circle_distance < circle["radius"]:
				min_factor = min(min_factor, 0.3)  # Inner circle influence
	return min_factor

func generate_grid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices = []
	for x in range(num_cells + 1):
		vertices.append([])
		for y in range(num_cells + 1):
			var pos = Vector3(x * cell_size, 0, y * cell_size)
			var noise_factor = mask_pool_area(x, y)
			pos.y = noise.get_noise_2d(pos.x, pos.z) * height_scale * noise_factor
			vertices[x].append(pos)
	
	for x in range(num_cells):
		for y in range(num_cells):
			var v0 = vertices[x][y]
			var v1 = vertices[x + 1][y]
			var v2 = vertices[x + 1][y + 1]
			var v3 = vertices[x][y + 1]
			st.add_vertex(v0)
			st.add_vertex(v1)
			st.add_vertex(v2)
			st.add_vertex(v0)
			st.add_vertex(v2)
			st.add_vertex(v3)
	
	st.generate_normals()
	mesh_instance.mesh = st.commit()
