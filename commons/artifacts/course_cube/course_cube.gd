extends Node3D
class_name CourseCube

## course_cube — two translations in the opposite order are the SAME translation. The
## difference between them is not in the answer, it is in the road.
##
## THE FAMILY. Four registry tokens declare an axis called `course`, and they are not four
## artifacts:
##
##   x_translation_cube  res://commons/artifacts/axis_translation_cube/x_translation_cube.tscn
##   y_translation_cube  res://commons/artifacts/axis_translation_cube/y_translation_cube.tscn
##   z_translation_cube  res://commons/artifacts/axis_translation_cube/z_translation_cube.tscn
##
## Three .tscn files, ONE script (axis_translation_cube.gd), and the whole difference between
## the three scenes is three lines each: `axis` 0/1/2, `course` lateral/lift/depth, and a
## colour. The script says so itself at gd:46 — "ONE BODY, FOUR NAMES" (four, because
## axis_translation_cube.tscn is the same script again with nothing overridden). This is the
## SIXTH time the corpus has found one scene wearing several registry names. The fourth
## member, translation_cube_demo, is a genuinely separate object
## (res://commons/primitives/translation/translation_cube_demo.gd, a two-door puzzle).
##
## TWO VOCABULARIES, AND ONLY ONE OF THEM NAMES A COMPOSITE MOVE.
##   x_/y_/z_translation_cube  course = lateral | lift | depth   (gd:66, default "lift")
##   translation_cube_demo     course = lift_lateral | lateral_lift | lift_depth |
##                                      lateral | free           (gd:45, default "lift_lateral")
## The three cubes travel ONCE, so their three words are three single runs of space. The door
## concedes permission in an ORDER, so its five words are ordered PLANS. The second list is
## taken here, because it is the only one in which the argument below can be stated at all.
##
## THE ARGUMENT, and it is checkable. `lift_lateral` and `lateral_lift` are the same two
## moves dealt the other way round. Translations form an ABELIAN group: u + v = v + u. So
## the two words name one destination, and an axis that tells them apart is telling apart the
## PATH, not the RESULT. The member's code agrees, and it agrees in the arithmetic rather
## than in a comment — translation_cube_demo._path_points (gd:230-238) walks the legs and
## accumulates, so for lift_lateral it returns S, S+Y·t, S+Y·t+X·s and for lateral_lift it
## returns S, S+X·s, S+X·s+Y·t. Different middles. IDENTICAL last element. `free` is the same
## corner again by a third road (gd:219-220 builds one diagonal leg whose span is the length
## of that same sum).
##
## SO IS THE MEMBER'S AXIS TIME-DOMAIN? No — and that is worth saying, because this corpus
## has been burned by rate-and-duration axes that a still cannot photograph (info_board's six
## identical tiles). translation_cube_demo has no _process and no Timer. The order is enforced
## in constrained_door's _physics_process on a GRABBED knob, which is invisible in a still,
## but the order is also BUILT: the arrows, the slot plate and the rail rods are all drawn
## from _path_points, so the elbow is standing geometry. The member's order axis is legible
## in a still under guide=arrows|slot|rail — and it is INVISIBLE under guide=ghost, which
## draws only pts[pts.size()-1] (gd:597). Three of that artifact's five course values render
## byte-identical in that column, and nobody registered it. That undeclared null is the seed
## of this artifact.
##
## WHAT THIS ONE IS. One cube, one start, one end, and the road between them built as real
## geometry — a tube through the corner it turns. `course` deals the legs. `reading` decides
## what is in the frame: the road, the two ends, or the displacement and the basis it carries.
## Under `ends` and under `frame`, lift_lateral, lateral_lift and free are ONE PICTURE, and
## that is not a failure of the axis, it is the group law photographed.

## COURSE — the plan the displacement follows. translation_cube_demo's five words, its order,
## its default. Each leg runs LEG = 0.44 m, so every course ends inside the same 0.68 m box.
##
##   lift_lateral  up, then across. The shipped plan, and the family default. Elbow at the
##                 TOP LEFT of the square (up first, then out).
##   lateral_lift  across, then up. The same two moves dealt the other way. Elbow at the
##                 BOTTOM RIGHT. Same start, same end, other road — this against lift_lateral
##                 is the artifact's whole claim.
##   lift_depth    up, then INTO the picture. The second leg runs along the axis the camera
##                 foreshortens hardest (+Z lies 0.79 along the sweep's view direction, so it
##                 photographs at 62% of its length), which is z_translation_cube's own lesson
##                 — the same displacement read almost entirely as scale.
##   lateral       one leg and no turn. The degenerate case: the family's `lateral` survives
##                 into this vocabulary unchanged, so this value is BOTH lists at once.
##   free          both moves conceded at once — one diagonal to the same corner as
##                 lift_lateral. No elbow. The negative case: with no order there is no corner
##                 to see, and the destination is the only thing left.
@export_enum("lift_lateral", "lateral_lift", "lift_depth", "lateral", "free") var course: String = "lift_lateral":
	set(v):
		course = v
		if is_inside_tree():
			_rebuild()

## READING — what is left in the frame as evidence that a translation happened. Descended
## from axis_translation_cube's second axis `account` (ghost | sweep | terminus | formula |
## none, gd:95), narrowed to the three that are geometry rather than typography.
##
##   path   the road. A 60 mm tube along every leg, a junction ball at the corner it turns,
##          and the cube at the far end. The only reading in which an order is a picture.
##   ends   the destination. Two cubes — dim where it started, bright where it finished —
##          and nothing whatever in between. This is `account = terminus` exactly: the figure
##          a textbook draws. It is also where lift_lateral, lateral_lift and free MUST be
##          one frame, because what it photographs is the group element.
##   frame  the operation. No cubes: the three basis arrows at the start, the same three
##          arrows carried to the end (parallel, unrotated — translation preserves the frame),
##          and the resultant displacement as one straight arrow. The arrows are painted the
##          three members' own cube_color values: +X is x_translation_cube's red-orange, +Y
##          is y_translation_cube's green, +Z is z_translation_cube's blue. Path-blind by
##          construction, like `ends`, for the same reason.
@export_enum("path", "ends", "frame") var reading: String = "path":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## One course, or all five in a row. NOT PART OF EITHER AXIS — an all-rungs value declared
## inside an axis makes capture_config_sweep union the row's AABB with every single and
## photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

const COURSES: PackedStringArray = ["lift_lateral", "lateral_lift", "lift_depth", "lateral", "free"]
const READINGS: PackedStringArray = ["path", "ends", "frame"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

## The family's body: axis_translation_cube builds its cube with this shader and nothing else
## (gd:21). It is opaque with bright barycentric edges, so a cube here is a solid mass that
## still reads as the family's wireframe.
const GRID_SHADER: Shader = preload("res://commons/resourses/shaders/Grid.gdshader")

# ── the one journey, metres ────────────────────────────────────────────────────────────
const LEG: float = 0.44           ## every leg, on every course. Equal legs is what makes
                                  ## lift_lateral and lateral_lift mirror images rather than
                                  ## merely different.
const CUBE: float = 0.20          ## the travelling body
const CENTRE_Y: float = 0.55      ## height of the centre of the travel box
const TRIAD: float = 0.15         ## basis arrow length, tip included

# ── marks ─────────────────────────────────────────────────────────────────────────────
## Everything here is thick for its span, on purpose. A rod artifact in a 0.69 m box is thin
## marks in a large volume: at 44 mm the whole subject came out at 2.1% of frame in a replica
## raster, and the corpus's own rule of thumb calls anything under ~6% too small to trust.
## 60 mm is 8.7% of the body and puts the subject over that bar without moving the camera in
## far enough to risk clipping the widest variant.
const TUBE_R: float = 0.030       ## the road: 60 mm
const CORNER_R: float = 0.042     ## junction ball at the elbow
const ARROW_R: float = 0.014      ## basis arrow shaft
const RESULT_R: float = 0.021     ## the resultant displacement arrow
const HEAD_R: float = 0.034       ## arrowhead base radius
const HEAD_L: float = 0.060       ## arrowhead length
const TUBE_SIDES: int = 8
const LADDER_PITCH: float = 0.80

const ROUTE_COLOR: Color = Color(0.98, 0.72, 0.22)   ## amber: the road, and the resultant
const BODY_COLOR: Color = Color(0.84, 0.87, 0.92)    ## the travelling cube, deliberately
                                                     ## neutral so the basis keeps the
                                                     ## family's three colours to itself
const START_COLOR: Color = Color(0.40, 0.44, 0.52)   ## where it was
const AXIS_X_COLOR: Color = Color(1.00, 0.40, 0.30)  ## x_translation_cube.tscn cube_color
const AXIS_Y_COLOR: Color = Color(0.30, 0.80, 0.40)  ## y_translation_cube.tscn cube_color
const AXIS_Z_COLOR: Color = Color(0.30, 0.50, 1.00)  ## z_translation_cube.tscn cube_color

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = _pick(str(config_data["layout"]), LAYOUTS, layout)
	if config_data.has("course"):
		course = _pick(str(config_data["course"]), COURSES, course)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
	_rebuild()


## An unknown word keeps the value already held rather than silently rendering as one.
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
		for c in COURSES:
			names.append(c)
	else:
		names.append(_pick(course, COURSES, "lift_lateral"))
	var n: int = names.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = str(names[i])
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, str(names[i]))


# ── the course, as a plan ──────────────────────────────────────────────────────────────
# A direct port of translation_cube_demo._leg_plan (gd:205-226) with the door's two spans
# replaced by one LEG, because the argument is about ORDER and a longer first leg would put
# a length difference inside it. `free` keeps the member's own construction verbatim: one
# leg, direction normalised, span the length of the same vector sum.

func _leg_plan(c: String) -> Array:
	var lift: Vector3 = Vector3(0.0, 1.0, 0.0)
	var side: Vector3 = Vector3(1.0, 0.0, 0.0)
	var into: Vector3 = Vector3(0.0, 0.0, 1.0)
	match c:
		"lateral_lift":
			return [{"dir": side, "span": LEG}, {"dir": lift, "span": LEG}]
		"lift_depth":
			return [{"dir": lift, "span": LEG}, {"dir": into, "span": LEG}]
		"lateral":
			return [{"dir": side, "span": LEG}]
		"free":
			var diagonal: Vector3 = lift * LEG + side * LEG
			return [{"dir": diagonal.normalized(), "span": diagonal.length()}]
		_:
			return [{"dir": lift, "span": LEG}, {"dir": side, "span": LEG}]


## The start, placed so that the union of every course sits centred on the vertical axis.
func _start_point() -> Vector3:
	return Vector3(-LEG * 0.5, CENTRE_Y - LEG * 0.5, -LEG * 0.5)


## Corner points of the road, walking the plan. The member's own accumulation, which is where
## the commutation actually lives: each component of the end point receives exactly ONE
## addition whichever order the legs are dealt in, so lift_lateral and lateral_lift end at the
## same point to the bit.
func _path_points(c: String) -> PackedVector3Array:
	var pts: PackedVector3Array = PackedVector3Array()
	var p: Vector3 = _start_point()
	pts.append(p)
	for leg in _leg_plan(c):
		var d: Vector3 = leg["dir"]
		var s: float = leg["span"]
		p = p + d * s
		pts.append(p)
	return pts


func _build_variant(holder: Node3D, c: String) -> void:
	var pts: PackedVector3Array = _path_points(c)
	var s: Vector3 = pts[0]
	var e: Vector3 = pts[pts.size() - 1]
	match _pick(reading, READINGS, "path"):
		"ends":
			_add_cube(holder, s, START_COLOR, 0.10, "StartCube")
			_add_cube(holder, e, BODY_COLOR, 0.55, "EndCube")
		"frame":
			_add_triad(holder, s, 0.10, "Start")
			_add_triad(holder, e, 0.65, "End")
			_add_arrow(holder, s, e, RESULT_R, ROUTE_COLOR, 0.45, "Resultant")
		_:
			_add_route(holder, pts)
			_add_cube(holder, e, BODY_COLOR, 0.55, "EndCube")
	_add_extent_anchor(holder)


# ── reading: path ──────────────────────────────────────────────────────────────────────

## The road as a body. One tube per leg — per leg, not one polyline, so the corner is a real
## mitre rather than a smoothed bend — plus a junction ball at every interior point. `lateral`
## and `free` have no interior point and get no ball, which is the honest picture of them:
## a course with no order has no corner to show.
func _add_route(holder: Node3D, pts: PackedVector3Array) -> void:
	for i in range(pts.size() - 1):
		var seg: PackedVector3Array = PackedVector3Array([pts[i], pts[i + 1]])
		holder.add_child(_tube(seg, TUBE_R, ROUTE_COLOR, 0.35, "Leg%d" % i))
	for i in range(1, pts.size() - 1):
		holder.add_child(_ball(pts[i], CORNER_R, ROUTE_COLOR, 0.45, "Corner%d" % i))


# ── reading: frame ─────────────────────────────────────────────────────────────────────

## The three basis arrows, in the three members' own colours, at one point. Drawn identically
## at the start and at the end: a translation moves the frame and turns nothing.
func _add_triad(holder: Node3D, at: Vector3, emit: float, label: String) -> void:
	_add_arrow(holder, at, at + Vector3(TRIAD, 0.0, 0.0), ARROW_R, AXIS_X_COLOR, emit, label + "X")
	_add_arrow(holder, at, at + Vector3(0.0, TRIAD, 0.0), ARROW_R, AXIS_Y_COLOR, emit, label + "Y")
	_add_arrow(holder, at, at + Vector3(0.0, 0.0, TRIAD), ARROW_R, AXIS_Z_COLOR, emit, label + "Z")


## Shaft plus a solid head, tip exactly at `to`.
func _add_arrow(holder: Node3D, from: Vector3, to: Vector3, r: float, c: Color, emit: float, label: String) -> void:
	var span: Vector3 = to - from
	var length: float = span.length()
	if length < 1e-5:
		return
	var dir: Vector3 = span / length
	var head: float = minf(HEAD_L, length * 0.6)
	var neck: Vector3 = to - dir * head
	holder.add_child(_tube(PackedVector3Array([from, neck]), r, c, emit, label + "Shaft"))
	var cone := MeshInstance3D.new()
	cone.name = label + "Head"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = HEAD_R
	cm.height = head
	cm.radial_segments = 12
	cone.mesh = cm
	cone.transform = Transform3D(_aligned_basis(dir), (neck + to) * 0.5)
	cone.material_override = _mat(c, emit)
	holder.add_child(cone)


## A basis whose +Y runs along `dir` — cylinders stand on Y. translation_cube_demo's own
## helper (gd:477-484) with ONE CORRECTION, and it is a real bug in the member rather than a
## stylistic difference: the demo's last line is `fwd = up.cross(right)`, which is -(X × Y),
## so the basis it returns has determinant -1. A reflected basis inverts the transformed
## normals, and every rail rod and end stop the demo draws under guide=rail is therefore lit
## from inside. It goes unnoticed there because a cylinder is rotationally symmetric and the
## silhouette is right. Here the arrowheads are the smallest marks in the frame and a dark
## cone would be a fact about a cross product, so the cross is taken the other way round:
## Z = X × Y, determinant +1.
func _aligned_basis(dir: Vector3) -> Basis:
	var up: Vector3 = dir.normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(up.dot(ref)) > 0.99:
		ref = Vector3.FORWARD
	var right: Vector3 = ref.cross(up).normalized()
	var fwd: Vector3 = right.cross(up).normalized()
	return Basis(right, up, fwd)


# ── the constant extent ────────────────────────────────────────────────────────────────

## capture_config_sweep fits the frame by the subtree's bounding-box diagonal and refits for
## every variant, so without this the `lateral` course — one flat leg and no rise — would be
## photographed from closer than the others and its whole frame would shift. The bite report
## would then be a picture of a zoom. axis_translation_cube learned this and shipped the same
## fix (gd:671-687); the box here is the union over BOTH axes and all five courses, so every
## one of the fifteen variants has the identical AABB: 0.69 m cubed, centred
## (0.025, 0.575, 0.025). It is not padding — the visible geometry reaches every face of it
## (the start cube the three low ones, the lift_lateral end cube and the end triads the rest).
##
## layers = 0, NOT visible = false: a zero-layer VisualInstance3D is in no camera's cull mask,
## draws nothing, and still reports its AABB. visible = false would hide it AND everything
## under it and would also remove it from the fit.
func _add_extent_anchor(holder: Node3D) -> void:
	var s: Vector3 = _start_point()
	var reach: float = maxf(CUBE * 0.5, TRIAD)
	var lo: Vector3 = s - Vector3.ONE * (CUBE * 0.5)
	var hi: Vector3 = s + Vector3.ONE * (LEG + reach)
	var anchor := MeshInstance3D.new()
	anchor.name = "ExtentAnchor"
	var box := BoxMesh.new()
	box.size = hi - lo
	anchor.mesh = box
	anchor.position = (lo + hi) * 0.5
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(anchor)


# ── mesh helpers ───────────────────────────────────────────────────────────────────────

func _add_cube(holder: Node3D, at: Vector3, c: Color, emit: float, label: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = label
	var box := BoxMesh.new()
	box.size = Vector3(CUBE, CUBE, CUBE)
	mi.mesh = box
	var mat := ShaderMaterial.new()
	mat.shader = GRID_SHADER
	mat.set_shader_parameter("modelColor", Color(c.r * 0.22, c.g * 0.22, c.b * 0.22, 1.0))
	mat.set_shader_parameter("wireframeColor", c)
	mat.set_shader_parameter("emissionColor", Color(c.r, c.g, c.b, 1.0))
	mat.set_shader_parameter("width", 3.0)
	mat.set_shader_parameter("blur", 0.5)
	mat.set_shader_parameter("emission_strength", emit)
	mat.set_shader_parameter("show_interior", true)
	mi.material_override = mat
	mi.position = at
	holder.add_child(mi)


## A round tube along a polyline, eight sides, rotation-minimising frames, normals outward
## per vertex, capped at both ends so a leg reads as a rod and not a pipe. Culling is off.
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
	for e in range(2):
		var ci: int = 0 if e == 0 else count - 1
		var ring2: Array = rings[ci]
		var cap_n: Vector3 = (pts[0] - pts[1]).normalized() if e == 0 else (pts[count - 1] - pts[count - 2]).normalized()
		for k in range(TUBE_SIDES):
			var k2b: int = (k + 1) % TUBE_SIDES
			var p0: Array = ring2[k]
			var p1: Array = ring2[k2b]
			st.set_normal(cap_n)
			st.add_vertex(pts[ci])
			st.set_normal(cap_n)
			st.add_vertex(p0[0])
			st.set_normal(cap_n)
			st.add_vertex(p1[0])
	mi.mesh = st.commit()
	mi.material_override = _mat(c, emit)
	return mi


func _ball(at: Vector3, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.position = at
	mi.material_override = _mat(c, emit)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
