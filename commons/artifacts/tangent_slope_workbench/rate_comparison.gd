extends Node3D
## Opt-in comparison for Change_Intro: two spatial samples before the analytic tangent.
const STEPS = [0.5, 0.25, 0.125, 0.0625]
var bench: Node3D
var panel: Node3D
var buttons: Dictionary = {}
var readout: Label
var step_index := 0
var revealed := false
var secant: MeshInstance3D
var second: MeshInstance3D
var mesh := ImmediateMesh.new()

func _ready() -> void:
	bench = get_parent()
	var light = OmniLight3D.new()
	light.position = Vector3(0, 1.8, 1.5)
	light.omni_range = 3.5
	light.light_energy = 2.0
	light.shadow_enabled = false
	add_child(light)
	# Extend the existing console so the second interface cannot hide its slider.
	panel = bench._plate_root
	panel.board_width = 1.8
	panel.face_to_origin = false
	panel.body_height = 0.8
	panel.position.y = 0
	panel.panel().label_mesh = false
	bench._sign_root.position = Vector3(1.05, 1.65, -0.05)
	panel.set_title("TWO SAMPLES / x IS POSITION")
	panel.panel().title_color = Color("17202a")
	panel.panel().label_color = Color("17202a")
	panel.panel().label_mesh_color = Color("17202a")
	readout = bench._plate_readout
	for id in ["x -", "x +", "STEP", "DERIVATIVE", "RESET"]:
		var button = panel.add_button(id)
		buttons[id] = button
		button.pressed.connect(act.bind(id))
	var ink = StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("58e7ae")
	secant = MeshInstance3D.new()
	secant.name = "TwoSampleLine"
	secant.mesh = mesh
	secant.material_override = ink
	bench._plot_root.add_child(secant)
	second = MeshInstance3D.new()
	second.name = "SecondSample"
	var sphere = SphereMesh.new()
	sphere.radius = 0.019
	sphere.height = 0.038
	second.mesh = sphere
	second.material_override = ink
	bench._plot_root.add_child(second)

func sample() -> Dictionary:
	var x: float = bench._x
	# At the right edge sample backwards, and display that signed interval.
	var h: float = STEPS[step_index]
	if x + h > bench.x_max: h = -h
	var rise: float = bench._f(x + h) - bench._f(x)
	return {"x":x, "h":h, "next":x+h, "rise":rise, "rate":rise/h}

func act(id: String) -> void:
	match id:
		"x -": set_x(bench._x - 0.125)
		"x +": set_x(bench._x + 0.125)
		"STEP": step_index = (step_index + 1) % STEPS.size()
		"DERIVATIVE": revealed = not revealed
		"RESET":
			step_index = 0
			revealed = false
			set_x(bench.initial_x)
	bench._refresh_all()

func set_x(value: float) -> void:
	bench._x = clampf(value, bench.x_min, bench.x_max)
	bench._slider.set_normalized_value(bench._x_to_normalized(bench._x))

func point(x: float, y: float) -> Vector3:
	return Vector3(bench._x_to_local(x), bench._f_to_local(y), 0.008)

func refresh() -> void:
	var s = sample()
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(point(s.x, bench._f(s.x)))
	mesh.surface_add_vertex(point(s.next, bench._f(s.next)))
	mesh.surface_end()
	second.position = point(s.next, bench._f(s.next))
	bench._tangent_mesh_inst.visible = revealed
	bench._derivative_root.visible = revealed
	bench._sign_root.visible = revealed
	readout.text = "x %.3f / f %.4f / h %+.4f\nrise %+.4f / h = %+.4f / %s" % [s.x, bench._f(s.x), s.h, s.rise, s.rate, "analytic f' %+.4f" % bench._df(s.x) if revealed else "compare first"]
