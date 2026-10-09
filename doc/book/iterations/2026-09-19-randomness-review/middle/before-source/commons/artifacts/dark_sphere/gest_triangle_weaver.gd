extends RigidBody3D
# NO class_name — this is preloaded by script path. A class_name can fail to
# resolve on the Quest's loader thread while every local gate is green
# (standing memory, 2026-08-21).

# ── RUNG THREE OF THE GESTATION (2026-08-24, Palle: "then in triangles, a
# triangle hovers, a weaving trace starts. A weaver's logic, before it can take
# another form in primitive form, weaving primitives") ────────────────────────
#
# The point fell, because a position has no defence. The line fell and broke,
# because a relation is fragile. This one HOLDS — a triangle is the first thing
# with an INSIDE — and then it weaves that inside out of nothing but straight
# chords.
#
# THE CLOTH IS TRIAXIAL. Warp and weft is the square grid's cloth: two families
# at 90 degrees. A triangle's native cloth is THREE families at 60. Each fan
# runs from one corner, chord k walking out along one edge while the other end
# walks in along the other, so the fan's ENVELOPE is a parabola tangent to both
# edges — three fans, three parabolas, a curved trefoil that nothing ever drew
# as a curve. That is the primitives chapter's own claim (three_points_triangle
# .gd:6, "every curve is a lie told well by enough triangles") shown rather
# than asserted.
#
# THE ONE BIT THAT MAKES IT CLOTH is _chord_z: relief along a chord's own run,
# over for the first third and under for the last. It is cyclically consistent
# across all three fans WITHOUT a family index, because fan f's start-third
# shares an edge with fan f+1's end-third, so one reads +lift exactly where the
# other reads -lift. This is codex_loom's ±lift (_weave_warp_y_at :612 /
# _weave_weft_y_at :617) — one bit, two complementary heights — carried from
# two families to three.

## sibling scale across the rungs: 0.44 m point, ~1.5 m line, ~1 m triangle
@export var tri_m: float = 0.99
@export var strand_colour: Color = Color(0.72, 0.55, 0.95)
## codex_loom's own band (:501). 14 x 3 fans = 42 chords of cloth.
@export var chords_per_fan: int = 14
@export var chords_per_second: float = 7.0
@export var hover_m: float = 0.55

const SEGS := 3          # over · cross · under, per chord
const RISE_S := 1.2
const HOLD_S := 3.0

var _C: Array = []                 # the three corners, local
var _mm: MultiMesh = null
var _n: int = 0                    # instances written
var _cap: int = 0                  # decided once in _build_cloth, never again
var _laid: int = 0                 # chords laid
var _chord_cap: int = 0
var _t: float = 0.0                # weave accumulator
var _life: float = 0.0
var _held: float = 0.0
var _base_y: float = 0.0
var _rise_from: float = 0.0
var _placed: bool = false
var _done: bool = false
## draw_dot's RET_DOT_R — the corpus's only legibility calibration — and
## codex_loom's spacing * 0.31 for a lattice that does not self-occlude
var _strand_r: float = 0.020
var _lift: float = 0.028           # _strand_r * 1.4, codex_loom.gd:512


func _ready() -> void:
	freeze = true              # holds the pose (force_cube.gd:54)
	gravity_scale = 0.0        # insurance if anything ever unfreezes it
	linear_damp = 0.3
	angular_damp = 0.5
	collision_layer = 0        # inert: it is a yield, not an obstacle
	collision_mask = 0         # never pushes the world
	# NO release_mode — that is XRToolsPickable's property, not RigidBody3D's.
	_corners()
	_build_hull()
	_build_frame()
	_build_cloth()


func _corners() -> void:
	# the canonical body, three_points_triangle.gd:85-87 (the only triangle
	# geometry duplicated verbatim in the corpus), scaled to tri_m
	var s: float = tri_m / 1.1
	_C = [Vector3(0.0, 1.1 * 0.6, 0.0) * s,
		Vector3(-1.2 * 0.5, -1.1 * 0.4, 0.0) * s,
		Vector3(1.2 * 0.5, -1.1 * 0.4, 0.0) * s]


func _mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = strand_colour
	m.emission_enabled = true
	m.emission = strand_colour
	m.emission_energy_multiplier = 1.3
	m.roughness = 0.4
	return m


## A guarded frame between two points. MorphoPrimitive.multi_tube cannot be
## used here: its frame is forward x Vector3.UP (morpho_primitive.gd:90) and
## DEGENERATES for world-Y-aligned paths — an upright triangle's chords run
## near-vertical, so it would emit garbage tubes. The reference axis is chosen
## away from the direction instead, which is the whole fix.
func _seg_xform(a: Vector3, b: Vector3) -> Transform3D:
	var d: Vector3 = b - a
	var l: float = d.length()
	if l < 0.0001:
		return Transform3D()
	var yv: Vector3 = d / l
	var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var xv: Vector3 = ref.cross(yv).normalized()
	var zv: Vector3 = yv.cross(xv).normalized()
	# the mesh is a UNIT-height cylinder: only Y carries the length
	return Transform3D(Basis(xv, yv * l, zv), (a + b) * 0.5)


## A legal body needs a shape; this one is never asked to collide with anything.
func _build_hull() -> void:
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(tri_m * 1.1, tri_m * 1.1, 0.12)
	cs.shape = bx
	add_child(cs)


## THREE EDGES AND THREE CORNERS AND NO FACE. That is the whole difference from
## three_points_triangle, which ships its face filled: here the enclosure is
## stated EMPTY, and the weave is what fills it.
func _build_frame() -> void:
	var mat: StandardMaterial3D = _mat()
	for i in range(3):
		var a: Vector3 = _C[i]
		var b: Vector3 = _C[(i + 1) % 3]
		var e := MeshInstance3D.new()
		e.name = "Edge%d" % i
		var cm := CylinderMesh.new()
		cm.height = 1.0
		cm.top_radius = _strand_r * 1.3
		cm.bottom_radius = _strand_r * 1.3
		cm.radial_segments = 6
		e.mesh = cm
		e.material_override = mat
		e.transform = _seg_xform(a, b)
		add_child(e)
		var c := MeshInstance3D.new()
		c.name = "Corner%d" % i
		var sm := SphereMesh.new()
		sm.radius = _strand_r * 2.0
		sm.height = _strand_r * 4.0
		c.mesh = sm
		c.material_override = mat
		c.position = a
		add_child(c)


func _build_cloth() -> void:
	_chord_cap = maxi(1, chords_per_fan) * 3
	_cap = _chord_cap * SEGS                 # 126 — decided here, never touched
	var cyl := CylinderMesh.new()
	cyl.height = 1.0                         # UNIT: _seg_xform scales Y
	cyl.top_radius = _strand_r
	cyl.bottom_radius = _strand_r
	cyl.radial_segments = 6
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.mesh = cyl
	_mm.instance_count = _cap
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Cloth"
	mmi.multimesh = _mm
	var mat: StandardMaterial3D = _mat()
	mat.vertex_color_use_as_albedo = true    # attractor_plotter.gd:68
	mmi.material_override = mat
	add_child(mmi)


## Chord k of fan f. Dead straight — the curve is what the fan LEAVES BEHIND.
func _chord_ends(f: int, k: int) -> Array:
	var t: float = float(k + 1) / float(maxi(1, chords_per_fan) + 1)
	return [_C[f].lerp(_C[(f + 1) % 3], t),
		_C[f].lerp(_C[(f + 2) % 3], 1.0 - t)]


func _chord_z(u: float) -> float:
	if u < 0.334:
		return _lift        # over
	if u > 0.666:
		return -_lift       # under
	return 0.0


## One chord, three segments, through four nodes at u = 0, 1/3, 2/3, 1 — so the
## strand goes OVER, crosses, and passes UNDER, connected end to end.
func _weave_one() -> void:
	if _laid >= _chord_cap or _mm == null:
		return
	var f: int = _laid % 3            # interleaved, so all three fans thicken together
	var k: int = _laid / 3
	var e: Array = _chord_ends(f, k)
	var a: Vector3 = e[0]
	var b: Vector3 = e[1]
	var col: Color = strand_colour.lerp(Color(1, 1, 1), 0.10 * float(f))
	var pts: Array = []
	for i in range(SEGS + 1):
		var u: float = float(i) / float(SEGS)
		pts.append(a.lerp(b, u) + Vector3(0.0, 0.0, _chord_z(u)))
	for s in range(SEGS):
		if _n >= _cap:
			break
		_mm.set_instance_transform(_n, _seg_xform(pts[s], pts[s + 1]))
		_mm.set_instance_color(_n, col)
		_n += 1
	_mm.visible_instance_count = _n
	_laid += 1


func _process(delta: float) -> void:
	# the parent places this AFTER add_child (like rungs one and two), so the
	# hover base cannot be read in _ready — it is taken on the first frame
	if not _placed:
		_placed = true
		_rise_from = position.y
		_base_y = position.y + hover_m
	_life += delta
	if _life < RISE_S:
		var u: float = clampf(_life / RISE_S, 0.0, 1.0)
		position.y = lerpf(_rise_from, _base_y, u * u * (3.0 - 2.0 * u))
	else:
		# absolute assignment off a stored base, off delta — never +=, and never
		# Time.get_time_dict_from_system() (an INTEGER second, so it steps at 1 Hz)
		position.y = _base_y + sin(_life * 0.9) * 0.012
	if not _done:
		# frame-rate independent catch-up, so it looks the same at 72 and 90 Hz
		_t += delta
		var interval: float = 1.0 / maxf(0.1, chords_per_second)
		while _t >= interval and _laid < _chord_cap:
			_t -= interval
			_weave_one()
		_t = fmod(_t, maxf(interval, 0.001))
		if _laid >= _chord_cap:
			_done = true
	else:
		# a yield left behind in a hall the visitor walks out of: it finishes,
		# breathes a moment, and then costs nothing at all. No reseed, no loop.
		_held += delta
		if _held >= HOLD_S:
			set_process(false)
