extends Control
class_name MetabolismHUD

## QFEP budget meter. Reads Performance monitors each frame and renders
## them as ms/frame bars. The frame budget (11.1ms@90Hz or 13.9ms@72Hz)
## is the ceiling — exceeding it means the runner will throttle the
## next map's LOD. This HUD is the body's metabolism, made visible.

@export var target_hz: float = 72.0      # Quest 2 default
@export var panel_width: float = 320.0
@export var panel_height: float = 140.0

var _frame_target_ms: float = 0.0

# Emitted when a sustained budget breach is detected. The SpineRunner
# listens and can drop next-map LOD in response.
signal budget_pressure(level: float)   # 0..1, 1 = over budget

var _pressure_accum: float = 0.0


func _ready() -> void:
	_frame_target_ms = 1000.0 / target_hz
	custom_minimum_size = Vector2(panel_width, panel_height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(12, 12)
	size = Vector2(panel_width, panel_height)


func _process(delta: float) -> void:
	queue_redraw()
	var gpu_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	# TIME_PROCESS is frame-total; we'll expose both process and physics.
	var norm: float = clampf(gpu_ms / _frame_target_ms, 0.0, 2.0)
	# Smooth pressure so transients don't cause LOD thrash
	_pressure_accum = lerpf(_pressure_accum, norm, 0.15)
	emit_signal("budget_pressure", _pressure_accum)


func _draw() -> void:
	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var proc_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phys_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: float = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objs: float = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)

	# Background panel
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.09, 0.82), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.42, 0.55, 0.6), false, 1.0)

	var font: Font = ThemeDB.fallback_font
	var fs := 12
	var y := 6.0
	var label_color := Color(0.78, 0.82, 0.9)
	var value_color := Color(0.95, 0.95, 1.0)

	draw_string(font, Vector2(10, y + 12), "METABOLISM  %.0f / %.0f Hz" % [fps, target_hz],
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs + 1, Color(0.92, 0.80, 0.45))
	y += 22

	_draw_bar(font, fs, Vector2(10, y), "proc", proc_ms, _frame_target_ms, label_color, value_color)
	y += 20
	_draw_bar(font, fs, Vector2(10, y), "phys", phys_ms, _frame_target_ms, label_color, value_color)
	y += 20

	var draw_norm: float = clampf(draw_calls / 200.0, 0.0, 1.3)
	_draw_bar_raw(font, fs, Vector2(10, y), "draw", "%.0f / 200" % draw_calls, draw_norm, label_color, value_color)
	y += 20

	_draw_bar_raw(font, fs, Vector2(10, y), "objs", "%.0f" % objs, clampf(objs / 4000.0, 0.0, 1.3), label_color, value_color)
	y += 20

	_draw_bar_raw(font, fs, Vector2(10, y), "mem ", "%.0f MB" % mem_mb, clampf(mem_mb / 800.0, 0.0, 1.3), label_color, value_color)


func _draw_bar(font: Font, fs: int, pos: Vector2, name: String, value_ms: float, max_ms: float, label_color: Color, value_color: Color) -> void:
	var norm: float = clampf(value_ms / max_ms, 0.0, 1.3)
	var text := "%.1f / %.1f ms" % [value_ms, max_ms]
	_draw_bar_raw(font, fs, pos, name, text, norm, label_color, value_color)


func _draw_bar_raw(font: Font, fs: int, pos: Vector2, name: String, text: String, norm: float, label_color: Color, value_color: Color) -> void:
	draw_string(font, pos + Vector2(0, 12), name, HORIZONTAL_ALIGNMENT_LEFT, 34, fs, label_color)
	var bar_rect := Rect2(pos + Vector2(42, 2), Vector2(170, 12))
	draw_rect(bar_rect, Color(0.14, 0.16, 0.20, 1.0), true)
	var fill_w: float = bar_rect.size.x * clampf(norm, 0.0, 1.0)
	var col: Color
	if norm < 0.6:      col = Color(0.35, 0.80, 0.45)
	elif norm < 0.9:    col = Color(0.85, 0.72, 0.30)
	else:               col = Color(0.92, 0.38, 0.35)
	draw_rect(Rect2(bar_rect.position, Vector2(fill_w, bar_rect.size.y)), col, true)
	if norm > 1.0:
		# Over-budget tick
		var over_x: float = bar_rect.position.x + bar_rect.size.x
		draw_line(Vector2(over_x, bar_rect.position.y - 2),
			Vector2(over_x, bar_rect.position.y + bar_rect.size.y + 2),
			Color(1.0, 0.4, 0.4), 2.0)
	draw_string(font, pos + Vector2(220, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, value_color)
