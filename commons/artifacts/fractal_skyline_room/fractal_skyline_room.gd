extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalSkylineRoom

## @identity
## name: "Fractal architecture"
## tier: large
## lineage: Eiffel's tower read as a fractal — a girder is a lattice of smaller
##   girders, and the whole skyline of spires is the same branching repeated across
##   a city block.
## essence: A room-scale fractal skyline. Several towers, and every tower is a strut
##   that branches into smaller struts that branch again — the Eiffel trick where the
##   iron looks solid but is mostly self-similar lattice. Step back and the city is one
##   spire; step in and the spire is a city. Self-similar structure carries the load
##   and the eye at once.
## truth: "self-similar structure — a girder made of girders, a city made of spires"
## applications: lattice that is mostly air — recurse a branching strut and the same
##   rule builds a tower light enough to stand and tall enough to see.

@export var depth: int = 4
@export var tower_count: int = 5
@export var base_height: float = 2.8
@export var floor_size: float = 7.0
@export var iron_col: Color = Color(0.62, 0.40, 0.26)
@export var spire_col: Color = Color(0.86, 0.62, 0.34)
@export var floor_col: Color = Color(0.10, 0.11, 0.14)
@export var label_col: Color = Color(0.96, 0.84, 0.56)

var _t: float = 0.0
var _spires: Array[MeshInstance3D] = []

# accumulators while recursing — flushed into a MultiMesh
var _strut_a: Array[Vector3] = []
var _strut_b: Array[Vector3] = []
var _strut_r: Array[float] = []
var _strut_c: Array[Color] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("tower_count"):
		tower_count = clampi(int(config["tower_count"]), 1, 9)
	if config.has("base_height"):
		base_height = float(config["base_height"])
	if config.has("iron_col"):
		iron_col = _parse_color(config["iron_col"], iron_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_spires.clear()
	_build()


func _build() -> void:
	# Room floor.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), _matte_mat(floor_col, 0.9, 0.1)))
	# faint plinth grid under each tower
	var plinth_mat: StandardMaterial3D = _matte_mat(floor_col.lightened(0.12), 0.8, 0.2)

	_strut_a.clear()
	_strut_b.clear()
	_strut_r.clear()
	_strut_c.clear()
	_spires.clear()

	# Lay the towers out on a loose ring + one tall centre spire.
	var positions: Array[Vector3] = []
	positions.append(Vector3.ZERO)
	var ring: int = max(tower_count - 1, 0)
	for i in range(ring):
		var ang: float = TAU * float(i) / float(max(ring, 1))
		var rad: float = floor_size * 0.30
		positions.append(Vector3(cos(ang) * rad, 0.0, sin(ang) * rad))

	for idx in range(positions.size()):
		var p: Vector3 = positions[idx]
		var is_centre: bool = idx == 0
		var h: float = base_height * (1.25 if is_centre else _rng.randf_range(0.7, 1.0))
		add_child(_box(p + Vector3(0.0, 0.05, 0.0), Vector3(0.7, 0.1, 0.7), plinth_mat))
		_branch(p, Vector3.UP, h, h * 0.06, depth, is_centre)

	# Flush all recursive struts into a single MultiMesh.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 1.0
	mm.mesh = cyl
	mm.instance_count = _strut_a.size()
	for i in range(_strut_a.size()):
		var a: Vector3 = _strut_a[i]
		var b: Vector3 = _strut_b[i]
		var rr: float = _strut_r[i]
		var length: float = maxf(a.distance_to(b), 0.001)
		var basis: Basis = _basis_y_to(b - a)
		basis = basis.scaled(Vector3(rr, length, rr))
		mm.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
		mm.set_instance_color(i, _strut_c[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "TowerLattice"
	mi.multimesh = mm
	var lat_mat := StandardMaterial3D.new()
	lat_mat.vertex_color_use_as_albedo = true
	lat_mat.metallic = 0.5
	lat_mat.roughness = 0.45
	lat_mat.emission_enabled = true
	lat_mat.emission = Color.WHITE
	lat_mat.emission_energy_multiplier = 0.14 if emissive else 0.0
	mi.material_override = lat_mat
	add_child(mi)

	# Overhead label.
	add_child(_billboard_label("SELF-SIMILAR STRUCTURE", Vector3(0.0, 3.6, 0.0), 40, label_col))


# A branching strut: draw this trunk, then fork into smaller struts that splay
# outward and keep branching to a capped depth. Tips get a glowing spire sphere.
func _branch(base: Vector3, dir: Vector3, length: float, radius: float, d: int, centre: bool) -> void:
	var top: Vector3 = base + dir.normalized() * length
	var t: float = clampf(float(depth - d) / float(maxi(depth - 1, 1)), 0.0, 1.0)
	var col: Color = iron_col.lerp(spire_col, t)
	_strut_a.append(base)
	_strut_b.append(top)
	_strut_r.append(radius)
	_strut_c.append(col)

	if d <= 1:
		# Spire cap — a small glowing node, collected as a real mesh so it can twinkle.
		var s: MeshInstance3D = _sphere(top, maxf(radius * 1.8, 0.02), _glow_mat(spire_col, 2.2))
		add_child(s)
		_spires.append(s)
		return

	# Fork into 3 child struts (centre tower forks tighter/taller).
	var forks: int = 3
	var splay: float = 0.5 if centre else 0.7
	var child_len: float = length * 0.62
	var child_rad: float = radius * 0.62
	var ref: Vector3 = Vector3.RIGHT if absf(dir.normalized().dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var side: Vector3 = ref.cross(dir).normalized()
	for i in range(forks):
		var ang: float = TAU * float(i) / float(forks)
		var lean: Vector3 = (side.rotated(dir.normalized(), ang)) * sin(splay)
		var child_dir: Vector3 = (dir.normalized() * cos(splay) + lean).normalized()
		_branch(top, child_dir, child_len, child_rad, d - 1, centre)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Twinkle the spires.
	for i in range(_spires.size()):
		var s: MeshInstance3D = _spires[i]
		if s == null:
			continue
		var pulse: float = 0.85 + 0.25 * sin(_t * 1.6 + float(i) * 0.7)
		s.scale = Vector3.ONE * pulse
