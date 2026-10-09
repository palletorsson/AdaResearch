extends Node
var nail_color: Color = Color(1.0, 0.5, 0.7, 1.0)  # Default pink
var hand_color: Color = Color(0.8, 0.6, 0.5, 1.0)  # Default skin tone
signal nail_color_changed(new_color: Color)
signal hand_color_changed(new_color: Color)
func set_nail_color(color: Color) -> void:
	nail_color = color
	emit_signal("nail_color_changed", nail_color)


func get_nail_color() -> Color:
	return nail_color

# Hand color management
func set_hand_color(color: Color) -> void:
	hand_color = color
	emit_signal("hand_color_changed", hand_color)
	#if debug:
		#print("GameManager: Hand color set to %s" % color)

func get_hand_color() -> Color:
	return hand_color
