@tool
extends "res://commons/primitives/cubes/grab_cube_scalable.gd"

## Attachable Grab Cube
##
## Extends scalable grab cube with attachment points on all faces.
## Used for furniture assembly puzzles where pieces need to snap together.

const AttachmentPointScene = preload("res://commons/primitives/furniture/attachment_point.tscn")

## Which faces have attachment points
@export_flags("Top", "Bottom", "Left", "Right", "Front", "Back") var attachment_faces: int = 63  # All faces by default

## Signal when any attachment point connects
signal attachment_connected(face: int, other_point: Node)

## Signal when any attachment point disconnects
signal attachment_disconnected(face: int, other_point: Node)

# Attachment points by face (0=+X, 1=-X, 2=+Y, 3=-Y, 4=+Z, 5=-Z)
var _attachment_points: Array[Node] = []

# Face direction mapping (matches AttachmentPoint.FaceDirection enum)
const FACE_FLAGS = {
	0: 4,   # +X = Right = bit 3
	1: 8,   # -X = Left = bit 2
	2: 1,   # +Y = Top = bit 0
	3: 2,   # -Y = Bottom = bit 1
	4: 16,  # +Z = Front = bit 4
	5: 32   # -Z = Back = bit 5
}


func _ready() -> void:
	super()

	if not Engine.is_editor_hint():
		_create_attachment_points()

	# Connect to scale changes to update attachment positions
	if not Engine.is_editor_hint():
		scale_changed.connect(_on_scale_changed)
		axis_scale_changed.connect(_on_axis_scale_changed)


func _create_attachment_points() -> void:
	print("GrabCubeAttachable: Creating attachment points, flags=%d" % attachment_faces)

	# Clear existing
	for point in _attachment_points:
		if is_instance_valid(point):
			point.queue_free()
	_attachment_points.clear()

	# Create for each enabled face
	for face_dir in range(6):
		var flag = FACE_FLAGS[face_dir]
		if attachment_faces & flag:
			var point = AttachmentPointScene.instantiate()
			point.face = face_dir
			point.name = "AttachmentPoint_" + _get_face_name(face_dir)
			add_child(point)
			_attachment_points.append(point)

			# Connect signals
			point.connected.connect(_on_attachment_connected.bind(face_dir))
			point.disconnected.connect(_on_attachment_disconnected.bind(face_dir))

			# Position for current size
			_update_attachment_position(point)
			print("GrabCubeAttachable: Created attachment point for face %s" % _get_face_name(face_dir))
		else:
			_attachment_points.append(null)

	print("GrabCubeAttachable: Created %d attachment points" % _attachment_points.filter(func(p): return p != null).size())


func _get_face_name(face_dir: int) -> String:
	match face_dir:
		0: return "PosX"
		1: return "NegX"
		2: return "PosY"
		3: return "NegY"
		4: return "PosZ"
		5: return "NegZ"
	return "Unknown"


func _update_attachment_position(point: Node) -> void:
	if point == null or not point.has_method("update_for_cube_size"):
		return

	# Get current cube size from scale indices
	var scale_x = scale_snap_values[_scale_index_x] if _scale_index_x < scale_snap_values.size() else 1.0
	var scale_y = scale_snap_values[_scale_index_y] if _scale_index_y < scale_snap_values.size() else 1.0
	var scale_z = scale_snap_values[_scale_index_z] if _scale_index_z < scale_snap_values.size() else 1.0

	var cube_size = Vector3(scale_x, scale_y, scale_z) * _mesh_base_scale
	point.update_for_cube_size(cube_size)


func _update_all_attachment_positions() -> void:
	for point in _attachment_points:
		_update_attachment_position(point)


func _on_scale_changed(_new_scale: float, _scale_index: int) -> void:
	_update_all_attachment_positions()


func _on_axis_scale_changed(_axis: String, _new_scale: float, _scale_index: int) -> void:
	_update_all_attachment_positions()


func _on_attachment_connected(other_point: Node, face_dir: int) -> void:
	attachment_connected.emit(face_dir, other_point)


func _on_attachment_disconnected(other_point: Node, face_dir: int) -> void:
	attachment_disconnected.emit(face_dir, other_point)


## Get attachment point for a specific face
func get_attachment_point(face_dir: int) -> Node:
	if face_dir >= 0 and face_dir < _attachment_points.size():
		return _attachment_points[face_dir]
	return null


## Check if a specific face is connected
func is_face_connected(face_dir: int) -> bool:
	var point = get_attachment_point(face_dir)
	if point and point.has_method("is_attached"):
		return point.is_attached()
	return false


## Get all connected faces
func get_connected_faces() -> Array[int]:
	var result: Array[int] = []
	for i in range(_attachment_points.size()):
		if is_face_connected(i):
			result.append(i)
	return result


## Get all objects this cube is attached to
func get_attached_objects() -> Array[Node]:
	var result: Array[Node] = []
	for point in _attachment_points:
		if point and point.has_method("get_connected_point"):
			var connected = point.get_connected_point()
			if connected:
				var other_parent = connected.get_parent()
				if other_parent and other_parent not in result:
					result.append(other_parent)
	return result
