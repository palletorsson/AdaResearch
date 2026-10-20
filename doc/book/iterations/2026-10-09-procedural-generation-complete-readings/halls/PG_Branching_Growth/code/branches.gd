extends Node3D
const Growth = preload("growth.gd")
const Point = preload("point_body.gd")
const DISPLAY := 0.4
var model = Growth.new()
var point
var live: Node3D
var witness: Node3D
var caption: Label3D
var held: Array = []

func _ready() -> void:
	caption = label("", Vector3(0,2.85,0))
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	act("RESET")

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,0.8))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_H: act("HOLD")
			KEY_R: act("RESET")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"RESET": model.reset()
		"HOLD":
			held = model.nodes.duplicate(true)
			if is_instance_valid(witness): witness.free()
			witness = display(Vector3(-2,0.4,0), DISPLAY * 0.6)
			draw_record(held, witness, Color("c3b9df"))
	refresh()

func refresh() -> void:
	if is_instance_valid(live): live.free()
	live = display(Vector3(0,0.35,0), DISPLAY)
	draw_record(model.nodes, live, Color("8fd2c6"))
	for i in model.points.size():
		sphere(model.points[i], 0.055 if model.reached[i] else 0.1,
			Color("586270") if model.reached[i] else Color("efb2d1"), live)
	for row in model.nodes:
		if not row.active: continue
		var target: int = model.nearest(row.position)
		if target < 0: continue
		var direction: Vector3 = (model.points[target] - row.position).normalized()
		rod(row.position, model.points[target], 0.012, Color("946678"), live)
		rod(row.position, row.position + direction * Growth.STEP, 0.055, Color.WHITE, live)
		break
	var last: Dictionary = model.nodes.back()
	caption.text = "%d records / %d positions / step %d\nLast child: parent %d / target %d\nSPACE or held trigger: step | T: ten | H: hold | R: reset\n%s" % [model.nodes.size(), model.distinct_count(), model.generation, last.parent, last.target, model.reason]

func display(at: Vector3, factor: float) -> Node3D:
	var node := Node3D.new()
	add_child(node)
	node.position = at
	node.scale = Vector3.ONE * factor
	return node

func draw_record(rows: Array, host: Node3D, colour: Color) -> void:
	sphere(Vector3.ZERO, 0.13, colour, host)
	for row in rows:
		if row.parent >= 0: rod(rows[row.parent].position, row.position, 0.045, colour, host)

func mesh(shape: Mesh, at: Vector3, colour: Color, host: Node3D) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.7
	body.mesh = shape
	body.material_override = material
	body.position = at
	host.add_child(body)
	return body

func sphere(at: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var shape := SphereMesh.new()
	shape.radius = radius; shape.height = 2 * radius
	shape.radial_segments = 12; shape.rings = 6
	mesh(shape, at, colour, host)

func rod(a: Vector3, b: Vector3, radius: float, colour: Color, host: Node3D) -> void:
	var length := a.distance_to(b)
	if length < 0.0001: return
	var shape := CylinderMesh.new()
	shape.top_radius = radius; shape.bottom_radius = radius; shape.height = length
	shape.radial_segments = 8
	var body := mesh(shape, (a+b)/2, colour, host)
	body.quaternion = Quaternion(Vector3.UP, (b-a)/length)

func label(text: String, at: Vector3) -> Label3D:
	var node := Label3D.new()
	node.text = text; node.position = at; node.font_size = 26
	node.pixel_size = 0.002; node.outline_size = 8
	add_child(node)
	return node
