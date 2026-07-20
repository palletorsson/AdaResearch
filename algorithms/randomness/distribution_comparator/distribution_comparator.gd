# distribution_comparator.gd
# Distribution Comparator — side-by-side probability distributions
# Three columns of histogram bars showing Uniform, Gaussian, and Exponential
# distributions generated from the same number of random samples.
#
# @identity
# essence: shape is statistics made visible — three distributions from one source
# desire: slide the sample count, hit resample, watch the bars redraw and diverge
# critical_parameter: sample count — more samples smooth the curves toward their ideal shape
# triggers: SAMPLES slider scales resolution; RESAMPLE regenerates all three columns
# emerges: uniform stays flat, gaussian peaks in the center, exponential decays — same randomness, different rules
# needs: RackTemplates panel [has]; BoxMesh bars [has]; Label3D headers [has]
# relationships: sibling to seed_replay (both explore RNG); feeds into monte_carlo (sampling foundations)
# truth: The same random source produces radically different shapes depending on the rule that channels it.

extends Node3D

class_name DistributionComparator

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## Every colour derives from HangarKit.finish_palette(), so one word re-skins
## the whole body instead of a dozen hand-typed constants.
@export var finish: String = "rams"
@export var wear: float = 0.10
@export var unit_code: String = "DC-03"


# ── Config ────────────────────────────────────────────────────────────
const NUM_BINS: int = 16
const MAX_BAR_HEIGHT: float = 0.25
const BAR_WIDTH: float = 0.012
const BAR_DEPTH: float = 0.012
const BAR_GAP: float = 0.004
const COLUMN_GAP: float = 0.06

# ── Colors ────────────────────────────────────────────────────────────
const COLOR_UNIFORM := Color(0.3, 0.5, 0.9)
const COLOR_GAUSSIAN := Color(0.3, 0.85, 0.4)
const COLOR_EXPONENTIAL := Color(0.9, 0.55, 0.2)

# ── State ─────────────────────────────────────────────────────────────
var _sample_count: int = 1000
var _rng := RandomNumberGenerator.new()
var _bars: Array[Array] = [[], [], []]  # 3 columns × 16 bars


func _ready() -> void:
	_rng.randomize()
	_build_bars()
	_build_headers()
	_build_panel()
	_create_cabinet()
	_resample()


# ═════════════════════════════════════════════════════════════════════
# BARS
# ═════════════════════════════════════════════════════════════════════

func _build_bars() -> void:
	var col_width: float = NUM_BINS * (BAR_WIDTH + BAR_GAP) - BAR_GAP
	var total_width: float = 3.0 * col_width + 2.0 * COLUMN_GAP
	var colors := [COLOR_UNIFORM, COLOR_GAUSSIAN, COLOR_EXPONENTIAL]

	for col in 3:
		var col_origin_x: float = -total_width / 2.0 + float(col) * (col_width + COLUMN_GAP)
		var column_bars: Array[MeshInstance3D] = []
		for bin_idx in NUM_BINS:
			var mi := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(BAR_WIDTH, 0.01, BAR_DEPTH)
			mi.mesh = box

			var mat := StandardMaterial3D.new()
			mat.albedo_color = colors[col]
			mat.emission = colors[col] * 0.3
			mat.emission_energy_multiplier = 0.4
			mi.material_override = mat

			mi.position = Vector3(
				col_origin_x + float(bin_idx) * (BAR_WIDTH + BAR_GAP),
				0.35,
				0
			)
			add_child(mi)
			column_bars.append(mi)
		_bars[col] = column_bars


# ═════════════════════════════════════════════════════════════════════
# HEADERS
# ═════════════════════════════════════════════════════════════════════

func _build_headers() -> void:
	var col_width: float = NUM_BINS * (BAR_WIDTH + BAR_GAP) - BAR_GAP
	var total_width: float = 3.0 * col_width + 2.0 * COLUMN_GAP
	var titles := ["UNIFORM", "GAUSSIAN", "EXPONENTIAL"]
	var colors := [COLOR_UNIFORM, COLOR_GAUSSIAN, COLOR_EXPONENTIAL]

	# Headers are SIGNAGE on the window's back wall (the cabinet ruling):
	# baked tags flush against the backdrop, one per column, column-tinted.
	for col in 3:
		var col_center_x: float = -total_width / 2.0 + float(col) * (col_width + COLUMN_GAP) + col_width / 2.0
		var tag: Node3D = BakedText.make_tag(
			titles[col], colors[col], 0.024,
			Color(0.055, 0.06, 0.075), false, Color(0, 0, 0, 0))
		if tag:
			tag.position = Vector3(col_center_x, 0.655, -0.022)
			add_child(tag)


# ═════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("", [
		[{"type": "slider_h", "label": "SAMPLES", "default": 0.1}],
		[{"type": "button", "label": "RESAMPLE"}],
	])
	# seated on the cabinet's dashboard wedge (all-in-one body)
	panel.position = Vector3(0, 0.175, 0.098)
	panel.rotation_degrees = Vector3(-15, 0, 0)
	panel.scale = Vector3(0.9, 0.9, 0.9)
	add_child(panel)

	# Samples slider (Param_0)
	var samples_slider: Node = panel.find_child("Param_0", true, false)
	if samples_slider and samples_slider.has_signal("slider_moved"):
		samples_slider.slider_moved.connect(_on_samples_slider)

	# Resample button (Btn_0)
	var resample_btn: Node = panel.find_child("Btn_0", true, false)
	if resample_btn:
		var area = resample_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _resample())


func _on_samples_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("DISTRIBUTIONS/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		var norm: float = slider.get_normalized_value()
		# Map 0..1 to 100..10000
		_sample_count = int(100.0 + norm * 9900.0)
		_resample()


# ═════════════════════════════════════════════════════════════════════
# SAMPLING
# ═════════════════════════════════════════════════════════════════════

func _resample() -> void:
	var buckets: Array[Array] = [[], [], []]
	for col in 3:
		var bins: Array[int] = []
		bins.resize(NUM_BINS)
		for i in NUM_BINS:
			bins[i] = 0
		buckets[col] = bins

	# Generate samples
	_rng.randomize()
	var lambda: float = 1.5  # exponential decay rate

	for _i in _sample_count:
		# Uniform: [0, 1)
		var u: float = _rng.randf()
		var u_bin: int = clampi(int(u * NUM_BINS), 0, NUM_BINS - 1)
		buckets[0][u_bin] += 1

		# Gaussian: randfn centered at 0.5, sigma 0.15, clamp to [0, 1)
		var g: float = clampf(_rng.randfn(0.5, 0.15), 0.0, 0.9999)
		var g_bin: int = clampi(int(g * NUM_BINS), 0, NUM_BINS - 1)
		buckets[1][g_bin] += 1

		# Exponential: -ln(randf()) / lambda, normalized to [0, 1) range
		var raw: float = -log(_rng.randf()) / lambda
		var e: float = clampf(raw / 4.0, 0.0, 0.9999)  # scale so most values fit
		var e_bin: int = clampi(int(e * NUM_BINS), 0, NUM_BINS - 1)
		buckets[2][e_bin] += 1

	# Update bar heights
	for col in 3:
		var max_count: int = 1
		for b in buckets[col]:
			if b > max_count:
				max_count = b

		for bin_idx in NUM_BINS:
			var bar: MeshInstance3D = _bars[col][bin_idx]
			var ratio: float = float(buckets[col][bin_idx]) / float(max_count)
			var h: float = maxf(ratio * MAX_BAR_HEIGHT, 0.003)
			var box: BoxMesh = bar.mesh
			box.size.y = h
			bar.position.y = 0.35 + h / 2.0


## THE CABINET — propagation no. 3 of the all-in-one interface ruling: the
## comparator becomes a wide console. The three histograms live inside ONE
## window (dark backdrop, glass, column headers baked on the back wall);
## the SAMPLES/RESAMPLE pad seats on a dashboard wedge; sign band in the
## cap; maroon flank; vent strip; plinth on feet.
func _create_cabinet() -> void:
	var col_width: float = NUM_BINS * (BAR_WIDTH + BAR_GAP) - BAR_GAP
	var win_w: float = 3.0 * col_width + 2.0 * COLUMN_GAP + 0.08
	var win_bot: float = 0.30
	var win_top: float = 0.72
	var total_w: float = win_w + 0.10 + 0.14      # maroon flank + vent column
	var cx: float = (win_w / 2.0 + 0.14) - total_w / 2.0
	var body_top: float = win_top + 0.05
	var cap_h: float = 0.11

	var cab := Node3D.new()
	cab.name = "Cabinet"
	add_child(cab)

	# ── One palette word drives every part (kit finish system) ──────────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.5, 0.6, 0.75, 0.10)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.roughness = 0.1
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# backdrop wall inside the window (bars read against it)
	var backdrop := MeshInstance3D.new()
	var backdrop_mesh := BoxMesh.new()
	backdrop_mesh.size = Vector3(win_w, win_top - win_bot, 0.012)
	backdrop.mesh = backdrop_mesh
	backdrop.material_override = dark
	backdrop.position = Vector3(0.0, (win_bot + win_top) / 2.0, -0.035)
	cab.add_child(backdrop)

	# window glass
	var glass := MeshInstance3D.new()
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(win_w, win_top - win_bot, 0.004)
	glass.mesh = glass_mesh
	glass.material_override = glass_mat
	glass.position = Vector3(0.0, (win_bot + win_top) / 2.0, 0.052)
	cab.add_child(glass)

	# back slab
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(total_w, body_top, 0.05)
	back.mesh = back_mesh
	back.material_override = shell
	back.position = Vector3(cx, body_top / 2.0, -0.075)
	cab.add_child(back)

	# maroon flank (left) + vent column (right)
	var flank := MeshInstance3D.new()
	var flank_mesh := BoxMesh.new()
	flank_mesh.size = Vector3(0.10, body_top, 0.16)
	flank.mesh = flank_mesh
	flank.material_override = maroon
	flank.position = Vector3(-win_w / 2.0 - 0.05, body_top / 2.0, -0.02)
	cab.add_child(flank)
	var vcol := MeshInstance3D.new()
	var vcol_mesh := BoxMesh.new()
	vcol_mesh.size = Vector3(0.14, body_top, 0.16)
	vcol.mesh = vcol_mesh
	vcol.material_override = shell
	vcol.position = Vector3(win_w / 2.0 + 0.07, body_top / 2.0, -0.02)
	cab.add_child(vcol)
	for gi in range(8):
		var slat := MeshInstance3D.new()
		var slat_mesh := BoxMesh.new()
		slat_mesh.size = Vector3(0.10, 0.010, 0.012)
		slat.mesh = slat_mesh
		slat.material_override = dark
		slat.position = Vector3(win_w / 2.0 + 0.07, 0.16 + float(gi) * 0.024, 0.062)
		cab.add_child(slat)

	# body below the window — the console face the dashboard grows from
	var below := MeshInstance3D.new()
	var below_mesh := BoxMesh.new()
	below_mesh.size = Vector3(win_w, win_bot, 0.14)
	below.mesh = below_mesh
	below.material_override = shell
	below.position = Vector3(0.0, win_bot / 2.0, -0.03)
	cab.add_child(below)
	# band above the window closing the frame
	var above := MeshInstance3D.new()
	var above_mesh := BoxMesh.new()
	above_mesh.size = Vector3(win_w, body_top - win_top, 0.14)
	above.mesh = above_mesh
	above.material_override = shell
	above.position = Vector3(0.0, (win_top + body_top) / 2.0, -0.03)
	cab.add_child(above)

	# dashboard wedge (center) — the pad's shoulder
	var wedge := _make_wedge(0.34, 0.15, 0.075, 0.022, dark)
	wedge.position = Vector3(0.0, 0.175, 0.040)
	cab.add_child(wedge)

	# sign cap
	var cap := MeshInstance3D.new()
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(total_w, cap_h, 0.18)
	cap.mesh = cap_mesh
	cap.material_override = shell
	cap.position = Vector3(cx, body_top + cap_h / 2.0, -0.02)
	cab.add_child(cap)
	var cap_stripe := MeshInstance3D.new()
	var cap_stripe_mesh := BoxMesh.new()
	cap_stripe_mesh.size = Vector3(total_w, 0.006, 0.004)
	cap_stripe.mesh = cap_stripe_mesh
	cap_stripe.material_override = accent
	cap_stripe.position = Vector3(cx, body_top + 0.004, 0.072)
	cab.add_child(cap_stripe)
	var sign := MeshInstance3D.new()
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(total_w - 0.10, 0.072, 0.012)
	sign.mesh = sign_mesh
	sign.material_override = dark
	sign.position = Vector3(cx, body_top + cap_h / 2.0, 0.070)
	cab.add_child(sign)
	var sign_title: Node3D = BakedText.make_tag(
		"DISTRIBUTION COMPARATOR", Color(0.93, 0.94, 0.97), 0.028,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(cx, body_top + cap_h / 2.0 + 0.012, 0.078)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"ONE SOURCE - THREE RULES", Color(0.55, 0.58, 0.66), 0.014,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(cx, body_top + cap_h / 2.0 - 0.018, 0.078)
		cab.add_child(sign_sub)

	# plinth + feet
	var plinth := MeshInstance3D.new()
	var plinth_mesh := BoxMesh.new()
	plinth_mesh.size = Vector3(total_w, 0.09, 0.22)
	plinth.mesh = plinth_mesh
	plinth.material_override = dark
	plinth.position = Vector3(cx, 0.045, -0.01)
	cab.add_child(plinth)
	for fx in [-total_w / 2.0 + 0.08, total_w / 2.0 - 0.08]:
		var foot := MeshInstance3D.new()
		var foot_mesh := BoxMesh.new()
		foot_mesh.size = Vector3(0.10, 0.03, 0.18)
		foot.mesh = foot_mesh
		foot.material_override = dark
		foot.position = Vector3(cx + fx, 0.015, -0.01)
		cab.add_child(foot)


## Right-triangle prism shoulder (shared cabinet grammar — see galton_board).

	# ── Kit details: the manufactured read the station props carry ──────
	cab.add_child(HangarKit.bolts(
		Vector3(win_w / 2.0 + 0.07, 0.14, 0.062),
		Vector3(win_w / 2.0 + 0.07, body_top - 0.10, 0.062),
		7, 0.009, steel))
	var bar: Node3D = HangarKit.three_color_bar(0.26, 0.016)
	if bar:
		bar.position = Vector3(-win_w / 2.0 - 0.05, win_bot - 0.10, 0.075)
		cab.add_child(bar)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.12, 0.030),
		col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-win_w / 2.0 + 0.10, 0.155, 0.052)
		cab.add_child(code)
	var gb: MeshInstance3D = HangarKit.grime_band(total_w * 0.9, 0.055, 0.050, col_body)
	if gb:
		gb.position.x = cx                  # keep the kit's baked z
		cab.add_child(gb)


func _make_wedge(w: float, h: float, d_bottom: float, d_top: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x0: float = -w / 2.0
	var x1: float = w / 2.0
	var y0: float = -h / 2.0
	var y1: float = h / 2.0
	var bbl := Vector3(x0, y0, 0.0)
	var bbr := Vector3(x1, y0, 0.0)
	var btl := Vector3(x0, y1, 0.0)
	var btr := Vector3(x1, y1, 0.0)
	var fbl := Vector3(x0, y0, d_bottom)
	var fbr := Vector3(x1, y0, d_bottom)
	var ftl := Vector3(x0, y1, d_top)
	var ftr := Vector3(x1, y1, d_top)
	var faces := [
		[fbl, fbr, ftr, ftl],
		[bbr, bbl, btl, btr],
		[bbl, fbl, ftl, btl],
		[fbr, bbr, btr, ftr],
		[btl, ftl, ftr, btr],
		[bbl, bbr, fbr, fbl],
	]
	for f in faces:
		st.add_vertex(f[0]); st.add_vertex(f[1]); st.add_vertex(f[2])
		st.add_vertex(f[0]); st.add_vertex(f[2]); st.add_vertex(f[3])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func apply_grid_config(config: Dictionary) -> void:
	pass
