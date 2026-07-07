## Triangle Table — limits of geometry. DNA gallery capture.
##
## Pedagogical claim: a triangle's angle sum depends on the curvature of the
## surface it lives on. The parallel postulate is a SETTING, not a truth.
##   - Flat (K = 0):       α + β + γ = π  (180°)        — Euclid
##   - Elliptic (K > 0):   α + β + γ > π  (excess)      — sphere
##   - Hyperbolic (K < 0): α + β + γ < π  (defect)      — saddle / Poincaré disk
## The deviation IS the curvature (Gauss-Bonnet). Big triangle → big deviation;
## tiny triangle → locally flat → ~180° on any surface.
##
## Sweep: 3 surfaces × 3 triangle sizes = 9 cells.
##   row 1: sphere      (K=+1, unit radius) at small / medium / large
##   row 2: plane       (K=0)               — always 180°, the diagnostic case
##   row 3: Poincaré    (K=−1, unit disk)   at small / medium / large
##
## Each cell renders:
##   - the surface drawn faintly (translucent globe / grid / Poincaré boundary)
##   - the triangle's three vertices as small colored spheres
##   - geodesic edges (straight on flat, great-circle arcs on sphere, arcs of
##     boundary-orthogonal circles on the Poincaré disk)
##   - small arc-segment markers at each vertex showing the interior angle
##   - text label in cell: "α+β+γ = NNN.N° (K=K, excess/defect)" baked into
##     the PNG via a Label3D
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_triangle_table_gallery.gd \
##     -- --out=user://triangle_table_gallery
##
## Output: <out>/{flat_small,flat_medium,flat_large, sphere_small,..., poincare_small,...}.png
##         + .json sidecar per cell + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Triangle visuals
const VERTEX_COLOR_A: Color = Color(0.98, 0.42, 0.42)        # red — vertex A
const VERTEX_COLOR_B: Color = Color(0.42, 0.78, 0.98)        # blue — vertex B
const VERTEX_COLOR_C: Color = Color(0.62, 0.95, 0.50)        # green — vertex C
const EDGE_COLOR: Color = Color(1.00, 0.92, 0.55)            # warm yellow geodesic
const ANGLE_ARC_COLOR: Color = Color(1.00, 0.62, 0.18)       # bright orange angle arc
const SURFACE_COLOR_FLAT: Color = Color(0.40, 0.44, 0.52, 0.65)
const SURFACE_COLOR_SPHERE: Color = Color(0.55, 0.45, 0.78, 0.30)
const SURFACE_COLOR_DISK: Color = Color(0.30, 0.55, 0.78, 0.18)
const SURFACE_BOUNDARY_COLOR: Color = Color(0.92, 0.82, 0.55, 0.95)
const GRID_LINE_COLOR: Color = Color(0.55, 0.60, 0.70, 0.50)
const LABEL_BG_COLOR: Color = Color(0.04, 0.05, 0.08, 0.92)

# Drawing tuneables
const VERTEX_RADIUS: float = 0.040
const EDGE_LINE_THICKNESS: float = 0.014     # via thin cylinder mesh
const ANGLE_ARC_RADIUS: float = 0.16          # arc radius in tangent-plane units
const ANGLE_ARC_SEGMENTS: int = 24
const EDGE_SEGMENTS: int = 64

var _output_dir: String = "user://triangle_table_gallery"
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
	_setup_viewport()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep: three surfaces × three triangle sizes ──────────────────
	# Order chosen so manifest entries read row-by-row: sphere → flat → hyperbolic
	# Sizes labelled small/medium/large; each surface picks its own
	# numeric values appropriate to its geometry.

	# Sphere — angles in radians for two vertices, fixed-axis triangle.
	# We pick three latitudes/longitudes such that vertex distances grow
	# from "tiny triangle on the equator" to "covers a quarter of the sphere".
	# Spherical triangle on unit sphere, parameterised by "size" (the
	# angular distance from north pole down to two equatorial vertices,
	# plus the longitude span between those two vertices).
	#
	#                       /\ ← vertex A (top, at colatitude=delta from north)
	#                      /  \
	#                     /    \
	#                    /      \
	#         vertex B ─/──────  ─\─ vertex C
	#         (lat=π/2-delta,    (lat=π/2-delta,
	#          lon=-half)          lon=+half)
	#
	# Small: delta=0.10rad, half=0.10rad → tiny triangle near a pole
	# Medium: delta=0.55rad, half=0.55rad
	# Large: delta=1.10rad, half=1.10rad → covers a major chunk
	var sphere_sizes := [
		{"label": "small",  "delta": 0.12, "half_lon": 0.12},
		{"label": "medium", "delta": 0.40, "half_lon": 0.40},
		{"label": "large",  "delta": 0.75, "half_lon": 0.75},
	]
	for s in sphere_sizes:
		await _capture_sphere_cell(s["label"], s["delta"], s["half_lon"])

	# Flat — equilateral triangle in XZ plane at three sizes.
	# The diagnostic row: same triangle shape, three sizes, ALL 180°.
	var flat_sizes := [
		{"label": "small",  "scale": 0.18},
		{"label": "medium", "scale": 0.45},
		{"label": "large",  "scale": 0.78},
	]
	for s in flat_sizes:
		await _capture_flat_cell(s["label"], s["scale"])

	# Hyperbolic on Poincaré disk — three vertices inside the unit disk,
	# arranged symmetrically (rotated 120° from each other) at three
	# distances from the origin. As the radius → boundary, the ideal
	# triangle's angle sum → 0; as the radius → 0, → π.
	# We pick radii so the triangle gradually inflates toward the boundary.
	var poincare_sizes := [
		{"label": "small",  "radius": 0.18},  # small triangle near origin → near 180°
		{"label": "medium", "radius": 0.55},
		{"label": "large",  "radius": 0.85},  # nearly ideal → angle sum → small
	]
	for s in poincare_sizes:
		await _capture_poincare_cell(s["label"], s["radius"])

	# Manifest ─────────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Triangle table — limits of geometry. A triangle laid on three surfaces (flat K=0, elliptic K=+1, hyperbolic K=−1) at three sizes each = 9 cells. Edges are geodesics: straight on flat, great-circle arcs on the sphere, arcs of boundary-orthogonal circles on the Poincaré disk. Interior angles measured at each vertex; their sum equals π only on flat. Spherical triangles have excess (sum > π); hyperbolic triangles have defect (sum < π). The deviation IS the curvature — Gauss-Bonnet made tactile. The parallel postulate is a setting, not a truth.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Viewport setup ──────────────────────────────────────────────────

func _setup_viewport() -> void:
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.82, 0.92)
	env.ambient_light_energy = 0.65
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

	# Lighting trio (key + fill + rim) — matches parametric_mesh_gallery
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, 35, 0)
	key_light.light_energy = 1.5
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
	rim_light.light_energy = 1.0
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	rim_light.shadow_enabled = false
	_viewport.add_child(rim_light)

	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_viewport.add_child(_camera)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


# ── Material helpers ────────────────────────────────────────────────

func _solid_mat(color: Color, emission: float = 0.20) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = emission
	return mat


func _surface_mat(color: Color, double_sided: bool = true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.85
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.10
	if double_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _unshaded_line_mat(color: Color, energy: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.disable_receive_shadows = true
	# Render through the translucent surface so the geodesic stays visible.
	mat.no_depth_test = true
	return mat


# ── Camera helpers ─────────────────────────────────────────────────

func _set_perspective_camera(position: Vector3, look_at: Vector3, up: Vector3 = Vector3.UP) -> void:
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.position = position
	_camera.look_at(look_at, up)


func _set_orthographic_camera(size: float, position: Vector3, look_at: Vector3, up: Vector3 = Vector3.UP) -> void:
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = size
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.position = position
	_camera.look_at(look_at, up)


# ── SPHERE (K = +1) ────────────────────────────────────────────────
#
# Unit sphere centered at origin. Three vertices A, B, C as unit vectors.
# Layout: A at the "top" (near +Y pole). B at lat=π/2-delta, lon=-half_lon.
# C at lat=π/2-delta, lon=+half_lon. As delta and half_lon grow, the
# triangle covers more of the sphere → larger angle excess.

func _capture_sphere_cell(size_label: String, delta: float, half_lon: float) -> void:
	_clear_holder()
	var radius: float = 1.0

	# Vertices — A at colatitude delta from +Y pole (so lat = π/2 - delta),
	# longitude 0. B and C at colatitude delta from "south of A" — we want
	# all three vertices roughly symmetric so the triangle is isoceles.
	# Place A at colatitude=0 (north pole) and B/C at colatitude=2*delta,
	# split by half_lon on either side of longitude 0. (Slightly cleaner.)
	# We then ROTATE all three vertices so the triangle's centroid points
	# along a fixed camera-facing direction. This keeps the camera position
	# constant across all three sphere cells.
	var V_A_local: Vector3 = _sphere_point(0.0, 0.0, radius)
	var V_B_local: Vector3 = _sphere_point(2.0 * delta, -half_lon, radius)
	var V_C_local: Vector3 = _sphere_point(2.0 * delta, +half_lon, radius)
	var local_centroid: Vector3 = (V_A_local + V_B_local + V_C_local).normalized()
	# Pre-rotate vertices so centroid lines up with the camera-facing axis.
	# Use a slightly off-axis target so the triangle reads as 3D, not as a
	# flat silhouette dead-on.
	var face_dir: Vector3 = Vector3(0.30, 0.55, 0.78).normalized()
	var rot: Basis = _rotation_basis_from_to(local_centroid, face_dir)
	var V_A: Vector3 = rot * V_A_local
	var V_B: Vector3 = rot * V_B_local
	var V_C: Vector3 = rot * V_C_local

	# Compute interior angles. On unit sphere, interior angle at V between
	# edges V→A and V→B is the angle between tangent vectors. Tangent of
	# edge V→W at V is (W - cos(c)·V) / sin(c) where c = arccos(V·W).
	var ang_A_rad: float = _sphere_interior_angle(V_A, V_B, V_C)
	var ang_B_rad: float = _sphere_interior_angle(V_B, V_C, V_A)
	var ang_C_rad: float = _sphere_interior_angle(V_C, V_A, V_B)
	var sum_rad: float = ang_A_rad + ang_B_rad + ang_C_rad
	var sum_deg: float = rad_to_deg(sum_rad)
	var excess_deg: float = sum_deg - 180.0

	# ── Build the scene ────────────────────────────────────────────
	# Translucent sphere
	var sphere_mi := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2.0
	sphere_mesh.radial_segments = 64
	sphere_mesh.rings = 32
	sphere_mi.mesh = sphere_mesh
	sphere_mi.material_override = _surface_mat(SURFACE_COLOR_SPHERE, false)
	_scene_holder.add_child(sphere_mi)

	# A faint latitude/longitude wireframe to read the curvature
	var latlon_wire := _build_sphere_latlon_wire(radius, 12, 6)
	_scene_holder.add_child(latlon_wire)

	# Three great-circle edges A-B, B-C, C-A
	for edge in [[V_A, V_B], [V_B, V_C], [V_C, V_A]]:
		var arc_pts := _sphere_great_circle_arc(edge[0], edge[1], radius, EDGE_SEGMENTS)
		_scene_holder.add_child(_polyline_mesh(arc_pts, EDGE_COLOR, EDGE_LINE_THICKNESS))

	# Vertex spheres — bump them out a hair so they sit above the surface
	_scene_holder.add_child(_vertex_sphere(V_A * 1.01, VERTEX_COLOR_A))
	_scene_holder.add_child(_vertex_sphere(V_B * 1.01, VERTEX_COLOR_B))
	_scene_holder.add_child(_vertex_sphere(V_C * 1.01, VERTEX_COLOR_C))

	# Angle markers — small arcs in the tangent plane at each vertex
	_scene_holder.add_child(_sphere_angle_arc(V_A, V_B, V_C, radius))
	_scene_holder.add_child(_sphere_angle_arc(V_B, V_C, V_A, radius))
	_scene_holder.add_child(_sphere_angle_arc(V_C, V_A, V_B, radius))

	# Camera: orthographic, fixed for all three sphere cells. Look from face_dir
	# toward a look-at target slightly above origin so the sphere occupies the
	# upper portion of the frame and the label sits clear below.
	var cam_dist: float = 5.0
	var look_at_target: Vector3 = Vector3(0, 0.30, 0)
	_set_orthographic_camera(3.0, face_dir * cam_dist + look_at_target, look_at_target, Vector3.UP)

	# Label — place below the sphere in world space. Sphere bottom is at
	# Y=-1; ortho frame Y range = look_y ± 1.5 = [-1.20, +1.80]. Label at
	# Y=-1.12 lives between sphere bottom and frame bottom.
	var label_text := "α+β+γ = %.1f°\nK=+1, excess %.1f°" % [sum_deg, excess_deg]
	_scene_holder.add_child(_make_label(label_text, Vector3(0, -1.12, 0)))

	await _capture_and_record("sphere_%s" % size_label, {
		"surface": "elliptic",
		"K": 1,
		"size": size_label,
		"radius": radius,
		"vertices": [
			[V_A.x, V_A.y, V_A.z],
			[V_B.x, V_B.y, V_B.z],
			[V_C.x, V_C.y, V_C.z],
		],
		"angles_degrees": [rad_to_deg(ang_A_rad), rad_to_deg(ang_B_rad), rad_to_deg(ang_C_rad)],
		"angle_sum_degrees": sum_deg,
		"excess_or_defect": excess_deg,
		"notes": _sphere_notes(size_label, sum_deg, excess_deg),
	})


# Convert (colatitude, longitude) on unit sphere to Cartesian.
# colatitude=0 → north pole (0, R, 0). longitude=0 → +X side.
func _sphere_point(colat: float, lon: float, radius: float) -> Vector3:
	var sin_c: float = sin(colat)
	return Vector3(sin_c * cos(lon), cos(colat), sin_c * sin(lon)) * radius


# Spherical interior angle at vertex V given the other two vertices A and B.
# (V, A, B must all be unit-length, i.e. on the unit sphere.)
func _sphere_interior_angle(V: Vector3, A: Vector3, B: Vector3) -> float:
	# Tangent vector at V along the great-circle arc to A:
	#   t_VA = (A - (V·A) V) normalized
	# Same for B. Interior angle = arccos(t_VA · t_VB).
	var V_n: Vector3 = V.normalized()
	var A_n: Vector3 = A.normalized()
	var B_n: Vector3 = B.normalized()
	var t_VA: Vector3 = (A_n - V_n * V_n.dot(A_n)).normalized()
	var t_VB: Vector3 = (B_n - V_n * V_n.dot(B_n)).normalized()
	var c: float = clamp(t_VA.dot(t_VB), -1.0, 1.0)
	return acos(c)


# Great-circle arc from A to B sampled with segments+1 points.
# Slerp: (sin((1-t)·c)·A + sin(t·c)·B) / sin(c), c = angle between A,B.
func _sphere_great_circle_arc(A: Vector3, B: Vector3, radius: float, segments: int) -> PackedVector3Array:
	var A_n: Vector3 = A.normalized()
	var B_n: Vector3 = B.normalized()
	var dot_v: float = clamp(A_n.dot(B_n), -1.0, 1.0)
	var c: float = acos(dot_v)
	var pts := PackedVector3Array()
	if abs(c) < 1.0e-6:
		pts.append(A_n * radius)
		pts.append(B_n * radius)
		return pts
	var sin_c: float = sin(c)
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var s0: float = sin((1.0 - t) * c) / sin_c
		var s1: float = sin(t * c) / sin_c
		var p: Vector3 = (A_n * s0 + B_n * s1) * radius
		pts.append(p)
	return pts


# Small angle-arc marker at vertex V on the unit sphere, in the tangent
# plane, swept between the tangent-to-A and tangent-to-B directions.
func _sphere_angle_arc(V: Vector3, A: Vector3, B: Vector3, radius: float) -> MeshInstance3D:
	var V_n: Vector3 = V.normalized()
	var A_n: Vector3 = A.normalized()
	var B_n: Vector3 = B.normalized()
	var t_VA: Vector3 = (A_n - V_n * V_n.dot(A_n)).normalized()
	var t_VB: Vector3 = (B_n - V_n * V_n.dot(B_n)).normalized()
	var ang: float = acos(clamp(t_VA.dot(t_VB), -1.0, 1.0))
	# Construct a basis (t_VA, perp_in_plane) so we sweep through the
	# interior angle, not the exterior reflex.
	var perp: Vector3 = (t_VB - t_VA * t_VA.dot(t_VB))
	if perp.length() < 1.0e-5:
		# Degenerate (collinear) — just skip arc by returning empty mesh.
		var empty := MeshInstance3D.new()
		empty.mesh = ImmediateMesh.new()
		return empty
	perp = perp.normalized()
	var pts := PackedVector3Array()
	# Sit the arc on the sphere surface bumped slightly outward so it reads
	# clearly. The arc lies in the tangent plane at V, scaled by ANGLE_ARC_RADIUS,
	# then re-projected onto the sphere by adding V_n*radius.
	var center: Vector3 = V_n * (radius * 1.005)
	for i in range(ANGLE_ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ANGLE_ARC_SEGMENTS)
		var phi: float = t * ang
		var dir: Vector3 = t_VA * cos(phi) + perp * sin(phi)
		# Place arc point in the tangent plane offset from center; this is
		# NOT on the sphere — it sticks above slightly. Acceptable: we want
		# it visible. Projection onto the sphere would shrink the arc.
		var p: Vector3 = center + dir * ANGLE_ARC_RADIUS
		pts.append(p)
	return _polyline_mesh(pts, ANGLE_ARC_COLOR, EDGE_LINE_THICKNESS * 0.75)


# Latitude/longitude wireframe — a faint guide that shows the sphere's
# curvature without dominating the triangle. lat_count = number of
# latitudinal circles (not counting poles); lon_count = number of meridians.
func _build_sphere_latlon_wire(radius: float, lon_count: int, lat_count: int) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_line_mat(Color(0.65, 0.62, 0.78, 0.45), 0.5))
	var bump: float = 1.001
	# Meridians (longitudes)
	for i in range(lon_count):
		var lon: float = float(i) * TAU / float(lon_count)
		var cos_l: float = cos(lon)
		var sin_l: float = sin(lon)
		var steps: int = 48
		for step in range(steps):
			var t0: float = float(step) / float(steps)
			var t1: float = float(step + 1) / float(steps)
			var colat0: float = lerpf(0.0, PI, t0)
			var colat1: float = lerpf(0.0, PI, t1)
			var p0: Vector3 = Vector3(sin(colat0) * cos_l, cos(colat0), sin(colat0) * sin_l) * (radius * bump)
			var p1: Vector3 = Vector3(sin(colat1) * cos_l, cos(colat1), sin(colat1) * sin_l) * (radius * bump)
			im.surface_add_vertex(p0)
			im.surface_add_vertex(p1)
	# Latitudes (parallels) — skip poles
	for j in range(1, lat_count):
		var colat: float = float(j) * PI / float(lat_count)
		var sin_c: float = sin(colat)
		var y: float = cos(colat) * radius * bump
		var r_at: float = sin_c * radius * bump
		var steps2: int = 64
		for step in range(steps2):
			var a0: float = float(step) * TAU / float(steps2)
			var a1: float = float(step + 1) * TAU / float(steps2)
			im.surface_add_vertex(Vector3(cos(a0) * r_at, y, sin(a0) * r_at))
			im.surface_add_vertex(Vector3(cos(a1) * r_at, y, sin(a1) * r_at))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "SphereLatLon"
	return mi


# ── FLAT (K = 0) ───────────────────────────────────────────────────

func _capture_flat_cell(size_label: String, scale: float) -> void:
	_clear_holder()

	# Equilateral triangle in XZ plane centred at origin, top vertex toward +Z.
	var V_A: Vector3 = Vector3(0.0, 0.0, -scale)                  # top
	var V_B: Vector3 = Vector3(-scale * sin(deg_to_rad(60.0)), 0.0, scale * 0.5)
	var V_C: Vector3 = Vector3(+scale * sin(deg_to_rad(60.0)), 0.0, scale * 0.5)

	# Interior angles via planar vectors
	var ang_A: float = _planar_interior_angle(V_A, V_B, V_C)
	var ang_B: float = _planar_interior_angle(V_B, V_C, V_A)
	var ang_C: float = _planar_interior_angle(V_C, V_A, V_B)
	var sum_rad: float = ang_A + ang_B + ang_C
	var sum_deg: float = rad_to_deg(sum_rad)

	# Grid plane
	_scene_holder.add_child(_build_grid_plane(1.4, 16))

	# Edges — straight lines
	_scene_holder.add_child(_polyline_mesh(PackedVector3Array([V_A, V_B]), EDGE_COLOR, EDGE_LINE_THICKNESS))
	_scene_holder.add_child(_polyline_mesh(PackedVector3Array([V_B, V_C]), EDGE_COLOR, EDGE_LINE_THICKNESS))
	_scene_holder.add_child(_polyline_mesh(PackedVector3Array([V_C, V_A]), EDGE_COLOR, EDGE_LINE_THICKNESS))

	# Vertex spheres
	_scene_holder.add_child(_vertex_sphere(V_A, VERTEX_COLOR_A))
	_scene_holder.add_child(_vertex_sphere(V_B, VERTEX_COLOR_B))
	_scene_holder.add_child(_vertex_sphere(V_C, VERTEX_COLOR_C))

	# Planar angle arcs
	_scene_holder.add_child(_planar_angle_arc(V_A, V_B, V_C))
	_scene_holder.add_child(_planar_angle_arc(V_B, V_C, V_A))
	_scene_holder.add_child(_planar_angle_arc(V_C, V_A, V_B))

	# Camera: orthographic top-down — looking straight down +Y at the XZ plane.
	# The "up" of the screen corresponds to -Z (so V_A at z<0 appears at top).
	# Look-at target shifted toward -Z so the triangle sits in the upper
	# portion of the frame, leaving the lower portion clear for the label.
	# Ortho size 2.40 → visible Z range = look_z ± 1.20 = [-0.20-1.20, -0.20+1.20] = [-1.40, +1.00]
	_set_orthographic_camera(2.40, Vector3(0.0, 2.5, -0.20), Vector3(0, 0, -0.20), Vector3(0, 0, -1))

	# Label — placed in the screen-bottom margin (positive Z is screen-bottom
	# since we look from +Y down toward -Y with up=-Z). z=0.80 stays inside.
	var label_text := "α+β+γ = %.1f°\nK=0, flat" % sum_deg
	_scene_holder.add_child(_make_label(label_text, Vector3(0.0, 0.04, 0.80)))

	await _capture_and_record("flat_%s" % size_label, {
		"surface": "flat",
		"K": 0,
		"size": size_label,
		"scale": scale,
		"vertices": [
			[V_A.x, V_A.y, V_A.z],
			[V_B.x, V_B.y, V_B.z],
			[V_C.x, V_C.y, V_C.z],
		],
		"angles_degrees": [rad_to_deg(ang_A), rad_to_deg(ang_B), rad_to_deg(ang_C)],
		"angle_sum_degrees": sum_deg,
		"excess_or_defect": sum_deg - 180.0,
		"notes": _flat_notes(size_label, sum_deg),
	})


func _planar_interior_angle(V: Vector3, A: Vector3, B: Vector3) -> float:
	var u: Vector3 = (A - V).normalized()
	var w: Vector3 = (B - V).normalized()
	return acos(clamp(u.dot(w), -1.0, 1.0))


func _planar_angle_arc(V: Vector3, A: Vector3, B: Vector3) -> MeshInstance3D:
	var u: Vector3 = (A - V).normalized()
	var w: Vector3 = (B - V).normalized()
	var ang: float = acos(clamp(u.dot(w), -1.0, 1.0))
	# The arc lies in the same plane as the triangle (XZ for flat). Sweep
	# from u toward w by interpolating in the plane spanned by them.
	var perp: Vector3 = (w - u * u.dot(w))
	if perp.length() < 1.0e-5:
		var empty := MeshInstance3D.new()
		empty.mesh = ImmediateMesh.new()
		return empty
	perp = perp.normalized()
	var pts := PackedVector3Array()
	for i in range(ANGLE_ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ANGLE_ARC_SEGMENTS)
		var phi: float = t * ang
		var dir: Vector3 = u * cos(phi) + perp * sin(phi)
		pts.append(V + dir * ANGLE_ARC_RADIUS * 0.8)
	return _polyline_mesh(pts, ANGLE_ARC_COLOR, EDGE_LINE_THICKNESS * 0.75)


func _build_grid_plane(half_size: float, divisions: int) -> Node3D:
	var holder := Node3D.new()
	holder.name = "GridPlane"
	# A solid translucent plane behind the grid, very dim
	var plane_mi := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(half_size * 2.0, half_size * 2.0)
	plane_mi.mesh = plane_mesh
	plane_mi.position = Vector3(0, -0.001, 0)
	plane_mi.material_override = _surface_mat(SURFACE_COLOR_FLAT, true)
	holder.add_child(plane_mi)

	# Grid lines
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_line_mat(GRID_LINE_COLOR, 0.45))
	var step: float = (half_size * 2.0) / float(divisions)
	for i in range(divisions + 1):
		var v: float = -half_size + float(i) * step
		# Lines along X (varying Z)
		im.surface_add_vertex(Vector3(-half_size, 0.001, v))
		im.surface_add_vertex(Vector3(+half_size, 0.001, v))
		# Lines along Z (varying X)
		im.surface_add_vertex(Vector3(v, 0.001, -half_size))
		im.surface_add_vertex(Vector3(v, 0.001, +half_size))
	im.surface_end()
	var grid_mi := MeshInstance3D.new()
	grid_mi.mesh = im
	grid_mi.name = "GridLines"
	holder.add_child(grid_mi)
	return holder


# ── POINCARÉ DISK (K = −1) ─────────────────────────────────────────
#
# Unit disk in the XZ plane (Y=0). Vertices are points inside the disk.
# Geodesic between two points P, Q:
#   - If the line through origin, P, Q is the same line (i.e. PQ goes
#     through 0), the geodesic is the straight diameter segment.
#   - Otherwise, it's the arc of a circle orthogonal to the unit circle
#     boundary passing through P and Q.
#
# Finding the orthogonal-circle center for non-diameter case:
#   The inversion of P in the unit circle is P* = P / |P|².
#   Any circle orthogonal to the unit circle is preserved by inversion;
#   if such a circle passes through P, it also passes through P*. So the
#   orthogonal circle through P and Q is the (unique) circle through three
#   points: P, Q, P*. Find its center C by intersecting perpendicular
#   bisectors of PP* and PQ.

func _capture_poincare_cell(size_label: String, triangle_radius: float) -> void:
	_clear_holder()

	# Three vertices arranged at 120° rotations around origin on a circle
	# of radius triangle_radius inside the unit disk.
	# Vertex angles: V_A at top (camera up = -Z, so put V_A at -Z),
	# V_B at lower-left, V_C at lower-right. Symmetric about the vertical.
	var V_A: Vector3 = Vector3(triangle_radius * cos(deg_to_rad(270.0)),
							   0.0,
							   triangle_radius * sin(deg_to_rad(270.0)))
	var V_B: Vector3 = Vector3(triangle_radius * cos(deg_to_rad(150.0)),
							   0.0,
							   triangle_radius * sin(deg_to_rad(150.0)))
	var V_C: Vector3 = Vector3(triangle_radius * cos(deg_to_rad(30.0)),
							   0.0,
							   triangle_radius * sin(deg_to_rad(30.0)))

	# Disk boundary as a faint ring + a dim translucent disk fill
	_scene_holder.add_child(_build_poincare_disk_visuals(1.0))

	# Geodesic edges — collect per-edge data so we can compute the tangents
	# at the vertices for the angle arcs.
	# Each edge gives: (arc center C, arc radius r, is_diameter, sweep_dir).
	# For interior angle at V along edge V→W, the tangent at V is perp to
	# (V - C) for arc, or just the direction (W - V) for diameter.
	var edge_AB := _poincare_geodesic_data(V_A, V_B)
	var edge_BC := _poincare_geodesic_data(V_B, V_C)
	var edge_CA := _poincare_geodesic_data(V_C, V_A)

	# Add the geodesic visual for each edge
	_scene_holder.add_child(_polyline_mesh(_poincare_geodesic_arc_points(V_A, V_B, edge_AB),
											EDGE_COLOR, EDGE_LINE_THICKNESS))
	_scene_holder.add_child(_polyline_mesh(_poincare_geodesic_arc_points(V_B, V_C, edge_BC),
											EDGE_COLOR, EDGE_LINE_THICKNESS))
	_scene_holder.add_child(_polyline_mesh(_poincare_geodesic_arc_points(V_C, V_A, edge_CA),
											EDGE_COLOR, EDGE_LINE_THICKNESS))

	# Vertex spheres
	_scene_holder.add_child(_vertex_sphere(V_A, VERTEX_COLOR_A))
	_scene_holder.add_child(_vertex_sphere(V_B, VERTEX_COLOR_B))
	_scene_holder.add_child(_vertex_sphere(V_C, VERTEX_COLOR_C))

	# Interior angles. The Poincaré disk is conformal: the hyperbolic angle
	# equals the Euclidean angle between the tangent vectors. So we just
	# compute the Euclidean tangent at V for each of the two incident edges,
	# then take arccos of their dot product.
	#   At vertex V_A: edges (V_A → V_B) [edge_AB] and (V_A → V_C) [edge_CA reversed].
	# Use _poincare_tangent_at to get the unit tangent at V along each edge.
	var t_A_to_B: Vector3 = _poincare_tangent_at(V_A, V_B, edge_AB)
	var t_A_to_C: Vector3 = _poincare_tangent_at(V_A, V_C, _poincare_geodesic_data(V_A, V_C))
	var ang_A: float = acos(clamp(t_A_to_B.dot(t_A_to_C), -1.0, 1.0))

	var t_B_to_A: Vector3 = _poincare_tangent_at(V_B, V_A, _poincare_geodesic_data(V_B, V_A))
	var t_B_to_C: Vector3 = _poincare_tangent_at(V_B, V_C, edge_BC)
	var ang_B: float = acos(clamp(t_B_to_A.dot(t_B_to_C), -1.0, 1.0))

	var t_C_to_A: Vector3 = _poincare_tangent_at(V_C, V_A, edge_CA)
	var t_C_to_B: Vector3 = _poincare_tangent_at(V_C, V_B, _poincare_geodesic_data(V_C, V_B))
	var ang_C: float = acos(clamp(t_C_to_A.dot(t_C_to_B), -1.0, 1.0))

	var sum_rad: float = ang_A + ang_B + ang_C
	var sum_deg: float = rad_to_deg(sum_rad)
	var defect_deg: float = 180.0 - sum_deg

	# Angle arc markers — at each vertex sweep from t_first to t_second
	_scene_holder.add_child(_disk_angle_arc(V_A, t_A_to_B, t_A_to_C))
	_scene_holder.add_child(_disk_angle_arc(V_B, t_B_to_A, t_B_to_C))
	_scene_holder.add_child(_disk_angle_arc(V_C, t_C_to_A, t_C_to_B))

	# Camera: orthographic head-on view of the disk (look down +Y axis).
	# Look-at target shifted toward -Z so the disk sits in the upper portion
	# of the frame, leaving black margin below for the label. Ortho size 2.80
	# → visible Z range = look_z ± 1.40 = [-0.30-1.40, -0.30+1.40] = [-1.70, +1.10].
	# Disk boundary at |z|=1 → disk bottom at z=+1.0; label at z=+1.05 lives
	# just outside the disk in the black margin.
	_set_orthographic_camera(2.80, Vector3(0.0, 2.5, -0.30), Vector3(0, 0, -0.30), Vector3(0, 0, -1))

	var label_text := "α+β+γ = %.1f°\nK=−1, defect %.1f°" % [sum_deg, defect_deg]
	_scene_holder.add_child(_make_label(label_text, Vector3(0.0, 0.04, 0.98)))

	await _capture_and_record("poincare_%s" % size_label, {
		"surface": "hyperbolic",
		"K": -1,
		"size": size_label,
		"triangle_radius": triangle_radius,
		"vertices": [
			[V_A.x, V_A.y, V_A.z],
			[V_B.x, V_B.y, V_B.z],
			[V_C.x, V_C.y, V_C.z],
		],
		"angles_degrees": [rad_to_deg(ang_A), rad_to_deg(ang_B), rad_to_deg(ang_C)],
		"angle_sum_degrees": sum_deg,
		"excess_or_defect": -defect_deg,
		"notes": _poincare_notes(size_label, sum_deg, defect_deg),
	})


# Geodesic data for edge from P to Q on the Poincaré disk.
# Returns Dictionary { is_diameter, center, radius }.
func _poincare_geodesic_data(P: Vector3, Q: Vector3) -> Dictionary:
	# Work in 2D (XZ); Y always 0.
	var p := Vector2(P.x, P.z)
	var q := Vector2(Q.x, Q.z)
	# Check if PQ passes through origin (collinear with 0). Cross product zero.
	var cross: float = p.x * q.y - p.y * q.x
	if abs(cross) < 1.0e-7:
		return {"is_diameter": true, "center": Vector2.ZERO, "radius": 0.0}
	# Otherwise build the circle through P, Q, P* where P* = P / |P|^2.
	var p_inv := p / p.length_squared()
	var center: Vector2 = _circumcenter_2d(p, q, p_inv)
	var radius: float = (center - p).length()
	return {"is_diameter": false, "center": center, "radius": radius}


func _circumcenter_2d(A: Vector2, B: Vector2, C: Vector2) -> Vector2:
	# Standard formula for the circumcenter of triangle ABC in 2D.
	var d: float = 2.0 * (A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y))
	if abs(d) < 1.0e-9:
		return (A + B + C) / 3.0  # degenerate, fallback
	var a2: float = A.x * A.x + A.y * A.y
	var b2: float = B.x * B.x + B.y * B.y
	var c2: float = C.x * C.x + C.y * C.y
	var ux: float = (a2 * (B.y - C.y) + b2 * (C.y - A.y) + c2 * (A.y - B.y)) / d
	var uy: float = (a2 * (C.x - B.x) + b2 * (A.x - C.x) + c2 * (B.x - A.x)) / d
	return Vector2(ux, uy)


# Sampled points along the geodesic from P to Q in the Poincaré disk.
func _poincare_geodesic_arc_points(P: Vector3, Q: Vector3, geo: Dictionary) -> PackedVector3Array:
	var pts := PackedVector3Array()
	if geo["is_diameter"]:
		# Straight line in XZ plane
		var steps := 4
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			pts.append(P.lerp(Q, t))
		return pts
	# Arc — interpolate the angle parameter around the center.
	var center: Vector2 = geo["center"]
	var radius: float = geo["radius"]
	var ang_P: float = atan2(P.z - center.y, P.x - center.x)
	var ang_Q: float = atan2(Q.z - center.y, Q.x - center.x)
	# Choose the shorter arc direction.
	var delta: float = ang_Q - ang_P
	if delta > PI:
		delta -= TAU
	elif delta < -PI:
		delta += TAU
	for i in range(EDGE_SEGMENTS + 1):
		var t: float = float(i) / float(EDGE_SEGMENTS)
		var ang: float = ang_P + delta * t
		var x: float = center.x + radius * cos(ang)
		var z: float = center.y + radius * sin(ang)
		pts.append(Vector3(x, 0.005, z))   # tiny lift off disk plane
	return pts


# Unit tangent vector at V on the geodesic from V toward W.
# For a circular arc with center C and radius r, the tangent at V is
# perpendicular to (V - C), oriented toward W. For a diameter, the tangent
# is just (W - V) normalised.
func _poincare_tangent_at(V: Vector3, W: Vector3, geo: Dictionary) -> Vector3:
	if geo["is_diameter"]:
		return (W - V).normalized()
	var center: Vector2 = geo["center"]
	var v2 := Vector2(V.x, V.z) - center
	# Perpendicular (rotate 90°): (-v2.y, v2.x)
	var perp := Vector2(-v2.y, v2.x).normalized()
	# Determine which of ±perp points toward W (along the arc).
	# Use the direction to W projected onto the tangent.
	var to_w := Vector2(W.x, W.z) - Vector2(V.x, V.z)
	if perp.dot(to_w) < 0.0:
		perp = -perp
	return Vector3(perp.x, 0.0, perp.y)


# Disk boundary (unit circle) drawn as a glowing ring; faint disk fill.
func _build_poincare_disk_visuals(disk_radius: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "PoincareDisk"

	# Filled disk (translucent)
	var disk_mi := MeshInstance3D.new()
	var disk_mesh := CylinderMesh.new()
	disk_mesh.top_radius = disk_radius
	disk_mesh.bottom_radius = disk_radius
	disk_mesh.height = 0.001
	disk_mesh.radial_segments = 96
	disk_mesh.rings = 1
	disk_mi.mesh = disk_mesh
	disk_mi.material_override = _surface_mat(SURFACE_COLOR_DISK, true)
	holder.add_child(disk_mi)

	# Boundary ring (line)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_line_mat(SURFACE_BOUNDARY_COLOR, 1.0))
	var steps := 128
	for i in range(steps):
		var a0: float = float(i) * TAU / float(steps)
		var a1: float = float(i + 1) * TAU / float(steps)
		im.surface_add_vertex(Vector3(cos(a0) * disk_radius, 0.003, sin(a0) * disk_radius))
		im.surface_add_vertex(Vector3(cos(a1) * disk_radius, 0.003, sin(a1) * disk_radius))
	im.surface_end()
	var ring_mi := MeshInstance3D.new()
	ring_mi.mesh = im
	holder.add_child(ring_mi)
	return holder


# Angle arc on the disk plane at vertex V, sweeping from tangent ta to tb.
func _disk_angle_arc(V: Vector3, ta: Vector3, tb: Vector3) -> MeshInstance3D:
	var ang: float = acos(clamp(ta.dot(tb), -1.0, 1.0))
	# Sweep from ta toward tb through the interior.
	var perp: Vector3 = (tb - ta * ta.dot(tb))
	if perp.length() < 1.0e-5:
		var empty := MeshInstance3D.new()
		empty.mesh = ImmediateMesh.new()
		return empty
	perp = perp.normalized()
	var pts := PackedVector3Array()
	for i in range(ANGLE_ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ANGLE_ARC_SEGMENTS)
		var phi: float = t * ang
		var dir: Vector3 = ta * cos(phi) + perp * sin(phi)
		pts.append(V + dir * ANGLE_ARC_RADIUS * 0.75 + Vector3(0, 0.006, 0))
	return _polyline_mesh(pts, ANGLE_ARC_COLOR, EDGE_LINE_THICKNESS * 0.75)


# ── Geometry helpers ────────────────────────────────────────────────

# Vertex sphere
func _vertex_sphere(pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = VERTEX_RADIUS
	sm.height = VERTEX_RADIUS * 2.0
	sm.radial_segments = 24
	sm.rings = 12
	mi.mesh = sm
	mi.position = pos
	mi.material_override = _solid_mat(color, 0.45)
	return mi


# Polyline rendered as a sequence of thin cylinders. Better silhouette than
# ImmediateMesh lines for the bold geodesic.
func _polyline_mesh(pts: PackedVector3Array, color: Color, thickness: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "PolyLine"
	if pts.size() < 2:
		return holder
	var mat := _solid_mat(color, 0.50)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg_len: float = a.distance_to(b)
		if seg_len < 1.0e-6:
			continue
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = thickness * 0.5
		cyl.bottom_radius = thickness * 0.5
		cyl.height = seg_len
		cyl.radial_segments = 10
		mi.mesh = cyl
		mi.material_override = mat
		var mid: Vector3 = (a + b) * 0.5
		mi.position = mid
		# Orient: cylinder's default axis is +Y. Rotate so +Y aligns with (b-a).
		var dir: Vector3 = (b - a).normalized()
		mi.basis = _basis_from_y_dir(dir)
		holder.add_child(mi)
	return holder


# Returns a Basis that rotates the unit vector `from` to the unit vector `to`.
# Handles parallel and antiparallel cases.
func _rotation_basis_from_to(from: Vector3, to: Vector3) -> Basis:
	var f: Vector3 = from.normalized()
	var t: Vector3 = to.normalized()
	var d: float = clamp(f.dot(t), -1.0, 1.0)
	if d > 0.99999:
		return Basis.IDENTITY
	if d < -0.99999:
		# 180° — pick any perpendicular axis
		var perp: Vector3
		if abs(f.x) < 0.9:
			perp = Vector3.RIGHT
		else:
			perp = Vector3.UP
		var axis: Vector3 = f.cross(perp).normalized()
		return Basis(axis, PI)
	var axis2: Vector3 = f.cross(t).normalized()
	var ang: float = acos(d)
	return Basis(axis2, ang)


# Build a basis whose +Y axis points along `dir`. Picks a reasonable X axis.
func _basis_from_y_dir(dir: Vector3) -> Basis:
	var y: Vector3 = dir.normalized()
	# Pick an arbitrary reference axis to cross with.
	var ref: Vector3
	if abs(y.dot(Vector3.UP)) > 0.99:
		ref = Vector3.RIGHT
	else:
		ref = Vector3.UP
	var x: Vector3 = ref.cross(y).normalized()
	var z: Vector3 = y.cross(x).normalized()
	return Basis(x, y, z)


# Make a Label3D for the cell's text annotation.
func _make_label(text: String, world_position: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.pixel_size = 0.002
	label.font_size = 56
	label.outline_size = 10
	label.outline_modulate = LABEL_BG_COLOR
	label.modulate = Color(1.0, 0.98, 0.88)
	label.no_depth_test = true
	label.fixed_size = false
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = world_position
	return label


# Heuristic label placement for the perspective sphere case: place the label
# "below and in front of" the sphere relative to the camera, so it doesn't
# obscure the triangle.
func _label_position_for_perspective(cam_pos: Vector3) -> Vector3:
	# Move along the camera-direction toward origin but offset downward.
	var to_origin: Vector3 = -cam_pos.normalized()
	# Position the label outside the sphere on the camera side, low.
	var lp: Vector3 = cam_pos * 0.55 + Vector3(0, -0.9, 0)
	return lp


# ── Capture + record ───────────────────────────────────────────────

func _capture_and_record(id: String, meta: Dictionary) -> void:
	await create_timer(0.06).timeout
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var cfg_rel := "%s.json" % id
	var config := meta.duplicate(true)
	config["id"] = id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	var entry := {
		"id": id,
		"surface": meta.get("surface", ""),
		"K": meta.get("K", 0),
		"size": meta.get("size", ""),
		"angle_sum_degrees": meta.get("angle_sum_degrees", 0.0),
		"excess_or_defect": meta.get("excess_or_defect", 0.0),
		"notes": meta.get("notes", ""),
		"image": "/triangle-table-gallery/%s" % img_rel,
		"config": "/triangle-table-gallery/%s" % cfg_rel,
		"params": meta,
	}
	_entries.append(entry)
	print("  saved: %s — sum=%.2f°  K=%d  size=%s" %
		[id, meta.get("angle_sum_degrees", 0.0), meta.get("K", 0), meta.get("size", "")])


# ── Notes / per-cell prose ─────────────────────────────────────────

func _sphere_notes(size: String, sum_deg: float, excess_deg: float) -> String:
	match size:
		"small":
			return "Tiny spherical triangle — angle sum %.1f° (excess %.2f°). Small triangles are locally flat; on a small enough patch, even the sphere looks Euclidean." % [sum_deg, excess_deg]
		"medium":
			return "Medium spherical triangle — angle sum %.1f° (excess %.2f°). The excess is now clearly visible; the same triangle that was nearly 180° at small scale has opened up." % [sum_deg, excess_deg]
		"large":
			return "Large spherical triangle — angle sum %.1f° (excess %.2f°). Cover a quarter of the sphere and the angle excess grows accordingly. Excess = (area / R²) · (180°/π)." % [sum_deg, excess_deg]
		_:
			return ""


func _flat_notes(size: String, sum_deg: float) -> String:
	match size:
		"small":
			return "Flat equilateral triangle, small — angle sum %.2f° (target 180°). Size doesn't matter on the plane." % sum_deg
		"medium":
			return "Flat equilateral triangle, medium — angle sum %.2f° (target 180°). Identical to small in every angular respect." % sum_deg
		"large":
			return "Flat equilateral triangle, large — angle sum %.2f° (target 180°). The diagnostic row: same number at every scale. This is what 'K=0' means." % sum_deg
		_:
			return ""


func _poincare_notes(size: String, sum_deg: float, defect_deg: float) -> String:
	match size:
		"small":
			return "Small hyperbolic triangle near disk center — angle sum %.1f° (defect %.2f°). Near the origin the metric is nearly Euclidean; the defect is small." % [sum_deg, defect_deg]
		"medium":
			return "Medium hyperbolic triangle on Poincaré disk — angle sum %.1f° (defect %.2f°). The geodesic arcs curve inward; angles compress. The fifth postulate has failed." % [sum_deg, defect_deg]
		"large":
			return "Large hyperbolic triangle nearing ideal — angle sum %.1f° (defect %.2f°). As vertices approach the boundary the triangle becomes ideal (angle sum → 0). Defect = area." % [sum_deg, defect_deg]
		_:
			return ""
