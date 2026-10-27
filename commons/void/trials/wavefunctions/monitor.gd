extends "res://commons/artifacts/science_screen/science_screen.gd"
## Bind the original waveform receiver to the same named, editable pendulum.
var samples: Array[Vector2] = []
var elapsed: float = 0.0

func _connect_tracking_for_mode() -> void:
	_tracking_generic = get_parent().get_parent().get_node_or_null("pendulum/Artifact")
	if is_instance_valid(_tracking_generic):
		_source_artifact_name = "control_pendulum"

func _build_viewport() -> void:
	super._build_viewport()
	_viewport.remove_child(_canvas)
	_canvas.queue_free()
	_canvas = LiveCanvas.new()
	_canvas.instrument = self
	_canvas.size = Vector2(VP_WIDTH, VP_HEIGHT)
	_viewport.add_child(_canvas)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_tracking_generic): return
	elapsed += delta
	samples.append(Vector2(elapsed, _tracking_generic._angle))
	while not samples.is_empty() and samples[0].x < elapsed - 8.0: samples.pop_front()
	_canvas.queue_redraw()

class LiveCanvas extends Control:
	var instrument: Node3D
	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var ink := Color(.5, .95, 1)
		draw_rect(Rect2(Vector2.ZERO, size), Color(.015, .025, .04))
		draw_string(font, Vector2(26, 44), "PENDULUM / RECORDED ANGLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, ink)
		draw_string(font, Vector2(40, 73), "Vertical range: -pi/2 to +pi/2 radians", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
		var bounds := Rect2(40, 90, size.x - 80, size.y - 185)
		for i in 9:
			var x := bounds.position.x + bounds.size.x * i / 8.0
			draw_line(Vector2(x, bounds.position.y), Vector2(x, bounds.end.y), Color(.12,.2,.25))
		for i in 5:
			var y := bounds.position.y + bounds.size.y * i / 4.0
			draw_line(Vector2(bounds.position.x,y), Vector2(bounds.end.x,y), Color(.12,.2,.25))
		var previous := Vector2.ZERO
		for i in instrument.samples.size():
			var sample: Vector2 = instrument.samples[i]
			var point := Vector2(bounds.end.x - (instrument.elapsed - sample.x) / 8.0 * bounds.size.x, bounds.get_center().y - sample.y / (PI * .5) * bounds.size.y * .5)
			if i > 0: draw_line(previous, point, ink, 2.5)
			previous = point
		draw_string(font, Vector2(40, size.y - 65), "-8 s                         time                         NOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, ink)
		var driver: Node3D = instrument._tracking_generic
		var label := "NO PENDULUM INPUT"
		if is_instance_valid(driver): label = "ANGLE %+.2f rad    VELOCITY %+.2f rad/s" % [driver._angle, driver._angular_velocity]
		draw_string(font, Vector2(40, size.y - 26), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(1,.8,.45))
