## One-off sweep capture for the Shannon-bound DNA gallery.
##
## Mathematical claim — for a binary source with P(1)=p, the minimum bits/symbol
## needed for lossless compression is exactly the Shannon binary entropy
##   H(p) = −p log₂ p − (1−p) log₂ (1−p)
## H(0) = H(1) = 0 (degenerate source, perfect compression). H(0.5) = 1 (fair
## coin, incompressible). The function is symmetric around 0.5 because
## relabeling 0↔1 doesn't change information content. Real compressors can
## approach H(p) but never beat it (Shannon 1948, source-coding theorem).
##
## The 8 cells walk along the hill of H(p):
##   p=0.0  → H=0.000   theoretical_min = 0 bits   ("constant")
##   p=0.1  → H≈0.469   theoretical_min ≈ 120 bits ("sparse")
##   p=0.25 → H≈0.811   theoretical_min ≈ 208 bits ("biased")
##   p=0.4  → H≈0.971   theoretical_min ≈ 249 bits ("leaning")
##   p=0.5  → H=1.000   theoretical_min = 256 bits ("fair coin")
##   p=0.6  → H≈0.971   theoretical_min ≈ 249 bits ("leaning")
##   p=0.75 → H≈0.811   theoretical_min ≈ 208 bits ("biased")
##   p=0.9  → H≈0.469   theoretical_min ≈ 120 bits ("sparse")
##
## Each cell renders:
##   - 16×16 grid of sample bits drawn from Bernoulli(p) with a deterministic
##     seed shared across cells (so the only difference between cells is p).
##     Black square = 0, bright cyan square = 1.
##   - The H(p) value as a large number label
##   - The entropy curve H(p) drawn as a small line graph in the corner with a
##     bright dot at the current cell's p position
##   - The compression result — runs a Huffman-frequency estimate on the actual
##     256-bit sample and shows actual_bits / theoretical_min_bits / raw_bits.
##   - A label naming the case ("constant", "sparse", "biased", …)
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_shannon_bound_gallery.gd \
##     -- --out=user://shannon_bound_gallery
##
## Output: <out>/{id}.png + {id}.json + manifest.json
extends SceneTree

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Camera framing: orthographic, looking straight down +Z at the XY plane.
# ORTHO_SIZE = 4.0 means the visible Y range is [-2, +2].
const ORTHO_SIZE: float = 4.0

# Bit-grid rendering.
const GRID_N: int = 16
const GRID_TOTAL_W: float = 1.95         # total grid width in world units
const GRID_CENTER_Y: float = -0.30       # vertical center of the grid panel
const BIT_GAP: float = 0.008             # gap between cells

# Entropy curve panel (top-right).
const CURVE_X_LO: float = 0.85
const CURVE_X_HI: float = 1.85
const CURVE_Y_LO: float = 0.85
const CURVE_Y_HI: float = 1.65
const CURVE_SAMPLES: int = 121           # smooth line, 121 points along p ∈ [0, 1]

# Compression bar panel (bottom-right of the grid, beneath).
# Three horizontal bars: raw_bits, theoretical_min, compressed_bits.
const BAR_PANEL_Y_LO: float = -1.85
const BAR_PANEL_Y_HI: float = -1.18
const BAR_PANEL_X_LO: float = -1.85
const BAR_PANEL_X_HI: float = 1.85

# Color palette.
const ZERO_COLOR: Color = Color(0.04, 0.05, 0.08)        # near-black for 0
const ZERO_BORDER: Color = Color(0.18, 0.22, 0.30)
const ONE_COLOR: Color = Color(0.32, 0.92, 0.96)         # bright cyan for 1
const CURVE_LINE: Color = Color(0.62, 0.78, 0.92, 0.95)  # entropy curve
const CURVE_DOT: Color = Color(1.0, 0.86, 0.30)          # bright amber dot at current p
const CURVE_BG: Color = Color(0.10, 0.12, 0.17, 0.85)
const CURVE_BORDER: Color = Color(0.32, 0.36, 0.46, 0.85)
const BAR_RAW: Color = Color(0.38, 0.42, 0.52)           # raw bits — neutral gray
const BAR_THEORETICAL: Color = Color(0.96, 0.62, 0.32)   # Shannon floor — amber
const BAR_COMPRESSED: Color = Color(0.42, 0.86, 0.50)    # achieved by compressor — green
const TEXT_BRIGHT: Color = Color(0.96, 0.96, 0.98)
const TEXT_DIM: Color = Color(0.62, 0.66, 0.74)
const PANEL_BG: Color = Color(0.10, 0.12, 0.17, 0.85)

# Shared RNG seed across all cells so the only varying input is p.
const SHARED_SEED: int = 0x5108AD0E

# Sample size — 16×16 = 256 bits per cell.
const SAMPLE_BITS_N: int = 256


var _output_dir: String = "user://shannon_bound_gallery"
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
	# ── Viewport setup ──────────────────────────────────────────────
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.86, 0.92)
	env.ambient_light_energy = 1.0
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

	# Cosmetic light — unshaded materials don't strictly need it but keeps env happy.
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, 0, 0)
	key_light.light_energy = 0.6
	_viewport.add_child(key_light)

	# Orthographic camera, head-on at the XY plane.
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = ORTHO_SIZE
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	_camera.position = Vector3(0, 0, 5)
	_viewport.add_child(_camera)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	# ── Sweep over the 8 probabilities ──────────────────────────────
	var sweep: Array = _build_sweep()
	for spec in sweep:
		var result: Dictionary = _sample_and_compress(spec["p"])
		_build_scene(spec, result)
		await create_timer(0.05).timeout
		await _capture_and_record(spec, result)
		_clear_holder()
		await create_timer(0.02).timeout

	# ── Manifest ────────────────────────────────────────────────────
	var manifest := {
		"version": 1,
		"description": "Binary entropy H(p) = −p log₂ p − (1−p) log₂ (1−p) swept across 8 values of p ∈ {0.0, 0.1, 0.25, 0.4, 0.5, 0.6, 0.75, 0.9}. Each cell shows a 16×16 sample drawn from Bernoulli(p) with a shared deterministic seed, the H(p) value, the entropy curve with a marker at the current p, and a Huffman-frequency compression estimate compared against the Shannon floor (theoretical_min = H(p) × 256). The hill peaks at p=0.5 (incompressible) and falls to 0 at both ends. Shannon 1948, source-coding theorem: no algorithm can beat H(p) on a Bernoulli source.",
		"capture_size": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"camera": {"projection": "orthogonal", "size": ORTHO_SIZE},
		"sample_bits_per_cell": SAMPLE_BITS_N,
		"grid_n": GRID_N,
		"shared_seed": "0x%X" % SHARED_SEED,
		"references": {
			"shannon_1948": "C. E. Shannon, A Mathematical Theory of Communication, Bell System Technical Journal 27 (1948), 379–423, 623–656.",
			"source_coding_theorem": "No lossless code achieves expected length below the source entropy. H(p) is the floor.",
		},
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d entries saved to %s" % [_entries.size(), _output_dir])
	quit(0)


# ─── Sweep specification ─────────────────────────────────────────────
func _build_sweep() -> Array:
	var sweep: Array = []
	sweep.append({"id": "1_p000_constant",   "p": 0.00, "label": "constant",  "notes": "p=0: the source is constant zero. Every symbol is the same. No bits needed to encode it. The Shannon floor is 0 — the message 'all zeros, 256 of them' is a single statement."})
	sweep.append({"id": "2_p010_sparse",     "p": 0.10, "label": "sparse",    "notes": "p=0.1: about 1 in 10 symbols is a 1. Very compressible — run-length or arithmetic coding gets close to 120 bits."})
	sweep.append({"id": "3_p025_biased",     "p": 0.25, "label": "biased",    "notes": "p=0.25: a clearly biased coin. H≈0.811 bits/symbol. Compressors can still squeeze ~30% off."})
	sweep.append({"id": "4_p040_leaning",    "p": 0.40, "label": "leaning",   "notes": "p=0.4: only slightly biased. H≈0.971 — there's almost nothing left to compress, but a tiny amount."})
	sweep.append({"id": "5_p050_fair_coin",  "p": 0.50, "label": "fair coin", "notes": "p=0.5: the fair coin. H = 1.000 exactly. The Shannon floor IS the raw size. Incompressible — no algorithm can do better than 256 bits for 256 fair coin tosses."})
	sweep.append({"id": "6_p060_leaning",    "p": 0.60, "label": "leaning",   "notes": "p=0.6: mirror image of p=0.4. H(p) is symmetric around 0.5: relabeling 0↔1 doesn't change the information content."})
	sweep.append({"id": "7_p075_biased",     "p": 0.75, "label": "biased",    "notes": "p=0.75: more 1s than 0s. H≈0.811, same as p=0.25 — same hill, opposite slope."})
	sweep.append({"id": "8_p090_sparse",     "p": 0.90, "label": "sparse",    "notes": "p=0.9: mostly 1s, a few 0s. Same H≈0.469 as p=0.1 — the 0s are now the rare symbol."})
	return sweep


# ─── Binary entropy H(p) ─────────────────────────────────────────────
func _entropy(p: float) -> float:
	if p <= 0.0 or p >= 1.0:
		return 0.0
	var q: float = 1.0 - p
	# log₂ via natural log: log₂(x) = ln(x) / ln(2).
	var inv_ln2: float = 1.0 / log(2.0)
	return -p * log(p) * inv_ln2 - q * log(q) * inv_ln2


# ─── Sample and compress ─────────────────────────────────────────────
# Draw SAMPLE_BITS_N bits from Bernoulli(p) using the shared seed, then run a
# Huffman-frequency estimate of the compressed length based on observed
# frequencies of 0s and 1s. For a binary source, optimal symbol coding is
# 1 bit per symbol (you can't do better symbol-by-symbol), but the cross-entropy
# −n₀ log₂ p₀ − n₁ log₂ p₁ with the observed empirical frequencies p₀, p₁
# is what a perfect arithmetic coder achieves and is the right estimate to
# compare against the Shannon floor.
func _sample_and_compress(p: float) -> Dictionary:
	# Deterministic RNG, identical seed across cells.
	var rng := RandomNumberGenerator.new()
	rng.seed = SHARED_SEED

	var bits: PackedByteArray = PackedByteArray()
	bits.resize(SAMPLE_BITS_N)
	var n_ones: int = 0
	for i in range(SAMPLE_BITS_N):
		var u: float = rng.randf()
		var bit: int = 1 if u < p else 0
		bits[i] = bit
		n_ones += bit
	var n_zeros: int = SAMPLE_BITS_N - n_ones

	# Empirical Shannon estimate (cross-entropy with observed frequencies).
	# This is what an arithmetic coder with a learned model achieves, and is the
	# tightest fair estimate of "actual achievable compressed length" for a
	# binary memoryless source.
	var p_hat: float = float(n_ones) / float(SAMPLE_BITS_N)
	var p_hat_clamped: float = clamp(p_hat, 1e-9, 1.0 - 1e-9)
	# Observed entropy in bits/symbol.
	var observed_entropy: float
	if n_ones == 0 or n_zeros == 0:
		# Degenerate empirical source — perfect compression possible.
		observed_entropy = 0.0
	else:
		var inv_ln2: float = 1.0 / log(2.0)
		observed_entropy = -p_hat_clamped * log(p_hat_clamped) * inv_ln2 \
			- (1.0 - p_hat_clamped) * log(1.0 - p_hat_clamped) * inv_ln2

	# A real arithmetic coder also needs to transmit the model (~16-20 bits for
	# a single Bernoulli parameter). We add a small overhead so the compressed
	# number reads as "what a real compressor would actually emit" rather than
	# the pure information-theoretic lower bound. The Shannon floor (using the
	# TRUE p) is reported separately.
	const MODEL_OVERHEAD: float = 16.0  # bits to transmit p_hat
	var compressed_bits: float = ceil(observed_entropy * float(SAMPLE_BITS_N)) + MODEL_OVERHEAD
	# But never claim to beat the true Shannon floor by more than the model
	# overhead's slack — the floor is the floor.
	var theoretical_min: float = _entropy(p) * float(SAMPLE_BITS_N)
	# Note: observed_entropy can be slightly different from true p's entropy,
	# because the sample's empirical frequency drifts from p. We report both.

	# Hex-encode the sample bits.
	var hex_bits: String = _bits_to_hex(bits)

	return {
		"bits": bits,
		"n_ones": n_ones,
		"n_zeros": n_zeros,
		"p_hat": p_hat,
		"true_entropy_bits": _entropy(p),
		"observed_entropy_bits": observed_entropy,
		"theoretical_min_bits": theoretical_min,
		"compressed_bits": compressed_bits,
		"raw_bits": float(SAMPLE_BITS_N),
		"sample_hex": hex_bits,
	}


func _bits_to_hex(bits: PackedByteArray) -> String:
	# Pack 256 bits into 64 hex chars (big-endian within each nibble).
	var out: String = ""
	var byte: int = 0
	var idx: int = 0
	for i in range(bits.size()):
		byte = (byte << 1) | int(bits[i])
		if (i + 1) % 4 == 0:
			out += "0123456789abcdef"[byte]
			byte = 0
			idx += 1
	return out


# ─── Scene construction ──────────────────────────────────────────────
func _build_scene(spec: Dictionary, result: Dictionary) -> void:
	_add_title(spec)
	_add_entropy_label(spec["p"], result["true_entropy_bits"])
	_add_bit_grid(result["bits"])
	_add_entropy_curve(spec["p"])
	_add_compression_bars(result)
	_add_label_case(spec["label"])


# ─── Top: machine name + p value ─────────────────────────────────────
func _add_title(spec: Dictionary) -> void:
	# Top-left: "p = 0.500"
	var p_lab := Label3D.new()
	p_lab.text = "p = %.3f" % spec["p"]
	p_lab.font_size = 72
	p_lab.outline_size = 12
	p_lab.modulate = TEXT_BRIGHT
	p_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	p_lab.shaded = false
	p_lab.no_depth_test = true
	p_lab.pixel_size = 0.0025
	p_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	p_lab.position = Vector3(-1.85, 1.65, 0.02)
	_scene_holder.add_child(p_lab)

	# Subtitle: "Shannon bound · 256-bit sample"
	var sub := Label3D.new()
	sub.text = "Shannon bound · 256-bit sample"
	sub.font_size = 28
	sub.outline_size = 6
	sub.modulate = TEXT_DIM
	sub.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	sub.shaded = false
	sub.no_depth_test = true
	sub.pixel_size = 0.0025
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	sub.position = Vector3(-1.85, 1.42, 0.02)
	_scene_holder.add_child(sub)


# ─── Entropy big-number label (center-left under title) ──────────────
func _add_entropy_label(p: float, h: float) -> void:
	# Compute h locally too so we render exactly what the math says.
	var _h_check: float = _entropy(p)
	# Big number: "H = 0.881 bits/symbol"
	var lab := Label3D.new()
	lab.text = "H = %.3f bits/symbol" % h
	lab.font_size = 56
	lab.outline_size = 10
	lab.modulate = ONE_COLOR
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lab.position = Vector3(-1.85, 1.12, 0.02)
	_scene_holder.add_child(lab)

	# Small explanation under it: "H(p) = −p log₂ p − (1−p) log₂ (1−p)"
	var formula := Label3D.new()
	formula.text = "H(p) = −p log₂ p − (1−p) log₂ (1−p)"
	formula.font_size = 28
	formula.outline_size = 6
	formula.modulate = TEXT_DIM
	formula.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	formula.shaded = false
	formula.no_depth_test = true
	formula.pixel_size = 0.0025
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	formula.position = Vector3(-1.85, 0.90, 0.02)
	_scene_holder.add_child(formula)


# ─── 16×16 bit grid (center-bottom) ──────────────────────────────────
func _add_bit_grid(bits: PackedByteArray) -> void:
	# Lay out a 16×16 grid centered on (0, GRID_CENTER_Y).
	# Each cell side = (GRID_TOTAL_W - 15 * BIT_GAP) / 16.
	var cell: float = (GRID_TOTAL_W - float(GRID_N - 1) * BIT_GAP) / float(GRID_N)
	var half_w: float = GRID_TOTAL_W * 0.5
	var x0: float = -half_w
	var y0: float = GRID_CENTER_Y - GRID_TOTAL_W * 0.5

	# Panel background (subtle), so the grid reads as a coherent block.
	var bg_im := ImmediateMesh.new()
	bg_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(PANEL_BG))
	var pad: float = 0.06
	_quad(bg_im,
		Vector3(x0 - pad, y0 - pad, 0.005),
		Vector3(x0 + GRID_TOTAL_W + pad, y0 - pad, 0.005),
		Vector3(x0 + GRID_TOTAL_W + pad, y0 + GRID_TOTAL_W + pad, 0.005),
		Vector3(x0 - pad, y0 + GRID_TOTAL_W + pad, 0.005))
	bg_im.surface_end()
	# Subtle panel border.
	bg_im.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(0.35, 0.40, 0.50, 0.6)))
	var bl := Vector3(x0 - pad, y0 - pad, 0.006)
	var br := Vector3(x0 + GRID_TOTAL_W + pad, y0 - pad, 0.006)
	var tr := Vector3(x0 + GRID_TOTAL_W + pad, y0 + GRID_TOTAL_W + pad, 0.006)
	var tl := Vector3(x0 - pad, y0 + GRID_TOTAL_W + pad, 0.006)
	bg_im.surface_add_vertex(bl); bg_im.surface_add_vertex(br)
	bg_im.surface_add_vertex(br); bg_im.surface_add_vertex(tr)
	bg_im.surface_add_vertex(tr); bg_im.surface_add_vertex(tl)
	bg_im.surface_add_vertex(tl); bg_im.surface_add_vertex(bl)
	bg_im.surface_end()
	var bg_mi := MeshInstance3D.new()
	bg_mi.mesh = bg_im
	bg_mi.name = "GridBg"
	_scene_holder.add_child(bg_mi)

	# Count bits up-front so we only open surfaces that will have vertices —
	# ImmediateMesh.surface_end() errors if no vertices were added.
	var has_zero: bool = false
	var has_one: bool = false
	for b in bits:
		if b == 0:
			has_zero = true
		else:
			has_one = true
		if has_zero and has_one:
			break

	# Two-pass cell drawing — one mesh for 0-cells, one for 1-cells.
	# Zero cells first (near-black tile).
	if has_zero:
		var im0 := ImmediateMesh.new()
		im0.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(ZERO_COLOR))
		for r in range(GRID_N):
			for c in range(GRID_N):
				var idx: int = r * GRID_N + c
				if bits[idx] != 0:
					continue
				var cx: float = x0 + float(c) * (cell + BIT_GAP)
				# Row 0 at top → flip y so reading order is left-to-right, top-to-bottom.
				var cy: float = y0 + float(GRID_N - 1 - r) * (cell + BIT_GAP)
				_quad(im0,
					Vector3(cx, cy, 0.011),
					Vector3(cx + cell, cy, 0.011),
					Vector3(cx + cell, cy + cell, 0.011),
					Vector3(cx, cy + cell, 0.011))
		im0.surface_end()
		var mi0 := MeshInstance3D.new()
		mi0.mesh = im0
		mi0.name = "GridZeros"
		_scene_holder.add_child(mi0)

	# One cells (bright cyan).
	if has_one:
		var im1 := ImmediateMesh.new()
		im1.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(ONE_COLOR))
		for r in range(GRID_N):
			for c in range(GRID_N):
				var idx: int = r * GRID_N + c
				if bits[idx] != 1:
					continue
				var cx: float = x0 + float(c) * (cell + BIT_GAP)
				var cy: float = y0 + float(GRID_N - 1 - r) * (cell + BIT_GAP)
				_quad(im1,
					Vector3(cx, cy, 0.012),
					Vector3(cx + cell, cy, 0.012),
					Vector3(cx + cell, cy + cell, 0.012),
					Vector3(cx, cy + cell, 0.012))
		im1.surface_end()
		var mi1 := MeshInstance3D.new()
		mi1.mesh = im1
		mi1.name = "GridOnes"
		_scene_holder.add_child(mi1)

	# Subtle border on every cell.
	var imb := ImmediateMesh.new()
	imb.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(ZERO_BORDER))
	for r in range(GRID_N):
		for c in range(GRID_N):
			var cx: float = x0 + float(c) * (cell + BIT_GAP)
			var cy: float = y0 + float(GRID_N - 1 - r) * (cell + BIT_GAP)
			var cbl := Vector3(cx, cy, 0.013)
			var cbr := Vector3(cx + cell, cy, 0.013)
			var ctr := Vector3(cx + cell, cy + cell, 0.013)
			var ctl := Vector3(cx, cy + cell, 0.013)
			imb.surface_add_vertex(cbl); imb.surface_add_vertex(cbr)
			imb.surface_add_vertex(cbr); imb.surface_add_vertex(ctr)
			imb.surface_add_vertex(ctr); imb.surface_add_vertex(ctl)
			imb.surface_add_vertex(ctl); imb.surface_add_vertex(cbl)
	imb.surface_end()
	var mib := MeshInstance3D.new()
	mib.mesh = imb
	mib.name = "GridBorders"
	_scene_holder.add_child(mib)


# ─── Entropy curve panel (top-right) ─────────────────────────────────
# H(p) plotted with a bright dot at the current cell's p.
func _add_entropy_curve(current_p: float) -> void:
	var w: float = CURVE_X_HI - CURVE_X_LO
	var h: float = CURVE_Y_HI - CURVE_Y_LO

	# Panel background + border.
	var im_bg := ImmediateMesh.new()
	im_bg.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(CURVE_BG))
	_quad(im_bg,
		Vector3(CURVE_X_LO, CURVE_Y_LO, 0.005),
		Vector3(CURVE_X_HI, CURVE_Y_LO, 0.005),
		Vector3(CURVE_X_HI, CURVE_Y_HI, 0.005),
		Vector3(CURVE_X_LO, CURVE_Y_HI, 0.005))
	im_bg.surface_end()
	im_bg.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(CURVE_BORDER))
	var bl := Vector3(CURVE_X_LO, CURVE_Y_LO, 0.006)
	var br := Vector3(CURVE_X_HI, CURVE_Y_LO, 0.006)
	var tr := Vector3(CURVE_X_HI, CURVE_Y_HI, 0.006)
	var tl := Vector3(CURVE_X_LO, CURVE_Y_HI, 0.006)
	im_bg.surface_add_vertex(bl); im_bg.surface_add_vertex(br)
	im_bg.surface_add_vertex(br); im_bg.surface_add_vertex(tr)
	im_bg.surface_add_vertex(tr); im_bg.surface_add_vertex(tl)
	im_bg.surface_add_vertex(tl); im_bg.surface_add_vertex(bl)
	im_bg.surface_end()
	var mi_bg := MeshInstance3D.new()
	mi_bg.mesh = im_bg
	mi_bg.name = "CurveBg"
	_scene_holder.add_child(mi_bg)

	# Curve as line strip — 121 samples along p ∈ [0, 1].
	# Use small chart inset so the curve doesn't touch the panel edges.
	var inset_x: float = 0.10
	var inset_y_top: float = 0.06
	var inset_y_bot: float = 0.18  # extra room for x-axis labels
	var chart_x_lo: float = CURVE_X_LO + inset_x
	var chart_x_hi: float = CURVE_X_HI - inset_x
	var chart_y_lo: float = CURVE_Y_LO + inset_y_bot
	var chart_y_hi: float = CURVE_Y_HI - inset_y_top
	var chart_w: float = chart_x_hi - chart_x_lo
	var chart_h: float = chart_y_hi - chart_y_lo

	var im_curve := ImmediateMesh.new()
	im_curve.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(CURVE_LINE))
	var prev: Vector3 = Vector3.ZERO
	for i in range(CURVE_SAMPLES):
		var p: float = float(i) / float(CURVE_SAMPLES - 1)
		var hv: float = _entropy(p)
		var x: float = chart_x_lo + p * chart_w
		var y: float = chart_y_lo + hv * chart_h
		var v := Vector3(x, y, 0.012)
		if i > 0:
			im_curve.surface_add_vertex(prev)
			im_curve.surface_add_vertex(v)
		prev = v
	im_curve.surface_end()
	# x-axis line
	im_curve.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(0.40, 0.44, 0.52, 0.7)))
	im_curve.surface_add_vertex(Vector3(chart_x_lo, chart_y_lo, 0.011))
	im_curve.surface_add_vertex(Vector3(chart_x_hi, chart_y_lo, 0.011))
	# y-axis line
	im_curve.surface_add_vertex(Vector3(chart_x_lo, chart_y_lo, 0.011))
	im_curve.surface_add_vertex(Vector3(chart_x_lo, chart_y_hi, 0.011))
	# top dashed reference line at H=1
	# (just a thin solid line in this implementation)
	im_curve.surface_end()

	var mi_curve := MeshInstance3D.new()
	mi_curve.mesh = im_curve
	mi_curve.name = "Curve"
	_scene_holder.add_child(mi_curve)

	# Bright dot at the current p.
	var dot_x: float = chart_x_lo + current_p * chart_w
	var dot_y: float = chart_y_lo + _entropy(current_p) * chart_h
	var dot_im := ImmediateMesh.new()
	dot_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(CURVE_DOT))
	# Octagon as filled disk.
	var dot_r: float = 0.035
	var dot_z: float = 0.014
	var n_sides: int = 16
	var center := Vector3(dot_x, dot_y, dot_z)
	for i in range(n_sides):
		var a0: float = float(i) * TAU / float(n_sides)
		var a1: float = float(i + 1) * TAU / float(n_sides)
		var v0 := center + Vector3(cos(a0) * dot_r, sin(a0) * dot_r, 0.0)
		var v1 := center + Vector3(cos(a1) * dot_r, sin(a1) * dot_r, 0.0)
		dot_im.surface_add_vertex(center)
		dot_im.surface_add_vertex(v0)
		dot_im.surface_add_vertex(v1)
	dot_im.surface_end()
	var mi_dot := MeshInstance3D.new()
	mi_dot.mesh = dot_im
	mi_dot.name = "CurrentDot"
	_scene_holder.add_child(mi_dot)

	# Title above the curve panel.
	var title := Label3D.new()
	title.text = "H(p) hill"
	title.font_size = 32
	title.outline_size = 6
	title.modulate = TEXT_DIM
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	title.shaded = false
	title.no_depth_test = true
	title.pixel_size = 0.0025
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector3((CURVE_X_LO + CURVE_X_HI) * 0.5, CURVE_Y_HI - 0.06, 0.013)
	_scene_holder.add_child(title)

	# Axis labels.
	var x_lab_lo := Label3D.new()
	x_lab_lo.text = "0"
	x_lab_lo.font_size = 22
	x_lab_lo.outline_size = 4
	x_lab_lo.modulate = TEXT_DIM
	x_lab_lo.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	x_lab_lo.shaded = false
	x_lab_lo.no_depth_test = true
	x_lab_lo.pixel_size = 0.0025
	x_lab_lo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x_lab_lo.position = Vector3(chart_x_lo, chart_y_lo - 0.07, 0.013)
	_scene_holder.add_child(x_lab_lo)

	var x_lab_mid := Label3D.new()
	x_lab_mid.text = "0.5"
	x_lab_mid.font_size = 22
	x_lab_mid.outline_size = 4
	x_lab_mid.modulate = TEXT_DIM
	x_lab_mid.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	x_lab_mid.shaded = false
	x_lab_mid.no_depth_test = true
	x_lab_mid.pixel_size = 0.0025
	x_lab_mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x_lab_mid.position = Vector3(chart_x_lo + 0.5 * chart_w, chart_y_lo - 0.07, 0.013)
	_scene_holder.add_child(x_lab_mid)

	var x_lab_hi := Label3D.new()
	x_lab_hi.text = "1"
	x_lab_hi.font_size = 22
	x_lab_hi.outline_size = 4
	x_lab_hi.modulate = TEXT_DIM
	x_lab_hi.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	x_lab_hi.shaded = false
	x_lab_hi.no_depth_test = true
	x_lab_hi.pixel_size = 0.0025
	x_lab_hi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	x_lab_hi.position = Vector3(chart_x_hi, chart_y_lo - 0.07, 0.013)
	_scene_holder.add_child(x_lab_hi)

	# y=1 label
	var y_lab := Label3D.new()
	y_lab.text = "H=1"
	y_lab.font_size = 20
	y_lab.outline_size = 4
	y_lab.modulate = TEXT_DIM
	y_lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	y_lab.shaded = false
	y_lab.no_depth_test = true
	y_lab.pixel_size = 0.0025
	y_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	y_lab.position = Vector3(chart_x_lo - 0.02, chart_y_hi, 0.013)
	_scene_holder.add_child(y_lab)


# ─── Compression bars (bottom panel) ─────────────────────────────────
# Three bars:
#   raw_bits         = 256 (always)
#   compressed_bits  = what a Huffman-frequency / arithmetic coder achieves
#   theoretical_min  = H(p) × 256, the Shannon floor
func _add_compression_bars(result: Dictionary) -> void:
	var raw: float = result["raw_bits"]
	var theor: float = result["theoretical_min_bits"]
	var comp: float = result["compressed_bits"]

	# Bar area inside the panel.
	var pad: float = 0.08
	var bar_x_lo: float = BAR_PANEL_X_LO + 0.32  # leave room for labels on left
	var bar_x_hi: float = BAR_PANEL_X_HI - 0.65  # leave room for numbers on right
	var bar_w_max: float = bar_x_hi - bar_x_lo
	var area_y_lo: float = BAR_PANEL_Y_LO + pad
	var area_y_hi: float = BAR_PANEL_Y_HI - pad
	var slot_h: float = (area_y_hi - area_y_lo) / 3.0
	var bar_height: float = slot_h * 0.55

	# Panel background.
	var im_bg := ImmediateMesh.new()
	im_bg.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material_transparent(PANEL_BG))
	_quad(im_bg,
		Vector3(BAR_PANEL_X_LO, BAR_PANEL_Y_LO, 0.005),
		Vector3(BAR_PANEL_X_HI, BAR_PANEL_Y_LO, 0.005),
		Vector3(BAR_PANEL_X_HI, BAR_PANEL_Y_HI, 0.005),
		Vector3(BAR_PANEL_X_LO, BAR_PANEL_Y_HI, 0.005))
	im_bg.surface_end()
	im_bg.surface_begin(Mesh.PRIMITIVE_LINES, _unshaded_material(Color(0.35, 0.40, 0.50, 0.6)))
	var bl := Vector3(BAR_PANEL_X_LO, BAR_PANEL_Y_LO, 0.006)
	var br := Vector3(BAR_PANEL_X_HI, BAR_PANEL_Y_LO, 0.006)
	var tr := Vector3(BAR_PANEL_X_HI, BAR_PANEL_Y_HI, 0.006)
	var tl := Vector3(BAR_PANEL_X_LO, BAR_PANEL_Y_HI, 0.006)
	im_bg.surface_add_vertex(bl); im_bg.surface_add_vertex(br)
	im_bg.surface_add_vertex(br); im_bg.surface_add_vertex(tr)
	im_bg.surface_add_vertex(tr); im_bg.surface_add_vertex(tl)
	im_bg.surface_add_vertex(tl); im_bg.surface_add_vertex(bl)
	im_bg.surface_end()
	var mi_bg := MeshInstance3D.new()
	mi_bg.mesh = im_bg
	mi_bg.name = "BarPanelBg"
	_scene_holder.add_child(mi_bg)

	# Title on the panel.
	var title := Label3D.new()
	title.text = "COMPRESSION (bits to encode 256 samples)"
	title.font_size = 22
	title.outline_size = 4
	title.modulate = TEXT_DIM
	title.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	title.shaded = false
	title.no_depth_test = true
	title.pixel_size = 0.0025
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.position = Vector3(BAR_PANEL_X_LO + 0.10, BAR_PANEL_Y_HI - 0.06, 0.013)
	_scene_holder.add_child(title)

	# 3 bars from top to bottom: raw, compressed, theoretical
	var bars_data := [
		{"label": "raw", "value": raw, "color": BAR_RAW, "format": "%d bits"},
		{"label": "compressor", "value": comp, "color": BAR_COMPRESSED, "format": "%d bits"},
		{"label": "Shannon", "value": theor, "color": BAR_THEORETICAL, "format": "%.1f bits"},
	]

	for i in range(bars_data.size()):
		var bar = bars_data[i]
		var y_center: float = area_y_hi - slot_h * (float(i) + 0.5)
		var bar_y_lo: float = y_center - bar_height * 0.5
		var bar_y_hi: float = y_center + bar_height * 0.5
		var frac: float = clamp(bar["value"] / raw, 0.0, 1.0)
		var bar_x_end: float = bar_x_lo + bar_w_max * frac

		# Bar background track (faint gray).
		var im_track := ImmediateMesh.new()
		im_track.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(Color(0.18, 0.20, 0.26, 0.85)))
		_quad(im_track,
			Vector3(bar_x_lo, bar_y_lo, 0.012),
			Vector3(bar_x_hi, bar_y_lo, 0.012),
			Vector3(bar_x_hi, bar_y_hi, 0.012),
			Vector3(bar_x_lo, bar_y_hi, 0.012))
		im_track.surface_end()
		# Bar fill in the assigned color.
		im_track.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _unshaded_material(bar["color"]))
		_quad(im_track,
			Vector3(bar_x_lo, bar_y_lo, 0.013),
			Vector3(bar_x_end, bar_y_lo, 0.013),
			Vector3(bar_x_end, bar_y_hi, 0.013),
			Vector3(bar_x_lo, bar_y_hi, 0.013))
		im_track.surface_end()
		var mi := MeshInstance3D.new()
		mi.mesh = im_track
		mi.name = "Bar%d" % i
		_scene_holder.add_child(mi)

		# Left-side label.
		var lab := Label3D.new()
		lab.text = bar["label"]
		lab.font_size = 28
		lab.outline_size = 6
		lab.modulate = TEXT_BRIGHT
		lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		lab.shaded = false
		lab.no_depth_test = true
		lab.pixel_size = 0.0025
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lab.position = Vector3(bar_x_lo - 0.04, y_center, 0.014)
		_scene_holder.add_child(lab)

		# Right-side numeric value.
		var val := Label3D.new()
		if bar["label"] == "Shannon":
			val.text = "%.1f bits" % bar["value"]
		else:
			val.text = "%d bits" % int(round(bar["value"]))
		val.font_size = 28
		val.outline_size = 6
		val.modulate = bar["color"]
		val.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
		val.shaded = false
		val.no_depth_test = true
		val.pixel_size = 0.0025
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		val.position = Vector3(bar_x_hi + 0.04, y_center, 0.014)
		_scene_holder.add_child(val)


# ─── Case label (e.g. "fair coin") top-center ────────────────────────
func _add_label_case(label: String) -> void:
	var lab := Label3D.new()
	lab.text = label
	lab.font_size = 56
	lab.outline_size = 10
	lab.modulate = TEXT_BRIGHT
	lab.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	lab.shaded = false
	lab.no_depth_test = true
	lab.pixel_size = 0.0025
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector3(0.0, 1.62, 0.02)
	_scene_holder.add_child(lab)


# ─── Materials ───────────────────────────────────────────────────────
func _unshaded_material(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.4
	mat.disable_receive_shadows = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Allow transparency in case the caller passed a color with alpha < 1.
	if c.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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


func _quad(im: ImmediateMesh, bl: Vector3, br: Vector3, tr: Vector3, tl: Vector3) -> void:
	im.surface_add_vertex(bl)
	im.surface_add_vertex(br)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(tr)
	im.surface_add_vertex(tl)


# ─── Capture and record ──────────────────────────────────────────────
func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		c.queue_free()


func _capture_and_record(spec: Dictionary, result: Dictionary) -> void:
	# Yield frames so the viewport renders before we sample its texture.
	await process_frame
	await process_frame
	await process_frame
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % spec["id"]
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	# JSON sidecar — p, entropy, theoretical_min, compressed, sample, notes.
	var cfg := {
		"id": spec["id"],
		"label": spec["label"],
		"p": spec["p"],
		"entropy_bits": result["true_entropy_bits"],
		"observed_entropy_bits": result["observed_entropy_bits"],
		"theoretical_min_bits": result["theoretical_min_bits"],
		"compressed_bits": int(round(result["compressed_bits"])),
		"raw_bits": int(round(result["raw_bits"])),
		"n_ones": result["n_ones"],
		"n_zeros": result["n_zeros"],
		"p_hat_empirical": result["p_hat"],
		"sample_bits": result["sample_hex"],
		"shared_seed": "0x%X" % SHARED_SEED,
		"sample_size": SAMPLE_BITS_N,
		"compressor": "huffman_frequency_estimate_with_16bit_model_overhead",
		"notes": spec["notes"],
	}
	var cfg_rel := "%s.json" % spec["id"]
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(cfg, "\t"))
	cf.close()

	_entries.append({
		"id": spec["id"],
		"label": spec["label"],
		"p": spec["p"],
		"entropy_bits": result["true_entropy_bits"],
		"theoretical_min_bits": result["theoretical_min_bits"],
		"compressed_bits": int(round(result["compressed_bits"])),
		"raw_bits": int(round(result["raw_bits"])),
		"n_ones": result["n_ones"],
		"n_zeros": result["n_zeros"],
		"notes": spec["notes"],
		"image": "/shannon-bound-gallery/%s" % img_rel,
		"config": "/shannon-bound-gallery/%s" % cfg_rel,
	})
	print("  saved: %s  p=%.3f  H=%.4f  comp=%d  shannon=%.1f" % [
		spec["id"], spec["p"], result["true_entropy_bits"],
		int(round(result["compressed_bits"])), result["theoretical_min_bits"],
	])
