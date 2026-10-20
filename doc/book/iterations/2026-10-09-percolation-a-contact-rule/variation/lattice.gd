extends Node3D
const Reach = preload("reach.gd")
const Point = preload("point_body.gd")
const EDGE := 0.3
var model = Reach.new()
var point
var cells: Node3D
var caption: Label3D
var corner := false
var is_lattice := false
var density := 0

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0,2.85,0)
	caption.font_size = 26; caption.pixel_size = 0.002; caption.outline_size = 8
	add_child(caption)
	point = Point.new()
	add_child(point)
	point.action_pressed.connect(func(_p): act("STEP"))
	model.contact(false)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0,1.1,1.5))

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: act("STEP")
			KEY_T: act("TEN")
			KEY_C: act("CONTACT")
			KEY_L: act("LATTICE")
			KEY_D: act("DENSITY")
			KEY_R: act("RESTART")

func act(action: String) -> void:
	match action:
		"STEP": model.step()
		"TEN": for i in 10: model.step()
		"CONTACT":
			corner = not corner
			is_lattice = false
			model.contact(corner)
		"LATTICE":
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"DENSITY":
			density = (density + 1) % 3
			is_lattice = true
			model.lattice([0.2,0.4,0.6][density])
		"RESTART": model.restart()
	refresh()

func refresh() -> void:
	if is_instance_valid(cells): cells.free()
	cells = Node3D.new()
	add_child(cells)
	for cell: Vector3i in model.occupied:
		var body := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3.ONE * EDGE
		body.mesh = shape
		body.position = (Vector3(cell) - Vector3(2.5,0,2.5)) * EDGE + Vector3(0,0.55,0)
		var finish := StandardMaterial3D.new()
		finish.roughness = 0.7
		finish.albedo_color = Color("faf6ee")
		if model.reached.has(cell): finish.albedo_color = Color("ec9ebd")
		if model.sources.has(cell): finish.albedo_color = Color("8b345b")
		body.material_override = finish
		cells.add_child(body)
	var mode: String = "Lattice p=%s" % [0.2,0.4,0.6][density] if is_lattice else ("CORNER" if corner else "FACE")
	caption.text = "%s | step %d/64\n%d reached beyond %d source sites\nSPACE or held trigger: step | T: ten | C: contact\nL: lattice | D: density | R: restart" % [mode, model.generation, model.reached.size()-model.sources.size(), model.sources.size()]
	if is_lattice: caption.text += "\n%d reached on opposite z face" % model.far_count()
