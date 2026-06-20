extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RecursiveTreeBench

## @identity
## name: "Recursive trees"
## tier: medium
## lineage: the binary tree as a real tree — split, rotate, recurse. The oldest
##   picture of recursion: a trunk that is nothing but two smaller trees joined at
##   the root.
## essence: A trunk forks into two branches, and each branch is itself a whole smaller
##   tree forking again, six times down. The rule never mentions leaves or canopy — it
##   only says "to grow a tree, grow two smaller trees rotated apart." Everything else
##   (the crown, the silhouette, the gradient from bark to bud) falls out of repeating
##   that one split. The part is the whole, scaled.
## truth: "a trunk that is two smaller trees"
## applications: branching from one rule — split-and-recurse fills space with structure
##   no one drew, the canonical shape of every recursive subdivision.

@export var depth: int = 6
@export var trunk_len: float = 0.26
@export var branch_angle: float = 26.0
@export var shrink: float = 0.74
@export var bark_col: Color = Color(0.46, 0.30, 0.16)
@export var bud_col: Color = Color(0.40, 0.82, 0.34)
@export var bench_col: Color = Color(0.16, 0.18, 0.22)
@export var label_col: Color = Color(0.86, 0.94, 0.7)

var _t: float = 0.0
var _crown_root: Node3D = null

# accumulators for the branch lattice
var _seg_a: Array[Vector3] = []
var _seg_b: Array[Vector3] = []
var _seg_r: Array[float] = []
var _seg_c: Array[Color] = []
var _buds: Array[Vector3] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 7)
	if config.has("branch_angle"):
		branch_angle = float(config["branch_angle"])
	if config.has("shrink"):
		shrink = clampf(float(config["shrink"]), 0.5, 0.9)
	if config.has("bark_col"):
		bark_col = _parse_color(config["bark_col"], bark_col)
	if config.has("bud_col"):
		bud_col = _parse_color(config["bud_col"], bud_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_crown_root = null
	_build()


func _build() -> void:
	# Bench base.
	var top_y: float = 0.85
	var bench_mat: StandardMaterial3D = _matte_mat(bench_col, 0.7, 0.2)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.7), bench_mat))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.12, top_y, _steel_mat(bench_col.lightened(0.1))))

	# Crown root so we can sway the whole tree.
	var root := Node3D.new()
	root.name = "TreeSway"
	root.position = Vector3(0.0, top_y + 0.1, 0.0)
	add_child(root)
	_crown_root = root

	_seg_a.clear()
	_seg_b.clear()
	_seg_r.clear()
	_seg_c.clear()
	_buds.clear()

	# Grow from the bench top, straight up.
	_grow(Vector3.ZERO, Vector3.UP, trunk_len, depth)

	# Flush branch segments into one MultiMesh.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	mm.mesh = cyl
	mm.instance_count = _seg_a.size()
	for i in range(_seg_a.size()):
		var a: Vector3 = _seg_a[i]
		var b: Vector3 = _seg_b[i]
		var rr: float = _seg_r[i]
		var length: float = maxf(a.distance_to(b), 0.001)
		var basis: Basis = _basis_y_to(b - a).scaled(Vector3(rr, length, rr))
		mm.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
		mm.set_instance_color(i, _seg_c[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "BranchLattice"
	mi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.vertex_color_use_as_albedo = true
	bmat.roughness = 0.8
	bmat.emission_enabled = true
	bmat.emission = Color.WHITE
	bmat.emission_energy_multiplier = 0.12 if emissive else 0.0
	mi.material_override = bmat
	root.add_child(mi)

	# Buds at the tips as one MultiMesh of small spheres.
	if not _buds.is_empty():
		var bm := MultiMesh.new()
		bm.transform_format = MultiMesh.TRANSFORM_3D
		bm.use_colors = true
		bm.mesh = SphereMesh.new()
		bm.instance_count = _buds.size()
		for i in range(_buds.size()):
			var s: float = 0.018
			bm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), _buds[i]))
			bm.set_instance_color(i, bud_col)
		var bmi := MultiMeshInstance3D.new()
		bmi.name = "Buds"
		bmi.multimesh = bm
		var budmat := StandardMaterial3D.new()
		budmat.vertex_color_use_as_albedo = true
		budmat.emission_enabled = true
		budmat.emission = Color.WHITE
		budmat.emission_energy_multiplier = 0.6 if emissive else 0.0
		bmi.material_override = budmat
		root.add_child(bmi)

	add_child(_billboard_label("A TRUNK THAT IS TWO SMALLER TREES", Vector3(0.0, top_y + 1.05, 0.0), 22, label_col))


# To grow a tree: draw the trunk, then grow two smaller trees rotated apart from
# its top. Base case at d<=1 leaves a bud. This IS the whole definition.
func _grow(base: Vector3, dir: Vector3, length: float, d: int) -> void:
	var top: Vector3 = base + dir.normalized() * length
	var t: float = clampf(float(depth - d) / float(maxi(depth - 1, 1)), 0.0, 1.0)
	var col: Color = bark_col.lerp(bud_col, t)
	var radius: float = 0.012 * pow(shrink, float(depth - d)) + 0.002
	_seg_a.append(base)
	_seg_b.append(top)
	_seg_r.append(radius)
	_seg_c.append(col)

	if d <= 1:
		_buds.append(top)
		return

	# Two children: split-and-rotate. Branch in the plane defined by an axis that
	# precesses with depth so the crown fills 3D rather than staying flat.
	var ang: float = deg_to_rad(branch_angle)
	var ref: Vector3 = Vector3.FORWARD if absf(dir.normalized().dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var axis: Vector3 = ref.cross(dir).normalized()
	# precess the bending axis a little each level for a fuller tree
	axis = axis.rotated(dir.normalized(), float(depth - d) * 0.6)
	var left_dir: Vector3 = dir.normalized().rotated(axis, ang)
	var right_dir: Vector3 = dir.normalized().rotated(axis, -ang)
	var child_len: float = length * shrink
	_grow(top, left_dir, child_len, d - 1)
	_grow(top, right_dir, child_len, d - 1)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _crown_root != null:
		_crown_root.rotation.z = sin(_t * 0.6) * 0.03
		_crown_root.rotation.y = _t * 0.12
