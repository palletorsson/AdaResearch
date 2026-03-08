# RackGroup.gd
# Canonical 2D group container — background panel with optional title.
# Draws: rounded border, darker inner area, title bar at top.

extends RackControlBase
class_name RackGroup

## Group title displayed at top
@export var group_title: String = "" : set = set_group_title


func _init() -> void:
	_control_type = "group"


func set_group_title(val: String) -> void:
	group_title = val
	queue_redraw()


func _draw_background() -> void:
	# Outer border
	var border_w := RackDesignTokens.get_layout("group_border_px", 2.0)
	var border_color := RackDesignTokens.get_color("panel_dark")
	draw_rect(Rect2(Vector2.ZERO, size), border_color)

	# Inner fill
	var inner_rect := Rect2(
		Vector2(border_w, border_w),
		size - Vector2(border_w * 2, border_w * 2)
	)
	draw_rect(inner_rect, _cell_bg)


func _draw_control() -> void:
	var border_w := RackDesignTokens.get_layout("group_border_px", 2.0)

	if not group_title.is_empty():
		# Title bar background
		var title_h := 22.0
		var title_rect := Rect2(
			Vector2(border_w, border_w),
			Vector2(size.x - border_w * 2, title_h)
		)
		draw_rect(title_rect, _track_groove)

		# Title text
		var font := get_theme_default_font()
		var fs := RackDesignTokens.get_font_size("label_font_size")
		var text_size := font.get_string_size(group_title, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var tx := (size.x - text_size.x) / 2.0
		var ty := border_w + title_h / 2.0 + text_size.y / 3.0
		draw_string(font, Vector2(tx, ty), group_title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)

	# Corner accents (small L-shapes at corners)
	var accent_len := 8.0
	var corner_color := Color(_accent, 0.4)
	# Top-left
	draw_line(Vector2(0, 0), Vector2(accent_len, 0), corner_color, 1.0)
	draw_line(Vector2(0, 0), Vector2(0, accent_len), corner_color, 1.0)
	# Top-right
	draw_line(Vector2(size.x, 0), Vector2(size.x - accent_len, 0), corner_color, 1.0)
	draw_line(Vector2(size.x, 0), Vector2(size.x, accent_len), corner_color, 1.0)
	# Bottom-left
	draw_line(Vector2(0, size.y), Vector2(accent_len, size.y), corner_color, 1.0)
	draw_line(Vector2(0, size.y), Vector2(0, size.y - accent_len), corner_color, 1.0)
	# Bottom-right
	draw_line(Vector2(size.x, size.y), Vector2(size.x - accent_len, size.y), corner_color, 1.0)
	draw_line(Vector2(size.x, size.y), Vector2(size.x, size.y - accent_len), corner_color, 1.0)


func _draw_label() -> void:
	# Groups use group_title instead of control_label
	pass
