## A first remake of the Cyrtoidea plate (Haeckel, Kunstformen der Natur, Tafel 31)
## from the mesh grammar operations. Scratch sketch, 2026-10-01.
##
## Existing operations used: InsetFaceOp, DeleteFaceOp, ExtrudeFaceOp, TubeBranchOp,
## and the selectors by_callable, by_tag, by_random, by_index.
## Two things are written here and are NOT in the grammar:
##   lathe()        a seed made by turning a profile round an axis
##   cell_pores()   inset a CELL of six triangles toward the vertex they share,
##                  and leave the middle open: a hexagonal pore
extends SceneTree

const InsetFaceOp = preload("res://commons/mesh_grammar/operations/inset_face_op.gd")
const DeleteFaceOp = preload("res://commons/mesh_grammar/operations/delete_face_op.gd")
const ExtrudeFaceOp = preload("res://commons/mesh_grammar/operations/extrude_face_op.gd")
const TubeBranchOp = preload("res://commons/mesh_grammar/operations/tube_branch_op.gd")

var out_path := "user://radiolaria.png"
var bone: StandardMaterial3D
var env: Environment
var counts: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
	call_deferred("_run")


## The seed. profile: Vector2(radius, height), top to bottom. Radius 0 is a pole.
## Alternate rings are turned half a step, so the wall is a lattice of near-equal
## triangles, six round every vertex. Every third vertex is tagged "centre": the
## six triangles round a centre are one cell, and the cells cover the wall.
## `segments` must be a multiple of 3.
func lathe(profile: Array, segments: int) -> MeshData:
	var md := MeshData.new()
	var first: Array[int] = []
	var pole: Array[bool] = []
	var centres: Array[int] = []
	for i in range(profile.size()):
		var p: Vector2 = profile[i]
		first.append(md.vertices.size())
		if p.x <= 0.0001:
			pole.append(true)
			md.vertices.append(Vector3(0.0, p.y, 0.0))
		else:
			pole.append(false)
			var shift: float = 0.5 if i % 2 == 1 else 0.0
			for j in range(segments):
				var th: float = TAU * (float(j) + shift) / float(segments)
				if posmod(j - (i - (i & 1)) / 2 - i, 3) == 0:
					centres.append(md.vertices.size())
				md.vertices.append(Vector3(p.x * cos(th), p.y, p.x * sin(th)))
	for i in range(profile.size() - 1):
		for j in range(segments):
			var a: int = first[i] if pole[i] else first[i] + j
			var b: int = first[i] if pole[i] else first[i] + (j + 1) % segments
			var c: int = first[i + 1] if pole[i + 1] else first[i + 1] + j
			var d: int = first[i + 1] if pole[i + 1] else first[i + 1] + (j + 1) % segments
			if pole[i]:
				md.faces.append(PackedInt32Array([b, d, c]))
			elif pole[i + 1]:
				md.faces.append(PackedInt32Array([a, b, c]))
			elif i % 2 == 0:
				md.faces.append(PackedInt32Array([a, b, c]))
				md.faces.append(PackedInt32Array([b, d, c]))
			else:
				md.faces.append(PackedInt32Array([a, b, d]))
				md.faces.append(PackedInt32Array([a, d, c]))
	md._init_metadata()
	for v in centres:
		md.vertex_tags[v] = PackedStringArray(["centre"])
	return md


## A profile from a few control points, resampled to `rows` equal steps.
func profile_from(points: Array, rows: int) -> Array:
	var lengths: Array[float] = [0.0]
	for i in range(1, points.size()):
		lengths.append(lengths[i - 1] + (points[i] as Vector2).distance_to(points[i - 1]))
	var total: float = lengths[-1]
	var out: Array = []
	for r in range(rows + 1):
		var s: float = total * float(r) / float(rows)
		var k := 1
		while k < points.size() - 1 and lengths[k] < s:
			k += 1
		var t: float = inverse_lerp(lengths[k - 1], lengths[k], s)
		out.append((points[k - 1] as Vector2).lerp(points[k], clampf(t, 0.0, 1.0)))
	return out


func band(y_top: float, y_bottom: float) -> MeshSelector:
	return MeshSelector.by_callable(func(m: MeshData, i: int) -> bool:
		var y: float = m.get_face_centroid(i).y
		return y <= y_top and y > y_bottom and not m.face_has_tag(i, "bar"))


## Pores with the rules we have: inset every triangle of a band, delete the middle.
func triangle_pores(md: MeshData, y_top: float, y_bottom: float, amount: float) -> void:
	InsetFaceOp.new(band(y_top, y_bottom), {"amount": amount, "inner_tag": "pore", "border_tag": "bar"}).apply(md)
	DeleteFaceOp.new(MeshSelector.by_tag("pore"), {}).apply(md)


## The new rule. Every wall triangle has one "centre" vertex. Pull the other two
## toward it by `bar` (0..1, the width of the bar) and keep only the strip between:
## six strips round one centre leave a hexagonal pore. bar_top and bar_bottom let
## the pores grow down the body.
func cell_pores(md: MeshData, y_top: float, y_bottom: float, bar_top: float, bar_bottom: float) -> void:
	var gone := PackedInt32Array()
	var strips: Array = []
	var pulled: Dictionary = {}
	for fi in range(md.faces.size()):
		var f: PackedInt32Array = md.faces[fi]
		var y: float = md.get_face_centroid(fi).y
		if y > y_top or y <= y_bottom:
			continue
		var k := -1
		for n in range(3):
			if md.vertex_tags[f[n]].has("centre"):
				k = n
		if k < 0:
			continue
		var c: int = f[k]
		var p: int = f[(k + 1) % 3]
		var q: int = f[(k + 2) % 3]
		var bar: float = lerpf(bar_bottom, bar_top, inverse_lerp(y_bottom, y_top, y))
		var inner: Array[int] = []
		for v in [p, q]:
			var key := Vector2i(c, v)
			if not pulled.has(key):
				pulled[key] = md.add_vertex(md.vertices[v].lerp(md.vertices[c], bar))
			inner.append(pulled[key])
		gone.append(fi)
		strips.append(PackedInt32Array([p, q, inner[1]]))
		strips.append(PackedInt32Array([p, inner[1], inner[0]]))
	md.remove_faces(gone)
	for s in strips:
		md.add_face(s, PackedStringArray(["bar"]))


## `count` faces of the lip (the faces that look down), evenly round the axis.
func lip_faces(md: MeshData, count: int) -> MeshSelector:
	var best := PackedInt32Array()
	for k in range(count):
		var want: float = TAU * (float(k) + 0.25) / float(count)
		var pick := -1
		var near := 1e9
		for fi in range(md.faces.size()):
			if md.get_face_normal(fi).y > -0.5:
				continue
			var c: Vector3 = md.get_face_centroid(fi)
			var off: float = absf(angle_difference(atan2(c.z, c.x), want))
			if off < near:
				near = off
				pick = fi
		if pick >= 0 and not best.has(pick):
			best.append(pick)
	return MeshSelector.by_index(best)


func feet(md: MeshData, count: int, length: float, radius: float) -> void:
	TubeBranchOp.new(lip_faces(md, count), {"length": length, "start_radius": radius, "end_radius": 0.003,
		"segments": 6, "rings": 6, "curve_amount": 0.0}).apply(md)


func teeth(md: MeshData, count: int, length: float) -> void:
	ExtrudeFaceOp.new(lip_faces(md, count), {"distance": length, "scale": 0.05, "min_area": 0.000001}).apply(md)


func bristles(md: MeshData, share: float, length: float, seed_value: int) -> void:
	TubeBranchOp.new(MeshSelector.by_tag("bar").and_also(MeshSelector.by_random(share, seed_value)),
		{"length": length, "start_radius": 0.007, "end_radius": 0.001, "segments": 3, "rings": 1, "curve_amount": 0.0}).apply(md)


## MeshData winds its faces counter-clockwise seen from outside; Godot draws the
## clockwise side. Emit each face turned over, with the outward normal.
func to_mesh(md: MeshData) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for fi in range(md.faces.size()):
		var f: PackedInt32Array = md.faces[fi]
		var n: Vector3 = md.get_face_normal(fi)
		for k in [0, 2, 1]:
			st.set_normal(n)
			st.add_vertex(md.vertices[f[k]])
	return st.commit()


func place(md: MeshData, at: Vector3, label: String) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = to_mesh(md)
	mi.material_override = bone
	mi.position = at
	mi.rotation_degrees = Vector3(16.0, 20.0, 0.0)
	root.add_child(mi)
	caption(label, at)
	counts.append("%s: %d faces, %d vertices" % [label, md.face_count(), md.vertex_count()])


func caption(text: String, at: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 30
	l.pixel_size = 0.0035
	l.modulate = Color(0.8, 0.8, 0.8)
	l.shaded = false
	l.position = at + Vector3(0.0, -1.22, 0.0)
	root.add_child(l)


func place_profile(points: Array, at: Vector3, label: String) -> void:
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.95, 0.93, 0.88)
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
	for p in points:
		im.surface_add_vertex(Vector3((p as Vector2).x, (p as Vector2).y, 0.0))
	im.surface_end()
	var axis := StandardMaterial3D.new()
	axis.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	axis.albedo_color = Color(0.4, 0.4, 0.4)
	im.surface_begin(Mesh.PRIMITIVE_LINES, axis)
	im.surface_add_vertex(Vector3(0.0, 1.0, 0.0))
	im.surface_add_vertex(Vector3(0.0, -0.95, 0.0))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.position = at
	root.add_child(mi)
	caption(label, at)


# ---- the bodies ---------------------------------------------------------------

## Helmet: horn, head, chest, and a lip that looks down and a little outward.
func helmet_points() -> Array:
	return [Vector2(0.0, 0.97), Vector2(0.025, 0.64), Vector2(0.10, 0.57), Vector2(0.13, 0.47),
		Vector2(0.09, 0.39), Vector2(0.26, 0.21), Vector2(0.44, -0.10), Vector2(0.52, -0.40),
		Vector2(0.50, -0.50), Vector2(0.40, -0.58)]


## step 2 the turned profile, 3 pores by triangle, 4 pores by cell, 5 feet, 6 bristles
func helmet(step: int) -> MeshData:
	var md: MeshData = lathe(profile_from(helmet_points(), 30), 36)
	if step == 3:
		triangle_pores(md, 0.60, -0.48, 0.36)
	if step >= 4:
		cell_pores(md, 0.60, -0.48, 0.52, 0.24)
	if step >= 5:
		feet(md, 3, 0.62, 0.05)
	if step >= 6:
		bristles(md, 0.035, 0.30, 7)
	return md


func ovoid() -> MeshData:
	var pts: Array = []
	for k in range(13):
		var t: float = float(k) / 12.0
		pts.append(Vector2(0.50 * sin(PI * t) * (1.0 - 0.18 * t), 0.8 * cos(PI * t)))
	pts[12] = Vector2(0.10, -0.80)
	pts.append(Vector2(0.10, -0.92))
	var md: MeshData = lathe(profile_from(pts, 26), 30)
	cell_pores(md, 0.70, -0.72, 0.34, 0.34)
	return md


func fringed_dome() -> MeshData:
	var pts: Array = [Vector2(0.0, 0.84), Vector2(0.02, 0.62), Vector2(0.10, 0.54), Vector2(0.10, 0.42),
		Vector2(0.30, 0.32), Vector2(0.50, 0.08), Vector2(0.52, -0.16), Vector2(0.44, -0.26), Vector2(0.34, -0.30)]
	var md: MeshData = lathe(profile_from(pts, 22), 36)
	cell_pores(md, 0.40, -0.14, 0.45, 0.30)
	teeth(md, 18, 0.34)
	return md


func flask() -> MeshData:
	var pts: Array = [Vector2(0.0, 0.97), Vector2(0.02, 0.80), Vector2(0.08, 0.76), Vector2(0.10, 0.68), Vector2(0.07, 0.62),
		Vector2(0.15, 0.52), Vector2(0.12, 0.44), Vector2(0.21, 0.32), Vector2(0.17, 0.22), Vector2(0.28, 0.08), Vector2(0.24, -0.02),
		Vector2(0.46, -0.22), Vector2(0.54, -0.48), Vector2(0.44, -0.74), Vector2(0.22, -0.88), Vector2(0.0, -0.90)]
	var md: MeshData = lathe(profile_from(pts, 44), 42)
	cell_pores(md, 0.74, -0.86, 0.55, 0.28)
	return md


func great_dome() -> MeshData:
	var pts: Array = [Vector2(0.0, 1.0), Vector2(0.025, 0.70), Vector2(0.09, 0.64), Vector2(0.12, 0.54), Vector2(0.10, 0.46),
		Vector2(0.34, 0.30), Vector2(0.56, 0.02), Vector2(0.66, -0.28), Vector2(0.62, -0.40), Vector2(0.52, -0.46)]
	var md: MeshData = lathe(profile_from(pts, 20), 24)
	cell_pores(md, 0.66, -0.38, 0.60, 0.12)
	teeth(md, 12, 0.30)
	bristles(md, 0.06, 0.55, 3)
	return md


func tripod() -> MeshData:
	var pts: Array = [Vector2(0.0, 1.0), Vector2(0.02, 0.68), Vector2(0.09, 0.62), Vector2(0.11, 0.52), Vector2(0.08, 0.46),
		Vector2(0.22, 0.36), Vector2(0.31, 0.18), Vector2(0.30, 0.06), Vector2(0.22, -0.02)]
	var md: MeshData = lathe(profile_from(pts, 20), 30)
	cell_pores(md, 0.50, 0.08, 0.45, 0.30)
	feet(md, 3, 0.95, 0.045)
	bristles(md, 0.05, 0.22, 11)
	return md


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(2280, 1320))
	bone = StandardMaterial3D.new()
	bone.albedo_color = Color(0.95, 0.93, 0.88)
	bone.roughness = 1.0
	bone.cull_mode = BaseMaterial3D.CULL_DISABLED

	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 1.0, 1.0)
	env.ambient_light_energy = 0.16
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-36.0, 38.0, 0.0)
	sun.light_energy = 1.3
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.environment = env
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 5.4
	cam.position = Vector3(0.0, 0.0, 10.0)
	root.add_child(cam)
	cam.current = true

	var dx := 1.52
	var x0 := -dx * 2.5
	var top := 1.36
	var bottom := -1.34
	place_profile(profile_from(helmet_points(), 30), Vector3(x0, top, 0.0), "1  a profile")
	place(helmet(2), Vector3(x0 + dx, top, 0.0), "2  turned round its axis")
	place(helmet(3), Vector3(x0 + dx * 2.0, top, 0.0), "3  inset, delete: every triangle")
	place(helmet(4), Vector3(x0 + dx * 3.0, top, 0.0), "4  inset, delete: cells of six")
	place(helmet(5), Vector3(x0 + dx * 4.0, top, 0.0), "5  branch three lip faces")
	place(helmet(6), Vector3(x0 + dx * 5.0, top, 0.0), "6  branch a few bars, thin")
	place(ovoid(), Vector3(x0, bottom, 0.0), "ovoid")
	place(fringed_dome(), Vector3(x0 + dx, bottom, 0.0), "fringed dome")
	place(flask(), Vector3(x0 + dx * 2.0, bottom, 0.0), "flask of five joints")
	place(tripod(), Vector3(x0 + dx * 3.0, bottom, 0.0), "tripod")
	place(great_dome(), Vector3(x0 + dx * 4.0, bottom, 0.0), "great dome")
	place(helmet(6), Vector3(x0 + dx * 5.0, bottom, 0.0), "helmet")

	for i in range(8):
		await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(out_path)
	for c in counts:
		print("RADIOLARIA ", c)
	print("RADIOLARIA saved ", out_path, " ", img.get_size())
	quit(0)
