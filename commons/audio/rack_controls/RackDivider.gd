# RackDivider.gd
# Canonical 2D visual separator — thin vertical or horizontal line.
# Draws: accent-colored line with faded edges.

extends RackControlBase
class_name RackDivider

## Orientation
@export_enum("vertical", "horizontal") var orientation: String = "vertical"


func _init() -> void:
	_control_type = "divider"


func _get_canonical_size() -> Vector2:
	var base := RackDesignTokens.get_size_px("divider")
	if orientation == "horizontal":
		return Vector2(base.y, base.x)  # Swap w/h
	return base


func _draw_background() -> void:
	# Dividers have no background fill — transparent
	pass


func _draw_control() -> void:
	var thickness := RackDesignTokens.get_layout("divider_thickness_px", 2.0)
	var line_color := RackDesignTokens.get_color("panel_medium")
	var fade_color := Color(line_color, 0.15)

	if orientation == "vertical":
		var cx := size.x / 2.0
		var margin := 8.0
		# Main line
		draw_line(
			Vector2(cx, margin),
			Vector2(cx, size.y - margin),
			line_color, thickness
		)
		# Faded caps
		draw_line(Vector2(cx, 0), Vector2(cx, margin), fade_color, thickness)
		draw_line(Vector2(cx, size.y - margin), Vector2(cx, size.y), fade_color, thickness)
	else:
		var cy := size.y / 2.0
		var margin := 8.0
		draw_line(
			Vector2(margin, cy),
			Vector2(size.x - margin, cy),
			line_color, thickness
		)
		draw_line(Vector2(0, cy), Vector2(margin, cy), fade_color, thickness)
		draw_line(Vector2(size.x - margin, cy), Vector2(size.x, cy), fade_color, thickness)


func _draw_label() -> void:
	# Dividers have no label
	pass
