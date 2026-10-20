extends Node3D
const PointBody = preload("point_body.gd")
const CUT_SPAN := 0.15
const MODES := ["ALL", "FREQUENCY", "NOISE", "CUT"]
var mode := 0
var preview := 0.3
var committed := 0.3
var built_mode := 0
var point: XRToolsPickable
var reading := Label3D.new()
var generators: Array[GyroidFieldGenerator] = []
var holders: Array[Node3D] = []

func recipe(value: float, choice: int) -> Dictionary:
	var s := clampf(value, 0.0, 1.0)
	var f := s if choice == 0 or choice == 1 else 0.3
	var n := s if choice == 0 or choice == 2 else 0.3
	var t := s if choice == 0 or choice == 3 else 0.3
	return {"frequency": lerpf(0.9, 1.6, f),
		"noise_amp": lerpf(0.05, 0.20, n),
		"threshold": CUT_SPAN * (2.0 * t - 1.0)}

func assign(generator: GyroidFieldGenerator, values: Dictionary) -> void:
	generator.frequency = values.frequency
	generator.noise_amp = values.noise_amp
	generator.threshold = values.threshold

func apply_preview() -> void:
	assign(generators[1], recipe(preview, mode))
	generators[1].regenerate(holders[1])
	committed = preview
	built_mode = mode
	refresh()

func reset() -> void:
	mode = 0
	preview = 0.3
	apply_preview()

func _ready() -> void:
	for side in 2:
		var holder := Node3D.new()
		holder.position = Vector3(-1.25 if side == 0 else 1.25, 1.6, 0)
		holder.scale = Vector3.ONE * 0.25
		add_child(holder)
		holders.append(holder)
		var generator := GyroidFieldGenerator.new()
		generator.box_size = Vector3.ONE * 8.0
		generator.voxel_resolution = Vector3i(24, 24, 24)
		generator.noise.seed = 1337
		assign(generator, recipe(0.3, 0))
		generator.generate_gyroid_mesh(holder)
		generator.generate_collision(holder)
		generators.append(generator)
		plinth(holder.position.x)
		caption("A / KEPT AT 0.30" if side == 0 else "B / YOUR RECIPE", Vector3(holder.position.x, 2.8, 0))
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body):
		if point.held(): apply_preview())
	park()
	reading.position = Vector3(0, 3.25, 0.8)
	reading.font_size = 40
	reading.pixel_size = 0.002
	add_child(reading)
	caption("PULL UP: 0.80m -> 1.60m / TRIGGER: BUILD", Vector3(0, 0.65, 1.35))
	refresh()

func _physics_process(_delta: float) -> void:
	if point.held():
		preview = clampf((to_local(point.global_position).y - 0.8) / 0.8, 0.0, 1.0)
		refresh()
	else:
		park()

func park() -> void:
	point.position = Vector3(0, 0.8 + preview * 0.8, 1.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: mode = (mode + 1) % MODES.size()
			KEY_UP: preview = minf(1.0, preview + 0.1)
			KEY_DOWN: preview = maxf(0.0, preview - 0.1)
			KEY_SPACE: apply_preview()
			KEY_R: reset()
			_: return
		refresh()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	var values := recipe(preview, mode)
	reading.text = "PREVIEW %.2f / %s\nk %.3f   noise %.3f   cut %.3f\nBUILT %.2f / %s\n1: MODE   UP/DOWN: PREVIEW   SPACE: BUILD   R: RESET" % [preview, MODES[mode], values.frequency, values.noise_amp, values.threshold, committed, MODES[built_mode]]

func caption(words: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = 32
	label.pixel_size = 0.002
	add_child(label)

func plinth(x: float) -> void:
	var surface := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.1, 0.6, 2.1)
	surface.mesh = mesh
	surface.position = Vector3(x, 0.3, 0)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("33343d")
	surface.material_override = finish
	add_child(surface)
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	boundary.shape = shape
	surface.add_child(body)
	body.add_child(boundary)
