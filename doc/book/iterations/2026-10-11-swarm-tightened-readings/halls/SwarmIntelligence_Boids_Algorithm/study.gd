extends Node3D
const Flock = preload("flock.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
const NAMES := ["SEPARATION", "ALIGNMENT", "COHESION", "ALL THREE"]
var flock = Flock.new()
var points: Array[Node3D] = []
var halos: Array[MeshInstance3D] = []
var arrows: Array[Node3D] = []
var radius_ring: MeshInstance3D
var caption: Label3D
var witness := 0
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL, HEIGHT, -(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return flock.wrap_position(Vector2(p.x/CELL+8.0, -p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func visual(mesh: Mesh, colour: Color, parent: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.material_override = finish(colour)
	parent.add_child(body)
	return body

func ring(radius: float, colour: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius-0.005
	mesh.outer_radius = radius+0.005
	mesh.rings = 48
	mesh.ring_segments = 6
	return visual(mesh,colour,self)

func arrow(colour: Color) -> Node3D:
	var body := Node3D.new()
	add_child(body)
	for tip in [false,true]:
		var mesh := CylinderMesh.new()
		mesh.height = 0.03 if tip else 0.1
		mesh.bottom_radius = 0.025 if tip else 0.007
		mesh.top_radius = 0.0 if tip else 0.007
		mesh.radial_segments = 8
		visual(mesh,colour,body)
	return body

func show_arrow(body: Node3D, vector: Vector2, at: Vector3) -> void:
	body.visible = not vector.is_zero_approx()
	if not body.visible: return
	var length := vector.length()*0.07
	body.position = at
	body.quaternion = Quaternion(Vector3.UP,Vector3(vector.x,0,-vector.y).normalized())
	body.get_child(0).mesh.height = length
	body.get_child(0).position.y = length*0.5
	body.get_child(1).position.y = length+0.015

func label(words: String, at: Vector3, size: int = 24) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := BoxMesh.new()
	base.size = Vector3(2.7,0.08,2.7)
	visual(base,Color("747c84"),self).position.y = HEIGHT-0.13
	for i in range(flock.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): choose(i))
		points.append(point)
		halos.append(ring(0.10,Color("a0e8ec")))
	radius_ring = ring(flock.radius*CELL,Color("f5ce60"))
	for colour in ["fa6262","679cfa","59d996","ffffff"]:
		arrows.append(arrow(Color(colour)))
	label("WHO IS NEAR?",Vector3(0,2.28,-1.3),36)
	caption = label("",Vector3(0,1.90,-1.3),24)
	label("Red: separate / blue: align / green: gather\nWhite: combined acceleration (0.07 m per cell/s²)",Vector3(0,1.51,-1.3),19)
	var actions := [toggle_play, change_rule, change_radius, restart]
	for i in range(4):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run","Rule","Radius","Reset"][i]
		button.position = Vector3((i-1.5)*0.72,0.85,1.60)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(["RUN / PAUSE","NEXT RULE","RADIUS 2 / 3.5","RESET BODIES"][i],button.position+Vector3(0,0.17,0),16)
	paint()

func choose(i: int) -> void:
	if points[i].held():
		witness = i
		paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_rule() -> void:
	flock.mode = (flock.mode+1)%4
	paint()

func change_radius() -> void:
	flock.radius = 2.0 if flock.radius > 2.0 else 3.5
	paint()

func restart() -> void:
	flock.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			flock.positions[i] = record(to_local(points[i].global_position))
			flock.velocities[i] = Vector2.ZERO
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Flock.DT:
			flock.step()
			elapsed = maxf(0.0,elapsed-Flock.DT)
	paint()

func paint() -> void:
	var nearby: Array[int] = flock.neighbours(witness)
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(flock.positions[i])
		halos[i].position = place(flock.positions[i])-Vector3.UP*0.08
		halos[i].visible = i in nearby
	var at := place(flock.positions[witness])
	radius_ring.position = at-Vector3.UP*0.065
	radius_ring.mesh.inner_radius = flock.radius*CELL-0.005
	radius_ring.mesh.outer_radius = flock.radius*CELL+0.005
	var parts: Array[Vector2] = flock.requests(witness)
	for rule in range(3):
		var active: bool = flock.mode == 3 or flock.mode == rule
		show_arrow(arrows[rule],parts[rule]*flock.weights[rule] if active else Vector2.ZERO,at+Vector3.UP*(0.14+rule*0.04))
	show_arrow(arrows[3],flock.acceleration(witness),at+Vector3.UP*0.30)
	var a: Vector2 = flock.acceleration(witness)
	var v: Vector2 = flock.velocities[witness]
	caption.text = "%s / point %d / neighbours %s\nRadius %.1f cells / v (%.2f, %.2f) cells/s\na (%.2f, %.2f) cells/s² / tick %d / %s" % [
		NAMES[flock.mode],witness,str(nearby),flock.radius,v.x,v.y,a.x,a.y,flock.steps,"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_rule()
		elif event.keycode == KEY_3: change_radius()
		elif event.keycode == KEY_R: restart()
