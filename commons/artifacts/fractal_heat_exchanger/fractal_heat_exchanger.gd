extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalHeatExchanger

## @identity
## name: "Fractal antennas & structures"
## tier: medium
## lineage: a space-filling fin tree — the lung's trick, run in copper.
## essence: A bench heat-exchanger whose pipes branch and branch until the surface
##   almost fills the volume. A hot-to-cool gradient runs from the trunk out to the
##   finest tips: the deeper the recursion, the more area touches the air, the more
##   heat leaves. All surface, almost no solid.
## truth: "a fractal is how you put infinite surface in a finite box"
## applications: infinite edge in finite room — branching maximises area-to-volume,
##   the same move a radiator, a lung and a river delta all make.

@export var depth: int = 4
@export var trunk_len: float = 0.16
@export var trunk_radius: float = 0.028
@export var split: int = 2
@export var hot_col: Color = Color(0.95, 0.32, 0.14)
@export var cool_col: Color = Color(0.30, 0.58, 0.92)
@export var bench_col: Color = Color(0.30, 0.32, 0.34)
@export var label_col: Color = Color(0.95, 0.66, 0.40)

var _t: float = 0.0
var _tree_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 5)
	if config.has("split"):
		split = clampi(int(config["split"]), 2, 3)
	if config.has("hot_col"):
		hot_col = _parse_color(config["hot_col"], hot_col)
	if config.has("cool_col"):
		cool_col = _parse_color(config["cool_col"], cool_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tree_root = null
	_build()


func _build() -> void:
	# --- bench base ---------------------------------------------------------
	var top_y: float = 0.85
	var top_mat: StandardMaterial3D = _matte_mat(bench_col, 0.6, 0.1)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.55), top_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.22, 0.23, 0.25))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.07, top_y, leg_mat))
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), 0.22, 0.04, leg_mat))

	# a hot manifold block the trunk rises out of
	add_child(_box(Vector3(0.0, top_y + 0.12, 0.0), Vector3(0.26, 0.08, 0.26), _glow_mat(hot_col, 1.4)))

	# --- the branching exchanger -------------------------------------------
	var root := Node3D.new()
	root.name = "ExchangerTree"
	root.position = Vector3(0.0, top_y + 0.16, 0.0)
	add_child(root)
	_tree_root = root

	# grow upward, splitting; colour by recursion depth (hot trunk -> cool tips)
	_branch(root, Vector3(0.0, 0.0, 0.0), Vector3.UP, trunk_len, trunk_radius, depth, 0)

	add_child(_billboard_label("ALL SURFACE, NO VOLUME", Vector3(0.0, 1.6, 0.0), 18, label_col))


func _branch(parent: Node3D, base: Vector3, dir: Vector3, length: float, radius: float, d: int, level: int) -> void:
	var tip: Vector3 = base + dir.normalized() * length
	# colour: 0 at trunk (hot) -> 1 at finest tips (cool)
	var t: float = float(level) / float(max(depth, 1))
	var pipe_col: Color = hot_col.lerp(cool_col, t)
	var pipe_mat: StandardMaterial3D = _glow_mat(pipe_col, 1.0)
	parent.add_child(_cylinder_between(base, tip, radius, pipe_mat))

	# fins: thin plates straddling the pipe to read as a finned exchanger
	if level >= 1:
		var fin_mat: StandardMaterial3D = _matte_mat(pipe_col, 0.4, 0.3)
		var mid: Vector3 = (base + tip) * 0.5
		var fw: float = length * 0.5
		parent.add_child(_box(mid, Vector3(fw, length * 0.5, 0.004), fin_mat))
		parent.add_child(_box(mid, Vector3(0.004, length * 0.5, fw), fin_mat))

	if d <= 1:
		# cooled tip nub
		parent.add_child(_sphere(tip, radius * 1.4, _glow_mat(cool_col, 1.6)))
		return

	# split into `split` children, fanned around the parent direction
	var ref: Vector3 = Vector3.RIGHT if absf(dir.normalized().dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var perp: Vector3 = dir.cross(ref).normalized()
	var spread: float = deg_to_rad(38.0)
	for i in range(split):
		var ang_about: float = TAU * float(i) / float(split)
		var axis: Vector3 = perp.rotated(dir.normalized(), ang_about)
		var child_dir: Vector3 = dir.normalized().rotated(axis, spread)
		_branch(parent, tip, child_dir, length * 0.72, radius * 0.66, d - 1, level + 1)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _tree_root != null:
		_tree_root.rotation.y = sin(_t * 0.4) * 0.06
