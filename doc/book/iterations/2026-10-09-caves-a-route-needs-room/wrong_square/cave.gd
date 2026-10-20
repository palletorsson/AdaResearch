extends Node3D
const Carver = preload("carver.gd")
const PointBody = preload("point_body.gd")
const EDGE := 0.28
const ROUTE := [Vector3i(3,0,6), Vector3i(3,0,5), Vector3i(3,0,4),
	Vector3i(3,0,4), Vector3i(4,0,4), Vector3i(4,0,3),
	Vector3i(4,0,2), Vector3i(4,0,1), Vector3i(4,0,0)]
var model := Carver.new()
var point := PointBody.new()
var drawing := Node3D.new()
var caption := Label3D.new()
var cursor := 0
var cutaway := false

func _ready() -> void:
	add_child(drawing)
	add_child(caption)
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 26
	caption.pixel_size = 0.002
	add_child(point)
	park()
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held(): park()

func park() -> void:
	point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.1, 1.45))

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_SPACE: act("STEP")
		KEY_F: act("FINISH")
		KEY_C: act("CUT")
		KEY_R: act("RESET")

func act(command: String) -> void:
	match command:
		"STEP": advance()
		"FINISH":
			while cursor < ROUTE.size(): advance()
		"CUT": cutaway = not cutaway
		"RESET":
			model.reset()
			cursor = 0
	redraw()

func advance() -> void:
	if cursor < ROUTE.size():
		model.carve(ROUTE[cursor])
		cursor += 1

func location(p: Vector3i) -> Vector3:
	return Vector3(p - Vector3i(3,0,3)) * EDGE + Vector3(0, 0.75 + EDGE / 2, 0)

func redraw() -> void:
	for child in drawing.get_children():
		drawing.remove_child(child)
		child.queue_free()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("eee8dc")
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("efb751")
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * EDGE
	for y in Carver.SIZE.y:
		for z in Carver.SIZE.z:
			for x in Carver.SIZE.x:
				var p := Vector3i(x,y,z)
				if model.solid[model.index(p)] == 0: continue
				if cutaway and y >= 2: continue
				var cell := MeshInstance3D.new()
				cell.mesh = cube
				cell.material_override = stone
				cell.position = location(p)
				drawing.add_child(cell)
	var dot := SphereMesh.new()
	dot.radius = 0.025
	dot.height = 0.05
	for p in model.history:
		var mark := MeshInstance3D.new()
		mark.mesh = dot
		mark.material_override = gold
		mark.position = location(p)
		drawing.add_child(mark)
	caption.text = "A ROUTE NEEDS ROOM\n%d / %d centres | %d empty cells | headroom %d\nSPACE / held action: carve | F: finish | C: cutaway | R: reset\n%s" % [cursor, ROUTE.size(), model.air_count(), Carver.HEADROOM,
		"CUTAWAY: upper two layers hidden, data kept" if cutaway else "All remaining solid cells shown"]
