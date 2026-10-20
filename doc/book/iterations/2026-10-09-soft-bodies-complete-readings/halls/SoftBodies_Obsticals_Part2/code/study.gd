extends Node3D

const SamplePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const SAMPLE_TIME := 1.5
const CONTACT := Vector3(0.6 / 7.0, 1.1, 0.1)
const CASES := [
	{"name": "A", "damping": 0.1},
	{"name": "B", "damping": 0.6},
]
var panels: Array[SamplePanel] = []
var points: Array[XRToolsPickable] = []
var captions: Array[Label3D] = []
var results: Array[float] = []
var elapsed := 0.0
var running := false
var armed := false
var status := ""

func _ready() -> void:
	for i in CASES.size():
		var point := Point.new()
		point.position = bay(i) + CONTACT
		add_child(point)
		points.append(point)
		point.action_pressed.connect(func(_p): request_replay())
		var caption := Label3D.new()
		caption.position = bay(i) + Vector3(0, 2.8, 0.5)
		caption.font_size = 28
		caption.pixel_size = 0.003
		add_child(caption)
		captions.append(caption)
	replay()

func bay(i: int) -> Vector3:
	return Vector3((i - 0.5) * 2.0, 0, 0)

func request_replay() -> void:
	armed = true

func replay() -> void:
	for panel in panels:
		remove_child(panel)
		panel.queue_free()
	panels.clear()
	results.clear()
	for i in CASES.size():
		var panel := SamplePanel.new()
		for index in panel.pins:
			panel.set_point_pinned(index, false)
		panel.pins.clear()
		panel.position = bay(i) + Vector3(0, 2.1, 0)
		panel.rotation.z = PI * 0.5
		panel.damping_coefficient = CASES[i].damping
		add_child(panel)
		panels.append(panel)
	elapsed = 0.0
	running = true
	armed = false
	status = "Fresh drop"

func _physics_process(delta: float) -> void:
	var hand_inside := false
	for i in points.size():
		if points[i].held():
			hand_inside = true
		else:
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, bay(i) + CONTACT)
	if hand_inside:
		running = false
		results.clear()
		status = "Hand changes the experiment"
	elif armed:
		replay()
	elif running:
		elapsed += delta
		if elapsed >= SAMPLE_TIME:
			for panel in panels:
				results.append(height_span(panel))
			running = false
			status = "Sample kept; bodies continue"
	for i in captions.size():
		var reading := "height --"
		if results.size() == CASES.size():
			reading = "height %.3f m" % results[i]
		captions[i].text = "%s | damping %.2f\n%s | t %.2f s\n%s\n1 or grip / trigger / release: replay" % [CASES[i].name, CASES[i].damping, reading, elapsed, status]

func height_span(panel: SoftBody3D) -> float:
	var low := INF
	var high := -INF
	for i in panel.rest_points.size():
		var y := to_local(panel.get_point_transform(i)).y
		low = minf(low, y)
		high = maxf(high, y)
	return high - low

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		request_replay()
