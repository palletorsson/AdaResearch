extends Node3D
## The budget. A neck to walk through, a ring whose segments double, and on a
## line of text what the frame costs. Space doubles the ring.

const Look := preload("res://supplied/look.gd")
const Surfaces := preload("res://guests/budget/surfaces.gd")

var segments := 3     # the ring's sides, around its opening

func _ready() -> void:
	$Ring.material_override = Look.paint(Look.THIRD)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	show_ring()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		segments = segments * 2 if segments < 96 else 3
		show_ring()
	var drawing := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	$Readout.text = "%d fps    %.2f ms of drawing    %d triangles    %d draw calls" % [
		Performance.get_monitor(Performance.TIME_FPS), drawing,
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]

func show_ring() -> void:
	$Ring.mesh.rings = segments
	var gap := Surfaces.gap_to_circle(segments)
	print("ring: %d segments, %d triangles, %.2f%% short of the circle" % [segments, $Ring.mesh.get_faces().size() / 3, gap * 100.0])
