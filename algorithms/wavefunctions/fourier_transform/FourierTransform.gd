extends Node3D
class_name FourierTransform

var time: float = 0.0
var transform_progress: float = 0.0
var frequency_resolution: float = 0.0
var phase_coherence: float = 0.0
var sample_count: int = 64
var frequency_bins: int = 32
var time_waveform: Array = []
var frequency_spectrum: Array = []
var sine_waves: Array = []
var cosine_waves: Array = []
var complex_numbers: Array = []
var flow_particles: Array = []

# Wave parameters
var fundamental_freq: float = 1.0
var harmonics: Array = [1.0, 0.5, 0.3, 0.2, 0.1]  # Harmonic amplitudes
var noise_level: float = 0.1

func _ready():
	# Initialize Fourier Transform visualization
	print("Fourier Transform Visualization initialized")
	create_time_waveform()
	create_frequency_spectrum()
	create_wave_components()
	create_complex_numbers()
	create_flow_particles()
	setup_fourier_metrics()

func _process(delta):
	time += delta
	
	# Simulate transform progress
	transform_progress = min(1.0, time * 0.1)
	frequency_resolution = transform_progress * 0.9
	phase_coherence = transform_progress * 0.85
	
	update_waveforms(delta)
	animate_transform_engine(delta)
	animate_wave_components(delta)
	animate_data_flow(delta)
	update_fourier_metrics(delta)

func create_time_waveform():
	# Create time domain waveform points
	var time_waveform_node = $TimeDomain/TimeWaveform
	for i in range(sample_count):
		var point = CSGSphere3D.new()
		point.radius = 0.05
		point.material_override = StandardMaterial3D.new()
		point.material_override.albedo_color = Color(0.2, 0.8, 0.8, 1)
		point.material_override.emission_enabled = true
		point.material_override.emission = Color(0.2, 0.8, 0.8, 1) * 0.3
		
		# Position along time axis
		var t = float(i) / sample_count
		var x = (t - 0.5) * 6.0  # Scale to fit axis
		var y = 0.0  # Will be calculated based on wave function
		point.position = Vector3(x, y, 0)
		
		time_waveform_node.add_child(point)
		time_waveform.append({
			"point": point,
			"time": t,
			"amplitude": 0.0
		})

func create_frequency_spectrum():
	# Create frequency domain spectrum bars
	var frequency_spectrum_node = $FrequencyDomain/FrequencySpectrum
	for i in range(frequency_bins):
		var bar = CSGBox3D.new()
		bar.size = Vector3(0.15, 1.0, 0.15)
		bar.material_override = StandardMaterial3D.new()
		bar.material_override.albedo_color = Color(0.8, 0.2, 0.8, 1)
		bar.material_override.emission_enabled = true
		bar.material_override.emission = Color(0.8, 0.2, 0.8, 1) * 0.3
		
		# Position along frequency axis
		var f = float(i) / frequency_bins
		var x = (f - 0.5) * 6.0  # Scale to fit axis
		bar.position = Vector3(x, 0, 0)
		
		frequency_spectrum_node.add_child(bar)
		frequency_spectrum.append({
			"bar": bar,
			"frequency": f * 10.0,  # Scale to reasonable frequency range
			"magnitude": 0.0,
			"phase": 0.0
		})

func create_wave_components():
	# Create sine wave components
	var sine_waves_node = $WaveComponents/SineWaves
	for i in range(harmonics.size()):
		var sine_component = CSGCylinder3D.new()
		sine_component.radius = 0.05
		
		sine_component.height = 2.0
		sine_component.material_override = StandardMaterial3D.new()
		sine_component.material_override.albedo_color = Color(0.8, 0.2, 0.2, 1)
		sine_component.material_override.emission_enabled = true
		sine_component.material_override.emission = Color(0.8, 0.2, 0.2, 1) * 0.3
		
		# Position components
		var x = (i - harmonics.size()/2.0) * 0.8
		sine_component.position = Vector3(x, 0, -1)
		
		sine_waves_node.add_child(sine_component)
		sine_waves.append({
			"component": sine_component,
			"frequency": fundamental_freq * (i + 1),
			"amplitude": harmonics[i],
			"phase": 0.0
		})
	
	# Create cosine wave components
	var cosine_waves_node = $WaveComponents/CosineWaves
	for i in range(harmonics.size()):
		var cosine_component = CSGCylinder3D.new()
		cosine_component.radius = 0.05
		co
		cosine_component.height = 2.0
		cosine_component.material_override = StandardMaterial3D.new()
		cosine_component.material_override.albedo_color = Color(0.2, 0.8, 0.2, 1)
		cosine_component.material_override.emission_enabled = true
		cosine_component.material_override.emission = Color(0.2, 0.8, 0.2, 1) * 0.3
		
		# Position components
		var x = (i - harmonics.size()/2.0) * 0.8
		cosine_component.position = Vector3(x, 0, 0)
		
		cosine_waves_node.add_child(cosine_component)
		cosine_waves.append({
			"component": cosine_component,
			"frequency": fundamental_freq * (i + 1),
			"amplitude": harmonics[i],
			"phase": PI/2  # Cosine is 90 degrees out of phase
		})

func create_complex_numbers():
	# Create complex number representations
	var complex_numbers_node = $WaveComponents/ComplexNumbers
	for i in range(8):
		var complex_repr = CSGSphere3D.new()
		complex_repr.radius = 0.08
		complex_repr.material_override = StandardMaterial3D.new()
		complex_repr.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		complex_repr.material_override.emission_enabled = true
		complex_repr.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position in complex plane representation
		var angle = float(i) / 8.0 * PI * 2
		var radius = 1.5
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		complex_repr.position = Vector3(x, 0, z + 1)
		
		complex_numbers_node.add_child(complex_repr)
		complex_numbers.append({
			"representation": complex_repr,
			"real": cos(angle),
			"imaginary": sin(angle),
			"magnitude": 1.0,
			"phase": angle
		})

func create_flow_particles():
	# Create transform flow particles
	var flow_particles_node = $DataFlow/FlowParticles
	for i in range(30):
		var particle = CSGSphere3D.new()
		particle.radius = 0.05
		particle.material_override = StandardMaterial3D.new()
		particle.material_override.albedo_color = Color(0.8, 0.8, 0.2, 1)
		particle.material_override.emission_enabled = true
		particle.material_override.emission = Color(0.8, 0.8, 0.2, 1) * 0.3
		
		# Position particles along the transform flow path
		var progress = float(i) / 30
		var x = lerp(-8, 8, progress)
		var y = sin(progress * PI * 4) * 2.0
		particle.position = Vector3(x, y, 0)
		
		flow_particles_node.add_child(particle)
		flow_particles.append(particle)

func setup_fourier_metrics():
	# Initialize Fourier metrics
	var resolution_indicator = $FourierMetrics/ResolutionMeter/ResolutionIndicator
	var phase_indicator = $FourierMetrics/PhaseCoherenceMeter/PhaseIndicator
	if resolution_indicator:
		resolution_indicator.position.x = 0  # Start at middle
	if phase_indicator:
		phase_indicator.position.x = 0  # Start at middle

func update_waveforms(delta):
	# Update time domain waveform
	for i in range(time_waveform.size()):
		var point_data = time_waveform[i]
		var point = point_data["point"]
		var t = point_data["time"]
		
		# Calculate composite wave from harmonics
		var amplitude = 0.0
		for j in range(harmonics.size()):
			var freq = fundamental_freq * (j + 1)
			var harmonic_amp = harmonics[j]
			amplitude += harmonic_amp * sin(2 * PI * freq * (t + time * 0.5))
		
		# Add some noise
		amplitude += randf_range(-noise_level, noise_level)
		
		point_data["amplitude"] = amplitude
		
		# Update visual position
		if point:
			var target_y = amplitude * 2.0  # Scale for visibility
			point.position.y = lerp(point.position.y, target_y, delta * 3.0)
			
			# Pulse based on amplitude
			var pulse = 1.0 + abs(amplitude) * 0.5
			point.scale = Vector3.ONE * pulse
			
			# Color based on amplitude
			var intensity = abs(amplitude)
			point.material_override.albedo_color = Color(0.2 + intensity * 0.6, 0.8, 0.8 - intensity * 0.6, 1)
	
	# Perform simplified FFT calculation for frequency domain
	update_frequency_spectrum(delta)

func update_frequency_spectrum(delta):
	# Simplified FFT calculation (for visualization purposes)
	for i in range(frequency_spectrum.size()):
		var spectrum_data = frequency_spectrum[i]
		var bar = spectrum_data["bar"]
		var freq = spectrum_data["frequency"]
		
		# Calculate magnitude for this frequency bin
		var magnitude = 0.0
		var phase_sum = 0.0
		
		# Sample from time domain data
		for j in range(time_waveform.size()):
			var t = time_waveform[j]["time"]
			var amplitude = time_waveform[j]["amplitude"]
			
			# Simplified DFT calculation
			var real_part = amplitude * cos(2 * PI * freq * t)
			var imag_part = amplitude * sin(2 * PI * freq * t)
			
			magnitude += sqrt(real_part * real_part + imag_part * imag_part)
			phase_sum += atan2(imag_part, real_part)
		
		magnitude = magnitude / time_waveform.size()
		var phase = phase_sum / time_waveform.size()
		
		spectrum_data["magnitude"] = magnitude
		spectrum_data["phase"] = phase
		
		# Update visual representation
		if bar:
			var target_height = magnitude * 4.0 + 0.1  # Scale and add minimum height
			bar.size.y = lerp(bar.size.y, target_height, delta * 2.0)
			bar.position.y = target_height * 0.5  # Center at base
			
			# Color based on magnitude
			var intensity = clamp(magnitude, 0.0, 1.0)
			bar.material_override.albedo_color = Color(0.8 * intensity, 0.2 + 0.6 * intensity, 0.8 - 0.6 * intensity, 1)
			
			# Emission based on phase
			var phase_intensity = (sin(phase + time * 2.0) * 0.5 + 0.5) * intensity
			bar.material_override.emission = bar.material_override.albedo_color * (0.3 + phase_intensity * 0.4)

func animate_transform_engine(delta):
	# Animate transform engine core
	var engine_core = $TransformEngine/EngineCore
	if engine_core:
		# Rotate engine
		engine_core.rotation.y += delta * 0.5
		
		# Pulse based on transform progress
		var pulse = 1.0 + sin(time * 2.0) * 0.1 * transform_progress
		engine_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity based on transform activity
		if engine_core.material_override:
			var intensity = 0.3 + transform_progress * 0.7
			engine_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate transform method cores
	var fft_core = $TransformEngine/TransformMethods/FFTCore
	if fft_core:
		fft_core.rotation.y += delta * 0.8
		var fft_activation = sin(time * 1.5) * 0.5 + 0.5
		fft_activation *= transform_progress
		
		var pulse = 1.0 + fft_activation * 0.3
		fft_core.scale = Vector3.ONE * pulse
		
		if fft_core.material_override:
			var intensity = 0.3 + fft_activation * 0.7
			fft_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var dft_core = $TransformEngine/TransformMethods/DFTCore
	if dft_core:
		dft_core.rotation.y += delta * 1.0
		var dft_activation = cos(time * 1.8) * 0.5 + 0.5
		dft_activation *= transform_progress
		
		var pulse = 1.0 + dft_activation * 0.3
		dft_core.scale = Vector3.ONE * pulse
		
		if dft_core.material_override:
			var intensity = 0.3 + dft_activation * 0.7
			dft_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	var ifft_core = $TransformEngine/TransformMethods/IFFTCore
	if ifft_core:
		ifft_core.rotation.y += delta * 1.2
		var ifft_activation = sin(time * 2.0) * 0.5 + 0.5
		ifft_activation *= transform_progress
		
		var pulse = 1.0 + ifft_activation * 0.3
		ifft_core.scale = Vector3.ONE * pulse
		
		if ifft_core.material_override:
			var intensity = 0.3 + ifft_activation * 0.7
			ifft_core.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity

func animate_wave_components(delta):
	# Animate wave components core
	var components_core = $WaveComponents/ComponentsCore
	if components_core:
		# Rotate components
		components_core.rotation.y += delta * 0.3
		
		# Pulse based on transform progress
		var pulse = 1.0 + sin(time * 2.5) * 0.1 * transform_progress
		components_core.scale = Vector3.ONE * pulse
		
		# Change emission intensity
		if components_core.material_override:
			var intensity = 0.3 + transform_progress * 0.7
			components_core.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate sine wave components
	for i in range(sine_waves.size()):
		var wave_data = sine_waves[i]
		var component = wave_data["component"]
		
		if component:
			# Scale based on amplitude and frequency activity
			var activity = sin(time * wave_data["frequency"] + wave_data["phase"]) * 0.5 + 0.5
			var amplitude_scale = wave_data["amplitude"] * transform_progress
			var target_height = 2.0 * amplitude_scale * (0.5 + activity * 0.5)
			
			component.height = lerp(component.height, target_height, delta * 2.0)
			
			# Rotation based on frequency
			component.rotation.y += delta * wave_data["frequency"] * 0.5
			
			# Color intensity based on activity
			var intensity = 0.3 + activity * amplitude_scale * 0.7
			component.material_override.emission = Color(0.8, 0.2, 0.2, 1) * intensity
	
	# Animate cosine wave components
	for i in range(cosine_waves.size()):
		var wave_data = cosine_waves[i]
		var component = wave_data["component"]
		
		if component:
			# Scale based on amplitude and frequency activity
			var activity = cos(time * wave_data["frequency"] + wave_data["phase"]) * 0.5 + 0.5
			var amplitude_scale = wave_data["amplitude"] * transform_progress
			var target_height = 2.0 * amplitude_scale * (0.5 + activity * 0.5)
			
			component.height = lerp(component.height, target_height, delta * 2.0)
			
			# Rotation based on frequency
			component.rotation.y += delta * wave_data["frequency"] * 0.5
			
			# Color intensity based on activity
			var intensity = 0.3 + activity * amplitude_scale * 0.7
			component.material_override.emission = Color(0.2, 0.8, 0.2, 1) * intensity
	
	# Animate complex numbers
	for i in range(complex_numbers.size()):
		var complex_data = complex_numbers[i]
		var representation = complex_data["representation"]
		
		if representation:
			# Rotate in complex plane
			var phase = complex_data["phase"] + time * 1.0
			var magnitude = complex_data["magnitude"] * (0.8 + 0.2 * transform_progress)
			
			var x = cos(phase) * magnitude * 1.5
			var z = sin(phase) * magnitude * 1.5 + 1
			
			representation.position.x = lerp(representation.position.x, x, delta * 2.0)
			representation.position.z = lerp(representation.position.z, z, delta * 2.0)
			
			# Pulse based on magnitude
			var pulse = 1.0 + magnitude * 0.3
			representation.scale = Vector3.ONE * pulse
			
			# Color based on phase
			var hue = phase / (PI * 2)
			var sat = 0.8
			var val = 0.8
			# Simple HSV to RGB conversion for demonstration
			var color = Color(val, val, val, 1)  # Simplified
			representation.material_override.albedo_color = color

func animate_data_flow(delta):
	# Animate flow particles
	for i in range(flow_particles.size()):
		var particle = flow_particles[i]
		if particle:
			# Move particles through the transform flow
			var progress = (time * 0.3 + float(i) * 0.08) % 1.0
			var x = lerp(-8, 8, progress)
			var y = sin(progress * PI * 4) * 2.0
			
			particle.position.x = lerp(particle.position.x, x, delta * 2.0)
			particle.position.y = lerp(particle.position.y, y, delta * 2.0)
			
			# Change color based on position and transform progress
			var color_progress = fmod((progress + 0.5), 1.0)
			var red_component = 0.8 * (0.5 + color_progress * 0.5)
			var blue_component = 0.8 * (0.5 + (1.0 - color_progress) * 0.5)
			particle.material_override.albedo_color = Color(red_component, 0.2, blue_component, 1)
			particle.material_override.emission = Color(red_component, 0.2, blue_component, 1) * 0.3
			
			# Pulse particles based on transform
			var pulse = 1.0 + sin(time * 3.0 + i * 0.3) * 0.2 * transform_progress
			particle.scale = Vector3.ONE * pulse

func update_fourier_metrics(delta):
	# Update frequency resolution meter
	var resolution_indicator = $FourierMetrics/ResolutionMeter/ResolutionIndicator
	if resolution_indicator:
		var target_x = lerp(-2, 2, frequency_resolution)
		resolution_indicator.position.x = lerp(resolution_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on resolution
		var green_component = 0.8 * frequency_resolution
		var red_component = 0.2 + 0.6 * (1.0 - frequency_resolution)
		resolution_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)
	
	# Update phase coherence meter
	var phase_indicator = $FourierMetrics/PhaseCoherenceMeter/PhaseIndicator
	if phase_indicator:
		var target_x = lerp(-2, 2, phase_coherence)
		phase_indicator.position.x = lerp(phase_indicator.position.x, target_x, delta * 2.0)
		
		# Change color based on phase coherence
		var green_component = 0.8 * phase_coherence
		var red_component = 0.2 + 0.6 * (1.0 - phase_coherence)
		phase_indicator.material_override.albedo_color = Color(red_component, green_component, 0.2, 1)

func set_fundamental_frequency(freq: float):
	fundamental_freq = clamp(freq, 0.1, 5.0)

func set_noise_level(noise: float):
	noise_level = clamp(noise, 0.0, 0.5)

func get_transform_progress() -> float:
	return transform_progress

func get_frequency_resolution() -> float:
	return frequency_resolution

func get_phase_coherence() -> float:
	return phase_coherence

func reset_transform():
	time = 0.0
	transform_progress = 0.0
	frequency_resolution = 0.0
	phase_coherence = 0.0
