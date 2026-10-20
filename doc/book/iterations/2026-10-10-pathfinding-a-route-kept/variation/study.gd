extends Node3D
const Route = preload("route.gd")
const PointBody = preload("point_body.gd")
const START := 3
const GOAL := 6
const NEUTRAL := Color("6c7280")
const OPEN := Color("54bce8")
const PATH := Color("f4c878")
const CLOSED := Color("d66079")
const FRONT := Vector3(0, 0, 0.14)
const PARK := Vector3(0, 0.8, 0.5)
var graph = Route.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var rods: Array[MeshInstance3D] = []
var ends: Array = []
var places: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var blocked: Array[int] = []
var path: Array[int] = []
var phase := 0
var leg := 0
var cursor := Vector3.ZERO

func _ready() -> void:
	for vertex in range(places.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.position = places[vertex]
		lamp.material_override = finish(OPEN)
		add_child(lamp)
		lamps.append(lamp)
		var number := Label3D.new()
		number.text = str(vertex)
		number.position = places[vertex] + Vector3(0, 0.14, 0.08)
		number.font_size = 40
		number.pixel_size = 0.002
		add_child(number)
	for a in range(graph.neighbours.size()):
		for b: int in graph.neighbours[a]:
			if a < b:
				var rod := MeshInstance3D.new()
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.008
				cylinder.bottom_radius = 0.008
				cylinder.height = places[a].distance_to(places[b])
				rod.mesh = cylinder
				rod.position = (places[a] + places[b]) * 0.5
				rod.quaternion = Quaternion(Vector3.UP, (places[b] - places[a]).normalized())
				rod.material_override = finish(NEUTRAL)
				add_child(rod)
				rods.append(rod)
				ends.append([a, b])
	add_child(point)
	point.action_pressed.connect(func(_source): change_availability())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	replan()

func change_availability() -> void:
	phase = (phase + 1) % 3
	blocked.clear()
	if phase >= 1:
		blocked.append(0)
	if phase == 2:
		blocked.append(4)
	replan()

func replan() -> void:
	path = graph.find_path(START, GOAL, blocked)
	leg = 0
	cursor = PARK if path.is_empty() else places[path[0]] + FRONT
	if not point.held():
		point.position = cursor
	for vertex in range(lamps.size()):
		lamps[vertex].material_override.albedo_color = CLOSED if vertex in blocked else OPEN
	for i in range(rods.size()):
		var a: int = ends[i][0]
		var b: int = ends[i][1]
		rods[i].visible = a not in blocked and b not in blocked
		var on_path := false
		for step in range(path.size() - 1):
			on_path = on_path or (a == path[step] and b == path[step + 1]) or (b == path[step] and a == path[step + 1])
		rods[i].material_override.albedo_color = PATH if on_path else NEUTRAL
	caption.text = "FROM %d TO %d / blocked: %s" % [START, GOAL, str(blocked)]
	caption.text += "\nRoute: " + ("NO ROUTE" if path.is_empty() else str(path))
	caption.text += "\nSearch visited: " + str(graph.visited)
	caption.text += "\nTrigger / 1: block 0, then 4, then restore"
	caption.text += "\nHold: pause traveller    R: replay this route"

func _process(delta: float) -> void:
	if point.held():
		return
	if leg < path.size() - 1:
		var target := places[path[leg + 1]] + FRONT
		cursor = cursor.move_toward(target, 0.55 * delta)
		if cursor.is_equal_approx(target):
			leg += 1
	point.position = cursor

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.6
	return material

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			change_availability()
		elif event.keycode == KEY_R:
			replan()
