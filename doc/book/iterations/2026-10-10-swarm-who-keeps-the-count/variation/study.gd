extends Node3D
const Account = preload("account.gd")
const Observed = preload("observed.gd")
const PointBody = preload("point_body.gd")
const PERIOD := 1.0/60.0
const PREY := Color("71d9e9")
const PREDATOR := Color("ec7697")
const SUPPLY := Color("ffcd68")
var account = Account.new()
var model = Observed.new()
var points: Dictionary = {}
var captions: Array[Label3D] = []
var notes: Array[Label3D] = []
var selection: MeshInstance3D
var food: MultiMeshInstance3D
var witness := 0
var playing := false
var elapsed := 0.0
var show_supply := true

func place(p: Vector3) -> Vector3:
	return Vector3(p.x*15.0,0.8+p.y*3.0,p.z*15.0)

func record(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x/15.0,-0.4,0.4),clampf((p.y-0.8)/3.0,0,0.4),clampf(p.z/15.0,-0.4,0.4))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.35
	return material

func tile(size: Vector3, colour: Color, at: Vector3) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.material_override = finish(colour)
	surface.position = at
	add_child(surface)

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.025
	mesh.outer_radius = radius+0.025
	mesh.rings = 32
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	return body

func _ready() -> void:
	add_child(model)
	account.begin(model.prey_list.size(),model.predator_list.size())
	model.event_record.connect(account.record)
	tile(Vector3(12.5,0.02,12.5),Color("152d36"),Vector3(0,0.015,0))
	for side in [-1,1]:
		tile(Vector3(12.5,0.015,0.06),SUPPLY,Vector3(0,0.035,side*6.25))
		tile(Vector3(0.06,0.015,12.5),SUPPLY,Vector3(side*6.25,0.035,0))
	food = MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	var pellet := SphereMesh.new()
	pellet.radius = 0.07
	pellet.height = 0.14
	pellet.radial_segments = 8
	pellet.rings = 4
	batch.mesh = pellet
	food.multimesh = batch
	food.material_override = finish(Color("9ff082"))
	add_child(food)
	selection = ring(0.36,Color.WHITE)
	add_child(selection)
	for side in [-1,1]:
		var z: float = side*6.9
		var x: float = -side*3.1
		label("WHO KEEPS THEM HERE?",Vector3(0,3.8,z),42)
		captions.append(label("",Vector3(0,2.8,z),26))
		notes.append(label("",Vector3(x,1.8,z),17))
		tile(Vector3(3.65,0.08,0.5),Color("35444a"),Vector3(x,0.88,z))
		var actions := [toggle_play,single_step,restart,toggle_supply]
		for i in range(4):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Restart","Record"][i]+str(side)
			button.position = Vector3(x+(i-1.5)*1.05,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE STEP","RESTART","SUPPLY ROW"][i],button.position+Vector3.UP*0.23,19)
			words.pixel_size = 0.0025
		label("BLUE prey / PINK predators / GREEN food\nGOLD ring = supplied body\nHold a sphere: pause + move / trigger: inspect",Vector3(-x,1.3,z),21)
	paint()

func bodies() -> Array:
	return model.prey_list+model.predator_list

func any_held() -> bool:
	for point in points.values():
		if point.held(): return true
	return false

func toggle_play() -> void:
	playing = not playing

func single_step() -> void:
	playing = false
	elapsed = 0.0
	if not any_held(): model.advance(PERIOD)
	paint()

func restart() -> void:
	if any_held(): return
	playing = false
	elapsed = 0.0
	model.restart()
	account.begin(model.prey_list.size(),model.predator_list.size())
	show_supply = true
	paint()

func toggle_supply() -> void:
	show_supply = not show_supply
	paint()

func choose(id: int) -> void:
	if points.has(id) and points[id].held(): witness = id

func _process(delta: float) -> void:
	for body in bodies():
		var id: int = body.get_instance_id()
		if points.has(id) and points[id].held():
			body.position = record(to_local(points[id].global_position))
			body.velocity = Vector3.ZERO
	if any_held():
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.1)
		while elapsed+0.000001 >= PERIOD:
			model.advance(PERIOD)
			elapsed = maxf(0,elapsed-PERIOD)
	paint()

func paint() -> void:
	var live := bodies()
	var ids: Array[int] = []
	for body in live:
		var id: int = body.get_instance_id()
		ids.append(id)
		if not points.has(id):
			var point = PointBody.new()
			point.tint = PREY if model.prey_list.has(body) else PREDATOR
			point.get_child(0).scale = Vector3.ONE*3
			point.get_child(1).shape.radius *= 3
			add_child(point)
			point.action_pressed.connect(func(_source): choose(id))
			if body.get_meta("arrival") == "supplied":
				var mark := ring(0.3,SUPPLY)
				point.add_child(mark)
			points[id] = point
		if not points[id].held(): points[id].position = place(body.position)
	for id in points.keys():
		if not ids.has(id):
			points[id].queue_free()
			points.erase(id)
	if not points.has(witness): witness = ids[0] if not ids.is_empty() else 0
	selection.visible = points.has(witness)
	if selection.visible: selection.position = to_local(points[witness].global_position)-Vector3.UP*0.25
	if food.multimesh.instance_count != model.food_list.size():
		food.multimesh.instance_count = model.food_list.size()
	for i in range(model.food_list.size()):
		food.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,place(model.food_list[i].position)))
	var lines := ""
	for species in ["prey","predator"]:
		var actual: int = model.prey_list.size() if species == "prey" else model.predator_list.size()
		lines += "%s: %d + %d born - %d lost + %s supplied = %d / actual %d / gap %d\n" % [species.to_upper(),account.initial[species],account.total(species,"birth"),account.total(species,"loss"),str(account.total(species,"supplied")) if show_supply else "?",account.expected(species,show_supply),actual,account.difference(species,actual,show_supply)]
	for text in captions:
		text.text = lines+("FULL RECORD" if show_supply else "FILTERED: SUPPLIED BODIES OMITTED")
	var arrival := "none"
	var health := 0.0
	for body in live:
		if body.get_instance_id() == witness:
			arrival = body.get_meta("arrival")
			health = body.health
	for text in notes:
		text.text = "%s / step %d\nSelected: %s / health %.2f\nOutside food %d / pressure steps %d" % ["HELD" if any_held() else ("RUN" if playing else "PAUSE"),model.tick,arrival,health,account.total("support","food"),account.total("support","pressure")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_R: restart()
		elif event.keycode == KEY_3: toggle_supply()
