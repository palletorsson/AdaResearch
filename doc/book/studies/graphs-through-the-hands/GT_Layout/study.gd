extends Node3D
const Traversal = preload("traversal.gd")
const Layout = preload("layout.gd")
const PointBody = preload("point_body.gd")
var graph = Traversal.new()
var drawing = Layout.new()
var point = PointBody.new()
var caption := Label3D.new()
var lamps: Array[MeshInstance3D] = []
var numbers: Array[Label3D] = []
var rods: Array[MeshInstance3D] = []
var ends: Array = []
var running := true

func _ready() -> void:
	for vertex in range(drawing.positions.size()):
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		lamp.mesh = sphere
		lamp.material_override = finish(Color("54bce8"))
		lamp.visible = vertex != 0 # The carried point itself shows vertex zero.
		add_child(lamp)
		lamps.append(lamp)
		var number := Label3D.new()
		number.text = str(vertex)
		number.font_size = 40
		number.pixel_size = 0.002
		add_child(number)
		numbers.append(number)
	for a in range(graph.neighbours.size()):
		for b: int in graph.neighbours[a]:
			if a < b:
				var rod := MeshInstance3D.new()
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.008
				cylinder.bottom_radius = 0.008
				rod.mesh = cylinder
				rod.material_override = finish(Color("6c7280"))
				add_child(rod)
				rods.append(rod)
				ends.append([a, b])
	add_child(point)
	point.action_pressed.connect(func(_source): toggle())
	caption.position = Vector3(0, 3.25, 0)
	caption.font_size = 30
	caption.pixel_size = 0.002
	add_child(caption)
	refresh_caption()
	redraw()

func _physics_process(delta: float) -> void:
	var pinned := -1
	if point.held():
		# Hand is in world space. This drawing uses the host's local XY plane.
		var hand := to_local(point.global_position)
		drawing.positions[0] = Vector3(hand.x, hand.y, 0)
		drawing.velocities[0] = Vector3.ZERO
		pinned = 0
	if running:
		drawing.step(delta, graph.neighbours, pinned)
	redraw()

func redraw() -> void:
	lamps[0].visible = point.held() # Show the planar projection while the hand is off-plane.
	for vertex in range(lamps.size()):
		lamps[vertex].position = drawing.positions[vertex]
		numbers[vertex].position = drawing.positions[vertex] + Vector3(0, 0.14, 0.08)
	if not point.held():
		point.position = drawing.positions[0]
	for index in range(rods.size()):
		var a: Vector3 = drawing.positions[ends[index][0]]
		var b: Vector3 = drawing.positions[ends[index][1]]
		var offset := b - a
		rods[index].visible = offset.length() > 0.001
		rods[index].mesh.height = maxf(offset.length(), 0.001)
		rods[index].position = (a + b) * 0.5
		if rods[index].visible:
			rods[index].quaternion = Quaternion(Vector3.UP, offset.normalized())

func visit_order(breadth: bool) -> Array[int]:
	graph.restart(breadth)
	while graph.next_visit() != -1:
		pass
	return graph.visited.duplicate()

func refresh_caption() -> void:
	caption.text = "MOVING DRAWING" if running else "PAUSED DRAWING"
	caption.text += "\nQueue: " + str(visit_order(true))
	caption.text += "\nStack: " + str(visit_order(false))
	caption.text += "\nHold black point: move vertex 0 in this plane"
	caption.text += "\nTrigger / 1: pause or resume    R: reset drawing"

func toggle() -> void:
	running = not running
	refresh_caption()

func restart() -> void:
	drawing = Layout.new()
	running = true
	refresh_caption()
	redraw()

func finish(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.6
	return material

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			toggle()
		elif event.keycode == KEY_R:
			restart()
