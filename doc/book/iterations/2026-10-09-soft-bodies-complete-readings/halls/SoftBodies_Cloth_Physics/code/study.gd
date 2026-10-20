extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const HOME := Vector3(0, 1.3, 0)
var sheet: Sheet
var point: XRToolsPickable
var frame: MeshInstance3D
var markers: Node3D
var caption: Label3D

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0, 2.45, 0)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	markers = Node3D.new()
	add_child(markers)
	frame = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(Sheet.WIDTH + 0.2, 0.05, 0.08)
	frame.mesh = bar
	frame.position = HOME + Vector3(0, Sheet.HEIGHT * 0.5 + 0.06, 0)
	add_child(frame)
	point = Point.new()
	point.position = Vector3(0.85, 1.3, 0.3)
	add_child(point)
	point.action_pressed.connect(func(_p): act("PINS"))
	rebuild()

func rebuild() -> void:
	if is_instance_valid(sheet):
		remove_child(sheet)
		sheet.queue_free()
	sheet = Sheet.new()
	sheet.position = HOME
	add_child(sheet)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0.85, 1.3, 0.3))
	for j in sheet.pins.size():
		markers.get_child(j).global_position = sheet.get_point_transform(sheet.pins[j])

func act(command: String) -> void:
	match command:
		"PINS":
			if sheet.mode == 0: sheet.set_pins(1)
			else: rebuild()
		"SUPPORT": frame.visible = not frame.visible
		"RELEASE": sheet.set_pins(2)
		"REBUILD": rebuild()
	refresh()

func refresh() -> void:
	for marker in markers.get_children():
		markers.remove_child(marker)
		marker.queue_free()
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	for i in sheet.pins:
		var dot := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		dot.mesh = sphere
		dot.material_override = gold
		markers.add_child(dot)
		dot.global_position = sheet.get_point_transform(i)
	caption.text = "%s | %d pins\n1 / held trigger: pins | 2: show support\nX: release all | R: rebuild" % [["TOP ROW", "TWO CORNERS", "RELEASED"][sheet.mode], sheet.pins.size()]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("PINS")
			KEY_2: act("SUPPORT")
			KEY_X: act("RELEASE")
			KEY_R: act("REBUILD")
