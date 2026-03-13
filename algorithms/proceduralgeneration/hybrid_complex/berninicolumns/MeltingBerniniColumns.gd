# MeltingBerniniColumns.gd
# A 3D procedural generation system creating melting, overhanging, extreme queer columns
# inspired by Gian Lorenzo Bernini's baroque style, but with radical deformations
extends Node3D

# -- Configuration --

# Parameters for column generation
@export_category("Layout")
@export_range(1, 64, 1) var column_count: int = 9
@export var layout_radius: float = 3.8
@export var include_center_column: bool = true
@export var show_platform: bool = true

@export_category("Column Shape")
@export var column_height: float = 10.0
@export var column_radius: float = 0.5
@export var spiral_density: float = 5.0  # More spirals
@export var sine_amplitude: float = 0.4  # Extreme wave
@export var cosine_amplitude: float = 0.4  # Extreme wave
@export var vertical_segments: int = 80  # More detail for melting
@export var radial_segments: int = 24  # More detail
@export var twist_factor: float = 2.5  # Extreme twist
@export var material_color: Color = Color(0.9, 0.3, 0.8, 1.0)  # Queer magenta

# Melting parameters
@export var melt_strength: float = 1.5  # How much the column droops
@export var overhang_factor: float = 0.8  # Extreme overhangs
@export var bulge_amplitude: float = 0.6  # Organic bulges
@export var chaos_factor: float = 0.3  # Random organic deformation

# Profile/ribs parameters
@export var rib_count: int = 12  # Number of vertical ribs/flutes
@export var rib_depth: float = 0.15  # How deep the ribs cut into surface
@export var rib_sharpness: float = 2.0  # How sharp vs smooth the ribs are

@export var use_marble_shader: bool = true
@export var marble_vein_contrast: float = 2.2
@export var marble_vein_strength: float = 0.55
@export var marble_noise_scale: float = 0.4
@export var marble_turbulence: float = 3.6
@export var marble_swirl_strength: float = 1.1
@export var marble_time_speed: float = 0.2
@export var marble_emission_strength: float = 0.2
@export var marble_normal_perturb: float = 0.25
@export var marble_metallic: float = 0.6
@export var marble_roughness: float = 0.28

# Shader path
const DISPLACEMENT_SHADER_PATH = "res://algorithms/patterngeneration/fabrics/displacement.gdshader"
const DISPLACEMENT_SHADER: Shader = preload("res://algorithms/patterngeneration/fabrics/displacement.gdshader")
var displacement_shader: Shader = null
const MARBLE_SHADER_PATH = "res://algorithms/proceduralgeneration/hybrid_complex/berninicolumns/shaders/marble_column.gdshader"
const MARBLE_SHADER: Shader = preload("res://algorithms/proceduralgeneration/hybrid_complex/berninicolumns/shaders/marble_column.gdshader")
var marble_shader: Shader = null

# For animated rotation and melting
@export var rotate_columns: bool = true
@export var rotation_speed: float = 0.15
@export var animate_melting: bool = true
@export var melt_speed: float = 0.3
var time: float = 0.0

# -- Scene State --
var columns: Array = []  # Holds dictionaries with column node, mesh, material, and metadata
var column_positions: Array[Vector3] = []

# Queer color palette
var queer_colors = [
	Color(1.0, 0.4, 0.7, 1.0),  # Hot pink
	Color(0.8, 0.3, 1.0, 1.0),  # Purple
	Color(0.3, 0.9, 1.0, 1.0),  # Cyan
	Color(1.0, 0.8, 0.2, 1.0),  # Gold
	Color(0.9, 0.3, 0.8, 1.0),  # Magenta
]

# -- Godot Lifecycle Functions --

func _ready() -> void:
	_build_column_positions()

	# Confirm displacement shader availability (falls back to procedural normal map when null)
	displacement_shader = DISPLACEMENT_SHADER if is_instance_valid(DISPLACEMENT_SHADER) else null
	if not displacement_shader:
		push_warning("Displacement shader missing, using procedural normal map fallback.")

	marble_shader = MARBLE_SHADER if is_instance_valid(MARBLE_SHADER) else null
	if use_marble_shader and not marble_shader:
		push_warning("Marble shader missing, reverting to standard material fallback.")

	# Create the melting columns with different colors
	for i in range(column_positions.size()):
		var pos = column_positions[i]
		var color = material_color
		if queer_colors.size() > 0:
			color = queer_colors[i % queer_colors.size()]
		var column_data = create_spiral_column(color, i)
		var column_node: Node3D = column_data["node"]
		column_node.position = pos
		add_child(column_node)
		columns.append(column_data)

	# Optional floor/platform.
	if show_platform:
		create_platform()

	# Add a light to highlight the columns
	create_lighting()

func _build_column_positions() -> void:
	column_positions.clear()

	var include_center_count := 0
	if include_center_column:
		column_positions.append(Vector3.ZERO)
		include_center_count = 1

	var ring_count := maxi(column_count - include_center_count, 0)
	if ring_count == 0:
		if column_positions.is_empty():
			column_positions.append(Vector3.ZERO)
		return

	for i in range(ring_count):
		var angle := TAU * float(i) / float(ring_count)
		var x := cos(angle) * layout_radius
		var z := sin(angle) * layout_radius
		column_positions.append(Vector3(x, 0.0, z))

func _process(delta: float) -> void:
	# Animate the columns if enabled
	time += delta

	for column_data in columns:
		if column_data.has("material") and column_data["material"] is ShaderMaterial:
			var shader_material: ShaderMaterial = column_data["material"]
			if shader_material.shader == marble_shader:
				shader_material.set_shader_parameter("u_time", time)

	if rotate_columns:
		for i in range(columns.size()):
			var column_data: Dictionary = columns[i]
			var column_node := column_data.get("node") as Node3D
			if column_node:
				column_node.rotation.y = time * rotation_speed * (1.0 + i * 0.3)

	if animate_melting:
		for i in range(columns.size()):
			var column_data: Dictionary = columns[i]
			var melt_phase = sin(time * melt_speed + i) * 0.5 + 0.5
			update_column_mesh(column_data, melt_phase)

# --- Procedural Generation Functions ---

func update_column_mesh(column_data: Dictionary, melt_phase: float) -> void:
	var shaft := column_data.get("shaft") as MeshInstance3D
	if not shaft or not is_instance_valid(shaft):
		return

	var base_phase: float = column_data.get("base_melt_phase", 0.6)
	var target_phase = clamp(lerp(base_phase, melt_phase, 0.75), 0.05, 1.0)
	shaft.mesh = generate_spiral_column_mesh(target_phase)
	column_data["base_melt_phase"] = target_phase

	if column_data.has("material") and column_data["material"] is Material:
		var material: Material = column_data["material"]
		if displacement_shader:
			shaft.material_override = material
		else:
			shaft.set_surface_override_material(0, material)


func create_shaft_material(color: Color) -> Material:
	if use_marble_shader and marble_shader:
		var shader_material := ShaderMaterial.new()
		shader_material.shader = marble_shader
		shader_material.set_shader_parameter("base_color", Vector3(color.r, color.g, color.b))
		var vein_color := color.lightened(0.25)
		shader_material.set_shader_parameter("vein_color", Vector3(vein_color.r, vein_color.g, vein_color.b))
		shader_material.set_shader_parameter("vein_contrast", marble_vein_contrast)
		shader_material.set_shader_parameter("vein_strength", marble_vein_strength)
		shader_material.set_shader_parameter("noise_scale", marble_noise_scale)
		shader_material.set_shader_parameter("turbulence", marble_turbulence)
		shader_material.set_shader_parameter("swirl_strength", marble_swirl_strength)
		shader_material.set_shader_parameter("time_speed", marble_time_speed)
		shader_material.set_shader_parameter("emission_strength", marble_emission_strength)
		shader_material.set_shader_parameter("normal_perturb", marble_normal_perturb)
		shader_material.set_shader_parameter("metallic_amount", marble_metallic)
		shader_material.set_shader_parameter("roughness_amount", marble_roughness)
		shader_material.set_shader_parameter("u_time", time)
		return shader_material

	if displacement_shader:
		var displacement_material := ShaderMaterial.new()
		displacement_material.shader = displacement_shader
		displacement_material.set_shader_parameter("base_color", Vector3(color.r, color.g, color.b))
		displacement_material.set_shader_parameter("time_scale", 0.3)
		displacement_material.set_shader_parameter("cell_scale", 8.0)
		displacement_material.set_shader_parameter("displacement_strength", 0.8)
		displacement_material.set_shader_parameter("animation_speed", 0.5)
		displacement_material.set_shader_parameter("vertex_displacement", 0.05)
		displacement_material.set_shader_parameter("roughness", 0.3)
		displacement_material.set_shader_parameter("metallic", 0.7)
		displacement_material.set_shader_parameter("emission_strength", 0.5)
		displacement_material.set_shader_parameter("base_alpha", 1.0)
		displacement_material.set_shader_parameter("animate", true)
		displacement_material.set_shader_parameter("use_vertex_displacement", true)
		displacement_material.set_shader_parameter("use_full_color", false)
		displacement_material.set_shader_parameter("use_pattern_alpha", false)
		displacement_material.set_shader_parameter("color_r", Vector3(color.r * 1.2, color.g * 0.8, color.b * 0.8))
		displacement_material.set_shader_parameter("color_g", Vector3(color.r * 0.8, color.g * 1.2, color.b * 0.8))
		displacement_material.set_shader_parameter("color_b", Vector3(color.r * 0.8, color.g * 0.8, color.b * 1.2))
		return displacement_material

	var normal_map = create_crackle_normal_map()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.7
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = color * 0.3
	material.normal_enabled = true
	material.normal_texture = normal_map
	material.normal_scale = 1.5
	return material


func create_spiral_column(color: Color, index: int) -> Dictionary:
	# Creates a single, complete melting column and returns metadata for animation
	var column_node := Node3D.new()
	column_node.name = "BerniniColumn_%d" % index

	var shaft := MeshInstance3D.new()
	shaft.name = "ColumnShaft"
	var base_melt_phase = clamp(0.45 + index * 0.1, 0.05, 1.0)
	shaft.mesh = generate_spiral_column_mesh(base_melt_phase)

	var material := create_shaft_material(color)
	if displacement_shader:
		shaft.material_override = material
	else:
		shaft.set_surface_override_material(0, material)

	column_node.add_child(shaft)

	var base := add_column_base(column_node, color, index)
	var capital := add_column_capital(column_node, color, index)

	return {
		"node": column_node,
		"shaft": shaft,
		"material": material,
		"index": index,
		"color": color,
		"base": base,
		"capital": capital,
		"base_melt_phase": base_melt_phase
	}

func create_crackle_normal_map() -> ImageTexture:
	# Create a procedural crackle/crack pattern for surface detail
	var size = 512
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)

	# Generate crackle pattern using Voronoi-like cellular noise
	for y in range(size):
		for x in range(size):
			var crack_value = generate_crackle_value(x, y, size)

			# Convert height value to normal map (RGB = XYZ)
			# Blue channel is "up", red/green are horizontal offsets
			var normal_x = 0.5  # Neutral
			var normal_y = 0.5  # Neutral
			var normal_z = crack_value  # Height variation

			# Calculate gradients for proper normal mapping
			var crack_left = generate_crackle_value(x - 1, y, size)
			var crack_right = generate_crackle_value(x + 1, y, size)
			var crack_up = generate_crackle_value(x, y - 1, size)
			var crack_down = generate_crackle_value(x, y + 1, size)

			# Compute normal from height gradients
			var dx = (crack_right - crack_left) * 2.0
			var dy = (crack_down - crack_up) * 2.0

			normal_x = 0.5 + dx * 0.5
			normal_y = 0.5 + dy * 0.5
			normal_z = 0.5 + 0.5  # Pointing mostly upward

			var color = Color(normal_x, normal_y, normal_z)
			image.set_pixel(x, y, color)

	var texture = ImageTexture.create_from_image(image)
	return texture

func generate_crackle_value(x: int, y: int, size: int) -> float:
	# Generate a crackle pattern using multi-scale noise
	var fx = float(x) / size
	var fy = float(y) / size

	# Multiple frequencies for detail
	var value = 0.0

	# Large cracks
	value += cellular_noise(fx * 4.0, fy * 4.0) * 0.5

	# Medium cracks
	value += cellular_noise(fx * 8.0, fy * 8.0) * 0.3

	# Fine surface texture
	value += cellular_noise(fx * 16.0, fy * 16.0) * 0.2

	return clamp(value, 0.0, 1.0)

func cellular_noise(x: float, y: float) -> float:
	# Simple cellular/Voronoi noise approximation for cracks
	var cell_x = floor(x)
	var cell_y = floor(y)

	var min_dist = 999.0

	# Check neighboring cells
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var neighbor_x = cell_x + dx
			var neighbor_y = cell_y + dy

			# Generate pseudo-random point in cell
			var point_x = neighbor_x + pseudo_random(neighbor_x * 127.1 + neighbor_y * 311.7)
			var point_y = neighbor_y + pseudo_random(neighbor_x * 269.5 + neighbor_y * 183.3)

			# Distance to point
			var dist = sqrt((x - point_x) * (x - point_x) + (y - point_y) * (y - point_y))
			min_dist = min(min_dist, dist)

	# Create crack pattern: dark lines where distance is small
	var crack = smoothstep(0.0, 0.15, min_dist)

	return crack

func pseudo_random(seed: float) -> float:
	# Simple pseudo-random function
	return fmod(sin(seed) * 43758.5453, 1.0)

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func generate_spiral_column_mesh(melt_phase: float = 0.5) -> Mesh:
	# Core function with EXTREME melting, overhangs, and organic deformations
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Generate vertices with melting deformation
	for i in range(vertical_segments + 1):
		var v = float(i) / vertical_segments # Vertical progress (0.0 to 1.0)

		# MELTING: Height gets compressed more as we go up
		var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
		var height = v * column_height - melt_factor * 2.0

		# Calculate the spiral center offset with EXTREME amplitudes
		var spiral_angle = v * spiral_density * 2.0 * PI
		var center_offset_x = sin(spiral_angle) * sine_amplitude
		var center_offset_z = cos(spiral_angle) * cosine_amplitude

		# OVERHANG: Make top sections lean outward dramatically
		var overhang = pow(v, 2.0) * overhang_factor
		center_offset_x += sin(spiral_angle * 0.5) * overhang
		center_offset_z += cos(spiral_angle * 0.5) * overhang

		# Multiple wave frequencies for organic complexity
		var wave1 = sin(v * PI * 6) * 0.15
		var wave2 = cos(v * PI * 12) * 0.08
		var wave3 = sin(v * PI * 20) * 0.04
		center_offset_x += wave1 + wave2 + wave3
		center_offset_z += wave1 - wave2 + wave3

		# BULGES: Organic expanding and contracting
		var bulge = sin(v * PI * 5 + melt_phase * PI) * bulge_amplitude
		var radius_variation = 1.0 + bulge + sin(v * PI * 3) * 0.2

		# Add asymmetric chaos
		var chaos_x = sin(v * 173.5) * chaos_factor
		var chaos_z = cos(v * 271.3) * chaos_factor
		center_offset_x += chaos_x
		center_offset_z += chaos_z

		# Create a ring of vertices at the current height
		for j in range(radial_segments + 1):
			var u = float(j) / radial_segments
			var angle = u * 2.0 * PI + v * twist_factor * 2.0 * PI

			# Add per-vertex randomness for organic texture
			var vertex_chaos = sin(u * 234.7 + v * 157.3) * chaos_factor * 0.3

			# RIBS/FLUTES: Create vertical profile grooves
			var rib_angle = u * rib_count * 2.0 * PI  # Angle for rib pattern
			var rib_profile = pow(abs(sin(rib_angle)), rib_sharpness)  # Sharp peaks/valleys
			var rib_offset = rib_profile * rib_depth  # Depth of the groove

			# Vary rib depth along height for organic feel
			var rib_height_variation = 1.0 + sin(v * PI * 3) * 0.3
			rib_offset *= rib_height_variation

			# Apply rib offset to radius (pushing vertices inward at grooves)
			var ribbed_radius = (column_radius * radius_variation - rib_offset)

			# Calculate vertex position with ALL deformations including ribs
			var x = cos(angle) * ribbed_radius + center_offset_x + vertex_chaos
			var z = sin(angle) * ribbed_radius + center_offset_z + vertex_chaos
			var vertex = Vector3(x, height, z)

			# Calculate normal considering the rib profile
			var rib_normal_offset = -sin(rib_angle) * rib_depth * rib_sharpness
			var tangent = Vector3(-sin(angle), 0, cos(angle))
			var radial_dir = Vector3(cos(angle), 0, sin(angle))
			var normal = (radial_dir + tangent * rib_normal_offset).normalized()

			# Add the vertex data
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(vertex)
	
	# Create the triangle faces that connect the vertices
	for i in range(vertical_segments):
		for j in range(radial_segments): # FIX: Loop only to radial_segments
			# Get indices for the four corners of a quad
			var a = i * (radial_segments + 1) + j
			var b = i * (radial_segments + 1) + j + 1
			var c = (i + 1) * (radial_segments + 1) + j
			var d = (i + 1) * (radial_segments + 1) + j + 1
			
			# Create the first triangle of the quad
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			
			# Create the second triangle of the quad
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	
	# Finalize the mesh generation
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()

func create_tube_trail_base_mesh() -> Mesh:
	"""Create a tube trail mesh for the column base"""
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Tube parameters
	var base_radius = column_radius * 2.0
	var top_radius = column_radius * 1.5
	var height = 0.5
	var segments = radial_segments
	var rings = 8  # Number of vertical rings for the tube
	
	# Generate vertices for the tube
	for i in range(rings + 1):
		var v = float(i) / rings  # Vertical progress (0.0 to 1.0)
		var current_height = v * height
		var current_radius = lerp(base_radius, top_radius, v)
		
		# Create a ring of vertices
		for j in range(segments + 1):
			var u = float(j) / segments  # Radial progress (0.0 to 1.0)
			var angle = u * 2.0 * PI
			
			# Calculate vertex position
			var x = cos(angle) * current_radius
			var z = sin(angle) * current_radius
			var vertex = Vector3(x, current_height, z)
			
			# Calculate normal (pointing outward from center)
			var normal = Vector3(x, 0, z).normalized()
			
			# Add vertex data
			st.set_normal(normal)
			st.set_uv(Vector2(u, v))
			st.add_vertex(vertex)
	
	# Create triangle faces
	for i in range(rings):
		for j in range(segments):
			# Get indices for the four corners of a quad
			var a = i * (segments + 1) + j
			var b = i * (segments + 1) + j + 1
			var c = (i + 1) * (segments + 1) + j
			var d = (i + 1) * (segments + 1) + j + 1
			
			# Create the first triangle of the quad
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			
			# Create the second triangle of the quad
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	
	# Finalize the mesh
	st.generate_normals()
	st.generate_tangents()
	
	return st.commit()

func add_column_base(column_node: Node3D, color: Color, index: int) -> MeshInstance3D:
	# Adds a melting base to the bottom of a column
	var base = MeshInstance3D.new()
	base.mesh = create_tube_trail_base_mesh()
	base.position.y = -0.25

	if displacement_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = displacement_shader
		var base_color = color.darkened(0.2)
		shader_material.set_shader_parameter("base_color", Vector3(base_color.r, base_color.g, base_color.b))
		shader_material.set_shader_parameter("time_scale", 0.4)
		shader_material.set_shader_parameter("cell_scale", 6.0)
		shader_material.set_shader_parameter("displacement_strength", 0.6)
		shader_material.set_shader_parameter("animation_speed", 0.3)
		shader_material.set_shader_parameter("vertex_displacement", 0.03)
		shader_material.set_shader_parameter("emission_strength", 0.3)
		shader_material.set_shader_parameter("animate", true)
		base.material_override = shader_material
	else:
		var normal_map = create_crackle_normal_map()
		var material = StandardMaterial3D.new()
		material.albedo_color = color.darkened(0.2)
		material.metallic = 0.7
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.2
		material.normal_enabled = true
		material.normal_texture = normal_map
		material.normal_scale = 1.5
		base.set_surface_override_material(0, material)

	column_node.add_child(base)
	return base

func add_column_capital(column_node: Node3D, color: Color, index: int) -> MeshInstance3D:
	# Adds a melting, drooping capital to the top
	var capital = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.bottom_radius = column_radius * 1.5
	cylinder_mesh.top_radius = column_radius * 0.8  # Melting inward
	cylinder_mesh.height = 0.8
	cylinder_mesh.radial_segments = radial_segments
	capital.mesh = cylinder_mesh
	capital.position.y = column_height * 0.8  # Drooped down due to melting

	if displacement_shader:
		var shader_material = ShaderMaterial.new()
		shader_material.shader = displacement_shader
		var cap_color = color.lightened(0.1)
		shader_material.set_shader_parameter("base_color", Vector3(cap_color.r, cap_color.g, cap_color.b))
		shader_material.set_shader_parameter("time_scale", 0.5)
		shader_material.set_shader_parameter("cell_scale", 10.0)
		shader_material.set_shader_parameter("displacement_strength", 1.0)
		shader_material.set_shader_parameter("animation_speed", 0.6)
		shader_material.set_shader_parameter("vertex_displacement", 0.08)
		shader_material.set_shader_parameter("emission_strength", 0.6)
		shader_material.set_shader_parameter("animate", true)
		capital.material_override = shader_material
	else:
		var normal_map = create_crackle_normal_map()
		var material = StandardMaterial3D.new()
		material.albedo_color = color.lightened(0.1)
		material.metallic = 0.7
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = color * 0.4
		material.normal_enabled = true
		material.normal_texture = normal_map
		material.normal_scale = 1.5
		capital.set_surface_override_material(0, material)

	column_node.add_child(capital)
	return capital

# --- Scene Setup Functions ---

func create_platform() -> void:
	# Creates a vibrant queer platform
	var platform = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(10.0, 0.3, 10.0)
	platform.mesh = box_mesh
	platform.position.y = -0.5

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.15, 0.2, 1.0)  # Dark base
	material.metallic = 0.8
	material.roughness = 0.4
	material.emission_enabled = true
	material.emission = Color(0.5, 0.2, 0.8, 1.0) * 0.1  # Purple glow
	platform.set_surface_override_material(0, material)

	add_child(platform)

func create_lighting() -> void:
	# Dramatic queer lighting
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 0.8
	dir_light.light_color = Color(1.0, 0.8, 1.0)  # Pink tint
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)

	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_energy = 0.4
	ambient_light.light_color = Color(0.6, 0.8, 1.0)  # Blue tint
	ambient_light.rotation_degrees = Vector3(45, -135, 0)
	add_child(ambient_light)

	# Add colored spotlights for each column
	for i in range(column_positions.size()):
		var pos = column_positions[i]
		var color = material_color
		if queer_colors.size() > 0:
			color = queer_colors[i % queer_colors.size()]

		var spotlight = SpotLight3D.new()
		spotlight.position = pos + Vector3(0, column_height * 1.5, 0)
		var direction: Vector3 = (pos - spotlight.position).normalized()
		var up_hint: Vector3 = Vector3.FORWARD if abs(direction.dot(Vector3.UP)) > 0.95 else Vector3.UP
		spotlight.look_at_from_position(spotlight.position, pos, up_hint)
		spotlight.light_energy = 3.0
		spotlight.light_color = color
		spotlight.spot_range = column_height * 2.5
		spotlight.spot_angle = 35.0
		add_child(spotlight)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

