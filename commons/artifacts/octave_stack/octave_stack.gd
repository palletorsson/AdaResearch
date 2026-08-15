extends Node3D
class_name OctaveStack

## octave_stack — the fourth octave cannot matter, and that is arithmetic, not taste.
##
## THE FAMILY. Eight artifacts declare the axis `octaves`: marchingcubes_cave,
## marchingcubes_inside_cave, mc_cave, mc_inside_cave (1 2 3 6), noise_quarry and noise_space
## (1 2 3 4), simplex_noise (1 2 4 6), generator_bench (1 2 3). It is the corpus's most-shared
## quantity axis and every one of them presents it as detail you can dial up.
##
## THE ARGUMENT. Fractal noise sums octaves at halving amplitude and doubling frequency. The
## first octave contributes 1, the second 1/2, the third 1/4, the fourth 1/8. So the total any
## octave past the first can still add is bounded by what is left of the series, and by octave
## four that remainder is a fourteenth of the whole. **The ladder converges by construction,
## before anything is drawn.** An artifact offering 1 2 3 6 is offering three useful rungs and
## a decoration, and four of the family's eight members go to 6.
##
## THE CONTRAST THIS WAVE IS BUILT ON. depth_well shows the same grammar — one integer, turn
## it up — over a recursion, where each level MULTIPLIES what the last one made. Same word,
## opposite curve. Neither family says which kind it is.
##
## THE BODY, NOT A GAUGE. No amplitude chart. The field is built as a real heightfield ribbon
## at each octave count, and in the `layers` reading each octave is drawn as its own sheet at
## its own true amplitude, stacked in the air above the sum — so the halving is visible as
## thickness rather than asserted as a number.

## How many octaves are summed. 1 2 3 4 are noise_quarry's and noise_space's own values; 6 is
## carried because four of the eight members offer it and the point is what it fails to buy.
@export_enum("1", "2", "3", "4", "6") var octaves: String = "3":
	set(v):
		octaves = v
		if is_inside_tree():
			_rebuild()

## What is drawn of each sum.
##   sum      — the field itself, the only thing the family ever shows.
##   layers   — every octave as its own sheet at its true amplitude, stacked above the sum.


##   residue  — the difference between this octave count and the one below it, alone.
@export_enum("sum", "layers", "residue") var reading: String = "sum":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## Fixed so five variants are five readings of ONE field and not five different fields.

## Whether the rungs stand together or one at a time. THIS IS NOT PART OF THE AXIS, and
## separating it cost a sweep to learn: with "ladder" declared as a value of the ladder axis
## itself, capture_config_sweep unioned the AABB of the all-rungs view with every single-rung
## view, framed the singles against a row five times their width, and photographed them as
## specks — the critic then crashed on a subject box too small to sample. A layout is not a
## rung. The sweep pins this to `single` through dna.fixture; the artifact still stands as the
## whole comparison by default, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

@export var seed_value: int = 20260815
@export var span: float = 0.86
@export var spacing: float = 1.02

const COLS := 34
const ROWS := 34
const AMP := 0.20

var _built: Array[Node3D] = []
var _noise: FastNoiseLite


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("octaves"):
		octaves = str(config_data["octaves"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	if config_data.has("seed_value"):
		seed_value = int(config_data["seed_value"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = seed_value
	_noise.frequency = 1.0

	var steps: Array = [1, 2, 3, 4, 6] if layout == "ladder" else [int(octaves)]
	var n: int = steps.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "o%d" % steps[i]
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_one(holder, int(steps[i]))


func _build_one(holder: Node3D, oct: int) -> void:
	match reading:
		"sum":
			holder.add_child(_sheet(_field(oct), Color(0.76, 0.70, 0.56), 0.0, 0.0))
		"layers":
			# Each octave alone, at its own amplitude, stacked. The halving is the geometry.
			holder.add_child(_sheet(_field(oct), Color(0.70, 0.66, 0.56), 0.0, 0.0))
			for k in range(oct):
				var band: PackedFloat32Array = _octave_alone(k)
				var t := float(k) / float(maxi(oct - 1, 1))
				holder.add_child(_sheet(band, Color(0.88, 0.76, 0.42).lerp(
						Color(0.38, 0.60, 0.74), t), 0.34, 0.16 + 0.13 * float(k)))
		"residue":
			# What this octave count added over the one below. For oct 1 the field itself is
			# the residue, since there is nothing below it.
			var lower: int = maxi(oct - 1, 0)
			var hi: PackedFloat32Array = _field(oct)
			var res := PackedFloat32Array()
			res.resize(hi.size())
			if lower == 0:
				for i in range(hi.size()):
					res[i] = hi[i]
			else:
				var lo: PackedFloat32Array = _field(lower)
				for i in range(hi.size()):
					res[i] = hi[i] - lo[i]
			holder.add_child(_sheet(res, Color(0.86, 0.52, 0.34), 0.42, 0.0))


## The summed field at n octaves — amplitude halving, frequency doubling.
func _field(n: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(COLS * ROWS)
	for r in range(ROWS):
		for c in range(COLS):
			var u := float(c) / float(COLS - 1)
			var v := float(r) / float(ROWS - 1)
			var amp := 1.0
			var freq := 1.6
			var acc := 0.0
			var norm := 0.0
			for _k in range(n):
				acc += amp * _noise.get_noise_2d(u * freq * 10.0, v * freq * 10.0)
				norm += amp
				amp *= 0.5
				freq *= 2.0
			h[r * COLS + c] = (acc / maxf(norm, 0.0001)) * AMP
	return h


## Octave k alone, at the amplitude it actually contributes to the sum.
func _octave_alone(k: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(COLS * ROWS)
	var amp: float = pow(0.5, float(k))
	var freq: float = 1.6 * pow(2.0, float(k))
	for r in range(ROWS):
		for c in range(COLS):
			var u := float(c) / float(COLS - 1)
			var v := float(r) / float(ROWS - 1)
			h[r * COLS + c] = amp * _noise.get_noise_2d(u * freq * 10.0, v * freq * 10.0) * AMP
	return h


func _sheet(h: PackedFloat32Array, col: Color, emit: float, lift: float) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for r in range(ROWS - 1):
		for c in range(COLS - 1):
			var quad: Array = [Vector2i(c, r), Vector2i(c + 1, r), Vector2i(c, r + 1),
					Vector2i(c + 1, r), Vector2i(c + 1, r + 1), Vector2i(c, r + 1)]
			for q in quad:
				var qq: Vector2i = q
				var x := (float(qq.x) / float(COLS - 1) - 0.5) * span
				var z := (float(qq.y) / float(ROWS - 1) - 0.5) * span
				st.add_vertex(Vector3(x, h[qq.y * COLS + qq.x] + lift, z))
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	mi.material_override = m
	return mi
