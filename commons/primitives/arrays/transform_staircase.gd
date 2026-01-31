@tool
extends Node3D
class_name TransformStaircase

## Transform Staircase - Arrays meet Transformation
## Demonstrates how repetition + transformation = emergent structure
## The staircase that Escher dreamed of, mathematically precise

signal step_changed(index: int, transform: Transform3D)

enum StaircaseType { 
	LINEAR,      # Simple ascending stair
	SPIRAL,      # Helical staircase
	MOBIUS,      # Twisted band
	FIBONACCI,   # Golden spiral scaling
	FRACTAL,     # Self-similar branching
	DNA          # Double helix
}

@export var staircase_type: StaircaseType = StaircaseType.SPIRAL:
	set(v):
		staircase_type = v
		_rebuild()

@export_range(3, 128) var step_count: int = 24:
	set(v):
		step_count = v
		_rebuild()

@export var step_primitive: PackedScene = null:
	set(v):
		step_primitive = v
		_rebuild()

@export var base_scale: Vector3 = Vector3(0.4, 0.1, 0.2):
	set(v):
		base_scale = v
		_rebuild()

# Linear params
@export_group("Linear")
@export var linear_rise: float = 0.15
@export var linear_run: float = 0.3

# Spiral params  
@export_group("Spiral")
@export var spiral_radius: float = 1.5
@export var spiral_rise_per_step: float = 0.12
@export var spiral_angle_per_step: float = 15.0

# Mobius params
@export_group("Mobius")
@export var mobius_radius: float = 2.0
@export var mobius_twist_total: float = 180.0

# Fibonacci params
@export_group("Fibonacci")
@export var fib_scale_factor: float = 1.05
@export var fib_angle: float = 137.5  # Golden angle

# DNA params
@export_group("DNA")
@export var dna_radius: float = 0.8
@export var dna_rise_per_step: float = 0.1
@export var dna_angle_per_step: float = 36.0

@export_group("Visual")
@export var color_gradient: Gradient = null:
	set(v):
		color_gradient = v
		_rebuild()

@export var use_rainbow: bool = true:
	set(v):
		use_rainbow = v
		_rebuild()

@export var emit_light: bool = true

var _steps: Array[Node3D] = []
var _default_mesh: Mesh

func _ready() -> void:
	_create_default_mesh()
	_rebuild()

func _create_default_mesh() -> void:
	# Default step is a box
	var box = BoxMesh.new()
	box.size = Vector3.ONE
	_default_mesh = box

func _rebuild() -> void:
	# Clear existing
	for step in _steps:
		if is_instance_valid(step):
			step.queue_free()
	_steps.clear()
	
	# Build new staircase
	for i in range(step_count):
		var step_transform = _calculate_step_transform(i)
		var step_node = _create_step(i, step_transform)
		_steps.append(step_node)
		add_child(step_node)

func _calculate_step_transform(index: int) -> Transform3D:
	var t = float(index) / max(step_count - 1, 1)
	var xform = Transform3D.IDENTITY
	
	match staircase_type:
		StaircaseType.LINEAR:
			xform = _linear_transform(index)
		StaircaseType.SPIRAL:
			xform = _spiral_transform(index)
		StaircaseType.MOBIUS:
			xform = _mobius_transform(index, t)
		StaircaseType.FIBONACCI:
			xform = _fibonacci_transform(index)
		StaircaseType.FRACTAL:
			xform = _fractal_transform(index, t)
		StaircaseType.DNA:
			xform = _dna_transform(index)
	
	return xform

func _linear_transform(index: int) -> Transform3D:
	var pos = Vector3(
		index * linear_run,
		index * linear_rise,
		0
	)
	return Transform3D(Basis.IDENTITY, pos)

func _spiral_transform(index: int) -> Transform3D:
	var angle = deg_to_rad(index * spiral_angle_per_step)
	var pos = Vector3(
		cos(angle) * spiral_radius,
		index * spiral_rise_per_step,
		sin(angle) * spiral_radius
	)
	# Rotate step to face outward
	var basis = Basis(Vector3.UP, angle + PI/2)
	return Transform3D(basis, pos)

func _mobius_transform(index: int, t: float) -> Transform3D:
	var angle = t * TAU  # Full circle
	var twist = deg_to_rad(t * mobius_twist_total)
	
	var pos = Vector3(
		cos(angle) * mobius_radius,
		sin(twist) * 0.3,  # Slight vertical wave
		sin(angle) * mobius_radius
	)
	
	# Combine rotation around ring with twist
	var basis = Basis(Vector3.UP, angle)
	basis = basis.rotated(basis.z, twist)
	
	return Transform3D(basis, pos)

func _fibonacci_transform(index: int) -> Transform3D:
	var angle = deg_to_rad(index * fib_angle)
	var scale_mult = pow(fib_scale_factor, index)
	var radius = 0.1 * scale_mult
	
	var pos = Vector3(
		cos(angle) * radius,
		index * 0.02 * scale_mult,
		sin(angle) * radius
	)
	
	var basis = Basis(Vector3.UP, angle)
	basis = basis.scaled(Vector3.ONE * min(scale_mult, 3.0))
	
	return Transform3D(basis, pos)

func _fractal_transform(index: int, t: float) -> Transform3D:
	# Branching pattern using bit decomposition
	var angle = 0.0
	var radius = 1.0
	var height = 0.0
	var temp_index = index
	
	for bit in range(7):  # 7 levels of recursion
		if temp_index & 1:
			angle += deg_to_rad(60) * pow(0.7, bit)
			radius *= 0.8
		else:
			angle -= deg_to_rad(45) * pow(0.7, bit)
		height += 0.1 * pow(0.8, bit)
		temp_index >>= 1
	
	var pos = Vector3(
		cos(angle) * radius,
		height,
		sin(angle) * radius
	)
	
	var scale_factor = pow(0.95, index * 0.3)
	var basis = Basis(Vector3.UP, angle).scaled(Vector3.ONE * scale_factor)
	
	return Transform3D(basis, pos)

func _dna_transform(index: int) -> Transform3D:
	var angle = deg_to_rad(index * dna_angle_per_step)
	var height = index * dna_rise_per_step
	
	# Alternate between two helices
	var helix = index % 2
	var offset_angle = angle + (PI if helix == 1 else 0)
	
	var pos = Vector3(
		cos(offset_angle) * dna_radius,
		height,
		sin(offset_angle) * dna_radius
	)
	
	var basis = Basis(Vector3.UP, offset_angle)
	return Transform3D(basis, pos)

func _create_step(index: int, xform: Transform3D) -> Node3D:
	var step: Node3D
	
	if step_primitive:
		step = step_primitive.instantiate()
	else:
		step = MeshInstance3D.new()
		(step as MeshInstance3D).mesh = _default_mesh
	
	step.name = "Step_%03d" % index
	step.transform = xform
	
	# Apply scale
	if step is MeshInstance3D:
		step.scale = base_scale
	
	# Apply color
	var color = _get_step_color(index)
	_apply_color(step, color)
	
	step_changed.emit(index, xform)
	
	return step

func _get_step_color(index: int) -> Color:
	var t = float(index) / max(step_count - 1, 1)
	
	if color_gradient:
		return color_gradient.sample(t)
	elif use_rainbow:
		return Color.from_hsv(t, 0.8, 1.0)
	else:
		return Color.WHITE

func _apply_color(node: Node3D, color: Color) -> void:
	var mesh_instance = node as MeshInstance3D
	if not mesh_instance:
		mesh_instance = node.get_node_or_null("MeshInstance3D") as MeshInstance3D
	
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		if emit_light:
			mat.emission_enabled = true
			mat.emission = color
			mat.emission_energy_multiplier = 0.5
		mat.metallic = 0.3
		mat.roughness = 0.4
		mesh_instance.material_override = mat

# Public API

func get_step_transform(index: int) -> Transform3D:
	if index >= 0 and index < _steps.size():
		return _steps[index].transform
	return Transform3D.IDENTITY

func get_all_positions() -> Array[Vector3]:
	var positions: Array[Vector3] = []
	for step in _steps:
		positions.append(step.global_position)
	return positions

func animate_build(duration: float = 2.0) -> void:
	"""Animate steps appearing one by one"""
	for i in range(_steps.size()):
		_steps[i].visible = false
	
	var delay_per_step = duration / _steps.size()
	for i in range(_steps.size()):
		get_tree().create_timer(i * delay_per_step).timeout.connect(
			func(): _steps[i].visible = true
		)

func set_step_count_animated(new_count: int, duration: float = 1.0) -> void:
	"""Smoothly transition to new step count"""
	var tween = create_tween()
	tween.tween_method(
		func(v): step_count = int(v),
		step_count,
		new_count,
		duration
	)
