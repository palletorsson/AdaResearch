extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EnergyLandscapeBench

## @identity
## name: "Settling: gradient descent toward max Q"
## tier: medium
## lineage: the bowl, generalised to a wrinkled surface — many basins, each a possible rest
##   state; height is energy, so the low places are the stable ones.
## essence: A bench-top wavy landscape, ~0.6m, where height means energy. A soft body is
##   dropped onto the hills and rolls. It does not find the deepest valley on the map — only
##   the nearest one downhill from where it landed. The basin it ends in is its answer: a
##   local minimum, reached by following the slope, not by surveying the whole terrain.
## truth: "IT FINDS THE NEAREST VALLEY, NOT THE DEEPEST" — descent is local, not global
## applications: training, annealing, protein folding — landscapes with many rest states.
## axis: assay — what the apparatus does with a basin the body chose (see the ASSAY section).

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var grid: int = 22
@export var span: float = 0.62
@export var amp: float = 0.09
@export var blob_size: float = 0.14
@export var low_col: Color = Color(0.22, 0.30, 0.55)
@export var high_col: Color = Color(0.85, 0.55, 0.95)
@export var blob_col: Color = Color(0.95, 0.85, 0.40)
@export var base_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

## AXIS — WHAT THE APPARATUS DOES WITH A RESULT NOBODY SPECIFIED. Shared word for word
## across the soft-body bench family (see the ASSAY section at the foot of this file).
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

var _t: float = 0.0
var _sway: Node3D = null
var _sim = null
var _blob_mm: MultiMesh = null
var _blob_holder: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = clampi(int(config["grid"]), 10, 40)
	if config.has("span"):
		span = float(config["span"])
	if config.has("amp"):
		amp = clampf(float(config["amp"]), 0.03, 0.18)
	if config.has("blob_col"):
		blob_col = _parse_color(config["blob_col"], blob_col)
	if config.has("assay"):
		var _a: String = str(config["assay"]).strip_edges().to_lower()
		assay = _a if ASSAYS.has(_a) else assay
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sway = null
	_sim = null
	_blob_mm = null
	_blob_holder = null
	_build()


func _energy(x: float, z: float) -> float:
	# Wavy landscape — two sine ridges crossed; a few basins of varying depth.
	return amp * (sin(x * 9.0) * 0.6 + cos(z * 7.0) * 0.5 + sin((x + z) * 5.0) * 0.4)


func _landscape_mesh() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE
	mm.mesh = bm
	var count: int = grid * grid
	mm.instance_count = count
	var cell: float = span / float(grid)
	var idx: int = 0
	var lo: float = INF
	var hi: float = -INF
	# First pass for colour range.
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	for gz in range(grid):
		for gx in range(grid):
			var x: float = (float(gx) / float(grid - 1) - 0.5) * span
			var z: float = (float(gz) / float(grid - 1) - 0.5) * span
			var h: float = _energy(x, z)
			var col_t: float = (h - lo) / maxf(hi - lo, 1e-4)
			var xf := Transform3D(Basis().scaled(Vector3(cell * 0.95, 0.02, cell * 0.95)), Vector3(x, h, z))
			mm.set_instance_transform(idx, xf)
			mm.set_instance_color(idx, low_col.lerp(high_col, col_t))
			idx += 1
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _make_sim() -> void:
	# A small jelly dropped off-centre so it rolls into a nearby basin.
	var sim = SBShapes.make_jelly_grid(2, 2, 2, blob_size * 0.5, 0.7)
	sim.gravity = Vector3(0.0, -3.5, 0.0)
	sim.damping = 0.96
	sim.floor_y = -10.0
	# Offset it onto a slope.
	for i in sim.positions.size():
		sim.positions[i] += Vector3(span * 0.22, 0.2, -span * 0.18)
		sim.prev_positions[i] = sim.positions[i]
	_sim = sim


func _build() -> void:
	# Bench base + pillar
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(base_col, 0.85)))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.5, _steel_mat(Color(0.34, 0.36, 0.40))))

	var sway := Node3D.new()
	sway.name = "LandscapeSway"
	add_child(sway)
	_sway = sway

	# Landscape sits on top of the pillar.
	var land := _landscape_mesh()
	land.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(land)

	# Soft body as a live MultiMesh; constrained to ride the surface each frame.
	_make_sim()
	_blob_holder = Node3D.new()
	_blob_holder.position = Vector3(0.0, 0.86, 0.0)
	sway.add_child(_blob_holder)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = blob_size * 0.28
	sm.height = blob_size * 0.56
	mm.mesh = sm
	mm.instance_count = _sim.positions.size()
	_blob_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = blob_col
	bmat.roughness = 0.4
	bmat.emission_enabled = true
	bmat.emission = blob_col
	bmat.emission_energy_multiplier = 0.35 if emissive else 0.0
	mmi.material_override = bmat
	_blob_holder.add_child(mmi)
	_settle_blob_to_surface()
	_refresh_blob()

	add_child(_billboard_label("IT FINDS THE NEAREST VALLEY, NOT THE DEEPEST", Vector3(0.0, 1.6, 0.0), 22, label_col))

	# ASSAY apparatus, appended LAST so every child index and position above is untouched
	# on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


func _settle_blob_to_surface() -> void:
	# Pre-roll the blob so the snapshot already sits in a basin.
	for _i in 90:
		_constrain_to_surface()
		_sim.step()


func _constrain_to_surface() -> void:
	# Each particle cannot sink below the landscape height at its (x,z).
	for i in _sim.positions.size():
		var p: Vector3 = _sim.positions[i]
		var floor_h: float = _energy(p.x, p.z) + blob_size * 0.28
		if p.y < floor_h:
			_sim.positions[i].y = floor_h
			# Gentle downhill nudge so it slides toward lower energy (gradient).
			var gx: float = (_energy(p.x + 0.01, p.z) - _energy(p.x - 0.01, p.z)) / 0.02
			var gz: float = (_energy(p.x, p.z + 0.01) - _energy(p.x, p.z - 0.01)) / 0.02
			_sim.positions[i].x -= gx * 0.0008
			_sim.positions[i].z -= gz * 0.0008


func _refresh_blob() -> void:
	if _blob_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_blob_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim != null:
		_constrain_to_surface()
		_sim.step()
		_refresh_blob()
	if _sway != null:
		_sway.rotation.y = sin(_t * 0.3) * 0.12

# ── ASSAY ────────────────────────────────────────────────────────────────────────────────
# One axis, five values, shared word for word with mass_spring_bench, membrane_bench,
# rigidity_dial_bench, abject_bench, octopus_bench and becoming_bench: one kit, one
# vocabulary, so a room of benches cannot disagree with itself about what a
# demonstration is for.
#
# THE AXIS IS ON THE APPARATUS, NEVER ON THE STARTING CONDITIONS. A soft body relaxes: five
# lattices started five different ways settle into the same slump and photograph as one
# object five times. The bench is the thing that holds still, so the bench is the thing that
# can carry a claim — and the claim is that a laboratory decides what counts as a result.
#
#   none     nothing. The specimen alone on its pillar; trust the eye. The legacy lineage.
#   gauge    a graduated column and an indicator arm reaching in — the slump gets a number.
#   control  an empty reference cage on its own plinth — the slump gets a comparison.
#   chart    a plotted board standing behind it — the slump gets a history.
#   vitrine  a glass case on posts, capped and captioned — the slump gets a canon.
#
# The same settled shape, five times over, is a curiosity, a measurement, a difference, a
# record and an exhibit. Nothing about the soft body changes between them.

const ASSAY_TOP := 0.86                        # the bench working surface, family-wide
const ASSAY_READ := Color(0.98, 0.74, 0.26)    # the instrument accent: readings and ink
const ASSAY_WIRE := Color(0.55, 0.88, 0.98)    # the reference standard's cool wire


## Where this bench puts its apparatus. The landscape sits on a pillar, so the gauge column
## and the chart legs run all the way down to the base plate at y = 0.20.
func _assay_dressing() -> void:
	var half: float = maxf(span * 0.5, 0.31)
	match assay:
		"gauge":
			_assay_gauge(Vector3(-0.46, 0.0, -0.26), 0.50, 0.20)
		"control":
			_assay_control(Vector3(maxf(0.42, half + 0.14), ASSAY_TOP, 0.0), 0.20)
		"chart":
			_assay_chart(0.86, -0.335, 0.20)
		"vitrine":
			_assay_vitrine(Vector3(0.0, ASSAY_TOP + 0.28, 0.0),
				Vector3(maxf(half * 2.0 + 0.12, 0.70), 0.56, maxf(half * 2.0 + 0.12, 0.70)))
		_:
			pass                                # "none" — the legacy lineage


## GAUGE — a graduated column standing beside the bench with a cantilever indicator arm
## reaching in over the specimen and a stylus dropping onto it. The bench stops merely
## holding a shape and starts reporting a height.
func _assay_gauge(post: Vector3, reach: float, stand_y: float) -> void:
	var steel: StandardMaterial3D = _steel_mat(Color(0.42, 0.45, 0.50))
	var tick: StandardMaterial3D = _matte_mat(Color(0.88, 0.88, 0.84), 0.5)
	var read: StandardMaterial3D = _glow_mat(ASSAY_READ, 0.95)
	var top_y: float = ASSAY_TOP + 0.58
	add_child(_box(Vector3(post.x, stand_y + 0.015, post.z), Vector3(0.17, 0.03, 0.17), steel))
	add_child(_box(Vector3(post.x, (stand_y + top_y) * 0.5, post.z),
		Vector3(0.05, maxf(top_y - stand_y, 0.05), 0.05), steel))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = ASSAY_TOP + 0.02 + float(i) * 0.045
		var tl: float = 0.085 if (i % 5) == 0 else 0.045
		add_child(_box(Vector3(post.x + 0.025 + tl * 0.5, ty, post.z), Vector3(tl, 0.008, 0.012),
			read if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the specimen, a
	# lit point and a stylus dropped from it.
	var ay: float = ASSAY_TOP + 0.30
	add_child(_box(Vector3(post.x, ay, post.z), Vector3(0.09, 0.06, 0.09),
		_matte_mat(Color(0.20, 0.21, 0.25), 0.6)))
	add_child(_box(Vector3(post.x + reach * 0.5 + 0.03, ay, post.z), Vector3(reach, 0.024, 0.024), read))
	add_child(_sphere(Vector3(post.x + reach + 0.03, ay, post.z), 0.028, read))
	add_child(_box(Vector3(post.x + reach + 0.03, (ay + ASSAY_TOP + 0.10) * 0.5, post.z),
		Vector3(0.012, maxf(ay - ASSAY_TOP - 0.10, 0.02), 0.012), read))
	add_child(_billboard_label("GAUGE", Vector3(post.x, top_y + 0.07, post.z), 11, ASSAY_READ))


## CONTROL — the reference the bench keeps beside the specimen: an empty cage at the size
## the body had before anything happened to it, on its own witness plinth. The settled
## shape stops being a thing and becomes a difference from something.
func _assay_control(at: Vector3, stand_y: float) -> void:
	var pale: StandardMaterial3D = _matte_mat(Color(0.80, 0.80, 0.76), 0.6)
	var wire: StandardMaterial3D = _glow_mat(ASSAY_WIRE, 0.9)
	if at.y - stand_y > 0.05:
		add_child(_box(Vector3(at.x, (stand_y + at.y) * 0.5, at.z),
			Vector3(0.07, at.y - stand_y, 0.07), _steel_mat(Color(0.38, 0.40, 0.45))))
	add_child(_box(Vector3(at.x, at.y + 0.02, at.z), Vector3(0.24, 0.04, 0.24), pale))
	# Twelve edges of an undeformed cube with nothing inside it.
	var s: float = 0.10
	var cy: float = at.y + 0.05 + s
	for sx in [-s, s]:
		for sz in [-s, s]:
			add_child(_box(Vector3(at.x + sx, cy, at.z + sz), Vector3(0.009, s * 2.0, 0.009), wire))
	for sy in [-s, s]:
		for sz in [-s, s]:
			add_child(_box(Vector3(at.x, cy + sy, at.z + sz), Vector3(s * 2.0, 0.009, 0.009), wire))
		for sx in [-s, s]:
			add_child(_box(Vector3(at.x + sx, cy + sy, at.z), Vector3(0.009, 0.009, s * 2.0), wire))
	for sx2 in [-s, s]:
		for sy2 in [-s, s]:
			for sz2 in [-s, s]:
				add_child(_sphere(Vector3(at.x + sx2, cy + sy2, at.z + sz2), 0.016, wire))
	add_child(_billboard_label("CONTROL", Vector3(at.x, cy + s + 0.09, at.z), 11, ASSAY_WIRE))


## CHART — a record board at the back of the bench carrying the settling trace: an
## oscillation that damps out onto the rest line. The bench stops showing a state and starts
## keeping a history, and what you are looking at is the END of a line that was drawn.
func _assay_chart(board_w: float, bz: float, stand_y: float) -> void:
	var board_h: float = 0.52
	var by: float = ASSAY_TOP + 0.06 + board_h * 0.5
	var frame: StandardMaterial3D = _matte_mat(Color(0.26, 0.27, 0.31), 0.7)
	var paper: StandardMaterial3D = _matte_mat(Color(0.87, 0.86, 0.81), 0.85)
	var rule: StandardMaterial3D = _matte_mat(Color(0.58, 0.58, 0.54), 0.7)
	var ink: StandardMaterial3D = _glow_mat(ASSAY_READ, 1.0)
	var foot: float = by - board_h * 0.5
	for lx in [-board_w * 0.36, board_w * 0.36]:
		add_child(_box(Vector3(lx, (stand_y + foot) * 0.5, bz),
			Vector3(0.03, maxf(foot - stand_y, 0.02), 0.03), frame))
	add_child(_box(Vector3(0.0, by, bz - 0.012), Vector3(board_w + 0.04, board_h + 0.04, 0.016), frame))
	add_child(_box(Vector3(0.0, by, bz), Vector3(board_w, board_h, 0.012), paper))
	var x0: float = -board_w * 0.42
	var x1: float = board_w * 0.42
	var y0: float = by - board_h * 0.34
	var y1: float = by + board_h * 0.34
	add_child(_box(Vector3(0.0, y0, bz + 0.009), Vector3(board_w * 0.86, 0.008, 0.006), rule))
	add_child(_box(Vector3(x0, by, bz + 0.009), Vector3(0.008, board_h * 0.70, 0.006), rule))
	for i in range(4):
		add_child(_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), bz + 0.008),
			Vector3(board_w * 0.86, 0.003, 0.004), rule))
	# The trace is CLOSED FORM, not sampled from the running sim: a plot that came out
	# different on every launch would be noise wearing the costume of a record.
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(29):
		var f: float = float(i) / 28.0
		var v: float = exp(-3.4 * f) * cos(f * 13.0)
		pts.append(Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.44), bz + 0.015))
	for i in range(pts.size() - 1):
		add_child(_cylinder_between(pts[i], pts[i + 1], 0.006, ink))
	add_child(_sphere(pts[pts.size() - 1], 0.015, ink))
	add_child(_billboard_label("CHART", Vector3(0.0, by + board_h * 0.5 + 0.07, bz), 11, ASSAY_READ))


## VITRINE — a case. The demonstration stops being something you can reach into and becomes
## an exhibit: glass on four posts, a capping plate, a caption on the front rail. The
## specimen goes on moving inside and can no longer be touched.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = _steel_mat(Color(0.30, 0.32, 0.36))
	var cap: StandardMaterial3D = _matte_mat(Color(0.20, 0.21, 0.25), 0.7)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	add_child(_box(c, s, _glass_mat(Color(0.72, 0.84, 0.95), 0.09)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			add_child(_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.034, s.y, 0.034), post))
	# Rails, not floors: a solid pan at the base would hide whatever the bench has down there.
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			add_child(_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.026, 0.026), post))
		for sx2 in [-hx, hx]:
			add_child(_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.026, 0.026, s.z), post))
	add_child(_box(Vector3(c.x, y1 + 0.026, c.z), Vector3(s.x + 0.05, 0.03, s.z + 0.05), cap))
	add_child(_box(Vector3(c.x, y0 + 0.06, c.z + hz + 0.014), Vector3(minf(s.x * 0.5, 0.34), 0.07, 0.012),
		_matte_mat(Color(0.13, 0.14, 0.17), 0.8)))
	add_child(_billboard_label("VITRINE", Vector3(c.x, y0 + 0.06, c.z + hz + 0.035), 11,
		Color(0.90, 0.92, 0.97)))
