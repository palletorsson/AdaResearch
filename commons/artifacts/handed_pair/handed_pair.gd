extends Node3D
class_name HandedPair

## handed_pair — handedness is a CONVENTION laid over one fixed piece of data.
##
## THE FAMILY. Three artifacts declare an axis called `handedness`, in two vocabularies.
## VectorCrossProduct (right · left · both) and torque_demo (right · left · both) stand in
## the same folder and compute the same product: `right` is the literal `a.cross(b)` /
## `r.cross(f)` each file shipped with, `left` swaps the operands, `both` builds the second
## perpendicular tail to tail with the first through the origin, dimmer or recoloured.
## dna_specimen (right · left) reaches one node down into doublehelix.gd and flips the sign
## on the angle step, calling +i "right, B-DNA" and -i "left, Z-DNA". Nobody draws a mirror
## plane. In every one of them the word names WHICH OF THE TWO PERPENDICULARS to a plane is
## promoted to "the" third axis once the first two are given.
##
## THE ARGUMENT. The data never changes hand. Two vectors, the plane they span, and the sense
## of turning from the first toward the second are all the same in every variant here; what
## the word picks is the side of that plane the third axis stands on. The mirror image of a
## right-handed construction is a left-handed one obeying the same law with the opposite
## sign, so `left` is built here as the reflection of `right` through the a-b plane — for
## the arrow, for the torque, and for the helix, ONE mirror — and `both` is the two halves
## standing together, a figure that is achiral. Nothing in the geometry prefers a side; the
## right-hand rule is a rule about hands.
##
## THE FINDING THAT OVERRULES THE BRIEF. The brief asked that `right` be the same convention
## in all three figures and that the note say how that was checked across the members. It
## was checked by computing the sign of the discrete torsion of each member's `right`
## (P0..P3 consecutive points: (P1-P0) x (P2-P1) . (P3-P2), positive for a right-hand
## screw). VectorCrossProduct and torque_demo are right-handed by construction — Godot's
## Vector3.cross is the right-hand formula in a right-hand frame, and apply_torque spins the
## same way. doublehelix.gd's shipped `right` is (cos(+i*step) r, y rising, sin(+i*step) r):
## its torsion is NEGATIVE (-1.4e-4 on the 96-point strand, the reference helix
## (cos t, sin t, t) gives +1.5e-3), so the winding that every dna_specimen placement calls
## B-DNA is a LEFT-handed screw in world space and its `left` is the right-handed one. This
## artifact follows the right-hand rule, so its `right` helix winds the way dna_specimen's
## `left` does. Two of three members agree with the physics; the third has the word on
## backwards, and the note in the registry says so.
##
## THE BODY, NOT A GAUGE. There is no chart and no readout. One frame: a along one horizontal
## direction, b at ninety degrees to it in the floor plane, so a x b is exactly UP. The pair
## is turned so that from the sweep standpoint (yaw 0.62, pitch -0.26) a runs screen-right,
## b runs screen-left and away, and the perpendicular is the vertical between them: the
## mirror plane is the floor, seen nearly edge-on, which is the standpoint from which a
## reflection moves the most. (Had the plane faced the camera, as the members' +Z torque
## does at 38 degrees off the view line, the flip would foreshorten toward nothing.)

## WHICH PERPENDICULAR. The family's three words, VectorCrossProduct's order (gd:37).
##   right  the perpendicular is a x b — up. The right-hand rule; the literal expression the
##          two vector benches shipped with. In the helix figure the screw that turns a
##          toward b while advancing along a x b, which is right-handed (torsion +).
##   left   the perpendicular is b x a — down. The same plane, the same turning sense from a
##          toward b, the third axis on the other side: the exact reflection of `right`
##          through the a-b plane. In the helix figure a left-handed screw (torsion -).
##   both   the two perpendiculars tail to tail at the origin, one each way, the counter
##          drawn the way its member draws it — VectorCrossProduct's teal `b x a`
##          (gd:235), torque_demo's dimmer purple (gd:226), and for the helix the second
##          screw in the strand colours at 0.55. The union of right and left; achiral.
@export_enum("right", "left", "both") var handedness: String = "right":
	set(v):
		handedness = v
		if is_inside_tree():
			_rebuild()

## WHICH CONSTRUCTION IS DRAWN. Every figure keeps the same a, the same b, the same turning
## arc from a toward b, and the same perpendicular arrow; each adds its member's body.
##   cross   VectorCrossProduct's bench: a (orange) and b (blue) from the origin, the
##           parallelogram they span as the 10 x 10 ruled lattice its `span = grid` draws
##           (gd:203-219), and the product as a purple arrow of length PERP_LEN.
##   torque  torque_demo's bench: a is the lever arm r (cyan) from a pivot ball, b is the
##           force F (red) applied AT THE TIP of r rather than at the origin, and the
##           product is the torque tau (purple) standing on the pivot. The same cross
##           product with the second vector slid to the end of the first.
##   helix   dna_specimen's body wound around the perpendicular: a double helix of two
##           strands and rungs, radius HELIX_R, HELIX_TURNS turns over HELIX_H, whose
##           strand starts on a and turns toward b as it advances along the arrow. The
##           arrow itself is the helix's axis in doublehelix.gd's axis colour.
@export_enum("cross", "torque", "helix") var figure: String = "cross":
	set(v):
		figure = v
		if is_inside_tree():
			_rebuild()

## Whether one figure stands alone or all three stand in a row at the current handedness.
## NOT PART OF THE AXES — a value that shows every rung at once, declared inside an axis,
## makes capture_config_sweep union the row's AABB with every single and photograph the
## singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

const HANDS: PackedStringArray = ["right", "left", "both"]
const FIGURES: PackedStringArray = ["cross", "torque", "helix"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## The data. a at azimuth 60 degrees from +X toward -Z, b a quarter turn further the same
## way, both in the floor plane, so a x b = +Y exactly. Lengths in metres.
const A_LEN: float = 0.36
const B_LEN: float = 0.30
## The perpendicular is drawn at a fixed display length, the way torque_demo draws tau at
## `torque * 0.5`: the exhibit's own choice of units, not an axis.
const PERP_LEN: float = 0.45
const PERP_R: float = 0.018
const PERP_HEAD_R: float = 0.045
const PERP_HEAD_L: float = 0.09
const AB_R: float = 0.012
const AB_HEAD_R: float = 0.03
const AB_HEAD_L: float = 0.06
const ARC_R: float = 0.12
const ARC_TUBE_R: float = 0.004
const LATTICE_N: int = 10
const LATTICE_W: float = 0.006
const PIVOT_R: float = 0.035
const ORIGIN_R: float = 0.016
const HELIX_R: float = 0.09
const HELIX_H: float = 0.40
const HELIX_TURNS: int = 3
const HELIX_PPT: int = 32
const HELIX_STRAND_R: float = 0.011
const HELIX_RUNG_EVERY: int = 4
const HELIX_RUNG_R: float = 0.005
const HELIX_AXIS_R: float = 0.010
const HELIX_AXIS_HEAD_R: float = 0.03
const HELIX_AXIS_HEAD_L: float = 0.07
const LADDER_PITCH: float = 0.95
const TUBE_SIDES: int = 8
## How much dimmer the counter-hand is drawn at `both`: torque_demo's (0.8,0.3,1.0) against
## its counter (0.45,0.22,0.62) is 0.56 / 0.73 / 0.62 per channel.
const COUNTER_DIM: float = 0.55

## The members' own colours.
const CROSS_A: Color = Color(1.0, 0.55, 0.2)          # VectorCrossProduct gd:75
const CROSS_B: Color = Color(0.2, 0.7, 1.0)           # gd:76
const CROSS_N: Color = Color(0.75, 0.55, 1.0)         # gd:77
const CROSS_COUNTER: Color = Color(0.4, 0.9, 0.75)    # gd:235
const CROSS_LATTICE: Color = Color(0.6, 0.85, 1.0, 0.65)   # gd:147
const CROSS_LATTICE_EMIT: Color = Color(0.35, 0.55, 0.9)   # gd:151
const TORQUE_R: Color = Color(0.3, 0.8, 1.0)          # TorqueDemo gd:75
const TORQUE_F: Color = Color(1.0, 0.3, 0.3)          # gd:84
const TORQUE_T: Color = Color(0.8, 0.3, 1.0)          # gd:93
const TORQUE_COUNTER: Color = Color(0.45, 0.22, 0.62) # gd:226
const TORQUE_BALL: Color = Color(0.9, 0.5, 0.8)       # force_containment_base gd:87
const HELIX_STRAND_A: Color = Color(0.2, 0.85, 1.0)   # doublehelix gd:72
const HELIX_STRAND_B: Color = Color(1.0, 0.42, 0.75)  # gd:78
const HELIX_RUNG: Color = Color(0.7, 1.0, 0.6)        # gd:84
const HELIX_AXIS: Color = Color(0.35, 0.65, 1.0)      # gd:90
const ARC_COLOR: Color = Color(0.92, 0.92, 0.96)
const ORIGIN_COLOR: Color = Color(0.46, 0.47, 0.52)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("handedness"):
		handedness = _pick(str(config_data["handedness"]), HANDS, handedness)
	if config_data.has("figure"):
		figure = _pick(str(config_data["figure"]), FIGURES, figure)
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


# ── the frame ────────────────────────────────────────────────────────────────────────────

## a's direction: azimuth 60 degrees from +X toward -Z, in the floor plane.
func _a_dir() -> Vector3:
	return Vector3(cos(PI / 3.0), 0.0, -sin(PI / 3.0))


## b's direction: a turned a further quarter toward -Z. (Positive rotation about +Y takes
## +X to -Z, so this is a x b = +Y by construction, not by assertion.)
func _b_dir() -> Vector3:
	return Vector3(-sin(PI / 3.0), 0.0, -cos(PI / 3.0))


## The perpendicular the right hand names. Computed, so that if anyone edits a or b the
## arrow follows the product and not a constant.
func _n_dir() -> Vector3:
	return _a_dir().cross(_b_dir()).normalized()


## Which signs along n each handedness draws, primary first.
func _sides(hand: String) -> Array:
	if hand == "left":
		return [-1.0]
	if hand == "both":
		return [1.0, -1.0]
	return [1.0]


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var figs: Array = []
	if layout == "ladder":
		for f in FIGURES:
			figs.append(f)
	else:
		figs.append(_pick(figure, FIGURES, "cross"))
	var hand: String = _pick(handedness, HANDS, "right")
	var count: int = figs.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = str(figs[i])
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_figure(holder, str(figs[i]), hand)


## One figure under one handedness.
func _build_figure(holder: Node3D, fig: String, hand: String) -> void:
	var a: Vector3 = _a_dir() * A_LEN
	var b: Vector3 = _b_dir() * B_LEN
	var n: Vector3 = _n_dir()
	var sides: Array = _sides(hand)
	# The turning sense from a toward b: the datum every hand shares.
	holder.add_child(_arc())
	if fig == "torque":
		holder.add_child(_sphere(Vector3.ZERO, PIVOT_R, TORQUE_BALL, 0.1, "Pivot"))
		holder.add_child(_arrow(Vector3.ZERO, a, AB_R, AB_HEAD_R, AB_HEAD_L, TORQUE_R, 0.25, "LeverR"))
		holder.add_child(_arrow(a, b, AB_R, AB_HEAD_R, AB_HEAD_L, TORQUE_F, 0.25, "ForceF"))
		for k in range(sides.size()):
			var s: float = float(sides[k])
			var c: Color = TORQUE_T if k == 0 else TORQUE_COUNTER
			holder.add_child(_arrow(Vector3.ZERO, n * s * PERP_LEN, PERP_R, PERP_HEAD_R, PERP_HEAD_L,
					c, 0.3, "Torque" if s > 0.0 else "TorqueMirror"))
		return
	if fig == "helix":
		holder.add_child(_sphere(Vector3.ZERO, ORIGIN_R, ORIGIN_COLOR, 0.0, "Origin"))
		holder.add_child(_arrow(Vector3.ZERO, a, AB_R, AB_HEAD_R, AB_HEAD_L, CROSS_A, 0.2, "VectorA"))
		holder.add_child(_arrow(Vector3.ZERO, b, AB_R, AB_HEAD_R, AB_HEAD_L, CROSS_B, 0.2, "VectorB"))
		for k in range(sides.size()):
			var s: float = float(sides[k])
			var dim: float = 1.0 if k == 0 else COUNTER_DIM
			holder.add_child(_arrow(Vector3.ZERO, n * s * PERP_LEN, HELIX_AXIS_R, HELIX_AXIS_HEAD_R,
					HELIX_AXIS_HEAD_L, _dimmed(HELIX_AXIS, dim), 0.3, "Axis" if s > 0.0 else "AxisMirror"))
			_add_helix(holder, s, dim)
		return
	# cross
	holder.add_child(_sphere(Vector3.ZERO, ORIGIN_R, ORIGIN_COLOR, 0.0, "Origin"))
	holder.add_child(_lattice(a, b))
	holder.add_child(_arrow(Vector3.ZERO, a, AB_R, AB_HEAD_R, AB_HEAD_L, CROSS_A, 0.25, "VectorA"))
	holder.add_child(_arrow(Vector3.ZERO, b, AB_R, AB_HEAD_R, AB_HEAD_L, CROSS_B, 0.25, "VectorB"))
	for k in range(sides.size()):
		var s: float = float(sides[k])
		var c: Color = CROSS_N if k == 0 else CROSS_COUNTER
		holder.add_child(_arrow(Vector3.ZERO, n * s * PERP_LEN, PERP_R, PERP_HEAD_R, PERP_HEAD_L,
				c, 0.3, "AxB" if s > 0.0 else "BxA"))


# ── the bodies ───────────────────────────────────────────────────────────────────────────

## A double helix around the perpendicular. Strand A starts on a and turns toward b as it
## advances along sign * n; strand B is a half turn behind. Turning a -> b while advancing
## along a x b is a right-hand screw; along b x a it is a left-hand one. Same radius, same
## pitch, same rungs, same colours: only the side of the plane, and with it the hand.
func _add_helix(holder: Node3D, side: float, dim: float) -> void:
	var ah: Vector3 = _a_dir()
	var bh: Vector3 = _b_dir()
	var n: Vector3 = _n_dir() * side
	var total: int = HELIX_TURNS * HELIX_PPT
	var lift: float = 0.02   # the first ring stands just off the plane so the strands read
	var pa: PackedVector3Array = PackedVector3Array()
	var pb: PackedVector3Array = PackedVector3Array()
	for i in range(total + 1):
		var t: float = float(i) / float(total)
		var ang: float = t * float(HELIX_TURNS) * TAU
		var along: float = lift + HELIX_H * t
		var ring_a: Vector3 = (ah * cos(ang) + bh * sin(ang)) * HELIX_R
		var ring_b: Vector3 = (ah * cos(ang + PI) + bh * sin(ang + PI)) * HELIX_R
		pa.append(ring_a + n * along)
		pb.append(ring_b + n * along)
	var suffix: String = "" if side > 0.0 else "Mirror"
	holder.add_child(_tube(pa, HELIX_STRAND_R, _dimmed(HELIX_STRAND_A, dim), 0.35, "StrandA" + suffix))
	holder.add_child(_tube(pb, HELIX_STRAND_R, _dimmed(HELIX_STRAND_B, dim), 0.35, "StrandB" + suffix))
	var rungs := Node3D.new()
	rungs.name = "Rungs" + suffix
	var ri: int = 0
	while ri <= total:
		rungs.add_child(_rod(pa[ri], pb[ri], _dimmed(HELIX_RUNG, dim), HELIX_RUNG_R, "Rung%d" % ri))
		ri += HELIX_RUNG_EVERY
	holder.add_child(rungs)


## VectorCrossProduct's `span = grid`: LATTICE_N + 1 lines along a at b-subdivisions and
## LATTICE_N + 1 along b at a-subdivisions (gd:205-219), each a ribbon LATTICE_W wide lying
## in the plane, one mesh, unshaded and emissive like its material (gd:146-153).
func _lattice(a: Vector3, b: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "ParallelogramGrid"
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: Vector3 = _n_dir()
	var half: float = LATTICE_W * 0.5
	for i in range(LATTICE_N + 1):
		var t: float = float(i) / float(LATTICE_N)
		# Along a, offset by b * t.
		_ribbon(st, b * t, a + b * t, n.cross(a).normalized() * half, n)
		# Along b, offset by a * t.
		_ribbon(st, a * t, a * t + b, n.cross(b).normalized() * half, n)
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = CROSS_LATTICE
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = CROSS_LATTICE_EMIT
	m.emission_energy_multiplier = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi


func _ribbon(st: SurfaceTool, p0: Vector3, p1: Vector3, w: Vector3, normal: Vector3) -> void:
	var quad: Array = [p0 - w, p0 + w, p1 - w, p1 - w, p0 + w, p1 + w]
	for j in range(quad.size()):
		var p: Vector3 = quad[j]
		st.set_normal(normal)
		st.add_vertex(p)


## The turning sense from a toward b: a quarter arc at ARC_R in the plane with a small head
## on the b end. It is the same at every handedness — that is the point of drawing it.
func _arc() -> Node3D:
	var root := Node3D.new()
	root.name = "TurnArc"
	var ah: Vector3 = _a_dir()
	var bh: Vector3 = _b_dir()
	var pts: PackedVector3Array = PackedVector3Array()
	var steps: int = 24
	for i in range(steps + 1):
		var t: float = float(i) / float(steps) * (PI * 0.5 - 0.12)
		pts.append((ah * cos(t) + bh * sin(t)) * ARC_R)
	root.add_child(_tube(pts, ARC_TUBE_R, ARC_COLOR, 0.25, "Arc"))
	var end_t: float = PI * 0.5 - 0.12
	var tip_from: Vector3 = (ah * cos(end_t) + bh * sin(end_t)) * ARC_R
	var tangent: Vector3 = (-ah * sin(end_t) + bh * cos(end_t)).normalized()
	var head := _cone(tip_from, tangent, 0.012, 0.03, ARC_COLOR, 0.25, "ArcHead")
	root.add_child(head)
	return root


# ── mesh helpers ─────────────────────────────────────────────────────────────────────────

func _dimmed(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, c.a)


## An arrow from `base` along `vec`: shaft cylinder plus cone, both along the holder's local
## +Y, the holder's basis built proper (determinant +1) so nothing here mirrors anything.
func _arrow(base: Vector3, vec: Vector3, r: float, head_r: float, head_l: float, c: Color,
		emit: float, label: String) -> Node3D:
	var root := Node3D.new()
	root.name = label
	var length: float = vec.length()
	if length < 1e-5:
		return root
	root.position = base
	root.basis = _basis_y(vec / length)
	var hl: float = minf(head_l, length * 0.4)
	var shaft_l: float = length - hl
	var shaft := _cylinder(Vector3(0.0, shaft_l * 0.5, 0.0), r, shaft_l, c, emit, "Shaft")
	root.add_child(shaft)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = head_r
	cone.height = hl
	cone.radial_segments = 16
	cone.rings = 0
	head.mesh = cone
	head.position = Vector3(0.0, shaft_l + hl * 0.5, 0.0)
	head.material_override = _mat(c, emit, false)
	root.add_child(head)
	return root


func _cone(at: Vector3, dir: Vector3, r: float, h: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = r
	cone.height = h
	cone.radial_segments = 12
	cone.rings = 0
	mi.mesh = cone
	mi.basis = _basis_y(dir.normalized())
	mi.position = at + dir.normalized() * h * 0.5
	mi.material_override = _mat(c, emit, false)
	return mi


## A right-handed orthonormal basis whose Y axis is `y`. x = helper x y, z = x x y, so
## det = +1: a proper rotation, never a reflection.
func _basis_y(y: Vector3) -> Basis:
	var helper: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var x: Vector3 = helper.cross(y).normalized()
	var z: Vector3 = x.cross(y).normalized()
	return Basis(x, y, z)


## A round tube along a polyline with rotation-minimising frames, normals outward, culling
## off (regime_threshold's helper).
func _tube(pts: PackedVector3Array, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var count: int = pts.size()
	if count < 2:
		return mi
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


func _sphere(at: Vector3, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = at
	mi.material_override = _mat(c, emit, false)
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
	if dir.length_squared() > 0.5:
		mi.basis = _basis_y(dir)
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
