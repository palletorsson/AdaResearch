extends Node3D

# 0 clockwise   1 clockwise with flipped normals   2 counter-clockwise   3 counter-clockwise double-sided
@export_enum("clockwise", "clockwise flipped normals", "counter-clockwise", "counter-clockwise double-sided") var side := 0

var trace: Array[Vector3] = []
var gate := 0.1
var capacity := 128
var recording := true
var closed := false

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % distance

	if Input.is_action_just_pressed("pause"):
		recording = not recording
	if Input.is_action_just_pressed("close") and trace.size() >= 3:
		closed = true
		recording = false
	if Input.is_action_just_pressed("fill") and closed:
		build_face()
	if Input.is_action_just_pressed("drop"):
		$Marble.drop(b + Vector3.UP)
	if Input.is_action_pressed("look"):
		$Under.current = true
	else:
		$Camera3D.current = true
	if recording and not closed:
		keep(b)
	$Strip.draw(outline())
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m\n%s\nmarble at %.2f m" % [trace.size(), route_length(), straight_length(), status(), $Marble.position.y]

func keep(p: Vector3) -> void:
	if trace.is_empty() or (p - trace[-1]).length() >= gate:
		trace.append(p)
		if trace.size() > capacity:
			trace.pop_front()

func route_length() -> float:
	var total := 0.0
	for i in range(1, trace.size()):
		total += (trace[i] - trace[i - 1]).length()
	return total

func straight_length() -> float:
	if trace.is_empty():
		return 0.0
	return (trace[-1] - trace[0]).length()

func outline() -> Array[Vector3]:
	var loop: Array[Vector3] = trace.duplicate()
	if closed:
		loop.append(trace[0])
	return loop

func build_face() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, trace.size() - 1):
		surface.add_vertex(trace[0])
		if side < 2:
			surface.add_vertex(trace[i])
			surface.add_vertex(trace[i + 1])
		else:
			surface.add_vertex(trace[i + 1])
			surface.add_vertex(trace[i])
	if side == 1:
		surface.generate_normals(true)
	else:
		surface.generate_normals()
	$Face.mesh = surface.commit()
	if side == 3:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_BACK
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape

func status() -> String:
	if not closed:
		return "open"
	var around := route_length() + straight_length()
	if $Face.mesh == null:
		return "closed, %.2f m around" % around
	return "closed, %.2f m around, %d triangles" % [around, trace.size() - 2]
