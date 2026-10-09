extends Node3D
## The budget's guest: a neck you cannot walk through, 0.96 m high, and above
## it what the frame it stands in costs. The numbers are the ones the Readout
## of budget.gd shows, moved here so that they come to your room with the neck.
## This folder goes to your room whole: the colours are written out.

const INK := Color("ffffff")     # the look's INK and SHADE, written out
const SHADE := Color("0d0620")

func _ready() -> void:
	$Meter.modulate = INK
	$Meter.outline_modulate = SHADE
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)

func _process(_delta: float) -> void:
	var drawing := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	$Meter.text = "%d fps, %.2f ms of drawing\n%d triangles, %d draw calls\nthis neck: %d triangles" % [
		Performance.get_monitor(Performance.TIME_FPS), drawing,
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		$Neck.triangles()]
