extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalTrussTower

## @identity
## name: "Fractal antennas & structures"
## tier: large
## lineage: a self-similar truss — Eiffel's gusset, recursed until it is its own scaffold.
## essence: A room-scale tower whose every strut is itself a little truss of thinner
##   struts. Strength lives in the bracing, not the bulk: subdivide a beam into a
##   frame and the frame holds more for less metal. Walk inside and you are inside a
##   beam that is made of beams.
## truth: "max strength, min material — a strut that is struts"
## applications: self-supporting structure — recurse the bracing and the same
##   skeleton spans further with less mass; the move every tall thing makes.

@export var depth: int = 3
@export var tower_height: float = 3.6
@export var base_width: float = 1.3
@export var floor_size: float = 7.0
@export var steel_col: Color = Color(0.62, 0.66, 0.72)
@export var brace_col: Color = Color(0.46, 0.52, 0.60)
@export var floor_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.80, 0.86, 0.94)

var _t: float = 0.0
var _sway_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("tower_height"):
		tower_height = float(config["tower_height"])
	if config.has("base_width"):
		base_width = float(config["base_width"])
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("steel_col"):
		steel_col = _parse_color(config["steel_col"], steel_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway_root = null
	_build()


func _build() -> void:
	# --- room floor ---------------------------------------------------------
	var floor_mat: StandardMaterial3D = _matte_mat(floor_col, 0.9, 0.1)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), floor_mat))

	# concrete footing pads at the four base corners
	var pad_mat: StandardMaterial3D = _matte_mat(Color(0.30, 0.30, 0.33), 1.0)
	var hw0: float = base_width * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			add_child(_box(Vector3(hw0 * sx, 0.04, hw0 * sz), Vector3(0.4, 0.1, 0.4), pad_mat))

	var root := Node3D.new()
	root.name = "TrussSway"
	add_child(root)
	_sway_root = root

	var steel_mat: StandardMaterial3D = _steel_mat(steel_col)
	var brace_mat: StandardMaterial3D = _steel_mat(brace_col)

	# A square section, tapering as it rises, built as a recursive braced prism.
	var top_w: float = base_width * 0.42
	_truss_segment(root, 0.0, tower_height, base_width, top_w, depth, steel_mat, brace_mat)

	# a small beacon mast on the apex
	var apex := Vector3(0.0, tower_height, 0.0)
	root.add_child(_cylinder(apex + Vector3(0.0, 0.18, 0.0), 0.02, 0.36, steel_mat))
	root.add_child(_sphere(apex + Vector3(0.0, 0.4, 0.0), 0.06, _glow_mat(Color(0.95, 0.45, 0.30), 2.4)))

	add_child(_billboard_label("MAX STRENGTH, MIN MATERIAL", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _truss_segment(parent: Node3D, y0: float, y1: float, w_bot: float, w_top: float, d: int, leg_mat: Material, brace_mat: Material) -> void:
	# Four corner legs of this section.
	var hb: float = w_bot * 0.5
	var ht: float = w_top * 0.5
	var corners_b: Array = [
		Vector3(-hb, y0, -hb), Vector3(hb, y0, -hb), Vector3(hb, y0, hb), Vector3(-hb, y0, hb)
	]
	var corners_t: Array = [
		Vector3(-ht, y1, -ht), Vector3(ht, y1, -ht), Vector3(ht, y1, ht), Vector3(-ht, y1, ht)
	]
	var leg_r: float = lerpf(0.05, 0.018, 1.0 - float(d) / float(max(depth, 1)))
	for i in range(4):
		parent.add_child(_cylinder_between(corners_b[i], corners_t[i], leg_r, leg_mat))

	if d <= 1:
		# Base case: X-bracing on each of the four faces — the strength is the bracing.
		var br: float = leg_r * 0.55
		for i in range(4):
			var j: int = (i + 1) % 4
			parent.add_child(_cylinder_between(corners_b[i], corners_t[j], br, brace_mat))
			parent.add_child(_cylinder_between(corners_b[j], corners_t[i], br, brace_mat))
			# horizontal tie at the top of the panel
			parent.add_child(_cylinder_between(corners_t[i], corners_t[j], br, brace_mat))
		return

	# Recurse: split this section into two stacked sub-sections, each a smaller truss.
	var ym: float = (y0 + y1) * 0.5
	var w_mid: float = (w_bot + w_top) * 0.5
	_truss_segment(parent, y0, ym, w_bot, w_mid, d - 1, leg_mat, brace_mat)
	_truss_segment(parent, ym, y1, w_mid, w_top, d - 1, leg_mat, brace_mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway_root != null:
		_sway_root.rotation.z = sin(_t * 0.5) * 0.006
		_sway_root.rotation.x = cos(_t * 0.4) * 0.005
