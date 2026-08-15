extends Node3D
class_name RegimeThreshold

## regime_threshold — a regime is a NAME laid over one continuous dial.
##
## THE FAMILY. Five artifacts declare an axis called `regime`. Two of them use the damping
## vocabulary and are the subject here: control_pendulum (free · underdamped · critical ·
## overdamped · resonance) and mass_spring_damper (all · underdamped · critical · overdamped).
## Three more use the same word for a different threshold crossing and are kin, not subject:
## rotation_gimbal (free · approaching · locked · past — where on the approach to gimbal lock
## the rig is found), exercise_1_3_solution_3_d_bouncing_ball_vr (stock · elastic · dead ·
## inelastic — a restitution coefficient of 0.9 · 1.0 · 0.0 · 0.55) and bifurcation_diagram /
## bifurcation_walkway (all · stable · cascade · chaos · period3 — windows of the logistic r).
## In every one of them the axis names STATIONS ALONG ONE NUMBER: zeta, the Y angle, e, r.
##
## THE ARGUMENT. Underdamped / critical / overdamped is the damping ratio zeta crossing 1.0.
## Two half-lines and the point between them, and the vocabulary promotes the point to a peer
## of the half-lines. mass_spring_damper's own bench is the proof that nobody can see the
## point: its "Critically Damped" mass is d = 12 at k = 40, m = 1, which is zeta = 12 / (2
## sqrt 40) = 0.949 — five percent UNDERDAMPED, a mass that will in fact cross zero, at an
## amplitude of about 2e-4 of its release, one and a half seconds in. It has stood on the
## bench labelled critical since it was written and it is not, and no viewer could tell,
## because the difference between 0.949 and 1.000 is a fact about a name and not about a
## picture. control_pendulum sets its critical at exactly 1.00 (gd:224) — a measure-zero
## point on the dial, dressed as a third kind of pendulum. So: the regimes are real as
## descriptions of what the trace does (crosses the rest line, or does not), and they are
## NOT three systems. They are one system, one release, five settings of one knob.
##
## THE BODY, NOT A GAUGE. There is no chart. The system is built as a body — an anchor
## bar, a coil spring whose pitch IS the extension, a mass block, and a dashpot whose bore
## is sized by zeta so the damping is a part you can see. The trajectory is the path the
## mass's centre would scratch on a wall sliding past it at constant speed, laid down as a
## real tube in space; the rest rail is that same wall's rest line, one thin rod. The
## envelope is the region the mass could occupy at each moment, a translucent sheet behind
## the tube. Everything is computed in closed form from the same release, so five variants
## are five readings of one system and not five simulations that happen to be near each
## other.

## WHICH SETTING OF THE ONE KNOB. The five values are control_pendulum's list character for
## character (gd:72), and its zetas (gd:219-228) except that free is taken at its word:
##   free         zeta 0.00, no drive. The pure cosine, forever. control_pendulum's free is
##                a shipped 0.995-per-frame multiplier it measures at zeta 0.037, and
##                mass_spring_damper's "Underdamped" is d 0.5, zeta 0.040 — both are, over a
##                four-second window, this picture. No dashpot is drawn: there is nothing to
##                draw.
##   underdamped  zeta 0.25 (control_pendulum gd:222). Crosses the rest line, decays inside
##                the window; the tangent envelope x0 e^(-zeta w0 t) / sqrt(1 - zeta^2).
##   critical     zeta 1.00 (gd:224). x0 (1 + w0 t) e^(-w0 t): the fastest return that never
##                crosses. THE POINT. mass_spring_damper's version of it is 0.949.
##   overdamped   zeta 2.50 (gd:226). Two real exponentials; the slow one, at rate
##                (zeta - sqrt(zeta^2 - 1)) w0 = 1.32 /s, is what you see, and it is SLOWER
##                than critical, which is the whole joke of the name.
##   resonance    zeta 0.08 and a drive at w0 (gd:227, gd:269-271). The steady amplitude is
##                DRIVE_RATIO times the release, control_pendulum's own 0.375 / 0.3 = 1.25.
##                The one value on the dial that is not a damping — it is the other knob,
##                turned — and it is here because control_pendulum put it there.
@export_enum("free", "underdamped", "critical", "overdamped", "resonance") var regime: String = "free":
	set(v):
		regime = v
		if is_inside_tree():
			_rebuild()

## WHAT IS DRAWN OF THE SYSTEM.
##   trace     the body at the moment of release, and the tube the mass's centre draws over
##             the next WINDOW seconds, against the rest rail. The reading that shows the
##             regimes as one dial.
##   bob       the body alone, frozen half a natural period after release — the moment the
##             free mass reaches the far side — with a ghost of the mass at its release
##             height. Every damped mass has fallen short of the ghost's mirror by exactly
##             its regime. control_pendulum's own note says a still of the body at one phase
##             is a fact about the camera; this reading picks the phase on purpose.
##   envelope  the trace, inside the region the mass could occupy: a translucent sheet from
##             +A(t) to -A(t) behind the tube. For zeta < 1 that is the tangent envelope,
##             whose 1 / sqrt(1 - zeta^2) blows up AT the critical point; for zeta >= 1
##             there is no oscillation left to envelope and the trace is its own skin, so
##             the sheet closes onto the tube. The boundary seen from both sides.
@export_enum("trace", "bob", "envelope") var reading: String = "trace":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## Whether one regime stands alone or all five stand in a row. NOT PART OF THE AXIS — wave 13
## learned that a value which shows every rung at once, declared inside the ladder axis,
## makes capture_config_sweep union the AABB of the row with every single rung and photograph
## the singles as specks. A layout is not a rung. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## How far the mass is pulled DOWN before release, in metres. Every regime is released from
## here, from rest — that is what makes them readings of one system.
@export var release: float = 0.20
## How many seconds of trajectory the tube carries. About four natural periods at k = 40.
@export var window: float = 4.0

const REGIMES: PackedStringArray = ["free", "underdamped", "critical", "overdamped", "resonance"]
const READINGS: PackedStringArray = ["trace", "bob", "envelope"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## mass_spring_damper's bench, byte for byte: k = 40, m = 1, so w0 = sqrt(40) = 6.32 rad/s
## and one natural period is 0.993 s.
const STIFFNESS: float = 40.0
const MASS: float = 1.0
## control_pendulum's zetas (gd:219-228). `free` is not measured here; it is the word.
const ZETAS: Dictionary = {
	"free": 0.0,
	"underdamped": 0.25,
	"critical": 1.0,
	"overdamped": 2.5,
	"resonance": 0.08,
}
## Steady resonant amplitude as a multiple of the release: control_pendulum's DRIVE_AMP /
## (2 zeta) = 0.375 rad against a START_ANGLE of 0.3 rad (gd:84-89).
const DRIVE_RATIO: float = 1.25

## Body dimensions, metres. Everything sits inside about 1.2 m so one camera frames it.
const ANCHOR_Y: float = 0.55
const ANCHOR_HALF_W: float = 0.13
const ANCHOR_H: float = 0.03
const SPRING_X: float = -0.03
const SPRING_R: float = 0.03
const SPRING_COILS: int = 8
const SPRING_WIRE: float = 0.005
const DASHPOT_X: float = 0.05
const DASHPOT_LEN: float = 0.24
const MASS_SIZE: Vector3 = Vector3(0.16, 0.08, 0.08)
const TRACE_LEN: float = 0.90
const TRACE_R: float = 0.008
const RAIL_R: float = 0.003
const SHEET_Z: float = -0.025
const LADDER_PITCH: float = 1.30
const TRACE_SAMPLES: int = 160
const TUBE_SIDES: int = 6

## The family's own colours per named regime — mass_spring_damper gd:132/139/146 blue, green,
## red — with two more for the values it does not have.
const REGIME_COLOR: Dictionary = {
	"free": Color(0.78, 0.82, 0.90),
	"underdamped": Color(0.30, 0.50, 1.00),
	"critical": Color(0.30, 1.00, 0.30),
	"overdamped": Color(1.00, 0.30, 0.30),
	"resonance": Color(1.00, 0.72, 0.30),
}
const METAL: Color = Color(0.46, 0.47, 0.52)
const RAIL: Color = Color(0.30, 0.31, 0.36)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("regime"):
		regime = _pick(str(config_data["regime"]), REGIMES, regime)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
	if config_data.has("release"):
		release = float(config_data["release"])
	if config_data.has("window"):
		window = float(config_data["window"])
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: Array = []
	if layout == "ladder":
		for r in REGIMES:
			names.append(r)
	else:
		names.append(_pick(regime, REGIMES, "free"))
	var n: int = names.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(names[i])
		# Centre each variant on its own origin: the trace readings run from the body at the
		# left to the end of the rail at the right, so the body stands at -TRACE_LEN / 2.
		var body_x: float = 0.0 if reading == "bob" else -TRACE_LEN * 0.5
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH + body_x, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[i]))


## One regime, in whichever reading is set.
func _build_variant(holder: Node3D, r: String) -> void:
	if reading == "bob":
		_add_body(holder, r, 0.5 * _period())
		_add_ghost(holder, r)
		return
	_add_body(holder, r, 0.0)
	_add_rail(holder)
	if reading == "envelope":
		_add_envelope(holder, r)
	_add_trace(holder, r)


# ── the physics, in closed form ─────────────────────────────────────────────────────────

func _omega0() -> float:
	return sqrt(STIFFNESS / MASS)


func _period() -> float:
	return TAU / _omega0()


func _zeta(r: String) -> float:
	if ZETAS.has(r):
		return float(ZETAS[r])
	return 0.0


## Displacement of the mass centre from rest, metres, positive UP, t seconds after release
## from x = -release at rest. Closed forms of x'' + 2 zeta w0 x' + w0^2 x = f(t).
func _displacement(r: String, t: float) -> float:
	var w0: float = _omega0()
	var z: float = _zeta(r)
	var x0: float = release
	if r == "resonance":
		# Particular solution at exact resonance is (F / 2 zeta w0^2) sin(w0 t) — a quarter
		# turn behind a cosine drive — and the homogeneous part is fitted to the same
		# release as every other value.
		var a_ss: float = DRIVE_RATIO * x0
		var wd: float = w0 * sqrt(1.0 - z * z)
		var c: float = -x0
		var d: float = -w0 * (z * x0 + a_ss) / wd
		return exp(-z * w0 * t) * (c * cos(wd * t) + d * sin(wd * t)) + a_ss * sin(w0 * t)
	if z <= 0.0:
		return -x0 * cos(w0 * t)
	if z < 1.0:
		var wd: float = w0 * sqrt(1.0 - z * z)
		return -x0 * exp(-z * w0 * t) * (cos(wd * t) + z / sqrt(1.0 - z * z) * sin(wd * t))
	if absf(z - 1.0) < 1e-9:
		return -x0 * exp(-w0 * t) * (1.0 + w0 * t)
	# Overdamped as the sum of its two real exponentials, so nothing overflows.
	var s: float = sqrt(z * z - 1.0)
	var slow: float = (z + s) * exp(-(z - s) * w0 * t)
	var fast: float = (z - s) * exp(-(z + s) * w0 * t)
	return -x0 / (2.0 * s) * (slow - fast)


## Half-height of the region the mass could occupy at t. See the `envelope` gloss.
func _envelope(r: String, t: float) -> float:
	var w0: float = _omega0()
	var z: float = _zeta(r)
	var x0: float = release
	if r == "resonance":
		# To first order: the drive's beat envelope A_ss (1 - e^(-zeta w0 t)) plus the
		# release's own decaying skin. A bound, not a tangent — the two parts are not
		# exactly in phase because wd is not exactly w0.
		var a_ss: float = DRIVE_RATIO * x0
		var decay: float = exp(-z * w0 * t)
		return a_ss * (1.0 - decay) + x0 * decay / sqrt(1.0 - z * z)
	if z <= 0.0:
		return x0
	if z < 1.0:
		return x0 * exp(-z * w0 * t) / sqrt(1.0 - z * z)
	return absf(_displacement(r, t))


# ── the body ────────────────────────────────────────────────────────────────────────────

## Anchor bar, coil spring, mass block, dashpot (bore sized by zeta), and for resonance the
## crank on the anchor that drives it. The mass sits at its displacement at time t.
func _add_body(holder: Node3D, r: String, t: float) -> void:
	var y: float = _displacement(r, t)
	var z: float = _zeta(r)
	# Anchor bar.
	holder.add_child(_box(Vector3(0.0, ANCHOR_Y + ANCHOR_H * 0.5, 0.0),
			Vector3(ANCHOR_HALF_W * 2.0, ANCHOR_H, 0.06), METAL, 0.0, "Anchor"))
	# The spring: a helix whose pitch is the extension. Anchor down to the top of the mass.
	var top: float = ANCHOR_Y
	var bottom: float = y + MASS_SIZE.y * 0.5
	var pts: PackedVector3Array = PackedVector3Array()
	var n: int = SPRING_COILS * 14
	for i in range(n + 1):
		var u: float = float(i) / float(n)
		var ang: float = u * float(SPRING_COILS) * TAU
		pts.append(Vector3(SPRING_X + SPRING_R * cos(ang), top + (bottom - top) * u,
				SPRING_R * sin(ang)))
	holder.add_child(_tube(pts, SPRING_WIRE, METAL, 0.0, "Spring"))
	# The mass, in the regime's colour.
	holder.add_child(_box(Vector3(0.0, y, 0.0), MASS_SIZE, _color(r), 0.15, "Mass"))
	# The dashpot: a bore whose radius is the damping, and a piston rod down to the mass.
	# free has none — there is nothing to draw.
	if z > 0.0:
		var bore: float = 0.008 + 0.012 * minf(z, 2.5)
		holder.add_child(_cylinder(Vector3(DASHPOT_X, ANCHOR_Y - DASHPOT_LEN * 0.5, 0.0),
				bore, DASHPOT_LEN, METAL, 0.0, "DashpotBore"))
		var rod_top: float = ANCHOR_Y - DASHPOT_LEN + 0.02
		var rod_bottom: float = y + MASS_SIZE.y * 0.5
		if rod_top > rod_bottom:
			holder.add_child(_cylinder(Vector3(DASHPOT_X, (rod_top + rod_bottom) * 0.5, 0.0),
					0.004, rod_top - rod_bottom, RAIL, 0.0, "PistonRod"))
	if r == "resonance":
		# A crank wheel on the anchor with its pin off-centre: the other knob, turned.
		var wheel := _cylinder(Vector3(0.0, ANCHOR_Y + ANCHOR_H + 0.035, 0.0), 0.035, 0.02,
				METAL, 0.0, "Crank")
		wheel.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		holder.add_child(wheel)
		var pin := _cylinder(Vector3(0.022, ANCHOR_Y + ANCHOR_H + 0.035, 0.0), 0.006, 0.05,
				_color(r), 0.4, "CrankPin")
		pin.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		holder.add_child(pin)


## The mass at its release height, translucent, so a still of the body carries how far it
## has moved.
func _add_ghost(holder: Node3D, r: String) -> void:
	var c: Color = _color(r)
	c.a = 0.28
	holder.add_child(_box(Vector3(0.0, -release, 0.0), MASS_SIZE, c, 0.0, "Ghost"))


## The rest line of the sliding wall: one rod at the height the mass hangs at rest.
func _add_rail(holder: Node3D) -> void:
	holder.add_child(_rod(Vector3(0.0, 0.0, 0.0), Vector3(TRACE_LEN, 0.0, 0.0), RAIL, RAIL_R,
			"RestRail"))


## The path the mass centre draws on a wall sliding past at TRACE_LEN / window m/s.
func _add_trace(holder: Node3D, r: String) -> void:
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(TRACE_SAMPLES + 1):
		var t: float = window * float(i) / float(TRACE_SAMPLES)
		pts.append(Vector3(TRACE_LEN * t / window, _displacement(r, t), 0.0))
	holder.add_child(_tube(pts, TRACE_R, _color(r), 0.6, "Trace"))


## The region the mass could occupy, +A(t) to -A(t), as one translucent sheet behind the tube.
func _add_envelope(holder: Node3D, r: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = TRACE_SAMPLES
	for i in range(n):
		var t0: float = window * float(i) / float(n)
		var t1: float = window * float(i + 1) / float(n)
		var xa: float = TRACE_LEN * t0 / window
		var xb: float = TRACE_LEN * t1 / window
		var ea: float = _envelope(r, t0)
		var eb: float = _envelope(r, t1)
		var p00 := Vector3(xa, ea, SHEET_Z)
		var p01 := Vector3(xa, -ea, SHEET_Z)
		var p10 := Vector3(xb, eb, SHEET_Z)
		var p11 := Vector3(xb, -eb, SHEET_Z)
		# Wound to face +Z (the viewer's side); culling is off anyway.
		var quad: Array = [p00, p01, p10, p10, p01, p11]
		for j in range(quad.size()):
			var p: Vector3 = quad[j]
			st.set_normal(Vector3.BACK)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.name = "Envelope"
	mi.mesh = st.commit()
	var c: Color = _color(r)
	c.a = 0.30
	mi.material_override = _mat(c, 0.25, true)
	holder.add_child(mi)


# ── mesh helpers ────────────────────────────────────────────────────────────────────────

func _color(r: String) -> Color:
	if REGIME_COLOR.has(r):
		return REGIME_COLOR[r] as Color
	return REGIME_COLOR["free"] as Color


## A round tube along a polyline, six sides, normals set outward per vertex so lighting is
## right whichever way a face happens to wind; culling is off for the same reason.
func _tube(pts: PackedVector3Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var count: int = pts.size()
	if count < 2:
		return mi
	# Rotation-minimising frames: carry one normal along the path by projecting it out of
	# each new tangent. A fixed reference axis flips at the steep parts of a trace and at
	# every quarter-turn of the helix, and a flip between two rings pinches the tube.
	var rings: Array = []
	var n1: Vector3 = Vector3.ZERO
	for i in range(count):
		var prev: Vector3 = pts[maxi(i - 1, 0)]
		var next: Vector3 = pts[mini(i + 1, count - 1)]
		var tangent: Vector3 = (next - prev).normalized()
		if tangent.length_squared() < 0.5:
			tangent = Vector3.RIGHT
		if i == 0:
			var seed_axis: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
			n1 = tangent.cross(seed_axis).normalized()
		else:
			n1 = n1 - tangent * n1.dot(tangent)
			if n1.length_squared() < 1e-8:
				var seed_again: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
				n1 = tangent.cross(seed_again)
			n1 = n1.normalized()
		var n2: Vector3 = tangent.cross(n1).normalized()
		var ring: Array = []
		for k in range(TUBE_SIDES):
			var a: float = TAU * float(k) / float(TUBE_SIDES)
			var normal: Vector3 = n1 * cos(a) + n2 * sin(a)
			ring.append([pts[i] + normal * r, normal])
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(count - 1):
		var ra: Array = rings[i]
		var rb: Array = rings[i + 1]
		for k in range(TUBE_SIDES):
			var k2: int = (k + 1) % TUBE_SIDES
			var a0: Array = ra[k]
			var a1: Array = ra[k2]
			var b0: Array = rb[k]
			var b1: Array = rb[k2]
			var order: Array = [a0, b0, a1, a1, b0, b1]
			for j in range(order.size()):
				var v: Array = order[j]
				var vpos: Vector3 = v[0]
				var vnrm: Vector3 = v[1]
				st.set_normal(vnrm)
				st.add_vertex(vpos)
	mi.mesh = st.commit()
	mi.material_override = _mat(c, emit, false)
	return mi


func _box(at: Vector3, size: Vector3, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = _mat(c, emit, c.a < 0.999)
	return mi


func _cylinder(at: Vector3, r: float, h: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(h, 0.0001)
	cyl.radial_segments = 12
	cyl.rings = 0
	mi.mesh = cyl
	mi.position = at
	mi.material_override = _mat(c, emit, false)
	return mi


func _rod(a: Vector3, b: Vector3, c: Color, r: float, label: String) -> MeshInstance3D:
	var mi := _cylinder((a + b) * 0.5, r, a.distance_to(b), c, 0.0, label)
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mi.position, mi.position + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return mi


func _mat(c: Color, emit: float, translucent: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.55
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if translucent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
