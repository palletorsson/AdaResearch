extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RecursionBench

## @identity
## name: "Recursion (calls itself)"
## tier: medium
## lineage: a set of Russian nesting dolls drawn as light — a rule that, to finish,
##   first calls a smaller copy of itself, and so on until the base case.
## essence: Circles within circles within circles. Each ring is the same rule applied
##   at a smaller radius, offset slightly so the depth is legible: ring N is drawn only
##   after ring N+1 returns. The recursion is the object — a definition that contains a
##   shrunken copy of the very thing being defined. The innermost ring is the base case
##   that finally answers.
## truth: "a rule that contains itself — to draw the circle, first draw the smaller one"
## applications: self-reference made visible — one function, called inside its own body,
##   builds a whole nested family from a single base case.

@export var depth: int = 6
@export var outer_radius: float = 0.34
@export var shrink: float = 0.74
@export var ring_col_in: Color = Color(0.34, 0.78, 0.92)
@export var ring_col_out: Color = Color(0.92, 0.42, 0.74)
@export var bench_col: Color = Color(0.16, 0.18, 0.22)
@export var label_col: Color = Color(0.9, 0.92, 0.98)

var _t: float = 0.0
var _stack_root: Node3D = null
var _rings: Array[MeshInstance3D] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 8)
	if config.has("outer_radius"):
		outer_radius = float(config["outer_radius"])
	if config.has("shrink"):
		shrink = clampf(float(config["shrink"]), 0.5, 0.9)
	if config.has("ring_col_in"):
		ring_col_in = _parse_color(config["ring_col_in"], ring_col_in)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_stack_root = null
	_rings.clear()
	_build()


func _build() -> void:
	# Bench base.
	var top_y: float = 0.85
	var bench_mat: StandardMaterial3D = _matte_mat(bench_col, 0.7, 0.2)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.7), bench_mat))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.12, top_y, _steel_mat(bench_col.lightened(0.1))))

	# Structure on top: a tower of nested rings, each higher and smaller.
	var root := Node3D.new()
	root.name = "RecursionStack"
	root.position = Vector3(0.0, top_y + 0.12, 0.0)
	add_child(root)
	_stack_root = root
	_rings.clear()

	_nest(root, outer_radius, 0)

	var label_y: float = top_y + 0.12 + float(depth) * (outer_radius * 0.18) + 0.3
	add_child(_billboard_label("A RULE THAT CONTAINS ITSELF", Vector3(0.0, maxf(label_y, top_y + 0.75), 0.0), 22, label_col))


# Recursion made literal: to place ring at depth `d`, first place the smaller ring
# at depth d+1 (the recursive call), then draw this ring on return. The stack height
# encodes how deep the call went; the innermost sphere is the base case.
func _nest(parent: Node3D, radius: float, d: int) -> void:
	if d >= depth or radius < 0.015:
		# Base case — a solid bead marking where the recursion bottomed out.
		var step_y: float = float(d) * (outer_radius * 0.18)
		parent.add_child(_sphere(Vector3(0.0, step_y, 0.0), maxf(radius * 0.8, 0.012), _glow_mat(ring_col_in, 2.4)))
		return

	# Recurse first (deeper, smaller) — the call happens before this ring is drawn.
	_nest(parent, radius * shrink, d + 1)

	# On return, draw this ring at its own height in the stack.
	var t: float = clampf(float(d) / float(maxi(depth - 1, 1)), 0.0, 1.0)
	var col: Color = ring_col_out.lerp(ring_col_in, t)
	var y: float = float(d) * (outer_radius * 0.18)
	var tube: float = clampf(radius * 0.08, 0.004, 0.03)
	var ring: MeshInstance3D = _torus(Vector3(0.0, y, 0.0), radius, tube, _glow_mat(col, 1.6))
	# Lay the torus flat (rings stacked like plates).
	ring.rotation.x = PI * 0.5
	parent.add_child(ring)
	_rings.append(ring)

	# A thin riser linking this ring to the one above keeps the stack reading as one call chain.
	if d > 0:
		var below_y: float = float(d - 1) * (outer_radius * 0.18)
		parent.add_child(_cylinder_between(Vector3(0.0, below_y, 0.0), Vector3(0.0, y, 0.0), 0.004, _steel_mat(col)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Slow spin of the whole stack + per-ring counter-rotation so depth reads.
	if _stack_root != null:
		_stack_root.rotation.y = _t * 0.3
	for i in range(_rings.size()):
		var r: MeshInstance3D = _rings[i]
		if r == null:
			continue
		r.rotation.z = sin(_t * 0.8 + float(i) * 0.5) * 0.18
