extends Node3D

@export var signal_type: int = 0  # 0=Sine, 1=Square, 2=Triangle, 3=Sawtooth
@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var harmonics: int = 1

var time_domain_points: Array[CSGSphere3D] = []
var frequency_domain_bars: Array[CSGBox3D] = []
var time_domain_size = 20
var frequency_domain_size = 16
var time_resolution = 0.5
var animation_time = 0.0
var show_frequency_domain = false

func _ready():
	create_time_domain_display()
	create_frequency_domain_display()

func _process(delta):
	animation_time += delta
	update_time_domain_signal()

func create_time_domain_display():
	# Clear existing points
	for point in time_domain_points:
		point.queue_free()
	time_domain_points.clear()
	
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

func create_frequency_domain_display():
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

func update_time_domain_signal():
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

func compute_fft():
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

func reset_signal():
	animation_time = 0.0
	set_frequency_domain_visible(false)
	update_time_domain_signal()

func set_frequency_domain_visible(visible: bool):
	for bar in frequency_domain_bars:
		bar.visible = visible

func update_signal():
	# This function is called when parameters change
	update_time_domain_signal()
