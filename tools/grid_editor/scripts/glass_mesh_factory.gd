class_name GlassMeshFactory
## Static factory for glass segment meshes used by the grid editor.
## Extracted from editor_main.gd to share between the interactive editor
## and the headless capture scene.

# ── Main entry point ─────────────────────────────────────────

static func create_glass_segment(element: Dictionary, grid_size: float, tube_radius: float = 0.015) -> Node3D:
	var segment_type = element.get("segment_type", "")
	var elem_size = element.get("size", [1, 1])
	var width = elem_size[0] * grid_size
	var height = elem_size[1] * grid_size

	var glass_mat = StandardMaterial3D.new()
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.4)
	glass_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var node: Node3D = null

	match segment_type:
		"straight":
			node = Node3D.new()
			var mi = MeshInstance3D.new()
			mi.mesh = generate_tube_mesh(height, tube_radius, 16, 2, width / 2.0, 0.0)
			mi.material_override = glass_mat
			node.add_child(mi)
		"straight_h":
			node = Node3D.new()
			var mi_h = MeshInstance3D.new()
			mi_h.mesh = generate_tube_mesh_horizontal(width, tube_radius, 16, 2, height / 2.0, 0.0)
			mi_h.material_override = glass_mat
			node.add_child(mi_h)
		"corner", "corner_bl":
			node = create_elbow_directed(width, height, tube_radius, glass_mat, 180)
		"corner_br":
			node = create_elbow_directed(width, height, tube_radius, glass_mat, 270)
		"corner_tr":
			node = create_elbow_directed(width, height, tube_radius, glass_mat, 0)
		"corner_tl":
			node = create_elbow_directed(width, height, tube_radius, glass_mat, 90)
		"corner45":
			node = create_corner45(width, height, tube_radius, glass_mat)
		"wobbly":
			node = create_wobbly(width, height, tube_radius, glass_mat, -grid_size * 0.5)
		"reducer":
			node = create_reducer(width, height, tube_radius, glass_mat)
		"sbend":
			node = create_sbend(width, height, tube_radius, glass_mat)
		"ubend":
			node = create_ubend(width, height, tube_radius, glass_mat, -grid_size * 0.5)
		"ypipe":
			node = create_ypipe(width, height, tube_radius, glass_mat)
		"junction":
			node = create_tee(width, height, tube_radius, glass_mat)
		"cross":
			node = create_cross(width, height, tube_radius, glass_mat)
		"spiral":
			node = create_spiral(width, height, tube_radius, glass_mat)
		"condenser":
			node = create_condenser(width, height, tube_radius, glass_mat)
		"flask":
			node = create_flask(width, height, tube_radius, glass_mat)
		"beaker":
			node = create_beaker(width, height, glass_mat)
		"cap":
			node = create_cap(width, height, tube_radius, glass_mat)
		"drip":
			node = create_drip(width, height, tube_radius, glass_mat)
		_:
			node = create_tube(height, tube_radius, glass_mat)
			node.position.x = width / 2

	if node: node.name = element.get("id", "segment")
	return node


static func create_placeholder(element: Dictionary, grid_size: float) -> Node3D:
	var node = Node3D.new(); node.name = element.get("id", "element")
	var sz = _safe_size(element); var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new(); mesh.size = Vector3(sz[0] * grid_size * 0.8, sz[1] * grid_size * 0.8, 0.01)
	mi.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.5, 0.6); mat.emission_enabled = true; mat.emission = Color(0.2, 0.3, 0.4)
	mi.material_override = mat; mi.position = Vector3(sz[0] * grid_size * 0.5, sz[1] * grid_size * 0.5, 0)
	node.add_child(mi)
	var label = Label3D.new(); label.text = element.get("icon", "?")
	label.position = Vector3(sz[0] * grid_size * 0.5, sz[1] * grid_size * 0.5, 0.01)
	label.pixel_size = 0.005; label.font_size = 32; label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.add_child(label)
	return node


static func _safe_size(element: Dictionary) -> Array:
	var s = element.get("size", [1, 1])
	return s if s is Array and s.size() >= 2 else [1, 1]


# ── Creation wrappers ────────────────────────────────────────

static func create_tube(length: float, radius: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var mi = MeshInstance3D.new()
	mi.mesh = generate_tube_mesh(length, radius, 16, 2)
	mi.material_override = mat
	node.add_child(mi)
	return node

static func create_elbow_directed(width: float, height: float, radius: float, mat: Material, direction: int) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var arc_r = min(width, height) / 2.0
	var cy: float; var cz: float
	match direction:
		0:   cy = 0.0;    cz = width
		90:  cy = 0.0;    cz = 0.0
		180: cy = height; cz = 0.0
		_:   cy = height; cz = width
	mi.mesh = generate_directed_elbow_yz(arc_r, radius, cy, cz, direction, 16, 16)
	mi.material_override = mat; node.add_child(mi); return node

static func create_sbend(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = generate_sbend_mesh_yz(h, w, r, 16, 24); mi.material_override = mat
	node.add_child(mi); return node

static func create_ubend(w: float, h: float, r: float, mat: Material, y_offset: float = 0.0) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = generate_ubend_mesh_yz(w, h, r, 16, 20, y_offset); mi.material_override = mat
	node.add_child(mi); return node

static func create_tee(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var cz = w / 2; var cy = h / 2
	var vert = create_tube(h, r, mat); vert.position.z = cz; node.add_child(vert)
	var horiz = MeshInstance3D.new(); horiz.mesh = generate_tube_mesh(w / 2, r, 16, 2)
	horiz.material_override = mat; horiz.rotation.x = PI / 2; horiz.position = Vector3(0, cy, cz); node.add_child(horiz)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 1.5; sm.height = r * 3
	sp.mesh = sm; sp.material_override = mat; sp.position = Vector3(0, cy, cz); node.add_child(sp)
	return node

static func create_ypipe(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var cz = w / 2; var jy = h * 0.35
	var stem = create_tube(jy, r, mat); stem.position.z = cz; node.add_child(stem)
	for side in [-1, 1]:
		var br = MeshInstance3D.new(); br.mesh = generate_tube_mesh(h * 0.55, r, 16, 2)
		br.material_override = mat; br.position = Vector3(0, jy, cz); br.rotation.x = side * PI / 5; node.add_child(br)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 2; sm.height = r * 4
	sp.mesh = sm; sp.material_override = mat; sp.position = Vector3(0, jy, cz); node.add_child(sp)
	return node

static func create_cross(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var c = Vector3(0, h / 2, w / 2)
	var vert = create_tube(h, r, mat); vert.position.z = c.z; node.add_child(vert)
	var horiz = MeshInstance3D.new(); horiz.mesh = generate_tube_mesh(w, r, 16, 2)
	horiz.material_override = mat; horiz.rotation.x = PI / 2; horiz.position = c; node.add_child(horiz)
	var sp = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = r * 1.8; sm.height = r * 3.6
	sp.mesh = sm; sp.material_override = mat; sp.position = c; node.add_child(sp)
	return node

static func create_spiral(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = generate_spiral_mesh(h, w * 0.35, r, 4, 12, 48)
	mi.material_override = mat; mi.position.z = w / 2; node.add_child(mi); return node

static func create_condenser(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var inner = create_tube(h, r, mat); inner.position.z = w / 2; node.add_child(inner)
	var jacket = create_tube(h * 0.7, r * 2.5, mat); jacket.position = Vector3(0, h * 0.15, w / 2); node.add_child(jacket)
	return node

static func create_flask(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new()
	var bulb = MeshInstance3D.new(); var sm = SphereMesh.new(); sm.radius = w * 0.4; sm.height = w * 0.8
	bulb.mesh = sm; bulb.material_override = mat; bulb.position = Vector3(0, w * 0.4, w / 2); node.add_child(bulb)
	var neck = create_tube(h - w * 0.7, r, mat)
	neck.position = Vector3(0, w * 0.7, w / 2); node.add_child(neck); return node

static func create_beaker(w: float, h: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = w * 0.4; cyl.bottom_radius = w * 0.35; cyl.height = h * 0.9
	mi.mesh = cyl; mi.material_override = mat; mi.position = Vector3(0, h * 0.45, w / 2)
	node.add_child(mi); return node

static func create_cap(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var sp = SphereMesh.new(); sp.radius = min(w, h) * 0.4; sp.height = sp.radius * 2.0; sp.is_hemisphere = true
	mi.mesh = sp; mi.material_override = mat; mi.rotation.x = PI; mi.position = Vector3(0, h * 0.5, w / 2.0)
	node.add_child(mi); return node

static func create_drip(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cone = CylinderMesh.new(); cone.top_radius = r; cone.bottom_radius = r * 0.3; cone.height = h * 0.8
	mi.mesh = cone; mi.material_override = mat; mi.position = Vector3(0, h * 0.5, w / 2.0)
	node.add_child(mi); return node

static func create_corner45(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var ar = min(w, h) / 2.0
	mi.mesh = generate_corner45_mesh_yz(ar, r, h / 2.0, w / 2.0, 16, 12)
	mi.material_override = mat; node.add_child(mi); return node

static func create_wobbly(w: float, h: float, r: float, mat: Material, y_offset: float = 0.0) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	var cz = w / 2.0; var amp = max(r * 1.5, w * 0.2); var wc = max(2.0, h / max(w * 0.4, 0.001))
	mi.mesh = generate_wobbly_mesh_yz(h, cz, amp, wc, r, 16, 32, y_offset)
	mi.material_override = mat; node.add_child(mi); return node

static func create_reducer(w: float, h: float, r: float, mat: Material) -> Node3D:
	var node = Node3D.new(); var mi = MeshInstance3D.new()
	mi.mesh = generate_reducer_mesh_yz(h, w / 2.0, r, r * 0.6, 16, 8)
	mi.material_override = mat; node.add_child(mi); return node


# ── Mesh generators ──────────────────────────────────────────

static func generate_tube_mesh(length: float, radius: float, segments: int, rings: int, center_z: float = 0.0, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var y = y_offset + (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			st.set_normal(Vector3(cos(angle), 0, sin(angle)))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(cos(angle) * radius, y, center_z + sin(angle) * radius))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s; var next = curr + segments + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents(); return st.commit()

static func generate_tube_mesh_horizontal(length: float, radius: float, segments: int, rings: int, center_y: float = 0.0, z_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rings + 1):
		var z = z_offset + (float(r) / rings) * length
		for s in range(segments + 1):
			var angle = (float(s) / segments) * TAU
			st.set_normal(Vector3(cos(angle), sin(angle), 0))
			st.set_uv(Vector2(float(s) / segments, float(r) / rings))
			st.add_vertex(Vector3(cos(angle) * radius, center_y + sin(angle) * radius, z))
	for r in range(rings):
		for s in range(segments):
			var curr = r * (segments + 1) + s; var next = curr + segments + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents(); return st.commit()

static func generate_directed_elbow_yz(arc_radius: float, tube_radius: float, center_y: float, center_z: float, direction: int, tube_segs: int, bend_segs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start_angle: float; var end_angle: float
	match direction:
		0:   start_angle = PI;  end_angle = PI / 2.0
		90:  start_angle = 0.0; end_angle = PI / 2.0
		180: start_angle = 0.0; end_angle = -PI / 2.0
		_:   start_angle = PI;  end_angle = 3.0 * PI / 2.0
	var prev_normal := Vector3.ZERO
	for b in range(bend_segs + 1):
		var t = float(b) / bend_segs
		var angle = lerpf(start_angle, end_angle, t)
		var center = Vector3(0, center_y + arc_radius * sin(angle), center_z + arc_radius * cos(angle))
		var d_angle = end_angle - start_angle
		var tangent = Vector3(0, arc_radius * cos(angle) * d_angle, -arc_radius * sin(angle) * d_angle).normalized()
		var normal: Vector3; var binormal: Vector3
		if prev_normal == Vector3.ZERO:
			normal = tangent.cross(Vector3.RIGHT)
			if normal.length_squared() < 0.001: normal = tangent.cross(Vector3.UP)
			normal = normal.normalized()
		else:
			normal = prev_normal - tangent * tangent.dot(prev_normal)
			if normal.length_squared() < 0.001: normal = prev_normal
			else: normal = normal.normalized()
		binormal = tangent.cross(normal).normalized(); prev_normal = normal
		for s in range(tube_segs + 1):
			var ra = (float(s) / tube_segs) * TAU
			var offset = (normal * cos(ra) + binormal * sin(ra)) * tube_radius
			st.set_normal(offset.normalized()); st.set_uv(Vector2(float(s) / tube_segs, t))
			st.add_vertex(center + offset)
	for b in range(bend_segs):
		for s in range(tube_segs):
			var curr = b * (tube_segs + 1) + s; var next = curr + tube_segs + 1
			st.add_index(curr); st.add_index(next); st.add_index(curr + 1)
			st.add_index(curr + 1); st.add_index(next); st.add_index(next + 1)
	st.generate_tangents(); return st.commit()

static func generate_sbend_mesh_yz(height: float, width: float, tr: float, ts: int, ls: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(ls + 1):
		var t = float(l) / ls; var y = t * height; var z = width * (0.5 - 0.5 * cos(PI * t))
		var dy = height / ls; var dz = width * 0.5 * PI * sin(PI * t) / ls
		var tang = Vector3(0, dy, dz).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var ro = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(ro.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + ro)
	for l in range(ls):
		for s in range(ts):
			var c = l * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

static func generate_ubend_mesh_yz(width: float, height: float, tr: float, ts: int, bs: int, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cz = width / 2.0; var ar = cz - tr; var yt = height; var yb = tr; var ys = yt - yb
	for b in range(bs + 1):
		var t = float(b) / bs; var a = PI * t; var z = cz - ar * cos(a); var y = y_offset + yt - ys * sin(a)
		var tang = Vector3(0, -ys * cos(a), ar * sin(a)).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + off)
	for b in range(bs):
		for s in range(ts):
			var c = b * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

static func generate_spiral_mesh(h: float, cr: float, tr: float, turns: int, ts: int, cs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for c in range(cs + 1):
		var t = float(c) / cs; var ca = t * turns * TAU; var y = t * h
		var center = Vector3(cr * cos(ca), y, cr * sin(ca))
		var dx = -cr * sin(ca) * turns * TAU / cs; var dy = h / cs; var dz = cr * cos(ca) * turns * TAU / cs
		var tang = Vector3(dx, dy, dz).normalized()
		var bn = tang.cross(Vector3.UP).normalized(); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(center + off)
	for c2 in range(cs):
		for s in range(ts):
			var cu = c2 * (ts + 1) + s; var nx = cu + ts + 1
			st.add_index(cu); st.add_index(nx); st.add_index(cu + 1)
			st.add_index(cu + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

static func generate_corner45_mesh_yz(ar: float, tr: float, cy: float, cz: float, ts: int, bs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sa = -PI / 2.0; var ea = -PI / 4.0; var pn := Vector3.ZERO
	for b in range(bs + 1):
		var t = float(b) / bs; var a = lerpf(sa, ea, t)
		var center = Vector3(0, cy + ar * sin(a), cz + ar * cos(a))
		var da = ea - sa; var tang = Vector3(0, ar * cos(a) * da, -ar * sin(a) * da).normalized()
		var n: Vector3; var bn: Vector3
		if pn == Vector3.ZERO:
			n = tang.cross(Vector3.RIGHT); if n.length_squared() < 0.001: n = tang.cross(Vector3.UP)
			n = n.normalized()
		else: n = pn - tang * tang.dot(pn); n = pn if n.length_squared() < 0.001 else n.normalized()
		bn = tang.cross(n).normalized(); pn = n
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var off = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(off.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(center + off)
	for b2 in range(bs):
		for s in range(ts):
			var c = b2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

static func generate_wobbly_mesh_yz(h: float, cz: float, amp: float, wc: float, tr: float, ts: int, ls: int, y_offset: float = 0.0) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for l in range(ls + 1):
		var t = float(l) / ls; var y = y_offset + t * h; var z = cz + sin(t * TAU * wc) * amp
		var dy = h / ls; var dz = cos(t * TAU * wc) * amp * TAU * wc / ls
		var tang = Vector3(0, dy, dz).normalized(); var bn = Vector3(1, 0, 0); var n = bn.cross(tang).normalized()
		for s in range(ts + 1):
			var ra = (float(s) / ts) * TAU; var ro = (n * cos(ra) + bn * sin(ra)) * tr
			st.set_normal(ro.normalized()); st.set_uv(Vector2(float(s) / ts, t)); st.add_vertex(Vector3(0, y, z) + ro)
	for l2 in range(ls):
		for s in range(ts):
			var c = l2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()

static func generate_reducer_mesh_yz(h: float, cz: float, br: float, tr: float, ts: int, rs: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(rs + 1):
		var t = float(r) / rs; var y = t * h; var cr = lerpf(br, tr, t)
		for s in range(ts + 1):
			var th = (float(s) / ts) * TAU
			st.set_normal(Vector3(cos(th), 0, sin(th))); st.set_uv(Vector2(float(s) / ts, t))
			st.add_vertex(Vector3(cr * cos(th), y, cz + cr * sin(th)))
	for r2 in range(rs):
		for s in range(ts):
			var c = r2 * (ts + 1) + s; var nx = c + ts + 1
			st.add_index(c); st.add_index(nx); st.add_index(c + 1)
			st.add_index(c + 1); st.add_index(nx); st.add_index(nx + 1)
	st.generate_tangents(); return st.commit()
