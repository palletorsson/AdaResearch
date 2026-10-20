extends Node3D
## Shadow Game's actual pickable point. Its strokes join the museum archive.
const PointBody = preload("res://commons/shadow_game/point.gd")
const LineSkin = preload("res://commons/museum_runner/forms/line_skin.gd")
const RADIUS := 0.07 # Half the original 14 cm radius; resize geometry and collider.
const SPACING := 0.12 # Same sampling distance as Shadow Game.
const MAX_SEGMENTS := 2048
var point: XRToolsPickable
var ink: Node3D
var stroke: Array[Vector3] = []
var recording := false

func _ready() -> void:
	ink = Node3D.new()
	ink.name = "KeptTrace"
	add_child(ink)
	point = PointBody.new()
	point.name = "BlackPoint"
	for child in point.get_children():
		if child is MeshInstance3D:
			child.mesh.radius = RADIUS
			child.mesh.height = RADIUS * 2
		elif child is CollisionShape3D:
			child.shape.radius = RADIUS
	add_child(point)
	point.picked_up.connect(_taken)
	point.dropped.connect(_released)

func _taken(_body: Node3D) -> void:
	stroke.clear()
	recording = true
	_sample()

func _physics_process(_delta: float) -> void:
	if recording and point.is_held(): _sample()

func _sample() -> void:
	if ink.get_child_count() >= MAX_SEGMENTS: return # Preserve existing marks.
	var at := point.global_position
	if not stroke.is_empty():
		var previous := stroke[-1]
		if previous.distance_to(at) < SPACING: return
		var a := to_local(previous)
		var b := to_local(at)
		var line := LineSkin.new()
		line.show_segment(a, b-a, a.distance_to(b))
		ink.add_child(line)
	stroke.append(at)

func _released(_body: Node3D) -> void:
	if not recording: return
	_sample()
	recording = false
	var archive := get_node_or_null("/root/TraceData")
	if archive != null and stroke.size() > 1: archive.add_trace(stroke)

func reset_after_fall() -> void:
	if point.is_held() or point.global_position.y >= global_position.y-1: return
	point.transform = Transform3D.IDENTITY
	point.linear_velocity = Vector3.ZERO
	point.angular_velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(point.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, point.global_transform)
