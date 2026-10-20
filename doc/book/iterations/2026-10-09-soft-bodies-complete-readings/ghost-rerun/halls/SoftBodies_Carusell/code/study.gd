extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const RATE := 0.4
const HOME := Vector3(0, 1.3, 0)
var sheet: Sheet
var point: XRToolsPickable
var hub: Node3D
var caption: Label3D
var phase := 0.0
var rate := RATE

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	hub = Node3D.new()
	hub.position = HOME + Vector3.UP * Sheet.HEIGHT * 0.5
	add_child(hub)
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(Sheet.WIDTH + 0.2, 0.05, 0.08)
	bar.mesh = box
	bar.position.y = 0.06
	hub.add_child(bar)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	for side in [-1, 1]:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		marker.mesh = sphere
		marker.material_override = gold
		marker.position.x = side * Sheet.WIDTH * 0.5
		hub.add_child(marker)
	point = Point.new()
	point.position = Vector3(1.15, 1.3, 0.6)
	add_child(point)
	point.action_pressed.connect(func(_p): act("PLAY / HOLD"))
	rebuild()

func rebuild() -> void:
	if is_instance_valid(sheet):
		remove_child(sheet)
		sheet.queue_free()
	phase = 0.0
	rate = RATE
	hub.rotation.y = phase
	sheet = Sheet.new()
	sheet.set_pins(1)
	sheet.position = HOME
	add_child(sheet)

func _physics_process(delta: float) -> void:
	phase = wrapf(phase + rate * delta, -PI, PI)
	hub.rotation.y = phase
	for i in sheet.pins:
		var offset := Vector3(sheet.rest_points[i].x, 0, 0)
		var target := hub.to_global(offset)
		PhysicsServer3D.soft_body_move_point(sheet.get_physics_rid(), i, target)
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(1.15, 1.3, 0.6))
	caption.text = "%.2f rad/s | %.2f rad\n1: speed | 2: reverse | 3: stop | R: rebuild\nHeld trigger: play / hold" % [rate, phase]

func act(command: String) -> void:
	match command:
		"SPEED": rate = RATE * 2.0 if is_equal_approx(rate, RATE) else RATE
		"REVERSE": rate = -rate
		"STOP": rate = 0.0
		"PLAY / HOLD": rate = RATE if is_zero_approx(rate) else 0.0
		"REBUILD": rebuild()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("SPEED")
			KEY_2: act("REVERSE")
			KEY_3: act("STOP")
			KEY_R: act("REBUILD")
