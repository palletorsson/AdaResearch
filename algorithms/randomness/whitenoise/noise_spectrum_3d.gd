@tool
extends Node3D

# Agent-Spectrum: 3D Noise Spectrum Visualization
# Visualizes different "colors" of noise (White, Pink, Brown, Blue, Violet)
# Based on their spectral density characteristics

enum NoiseType {
	WHITE,    # Equal power at all frequencies (flat spectrum)
	PINK,     # 1/f noise (power decreases with frequency)
	BROWN,    # 1/f² noise (Brownian/red noise)
	BLUE,     # f noise (power increases with frequency)
	VIOLET    # f² noise (power increases faster)
}

@export var noise_type: NoiseType = NoiseType.WHITE:
	set(value):
		noise_type = value
		if is_inside_tree():
			generate_spectrum()

@export var frequency_bins: int = 200  # Number of frequency samples
@export var spacing: float = 0.05
@export var max_height: float = 3.0
@export var line_thickness: float = 0.02
@export var seed_value: int = 0:
	set(value):
		seed_value = value
		if is_inside_tree():
			generate_spectrum()

@export var show_all_types: bool = false:
	set(value):
		show_all_types = value
		if is_inside_tree():
			generate_spectrum()

var _rng = RandomNumberGenerator.new()
var _multi_mesh_instance: MultiMeshInstance3D

# Color mapping for each noise type
var noise_colors = {
	NoiseType.WHITE: Color(0.9, 0.9, 0.9),    # White/Gray
	NoiseType.PINK: Color(1.0, 0.4, 0.7),     # Pink
	NoiseType.BROWN: Color(0.6, 0.2, 0.1),    # Brown/Red
	NoiseType.BLUE: Color(0.2, 0.5, 1.0),     # Blue
	NoiseType.VIOLET: Color(0.7, 0.3, 1.0)    # Violet
}

func _ready():
	_setup_multimesh()
	generate_spectrum()

func _setup_multimesh():
	if _multi_mesh_instance:
		_multi_mesh_instance.queue_free()
	
	_multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(_multi_mesh_instance)
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(line_thickness, 1.0, line_thickness)
	
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = material
	
	_multi_mesh_instance.multimesh = MultiMesh.new()
	_multi_mesh_instance.multimesh.mesh = mesh
	_multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multi_mesh_instance.multimesh.use_colors = true

func generate_spectrum():
	if not _multi_mesh_instance:
		return
	
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	
	if show_all_types:
		_generate_all_types()
	else:
		_generate_single_type(noise_type)

func _generate_single_type(type: NoiseType):
	_multi_mesh_instance.multimesh.instance_count = frequency_bins
	
	for i in range(frequency_bins):
		var frequency_ratio = float(i + 1) / float(frequency_bins)  # 0.0 to 1.0
		var power = _calculate_spectral_power(type, frequency_ratio)
		
		# Add random variation (the "noise" in the spectrum)
		var random_variation = _rng.randf_range(0.7, 1.3)
		power *= random_variation
		
		var height = clamp(power * max_height, 0.01, max_height * 2.0)
		
		# Position along X axis (frequency)
		var x_pos = (i * spacing) - (frequency_bins * spacing / 2.0)
		var pos = Vector3(x_pos, height / 2.0, 0)
		
		# Transform
		var basis = Basis()
		basis = basis.scaled(Vector3(1.0, height, 1.0))
		var transform = Transform3D(basis, pos)
		
		_multi_mesh_instance.multimesh.set_instance_transform(i, transform)
		
		# Color based on noise type
		var color = noise_colors[type]
		color.a = 0.8  # Slight transparency
		_multi_mesh_instance.multimesh.set_instance_color(i, color)

func _generate_all_types():
	var types = [NoiseType.BROWN, NoiseType.PINK, NoiseType.WHITE, NoiseType.BLUE, NoiseType.VIOLET]
	var total_count = frequency_bins * types.size()
	_multi_mesh_instance.multimesh.instance_count = total_count
	
	var idx = 0
	var z_spacing = 2.0  # Space between noise types
	
	for type_idx in range(types.size()):
		var type = types[type_idx]
		var z_offset = (type_idx - 2) * z_spacing  # Center around 0
		
		for i in range(frequency_bins):
			var frequency_ratio = float(i + 1) / float(frequency_bins)
			var power = _calculate_spectral_power(type, frequency_ratio)
			
			# Add random variation
			var random_variation = _rng.randf_range(0.7, 1.3)
			power *= random_variation
			
			var height = clamp(power * max_height, 0.01, max_height * 2.0)
			
			# Position
			var x_pos = (i * spacing) - (frequency_bins * spacing / 2.0)
			var pos = Vector3(x_pos, height / 2.0, z_offset)
			
			# Transform
			var basis = Basis()
			basis = basis.scaled(Vector3(1.0, height, 1.0))
			var transform = Transform3D(basis, pos)
			
			_multi_mesh_instance.multimesh.set_instance_transform(idx, transform)
			
			# Color
			var color = noise_colors[type]
			color.a = 0.7
			_multi_mesh_instance.multimesh.set_instance_color(idx, color)
			
			idx += 1

# Calculate spectral power density for different noise types
# frequency_ratio: 0.0 (low freq) to 1.0 (high freq)
func _calculate_spectral_power(type: NoiseType, frequency_ratio: float) -> float:
	# Avoid division by zero
	var f = max(frequency_ratio, 0.01)
	
	match type:
		NoiseType.WHITE:
			# Equal power at all frequencies
			return 1.0
		
		NoiseType.PINK:
			# 1/f noise (power decreases with frequency)
			return 1.0 / f
		
		NoiseType.BROWN:
			# 1/f² noise (Brownian/red noise)
			return 1.0 / (f * f)
		
		NoiseType.BLUE:
			# f noise (power increases with frequency)
			return f
		
		NoiseType.VIOLET:
			# f² noise (power increases faster)
			return f * f
	
	return 1.0
