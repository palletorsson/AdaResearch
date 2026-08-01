extends Node3D

# Enhanced Configuration variables

# @identity
# essence: sculpture(t) = core + petals(sin(morph*t)) + tendrils(sin(pulse*t)) + orbital_rings
# desire: Witness a Kusama-inspired sculpture pulse, morph, and shift color in obsessive oscillation
# critical_parameter: detail_scale — controls geometric complexity of petals, tendrils, and orbital elements
# triggers: time drives morph_time, pulse_time, and color_time through layered sine animations
# emerges: obsessive visual density — polka dots as high-frequency oscillation of attention
# needs: VR spatial presence [has], detail/color controls [missing]
# relationships: depends on multi-layered procedural mesh generation; contrasts with ruth_asawa_sculpture (Kusama excess vs Asawa restraint); unlocks art-as-oscillation
# truth: Obsessive repetition is oscillation at maximum frequency — the dot is the shortest wavelength of attention.

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

## AXIS — HOW FAR THE DOT HAS GONE. The artifact's own truth line says the dot is the
## shortest wavelength of attention; Kusama's practice says the dot does not stop at the
## edge of the object. This axis is the question of where it does stop.
##
## Every value here is built from the dot MultiMeshes that already exist. Nothing changes
## about the sine geometry underneath — the petals, the core layers and the spirals are
## computed identically in all four.
##
##   skin           the legacy lineage, byte for byte — dots on the core spheres, on every
##                  petal layer and on every tendril segment, and nowhere else. A decorated
##                  object: the pattern obeys the form's boundary.
##   none           the three dot passes withheld. What is left is the sine geometry the
##                  dots were covering — layered translucent spheres, six morphing petals,
##                  three harmonic spirals — which almost nobody has ever seen.
##   air            the dots leave the surface: a field of 240 of them fills the volume
##                  around the sculpture. The Infinity Room read — the pattern is no longer
##                  ON something, it is the medium the object is suspended in.
##   obliteration   every surface stands down and only the repeated small elements remain —
##                  roughly 560 dots plus the three cube spirals, all of them MultiMeshes and
##                  so untouched — and the form is legible purely as its own constellation.
##                  Kusama's word, and her claim: repetition does not decorate a body, it
##                  dissolves one.
##
## `obliteration` sets layers = 0 on the mesh instances rather than visible = false. The dot
## MultiMeshes are CHILDREN of those meshes and Godot resolves visibility through
## is_visible_in_tree(), so hiding the parent would take the dots with it and render an
## empty frame. Render layers are per-instance and do not propagate.
@export_enum("skin", "none", "air", "obliteration") var obsession: String = "skin"
const OBSESSIONS: PackedStringArray = ["skin", "none", "air", "obliteration"]

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

# Audio System
var audio_player: AudioStreamPlayer3D
var audio_stream: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
const SAMPLE_RATE = 44100.0
var audio_phase: float = 0.0

func _ready() -> void:
	_read_dna_meta()
	detail_scale_clamped = clamp(detail_scale, 0.35, 1.3)
	if abs(vertical_offset) > 0.001:
		translate(Vector3(0, vertical_offset, 0))
	
	_setup_audio()
	
	if generate_on_ready:
		generate_ultra_vivid_sculpture()


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build and an
## unknown word keeps the default. No metadata, no change.
func _read_dna_meta() -> void:
	if has_meta("config_obsession"):
		var o: String = str(get_meta("config_obsession")).strip_edges().to_lower()
		obsession = o if OBSESSIONS.has(o) else obsession

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1
	
	audio_player.stream = audio_stream
	audio_player.unit_size = 10.0
	audio_player.max_db = -10.0
	audio_player.autoplay = true
	
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback()

func _process(delta: float) -> void:
	time += delta * animation_intensity
	color_time += delta * color_shift_speed
	morph_time += delta * 0.7
	pulse_time += delta * 1.5
	
	animate_all_elements(delta)
	_generate_audio_samples()

func _generate_audio_samples() -> void:
	if not playback:
		return

	var frames_available = playback.get_frames_available()
	if frames_available < 1:
		return

	# Kusama-style ethereal infinity sound
	# Dreamy, hypnotic drones with polka-dot pulsing

	# Base frequencies - ethereal chord (Cm7 voicing for dreamy quality)
	var base_freqs = [
		130.81,  # C3 - root
		155.56,  # Eb3 - minor third
		196.00,  # G3 - fifth
		233.08,  # Bb3 - minor seventh
	]

	# Master volume - soft and dreamy
	var master_vol = 0.08 * (0.6 + morphing_amplitude * 0.4)

	for i in range(frames_available):
		var t = time + float(i) / SAMPLE_RATE
		var sample = 0.0

		# Layer 1: Ethereal pad - soft detuned voices
		for j in range(base_freqs.size()):
			var freq = base_freqs[j]
			# Subtle detuning for richness (infinity feel)
			var detune = 1.0 + sin(t * 0.1 + j * 1.5) * 0.003
			freq *= detune

			# Phase for this voice
			var phase = t * freq

			# Soft sine with gentle harmonics
			var voice = sin(phase * TAU) * 0.4
			voice += sin(phase * TAU * 2.0) * 0.15  # Soft octave
			voice += sin(phase * TAU * 3.0) * 0.05  # Touch of fifth harmonic

			# Gentle tremolo (polka dot pulsing)
			var tremolo = 0.7 + 0.3 * sin(t * (1.5 + j * 0.3))

			sample += voice * tremolo * 0.25

		# Layer 2: High ethereal shimmer - very soft
		var shimmer_freq = 523.25  # C5 - high octave
		var shimmer_phase = t * shimmer_freq
		var shimmer = sin(shimmer_phase * TAU) * 0.1
		shimmer += sin(shimmer_phase * TAU * 1.5) * 0.05  # Fifth
		# Slow breathing on shimmer
		shimmer *= 0.4 + 0.6 * sin(t * 0.3) * sin(t * 0.3)
		sample += shimmer * 0.15

		# Layer 3: Deep sub-bass drone (infinity depth)
		var sub_freq = 65.41  # C2 - low octave
		var sub_phase = t * sub_freq
		var sub = sin(sub_phase * TAU) * 0.3
		# Very slow pulse
		sub *= 0.5 + 0.5 * sin(t * 0.2)
		sample += sub * 0.2

		# Apply master volume with soft limiting
		sample *= master_vol
		sample = tanh(sample * 2.0) * 0.5  # Soft saturation

		playback.push_frame(Vector2(sample, sample))

	# Update phase tracking for continuity (not critical with t-based synthesis)
	audio_phase += frames_available
	if audio_phase > SAMPLE_RATE * 10.0:
		audio_phase -= SAMPLE_RATE * 10.0


func generate_ultra_vivid_sculpture() -> void:
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

	# OBSESSION, appended LAST so every child index and material above is untouched on the
	# legacy path. "skin" and "none" both fall through and add nothing here — the difference
	# between them was already made by the guard at the top of the three dot passes.
	match obsession:
		"air":
			_obsession_air()
		"obliteration":
			_obsession_obliteration(self)
		_:
			pass

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

func create_morphing_petals() -> void:
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

func create_undulating_tendrils() -> void:
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

func create_orbital_rings() -> void:
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

	# Use MultiMesh for orbital orbs
	var orb_mesh = SphereMesh.new()
	orb_mesh.radius = 0.15
	orb_mesh.height = 0.30
	orb_mesh.radial_segments = max(8, int(round(12 * detail_scale_clamped)))
	orb_mesh.rings = max(4, int(round(8 * detail_scale_clamped)))

	var mat = StandardMaterial3D.new()
	mat.albedo_color = ring_color
	mat.roughness = 0.0
	mat.metallic = 0.8
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = ring_color * 0.8
	orb_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = num_orbs
	mm.mesh = orb_mesh

	for orb in range(num_orbs):
		var orb_radius = 0.15 + sin(orb * 0.5) * 0.05
		var scale_factor = orb_radius / 0.15
		var angle = (2 * PI * orb) / num_orbs

		var t = Transform3D()
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = Vector3(
			cos(angle) * ring_radius,
			sin(ring_index * 2) * 0.5,
			sin(angle) * ring_radius
		)
		mm.set_instance_transform(orb, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "OrbitalOrbs_MM"
	mmi.multimesh = mm
	orbital.add_child(mmi)

	return orbital

func create_harmonic_clusters() -> void:
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
	var total_dots = harmonic_count * dots_per_harmonic

	# Use MultiMesh for all harmonic cluster dots
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.08
	dot_mesh.height = 0.16
	dot_mesh.radial_segments = max(6, int(round(8 * detail_scale_clamped)))
	dot_mesh.rings = max(3, int(round(4 * detail_scale_clamped)))

	var mat = StandardMaterial3D.new()
	mat.albedo_color = cluster_color
	mat.roughness = 0.0
	mat.metallic = 1.0
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = cluster_color * 1.2
	dot_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = total_dots
	mm.mesh = dot_mesh

	var idx = 0
	for harmonic in range(harmonic_count):
		for dot in range(dots_per_harmonic):
			var dot_radius = 0.08 + sin(harmonic) * 0.02
			var scale_factor = dot_radius / 0.08
			var angle = (2 * PI * dot) / float(dots_per_harmonic)
			var radius = base_radius + sin(harmonic * PI) * 0.8
			var height = cos(harmonic * PI * 0.5) * 2.0

			var t = Transform3D()
			t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
			t.origin = Vector3(cos(angle) * radius, height, sin(angle) * radius)
			mm.set_instance_transform(idx, t)
			idx += 1

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "HarmonicClusterDots_MM"
	mmi.multimesh = mm
	cluster.add_child(mmi)

	return cluster

func create_energy_streams() -> void:
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

	# Use MultiMesh for energy stream particles
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.05
	particle_mesh.height = 0.10
	particle_mesh.radial_segments = 6
	particle_mesh.rings = 4

	var mat = StandardMaterial3D.new()
	mat.albedo_color = stream_color
	mat.roughness = 0.0
	mat.metallic = 0.9
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = stream_color * 1.5
	particle_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = segments
	mm.mesh = particle_mesh

	# Store MultiMesh ref for _process() animation updates
	stream.set_meta("multimesh", mm)
	stream.set_meta("segment_count", segments)

	for segment in range(segments):
		var particle_radius = 0.05 + sin(segment * 0.3) * 0.02
		var scale_factor = particle_radius / 0.05

		var t = Transform3D()
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = Vector3.ZERO  # Will be positioned by animation
		mm.set_instance_transform(segment, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "EnergyStream_MM"
	mmi.multimesh = mm
	stream.add_child(mmi)

	return stream

func create_harmonic_spiral(radius, harmonic_index):
	var spiral = Node3D.new()
	spiral.name = "HarmonicSpiral_" + str(harmonic_index)

	var segments = max(18, int(round((48 + harmonic_index * 8) * detail_scale_clamped)))
	var spiral_color = kusama_colors[harmonic_index % kusama_colors.size()]

	# Use MultiMesh for spiral segments (all same BoxMesh)
	var cube = BoxMesh.new()
	cube.size = Vector3(0.1, 0.05, 0.1)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = spiral_color
	mat.roughness = 0.1
	mat.metallic = 0.6
	mat.metallic_specular = 0.9
	mat.emission_enabled = true
	mat.emission = spiral_color * 0.4
	cube.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = segments
	mm.mesh = cube

	for i in range(segments):
		var size_factor = 1.0 + sin(i * 0.2) * 0.3
		var angle = (2 * PI * i * 3) / segments
		var spiral_radius = radius * (1.0 - float(i) / segments * 0.5)
		var height = sin(i * 0.1) * 0.3

		var rot = Vector3(
			sin(i * 0.1) * 30,
			rad_to_deg(angle),
			cos(i * 0.1) * 15
		)

		var t = Transform3D()
		t.basis = Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
		t.basis = t.basis.scaled(Vector3(size_factor, size_factor, size_factor))
		t.origin = Vector3(cos(angle) * spiral_radius, height, sin(angle) * spiral_radius)
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "HarmonicSpiral_MM"
	mmi.multimesh = mm
	spiral.add_child(mmi)

	return spiral

func add_ultra_vivid_polka_dots(mesh_instance, base_color, density_factor, invert_colors) -> void:
	if obsession == "none":
		return
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	var mesh_size = max(aabb.size.x, max(aabb.size.y, aabb.size.z))
	var num_dots = int(30 * mesh_size * density_factor)
	if num_dots < 1:
		return

	# Use MultiMesh for all dots (same sphere geometry, varied transforms)
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.04  # Average size
	dot_mesh.height = 0.08
	dot_mesh.radial_segments = max(6, int(round(8 * detail_scale_clamped)))
	dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))

	var dot_color = aurora_colors[0] if invert_colors else base_color.inverted()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = dot_color
	mat.roughness = 0.0
	mat.metallic = 0.8
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = dot_color * 0.8
	dot_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = num_dots
	mm.mesh = dot_mesh

	for i in range(num_dots):
		var size_variation = 0.03 + sin(i * 0.5) * 0.05
		var scale_factor = size_variation / 0.04  # Relative to base radius

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

		var pos = surface_point.normalized() * (surface_point.length() + 0.02)

		var t = Transform3D()
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = pos
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "UltraVividDots_MM"
	mmi.multimesh = mm
	mesh_instance.add_child(mmi)

func add_harmonic_polka_dots(mesh_instance, base_color, density, petal_index, layer) -> void:
	if obsession == "none":
		return
	var mesh = mesh_instance.mesh
	var aabb = mesh.get_aabb()
	var num_dots = max(8, int(round(25 * density * detail_scale_clamped)))

	# Use MultiMesh for harmonic dots
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.03  # Base size
	dot_mesh.height = 0.06
	dot_mesh.radial_segments = max(4, int(round(6 * detail_scale_clamped)))
	dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))

	var hue_shift = sin(0.1 + petal_index + layer) * 0.5
	var dot_color = base_color.lerp(plasma_spectrum[0], hue_shift)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = dot_color
	mat.roughness = 0.0
	mat.metallic = 0.9
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = dot_color * 1.0
	dot_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = num_dots
	mm.mesh = dot_mesh

	for i in range(num_dots):
		var harmonic_factor = 1.0 / (i + 1)
		var dot_size = 0.04 * harmonic_factor * (1.0 + sin(i * 0.8) * 0.5)
		var scale_factor = dot_size / 0.03

		var golden_angle = 2.4
		var radius_factor = sqrt(float(i) / num_dots)
		var angle = i * golden_angle + sin(i * 0.2) * 0.5

		var x = cos(angle) * radius_factor * aabb.size.x * 0.4
		var y = sin(i * 0.3) * aabb.size.y * 0.3
		var z = sin(angle) * radius_factor * aabb.size.z * 0.4

		var t = Transform3D()
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = Vector3(x, y, z)
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "HarmonicDots_MM"
	mmi.multimesh = mm
	mesh_instance.add_child(mmi)

func add_sine_wave_dots(mesh_instance, base_color, density, segment_index) -> void:
	if obsession == "none":
		return
	var num_dots = max(6, int(round(20 * density * detail_scale_clamped)))

	# Use MultiMesh for sine wave dots
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.03  # Base size
	dot_mesh.height = 0.06
	dot_mesh.radial_segments = max(4, int(round(6 * detail_scale_clamped)))
	dot_mesh.rings = max(2, int(round(4 * detail_scale_clamped)))

	var color_phase = sin(0.2 + segment_index * 0.5) * 0.5 + 0.5
	var dot_color = base_color.lerp(kusama_colors[0], color_phase)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = dot_color
	mat.roughness = 0.0
	mat.metallic = 0.8
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = dot_color * 0.9
	dot_mesh.material = mat

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = num_dots
	mm.mesh = dot_mesh

	for i in range(num_dots):
		var dot_size = 0.03 + sin(i * 0.4 + segment_index) * 0.02
		var scale_factor = dot_size / 0.03

		var angle = (2 * PI * i) / num_dots
		var wave_radius = 0.2 + sin(i * 0.3) * 0.1
		var wave_height = cos(i * 0.4) * 0.1

		var t = Transform3D()
		t.basis = Basis.IDENTITY.scaled(Vector3(scale_factor, scale_factor, scale_factor))
		t.origin = Vector3(cos(angle) * wave_radius, wave_height, sin(angle) * wave_radius)
		mm.set_instance_transform(i, t)

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "SineWaveDots_MM"
	mmi.multimesh = mm
	mesh_instance.add_child(mmi)

func animate_all_elements(_delta) -> void:
	animate_core_layers()
	animate_morphing_petals()
	animate_undulating_tendrils()
	animate_orbital_rings()
	animate_harmonic_clusters()
	animate_energy_streams()

func animate_core_layers() -> void:
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

func animate_morphing_petals() -> void:
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

func animate_undulating_tendrils() -> void:
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

func animate_orbital_rings() -> void:
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

func animate_harmonic_clusters() -> void:
	if not include_harmonic_clusters or harmonic_dots.is_empty():
		return
	for i in range(harmonic_dots.size()):
		var cluster = harmonic_dots[i]
		if not cluster:
			continue

		# Cluster rotation with harmonic frequencies
		cluster.rotation_degrees.y += (i + 1) * 0.3
		cluster.rotation_degrees.x = sin(time * 0.6 + i) * 10 * morphing_amplitude

func animate_energy_streams() -> void:
	if not include_energy_streams or energy_streams.is_empty():
		return
	for i in range(energy_streams.size()):
		var stream = energy_streams[i]
		if not stream:
			continue

		# Use stored MultiMesh for animation
		if not stream.has_meta("multimesh"):
			continue
		var mm: MultiMesh = stream.get_meta("multimesh")
		var segment_count: int = stream.get_meta("segment_count")

		var stream_angle = (2 * PI * i) / energy_streams.size()

		for j in range(segment_count):
			var flow_progress = fmod((time * 2.0 + float(j) * 0.1), 1.0)

			var path_radius = 5.0 + sin(flow_progress * PI * 4) * 1.5
			var path_height = sin(flow_progress * PI * 6) * 3.0 + cos(time + i) * 0.5
			var path_angle = stream_angle + flow_progress * PI * 8

			var pulse = 1.0 + sin(time * 8 + j * 0.3) * 0.6 * morphing_amplitude
			var particle_radius = 0.05 + sin(j * 0.3) * 0.02
			var base_scale = particle_radius / 0.05 * pulse

			var t = Transform3D()
			t.basis = Basis.IDENTITY.scaled(Vector3(base_scale, base_scale, base_scale))
			t.origin = Vector3(
				cos(path_angle) * path_radius,
				path_height,
				sin(path_angle) * path_radius
			)
			mm.set_instance_transform(j, t)

func setup_ultra_vivid_environment() -> void:
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
	

func create_dynamic_lighting() -> void:
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

func create_ultra_vivid_floor() -> void:
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
func set_animation_intensity(intensity: float) -> void:
	animation_intensity = clamp(intensity, 0.0, 3.0)

func set_color_shift_speed(speed: float) -> void:
	color_shift_speed = clamp(speed, 0.0, 5.0)

func set_morphing_amplitude(amplitude: float) -> void:
	morphing_amplitude = clamp(amplitude, 0.0, 1.0)

func cycle_color_palette() -> void:
	# Rotate through different color schemes
	var temp = kusama_colors[0]
	for i in range(kusama_colors.size() - 1):
		kusama_colors[i] = kusama_colors[i + 1]
	kusama_colors[-1] = temp

func generate() -> void:
	clear_children()
	detail_scale_clamped = clamp(detail_scale, 0.35, 1.3)
	generate_ultra_vivid_sculpture()

func clear_children() -> void:
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
	
	func _init(p0, p1, p2, p3, p_thickness = 0.3) -> void:
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
	
	func add_quad_to_surface(st: SurfaceTool, v0, v1, v2, v3, segment, total_segments) -> void:
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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the DNA axis is read here; every other key is ignored exactly as before. This
	# records the value and does NOT rebuild: generate() routes through clear_children(),
	# which frees every child including the AudioStreamPlayer3D that _setup_audio() made and
	# never re-creates it. The real channel is _read_dna_meta(), which runs before the build.
	if config.has("obsession"):
		var o: String = str(config["obsession"]).strip_edges().to_lower()
		obsession = o if OBSESSIONS.has(o) else obsession


# ── OBSESSION ────────────────────────────────────────────────────────────────────────────
# Appended LAST. Both builders work on what generate_ultra_vivid_sculpture() has already
# made, so neither can disturb the sine geometry.

## AIR — the dot field leaves the object. 240 dots on a deterministic golden-angle spiral
## through a shell of radius ~2.4, sized by the same sine modulation the rest of the file
## uses (no randf: this sequence teaches before pseudo-randomness exists). Held in ONE
## MultiMesh, and MultiMeshInstance3D is not counted by the capture framer's AABB walk, so
## the halo cannot quietly re-frame the shot against the other three values.
func _obsession_air() -> void:
	var count: int = 240
	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.07
	dot_mesh.height = 0.14
	dot_mesh.radial_segments = 8
	dot_mesh.rings = 4

	var mat := StandardMaterial3D.new()
	mat.albedo_color = kusama_colors[1]
	mat.roughness = 0.0
	mat.metallic = 0.9
	mat.metallic_specular = 1.0
	mat.emission_enabled = true
	mat.emission = kusama_colors[1] * 0.9
	dot_mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = dot_mesh

	for i in range(count):
		var t: float = float(i) / float(count)
		var yy: float = 1.0 - 2.0 * t
		var ring: float = sqrt(maxf(1.0 - yy * yy, 0.0))
		var a: float = float(i) * 2.399963
		var rad: float = 2.4 + sin(float(i) * 0.7) * 0.9
		var s: float = 0.7 + sin(float(i) * 1.3) * 0.35
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(s, s, s))
		xf.origin = Vector3(cos(a) * ring * rad, yy * rad * 0.85, sin(a) * ring * rad)
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "ObsessionAir_MM"
	mmi.multimesh = mm
	add_child(mmi)


## OBLITERATION — the surfaces stand down and their dots stay. layers = 0, NOT
## visible = false: every dot cloud in this artifact is a MultiMeshInstance3D CHILD of the
## MeshInstance3D it decorates, and visibility resolves through is_visible_in_tree(), so
## hiding a parent would hide its dots too and leave an empty frame. Render layers are
## per-instance and do not propagate. MultiMeshInstance3D is a sibling class of
## MeshInstance3D, not a subclass, so the `is` test below leaves the dots alone.
func _obsession_obliteration(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).layers = 0
		_obsession_obliteration(child)
