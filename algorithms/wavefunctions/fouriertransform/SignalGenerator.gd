extends Node3D

@export var signal_type: int = 0  # 0=Sine, 1=Square, 2=Triangle, 3=Sawtooth
@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var harmonics: int = 1

## DNA (declared on the scene root, FourierTransform.gd, and pushed down here).
## domain — which side of the transform is standing in the room. Before promotion the
##          frequency bars were built and immediately hidden, revealed only by a UI
##          button that map placements suppress: the artifact called "Fourier Transform"
##          never showed the transform.
## trace  — how much of the sampling is admitted. The signal has always been drawn as
##          20 discrete spheres; whether that discreteness is confessed (stems), merely
##          shown (samples) or hidden behind a continuum (ribbon) is the argument.
var domain: String = "time"
var trace: String = "samples"

var time_domain_points: Array[CSGSphere3D] = []
var frequency_domain_bars: Array[CSGBox3D] = []
var stem_meshes: Array[MeshInstance3D] = []
var ribbon: MeshInstance3D
var ribbon_mesh: ImmediateMesh
var time_domain_size = 20
var frequency_domain_size = 16
var time_resolution = 0.5
var animation_time = 0.0
var show_frequency_domain = false

func _ready() -> void:
	create_time_domain_display()
	create_frequency_domain_display()
	_apply_domain()

func _process(delta: float) -> void:
	animation_time += delta
	update_time_domain_signal()

func create_time_domain_display() -> void:
	# Clear existing points
	for point in time_domain_points:
		point.queue_free()
	time_domain_points.clear()
	for stem in stem_meshes:
		stem.queue_free()
	stem_meshes.clear()

	# Create time domain visualization points
	for i in range(-time_domain_size/2, time_domain_size/2):
		var point = CSGSphere3D.new()
		point.radius = 0.1
		point.position = Vector3(i * time_resolution, 0, 0)

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.7, 0.9)
		material.metallic = 0.1
		material.roughness = 0.8
		point.material_override = material

		add_child(point)
		time_domain_points.append(point)

		# The stem that says where the sample was taken from. Hidden unless trace=stems.
		var stem := MeshInstance3D.new()
		var stem_mesh := BoxMesh.new()
		stem_mesh.size = Vector3(0.09, 1.0, 0.09)
		stem.mesh = stem_mesh
		stem.position = Vector3(i * time_resolution, 0, 0)
		var stem_material := StandardMaterial3D.new()
		stem_material.albedo_color = Color(0.2, 0.7, 0.9)
		stem_material.metallic = 0.1
		stem_material.roughness = 0.8
		stem.material_override = stem_material
		stem.visible = false
		add_child(stem)
		stem_meshes.append(stem)

	_ensure_ribbon()
	_apply_trace()

func _ensure_ribbon() -> void:
	# The continuum reading: a filled band from the zero line up to the signal, with no
	# sample markers at all. Regenerated per frame, so ImmediateMesh rather than ArrayMesh.
	if ribbon and is_instance_valid(ribbon):
		return
	ribbon_mesh = ImmediateMesh.new()
	ribbon = MeshInstance3D.new()
	ribbon.mesh = ribbon_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.7, 0.9)
	material.metallic = 0.1
	material.roughness = 0.6
	material.emission_enabled = true
	material.emission = Color(0.2, 0.7, 0.9)
	material.emission_energy_multiplier = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.material_override = material
	ribbon.visible = false
	add_child(ribbon)

func create_frequency_domain_display() -> void:
	# Clear existing bars
	for bar in frequency_domain_bars:
		bar.queue_free()
	frequency_domain_bars.clear()
	
	# Create frequency domain visualization bars
	for i in range(frequency_domain_size):
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.8, 0.1, 0.1)
		bar.position = Vector3(i * 1.2 - frequency_domain_size/2 * 1.2, 0, 10)
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.9, 0.3, 0.6)
		material.metallic = 0.2
		material.roughness = 0.7
		bar.material_override = material
		
		add_child(bar)
		frequency_domain_bars.append(bar)
	
	# Initially hide frequency domain
	set_frequency_domain_visible(false)

func update_time_domain_signal() -> void:
	for i in range(time_domain_points.size()):
		var point = time_domain_points[i]
		var x = (i - time_domain_points.size()/2) * time_resolution
		var t = x + animation_time * 2.0
		
		var y = generate_signal_at_time(t)
		point.position.y = y * amplitude
		
		# Color based on signal value
		var signal_ratio = (y + 1.0) / 2.0
		var color = lerp(Color(0.2, 0.7, 0.9), Color(0.9, 0.3, 0.6), signal_ratio)
		
		if point.material_override:
			point.material_override.albedo_color = color

	if trace == "stems":
		_update_stems()
	elif trace == "ribbon":
		_update_ribbon()

func _update_stems() -> void:
	for i in range(stem_meshes.size()):
		if i >= time_domain_points.size():
			break
		var stem: MeshInstance3D = stem_meshes[i]
		var y: float = time_domain_points[i].position.y
		var height: float = maxf(0.05, absf(y))
		stem.scale = Vector3(1.0, height, 1.0)
		stem.position.y = y * 0.5

func _update_ribbon() -> void:
	if ribbon_mesh == null:
		return
	ribbon_mesh.clear_surfaces()
	if time_domain_points.size() < 2:
		return
	ribbon_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(time_domain_points.size()):
		var p: Vector3 = time_domain_points[i].position
		ribbon_mesh.surface_set_normal(Vector3(0, 0, 1))
		ribbon_mesh.surface_add_vertex(Vector3(p.x, 0.0, 0.0))
		ribbon_mesh.surface_set_normal(Vector3(0, 0, 1))
		ribbon_mesh.surface_add_vertex(Vector3(p.x, p.y, 0.0))
	ribbon_mesh.surface_end()

func _apply_trace() -> void:
	var show_time: bool = domain != "frequency"
	var show_points: bool = show_time and trace != "ribbon"
	var show_stems: bool = show_time and trace == "stems"
	var show_ribbon: bool = show_time and trace == "ribbon"
	for point in time_domain_points:
		point.visible = show_points
	for stem in stem_meshes:
		stem.visible = show_stems
	if ribbon:
		ribbon.visible = show_ribbon
	if show_stems:
		_update_stems()
	if show_ribbon:
		_update_ribbon()

func _apply_domain() -> void:
	if domain == "time":
		set_frequency_domain_visible(false)
	else:
		compute_fft()
	_apply_trace()

func set_domain_mode(value: String) -> void:
	var wanted: String = value.strip_edges()
	if wanted == "" or wanted == domain:
		return
	domain = wanted
	if is_node_ready():
		_apply_domain()

func set_trace_mode(value: String) -> void:
	var wanted: String = value.strip_edges()
	if wanted == "" or wanted == trace:
		return
	trace = wanted
	if is_node_ready():
		_apply_trace()

func generate_signal_at_time(t: float) -> float:
	var omega = 2.0 * PI * frequency
	var signal_value = 0.0
	
	match signal_type:
		0:  # Sine wave
			signal_value = sin(omega * t)
		1:  # Square wave
			signal_value = sign(sin(omega * t))
		2:  # Triangle wave
			signal_value = 2.0 * abs(2.0 * (omega * t / (2.0 * PI) - floor(omega * t / (2.0 * PI) + 0.5))) - 1.0
		3:  # Sawtooth wave
			signal_value = 2.0 * (omega * t / (2.0 * PI) - floor(omega * t / (2.0 * PI) + 0.5))
	
	# Add harmonics
	if harmonics > 1:
		for h in range(2, harmonics + 1):
			var harmonic_amplitude = 1.0 / h
			match signal_type:
				0:  # Sine harmonics
					signal_value += harmonic_amplitude * sin(h * omega * t)
				1:  # Square harmonics (odd harmonics only)
					if h % 2 == 1:
						signal_value += harmonic_amplitude * sin(h * omega * t)
				2:  # Triangle harmonics (odd harmonics only)
					if h % 2 == 1:
						signal_value += harmonic_amplitude * sin(h * omega * t)
				3:  # Sawtooth harmonics
					signal_value += harmonic_amplitude * sin(h * omega * t)
	
	return signal_value

func compute_fft() -> void:
	# Simple FFT-like visualization
	# In a real implementation, you'd use a proper FFT algorithm
	var signal_samples = []
	for i in range(frequency_domain_size):
		var t = (i - frequency_domain_size/2) * 0.1
		signal_samples.append(generate_signal_at_time(t))
	
	# Calculate frequency components (simplified)
	var frequency_components = []
	for freq in range(frequency_domain_size):
		var component = 0.0
		for i in range(frequency_domain_size):
			var t = (i - frequency_domain_size/2) * 0.1
			component += signal_samples[i] * cos(2.0 * PI * freq * t / frequency_domain_size)
		frequency_components.append(abs(component))
	
	# Update frequency domain visualization
	for i in range(frequency_domain_bars.size()):
		var bar = frequency_domain_bars[i]
		var height = frequency_components[i] * 5.0  # Scale for visibility
		bar.size.y = max(0.1, height)
		bar.position.y = height / 2.0
	
	# Show frequency domain
	set_frequency_domain_visible(true)

func reset_signal() -> void:
	animation_time = 0.0
	# Reset returns to whatever the DNA says this placement is; at domain=time that is
	# exactly the pre-promotion behaviour (frequency bars hidden).
	_apply_domain()
	update_time_domain_signal()

func set_frequency_domain_visible(visible: bool) -> void:
	for bar in frequency_domain_bars:
		bar.visible = visible

func update_signal() -> void:
	# This function is called when parameters change
	update_time_domain_signal()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
