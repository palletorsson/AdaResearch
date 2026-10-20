extends Node3D

const PressurePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const RATE := 1.0
const AMPLITUDE := 0.5
var panels: Array[PressurePanel] = []
var point: XRToolsPickable
var caption: Label3D
var phase := 0.0
var rate := RATE
var amplitude := AMPLITUDE
var held := false
var pressure := 0.0

func _ready() -> void:
	for side in [-1, 1]:
		var panel := PressurePanel.new()
		panel.position = Vector3(side * 0.8, 1.3, 0)
		add_child(panel)
		panels.append(panel)
	point = Point.new()
	point.position = Vector3(0, 1.3, 1.2)
	add_child(point)
	point.action_pressed.connect(func(_p): act("HOLD DRIVE"))
	caption = Label3D.new()
	caption.position = Vector3(0, 2.15, 0.8)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	apply_pressure()

func _physics_process(delta: float) -> void:
	if not held:
		phase = wrapf(phase + rate * delta, 0.0, TAU)
	apply_pressure()
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.3, 1.2))
	caption.text = "PRESSURE %.2f | phase %.2f\n1 amplitude %.2f | 2 rate %.2f | 3 hold %s\n4 stiffness | R reset phase | held trigger: hold drive" % [pressure, phase, amplitude, rate, held]

func apply_pressure() -> void:
	pressure = (sin(phase) + 1.0) * 0.5 * amplitude
	for panel in panels:
		panel.pressure_coefficient = pressure

func act(command: String) -> void:
	match command:
		"AMPLITUDE": amplitude = 0.15 if amplitude > 0.15 else AMPLITUDE
		"RATE": rate = RATE * 0.5 if is_equal_approx(rate, RATE) else RATE
		"HOLD DRIVE": held = not held
		"STIFFNESS":
			for panel in panels:
				panel.linear_stiffness = 0.2 if panel.linear_stiffness > 0.2 else 0.5
		"RESET PHASE": phase = 0.0
	apply_pressure()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("AMPLITUDE")
			KEY_2: act("RATE")
			KEY_3: act("HOLD DRIVE")
			KEY_4: act("STIFFNESS")
			KEY_R: act("RESET PHASE")
