# interactive_line.gd - a line as a tube threaded through grabbable points
#
# @identity
# essence: a line rendered as a tube through a chain of grabbable point-spheres, rebuilt every frame from their positions
# desire: learner feels that a line is not a stroke but a sequence of points — move a point and the line follows
# critical_parameter: the point positions (point_count and their live global_position) — the line is nothing but the points it threads
# triggers: spawns point_count spheres with random jitter, then rebuilds a tube mesh through them every _process via SurfaceTool
# emerges: the insight that a curve is an interpolation over samples — continuity is manufactured between discrete handles
# needs: [live tube rebuilt from grabbable points [has], missing a control to add or remove points at runtime]
# relationships: the movable cousin of the static line primitive; a bridge from point to curve
# truth: a line is a decision to connect points — the points are given, the connection is authored
extends Node3D

@export var point_scene: PackedScene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
@export var line_material: ShaderMaterial = preload("res://commons/resourses/shaders/line_shader.tres")
@export var point_count: int = 8
@export var point_spacing: float = 0.5
@export var line_thickness: float = 0.02
@export var tube_sides: int = 8  # Number of sides for the tube

## AXIS — SLACK: where the SHAPE of a run comes from, once the anchors are given.
## Shared word for word with [[cable_builder]] and [[BigPipeSystem]], the other two
## builders in this tier: all three are handed a set of points and asked to make a run
## between them, and all three have to answer the same question — does the run admit
## that it has weight? One vocabulary, three different homes on it.
##
##   chord     the draughtsman's answer, denied. Straight members point to point, a
##             visible kink at every handle. Weight is not in the drawing at all.
##   spline    the draughtsman's answer, granted. A fair curve threaded through the
##             same points — smooth, kinkless, no downward bias. The curvature was
##             DRAWN, not derived; a lofting batten, not gravity.
##   catenary  the run hangs. Every span bows downward, deepest at mid-span, keyed to
##             the length of that span. Reads as a chain of shallow swags.
##   festoon   the run is given more length than the gap needs, so it hangs in deep
##             loops well below the handles. Slack admitted, and then some.
##   truss     the run refuses to hang and SHOWS what stops it — a bottom chord, a
##             post dropped from every handle, and a zigzag web between them. The
##             line becomes a girder; the physics is answered by structure.
##
## Legacy lineage is `chord`: this artifact has always drawn straight tube segments
## between raw point positions, so nothing above the SLACK section changes for it.
@export var slack: String = "chord"
const SLACKS: PackedStringArray = ["chord", "spline", "catenary", "festoon", "truss"]

## NOT an axis — a measurement fixture. _spawn_points() jitters every handle by
## randf_range, so two launches of this artifact are two different polylines. That is
## fine in a map and fatal on a test bench: a sweep across `slack` would be comparing
## five different random lines and would report a bite it had not earned. Any value
## >= 0 seeds the RNG instead, so every variant gets the SAME handles and the only
## thing that differs between frames is the axis. -1 keeps randomize(), untouched.
@export var handle_seed: int = -1

var points: Array[Node3D] = []
var mesh_instance: MeshInstance3D

func _ready() -> void:
	if handle_seed >= 0:
		seed(handle_seed)
	else:
		randomize()
	mesh_instance = $LineMesh
	_spawn_points()
	_update_line()

func _process(_delta):
	_update_line()

func _spawn_points() -> void:
	var parent = $Points
	points.clear()
	
	for i in range(point_count):
		var p = point_scene.instantiate()
		
		# Random jitter for organic layout
		var y = randf_range(-1.0, 1.0)
		var z = randf_range(-0.5, 0.5)
		
		p.position = Vector3(i * point_spacing, y, z)
		parent.add_child(p)
		points.append(p)

func _update_line() -> void:
	if points.size() < 2:
		return

	# SLACK — every non-default lineage is built in its own function at the bottom of
	# this file. "chord" falls straight through to the legacy body below, line for line.
	if slack != "chord":
		_update_line_slack()
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Create a new material instance for this line
	var mat := _create_line_material()
	st.set_material(mat)

	# Build a tube connecting all points
	for i in range(points.size() - 1):
		var p1 = to_local(points[i].global_position)
		var p2 = to_local(points[i + 1].global_position)
		var segment_dir = (p2 - p1).normalized()

		# Find perpendicular vectors for tube cross-section
		var up = Vector3.UP
		if abs(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right = segment_dir.cross(up).normalized()
		var forward = right.cross(segment_dir).normalized()

		var uv_x1 = float(i) / float(points.size() - 1)
		var uv_x2 = float(i + 1) / float(points.size() - 1)

		# Create tube segment
		for side in range(tube_sides):
			var angle1 = (float(side) / tube_sides) * TAU
			var angle2 = (float(side + 1) / tube_sides) * TAU

			var offset1 = (right * cos(angle1) + forward * sin(angle1)) * line_thickness
			var offset2 = (right * cos(angle2) + forward * sin(angle2)) * line_thickness

			# Create quad (2 triangles) for this tube segment face
			# Triangle 1
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / tube_sides))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)

			# Triangle 2
			st.set_uv(Vector2(uv_x1, float(side) / tube_sides))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / tube_sides))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / tube_sides))
			st.add_vertex(p1 + offset2)

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat

func _create_line_material() -> ShaderMaterial:
	# Make a *copy* of the exported ShaderMaterial, otherwise each update overwrites one shared resource
	var mat := line_material.duplicate() as ShaderMaterial

	# Same fixture as the handles: this function is called from _update_line() EVERY
	# FRAME and rolls a fresh glow_intensity each time, so the brightest pixels in the
	# frame — which are exactly the ones the bite critic measures — flicker across a
	# 1.5..2.0 range independently of the axis. handle_seed pins them. Default (-1)
	# leaves the legacy randf path below completely untouched.
	if handle_seed >= 0:
		mat.set_shader_parameter("time_offset", 0.0)
		mat.set_shader_parameter("flow_speed", 0.0)
		mat.set_shader_parameter("glow_intensity", 1.75)
		mat.set_shader_parameter("thickness_variation", 0.0)
		mat.set_shader_parameter("pulse_frequency", 0.0)
		return mat

	mat.set_shader_parameter("time_offset", randf_range(0.0, 10.0))
	mat.set_shader_parameter("flow_speed", 0.0)
	mat.set_shader_parameter("glow_intensity", randf_range(1.5, 2.0))
	mat.set_shader_parameter("thickness_variation", 0.0)
	mat.set_shader_parameter("pulse_frequency", 0.0)
	
	return mat

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	# LEGACY: this method has always taken a config and done nothing with it. It still
	# ignores every key but one — a `slack` token, so a map can pick the lineage with
	# `line_builder_3d:0:0#slack:festoon`. No rebuild is needed or done here: _process
	# re-runs _update_line() every frame anyway. An unknown word keeps the default.
	if config.has("slack"):
		var s: String = str(config["slack"]).strip_edges().to_lower()
		if SLACKS.has(s):
			slack = s


# ── SLACK ─────────────────────────────────────────────────────────────────────
# Appended LAST. Nothing above this line was touched except the one early-return in
# _update_line() and the handle_seed guard in _create_line_material(), both of which
# are inert at the defaults, so `chord` renders exactly the mesh it rendered before.


func _update_line_slack() -> void:
	var anchors := PackedVector3Array()
	for p in points:
		anchors.append(to_local(p.global_position))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := _create_line_material()
	st.set_material(mat)

	match slack:
		"spline":
			_emit_run(st, _fair_curve(anchors), line_thickness)
		"catenary":
			_emit_run(st, _swag(anchors, 0.45), line_thickness)
		"festoon":
			_emit_run(st, _swag(anchors, 1.15), line_thickness)
		"truss":
			_emit_run(st, anchors, line_thickness)
			_emit_truss(st, anchors)
		_:
			# unreachable at a valid value; keeps an unknown word looking like `chord`
			_emit_run(st, anchors, line_thickness)

	st.generate_normals()
	var mesh := st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = mat


## A fair curve THROUGH the same handles — Catmull-Rom tangents on a Curve3D, then
## resampled evenly. No downward bias: the smoothing is a drawing convention.
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
		var tangent: Vector3 = (nxt - prev) * 0.28
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


## Per-span downward bow, zero at each handle and deepest at mid-span, scaled by the
## length of that span. factor is the depth as a fraction of the span.
func _swag(a: PackedVector3Array, factor: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var steps: int = 10
	for i in range(a.size() - 1):
		var p1: Vector3 = a[i]
		var p2: Vector3 = a[i + 1]
		var span: float = p1.distance_to(p2)
		for k in range(steps + 1):
			if i > 0 and k == 0:
				continue
			var t: float = float(k) / float(steps)
			var p: Vector3 = p1.lerp(p2, t)
			p.y -= factor * span * 4.0 * t * (1.0 - t)
			out.append(p)
	return out


## The lattice that stops the run hanging: a straight bottom chord under the whole
## line, a post from every handle down to it, and a zigzag web between them.
func _emit_truss(st: SurfaceTool, a: PackedVector3Array) -> void:
	var n: int = a.size()
	if n < 2:
		return
	var drop := Vector3(0.0, 0.55, 0.0)
	var r: float = maxf(line_thickness * 0.75, 0.012)
	var foot_a: Vector3 = a[0] - drop
	var foot_b: Vector3 = a[n - 1] - drop
	_emit_run(st, _pair(foot_a, foot_b), r)
	for i in range(n):
		var t: float = float(i) / float(maxi(n - 1, 1))
		var foot: Vector3 = foot_a.lerp(foot_b, t)
		_emit_run(st, _pair(a[i], foot), r)
		if i < n - 1:
			var t2: float = float(i + 1) / float(maxi(n - 1, 1))
			var foot2: Vector3 = foot_a.lerp(foot_b, t2)
			if i % 2 == 0:
				_emit_run(st, _pair(a[i], foot2), r)
			else:
				_emit_run(st, _pair(foot, a[i + 1]), r)


func _pair(a: Vector3, b: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.append(a)
	out.append(b)
	return out


## The same swept-circle tube the legacy body builds, over an arbitrary path, into a
## SurfaceTool the caller owns — so one commit carries the run AND its structure.
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

		var up := Vector3.UP
		if absf(segment_dir.dot(up)) > 0.9:
			up = Vector3.RIGHT
		var right: Vector3 = segment_dir.cross(up).normalized()
		var forward: Vector3 = right.cross(segment_dir).normalized()

		var uv_x1: float = float(i) / float(last)
		var uv_x2: float = float(i + 1) / float(last)

		for side in range(tube_sides):
			var angle1: float = (float(side) / float(tube_sides)) * TAU
			var angle2: float = (float(side + 1) / float(tube_sides)) * TAU
			var offset1: Vector3 = (right * cos(angle1) + forward * sin(angle1)) * radius
			var offset2: Vector3 = (right * cos(angle2) + forward * sin(angle2)) * radius

			st.set_uv(Vector2(uv_x1, float(side) / float(tube_sides)))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side) / float(tube_sides)))
			st.add_vertex(p2 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / float(tube_sides)))
			st.add_vertex(p2 + offset2)

			st.set_uv(Vector2(uv_x1, float(side) / float(tube_sides)))
			st.add_vertex(p1 + offset1)
			st.set_uv(Vector2(uv_x2, float(side + 1) / float(tube_sides)))
			st.add_vertex(p2 + offset2)
			st.set_uv(Vector2(uv_x1, float(side + 1) / float(tube_sides)))
			st.add_vertex(p1 + offset2)
