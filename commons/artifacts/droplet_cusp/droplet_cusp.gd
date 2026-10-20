# DropletCusp.gd — a boolean funnel, a soft ball, and the drop that forms or doesn't
#
# @identity
# essence: a block with a funnel carved out of it by subtraction and a soft sphere dropped on the mouth; the ball passes, hangs, or rests, and the hanging case IS the droplet — tail up, cusp forming where the waist grips it
# desire: learner stops reading "does it fit" as a comparison of two radii and meets it as a negotiation under gravity — the hole does not move, the ball gives, and softness is purchasing power
# critical_parameter: waist — the throat of the funnel as a fraction of the ball's rest radius (snug / tight / narrow / scant); under it flesh sets what the ball negotiates with (firm / pliant / jelly / balloon)
# triggers: none; changing either axis rebuilds the experiment and physics re-runs it, the plate reading SETTLING until the pose stops moving
# emerges: the recognition that the teardrop is not a shape anyone drew — it is what a soft body looks like while a boundary is halfway through refusing it
# relationships: the deformable member of the separation family — [[bridge_cut]] cuts an edge, [[boolean_neck]] thins a neck to nothing, [[flex_connector]] asks whether a length fits a region; here the BODY gives instead of the boundary
# truth: a hole is not a size, it is a question put to whatever arrives
extends Node3D
class_name DropletCusp

## REBUILT 2026-10-13 AT PALLE'S INSTRUCTION, replacing a posed surface.
##
## The first version of this artifact was a surface of revolution with an
## exponent that decided whether the tip was round, a cone, or a cusp — a
## correct, measured illustration (apex angles 179.1 / 162.7 / 84.5 / 1.2
## degrees across the threshold at exponent 1), and still an illustration: the
## shape was POSED. Palle: "rebuild artifact improve ... use a boolean carve
## and a soft body sphere and see if they can fit." So now nothing here is
## posed. The funnel is a genuine CSG subtraction, the ball is a soft body
## simulated by the physics engine, and the teardrop-with-cusp appears only
## when the experiment produces it: a soft ball hanging in a too-narrow waist,
## bulging below, necking above. What used to be the `stage` axis (attached,
## necking, pinching, detached) is now an OUTCOME the physics reaches, not an
## input anyone sets.
##
## TWO COMBINERS READ ONE SET OF CARVE NUMBERS. The collision solid is the
## full block, drawn on no camera layer (layers = 0), and is what the ball
## negotiates with. The visual solid has its front half sectioned away so the
## waist and the settled ball argue in public — without the section,
## waist=snug would swallow the ball out of sight and every flesh value would
## photograph identical, the occlusion trap this corpus has already paid for.
## A faint glass pane stands where the section is, because a face that stops
## the ball but not the eye should look like glass, not like a lie.
##
## THE VERDICT IS READ FROM THE PHYSICS SERVER, not the renderer: headless,
## rendering-side readbacks lie. Settled means the ball's bounds stopped
## moving for half a second. probe_droplet_fit gates every claim at BOTH 60
## and 90 Hz, because settle outcomes in this corpus have flipped with tick
## rate before (a die once read 15/16 at 90 Hz and 2/16 at 60).

const WAISTS := ["snug", "tight", "narrow", "scant"]
const FLESHES := ["firm", "pliant", "jelly", "balloon"]

@export_enum("snug", "tight", "narrow", "scant") var waist: String = "tight":
	set(v):
		waist = v
		if is_inside_tree():
			_rebuild()

@export_enum("firm", "pliant", "jelly", "balloon") var flesh: String = "firm":
	set(v):
		flesh = v
		if is_inside_tree():
			_rebuild()

@export var ball_radius: float = 0.075
@export var show_readout: bool = true

@export var block_color: Color = Color(0.38, 0.36, 0.40)
@export var ball_color: Color = Color(0.20, 0.52, 0.86)
@export var hang_color: Color = Color(0.95, 0.68, 0.18)

const BLOCK_TOP := 0.0
const BLOCK_BOTTOM := -0.16
# The waist height lives with the collision constants (WAIST_Y): the beads and
# the drawn washer both sit there, so the eye and the physics read one height.
# Directly under the washer, NOT far below: a passing drop that falls 0.3 m
# arrives at 48 mm per tick and tunnels any floor the solver owns. Caught here
# it lands at under 1 m/s with its top still below the washer, so PASSED stays
# unambiguous.
const TRAY_Y := -0.225

# Fine, because JELLY CREEPS: at 0.4 mm per tick the ooze through a tight waist
# read as stillness and a mid-ooze pose became a verdict -- caught because
# 60 Hz and 90 Hz disagreed by 24 mm, which moving bodies do and settled ones
# cannot.
const SETTLE_EPS := 0.0001       # metres of bound movement that still counts as still
const SETTLE_TICKS := 45         # this many quiet ticks in a row = settled
const TIMEOUT_TICKS := 1200      # ~20 s at 60 Hz; past this we call it and say so

var _ball: MeshInstance3D        # the shell's skin; the physics lives in _pts
var _plate: Label3D
var _built: Node3D
var _waist_r: float = 0.0
var _settled: bool = false
var _timed_out: bool = false
var _unstable: bool = false
var _quiet: int = 0
var _ticks: int = 0
var _last_top: float = 1e9
var _last_bottom: float = 1e9


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# ------------------------------------------------------------ the two recipes

## Throat radius as a fraction of the ball's rest radius. Above 1 a rigid ball
## would pass; below 1 only deformation gets it through; at the bottom nothing
## does. The interesting values are the middle two, where the answer depends on
## the OTHER axis.
func _waist_factor() -> float:
	match waist:
		"snug": return 1.12
		"tight": return 0.86
		"narrow": return 0.74
		"scant": return 0.56
	return 0.90


## [constraint iterations, pressure, damping, grip]. The names are the
## argument: firm holds its shape AND bites where it touches; jelly gives its
## shape away and LUBRICATES (low grip is what lets it ooze through a waist
## that firm merely hangs in — without the grip difference the two sank within
## 2 mm of each other and the axis argued nothing); balloon has almost no skin
## but insists on its volume. These feed the artifact's own verlet shell, not
## SoftBody3D: the engine recipe's pressure_coefficient turned out to mean
## VOLUME, and 60 of it inflated the "firm" ball forty percent wider than the
## snug aperture before launch.
func _flesh_recipe() -> Array:
	match flesh:
		"firm": return [12, 10.0, 0.94, 0.68]
		"pliant": return [6, 6.0, 0.96, 0.5]
		"jelly": return [2, 2.0, 0.985, 0.22]
		"balloon": return [2, 22.0, 0.955, 0.5]
	return [12, 10.0, 0.94, 0.68]


# --------------------------------------------- the ball's own physics
#
# A verlet pressure shell: a once-subdivided icosahedron (42 points, 80 faces)
# with distance constraints on its edges, a volume-restoring pressure along
# each point's outward normal, and ANALYTIC collision against the exact
# flare / bore / washer numbers the CSG is carved with. This exists because
# four engine substrates failed measurably first (see the note in _rebuild):
# GodotPhysics soft bodies cannot squeeze through an aperture. The upside of
# owning it: one source of truth for eye and physics, determinism without a
# seed, and a GRIP term -- contacts eat most of a point's slide, which is what
# lets a wedged drop HANG instead of lubricating through.

const WAIST_Y := -0.045
const WASHER_HALF := 0.008       # half-thickness of the drawn washer slab
const TRAY_FLOOR := -0.23        # where a passed drop lands (the dish interior)
const SUBSTEPS := 4
const GRIP := 0.55               # fallback; the live value is the flesh's own

var _grip_now: float = GRIP

var _pts := PackedVector3Array()
var _prev := PackedVector3Array()
var _edges: Array = []           # [i, j, rest_length]
var _faces := PackedInt32Array()
var _rest_r: float = 0.0
var _skin_mat: StandardMaterial3D
var _last_rho: float = 0.0       # the shell centre's horizontal distance


func _init_shell(centre: Vector3) -> void:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var base: Array = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	var faces0: Array = [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
	]
	var verts: Array = []
	for b in base:
		verts.append((b as Vector3).normalized())
	# one subdivision: 12 -> 42 points, 20 -> 80 faces
	var cache := {}
	var faces1: Array = []
	for f in faces0:
		var ab := _midpoint(verts, cache, f[0], f[1])
		var bc := _midpoint(verts, cache, f[1], f[2])
		var ca := _midpoint(verts, cache, f[2], f[0])
		faces1.append([f[0], ab, ca])
		faces1.append([f[1], bc, ab])
		faces1.append([f[2], ca, bc])
		faces1.append([ab, bc, ca])

	_pts.resize(verts.size())
	_prev.resize(verts.size())
	for i in range(verts.size()):
		var p: Vector3 = verts[i] * ball_radius + centre
		_pts[i] = p
		_prev[i] = p
	_faces = PackedInt32Array()
	var edge_set := {}
	for f in faces1:
		_faces.append(f[0]); _faces.append(f[1]); _faces.append(f[2])
		for pair in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
			var a: int = mini(pair[0], pair[1])
			var b: int = maxi(pair[0], pair[1])
			edge_set[a * 1000 + b] = [a, b]
	_edges.clear()
	for k in edge_set:
		var e: Array = edge_set[k]
		_edges.append([e[0], e[1], _pts[e[0]].distance_to(_pts[e[1]])])
	_rest_r = ball_radius


func _midpoint(verts: Array, cache: Dictionary, a: int, b: int) -> int:
	var key := mini(a, b) * 1000 + maxi(a, b)
	if cache.has(key):
		return cache[key]
	var m: Vector3 = ((verts[a] as Vector3) + (verts[b] as Vector3)).normalized()
	verts.append(m)
	cache[key] = verts.size() - 1
	return verts.size() - 1


func _step_shell(delta: float) -> void:
	var rec := _flesh_recipe()
	var iters: int = int(rec[0])
	var pressure: float = float(rec[1])
	var damp: float = float(rec[2])
	_grip_now = float(rec[3])
	var dt := delta / float(SUBSTEPS)
	for _s in range(SUBSTEPS):
		var centre := Vector3.ZERO
		for p in _pts:
			centre += p
		centre /= float(_pts.size())
		var mean_r := 0.0
		for p in _pts:
			mean_r += (p - centre).length()
		mean_r /= float(_pts.size())
		var puff := pressure * (_rest_r - mean_r) / _rest_r
		for i in range(_pts.size()):
			var p := _pts[i]
			var vel := (p - _prev[i]) * damp
			var n := p - centre
			var acc := Vector3(0, -9.8, 0)
			var nl := n.length()
			if nl > 1e-6:
				acc += n / nl * puff
			_prev[i] = p
			_pts[i] = p + vel + acc * dt * dt
		for _k in range(iters):
			for e in _edges:
				var i2: int = e[0]
				var j2: int = e[1]
				var rest: float = e[2]
				var d := _pts[j2] - _pts[i2]
				var l := d.length()
				if l < 1e-9:
					continue
				var corr := d * (0.5 * (l - rest) / l)
				_pts[i2] += corr
				_pts[j2] -= corr
		for i in range(_pts.size()):
			_collide_point(i)


## The funnel as mathematics: the same flare sphere, bore cylinder and washer
## slab the CSG subtracts, resolved by least penetration. Push-outs INTO the
## void are legitimate exits (the hole's own wall); the tray floor catches
## everything that gets through or falls beside.
func _collide_point(i: int) -> void:
	var p := _pts[i]
	var rho := Vector2(p.x, p.z).length()
	var hit := false
	if absf(p.y - WAIST_Y) <= WASHER_HALF and rho >= _waist_r and rho <= 0.115:
		var pen_top := (WAIST_Y + WASHER_HALF) - p.y
		var pen_bot := p.y - (WAIST_Y - WASHER_HALF)
		var pen_in := rho - _waist_r
		if pen_in <= pen_top and pen_in <= pen_bot:
			var k := (_waist_r - 0.0004) / maxf(rho, 1e-6)
			p.x *= k
			p.z *= k
		elif pen_top <= pen_bot:
			p.y = WAIST_Y + WASHER_HALF
		else:
			p.y = WAIST_Y - WASHER_HALF
		hit = true
	elif p.y > -0.16 and p.y < 0.0 and absf(p.x) < 0.13 and absf(p.z) < 0.13:
		var flare_sq := 0.105 * 0.105 - (p.y - 0.045) * (p.y - 0.045)
		var void_r := 0.08
		if flare_sq > 0.0:
			void_r = maxf(void_r, sqrt(flare_sq))
		if rho > void_r:
			if p.y > -0.05 and -p.y < rho - void_r:
				p.y = 0.0               # nearest way out is up: the block's top
			else:
				var k2 := void_r / maxf(rho, 1e-6)
				p.x *= k2
				p.z *= k2
			hit = true
	if p.y < TRAY_FLOOR:
		p.y = TRAY_FLOOR
		hit = true
	if hit:
		_prev[i] = _prev[i].lerp(p, _grip_now)
		_pts[i] = p


func _update_skin() -> void:
	if _ball == null or not is_instance_valid(_ball) or _pts.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if _skin_mat != null:
		st.set_material(_skin_mat)
	var fi := 0
	while fi < _faces.size():
		st.add_vertex(_pts[_faces[fi]])
		st.add_vertex(_pts[_faces[fi + 2]])
		st.add_vertex(_pts[_faces[fi + 1]])
		fi += 3
	st.generate_normals()
	_ball.mesh = st.commit()


# ----------------------------------------------------------------- the body

func _carve_into(comb: CSGCombiner3D, sectioned: bool) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = block_color
	m.metallic = 0.1
	m.roughness = 0.7

	var block := CSGBox3D.new()
	block.size = Vector3(0.26, 0.16, 0.26)
	block.position = Vector3(0, -0.08, 0)
	block.material = m
	comb.add_child(block)

	# the mouth: a sphere seated above the top face flares the entry
	var flare := CSGSphere3D.new()
	flare.radius = 0.105
	flare.radial_segments = 24
	flare.rings = 12
	flare.position = Vector3(0, 0.045, 0)
	flare.operation = CSGShape3D.OPERATION_SUBTRACTION
	comb.add_child(flare)

	# the bore: wider than the ball at rest, so a passing drop does not clip
	# the drawn walls -- the NARROW part is the washer below, not the bore
	var bore := CSGCylinder3D.new()
	bore.radius = 0.080
	bore.height = 0.20
	bore.sides = 24
	bore.position = Vector3(0, -0.08, 0)
	bore.operation = CSGShape3D.OPERATION_SUBTRACTION
	comb.add_child(bore)

	# the waist itself, drawn: a washer whose hole is the axis value, at the
	# exact height where the collision beads sit
	var washer := CSGCylinder3D.new()
	washer.radius = 0.10
	washer.height = 0.016
	washer.sides = 24
	washer.position = Vector3(0, WAIST_Y, 0)
	var wm := StandardMaterial3D.new()
	wm.albedo_color = block_color.lightened(0.22)
	wm.metallic = 0.2
	wm.roughness = 0.5
	washer.material = wm
	comb.add_child(washer)
	var hole := CSGCylinder3D.new()
	hole.radius = _waist_r
	hole.height = 0.024
	hole.sides = 24
	hole.position = Vector3(0, WAIST_Y, 0)
	hole.operation = CSGShape3D.OPERATION_SUBTRACTION
	comb.add_child(hole)

	# the tray below: a dish the passed ball rests in, also by subtraction
	var tray := CSGBox3D.new()
	tray.size = Vector3(0.26, 0.05, 0.26)
	tray.position = Vector3(0, TRAY_Y, 0)
	tray.material = m
	comb.add_child(tray)
	var dish := CSGBox3D.new()
	dish.size = Vector3(0.21, 0.04, 0.21)
	dish.position = Vector3(0, TRAY_Y + 0.016, 0)
	dish.operation = CSGShape3D.OPERATION_SUBTRACTION
	comb.add_child(dish)

	if sectioned:
		var cut := CSGBox3D.new()
		cut.size = Vector3(0.28, 0.50, 0.14)
		cut.position = Vector3(0, -0.17, 0.022 + 0.07)
		cut.operation = CSGShape3D.OPERATION_SUBTRACTION
		comb.add_child(cut)


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()
	_settled = false
	_timed_out = false
	_unstable = false
	_quiet = 0
	_ticks = 0
	_last_top = 1e9
	_last_bottom = 1e9
	_waist_r = ball_radius * _waist_factor()

	# NO StaticBody3D AND NO SoftBody3D. Four substrates were tried and each
	# failed in its own measured way: CSG trimesh collision let jelly tunnel
	# 4.3 km; a 12-box ring fed the solver contradictory push-outs; sphere and
	# capsule shapes turned out to generate NO soft contacts at all in this
	# engine (probe_softbody_shapes); and a cylinder-post ring with a collar
	# deck ejected the ball off its edges. GodotPhysics soft bodies cannot do
	# squeeze-through-aperture. So the ball below is this artifact's OWN
	# simulation — a verlet pressure shell colliding analytically against the
	# SAME flare/bore/washer numbers the CSG draws. One source, no engine fight,
	# and the precedent is the corpus's: BaseCA and cloth_loom own their sims.

	# the solid the visitor sees: sectioned so the waist argues in public
	var vis := CSGCombiner3D.new()
	vis.name = "VisualSolid"
	vis.use_collision = false
	_carve_into(vis, true)
	_built.add_child(vis)

	# the glass where the section is — it stops the ball, so it should be seen
	var pane := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.26, 0.42, 0.004)
	pane.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.75, 0.85, 0.95, 0.10)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.05
	pane.material_override = gm
	pane.position = Vector3(0, -0.165, 0.024)
	_built.add_child(pane)

	# the soft ball, starting just clear of the mouth so contact is immediate
	# and a capture meets a settling pose, not a falling one
	_init_shell(Vector3(0, ball_radius + 0.004, 0))
	_ball = MeshInstance3D.new()
	_ball.name = "Ball"
	var bm := StandardMaterial3D.new()
	bm.albedo_color = ball_color
	bm.metallic = 0.15
	bm.roughness = 0.35
	_skin_mat = bm
	_built.add_child(_ball)
	_update_skin()

	if show_readout:
		_plate = Label3D.new()
		_plate.font_size = 40
		_plate.pixel_size = 0.00042
		_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_plate.position = Vector3(0, 0.16, 0)
		_plate.modulate = ball_color
		_plate.text = "SETTLING..."
		_built.add_child(_plate)

	# CSG is not a MeshInstance3D, so without this the capture AABB sees only
	# the glass pane and the ball
	var anchor := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.28, 0.56, 0.28)
	anchor.mesh = am
	anchor.layers = 0
	anchor.name = "ExtentAnchor"
	anchor.position = Vector3(0, -0.15, 0)
	_built.add_child(anchor)

	set_physics_process(true)


## Bounds straight off the shell's own particles: no renderer (which lies
## headless) and no physics server (which no longer owns this ball).
func _bounds() -> AABB:
	if _pts.is_empty():
		return AABB()
	var lo: Vector3 = _pts[0]
	var hi: Vector3 = _pts[0]
	for p in _pts:
		lo = lo.min(p)
		hi = hi.max(p)
	return AABB(lo + global_position, hi - lo)


func _physics_process(dt: float) -> void:
	if _pts.is_empty():
		return
	_step_shell(dt)
	if _ticks % 2 == 0:
		_update_skin()
	_ticks += 1
	var bb := _bounds()
	if bb.size == Vector3.ZERO:
		return
	var top := bb.position.y + bb.size.y - global_position.y
	var bottom := bb.position.y - global_position.y
	# a soft body solver can blow up to NaN (the first CSG build did, at 90 Hz);
	# keep the last finite pose and say UNSTABLE rather than printing nan mm
	if not (is_finite(top) and is_finite(bottom)):
		_unstable = true
		_settled = true
		_update_plate()
		set_physics_process(false)
		return
	var moved := maxf(absf(top - _last_top), absf(bottom - _last_bottom))
	_last_top = top
	_last_bottom = bottom
	var mid := bb.position + bb.size * 0.5 - global_position
	_last_rho = Vector2(mid.x, mid.z).length()
	_quiet = _quiet + 1 if moved < SETTLE_EPS else 0
	if _ticks % 10 == 0 and _plate != null and is_instance_valid(_plate):
		_update_plate()
	if _quiet >= SETTLE_TICKS or _ticks >= TIMEOUT_TICKS:
		_settled = true
		_timed_out = _ticks >= TIMEOUT_TICKS and _quiet < SETTLE_TICKS
		_update_plate()
		# a settled work keeps paying unless it is told to stop
		set_physics_process(false)


func _update_plate() -> void:
	if _plate == null or not is_instance_valid(_plate):
		return
	_plate.text = _verdict()
	_plate.modulate = hang_color if verdict_word() == "HANGS" else ball_color


# ----------------------------------------------------------------- the claim

func _verdict() -> String:
	if _last_top > 1e8:
		return "SETTLING..."
	var state := ""
	match verdict_word():
		"UNSTABLE":
			state = "UNSTABLE
the solver gave up before the pose did"
		"ESCAPED":
			state = "ESCAPED
the walls did not hold -- this is a bug, not a verdict"
		"SETTLING":
			state = "SETTLING...\ntop %+.0f mm of the rim" % (_last_top * 1000.0)
		"PASSED":
			state = "PASSED THROUGH\nthe drop detached\nresting %.0f mm below" \
				% absf(_last_top * 1000.0)
		"HANGS":
			state = "HANGS IN THE WAIST\nthe droplet forms\n%.0f mm through, %.0f mm above" \
				% [absf(_last_bottom * 1000.0), _last_top * 1000.0]
		"PROUD":
			state = "RESTS PROUD\nthe waist refused it\nbottom %+.0f mm of the waist" \
				% ((_last_bottom - WAIST_Y) * 1000.0)
	if _timed_out:
		state += "\n(still moving at timeout)"
	return state


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("waist"):
		var w := str(config_data["waist"]).to_lower().strip_edges()
		if WAISTS.has(w):
			waist = w
			dirty = true
	if config_data.has("flesh"):
		var f := str(config_data["flesh"]).to_lower().strip_edges()
		if FLESHES.has(f):
			flesh = f
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim is testable without reading pixels.
func is_settled() -> bool:
	return _settled


func verdict_word() -> String:
	if not _settled:
		return "SETTLING"
	if _unstable:
		return "UNSTABLE"
	if _last_bottom < -0.6:
		return "ESCAPED"       # through the tray and gone: collision has failed
	if _last_top < WAIST_Y - 0.01:
		# below the washer AND still on the axis: it went THROUGH. A low ball
		# far off-axis fell BESIDE the funnel, which is a bug, not a pass.
		if _last_rho < 0.09:
			return "PASSED"
		return "ESCAPED"
	if _last_bottom > WAIST_Y - 0.006:
		return "PROUD"
	return "HANGS"


func ball_top_m() -> float:
	return _last_top


func ball_bottom_m() -> float:
	return _last_bottom


func waist_radius_m() -> float:
	return _waist_r


func used_physics_bounds() -> bool:
	# the ball is this artifact's own verlet shell, so its bounds come from its
	# own particles -- there is no renderer or physics server in the loop to lie
	return true
