extends Node3D

## ABSTRACT WORKS FOR THE WALL — 3D in 2D, and 2D in 3D.
##
## 2026-09-01, Palle: "Can we make a system for abstract art? I think 3d in 2d
## and 2d in 3d. On the wall works panel where there now is text I also want
## abstract works. For instance in a point line just two shades of gray dividing
## a canvas horizontally, another one diagonally. It can be one that is 2d in 3d
## frame. And also like a screen shot from a small camera set up where we let
## slightly fall on a cube closeup isometric? These could also include a way to
## show the black board principal on the wall works?"
##
## THE RECURSION IS THE SYSTEM, and it is worth naming before the code:
##
##   the FRAME is 3D          a real moulding with depth, casting a real shadow
##   the WORK is 2D           a flat face, no depth, the oldest lie in painting
##   and one work is 3D AGAIN inside its own 2D — `cube_isometric` is a live
##                            camera on a real cube, rendered flat onto the face
##
## So a visitor walking past sees a picture; walking closer sees that one of the
## pictures is a window; walking round sees that the window's cube is not in the
## room. That is the whole of "3d in 2d and 2d in 3d" as one object rather than
## as two, and the museum needs no new machinery to hang it.
##
## FOUR WORKS, ONE AXIS:
##
##   divide_horizontal   two greys, a hard horizontal edge
##   divide_diagonal     the same two greys, corner to corner
##   cube_isometric      a live orthographic camera on a lit cube — 3D in 2D
##   chalk               the blackboard principle: a dark board, worked on
##
## THE DIVISIONS ARE GEOMETRY, NOT A SHADER. Two triangles in an ArrayMesh, so
## the edge is exact at any size and there is nothing to reimport. This repo has
## already paid for the alternative: a stale compiled shader reads as INERT to
## the DNA critic and headless never reimports, so a shader here would be a
## picture that photographs correctly on one machine and blank on the bench.
##
## `chalk` deliberately does NOT reimplement the chalkboard. The corpus has eight
## of them already — point, line, triangle, quad, qfep, endlessness, thrownness —
## and the principle they carry is that a board is a surface you work ON, not a
## picture you finish. What this does is put that surface on the WALL, at the
## scale of a painting, so the room can hang a thing that is still being used
## next to things that are done.

@export_enum("divide_horizontal", "divide_vertical", "divide_diagonal", "divide_off_centre", "horizon_soft", "point_one", "two_points", "segment_drawn", "grid_regular", "trace_once", "corner_square", "cube_isometric", "cube_wire", "sphere_raking", "chalk") var work: String = "divide_horizontal"
@export var width_m: float = 0.86
@export var aspect: float = 0.74                ## height / width
@export var frame_depth_m: float = 0.055
@export var frame_face_m: float = 0.045
@export var frame_color: Color = Color(0.13, 0.13, 0.14)
## The two greys. Palle: "just two shades of gray dividing a canvas".
@export var tone_a: Color = Color(0.72, 0.72, 0.71)
@export var tone_b: Color = Color(0.31, 0.31, 0.33)
## cube_isometric: how far off-axis the light rakes. Palle: "let slightly fall".
@export var rake_degrees: float = 22.0

var _face: Node3D
var _viewport: SubViewport = null


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("work"):
		# THE WHITELIST IS DERIVED FROM THE EXPORT, NOT RETYPED.
		#
		# It was a hand-typed list of the original four, and after the axis grew to
		# fifteen the other eleven were silently REJECTED: `#work:grid_regular` in
		# a map token would fall back to divide_horizontal with no error anywhere.
		# That is this corpus's most expensive failure mode — science_screen
		# shipped a declaration naming four values its code did not have, swept
		# sixteen identical frames, and the critic reported a fact about a typo.
		# Reading the enum hint means the list cannot drift from the code again.
		var w: String = str(config_data["work"]).strip_edges().to_lower()
		var allowed: PackedStringArray = PackedStringArray()
		for prop in get_property_list():
			if prop.get("name") == "work":
				allowed = String(prop.get("hint_string", "")).split(",")
		if allowed.is_empty() or allowed.has(w):
			work = w
		else:
			push_warning("wall_abstract: unknown work '%s' — kept '%s'" % [w, work])
	if config_data.has("width_m"):
		width_m = float(config_data["width_m"])
	if config_data.has("aspect"):
		aspect = float(config_data["aspect"])
	if _face:
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_viewport = null
	var h: float = width_m * aspect

	_frame(h)
	_face = Node3D.new()
	_face.name = "Face"
	_face.position = Vector3(0, 0, frame_depth_m * 0.25)
	add_child(_face)

	match work:
		"divide_vertical":      _face.add_child(_divided(h, "vertical"))
		"divide_diagonal":      _face.add_child(_divided(h, "diagonal"))
		"divide_off_centre":    _face.add_child(_divided(h, "off_centre"))
		"horizon_soft":         _face.add_child(_gradient(h))
		"point_one":            _face.add_child(_marks(h, [[0.0, 0.0, 0.055, 0.055, 0.0]]))
		"two_points":           _face.add_child(_marks(h, [
									[-0.21, 0.0, 0.05, 0.05, 0.0],
									[0.21, 0.0, 0.05, 0.05, 0.0]]))
		"segment_drawn":        _face.add_child(_marks(h, [
									[-0.21, 0.0, 0.05, 0.05, 0.0],
									[0.21, 0.0, 0.05, 0.05, 0.0],
									[0.0, 0.0, 0.42, 0.008, 0.0]]))
		"grid_regular":         _face.add_child(_grid(h))
		"trace_once":           _face.add_child(_trace(h))
		"corner_square":        _face.add_child(_marks(h, [[-0.26, 0.19, 0.15, 0.15, 0.0]]))
		"cube_isometric":       _face.add_child(_window(h, "cube"))
		"cube_wire":            _face.add_child(_window(h, "wire"))
		"sphere_raking":        _face.add_child(_window(h, "sphere"))
		"chalk":                _face.add_child(_chalk(h))
		_:                      _face.add_child(_divided(h, "horizontal"))


## THE FRAME — the 3D half. Four mouldings with real depth, so the flat work
## inside is flat BY CONTRAST rather than by assertion.
func _frame(h: float) -> void:
	var ow: float = width_m + frame_face_m * 2.0
	var oh: float = h + frame_face_m * 2.0
	var bars := [
		[Vector3(ow, frame_face_m, frame_depth_m), Vector3(0, (h + frame_face_m) * 0.5, 0)],
		[Vector3(ow, frame_face_m, frame_depth_m), Vector3(0, -(h + frame_face_m) * 0.5, 0)],
		[Vector3(frame_face_m, oh, frame_depth_m), Vector3((width_m + frame_face_m) * 0.5, 0, 0)],
		[Vector3(frame_face_m, oh, frame_depth_m), Vector3(-(width_m + frame_face_m) * 0.5, 0, 0)],
	]
	for bar in bars:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = bar[0]
		m.mesh = bm
		m.position = bar[1]
		m.material_override = _flat(frame_color, 0.55)
		add_child(m)


## TWO TONES, ONE EDGE. Built as an ArrayMesh of two triangles so the division is
## exact geometry — the horizontal split shares a mid-edge, the diagonal shares
## the corner-to-corner one, and neither needs a texture or a shader.
func _divided(h: float, cut: String) -> MeshInstance3D:
	var hw: float = width_m * 0.5
	var hh: float = h * 0.5
	var tl := Vector3(-hw, hh, 0)
	var tr := Vector3(hw, hh, 0)
	var bl := Vector3(-hw, -hh, 0)
	var br := Vector3(hw, -hh, 0)
	var mesh := ArrayMesh.new()

	match cut:
		"diagonal":
			_surface(mesh, [bl, tr, tl], tone_a)
			_surface(mesh, [bl, br, tr], tone_b)
		"vertical":
			var tm := Vector3(0, hh, 0)
			var bm := Vector3(0, -hh, 0)
			_surface(mesh, [bl, bm, tm], tone_a)
			_surface(mesh, [bl, tm, tl], tone_a)
			_surface(mesh, [bm, br, tr], tone_b)
			_surface(mesh, [bm, tr, tm], tone_b)
		"off_centre":
			# THE SAME EDGE, NOT IN THE MIDDLE. Beside divide_horizontal this is
			# the whole argument: a division is not one decision but two, WHERE
			# and WHICH WAY, and the middle is a choice that looks like an
			# absence of one.
			var y: float = hh * 0.42
			var ml := Vector3(-hw, y, 0)
			var mr := Vector3(hw, y, 0)
			_surface(mesh, [ml, tr, tl], tone_a)
			_surface(mesh, [ml, mr, tr], tone_a)
			_surface(mesh, [bl, mr, ml], tone_b)
			_surface(mesh, [bl, br, mr], tone_b)
		_:
			var lm := Vector3(-hw, 0, 0)
			var rm := Vector3(hw, 0, 0)
			_surface(mesh, [lm, tr, tl], tone_a)
			_surface(mesh, [lm, rm, tr], tone_a)
			_surface(mesh, [bl, rm, lm], tone_b)
			_surface(mesh, [bl, br, rm], tone_b)

	var mi := MeshInstance3D.new()
	mi.name = "Divided"
	mi.mesh = mesh
	return mi


## THE SAME DIVISION WITHOUT THE DECISION.
##
## Vertex colours interpolated top to bottom, so the two tones are still both
## there and the edge between them is nowhere. Hung beside divide_horizontal it
## asks what the hard edge was actually for — the tones did not need it, only the
## claim that one thing ends and another begins did.
func _gradient(h: float) -> MeshInstance3D:
	var hw: float = width_m * 0.5
	var hh: float = h * 0.5
	var verts := PackedVector3Array([
		Vector3(-hw, hh, 0), Vector3(hw, hh, 0), Vector3(hw, -hh, 0),
		Vector3(-hw, hh, 0), Vector3(hw, -hh, 0), Vector3(-hw, -hh, 0)])
	var cols := PackedColorArray([tone_a, tone_a, tone_b, tone_a, tone_b, tone_b])
	var norms := PackedVector3Array()
	for i in 6:
		norms.append(Vector3.BACK)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_NORMAL] = norms
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _painted())
	var mi := MeshInstance3D.new()
	mi.name = "Gradient"
	mi.mesh = mesh
	return mi


## A PALE GROUND WITH MARKS ON IT — the point, the two points, the segment, the
## corner. Each entry is [x, y, w, h, degrees] in canvas fractions, so the same
## helper draws a dot, a pair, a joined pair and a square.
##
## point_one / two_points / segment_drawn are deliberately the SAME artifact in
## three states, because that is the corpus's own first argument: one point is a
## position, two are a relation, and keeping what lies between them is a further
## decision on top of that.
func _marks(h: float, items: Array) -> MeshInstance3D:
	var mi := _ground(h, tone_a)
	var k: float = width_m
	for it in items:
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(float(it[2]) * k, float(it[3]) * k)
		m.mesh = q
		m.position = Vector3(float(it[0]) * k, float(it[1]) * k, 0.003)
		m.rotation = Vector3(0, 0, deg_to_rad(float(it[4])))
		m.material_override = _ink()
		mi.add_child(m)
	return mi


## THE LINE MADE REGULAR, REPEATABLE AND INDIFFERENT TO YOU.
func _grid(h: float) -> MeshInstance3D:
	var mi := _ground(h, tone_a)
	var k: float = width_m
	var cols := 7
	var rows := 5
	for i in range(1, cols):
		var x: float = (float(i) / float(cols) - 0.5) * 0.92
		mi.add_child(_bar(Vector3(x * k, 0, 0.003), Vector2(0.006 * k, h * 0.92), 0.0))
	for j in range(1, rows):
		var y: float = (float(j) / float(rows) - 0.5) * 0.92
		mi.add_child(_bar(Vector3(0, y * h, 0.003), Vector2(width_m * 0.92, 0.006 * k), 0.0))
	return mi


## AND THE LINE MADE ONCE, BY A BODY, NEVER RECOVERABLE.
##
## The grid's opposite, and the two hang as a pair because they are the fork the
## whole chapter walks into: Point_Trace and Point_Line_Grid are the next two
## rooms. The path is fixed, not random — a trace that differed every build would
## be a generator, and a generator is a third thing that is neither.
func _trace(h: float) -> MeshInstance3D:
	var mi := _ground(h, tone_a)
	var pts := [
		Vector2(-0.40, -0.26), Vector2(-0.22, 0.05), Vector2(-0.05, -0.11),
		Vector2(0.09, 0.21), Vector2(0.26, 0.02), Vector2(0.41, 0.17)]
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i] * width_m
		var b: Vector2 = pts[i + 1] * width_m
		var mid := (a + b) * 0.5
		var d := b - a
		mi.add_child(_bar(Vector3(mid.x, mid.y, 0.003),
				Vector2(d.length(), 0.009 * width_m), rad_to_deg(d.angle())))
	return mi


func _ground(h: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	var q := QuadMesh.new()
	q.size = Vector2(width_m, h)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.94
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = m
	return mi


func _bar(at: Vector3, size: Vector2, deg: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	m.mesh = q
	m.position = at
	m.rotation = Vector3(0, 0, deg_to_rad(deg))
	m.material_override = _ink()
	return m


func _ink() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tone_b
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _painted() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.94
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _surface(mesh: ArrayMesh, tri: Array, col: Color) -> void:
	var verts := PackedVector3Array(tri)
	var cols := PackedColorArray([col, col, col])
	var norms := PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_NORMAL] = norms
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.94
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED   # a matt painted surface
	# CULLING OFF. The first sweep photographed both divisions as an EMPTY FRAME
	# and the critic reported them identical at 0.00% — correctly, because they
	# were: hand-wound triangles faced away from the camera and were culled, so
	# the canvas rendered nothing at all. A painted face has no back to hide, and
	# a picture that depends on my getting winding order right is a picture that
	# will vanish again the next time someone edits a vertex list.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(mesh.get_surface_count() - 1, m)


## 3D IN 2D — a real cube, a real light, an orthographic camera, rendered flat.
##
## Palle: "like a screen shot from a small camera set up where we let slightly
## fall on a cube closeup isometric." It is not a screenshot. It is a live
## SubViewport, so the cube in the picture is a cube in the world — just not in
## THIS room — and the light rakes across it at the angle the export names.
func _window(h: float, subject: String = "cube") -> MeshInstance3D:
	var vp := SubViewport.new()
	vp.size = Vector2i(512, int(512.0 * aspect))
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# ITS OWN WORLD, or the picture is in the room.
	#
	# A SubViewport SHARES its parent's World3D unless told otherwise, so the
	# first sweep put the cube and both its lights into the museum: the capture
	# framed on a 1 m cube floating in the hall and the frame was nowhere in
	# shot. The whole claim of this variant is that the cube exists somewhere
	# that is not here — sharing a world is that claim being false.
	vp.own_world_3d = true
	add_child(vp)
	_viewport = vp

	var world := Node3D.new()
	vp.add_child(world)

	_subject_into(world, subject)

	# ISOMETRIC: an orthographic camera on the true isometric axis. Perspective
	# would make it a photograph of a cube; orthographic makes it a DRAWING of
	# one, which is the register the rest of the wall is in.
	# ITS OWN WORLD HAS NO SKY AND NO AMBIENT, so it needs an environment or the
	# render is a flat field. This one is deliberately plain: a paper-dark ground
	# and a little ambient, so the cube reads by its own three faces rather than
	# by a horizon.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.07, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.56, 0.60)
	env.ambient_light_energy = 0.45

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 1.9
	cam.environment = env
	vp.add_child(cam)
	# AIM IT ONLY ONCE IT IS IN THE TREE. look_at_from_position on a node outside
	# the tree does not orient it — the first sweep produced a flat grey panel
	# because the camera never turned and was staring past the cube into an empty
	# world. Position, then parent, then aim.
	cam.position = Vector3(1, 1, 1) * 3.0
	cam.look_at(Vector3.ZERO, Vector3.UP)

	# "let slightly fall" — a raking key, low and off to one side, so two faces
	# read as different greys and the third falls away. A cube lit head-on is a
	# square.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-rake_degrees, -38.0, 0.0)
	key.light_energy = 1.5
	vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-64.0, 140.0, 0.0)
	fill.light_energy = 0.28
	vp.add_child(fill)

	var mi := MeshInstance3D.new()
	mi.name = "Window"
	var q := QuadMesh.new()
	q.size = Vector2(width_m, h)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_texture = vp.get_texture()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	return mi


## THE BLACKBOARD PRINCIPLE, HUNG. A dark matt board with chalk on it — the one
## surface in the museum that is not finished. It is not a copy of the chalkboard
## artifacts (there are eight) but the same claim at painting scale: a board is
## something you work ON, and hanging one among things that are done is the point.
func _chalk(h: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Chalk"
	var q := QuadMesh.new()
	q.size = Vector2(width_m, h)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.12, 0.11)
	m.roughness = 0.98
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mi.material_override = m

	# The marks: a few chalk strokes, thin unshaded quads laid just proud of the
	# board. Deliberately sparse and unfinished.
	var strokes := [
		[Vector3(-0.24, 0.12, 0.004), Vector2(0.30, 0.006), 0.0],
		[Vector3(-0.09, 0.02, 0.004), Vector2(0.20, 0.006), 34.0],
		[Vector3(0.16, -0.06, 0.004), Vector2(0.16, 0.006), -18.0],
		[Vector3(-0.20, -0.16, 0.004), Vector2(0.09, 0.006), 90.0],
	]
	for st in strokes:
		var s := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = (st[1] as Vector2) * (width_m / 0.86)
		s.mesh = sq
		s.position = (st[0] as Vector3) * (width_m / 0.86)
		s.rotation = Vector3(0, 0, deg_to_rad(float(st[2])))
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.88, 0.90, 0.87, 0.82)
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s.material_override = sm
		mi.add_child(s)
	return mi


func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


## WHAT STANDS IN THE LITTLE WORLD.
##
##   cube     a solid — the object, lit
##   wire     the same cube as twelve edges — the DRAWING of an object, so the
##            pair asks whether a cube is a solid we shade or a diagram we agreed
##            on. Beside the flat divisions it is the sharpest question on the
##            wall, because a wireframe is a 3D thing that is already only lines.
##   sphere   curvature instead of facets: the same raking light, but the tone
##            runs continuously, which is horizon_soft's argument in three
##            dimensions. Two greys with no edge, made by geometry rather than
##            by a gradient.
func _subject_into(world: Node3D, subject: String) -> void:
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.80, 0.79, 0.76)
	pale.roughness = 0.86

	match subject:
		"sphere":
			var sp := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.6
			sm.height = 1.2
			sm.radial_segments = 48
			sm.rings = 24
			sp.mesh = sm
			sp.material_override = pale
			world.add_child(sp)
		"wire":
			var edge_mat := StandardMaterial3D.new()
			edge_mat.albedo_color = Color(0.92, 0.92, 0.90)
			edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			var t: float = 0.022
			var e: float = 1.0
			# twelve edges of a unit cube, built as thin bars: four along each axis
			for ax in 3:
				for i in 4:
					var b := MeshInstance3D.new()
					var bm2 := BoxMesh.new()
					var off_a: float = (-0.5 if i < 2 else 0.5) * e
					var off_b: float = (-0.5 if i % 2 == 0 else 0.5) * e
					match ax:
						0:
							bm2.size = Vector3(e + t, t, t)
							b.position = Vector3(0, off_a, off_b)
						1:
							bm2.size = Vector3(t, e + t, t)
							b.position = Vector3(off_a, 0, off_b)
						_:
							bm2.size = Vector3(t, t, e + t)
							b.position = Vector3(off_a, off_b, 0)
					b.mesh = bm2
					b.material_override = edge_mat
					world.add_child(b)
		_:
			var cube := MeshInstance3D.new()
			var bm3 := BoxMesh.new()
			bm3.size = Vector3(1, 1, 1)
			cube.mesh = bm3
			cube.material_override = pale
			world.add_child(cube)
