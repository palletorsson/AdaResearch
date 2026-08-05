@tool
extends MeshInstance3D


# @identity
# essence: surface(u,v) = radius_curve(u) * (cos(v), sin(v)) + audio_reactive_deformation
# desire: See a wire-mesh sculpture breathe and deform in response to ambient sound
# critical_parameter: radius_curve — the profile curve that defines the lobed silhouette of the hanging form
# triggers: audio spectrum analysis modulates the surface; band_values deform the mesh in real-time
# emerges: sculpture as frozen listening — the wire form records sound as spatial deformation
# needs: VR spatial audio input [has], spectrum analyzer [has]
# relationships: depends on AudioEffectSpectrumAnalyzer; contrasts with kusama_sine (restrained wire vs excessive dots); unlocks sound-reactive sculpture
# truth: A wire sculpture is a surface of revolution that has learned to listen.

@export_category("Mesh Settings")
@export_range(10, 200, 1) var u_resolution: int = 60
@export_range(10, 200, 1) var v_resolution: int = 100
@export var radius_curve: Curve
@export var height: float = 10.0
@export var max_radius: float = 2.0
@export var wireframe: bool = true

@export_category("Animation")
@export var auto_rotate: bool = true
@export var rotation_speed: float = 0.5

## --- DNA (stage 2, promoted 2026-08-05) ------------------------------------------------
## TWO AXES, AND NEITHER OF THEM TOUCHES THE PROFILE. radius_curve is this artifact's
## declared critical_parameter and the shipped scene supplies its own eight-point curve, so
## the lobed SILHOUETTE is identical at every value below. What the axes open is the pair of
## things Asawa's own titles argue about and this code had nailed shut: how the wire is
## looped, and how many forms are inside the form.
##
## weave — WHICH LINES EXIST, not how many. u_resolution and v_resolution stay exactly what
## they were, un-promoted, because a resolution knob is a density knob and says nothing.
## What changes is the topology of the line set laid over the same vertices:
##   grid       both families of segments, the shipped lineage byte for byte — a woven skin.
##   rings      the horizontal loops only. The form reads as stacked contours: the profile
##              curve made literal, a surface of revolution admitting it is one.
##   diagonal   each quad crossed corner to corner instead of edged. The closest this
##              vertex grid comes to a crocheted loop, which is what the wire actually is.
##   meridians  the vertical runs only. A birdcage: the silhouette swept, the surface gone.
## Openness rises from grid to rings, which is the half of the claim that matters — you can
## only see an inner form through a skin loose enough to see through.
##
## nesting — Asawa titled these "Continuous Form within a Form", and counted the layers.
##   single         one surface. The shipped tree: no extra node is created at all.
##   within         one smaller form hung inside, at 0.58 radius and 0.86 height.
##   within_within  two, at 0.62 and 0.34. Inside becomes outside twice over.
## Every inner form is strictly inside the outer one, so the merged AABB — and therefore the
## sweep's camera — is the same at every value.
##
## DEFAULT PRESERVES. weave = "grid" emits the two index pairs in the shipped order from the
## shipped loop; nesting = "single" builds nothing and adds no node. The four existing
## placements (WaveFunctions_John_Cage and its _p1/_p2, Curation_Bay_wavefunctions_5, plus
## the John Cage corridor) render exactly as before.
@export_enum("grid", "rings", "diagonal", "meridians") var weave: String = "grid"
@export_enum("single", "within", "within_within") var nesting: String = "single"
const WEAVES: PackedStringArray = ["grid", "rings", "diagonal", "meridians"]
const NESTINGS: PackedStringArray = ["single", "within", "within_within"]
const NEST_HOST := "NestedForms"
## radius scale, height scale — one entry per inner form, outermost first.
const NEST_LAYERS := {
	"single": [],
	"within": [Vector2(0.58, 0.86)],
	"within_within": [Vector2(0.62, 0.90), Vector2(0.34, 0.72)],
}

var _built: bool = false

@export_category("Audio Reactivity")
@export var audio_reactive: bool = false
@export var frequency_influence: float = 2.0  # How much frequency affects shape
@export var volume_pulse: float = 0.5  # How much volume affects scale
@export var audio_smoothing: float = 0.2  # Smoothing factor (lower = smoother)
@export var spectrum_bands: int = 16  # Number of frequency bands to use
@export var debug_audio: bool = false  # Print audio levels

# Audio analysis
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var band_values: PackedFloat32Array
var smoothed_bands: PackedFloat32Array
var current_volume: float = 0.0
var smoothed_volume: float = 0.0
var base_scale: Vector3
var audio_initialized: bool = false
var debug_timer: float = 0.0

func _ready() -> void:
	weave = _pick(weave, WEAVES, "grid")
	nesting = _pick(nesting, NESTINGS, "single")
	if not radius_curve:
		_create_default_curve()
	generate_surface()
	base_scale = scale
	_build_nesting()
	_built = true

## Normalise an axis value to one the code can actually build. A map token or a sweep
## hands a raw string; anything unrecognised falls back to the shipped lineage rather
## than to whatever a match block's wildcard happens to draw.
func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = str(value).strip_edges().to_lower()
	return v if allowed.has(v) else fallback

func _ensure_audio_initialized() -> void:
	if audio_initialized:
		return

	_setup_audio_analysis()
	band_values.resize(spectrum_bands)
	band_values.fill(0.0)
	smoothed_bands.resize(spectrum_bands)
	smoothed_bands.fill(0.0)
	audio_initialized = true
	print("Ruth Asawa: Audio initialized, spectrum_instance = ", spectrum_instance != null)

func _setup_audio_analysis() -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	print("Ruth Asawa: Setting up audio on Master bus (index ", master_bus_index, ")")

	# Check if spectrum analyzer already exists
	var effect_count = AudioServer.get_bus_effect_count(master_bus_index)
	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(master_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, i) as AudioEffectSpectrumAnalyzerInstance
			print("Ruth Asawa: Found existing spectrum analyzer")
			return

	# Create new spectrum analyzer
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 2.0
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048

	AudioServer.add_bus_effect(master_bus_index, spectrum_analyzer)
	effect_count = AudioServer.get_bus_effect_count(master_bus_index)
	spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, effect_count - 1) as AudioEffectSpectrumAnalyzerInstance
	print("Ruth Asawa: Created new spectrum analyzer, instance = ", spectrum_instance != null)

func _process(delta: float) -> void:
	if auto_rotate:
		rotation.y += rotation_speed * delta

	if audio_reactive and not Engine.is_editor_hint():
		_ensure_audio_initialized()
		if spectrum_instance:
			_update_audio_data()
			_apply_audio_to_mesh()

			if debug_audio:
				debug_timer += delta
				if debug_timer > 0.5:
					debug_timer = 0.0
					print("Ruth Asawa: volume=%.2f, bands[0]=%.2f, bands[8]=%.2f" % [smoothed_volume, smoothed_bands[0] if smoothed_bands.size() > 0 else 0, smoothed_bands[8] if smoothed_bands.size() > 8 else 0])

func _create_default_curve() -> void:
	radius_curve = Curve.new()
	# Create a lobed shape similar to the reference
	radius_curve.add_point(Vector2(0.0, 0.2))
	radius_curve.add_point(Vector2(0.1, 0.8)) # Lobe 1
	radius_curve.add_point(Vector2(0.2, 0.1)) # Pinch
	radius_curve.add_point(Vector2(0.35, 0.9)) # Lobe 2
	radius_curve.add_point(Vector2(0.5, 0.15)) # Pinch
	radius_curve.add_point(Vector2(0.7, 1.0)) # Lobe 3 (Big)
	radius_curve.add_point(Vector2(0.85, 0.2)) # Pinch
	radius_curve.add_point(Vector2(1.0, 0.4)) # Bottom

func generate_surface() -> void:
	var st := SurfaceTool.new()
	
	if wireframe:
		st.begin(Mesh.PRIMITIVE_LINES)
	else:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_max := TAU
	
	# Generate vertices
	for i in range(v_resolution + 1):
		var v_ratio = float(i) / float(v_resolution)
		var y = (v_ratio - 0.5) * height # Center vertically
		
		# Sample radius from curve
		var r = 1.0
		if radius_curve:
			r = radius_curve.sample(v_ratio) * max_radius
		
		for j in range(u_resolution + 1):
			var u_ratio = float(j) / float(u_resolution)
			var u = u_ratio * u_max
			
			var x = r * cos(u)
			var z = r * sin(u)
			
			# Add some "woven" offset for wireframe look if desired, 
			# but simple grid is fine for now.
			
			st.set_uv(Vector2(u_ratio, v_ratio))
			st.add_vertex(Vector3(x, -y, z)) # Invert y to match curve top-down logic usually

	# Generate indices — see _add_indices(): weave decides WHICH segments exist.
	_add_indices(st)

	if not wireframe:
		st.generate_normals()
		st.generate_tangents()

	var generated_mesh := st.commit()
	if generated_mesh:
		var material := StandardMaterial3D.new()
		if wireframe:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.albedo_color = Color(1.0, 1.0, 1.0)
			material.emission_enabled = true
			material.emission = Color(1.0, 1.0, 1.0)
			material.emission_energy = 0.6
		else:
			material.albedo_color = Color(1.0, 1.0, 1.0)
			material.metallic = 0.5
			material.roughness = 0.5
			material.cull_mode = BaseMaterial3D.CULL_DISABLED # Show both sides
			
		generated_mesh.surface_set_material(0, material)
		mesh = generated_mesh

## --- weave ------------------------------------------------------------------------------
## The index generator both surfaces share. Same vertices in every case; what changes is
## which segments are drawn between them, which is the only non-density sense in which a
## wire surface can be more or less open.
##
## "grid" emits the two pairs in the shipped order, from the shipped loop, so it is the
## legacy lineage byte for byte. The triangle branch is untouched and ignores weave — with
## wireframe = false there are no lines for the axis to be about, and every placement and
## the scene itself ship wireframe = true.
func _add_indices(st: SurfaceTool) -> void:
	for i in range(v_resolution):
		for j in range(u_resolution):
			var current: int = i * (u_resolution + 1) + j
			var next_row: int = (i + 1) * (u_resolution + 1) + j

			if not wireframe:
				# Triangles
				st.add_index(current)
				st.add_index(current + 1)
				st.add_index(next_row)

				st.add_index(current + 1)
				st.add_index(next_row + 1)
				st.add_index(next_row)
				continue

			match weave:
				"rings":
					# Horizontal loops only — the profile curve made literal.
					st.add_index(current)
					st.add_index(current + 1)
				"meridians":
					# Vertical runs only — a birdcage; the swept silhouette, no skin.
					st.add_index(current)
					st.add_index(next_row)
				"diagonal":
					# Each quad crossed corner to corner: the nearest a vertex grid gets
					# to a crocheted loop, which is what the wire physically is.
					st.add_index(current)
					st.add_index(next_row + 1)
					st.add_index(current + 1)
					st.add_index(next_row)
				_:
					# "grid" — the shipped lineage, horizontal then vertical.
					st.add_index(current)
					st.add_index(current + 1)

					st.add_index(current)
					st.add_index(next_row)


## --- nesting ----------------------------------------------------------------------------
## Form within a form. Each layer is an independent MeshInstance3D child under one host
## node, built from the SAME radius_curve at a reduced radius and height, so the inner
## silhouette is the outer one shrunk — which is what Asawa's nested forms are.
##
## "single" creates no host node at all, so the shipped scene tree is untouched. Inner forms
## are strictly inside the outer, so the merged AABB does not move and the sweep's camera
## is the same at every value.
func _build_nesting() -> void:
	var old: Node = get_node_or_null(NEST_HOST)
	if old:
		remove_child(old)
		old.queue_free()

	var layers: Array = NEST_LAYERS.get(nesting, [])
	if layers.is_empty():
		return

	var host := Node3D.new()
	host.name = NEST_HOST
	add_child(host)
	for k in range(layers.size()):
		var spec: Vector2 = layers[k]
		var mi := MeshInstance3D.new()
		mi.name = "Within%d" % (k + 1)
		mi.mesh = _make_nested_surface(spec.x, spec.y)
		host.add_child(mi)


## One inner form. Same parametric surface as generate_surface(), scaled in radius and
## height, honouring the same weave so the layers read as one crocheted object rather than
## two unrelated meshes.
func _make_nested_surface(rad_scale: float, hgt_scale: float) -> ArrayMesh:
	var st := SurfaceTool.new()

	if wireframe:
		st.begin(Mesh.PRIMITIVE_LINES)
	else:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_max := TAU

	for i in range(v_resolution + 1):
		var v_ratio: float = float(i) / float(v_resolution)
		var y: float = (v_ratio - 0.5) * height * hgt_scale

		var r: float = 1.0
		if radius_curve:
			r = radius_curve.sample(v_ratio) * max_radius
		r *= rad_scale

		for j in range(u_resolution + 1):
			var u_ratio: float = float(j) / float(u_resolution)
			var u: float = u_ratio * u_max
			st.set_uv(Vector2(u_ratio, v_ratio))
			st.add_vertex(Vector3(r * cos(u), -y, r * sin(u)))

	_add_indices(st)

	if not wireframe:
		st.generate_normals()
		st.generate_tangents()

	var inner_mesh := st.commit()
	if inner_mesh:
		var material := StandardMaterial3D.new()
		if wireframe:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# Dimmer than the outer skin, so a still reads which form is inside which.
			material.albedo_color = Color(0.82, 0.86, 0.92)
			material.emission_enabled = true
			material.emission = Color(0.82, 0.86, 0.92)
			material.emission_energy = 0.38
		else:
			material.albedo_color = Color(0.85, 0.85, 0.85)
			material.metallic = 0.5
			material.roughness = 0.5
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		inner_mesh.surface_set_material(0, material)
	return inner_mesh


func _update_audio_data() -> void:
	if not spectrum_instance:
		return

	var max_freq = 4000.0  # Focus on 0-4kHz range
	var freq_step = max_freq / spectrum_bands
	var total_magnitude = 0.0

	for i in range(spectrum_bands):
		var freq = i * freq_step
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq,
			freq + freq_step,
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)

		var linear_mag = magnitude.length()
		var db_mag = linear_to_db(linear_mag + 0.0001)
		var normalized = clamp((db_mag + 60.0) / 60.0, 0.0, 1.0)

		band_values[i] = normalized
		smoothed_bands[i] = lerp(smoothed_bands[i], normalized, audio_smoothing)
		total_magnitude += normalized

	current_volume = total_magnitude / spectrum_bands
	smoothed_volume = lerp(smoothed_volume, current_volume, audio_smoothing)

func _apply_audio_to_mesh() -> void:
	# Apply volume pulse to scale
	var pulse = 1.0 + smoothed_volume * volume_pulse
	scale = base_scale * pulse

	# Regenerate mesh with frequency-modulated shape
	generate_audio_reactive_surface()

func generate_audio_reactive_surface() -> void:
	var st := SurfaceTool.new()

	if wireframe:
		st.begin(Mesh.PRIMITIVE_LINES)
	else:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var u_max := TAU
	var time := Time.get_ticks_msec() / 1000.0
	
	# Get bass, mid, and treble averages for whole-form response
	var bass_avg := 0.0
	var mid_avg := 0.0
	var treble_avg := 0.0
	var bands_per_group := spectrum_bands / 3
	
	for i in range(bands_per_group):
		bass_avg += smoothed_bands[i] if i < smoothed_bands.size() else 0.0
	for i in range(bands_per_group, bands_per_group * 2):
		mid_avg += smoothed_bands[i] if i < smoothed_bands.size() else 0.0
	for i in range(bands_per_group * 2, spectrum_bands):
		treble_avg += smoothed_bands[i] if i < smoothed_bands.size() else 0.0
	
	bass_avg /= bands_per_group
	mid_avg /= bands_per_group
	treble_avg /= bands_per_group

	for i in range(v_resolution + 1):
		var v_ratio := float(i) / float(v_resolution)
		var base_y := (v_ratio - 0.5) * height

		# Base radius from curve - FIXED, not audio-modulated
		var r := 1.0
		if radius_curve:
			r = radius_curve.sample(v_ratio) * max_radius

		# VERTICAL RING MOVEMENT (instead of radius deformation)
		# Each ring moves up/down based on audio frequency bands
		var ring_index := i % spectrum_bands
		var band_influence: float = smoothed_bands[ring_index] if ring_index < smoothed_bands.size() else 0.0
		
		# Bass creates slow vertical waves traveling up the form
		var bass_wave := sin(v_ratio * TAU * 2.0 - time * 2.0) * bass_avg * frequency_influence * 0.3
		
		# Mids add bouncing motion to rings
		var mid_bounce := sin(time * 4.0 + v_ratio * TAU * 3.0) * mid_avg * frequency_influence * 0.2
		
		# Treble adds fine vertical jitter
		var treble_jitter := sin(time * 8.0 + v_ratio * TAU * 6.0) * treble_avg * frequency_influence * 0.1
		
		# Band-specific vertical displacement
		var band_displacement := band_influence * frequency_influence * 0.5
		
		# Total vertical offset for this ring
		var y_offset := bass_wave + mid_bounce + treble_jitter + band_displacement
		var final_y := base_y + y_offset

		for j in range(u_resolution + 1):
			var u_ratio := float(j) / float(u_resolution)
			var u := u_ratio * u_max

			# Radius stays constant - only Y moves
			var x := r * cos(u)
			var z := r * sin(u)

			st.set_uv(Vector2(u_ratio, v_ratio))
			st.add_vertex(Vector3(x, -final_y, z))

	# Generate indices — see _add_indices(): weave decides WHICH segments exist.
	_add_indices(st)

	if not wireframe:
		st.generate_normals()
		st.generate_tangents()

	var generated_mesh := st.commit()
	if generated_mesh:
		var material := StandardMaterial3D.new()
		if wireframe:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# Color shifts with bass
			var hue := fposmod(bass_avg * 0.3, 1.0)
			var wire_color := Color.from_hsv(hue, 0.3, 1.0)
			material.albedo_color = wire_color
			material.emission_enabled = true
			material.emission = wire_color
			material.emission_energy = 0.4 + smoothed_volume * 1.5
		else:
			material.albedo_color = Color(1.0, 1.0, 1.0)
			material.metallic = 0.5
			material.roughness = 0.5
			material.cull_mode = BaseMaterial3D.CULL_DISABLED

		generated_mesh.surface_set_material(0, material)
		mesh = generated_mesh

func apply_grid_config(config: Dictionary) -> void:
	# Was a no-op stub, so no map token could reach anything on this artifact. It now reads
	# exactly two keys, and REBUILDS ONLY WHEN A VALUE ACTUALLY CHANGED and only after
	# _ready has built once — an unguarded rebuild here would tear down and re-lay every
	# vertex on calls that name nothing this artifact owns.
	var changed: bool = false

	if config.has("weave"):
		var w: String = str(config["weave"]).strip_edges().to_lower()
		if WEAVES.has(w) and w != weave:
			weave = w
			changed = true

	if config.has("nesting"):
		var n: String = str(config["nesting"]).strip_edges().to_lower()
		if NESTINGS.has(n) and n != nesting:
			nesting = n
			changed = true

	if not changed or not _built:
		return

	# Both surfaces carry the weave, so the outer is relaid too. When audio_reactive is on,
	# _process overwrites this mesh next frame — through the same _add_indices, so the weave
	# survives; the inner forms are static and are rebuilt here.
	generate_surface()
	_build_nesting()
