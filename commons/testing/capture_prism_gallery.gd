## One-off sweep capture for the prism left-to-right DNA gallery.
##
## Instances prism.tscn at 7 values of `left_to_right` from -1.0 to +1.0 and
## captures each from a consistent camera angle that reveals both the
## triangular face AND the rectangular side, so the top-edge slide reads
## clearly across the sweep.
##
## Pedagogical claim (mirrored from prism.gd @identity): a "prism" is a
## triangle dragged along an axis. When the top edge slides off-centre, the
## dragged triangle becomes a different triangle — and the same primitive
## becomes a fundamentally different shape.
##
## ── Godot PrismMesh semantics (verified empirically 2026-05-19) ─────
## The user's mental model and the spec text say:
##   lr = -1.0 → right-triangle prism (top edge fully left)
##   lr =  0.0 → symmetric isoceles wedge
##   lr = +1.0 → mirror right-triangle prism (top edge fully right)
##
## What Godot's PrismMesh actually does (probed via get_mesh_arrays()):
##   - Base ALWAYS spans x ∈ [-size.x/2, +size.x/2]
##   - lr in [ 0, +1]: top edge x = lerp(-size.x/2, +size.x/2, lr).
##                     So lr=0 puts the top at the LEFT corner of the
##                     base — a right-triangle prism with the right
##                     angle on the left. lr=+1 puts top at right corner
##                     (mirror right-triangle). lr=+0.5 gives the
##                     symmetric isoceles wedge.
##   - lr in [-1,  0]: top edge x = lerp(-1.5*size.x, -size.x/2, lr+1).
##                     The prism leans LEFT past the base; bounding box
##                     grows to the left. Obtuse / overhanging slope.
##                     lr=-1 puts the top at x = -1.5*size.x (3x the
##                     base half-width left of centre).
##
## So the sweep is NOT symmetric around 0 in the way the spec assumed —
## the negative half is an "overhanging" extrusion, not a mirror of the
## positive half. The captures still tell a clear left-to-right slide
## story, but the slide is asymmetric: -1 leans far past the base, 0 is
## a right-triangle, +1 is the mirror right-triangle, and the symmetric
## wedge actually lives at lr = +0.5 (NOT 0.0).
##
## This bug-in-spec is documented in the cell notes + page text.
##
## Visual setup (copied wholesale from capture_parametric_mesh_gallery.gd):
##   - Square 1024×1024 SubViewport with MSAA 8x + FXAA
##   - Isolated World3D so the project's autoload environments don't bleed in
##   - Three-light rig (key + fill + rim)
##   - Solid cyan body + white emissive overlay wireframe (ImmediateMesh,
##     PRIMITIVE_LINES) drawing exactly the 9 edges of the prism — 3 base
##     triangle edges, 3 top triangle edges (top "triangle" is degenerate:
##     a single line shared by two faces because the top is just one edge),
##     and 3 vertical edges. Total = 3 base + 3 verticals + 3 slant-to-top
##     = 9 distinct edges. Wait — actually PrismMesh is a triangle dragged
##     along Z, so it has TWO triangular caps (front/back) and THREE
##     rectangular sides. That's 6 cap edges (3 per cap) + 3 connecting
##     edges = 9 edges. Confirmed below.
##
## Camera angle: 28° yaw + 35° pitch matches the rest of the gallery family
## so visual style is consistent. The yaw rotates around Y so the prism's
## triangular face (which lies on the XY plane, dragged along Z) is partly
## visible alongside the long rectangular side — the slide is readable.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_prism_gallery.gd \
##     -- --out=user://parametric_prism_gallery
##
## Output: <out>/prism_lr_neg100.png ... prism_lr_100.png + manifest.json
extends SceneTree

const PRISM_SCENE: String = "res://commons/primitives/prism/prism.tscn"

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const WIRE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const BODY_COLOR: Color = Color(0.55, 0.85, 0.95, 1.0)  # cyan

# Sweep values, ordered low → high so file iteration matches reading order.
const SWEEP_VALUES: Array = [-1.0, -0.66, -0.33, 0.0, 0.33, 0.66, 1.0]

var _output_dir: String = "user://parametric_prism_gallery"
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
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	# ── Environment — dark BG, soft ambient, filmic tonemap ─────────
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

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25, 170, 0)
	rim_light.light_energy = 1.1
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	rim_light.shadow_enabled = false
	_viewport.add_child(rim_light)

	# ── Camera ──────────────────────────────────────────────────────
	# 28° yaw + 35° pitch — same as the parametric-mesh family so visual
	# style is consistent. The prism is built with the triangular cap on
	# the XY plane and the "drag axis" along Z; at this yaw both faces
	# show, and the slide of the top edge along X is the dominant signal.
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

	# Holder for the currently-captured subject + overlay wireframe
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep over left_to_right ────────────────────────────────────
	var prism_scene = load(PRISM_SCENE)
	if not prism_scene:
		push_error("Prism scene missing: %s" % PRISM_SCENE)
		quit(1)
		return

	for v in SWEEP_VALUES:
		var lr: float = float(v)
		var node = prism_scene.instantiate()
		node.left_to_right = lr
		node.size = Vector3(1.0, 1.0, 1.0)
		node.fill_color = BODY_COLOR
		node.wireframe_color = WIRE_COLOR
		_scene_holder.add_child(node)
		# Re-centre the body for framing. prism.gd offsets the mesh by
		# +0.5y to sit on a floor (counter with -0.5y). Additionally,
		# Godot's PrismMesh bounding box is asymmetric in X when lr < 0
		# (the prism leans left past the base). Centre by the actual
		# bounding-box centre so every cell frames the same way.
		var bbox_center_x: float = _prism_bbox_center_x(lr, 1.0)
		# Scale to ~0.7 so the lr=-1 cell (widest, bbox width 2.0) fits
		# in frame with margin. Smaller cells will appear smaller — this
		# is honest: the lr=-1 prism really IS bigger.
		var s: float = 0.7
		node.scale = Vector3(s, s, s)
		node.position = Vector3(-bbox_center_x * s, -0.5 * s, 0.0)
		await create_timer(0.05).timeout
		_apply_solid_material(node, BODY_COLOR)
		# Add the parametric wireframe overlay (9 distinct edges).
		# The wireframe is parented on the body's mesh node so it inherits
		# the +0.5y offset that prism.gd applies internally.
		var mesh_inst: Node3D = node.get_node_or_null("PrismMesh")
		if mesh_inst:
			var wire := _build_prism_wireframe(lr, Vector3(1.0, 1.0, 1.0))
			mesh_inst.add_child(wire)
		await create_timer(0.05).timeout

		var id := _encode_lr(lr)
		await _capture_and_record(id, {
			"primitive": "prism",
			"left_to_right": lr,
			"size": [1.0, 1.0, 1.0],
			"fill_color": [BODY_COLOR.r, BODY_COLOR.g, BODY_COLOR.b, BODY_COLOR.a],
			"wireframe_color": [WIRE_COLOR.r, WIRE_COLOR.g, WIRE_COLOR.b, WIRE_COLOR.a],
			"notes": _prism_notes(lr),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# Write manifest.json
	var manifest := {
		"version": 1,
		"description": "Prism left-to-right sweep — Godot's PrismMesh with the top edge slid from -1.0 through +1.0 in 7 cells. A prism is a triangle dragged along an axis; when the top edge slides, the dragged triangle becomes a different triangle and the same primitive becomes a different shape. BUG-IN-SPEC NOTE: Godot's PrismMesh sweep is NOT symmetric around 0. Empirically (verified via get_mesh_arrays()): lr in [0, +1] sweeps the top edge from x=-0.5 to x=+0.5 with the base fixed at [-0.5, +0.5], so lr=0 is a right-triangle prism (right angle on LEFT), lr=+0.5 is the symmetric isoceles wedge, lr=+1 is the mirror right-triangle. lr in [-1, 0] LEANS the top edge past the base's left corner (top_x ∈ [-1.5, -0.5]), producing overhanging obtuse prisms rather than mirror right-triangles. NOT the same as the prismblock primitive (which has a 5-face ridged geometry).",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"fov": 38.0, "yaw_deg": 28.0, "pitch_deg": 35.0, "distance": 2.4},
		"sweep_values": SWEEP_VALUES,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Helpers ─────────────────────────────────────────────────────────

# Encode a float in [-1, 1] to a filesystem-safe id like prism_lr_neg66 or
# prism_lr_0 or prism_lr_100. Magnitude is rounded to nearest integer percent.
func _encode_lr(lr: float) -> String:
	var pct: int = int(round(abs(lr) * 100.0))
	if abs(lr) < 1e-6:
		return "prism_lr_0"
	if lr < 0.0:
		return "prism_lr_neg%d" % pct
	return "prism_lr_%d" % pct


func _apply_solid_material(node: Node3D, color: Color) -> void:
	# Override every MeshInstance3D below `node` with a solid, flat-shaded
	# material so the body reads as a single silhouette color. The slide
	# of the top edge is then conveyed by the silhouette itself + the
	# overlay wireframe.
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
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = WIRE_COLOR
	mat.emission_enabled = true
	mat.emission = WIRE_COLOR
	mat.emission_energy_multiplier = 0.6
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	return mat


# Compute the actual X centre of Godot's PrismMesh bounding box, so the
# body can be re-centred for framing. Empirical (verified via
# get_mesh_arrays()):
#   - Base always spans x ∈ [-size.x/2, +size.x/2]
#   - For lr ≥ 0: top edge x ∈ [-size.x/2, +size.x/2], bbox = [-0.5, +0.5]*size.x
#   - For lr <  0: top edge x = -size.x * (0.5 + (1 + lr) * 0 ... actually
#     empirically: top_x = lerp(-1.5*size.x, -0.5*size.x, lr+1).
#     For lr=-1, top_x = -1.5*size.x; for lr=0, top_x = -0.5*size.x.
#     bbox.min.x = top_x, bbox.max.x = +0.5*size.x.
func _prism_bbox_center_x(lr: float, size_x: float) -> float:
	if lr >= 0.0:
		return 0.0  # symmetric across X for the positive half
	# Negative half: top edge extends past the base on the left.
	var top_x: float = lerpf(-1.5 * size_x, -0.5 * size_x, lr + 1.0)
	var min_x: float = top_x
	var max_x: float = +0.5 * size_x
	return (min_x + max_x) * 0.5


# Build the 9-edge wireframe of Godot's PrismMesh.
# Geometry (verified empirically, see header):
#   - Two triangular caps at z = -size.z/2 (back) and z = +size.z/2 (front)
#   - Base at y = -size.y/2, spans x ∈ [-size.x/2, +size.x/2]
#   - Top edge (single edge!) at y = +size.y/2, runs from
#     (top_x, +hy, -hz) to (top_x, +hy, +hz) where:
#       lr >= 0: top_x = lerp(-hx, +hx, lr)
#       lr <  0: top_x = lerp(-3*hx, -hx, lr + 1)
#   - 6 unique vertices: front and back × 3 (base-left, base-right, top).
#   - 9 edges: 3 front + 3 back + 3 connecting verticals.
func _build_prism_wireframe(left_to_right: float, size: Vector3) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material())

	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var top_x: float
	if left_to_right >= 0.0:
		top_x = lerpf(-hx, +hx, left_to_right)
	else:
		top_x = lerpf(-3.0 * hx, -hx, left_to_right + 1.0)
	var bump: float = 1.003  # small radial push to avoid z-fighting

	# Three triangle corners in (x, y) — same for front and back caps.
	# Compute centroid for outward bump.
	var cx: float = (-hx + hx + top_x) / 3.0
	var cy: float = (-hy + -hy + hy) / 3.0
	var bp := func(x: float, y: float) -> Vector2:
		var dx: float = x - cx
		var dy: float = y - cy
		return Vector2(cx + dx * bump, cy + dy * bump)

	var bl: Vector2 = bp.call(-hx, -hy)
	var br: Vector2 = bp.call(+hx, -hy)
	var ap: Vector2 = bp.call(top_x, +hy)

	var v_front_bl := Vector3(bl.x, bl.y, +hz * bump)
	var v_front_br := Vector3(br.x, br.y, +hz * bump)
	var v_front_ap := Vector3(ap.x, ap.y, +hz * bump)
	var v_back_bl := Vector3(bl.x, bl.y, -hz * bump)
	var v_back_br := Vector3(br.x, br.y, -hz * bump)
	var v_back_ap := Vector3(ap.x, ap.y, -hz * bump)

	# Front triangle (3 edges)
	im.surface_add_vertex(v_front_bl); im.surface_add_vertex(v_front_br)
	im.surface_add_vertex(v_front_br); im.surface_add_vertex(v_front_ap)
	im.surface_add_vertex(v_front_ap); im.surface_add_vertex(v_front_bl)

	# Back triangle (3 edges)
	im.surface_add_vertex(v_back_bl); im.surface_add_vertex(v_back_br)
	im.surface_add_vertex(v_back_br); im.surface_add_vertex(v_back_ap)
	im.surface_add_vertex(v_back_ap); im.surface_add_vertex(v_back_bl)

	# Three connecting edges (front→back at each triangle corner)
	im.surface_add_vertex(v_front_bl); im.surface_add_vertex(v_back_bl)
	im.surface_add_vertex(v_front_br); im.surface_add_vertex(v_back_br)
	im.surface_add_vertex(v_front_ap); im.surface_add_vertex(v_back_ap)

	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "PrismWire"
	return mi


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
		"primitive": meta.get("primitive", "prism"),
		"left_to_right": meta.get("left_to_right", 0.0),
		"image": "/parametric-prism-gallery/%s" % img_rel,
		"config": "/parametric-prism-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s (left_to_right=%.3f)" % [id, meta.get("left_to_right", 0.0)])


func _prism_notes(lr: float) -> String:
	# Notes describe what Godot's PrismMesh actually produces, not the
	# user's symmetric mental model. See header for empirical findings.
	if lr <= -0.95:
		return "Extreme overhang — top edge slid to x = -1.5 (three half-widths past the base's left corner). The triangle is heavily obtuse: one slope rises straight up from the base's left corner, the other slope drops steeply right. Godot's PrismMesh negative-half region leans the apex past the base, NOT into a mirror right-triangle."
	elif lr <= -0.5:
		return "Strong overhang — top edge at x ≈ -1.16. Asymmetric obtuse triangle dragged along Z. The negative half of the lr range produces overhanging prisms, not the mirror right-triangles one might expect by symmetry."
	elif lr <= -0.15:
		return "Mild overhang — top edge at x ≈ -0.83. Still slightly past the base's left corner. The slide is continuous; this is the gentlest version of the overhanging wedge."
	elif abs(lr) < 0.15:
		return "Right-triangle prism — top edge at x = -0.5, sitting exactly above the base's left corner. The right angle is on the LEFT. NOTE: contrary to the symmetric mental model, lr=0 is NOT the symmetric isoceles wedge in Godot's PrismMesh — that lives at lr=+0.5."
	elif lr <= 0.5:
		return "Skewed wedge — top edge at x ≈ -0.17, between the right-triangle (lr=0) and the symmetric wedge (lr=+0.5). The apex leans slightly left of centre."
	elif lr <= 0.95:
		return "Past-symmetric wedge — top edge at x ≈ +0.16, just right of centre. The symmetric isoceles wedge actually lives at lr=+0.5 in Godot's PrismMesh; this cell is one tick past it, with the apex leaning slightly right."
	else:
		return "Mirror right-triangle prism — top edge at x = +0.5, sitting above the base's right corner. The right angle is on the RIGHT. This is the mirror of the lr=0 cell (right-triangle prism, right angle on the left), with the symmetric wedge lr=+0.5 sitting between them."
