extends RefCounted
## Shared helpers for the room line sketcher: build fat glowing tube lines from
## sketch segments, and load/save sketch JSON. Used by both the desktop tool
## (room_line_sketcher.gd) and the in-world renderer (room_sketch_render.gd).
##
## A "segment" is a Dictionary {a: Vector3, b: Vector3, face: int}.

static func make_line_material(color: Color, glow: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = glow
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.roughness = 0.4
	m.metallic = 0.0
	return m

## Build one low-poly cylinder ("tube") per segment under a fresh Node3D.
static func build_tubes(segments: Array, radius: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Tubes"
	for s in segments:
		var mi := _tube(s["a"], s["b"], radius, mat)
		if mi != null:
			root.add_child(mi)
	return root

static func _tube(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var length := (b - a).length()
	if length < 0.0001:
		return null
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 6
	cyl.rings = 1
	cyl.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.transform = _align_y(a, b)  # cylinder axis is +Y; align it with the segment
	return mi

static func _align_y(a: Vector3, b: Vector3) -> Transform3D:
	var mid := (a + b) * 0.5
	var y := (b - a).normalized()
	var ref := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), mid)

## Build ALL segments as one vertex-coloured tube mesh. color_fn(point)->Color
## is evaluated per endpoint, so lines can fade with depth (greyer further in).
static func build_tubes_gradient(segments: Array, radius: float, color_fn: Callable) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for s in segments:
		if _emit_tube(st, s["a"], s["b"], radius, color_fn):
			any = true
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not any:
		return mi
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi

static func _emit_tube(st: SurfaceTool, a: Vector3, b: Vector3, radius: float, color_fn: Callable) -> bool:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return false
	var y := dir / length
	var ref := Vector3.RIGHT if absf(y.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	var ca: Color = color_fn.call(a)
	var cb: Color = color_fn.call(b)
	var n := 6
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var o0 := (x * cos(a0) + z * sin(a0)) * radius
		var o1 := (x * cos(a1) + z * sin(a1)) * radius
		_v(st, a + o0, ca); _v(st, b + o0, cb); _v(st, b + o1, cb)
		_v(st, a + o0, ca); _v(st, b + o1, cb); _v(st, a + o1, ca)
	return true

static func _v(st: SurfaceTool, p: Vector3, c: Color) -> void:
	st.set_color(c)
	st.add_vertex(p)

## Filled quads on a plane. fill = {p: [Vector3 x4 in winding order], color: Color}
static func build_fills(fills: Array) -> Node3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	for f in fills:
		var p = f.get("p", [])
		if not (p is Array) or p.size() < 4:
			continue
		var col := _ac(f.get("color", [0.3, 0.7, 1.0, 0.5]))
		var p0 := _av3(p[0]); var p1 := _av3(p[1]); var p2 := _av3(p[2]); var p3 := _av3(p[3])
		_v(st, p0, col); _v(st, p1, col); _v(st, p2, col)
		_v(st, p0, col); _v(st, p2, col); _v(st, p3, col)
		any = true
	var mi := MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not any:
		return mi
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	return mi

## Primitive solids. prim = {type, pos, size, color, faces?}. `faces` is an Array
## of per-face Colors — 6 for a cube (+X,-X,+Y,-Y,+Z,-Z), each painted independently;
## non-cube solids take faces[0] (or `color`) over the whole surface.
static func build_prims(prims: Array) -> Node3D:
	var root := Node3D.new()
	for p in prims:
		var type := String(p.get("type", "cube"))
		var size := float(p.get("size", 0.8))
		var base := _ac(p.get("color", [0.6, 0.8, 1.0, 1.0]))
		var faces = p.get("faces", [])
		var mi := MeshInstance3D.new()
		mi.position = _av3(p.get("pos", Vector3.ZERO))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if type == "cube":
			var cols := []
			if faces is Array and faces.size() >= 6:
				for k in 6:
					cols.append(_ac(faces[k]))
			else:
				for k in 6:
					cols.append(base)
			mi.mesh = _cube_faces_mesh(size, cols)
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.vertex_color_use_as_albedo = true
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			mi.material_override = m
		else:
			var col := base
			if faces is Array and faces.size() >= 1:
				col = _ac(faces[0])
			mi.mesh = _prim_mesh(type, size)
			var m := StandardMaterial3D.new()
			m.albedo_color = col
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = 0.5
			m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			mi.material_override = m
		root.add_child(mi)
	return root

## A cube as 6 quads with per-face vertex colours. Face order matches the sketcher's
## ray-pick: 0=+X 1=-X 2=+Y 3=-Y 4=+Z 5=-Z. cull_disabled so winding is irrelevant.
static func _cube_faces_mesh(size: float, cols: Array) -> ArrayMesh:
	var h := size * 0.5
	var quads := [
		[Vector3(h, -h, -h), Vector3(h, h, -h), Vector3(h, h, h), Vector3(h, -h, h)],      # +X
		[Vector3(-h, -h, h), Vector3(-h, h, h), Vector3(-h, h, -h), Vector3(-h, -h, -h)],  # -X
		[Vector3(-h, h, -h), Vector3(-h, h, h), Vector3(h, h, h), Vector3(h, h, -h)],       # +Y
		[Vector3(-h, -h, h), Vector3(-h, -h, -h), Vector3(h, -h, -h), Vector3(h, -h, h)],   # -Y
		[Vector3(-h, -h, h), Vector3(h, -h, h), Vector3(h, h, h), Vector3(-h, h, h)],       # +Z
		[Vector3(h, -h, -h), Vector3(-h, -h, -h), Vector3(-h, h, -h), Vector3(h, h, -h)],   # -Z
	]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var col: Color = _ac(cols[i]) if i < cols.size() else Color.WHITE
		var q = quads[i]
		_v(st, q[0], col); _v(st, q[1], col); _v(st, q[2], col)
		_v(st, q[0], col); _v(st, q[2], col); _v(st, q[3], col)
	return st.commit()

static func _prim_mesh(type: String, size: float) -> Mesh:
	match type:
		"sphere":
			var s := SphereMesh.new(); s.radius = size * 0.5; s.height = size; return s
		"cylinder":
			var c := CylinderMesh.new(); c.top_radius = size * 0.4; c.bottom_radius = size * 0.4; c.height = size; return c
		"pyramid":
			var c := CylinderMesh.new(); c.top_radius = 0.0; c.bottom_radius = size * 0.62; c.height = size; c.radial_segments = 4; return c
		_:
			var b := BoxMesh.new(); b.size = Vector3(size, size, size); return b

static func _av3(x) -> Vector3:
	if x is Vector3:
		return x
	if x is Array and x.size() >= 3:
		return Vector3(x[0], x[1], x[2])
	return Vector3.ZERO

static func _ac(x) -> Color:
	if x is Color:
		return x
	if x is Array and x.size() >= 3:
		var a := 1.0
		if x.size() >= 4:
			a = float(x[3])
		return Color(float(x[0]), float(x[1]), float(x[2]), a)
	return Color.WHITE

static func _ca(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]

# ── JSON IO ───────────────────────────────────────────────────────────────────
static func to_dict(room: Vector3i, cell: float, segments: Array, fills: Array = [], prims: Array = []) -> Dictionary:
	var segs := []
	for s in segments:
		var a: Vector3 = s["a"]
		var b: Vector3 = s["b"]
		segs.append({"a": [a.x, a.y, a.z], "b": [b.x, b.y, b.z], "face": int(s.get("face", 0))})
	var fls := []
	for f in fills:
		var pa := []
		for pt in f["p"]:
			var v := _av3(pt)
			pa.append([v.x, v.y, v.z])
		fls.append({"p": pa, "color": _ca(_ac(f.get("color", Color.WHITE)))})
	var prs := []
	for pr in prims:
		var pos := _av3(pr.get("pos", Vector3.ZERO))
		var fcols := []
		for fc in pr.get("faces", []):
			fcols.append(_ca(_ac(fc)))
		prs.append({
			"type": String(pr.get("type", "cube")),
			"pos": [pos.x, pos.y, pos.z],
			"size": float(pr.get("size", 0.8)),
			"color": _ca(_ac(pr.get("color", Color.WHITE))),
			"faces": fcols,
		})
	return {"room": [room.x, room.y, room.z], "cell": cell, "segments": segs, "fills": fls, "prims": prs}

static func fills_from_dict(d: Dictionary) -> Array:
	var out := []
	for f in d.get("fills", []):
		var p = f.get("p", [])
		if not (p is Array) or p.size() < 4:
			continue
		out.append({"p": [_av3(p[0]), _av3(p[1]), _av3(p[2]), _av3(p[3])], "color": _ac(f.get("color", [0.3, 0.7, 1.0, 0.5]))})
	return out

static func prims_from_dict(d: Dictionary) -> Array:
	var out := []
	for pr in d.get("prims", []):
		var fcols := []
		for fc in pr.get("faces", []):
			fcols.append(_ac(fc))
		out.append({
			"type": String(pr.get("type", "cube")),
			"pos": _av3(pr.get("pos", [0, 0, 0])),
			"size": float(pr.get("size", 0.8)),
			"color": _ac(pr.get("color", [0.6, 0.8, 1.0, 1.0])),
			"faces": fcols,
		})
	return out

static func segments_from_dict(d: Dictionary) -> Array:
	var out := []
	for s in d.get("segments", []):
		var a = s.get("a", [0, 0, 0])
		var b = s.get("b", [0, 0, 0])
		if a is Array and b is Array and a.size() >= 3 and b.size() >= 3:
			out.append({
				"a": Vector3(a[0], a[1], a[2]),
				"b": Vector3(b[0], b[1], b[2]),
				"face": int(s.get("face", 0)),
			})
	return out

static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return {}
	var txt := fa.get_as_text()
	fa.close()
	var parsed = JSON.parse_string(txt)
	return parsed if parsed is Dictionary else {}

static func save_json(path: String, d: Dictionary) -> bool:
	var fa := FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		return false
	fa.store_string(JSON.stringify(d, "  "))
	fa.close()
	return true
