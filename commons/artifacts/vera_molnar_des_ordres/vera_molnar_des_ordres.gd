extends Node3D
class_name VeraMolnarDesOrdres

# @identity
# essence: an off-white canvas of near-black squares whose deviation from the orthogonal grows outward from the centre, with a slider on the rail below that drives the maximum deviation from zero to twenty-five degrees and regenerates the whole field on every millimetre of travel
# desire: to hand a viewer the knob Molnár held — order and disorder as one continuous axis rather than two named styles, so nobody has to be told where the interesting region is
# critical_parameter: max_rotation, in degrees; at 0 the field is a perfect lattice, at ~4 it reads as a printing fault, at ~12 it becomes a composition, past ~20 the grid stops being recoverable by eye
# triggers: slider_moved fires on the horizontal slider, get_normalized_value() scales max_rotation, and _generate_composition() rebuilds every square in place from _calculate_rotation(col, row, index) — the (Dés)Ordres rule, disorder proportional to distance from centre times a positional pseudo-random sign
# emerges: the transition itself, which no still frame of Molnár's series contains — the moment a viewer finds the value where the square stops being square and starts being a mark
# needs: slider_horizontal.tscn [present, commons/interactables]; QuadMesh squares with unshaded cull-disabled materials [Godot built-ins]; the composition math of rotation_match_puzzle.gd, ported not re-derived
# relationships: the continuous twin of sol_lewitt_wall_drawing in the artmathematics room — LeWitt varies the drafter, Molnár varies the parameter, and both refuse the single authoritative picture
# truth: Molnár did not add randomness to a grid. She subtracted certainty from it by degrees, and the work is the derivative — how fast order is lost, not how much disorder is present.

## Vera Molnár, (Dés)Ordres. A grid of squares with controlled rotation
## disorder, standing as a canvas, with a VR slider that drives the maximum
## deviation continuously from an orthogonal lattice into des ordres.
##
## The composition math is ported from commons/primitives/puzzles/
## rotation_match_puzzle.gd — same _calculate_rotation, same palette, same
## rect construction — so the two objects agree about what a Molnár is.

@export_group("Canvas")
@export var grid_size: Vector2i = Vector2i(8, 6)
@export var cell_size: float = 0.15
@export var rect_scale: float = 0.85          # square size relative to cell (< 1 leaves gutters)

@export_group("Style")
## 0 = (Dés)Ordres — disorder grows from the centre. 1 = Interruptions — mostly
## aligned, a few squares broken loose. 2 = Random. 3 = Gradient.
@export_enum("Desordres", "Interruptions", "Random", "Gradient") var style: int = 0
@export var max_rotation: float = 12.0        # degrees; the slider drives this

@export_group("Colors — Molnar palette")
@export var background_color: Color = Color(0.95, 0.95, 0.92, 1.0)
@export var rect_color: Color = Color(0.05, 0.05, 0.08, 1.0)

const SLIDER_SCENE := preload("res://commons/interactables/slider_horizontal.tscn")
const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"

## The slider's top end. 25 degrees is the value rotation_match_puzzle ships as
## its own maximum; keeping it means the two objects reach the same extreme.
const ROTATION_MAX: float = 25.0

## Canvas centre at 1.45 m puts a 1.05 m canvas between 0.93 and 1.98 — eye
## height for a standing adult. The rail sits at 0.82 so the slider is reachable
## without a reach-up and, more importantly, never stands in front of the field.
const CANVAS_Y: float = 1.45                  # canvas centre height, metres
const RAIL_Y: float = 0.82                    # slider height — reachable, and clear of the canvas

var _built := false
var _created: Array[Node] = []
var _rect_holder: Node3D = null
var _slider: Node = null
var _rect_mat: Material = null


func _ready() -> void:
	_build_all()
	_built = true


func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _build_all() -> void:
	_rect_mat = _flat_material(rect_color)
	_build_stand()
	_build_canvas()
	_generate_composition()
	_build_slider()
	_build_plate()


# --- the object -------------------------------------------------------------

func _build_stand() -> void:
	var w: float = _canvas_width() + 0.18
	var base := MeshInstance3D.new()
	base.name = "Base"
	var box := BoxMesh.new()
	box.size = Vector3(w, 0.06, 0.30)
	base.mesh = box
	base.position = Vector3(0.0, 0.03, 0.0)
	base.material_override = _grid_material(Color(0.28, 0.30, 0.35), Color(0.45, 0.50, 0.60), 0.5)
	_own(base)

	# The rail the slider sits on — a shallow shelf tipped toward the viewer.
	var rail := MeshInstance3D.new()
	rail.name = "Rail"
	var rbox := BoxMesh.new()
	rbox.size = Vector3(w * 0.55, 0.035, 0.20)
	rail.mesh = rbox
	rail.position = Vector3(0.0, RAIL_Y, 0.13)
	rail.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	rail.material_override = _grid_material(Color(0.24, 0.26, 0.31), Color(0.45, 0.50, 0.60), 0.4)
	_own(rail)

	# Two slim posts carrying the canvas above the rail.
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.02
		cyl.bottom_radius = 0.02
		cyl.height = CANVAS_Y
		post.mesh = cyl
		post.position = Vector3(float(sx) * (w * 0.5 - 0.07), CANVAS_Y * 0.5, 0.0)
		post.material_override = _grid_material(Color(0.24, 0.26, 0.31), Color(0.45, 0.50, 0.60), 0.4)
		_own(post)


func _canvas_width() -> float:
	return float(grid_size.x) * cell_size + cell_size


func _canvas_height() -> float:
	return float(grid_size.y) * cell_size + cell_size


## The canvas: an off-white plate standing upright, facing +Z. Squares live in a
## child holder one centimetre proud of it, in canvas-local x/y metres.
func _build_canvas() -> void:
	var w: float = _canvas_width()
	var h: float = _canvas_height()

	var holder := Node3D.new()
	holder.name = "Canvas"
	holder.position = Vector3(0.0, CANVAS_Y, 0.0)
	_own(holder)

	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + 0.05, h + 0.05, 0.04)
	frame.mesh = fbox
	frame.position = Vector3(0.0, 0.0, -0.025)
	frame.material_override = _grid_material(Color(0.26, 0.28, 0.33), Color(0.45, 0.50, 0.60), 0.4)
	holder.add_child(frame)

	var plate := MeshInstance3D.new()
	plate.name = "Ground"
	var pbox := BoxMesh.new()
	pbox.size = Vector3(w, h, 0.015)
	plate.mesh = pbox
	plate.material_override = _flat_material(background_color)
	holder.add_child(plate)

	_rect_holder = Node3D.new()
	_rect_holder.name = "Squares"
	_rect_holder.position = Vector3(0.0, 0.0, 0.010)
	holder.add_child(_rect_holder)


# --- the composition (ported from rotation_match_puzzle.gd) ------------------

## Lay every square. Called on build and again on every slider move; it frees
## only the squares, so the canvas, frame and slider survive a regeneration.
func _generate_composition() -> void:
	if _rect_holder == null or not is_instance_valid(_rect_holder):
		return
	for c in _rect_holder.get_children():
		_rect_holder.remove_child(c)
		c.queue_free()

	var index: int = 0
	for row in range(grid_size.y):
		for col in range(grid_size.x):
			var local_pos := Vector3(
				(float(col) - float(grid_size.x) / 2.0 + 0.5) * cell_size,
				(float(row) - float(grid_size.y) / 2.0 + 0.5) * cell_size,
				0.0
			)
			var rot: float = _calculate_rotation(col, row, index)
			_rect_holder.add_child(_create_rect_mesh(local_pos, rot))
			index += 1


## The rule. Ported verbatim from rotation_match_puzzle._calculate_rotation —
## the pseudo-randomness is positional, not sampled, so the same cell always
## deviates the same way and only the SCALE of the deviation moves under the
## slider. That is what makes the transition read as one composition losing its
## grip rather than as a new composition every frame.
func _calculate_rotation(col: int, row: int, index: int) -> float:
	match style:
		0:  # (Dés)Ordres — disorder increases with distance from centre
			var center_x: float = float(grid_size.x) / 2.0
			var center_y: float = float(grid_size.y) / 2.0
			var dist: float = sqrt(pow(float(col) - center_x, 2.0) + pow(float(row) - center_y, 2.0))
			var max_dist: float = sqrt(pow(center_x, 2.0) + pow(center_y, 2.0))
			var disorder: float = dist / max_dist if max_dist > 0.0 else 0.0
			var seed_val: int = (col * 7 + row * 13 + 42) % 100
			var dir: float = 1.0 if seed_val % 2 == 0 else -1.0
			var variance: float = (float(seed_val) / 100.0) * 0.5 + 0.5
			return disorder * max_rotation * dir * variance

		1:  # Interruptions — mostly aligned, a few broken loose
			var iseed: int = (col * 11 + row * 17 + 31) % 100
			if iseed < 15:
				var rot_seed: int = (col * 23 + row * 29) % 100
				return (float(rot_seed) / 100.0 - 0.5) * 2.0 * max_rotation
			return 0.0

		2:  # Random
			var rseed: int = (col * 37 + row * 41 + index * 53) % 1000
			return (float(rseed) / 1000.0 - 0.5) * 2.0 * max_rotation

		3:  # Gradient — rotation increases diagonally
			var span: int = grid_size.x + grid_size.y - 2
			var t: float = float(col + row) / float(span) if span > 0 else 0.0
			var g: float = lerp(-max_rotation, max_rotation, t)
			return g

	return 0.0


## One square, rotated in the canvas plane. The puzzle rotates about Y because
## its canvas lies flat and is tipped up whole; this canvas already stands, so
## the same deviation is a rotation about Z.
func _create_rect_mesh(pos: Vector3, rot: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	var s: float = cell_size * rect_scale
	quad.size = Vector2(s, s)
	mi.mesh = quad
	mi.material_override = _rect_mat
	mi.position = pos
	mi.rotation_degrees.z = rot
	return mi


# --- the knob ---------------------------------------------------------------

## The slider that is the whole point: 0 to 25 degrees of maximum deviation,
## regenerating in place. Configured AFTER add_child so the slider's _ready has
## run and its inner nodes exist — set_normalized_value on a slider that has not
## resolved its @onready handles silently does nothing.
func _build_slider() -> void:
	var sl: Node = SLIDER_SCENE.instantiate()
	if sl == null:
		return
	_slider = sl
	sl.name = "DisorderSlider"
	sl.position = Vector3(0.0, RAIL_Y + 0.03, 0.19)
	sl.rotation_degrees = Vector3(-14.0, 0.0, 0.0)
	sl.scale = Vector3(1.5, 1.5, 1.5)
	_own(sl)
	if sl.has_method("set_range"):
		sl.set_range(0.0, ROTATION_MAX)
	if sl.has_method("set_normalized_value"):
		sl.set_normalized_value(clampf(max_rotation / ROTATION_MAX, 0.0, 1.0))
	if sl.has_signal("slider_moved"):
		sl.connect("slider_moved", Callable(self, "_on_slider_moved"))


func _on_slider_moved(_value) -> void:
	if _slider == null or not is_instance_valid(_slider):
		return
	var norm: float = 0.0
	if _slider.has_method("get_normalized_value"):
		norm = clampf(_slider.get_normalized_value(), 0.0, 1.0)
	max_rotation = norm * ROTATION_MAX
	_generate_composition()


func _build_plate() -> void:
	var ts := TextScreenScript.new()
	ts.name = "Plate"
	ts.mode = 0                       # Mode.SCREEN — a framed panel on the base
	ts.width_m = 0.34
	ts.position = Vector3(_canvas_width() * 0.5 - 0.02, RAIL_Y + 0.06, 0.10)
	if ts.has_method("set_text"):
		ts.set_text("(DES)ORDRES", "max deviation, degrees.\norder is a setting.")
	_own(ts)


# --- materials --------------------------------------------------------------

## Unshaded and cull-disabled, as the puzzle has it — a Molnár is a print, not a
## lit surface, and the squares must read from behind the canvas too.
func _flat_material(c: Color) -> Material:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_rect_holder = null
	_slider = null
	_build_all()


## Grid config. Keys: "style", "grid_x", "grid_y"/"grid_z", "max_rot", "cell".
func apply_grid_config(config_data: Dictionary) -> void:
	var before_style: int = style
	var before_grid: Vector2i = grid_size
	var before_rot: float = max_rotation
	var before_cell: float = cell_size

	if config_data.has("style"):
		var s: String = str(config_data["style"]).to_lower()
		match s:
			"molnar", "desordres", "des_ordres", "0": style = 0
			"interruptions", "1": style = 1
			"random", "2": style = 2
			"gradient", "3": style = 3
	if config_data.has("grid_x"):
		grid_size.x = clampi(int(config_data["grid_x"]), 2, 24)
	if config_data.has("grid_y") or config_data.has("grid_z"):
		grid_size.y = clampi(int(config_data.get("grid_y", config_data.get("grid_z", grid_size.y))), 2, 24)
	if config_data.has("max_rot"):
		max_rotation = clampf(float(config_data["max_rot"]), 0.0, ROTATION_MAX)
	if config_data.has("cell"):
		cell_size = clampf(float(config_data["cell"]), 0.04, 0.4)

	if not _built:
		return
	if (style == before_style and grid_size == before_grid
			and is_equal_approx(max_rotation, before_rot) and is_equal_approx(cell_size, before_cell)):
		# Nothing about the composition changed — say nothing, touch nothing, so
		# a curation pass handing us unrelated keys does not throw its own framing away.
		return

	if grid_size == before_grid and is_equal_approx(cell_size, before_cell):
		# Only the rule or its amplitude moved: regenerate the squares, keep the
		# canvas and the slider (and the slider's handle position) as they are.
		_generate_composition()
		if _slider != null and is_instance_valid(_slider) and _slider.has_method("set_normalized_value"):
			_slider.set_normalized_value(clampf(max_rotation / ROTATION_MAX, 0.0, 1.0))
	else:
		_rebuild_now()
	print("[VeraMolnarDesOrdres] style=%d grid=%s max_rot=%.1f" % [style, str(grid_size), max_rotation])
