# @identity
# essence: a turtle-graphics pipe network grown from string commands — `f` adds anchors, `r`/`l` bend bezier handles, `t`/`x` branch into independent curves; SurfaceTool extrudes one continuous mesh along the path
# desire: to make pipe-as-composition feel like writing a sentence — type "f r f l f" and the system turns where you said it would; the pipe IS the score
# critical_parameter: config_file or turtle command string — every junction, elbow, and branch lives in the string; geometry is just rendered grammar
# triggers: _ready() runs the auto_build pass; build_pipe_system() walks turtle commands, sets bezier IN/OUT handles per anchor, extrudes circular cross-sections via sample_baked tangent frames
# emerges: cathedral-organ topology from text — branching drain networks the player can walk through, with smooth corners that cost two lines of bezier instead of a hundred lines of arc math
# needs: VR walking inside pipes [has]; per-segment audio routing [missing]; runtime turtle editing [missing]; apply_grid_config [missing]
# relationships: pairs with seismograph (the readout) and coupled_oscillator_lattice (the medium) to form the wavefunctions plumbing-as-resonance arc; appears in Gravity Creates Rhythm, Sound as Waveform, Spatial Sound Laboratory
# truth: a pipe is a path with mass — when you bend a command string, you bend the air column, and the geometry becomes the instrument

@tool
extends Node3D
class_name BigPipeSystem

## BigPipeSystem — turtle-graphics drain pipes built on Curve3D.
##
## Third rewrite. Previous attempts hand-rolled quarter-torus elbows and
## had to reason about tangent frames manually. This version uses the
## pattern already proven in the project by `curve_extrusion.gd` and
## `dave-stewart-slime-tubes.gd`:
##
##   1. Build a single Curve3D from turtle commands. Each `f` adds an
##      anchor point. Turns set bezier IN/OUT handles at the anchor so
##      the curve bends smoothly through it.
##   2. Extrude a circular cross-section along the curve via SurfaceTool
##      (sample_baked + per-sample tangent frame).
##   3. Branches (`t`, `x`) emit their own independent Curve3D + mesh.
##
## The whole pipe is one continuous mesh. Smooth corners are free — the
## bezier handles are 2 lines of code instead of 100 lines of arc math.

signal build_complete

@export_group("Build Settings")
@export var auto_build: bool = true
@export var config_file: String = ""

@export_group("Pipe Dimensions")
@export var pipe_radius: float = 0.8
@export var segment_length: float = 2.0
## Bezier handle length at turns, as a fraction of segment_length.
## Controls how smooth the corner is. 0 = sharp (straight lines between
## points). 0.5 = classic elbow. 1.0 = very soft curve.
@export var corner_smoothness: float = 0.9

@export_group("Appearance")
@export var albedo_color: Color = Color(0.7, 0.7, 0.8)
@export var metallic: float = 0.8
@export var roughness: float = 0.2

@export_group("Mesh Resolution")
@export var samples_per_segment: int = 16
@export var tube_sides: int = 16

@export_group("DNA")
## AXIS — SLACK: where the SHAPE of a run comes from, once the anchors are given.
## Shared word for word with [[line_builder_3d]] and [[cable_builder]], the other two
## builders in this tier. All three are handed a set of points and asked to make a run
## between them; all three have to answer the same question — does the run admit that
## it has weight? A cable sags and a pipe does not, and that difference is physics the
## builder either honours, approximates, or ignores. One vocabulary, three homes.
##
## This artifact's home is `spline`: the whole third rewrite exists because bezier
## handles at the turn vertices buy smooth corners for two lines instead of a hundred
## lines of arc math. That is an approximation of a bend, drawn by the draughtsman.
##
##   chord     the handles are stripped. The run turns at a hard mitred angle, the
##             elbow the rewrite was written to avoid. Weight and bending both denied.
##   spline    THE LEGACY LINEAGE. corner_smoothness bezier handles at every turn
##             vertex; the pipe swings through its corners in a long fair arc.
##   catenary  the run is no longer level. Every span between anchors bellies downward
##             by a third of its own length — a pipe carrying its own mass.
##   festoon   the same belly, far deeper: the runs hang between their anchors in
##             loops, a drain that has given up on being infrastructure.
##   truss     the run refuses to hang and SHOWS what stops it: a post dropped from
##             every anchor to a common base plane, a bottom chord joining the feet,
##             and a zigzag web between. The pipe grows a gantry.
##
## Nothing here is a rate. The corner_smoothness / segment_length knobs above stay what
## they were; this axis is about what the geometry ADMITS, not how fast anything moves.
@export var slack: String = "spline"
const SLACKS: PackedStringArray = ["chord", "spline", "catenary", "festoon", "truss"]

# Turtle state
var _pos: Vector3 = Vector3.ZERO
var _forward: Vector3 = Vector3.FORWARD   # Godot: (0, 0, -1)
var _up: Vector3 = Vector3.UP
var _pending_turn: bool = false
var _pre_turn_forward: Vector3 = Vector3.ZERO

# The curve being built. A new one starts at _begin_curve() (first `f`
# after a cursor reset or after a branch). Branches emit a second curve.
var _curve: Curve3D = null
var _curves: Array[Curve3D] = []
var _segments_root: Node3D = null


func _ready() -> void:
	if auto_build and not config_file.is_empty():
		load_config_from_file(config_file)


# ─── Public API ─────────────────────────────────────────────────────

func generate(code: String) -> void:
	_reset()
	_curves = []
	_curve = null

	var commands := code.split(",", false)
	for cmd in commands:
		_dispatch(cmd.strip_edges().to_lower())

	if _curve != null:
		_curves.append(_curve)
	_emit_tubes()
	build_complete.emit()


func generate_from_code(code: String) -> void: generate(code)
func generate_pipes(code: String) -> void: generate(code)


func load_config_from_dict(data: Dictionary) -> void:
	var layout: Dictionary = data.get("layout", {})
	if layout.has("segment_length"):
		segment_length = float(layout["segment_length"])
	if layout.has("pipe_radius"):
		pipe_radius = float(layout["pipe_radius"])
	if layout.has("tube_radius"):
		pipe_radius = float(layout["tube_radius"])

	if data.has("path") and typeof(data["path"]) == TYPE_STRING:
		generate(String(data["path"]))
	elif data.has("segments") and typeof(data["segments"]) == TYPE_ARRAY:
		_build_from_segments(data["segments"] as Array)


func load_config_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("BigPipeSystem: config not found: %s" % path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		load_config_from_dict(parsed as Dictionary)


func clear() -> void:
	if _segments_root and is_instance_valid(_segments_root):
		_segments_root.queue_free()
		_segments_root = null


func apply_grid_config(_config: Dictionary) -> void:
	# LEGACY: this has always discarded everything the grid handed it, including the
	# `#path:` token four maps in the corpus pass. That is left exactly as it was —
	# see the report; it is a wiring bug, not something to quietly change inside a DNA
	# pass. The one thing this now does is adopt a `slack` token, and re-emit ONLY if
	# the system already has curves AND the value actually changed. With no curves
	# (which is every placement today) it is a no-op.
	if not _config.has("slack"):
		return
	var s: String = str(_config["slack"]).strip_edges().to_lower()
	if not SLACKS.has(s) or s == slack:
		return
	slack = s
	if _curves.size() > 0:
		clear()
		_emit_tubes()


# ─── Turtle state ───────────────────────────────────────────────────

func _reset() -> void:
	clear()
	_pos = Vector3.ZERO
	_forward = Vector3.FORWARD
	_up = Vector3.UP
	_pending_turn = false


func _right() -> Vector3:
	return _forward.cross(_up).normalized()


func _yaw(angle: float) -> void:
	_forward = (Basis(_up, angle) * _forward).normalized()


func _pitch(angle: float) -> void:
	var r := _right()
	_forward = (Basis(r, angle) * _forward).normalized()
	_up = (Basis(r, angle) * _up).normalized()


# ─── Command dispatch ───────────────────────────────────────────────

func _dispatch(cmd: String) -> void:
	match cmd:
		"f", "forward", "straight": _cmd_forward()
		"l", "left":  _queue_turn(); _yaw(-PI / 2)
		"r", "right": _queue_turn(); _yaw(PI / 2)
		"u", "up":    _queue_turn(); _pitch(-PI / 2)
		"d", "down":  _queue_turn(); _pitch(PI / 2)
		"t", "tee", "junction":  _cmd_branch_perp(-1.0)
		"x", "cross":            _cmd_cross()
		"cap", "end", "endcap":  _cmd_cap()
		"vu", "vup":             _cmd_vertical(1)
		"vd", "vdown":           _cmd_vertical(-1)
		"": pass
		_: push_warning("BigPipeSystem: unknown command '%s'" % cmd)


func _queue_turn() -> void:
	_pre_turn_forward = _forward
	_pending_turn = true


# ─── Commands ───────────────────────────────────────────────────────

func _cmd_forward() -> void:
	_ensure_curve_started()

	if _pending_turn:
		# The LAST point in the curve is the turn vertex. Set its in/out
		# bezier handles so the curve bends smoothly through it instead
		# of making a sharp angle.
		var last_idx: int = _curve.point_count - 1
		if last_idx >= 0:
			var handle_len: float = corner_smoothness * segment_length
			# in_handle: tangent of curve entering this point = -_pre_turn_forward
			# (Godot handles are relative to the point's position)
			_curve.set_point_in(last_idx, -_pre_turn_forward * handle_len)
			# out_handle: tangent of curve leaving this point = _forward
			_curve.set_point_out(last_idx, _forward * handle_len)
		_pending_turn = false

	var next_pos := _pos + _forward * segment_length
	_curve.add_point(next_pos)
	_pos = next_pos


func _cmd_branch_perp(side_sign: float) -> void:
	# T-junction: finish a straight segment along forward, then spawn a
	# branch curve perpendicular to forward (side_sign -1 = left, +1 = right).
	_cmd_forward()
	var mid_idx: int = _curve.point_count - 1
	var mid_pos: Vector3 = _curve.get_point_position(mid_idx)
	var side: Vector3 = _right() * side_sign

	# Emit the branch as its own curve
	var branch := Curve3D.new()
	branch.add_point(mid_pos)
	branch.add_point(mid_pos + side * segment_length)
	_curves.append(branch)


func _cmd_cross() -> void:
	# Forward + perpendicular crossbar straight through the midpoint
	_cmd_forward()
	var mid_idx: int = _curve.point_count - 1
	var mid_pos: Vector3 = _curve.get_point_position(mid_idx)
	var side: Vector3 = _right()

	var branch := Curve3D.new()
	branch.add_point(mid_pos - side * (segment_length / 2.0))
	branch.add_point(mid_pos + side * (segment_length / 2.0))
	_curves.append(branch)


func _cmd_cap() -> void:
	# Short stub terminating the current curve
	if _curve == null or _curve.point_count == 0:
		return
	var stub := _pos + _forward * (segment_length * 0.25)
	_curve.add_point(stub)
	_pos = stub


func _cmd_vertical(direction: int) -> void:
	# Reorient cursor vertically + advance one segment
	_forward = Vector3.UP if direction > 0 else Vector3.DOWN
	_cmd_forward()


# ─── Curve management ───────────────────────────────────────────────

func _ensure_curve_started() -> void:
	if _curve == null:
		_curve = Curve3D.new()
		_curve.add_point(_pos)


func _emit_tubes() -> void:
	_ensure_segments_root()
	var mat := _make_material()
	for c in _curves:
		if c.point_count < 2:
			continue
		# SLACK: at the default ("spline") _slack_curve returns the very same Curve3D
		# object, so this line extrudes exactly what it extruded before.
		var mesh := _extrude_curve(_slack_curve(c), pipe_radius, mat)
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		_segments_root.add_child(mi)

	# The gantry, APPENDED LAST so every pipe mesh above keeps its index and geometry.
	# Only "truss" adds anything at all here.
	if slack == "truss":
		for c in _curves:
			if c.point_count < 2:
				continue
			var tm := _truss_mesh(c)
			if tm == null:
				continue
			var ti := MeshInstance3D.new()
			ti.mesh = tm
			ti.material_override = mat
			_segments_root.add_child(ti)


## Extrude a circular profile along a Curve3D. Adapted from the project's
## curve_extrusion.gd and dave-stewart-slime-tubes.gd — the proven pattern
## for this problem in the codebase.
func _extrude_curve(curve: Curve3D, radius: float, _mat: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var length: float = curve.get_baked_length()
	if length < 0.0001:
		return null

	# Total samples scale with curve length so longer pipes don't pixelate
	var samples: int = max(int(length / segment_length * samples_per_segment), 8)

	# Precompute circular profile in 2D
	var profile: Array = []
	for k in range(tube_sides):
		var a: float = float(k) / float(tube_sides) * TAU
		profile.append(Vector2(cos(a), sin(a)) * radius)

	# Walk the curve, building a ring of verts at each sample
	var rings: Array = []  # Array of Array[Vector3]
	for i in range(samples + 1):
		var offset: float = (float(i) / float(samples)) * length
		var pos: Vector3 = curve.sample_baked(offset)
		# Tangent via forward-difference
		var next_offset: float = min(offset + length / float(samples * 2), length)
		var prev_offset: float = max(offset - length / float(samples * 2), 0.0)
		var tangent: Vector3 = (curve.sample_baked(next_offset) - curve.sample_baked(prev_offset)).normalized()
		if tangent.length_squared() < 0.0001:
			tangent = Vector3.FORWARD

		# Orthonormal frame — pick up vector not parallel to tangent
		var up: Vector3 = Vector3.UP
		if abs(tangent.dot(up)) > 0.99:
			up = Vector3.RIGHT
		var right: Vector3 = tangent.cross(up).normalized()
		up = right.cross(tangent).normalized()

		var ring: Array = []
		for v in profile:
			ring.append(pos + right * v.x + up * v.y)
		rings.append(ring)

	# Stitch rings into triangles
	for i in range(rings.size() - 1):
		var r0: Array = rings[i]
		var r1: Array = rings[i + 1]
		for j in range(tube_sides):
			var k: int = (j + 1) % tube_sides
			st.add_vertex(r0[j]); st.add_vertex(r1[j]); st.add_vertex(r1[k])
			st.add_vertex(r0[j]); st.add_vertex(r1[k]); st.add_vertex(r0[k])

	st.generate_normals()
	return st.commit()


func _ensure_segments_root() -> void:
	if _segments_root == null or not is_instance_valid(_segments_root):
		_segments_root = Node3D.new()
		_segments_root.name = "PipeSegments"
		add_child(_segments_root)


func _make_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo_color
	m.metallic = metallic
	m.roughness = roughness
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ─── segments-array schema fallback ─────────────────────────────────

func _build_from_segments(segments: Array) -> void:
	_reset()
	_curve = Curve3D.new()
	for seg in segments:
		if typeof(seg) != TYPE_DICTIONARY:
			continue
		var pos_raw: Variant = seg.get("position", [0, 0, 0])
		if typeof(pos_raw) == TYPE_ARRAY and (pos_raw as Array).size() >= 3:
			_curve.add_point(Vector3(float(pos_raw[0]), float(pos_raw[1]), float(pos_raw[2])))
	_curves.append(_curve)
	_emit_tubes()


# ─── SLACK ──────────────────────────────────────────────────────────
# Appended LAST. Nothing above was touched except the _slack_curve() call inside
# _emit_tubes() and the truss block after its loop, both inert at the default: at
# "spline" the extruder receives the identical Curve3D object and nothing extra is
# added, so the legacy lineage renders the mesh it always rendered.


## The curve the extruder actually gets. Assigned rather than returned per branch so
## there is exactly one exit and no exhaustiveness question. `out` starts as the very
## same Curve3D object, which is what "spline" — the legacy lineage — extrudes.
func _slack_curve(src: Curve3D) -> Curve3D:
	var out: Curve3D = src
	match slack:
		"chord":
			out = _straighten(src)
		"catenary":
			out = _sag_curve(src, 0.35)
		"festoon":
			out = _sag_curve(src, 0.85)
		"truss":
			out = src             # the pipe keeps its fillets; the gantry is added after
	return out


## Same anchors, no bezier handles: the run turns at a hard mitred angle.
func _straighten(src: Curve3D) -> Curve3D:
	var out := Curve3D.new()
	for i in range(src.point_count):
		out.add_point(src.get_point_position(i))
	return out


## Resample the baked curve and bow each anchor-to-anchor span downward — zero at the
## anchors, deepest at mid-span, depth = factor x the arc length of that span. Anchors
## are located on the baked curve by arc offset, so this works on filleted corners and
## on the handle-free branch curves alike.
func _sag_curve(src: Curve3D, factor: float) -> Curve3D:
	var n: int = src.point_count
	if n < 2:
		return src
	if src.get_baked_length() < 0.0001:
		return src
	var out := Curve3D.new()
	for i in range(n - 1):
		var o0: float = src.get_closest_offset(src.get_point_position(i))
		var o1: float = src.get_closest_offset(src.get_point_position(i + 1))
		var span: float = o1 - o0
		if span <= 0.0001:
			continue
		var steps: int = maxi(int(span / maxf(segment_length, 0.001) * 8.0), 8)
		for k in range(steps + 1):
			if out.point_count > 0 and k == 0:
				continue
			var t: float = float(k) / float(steps)
			var p: Vector3 = src.sample_baked(o0 + span * t)
			p.y -= factor * span * 4.0 * t * (1.0 - t)
			out.add_point(p)
	return out if out.point_count >= 2 else src


## The gantry under a run: a post from every anchor down to a common base plane, a
## bottom chord joining the feet, and a zigzag web between chord and pipe.
func _truss_mesh(src: Curve3D) -> ArrayMesh:
	var n: int = src.point_count
	if n < 2:
		return null
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var base_y: float = src.get_point_position(0).y
	for i in range(n):
		base_y = minf(base_y, src.get_point_position(i).y)
	base_y -= maxf(segment_length, 0.5) * 1.1

	var r: float = maxf(pipe_radius * 0.16, 0.04)
	var feet := PackedVector3Array()
	for i in range(n):
		var p: Vector3 = src.get_point_position(i)
		var foot := Vector3(p.x, base_y, p.z)
		feet.append(foot)
		_strut(st, p, foot, r)
	for i in range(n - 1):
		_strut(st, feet[i], feet[i + 1], r)
		if i % 2 == 0:
			_strut(st, src.get_point_position(i), feet[i + 1], r)
		else:
			_strut(st, feet[i], src.get_point_position(i + 1), r)

	st.generate_normals()
	return st.commit()


## One straight round member, swept into a SurfaceTool the caller owns.
func _strut(st: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	var delta: Vector3 = b - a
	if delta.length_squared() < 0.0001:
		return
	var dir: Vector3 = delta.normalized()
	var up := Vector3.UP
	if absf(dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = dir.cross(up).normalized()
	var frame_up: Vector3 = right.cross(dir).normalized()
	for k in range(tube_sides):
		var a1: float = float(k) / float(tube_sides) * TAU
		var a2: float = float(k + 1) / float(tube_sides) * TAU
		var o1: Vector3 = (right * cos(a1) + frame_up * sin(a1)) * radius
		var o2: Vector3 = (right * cos(a2) + frame_up * sin(a2)) * radius
		st.add_vertex(a + o1); st.add_vertex(b + o1); st.add_vertex(b + o2)
		st.add_vertex(a + o1); st.add_vertex(b + o2); st.add_vertex(a + o2)
