class_name ModularLabel
extends RefCounted
## Module: a label — the words of an association ("walk this line", "do not
## cross", a logic gate's name), as a Label3D in the project's caption style.


static func make(text: String, pixel_size: float = 0.005) -> Label3D:
	var l := Label3D.new()
	l.name = "label"
	l.text = text
	l.pixel_size = pixel_size
	l.font_size = 48
	l.outline_size = 6
	l.modulate = Color("2b1d14")
	l.outline_modulate = Color("f3ecdd")
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.no_depth_test = false
	l.set_meta("construction_mark", true)
	return l
