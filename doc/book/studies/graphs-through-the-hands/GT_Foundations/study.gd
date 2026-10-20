extends Node3D
const Traversal = preload("traversal.gd")
const PointBody = preload("point_body.gd")
const PARK := Vector3(0, 0.85, 0.65)
const TIDE := Color("54bce8")
const DIVER := Color("efa252")
const NEUTRAL := Color("6c7280")
var graph = Traversal.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var places: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var current := -1
var finished := false

func _ready() -> void:
	for vertex in range(places.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.position = places[vertex]
		lamp.material_override = finish(NEUTRAL)
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
				draw_edge(places[a], places[b])
	point.position = PARK
	add_child(point)
	point.action_pressed.connect(func(_source): advance())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 32
	caption.pixel_size = 0.002
	add_child(caption)
	restart(true)

func _process(_delta: float) -> void:
	if not point.held():
		point.position = PARK

func restart(use_queue: bool) -> void:
	graph.restart(use_queue)
	current = -1
	finished = false
	refresh()

func advance() -> void:
	if finished:
		restart(not graph.breadth)
		return
	current = graph.next_visit()
	finished = current == -1 or graph.visited.size() == places.size()
	refresh()

func refresh() -> void:
	var tint := TIDE if graph.breadth else DIVER
	for vertex in range(lamps.size()):
		var material: StandardMaterial3D = lamps[vertex].material_override
		material.albedo_color = tint if vertex in graph.visited else NEUTRAL
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.8 if vertex == current else 0.15
	var method := "QUEUE / take left" if graph.breadth else "STACK / take right"
	caption.text = method + "\nVisited: " + str(graph.visited)
	caption.text += "\nPending: " + str(graph.pending)
	caption.text += "\nTrigger / 1: " + ("other order" if finished else "one visit")
	caption.text += "    2: switch    R: restart"

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.15
	material.roughness = 0.6
	return material

func draw_edge(a: Vector3, b: Vector3) -> void:
	var rod := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = a.distance_to(b)
	rod.mesh = cylinder
	rod.position = (a + b) * 0.5
	rod.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	rod.material_override = finish(NEUTRAL)
	add_child(rod)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			advance()
		elif event.keycode == KEY_2:
			restart(not graph.breadth)
		elif event.keycode == KEY_R:
			restart(graph.breadth)
