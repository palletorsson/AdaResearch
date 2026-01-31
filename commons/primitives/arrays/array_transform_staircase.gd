@tool
extends Node3D
class_name ArrayTransformStaircase

## Array + Transform (Translate, Rotate, Scale)
## Three modes showing the three fundamental transformations
## Each cumulative. Each strict.

enum TransformMode {
	TRANSLATE,  # position[i] = i × offset
	ROTATE,     # rotation[i] = i × angle  
	SCALE,      # scale[i] = base × factor^i
}

@export var mode: TransformMode = TransformMode.TRANSLATE:
	set(v):
		mode = v
		_rebuild()

@export_range(2, 24) var count: int = 8:
	set(v):
		count = v
		_rebuild()

@export var element_size: Vector3 = Vector3(0.5, 0.1, 0.3):
	set(v):
		element_size = v
		_rebuild()

@export_group("Translate")
@export var translate_offset: Vector3 = Vector3(0.4, 0.15, 0.0):
	set(v):
		translate_offset = v
		if mode == TransformMode.TRANSLATE:
			_rebuild()

@export_group("Rotate")
@export var rotate_axis: Vector3 = Vector3(0, 1, 0):
	set(v):
		rotate_axis = v.normalized()
		if mode == TransformMode.ROTATE:
			_rebuild()

@export var rotate_angle_degrees: float = 30.0:
	set(v):
		rotate_angle_degrees = v
		if mode == TransformMode.ROTATE:
			_rebuild()

@export var rotate_radius: float = 0.8:
	set(v):
		rotate_radius = v
		if mode == TransformMode.ROTATE:
			_rebuild()

@export_group("Scale")
@export var scale_factor: float = 0.85:
	set(v):
		scale_factor = v
		if mode == TransformMode.SCALE:
			_rebuild()

@export var scale_center_offset: float = 0.0:
	set(v):
		scale_center_offset = v
		if mode == TransformMode.SCALE:
			_rebuild()

@export_group("Visual")
@export var element_color: Color = Color(0.7, 0.7, 0.75, 1.0):
	set(v):
		element_color = v
		_update_material()

var _elements: Array[MeshInstance3D] = []
var _material: StandardMaterial3D

func _ready() -> void:
	_create_material()
	_rebuild()

func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = element_color

func _update_material() -> void:
	if _material:
		_material.albedo_color = element_color

func _rebuild() -> void:
	# Clear
	for el in _elements:
		if is_instance_valid(el):
			el.queue_free()
	_elements.clear()
	
	# Build
	var box = BoxMesh.new()
	box.size = element_size
	
	for i in range(count):
		var el = MeshInstance3D.new()
		el.name = "Element_%d" % i
		el.mesh = box
		el.material_override = _material
		
		match mode:
			TransformMode.TRANSLATE:
				_apply_translate(el, i)
			TransformMode.ROTATE:
				_apply_rotate(el, i)
			TransformMode.SCALE:
				_apply_scale(el, i)
		
		add_child(el)
		_elements.append(el)

func _apply_translate(el: MeshInstance3D, i: int) -> void:
	# position[i] = i × offset
	el.position = i * translate_offset

func _apply_rotate(el: MeshInstance3D, i: int) -> void:
	# rotation[i] = i × angle, placed on circle
	var angle = deg_to_rad(i * rotate_angle_degrees)
	el.position = Vector3(
		cos(angle) * rotate_radius,
		0,
		sin(angle) * rotate_radius
	)
	el.rotation = Vector3(0, -angle, 0)

func _apply_scale(el: MeshInstance3D, i: int) -> void:
	# scale[i] = factor^i (telescoping/nested)
	var s = pow(scale_factor, i)
	el.scale = Vector3(s, s, s)
	el.position = Vector3(0, i * scale_center_offset, 0)

## Get the formula for current mode
func get_formula() -> String:
	match mode:
		TransformMode.TRANSLATE:
			return "position[i] = i × (%.2f, %.2f, %.2f)" % [translate_offset.x, translate_offset.y, translate_offset.z]
		TransformMode.ROTATE:
			return "rotation[i] = i × %.1f°" % rotate_angle_degrees
		TransformMode.SCALE:
			return "scale[i] = %.2f ^ i" % scale_factor
	return ""
