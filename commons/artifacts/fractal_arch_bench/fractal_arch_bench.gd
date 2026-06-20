extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalArchBench

## @identity
## name: "Fractal architecture"
## tier: medium
## lineage: a Roman aqueduct's logic on a workbench — the great span carried by
##   arches, and each arch carried by smaller arches, all the way down.
## essence: One load-bearing arch built entirely out of smaller arches. The big
##   span never touches the ground directly; it stands on two half-arches, which
##   stand on quarter-arches. The same curve at every scale holds the same weight
##   with less stone each level — span the most with the least.
## truth: "span the most with the least — an arch of arches"
## applications: recursive vaulting — a single arch rule, repeated at shrinking
##   scale, fills a span with structure that is mostly air.

@export var depth: int = 4
@export var span: float = 0.74
@export var rise: float = 0.62
@export var stone_col: Color = Color(0.74, 0.69, 0.56)
@export var bench_col: Color = Color(0.16, 0.18, 0.22)
@export var label_col: Color = Color(0.95, 0.88, 0.62)

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
	if config.has("span"):
		span = float(config["span"])
	if config.has("rise"):
		rise = float(config["rise"])
	if config.has("stone_col"):
		stone_col = _parse_color(config["stone_col"], stone_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway_root = null
	_build()


func _build() -> void:
	# Bench base.
	var top_y: float = 0.85
	var bench_mat: StandardMaterial3D = _matte_mat(bench_col, 0.7, 0.2)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.7), bench_mat))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.12, top_y, _steel_mat(bench_col.lightened(0.1))))

	# Sway root holds the recursive arch, springing from the bench top.
	var root := Node3D.new()
	root.name = "ArchSway"
	root.position = Vector3(0.0, top_y + 0.1, 0.0)
	add_child(root)
	_sway_root = root

	var stone_mat: StandardMaterial3D = _matte_mat(stone_col, 0.85, 0.0)

	# Master semicircular arch standing on the bench.
	_arch(root, Vector3(-span * 0.5, 0.0, 0.0), Vector3(span * 0.5, 0.0, 0.0), rise, depth, stone_mat)

	# Keystone glow at the crown of the master arch.
	root.add_child(_sphere(Vector3(0.0, rise, 0.0), 0.02, _glow_mat(label_col, 1.8)))

	add_child(_billboard_label("SPAN THE MOST WITH THE LEAST", Vector3(0.0, top_y + rise + 0.35, 0.0), 22, label_col))


# A semicircular arch from foot `a` to foot `b` rising to `h` at its crown.
# Recursion: the area under the arch is spanned by two smaller arches that
# spring from the same feet toward the centre, then those split again.
func _arch(parent: Node3D, a: Vector3, b: Vector3, h: float, d: int, mat: Material) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var half_w: float = (b - a).length() * 0.5
	var r: float = 0.012 * (1.0 + 0.5 * float(d))

	# Trace the semicircle as a polyline of short cylinders.
	var segs: int = 9
	var prev: Vector3 = a
	for i in range(1, segs + 1):
		var u: float = float(i) / float(segs)
		var ang: float = PI * (1.0 - u)  # PI at a, 0 at b
		var x: float = mid.x + cos(ang) * half_w
		var y: float = mid.y + sin(ang) * h
		var cur: Vector3 = Vector3(x, y, mid.z)
		parent.add_child(_cylinder_between(prev, cur, r, mat))
		prev = cur

	# Short jamb stubs grounding the feet.
	parent.add_child(_cylinder_between(a, a + Vector3(0.0, -0.05 - 0.04 * float(d), 0.0), r, mat))
	parent.add_child(_cylinder_between(b, b + Vector3(0.0, -0.05 - 0.04 * float(d), 0.0), r, mat))

	if d <= 1:
		return

	# Two child arches springing from the feet toward the centre, each half-width.
	var child_h: float = h * 0.5
	_arch(parent, a, mid, child_h, d - 1, mat)
	_arch(parent, mid, b, child_h, d - 1, mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sway_root != null:
		_sway_root.rotation.y = sin(_t * 0.4) * 0.06
