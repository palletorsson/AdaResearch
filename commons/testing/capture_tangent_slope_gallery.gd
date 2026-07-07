## One-off sweep capture for the tangent-slope DNA gallery.
##
## Renders the same curve f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) at 8
## x-positions across one period, drawing the tangent line at each point
## using the analytic derivative f'(x) = 0.8·cos(2x) − 0.75·sin(5x).
##
## Pedagogical claim (change.json sequence — "Things change."):
##   The derivative IS the slope of the tangent line at a point. Slide
##   along the curve and watch the slope flip sign at local extrema.
##
## Pair with capture_riemann_sum_gallery.gd (the integral sweep) — same
## f(x), two different operations: derivative (this gallery) reads
## instantaneous rate of change; Riemann sum reads accumulated area.
##
## Visual setup (matches capture_parametric_mesh_gallery.gd):
##   - Square 1024×1024 SubViewport with MSAA 8x + FXAA
##   - Isolated World3D so the project's autoloads don't bleed in
##   - Orthographic camera looking down +Z, framed to fit the curve's
##     x-range [0, 2π] and y-range [-0.5, 1.5]
##   - Three-light rig (unused under unshaded materials but consistent
##     with the family's setup so a future shaded variant drops in)
##   - Curve: pale white-blue line via ImmediateMesh
##   - Tangent: bright gold line ~30% of x-range either side of point
##   - Point: red sphere at (x, f(x))
##   - Slope label: corner Label3D with "f'(x) = ±N.NN"
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_tangent_slope_gallery.gd \
##     -- --out=user://tangent_slope_gallery
##
## Output: <out>/tangent_x<idx>.png + .json pairs + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)
const CURVE_COLOR: Color = Color(0.78, 0.86, 0.98)              # pale white-blue
const TANGENT_COLOR: Color = Color(1.0, 0.78, 0.20)             # bright gold
const POINT_COLOR: Color = Color(0.98, 0.32, 0.28)              # contrast red
const AXIS_COLOR: Color = Color(0.30, 0.32, 0.40)               # dim grey grid
const LABEL_COLOR: Color = Color(0.96, 0.96, 0.92)

# Curve domain — one full period of the slower 2x term (range 0…π).
# We sample a bit past π on either side so the tangent line never
# clips at the curve endpoints.
const X_MIN: float = 0.0
const X_MAX: float = 2.0 * PI       # ~6.283
const Y_MIN: float = -0.5
const Y_MAX: float = 1.5

# Tangent line extends this fraction of the x-domain on EITHER side
# of the contact point (~30% per the brief — total span ~60%).
const TANGENT_HALF_SPAN_FRAC: float = 0.30

# x-positions to sample — 8 cells across one period.
const X_POSITIONS: Array = [0.3, 1.0, 1.7, 2.4, 3.1, 3.8, 4.5, 5.2]

var _output_dir: String = "user://tangent_slope_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


# ── The function and its derivative ─────────────────────────────────
# Kept inline so they're trivially editable when the brief evolves.

func _f(x: float) -> float:
	return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)


func _df(x: float) -> float:
	# d/dx [0.5 + 0.4·sin(2x) + 0.15·cos(5x)]
	#   = 0.4·2·cos(2x) + 0.15·(-5)·sin(5x)
	#   = 0.8·cos(2x) − 0.75·sin(5x)
	return 0.8 * cos(2.0 * x) - 0.75 * sin(5.0 * x)


func _run() -> void:
	# ── SubViewport — explicit 1024×1024 square with MSAA 8x ────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	# ── Environment — dark BG, soft ambient ─────────────────────────
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

	# ── Lighting trio (mostly redundant for unshaded materials but
	# kept consistent with the family) ──────────────────────────────
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

	# ── Camera — orthographic, looking down +Z ─────────────────────
	# Frame so the entire domain [X_MIN, X_MAX] × [Y_MIN, Y_MAX] fits
	# with a small margin. We translate the scene so the curve is
	# centred on (0, 0) and use ortho size = max(x_span, y_span) * 1.1.
	#
	# All curve geometry below is generated in this CENTERED coord
	# system (x_world = x - x_center, y_world = y - y_center).
	var x_span: float = X_MAX - X_MIN
	var y_span: float = Y_MAX - Y_MIN
	var ortho_size: float = max(x_span, y_span) * 1.08
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ortho_size
	_camera.near = 0.01
	_camera.far = 100.0
	_camera.current = true
	# Looking from +Z down at the XY plane. Up is +Y.
	_camera.position = Vector3(0, 0, 10.0)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3(0, 0, 0), Vector3.UP)

	# Scene holder lives at origin; every per-frame scene is rebuilt under it.
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep ───────────────────────────────────────────────────────
	for i in range(X_POSITIONS.size()):
		var x_pos: float = X_POSITIONS[i]
		var y_val: float = _f(x_pos)
		var slope: float = _df(x_pos)

		_build_scene_for(x_pos, y_val, slope)
		await create_timer(0.05).timeout
		await _capture_and_record("tangent_x%d" % i, {
			"index": i,
			"x_position": x_pos,
			"y_value": y_val,
			"slope": slope,
			"function": "f(x) = 0.5 + 0.4*sin(2x) + 0.15*cos(5x)",
			"derivative": "f'(x) = 0.8*cos(2x) - 0.75*sin(5x)",
			"notes": _slope_notes(x_pos, slope),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# Write manifest.json
	var manifest := {
		"version": 1,
		"description": "Tangent slope sweep — 8 cells of the same curve f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) with the analytic tangent line f'(x) = 0.8·cos(2x) − 0.75·sin(5x) drawn at x ∈ [0.3, 1.0, 1.7, 2.4, 3.1, 3.8, 4.5, 5.2]. The derivative pair to riemann-sum-gallery (integral sweep on the same f). Captured at 1024×1024 with MSAA 8x; orthographic camera looking down +Z. The pedagogical claim of change.json (\"Things change. Change accumulates.\") made into a navigable substrate — derivative = slope of tangent at a point.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"function": "f(x) = 0.5 + 0.4*sin(2x) + 0.15*cos(5x)",
		"derivative": "f'(x) = 0.8*cos(2x) - 0.75*sin(5x)",
		"domain": [X_MIN, X_MAX],
		"x_positions": X_POSITIONS,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ── Per-cell scene assembly ─────────────────────────────────────────

func _build_scene_for(x_point: float, y_point: float, slope: float) -> void:
	# Center transform — every world coordinate below subtracts
	# (x_center, y_center) so the camera at origin sees the curve.
	var x_center: float = (X_MIN + X_MAX) * 0.5
	var y_center: float = (Y_MIN + Y_MAX) * 0.5

	# 1. Axes (dim grey) for spatial reference.
	var axes_mesh := ImmediateMesh.new()
	axes_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_material(AXIS_COLOR, 0.3))
	# Horizontal y=0 line
	axes_mesh.surface_add_vertex(_w(X_MIN, 0.0, x_center, y_center))
	axes_mesh.surface_add_vertex(_w(X_MAX, 0.0, x_center, y_center))
	# Vertical x=0 line — only if 0 is in domain (it is, at X_MIN)
	axes_mesh.surface_add_vertex(_w(X_MIN, Y_MIN, x_center, y_center))
	axes_mesh.surface_add_vertex(_w(X_MIN, Y_MAX, x_center, y_center))
	# x-tick marks at integers (small notches)
	var tick_h: float = 0.04
	for tx in range(1, 7):  # 1..6
		axes_mesh.surface_add_vertex(_w(float(tx), -tick_h, x_center, y_center))
		axes_mesh.surface_add_vertex(_w(float(tx), tick_h, x_center, y_center))
	# y-tick marks at -0.5, 0, 0.5, 1.0, 1.5
	var tick_w: float = 0.05
	for ty in [-0.5, 0.5, 1.0]:
		axes_mesh.surface_add_vertex(_w(X_MIN - tick_w, float(ty), x_center, y_center))
		axes_mesh.surface_add_vertex(_w(X_MIN + tick_w, float(ty), x_center, y_center))
	axes_mesh.surface_end()
	var axes_mi := MeshInstance3D.new()
	axes_mi.mesh = axes_mesh
	axes_mi.name = "Axes"
	_scene_holder.add_child(axes_mi)

	# 2. The curve f(x), full domain, as polyline.
	var curve_mesh := ImmediateMesh.new()
	curve_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _line_material(CURVE_COLOR, 1.0))
	var segments: int = 240
	for s in range(segments + 1):
		var t: float = float(s) / float(segments)
		var x: float = lerpf(X_MIN, X_MAX, t)
		var y: float = _f(x)
		curve_mesh.surface_add_vertex(_w(x, y, x_center, y_center))
	curve_mesh.surface_end()
	var curve_mi := MeshInstance3D.new()
	curve_mi.mesh = curve_mesh
	curve_mi.name = "Curve"
	_scene_holder.add_child(curve_mi)

	# 3. The tangent line at (x_point, y_point) with slope=slope.
	# y - y_point = slope * (x - x_point)
	# Extends TANGENT_HALF_SPAN_FRAC of x-range on either side.
	var half_span: float = (X_MAX - X_MIN) * TANGENT_HALF_SPAN_FRAC
	var x_a: float = x_point - half_span
	var x_b: float = x_point + half_span
	# Clip tangent to the visible y-range too — otherwise steep
	# slopes shoot off the top/bottom and dominate the frame.
	var y_a: float = y_point + slope * (x_a - x_point)
	var y_b: float = y_point + slope * (x_b - x_point)
	if y_a < Y_MIN:
		x_a = x_point + (Y_MIN - y_point) / slope
		y_a = Y_MIN
	elif y_a > Y_MAX:
		x_a = x_point + (Y_MAX - y_point) / slope
		y_a = Y_MAX
	if y_b < Y_MIN:
		x_b = x_point + (Y_MIN - y_point) / slope
		y_b = Y_MIN
	elif y_b > Y_MAX:
		x_b = x_point + (Y_MAX - y_point) / slope
		y_b = Y_MAX
	var tangent_mesh := ImmediateMesh.new()
	tangent_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _line_material(TANGENT_COLOR, 1.2))
	tangent_mesh.surface_add_vertex(_w(x_a, y_a, x_center, y_center))
	tangent_mesh.surface_add_vertex(_w(x_b, y_b, x_center, y_center))
	tangent_mesh.surface_end()
	var tangent_mi := MeshInstance3D.new()
	tangent_mi.mesh = tangent_mesh
	tangent_mi.name = "Tangent"
	_scene_holder.add_child(tangent_mi)

	# 4. The contact point at (x_point, y_point) — bright red sphere.
	var pt_mesh := SphereMesh.new()
	pt_mesh.radius = 0.10
	pt_mesh.height = 0.20
	pt_mesh.radial_segments = 16
	pt_mesh.rings = 8
	var pt_mat := StandardMaterial3D.new()
	pt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pt_mat.albedo_color = POINT_COLOR
	pt_mat.emission_enabled = true
	pt_mat.emission = POINT_COLOR
	pt_mat.emission_energy_multiplier = 0.7
	var pt_mi := MeshInstance3D.new()
	pt_mi.mesh = pt_mesh
	pt_mi.material_override = pt_mat
	pt_mi.position = _w(x_point, y_point, x_center, y_center) + Vector3(0, 0, 0.02)
	pt_mi.name = "Point"
	_scene_holder.add_child(pt_mi)

	# 5. Slope label in the top-left corner.
	var label := Label3D.new()
	label.text = "f'(%.2f) = %+0.2f" % [x_point, slope]
	label.font_size = 64
	label.outline_size = 12
	label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	label.modulate = LABEL_COLOR
	label.no_depth_test = true
	label.fixed_size = false
	label.pixel_size = 0.005
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# Place near top-left of camera frame. Camera at +Z; +X is right,
	# +Y is up. We position in centred world coords so it sits inside
	# the ortho frustum.
	var label_x: float = X_MIN + 0.15 - x_center
	var label_y: float = Y_MAX - 0.10 - y_center
	label.position = Vector3(label_x, label_y, 0.5)
	_scene_holder.add_child(label)

	# 6. A second, smaller label naming the curve (anchored bottom-right).
	var curve_label := Label3D.new()
	curve_label.text = "f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x)"
	curve_label.font_size = 36
	curve_label.outline_size = 8
	curve_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	curve_label.modulate = Color(0.62, 0.70, 0.85)
	curve_label.no_depth_test = true
	curve_label.pixel_size = 0.005
	curve_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	curve_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	curve_label.position = Vector3(X_MAX - 0.15 - x_center, Y_MIN + 0.10 - y_center, 0.5)
	_scene_holder.add_child(curve_label)


# ── Helpers ─────────────────────────────────────────────────────────

func _w(x: float, y: float, x_center: float, y_center: float) -> Vector3:
	# World position from curve coordinates (centred so camera at origin
	# sees the framed area).
	return Vector3(x - x_center, y - y_center, 0.0)


func _line_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	mat.disable_receive_shadows = true
	mat.no_depth_test = false
	return mat


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _slope_notes(x: float, slope: float) -> String:
	# Plain-language description of what the tangent reads at this x.
	# Flips on sign and steepness so adjacent cells contrast.
	var abs_s: float = absf(slope)
	var direction: String
	if slope > 0.05:
		direction = "rising"
	elif slope < -0.05:
		direction = "falling"
	else:
		direction = "nearly flat — at or near a local extremum"
	var steep: String
	if abs_s < 0.15:
		steep = "very gentle"
	elif abs_s < 0.5:
		steep = "moderate"
	elif abs_s < 1.0:
		steep = "steep"
	else:
		steep = "very steep"
	return "At x=%.2f the curve is %s; tangent slope is %s (f'=%+.3f). Read the gold line: that's the instantaneous rate of change at that single point — the derivative made visible." % [x, direction, steep, slope]


func _capture_and_record(id: String, meta: Dictionary) -> void:
	# Yield a few frames so the viewport definitely renders before
	# we sample the texture.
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
		"image": "/tangent-slope-gallery/%s" % img_rel,
		"config": "/tangent-slope-gallery/%s" % cfg_rel,
		"params": meta,
	})
	print("  saved: %s  (x=%.2f, slope=%+.3f)" % [id, meta.get("x_position", 0.0), meta.get("slope", 0.0)])
