## Picture-perfect capture for the /parametric-platonic-gallery DNA gallery.
##
## The family of the five Platonic solids: tetrahedron, cube, octahedron,
## dodecahedron, icosahedron. The pedagogical claim is the family itself —
## there are exactly five regular convex polyhedra in 3D space, and we render
## all five side-by-side at the same circumscribed-sphere radius so size
## doesn't bias the eye.
##
## Visual goals (mirrors capture_parametric_mesh_gallery.gd):
##   - Square 1024×1024 SubViewport with MSAA 8x + FXAA for crisp edges
##   - Three-quarter view from above (yaw=28°, pitch=35°, fov=38°)
##   - Each solid gets a SOLID-color body material (no shader-noise diagonals)
##     plus an overlay wireframe ImmediateMesh drawing only the true polyhedron
##     edges (one line per edge, not per triangle) — vertex/edge counts are
##     literally countable at thumbnail scale
##   - Distinct saturated body colors per solid + bright white wireframe lines
##   - Three-light rig (key + fill + rim) on isolated World3D
##
## Inline geometry: vertices are normalized so each solid's circumscribed
## sphere has radius 0.5m. Same volume envelope across all five.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_platonic_gallery.gd \
##     -- --out=user://parametric_platonic_gallery
##
## Output: <out>/{tetrahedron,cube,octahedron,dodecahedron,icosahedron}.png
##         + matching .json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const WIRE_COLOR: Color = Color(1.0, 1.0, 1.0)
const TARGET_RADIUS: float = 0.5  # Circumscribed-sphere radius for every solid.
const PHI: float = 1.618033988749895

# Saturated palette — distinct hues so each cell reads at a glance.
const COLOR_TETRA: Color = Color(0.98, 0.58, 0.20)   # orange
const COLOR_CUBE: Color = Color(0.95, 0.30, 0.34)    # red
const COLOR_OCTA: Color = Color(0.65, 0.38, 0.95)    # violet
const COLOR_DODECA: Color = Color(0.42, 0.82, 0.45)  # green
const COLOR_ICOSA: Color = Color(0.36, 0.62, 1.0)    # blue

var _output_dir: String = "user://parametric_platonic_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── SubViewport — 1024×1024 square with MSAA 8x ────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.80)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	# ── Lighting: key + fill + rim ──────────────────────────────────
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, 35, 0)
	key_light.light_energy = 1.6
	key_light.light_color = Color(1.0, 0.96, 0.88)
	key_light.shadow_enabled = false
	_viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, -110, 0)
	fill_light.light_energy = 0.55
	fill_light.light_color = Color(0.72, 0.82, 1.0)
	fill_light.shadow_enabled = false
	_viewport.add_child(fill_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25, 170, 0)
	rim_light.light_energy = 1.1
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	rim_light.shadow_enabled = false
	_viewport.add_child(rim_light)

	# ── Camera — three-quarter view, square framing ────────────────
	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	var focus := Vector3.ZERO
	var distance := 2.4
	var yaw := deg_to_rad(28.0)
	var pitch := deg_to_rad(35.0)
	_camera.position = focus + Vector3(
		distance * sin(yaw) * cos(pitch),
		distance * sin(pitch),
		distance * cos(yaw) * cos(pitch)
	)
	_viewport.add_child(_camera)
	_camera.look_at(focus, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── The five solids ─────────────────────────────────────────────
	# Order: vertex count ascending — tetra (4) → cube (8) → octa (6
	# vertices but 8 faces, dual of cube) → dodeca (20 v / 12 f) →
	# icosa (12 v / 20 f, dual of dodeca). Page sorts by face count.
	var solids := [
		{
			"id": "tetrahedron",
			"color": COLOR_TETRA,
			"geom": _tetrahedron_geometry(),
			"faces_n": 4,
			"vertices_n": 4,
			"edges_n": 6,
			"face_polygon": "triangle (3 sides)",
			"schlafli": "{3,3}",
			"dual": "tetrahedron",  # self-dual
			"notes": "Four triangular faces, four vertices, six edges. Self-dual — its dual is itself. The simplest Platonic solid and the building block of every higher one. At each vertex three triangles meet.",
		},
		{
			"id": "cube",
			"color": COLOR_CUBE,
			"geom": _cube_geometry(),
			"faces_n": 6,
			"vertices_n": 8,
			"edges_n": 12,
			"face_polygon": "square (4 sides)",
			"schlafli": "{4,3}",
			"dual": "octahedron",
			"notes": "Six square faces, eight vertices, twelve edges. The grid cell, the unit measure. Its dual is the octahedron — put a vertex at the center of each face and you get one.",
		},
		{
			"id": "octahedron",
			"color": COLOR_OCTA,
			"geom": _octahedron_geometry(),
			"faces_n": 8,
			"vertices_n": 6,
			"edges_n": 12,
			"face_polygon": "triangle (3 sides)",
			"schlafli": "{3,4}",
			"dual": "cube",
			"notes": "Eight triangular faces, six vertices, twelve edges. Dual of the cube — same number of edges, vertices and faces swapped. At each vertex four triangles meet.",
		},
		{
			"id": "dodecahedron",
			"color": COLOR_DODECA,
			"geom": _dodecahedron_geometry(),
			"faces_n": 12,
			"vertices_n": 20,
			"edges_n": 30,
			"face_polygon": "regular pentagon (5 sides)",
			"schlafli": "{5,3}",
			"dual": "icosahedron",
			"notes": "Twelve regular pentagonal faces, twenty vertices, thirty edges. Built on the golden ratio φ. Dual of the icosahedron — the only Platonic solid whose faces are pentagons.",
		},
		{
			"id": "icosahedron",
			"color": COLOR_ICOSA,
			"geom": _icosahedron_geometry(),
			"faces_n": 20,
			"vertices_n": 12,
			"edges_n": 30,
			"face_polygon": "triangle (3 sides)",
			"schlafli": "{3,5}",
			"dual": "dodecahedron",
			"notes": "Twenty triangular faces, twelve vertices, thirty edges. The Platonic solid with the most faces — the closest to a sphere. At each vertex five triangles meet. Dual of the dodecahedron.",
		},
	]

	for solid in solids:
		var geom: Dictionary = solid["geom"]
		_normalize_to_circumsphere(geom["vertices"], TARGET_RADIUS)
		var color: Color = solid["color"]
		var body := _build_body(geom, color)
		_scene_holder.add_child(body)
		var wire := _build_polyhedron_wireframe(geom)
		body.add_child(wire)
		await create_timer(0.05).timeout
		await _capture_and_record(solid["id"], {
			"primitive": "platonic",
			"name": solid["id"],
			"faces": solid["faces_n"],
			"vertices": solid["vertices_n"],
			"edges": solid["edges_n"],
			"face_polygon": solid["face_polygon"],
			"schlafli": solid["schlafli"],
			"dual": solid["dual"],
			"notes": solid["notes"],
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "The five Platonic solids — tetrahedron, cube, octahedron, dodecahedron, icosahedron — rendered side-by-side at the same circumscribed-sphere radius so size doesn't bias the eye. There are exactly five regular convex polyhedra in 3D space (Euclid IX, proven by counting how many regular polygons can meet at a vertex). Captured at 1024×1024 with MSAA 8x; saturated body color per solid + bright white wireframe overlay drawing only the true polyhedron edges, so vertex and edge counts are countable at thumbnail scale.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"fov": 38.0, "yaw_deg": 28.0, "pitch_deg": 35.0, "distance": 2.4},
		"target_radius": TARGET_RADIUS,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Geometry — every face is a polygon (Array of vertex indices) ─────

func _tetrahedron_geometry() -> Dictionary:
	var vertices: Array = [
		Vector3( 1,  1,  1),
		Vector3( 1, -1, -1),
		Vector3(-1,  1, -1),
		Vector3(-1, -1,  1),
	]
	# 4 triangular faces. Winding chosen so normals point outward.
	var faces: Array = [
		[0, 2, 1],
		[0, 1, 3],
		[0, 3, 2],
		[1, 2, 3],
	]
	return {"vertices": vertices, "faces": faces}


func _cube_geometry() -> Dictionary:
	var vertices: Array = [
		Vector3(-1, -1,  1),  # 0
		Vector3( 1, -1,  1),  # 1
		Vector3( 1,  1,  1),  # 2
		Vector3(-1,  1,  1),  # 3
		Vector3(-1, -1, -1),  # 4
		Vector3( 1, -1, -1),  # 5
		Vector3( 1,  1, -1),  # 6
		Vector3(-1,  1, -1),  # 7
	]
	# 6 square faces (CCW seen from outside).
	var faces: Array = [
		[0, 1, 2, 3],  # +Z
		[5, 4, 7, 6],  # -Z
		[4, 0, 3, 7],  # -X
		[1, 5, 6, 2],  # +X
		[3, 2, 6, 7],  # +Y
		[4, 5, 1, 0],  # -Y
	]
	return {"vertices": vertices, "faces": faces}


func _octahedron_geometry() -> Dictionary:
	var vertices: Array = [
		Vector3( 0,  1,  0),  # top
		Vector3( 0, -1,  0),  # bottom
		Vector3( 1,  0,  0),
		Vector3(-1,  0,  0),
		Vector3( 0,  0,  1),
		Vector3( 0,  0, -1),
	]
	# 8 triangular faces.
	var faces: Array = [
		[0, 4, 2],
		[0, 2, 5],
		[0, 5, 3],
		[0, 3, 4],
		[1, 2, 4],
		[1, 5, 2],
		[1, 3, 5],
		[1, 4, 3],
	]
	return {"vertices": vertices, "faces": faces}


func _dodecahedron_geometry() -> Dictionary:
	# Standard dodecahedron coordinates using golden ratio φ.
	# 20 vertices = 8 cube corners (±1,±1,±1) + 12 rectangle corners.
	var a := 1.0 / PHI
	var b := PHI
	var vertices: Array = [
		Vector3( 1,  1,  1), Vector3( 1,  1, -1), Vector3( 1, -1,  1), Vector3(-1,  1,  1),
		Vector3(-1, -1,  1), Vector3(-1,  1, -1), Vector3( 1, -1, -1), Vector3(-1, -1, -1),
		Vector3( 0,  a,  b), Vector3( 0, -a,  b), Vector3( 0,  a, -b), Vector3( 0, -a, -b),
		Vector3( a,  b,  0), Vector3(-a,  b,  0), Vector3( a, -b,  0), Vector3(-a, -b,  0),
		Vector3( b,  0,  a), Vector3(-b,  0,  a), Vector3( b,  0, -a), Vector3(-b,  0, -a),
	]
	# 12 pentagonal faces — each a list of 5 vertex indices in winding order.
	var faces: Array = [
		[3, 17, 4, 9, 8],
		[0, 12, 13, 3, 8],
		[0, 8, 9, 2, 16],
		[0, 16, 18, 1, 12],
		[1, 18, 6, 14, 12],
		[2, 9, 4, 15, 14],
		[2, 14, 6, 18, 16],
		[3, 13, 5, 19, 17],
		[4, 17, 19, 7, 15],
		[5, 13, 12, 1, 10],
		[5, 10, 11, 7, 19],
		[6, 11, 10, 1, 18],
	]
	return {"vertices": vertices, "faces": faces}


func _icosahedron_geometry() -> Dictionary:
	# Three orthogonal golden rectangles' 12 corners.
	var a := 1.0
	var b := PHI
	var vertices: Array = [
		Vector3( b,  a,  0),  # 0
		Vector3(-b,  a,  0),  # 1
		Vector3( b, -a,  0),  # 2
		Vector3(-b, -a,  0),  # 3
		Vector3( a,  0,  b),  # 4
		Vector3( a,  0, -b),  # 5
		Vector3(-a,  0,  b),  # 6
		Vector3(-a,  0, -b),  # 7
		Vector3( 0,  b,  a),  # 8
		Vector3( 0, -b,  a),  # 9
		Vector3( 0,  b, -a),  # 10
		Vector3( 0, -b, -a),  # 11
	]
	# 20 triangular faces, outward-wound. Lifted from
	# commons/primitives/icosahedron/icosahedron.gd which has Euler V-E+F=2 verified.
	var faces: Array = [
		[0, 8, 4], [8, 1, 6], [8, 6, 4], [0, 10, 8], [1, 8, 10],
		[2, 4, 9], [9, 6, 3], [9, 4, 6], [2, 9, 11], [3, 11, 9],
		[0, 5, 10], [1, 10, 7],
		[2, 11, 5], [3, 7, 11],
		[4, 2, 0], [5, 0, 2],
		[6, 1, 3], [7, 3, 1],
		[10, 5, 7], [11, 7, 5],
	]
	return {"vertices": vertices, "faces": faces}


# ── Helpers ─────────────────────────────────────────────────────────

# Rescale all vertices so the circumscribed sphere has the given radius.
# All five Platonics have their vertices equidistant from the centroid by
# definition, so this gives "same envelope" across the family.
func _normalize_to_circumsphere(vertices: Array, target_r: float) -> void:
	var current_r: float = 0.0
	for v in vertices:
		current_r = max(current_r, (v as Vector3).length())
	if current_r <= 0.0:
		return
	var s: float = target_r / current_r
	for i in range(vertices.size()):
		vertices[i] = (vertices[i] as Vector3) * s


# Build the solid body as one MeshInstance3D. Polygonal faces are
# fan-triangulated from the first vertex. Each triangle gets a flat
# normal so the body reads as faceted (true to the polyhedron).
func _build_body(geom: Dictionary, color: Color) -> MeshInstance3D:
	var vertices: Array = geom["vertices"]
	var faces: Array = geom["faces"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in faces:
		if face.size() < 3:
			continue
		var v0: Vector3 = vertices[face[0]]
		# Flat normal for the whole polygon — Newell would be overkill;
		# the first triangle's normal is correct because the polygon is planar.
		var v_a: Vector3 = vertices[face[1]]
		var v_b: Vector3 = vertices[face[2]]
		var normal: Vector3 = (v_a - v0).cross(v_b - v0).normalized()
		for i in range(1, face.size() - 1):
			var a: Vector3 = vertices[face[i]]
			var b: Vector3 = vertices[face[i + 1]]
			st.set_normal(normal)
			st.add_vertex(v0)
			st.set_normal(normal)
			st.add_vertex(a)
			st.set_normal(normal)
			st.add_vertex(b)
	var mesh: ArrayMesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.15
	# CULL_DISABLED — any face-winding errors in the hand-coded pentagon
	# list don't leave holes. The wireframe overlay still keeps the
	# silhouette honest because edges are deduped by unordered pair.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.name = "PlatonicBody"
	return mi


# Build a wireframe overlay showing ONLY the unique polyhedron edges
# (not the fan-triangulation seams). For each face, walk its perimeter
# and add a line per edge; dedupe by sorted endpoint indices so each
# physical edge is drawn exactly once.
func _build_polyhedron_wireframe(geom: Dictionary) -> MeshInstance3D:
	var vertices: Array = geom["vertices"]
	var faces: Array = geom["faces"]
	var edge_set := {}
	for face in faces:
		var n: int = face.size()
		for i in range(n):
			var a: int = face[i]
			var b: int = face[(i + 1) % n]
			var key: String
			if a < b:
				key = "%d_%d" % [a, b]
			else:
				key = "%d_%d" % [b, a]
			edge_set[key] = [a, b]
	# Push wireframe slightly outward along vertex normal (= normalized
	# vertex position, since the body is centered at origin) so it doesn't
	# z-fight with the body's front faces.
	var bump: float = 1.005
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = WIRE_COLOR
	mat.emission_enabled = true
	mat.emission = WIRE_COLOR
	mat.emission_energy_multiplier = 0.6
	mat.disable_receive_shadows = true
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	for key in edge_set.keys():
		var pair: Array = edge_set[key]
		var p_a: Vector3 = (vertices[pair[0]] as Vector3) * bump
		var p_b: Vector3 = (vertices[pair[1]] as Vector3) * bump
		im.surface_add_vertex(p_a)
		im.surface_add_vertex(p_b)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "PlatonicWire"
	return mi


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, meta: Dictionary) -> void:
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var config := meta.duplicate(true)
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"notes": meta.get("notes", ""),
		"primitive": "platonic",
		"image": "/parametric-platonic-gallery/%s" % img_rel,
		"config": "/parametric-platonic-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s" % id)
