# ForbiddenBands.gd — a body settles where the rim permits
#
# @identity
# essence: a tilted dish whose rim carries raised red sectors; a soft ball rolls downhill, meets whatever stands there, and comes to rest in the nearest arc the bands leave open — the resting azimuth is the artifact's answer
# desire: learner stops reading a constraint as a line in a rulebook and meets it as a place their body cannot stay — nothing forbids the downhill point except that something is standing on it
# critical_parameter: bands — how much of the rim is taken (none / pair / quartet / belt); under it lean decides whether the body ever reaches the rim at all, and at level the bands are never met
# triggers: none; changing either axis rebuilds the dish and the physics re-runs, the plate reading SETTLING until the pose stops moving
# emerges: the recognition that an allowed region is what remains after everyone else's claims, and that a body does not need to know the rule — it finds the gap by being refused everywhere else
# relationships: the placement member of the separation family — [[droplet_cusp]] asks whether a body fits THROUGH a boundary, this one asks where a body may STAND on it; the deflection it measures is the Q at the blanket's edge made physical
# truth: where you come to rest is the shape of what refused you
extends Node3D
class_name ForbiddenBands

## FROM THE SOURCE FIGURE, by way of Palle's reading. The figure shows a region
## whose boundary carries reveal bands that an allowed strip must avoid; the
## physical version tilts the whole question into gravity. Downhill is the
## body's preference; the bands are what stands on it. With no bands the ball
## rests at azimuth zero, straight downhill -- the control that proves any
## deflection afterwards is the bands' doing. A pair of bands straddling
## downhill forces the ball sideways past the band's edge by a measured angle.
## A belt leaves no clear arc, and the ball rests ON the forbidden -- when
## everything is foreclosed, refusal has nowhere to send you.
##
## The ball is the same owned verlet pressure shell as droplet_cusp, for the
## same measured reason: engine soft bodies cannot negotiate geometry like
## this. The dish is analytic -- a tilted paraboloid with a hard outer wall and
## band bumpers 18 mm deep at the rim -- so the eye's dish and the physics'
## dish are one set of numbers.
##
## THE BANDS SIT 14 DEGREES OFF THE DOWNHILL AXIS, deliberately: dead-symmetric
## bands put the ball on a knife-edge ridge where a deterministic sim can
## oscillate forever without picking a side (and at six degrees the tangential
## pull was too weak to beat even light friction). Fourteen degrees breaks it the
## same way every run, so two placements of one token settle identically.

const BANDS_SET := ["none", "pair", "quartet", "belt"]
# The minimum of K*rho^2 - S*x sits at x = S/2K, INTERIOR unless S > 2*K*R.
# The first values (0.045..0.16) parked the ball at 45 mm, nowhere near the
# rim, and the bands were scenery. These put the minimum past the wall, so the
# wall is the constraint -- except faint, kept interior ON PURPOSE as the value
# where the dish still decides and the rim is never consulted.
const LEANS := {"level": 0.0, "faint": 0.12, "firm": 0.34, "steep": 0.55}

@export_enum("none", "pair", "quartet", "belt") var bands: String = "pair":
	set(v):
		bands = v
		if is_inside_tree():
			_rebuild()

@export_enum("level", "faint", "firm", "steep") var lean: String = "firm":
	set(v):
		lean = v
		if is_inside_tree():
			_rebuild()

@export var dish_radius: float = 0.16
@export var ball_radius: float = 0.06
@export var show_readout: bool = true

@export var dish_color: Color = Color(0.46, 0.48, 0.52)
@export var band_color: Color = Color(0.86, 0.16, 0.16)
@export var ball_color: Color = Color(0.22, 0.55, 0.85)
@export var clear_color: Color = Color(0.30, 0.62, 0.40)

const DISH_K := 0.9              # paraboloid steepness: y = K * rho^2 - slope * x
# Deep, and the depth is load-bearing: at 18 mm a ball nestled INTO the bumper
# at full downhill sat LOWER than any clear arc (0.9*0.082^2 - S*0.082 beats
# 0.9*0.1^2 - S*0.1*cos30), so resting on the forbidden was energetically
# correct and nothing ever deflected. At 60 mm the clear arc wins by 5 mm of
# height, and the ball arrives with five times the kinetic energy the band-edge
# barrier costs, so the slide past the edge actually happens.
const BAND_DEPTH := 0.06
const BAND_H := 0.05
const SUBSTEPS := 4
# Low, and that is the artifact arguing: GRIP 0.45 (droplet_cusp's wedge-hold
# friction) acted as STATIC friction here -- it ate the tangential pull at the
# band face every substep and the ball parked dead on the forbidden instead of
# sliding along it to the edge. A dish is a slippery place on purpose.
const GRIP := 0.12
const SETTLE_EPS := 0.0001
const SETTLE_TICKS := 45
const TIMEOUT_TICKS := 1200

var _pts := PackedVector3Array()
var _prev := PackedVector3Array()
var _edges: Array = []
var _faces := PackedInt32Array()
var _rest_r: float = 0.0
var _ball: MeshInstance3D
var _skin_mat: StandardMaterial3D
var _plate: Label3D
var _built: Node3D
var _settled: bool = false
var _timed_out: bool = false
var _quiet: int = 0
var _ticks: int = 0
var _last_centroid := Vector3.ZERO
var _was_centroid := Vector3(1e9, 1e9, 1e9)


## [center_deg, half_width_deg] per band. Azimuth 0 is downhill (+x).
func _band_arcs() -> Array:
	match bands:
		"pair": return [[14.0, 28.0], [194.0, 28.0]]
		"quartet": return [[14.0, 28.0], [104.0, 28.0], [194.0, 28.0], [284.0, 28.0]]
		"belt": return [[14.0, 155.0]]
	return []


func _ready() -> void:
	_built = Node3D.new()
	_built.name = "Built"
	add_child(_built)
	_rebuild()


# --------------------------------------------------------------- the shell
# (the droplet_cusp icosphere, trimmed to one flesh)

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


## FIXED-STEP, whatever the engine's tick rate. The first version divided the
## incoming delta by four, which made the INTEGRATION depend on the tick rate:
## the probe passed at its two gated rates while the capture harness, running
## at the project's own rate, watched the same ball stop 50 mm short and print
## CENTERED. An accumulator at 240 steps per simulated second integrates the
## same physics in the same order at 30, 60 or 90 Hz.
var _acc := 0.0
const FIXED_H := 1.0 / 240.0


func _step_shell(delta: float) -> void:
	_acc += minf(delta, 0.1)
	var dt := FIXED_H
	var budget := 12
	while _acc >= FIXED_H and budget > 0:
		_acc -= FIXED_H
		budget -= 1
		_substep(dt)


func _substep(dt: float) -> void:
	for _s in range(1):
		var centre := Vector3.ZERO
		for p in _pts:
			centre += p
		centre /= float(_pts.size())
		var mean_r := 0.0
		for p in _pts:
			mean_r += (p - centre).length()
		mean_r /= float(_pts.size())
		var puff := 6.0 * (_rest_r - mean_r) / _rest_r
		for i in range(_pts.size()):
			var p := _pts[i]
			var vel := (p - _prev[i]) * 0.96
			var n := p - centre
			var acc := Vector3(0, -9.8, 0)
			var nl := n.length()
			if nl > 1e-6:
				acc += n / nl * puff
			_prev[i] = p
			_pts[i] = p + vel + acc * dt * dt
		for _k in range(6):
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


func _surface_y(x: float, z: float) -> float:
	var rho2 := x * x + z * z
	return DISH_K * rho2 - float(LEANS.get(lean, 0.0)) * x


func _in_band(az_deg: float) -> bool:
	for arc in _band_arcs():
		var d := absf(fposmod(az_deg - float(arc[0]) + 180.0, 360.0) - 180.0)
		if d <= float(arc[1]):
			return true
	return false


func _collide_point(i: int) -> void:
	var p := _pts[i]
	var hit := false
	# the dish floor, resolved along the surface NORMAL. A vertical clamp was
	# tried first and the ball sat at the centre of a firmly tilted dish forever
	# (rho 3 mm at lean=firm): pushing straight up off a slanted floor exerts no
	# sideways force at all, so the slope never became a slide. The normal of
	# y = K*rho^2 - S*x is (-(2Kx - S), 1, -2Kz), and resolving along it is
	# what lets gravity discover the downhill.
	var ys := _surface_y(p.x, p.z)
	if p.y < ys:
		var slope := float(LEANS.get(lean, 0.0))
		var n := Vector3(-(2.0 * DISH_K * p.x - slope), 1.0, -2.0 * DISH_K * p.z)
		n = n.normalized()
		p += n * ((ys - p.y) / maxf(n.y, 0.2))
		hit = true
	var rho := Vector2(p.x, p.z).length()
	var az := rad_to_deg(atan2(p.z, p.x))
	# THE BANDS ARE FLAT WALLS, and flatness is load-bearing. A curved bumper's
	# normal is radial, so a ball pressing straight downhill against it feels
	# ZERO tangential force at azimuth 0 -- it parks there in equilibrium no
	# matter where the band's edges are, which three probe rounds proved. A
	# flat chord wall (the source figure's cuts are straight) has its normal
	# along the band's CENTRE, so a ball at azimuth 0 is pushed obliquely and
	# the slide to the edge falls out of the projection itself. The belt keeps
	# the curved wall: its job is no-escape, not deflection.
	for arc in _band_arcs():
		var half: float = float(arc[1])
		var c_deg: float = float(arc[0])
		var d_az := absf(fposmod(az - c_deg + 180.0, 360.0) - 180.0)
		if p.y >= BAND_H or d_az > half + 8.0:
			continue
		if half > 60.0:
			# the belt: curved, inescapable
			if rho > dish_radius - BAND_DEPTH and d_az <= half:
				var k := (dish_radius - BAND_DEPTH - 0.0005) / maxf(rho, 1e-6)
				p.x *= k
				p.z *= k
				hit = true
		else:
			var n := Vector3(cos(deg_to_rad(c_deg)), 0, sin(deg_to_rad(c_deg)))
			var along := p.dot(n)
			var face := dish_radius - BAND_DEPTH
			if along > face:
				p -= n * (along - face)
				hit = true
	# the outer wall, everywhere
	if rho > dish_radius:
		var k2 := dish_radius / maxf(rho, 1e-6)
		p.x *= k2
		p.z *= k2
		hit = true
	if hit:
		_prev[i] = _prev[i].lerp(p, GRIP)
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

func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = emit
	return m


func _rebuild() -> void:
	if _built == null:
		return
	for c in _built.get_children():
		c.queue_free()
	_settled = false
	_timed_out = false
	_quiet = 0
	_ticks = 0
	_was_centroid = Vector3(1e9, 1e9, 1e9)

	# the dish, drawn as a ring of wedge plates following the paraboloid
	var dm := _mat(dish_color, 0.06)
	var steps := 48
	for s in range(steps):
		var a0 := TAU * float(s) / float(steps)
		var mid_a := a0 + TAU / float(steps) * 0.5
		var wedge := BoxMesh.new()
		var arc_w := TAU / float(steps) * dish_radius * 1.1
		wedge.size = Vector3(dish_radius, 0.004, arc_w)
		var mi := MeshInstance3D.new()
		mi.mesh = wedge
		mi.material_override = dm
		var r_mid := dish_radius * 0.5
		var x := cos(mid_a) * r_mid
		var z := sin(mid_a) * r_mid
		mi.position = Vector3(x, _surface_y(x, z), z)
		mi.rotation = Vector3(0, -mid_a, atan2(
			_surface_y(cos(mid_a) * dish_radius, sin(mid_a) * dish_radius)
			- _surface_y(0, 0), dish_radius))
		_built.add_child(mi)

	# the bands, standing on the rim where they forbid
	var bm := _mat(band_color, 0.5)
	for arc in _band_arcs():
		var half: float = float(arc[1])
		var n_seg := maxi(int(half / 6.0), 2)
		for s2 in range(-n_seg, n_seg):
			var az := deg_to_rad(float(arc[0]) + half * (float(s2) + 0.5) / float(n_seg))
			var seg := BoxMesh.new()
			seg.size = Vector3(BAND_DEPTH, BAND_H, dish_radius * deg_to_rad(half) / float(n_seg) * 1.05)
			var mi2 := MeshInstance3D.new()
			mi2.mesh = seg
			mi2.material_override = bm
			var r_b := dish_radius - BAND_DEPTH * 0.5
			var x2 := cos(az) * r_b
			var z2 := sin(az) * r_b
			mi2.position = Vector3(x2, _surface_y(x2, z2) + BAND_H * 0.5, z2)
			mi2.rotation = Vector3(0, -az, 0)
			_built.add_child(mi2)

	# the ball, dropped just above the centre
	_init_shell(Vector3(0, ball_radius + 0.02, 0))
	_ball = MeshInstance3D.new()
	_ball.name = "Ball"
	_skin_mat = _mat(ball_color, 0.2)
	_skin_mat.metallic = 0.15
	_skin_mat.roughness = 0.35
	_built.add_child(_ball)
	_update_skin()

	if show_readout:
		_plate = Label3D.new()
		_plate.font_size = 40
		_plate.pixel_size = 0.00042
		_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_plate.position = Vector3(0, 0.17, 0)
		_plate.modulate = ball_color
		_plate.text = "SETTLING..."
		_built.add_child(_plate)

	var anchor := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(dish_radius * 2.3, 0.26, dish_radius * 2.3)
	anchor.mesh = am
	anchor.layers = 0
	anchor.name = "ExtentAnchor"
	anchor.position = Vector3(0, 0.05, 0)
	_built.add_child(anchor)

	set_physics_process(true)


func _physics_process(dt: float) -> void:
	if _pts.is_empty():
		return
	_step_shell(dt)
	if _ticks % 2 == 0:
		_update_skin()
	_ticks += 1
	var centre := Vector3.ZERO
	for p in _pts:
		centre += p
	centre /= float(_pts.size())
	if not (is_finite(centre.x) and is_finite(centre.y) and is_finite(centre.z)):
		_settled = true
		_timed_out = true
		set_physics_process(false)
		return
	var moved := (centre - _was_centroid).length()
	_was_centroid = centre
	_last_centroid = centre
	_quiet = _quiet + 1 if moved < SETTLE_EPS else 0
	if _ticks % 10 == 0 and _plate != null and is_instance_valid(_plate):
		_plate.text = _verdict()
		_plate.modulate = band_color if on_band() else (clear_color if at_rim() else ball_color)
	if _quiet >= SETTLE_TICKS or _ticks >= TIMEOUT_TICKS:
		_settled = true
		_timed_out = _ticks >= TIMEOUT_TICKS and _quiet < SETTLE_TICKS
		if _plate != null and is_instance_valid(_plate):
			_plate.text = _verdict()
			_plate.modulate = band_color if on_band() else (clear_color if at_rim() else ball_color)
		set_physics_process(false)


# ----------------------------------------------------------------- the claim

func rest_azimuth_deg() -> float:
	return rad_to_deg(atan2(_last_centroid.z, _last_centroid.x))


func rest_rho_m() -> float:
	return Vector2(_last_centroid.x, _last_centroid.z).length()


## Contact is tested on the shell's own points, not guessed from the centroid:
## with 60 mm bands a leaning ball's centre sits nowhere near the rim.
func at_rim() -> bool:
	for p in _pts:
		if Vector2(p.x, p.z).length() > dish_radius - 0.004:
			return true
	return false


## Resting ON a band means the body's PLACE is forbidden, not that a point
## grazes a band's end corner on the way past: the deflected ball leans its
## last millimetre on the wall's edge while standing at azimuth -30, and that
## is a clear rest. So: the centroid's azimuth must be inside a band's sector,
## AND the shell must actually lean on that band's wall.
func on_band() -> bool:
	var az_c := rest_azimuth_deg()
	var face := dish_radius - BAND_DEPTH
	for arc in _band_arcs():
		var half: float = float(arc[1])
		var c_deg: float = float(arc[0])
		var d_c := absf(fposmod(az_c - c_deg + 180.0, 360.0) - 180.0)
		if d_c > half:
			continue
		if half > 60.0:
			for p in _pts:
				if p.y >= BAND_H:
					continue
				var rho := Vector2(p.x, p.z).length()
				if rho > face - 0.004 and rho < face + 0.002:
					return true
		else:
			var n := Vector3(cos(deg_to_rad(c_deg)), 0, sin(deg_to_rad(c_deg)))
			for p in _pts:
				if p.y >= BAND_H:
					continue
				if p.dot(n) > face - 0.004:
					return true
	return false


func nearest_band_edge_deg() -> float:
	var az := rest_azimuth_deg()
	var best := 360.0
	for arc in _band_arcs():
		var d := absf(fposmod(az - float(arc[0]) + 180.0, 360.0) - 180.0) - float(arc[1])
		best = minf(best, d)
	return best


func is_settled() -> bool:
	return _settled


## A deflected ball leans on the band wall's END at rho 64 mm -- touching
## neither the outer rim nor the band's own sector. The first verdict read that
## as CENTERED and printed "the bands were never met" while the ball was
## propped against one; the capture caught it and the in-situ trace confirmed
## the physics was identical to the probe's. The verdict speaks CONTACT now.
func _leans_on_band() -> bool:
	var face := dish_radius - BAND_DEPTH
	for arc in _band_arcs():
		var half: float = float(arc[1])
		var c_deg: float = float(arc[0])
		for p in _pts:
			if p.y >= BAND_H:
				continue
			if half > 60.0:
				var rho := Vector2(p.x, p.z).length()
				var d_az := absf(fposmod(rad_to_deg(atan2(p.z, p.x)) - c_deg + 180.0, 360.0) - 180.0)
				if d_az <= half and rho > face - 0.004:
					return true
			elif p.dot(Vector3(cos(deg_to_rad(c_deg)), 0, sin(deg_to_rad(c_deg)))) > face - 0.004:
				return true
	return false


func _verdict() -> String:
	if not _settled:
		return "SETTLING...\nazimuth %+.0f deg" % rest_azimuth_deg()
	var s := ""
	if on_band():
		s = "ON THE FORBIDDEN\nno clear arc remained\nazimuth %+.0f deg" % rest_azimuth_deg()
	elif _band_arcs().is_empty():
		if at_rim():
			s = "RESTS DOWNHILL\nazimuth %+.0f deg -- nothing refused it" % rest_azimuth_deg()
		else:
			s = "CENTERED\nthe rim was never reached"
	elif at_rim() or _leans_on_band():
		s = "RESTS CLEAR\nazimuth %+.0f deg, %.0f deg past the band" \
			% [rest_azimuth_deg(), nearest_band_edge_deg()]
	elif rest_rho_m() < 0.05:
		s = "CENTERED\nthe rim was never reached\nthe bands were never met"
	else:
		s = "RESTS MID-DISH\nazimuth %+.0f deg -- the bowl holds it short of the bands" \
			% rest_azimuth_deg()
	if _timed_out:
		s += "\n(still moving at timeout)"
	return s


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("bands"):
		var b := str(config_data["bands"]).to_lower().strip_edges()
		if BANDS_SET.has(b):
			bands = b
			dirty = true
	if config_data.has("lean"):
		var l := str(config_data["lean"]).to_lower().strip_edges()
		if LEANS.has(l):
			lean = l
			dirty = true
	if config_data.has("show_readout"):
		show_readout = bool(config_data["show_readout"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()
