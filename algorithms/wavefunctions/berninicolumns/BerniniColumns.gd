# BerniniColumns.gd
# A 3D procedural generation system that creates spiral columns inspired by
# Gian Lorenzo Bernini's baroque architectural style.
extends Node3D


# @identity
# essence: column(h) = r * (cos(spiral_density*h), h, sin(spiral_density*h)) with sine/cosine amplitude modulation
# desire: Stand among baroque spiral columns that twist with trigonometric functions and emit organ tones
# critical_parameter: spiral_density — controls how many helical turns per column height
# triggers: time animates subtle column rotation; audio_phase drives organ sound generation
# emerges: the baroque as frozen oscillation — architecture that remembers the wave that shaped it
# needs: VR walkthrough [has], audio playback [has]
# relationships: depends on procedural spiral mesh generation; contrasts with sine_cylinder_staircase (decorative vs functional spirals); unlocks wave-as-architecture
# truth: A spiral column is a sine wave wrapped around a vertical axis.

const BERNINI_BASE_SCENE := preload("res://algorithms/wavefunctions/berninicolumns/bernini_base.tscn")

# -- Configuration --

# Parameters for column generation
@export var column_height: float = 8.0
@export var column_radius: float = 0.5
@export var spiral_density: float = 3.0  # Number of complete rotations
@export var sine_amplitude: float = 0.15
@export var cosine_amplitude: float = 0.15
@export var vertical_segments: int = 40
@export var radial_segments: int = 16
@export var twist_factor: float = 0.8  # How much the column twists as it rises
@export var material_color: Color = Color(0.96, 0.93, 0.85, 1.0)  # Bright warm marble

# For animated rotation
@export var rotate_columns: bool = true
@export var rotation_speed: float = 0.2
var time: float = 0.0

# Audio System
var audio_player: AudioStreamPlayer3D
var audio_stream: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
const SAMPLE_RATE = 44100.0
var audio_phase: float = 0.0

# -- Scene State --
var columns = []

# Column positions - equally spaced 3x3 grid
@export var grid_spacing: float = 4.0  # Distance between columns
var column_positions = []

## AXIS — THE PLAN the columns stand in, and therefore what building this is.
##
## The word is adopted from [[room_shape_demonstrator]], which already asks the same
## question of furniture (pair | head | circle | panopticon | vacant): how a set of identical
## elements is disposed, and what that disposition does to the body that walks in. Same word,
## same question, one scale up.
##
## A Solomonic column is a sine wound around a vertical axis; the spiral is the same in every
## value here. What changes is how many of them there are and where they stand, which is the
## only thing that decides whether the twist reads as a field, a canopy, a route or a
## threshold.
##
##   grid    the legacy lineage, byte for byte — 3 x 3 equally spaced. A hypostyle field:
##           no centre, no direction, nine equal columns and a body free to wander between
##           them because nothing tells it where to go.
##   ring    eight on a circle at the grid's corner radius, and nothing in the middle. The
##           Baldacchino read: the colonnade is built around something that is not there, and
##           the body's route is the circumference of an absence.
##   aisle   two rows of four, one bay apart. A nave: the columns stop being objects and
##           become a wall with holes in it, and the body is given exactly one direction.
##   pair    two columns, one bay apart, alone. A threshold — the wave reduced to the two
##           uprights of a door, which is the smallest arrangement that still asks a body to
##           pass BETWEEN rather than AROUND.
##
## The spotlights follow the columns, so a colonnade is lit the way it is laid out.
@export_enum("grid", "ring", "aisle", "pair") var colonnade: String = "grid"
const PLANS: PackedStringArray = ["grid", "ring", "aisle", "pair"]

func _generate_grid_positions() -> void:
	"""Generate a 3x3 equally spaced grid of column positions"""
	column_positions.clear()
	var grid_size = 3
	var offset = (grid_size - 1) * grid_spacing / 2.0
	
	for x in range(grid_size):
		for z in range(grid_size):
			var pos = Vector3(
				x * grid_spacing - offset,
				0,
				z * grid_spacing - offset
			)
			column_positions.append(pos)

	# PLAN, appended LAST so the 3 x 3 list above is built exactly as it always was. "grid"
	# falls through to `_` and keeps it; the other three clear it and lay out their own.
	match colonnade:
		"ring":
			_plan_ring()
		"aisle":
			_plan_aisle()
		"pair":
			_plan_pair()
		_:
			pass

# -- Godot Lifecycle Functions --

func _ready() -> void:
	_read_dna_meta()
	_setup_audio()
	
	# Generate equally spaced grid positions
	_generate_grid_positions()
	
	# Create the Baldacchino columns
	for pos in column_positions:
		var column = create_spiral_column()
		column.position = pos
		add_child(column)
		columns.append(column)
	
	# Add a light to highlight the columns
	create_lighting()

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1
	
	audio_player.stream = audio_stream
	audio_player.unit_size = 15.0
	audio_player.max_db = -5.0
	audio_player.autoplay = true
	
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback()

func _process(delta: float) -> void:
	# Animate the columns if enabled
	if rotate_columns:
		time += delta
		for column in columns:
			var rotating_root = column.get_node_or_null("RotatingRoot")
			if rotating_root:
				# Slow continuous rotation applied only to the shaft/capital
				rotating_root.rotation.y = time * rotation_speed
	
	_generate_audio_samples()

func _generate_audio_samples() -> void:
	if not playback:
		return
		
	var frames_available = playback.get_frames_available()
	if frames_available < 1:
		return
		
	for i in range(frames_available):
		var sample = 0.0
		
		# Generate a chord based on the 8 columns
		# Frequencies based on a richer D Major chord with octave doubling
		# Modulate slightly with rotation speed
		var freqs = [146.83, 185.00, 220.00, 293.66, 73.42, 110.00, 329.63, 440.00] # D2-D4 extended
		
		for j in range(min(8, column_positions.size())):
			var f = freqs[j] + sin(time * 0.5 + j) * 2.0 # Slight detuning
			
			# Sawtooth-ish wave for metallic sound
			var wave = 2.0 * (fmod(audio_phase * f / SAMPLE_RATE + float(j) * 0.25, 1.0) - 0.5)
			
			# Soften it to triangle
			wave = abs(wave) * 2.0 - 1.0
			
			sample += wave
			
		sample *= 0.1 * rotation_speed # Volume based on rotation
		
		playback.push_frame(Vector2(sample, sample))
		
		audio_phase += 1.0
		if audio_phase > SAMPLE_RATE:
			audio_phase -= SAMPLE_RATE

# --- Procedural Generation Functions ---

func create_spiral_column() -> Node3D:
	# Creates a single, complete column with a base, shaft, and capital.
	var column_node = Node3D.new()
	var rotating_root = Node3D.new()
	rotating_root.name = "RotatingRoot"
	column_node.add_child(rotating_root)
	
	# Create the main spiral shaft
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generate_spiral_column_mesh()
	
	# Create and apply the material — bright to emphasize column form
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.4
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = material_color * 0.15
	material.emission_energy_multiplier = 0.5
	mesh_instance.set_surface_override_material(0, material)
	
	rotating_root.add_child(mesh_instance)
	
	# Add the decorative top and bottom parts
	add_column_base(column_node)
	add_column_capital(rotating_root)
	
	return column_node

func generate_spiral_column_mesh() -> Mesh:
	# This is the core function that builds the column's geometry vertex by vertex.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate vertices in rings, moving up the column
	for i in range(vertical_segments + 1):
		var v = float(i) / vertical_segments # Vertical progress (0.0 to 1.0)
		var height = v * column_height
		
		# Calculate the spiral center offset using sine and cosine
		var spiral_angle = v * spiral_density * 2.0 * PI
		var center_offset_x = sin(spiral_angle) * sine_amplitude
		var center_offset_z = cos(spiral_angle) * cosine_amplitude
		
		# Add a secondary wave for more complex Bernini-style shaping
		var secondary_wave = sin(v * PI * 4) * 0.05
		center_offset_x += secondary_wave
		center_offset_z += secondary_wave
		
		# Vary the radius along the height for a more organic feel
		var radius_variation = 1.0 + sin(v * PI * 8) * 0.1
		
		# Create a ring of vertices at the current height
		for j in range(radial_segments + 1): # FIX: Loop to +1 to create a seam vertex
			var u = float(j) / radial_segments # Radial progress (0.0 to 1.0)
			var angle = u * 2.0 * PI + v * twist_factor * 2.0 * PI
			
			# Calculate vertex position with spiral displacement and twist
			var x = cos(angle) * column_radius * radius_variation + center_offset_x
			var z = sin(angle) * column_radius * radius_variation + center_offset_z
			var vertex = Vector3(x, height, z)
			
			# Calculate an approximate normal for lighting
			var normal = Vector3(x - center_offset_x, 0, z - center_offset_z).normalized()
			
			# Add the vertex data to the surface tool
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

func add_column_base(column_node: Node3D) -> void:
	# Adds the Bernini base scene below the column shaft.
	var base_instance = BERNINI_BASE_SCENE.instantiate()
	base_instance.position.y = -0.25
	var mesh_instance := base_instance.get_node_or_null("StaticBody3D/MeshInstance3D") as MeshInstance3D
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = material_color
		material.metallic = 0.4
		material.roughness = 0.35
		material.emission_enabled = true
		material.emission = material_color * 0.15
		material.emission_energy_multiplier = 0.5
		mesh_instance.set_surface_override_material(0, material)
	column_node.add_child(base_instance)

func add_column_capital(column_node: Node3D) -> void:
	# Adds a cylindrical capital to the top of a column.
	var capital = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.bottom_radius = column_radius * 1.2
	cylinder_mesh.top_radius = column_radius * 1.8
	cylinder_mesh.height = 0.6
	cylinder_mesh.radial_segments = radial_segments
	capital.mesh = cylinder_mesh
	capital.position.y = column_height + 0.3
	
	var material = StandardMaterial3D.new()
	material.albedo_color = material_color
	material.metallic = 0.4
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = material_color * 0.15
	material.emission_energy_multiplier = 0.5
	capital.set_surface_override_material(0, material)
	
	column_node.add_child(capital)

# --- Scene Setup Functions ---

func create_lighting() -> void:
	# Sets up basic lighting for the scene to make the columns visible.
	var dir_light = DirectionalLight3D.new()
	dir_light.light_energy = 1.2
	dir_light.shadow_enabled = true
	dir_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(dir_light)
	
	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_energy = 0.3
	ambient_light.rotation_degrees = Vector3(45, -135, 0)
	add_child(ambient_light)
	
	# Add a spotlight for each column to create dramatic highlights
	for pos in column_positions:
		var spotlight = SpotLight3D.new()
		spotlight.position = pos + Vector3(0, column_height * 1.5, 0)
		# Use FORWARD as up vector when looking straight down to avoid colinear vectors
		spotlight.look_at_from_position(spotlight.position, pos, Vector3.FORWARD)
		spotlight.light_energy = 2.0
		spotlight.light_color = Color(1.0, 0.9, 0.7) # Warm golden light
		spotlight.spot_range = column_height * 2.0
		spotlight.spot_angle = 30.0
		add_child(spotlight)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# Only the DNA axis is read here; every other key is ignored exactly as before.
	#
	# NOTE ON THE REAL CHANNEL: the grid instantiates BerniniScene.tscn, whose ROOT has no
	# script — this script lives on the BerniniColumns child. So the grid's has_method()
	# check fails on the root and this function is never reached from a map. The metadata
	# channel is: the grid sets config_* on the root before add_child, and _read_dna_meta
	# below reads it from the parent. This stays for the DNA-spec path, which calls it
	# directly. It records the value; it does NOT rebuild, because there is no teardown for
	# nine columns, nine spotlights and a running audio generator, and inventing one here
	# would risk the built path for a case that cannot occur.
	if config.has("colonnade"):
		var v: String = str(config["colonnade"]).strip_edges().to_lower()
		colonnade = v if PLANS.has(v) else colonnade


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the build. It
## looks at the PARENT as well as at itself: the metadata lands on BerniniScene, the scene
## root, because that is the node the grid instantiated, and this script is one level down.
## No metadata, no change — an unknown word keeps the default.
func _read_dna_meta() -> void:
	var raw: Variant = null
	if has_meta("config_plan"):
		raw = get_meta("config_plan")
	else:
		var host: Node = get_parent()
		if host != null and host.has_meta("config_plan"):
			raw = host.get_meta("config_plan")
	if raw == null:
		return
	var v: String = str(raw).strip_edges().to_lower()
	colonnade = v if PLANS.has(v) else colonnade


# ── PLAN ─────────────────────────────────────────────────────────────────────────────────
# Appended LAST. Each builder clears the 3 x 3 list and writes its own; "grid" never reaches
# them, so the legacy lineage keeps the exact nine positions it always had. Everything
# downstream — the columns, the spotlights, the audio voice count — reads column_positions,
# so a colonnade is built, lit and voiced consistently.

## RING — eight on a circle at the grid's corner radius, empty in the middle.
func _plan_ring() -> void:
	column_positions.clear()
	var count: int = 8
	var radius: float = grid_spacing * 1.414
	for i in range(count):
		var a: float = TAU * float(i) / float(count)
		column_positions.append(Vector3(cos(a) * radius, 0.0, sin(a) * radius))


## AISLE — two rows of four, one bay apart: a nave with a single direction through it.
func _plan_aisle() -> void:
	column_positions.clear()
	var per_side: int = 4
	var half: float = grid_spacing * 0.5
	for i in range(per_side):
		var z: float = (float(i) - float(per_side - 1) * 0.5) * grid_spacing
		column_positions.append(Vector3(-half, 0.0, z))
		column_positions.append(Vector3(half, 0.0, z))


## PAIR — two columns, one bay apart: a threshold, and nothing else.
func _plan_pair() -> void:
	column_positions.clear()
	var half: float = grid_spacing * 0.5
	column_positions.append(Vector3(-half, 0.0, 0.0))
	column_positions.append(Vector3(half, 0.0, 0.0))
