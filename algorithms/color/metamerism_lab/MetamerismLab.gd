@tool
extends Node3D

@export var wave_speed: float = 2.0
@export var wave_amplitude: float = 0.5

var time: float = 0.0

var _left_source: MeshInstance3D # Pure Yellow
var _right_source: MeshInstance3D # Red + Green Mixed
var _left_wave: Node3D
var _right_wave: Node3D
var _left_result: MeshInstance3D
var _right_result: MeshInstance3D

func _ready() -> void:
	_create_lab()

func _process(delta: float) -> void:
	time += delta
	_animate(delta)

func _create_lab() -> void:
	for child in get_children():
		child.queue_free()
		
	# --- Left Side: Pure Physics (580nm) ---
	_left_source = _create_box(Color(1.0, 1.0, 0.0), Vector3(-2, 2, 0)) # Yellow box
	_left_result = _create_sphere(Color(1.0, 1.0, 0.0), Vector3(-2, -2, 0)) # Yellow result
	_left_wave = Node3D.new()
	_left_wave.position = Vector3(-2, 0, 0)
	add_child(_left_wave)
	
	# --- Right Side: Mixed Physics (650nm + 540nm) ---
	_right_source = _create_box(Color(1.0, 1.0, 1.0), Vector3(2, 2, 0)) # White/Mixed box
	_right_result = _create_sphere(Color(1.0, 1.0, 0.0), Vector3(2, -2, 0)) # Yellow result (IDENTICAL COLOR)
	_right_wave = Node3D.new()
	_right_wave.position = Vector3(2, 0, 0)
	add_child(_right_wave)
	
	# Create fixed "dots" for wave visualization
	_create_wave_dots(_left_wave, 1) # Single yellow wave
	_create_wave_dots(_right_wave, 2) # Red and Green waves

func _create_wave_dots(parent: Node, count: int) -> void:
	for i in range(20):
		for c in range(count):
			var dot = MeshInstance3D.new()
			dot.mesh = SphereMesh.new()
			dot.mesh.radius = 0.05
			dot.mesh.height = 0.1
			dot.material_override = StandardMaterial3D.new()
			dot.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			
			if count == 1:
				dot.material_override.albedo_color = Color(1.0, 1.0, 0.0) # pure yellow
			elif c == 0:
				dot.material_override.albedo_color = Color(1.0, 0.0, 0.0) # red
			else:
				dot.material_override.albedo_color = Color(0.0, 1.0, 0.0) # green
				
			parent.add_child(dot)
			# Store initial index for animation
			dot.set_meta("idx", i)
			dot.set_meta("channel", c)

func _create_box(color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.mesh.size = Vector3(1, 1, 1)
	mi.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)
	return mi

func _create_sphere(color: Color, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = SphereMesh.new()
	mi.mesh.radius = 0.5
	mi.mesh.height = 1.0
	mi.position = pos
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)
	return mi

func _animate(_delta) -> void:
	# Animate Left Wave (Single Yellow Frequency)
	for child in _left_wave.get_children():
		var idx = child.get_meta("idx")
		var y_base = lerp(2.0, -2.0, float(idx)/19.0)
		# 580nm approx frequency = medium
		var x_offset = sin(time * wave_speed * 1.0 + y_base * 4.0) * wave_amplitude
		child.position = Vector3(x_offset, y_base, 0)
		
	# Animate Right Wave (Red + Green Frequencies)
	for child in _right_wave.get_children():
		var idx = child.get_meta("idx")
		var channel = child.get_meta("channel")
		var y_base = lerp(2.0, -2.0, float(idx)/19.0)
		
		# Red (slower, longer wavelength)
		if channel == 0:
			var x_offset = sin(time * wave_speed * 0.8 + y_base * 3.0) * wave_amplitude
			child.position = Vector3(x_offset - 0.2, y_base, 0) # Offset slightly left
			
		# Green (faster, shorter wavelength)
		else:
			var x_offset = sin(time * wave_speed * 1.2 + y_base * 5.0) * wave_amplitude
			child.position = Vector3(x_offset + 0.2, y_base, 0) # Offset slightly right

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

