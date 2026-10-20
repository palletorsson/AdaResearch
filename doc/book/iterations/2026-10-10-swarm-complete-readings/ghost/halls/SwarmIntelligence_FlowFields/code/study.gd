extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
var field = Field.new()
var points: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var arrows: Array[Node3D] = []
var caption: Label3D
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x-8.0)*CELL, HEIGHT, -(p.y-8.0)*CELL)

func record(p: Vector3) -> Vector2:
	return field.wrap_position(Vector2(p.x/CELL+8.0, -p.z/CELL+8.0))

func finish(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.5
	return material

func tile(size: Vector3, colour: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = finish(colour)
	add_child(body)
	return body

func arrow(at: Vector3) -> Node3D:
	var body := Node3D.new()
	add_child(body)
	body.position = at
	for tip in [false,true]:
		var visual := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.height = 0.03 if tip else 0.08
		mesh.bottom_radius = 0.02 if tip else 0.006
		mesh.top_radius = 0.0 if tip else 0.006
		mesh.radial_segments = 8
		visual.mesh = mesh
		visual.material_override = finish(Color("c5e5e9"))
		visual.position.y = 0.055 if tip else 0.0
		body.add_child(visual)
	return body

func label(words: String, at: Vector3, size: int = 26) -> Label3D:
	var text := Label3D.new()
	text.text = words
	text.position = at
	text.font_size = size
	text.pixel_size = 0.002
	add_child(text)
	return text

func _ready() -> void:
	var base := tile(Vector3(2.7,0.08,2.7), Color("242832"))
	base.position.y = HEIGHT-0.13
	for y in range(Field.WIDTH):
		for x in range(Field.WIDTH):
			var at := place(Vector2(x+0.5,y+0.5)) - Vector3.UP*0.075
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94), Color("283c46"))
			cell.position = at
			tiles.append(cell)
			arrows.append(arrow(at+Vector3.UP*0.025))
	for i in range(field.positions.size()):
		var point = PointBody.new()
		if i == 0: point.tint = Color("ef8bad")
		add_child(point)
		point.action_pressed.connect(func(_source): edit_under(i))
		points.append(point)
	caption = label("", Vector3(0,1.9,-1.35), 28)
	label("DIRECTIONS ALREADY HERE", Vector3(0,2.3,-1.35), 34)
	label("Pink: point 0 / arrows: supplied direction", Vector3(0,1.55,-1.35), 22)
	var actions := [toggle_play, change_patch, restart]
	var words := ["RUN / PAUSE", "TURN / STOP / EAST", "RESET"]
	for i in range(3):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run", "Patch", "Reset"][i]
		button.position = Vector3((i-1)*0.8,0.85,1.6)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(words[i],button.position+Vector3(0,0.17,0),18)
	paint()

func edit_under(i: int) -> void:
	if not points[i].held(): return
	field.positions[i] = record(to_local(points[i].global_position))
	field.edit_cell(field.positions[i])
	paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_patch() -> void:
	field.patch_mode = (field.patch_mode+1) % 3
	field.set_patch()
	paint()

func restart() -> void:
	field.reset()
	playing = false
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			field.positions[i] = record(to_local(points[i].global_position))
			field.velocities[i] = Vector2.ZERO
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed+0.000001 >= Field.DT:
			field.step()
			elapsed = maxf(0.0,elapsed-Field.DT)
	paint()

func paint() -> void:
	for i in range(arrows.size()):
		var v:Vector2 = field.vectors[i]
		arrows[i].visible = not v.is_zero_approx()
		if arrows[i].visible:
			arrows[i].quaternion = Quaternion(Vector3.UP,Vector3(v.x,0,-v.y).normalized())
		tiles[i].material_override.albedo_color = Color("404048") if v.is_zero_approx() else (
			Color("416977") if v.y > 0 else Color("283c46"))
	for i in range(points.size()):
		if not points[i].held(): points[i].position = place(field.positions[i])
	var d:Vector2 = field.desired_at(field.positions[0])
	var v:Vector2 = field.velocities[0]
	var address:int = field.index_at(field.positions[0])
	caption.text = "Point 0 / cell %d\nDesired (%.1f, %.1f) / velocity (%.1f, %.1f) cells/s\nTick %d / %s" % [
		address,d.x,d.y,v.x,v.y,field.steps,"RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_patch()
		elif event.keycode == KEY_R: restart()
