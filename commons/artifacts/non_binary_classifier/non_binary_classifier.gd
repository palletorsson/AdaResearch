extends Node3D
class_name NonBinaryClassifier

# @identity
# essence: a scatter of sixty samples filling a lit table, a violet slab of undecided ground lying across it, and a curved decision boundary floating above both as a standing ribbon — taking gradient steps every frame and never arriving, because every sample caught inside that slab has its label re-drawn before the optimiser can use it
# desire: to refuse the demonstration where a classifier converges and the lesson is that categories are findable — this one runs the same arithmetic and cannot stop, and the reason is legible on the table
# critical_parameter: margin_width — the half-width of the undecided band, in RMS score units, which is also the visible half-width of the violet slab. At 0 no sample is ever relabelled, the loss descends, and the boundary snaps to a hard binary split within seconds; widened, the slab swallows enough of the population that it can never close
# triggers: _process runs gradient_steps descents on logistic loss over a quadratic feature map, then every relabel_period frames re-draws the label of each sample whose score falls inside the margin; the boundary is re-contoured by marching squares over the live score field and the margin band is re-filled cell by cell from the same sampling
# emerges: the boundary keeps moving BECAUSE the ambiguous samples refuse to resolve — the drift readout goes to zero the moment the margin does, which is the proof that this is not a broken optimiser but a contested ground truth; the slab is the visible extent of what the model will not commit to, and the magenta samples standing in it are the reason it cannot
# needs: ImmediateMesh for the boundary ribbon, the margin walls and the margin slab [Godot built-in]; SphereMesh samples [built-in]; Grid.gdshader for the table [present]; TextScreen plate [present]
# relationships: the speculative-computation answer to excluded_class_visualizer — that one shows who is outside a fixed line, this one shows a line that cannot fix itself while they are inside it
# truth: a classifier does not fail on ambiguous cases. It fails to terminate. Convergence was never a property of the algorithm; it was a promise about the data, and the promise was that everyone had already been sorted.

## The non-binary classifier for the speculativecomputation sequence.
##
## Model: logistic regression over the quadratic feature map
##   φ(x, z) = [1, x, z, x², x·z, z²]
## so the zero set of w·φ is a conic — a curve that genuinely bends, not a line
## wearing a curve's name. The boundary is drawn by marching squares over a
## 28×28 sampling of w·φ, extruded into a ribbon that floats clear of the deck.
##
## Under it, the region |w·φ| < margin_width is filled as a translucent violet
## slab: capped on top, walled at the ±margin level sets, with the samples
## standing inside it. The slab is not decoration for the margin — it is the
## margin, drawn at the size it actually occupies on the table, so the magenta
## dots inside it are visibly the population being re-labelled.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ── Configuration ────────────────────────────────────────────────────

## THE critical parameter. Half-width of the undecided band, in RMS score units
## (the weight vector is held at unit RMS, so this is a stable fraction of the
## field and not a quantity that shrinks as training proceeds).
## 0.0 → the classifier converges and stops. Anything above ~0.15 → it cannot.
@export var margin_width: float = 0.55
@export var sample_count: int = 60
## Gradient descent steps taken per rendered frame.
@export var gradient_steps: int = 6
@export var learning_rate: float = 0.55
## Frames between relabelling passes over the margin band.
@export var relabel_period: int = 4
@export var build_seed: int = 20260729

@export_group("Table")
## Low enough that the boundary can float clear of the deck and the whole
## artifact still fits under the 1 m of its declared 2×1×2 footprint.
@export var deck_height: float = 0.74
@export var deck_size: float = 1.88
## Half-extent of the field in table metres. Model space is ±1.
@export var field_half: float = 0.84
## Sample radius. Sized against the field, not against the eye: 60 dots on a
## 1.7 m board have to be this big to read as a population rather than dust.
@export var dot_radius: float = 0.036

@export_group("Boundary")
## Marching-squares resolution over the score field.
@export var contour_res: int = 28
## How tall the boundary ribbon stands.
@export var ribbon_height: float = 0.20
## How far the boundary floats above the deck. Non-zero on purpose: at 0 the
## boundary is a decal on the table, and a decal is a fact about the surface
## rather than an object with a position of its own.
@export var boundary_lift: float = 0.115
## Redraws per second of the contour. The gradient still runs every frame.
@export var contour_hz: float = 20.0

@export_group("Margin band")
## Underside and top cap of the translucent slab, above the field plane.
@export var band_floor: float = 0.014
@export var band_ceiling: float = 0.086

# ── Palette ──────────────────────────────────────────────────────────

const COL_A := Color(0.38, 0.80, 1.00)
const COL_B := Color(1.00, 0.78, 0.30)
const COL_AMBIG := Color(1.00, 0.35, 0.85)
const COL_BOUND := Color(0.95, 0.97, 1.00)
const COL_MARGIN := Color(0.60, 0.45, 0.85)

const FEATURES := 6

# ── State ────────────────────────────────────────────────────────────

## Sample positions in model space, x and z each in [-1, 1].
var _sx: Array[float] = []
var _sz: Array[float] = []
## Current label, +1 or -1. Not ground truth — nothing here has ground truth.
var _label: Array[float] = []
## Whether this sample sat inside the margin at the last relabel pass.
var _ambiguous: Array[bool] = []
var _dots: Array[Node] = []

var _w: Array[float] = []

var _field_root: Node3D
var _bound_mesh: ImmediateMesh
var _margin_mesh: ImmediateMesh
var _band_mesh: ImmediateMesh
var _readout: Label3D
var _rng := RandomNumberGenerator.new()

var _frame: int = 0
var _accum: float = 0.0
## Exponential moving average of how far the boundary moved between contours.
var _drift: float = 0.0
var _last_centroid := Vector2.ZERO
var _has_centroid := false
var _ambig_count: int = 0

var _created: Array[Node] = []
var _built := false


func _ready() -> void:
	_build_all()
	_built = true


func _build_all() -> void:
	_rng.seed = build_seed
	_seed_samples()
	_seed_weights()
	_fix_the_gauge()   # so frame zero is drawn in the same units as every frame after it
	_build_table()
	_build_field()
	_build_plate()
	_redraw_contours()
	_refresh_readout()


func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


# ── The samples ──────────────────────────────────────────────────────

## Two lobes with a deliberately overlapping waist. The overlap is not sloppy
## sampling — it is the population the margin will spend the rest of the
## artifact's life failing to sort.
func _seed_samples() -> void:
	_sx.clear()
	_sz.clear()
	_label.clear()
	_ambiguous.clear()
	var n: int = maxi(8, sample_count)
	for i in range(n):
		var side: float = 1.0 if i % 2 == 0 else -1.0
		var cx: float = side * 0.50
		var cz: float = side * 0.34
		# Wide enough that the two lobes reach the edges of the board. A scatter
		# huddled in the middle of its own field looks like a shortage of data;
		# the shortage here is of a line, not of samples.
		var x: float = clampf(cx + _rng.randfn(0.0, 0.47), -0.97, 0.97)
		var z: float = clampf(cz + _rng.randfn(0.0, 0.49), -0.97, 0.97)
		_sx.append(x)
		_sz.append(z)
		_label.append(side)
		_ambiguous.append(false)


func _seed_weights() -> void:
	_w.clear()
	for i in range(FEATURES):
		_w.append(_rng.randf_range(-0.20, 0.20))


## The feature map φ(x, z) = [1, x, z, x², x·z, z²]. Written out at both call
## sites rather than returned as an array: this runs 60 samples × 6 steps ×
## 90 frames a second, and an allocation there is 32 000 short-lived arrays a
## second for six floats each.
func _score(x: float, z: float) -> float:
	return (float(_w[0])
		+ float(_w[1]) * x
		+ float(_w[2]) * z
		+ float(_w[3]) * x * x
		+ float(_w[4]) * x * z
		+ float(_w[5]) * z * z)


# ── The loop that will not finish ────────────────────────────────────

func _process(delta: float) -> void:
	if _sx.is_empty():
		return
	_frame += 1
	for _s in range(maxi(1, gradient_steps)):
		_descend()
	_fix_the_gauge()
	if relabel_period > 0 and _frame % relabel_period == 0:
		_relabel_the_undecided()

	_accum += delta
	var period: float = 1.0 / maxf(1.0, contour_hz)
	if _accum >= period:
		_accum = 0.0
		_redraw_contours()
		_refresh_readout()


## One full-batch step on logistic loss. Deliberately plain: if the boundary
## never settles, nobody should be able to blame the optimiser.
func _descend() -> void:
	var n: int = _sx.size()
	if n == 0:
		return
	var g0: float = 0.0
	var g1: float = 0.0
	var g2: float = 0.0
	var g3: float = 0.0
	var g4: float = 0.0
	var g5: float = 0.0
	for k in range(n):
		var x: float = float(_sx[k])
		var z: float = float(_sz[k])
		var y: float = float(_label[k])
		var s: float = _score(x, z)
		# d/ds of log(1 + exp(-y·s)) = -y · σ(-y·s)
		var sig: float = 1.0 / (1.0 + exp(clampf(y * s, -30.0, 30.0)))
		var c: float = -y * sig
		g0 += c
		g1 += c * x
		g2 += c * z
		g3 += c * x * x
		g4 += c * x * z
		g5 += c * z * z
	var grad: Array[float] = [g0, g1, g2, g3, g4, g5]
	var scale: float = learning_rate / float(n)
	for i in range(FEATURES):
		# A weak decay, kept from the plain version; the gauge fix below is what
		# actually holds the scale. Neither stops convergence — set margin_width
		# to 0 and watch it stop.
		_w[i] = float(_w[i]) * 0.9995 - scale * float(grad[i])


## Scale the whole weight vector to unit RMS score over the samples.
##
## Uniform scaling of w leaves the zero set of w·φ exactly where it was, so this
## does nothing to the boundary and nothing to the descent's direction. What it
## fixes is the UNIT the margin is measured in. Logistic loss rewards ever-larger
## weights on data it has already separated, and an unscaled run inflates every
## score until a margin of 0.55 covers a sliver of the table and the undecided
## population empties out — the artifact would look like it had settled while
## still churning. Held at RMS 1, margin_width means a stable fraction of the
## field, and the band keeps the width it is set to.
func _fix_the_gauge() -> void:
	var n: int = _sx.size()
	if n == 0:
		return
	var acc: float = 0.0
	for k in range(n):
		var s: float = _score(float(_sx[k]), float(_sz[k]))
		acc += s * s
	var rms: float = sqrt(acc / float(n))
	if rms < 1.0e-4:
		return
	var inv: float = 1.0 / rms
	for i in range(FEATURES):
		_w[i] = float(_w[i]) * inv


## THE MECHANISM. Every sample whose score falls inside the margin has its label
## re-drawn from the model's own current confidence. Outside the band nothing is
## touched. At margin_width = 0 this loop assigns nothing and the descent above
## is an ordinary logistic regression that converges like any other.
func _relabel_the_undecided() -> void:
	var m: float = maxf(0.0, margin_width)
	_ambig_count = 0
	for k in range(_sx.size()):
		var s: float = _score(float(_sx[k]), float(_sz[k]))
		var inside: bool = absf(s) < m
		_ambiguous[k] = inside
		if not inside:
			continue
		_ambig_count += 1
		# Confidence read against the band's own half-width rather than against
		# raw score units, now that the gauge holds those at RMS 1: a sample
		# standing at the wall keeps its label about nine times in ten, one at
		# the centre of the band is a coin flip. Churn concentrated where the
		# model has genuinely nothing to say, instead of smeared over the band.
		var t: float = maxf(1.0e-4, m * 0.5)
		var p: float = 1.0 / (1.0 + exp(clampf(-s / t, -30.0, 30.0)))
		_label[k] = 1.0 if _rng.randf() < p else -1.0
	_repaint_dots()


# ── Field, samples, boundary ─────────────────────────────────────────

func _model_to_local(x: float, z: float) -> Vector3:
	return Vector3(x * field_half, 0.0, z * field_half)


func _build_field() -> void:
	_field_root = Node3D.new()
	_field_root.name = "Field"
	_field_root.position = Vector3(0.0, deck_height + 0.012, 0.0)
	_own(_field_root)

	_dots.clear()
	var r: float = maxf(0.006, dot_radius)
	for k in range(_sx.size()):
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 12
		sm.rings = 7
		dot.mesh = sm
		dot.material_override = _emissive(COL_A, 2.0)
		# Seated so the samples stand inside the margin slab rather than under it.
		dot.position = _model_to_local(float(_sx[k]), float(_sz[k])) + Vector3(0.0, r, 0.0)
		_field_root.add_child(dot)
		_dots.append(dot)
	_repaint_dots()

	# The margin, at the size it actually occupies. Drawn before the boundary so
	# the ribbon reads as floating over it.
	_band_mesh = ImmediateMesh.new()
	var dmi := MeshInstance3D.new()
	dmi.name = "MarginSlab"
	dmi.mesh = _band_mesh
	dmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dmat := _emissive(COL_MARGIN, 0.9)
	dmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.albedo_color = Color(COL_MARGIN.r, COL_MARGIN.g, COL_MARGIN.b, 0.22)
	dmi.material_override = dmat
	_field_root.add_child(dmi)

	_bound_mesh = ImmediateMesh.new()
	var bmi := MeshInstance3D.new()
	bmi.name = "Boundary"
	bmi.mesh = _bound_mesh
	bmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bmat := _emissive(COL_BOUND, 2.4)
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bmi.material_override = bmat
	_field_root.add_child(bmi)

	_margin_mesh = ImmediateMesh.new()
	var mmi := MeshInstance3D.new()
	mmi.name = "MarginBand"
	mmi.mesh = _margin_mesh
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mmat := _emissive(COL_MARGIN, 1.3)
	mmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mmat.albedo_color = Color(COL_MARGIN.r, COL_MARGIN.g, COL_MARGIN.b, 0.55)
	mmi.material_override = mmat
	_field_root.add_child(mmi)


func _repaint_dots() -> void:
	for k in range(_dots.size()):
		var dot: Node = _dots[k]
		if not is_instance_valid(dot):
			continue
		var mat: StandardMaterial3D = (dot as MeshInstance3D).material_override as StandardMaterial3D
		if mat == null:
			continue
		var amb: bool = k < _ambiguous.size() and bool(_ambiguous[k])
		var c: Color = COL_A if float(_label[k]) > 0.0 else COL_B
		if amb:
			c = COL_AMBIG
		mat.albedo_color = c
		mat.emission = c
		mat.emission_energy_multiplier = 3.4 if amb else 2.0
		# Undecided samples swell. Colour alone loses the argument against a
		# violet slab sitting between them and the eye. Re-seated as they grow,
		# so a swollen sample stands on the field instead of sinking into it.
		var s: float = 1.5 if amb else 1.0
		var mi: MeshInstance3D = dot as MeshInstance3D
		mi.scale = Vector3(s, s, s)
		var p: Vector3 = mi.position
		mi.position = Vector3(p.x, maxf(0.006, dot_radius) * s, p.z)


## Marching squares over one sampling of the score field, at three levels: the
## decision boundary and the two margin walls. The same sampling is walked once
## more to cap the slab between the walls. Sampling once and reading it four
## times is the only reason this can run at 20 Hz in GDScript.
func _redraw_contours() -> void:
	if _bound_mesh == null or _margin_mesh == null:
		return
	var res: int = clampi(contour_res, 8, 64)
	var grid: Array = []
	for i in range(res + 1):
		var row: Array[float] = []
		var x: float = -1.0 + 2.0 * float(i) / float(res)
		for j in range(res + 1):
			var z: float = -1.0 + 2.0 * float(j) / float(res)
			row.append(_score(x, z))
		grid.append(row)

	var lift: float = maxf(0.0, boundary_lift)
	var segs: Array = _contour(grid, res, 0.0)
	_bound_mesh.clear_surfaces()
	if not segs.is_empty():
		_bound_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for s in segs:
			_ribbon(_bound_mesh, s[0], s[1], lift, ribbon_height)
		_bound_mesh.surface_end()

	var y0: float = minf(band_floor, band_ceiling)
	var y1: float = maxf(band_floor, band_ceiling)
	_margin_mesh.clear_surfaces()
	var m: float = maxf(0.0, margin_width)
	if m > 0.001:
		var walls: Array = _contour(grid, res, m)
		walls.append_array(_contour(grid, res, -m))
		if not walls.is_empty():
			_margin_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			for s2 in walls:
				_ribbon(_margin_mesh, s2[0], s2[1], y0, y1 - y0)
			_margin_mesh.surface_end()

	if _band_mesh != null:
		_band_mesh.clear_surfaces()
		if m > 0.001:
			_fill_band(grid, res, m, y1)

	_track_drift(segs)


## The cap of the margin slab: one horizontal quad per cell whose centre score
## falls inside the band. Cell-centre testing steps slightly against the walls,
## which is why the walls are drawn from the exact level sets and drawn on top —
## the crisp edge comes from them, the area comes from here.
func _fill_band(grid: Array, res: int, m: float, y: float) -> void:
	var step: float = 2.0 / float(res)
	var opened: bool = false
	for i in range(res):
		var col0: Array = grid[i]
		var col1: Array = grid[i + 1]
		for j in range(res):
			var avg: float = (float(col0[j]) + float(col1[j])
				+ float(col1[j + 1]) + float(col0[j + 1])) * 0.25
			if absf(avg) >= m:
				continue
			if not opened:
				_band_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
				opened = true
			var x0: float = -1.0 + step * float(i)
			var z0: float = -1.0 + step * float(j)
			var a: Vector3 = _model_to_local(x0, z0) + Vector3(0.0, y, 0.0)
			var b: Vector3 = _model_to_local(x0 + step, z0) + Vector3(0.0, y, 0.0)
			var c: Vector3 = _model_to_local(x0 + step, z0 + step) + Vector3(0.0, y, 0.0)
			var d: Vector3 = _model_to_local(x0, z0 + step) + Vector3(0.0, y, 0.0)
			_band_mesh.surface_set_normal(Vector3.UP)
			_band_mesh.surface_add_vertex(a)
			_band_mesh.surface_add_vertex(b)
			_band_mesh.surface_add_vertex(c)
			_band_mesh.surface_add_vertex(a)
			_band_mesh.surface_add_vertex(c)
			_band_mesh.surface_add_vertex(d)
	if opened:
		_band_mesh.surface_end()


## Zero crossings of (field − level) along cell edges, joined per cell. Returns
## an Array of [Vector2, Vector2] in MODEL space.
func _contour(grid: Array, res: int, level: float) -> Array:
	var out: Array = []
	var step: float = 2.0 / float(res)
	for i in range(res):
		var col0: Array = grid[i]
		var col1: Array = grid[i + 1]
		for j in range(res):
			var v00: float = float(col0[j]) - level
			var v10: float = float(col1[j]) - level
			var v11: float = float(col1[j + 1]) - level
			var v01: float = float(col0[j + 1]) - level
			var x0: float = -1.0 + step * float(i)
			var z0: float = -1.0 + step * float(j)
			var pts: Array = []
			if (v00 < 0.0) != (v10 < 0.0):
				pts.append(Vector2(x0 + step * _frac(v00, v10), z0))
			if (v10 < 0.0) != (v11 < 0.0):
				pts.append(Vector2(x0 + step, z0 + step * _frac(v10, v11)))
			if (v01 < 0.0) != (v11 < 0.0):
				pts.append(Vector2(x0 + step * _frac(v01, v11), z0 + step))
			if (v00 < 0.0) != (v01 < 0.0):
				pts.append(Vector2(x0, z0 + step * _frac(v00, v01)))
			# Two crossings is the ordinary case; four is a saddle, where the
			# pairing is ambiguous. Joining 0-1 and 2-3 picks one resolution of
			# the saddle — arbitrary, and it affects one cell in a few hundred.
			if pts.size() >= 2:
				out.append([pts[0], pts[1]])
			if pts.size() >= 4:
				out.append([pts[2], pts[3]])
	return out


func _frac(a: float, b: float) -> float:
	var d: float = b - a
	if absf(d) < 1.0e-9:
		return 0.5
	return clampf(-a / d, 0.0, 1.0)


## One segment of contour, extruded into a standing quad (two triangles), based
## at height y0 above the field plane.
func _ribbon(im: ImmediateMesh, p0: Vector2, p1: Vector2, y0: float, h: float) -> void:
	var a: Vector3 = _model_to_local(p0.x, p0.y) + Vector3(0.0, y0, 0.0)
	var b: Vector3 = _model_to_local(p1.x, p1.y) + Vector3(0.0, y0, 0.0)
	var au: Vector3 = a + Vector3(0.0, h, 0.0)
	var bu: Vector3 = b + Vector3(0.0, h, 0.0)
	im.surface_set_normal(Vector3.UP)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_add_vertex(bu)
	im.surface_add_vertex(a)
	im.surface_add_vertex(bu)
	im.surface_add_vertex(au)


## How far the boundary moved since the last contour, smoothed. This is the
## number that goes to zero when the margin does — the readout that separates
## "contested" from "broken".
func _track_drift(segs: Array) -> void:
	if segs.is_empty():
		_has_centroid = false
		return
	var acc := Vector2.ZERO
	for s in segs:
		var p0: Vector2 = s[0]
		var p1: Vector2 = s[1]
		acc += (p0 + p1) * 0.5
	var centroid: Vector2 = acc / float(segs.size())
	if _has_centroid:
		var d: float = centroid.distance_to(_last_centroid)
		_drift = _drift * 0.82 + d * 0.18
	_last_centroid = centroid
	_has_centroid = true


# ── Table + readout ──────────────────────────────────────────────────

func _build_table() -> void:
	var body := _grid_material(Color(0.28, 0.30, 0.36), Color(0.45, 0.50, 0.62), 0.5)
	var deck := MeshInstance3D.new()
	deck.name = "Deck"
	var dbox := BoxMesh.new()
	dbox.size = Vector3(deck_size, 0.06, deck_size)
	deck.mesh = dbox
	deck.position = Vector3(0.0, deck_height - 0.03, 0.0)
	deck.material_override = body
	_own(deck)

	# A near-black inlay: the field needs a ground dark enough for emissive
	# dots and a white ribbon to read against.
	var inlay := MeshInstance3D.new()
	inlay.name = "FieldInlay"
	var ibox := BoxMesh.new()
	ibox.size = Vector3(field_half * 2.0 + 0.08, 0.012, field_half * 2.0 + 0.08)
	inlay.mesh = ibox
	var imat := StandardMaterial3D.new()
	imat.albedo_color = Color(0.035, 0.04, 0.055)
	imat.roughness = 0.9
	inlay.material_override = imat
	inlay.position = Vector3(0.0, deck_height + 0.006, 0.0)
	_own(inlay)

	var leg_h: float = maxf(0.05, deck_height - 0.06)
	for xi in range(2):
		for zi in range(2):
			var lx: float = (-1.0 if xi == 0 else 1.0) * (deck_size * 0.5 - 0.11)
			var lz: float = (-1.0 if zi == 0 else 1.0) * (deck_size * 0.5 - 0.11)
			var leg := MeshInstance3D.new()
			var lbox := BoxMesh.new()
			lbox.size = Vector3(0.08, leg_h, 0.08)
			leg.mesh = lbox
			leg.position = Vector3(lx, leg_h * 0.5, lz)
			leg.material_override = body
			_own(leg)

	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.font_size = 26
	_readout.outline_size = 4
	_readout.pixel_size = 0.001
	_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readout.modulate = Color(0.88, 0.92, 1.0)
	# Below the top of the floating boundary, and the whole stack stays under
	# 1.10 m so the artifact's AABB honours its declared 2×1×2 footprint —
	# a billboard is measured into the bounds like anything else.
	_readout.position = Vector3(0.0, deck_height + 0.24, -deck_size * 0.5 + 0.06)
	_own(_readout)


func _refresh_readout() -> void:
	if _readout == null or not is_instance_valid(_readout):
		return
	var state: String = "SETTLED" if _drift < 0.0008 else "MOVING"
	_readout.text = "margin %.2f   ·   undecided %d/%d\ndrift %.4f   ·   %s" % [
		margin_width, _ambig_count, _sx.size(), _drift, state]


func _build_plate() -> void:
	# Configure BEFORE add_child — TextScreen's setters rebuild only in-tree.
	var ts := TextScreenScript.new()
	ts.name = "TablePlate"
	ts.mode = 2                      # Mode.PAD
	ts.width_m = 0.36
	ts.position = Vector3(0.0, deck_height + 0.03, deck_size * 0.5 - 0.14)
	if ts.has_method("set_text"):
		ts.call("set_text", "NON-BINARY CLASSIFIER",
			"it is not stuck. it is being argued with")
	_own(ts)


# ── Materials ────────────────────────────────────────────────────────

func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = energy
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


# ── Rebuild / grid config ────────────────────────────────────────────

func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_dots.clear()
	_field_root = null
	_bound_mesh = null
	_margin_mesh = null
	_band_mesh = null
	_readout = null
	_drift = 0.0
	_has_centroid = false
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_samples: int = sample_count
	var before_seed: int = build_seed
	var before_half: float = field_half

	# THE critical parameter — #margin_width:0.0 snaps it to a hard binary split.
	if config_data.has("margin_width"):
		margin_width = clampf(float(config_data["margin_width"]), 0.0, 2.0)
	if config_data.has("samples"):
		sample_count = clampi(int(config_data["samples"]), 8, 240)
	if config_data.has("learning_rate"):
		learning_rate = clampf(float(config_data["learning_rate"]), 0.01, 4.0)
	if config_data.has("gradient_steps"):
		gradient_steps = clampi(int(config_data["gradient_steps"]), 1, 64)
	if config_data.has("relabel_period"):
		relabel_period = clampi(int(config_data["relabel_period"]), 0, 240)
	if config_data.has("field_half"):
		field_half = clampf(float(config_data["field_half"]), 0.2, 2.0)
	if config_data.has("seed"):
		build_seed = int(config_data["seed"])

	if not _built:
		return   # _ready has not run yet; it will build with these values.

	if sample_count != before_samples or build_seed != before_seed \
			or not is_equal_approx(field_half, before_half):
		_rebuild_now()
		print("[NonBinaryClassifier] Config applied — rebuilt: samples=%d margin=%.2f" % [
			sample_count, margin_width])
		return
	# margin_width and the descent knobs need no geometry: the next frame reads
	# them. Rebuilding here would throw away the run in progress, which is the
	# one thing this artifact is made of.
	_refresh_readout()
