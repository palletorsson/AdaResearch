extends Node3D

@export var segment_scene: PackedScene = preload("res://algorithms/wavefunctions/rainbow_hallway/tube_segement.tscn")
@export var major_radius: float = 4.0
@export var tube_radius: float = 1.2
@export var height: float = 12.0
@export var turns: float = 2.5
@export_range(8, 200, 1) var segments: int = 60
@export var cleanup_previous: bool = true
@export var segment_alignment_degrees: Vector3 = Vector3(-90.0, 0.0, 0.0):
	set(value):
		segment_alignment_degrees = value
		_update_alignment_basis()

var _segment_cache: Array[Node3D] = []
var _alignment_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	_update_alignment_basis()
	_generate_segments()

func _update_alignment_basis() -> void:
	var radians := segment_alignment_degrees * (PI / 180.0)
	var basis := Basis.IDENTITY
	basis = basis.rotated(Vector3.RIGHT, radians.x)
	basis = basis.rotated(Vector3.UP, radians.y)
	basis = basis.rotated(Vector3.FORWARD, radians.z)
	_alignment_basis = basis
	
func _generate_segments() -> void:
	if cleanup_previous:
		for child in _segment_cache:
			if child and is_instance_valid(child):
				child.queue_free()
	_segment_cache.clear()

	if not segment_scene:
		push_warning("Segment scene not set")
		return

	var previous_frame: Dictionary = {}
	for i in range(segments):
		var t := float(i) / float(max(1, segments - 1))
		var frame := _compute_frame(t)
		if frame.is_empty():
			continue
		var instance := segment_scene.instantiate() as Node3D
		if not instance:
			continue

		var basis := _build_basis(frame, previous_frame)
		instance.transform = Transform3D(basis * _alignment_basis, frame["point"])
		add_child(instance)
		_segment_cache.append(instance)
		previous_frame = frame

func _compute_frame(t: float) -> Dictionary:
	var u := t * turns * TAU
	var center := Vector3(
		major_radius * cos(u),
		height * (1.0 - t),
		major_radius * sin(u)
	)
	var tangent := Vector3(
		-major_radius * sin(u),
		-height * turns * TAU,
		major_radius * cos(u)
	).normalized()
	var normal := Vector3(cos(u), 0.0, sin(u)).normalized()
	var binormal := tangent.cross(normal).normalized()
	return {
		"point": center,
		"tangent": tangent,
		"normal": normal,
		"binormal": binormal
	}

func _build_basis(frame: Dictionary, previous_frame: Dictionary) -> Basis:
	var tangent: Vector3 = frame["tangent"]
	var normal: Vector3 = frame["normal"]
	var binormal: Vector3 = frame["binormal"]
	if not previous_frame.is_empty():
		var prev_binormal: Vector3 = previous_frame["binormal"]
		if prev_binormal.dot(binormal) < 0:
			binormal = -binormal
			normal = binormal.cross(tangent).normalized()
	var right := normal.cross(tangent).normalized()
	normal = tangent.cross(right).normalized()
	return Basis(right, normal, tangent)
