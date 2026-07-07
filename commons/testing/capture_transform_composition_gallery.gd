## Composition Order Matters — DNA gallery capture script.
##
## Pedagogical claim (from commons/maps/sequences/transformation.json):
##   "Combine transformations and see order matters."
## Mathematically: T1 ∘ T2 ≠ T2 ∘ T1 for most transformation pairs. The same
## two operations produce a DIFFERENT final pose depending on which one runs
## first. This script makes that visible by rendering 4 pairs × 2 orderings
## = 8 cells, each cell holding:
##   - the BASE shape as a faint ghost (the "before")
##   - the TRANSFORMED shape as a saturated solid (the "after")
##   - a thin GOLD arrow from base-centroid to transformed-centroid (the
##     "trajectory" — the displacement vector through composition space)
##   - corner label baked into the JSON sidecar (the page renders the label)
##
## Pairs:
##   1. R_y(+45°)  ⊕  T_x(+1.0)
##   2. R_z(+60°)  ⊕  S(×1.5)
##   3. T_x(+0.8)  ⊕  S(×0.6)
##   4. R_x(+30°)  ⊕  R_y(+45°)
##
## Naming: pair{N}_t1_first means "apply T1 first, then T2" → result = T2·T1·v
##         pair{N}_t2_first means "apply T2 first, then T1" → result = T1·T2·v
##
## Visual goals: match parametric_mesh_gallery — 1024×1024 SubViewport, MSAA
## 8x + FXAA, isolated World3D, three-quarter perspective (cam at (3,3,3)),
## key+fill+rim lighting, filmic tonemap, dark background.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_transform_composition_gallery.gd \
##     -- --out=user://transform_composition_gallery
##
## Output: <out>/pair{1..4}_{t1,t2}_first.png + .json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const GHOST_COLOR: Color = Color(0.55, 0.65, 0.80, 0.20)     # faint blue ghost
const SOLID_COLOR: Color = Color(0.95, 0.35, 0.45)           # saturated red-magenta
const NOSE_COLOR: Color = Color(1.0, 0.95, 0.55)             # bright yellow "+X nose" stripe
const ARROW_COLOR: Color = Color(1.00, 0.78, 0.18)           # gold trajectory
const AXIS_COLOR: Color = Color(0.35, 0.40, 0.50)            # dim world axes

var _output_dir: String = "user://transform_composition_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


# Transformation operations. Each is a Transform3D you can compose.
# Translation/rotation/scale produced with the matching Transform3D helpers
# so the eventual basis math is correct (not just Euler angles in Vector3).
class TransformOp:
	var label: String
	var short: String
	var xform: Transform3D
	func _init(p_label: String, p_short: String, p_xform: Transform3D) -> void:
		label = p_label
		short = p_short
		xform = p_xform


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# ── SubViewport (isolated World3D so the project's autoloads can't bleed in)
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

	# ── Lighting trio (key + fill + rim) — same as parametric_mesh_gallery
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

	# ── Camera. The spec asks for (3,3,3) at fov 38°, looking at origin.
	# The transformed shapes can land up to ~2.5u from origin (worst case
	# pair 1: rotate then translate +X = 1.0; pair 3 grows to ~0.8). We
	# pull the camera back a touch (to 4u total distance via 2.4·sqrt(3)
	# ≈ 4.16) so the trajectory arrows have room to show.
	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(3.0, 3.0, 3.0)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── The four pairs of transformations ─────────────────────────────
	# Stored as TransformOp objects so the composition math runs through
	# Transform3D's basis multiplication (correct) instead of summing Euler
	# angles or anything similar that would silently commute and ruin the
	# whole pedagogical point.
	var pairs := [
		{
			"index": 1,
			"t1": TransformOp.new(
				"Rotate +45° Y", "R_y(+45°)",
				Transform3D(Basis().rotated(Vector3.UP, deg_to_rad(45.0)), Vector3.ZERO)
			),
			"t2": TransformOp.new(
				"Translate +X 1.0", "T_x(+1.0)",
				Transform3D(Basis.IDENTITY, Vector3(1.0, 0.0, 0.0))
			),
		},
		{
			"index": 2,
			"t1": TransformOp.new(
				"Rotate +60° Z", "R_z(+60°)",
				Transform3D(Basis().rotated(Vector3.FORWARD, deg_to_rad(60.0)), Vector3.ZERO)
			),
			"t2": TransformOp.new(
				"Scale ×1.5", "S(×1.5)",
				Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.5), Vector3.ZERO)
			),
		},
		{
			"index": 3,
			"t1": TransformOp.new(
				"Translate +X 0.8", "T_x(+0.8)",
				Transform3D(Basis.IDENTITY, Vector3(0.8, 0.0, 0.0))
			),
			"t2": TransformOp.new(
				"Scale ×0.6", "S(×0.6)",
				Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.6), Vector3.ZERO)
			),
		},
		{
			"index": 4,
			"t1": TransformOp.new(
				"Rotate +30° X", "R_x(+30°)",
				Transform3D(Basis().rotated(Vector3.RIGHT, deg_to_rad(30.0)), Vector3.ZERO)
			),
			"t2": TransformOp.new(
				"Rotate +45° Y", "R_y(+45°)",
				Transform3D(Basis().rotated(Vector3.UP, deg_to_rad(45.0)), Vector3.ZERO)
			),
		},
	]

	# Sweep — both orderings for each pair.
	for p in pairs:
		var pair_idx: int = p["index"]
		var t1: TransformOp = p["t1"]
		var t2: TransformOp = p["t2"]

		# Order A — T1 FIRST, then T2. In matrix form: final = T2 · T1 · v.
		# Composition reads RIGHT-TO-LEFT in the math; "T1 first" = rightmost.
		await _capture_pair_cell(
			"pair%d_t1_first" % pair_idx,
			pair_idx, t1, t2,
			t2.xform * t1.xform,
			"%s → %s" % [t1.label, t2.label],
			"T1 first, then T2",
			"T2 ∘ T1",
			"t1_first"
		)

		# Order B — T2 FIRST, then T1. final = T1 · T2 · v.
		await _capture_pair_cell(
			"pair%d_t2_first" % pair_idx,
			pair_idx, t1, t2,
			t1.xform * t2.xform,
			"%s → %s" % [t2.label, t1.label],
			"T2 first, then T1",
			"T1 ∘ T2",
			"t2_first"
		)

	# ── Manifest ──────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Composition of two transformations applied in BOTH orders, for four pairs of (rotate, translate, scale) operations. Same operations, different order → different result. The faint blue ghost is the untransformed base; the saturated red shape is the result; the gold arrow runs from base-centroid to result-centroid. Captured at 1024×1024 with MSAA 8x. The pedagogical claim of the transformation sequence (\"combine transformations and see order matters\", transformation.json:demonstration) made into a navigable side-by-side gallery.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"position": [3.0, 3.0, 3.0], "look_at": [0.0, 0.0, 0.0], "fov": 38.0},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Cell builder ────────────────────────────────────────────────────────
#
# Builds one capture by adding:
#   1. dim world axis lines (X red, Y green, Z blue) — orientation cue
#   2. faint ghost of the BASE arrow at the origin
#   3. SOLID transformed arrow with bright yellow +X nose stripe
#   4. gold trajectory arrow from base-centroid to transformed-centroid
# Then triggers a capture and writes the JSON sidecar.
func _capture_pair_cell(
	id: String,
	pair_idx: int,
	t1: TransformOp,
	t2: TransformOp,
	final_xform: Transform3D,
	human_label: String,
	order_words: String,
	composition: String,
	order_id: String
) -> void:
	_clear_holder()

	# World axes (very dim) — give the viewer a frame so they can read
	# "where did this shape end up" without thinking too hard.
	var axes := _build_world_axes(1.5)
	_scene_holder.add_child(axes)

	# Base shape — the "before". Centroid of base is at origin.
	var ghost := _build_arrow_shape(true)
	_scene_holder.add_child(ghost)

	# Transformed shape — the "after". Apply final_xform to the same arrow.
	var solid := _build_arrow_shape(false)
	solid.transform = final_xform
	_scene_holder.add_child(solid)

	# Trajectory arrow: base centroid (origin) → transformed centroid (final.origin)
	# Use final_xform applied to the BASE centroid, which for our shape is
	# placed at (0,0,0) in local space, so it's just final_xform.origin.
	# (The shape vertices straddle 0 along Y and Z; the centroid is on the
	# axis between base-face center and apex — at (0.2, 0, 0) approximately.
	# Use the centroid in local coords for correctness.)
	var base_centroid: Vector3 = _arrow_centroid()
	var final_centroid: Vector3 = final_xform * base_centroid
	if base_centroid.distance_to(final_centroid) > 0.005:
		var traj := _build_trajectory_arrow(base_centroid, final_centroid)
		_scene_holder.add_child(traj)

	await create_timer(0.05).timeout
	# Capture
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar
	var meta := {
		"id": id,
		"pair_index": pair_idx,
		"order": order_id,                 # "t1_first" or "t2_first"
		"t1": t1.label,
		"t2": t2.label,
		"t1_short": t1.short,
		"t2_short": t2.short,
		"applied_label": human_label,
		"order_words": order_words,
		"composition": composition,        # "T2 ∘ T1" or "T1 ∘ T2"
		"final_position": [
			final_xform.origin.x, final_xform.origin.y, final_xform.origin.z
		],
		"final_centroid": [
			final_centroid.x, final_centroid.y, final_centroid.z
		],
		"final_basis": [
			[final_xform.basis.x.x, final_xform.basis.x.y, final_xform.basis.x.z],
			[final_xform.basis.y.x, final_xform.basis.y.y, final_xform.basis.y.z],
			[final_xform.basis.z.x, final_xform.basis.z.y, final_xform.basis.z.z],
		],
		"notes": _cell_notes(pair_idx, order_id, t1, t2, final_xform),
	}
	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(meta, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"pair_index": pair_idx,
		"order": order_id,
		"applied_label": human_label,
		"composition": composition,
		"notes": meta["notes"],
		"image": "/transform-composition-gallery/%s" % img_rel,
		"config": "/transform-composition-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s" % id)


# ── Arrow / shape construction ─────────────────────────────────────────
#
# A "directional tetrahedron-with-fin" — five vertices that read clearly
# as oriented in space:
#   apex          A = ( 0.55,  0.0,   0.0 )   ← the "nose", points +X
#   base back-up  B = (-0.30,  0.30,  0.0 )   ← top vertex of triangular base
#   base front-l  C = (-0.30, -0.18, -0.30 )  ← bottom-left of base
#   base front-r  D = (-0.30, -0.18,  0.30 )  ← bottom-right of base
#   fin top       F = (-0.10,  0.45,  0.0 )   ← upright fin on top → "which way is up"
#
# This gives clear cues for ALL THREE axes:
#   - apex points +X     (which way is forward?)
#   - fin points +Y      (which way is up?)
#   - the base is wider along ±Z (which side is left vs right?)
# So whichever way the composition rotates this thing, the viewer can read
# its orientation at a glance.
const SHAPE_APEX := Vector3(0.55, 0.0, 0.0)
const SHAPE_B := Vector3(-0.30, 0.30, 0.0)
const SHAPE_C := Vector3(-0.30, -0.18, -0.30)
const SHAPE_D := Vector3(-0.30, -0.18, 0.30)
const SHAPE_F := Vector3(-0.10, 0.45, 0.0)


func _arrow_centroid() -> Vector3:
	# Approximate centroid — midpoint of apex and base-rear is enough for
	# the trajectory arrow to read well. Doesn't need to be exact, just
	# stable across base and transformed copies.
	return (SHAPE_APEX + SHAPE_B + SHAPE_C + SHAPE_D + SHAPE_F) / 5.0


func _build_arrow_shape(is_ghost: bool) -> Node3D:
	var holder := Node3D.new()
	holder.name = "ArrowShape"

	var body_color: Color
	var nose_color: Color
	if is_ghost:
		body_color = GHOST_COLOR
		nose_color = Color(GHOST_COLOR.r, GHOST_COLOR.g, GHOST_COLOR.b, 0.25)
	else:
		body_color = SOLID_COLOR
		nose_color = NOSE_COLOR

	# Body — 5-vertex polyhedron rendered as the four triangular faces of
	# the tetrahedron PLUS the two triangles that connect the fin to the
	# apex-to-back ridge. Build with ImmediateMesh + triangles.
	var im := ImmediateMesh.new()
	var mat := _make_body_material(body_color, is_ghost)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)

	# Tetrahedron faces (apex + 3 base vertices). Wound CCW from outside.
	_add_tri(im, SHAPE_APEX, SHAPE_C, SHAPE_D)   # front (toward +X, bottom)
	_add_tri(im, SHAPE_APEX, SHAPE_D, SHAPE_B)   # +Z side rising to top
	_add_tri(im, SHAPE_APEX, SHAPE_B, SHAPE_C)   # -Z side rising to top
	_add_tri(im, SHAPE_B, SHAPE_D, SHAPE_C)      # back base

	# Fin — a small triangle sitting on the top ridge (from B toward apex)
	_add_tri(im, SHAPE_B, SHAPE_APEX, SHAPE_F)   # +Z face of fin
	_add_tri(im, SHAPE_APEX, SHAPE_B, SHAPE_F)   # -Z face (back-facing copy)

	im.surface_end()

	# Apex "nose" stripe — a separate ImmediateMesh with a bright nose color
	# so the +X direction screams out at thumbnail scale.
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _make_body_material(nose_color, is_ghost))
	# Tiny pyramid at the apex
	var apex_tip: Vector3 = SHAPE_APEX + Vector3(0.06, 0.0, 0.0)
	var ring_r: float = 0.04
	var ring_back: Vector3 = SHAPE_APEX + Vector3(-0.02, 0.0, 0.0)
	for i in range(6):
		var a0: float = float(i) * TAU / 6.0
		var a1: float = float(i + 1) * TAU / 6.0
		var p0: Vector3 = ring_back + Vector3(0.0, cos(a0) * ring_r, sin(a0) * ring_r)
		var p1: Vector3 = ring_back + Vector3(0.0, cos(a1) * ring_r, sin(a1) * ring_r)
		_add_tri(im, apex_tip, p0, p1)
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	holder.add_child(mi)

	# Add wireframe outline so the ghost is still legible even when very
	# faint, AND so the solid shape's edges stand out against the busy
	# background of "ghost + solid + axes + trajectory arrow".
	var wire := _build_arrow_wireframe(is_ghost)
	holder.add_child(wire)

	return holder


func _build_arrow_wireframe(is_ghost: bool) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	var wire_color := Color(0.85, 0.92, 1.0, 0.45) if is_ghost else Color(1.0, 1.0, 1.0, 1.0)
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material(wire_color, is_ghost))
	# Tetrahedron edges
	var edges: Array = [
		[SHAPE_APEX, SHAPE_B], [SHAPE_APEX, SHAPE_C], [SHAPE_APEX, SHAPE_D],
		[SHAPE_B, SHAPE_C], [SHAPE_C, SHAPE_D], [SHAPE_D, SHAPE_B],
		# Fin edges
		[SHAPE_B, SHAPE_F], [SHAPE_APEX, SHAPE_F],
	]
	for e in edges:
		im.surface_add_vertex(e[0])
		im.surface_add_vertex(e[1])
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "ArrowWire"
	return mi


func _make_body_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	else:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.18
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _make_wire_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.6
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	return mat


func _add_tri(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Compute a flat-shading normal so the body lights consistently.
	var n: Vector3 = (b - a).cross(c - a).normalized()
	im.surface_set_normal(n)
	im.surface_add_vertex(a)
	im.surface_set_normal(n)
	im.surface_add_vertex(b)
	im.surface_set_normal(n)
	im.surface_add_vertex(c)


# ── World axes — dim X/Y/Z reference frame ──────────────────────────────
func _build_world_axes(length: float) -> Node3D:
	var holder := Node3D.new()
	holder.name = "WorldAxes"
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material(AXIS_COLOR, false))
	# X
	im.surface_add_vertex(Vector3(-length, 0, 0))
	im.surface_add_vertex(Vector3(length, 0, 0))
	# Y
	im.surface_add_vertex(Vector3(0, -length, 0))
	im.surface_add_vertex(Vector3(0, length, 0))
	# Z
	im.surface_add_vertex(Vector3(0, 0, -length))
	im.surface_add_vertex(Vector3(0, 0, length))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	holder.add_child(mi)
	# Add tiny tick markers at +X, +Y, +Z so the eye finds the positive end
	# of each axis without needing a label.
	_add_axis_tick(holder, Vector3(length, 0, 0), Color(0.95, 0.40, 0.45))     # +X = red
	_add_axis_tick(holder, Vector3(0, length, 0), Color(0.45, 0.95, 0.55))     # +Y = green
	_add_axis_tick(holder, Vector3(0, 0, length), Color(0.45, 0.65, 0.95))     # +Z = blue
	return holder


func _add_axis_tick(parent: Node3D, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.10
	sphere.radial_segments = 12
	sphere.rings = 6
	mi.mesh = sphere
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	parent.add_child(mi)


# ── Trajectory arrow — gold line from base-centroid to result-centroid ──
#
# Built as a thin cylindrical tube (so it has body at thumbnail scale)
# plus a small cone arrowhead pointing toward the target. The whole thing
# is rendered unshaded so it reads as a graphical annotation rather than
# a physical object.
func _build_trajectory_arrow(start: Vector3, end: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = "Trajectory"

	var v: Vector3 = end - start
	var dist: float = v.length()
	if dist < 0.005:
		return holder

	# Pull the line END BACK a touch so the arrowhead doesn't overshoot
	# into the body of the transformed shape.
	var head_len: float = 0.12
	var shaft_len: float = max(0.01, dist - head_len)

	# Shaft — thin cylinder along +Y from origin, then rotated so it
	# points from start to end.
	var shaft_mi := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.018
	shaft_mesh.bottom_radius = 0.018
	shaft_mesh.height = shaft_len
	shaft_mesh.radial_segments = 8
	shaft_mesh.rings = 1
	shaft_mi.mesh = shaft_mesh
	# Place at start + half-shaft, oriented along v
	shaft_mi.transform = _aim_transform(start, end, shaft_len / 2.0)
	shaft_mi.material_override = _make_arrow_material()
	holder.add_child(shaft_mi)

	# Head — cone (cylinder top_radius=0) at the END
	var head_mi := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.055
	head_mesh.height = head_len
	head_mesh.radial_segments = 12
	head_mesh.rings = 1
	head_mi.mesh = head_mesh
	head_mi.transform = _aim_transform(start, end, dist - head_len / 2.0)
	head_mi.material_override = _make_arrow_material()
	holder.add_child(head_mi)

	return holder


func _aim_transform(start: Vector3, end: Vector3, t: float) -> Transform3D:
	# Build a Transform3D that places a +Y-aligned mesh (Godot's default)
	# at the parametric point `start + t * normalize(end - start)`, pointing
	# from start toward end.
	var dir: Vector3 = (end - start).normalized()
	var pos: Vector3 = start + dir * t
	# Pick a reference up that isn't parallel to dir
	var up_ref: Vector3 = Vector3.UP
	if abs(dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT
	# Quaternion that rotates +Y to dir
	var basis_y_to_dir: Basis = Basis()
	# Use Transform3D.looking_at via a small trick: a node's +Y is its mesh axis,
	# so we construct a basis where y = dir, then orthogonalise.
	var y: Vector3 = dir
	var z: Vector3 = y.cross(up_ref).normalized()
	if z.length_squared() < 0.0001:
		# fallback if up_ref still parallel
		z = y.cross(Vector3.FORWARD).normalized()
	var x: Vector3 = z.cross(y).normalized()
	basis_y_to_dir = Basis(x, y, z)
	return Transform3D(basis_y_to_dir, pos)


func _make_arrow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ARROW_COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = ARROW_COLOR
	mat.emission_energy_multiplier = 0.85
	return mat


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


# ── Notes generator — the cell's caption text ───────────────────────────
func _cell_notes(pair_idx: int, order_id: String, t1: TransformOp, t2: TransformOp, final_xform: Transform3D) -> String:
	var prefix: String
	if order_id == "t1_first":
		prefix = "Apply %s first, then %s." % [t1.short, t2.short]
	else:
		prefix = "Apply %s first, then %s." % [t2.short, t1.short]
	var pos: Vector3 = final_xform.origin
	var pos_str: String = "Centroid lands at (%.2f, %.2f, %.2f)." % [pos.x, pos.y, pos.z]
	var commentary: String = ""
	match pair_idx:
		1:
			if order_id == "t1_first":
				commentary = " The rotation spins the local frame first, so the subsequent +X translation moves the shape diagonally in world space."
			else:
				commentary = " The translation moves +X first, then the rotation pivots the whole thing around the world origin — the shape ends up far from where the t1-first ordering put it."
		2:
			if order_id == "t1_first":
				commentary = " Rotation around Z first, then uniform scale — the orientation is the same as t2-first, but the centroid (still at origin) is unmoved. Pure-rotation + pure-scale around origin: ONE OF THE FEW PAIRS THAT COMMUTES."
			else:
				commentary = " Scale first, then rotate around Z — same result as t1-first because both operations fix the origin. Notice the final orientation matches the other ordering."
		3:
			if order_id == "t1_first":
				commentary = " Translation moves the shape to (0.8, 0, 0), then scaling around origin pulls it back to 0.6×0.8 = 0.48. Scale shrinks the displacement too."
			else:
				commentary = " Scale first (still at origin), THEN translation by full 0.8. Final position 0.8 — scale didn't shrink the translation because translation came after. Big visual gap from t1-first ordering."
		4:
			if order_id == "t1_first":
				commentary = " X-rotation first tilts the shape; then Y-rotation spins the tilted frame. The fin and apex end up in DIFFERENT positions than the other ordering."
			else:
				commentary = " Y-rotation first turns the shape; then X-rotation tilts the turned frame. SO(3) rotations don't commute — the order of two rotations around different axes always produces different orientations."
	return prefix + " " + pos_str + commentary
