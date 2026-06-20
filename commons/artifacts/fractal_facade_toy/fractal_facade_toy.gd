extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalFacadeToy

## @identity
## name: "Fractal architecture"
## tier: small
## lineage: a Gothic cathedral front folded down to the palm — the rose window's
##   tracery, where every arch is a smaller copy of the wall that holds it.
## essence: A held recursive facade. One pointed arch is filled with two smaller
##   arches, and each of those is filled with two smaller still. The whole elevation
##   is in any one of its niches: span the most stone with the least rule. The mason
##   never drew the small arches — they fell out of repeating the big one.
## truth: "the whole is in the part — one arch contains the cathedral"
## applications: self-similar tracery — recurse a pointed arch and a single carving
##   rule fills a wall with windows at every scale.

@export var depth: int = 4
@export var width: float = 0.34
@export var height: float = 0.40
@export var bar_radius: float = 0.0045
@export var stone_col: Color = Color(0.78, 0.72, 0.58)
@export var glass_col: Color = Color(0.32, 0.52, 0.74)
@export var label_col: Color = Color(0.94, 0.88, 0.66)

var _t: float = 0.0
var _spin_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("width"):
		width = float(config["width"])
	if config.has("height"):
		height = float(config["height"])
	if config.has("stone_col"):
		stone_col = _parse_color(config["stone_col"], stone_col)
	if config.has("glass_col"):
		glass_col = _parse_color(config["glass_col"], glass_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_spin_root = null
	_build()


func _build() -> void:
	# Held toy — no table. A thin facade panel carved with recursive arches.
	var root := Node3D.new()
	root.name = "FacadeSpin"
	add_child(root)
	_spin_root = root

	var stone_mat: StandardMaterial3D = _matte_mat(stone_col, 0.85, 0.0)
	var glass_mat: StandardMaterial3D = _glass_mat(glass_col, 0.55)

	# Backing wall slab — the dielectric the tracery sits on.
	root.add_child(_box(Vector3(0.0, height * 0.5, -0.012), Vector3(width * 1.16, height * 1.12, 0.014), glass_mat))
	root.add_child(_box(Vector3(0.0, height * 0.5, -0.02), Vector3(width * 1.24, height * 1.2, 0.012), stone_mat))

	# Master pointed arch fills the panel.
	_arch(root, Vector3(0.0, 0.02, 0.0), width, height * 0.96, depth, stone_mat)

	# A little gable peak / finial above, so the silhouette reads as a facade.
	var peak: float = height + 0.03
	root.add_child(_cylinder_between(Vector3(-width * 0.5, height * 0.92, 0.0), Vector3(0.0, peak, 0.0), bar_radius * 1.4, stone_mat))
	root.add_child(_cylinder_between(Vector3(width * 0.5, height * 0.92, 0.0), Vector3(0.0, peak, 0.0), bar_radius * 1.4, stone_mat))
	root.add_child(_sphere(Vector3(0.0, peak, 0.0), bar_radius * 2.4, _glow_mat(label_col, 1.6)))

	add_child(_billboard_label("THE WHOLE IS IN THE PART", Vector3(0.0, peak + 0.05, 0.0), 18, label_col))


# A pointed (Gothic) arch: two jambs, a pointed head built of two arcs meeting at
# an apex. When depth allows, the bay is split into two half-width child arches.
func _arch(parent: Node3D, base: Vector3, w: float, h: float, d: int, mat: Material) -> void:
	var half: float = w * 0.5
	var left_foot: Vector3 = base + Vector3(-half, 0.0, 0.0)
	var right_foot: Vector3 = base + Vector3(half, 0.0, 0.0)
	var spring: float = h * 0.55  # height where the jambs end and the arc begins
	var apex: Vector3 = base + Vector3(0.0, h, 0.0)
	var left_spring: Vector3 = left_foot + Vector3(0.0, spring, 0.0)
	var right_spring: Vector3 = right_foot + Vector3(0.0, spring, 0.0)

	var r: float = bar_radius * (1.0 + 0.4 * float(d))  # thicker bars at the top level

	# vertical jambs
	parent.add_child(_cylinder_between(left_foot, left_spring, r, mat))
	parent.add_child(_cylinder_between(right_foot, right_spring, r, mat))

	# pointed head — sample each side as a shallow arc rising to the apex
	var segs: int = 5
	var prev_l: Vector3 = left_spring
	var prev_r: Vector3 = right_spring
	for i in range(1, segs + 1):
		var u: float = float(i) / float(segs)
		# bulge outward then converge: simple quadratic toward apex
		var lx: float = lerpf(left_spring.x, apex.x, u)
		var rx: float = lerpf(right_spring.x, apex.x, u)
		var ly: float = lerpf(spring, h, u) - sin(u * PI) * h * 0.06
		var cur_l: Vector3 = base + Vector3(lx, ly, 0.0)
		var cur_r: Vector3 = base + Vector3(rx, ly, 0.0)
		parent.add_child(_cylinder_between(prev_l, cur_l, r, mat))
		parent.add_child(_cylinder_between(prev_r, cur_r, r, mat))
		prev_l = cur_l
		prev_r = cur_r

	if d <= 1:
		return

	# Split the bay into two child arches sharing a central mullion.
	var child_w: float = w * 0.46
	var child_h: float = spring * 0.92
	var offset: float = w * 0.24
	_arch(parent, base + Vector3(-offset, 0.0, 0.001), child_w, child_h, d - 1, mat)
	_arch(parent, base + Vector3(offset, 0.0, 0.001), child_w, child_h, d - 1, mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _spin_root != null:
		_spin_root.rotation.y = sin(_t * 0.55) * 0.28
		_spin_root.rotation.x = cos(_t * 0.4) * 0.04
