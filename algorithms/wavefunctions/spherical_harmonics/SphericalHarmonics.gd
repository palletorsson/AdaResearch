extends Node3D

## Spherical Harmonics - Music of the Spheres (Mario Edition)
## A small sphere orbits a large sphere, creating a retro "Coin" sound rhythmically
##
## Concept: Position on sphere (θ, φ) → Sound parameters
## - Theta (latitude): Pitch (Frequency Range)
## - Phi (longitude): Snappiness (Decay Rate)
## - Radius: Amplitude
##
## This version uses a square wave synthesizer with a frequency chirp and exponential decay
## to emulate the classic 8-bit "pick up" sound effect.
##
## OPTIMIZED: Uses WavefunctionResources for shared meshes and MultiMesh for trails


# @identity
# essence: Y_l^m(theta, phi) — position on sphere via spherical coordinates
# desire: Watch a point orbit a sphere tracing harmonic patterns with a coin-sound rhythm
# critical_parameter: orbit_speed_phi / orbit_speed_theta ratio — determines the harmonic pattern traced
# triggers: auto_orbit toggles between free exploration and automated traversal
# emerges: spherical Lissajous figures from two angular velocities on a sphere
# needs: VR grab to manually steer the orbiting point [missing], speed sliders [missing]
# relationships: depends on spherical coordinate mapping; contrasts with lissajous_curves (sphere vs plane); unlocks 3D harmonic visualization
# truth: Every function on a sphere decomposes into spherical harmonics, the way every signal decomposes into sines.

# =============================================================================
# DNA — stage 2, promoted 2026-07-29
# =============================================================================
# The artifact is named after Y_l^m and never drew one. The centre body was a plain
# translucent ball — WavefunctionResources.get_unit_sphere() under a blue glass material —
# and the harmonic existed only as the RATIO of two orbit speeds, traced out over time by
# a point circling outside it. Standing in the room you see a ball, and the mode is an
# argument you have to wait for.
#
# surface asks what a spherical harmonic IS on the object that claims to be one:
#   glass — the pre-promotion body. The mode is implied by the orbit and nothing else.
#   nodal — Y_l^m's sign painted onto the unit sphere: warm lobes, cool lobes, and the
#           nodal lines between them. The harmonic as a field ON a fixed sphere.
#   lobed — the radius driven by |Y_l^m|, the textbook balloon plot. The harmonic as a
#           SHAPE, which is what most people picture and is a different claim.
#   wire  — the theta/phi cage alone, l latitudes and 2m meridians. The coordinate system
#           without the field: what the mode divides, before it says anything.
@export_enum("glass", "nodal", "lobed", "wire") var surface: String = "glass"
## Degree and order of the harmonic the patterned surfaces draw. Not declared as an axis:
## at surface=glass nothing in the frame depends on them, so a still cannot measure them.
@export var harmonic_l: int = 3
@export var harmonic_m: int = 2

const SPHERE_RINGS: int = 48
const SPHERE_SEGMENTS: int = 96
const CAGE_STEPS: int = 96

@onready var large_sphere: MeshInstance3D
@onready var small_sphere: MeshInstance3D
@onready var audio_player: AudioStreamPlayer3D

# MultiMesh trail (replaces 128 individual MeshInstance3D nodes)
var trail_multimesh: MultiMeshInstance3D
var trail_positions: PackedVector3Array

# Spherical coordinates (position of small sphere)
var theta: float = 0.0  # Latitude angle (0 to PI)
var phi: float = 0.0    # Longitude angle (0 to TAU)
var radius: float = 2.0 # Distance from center

# Control parameters
var orbit_speed_theta: float = 0.5  # How fast theta changes
var orbit_speed_phi: float = 1.0    # How fast phi changes
var auto_orbit: bool = true

# Audio synthesis
var audio_stream: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
const SAMPLE_RATE = 44100.0

# Mario Sound Parameters (Controlled by position)
var freq_start: float = 440.0
var freq_end: float = 880.0
var decay_rate: float = 8.0
var sound_duration: float = 0.5

# Trigger state
var last_quadrant: int = 0
var current_time_in_sound: float = 0.0
var is_playing_sound: bool = false

# Visualization
const TRAIL_LENGTH = 128
var trail_index: int = 0
var time: float = 0.0

func _ready() -> void:
	_create_spheres()
	_create_trail()
	_setup_audio()
	_setup_controls()
	print("SphericalHarmonics: Ready - Mario Mode Activated! (Optimized)")

func _create_spheres() -> void:
	# Large sphere (center) - body chosen by the `surface` axis
	_build_large_sphere()

	# Small sphere (orbiting)
	small_sphere = MeshInstance3D.new()
	var small_mesh = SphereMesh.new()
	small_mesh.radius = 0.1
	small_mesh.height = 0.2
	small_sphere.mesh = small_mesh
	# This one needs dynamic color, so create its own material
	var small_material = StandardMaterial3D.new()
	small_material.albedo_color = Color(1, 0.7, 0.2, 1.0)
	small_material.emission_enabled = true
	small_material.emission = Color(1, 0.7, 0.2, 1.0) * 0.8
	small_sphere.material_override = small_material
	add_child(small_sphere)

	# Initial position
	_update_small_sphere_position()

	# Labels
	_create_labels()

func _build_large_sphere() -> void:
	if large_sphere == null:
		large_sphere = MeshInstance3D.new()
		large_sphere.name = "LargeSphere"
		add_child(large_sphere)

	match surface:
		"nodal":
			large_sphere.mesh = _build_harmonic_mesh(false)
			large_sphere.material_override = _field_material(false)
		"lobed":
			large_sphere.mesh = _build_harmonic_mesh(true)
			large_sphere.material_override = _field_material(false)
		"wire":
			large_sphere.mesh = _build_cage_mesh()
			large_sphere.material_override = _field_material(true)
		_:
			# "glass" — the pre-promotion body, byte for byte. Note the mesh and material
			# here are STATIC and shared across every wavefunction artifact; they are
			# assigned, never mutated, and the variants above build their own.
			large_sphere.mesh = WavefunctionResources.get_unit_sphere()
			large_sphere.material_override = WavefunctionResources.get_glass_material(
				Color(0.2, 0.3, 0.8), 0.3
			)

func _field_material(unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1, 1)
	mat.metallic = 0.0
	mat.roughness = 0.55
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		mat.emission_enabled = true
		mat.emission = Color(0.35, 0.38, 0.5)
		mat.emission_energy_multiplier = 0.5
	return mat

func _build_harmonic_mesh(deform: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var peak: float = _harmonic_peak()
	for ring in range(SPHERE_RINGS):
		var t0: float = PI * float(ring) / float(SPHERE_RINGS)
		var t1: float = PI * float(ring + 1) / float(SPHERE_RINGS)
		for seg in range(SPHERE_SEGMENTS):
			var p0: float = TAU * float(seg) / float(SPHERE_SEGMENTS)
			var p1: float = TAU * float(seg + 1) / float(SPHERE_SEGMENTS)
			_add_field_quad(st, t0, t1, p0, p1, deform, peak)
	return st.commit()

func _add_field_quad(st: SurfaceTool, t0: float, t1: float, p0: float, p1: float,
		deform: bool, peak: float) -> void:
	var a: Vector3 = _field_point(t0, p0, deform, peak)
	var b: Vector3 = _field_point(t1, p0, deform, peak)
	var c: Vector3 = _field_point(t1, p1, deform, peak)
	var d: Vector3 = _field_point(t0, p1, deform, peak)
	var ca: Color = _field_color(t0, p0, peak)
	var cb: Color = _field_color(t1, p0, peak)
	var cc: Color = _field_color(t1, p1, peak)
	var cd: Color = _field_color(t0, p1, peak)
	_emit_vertex(st, a, ca)
	_emit_vertex(st, b, cb)
	_emit_vertex(st, c, cc)
	_emit_vertex(st, a, ca)
	_emit_vertex(st, c, cc)
	_emit_vertex(st, d, cd)

func _emit_vertex(st: SurfaceTool, p: Vector3, col: Color) -> void:
	# Normals set from the radial direction rather than generate_normals(), so the mesh
	# does not depend on getting SurfaceTool's winding convention right.
	st.set_color(col)
	st.set_normal(p.normalized())
	st.add_vertex(p)

func _field_point(t: float, p: float, deform: bool, peak: float) -> Vector3:
	var r: float = 1.0
	if deform:
		r = 0.15 + 0.85 * clampf(absf(_harmonic(t, p)) / peak, 0.0, 1.0)
	return Vector3(r * sin(t) * cos(p), r * cos(t), r * sin(t) * sin(p))

func _field_color(t: float, p: float, peak: float) -> Color:
	var h: float = _harmonic(t, p) / peak
	var mag: float = clampf(absf(h), 0.0, 1.0)
	var warm := Color(0.96, 0.36, 0.20)
	var cool := Color(0.13, 0.42, 0.95)
	var base: Color = warm if h >= 0.0 else cool
	return Color(0.04, 0.05, 0.11).lerp(base, 0.2 + 0.8 * mag)

func _build_cage_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	var wire := Color(0.55, 0.85, 1.0)
	var lat_count: int = maxi(harmonic_l, 1) + 2
	var lon_count: int = maxi(harmonic_m, 1) * 2
	for a in range(1, lat_count):
		var t: float = PI * float(a) / float(lat_count)
		for s in range(CAGE_STEPS):
			var p0: float = TAU * float(s) / float(CAGE_STEPS)
			var p1: float = TAU * float(s + 1) / float(CAGE_STEPS)
			_emit_vertex(st, _unit_point(t, p0), wire)
			_emit_vertex(st, _unit_point(t, p1), wire)
	for b in range(lon_count):
		var p: float = TAU * float(b) / float(lon_count)
		for s in range(CAGE_STEPS):
			var t0: float = PI * float(s) / float(CAGE_STEPS)
			var t1: float = PI * float(s + 1) / float(CAGE_STEPS)
			_emit_vertex(st, _unit_point(t0, p), wire)
			_emit_vertex(st, _unit_point(t1, p), wire)
	return st.commit()

func _unit_point(t: float, p: float) -> Vector3:
	return Vector3(sin(t) * cos(p), cos(t), sin(t) * sin(p))

func _harmonic(t: float, p: float) -> float:
	## Real form of Y_l^m up to normalisation: P_l^m(cos theta) * cos(m phi).
	return _assoc_legendre(harmonic_l, harmonic_m, cos(t)) * cos(float(harmonic_m) * p)

func _harmonic_peak() -> float:
	## |cos(m phi)| tops out at 1, so the peak of |Y| is the peak of |P_l^m|.
	var peak: float = 0.0001
	for ring in range(SPHERE_RINGS + 1):
		var t: float = PI * float(ring) / float(SPHERE_RINGS)
		var v: float = absf(_assoc_legendre(harmonic_l, harmonic_m, cos(t)))
		if v > peak:
			peak = v
	return peak

func _assoc_legendre(degree: int, order: int, x: float) -> float:
	## Standard three-term recurrence for the associated Legendre polynomial.
	var m: int = clampi(order, 0, 8)
	var l: int = maxi(degree, m)
	var pmm: float = 1.0
	if m > 0:
		var somx2: float = sqrt(maxf(0.0, (1.0 - x) * (1.0 + x)))
		var fact: float = 1.0
		for i in range(m):
			pmm *= -fact * somx2
			fact += 2.0
	if l == m:
		return pmm
	var pmmp1: float = x * (2.0 * float(m) + 1.0) * pmm
	if l == m + 1:
		return pmmp1
	var pll: float = 0.0
	for k in range(m + 2, l + 1):
		pll = ((2.0 * float(k) - 1.0) * x * pmmp1 - (float(k) + float(m) - 1.0) * pmm) / float(k - m)
		pmm = pmmp1
		pmmp1 = pll
	return pll

func _create_labels() -> void:
	var title = Label3D.new()
	title.text = "Music of the Spheres"
	title.position = Vector3(0, 2.5, 0)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color.BLACK
	add_child(title)

	var hint = Label3D.new()
	hint.name = "PositionLabel"
	hint.text = "θ=0.0° φ=0.0° | F=220Hz"
	hint.position = Vector3(0, -2.0, 0)
	hint.font_size = 20
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.modulate = Color(0.7, 0.7, 0.7, 0.9)
	hint.outline_size = 3
	hint.outline_modulate = Color.BLACK
	add_child(hint)

func _create_trail() -> void:
	# OPTIMIZED: Use MultiMesh instead of 128 individual MeshInstance3D nodes
	# This reduces draw calls from 128 to 1
	
	trail_positions.resize(TRAIL_LENGTH)
	
	trail_multimesh = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = TRAIL_LENGTH
	mm.mesh = WavefunctionResources.get_trail_sphere()
	trail_multimesh.multimesh = mm
	
	# Use shared emissive material
	trail_multimesh.material_override = WavefunctionResources.get_emissive_material(
		Color(1, 0.7, 0.2), 1.0, 0.8
	)
	
	# Initialize all instances as hidden (zero scale)
	for i in range(TRAIL_LENGTH):
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		# Set fading color based on age
		var age = float(i) / float(TRAIL_LENGTH)
		mm.set_instance_color(i, Color(1, 0.7, 0.2, 0.8 * (1.0 - age)))
	
	add_child(trail_multimesh)
	print("SphericalHarmonics: Trail using MultiMesh (1 node instead of 128)")

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1

	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -6.0
	add_child(audio_player)
	audio_player.play()
	
	# Get playback immediately
	playback = audio_player.get_stream_playback()

	print("SphericalHarmonics: Audio synthesis enabled (Mario Mode)")

func _setup_controls() -> void:
	# TODO: Connect to interactables if available
	# For now, auto-orbit mode
	pass

func _update_small_sphere_position() -> void:
	var x = radius * sin(theta) * cos(phi)
	var y = radius * cos(theta)
	var z = radius * sin(theta) * sin(phi)

	small_sphere.position = Vector3(x, y, z)

	# Update trail using MultiMesh
	if trail_multimesh and trail_multimesh.multimesh:
		var mm = trail_multimesh.multimesh
		var pos = small_sphere.position
		trail_positions[trail_index] = pos
		
		# Update this trail point's transform (visible, at position)
		var t = Transform3D(Basis(), pos)
		mm.set_instance_transform(trail_index, t)
		
		# Update colors to create fading effect (newest = bright, oldest = dim)
		for i in range(TRAIL_LENGTH):
			var age_offset = (trail_index - i + TRAIL_LENGTH) % TRAIL_LENGTH
			var alpha = 0.8 * (1.0 - float(age_offset) / float(TRAIL_LENGTH))
			mm.set_instance_color(i, Color(1, 0.7, 0.2, alpha))
		
		trail_index = (trail_index + 1) % TRAIL_LENGTH

func _update_sound_from_position() -> void:
	# Map theta to start frequency (Pitch)
	var theta_normalized = (sin(theta) + 1.0) / 2.0
	freq_start = lerp(220.0, 880.0, theta_normalized)
	freq_end = freq_start * 2.0 # Classic octave jump

	# Map phi to decay rate (Duration/Snappiness)
	# 0 = Long decay (ringing), 1 = Short decay (pluck)
	var phi_normalized = (sin(phi) + 1.0) / 2.0
	decay_rate = lerp(4.0, 12.0, phi_normalized)

	# Update label
	var label = get_node_or_null("PositionLabel")
	if label:
		label.text = "Mario Mode: F_Start=%.0fHz Decay=%.1f" % [freq_start, decay_rate]

func _process(delta: float) -> void:
	time += delta

	if auto_orbit:
		theta = wrapf(theta + orbit_speed_theta * delta, 0.0, TAU)
		phi = wrapf(phi + orbit_speed_phi * delta, 0.0, TAU)

	_update_small_sphere_position()
	_update_sound_from_position()
	
	# --- Rhythmic Trigger Logic ---
	# Trigger sound every time theta crosses a quadrant (0, 90, 180, 270 degrees)
	# This creates a rhythmic "Bling... Bling... Bling..." as it orbits
	var current_quadrant = int((theta / TAU) * 4.0) % 4
	if current_quadrant != last_quadrant:
		_trigger_sound()
		last_quadrant = current_quadrant
	
	_generate_audio_samples()
	_update_visualizations()

func _trigger_sound() -> void:
	current_time_in_sound = 0.0
	is_playing_sound = true
	
	# Visual flair on trigger
	var tween = create_tween()
	tween.tween_property(small_sphere, "scale", Vector3.ONE * 2.0, 0.05)
	tween.tween_property(small_sphere, "scale", Vector3.ONE, 0.2)

func _generate_audio_samples() -> void:
	if not playback:
		return

	var frames_available = playback.get_frames_available()
	if frames_available < 256:
		return

	var frames_to_fill = min(frames_available, 512)

	for _frame in range(frames_to_fill):
		var sample: float = 0.0
		
		if is_playing_sound:
			# Mario Sound Synthesis Logic
			current_time_in_sound += 1.0 / SAMPLE_RATE
			var progress = current_time_in_sound / sound_duration
			
			if progress >= 1.0:
				is_playing_sound = false
				sample = 0.0
			else:
				# Rising frequency chirp
				var freq = freq_start + ((freq_end - freq_start) * progress)
				
				# Exponential decay
				var envelope = exp(-progress * decay_rate)
				
				# Square wave using lookup table (OPTIMIZED)
				var phase = fposmod(freq * current_time_in_sound, 1.0)
				var wave = WavefunctionResources.fast_square(phase)
				
				sample = wave * envelope * 0.5

		playback.push_frame(Vector2(sample, sample))

func _update_visualizations() -> void:
	# Pulse color based on audio envelope
	var intensity = 0.0
	if is_playing_sound:
		var progress = current_time_in_sound / sound_duration
		intensity = exp(-progress * decay_rate)

	var freq_normalized = (freq_start - 220.0) / 660.0
	var color = Color(1.0 - freq_normalized * 0.5, 0.5 + intensity * 0.5, 0.2 + freq_normalized * 0.6, 1.0)
	var material = small_sphere.material_override as StandardMaterial3D
	if material:
		material.albedo_color = color
		material.emission = color * (0.5 + intensity * 2.0)

# Public API

func set_orbit_speed(theta_speed: float, phi_speed: float) -> void:
	orbit_speed_theta = theta_speed
	orbit_speed_phi = phi_speed

func set_position_spherical(new_theta: float, new_phi: float) -> void:
	theta = clamp(new_theta, 0.0, PI)
	phi = wrapf(new_phi, 0.0, TAU)
	_update_small_sphere_position()
	_update_sound_from_position()

func toggle_auto_orbit() -> void:
	auto_orbit = !auto_orbit
	print("SphericalHarmonics: Auto-orbit %s" % ("ON" if auto_orbit else "OFF"))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	var dirty: bool = false
	if config.has("surface"):
		var wanted: String = str(config["surface"]).strip_edges()
		if wanted != "" and wanted != surface:
			surface = wanted
			dirty = true
	if config.has("harmonic_l"):
		var wanted_l: int = int(config["harmonic_l"])
		if wanted_l > 0 and wanted_l != harmonic_l:
			harmonic_l = wanted_l
			dirty = true
	if config.has("harmonic_m"):
		var wanted_m: int = int(config["harmonic_m"])
		if wanted_m >= 0 and wanted_m != harmonic_m:
			harmonic_m = wanted_m
			dirty = true
	# Rebuild ONLY when something changed and _ready has already built once. Called
	# before _ready — the usual order from GridInteractablesComponent — the vars are set
	# and _create_spheres() reads them, so no shipped placement is disturbed.
	if dirty and is_node_ready() and large_sphere != null:
		_build_large_sphere()
