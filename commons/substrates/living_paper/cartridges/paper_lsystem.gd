extends PaperAlgorithm
class_name PaperLSystem

## L-system turtle graphics — tree/fern/dragon growing stroke by stroke.

enum Preset { TREE, FERN, DRAGON }

var preset: Preset = Preset.TREE
var _w: int
var _h: int
var _commands: Array[Dictionary] = []  # Pre-computed [{pos, end_pos, color}]
var _current_cmd: int = 0
var _color: Color
var _cmds_per_step: int = 3

func _init(p: Preset = Preset.TREE) -> void:
	preset = p

func get_name() -> String:
	match preset:
		Preset.TREE: return "L-System Tree"
		Preset.FERN: return "Barnsley Fern"
		Preset.DRAGON: return "Dragon Curve"
	return "L-System"

func get_background_color() -> Color:
	return Color(0.02, 0.03, 0.02)

func get_primary_color() -> Color:
	match preset:
		Preset.TREE: return Color(0.3, 0.8, 0.2)
		Preset.FERN: return Color(0.1, 0.7, 0.3)
		Preset.DRAGON: return Color(1.0, 0.3, 0.4)
	return Color.WHITE

func get_initial_steps() -> int:
	return 20

func initialize(img: Image, width: int, height: int) -> void:
	_w = width
	_h = height
	_current_cmd = 0
	_color = get_primary_color()
	_commands.clear()

	match preset:
		Preset.TREE:
			_generate_tree()
		Preset.FERN:
			_generate_fern()
		Preset.DRAGON:
			_generate_dragon()

func step(img: Image, _step_index: int) -> bool:
	for i in range(_cmds_per_step):
		if _current_cmd >= _commands.size():
			return false
		var cmd = _commands[_current_cmd]
		draw_line(img, cmd["from"], cmd["to"], cmd["color"])
		_current_cmd += 1
	return _current_cmd < _commands.size()

# --- L-System generators ---

func _generate_tree() -> void:
	var axiom = "F"
	var rules = {"F": "FF+[+F-F-F]-[-F+F+F]"}
	var iterations = 3
	var angle_deg = 25.0
	var step_size = 2.5
	var start = Vector2(_w / 2.0, _h - 4)
	var start_angle = -90.0  # pointing up
	_turtle(axiom, rules, iterations, angle_deg, step_size, start, start_angle)

func _generate_fern() -> void:
	var axiom = "X"
	var rules = {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}
	var iterations = 4
	var angle_deg = 22.5
	var step_size = 1.5
	var start = Vector2(_w / 2.0, _h - 4)
	var start_angle = -90.0
	_turtle(axiom, rules, iterations, angle_deg, step_size, start, start_angle)

func _generate_dragon() -> void:
	var axiom = "FX"
	var rules = {"X": "X+YF+", "Y": "-FX-Y"}
	var iterations = 10
	var angle_deg = 90.0
	var step_size = 2.0
	var start = Vector2(_w * 0.4, _h * 0.5)
	var start_angle = 0.0
	_turtle(axiom, rules, iterations, angle_deg, step_size, start, start_angle)

func _turtle(axiom: String, rules: Dictionary, iterations: int,
			 angle_deg: float, step_size: float, start: Vector2, start_angle: float) -> void:
	# Expand string
	var current = axiom
	for i in range(iterations):
		var next = ""
		for ch in current:
			next += rules.get(ch, ch)
		current = next

	# Execute turtle
	var pos = start
	var angle = start_angle
	var stack: Array = []
	var depth = 0

	for ch in current:
		match ch:
			"F":
				var rad = deg_to_rad(angle)
				var end_pos = pos + Vector2(cos(rad), sin(rad)) * step_size
				# Color fades with depth
				var intensity = clampf(1.0 - float(depth) * 0.1, 0.3, 1.0)
				_commands.append({
					"from": Vector2i(int(pos.x), int(pos.y)),
					"to": Vector2i(int(end_pos.x), int(end_pos.y)),
					"color": _color * intensity
				})
				pos = end_pos
			"+":
				angle += angle_deg
			"-":
				angle -= angle_deg
			"[":
				stack.append({"pos": pos, "angle": angle, "depth": depth})
				depth += 1
			"]":
				if stack.size() > 0:
					var state = stack.pop_back()
					pos = state["pos"]
					angle = state["angle"]
					depth = state["depth"]
