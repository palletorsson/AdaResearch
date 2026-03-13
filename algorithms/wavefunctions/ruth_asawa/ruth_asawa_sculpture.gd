@tool
extends MeshInstance3D

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
	if not radius_curve:
		_create_default_curve()
	generate_surface()
	base_scale = scale

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

	# Generate indices
	for i in range(v_resolution):
		for j in range(u_resolution):
			var current = i * (u_resolution + 1) + j
			var next_row = (i + 1) * (u_resolution + 1) + j
			
			if wireframe:
				# Horizontal line
				st.add_index(current)
				st.add_index(current + 1)
				
				# Vertical line
				st.add_index(current)
				st.add_index(next_row)
			else:
				# Triangles
				st.add_index(current)
				st.add_index(current + 1)
				st.add_index(next_row)
				
				st.add_index(current + 1)
				st.add_index(next_row + 1)
				st.add_index(next_row)

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

	# Generate indices
	for i in range(v_resolution):
		for j in range(u_resolution):
			var current := i * (u_resolution + 1) + j
			var next_row := (i + 1) * (u_resolution + 1) + j

			if wireframe:
				st.add_index(current)
				st.add_index(current + 1)
				st.add_index(current)
				st.add_index(next_row)
			else:
				st.add_index(current)
				st.add_index(current + 1)
				st.add_index(next_row)
				st.add_index(current + 1)
				st.add_index(next_row + 1)
				st.add_index(next_row)

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
