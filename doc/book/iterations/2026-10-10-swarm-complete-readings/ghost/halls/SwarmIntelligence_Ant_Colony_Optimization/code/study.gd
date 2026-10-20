extends Node3D
const Colony = preload("colony.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.75
const HEIGHT := 0.8
const BLUE := Color("49c9ef")
const ROSE := Color("ef789d")
var model = Colony.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var home_tiles: MultiMeshInstance3D
var food_tiles: MultiMeshInstance3D
var sensors: Array[MeshInstance3D] = []
var captions: Array[Label3D] = []
var selection: MeshInstance3D
var witness := 0
var playing := true
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

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
	mesh.inner_radius = radius-0.035
	mesh.outer_radius = radius+0.035
	mesh.rings = 48
	mesh.ring_segments = 8
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 32) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.004
	text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(text)
	return text

func field(offset: float) -> MultiMeshInstance3D:
	var body := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(CELL*0.43,0.012,CELL*0.9)
	batch.mesh = mesh
	batch.instance_count = Colony.WIDTH*Colony.WIDTH
	body.multimesh = batch
	var material := finish(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	body.material_override = material
	add_child(body)
	for y in range(Colony.WIDTH):
		for x in range(Colony.WIDTH):
			var at := place(Vector2(x+0.5,y+0.5))
			at.x += offset
			at.y = 0.035
			batch.set_instance_transform(x+y*Colony.WIDTH,Transform3D(Basis.IDENTITY,at))
	return body

func _ready() -> void:
	tile(Vector3(12.1,0.02,12.1),Color("111822")).position.y = 0.015
	home_tiles = field(-CELL*0.23)
	food_tiles = field(CELL*0.23)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		point.tint = Color("eae7e0") if i%2 == 0 else Color("25212a")
		# Enlarge the existing geometry and grab shape, not the rigid-body root.
		point.get_child(0).scale = Vector3.ONE*3.0
		point.get_child(1).shape.radius *= 3.0
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.15,Color("a0ef82")))
	for colour in [BLUE,Color.WHITE,ROSE]:
		sensors.append(tile(Vector3(0.12,0.04,0.12),colour))
	selection = ring(0.34,Color("ffd16d"))
	for target in [Colony.HOME,Colony.FOOD]:
		var is_home: bool = target == Colony.HOME
		var at := place(target)
		at.y = 0.10
		ring(Colony.CONTACT*CELL,BLUE if is_home else ROSE).position = at
		label("HOME / BLUE" if is_home else "FOOD / ROSE",at+Vector3.UP*2.0)
	for side in [-1,1]:
		var z: float = side*6.5
		var bank_x: float = -side*3.5
		label("TWO TRAILS UNDERFOOT",Vector3(0,3.3,z),52)
		captions.append(label("",Vector3(bank_x,1.95,z),22))
		label("Hold: pause + move   /   held trigger: select",Vector3(bank_x,1.45,z),16)
		tile(Vector3(3.65,0.08,0.5),Color("303747")).position = Vector3(bank_x,0.88,z)
		var actions := [toggle_play,single_step,replace,restart]
		for i in range(4):
			var button = preload("res://commons/interactables/push_button.tscn").instantiate()
			button.name = ["Run","Step","Replace","Reset"][i]+str(side)
			button.position = Vector3(bank_x+(i-1.5)*1.0,0.95,z)
			button.rotation.x = deg_to_rad(-25.0)
			if side < 0: button.rotation.y = PI
			add_child(button)
			button.pressed.connect(actions[i])
			var words := label(["RUN / PAUSE","ONE TICK","REPLACE POINTS","CLEAR ALL"][i],button.position+Vector3.UP*0.25,20)
			words.pixel_size = 0.0025
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

func replace() -> void:
	if any_held(): return
	model.replace_agents()
	playing = false
	elapsed = 0.0
	paint()

func restart() -> void:
	if any_held(): return
	model.reset()
	playing = false
	elapsed = 0.0
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
		while elapsed+0.000001 >= Colony.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Colony.DT)
	paint()

func paint() -> void:
	for i in range(model.home.size()):
		home_tiles.multimesh.set_instance_color(i,Color("142430").lerp(BLUE,model.home[i]/8.0))
		food_tiles.multimesh.set_instance_color(i,Color("241b29").lerp(ROSE,model.food[i]/8.0))
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.4
	selection.position = to_local(points[witness].global_position)-Vector3.UP*0.24
	var offsets := [Colony.TURN,0.0,-Colony.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))
		sensors[i].position.y = 0.13
	var returning: bool = model.carrying[witness]
	for text in captions:
		text.text = "Point %d / %s / delivered %d\nREAD %s  /  LEAVE %s\nL %.2f   F %.2f   R %.2f  / tick %d / %s" % [witness,
			"RETURN" if returning else "SEARCH",model.delivered,"HOME" if returning else "FOOD",
			"FOOD" if returning else "HOME",model.sense(witness,Colony.TURN,returning),
			model.sense(witness,0,returning),model.sense(witness,-Colony.TURN,returning),model.steps,
			"HELD" if any_held() else ("RUN" if playing else "PAUSE")]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
