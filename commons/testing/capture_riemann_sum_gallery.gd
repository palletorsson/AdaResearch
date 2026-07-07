## One-off sweep capture for the Riemann-sum DNA gallery.
##
## Renders the same curve f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) on [0, 2π]
## approximated by N midpoint-rule rectangles, with N stepping through the
## sweep [4, 8, 16, 32, 64, 128]. Six cells visualise the convergence claim
## of integral calculus — the integral IS the limit of the Riemann sum as
## N → ∞, and the rectangle stack literally morphs into the area under the
## curve as N grows.
##
## Visual goals:
##   - Square 1024×1024 SubViewport, MSAA 8x + FXAA, isolated World3D (same
##     "picture-perfect" rig as parametric-mesh-gallery)
##   - Orthographic camera looking down +Z at the XY plane so the curve and
##     the rectangles read as a clean 2D scientific plot
##   - Curve drawn as a smooth white polyline (200 samples → PRIMITIVE_LINE_STRIP)
##   - Rectangles drawn as translucent blue filled triangles + brighter outlines
##   - Light grid + axes underneath so the framing reads as a plot, not a soup
##
## Sweep: N ∈ [4, 8, 16, 32, 64, 128] — six cells.
##
## Per cell we also write a JSON sidecar containing N, the computed midpoint
## sum, the analytic true integral, and the absolute error |sum − true|.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_riemann_sum_gallery.gd \
##     -- --out=user://riemann_sum_gallery
##
## Output: <out>/riemann_n{N}.png + .json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Curve domain. We center the curve at the origin in world-space by translating
# the function's x-axis from [0, 5] → [-2.5, +2.5].
#
# Why [0, 5] rather than [0, 2π]: the function f(x) = 0.5 + 0.4·sin(2x) +
# 0.15·cos(5x) has trig components with periods that exactly tile [0, 2π],
# so the midpoint sum collapses to π for *every* N — convergence isn't
# visible in the numbers, even though it IS visible in the picture. The
# pedagogical goal is to show the sum approaching the true integral, so
# we pick a domain whose endpoint isn't aligned with the trig periods.
# On [0, 5] the sum genuinely converges from one direction to the true
# value and you can read the error decreasing in the captions.
const DOMAIN_LO: float = 0.0
const DOMAIN_HI: float = 5.0

# Visual / camera. Orthographic size is the vertical extent of the visible
# region. We render a square viewport, so visible width = visible height.
# Our domain is x ∈ [0, 5] which has width 5, and y ∈ [0, ~1.05]. After
# centering x on the origin, world-x runs in [-2.5·X_SCALE, +2.5·X_SCALE].
# With X_SCALE = 1.1 and ORTHO_SIZE = 3.4 we get visible x ∈ [-1.7, +1.7]·2
# = 3.4 wide, which neatly contains world-x ∈ [-2.75, +2.75] — wait, we need
# X_SCALE such that world-x at the edges sits ~inside the visible ±1.7 box.
# So X_SCALE ≈ 1.7/2.5 = 0.68 (slight margin → 0.62).
const ORTHO_SIZE: float = 3.6   # vertical extent (also horizontal for square)
const X_SCALE: float = 0.62     # 2.5·0.62 = 1.55 → fits in ±1.8 with margin
const Y_SCALE: float = 2.0      # stretch y so a ~1.0-range curve reads
const Y_OFFSET: float = -1.0    # shift curve down so y=0 sits at ~ -1 (axis line)

const CURVE_COLOR: Color = Color(1.0, 1.0, 1.0)
const RECT_FILL_COLOR: Color = Color(0.36, 0.62, 1.0, 0.32)     # translucent blue
const RECT_OUTLINE_COLOR: Color = Color(0.62, 0.84, 1.0, 0.95)  # brighter blue
const AXIS_COLOR: Color = Color(0.35, 0.40, 0.50, 0.55)
const GRID_COLOR: Color = Color(0.18, 0.22, 0.30, 0.40)

const N_VALUES: Array = [4, 8, 16, 32, 64, 128]

var _output_dir: String = "user://riemann_sum_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D
# Analytic integral of f over [0, 2π], computed once via fine sampling.
# We use N = 1,000,000 trapezoid as a "true" reference. (The analytic value
# is actually computable in closed form, see _analytic_true_integral, but
# we keep the fine-sample value too for cross-check.)
var _true_integral: float = 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# Precompute the "true" integral analytically.
	_true_integral = _analytic_true_integral()

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
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0  # We're using unshaded materials, so ambient mostly doesn't matter.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
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

	# A little directional light so anything that ends up shaded still reads.
	# All gallery content uses unshaded materials, so this is largely cosmetic.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.8
	key_light.shadow_enabled = false
	_viewport.add_child(key_light)

	# ── Camera — orthographic, looking down +Z ──────────────────────
	# The curve lies in the XY plane. Camera sits at +Z looking at origin.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ORTHO_SIZE
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	# Holder for the currently-captured scene contents.
	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep ───────────────────────────────────────────────────────
	for n in N_VALUES:
		_build_scene(int(n))
		await create_timer(0.05).timeout
		var sum: float = _midpoint_sum(int(n))
		var err: float = absf(sum - _true_integral)
		await _capture_and_record("riemann_n%d" % int(n), {
			"n": int(n),
			"sum": sum,
			"true_integral": _true_integral,
			"error": err,
			"notes": _notes_for_n(int(n), sum, err),
		})
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Midpoint Riemann sum of f(x) = 0.5 + 0.4·sin(2x) + 0.15·cos(5x) on [0, 5], at N ∈ [4, 8, 16, 32, 64, 128]. Six cells trace the integral emerging from a stack of rectangles. The pedagogical claim — integral = lim N→∞ Riemann sum — is made into a navigable parameter sweep, the calculus pair to parametric-mesh-gallery's radials × rings smoothness sweep. Captured at 1024×1024 with MSAA 8x; orthographic camera looking down +Z. Curve in white, rectangles in translucent blue.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"function": "f(x) = 0.5 + 0.4 * sin(2x) + 0.15 * cos(5x)",
		"domain": [DOMAIN_LO, DOMAIN_HI],
		"true_integral": _true_integral,
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	print("true integral: %.10f" % _true_integral)
	quit(0)


# ── The function being integrated ────────────────────────────────────
func _f(x: float) -> float:
	return 0.5 + 0.4 * sin(2.0 * x) + 0.15 * cos(5.0 * x)


# ── Analytic integral over [0, 5] ────────────────────────────────────
# ∫₀⁵ [0.5 + 0.4·sin(2x) + 0.15·cos(5x)] dx
#   = 0.5·5 + 0.4·[-cos(2x)/2]₀⁵ + 0.15·[sin(5x)/5]₀⁵
#   = 2.5 + 0.2·(1 − cos(10)) + 0.03·sin(25)
#   ≈ 2.5 + 0.2·(1 − (−0.8390715290764524)) + 0.03·(−0.13235175009777303)
#   ≈ 2.5 + 0.36781430581529046 − 0.003970552502933191
#   ≈ 2.8638437533123573
# We compute it from the closed-form expression so the JSON's "true_integral"
# matches a textbook calculation exactly, not a high-resolution estimate.
func _analytic_true_integral() -> float:
	return 2.5 + 0.2 * (1.0 - cos(10.0)) + 0.03 * sin(25.0)


# ── Midpoint-rule sum with N rectangles ──────────────────────────────
func _midpoint_sum(n: int) -> float:
	var dx: float = (DOMAIN_HI - DOMAIN_LO) / float(n)
	var total: float = 0.0
	for i in range(n):
		var x_mid: float = DOMAIN_LO + (float(i) + 0.5) * dx
		total += _f(x_mid)
	return total * dx


# ── Build the scene for one N ────────────────────────────────────────
func _build_scene(n: int) -> void:
	# 1. Axes + grid
	_add_axes_and_grid()
	# 2. The N rectangles (filled + outlined)
	_add_rectangles(n)
	# 3. The smooth curve on top
	_add_curve()
	# 4. The N + sum label
	_add_label_3d(n)


# ── Coordinate transform: function-space → world-space ───────────────
# Function x is in [0, 5]. We center it on the origin and scale by X_SCALE.
# Function y is in roughly [0, 1] (the curve y in fact ranges ~[0, ~1.05]).
# We shift down by Y_OFFSET and scale by Y_SCALE.
func _wx(x: float) -> float:
	# Center the domain on 0: x − (lo+hi)/2 = x − 2.5. Then scale.
	var center: float = (DOMAIN_LO + DOMAIN_HI) * 0.5
	return (x - center) * X_SCALE


func _wy(y: float) -> float:
	return y * Y_SCALE + Y_OFFSET


# ── Axes + grid mesh ─────────────────────────────────────────────────
func _add_axes_and_grid() -> void:
	var im := ImmediateMesh.new()
	var mat := _unshaded_material(GRID_COLOR)
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	# Vertical grid lines every 0.5 across [0, 5] → 10 internal lines.
	var grid_x_steps: int = 10
	for i in range(grid_x_steps + 1):
		var x: float = DOMAIN_LO + (DOMAIN_HI - DOMAIN_LO) * float(i) / float(grid_x_steps)
		var wx: float = _wx(x)
		# Skip the x = 0 and x = 2π edges to avoid double-drawing the axis frame.
		im.surface_add_vertex(Vector3(wx, _wy(0.0), 0.001))
		im.surface_add_vertex(Vector3(wx, _wy(1.2), 0.001))

	# Horizontal grid lines every 0.25.
	var grid_y_levels: Array = [0.25, 0.5, 0.75, 1.0]
	for y_val in grid_y_levels:
		im.surface_add_vertex(Vector3(_wx(DOMAIN_LO), _wy(float(y_val)), 0.001))
		im.surface_add_vertex(Vector3(_wx(DOMAIN_HI), _wy(float(y_val)), 0.001))

	im.surface_end()

	# Axis frame (the x-axis baseline and the left edge).
	im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(AXIS_COLOR))
	# x-axis (y = 0)
	im.surface_add_vertex(Vector3(_wx(DOMAIN_LO), _wy(0.0), 0.002))
	im.surface_add_vertex(Vector3(_wx(DOMAIN_HI), _wy(0.0), 0.002))
	# y-axis (x = 0 in function-space → wx = -π·X_SCALE)
	# Actually let's draw the left edge of the plot box at x = DOMAIN_LO.
	im.surface_add_vertex(Vector3(_wx(DOMAIN_LO), _wy(0.0), 0.002))
	im.surface_add_vertex(Vector3(_wx(DOMAIN_LO), _wy(1.2), 0.002))
	# Top edge
	im.surface_add_vertex(Vector3(_wx(DOMAIN_LO), _wy(1.2), 0.002))
	im.surface_add_vertex(Vector3(_wx(DOMAIN_HI), _wy(1.2), 0.002))
	# Right edge
	im.surface_add_vertex(Vector3(_wx(DOMAIN_HI), _wy(0.0), 0.002))
	im.surface_add_vertex(Vector3(_wx(DOMAIN_HI), _wy(1.2), 0.002))
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "AxesAndGrid"
	_scene_holder.add_child(mi)


# ── Rectangles (filled + outlined) ───────────────────────────────────
# Midpoint rule: each rectangle has its top at f(x_mid). Width = dx.
func _add_rectangles(n: int) -> void:
	var dx: float = (DOMAIN_HI - DOMAIN_LO) / float(n)

	# 1) Filled triangles for the rectangle bodies.
	var im_fill := ImmediateMesh.new()
	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(RECT_FILL_COLOR))
	for i in range(n):
		var x_lo: float = DOMAIN_LO + float(i) * dx
		var x_hi: float = x_lo + dx
		var x_mid: float = x_lo + 0.5 * dx
		var h: float = _f(x_mid)
		# Rectangle corners (in world coords). y = 0 at bottom, y = h at top.
		# z = 0.005 to sit just above the grid but below the curve.
		var z: float = 0.005
		var v_bl := Vector3(_wx(x_lo), _wy(0.0), z)
		var v_br := Vector3(_wx(x_hi), _wy(0.0), z)
		var v_tr := Vector3(_wx(x_hi), _wy(h),   z)
		var v_tl := Vector3(_wx(x_lo), _wy(h),   z)
		# Tri 1 (bl, br, tr), tri 2 (bl, tr, tl). Winding chosen to face +Z.
		im_fill.surface_add_vertex(v_bl)
		im_fill.surface_add_vertex(v_br)
		im_fill.surface_add_vertex(v_tr)
		im_fill.surface_add_vertex(v_bl)
		im_fill.surface_add_vertex(v_tr)
		im_fill.surface_add_vertex(v_tl)
	im_fill.surface_end()
	var mi_fill := MeshInstance3D.new()
	mi_fill.mesh = im_fill
	mi_fill.name = "RectFill"
	_scene_holder.add_child(mi_fill)

	# 2) Outline lines for each rectangle (left, top, right — skip bottom,
	#    which lies on the x-axis and would clutter the baseline). Plus the
	#    very-first left edge and very-last right edge anchor the stack to
	#    the y-axis baseline.
	var im_outline := ImmediateMesh.new()
	im_outline.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(RECT_OUTLINE_COLOR))
	for i in range(n):
		var x_lo: float = DOMAIN_LO + float(i) * dx
		var x_hi: float = x_lo + dx
		var x_mid: float = x_lo + 0.5 * dx
		var h: float = _f(x_mid)
		var z: float = 0.006
		var v_bl := Vector3(_wx(x_lo), _wy(0.0), z)
		var v_br := Vector3(_wx(x_hi), _wy(0.0), z)
		var v_tr := Vector3(_wx(x_hi), _wy(h),   z)
		var v_tl := Vector3(_wx(x_lo), _wy(h),   z)
		# Top
		im_outline.surface_add_vertex(v_tl)
		im_outline.surface_add_vertex(v_tr)
		# Left
		im_outline.surface_add_vertex(v_bl)
		im_outline.surface_add_vertex(v_tl)
		# Right
		im_outline.surface_add_vertex(v_br)
		im_outline.surface_add_vertex(v_tr)
	im_outline.surface_end()
	var mi_outline := MeshInstance3D.new()
	mi_outline.mesh = im_outline
	mi_outline.name = "RectOutline"
	_scene_holder.add_child(mi_outline)


# ── Smooth curve on top ──────────────────────────────────────────────
func _add_curve() -> void:
	var samples: int = 200
	var im := ImmediateMesh.new()
	# PRIMITIVE_LINE_STRIP gives us a continuous polyline through all samples.
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _unshaded_material(CURVE_COLOR))
	for i in range(samples + 1):
		var t: float = float(i) / float(samples)
		var x: float = lerpf(DOMAIN_LO, DOMAIN_HI, t)
		var y: float = _f(x)
		im.surface_add_vertex(Vector3(_wx(x), _wy(y), 0.01))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.name = "Curve"
	_scene_holder.add_child(mi)


# ── N + sum label as 3D text ─────────────────────────────────────────
func _add_label_3d(n: int) -> void:
	var label := Label3D.new()
	label.text = "N = %d" % n
	label.font_size = 96
	label.outline_size = 16
	label.modulate = Color(0.95, 0.95, 0.98)
	label.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	label.shaded = false
	label.no_depth_test = true
	label.fixed_size = false
	label.pixel_size = 0.0025
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.position = Vector3(_wx(DOMAIN_LO) + 0.08, _wy(1.2) - 0.18, 0.02)
	_scene_holder.add_child(label)

	var sum_label := Label3D.new()
	var sum: float = _midpoint_sum(n)
	sum_label.text = "sum = %.4f" % sum
	sum_label.font_size = 56
	sum_label.outline_size = 10
	sum_label.modulate = Color(0.78, 0.88, 1.0)
	sum_label.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	sum_label.shaded = false
	sum_label.no_depth_test = true
	sum_label.pixel_size = 0.0025
	sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sum_label.position = Vector3(_wx(DOMAIN_LO) + 0.08, _wy(1.2) - 0.34, 0.02)
	_scene_holder.add_child(sum_label)

	# True-integral reference in the corner.
	var true_label := Label3D.new()
	true_label.text = "true ≈ %.4f" % _true_integral
	true_label.font_size = 40
	true_label.outline_size = 8
	true_label.modulate = Color(0.65, 0.70, 0.80)
	true_label.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	true_label.shaded = false
	true_label.no_depth_test = true
	true_label.pixel_size = 0.0025
	true_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	true_label.position = Vector3(_wx(DOMAIN_HI) - 0.08, _wy(0.0) + 0.14, 0.02)
	_scene_holder.add_child(true_label)


# ── Materials ────────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	# Lines from ImmediateMesh in unshaded mode render with the albedo color.
	return mat


func _unshaded_material_transparent(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = Color(c.r, c.g, c.b, 1.0)
	mat.emission_energy_multiplier = 0.25
	return mat


# ── Capture helpers ──────────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(id: String, meta: Dictionary) -> void:
	# Yield a few frames so the viewport renders the new content before we sample.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % id
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var cfg_rel := "%s.json" % id
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(meta, "\t"))
	cf.close()

	_entries.append({
		"id": id,
		"notes": meta.get("notes", ""),
		"n": meta.get("n", 0),
		"sum": meta.get("sum", 0.0),
		"true_integral": meta.get("true_integral", 0.0),
		"error": meta.get("error", 0.0),
		"image": "/riemann-sum-gallery/%s" % img_rel,
		"config": "/riemann-sum-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  sum=%.6f  err=%.6f" % [id, meta.get("sum", 0.0), meta.get("error", 0.0)])


func _notes_for_n(n: int, sum: float, err: float) -> String:
	# Pedagogical observation per N. Tighter language as N grows.
	if n == 4:
		return "Coarse — only 4 rectangles. The midpoint heights catch the broad rise and fall but skip every wiggle. Error ≈ %.4f." % err
	elif n == 8:
		return "Still coarse — 8 rectangles begin to follow the curve's main peaks but miss the high-frequency cos(5x) component entirely. Error ≈ %.4f." % err
	elif n == 16:
		return "Tracking — 16 rectangles start to register the wiggle. The stack visibly leans toward the curve's shape. Error ≈ %.4f." % err
	elif n == 32:
		return "Close — 32 rectangles trace the curve well; the visible error is in the sharper turns. Error ≈ %.4f." % err
	elif n == 64:
		return "Tight — 64 rectangles look like the curve. At thumbnail scale you might mistake the rectangle stack for a filled region under the curve. Error ≈ %.4f." % err
	else:
		return "Indistinguishable — 128 rectangles are below visual discrimination from the true area. The integral has emerged from the polygon. Error ≈ %.4f." % err
