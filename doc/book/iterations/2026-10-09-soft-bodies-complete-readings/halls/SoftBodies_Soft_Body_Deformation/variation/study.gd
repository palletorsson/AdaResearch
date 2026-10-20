extends Node3D

const YieldingCube = preload("yielding_cube.gd")
const Point = preload("point_body.gd")
var cube: YieldingCube
var point: XRToolsPickable
var caption: Label3D

func _ready() -> void:
	cube = YieldingCube.new()
	cube.position = Vector3(0, 1.3, 0)
	add_child(cube)
	var pin := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	pin.mesh = sphere
	pin.position = cube.position + cube.rest_points[cube.anchor_index]
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	pin.material_override = gold
	add_child(pin)
	point = Point.new()
	point.position = Vector3(0.45, 1.3, 0.25)
	add_child(point)
	point.action_pressed.connect(func(_p): act("STIFFNESS"))
	caption = Label3D.new()
	caption.position = Vector3(0, 1.85, 0)
	caption.font_size = 32
	caption.pixel_size = 0.001
	add_child(caption)
	refresh()

func _physics_process(_delta: float) -> void:
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0.45, 1.3, 0.25))

func act(command: String) -> void:
	match command:
		"STIFFNESS": cube.linear_stiffness = 0.1 if cube.linear_stiffness > 0.1 else 0.5
		"DAMPING": cube.damping_coefficient = 0.1 if cube.damping_coefficient < 0.1 else 0.01
		"PRESSURE": cube.pressure_coefficient = 0.0 if cube.pressure_coefficient > 0.0 else 1.0
		"RESET": cube.reset_settings()
	refresh()

func refresh() -> void:
	caption.text = "ONE POINT STAYS\n1 stiffness %.2f | 2 damping %.2f\n3 pressure %.1f | R reset settings\nBlack point: press the surface; trigger changes stiffness" % [cube.linear_stiffness, cube.damping_coefficient, cube.pressure_coefficient]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("STIFFNESS")
			KEY_2: act("DAMPING")
			KEY_3: act("PRESSURE")
			KEY_R: act("RESET")
