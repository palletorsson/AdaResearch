@tool
extends Node3D

@export var spectrum_length: float = 10.0
@export var dot_count: int = 60
@export var dot_size: float = 0.5
@export var cycle_duration: float = 12.0

var time: float = 0.0
var _dots: Array[MeshInstance3D] = []
var _magenta_dots: Array[MeshInstance3D] = []

func _ready():
	_create_spectrum()

func _process(delta):
	time += delta
	_animate()

func _create_spectrum():
	for child in get_children():
		child.queue_free()
	_dots.clear()
	_magenta_dots.clear()
	
	# Create Spectral Dots (400nm - 700nm)
	for i in range(dot_count):
		var t = float(i) / (dot_count - 1)
		# Wavelength from 400 (Violet) to 700 (Red)
		var wavelength = lerp(400.0, 700.0, t)
		var color = _wavelength_to_color(wavelength)
		
		var dot = _create_dot(color)
		_dots.append(dot)
		add_child(dot)
	
	# Create Magenta Dots (The "Gap" Fillers)
	var magenta_count = int(dot_count / 3)
	for i in range(magenta_count):
		var t = float(i) / (magenta_count - 1)
		# Gradient from Red (end) to Violet (start)
		var color = Color(1.0, 0.0, 0.0).lerp(Color(0.5, 0.0, 1.0), t) # Simple Red->Violet mix
		
		var dot = _create_dot(color)
		dot.visible = false
		_magenta_dots.append(dot)
		add_child(dot)

func _create_dot(color: Color) -> MeshInstance3D:
	var mesh = SphereMesh.new()
	mesh.radius = dot_size * 0.5
	mesh.height = dot_size
	
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	
	return mi

func _animate():
	# Animation now ping-pongs: Linear -> Circular -> Linear -> ...
	# Full cycle: 0.0-0.5 forward, 0.5-1.0 backward
	
	var phase = fmod(time / cycle_duration, 1.0)
	
	# Create ping-pong effect
	var linear_phase: float
	if phase < 0.5:
		linear_phase = phase * 2.0  # 0.0 -> 1.0
	else:
		linear_phase = (1.0 - phase) * 2.0  # 1.0 -> 0.0
	
	var smooth_t = smoothstep(0.0, 1.0, linear_phase)
	
	# Radius for circular mode
	var radius = spectrum_length / PI * 0.5
	
	# Animate Spectral Dots
	for i in range(_dots.size()):
		var t = float(i) / (_dots.size() - 1)
		
		# Linear Position: Straight line centered on X axis
		var pos_linear = Vector3(lerp(-spectrum_length/2.0, spectrum_length/2.0, t), 0, 0)
		
		# Circular Position: 270 degrees arc (leaving gap for magenta)
		# Map t (0..1) to angle (-135 .. +135 degrees)
		var angle_start = deg_to_rad(-135.0)
		var angle_end = deg_to_rad(135.0)
		var angle = lerp(angle_start, angle_end, t) # Red is right, Violet is left
		var pos_circle = Vector3(sin(angle) * radius, cos(angle) * radius + radius, 0)
		
		_dots[i].position = pos_linear.lerp(pos_circle, smooth_t)
		
	# Animate Magenta Dots (Only visible in circle mode)
	for i in range(_magenta_dots.size()):
		var t = float(i) / (_magenta_dots.size() - 1)
		
		# Position in the gap (bottom of circle)
		# Angle from +135 to +225 (-135)
		var angle_gap_start = deg_to_rad(135.0)
		var angle_gap_end = deg_to_rad(225.0)
		var angle = lerp(angle_gap_start, angle_gap_end, t)
		
		var pos_circle = Vector3(sin(angle) * radius, cos(angle) * radius + radius, 0)
		
		# Lerp scale/visibility based on mode
		_magenta_dots[i].position = pos_circle
		_magenta_dots[i].scale = Vector3.ONE * smooth_t
		_magenta_dots[i].visible = smooth_t > 0.01

# --- Helper: Wavelength to Color Approximation ---
func _wavelength_to_color(lambda: float) -> Color:
	var r = 0.0
	var g = 0.0
	var b = 0.0
	
	if lambda >= 380 and lambda < 440:
		r = -(lambda - 440) / (440 - 380)
		g = 0.0
		b = 1.0
	elif lambda >= 440 and lambda < 490:
		r = 0.0
		g = (lambda - 440) / (490 - 440)
		b = 1.0
	elif lambda >= 490 and lambda < 510:
		r = 0.0
		g = 1.0
		b = -(lambda - 510) / (510 - 490)
	elif lambda >= 510 and lambda < 580:
		r = (lambda - 510) / (580 - 510)
		g = 1.0
		b = 0.0
	elif lambda >= 580 and lambda < 645:
		r = 1.0
		g = -(lambda - 645) / (645 - 580)
		b = 0.0
	elif lambda >= 645 and lambda <= 780:
		r = 1.0
		g = 0.0
		b = 0.0
		
	return Color(r, g, b)
