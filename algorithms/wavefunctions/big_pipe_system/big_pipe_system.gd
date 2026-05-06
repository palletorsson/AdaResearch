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
	pass


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
		var mesh := _extrude_curve(c, pipe_radius, mat)
		if mesh == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat
		_segments_root.add_child(mi)


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
