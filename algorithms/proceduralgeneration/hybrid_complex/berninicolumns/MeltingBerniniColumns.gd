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

# ── THE TRIO (stand:trio) — N2, 12 September 2026 ───────────────────────────
#
# WHAT THE ROOM ASKS. Can you tell how a body changes just by looking at its
# strange shape? The hall's own description claimed 3D Perlin erosion and
# reversible entropy; the shipped melt is a sine, there was no field anywhere in
# it, and nine columns all moving at once let nobody compare anything. So the
# staging is a CONTROLLED COMPARISON: three columns in one frame, the same mesh
# at the same resolution, the same material, the same mapped displacement range
# and the same viewing distance — differing in ONE thing, which is what drives
# the melt.
#
#   baseline   a fixed phase. The column you can recognise as a column.
#   periodic   sin(time * melt_speed) * 0.5 + 0.5 — the shipped driver, unchanged.
#   field      a real coherent field (FastNoiseLite, seeded), sampled along time
#              and mapped through the SAME [0,1] phase into the SAME function.
#              Newly implemented for this room, and labelled as such.
#
# WHICH COLUMN IS WHICH IS NOT WRITTEN ANYWHERE until REVEAL is pressed, and the
# three drivers are dealt to the three positions from the room's own seed, so the
# arrangement is reproducible and not learnable. A shape does not say what made
# it, and a label before the looking would answer the question the room asks.
#
#   stand:none  SHIPPED. The ring of nine, built and animated exactly as before.
#   stand:trio  The three, the plinths, the instrument, FREEZE · REVEAL · SPIN ·
#               MARBLE, and a rebuild bounded to TRIO_HZ with its cost measured.
#
# FREEZE stops time, so the geometry is repeatable and can be inspected; SPIN
# turns the whole column without touching the deformation, so rotation cannot be
# mistaken for melting; MARBLE swaps the veined shader for a matte material, so
# the material's noise cannot be mistaken for the geometric driver. Nothing here
# carries a collider: these are display columns and hold nothing up.
@export_enum("none", "trio") var stand: String = "none"
@export var field_seed: int = -1

const TRIO_GAP: float = 2.2       # column to column
const TRIO_H: float = 2.55        # under a three-metre hall's wall
const TRIO_R: float = 0.20
const TRIO_VSEG: int = 40         # bounded resolution: the shipped 80 x 24 is 2025
const TRIO_RSEG: int = 16         # vertices a frame, per column, forever
const TRIO_MELT: float = 0.35     # phase 0..1 maps to a 0.00..0.70 m drop at the top
const TRIO_HZ: float = 12.0       # bounded rebuild rate
const TRIO_BASE_PHASE: float = 0.10
const TRIO_DRIVERS: PackedStringArray = ["baseline", "periodic", "field"]

var _stand_root: Node3D = null
var _trio: Array = []
var _readout: Label3D = null
var _noise: FastNoiseLite = null
var _named_seed: int = 0
var _frozen: bool = false
var _revealed: bool = false
var _marble_on: bool = true
var _spin_on: bool = false
var _rebuild_ms: float = 0.0
var _rebuilds: int = 0
var _next_rebuild: float = 0.0
var _next_readout: float = 0.0
var _order: Array = []
var _samples: Array = []
var _amp_scale: float = 1.0       # 1.0 is the shipped mesh, to the vertex

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

	if stand == "trio":
		_prepare_trio()
		_build_trio()
		return

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
	if stand == "trio":
		_trio_process(delta)
		return

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
		var wave1 = sin(v * PI * 6) * 0.15 * _amp_scale
		var wave2 = cos(v * PI * 12) * 0.08 * _amp_scale
		var wave3 = sin(v * PI * 20) * 0.04 * _amp_scale
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
			var vertex_chaos = sin(u * 234.7 + v * 157.3) * chaos_factor * 0.3 * _amp_scale

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


## The map's own hand. `stand` asks for the trio, `seed` names the field, `speed`
## the sine's rate. Shipped placements send none of these and reach none of it.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if config.has("stand"):
		var sv: String = str(config["stand"]).strip_edges().to_lower()
		stand = "trio" if sv in ["trio", "three", "compare", "colonnade"] else "none"
	if config.has("seed"):
		field_seed = int(config["seed"])
	if config.has("speed"):
		melt_speed = float(config["speed"])
	if config.has("count"):
		column_count = maxi(1, int(config["count"]))


# ═════════════════════════════════════════════════════════════════════
# THE TRIO — stand:trio. Nothing below runs at stand:none.
# ═════════════════════════════════════════════════════════════════════

## A five-digit name for the field, and the deal that decides which driver stands
## where. Both come from the one seed, so the room is repeatable and the
## arrangement is not something a reader can learn once and carry between visits.
func _prepare_trio() -> void:
	if field_seed < 0:
		var namer := RandomNumberGenerator.new()
		namer.randomize()
		field_seed = namer.randi_range(10000, 99999)
	_named_seed = field_seed
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = field_seed
	_noise.frequency = 0.35
	var deal := RandomNumberGenerator.new()
	deal.seed = field_seed + 7
	_order = []
	for d in TRIO_DRIVERS:
		_order.append(d)
	for i in range(_order.size() - 1, 0, -1):
		var j: int = deal.randi_range(0, i)
		var tmp = _order[i]; _order[i] = _order[j]; _order[j] = tmp
	# the trio's own frame: three columns a visitor can hold in one look, at a
	# resolution a room can afford, with the melt mapped into a range both drivers
	# share exactly
	column_height = TRIO_H
	column_radius = TRIO_R
	vertical_segments = TRIO_VSEG
	radial_segments = TRIO_RSEG
	melt_strength = TRIO_MELT
	rotate_columns = false
	animate_melting = false
	show_platform = false
	# EVERY DEFORMATION AMPLITUDE IN THIS FILE IS IN METRES, and they were tuned for a
	# column eight to ten metres tall. On a 2.55 m one they tear the shape into flying
	# shards (measured: the first trio photographed as stacked ribbons, not columns), and
	# Astra's card asks for a RECOGNISABLE baseline column. So they scale with the height.
	var k: float = TRIO_H / 10.0
	_amp_scale = k
	spiral_density = 1.0            # one turn over the height: a spiral column, not a corkscrew
	sine_amplitude = 0.30 * k
	cosine_amplitude = 0.30 * k
	twist_factor = 0.5
	overhang_factor = 0.25 * k
	bulge_amplitude = 0.22 * k
	chaos_factor = 0.08 * k
	rib_count = 14
	rib_depth = 0.14 * k
	rib_sharpness = 2.0


## The phase each driver asks for at time t. One function, three answers; every
## one of them lands in [0,1] and goes through the same mesh call.
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE


## What a phase costs the column: the top loses this much height. Both drivers
## map through it, so the displacement RANGE is shared and the comparison is of
## drivers and nothing else.
func mapped_drop(phase: float) -> float:
	return 2.0 * melt_strength * phase


func _build_trio() -> void:
	var HangarKit := load("res://commons/artifacts/_hangar/hangar_kit.gd")
	_stand_root = Node3D.new()
	_stand_root.name = "Trio"
	add_child(_stand_root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.62, 0.60, 0.56)
	stone.roughness = 0.9
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.11, 0.115, 0.13)
	dark.roughness = 0.85

	_trio.clear()
	for slot in range(3):
		var kind: String = str(_order[slot])
		var x: float = (float(slot) - 1.0) * TRIO_GAP
		var plinth: MeshInstance3D = HangarKit.box(Vector3(x, 0.11, 0.0), Vector3(0.86, 0.22, 0.86), stone)
		plinth.name = "Plinth_%d" % slot
		_stand_root.add_child(plinth)
		var data: Dictionary = create_spiral_column(Color(0.86, 0.84, 0.80), slot)
		var node: Node3D = data["node"]
		node.name = "Column_%d" % slot
		node.position = Vector3(x, 0.22, 0.0)
		_stand_root.add_child(node)
		# a plate that says nothing yet: the shape is the only evidence until asked
		var plate_root := Node3D.new()
		plate_root.name = "Plate_%d" % slot
		plate_root.position = Vector3(x, 0.13, 0.45)
		_stand_root.add_child(plate_root)
		plate_root.add_child(HangarKit.box(Vector3.ZERO, Vector3(0.52, 0.11, 0.012), dark))
		var label := Label3D.new()
		label.name = "Text"
		label.text = "?"
		label.pixel_size = 0.0016
		label.font_size = 20
		label.modulate = Color(0.88, 0.94, 1.0)
		label.outline_size = 3
		label.outline_modulate = Color(0, 0, 0, 1)
		label.position = Vector3(0, 0, 0.010)
		plate_root.add_child(label)
		data["driver"] = kind
		data["slot"] = slot
		data["plate"] = label
		data["phase"] = driver_phase(kind, 0.0)
		_trio.append(data)
		_rebuild_column(data, data["phase"])

	# the instrument: what both drivers are doing right now, and in what range
	var plate_case := Node3D.new()
	plate_case.name = "Readout"
	plate_case.set_meta("em_local_instrument", true)
	plate_case.position = Vector3(-0.55, 1.02, 1.60)
	plate_case.rotation_degrees = Vector3(-16, 0, 0)
	_stand_root.add_child(plate_case)
	plate_case.add_child(HangarKit.box(Vector3.ZERO, Vector3(1.18, 0.26, 0.014), dark))
	_readout = Label3D.new()
	_readout.name = "Text"
	_readout.pixel_size = 0.00092
	_readout.font_size = 17
	_readout.line_spacing = 0.5
	_readout.modulate = Color(0.88, 0.94, 1.0)
	_readout.outline_size = 3
	_readout.outline_modulate = Color(0, 0, 0, 1)
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_readout.position = Vector3(-0.565, 0.118, 0.010)
	plate_case.add_child(_readout)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	if RackTpl != null:
		var panel: Node3D = RackTpl.create_panel("", [
			[{"type": "button", "label": "FREEZE"}, {"type": "button", "label": "REVEAL"}],
			[{"type": "button", "label": "SPIN"}, {"type": "button", "label": "MARBLE"}],
		], true)
		panel.name = "Panel"
		panel.set_meta("em_local_instrument", true)
		panel.position = Vector3(0.92, 1.06, 1.62)
		panel.rotation_degrees = Vector3(-26, 0, 0)
		panel.scale = Vector3(1.4, 1.4, 1.4)
		_stand_root.add_child(panel)
		var actions := {"Btn_0": func(): toggle_freeze(), "Btn_1": func(): reveal_drivers(), "Btn_2": func(): toggle_spin(), "Btn_3": func(): toggle_marble()}
		for btn_name in actions.keys():
			var btn: Node = panel.find_child(btn_name, true, false)
			if btn == null:
				continue
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area != null and area.has_signal("button_pressed"):
				var action: Callable = actions[btn_name]
				area.button_pressed.connect(func(_b): action.call())
	create_lighting()
	_update_trio_readout()


## One column's mesh, rebuilt at a phase, with the cost kept. This is the only
## place the trio spends anything, and the readout prints what it spent.
func _rebuild_column(data: Dictionary, phase: float) -> void:
	var shaft: MeshInstance3D = data.get("shaft")
	if shaft == null or not is_instance_valid(shaft):
		return
	var t0: int = Time.get_ticks_usec()
	shaft.mesh = generate_spiral_column_mesh(phase)
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	_rebuilds += 1
	_rebuild_ms = ms if _rebuilds <= 1 else (_rebuild_ms * 0.9 + ms * 0.1)
	data["phase"] = phase
	data["drop"] = mapped_drop(phase)


func _trio_process(delta: float) -> void:
	if not _frozen:
		time += delta
	for data in _trio:
		var mat = data.get("material")
		if mat is ShaderMaterial and (mat as ShaderMaterial).shader == marble_shader:
			(mat as ShaderMaterial).set_shader_parameter("u_time", time)
	if _spin_on:
		for data in _trio:
			var node: Node3D = data.get("node")
			if node != null and is_instance_valid(node):
				node.rotation.y += delta * rotation_speed * 2.0
	# the rebuild is bounded: a column is remade at most TRIO_HZ times a second,
	# and never at all while frozen or at the baseline
	if not _frozen and time >= _next_rebuild:
		_next_rebuild = time + 1.0 / TRIO_HZ
		for data in _trio:
			if str(data.get("driver")) == "baseline":
				continue
			_rebuild_column(data, driver_phase(str(data.get("driver")), time))
		if _samples.size() < 600:
			_samples.append({"t": snappedf(time, 0.01),
				"periodic": snappedf(driver_phase("periodic", time), 0.001),
				"field": snappedf(driver_phase("field", time), 0.001)})
	if time >= _next_readout:
		_next_readout = time + 0.2
		_update_trio_readout()


## The instrument. It says what each driver is doing and what that costs the
## column in metres — and it does NOT say which column is which until asked.
func _update_trio_readout() -> void:
	if _readout == null or not is_instance_valid(_readout):
		return
	var p: float = driver_phase("periodic", time)
	var fld: float = driver_phase("field", time)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("t %6.2f s%s · seed %d · same mesh %d×%d · same range 0.00–%.2f m" % [
		time, ("  FROZEN" if _frozen else ""), _named_seed, vertical_segments, radial_segments, mapped_drop(1.0)])
	lines.append("periodic  phase %.3f → drop %.2f m" % [p, mapped_drop(p)])
	lines.append("field     phase %.3f → drop %.2f m" % [fld, mapped_drop(fld)])
	lines.append("rebuild %.1f ms · at most %d/s · marble %s · spin %s" % [
		_rebuild_ms, int(TRIO_HZ), ("on" if _marble_on else "off"), ("on" if _spin_on else "off")])
	if not _revealed:
		lines.append("which column is which: press REVEAL — after you have looked")
	_readout.text = "\n".join(lines)


## Stop every changing input. The geometry stands still and can be inspected,
## and a rebuild at the same time gives the same mesh.
func toggle_freeze() -> void:
	if stand != "trio":
		return
	_frozen = not _frozen
	_update_trio_readout()


## Name the drivers, after the looking.
func reveal_drivers() -> void:
	if stand != "trio":
		return
	_revealed = not _revealed
	for data in _trio:
		var lbl: Label3D = data.get("plate")
		if lbl != null and is_instance_valid(lbl):
			lbl.text = (str(data.get("driver")).to_upper() if _revealed else "?")
	_update_trio_readout()


## Turn the whole column without touching its shape, so a body that is turning
## cannot be mistaken for a body that is changing.
func toggle_spin() -> void:
	if stand != "trio":
		return
	_spin_on = not _spin_on
	_update_trio_readout()


## The veins are a material, not a geometry. Take them off and the shape is all
## that is left to go on.
func toggle_marble() -> void:
	if stand != "trio":
		return
	_marble_on = not _marble_on
	for data in _trio:
		var shaft: MeshInstance3D = data.get("shaft")
		if shaft == null or not is_instance_valid(shaft):
			continue
		if _marble_on:
			shaft.material_override = data.get("material")
		else:
			var matte := StandardMaterial3D.new()
			matte.albedo_color = Color(0.80, 0.78, 0.74)
			matte.roughness = 0.85
			matte.metallic = 0.0
			shaft.material_override = matte
	_update_trio_readout()


## The trio as the room can read it: the seed, the deal, both drivers now, what
## each column is doing, what the rebuild costs, and the samples taken so far.
func trio_state() -> Dictionary:
	var cols: Array = []
	for data in _trio:
		var shaft: MeshInstance3D = data.get("shaft")
		var mesh: Mesh = shaft.mesh if shaft != null and is_instance_valid(shaft) else null
		var aabb: AABB = mesh.get_aabb() if mesh != null else AABB()
		var verts: int = 0
		if mesh != null and mesh.get_surface_count() > 0:
			verts = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
		var node: Node3D = data.get("node")
		cols.append({
			"slot": data.get("slot"), "driver": data.get("driver"),
			"phase": snappedf(float(data.get("phase", 0.0)), 0.001),
			"drop": snappedf(float(data.get("drop", 0.0)), 0.001),
			"verts": verts,
			"top": snappedf(aabb.position.y + aabb.size.y, 0.001),
			"aabb": [snappedf(aabb.size.x, 0.001), snappedf(aabb.size.y, 0.001), snappedf(aabb.size.z, 0.001)],
			"yaw": snappedf(node.rotation_degrees.y, 0.01) if node != null else 0.0,
			"plate": str((data.get("plate") as Label3D).text) if data.get("plate") != null else "",
			"marble": (shaft.material_override is ShaderMaterial) if shaft != null else false,
		})
	return {
		"seed": _named_seed, "order": _order, "time": snappedf(time, 0.01),
		"frozen": _frozen, "revealed": _revealed, "spin": _spin_on, "marble": _marble_on,
		"range": [0.0, snappedf(mapped_drop(1.0), 0.001)],
		"periodic_now": snappedf(driver_phase("periodic", time), 0.001),
		"field_now": snappedf(driver_phase("field", time), 0.001),
		"rebuild_ms": snappedf(_rebuild_ms, 0.01), "rebuilds": _rebuilds, "rebuild_hz": TRIO_HZ,
		"segments": [vertical_segments, radial_segments],
		"columns": cols, "samples": _samples,
	}


## Rebuild one column at a named time, whatever the clock says: the probe's way
## of asking whether the geometry is a function of the driver and nothing else.
func rebuild_at(slot: int, t: float) -> Dictionary:
	if slot < 0 or slot >= _trio.size():
		return {}
	var data: Dictionary = _trio[slot]
	var phase: float = driver_phase(str(data.get("driver")), t)
	_rebuild_column(data, phase)
	var shaft: MeshInstance3D = data.get("shaft")
	var mesh: Mesh = shaft.mesh if shaft != null else null
	var checksum: float = 0.0
	if mesh != null and mesh.get_surface_count() > 0:
		var verts: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for i in range(0, verts.size(), 17):
			checksum += verts[i].x * 1.7 + verts[i].y * 2.3 + verts[i].z * 3.1
	return {"slot": slot, "driver": data.get("driver"), "t": snappedf(t, 0.001),
		"phase": snappedf(phase, 0.0001), "drop": snappedf(mapped_drop(phase), 0.0001),
		"checksum": snappedf(checksum, 0.0001)}
