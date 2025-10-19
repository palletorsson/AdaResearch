extends Node3D

# Enhanced Configuration variables
@export_category("Ultra-Vivid Sculpture Configuration")
@export var num_petals: int = 6
@export var num_tendrils: int = 4
@export var num_orbital_rings: int = 2
@export var generate_on_ready: bool = true
@export var animation_intensity: float = 1.0
@export var color_shift_speed: float = 1.0
@export var morphing_amplitude: float = 0.3
@export var harmonic_layers: int = 3
@export var detail_scale: float = 0.6
@export var vertical_offset: float = 2.0
@export var include_tendrils: bool = false
@export var include_orbital_rings: bool = false
@export var include_harmonic_clusters: bool = false
@export var include_energy_streams: bool = false

# Time tracking for sine/cosine animations
var time: float = 0.0
var color_time: float = 0.0
var morph_time: float = 0.0
var pulse_time: float = 0.0

# Enhanced color palettes with spectral richness
var kusama_colors = [
	Color(1.0, 0.0, 0.2),    # Crimson
	Color(1.0, 0.3, 0.7),    # Hot Pink
	Color(0.0, 0.9, 0.3),    # Emerald
	Color(0.0, 0.6, 1.0),    # Azure
	Color(1.0, 0.8, 0.0),    # Gold
	Color(0.7, 0.0, 1.0),    # Purple
	Color(0.0, 1.0, 0.8),    # Cyan
	Color(1.0, 0.4, 0.0),    # Orange
]

var plasma_spectrum = [
	Color(0.0, 0.0, 0.3),    # Deep Blue
	Color(0.2, 0.0, 0.8),    # Violet
	Color(0.8, 0.0, 0.6),    # Magenta
	Color(1.0, 0.2, 0.0),    # Red-Orange
	Color(1.0, 0.8, 0.0),    # Yellow
	Color(1.0, 1.0, 0.8),    # White-hot
]

var aurora_colors = [
	Color(0.0, 1.0, 0.4),    # Aurora Green
	Color(0.0, 0.8, 1.0),    # Aurora Blue
	Color(1.0, 0.2, 1.0),    # Aurora Purple
	Color(1.0, 1.0, 0.0),    # Aurora Yellow
]

var detail_scale_clamped: float = 0.8

# Arrays to store dynamic elements
var dynamic_petals: Array = []
var morphing_tendrils: Array = []
var orbital_elements: Array = []
var harmonic_dots: Array = []
var energy_streams: Array = []

func _ready():
	detail_scale_clamped = clamp(detail_scale, 0.35, 1.3)
	if abs(vertical_offset) > 0.001:
		translate(Vector3(0, vertical_offset, 0))
	if generate_on_ready:
		generate_ultra_vivid_sculpture()

func _process(delta):
	time += delta * animation_intensity
	color_time += delta * color_shift_speed
	morph_time += delta * 0.7
	pulse_time += delta * 1.5
	
	animate_all_elements(delta)

func generate_ultra_vivid_sculpture():
	# Create the hyper-dynamic center core
	var core = create_ultra_vivid_core()
	add_child(core)
	
	# Create morphing petals with sine wave dynamics
	create_morphing_petals()
	
	# Optional modules for heavier geometry
	if include_tendrils:
		create_undulating_tendrils()
	if include_orbital_rings:
		create_orbital_rings()
	if include_harmonic_clusters:
		create_harmonic_clusters()
	if include_energy_streams:
		create_energy_streams()
	
	# Set up enhanced environment
	setup_ultra_vivid_environment()

func create_ultra_vivid_core():
	var core = Node3D.new()
	core.name = "UltraVividCore"
	
	# Create multiple layered spheres for depth
	for layer in range(4):
		var sphere = MeshInstance3D.new()
		sphere.name = "CoreLayer_" + str(layer)
		
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.9 - (layer * 0.15)
		sphere_mesh.height = sphere_mesh.radius * 2
		sphere_mesh.radial_segments = max(24, int(round(64 * detail_scale_clamped)))
		sphere_mesh.rings = max(16, int(round(32 * detail_scale_clamped)))
		sphere.mesh = sphere_mesh
		
		# Create ultra-vivid material with sine-based properties
		var material = StandardMaterial3D.new()
		material.albedo_color = kusama_colors[layer % kusama_colors.size()]
		material.roughness = 0.05
		material.metallic = 0.3 + sin(layer) * 0.2
		material.metallic_specular = 0.9
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.4
		
		# Add dynamic transparency with sine waves
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.7 + sin(layer * 2) * 0.2
		
		sphere.material_override = material
		
		# Add ultra-dense polka dot patterns
		add_ultra_vivid_polka_dots(sphere, material.albedo_color, 1.2 - (layer * 0.2), layer % 2 == 0)
		
		core.add_child(sphere)
	
	# Create pulsing inner spirals with multiple harmonics
	for harmonic in range(harmonic_layers):
		var spiral = create_harmonic_spiral(0.5 + harmonic * 0.1, harmonic)
		spiral.position.y = sin(harmonic) * 0.1
		core.add_child(spiral)
	
	return core

func create_morphing_petals():
	dynamic_petals.clear()
	
	for i in range(num_petals):
		var petal = create_morphing_petal(i)
		add_child(petal)
		dynamic_petals.append(petal)

func create_morphing_petal(index):
	var petal = Node3D.new()
	petal.name = "MorphingPetal_" + str(index)
	
	# Calculate dynamic position using sine waves
	var base_angle = (2 * PI * index) / num_petals
	var radius = 1.8 + sin(index * 0.5) * 0.3
	var petal_color = kusama_colors[index % kusama_colors.size()]
	
	# Create multiple petal layers for richness
	for layer in range(3):
		var petal_mesh = MeshInstance3D.new()
		petal_mesh.name = "PetalLayer_" + str(layer)
		
		# Create enhanced petal mesh with sine-based deformation
		var mesh = create_enhanced_petal_mesh(layer)
		petal_mesh.mesh = mesh
		
		# Create vivid material with dynamic properties
		var material = StandardMaterial3D.new()
		var layer_color = petal_color.lerp(aurora_colors[layer % aurora_colors.size()], 0.3)
		material.albedo_color = layer_color
		material.roughness = 0.1 - layer * 0.02
		material.metallic = 0.2 + layer * 0.1
		material.metallic_specular = 0.9
		material.emission_enabled = true
		material.emission = layer_color * (0.2 + layer * 0.1)
		
		# Add transparency for layering effect
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8 - layer * 0.15
		
		petal_mesh.material_override = material
		
		# Position with sine-based offset
		var layer_offset = sin(layer * PI) * 0.1
		petal_mesh.position = Vector3(0, layer_offset, layer * 0.05)
		petal_mesh.rotation_degrees = Vector3(0, 0, -30 - layer * 5)
		
		# Add ultra-vivid dots with harmonic patterns
		add_harmonic_polka_dots(petal_mesh, material.albedo_color, 0.8, index, layer)
		
		petal.add_child(petal_mesh)
	
	# Set initial position
	petal.position = Vector3(cos(base_angle) * radius, 0, sin(base_angle) * radius)
	petal.rotation_degrees = Vector3(0, rad_to_deg(base_angle), 0)
	
	return petal

func create_enhanced_petal_mesh(layer):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Create more complex petal shape with sine-based morphing
	var segments = max(16, int(round(32 * detail_scale_clamped)))
	var rings = max(8, int(round(16 * detail_scale_clamped)))
	
	for ring in range(rings):
		for segment in range(segments):
			var u = float(segment) / segments
			var v = float(ring) / rings
			
			# Create petal shape using sine and cosine
			var angle = u * 2 * PI
			var radius_factor = sin(v * PI) * (1.0 + sin(angle * 3) * 0.2)
			var height_factor = cos(v * PI * 0.5) * (0.3 + layer * 0.1)
			
			# Apply sine-based warping for organic feel
			var warp_x = sin(v * PI * 4) * 0.1
			var warp_y = cos(u * PI * 6) * 0.05
			
			var x = cos(angle) * radius_factor * (1.0 + v) + warp_x
			var y = height_factor + warp_y
			var z = sin(angle) * radius_factor * (1.0 + v)
			
			st.set_normal(Vector3(0, 1, 0))
			st.set_uv(Vector2(u, v))
			st.add_vertex(Vector3(x, y, z))
	
	# Add triangles
	for ring in range(rings - 1):
		for segment in range(segments):
			var i1 = ring * segments + segment
			var i2 = ring * segments + (segment + 1) % segments
			var i3 = (ring + 1) * segments + segment
			var i4 = (ring + 1) * segments + (segment + 1) % segments
			
			# Triangle 1
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)
			
			# Triangle 2
			st.add_index(i2)
			st.add_index(i4)
			st.add_index(i3)
	
	st.generate_normals()
	return st.commit()

func create_undulating_tendrils():
	morphing_tendrils.clear()
	
	for i in range(num_tendrils):
		var tendril = create_undulating_tendril(i)
		add_child(tendril)
		morphing_tendrils.append(tendril)

func create_undulating_tendril(index):
	var tendril = Node3D.new()
	tendril.name = "UndulatingTendril_" + str(index)
	
	var base_angle = (2 * PI * index) / num_tendrils
	var base_segments = 12 + index % 4
	var segments = max(6, int(round(base_segments * detail_scale_clamped)))
	var base_color = plasma_spectrum[index % plasma_spectrum.size()]
	
	var tendril_segments = []
	
	for i in range(segments):
		var segment = MeshInstance3D.new()
		segment.name = "TendrilSegment_" + str(i)
		
		# Create dynamic segment shapes
		var segment_mesh = create_tendril_segment_mesh(i, segments)
		segment.mesh = segment_mesh
		
		# Create ultra-vivid material
		var material = StandardMaterial3D.new()
		var segment_color = base_color.lerp(kusama_colors[i % kusama_colors.size()], 0.4)
		material.albedo_color = segment_color
		material.roughness = 0.05
		material.metallic = 0.4
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = segment_color * 0.5
		
		segment.material_override = material
		
		# Add ultra-dense dots with sine patterns
		add_sine_wave_dots(segment, segment_color, 0.5, i)
		
		tendril.add_child(segment)
		tendril_segments.append(segment)
	
	return tendril

func create_tendril_segment_mesh(segment_index, total_segments):
	var mesh = SphereMesh.new()
	var size_factor = 1.0 - (float(segment_index) / total_segments) * 0.7
	mesh.radius = 0.2 * size_factor * (1.0 + sin(segment_index) * 0.3)
	mesh.height = mesh.radius * 2
	mesh.radial_segments = max(8, int(round(16 * detail_scale_clamped)))
	mesh.rings = max(4, int(round(8 * detail_scale_clamped)))
	return mesh

func create_orbital_rings():
	orbital_elements.clear()
	
	for ring in range(num_orbital_rings):
		var orbital_system = create_orbital_ring_system(ring)
		add_child(orbital_system)
		orbital_elements.append(orbital_system)

func create_orbital_ring_system(ring_index):
	var orbital = Node3D.new()
	orbital.name = "OrbitalRing_" + str(ring_index)
	
	var ring_radius = 3.0 + ring_index * 0.8
	var base_orbs = 8 + ring_index * 2
	var num_orbs = max(6, int(round(base_orbs * detail_scale_clamped)))
	var ring_color = aurora_colors[ring_index % aurora_colors.size()]
	
	for orb in range(num_orbs):
		var orb_node = MeshInstance3D.new()
		orb_node.name = "Orb_" + str(orb)
		
		var orb_mesh = SphereMesh.new()
		orb_mesh.radius = 0.15 + sin(orb * 0.5) * 0.05
		orb_mesh.height = orb_mesh.radius * 2
		orb_mesh.radial_segments = max(8, int(round(12 * detail_scale_clamped)))
		orb_mesh.rings = max(4, int(round(8 * detail_scale_clamped)))
		orb_node.mesh = orb_mesh
		
		# Create glowing material
		var material = StandardMaterial3D.new()
		material.albedo_color = ring_color
		material.roughness = 0.0
		material.metallic = 0.8
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = ring_color * 0.8
		
		orb_node.material_override = material
		
		# Position in ring
		var angle = (2 * PI * orb) / num_orbs
		orb_node.position = Vector3(
			cos(angle) * ring_radius,
			sin(ring_index * 2) * 0.5,
			sin(angle) * ring_radius
		)
		
		orbital.add_child(orb_node)
	
	return orbital

func create_harmonic_clusters():
	harmonic_dots.clear()
	
	var cluster_count = max(3, int(round(6 * detail_scale_clamped)))
	for cluster in range(cluster_count):
		var cluster_node = create_harmonic_cluster(cluster)
		add_child(cluster_node)
		harmonic_dots.append(cluster_node)

func create_harmonic_cluster(cluster_index):
	var cluster = Node3D.new()
	cluster.name = "HarmonicCluster_" + str(cluster_index)
	
	var base_radius = 4.0 + cluster_index * 0.5
	var cluster_color = plasma_spectrum[cluster_index % plasma_spectrum.size()]
	var harmonic_count = max(3, int(round(5 * detail_scale_clamped)))
	var dots_per_harmonic = max(6, int(round(12 * detail_scale_clamped)))

	for harmonic in range(harmonic_count):
		for dot in range(dots_per_harmonic):
			var dot_node = MeshInstance3D.new()
			dot_node.name = "HarmonicDot_" + str(harmonic) + "_" + str(dot)
			var dot_mesh = SphereMesh.new()
			dot_mesh.radius = 0.08 + sin(harmonic) * 0.02
			dot_mesh.height = dot_mesh.radius * 2
			dot_mesh.radial_segments = max(6, int(round(8 * detail_scale_clamped)))
			dot_mesh.rings = max(3, int(round(4 * detail_scale_clamped)))
			dot_node.mesh = dot_mesh
			var material = StandardMaterial3D.new()
			material.albedo_color = cluster_color
			material.roughness = 0.0
			material.metallic = 1.0
			material.metallic_specular = 1.0
			material.emission_enabled = true
			material.emission = cluster_color * 1.2
			dot_node.material_override = material
			var angle = (2 * PI * dot) / float(dots_per_harmonic)
			var radius = base_radius + sin(harmonic * PI) * 0.8
			var height = cos(harmonic * PI * 0.5) * 2.0
			dot_node.position = Vector3(
				cos(angle) * radius,
				height,
				sin(angle) * radius
			)
			cluster.add_child(dot_node)
	return cluster

func create_energy_streams():
	energy_streams.clear()
	
	var stream_count = max(4, int(round(8 * detail_scale_clamped)))
	for stream in range(stream_count):
		var stream_node = create_energy_stream(stream)
		add_child(stream_node)
		energy_streams.append(stream_node)

func create_energy_stream(stream_index):
	var stream = Node3D.new()
	stream.name = "EnergyStream_" + str(stream_index)
	
	var stream_color = aurora_colors[stream_index % aurora_colors.size()]
	var segments = max(10, int(round(20 * detail_scale_clamped)))
	
	for segment in range(segments):
		var particle = MeshInstance3D.new()
		particle.name = "StreamParticle_" + str(segment)
		
		var particle_mesh = SphereMesh.new()
		particle_mesh.radius = 0.05 + sin(segment * 0.3) * 0.02
		particle_mesh.height = particle_mesh.radius * 2
		particle_mesh.radial_segments = 6
		particle_mesh.rings = 4
		particle.mesh = particle_mesh
		
		# Ultra-bright streaming material
		var material = StandardMaterial3D.new()
		material.albedo_color = stream_color
		material.roughness = 0.0
		material.metallic = 0.9
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = stream_color * 1.5
		
		particle.material_override = material
		
		stream.add_child(particle)
	
	return stream

func create_harmonic_spiral(radius, harmonic_index):
	var spiral = Node3D.new()
	spiral.name = "HarmonicSpiral_" + str(harmonic_index)
	
	var segments = max(18, int(round((48 + harmonic_index * 8) * detail_scale_clamped)))
	var spiral_color = kusama_colors[harmonic_index % kusama_colors.size()]
	
	for i in range(segments):
		var segment = MeshInstance3D.new()
		segment.name = "SpiralSegment_" + str(i)
		
		var cube = BoxMesh.new()
		var size_factor = 1.0 + sin(i * 0.2) * 0.3
		cube.size = Vector3(0.1, 0.05, 0.1) * size_factor
		segment.mesh = cube
		
		# Calculate spiral position using sine and cosine
		var angle = (2 * PI * i * 3) / segments  # Multiple turns
		var spiral_radius = radius * (1.0 - float(i) / segments * 0.5)
		var height = sin(i * 0.1) * 0.3
		
		segment.position = Vector3(
			cos(angle) * spiral_radius,
			height,
			sin(angle) * spiral_radius
		)
		
		# Dynamic rotation
		segment.rotation_degrees = Vector3(
			sin(i * 0.1) * 30,
			rad_to_deg(angle),
			cos(i * 0.1) * 15
		)
		
		# Ultra-vivid material
		var material = StandardMaterial3D.new()
		material.albedo_color = spiral_color
		material.roughness = 0.1
		material.metallic = 0.6
		material.metallic_specular = 0.9
		material.emission_enabled = true
		material.emission = spiral_color * 0.4
		
		segment.material_override = material
		
		spiral.add_child(segment)
	
	return spiral

func add_ultra_vivid_polka_dots(mesh_instance, base_color, density_factor, invert_colors):
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	var mesh_size = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	var num_dots = int(30 * mesh_size * density_factor)
	
	for i in range(num_dots):
		var dot = MeshInstance3D.new()
		dot.name = "UltraVividDot_" + str(i)
		
		# Create dynamic dot sizes using sine
		var size_variation = 0.03 + sin(i * 0.5) * 0.05
		var dot_mesh = SphereMesh.new()
		dot_mesh.radius = size_variation
		dot_mesh.height = size_variation * 2
		dot_mesh.radial_segments = max(6, int(round(8 * detail_scale_clamped)))
		dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))
		dot.mesh = dot_mesh
		
		# Ultra-bright dot material
		var material = StandardMaterial3D.new()
		var dot_color = aurora_colors[i % aurora_colors.size()] if invert_colors else base_color.inverted()
		material.albedo_color = dot_color
		material.roughness = 0.0
		material.metallic = 0.8
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = dot_color * 0.8
		
		dot.material_override = material
		
		# Distribute dots using sine-based patterns
		var theta = sin(i * 0.3) * PI
		var phi = cos(i * 0.7) * 2 * PI
		
		var surface_point = Vector3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta)
		)
		
		surface_point.x *= aabb.size.x * 0.5
		surface_point.y *= aabb.size.y * 0.5
		surface_point.z *= aabb.size.z * 0.5
		
		dot.position = surface_point.normalized() * (surface_point.length() + 0.02)
		mesh_instance.add_child(dot)

func add_harmonic_polka_dots(mesh_instance, base_color, density, petal_index, layer):
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	var num_dots = max(8, int(round(25 * density * detail_scale_clamped)))
	
	for i in range(num_dots):
		var dot = MeshInstance3D.new()
		dot.name = "HarmonicDot_" + str(i)
		
		# Size based on harmonic series
		var harmonic_factor = 1.0 / (i + 1)
		var dot_size = 0.04 * harmonic_factor * (1.0 + sin(i * 0.8) * 0.5)
		
		var dot_mesh = SphereMesh.new()
		dot_mesh.radius = dot_size
		dot_mesh.height = dot_size * 2
		dot_mesh.radial_segments = max(4, int(round(6 * detail_scale_clamped)))
		dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))
		dot.mesh = dot_mesh
		
		# Harmonic color shifting
		var hue_shift = sin(i * 0.1 + petal_index + layer) * 0.5
		var dot_color = base_color.lerp(plasma_spectrum[i % plasma_spectrum.size()], hue_shift)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = dot_color
		material.roughness = 0.0
		material.metallic = 0.9
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = dot_color * 1.0
		
		dot.material_override = material
		
		# Position using golden ratio and sine waves
		var golden_angle = 2.4  # Golden angle approximation
		var radius_factor = sqrt(float(i) / num_dots)
		var angle = i * golden_angle + sin(i * 0.2) * 0.5
		
		var x = cos(angle) * radius_factor * aabb.size.x * 0.4
		var y = sin(i * 0.3) * aabb.size.y * 0.3
		var z = sin(angle) * radius_factor * aabb.size.z * 0.4
		
		dot.position = Vector3(x, y, z)
		mesh_instance.add_child(dot)

func add_sine_wave_dots(mesh_instance, base_color, density, segment_index):
	var num_dots = max(6, int(round(20 * density * detail_scale_clamped)))
	
	for i in range(num_dots):
		var dot = MeshInstance3D.new()
		dot.name = "SineWaveDot_" + str(i)
		
		var dot_size = 0.03 + sin(i * 0.4 + segment_index) * 0.02
		var dot_mesh = SphereMesh.new()
		dot_mesh.radius = dot_size
		dot_mesh.height = dot_size * 2
		dot_mesh.radial_segments = max(4, int(round(6 * detail_scale_clamped)))
		dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))
		dot.mesh = dot_mesh
		
		# Sine-based color variation
		var color_phase = sin(i * 0.2 + segment_index * 0.5) * 0.5 + 0.5
		var dot_color = base_color.lerp(kusama_colors[i % kusama_colors.size()], color_phase)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = dot_color
		material.roughness = 0.0
		material.metallic = 0.8
		material.metallic_specular = 1.0
		material.emission_enabled = true
		material.emission = dot_color * 0.9
		
		dot.material_override = material
		
		# Sine wave positioning
		var angle = (2 * PI * i) / num_dots
		var wave_radius = 0.2 + sin(i * 0.3) * 0.1
		var wave_height = cos(i * 0.4) * 0.1
		
		dot.position = Vector3(
			cos(angle) * wave_radius,
			wave_height,
			sin(angle) * wave_radius
		)
		
		mesh_instance.add_child(dot)

func animate_all_elements(delta):
	animate_core_layers()
	animate_morphing_petals()
	animate_undulating_tendrils()
	animate_orbital_rings()
	animate_harmonic_clusters()
	animate_energy_streams()

func animate_core_layers():
	var core = get_node_or_null("UltraVividCore")
	if not core:
		return
	
	for i in range(core.get_child_count()):
		var layer = core.get_child(i)
		if layer is MeshInstance3D:
			# Pulsing scale with sine waves
			var pulse = 1.0 + sin(pulse_time * (2.0 + i * 0.5)) * 0.1 * morphing_amplitude
			layer.scale = Vector3.ONE * pulse
			
			# Color shifting
			if layer.material_override:
				var base_color = kusama_colors[i % kusama_colors.size()]
				var shift_factor = sin(color_time + i) * 0.5 + 0.5
				var new_color = base_color.lerp(aurora_colors[i % aurora_colors.size()], shift_factor)
				layer.material_override.albedo_color = new_color
				layer.material_override.emission = new_color * 0.4

func animate_morphing_petals():
	for i in range(dynamic_petals.size()):
		var petal = dynamic_petals[i]
		if not petal:
			continue
		
		# Sine-based position oscillation
		var base_angle = (2 * PI * i) / num_petals
		var radius_variation = sin(time * 0.5 + i) * 0.3 * morphing_amplitude
		var height_variation = cos(time * 0.7 + i) * 0.2 * morphing_amplitude
		var radius = 1.8 + radius_variation
		
		petal.position = Vector3(
			cos(base_angle) * radius,
			height_variation,
			sin(base_angle) * radius
		)
		
		# Rotation animation
		petal.rotation_degrees.y = rad_to_deg(base_angle) + sin(time + i) * 15
		
		# Scale pulsing
		var scale_pulse = 1.0 + sin(pulse_time * 2 + i) * 0.15 * morphing_amplitude
		petal.scale = Vector3.ONE * scale_pulse

func animate_undulating_tendrils():
	if not include_tendrils or morphing_tendrils.is_empty():
		return
	for i in range(morphing_tendrils.size()):
		var tendril = morphing_tendrils[i]
		if not tendril:
			continue
		
		# Undulating motion using sine waves
		var base_angle = (2 * PI * i) / num_tendrils
		var undulation = sin(time * 0.8 + i * 2) * 0.5 * morphing_amplitude
		var spiral_motion = cos(time * 0.3 + i) * 0.3 * morphing_amplitude
		
		# Animate each segment
		for j in range(tendril.get_child_count()):
			var segment = tendril.get_child(j)
			if segment is MeshInstance3D:
				# Sine-based positioning along tendril path
				var segment_angle = base_angle + (j * 0.3) + sin(time * 0.5) * 0.2
				var segment_radius = 2.0 + j * 0.4 + undulation
				var segment_height = sin(j * 0.8 + time) * 0.5 + spiral_motion
				
				segment.position = Vector3(
					cos(segment_angle) * segment_radius,
					segment_height,
					sin(segment_angle) * segment_radius
				)
				
				# Dynamic rotation
				segment.rotation_degrees = Vector3(
					sin(time * 1.2 + j) * 20,
					rad_to_deg(segment_angle) + cos(time * 0.8) * 10,
					cos(time * 1.5 + j) * 15
				)
				
				# Scale variation
				var scale_factor = 1.0 + sin(time * 2 + j * 0.5) * 0.2 * morphing_amplitude
				segment.scale = Vector3.ONE * scale_factor

func animate_orbital_rings():
	if not include_orbital_rings or orbital_elements.is_empty():
		return
	for i in range(orbital_elements.size()):
		var orbital = orbital_elements[i]
		if not orbital:
			continue
		
		# Orbital rotation with sine modulation
		var rotation_speed = 0.5 + i * 0.2
		var wobble = sin(time * 0.3 + i) * 5 * morphing_amplitude
		
		orbital.rotation_degrees.y += rotation_speed
		orbital.rotation_degrees.x = wobble
		orbital.rotation_degrees.z = cos(time * 0.4 + i) * 3 * morphing_amplitude
		
		# Animate individual orbs
		for j in range(orbital.get_child_count()):
			var orb = orbital.get_child(j)
			if orb is MeshInstance3D:
				# Pulsing scale
				var pulse = 1.0 + sin(pulse_time * 3 + j + i) * 0.3 * morphing_amplitude
				orb.scale = Vector3.ONE * pulse
				
				# Color cycling
				if orb.material_override:
					var color_shift = sin(color_time * 2 + j) * 0.5 + 0.5
					var base_color = aurora_colors[i % aurora_colors.size()]
					var new_color = base_color.lerp(plasma_spectrum[j % plasma_spectrum.size()], color_shift)
					orb.material_override.albedo_color = new_color
					orb.material_override.emission = new_color * (0.8 + sin(time + j) * 0.4)

func animate_harmonic_clusters():
	if not include_harmonic_clusters or harmonic_dots.is_empty():
		return
	for i in range(harmonic_dots.size()):
		var cluster = harmonic_dots[i]
		if not cluster:
			continue
		
		# Cluster rotation with harmonic frequencies
		cluster.rotation_degrees.y += (i + 1) * 0.3
		cluster.rotation_degrees.x = sin(time * 0.6 + i) * 10 * morphing_amplitude
		
		# Animate individual dots
		for j in range(cluster.get_child_count()):
			var dot = cluster.get_child(j)
			if dot is MeshInstance3D:
				# Harmonic pulsing
				var harmonic_freq = (j % 5) + 1
				var pulse = 1.0 + sin(pulse_time * harmonic_freq + i) * 0.4 * morphing_amplitude
				dot.scale = Vector3.ONE * pulse
				
				# Brightness modulation
				if dot.material_override:
					var brightness = 0.5 + sin(time * 2 + j * 0.1) * 0.5
					var base_emission = dot.material_override.albedo_color
					dot.material_override.emission = base_emission * (brightness + 0.5)

func animate_energy_streams():
	if not include_energy_streams or energy_streams.is_empty():
		return
	for i in range(energy_streams.size()):
		var stream = energy_streams[i]
		if not stream:
			continue
		
		# Stream flow animation
		for j in range(stream.get_child_count()):
			var particle = stream.get_child(j)
			if particle is MeshInstance3D:
				# Flowing motion using sine waves
				var flow_progress = fmod((time * 2.0 + float(j) * 0.1), 1.0)
				var stream_angle = (2 * PI * i) / energy_streams.size()
				
				# Create flowing path
				var path_radius = 5.0 + sin(flow_progress * PI * 4) * 1.5
				var path_height = sin(flow_progress * PI * 6) * 3.0 + cos(time + i) * 0.5
				var path_angle = stream_angle + flow_progress * PI * 8
				
				particle.position = Vector3(
					cos(path_angle) * path_radius,
					path_height,
					sin(path_angle) * path_radius
				)
				
				# Particle pulsing
				var pulse = 1.0 + sin(time * 8 + j * 0.3) * 0.6 * morphing_amplitude
				particle.scale = Vector3.ONE * pulse
				
				# Trail effect with transparency
				if particle.material_override:
					var trail_alpha = sin(flow_progress * PI) * 0.8 + 0.2
					particle.material_override.albedo_color.a = trail_alpha
					
					# Color shifting along stream
					var color_shift = sin(flow_progress * PI * 2 + time) * 0.5 + 0.5
					var base_color = aurora_colors[i % aurora_colors.size()]
					var stream_color = base_color.lerp(plasma_spectrum[j % plasma_spectrum.size()], color_shift)
					particle.material_override.albedo_color = Color(stream_color.r, stream_color.g, stream_color.b, trail_alpha)
					particle.material_override.emission = stream_color * (1.5 + sin(time * 4 + j) * 0.5)

func setup_ultra_vivid_environment():
	# Create dynamic lighting system
	create_dynamic_lighting()
	
	# Enhanced environment with atmospheric effects
	var world_environment = WorldEnvironment.new()
	world_environment.name = "UltraVividEnvironment"
	
	var environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.0, 0.15)  # Deep space blue
	environment.ambient_light_color = Color(0.8, 0.6, 1.0)
	environment.ambient_light_energy = 0.4
	
	# Enhanced bloom and glow effects
	environment.glow_enabled = true
	environment.glow_intensity = 1.5
	environment.glow_bloom = 0.3
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 0.8
	environment.glow_hdr_scale = 2.0
	
	# Fog for atmospheric depth
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.6, 0.4, 1.0)
	environment.fog_light_energy = 0.3
	environment.fog_sun_scatter = 0.1
	environment.fog_density = 0.02
	environment.fog_height = 2.0
	environment.fog_height_density = 0.1
	
	world_environment.environment = environment
	add_child(world_environment)
	

func create_dynamic_lighting():
	# Primary directional light with animation
	var main_light = DirectionalLight3D.new()
	main_light.name = "DynamicMainLight"
	main_light.position = Vector3(8, 10, 6)
	main_light.look_at_from_position(main_light.position, Vector3(0, 0, 0), Vector3.UP)
	main_light.light_energy = 2.0
	main_light.shadow_enabled = true
	main_light.light_color = Color(1.0, 0.9, 0.8)
	add_child(main_light)
	
	# Colored accent lights that pulse and move
	var accent_colors = [
		Color(1.0, 0.2, 0.4),  # Red
		Color(0.2, 0.8, 1.0),  # Blue
		Color(0.8, 1.0, 0.2),  # Green
		Color(1.0, 0.6, 0.2),  # Orange
	]
	
	for i in range(accent_colors.size()):
		var accent_light = OmniLight3D.new()
		accent_light.name = "AccentLight_" + str(i)
		accent_light.light_color = accent_colors[i]
		accent_light.light_energy = 1.5
		accent_light.omni_range = 15.0
		accent_light.omni_attenuation = 0.5
		
		# Position lights in a circle
		var angle = (2 * PI * i) / accent_colors.size()
		accent_light.position = Vector3(
			cos(angle) * 8,
			3,
			sin(angle) * 8
		)
		
		add_child(accent_light)

func create_ultra_vivid_floor():
	var floor_node = MeshInstance3D.new()
	floor_node.name = "UltraVividFloor"
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(40, 40)
	plane_mesh.subdivide_width = max(12, int(round(32 * detail_scale_clamped)))
	plane_mesh.subdivide_depth = max(12, int(round(32 * detail_scale_clamped)))
	floor_node.mesh = plane_mesh
	
	# Create animated floor material with sine wave patterns
	var floor_material = ShaderMaterial.new()
	var floor_shader = Shader.new()
	floor_shader.code = """
	shader_type spatial;
	
	uniform vec4 base_color : source_color = vec4(0.1, 0.05, 0.2, 1.0);
	uniform vec4 pattern_color : source_color = vec4(0.8, 0.4, 1.0, 1.0);
	uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
	uniform float wave_frequency : hint_range(1.0, 20.0) = 8.0;
	uniform float pattern_intensity : hint_range(0.0, 2.0) = 1.0;
	
	varying vec3 world_position;
	varying vec2 base_uv;
	
	void vertex() {
		world_position = VERTEX;
		base_uv = UV;
	}
	
	void fragment() {
		vec2 pos = world_position.xz;
		float time = TIME * time_scale;
		
		// Create multiple sine wave patterns
		float wave1 = sin(pos.x * wave_frequency + time * 2.0) * cos(pos.y * wave_frequency * 0.7 + time * 1.5);
		float wave2 = sin(pos.x * wave_frequency * 1.3 - time * 1.8) * sin(pos.y * wave_frequency * 1.1 + time * 2.2);
		float wave3 = cos(pos.x * wave_frequency * 0.8 + time * 1.2) * cos(pos.y * wave_frequency * 0.9 - time * 1.7);
		
		// Combine waves
		float combined_wave = (wave1 + wave2 + wave3) / 3.0;
		float pattern = smoothstep(-0.3, 0.3, combined_wave);
		
		// Add radial pattern
		float distance_from_center = length(pos) * 0.1;
		float radial = sin(distance_from_center * 5.0 - time * 3.0) * 0.5 + 0.5;
		
		// Combine patterns
		float final_pattern = pattern * radial * pattern_intensity;
		
		ALBEDO = mix(base_color.rgb, pattern_color.rgb, final_pattern);
		ROUGHNESS = 0.1;
		METALLIC = 0.8;
		EMISSION = pattern_color.rgb * final_pattern * 0.3;
	}
	"""
	
	floor_material.shader = floor_shader
	floor_material.set_shader_parameter("base_color", Color(0.1, 0.05, 0.2, 1.0))
	floor_material.set_shader_parameter("pattern_color", Color(0.8, 0.4, 1.0, 1.0))
	floor_material.set_shader_parameter("time_scale", 1.0)
	floor_material.set_shader_parameter("wave_frequency", 8.0)
	floor_material.set_shader_parameter("pattern_intensity", 1.0)
	
	floor_node.material_override = floor_material
	floor_node.position = Vector3(0, -1.0, 0)
	
	add_child(floor_node)

# Enhanced control functions
func set_animation_intensity(intensity: float):
	animation_intensity = clamp(intensity, 0.0, 3.0)

func set_color_shift_speed(speed: float):
	color_shift_speed = clamp(speed, 0.0, 5.0)

func set_morphing_amplitude(amplitude: float):
	morphing_amplitude = clamp(amplitude, 0.0, 1.0)

func cycle_color_palette():
	# Rotate through different color schemes
	var temp = kusama_colors[0]
	for i in range(kusama_colors.size() - 1):
		kusama_colors[i] = kusama_colors[i + 1]
	kusama_colors[-1] = temp

func generate():
	clear_children()
	detail_scale_clamped = clamp(detail_scale, 0.35, 1.3)
	generate_ultra_vivid_sculpture()

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	dynamic_petals.clear()
	morphing_tendrils.clear()
	orbital_elements.clear()
	harmonic_dots.clear()
	energy_streams.clear()

# Enhanced Bezier curve system for ultra-smooth organic shapes
class UltraVividPetalGenerator:
	var control_points = []
	var subdivisions = 32
	var thickness = 0.3
	var harmonic_distortion = 0.2
	
	func _init(p0, p1, p2, p3, p_thickness = 0.3):
		control_points = [p0, p1, p2, p3]
		thickness = p_thickness
	
	func evaluate_bezier_with_harmonics(t, time_offset = 0.0):
		var base_point = evaluate_base_bezier(t)
		
		# Add harmonic distortions using sine waves
		var harmonic1 = sin(t * PI * 4 + time_offset) * harmonic_distortion * 0.1
		var harmonic2 = cos(t * PI * 6 + time_offset * 1.5) * harmonic_distortion * 0.05
		var harmonic3 = sin(t * PI * 8 + time_offset * 0.8) * harmonic_distortion * 0.03
		
		base_point.y += harmonic1 + harmonic2 + harmonic3
		
		return base_point
	
	func evaluate_base_bezier(t):
		var t2 = t * t
		var t3 = t2 * t
		var mt = 1 - t
		var mt2 = mt * mt
		var mt3 = mt2 * mt
		
		return control_points[0] * mt3 + \
			   control_points[1] * 3 * mt2 * t + \
			   control_points[2] * 3 * mt * t2 + \
			   control_points[3] * t3
	
	func generate_ultra_vivid_petal_mesh(time_offset = 0.0):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var points = []
		var normals = []
		
		# Generate ultra-smooth curve with harmonic distortions
		for i in range(subdivisions + 1):
			var t = float(i) / subdivisions
			var point = evaluate_bezier_with_harmonics(t, time_offset)
			points.append(point)
			
			# Calculate smooth normals
			var tangent
			if i < subdivisions:
				var next_point = evaluate_bezier_with_harmonics((i + 1.0) / subdivisions, time_offset)
				tangent = (next_point - point).normalized()
			else:
				var prev_point = evaluate_bezier_with_harmonics((i - 1.0) / subdivisions, time_offset)
				tangent = (point - prev_point).normalized()
			
			var normal = Vector3(0, 1, 0).cross(tangent).normalized()
			normals.append(normal)
		
		# Generate ultra-detailed mesh
		for i in range(subdivisions):
			var p0 = points[i]
			var p1 = points[i + 1]
			var n0 = normals[i]
			var n1 = normals[i + 1]
			
			# Create thick, organic ribbon
			var thickness_variation = thickness * (1.0 + sin(float(i) / subdivisions * PI * 3) * 0.3)
			var v0 = p0 + n0 * thickness_variation
			var v1 = p0 - n0 * thickness_variation
			var v2 = p1 + n1 * thickness_variation
			var v3 = p1 - n1 * thickness_variation
			
			# Add triangles with proper UVs
			add_quad_to_surface(st, v0, v1, v2, v3, i, subdivisions)
		
		st.generate_normals()
		st.generate_tangents()
		return st.commit()
	
	func add_quad_to_surface(st: SurfaceTool, v0, v1, v2, v3, segment, total_segments):
		var u0 = 0.0
		var u1 = 1.0
		var v_coord = float(segment) / total_segments
		var v_coord_next = float(segment + 1) / total_segments
		
		# Triangle 1
		st.set_normal((v0 - v1).cross(v2 - v0).normalized())
		st.set_uv(Vector2(u0, v_coord))
		st.add_vertex(v0)
		
		st.set_normal((v0 - v1).cross(v2 - v0).normalized())
		st.set_uv(Vector2(u1, v_coord))
		st.add_vertex(v1)
		
		st.set_normal((v0 - v1).cross(v2 - v0).normalized())
		st.set_uv(Vector2(u0, v_coord_next))
		st.add_vertex(v2)
		
		# Triangle 2
		st.set_normal((v1 - v3).cross(v2 - v1).normalized())
		st.set_uv(Vector2(u1, v_coord))
		st.add_vertex(v1)
		
		st.set_normal((v1 - v3).cross(v2 - v1).normalized())
		st.set_uv(Vector2(u1, v_coord_next))
		st.add_vertex(v3)
		
		st.set_normal((v1 - v3).cross(v2 - v1).normalized())
		st.set_uv(Vector2(u0, v_coord_next))
		st.add_vertex(v2)
