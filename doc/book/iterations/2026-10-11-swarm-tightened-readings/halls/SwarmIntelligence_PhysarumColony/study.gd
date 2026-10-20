extends Node3D
const Trail = preload("trail.gd")
const PointBody = preload("point_body.gd")
const CELL := 0.16
const HEIGHT := 1.02
const TICK := 0.15
var trail = Trail.new()
var points: Array[Node3D] = []
var tiles: Array[MeshInstance3D] = []
var sensors: Array[MeshInstance3D] = []
var caption: Label3D
var playing := false
var elapsed := 0.0

func place(p: Vector2) -> Vector3:
	return Vector3((p.x - 8.0) * CELL, HEIGHT, -(p.y - 8.0) * CELL)

func record(p: Vector3) -> Vector2:
	return trail.wrap_position(Vector2(p.x / CELL + 8.0, -p.z / CELL + 8.0))

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
	base.position.y = HEIGHT - 0.13
	for y in range(Trail.WIDTH):
		for x in range(Trail.WIDTH):
			var cell := tile(Vector3(CELL*0.94,0.015,CELL*0.94), Color("283c46"))
			cell.position = place(Vector2(x+0.5,y+0.5)) - Vector3.UP*0.075
			tiles.append(cell)
	for i in range(trail.positions.size()):
		var point = PointBody.new()
		add_child(point)
		point.action_pressed.connect(func(_source): stamp(i))
		points.append(point)
	for colour in [Color("67c8df"), Color("ffffff"), Color("dc92ae")]:
		sensors.append(tile(Vector3(0.04,0.02,0.04), colour))
	caption = label("", Vector3(0,1.9,-1.35), 30)
	label("TRACE OUTSIDE THE POINT", Vector3(0,2.3,-1.35), 34)
	label("L / cyan      F / white      R / pink", Vector3(0,1.58,-1.35))
	var actions := [toggle_play, change_retention, restart]
	var words := ["RUN / PAUSE", "RETENTION", "RESET"]
	for i in range(3):
		var button = preload("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["Run", "Retention", "Reset"][i]
		button.position = Vector3((i-1)*0.65,0.85,1.6)
		button.rotation.x = deg_to_rad(-25.0)
		add_child(button)
		button.pressed.connect(actions[i])
		label(words[i], button.position+Vector3(0,0.17,0), 22)
	paint()

func stamp(i: int) -> void:
	trail.positions[i] = record(to_local(points[i].global_position))
	trail.deposit(trail.positions[i])
	paint()

func toggle_play() -> void:
	playing = not playing
	paint()

func change_retention() -> void:
	trail.retention = 0.55 if trail.retention > 0.8 else 0.92
	restart()

func restart() -> void:
	trail.reset()
	elapsed = 0.0
	paint()

func _process(delta: float) -> void:
	var holding := false
	for i in range(points.size()):
		if points[i].held():
			holding = true
			trail.positions[i] = record(to_local(points[i].global_position))
	if holding:
		elapsed = 0.0
	elif playing:
		elapsed += minf(delta,0.5)
		while elapsed >= TICK:
			trail.step()
			elapsed -= TICK
	paint()

func paint() -> void:
	for i in range(tiles.size()):
		tiles[i].material_override.albedo_color = Color("283c46").lerp(Color("f4d889"), trail.values[i]/8.0)
	for i in range(points.size()):
		if not points[i].held():
			points[i].position = place(trail.positions[i])
	var offsets := [Trail.TURN, 0.0, -Trail.TURN]
	for i in range(sensors.size()):
		sensors[i].position = place(trail.sensor_position(0,offsets[i])) - Vector3.UP*0.03
	caption.text = "Point 0: L %.2f   F %.2f   R %.2f\nTick %d  /  keep %.0f%%  /  %s" % [
		trail.sense(0,Trail.TURN), trail.sense(0,0), trail.sense(0,-Trail.TURN),
		trail.steps, trail.retention*100.0, "RUN" if playing else "PAUSE"]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1: toggle_play()
		elif event.keycode == KEY_2: change_retention()
		elif event.keycode == KEY_R: restart()
