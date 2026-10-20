extends Node3D
const Swarm = preload("swarm.gd")
const PointBody = preload("point_body.gd")
const PERIOD := 0.1
const BLUE := Color("49c9ef")
const GOLD := Color("ffd16d")
var model = Swarm.new()
var points: Array[Node3D] = []
var captions: Array[Label3D] = []
var field: MultiMeshInstance3D
var personal: MeshInstance3D
var shared: MeshInstance3D
var selection: MeshInstance3D
var connections: Array[MeshInstance3D] = []
var memory_labels: Array[Label3D] = []
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3(p.x,0.8,-p.y)

func record(p: Vector3) -> Vector2:
	return Vector2(clampf(p.x,-6,6),clampf(-p.z,-6,6))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.4
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.03
	mesh.outer_radius = radius+0.03
	mesh.rings = 48
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func connector(colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.018
	mesh.height = 1.0
	mesh.radial_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func connect_positions(body: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var d := b-a
	body.visible = d.length() > 0.001
	if not body.visible: return
	body.transform = Transform3D(Basis(Quaternion(Vector3.UP,d.normalized()))*Basis.from_scale(Vector3(1,d.length(),1)),(a+b)*0.5)

func _ready() -> void:
	tile(Vector3(12.1,0.02,12.1),Color("111822")).position.y = 0.015
	field = MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var cell := BoxMesh.new()
	cell.size = Vector3(0.72,0.012,0.72)
	batch.mesh = cell
	batch.instance_count = 256
	field.multimesh = batch
	var material := finish(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	field.material_override = material
	add_child(field)
	for y in range(16):
		for x in range(16):
			batch.set_instance_transform(x+y*16,Transform3D(Basis.IDENTITY,Vector3((x+0.5)*0.75-6,0.035,-((y+0.5)*0.75-6))))
	for i in range(model.positions.size()):
		var point = PointBody.new()
		point.tint = Color("eae7e0") if i%2 == 0 else Color("25212a")
		point.get_child(0).scale = Vector3.ONE*3.0
		point.get_child(1).shape.radius *= 3.0
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
	selection = ring(0.32,Color.WHITE)
	personal = ring(0.4,BLUE)
	shared = ring(0.6,GOLD)
	connections = [connector(BLUE),connector(GOLD)]
	memory_labels = [label("MY BEST",Vector3.ZERO,18),label("GROUP BEST",Vector3.ZERO,18)]
	for side in [-1,1]:
		var z: float = side*6.7
		var bank_x: float = -side*3.2
		label("BETTER ACCORDING TO WHICH SCORE?",Vector3(0,3.3,z),40)
		captions.append(label("",Vector3(bank_x,1.95,z),19))
		label("Hold: pause + move   /   held trigger: select",Vector3(bank_x,1.4,z),16)
		tile(Vector3(4.45,0.08,0.5),Color("303747")).position = Vector3(bank_x,0.88,z)
		var actions := [toggle_play,single_step,restart,func(): change(0),func(): change(1),func(): change(2)]
		for i in range(6):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Reset","Center","Edge","Ridge"][i]+str(side)
			button.position = Vector3(bank_x+(i-2.5)*0.82,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE STEP","RESTART","CENTER","EDGE","RIDGE"][i],button.position+Vector3.UP*0.24,19)
			words.pixel_size = 0.0025
	colour_field()
	paint()

func choose(i: int) -> void:
	if points[i].held(): witness = i
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing
	paint()

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.step()
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
	paint()

func change(next: int) -> void:
	if any_held(): return
	model.change_objective(next)
	playing = false
	elapsed = 0.0
	colour_field()
	paint()

func _process(delta: float) -> void:
	for i in range(points.size()):
		if points[i].held():
			model.positions[i] = record(to_local(points[i].global_position))
			model.velocities[i] = Vector2.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= PERIOD:
			model.step()
			elapsed = maxf(0.0,elapsed-PERIOD)
	paint()

func colour_field() -> void:
	for i in range(256):
		var at := field.multimesh.get_instance_transform(i).origin
		var value: float = model.score(record(at))/72.0
		if model.objective != Swarm.Objective.EDGE: value += 1.0
		field.multimesh.set_instance_color(i,Color("142430").lerp(Color("bb9964"),clampf(value,0,1)))

func paint() -> void:
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
	selection.position = to_local(points[witness].global_position)-Vector3.UP*0.24
	personal.position = place(model.best_positions[witness]); personal.position.y = 0.11
	shared.position = place(model.shared_position); shared.position.y = 0.16
	var start := place(model.positions[witness]); start.y = 0.09
	connect_positions(connections[0],start,personal.position)
	connect_positions(connections[1],start,shared.position)
	memory_labels[0].position = personal.position+Vector3.UP*0.4
	memory_labels[1].position = shared.position+Vector3.UP*0.65
	var formula: String = ["CENTER: -(x*x+y*y)","EDGE: x*x+y*y","RIDGE: -(x-y)^2 / 2"][model.objective]
	for text in captions:
		text.text = "%s / larger wins\nPoint %d: now %.2f / remembered %.2f\nGroup %.2f / step %d / %s" % [formula,witness,model.score(model.positions[witness]),model.best_scores[witness],model.shared_score,model.steps,"HELD" if any_held() else ("RUN" if playing else "PAUSE")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_R: restart()
		elif event.keycode == KEY_3: change(0)
		elif event.keycode == KEY_4: change(1)
		elif event.keycode == KEY_5: change(2)
