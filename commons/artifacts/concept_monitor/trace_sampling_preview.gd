extends "res://commons/artifacts/concept_monitor/preview.gd"
## Desktop preview drives the real DrawDot pen. The museum uses its normal grab.
const Dot = preload("res://commons/primitives/point/draw_dot.tscn")
var dot: Node3D
var pen: Node3D
var drawing_mouse := false
var demo := false
var demo_time := 0.0

func _ready() -> void:
	super()
	dot = Dot.instantiate()
	dot.name = "DrawDot"
	dot.set("simple_pen", true)
	dot.set("show_data_table", false)
	dot.set("movement_threshold", 100000.0)
	dot.position = Vector3(-1.7, 1.1, 0.6)
	add_child(dot)
	pen = dot.get("_grab_point")
	monitor.discover_sources()
	for child in get_children():
		if child is Label:
			child.text = "SPACE + mouse: draw / Wheel while drawing: depth / D: labelled demo gesture\nRight-drag: look / Home: return / Arrows: orbit trace / Click GRAIN / GRID"
	if "--trace-demo" in OS.get_cmdline_user_args(): call_deferred("start_demo")

func start_demo() -> void:
	demo = true
	drawing_mouse = false
	demo_time = 0.0
	monitor.active_source = null
	monitor.stage.record.end()
	dot.name = "DEMO_gesture"
	dot.call("clear_trail")
	pen.set("desktop_held", true)

func _process(delta: float) -> void:
	if demo:
		demo_time += delta
		if demo_time >= 6.0:
			demo = false
			pen.set("desktop_held", false)
			return
		var u := demo_time / 6.0
		pen.global_position = Vector3(-1.8 + 0.7 * u, 1.2 + 0.24 * sin(u * TAU * 2.0), 0.7 + 0.20 * sin(u * TAU))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_D and event.pressed and not event.echo:
		start_demo()
		return
	if event is InputEventKey and event.keycode == KEY_SPACE and not event.echo:
		demo = false
		drawing_mouse = event.pressed
		if drawing_mouse:
			monitor.active_source = null
			monitor.stage.record.end()
			dot.name = "Mouse_gesture"
			dot.call("clear_trail")
			pen.call("on_desktop_grab", self)
		else:
			pen.call("on_desktop_drop", self)
		return
	if event is InputEventMouseMotion and drawing_mouse:
		pen.position += Vector3(event.relative.x * 0.003, -event.relative.y * 0.003, 0)
		return
	if event is InputEventMouseButton and drawing_mouse and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		pen.position.z += -0.04 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.04
		return
	super(event)
