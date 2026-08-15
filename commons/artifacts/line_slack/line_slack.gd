extends Node3D
class_name LineSlack

## line_slack — a point in motion is a LINE, but between two fixed points there is not one
## line. There are as many as there are laws, and one of the five obeys none.
##
## THE FAMILY. Three scripts carry an axis called `slack` and all three carry the
## BYTE-IDENTICAL const ["chord", "spline", "catenary", "festoon", "truss"] —
## interactive_line.gd:43 (the scene registered as line_builder_3d), cable_builder.gd:50,
## big_pipe_system.gd:82. Twelve registry names resolve to those three scripts. What
## differs is only which value each one SHIPS: line_builder_3d "chord", big_pipe_system
## "spline", cable_builder "catenary". One vocabulary, three homes on it, and every member
## stands in exactly one of the five and forgoes the other four.
##
## THIS BENCH PUTS THE WORD ON THE AXIS AND ASKS WHAT EACH VALUE IS OBEYING. The run is
## given six fixed points — two anchored on masts, four free — and drawn five times by
## interactive_line's own five functions, then drawn again at three distances from the
## cause. Nothing about the points changes. Only the law does.
##
## WHAT THE CODE SAYS, and it corrected the brief in four places:
##
##   1. `catenary` IS A PARABOLA. All three scripts sag a span with the identical line
##      `p.y -= factor * span * 4.0 * t * (1.0 - t)` (interactive_line _swag, cable_builder
##      _swag, big_pipe_system _sag_curve). 4t(1-t) is a quadratic. Nowhere in the family
##      is there a cosh — the only cosh in the whole `slack` corpus is slack_yard's, and
##      that is a synthesis's DATUM, added later, not a member's behaviour. A parabola is
##      the shape a cable takes under a load uniform in the HORIZONTAL coordinate: a
##      suspension bridge carrying a level deck. A chain under its own weight is uniform
##      along the ARC and hangs as cosh. So `catenary` obeys a real law, and not the one it
##      is named after. AND YOU CANNOT SEE IT: at this bench's sag the parabola and the
##      true catenary of the same arc length differ by 1.7 mm at `catenary` and 5.6 mm at
##      `festoon`, against a run 40 mm thick. THAT is why this artifact has a second axis.
##      The difference between two laws is not in the curve. It is in the load.
##
##   2. CHORD IS NOT THE ONLY VALUE WITHOUT A PHYSICS. interactive_line's own gloss calls
##      `chord` "the draughtsman's answer, denied" and `spline` "the draughtsman's answer,
##      granted" — two conventions, neither with weight in it, the second explicitly "DRAWN,
##      not derived; a lofting batten, not gravity". So the five values are 2 drawings + 2
##      hangings + 1 structure, and the `load` reading is blank for TWO of them.
##
##   3. FESTOON IS NOT A LAW, IT IS A DIAL. `catenary` is _swag(anchors, 0.45) and `festoon`
##      is _swag(anchors, 1.15): the same call, ratio 2.5556 exactly. Same differential
##      equation, more cable. That is the sharpest possible version of "decoration": not a
##      different physics chosen for looks, but the SAME physics with the knob turned.
##
##   4. A TRUSS'S LINE IS A CHORD. interactive_line builds `truss` as
##      _emit_run(st, anchors, line_thickness) followed by _emit_truss(st, anchors) — the
##      first of those two lines is `chord`, verbatim. The truss changes nothing about the
##      line; it changes what is underneath it. So at reading=line, chord and truss are the
##      SAME PICTURE to the byte, and the whole of `truss` lives in one of three readings.
##      That is registered as a designed null, and it is the artifact's argument.
##
## THE THESIS SOMEBODY CAN DISAGREE WITH: a line between fixed points is a law made
## visible, and the law is not recoverable from the curve. The disagreement available is
## good — a reader can hold that this is just five arbitrary drawing conventions and that
## calling one of them "obeying gravity" is a story told about a quadratic. The 1.7 mm is
## where that objection is strongest, and the `load` reading is the answer to it: the
## conventions are indistinguishable, and their CAUSES are not.
##
## Nothing animates, nothing is printed, nothing is random. There is no _process, no Timer,
## no randf and no shader in this file, so two builds of one value are the same mesh.

## WHICH LAW THE LINE IS OBEYING. interactive_line's five values, its own const, its own
## order, and its own shipped default first. The behaviour of each is that file's own
## function, transcribed and not re-imagined:
##
##   chord     the draughtsman's answer, DENIED. Straight members point to point, a visible
##             kink at every handle. Obeys the handles and nothing else — pure geometry, a
##             claim about space with no matter anywhere in it. Arc 1.0614 m over a straight
##             span of 0.9600: even the null law spends 10.6% more line than the gap needs,
##             because it agreed to pass through six points instead of two.
##   spline    the draughtsman's answer, GRANTED. _fair_curve: a Curve3D through the same
##             six points with Catmull-Rom tangents (next - prev) * 0.28, resampled evenly.
##             Smooth, kinkless, NO DOWNWARD BIAS — the curvature was drawn, not derived.
##             Arc 1.0971 m, and it never leaves the chord by more than 21.0 mm, which is
##             half of the run's own thickness. Two conventions, one silhouette.
##   catenary  weight admitted. _swag(anchors, 0.45): every span bows downward, zero at each
##             handle, deepest at mid-span, depth 0.45 x that span = 86.4 mm here. It is a
##             PARABOLA, so what it actually solves is a load uniform per horizontal metre.
##             Arc 1.4612 m, 152% of the straight span.
##   festoon   the same law, 2.5556x. _swag(anchors, 1.15): sag 220.8 mm on a 192 mm span,
##             so each loop hangs deeper than its own span is long. Arc 2.7203 m — 283% of
##             the straight span, nearly three times more line than the gap needs. Slack
##             admitted, and then some.
##   truss     weight REFUSED, and the refusal shown. _emit_run(anchors) — which is `chord`
##             — plus _emit_truss: a straight bottom chord, a post from every handle down to
##             it, and a zigzag web alternating between them. Arc 1.0614 m, identical to
##             chord's, because it IS chord's. The line becomes a girder; the physics is
##             answered by structure rather than by shape.
@export_enum("chord", "spline", "catenary", "festoon", "truss") var slack: String = "chord":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SLACKS.has(picked):
			return                      ## an unreachable value keeps the current run
		slack = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW MUCH OF THE CAUSE IS IN THE FRAME. cube_lines' `disclosure` move, imported: that axis
## keeps twelve edge positions fixed and changes only which of them are DRAWN. This one keeps
## one run fixed and changes what is drawn beside it.
##
##   line   the run alone, on its masts, threading its six handles. What all three family
##          members actually ship — none of them draws a datum or a load. The default.
##   load   the run plus the force it is answering, as real geometry and nothing else.
##          catenary and festoon: eleven equal weights on stems, hung at eleven EQUAL
##          HORIZONTAL intervals, because equal-per-horizontal-metre is precisely the load
##          whose solution is the parabola the code writes. The spacing IS the claim; a
##          chain's own weight would be equal along the arc and would bunch in the sags.
##          truss: the bottom chord, six posts and the web — the source's _emit_truss, which
##          is the load path drawn as members. chord and spline: NOTHING, because a drawing
##          has no load, and those two frames are identical to their `line` frames.
##   span   the run plus the straight anchor-to-anchor rod behind it, 10 mm, in cube_lines'
##          own far-depth tint. Not a gauge and not a measurement — no sticks, no stations,
##          no numbers; slack_yard's `datum` axis already owns all of that and does it
##          better. Just the shortest path between the two fixed points, present in the
##          picture, so that the departure from pure geometry is a thing you see rather
##          than a thing you are told.
@export_enum("line", "load", "span") var reading: String = "line":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One span, or all five laws in a row. NOT PART OF EITHER AXIS. capture_config_sweep unions
## the AABB across a spec's variants, so a five-wide row in the same spec frames every single
## against six metres and photographs it as a speck. The registry fixture pins `single`.
## `ladder` is also slack_yard's yard in miniature and is a design view only — this bench
## must not publish a competing five-lane frame.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const SLACKS: PackedStringArray = ["chord", "spline", "catenary", "festoon", "truss"]
const READINGS: PackedStringArray = ["line", "load", "span"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the given, identical in all fifteen cells ──────────────────────────────────────────
## SIX points and not two, and this is forced by the source rather than chosen. With only
## the two anchors, _fair_curve's tangents at both ends are (a[1] - a[0]) * 0.28 — collinear
## with the chord — so the cubic degenerates and `spline` returns the straight segment.
## A two-point bench would have shipped an axis with a dead value that no gate could see.
## The two END handles are the fixed endpoints, anchored on the mast tops; the four interior
## ones are free, fixed literals, and identical under every law.
const N_HANDLES: int = 6
const SPAN_HALF: float = 0.48                ## anchors at x = -0.48 and +0.48
const ANCHOR_Y: float = 0.95
const STEP_X: float = 0.192                  ## (2 * SPAN_HALF) / (N_HANDLES - 1)
const HANDLE_DY: PackedFloat32Array = [0.000, 0.062, -0.048, 0.052, -0.058, 0.000]

# ── the run, metres ────────────────────────────────────────────────────────────────────
const RUN_R: float = 0.020        ## interactive_line's line_thickness default, verbatim
const TRUSS_R: float = 0.015      ## its maxf(line_thickness * 0.75, 0.012), evaluated
const GHOST_R: float = 0.010
const GHOST_Z: float = -0.035     ## the straight span sits BEHIND the run's plane
const TUBE_SIDES: int = 8         ## interactive_line's tube_sides default, verbatim

const CAT_F: float = 0.45         ## _swag(anchors, 0.45)
const FES_F: float = 1.15         ## _swag(anchors, 1.15)
const SPLINE_T: float = 0.28      ## _fair_curve's tangent scale
const SWAG_STEPS: int = 10        ## _swag's own step count

## RESCALED, and it is the only source constant that is. interactive_line drops its truss
## 0.55 m under a run of 7 x 0.5 = 3.50 m: a depth of 0.15714 of the span. A girder's depth
## is proportional to what it spans, so the ratio is the thing worth keeping and 0.55 m
## under a 0.96 m span would be a girder deeper than half its own span. 0.15729 x 0.96 =
## 0.151. (slack_yard declined to rescale cable_builder's 0.45 m drawn depth for the
## opposite and correct reason: there the CONSTANT is the argument — a drawn curve owes
## nothing to its span. Here the constant is not an argument about anything.)
const DROP: float = 0.151

# ── the constant furniture: what makes every variant the same box ──────────────────────
## rule_bench's backplate move. The masts and the sill are built BEFORE the axis is
## consulted and are identical in all fifteen cells, so the union AABB the sweep frames on
## is theirs. Measured in a Python replica of this geometry: every variant is
## 0.972 x 1.032 x 0.758 m in world space after FRONT_YAW, except `spline`, which is
## 1.034 m tall because the Catmull-Rom overshoots handle 1 by 2 mm. A catenary does sag
## below a chord and a truss is thicker — festoon's lowest tube point is 0.670 and its
## hung weights reach 0.569, the truss's bottom chord sits at 0.799 — and none of that
## touches the union, because the sill is already at 0.000 and the masts at 0.930.
const MAST_W: float = 0.05
const MAST_H: float = 0.93
const SILL_W: float = 1.08
const SILL_H: float = 0.03
const SILL_D: float = 0.16
const BEAD: float = 0.028         ## a handle: one of the six given points

# ── reading = load ─────────────────────────────────────────────────────────────────────
## Eleven weights at 80 mm of HORIZONTAL pitch, from x = -0.40 to +0.40. Equal size and
## equal horizontal spacing is not a styling decision: it is the load whose solution is
## 4t(1-t), which is the curve the code actually writes.
const LOAD_STATIONS: int = 11
const LOAD_STEP: float = 0.08
const STEM_LEN: float = 0.065
const STEM_R: float = 0.008
const LOAD_BEAD: float = 0.056

## The sweep's standpoint bearing. The run is planar at z = 0 and is turned to face it, so
## the departure from the straight span is seen as a departure rather than end-on. Same
## argument rule_bench and postulate_bench make. (interactive_line jitters its handles in z
## by randf_range(-0.5, 0.5); there is no RNG anywhere in this file, so the plane is flat
## by construction and not by seeding.)
const FRONT_YAW: float = 0.62
const LADDER_PITCH: float = 1.30

const STRUCT_COLOR: Color = Color(0.18, 0.20, 0.26)   ## capstone platform_color, gd:35
const RUN_COLOR: Color = Color(0.40, 0.80, 1.00)      ## cube_lines LEGACY_TINT, gd:51
const GHOST_COLOR: Color = Color(0.08, 0.14, 0.24)    ## cube_lines `depth` far end, gd:158
const LOAD_COLOR: Color = Color(1.00, 0.72, 0.30)     ## cube_lines `horizon` amber, gd:161
const RUN_EMISSION: Color = Color(0.14, 0.42, 0.62)
## The six given points, in off-white: the one thing all fifteen frames share is visibly
## not the law. rule_bench's seed convention.
const HANDLE_COLOR: Color = Color(0.93, 0.95, 0.97)

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("slack"):
		slack = str(config_data["slack"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
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
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = SLACKS.duplicate()
	else:
		names.append(_pick(slack, SLACKS, "chord"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Slack_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		holder.rotation.y = FRONT_YAW
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, names[i])


# ── the given points ───────────────────────────────────────────────────────────────────

func _handles() -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(N_HANDLES):
		out.append(Vector3(-SPAN_HALF + float(i) * STEP_X, ANCHOR_Y + HANDLE_DY[i], 0.0))
	return out


## interactive_line's dispatch, one for one. `chord` and `truss` return the raw handles
## because that is exactly what that file does for both of them.
func _run_path(which: String) -> PackedVector3Array:
	var a: PackedVector3Array = _handles()
	match which:
		"spline":
			return _fair_curve(a)
		"catenary":
			return _swag(a, CAT_F)
		"festoon":
			return _swag(a, FES_F)
	return a


## interactive_line _fair_curve, verbatim: a fair curve THROUGH the same handles —
## Catmull-Rom tangents on a Curve3D, then resampled evenly. No downward bias; the
## smoothing is a drawing convention.
func _fair_curve(a: PackedVector3Array) -> PackedVector3Array:
	var n: int = a.size()
	if n < 2:
		return a
	var cv := Curve3D.new()
	for i in range(n):
		cv.add_point(a[i])
	for i in range(n):
		var prev: Vector3 = a[maxi(i - 1, 0)]
		var nxt: Vector3 = a[mini(i + 1, n - 1)]
		var tangent: Vector3 = (nxt - prev) * SPLINE_T
		cv.set_point_in(i, -tangent)
		cv.set_point_out(i, tangent)
	var length: float = cv.get_baked_length()
	if length < 0.0001:
		return a
	var steps: int = maxi((n - 1) * 10, 8)
	var out := PackedVector3Array()
	for k in range(steps + 1):
		out.append(cv.sample_baked(length * float(k) / float(steps)))
	return out


## interactive_line _swag, verbatim: per-span downward bow, zero at each handle and deepest
## at mid-span, scaled by the length of that span. 4t(1-t) is a PARABOLA — see the header.
func _swag(a: PackedVector3Array, factor: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(a.size() - 1):
		var p1: Vector3 = a[i]
		var p2: Vector3 = a[i + 1]
		var span: float = p1.distance_to(p2)
		for k in range(SWAG_STEPS + 1):
			if i > 0 and k == 0:
				continue
			var t: float = float(k) / float(SWAG_STEPS)
			var p: Vector3 = p1.lerp(p2, t)
			p.y -= factor * span * 4.0 * t * (1.0 - t)
			out.append(p)
	return out


## The run's height at a horizontal station. The paths are monotone in x by construction —
## every handle is further right than the last and both generators only interpolate between
## adjacent handles — so the first bracketing segment is the right one.
func _path_y_at_x(path: PackedVector3Array, x: float) -> float:
	if path.is_empty():
		return ANCHOR_Y
	for i in range(path.size() - 1):
		var x0: float = path[i].x
		var x1: float = path[i + 1].x
		if (x0 - x) * (x1 - x) <= 0.0 and absf(x1 - x0) > 0.000001:
			var t: float = (x - x0) / (x1 - x0)
			return path[i].y + (path[i + 1].y - path[i].y) * t
	return path[path.size() - 1].y


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_variant(holder: Node3D, which: String) -> void:
	# The masts and the sill first, before the axis is consulted, so that the box the
	# sweep frames on is the same for every cell.
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mast_x: PackedFloat32Array = [-SPAN_HALF, SPAN_HALF]
	for i in range(mast_x.size()):
		_add_box(frame, Vector3(mast_x[i], MAST_H * 0.5, 0.0),
			Vector3(MAST_W, MAST_H, MAST_W))
	_add_box(frame, Vector3(0.0, SILL_H * 0.5, 0.0), Vector3(SILL_W, SILL_H, SILL_D))
	_commit(holder, "Frame", frame, STRUCT_COLOR, false)

	if reading == "span":
		var ghost := SurfaceTool.new()
		ghost.begin(Mesh.PRIMITIVE_TRIANGLES)
		_emit_run(ghost, _pair(Vector3(-SPAN_HALF, ANCHOR_Y, GHOST_Z),
			Vector3(SPAN_HALF, ANCHOR_Y, GHOST_Z)), GHOST_R)
		_commit(holder, "Span", ghost, GHOST_COLOR, false)

	var path: PackedVector3Array = _run_path(which)
	var run := SurfaceTool.new()
	run.begin(Mesh.PRIMITIVE_TRIANGLES)
	_emit_run(run, path, RUN_R)
	_commit(holder, "Run", run, RUN_COLOR, true)

	var given := SurfaceTool.new()
	given.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: PackedVector3Array = _handles()
	for i in range(pts.size()):
		_add_box(given, pts[i], Vector3(BEAD, BEAD, BEAD))
	_commit(holder, "Handles", given, HANDLE_COLOR, false)

	if reading == "load":
		var load_st := SurfaceTool.new()
		load_st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var drew: bool = false
		if which == "catenary" or which == "festoon":
			_emit_weights(load_st, path)
			drew = true
		elif which == "truss":
			_emit_truss(load_st, _handles())
			drew = true
		# chord and spline draw NOTHING here, and that is the reading, not a gap in it.
		if drew:
			_commit(holder, "Load", load_st, LOAD_COLOR, false)


## The load that makes the parabola: equal weights at EQUAL HORIZONTAL SPACING, hung off
## the run on short stems. Not a gauge — nothing here measures anything, and the weights
## are the same size at every station because a uniform load is uniform.
func _emit_weights(st: SurfaceTool, path: PackedVector3Array) -> void:
	var first: float = -0.5 * float(LOAD_STATIONS - 1) * LOAD_STEP
	for k in range(LOAD_STATIONS):
		var x: float = first + float(k) * LOAD_STEP
		var y: float = _path_y_at_x(path, x)
		_emit_run(st, _pair(Vector3(x, y, 0.0), Vector3(x, y - STEM_LEN, 0.0)), STEM_R)
		_add_box(st, Vector3(x, y - STEM_LEN - LOAD_BEAD * 0.5, 0.0),
			Vector3(LOAD_BEAD, LOAD_BEAD, LOAD_BEAD))


## interactive_line _emit_truss, verbatim but for DROP and TRUSS_R: the lattice that stops
## the run hanging — a straight bottom chord under the whole line, a post from every handle
## down to it, and a zigzag web between them.
func _emit_truss(st: SurfaceTool, a: PackedVector3Array) -> void:
	var n: int = a.size()
	if n < 2:
		return
	var drop: Vector3 = Vector3(0.0, DROP, 0.0)
	var foot_a: Vector3 = a[0] - drop
	var foot_b: Vector3 = a[n - 1] - drop
	_emit_run(st, _pair(foot_a, foot_b), TRUSS_R)
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var foot: Vector3 = foot_a.lerp(foot_b, t)
		_emit_run(st, _pair(a[i], foot), TRUSS_R)
		if i < n - 1:
			var t2: float = float(i + 1) / float(maxi(n - 1, 1))
			var foot2: Vector3 = foot_a.lerp(foot_b, t2)
			if i % 2 == 0:
				_emit_run(st, _pair(a[i], foot2), TRUSS_R)
			else:
				_emit_run(st, _pair(foot, a[i + 1]), TRUSS_R)


func _pair(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.append(a)
	out.append(b)
	return out


## interactive_line's swept-circle tube over an arbitrary path, with explicit outward
## normals added: the source calls generate_normals(), which is fine for it and gives this
## file no control over a tube whose radius is small next to its length. Wound outward AND
## drawn with CULL_DISABLED, because wave 13's lesson is that a run photographed from
## behind is indistinguishable from a run that was never built.
func _emit_run(st: SurfaceTool, path: PackedVector3Array, radius: float) -> void:
	var last: int = path.size() - 1
	if last < 1:
		return
	for i in range(last):
		var p1: Vector3 = path[i]
		var p2: Vector3 = path[i + 1]
		var delta: Vector3 = p2 - p1
		if delta.length_squared() < 0.0000001:
			continue
		var segment_dir: Vector3 = delta.normalized()
		var up: Vector3 = Vector3.UP
		if absf(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = segment_dir.cross(up).normalized()
		var forward: Vector3 = right.cross(segment_dir).normalized()
		for side in range(TUBE_SIDES):
			var angle1: float = (float(side) / float(TUBE_SIDES)) * TAU
			var angle2: float = (float(side + 1) / float(TUBE_SIDES)) * TAU
			var n1: Vector3 = right * cos(angle1) + forward * sin(angle1)
			var n2: Vector3 = right * cos(angle2) + forward * sin(angle2)
			var a1: Vector3 = p1 + n1 * radius
			var b1: Vector3 = p2 + n1 * radius
			var a2: Vector3 = p1 + n2 * radius
			var b2: Vector3 = p2 + n2 * radius
			st.set_normal(n1)
			st.add_vertex(a1)
			st.set_normal(n1)
			st.add_vertex(b1)
			st.set_normal(n2)
			st.add_vertex(b2)
			st.set_normal(n1)
			st.add_vertex(a1)
			st.set_normal(n2)
			st.add_vertex(b2)
			st.set_normal(n2)
			st.add_vertex(a2)
		# Flat caps, so an 8-sided tube does not read as a hollow pipe end-on.
		_cap(st, p1, right, forward, -segment_dir, radius)
		_cap(st, p2, right, forward, segment_dir, radius)


func _cap(st: SurfaceTool, at: Vector3, right: Vector3, forward: Vector3, n: Vector3,
		radius: float) -> void:
	for side in range(TUBE_SIDES):
		var angle1: float = (float(side) / float(TUBE_SIDES)) * TAU
		var angle2: float = (float(side + 1) / float(TUBE_SIDES)) * TAU
		var p1: Vector3 = at + (right * cos(angle1) + forward * sin(angle1)) * radius
		var p2: Vector3 = at + (right * cos(angle2) + forward * sin(angle2)) * radius
		st.set_normal(n)
		st.add_vertex(at)
		st.set_normal(n)
		st.add_vertex(p1)
		st.set_normal(n)
		st.add_vertex(p2)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], Vector3(0.0, 0.0, 1.0))
	_quad(st, p[5], p[4], p[7], p[6], Vector3(0.0, 0.0, -1.0))
	_quad(st, p[3], p[2], p[6], p[7], Vector3(0.0, 1.0, 0.0))
	_quad(st, p[4], p[5], p[1], p[0], Vector3(0.0, -1.0, 0.0))
	_quad(st, p[1], p[5], p[6], p[2], Vector3(1.0, 0.0, 0.0))
	_quad(st, p[4], p[0], p[3], p[7], Vector3(-1.0, 0.0, 0.0))


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3) -> void:
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emissive: bool) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emissive)
	holder.add_child(mi)


## StandardMaterial3D only. interactive_line drives its run through line_shader.tres, which
## carries time_offset, flow_speed, glow_intensity, thickness_variation and pulse_frequency
## and had to be pinned by a handle_seed fixture after it was found rolling a fresh
## glow_intensity every frame in all 72 placements. There is no shader here, so there is
## nothing to pin: that debt is the one thing from the source this bench does not inherit.
func _mat(c: Color, emissive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		m.emission_enabled = true
		m.emission = RUN_EMISSION
		m.emission_energy_multiplier = 0.5
	return m
