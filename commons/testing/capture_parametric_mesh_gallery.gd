## One-off sweep capture for the parametric-mesh DNA gallery.
##
## Instances cylinder_radials_rings.tscn, torus_radials_rings.tscn, and
## sphere.tscn (plus an inline CylinderMesh-with-top_radius=0 cone) at a
## range of (radial_segments, rings) values, captures each combination from
## a consistent camera angle, and saves <id>.png + <id>.json pairs.
##
## Visual goals (2026-05-19 rewrite):
##   - Square 1024×1024 SubViewport with MSAA 8x + FXAA for crisp edges
##   - Three-quarter view from above (38° pitch) so the polygonal top cap
##     of cylinders/cones is visible alongside the side faces — the
##     polygon-ness is most legible at thumbnail size from this angle
##   - Each subject gets a SOLID-color body material override (kills the
##     SimpleGrid shader's diagonal triangulation noise from v1) plus an
##     overlay wireframe ImmediateMesh that draws ONLY the parametric
##     segment edges (radial connectors + axial connectors) — so what you
##     count is the true `radial_segments` / `ring_segments` parameter,
##     not whatever triangulation SurfaceTool ended up with
##   - Saturated body colors (per-primitive), bright white wireframe lines,
##     near-black background, key + fill + rim lighting for silhouette pop
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_parametric_mesh_gallery.gd \
##     -- --out=user://parametric_mesh_gallery
##
## Output: <out>/{cylinder_r3,...,torus_s32,sphere_r3,...,cone_r32}.png
##         + manifest.json
extends SceneTree

const CYL_SCENE: String = "res://commons/primitives/cylinder/cylinder_radials_rings.tscn"
const TORUS_SCENE: String = "res://commons/primitives/torus/torus_radials_rings.tscn"
const SPHERE_SCENE: String = "res://commons/primitives/sphere/sphere.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const WIRE_COLOR: Color = Color(1.0, 1.0, 1.0)
const CYL_BODY_COLOR: Color = Color(0.93, 0.32, 0.42)        # saturated red-magenta
const TORUS_BODY_COLOR: Color = Color(0.36, 0.62, 1.0)       # saturated blue
const SPHERE_BODY_COLOR: Color = Color(0.62, 0.85, 0.40)     # saturated green
const CONE_BODY_COLOR: Color = Color(0.98, 0.72, 0.28)       # amber

var _output_dir: String = "user://parametric_mesh_gallery"
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
	# ── SubViewport — explicit 1024×1024 square with MSAA 8x ────────
	# Isolated World3D so the project's autoload environments / sky /
	# managers don't bleed into our background colour or lighting.
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	# ── Environment — dark BG, soft ambient, filmic tonemap ─────────
	# Set directly on the isolated World3D so the project's other
	# WorldEnvironment nodes can't override it.
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

	# ── Lighting trio: key + fill + rim ─────────────────────────────
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

	# Rim light from behind/above for silhouette pop
	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25, 170, 0)
	rim_light.light_energy = 1.1
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	rim_light.shadow_enabled = false
	_viewport.add_child(rim_light)

	# ── Camera — three-quarter from above, square framing ──────────
	# 38° pitch shows the polygonal TOP CAP of cylinders/cones (the most
	# legible "count the facets" signal at thumbnail scale) while keeping
	# enough of the side faces visible for the silhouette to read.
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
	# look_at must be called after add_child (node must be in tree).
	_camera.look_at(focus, Vector3.UP)

	# Holder for the currently-captured subject + overlay wireframe
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep ───────────────────────────────────────────────────────
	# Primary axis: number of radial segments. Eight cells, from "obvious
	# polygon" (3) to "looks smooth" (32). This is the central pedagogical
	# claim of these primitives' @identity: a smooth-looking curved surface
	# is a lie, and you can dial the lie back into legibility.
	var radial_values := [3, 4, 6, 8, 12, 16, 24, 32]

	# ── Cylinder ────────────────────────────────────────────────────
	var cyl_scene = load(CYL_SCENE)
	if not cyl_scene:
		push_error("Cylinder scene missing")
		quit(1)
		return
	for r in radial_values:
		var node = cyl_scene.instantiate()
		node.radial_segments = r
		node.rings = 1
		node.height = 1.0
		node.radius = 0.5
		node.base_color = CYL_BODY_COLOR
		_scene_holder.add_child(node)
		await create_timer(0.05).timeout
		_apply_solid_material(node, CYL_BODY_COLOR)
		var cyl_wire := _build_cylinder_wireframe(r, 1, 0.5, 1.0)
		node.add_child(cyl_wire)
		await create_timer(0.05).timeout
		await _capture_and_record("cylinder_r%d" % r, {
			"primitive": "cylinder",
			"radial_segments": r,
			"rings": 1,
			"notes": _cyl_notes(r),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Torus ───────────────────────────────────────────────────────
	# Vary ring_segments (tube cross-section resolution), hold rings = 32
	# so the donut PATH is always perceptually smooth and only the TUBE
	# changes from square to round.
	var torus_scene = load(TORUS_SCENE)
	if not torus_scene:
		push_error("Torus scene missing")
		quit(1)
		return
	for r in radial_values:
		var node = torus_scene.instantiate()
		node.rings = 32
		node.ring_segments = r
		node.inner_radius = 0.18
		node.outer_radius = 0.5
		node.base_color = TORUS_BODY_COLOR
		node.wireframe_color = WIRE_COLOR
		_scene_holder.add_child(node)
		# Tilt the torus 30° around X so the tube cross-section is visible
		# from the camera (otherwise we'd be looking straight down the hole).
		node.rotation_degrees = Vector3(30.0, 0.0, 0.0)
		await create_timer(0.05).timeout
		_apply_solid_material(node, TORUS_BODY_COLOR)
		var major_radius: float = (float(node.inner_radius) + float(node.outer_radius)) * 0.5  # 0.34
		var tube_radius: float = (float(node.outer_radius) - float(node.inner_radius)) * 0.5  # 0.16
		var tor_wire: MeshInstance3D = _build_torus_wireframe(32, r, major_radius, tube_radius)
		# Parent the wireframe under the body so transforms compose naturally.
		node.add_child(tor_wire)
		await create_timer(0.05).timeout
		await _capture_and_record("torus_s%d" % r, {
			"primitive": "torus",
			"ring_segments": r,
			"rings": 32,
			"notes": _torus_notes(r),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Sphere ──────────────────────────────────────────────────────
	# Vary radial_segments (longitudes), hold rings = 16 (latitudes)
	# so the curvature reads consistently and only the equator-resolution
	# changes from bipyramid-ish to perceptually round.
	var sphere_scene = load(SPHERE_SCENE)
	if not sphere_scene:
		push_error("Sphere scene missing")
		quit(1)
		return
	for r in radial_values:
		var node = sphere_scene.instantiate()
		node.radial_segments = r
		node.rings = 16
		node.radius = 0.5
		node.base_color = SPHERE_BODY_COLOR
		node.wireframe_color = WIRE_COLOR
		_scene_holder.add_child(node)
		await create_timer(0.05).timeout
		_apply_solid_material(node, SPHERE_BODY_COLOR)
		var sph_wire := _build_sphere_wireframe(r, 16, 0.5)
		node.add_child(sph_wire)
		await create_timer(0.05).timeout
		await _capture_and_record("sphere_r%d" % r, {
			"primitive": "sphere",
			"radial_segments": r,
			"rings": 16,
			"notes": _sphere_notes(r),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Cone ────────────────────────────────────────────────────────
	# Built inline as a CylinderMesh with top_radius = 0. Wireframe overlay
	# uses the cylinder wireframe builder with top_radius = 0, which
	# collapses the top ring to a single apex point.
	for r in radial_values:
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = r
		mesh.rings = 1
		node.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = CONE_BODY_COLOR
		mat.roughness = 0.55
		mat.metallic = 0.0
		mat.emission_enabled = true
		mat.emission = CONE_BODY_COLOR
		mat.emission_energy_multiplier = 0.15
		node.material_override = mat
		_scene_holder.add_child(node)
		await create_timer(0.05).timeout
		var cone_wire := _build_cone_wireframe(r, 0.5, 1.0)
		node.add_child(cone_wire)
		await create_timer(0.05).timeout
		await _capture_and_record("cone_r%d" % r, {
			"primitive": "cone",
			"radial_segments": r,
			"rings": 1,
			"top_radius": 0.0,
			"bottom_radius": 0.5,
			"height": 1.0,
			"notes": _cone_notes(r),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# Write manifest.json
	var manifest := {
		"version": 2,
		"description": "Parameter sweep for the radials-rings family of primitives. Each row holds the secondary axis constant and varies the segment count from 3 (clearly faceted) to 32 (perceptually smooth). Captured at 1024×1024 with MSAA 8x; solid-color body with overlay wireframe drawing only the parametric segment edges, so what the eye counts is the true `radial_segments` / `ring_segments` parameter rather than internal triangulation.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"fov": 38.0, "yaw_deg": 28.0, "pitch_deg": 35.0, "distance": 2.4},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Helpers ─────────────────────────────────────────────────────────

func _apply_solid_material(node: Node3D, color: Color) -> void:
	# Override every MeshInstance3D below `node` with a solid, flat-shaded
	# material so the body reads as a single silhouette color. The
	# segment count is then conveyed by the polygonal contour itself plus
	# the overlay wireframe — clean signal at thumbnail scale.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.15
	for child in _iter_meshes(node):
		child.material_override = mat


func _iter_meshes(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _make_wire_material() -> StandardMaterial3D:
	# Wireframe wants to sit cleanly ON the silhouette without showing the
	# back-side lines (which clutter and lie about the surface). We use
	# normal depth test (so back lines are hidden by the opaque body)
	# AND a slight forward bump on each wireframe vertex (handled in the
	# builders) to avoid z-fighting with the body's front faces.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = WIRE_COLOR
	mat.emission_enabled = true
	mat.emission = WIRE_COLOR
	mat.emission_energy_multiplier = 0.6
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	return mat


# Cylinder wireframe — only the parametric edges. The top/bottom polygons
# and the vertical axial connectors. No quad-split diagonals.
# A small radial bump keeps the wires from z-fighting with the body.
func _build_cylinder_wireframe(radial_segments: int, rings: int, radius: float, height: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material())
	var half_h: float = height / 2.0
	var num_levels: int = rings + 1
	var bump: float = 1.005
	# Horizontal ring polygons at each level
	for level in range(num_levels):
		var y: float = lerpf(-half_h, half_h, float(level) / float(rings))
		for i in range(radial_segments):
			var a0: float = float(i) * TAU / float(radial_segments)
			var a1: float = float(i + 1) * TAU / float(radial_segments)
			im.surface_add_vertex(Vector3(cos(a0) * radius * bump, y, sin(a0) * radius * bump))
			im.surface_add_vertex(Vector3(cos(a1) * radius * bump, y, sin(a1) * radius * bump))
	# Axial verticals
	for i in range(radial_segments):
		var a: float = float(i) * TAU / float(radial_segments)
		var x: float = cos(a) * radius * bump
		var z: float = sin(a) * radius * bump
		im.surface_add_vertex(Vector3(x, -half_h, z))
		im.surface_add_vertex(Vector3(x, half_h, z))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "CylinderWire"
	return mi


# Cone wireframe — the bottom polygon and the slant edges from base to apex.
func _build_cone_wireframe(radial_segments: int, radius: float, height: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material())
	var half_h: float = height / 2.0
	var bump: float = 1.005
	# Bottom ring polygon
	for i in range(radial_segments):
		var a0: float = float(i) * TAU / float(radial_segments)
		var a1: float = float(i + 1) * TAU / float(radial_segments)
		im.surface_add_vertex(Vector3(cos(a0) * radius * bump, -half_h, sin(a0) * radius * bump))
		im.surface_add_vertex(Vector3(cos(a1) * radius * bump, -half_h, sin(a1) * radius * bump))
	# Slant edges
	var apex: Vector3 = Vector3(0.0, half_h, 0.0)
	for i in range(radial_segments):
		var a: float = float(i) * TAU / float(radial_segments)
		im.surface_add_vertex(Vector3(cos(a) * radius * bump, -half_h, sin(a) * radius * bump))
		im.surface_add_vertex(apex)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "ConeWire"
	return mi


# Torus wireframe — `ring_segments` minor-loop polygons (around the tube
# cross-section) and `rings` major-loop polygons (around the donut center).
# Note: param name swap! Godot's TorusMesh uses `rings` for the donut path
# and `ring_segments` for the tube cross-section, matching the primitive's
# convention.
func _build_torus_wireframe(rings: int, ring_segments: int, major_radius: float, tube_radius: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material())
	var bump: float = 1.005
	# Major-axis polygons: for each tube cross-section index, connect all
	# `rings` points along the donut center.
	for v_i in range(ring_segments):
		var v: float = float(v_i) * TAU / float(ring_segments)
		var cos_v: float = cos(v)
		var sin_v: float = sin(v)
		for u_i in range(rings):
			var u0: float = float(u_i) * TAU / float(rings)
			var u1: float = float(u_i + 1) * TAU / float(rings)
			im.surface_add_vertex(_torus_point(u0, cos_v, sin_v, major_radius, tube_radius * bump))
			im.surface_add_vertex(_torus_point(u1, cos_v, sin_v, major_radius, tube_radius * bump))
	# Tube cross-section polygons: for each donut-center index, connect
	# all `ring_segments` points around the tube.
	for u_i in range(rings):
		var u: float = float(u_i) * TAU / float(rings)
		for v_i in range(ring_segments):
			var v0: float = float(v_i) * TAU / float(ring_segments)
			var v1: float = float(v_i + 1) * TAU / float(ring_segments)
			im.surface_add_vertex(_torus_point(u, cos(v0), sin(v0), major_radius, tube_radius * bump))
			im.surface_add_vertex(_torus_point(u, cos(v1), sin(v1), major_radius, tube_radius * bump))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "TorusWire"
	return mi


func _torus_point(u: float, cos_v: float, sin_v: float, R: float, r: float) -> Vector3:
	# Standard torus parametric: ((R + r·cos v)·cos u, r·sin v, (R + r·cos v)·sin u)
	var d: float = R + r * cos_v
	return Vector3(d * cos(u), r * sin_v, d * sin(u))


# Sphere wireframe — `radial_segments` meridians (longitudes) and `rings - 1`
# latitudinal circles. Top and bottom are poles, so the latitude count is
# rings - 1 (not rings) to match SphereMesh's convention.
func _build_sphere_wireframe(radial_segments: int, rings: int, radius: float) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material())
	var bump: float = 1.005
	# Meridians (longitudes) — connect the actual mesh vertices along each
	# meridian with straight line segments. This matches Godot's SphereMesh
	# triangulation: the body's silhouette is the polygon hull of these
	# vertices, so the wireframe overlay sits exactly on the body's faceted
	# silhouette rather than tracing a smooth great-circle that would
	# extend past the body at low ring counts.
	for i in range(radial_segments):
		var a: float = float(i) * TAU / float(radial_segments)
		var cos_a: float = cos(a)
		var sin_a: float = sin(a)
		for step in range(rings):
			var t0: float = float(step) / float(rings)
			var t1: float = float(step + 1) / float(rings)
			var phi0: float = lerpf(-PI / 2.0, PI / 2.0, t0)
			var phi1: float = lerpf(-PI / 2.0, PI / 2.0, t1)
			im.surface_add_vertex(_sphere_point(cos_a, sin_a, phi0, radius * bump))
			im.surface_add_vertex(_sphere_point(cos_a, sin_a, phi1, radius * bump))
	# Latitudinal circles — for each interior ring level (not poles), draw
	# the parallel as a `radial_segments`-sided polygon to match the body's
	# tessellation.
	for r_i in range(1, rings):
		var t: float = float(r_i) / float(rings)
		var phi: float = lerpf(-PI / 2.0, PI / 2.0, t)
		var cos_phi: float = cos(phi)
		var sin_phi: float = sin(phi)
		var y: float = sin_phi * radius * bump
		var r_at: float = cos_phi * radius * bump
		for step in range(radial_segments):
			var a0: float = float(step) * TAU / float(radial_segments)
			var a1: float = float(step + 1) * TAU / float(radial_segments)
			im.surface_add_vertex(Vector3(cos(a0) * r_at, y, sin(a0) * r_at))
			im.surface_add_vertex(Vector3(cos(a1) * r_at, y, sin(a1) * r_at))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "SphereWire"
	return mi


func _sphere_point(cos_a: float, sin_a: float, phi: float, r: float) -> Vector3:
	var cp: float = cos(phi)
	return Vector3(cos_a * cp * r, sin(phi) * r, sin_a * cp * r)


func _capture_and_record(id: String, meta: Dictionary) -> void:
	# Yield a few frames so the viewport definitely renders the new content
	# before we sample the texture.
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
		"primitive": meta.get("primitive", ""),
		"image": "/parametric-mesh-gallery/%s" % img_rel,
		"config": "/parametric-mesh-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s" % id)


func _cyl_notes(r: int) -> String:
	if r <= 4:
		return "Obvious polygon — reads as a %d-sided prism, not a cylinder." % r
	elif r <= 8:
		return "Faceted — the polygon-ness is visible but the silhouette starts to round."
	elif r <= 16:
		return "Nearly smooth — the wireframe gives away the lattice but the body reads as a cylinder."
	else:
		return "Perceptually smooth — the player accepts it as continuous."


func _torus_notes(s: int) -> String:
	if s <= 4:
		return "Square tube — the cross-section is so coarse the donut looks angular."
	elif s <= 8:
		return "Faceted tube — the donut shape is there but the tube reads as a polygon."
	elif s <= 16:
		return "Smoothing in — the tube starts to read round."
	else:
		return "Round tube — the donut topology dominates; the lie of smoothness is complete."


func _sphere_notes(r: int) -> String:
	if r <= 4:
		return "Bipyramid — only %d longitudinal slices; the equator is a polygon, the poles are sharp points." % r
	elif r <= 8:
		return "Faceted ball — the silhouette is recognisably round but every meridian is visible."
	elif r <= 16:
		return "Nearly round — the lattice is still readable along the equator; the poles soften."
	else:
		return "Perceptually smooth — the sphere reads as continuous curvature; the lattice fades into shading."


func _cone_notes(r: int) -> String:
	if r <= 4:
		return "Pyramid — %d-sided pyramid, not a cone. The apex is genuinely sharp; the base is a polygon." % r
	elif r <= 8:
		return "Faceted cone — silhouette starts to round but the base edges still flash as polygon vertices."
	elif r <= 16:
		return "Nearly conical — the base reads as a circle; only close inspection shows the segments."
	else:
		return "Perceptually smooth — accepted as a cone; the polygon truth is invisible at this density."
