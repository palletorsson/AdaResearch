extends Node3D
class_name TriangleCurvatureWorkbench

# @identity
# essence: an interactive Gauss-Bonnet workbench — the player turns a slider for Gaussian curvature K and watches the triangle's host surface switch sign with it. At K=0 the triangle sits on a flat cyan grid and its angles sum to exactly π. Push the slider negative and the surface morphs into a Poincaré disk; the same triangle's edges become arcs bowing inward, its angles deflate, and the readout shows a defect. Push positive and the surface inflates into a sphere; the edges balloon into great-circle arcs, the angles fatten, and the readout shows an excess. The defect/excess is the integral of K over the triangle.
# desire: the learner viscerally relocates Euclid's parallel postulate from "truth" to "a setting" — the slider IS Gauss-Bonnet, the surface is the parameter the postulate lives in
# critical_parameter: K — discrete in {-2, -1, -0.5, 0, +0.5, +1, +2}. Drives surface choice, edge geodesic type, angle measurement, and the excess/defect readout
# triggers: _ready() builds slider + surface root + triangle root + readout; _on_slider_changed swaps the surface and re-emits the triangle on it
# emerges: the Theorema Egregium of triangles — angle sum is intrinsic, not extrinsic. The triangle doesn't know it's "in 3D"; it only knows its host's K. The number it reads back is geometry's secret pulse.
# needs: slider_horizontal [present]; ImmediateMesh for triangle edges + angle arcs [present]; SphereMesh / QuadMesh / disk procgen for surfaces [present]; Label3D for readouts [present]; riemann_sum_workbench + shannon_workbench as siblings [present]
# relationships: paired with /triangle-table-gallery's 9 cells (3 surfaces × 3 sizes); sits beside riemann_sphere, hyperbolic_surface, elliptic_surface as their unifying instrument; embodies the foundationscrisis truth "Euclid was one consistent choice among many"
# truth: the parallel postulate is not a fact about lines, it is a setting on the surface they live in. Triangles on a sphere sum to more than 180°; on a disk they sum to less. The slider walks the postulate from "always", to "sometimes", to "never".

## A horizontal workbench for Gauss-Bonnet on a triangle.
##
## One slider drives Gaussian curvature K through seven detents
## {-2, -1, -0.5, 0, +0.5, +1, +2}. As K changes:
##   • the host surface morphs (Poincaré disk for K<0, flat grid for K=0, sphere for K>0)
##   • the triangle's three vertices stay at canonical 30° geodesic separation
##   • the edges become geodesics ON that surface (arcs, lines, or great-circle arcs)
##   • the interior angles are measured and the angle sum (α + β + γ) is shown
##   • the Gauss-Bonnet excess/defect (K · Area_T) appears as the gap from π
##
## The math: Gauss-Bonnet for a geodesic triangle says
##   ∫∫_T K dA  =  (α + β + γ) − π
## i.e. the angle sum exceeds π by exactly the integrated curvature over the
## triangle. For our constant-K surfaces this reduces to
##   K · Area_T  =  (α + β + γ) − π .

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Surface display")
## Where the surface sits relative to the artifact origin.
@export var surface_offset: Vector3 = Vector3(0.0, 1.55, -0.20)
## World-space radius the surface fills. The disk and sphere both fit inside this.
@export var surface_radius: float = 0.42
## Colors keyed to the three regimes — match /triangle-table-gallery palette.
@export var flat_color: Color = Color(0.30, 0.85, 1.0)        # cyan
@export var sphere_color: Color = Color(0.78, 0.45, 1.0)      # violet
@export var disk_color: Color = Color(0.35, 0.55, 1.0)        # blue

@export_group("Triangle")
## Geodesic half-angle each vertex sits at from the surface "north pole" /
## disk center / plane origin. 30° is small enough that all three regimes
## render cleanly inside surface_radius, and large enough that
## excess/defect is visible (~10° at K=±1).
@export var triangle_radius_deg: float = 30.0
## Number of segments per edge — 24 reads as smooth arcs without being heavy.
@export var edge_segments: int = 24
@export var triangle_edge_color: Color = Color(1.0, 0.95, 0.55)
@export var triangle_vertex_color: Color = Color(1.0, 0.6, 0.3)
@export var angle_arc_color: Color = Color(1.0, 0.4, 0.5)
@export var angle_arc_radius: float = 0.05
@export var angle_arc_segments: int = 16
@export var vertex_sphere_radius: float = 0.018

# ── Internal state ────────────────────────────────────────────────────

const SLIDER_SCENE_PATH: String = "res://commons/interactables/slider_horizontal.tscn"
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

# Seven discrete K stops. Order matters — the slider's [0, 1] maps onto these
# left-to-right, so negative K is on the left and positive on the right, which
# matches the disk → flat → sphere visual reading.
const K_STOPS: Array[float] = [-2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0]

var _k_index: int = 3            # default to K=0 (flat) — neutral starting point
var _k: float = 0.0

var _plate_root: Node3D
var _slider: Node                 # SliderHorizontal instance

# Surface — rebuilt every K change. We use a single root we can clear.
var _surface_root: Node3D

# Triangle layer — sits ON the surface and is rebuilt every K change.
var _triangle_root: Node3D

# Readout panel.
var _readout_root: Node3D
var _readout_sum: Label3D
var _readout_excess: Label3D
var _readout_k: Label3D
var _readout_regime: Label3D
var _plate_readout: Label       # 2D-in-3D readout integrated on the console board


# ── Lifecycle ─────────────────────────────────────────────────────────

## Starting K — the critical parameter, settable as DNA (snapped to K_STOPS).
@export var initial_k: float = 0.0

func _ready() -> void:
	var best_i := 0
	var best_d := 1.0e9
	for i in K_STOPS.size():
		var d: float = absf(K_STOPS[i] - initial_k)
		if d < best_d:
			best_d = d
			best_i = i
	_k_index = best_i
	_k = K_STOPS[_k_index]
	_build_plate_and_slider()
	_build_surface_and_triangle_roots()
	_refresh_all()


# ── Slider detents ────────────────────────────────────────────────────

func _normalized_to_k_index(norm: float) -> int:
	var stops: int = K_STOPS.size()
	var idx: int = int(round(norm * float(stops - 1)))
	return clampi(idx, 0, stops - 1)


func _k_index_to_normalized(idx: int) -> float:
	var stops: int = K_STOPS.size()
	return float(idx) / float(stops - 1)


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole — houses the plate (seated K slider) AND the
	# live readout as a 2D-in-3D screen on the board (replaces the floating card).
	_plate_root = InterfacePresets.build("workbench", "Triangle Curvature", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)

	_plate_readout = _plate_root.add_readout("")

	_slider = _plate_root.add_slider("K  Gaussian curvature", "K  Gaussian curvature")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _k_index_to_normalized(_k_index))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var k_norm: Variant = _slider.call("get_normalized_value")
	var new_idx: int = _normalized_to_k_index(float(k_norm))
	if new_idx == _k_index:
		return
	_k_index = new_idx
	_k = K_STOPS[_k_index]
	# Throttled refresh — keep the grab loop free (see _process).
	_viz_dirty = true


var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Surface + triangle roots ──────────────────────────────────────────

func _build_surface_and_triangle_roots() -> void:
	_surface_root = Node3D.new()
	_surface_root.name = "Surface"
	_surface_root.position = surface_offset
	add_child(_surface_root)

	_triangle_root = Node3D.new()
	_triangle_root.name = "Triangle"
	_triangle_root.position = surface_offset
	add_child(_triangle_root)


func _clear_node(node: Node3D) -> void:
	if node == null:
		return
	for c in node.get_children():
		c.queue_free()


# ── Surface builders (per regime) ─────────────────────────────────────

func _build_flat_surface() -> void:
	# A translucent cyan grid plane.
	var disk := MeshInstance3D.new()
	disk.name = "FlatPlane"
	var qm := QuadMesh.new()
	qm.size = Vector2(surface_radius * 2.0, surface_radius * 2.0)
	disk.mesh = qm
	# Lay the quad flat (its default normal is +z; we want the triangle on top).
	disk.rotation_degrees.x = -90.0
	disk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(flat_color.r, flat_color.g, flat_color.b, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = flat_color
	mat.emission_energy_multiplier = 0.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disk.material_override = mat
	_surface_root.add_child(disk)

	# Grid lines — 9 lines each way at 0.1·r spacing, drawn as a single
	# ImmediateMesh in the plane's local frame.
	var grid_mesh := ImmediateMesh.new()
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var n_lines: int = 9
	for i in range(n_lines + 1):
		var t: float = float(i) / float(n_lines)
		var u: float = -surface_radius + t * 2.0 * surface_radius
		grid_mesh.surface_add_vertex(Vector3(u, 0.001, -surface_radius))
		grid_mesh.surface_add_vertex(Vector3(u, 0.001, surface_radius))
		grid_mesh.surface_add_vertex(Vector3(-surface_radius, 0.001, u))
		grid_mesh.surface_add_vertex(Vector3(surface_radius, 0.001, u))
	grid_mesh.surface_end()

	var grid_inst := MeshInstance3D.new()
	grid_inst.name = "FlatGrid"
	grid_inst.mesh = grid_mesh
	grid_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(flat_color, 0.55)
	grid_mat.emission_enabled = true
	grid_mat.emission = flat_color
	grid_mat.emission_energy_multiplier = 0.6
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_inst.material_override = grid_mat
	_surface_root.add_child(grid_inst)


func _build_sphere_surface() -> void:
	# Translucent violet sphere. The sphere "K = +1" implies radius = 1 in
	# math units; we display it at surface_radius in world units. Edges and
	# vertices are mapped onto the sphere of this display radius.
	var sphere_inst := MeshInstance3D.new()
	sphere_inst.name = "Sphere"
	var sm := SphereMesh.new()
	sm.radius = surface_radius
	sm.height = surface_radius * 2.0
	sm.radial_segments = 48
	sm.rings = 24
	sphere_inst.mesh = sm
	sphere_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(sphere_color.r, sphere_color.g, sphere_color.b, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = sphere_color
	mat.emission_energy_multiplier = 0.35
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_FRONT  # show back-faces of the sphere
	sphere_inst.material_override = mat
	_surface_root.add_child(sphere_inst)

	# Latitude / longitude lines — light grid for reference.
	var grid_mesh := ImmediateMesh.new()
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	# Equator.
	for i in range(73):
		var t: float = float(i) / 72.0
		var a: float = t * TAU
		grid_mesh.surface_add_vertex(Vector3(cos(a) * surface_radius, 0.0, sin(a) * surface_radius))
	grid_mesh.surface_end()
	# Prime meridian.
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(73):
		var t2: float = float(i) / 72.0
		var a2: float = t2 * TAU
		grid_mesh.surface_add_vertex(Vector3(0.0, sin(a2) * surface_radius, cos(a2) * surface_radius))
	grid_mesh.surface_end()
	# Cross meridian.
	grid_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(73):
		var t3: float = float(i) / 72.0
		var a3: float = t3 * TAU
		grid_mesh.surface_add_vertex(Vector3(cos(a3) * surface_radius, sin(a3) * surface_radius, 0.0))
	grid_mesh.surface_end()

	var grid_inst := MeshInstance3D.new()
	grid_inst.name = "SphereGrid"
	grid_inst.mesh = grid_mesh
	grid_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(sphere_color, 0.45)
	grid_mat.emission_enabled = true
	grid_mat.emission = sphere_color
	grid_mat.emission_energy_multiplier = 0.5
	grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_inst.material_override = grid_mat
	_surface_root.add_child(grid_inst)


func _build_disk_surface() -> void:
	# Translucent blue Poincaré disk — drawn as a flat circle.
	# The disk boundary is the "circle at infinity"; we render it as a bright
	# ring so the player can see where space ends.
	var disk_inst := MeshInstance3D.new()
	disk_inst.name = "PoincareDisk"
	# Use a torus mesh oriented flat for a ring/halo + a filled inner quad.
	var disk_fill := MeshInstance3D.new()
	disk_fill.name = "DiskFill"
	var qm := QuadMesh.new()
	qm.size = Vector2(surface_radius * 2.0, surface_radius * 2.0)
	disk_fill.mesh = qm
	disk_fill.rotation_degrees.x = -90.0
	disk_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(disk_color.r, disk_color.g, disk_color.b, 0.12)
	fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_mat.emission_enabled = true
	fill_mat.emission = disk_color
	fill_mat.emission_energy_multiplier = 0.4
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	disk_fill.material_override = fill_mat
	_surface_root.add_child(disk_fill)

	# Boundary ring — bright. Hyperbolic geodesics terminate orthogonal to it.
	var ring_mesh := ImmediateMesh.new()
	ring_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var ring_segments: int = 96
	for i in range(ring_segments + 1):
		var t: float = float(i) / float(ring_segments)
		var a: float = t * TAU
		ring_mesh.surface_add_vertex(Vector3(cos(a) * surface_radius, 0.002, sin(a) * surface_radius))
	ring_mesh.surface_end()
	disk_inst.mesh = ring_mesh

	disk_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = disk_color
	ring_mat.emission_enabled = true
	ring_mat.emission = disk_color
	ring_mat.emission_energy_multiplier = 1.8
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disk_inst.material_override = ring_mat
	_surface_root.add_child(disk_inst)

	# Inner concentric guides — half-radius and quarter-radius hints.
	var guide_mesh := ImmediateMesh.new()
	for ring_t in [0.33, 0.66]:
		guide_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(73):
			var t2: float = float(i) / 72.0
			var a2: float = t2 * TAU
			var r2: float = surface_radius * float(ring_t)
			guide_mesh.surface_add_vertex(Vector3(cos(a2) * r2, 0.001, sin(a2) * r2))
		guide_mesh.surface_end()
	var guide_inst := MeshInstance3D.new()
	guide_inst.name = "DiskGuides"
	guide_inst.mesh = guide_mesh
	guide_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var guide_mat := StandardMaterial3D.new()
	guide_mat.albedo_color = Color(disk_color, 0.35)
	guide_mat.emission_enabled = true
	guide_mat.emission = disk_color
	guide_mat.emission_energy_multiplier = 0.6
	guide_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	guide_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	guide_inst.material_override = guide_mat
	_surface_root.add_child(guide_inst)


# ── Triangle (geodesic edges on the active surface) ───────────────────

# Returns the three triangle vertex positions in surface-local space.
# Vertices sit at 30° geodesic separation from a center "north pole" (sphere)
# / disk center / origin (plane), equispaced at 120° around it.
func _triangle_vertices() -> Array:
	var verts: Array = []
	var theta: float = deg_to_rad(triangle_radius_deg)
	for k in range(3):
		var phi: float = float(k) * TAU / 3.0  # 0°, 120°, 240°
		var p: Vector3
		if _k > 0.0:
			# Sphere: from north pole (0, R, 0), rotate by theta toward
			# longitude phi. Use spherical coords.
			var R: float = surface_radius
			p = Vector3(
				R * sin(theta) * cos(phi),
				R * cos(theta),
				R * sin(theta) * sin(phi)
			)
		elif _k < 0.0:
			# Poincaré disk: vertices on the flat (xz) plane. Place at
			# euclidean radius tanh(theta_h / 2) where theta_h is hyperbolic
			# half-angle from origin. We use Euclidean radius proportional
			# to triangle_radius_deg so visible size matches the sphere case.
			# Specifically: r_euc = triangle_radius_deg / 90 * 0.6 · R.
			# That keeps the triangle inside the disk for our K range.
			var r_euc: float = surface_radius * 0.55 * (triangle_radius_deg / 30.0)
			r_euc = clampf(r_euc, 0.0, surface_radius * 0.9)
			p = Vector3(r_euc * cos(phi), 0.002, r_euc * sin(phi))
		else:
			# Flat plane: vertices on a Euclidean circle, in the xz plane.
			var r_flat: float = surface_radius * 0.55 * (triangle_radius_deg / 30.0)
			p = Vector3(r_flat * cos(phi), 0.002, r_flat * sin(phi))
		verts.append(p)
	return verts


# Samples an edge between two vertices, returning N+1 points along the
# geodesic on the active surface.
func _edge_samples(a: Vector3, b: Vector3, n: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(n + 1)
	if _k > 0.0:
		# Sphere great-circle slerp through the sphere's center.
		var R: float = surface_radius
		var ua: Vector3 = a.normalized()
		var ub: Vector3 = b.normalized()
		var dot: float = clampf(ua.dot(ub), -1.0, 1.0)
		var omega: float = acos(dot)
		var sin_omega: float = sin(omega)
		if sin_omega < 1e-6:
			# Degenerate — fallback to lerp.
			for i in range(n + 1):
				var t: float = float(i) / float(n)
				out[i] = a.lerp(b, t)
		else:
			for i in range(n + 1):
				var t2: float = float(i) / float(n)
				var w1: float = sin((1.0 - t2) * omega) / sin_omega
				var w2: float = sin(t2 * omega) / sin_omega
				var v: Vector3 = (ua * w1 + ub * w2).normalized() * R
				out[i] = v
	elif _k < 0.0:
		# Poincaré disk geodesic: arc of a circle orthogonal to the unit disk
		# boundary, in the xz plane. Work in 2D, then lift y=0.
		# Vertices a2, b2 in unit-disk coords (divide by surface_radius).
		var a2: Vector2 = Vector2(a.x, a.z) / surface_radius
		var b2: Vector2 = Vector2(b.x, b.z) / surface_radius
		# Find the center C of the circle that passes through a2 and b2 and
		# meets the unit circle at right angles. Solution: invert a2 across
		# the unit circle to get a2' = a2 / |a2|^2; the geodesic circle passes
		# through a2, b2, and a2'. Use the standard formula
		#   C = (|a|^2 + 1) · (b - a) / (2 · (a×b))? — too brittle. Instead
		# solve directly via the system "C lies on perpendicular bisectors and
		# |C|^2 - 1 = |C - a|^2", which simplifies to
		#   2·C·a = |a|^2 + 1  and  2·C·b = |b|^2 + 1.
		var la2: float = a2.length_squared()
		var lb2: float = b2.length_squared()
		# Solve the 2x2 linear system for C.
		var det: float = 2.0 * (a2.x * b2.y - a2.y * b2.x)
		var is_diameter: bool = abs(det) < 1e-5
		if is_diameter:
			# Degenerate — vertices collinear with origin → geodesic is the
			# diameter line. Just sample linearly.
			for i in range(n + 1):
				var t3: float = float(i) / float(n)
				var pt2: Vector2 = a2.lerp(b2, t3)
				out[i] = Vector3(pt2.x * surface_radius, 0.003, pt2.y * surface_radius)
		else:
			var cx: float = ((la2 + 1.0) * b2.y - (lb2 + 1.0) * a2.y) / det
			var cy: float = ((lb2 + 1.0) * a2.x - (la2 + 1.0) * b2.x) / det
			var center: Vector2 = Vector2(cx, cy)
			var ra: Vector2 = a2 - center
			var rb: Vector2 = b2 - center
			var ang_a: float = atan2(ra.y, ra.x)
			var ang_b: float = atan2(rb.y, rb.x)
			# Pick the short way around (the arc that stays inside the disk).
			var dang: float = ang_b - ang_a
			while dang > PI:
				dang -= TAU
			while dang < -PI:
				dang += TAU
			var radius_arc: float = ra.length()
			for i in range(n + 1):
				var t4: float = float(i) / float(n)
				var ang: float = ang_a + t4 * dang
				var p2: Vector2 = center + Vector2(cos(ang), sin(ang)) * radius_arc
				out[i] = Vector3(p2.x * surface_radius, 0.003, p2.y * surface_radius)
	else:
		# Flat: straight line lerp.
		for i in range(n + 1):
			var tf: float = float(i) / float(n)
			out[i] = a.lerp(b, tf)
	return out


# Compute the interior angle at a vertex v, between the edges leading to
# u (previous vertex) and w (next vertex). The angle is the angle between
# the geodesic tangents at v.
func _interior_angle(v: Vector3, u: Vector3, w: Vector3) -> float:
	# Tangent vectors at v along each edge — approximated by the first segment
	# of the geodesic toward u and toward w.
	var u_samples: PackedVector3Array = _edge_samples(v, u, 2)
	var w_samples: PackedVector3Array = _edge_samples(v, w, 2)
	if u_samples.size() < 2 or w_samples.size() < 2:
		return 0.0
	var t_to_u: Vector3 = (u_samples[1] - v)
	var t_to_w: Vector3 = (w_samples[1] - v)
	if _k > 0.0:
		# On the sphere, project tangents into the tangent plane at v.
		var n_v: Vector3 = v.normalized()
		t_to_u = t_to_u - n_v * t_to_u.dot(n_v)
		t_to_w = t_to_w - n_v * t_to_w.dot(n_v)
	t_to_u = t_to_u.normalized()
	t_to_w = t_to_w.normalized()
	var dot: float = clampf(t_to_u.dot(t_to_w), -1.0, 1.0)
	return acos(dot)


# Compute the geometric area of the triangle T on the active surface, in
# square-radians (the unit appropriate for K · Area = excess).
func _triangle_area(verts: Array) -> float:
	if _k > 0.0:
		# Spherical excess directly gives the area-on-unit-sphere via
		# Gauss-Bonnet (E = α+β+γ - π = K·Area). So we don't actually need to
		# compute area independently — the formula IS the area, given K=1.
		# For display we use spherical excess as the "intrinsic area" and
		# scale by 1/K_abs to get the patch area in K-radians².
		# We avoid that here and let the readout call Gauss-Bonnet directly.
		var alpha: float = _interior_angle(verts[0], verts[2], verts[1])
		var beta: float = _interior_angle(verts[1], verts[0], verts[2])
		var gamma: float = _interior_angle(verts[2], verts[1], verts[0])
		var area_unit_sphere: float = (alpha + beta + gamma) - PI
		# K · Area_T = excess  →  Area_T = excess / K   (works for K≠0)
		return area_unit_sphere / max(abs(_k), 1e-6)
	elif _k < 0.0:
		var alpha2: float = _interior_angle(verts[0], verts[2], verts[1])
		var beta2: float = _interior_angle(verts[1], verts[0], verts[2])
		var gamma2: float = _interior_angle(verts[2], verts[1], verts[0])
		var defect: float = PI - (alpha2 + beta2 + gamma2)
		# K is negative, so K·Area = -defect → Area = defect / |K|.
		return defect / max(abs(_k), 1e-6)
	else:
		# Flat: planar triangle area via cross product (sq meters in our
		# display space). For the gallery we just report 0 excess; area is
		# decorative.
		var ab: Vector3 = verts[1] - verts[0]
		var ac: Vector3 = verts[2] - verts[0]
		return ab.cross(ac).length() * 0.5


# ── Triangle rendering ────────────────────────────────────────────────

func _build_triangle() -> void:
	var verts: Array = _triangle_vertices()

	# 1) Vertex spheres.
	for i in range(3):
		var v_inst := MeshInstance3D.new()
		v_inst.name = "Vertex_%d" % i
		var sm := SphereMesh.new()
		sm.radius = vertex_sphere_radius
		sm.height = vertex_sphere_radius * 2.0
		sm.radial_segments = 16
		sm.rings = 8
		v_inst.mesh = sm
		v_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var v_mat := StandardMaterial3D.new()
		v_mat.albedo_color = triangle_vertex_color
		v_mat.emission_enabled = true
		v_mat.emission = triangle_vertex_color
		v_mat.emission_energy_multiplier = 2.0
		v_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		v_inst.material_override = v_mat
		v_inst.position = verts[i]
		_triangle_root.add_child(v_inst)

	# 2) Edges — three geodesic polylines.
	var edge_mesh := ImmediateMesh.new()
	for k in range(3):
		var a: Vector3 = verts[k]
		var b: Vector3 = verts[(k + 1) % 3]
		var samples: PackedVector3Array = _edge_samples(a, b, edge_segments)
		edge_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in samples:
			edge_mesh.surface_add_vertex(p)
		edge_mesh.surface_end()

	var edge_inst := MeshInstance3D.new()
	edge_inst.name = "Edges"
	edge_inst.mesh = edge_mesh
	edge_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = triangle_edge_color
	edge_mat.emission_enabled = true
	edge_mat.emission = triangle_edge_color
	edge_mat.emission_energy_multiplier = 1.8
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	edge_inst.material_override = edge_mat
	_triangle_root.add_child(edge_inst)

	# 3) Angle arcs at each vertex — small arcs from one outgoing edge tangent
	#    to the other, visualising the interior angle.
	var arc_mesh := ImmediateMesh.new()
	for k in range(3):
		var v: Vector3 = verts[k]
		var u: Vector3 = verts[(k + 2) % 3]
		var w: Vector3 = verts[(k + 1) % 3]
		var u_samples2: PackedVector3Array = _edge_samples(v, u, 2)
		var w_samples2: PackedVector3Array = _edge_samples(v, w, 2)
		if u_samples2.size() < 2 or w_samples2.size() < 2:
			continue
		var t_u: Vector3 = (u_samples2[1] - v)
		var t_w: Vector3 = (w_samples2[1] - v)
		var normal: Vector3 = Vector3.UP
		if _k > 0.0:
			normal = v.normalized()
			# Project tangents into tangent plane.
			t_u = t_u - normal * t_u.dot(normal)
			t_w = t_w - normal * t_w.dot(normal)
		t_u = t_u.normalized()
		t_w = t_w.normalized()
		# Build an orthonormal basis (e1, e2) in the tangent plane, with
		# e1 = t_u, e2 perpendicular to it in the tangent plane on the side
		# of t_w.
		var e1: Vector3 = t_u
		var e2: Vector3 = (t_w - e1 * t_w.dot(e1))
		if e2.length() < 1e-6:
			continue
		e2 = e2.normalized()
		var ang: float = atan2(t_w.dot(e2), t_w.dot(e1))
		if ang < 0.0:
			ang += TAU
		# Clamp to [0, π] so we always draw the interior side.
		if ang > PI:
			ang = TAU - ang
			# swap e2 sign so the sweep goes the right way
			e2 = -e2
		arc_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(angle_arc_segments + 1):
			var t2: float = float(i) / float(angle_arc_segments)
			var theta: float = t2 * ang
			var pt: Vector3 = v + (e1 * cos(theta) + e2 * sin(theta)) * angle_arc_radius
			arc_mesh.surface_add_vertex(pt)
		arc_mesh.surface_end()

	var arc_inst := MeshInstance3D.new()
	arc_inst.name = "AngleArcs"
	arc_inst.mesh = arc_mesh
	arc_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var arc_mat := StandardMaterial3D.new()
	arc_mat.albedo_color = angle_arc_color
	arc_mat.emission_enabled = true
	arc_mat.emission = angle_arc_color
	arc_mat.emission_energy_multiplier = 1.5
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_inst.material_override = arc_mat
	_triangle_root.add_child(arc_inst)


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_readout_root.position = Vector3(surface_radius + 0.18, plate_height + 0.65, plate_offset_z + 0.05)
	add_child(_readout_root)

	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.50, 0.36)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.25, 0.0, -0.005)
	_readout_root.add_child(card)

	# α + β + γ — the headline.
	_readout_sum = Label3D.new()
	_readout_sum.name = "ReadoutSum"
	_readout_sum.font_size = 40
	_readout_sum.outline_size = 5
	_readout_sum.pixel_size = 0.001
	_readout_sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_sum.modulate = Color(1.0, 0.95, 0.55)
	_readout_sum.position = Vector3(0.02, 0.135, 0.0)
	_readout_root.add_child(_readout_sum)

	# Excess / defect.
	_readout_excess = Label3D.new()
	_readout_excess.name = "ReadoutExcess"
	_readout_excess.font_size = 24
	_readout_excess.outline_size = 3
	_readout_excess.pixel_size = 0.001
	_readout_excess.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_excess.modulate = Color(1.0, 0.4, 0.5)
	_readout_excess.position = Vector3(0.02, 0.055, 0.0)
	_readout_root.add_child(_readout_excess)

	# K value.
	_readout_k = Label3D.new()
	_readout_k.name = "ReadoutK"
	_readout_k.font_size = 22
	_readout_k.outline_size = 3
	_readout_k.pixel_size = 0.001
	_readout_k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_k.modulate = Color(0.7, 0.85, 1.0)
	_readout_k.position = Vector3(0.02, -0.015, 0.0)
	_readout_root.add_child(_readout_k)

	# Regime word: hyperbolic / flat / elliptic.
	_readout_regime = Label3D.new()
	_readout_regime.name = "ReadoutRegime"
	_readout_regime.font_size = 22
	_readout_regime.outline_size = 3
	_readout_regime.pixel_size = 0.001
	_readout_regime.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_regime.modulate = Color(0.85, 1.0, 0.85)
	_readout_regime.position = Vector3(0.02, -0.075, 0.0)
	_readout_root.add_child(_readout_regime)


func _refresh_readout(verts: Array) -> void:
	if _plate_readout == null:
		return
	var alpha: float = _interior_angle(verts[0], verts[2], verts[1])
	var beta: float = _interior_angle(verts[1], verts[0], verts[2])
	var gamma: float = _interior_angle(verts[2], verts[1], verts[0])
	var sum_deg: float = rad_to_deg(alpha + beta + gamma)
	var excess: float = sum_deg - 180.0
	var regime: String
	if _k > 0.0:
		regime = "elliptic · excess +%.1f°" % excess
	elif _k < 0.0:
		regime = "hyperbolic · defect %.1f°" % excess
	else:
		regime = "flat · Euclidean"
	_plate_readout.text = "α+β+γ = %.1f°\nK=%+0.1f · %s" % [sum_deg, _k, regime]


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_clear_node(_surface_root)
	_clear_node(_triangle_root)

	# Surface.
	if _k > 0.0:
		_build_sphere_surface()
	elif _k < 0.0:
		_build_disk_surface()
	else:
		_build_flat_surface()

	# Triangle (uses _k internally to pick geodesics).
	_build_triangle()

	# Readout (needs the same vertex set).
	_refresh_readout(_triangle_vertices())


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_k"):
		var requested_k: float = float(config_data["initial_k"])
		# Snap to nearest detent.
		var best_idx: int = 0
		var best_d: float = 99999.0
		for i in range(K_STOPS.size()):
			var d: float = abs(K_STOPS[i] - requested_k)
			if d < best_d:
				best_d = d
				best_idx = i
		_k_index = best_idx
		_k = K_STOPS[_k_index]
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _k_index_to_normalized(_k_index))
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("triangle_radius_deg"):
		triangle_radius_deg = float(config_data["triangle_radius_deg"])
		_refresh_all()
