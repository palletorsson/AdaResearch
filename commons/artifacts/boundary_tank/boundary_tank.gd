extends Node3D
class_name BoundaryTank

## Boundary Tank — a SYNTHESIS artifact. One pulse, four walls, one integration.
##
## @identity
## essence: Four channels stacked on one panel, each running the SAME wave under a
##   different boundary condition — fixed, free, absorbing, periodic. The pulse is
##   released identically in all four and integrated once; what separates them is
##   entirely what happens when it reaches the end.
## desire: To be read as four theories of what is outside the picture. `fixed` says
##   the outside is a mirror that inverts. `free` says it is a mirror that does not.
##   `absorbing` says there is no outside — the domain goes on forever and the wave
##   simply leaves. `periodic` says the outside is this same tank again.
## critical_parameter: `moment` — when the shutter opens. Until the wave reaches the
##   end, all four channels are identical to fifteen decimal places, and that is the
##   artifact's first claim rather than a defect of it.
## triggers: none. Nothing animates, nothing is grabbed, nothing is random. There is
##   no _process, no Timer, no physics body and no call to randf anywhere in the file.
## emerges: the space-time carpet. Each lane was first given an x-t diagram of its own
##   run, and the arithmetic killed it before any capture: a lane 128 cells long can
##   afford a strip 24.5 px tall, so the characteristic — 25 cells wide, crossing the
##   whole lane over that height — rasterises 2.3 px thick. The whole run is drawn as
##   a STROBE in the profile instead, where there is height to draw it in.
## needs: one integration, evaluated once [has, _run]; four lanes differing in nothing
##   but the edge rule [has]; an amplitude gauge whose ceiling never moves [has, AMP];
##   an energy count that is the real conserved quantity and not sum-of-squares
##   [has, _energy]; no random number anywhere [has]
## relationships: The exhibited word is [[wave_equation_solver]]'s. `moment` and its
##   four fractions are [[sorting_hall]]'s, preloaded. `evidence` is the word
##   [[wave_interference_tank]] and [[wave_interference_3d]] carry, routed through
##   their own reader.
## truth: A boundary condition is not a property of the wave. It is a statement about
##   a place the picture does not show, and it is unfalsifiable from inside the tank
##   until the wave gets there. Four channels that are bit-identical for eighty steps
##   are four different worlds the whole time.

# ═══════════════════════════════════════════════════════════════════════════
# SYNTHESIS DNA — `evidence` x `moment`, and `boundary` EXHIBITED
# ═══════════════════════════════════════════════════════════════════════════
#
# BORN PROMOTED. Nothing shipped before this file and no placement changes.
#
# WHY `boundary` IS NOT THE AXIS. Five artifacts declare the word and they carry
# THREE unrelated value lists — an editor's snap target (none|edge|cell|lattice, on
# vr_tile_editor, vr_tile_editor_mirror and pattern_maker_station), a containment
# policy (flow|cage|corners|open, on force_field_zone) and the wave equation's own
# boundary conditions (fixed|free|absorbing|periodic, on wave_equation_solver). This
# tank takes the third, because it is the only one of the three that describes a
# BOUNDARY rather than a snap rule or what a zone does to a body entering it, and
# because those four words are what the mathematics this corpus teaches means by
# them. The list is not retyped: it is read out of WAVE_SRC.BOUNDARIES at build
# time, so the lanes, their number and their order are the family's array.
#
# LAW 2, ANSWERED FROM THE OWNER'S CODE. wave_equation_solver's four values sit SIDE
# BY SIDE, not nested: _step_wave branches four ways and no branch contains another
# — periodic takes an entirely separate loop (the wrap is in the stencil), free
# applies _apply_free_edges after an interior sweep, absorbing applies _apply_sponge
# to BOTH leapfrog levels, and fixed does nothing at all. Four furniture builders,
# likewise, sharing no body. Parallel values are exactly the case where showing them
# all at once is not merely the top value, so the word is EXHIBITED — four lanes
# standing — and the axes vary the run instead.

const WAVE_SRC := preload("res://commons/artifacts/wave_equation_solver/wave_equation_solver.gd")
const SORT_SRC := preload("res://commons/artifacts/sorting_hall/sorting_hall.gd")
const TANK_SRC := preload("res://commons/artifacts/wave_interference_tank/wave_interference_tank.gd")

## evidence — how much of this one run is on the table. The three-rung sub-list eight
## artifacts already carry, in their order. `sources` is refused; see dna.declines.
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

## moment — which moment of the run is standing in the tank, as a fraction of one
## round trip. The words AND the fractions are sorting_hall's, read from SORT_SRC.
## Declared done-first because build_dna_gallery trims the second axis from the TAIL.
@export_enum("done", "half", "quarter", "start") var moment: String = "done"

# --- the run -------------------------------------------------------------------
## Cells across a lane, and the launch cell at 3/8 of it. 3/8 is not a taste: it is
## the largest launch offset for which the round trip 2*(CELLS-P0) = 1.25*CELLS is
## divisible by four, so all four of sorting_hall's fractions land on whole steps.
const CELLS: int = 128
const P0: int = 3 * CELLS / 8
const SIGMA: float = 10.0
const T_RUN: int = 5 * CELLS / 4
## Courant number, SQUARED, and it is 1 on purpose. The 1D CFL limit is 1 (not the
## 2D 1/sqrt(2) the parent clamps to), and AT exactly 1 the leapfrog is EXACT: a
## pulse translates one cell per step with no numerical dispersion, and the one-way
## condition below is exact too. Every number in the registry depends on this.
const R2: float = 1.0

# --- layout, metres ------------------------------------------------------------
const DX: float = 0.0175
const LANE_X: float = CELLS * DX
const MARGIN_L: float = 0.28
const MARGIN_R: float = 0.18
const PANEL_W: float = MARGIN_L + LANE_X + MARGIN_R
const HEADER_H: float = 0.10
const HEADER_GAP: float = 0.03
const PROFILE_H: float = 0.46
const GAUGE_H: float = 0.030
const BAND_H: float = PROFILE_H + GAUGE_H
const BAND_GAP: float = 0.032
const BOTTOM_M: float = 0.02
const PANEL_H: float = HEADER_H + HEADER_GAP + 4.0 * BAND_H + 3.0 * BAND_GAP + BOTTOM_M
## Metres per unit u. THE CEILING, FIXED ACROSS EVERY FRAME OF BOTH AXES. The largest
## displacement anywhere in the whole run is 1.995012 (free, at contact), so the half
## strip 0.23 holds 1.995012 * 0.113 = 0.225437 with 0.004563 to spare. Nothing is
## ever normalised to its own frame.
const AMP: float = 0.113
const XL: float = -PANEL_W * 0.5 + MARGIN_L
const XR: float = XL + LANE_X

const ZP0: float = -0.030
const ZP1: float = 0.0
const ZC0: float = 0.0
const ZC1: float = 0.004
const ZT0: float = 0.004
const ZT1: float = 0.010
const ZW0: float = 0.010
const ZW1: float = 0.054
const ZF0: float = 0.004
const ZF1: float = 0.060
const ZG0: float = 0.054
const ZG1: float = 0.066

const T_DATUM: float = 0.024
const T_RULE: float = 0.020
const T_GHOST: float = 0.026
const W_BAR: float = 0.052
const W_CYAN: float = 0.036
const L_MOUTH: float = 0.070

## The strobe: the whole run, at the quarters. Deliberately the same five fractions
## sorting_hall's MOMENTS names, so `longhand` draws the ladder `moment` climbs.
const STATIONS: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]

# --- colours -------------------------------------------------------------------
## PANEL_COLOR is sorting_hall's, so the two synthesis shells photograph as siblings.
const C_PANEL := Color(0.115, 0.120, 0.135)
const C_CHANNEL := Color(0.055, 0.058, 0.070)
const C_HEADER := Color(0.150, 0.157, 0.175)
## The ramp is wave_equation_solver's colour_positive / colour_negative / colour_zero.
## They are `var` there, not `const`, so they cannot be preloaded; they are written
## out here and the drift risk is recorded in the registry.
const C_POS := Color(0.15, 0.4, 1.0)
const C_NEG := Color(1.0, 0.2, 0.15)
const C_ZERO := Color(0.06, 0.06, 0.1)
## The parent's frame_mat, foam and periodic mat_x, in section.
const C_BROWN := Color(0.35, 0.25, 0.18)
const C_CYAN := Color(0.20, 0.85, 0.95)
const C_GHOST := Color(0.86, 0.88, 0.96)
const C_DATUM := Color(0.44, 0.47, 0.54)
const C_RULE := Color(0.28, 0.30, 0.35)
const C_GFILL := Color(0.95, 0.78, 0.35)
const C_GTRACK := Color(0.20, 0.21, 0.24)
const C_TEXT := Color(0.80, 0.83, 0.90)

# --- state ---------------------------------------------------------------------
var _root: Node3D = null
var _built: bool = false
var _hist: Dictionary = {}          # lane -> Array of PackedFloat32Array, one per step
var _e0: float = 1.0


func _ready() -> void:
	_read_grid_config_meta()
	_check_family_lists()
	_build()


# ── the arithmetic, evaluated ONCE ────────────────────────────────────────────
## One integrator. Four edge rules, each one line, and they are the whole axis:
##   fixed      u[0] = u[N] = 0                     Dirichlet, the parent's shipped rim
##   free       u[0] = u[1],   u[N] = u[N-1]        Neumann, the parent's _apply_free_edges
##   absorbing  u[0]' = u[1],  u[N]' = u[N-1]       Sommerfeld one-way; EXACT at r = 1
##   periodic   the stencil wraps                   the parent's _step_wave_periodic
## Nothing else differs. Same R2, same leapfrog, same initial data, NO damping — see
## the registry: a bulk loss term would put energy loss in every lane and make
## `absorbing` a difference of degree.
func _run() -> void:
	_hist.clear()
	for raw in WAVE_SRC.BOUNDARIES:
		var lane: String = String(raw)
		var n: int = CELLS if lane == "periodic" else CELLS + 1
		var u: PackedFloat32Array = PackedFloat32Array()
		var up: PackedFloat32Array = PackedFloat32Array()
		u.resize(n)
		up.resize(n)
		for i in range(n):
			u[i] = _gauss(float(i - P0))
			up[i] = _gauss(float(i - P0 + 1))    # one cell back, one step back: right-moving
		if lane == "fixed":
			u[0] = 0.0
			u[n - 1] = 0.0
			up[0] = 0.0
			up[n - 1] = 0.0
		var frames: Array = [u.duplicate()]
		for _s in range(T_RUN + 1):
			var nu: PackedFloat32Array = PackedFloat32Array()
			nu.resize(n)
			if lane == "periodic":
				for i in range(n):
					var ip: int = (i + 1) % n
					var im: int = (i - 1 + n) % n
					nu[i] = 2.0 * u[i] - up[i] + R2 * (u[ip] - 2.0 * u[i] + u[im])
			else:
				for i in range(1, n - 1):
					nu[i] = 2.0 * u[i] - up[i] + R2 * (u[i + 1] - 2.0 * u[i] + u[i - 1])
				if lane == "free":
					nu[0] = nu[1]
					nu[n - 1] = nu[n - 2]
				elif lane == "absorbing":
					nu[0] = u[1]
					nu[n - 1] = u[n - 2]
			up = u
			u = nu
			frames.append(u.duplicate())
		_hist[lane] = frames
	_e0 = _energy("fixed", 0)


func _gauss(s: float) -> float:
	return exp(-(s * s) / (2.0 * SIGMA * SIGMA))


## THE ENERGY THE LEAPFROG ACTUALLY CONSERVES, and the reason this function exists
## rather than sum(u*u). At `half` the fixed lane's displacement is ZERO in every
## cell — measured 9.93e-06 — and every joule is in the velocity. A sum-of-squares
## gauge would read 0.000 there and the tank would state that a pinned wall destroys
## the wave. That is sorting_hall's fault exactly: a proxy that silently reports zero.
##   E = 1/2 sum (u^{n+1} - u^n)^2  +  1/2 sum grad(u^n) . grad(u^{n+1})
func _energy(lane: String, step: int) -> float:
	var frames: Array = _hist[lane]
	var a: PackedFloat32Array = frames[step]
	var b: PackedFloat32Array = frames[step + 1]
	var n: int = a.size()
	var kin: float = 0.0
	for i in range(n):
		var d: float = b[i] - a[i]
		kin += d * d
	var wrap: bool = lane == "periodic"
	var m: int = n if wrap else n - 1
	var pot: float = 0.0
	for i in range(m):
		var j: int = (i + 1) % n
		pot += (a[j] - a[i]) * (b[j] - b[i])
	return 0.5 * kin + 0.5 * pot


func _step_of(word: String) -> int:
	return int(round(float(SORT_SRC.MOMENTS[word]) * float(T_RUN)))


func _sample(lane: String, step: int, i: int) -> float:
	var f: PackedFloat32Array = _hist[lane][step]
	return f[i % f.size()]


# ── build ─────────────────────────────────────────────────────────────────────
func _build() -> void:
	_root = Node3D.new()
	_root.name = "Tank"
	add_child(_root)
	_run()

	var solid := SurfaceTool.new()
	var water := SurfaceTool.new()
	solid.begin(Mesh.PRIMITIVE_TRIANGLES)
	water.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_w: float = PANEL_W * 0.5
	_box(solid, -half_w, half_w, 0.0, PANEL_H, ZP0, ZP1, C_PANEL)
	_box(solid, -half_w + 0.02, half_w - 0.02, PANEL_H - HEADER_H, PANEL_H - 0.012,
		ZC0, ZC1, C_HEADER)

	var step: int = _step_of(moment)
	for k in range(WAVE_SRC.BOUNDARIES.size()):
		var lane: String = String(WAVE_SRC.BOUNDARIES[k])
		var y_top: float = PANEL_H - HEADER_H - HEADER_GAP - float(k) * (BAND_H + BAND_GAP)
		var p_bot: float = y_top - PROFILE_H
		var datum: float = y_top - PROFILE_H * 0.5
		var g_top: float = p_bot
		var g_bot: float = p_bot - GAUGE_H

		_box(solid, XL, XR, p_bot, y_top, ZC0, ZC1, C_CHANNEL)
		_lane_label(lane, datum)

		if evidence != "result":
			_box(solid, XL, XR, datum - T_DATUM * 0.5, datum + T_DATUM * 0.5,
				ZT0, ZT1, C_DATUM)
			for sgn in [1.0, -1.0]:
				var yr: float = datum + float(sgn) * AMP
				_box(solid, XL, XR, yr - T_RULE * 0.5, yr + T_RULE * 0.5, ZT0, ZT1, C_RULE)
			# The energy gauge. Ceiling E0, the SAME number for all four lanes at
			# every moment, because all four were handed the same pulse.
			var frac: float = clampf(_energy(lane, step) / _e0, 0.0, 1.0)
			_box(solid, XL, XR, g_bot + 0.004, g_top - 0.004, ZT0, ZT1, C_GTRACK)
			if frac > 0.001:
				_box(solid, XL, XL + LANE_X * frac, g_bot + 0.006, g_top - 0.006,
					ZT0 + 0.001, ZT1 + 0.001, C_GFILL)
			# THE STROBE. `trace` draws station 0 alone — the released pulse, which is
			# the proof that all four lanes were handed the same wave. `longhand` draws
			# all five, so the entire run stands at once and the solid water below marks
			# which of them is `now`. It is the whole run at EVERY moment, deliberately:
			# a rung whose content shrank with the moment would be thin exactly where
			# the moment axis is already thin, and the two would hide each other.
			var count: int = 1 if evidence == "trace" else STATIONS.size()
			for si in range(count):
				var sstep: int = int(round(STATIONS[si] * float(T_RUN)))
				for i in range(CELLS + 1):
					var hs: float = _sample(lane, sstep, i)
					if absf(hs) * AMP < T_GHOST * 0.30:
						continue
					var ys: float = datum + hs * AMP
					_box(solid, XL + float(i) * DX, XL + float(i + 1) * DX,
						ys - T_GHOST * 0.5, ys + T_GHOST * 0.5, ZG0, ZG1, C_GHOST)

		for i in range(CELLS + 1):
			var h: float = _sample(lane, step, i)
			if absf(h) * AMP < 0.0018:
				continue
			var y: float = datum + h * AMP
			var lo: float = datum if h > 0.0 else y
			var hi: float = y if h > 0.0 else datum
			_box(water, XL + float(i) * DX, XL + float(i + 1) * DX, lo, hi,
				ZW0, ZW1, _ramp(h))

		_end_walls(solid, lane, p_bot, y_top, datum)

	_emit(solid, "Solid", false)
	_emit(water, "Water", true)
	_header_label()
	_built = true


## The parent's four rim vocabularies, transposed to a section through one channel.
## A rim seen in plan is a low rail; a channel seen in elevation shows its end wall
## at full height, so the SIZE is re-gauged and the CLAIM is not.
func _end_walls(st: SurfaceTool, lane: String, p_bot: float, y_top: float, datum: float) -> void:
	if lane == "fixed":
		for xw in [XL, XR]:
			var xf: float = float(xw)
			_box(st, xf - W_BAR * 0.5, xf + W_BAR * 0.5, p_bot, y_top, ZF0, ZF1, C_BROWN)
	elif lane == "free":
		# _build_frame_free removes the rail and leaves posts. In section: a post the
		# sheet rests on, stopping at the datum, with nothing beside the water above it.
		for xw in [XL, XR]:
			var xr: float = float(xw)
			_box(st, xr - W_BAR * 0.5, xr + W_BAR * 0.5, p_bot, datum, ZF0, ZF1, C_BROWN)
	elif lane == "absorbing":
		# No wall, and no gutter either. The parent draws a matte sponge band because
		# it HAS a sponge layer; the one-way condition here is exact and local, so a
		# gutter would be furniture for a mechanism this lane does not use. What is
		# true is that the channel simply carries on, so that is what is drawn.
		_box(st, XL - L_MOUTH, XL, p_bot, y_top, ZC0, ZC1, C_CHANNEL)
		_box(st, XR, XR + L_MOUTH, p_bot, y_top, ZC0, ZC1, C_CHANNEL)
	else:
		for xw in [XL, XR]:
			var xc: float = float(xw)
			_box(st, xc - W_CYAN * 0.5, xc + W_CYAN * 0.5, p_bot, y_top, ZF0, ZF1, C_CYAN)


## wave_equation_solver._displacement_color, value for value, including its clamp at
## +/-1. The consequence is stated rather than hidden: free's 1.995 at contact reads
## as fully saturated blue and its DOUBLING is legible in the height against the +1
## rule, not in the colour.
func _ramp(h: float) -> Color:
	var t: float = clampf(h, -1.0, 1.0)
	if t > 0.0:
		return C_ZERO.lerp(C_POS, t)
	return C_ZERO.lerp(C_NEG, -t)


func _box(st: SurfaceTool, x0: float, x1: float, y0: float, y1: float,
		z0: float, z1: float, c: Color) -> void:
	if x1 <= x0 or y1 <= y0:
		return
	var faces: Array = [
		[Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector3(0, 0, 1)],
		[Vector3(x1, y0, z0), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(0, 0, -1)],
		[Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(1, 0, 0)],
		[Vector3(x0, y0, z0), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x0, y1, z0), Vector3(-1, 0, 0)],
		[Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3(0, 1, 0)],
		[Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3(0, -1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[4]
		for tri in [[0, 1, 2], [0, 2, 3]]:
			for vi in tri:
				st.set_color(c)
				st.set_normal(n)
				st.add_vertex(f[vi])


func _emit(st: SurfaceTool, node_name: String, unshaded: bool) -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	if unshaded:
		# wave_equation_solver's own surface material is SHADING_MODE_UNSHADED, so the
		# water reads at full ramp value here as it does there.
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = mat
	_root.add_child(mi)


## HORIZONTAL_ALIGNMENT_CENTER, and the origin IS the centre of the plate. A Label3D
## left-aligned hangs from its origin and runs right, which would put "absorbing"
## through the channel's open mouth.
func _lane_label(lane: String, datum: float) -> void:
	var l := Label3D.new()
	l.name = "Lane_" + lane
	l.text = lane
	l.font_size = 22
	l.pixel_size = 0.0016
	l.position = Vector3(XL - 0.165, datum, ZT1 + 0.001)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate = C_TEXT
	l.outline_size = 2
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_root.add_child(l)


func _header_label() -> void:
	var l := Label3D.new()
	l.name = "Header"
	l.text = "boundary"
	l.font_size = 40
	l.pixel_size = 0.0016
	l.position = Vector3(0.0, PANEL_H - HEADER_H * 0.5 - 0.006, ZT1 + 0.001)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate = C_TEXT
	l.outline_size = 3
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_root.add_child(l)


# ── vocabulary gates ──────────────────────────────────────────────────────────
## BOTH DIRECTIONS, on every list, because an @export_enum hint is a literal the
## compiler will not check against anything. Passing check_dna_declarations.py is
## not evidence: that gate reads the hint out of the source TEXT.
func _check_family_lists() -> void:
	var mine: Array[String] = ["fixed", "free", "absorbing", "periodic"]
	for w in WAVE_SRC.BOUNDARIES:
		if not mine.has(String(w)):
			push_error("boundary_tank: wave_equation_solver declares boundary '%s' and this tank has no lane for it" % String(w))
	for w in mine:
		if not WAVE_SRC.BOUNDARIES.has(w):
			push_error("boundary_tank: this tank builds a lane '%s' that wave_equation_solver no longer declares" % w)
	var mine_m: Array[String] = ["done", "half", "quarter", "start"]
	for w in mine_m:
		if not SORT_SRC.MOMENTS.has(w):
			push_error("boundary_tank: moment '%s' is not in sorting_hall.MOMENTS" % w)
	for w in SORT_SRC.MOMENTS.keys():
		if not mine_m.has(String(w)):
			push_error("boundary_tank: sorting_hall.MOMENTS declares '%s' and this tank's export does not" % String(w))
	for w in ["result", "trace", "longhand"]:
		var rung: String = String(w)
		if TANK_SRC.evidence_name(rung) != rung:
			push_error("boundary_tank: '%s' is no longer a canonical evidence rung — wave_interference_tank now reads it as '%s'" % [rung, TANK_SRC.evidence_name(rung)])


func _is_evidence(w: String) -> bool:
	return w == "result" or w == "trace" or w == "longhand"


# ── configuration ─────────────────────────────────────────────────────────────
## Read on the way IN, before _ready builds, so the tank is built once in the right
## form instead of built and torn down. GridInteractablesComponent stamps this
## metadata on the instantiated root before it calls apply_grid_config.
func _read_grid_config_meta() -> void:
	var node: Node = self
	while node != null:
		if node.has_meta("config_evidence"):
			_set_evidence(str(node.get_meta("config_evidence")))
		if node.has_meta("config_moment"):
			_set_moment(str(node.get_meta("config_moment")))
		node = node.get_parent()


## Routed through wave_interference_tank's own static reader, so `pattern`, `field`,
## `section` and `terms` land on the rung the family says they mean instead of on a
## second alias table here. `sources` normalises to itself and is REFUSED loudly
## rather than silently falling through to the default — see dna.declines.
func _set_evidence(raw: String) -> void:
	var w: String = TANK_SRC.evidence_name(raw.strip_edges().to_lower())
	if w == "sources":
		push_warning("boundary_tank: `sources` is declined by this artifact (no two addends; the image train stands 1.44 m outside the wall) — keeping '%s'" % evidence)
		return
	if _is_evidence(w):
		evidence = w
	else:
		push_warning("boundary_tank: unknown evidence '%s' — keeping '%s'" % [raw, evidence])


func _set_moment(raw: String) -> void:
	var w: String = raw.strip_edges().to_lower()
	if SORT_SRC.MOMENTS.has(w):
		moment = w
	else:
		push_warning("boundary_tank: unknown moment '%s' — keeping '%s'" % [raw, moment])


## GUARDED ON CHANGE. The grid reaches this twice for one placement, and a placement
## carrying any other token arrives with neither key; an unguarded rebuild would tear
## the tank down and raise it again on both, for nothing. `_built` is the "_ready has
## already built once" test — before that, _ready does this itself.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_e: String = evidence
	var before_m: String = moment
	if config_data.has("evidence"):
		_set_evidence(str(config_data["evidence"]))
	if config_data.has("moment"):
		_set_moment(str(config_data["moment"]))
	if _built and (evidence != before_e or moment != before_m):
		_rebuild()


func _rebuild() -> void:
	if _root != null:
		remove_child(_root)
		_root.queue_free()
		_root = null
	_built = false
	_build()
