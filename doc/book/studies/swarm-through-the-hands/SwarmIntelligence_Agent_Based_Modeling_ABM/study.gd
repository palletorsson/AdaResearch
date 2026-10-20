extends Node3D
const Foragers = preload("foragers.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
var model = Foragers.new()
var points: Array[Node3D] = []
var cargo: Array[MeshInstance3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL,HEIGHT,-(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return model.wrap_position(Vector2(p.x/CELL+8.0,-p.z/CELL+8.0))

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	body.material_override = material
	add_child(body)
	return body

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func destination(p: Vector2, colour: Color, words: String) -> void:
	var body := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = Foragers.CONTACT*CELL-0.005
	ring.outer_radius = Foragers.CONTACT*CELL+0.005
	ring.rings = 48
	ring.ring_segments = 6
	body.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	body.material_override = material
	add_child(body)
	body.position = place(p)-Vector3.UP*0.06
	label(words,place(p)+Vector3(0,0.30,-0.22),20)

func _ready() -> void:
	tile(Vector3(2.7,0.08,2.7),Color("242832")).position.y = HEIGHT-0.13
	for y in range(Foragers.WIDTH):
		for x in range(Foragers.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94),Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5))-Vector3.UP*0.075
			tiles.append(cell)
	for i in range(model.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		cargo.append(tile(Vector3.ONE*0.06,Color("a0ef82")))
	for colour in ["67c8df","ffffff","dc92ae"]:
		sensors.append(tile(Vector3(0.035,0.02,0.035),Color(colour)))
	destination(Foragers.HOME,Color("fac35f"),"HOME")
	destination(Foragers.FOOD,Color("a0ef82"),"FOOD")
	label("WHAT THE POINT CARRIES",Vector3(0,2.28,-1.3),32)
	caption = label("",Vector3(0,1.88,-1.3),22)
	label("Cube above point: carrying / gold cells: shared trace",Vector3(0,1.49,-1.3),18)
	var actions := [toggle_play, single_step, replace, restart]
	for i in range(4):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run","Step","Replace","Reset"][i]
		button.position = Vector3((i-1.5)*0.72,0.85,1.60)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(["RUN / PAUSE","ONE TICK","REPLACE AGENTS","CLEAR ALL"][i],button.position+Vector3(0,0.17,0),16)
	paint()

func choose(i: int) -> void:
	if points[i].held():
		witness = i
		paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func any_held() -> bool:
	for point in points:
		if point.held(): return true
	return false

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
		while elapsed+0.000001 >= Foragers.DT:
			model.step()
			elapsed = maxf(0.0,elapsed-Foragers.DT)
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"),model.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(model.positions[i])
		cargo[i].visible = model.carrying[i]
		cargo[i].position = to_local(points[i].global_position)+Vector3.UP*0.14
	var offsets := [Foragers.TURN,0.0,-Foragers.TURN]
	for i in range(sensors.size()):
		sensors[i].visible = not model.carrying[witness]
		sensors[i].position = place(model.sensor_position(witness,offsets[i]))-Vector3.UP*0.03
	var v: Vector2 = model.velocities[witness]
	caption.text = "Point %d / %s / delivered %d\nv (%.2f, %.2f) cells/s / tick %d\nL %.2f / F %.2f / R %.2f / %s" % [
		witness,"RETURN + DEPOSIT" if model.carrying[witness] else "SEARCH",model.delivered,
		v.x,v.y,model.steps,model.sense(witness,Foragers.TURN),model.sense(witness,0),
		model.sense(witness,-Foragers.TURN),"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: single_step()
		elif event.keycode == KEY_3: replace()
		elif event.keycode == KEY_R: restart()
