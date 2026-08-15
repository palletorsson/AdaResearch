extends Node3D
class_name IntrusionBench

## intrusion_bench — one formula, five ways of damaging it, on three bodies.
##
## THE FAMILY. Four registry names share the axis `intrusion`, and they are TWO SCENES:
##   GyroidDemo + gyroid_demo                 -> GyroidDemo.tscn (TerrainGeneratorGyroid)
##                                               melted · formula · eroded · drifting
##   marchingcubes_torus_sculpture +
##   mc_torus_sculpture                       -> marchingcubes_torus_sculpture.tscn
##                                               (TerrainGeneratorTorus)
##                                               melted · formula · rippled · roughened
## Two vocabularies with two words in common. Both scenes default to `melted`, all
## eighteen map placements between them show melted, and by their own registry notes
## the pure `formula` has never been placed anywhere in the corpus.
##
## THE ARGUMENT. An intrusion is NOISE ADDED TO THE FORMULA'S FIELD IN ONE FREQUENCY
## BAND. Read off the two compute shaders rather than off the words, the family's six
## values are one null, one union and four bands:
##
##   formula    the level set. Nothing added.
##   drifting   gyroid — snoise(worldPos * 0.05) added to the density at 1.0: one noise
##              unit across the whole 20 m chunk, a threshold that varies through space.
##              ZERO-frequency band on the VALUE. (In the member it is stacked on eroded.)
##   rippled    torus — sin(3θ + 0.1y)*3 + sin(5θ)cos(0.15y)*4 added to the distance:
##              periodic, deterministic, three and five cycles round the ring. LOW band,
##              no randomness in it.
##   roughened  torus — five octaves of snoise * 8.0. samplePos is world * noise_scale /
##              chunk_scale = world * 0.002, so the BASE octave is 0.32 cycles across the
##              whole 158 m torus and the finest is ~1.5 tube radii. The word says grain;
##              the code says a LOW-TO-MID stochastic lump.
##   eroded     gyroid — snoise(p * 2.0) * 0.5 added to the density: about twelve cycles
##              per gyroid period, features smaller than the channel. The HIGH band.
##              SIGNED — pits and warts alike. Not a subtraction; nothing in either
##              shader subtracts.
##   melted     BOTH members' shipped state: everything that member adds, at full
##              strength. The gyroid's melted also displaces the COORDINATES before the
##              formula is read (`p += warp * 4.0`, at the same 0.05 wavelength as
##              drifting), which is the one operation here that is not a value band. It
##              is not a smoothing. It is every band at once.
##
## So the shared words are the null and the union, the four unshared words are four
## bands, and no band has ever been shown on the other body. The gyroid names a NESTED
## ladder (formula ⊂ eroded ⊂ drifting ⊂ melted — each rung adds a band on the last);
## the torus names a PARTITION (rippled | roughened, melted = both). Same word `melted`,
## two grammars. That is a claim someone can dispute, and the sweep is the dispute.
##
## THE BODY, NOT A GAUGE. One sampled scalar field -> marching cubes -> real triangles,
## deterministic (FastNoiseLite at a fixed seed; the same rung is the same mesh every
## boot). Each intrusion is ONE operator with fixed metric parameters, applied unchanged
## to whichever surface is chosen: the gyroid block, the torus, or a sphere — the null
## surface, which has no formula-structure of its own for a band to hide in. The same
## intrusion reading the same on all three is the honesty check.

## Which damage the formula receives. `melted` is the default because it is the export
## default of BOTH member scenes and the only rung eighteen map placements have shown.
@export_enum("melted", "formula", "eroded", "drifting", "rippled", "roughened") var intrusion: String = "melted":
	set(v):
		intrusion = v
		if is_inside_tree() and not _batch:
			_rebuild()

## Which formula is damaged. gyroid and torus are the family's two bodies; sphere is the
## null surface added so that a band can be seen with no formula underneath it.
@export_enum("gyroid", "torus", "sphere") var surface: String = "gyroid":
	set(v):
		surface = v
		if is_inside_tree() and not _batch:
			_rebuild()

## Whether the six intrusions stand together or one at a time. NOT PART OF THE AXES:
## wave 13 learned that an all-rungs value inside an axis makes capture_config_sweep union
## the AABB of the row with every single, and the singles photograph as specks. The sweep
## pins this to `single` through dna.fixture; the bench still stands as the whole
## comparison by default, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree() and not _batch:
			_rebuild()

## Field grid: cells per axis of the sampled box. 26 cells over 1.12 m is a 43 mm cell,
## which puts the torus tube at ~5 cells, the gyroid channel at ~4 and the finest noise
## band at ~4 cells — the coarsest grid that still resolves every band it draws.
@export var cells: int = 26
## Half-size of the sampled box, metres. Bodies stay under 0.37 m so the intrusions have
## room to push outward without leaving the field.
@export var extent: float = 0.56
## Ladder pitch, metres.
@export var spacing: float = 0.80
## FastNoiseLite seed. Every noise here is a pure function of this and position.
@export var noise_seed: int = 7

const INTRUSIONS: PackedStringArray = ["melted", "formula", "eroded", "drifting", "rippled", "roughened"]
const SURFACES: PackedStringArray = ["gyroid", "torus", "sphere"]
## Ladder order is the argument's order: the null, then the gyroid's nested rungs, then
## the torus's partition, then the union both members ship.
const LADDER: PackedStringArray = ["formula", "eroded", "drifting", "rippled", "roughened", "melted"]
const LADDER_SCALE := 0.8

# --- bodies, metres --------------------------------------------------------------------
const TORUS_MAJOR := 0.26
const TORUS_MINOR := 0.11
const SPHERE_RADIUS := 0.32
const GYROID_HALF := 0.34
## Gyroid wavenumber, rad/m: period 0.465 m, 1.46 periods across the 0.68 m block — the
## member's shipped `pair` shows ~1.6 periods per axis.
const GYROID_K := 13.5
## The gyroid is a labyrinth solid where g >= iso, as the member (iso_level 1.0 on a
## g whose max is 1.5) is; 0.5 here so the channels are ~4 cells wide (34% solid, inscribed
## channel radius ~0.08 m, measured on a 96^3 numpy replica of the level set).
const GYROID_ISO := 0.5
## |grad g| on the g = 0.5 level set, mean 1.43 (numpy replica), so (iso - g) / (k * 1.43)
## is a metric distance near the surface and the bands' amplitudes mean metres on it.
const GYROID_GRAD := 1.43

# --- bands, metres and per-metre -------------------------------------------------------
## eroded: ONE octave, features ~0.17 m (4 cells), 0.035 m — 0.44 of the gyroid channel
## radius. The member's is 0.5 g-units, roughly two thirds of ITS channel radius, at ~P/12.
const GRAIN_AMP := 0.035
const GRAIN_FREQ := 6.0
## drifting's own term: one octave at ~1 m features across a 0.7 m body (the member's is
## one noise unit across its 20 m chunk), 0.07 m — 0.9 of the channel radius. Near-DC.
const DRIFT_AMP := 0.07
const DRIFT_FREQ := 1.0
## rippled: the torus member's two analytic terms scaled to a 0.11 m tube. 3.0 and 4.0 on
## a 20 m tube are 0.15 r and 0.20 r; y*0.1 and y*0.15 rad/m on a 20 m tube are 2.0 r
## and 3.0 r per radian, i.e. 18 and 27 rad/m at r = 0.11.
const RIPPLE_TWIST_AMP := 0.0165
const RIPPLE_TWIST_Y := 18.0
const RIPPLE_BULGE_AMP := 0.022
const RIPPLE_BULGE_Y := 27.0
## roughened: five octaves, lacunarity 2, gain 0.5, RAW sum (the member does not
## normalise), base at 0.32 cycles across the 0.74 m torus exactly as the member's is
## across its 158 m one; 0.045 m on the raw sum ~= 0.4 r typical, 0.8 r at the peaks
## (member: ~8-15 m on a 20 m tube).
const ROUGH_AMP := 0.045
const ROUGH_FREQ := 0.43
const ROUGH_OCTAVES := 5
## melted's coordinate warp: three channels at 0.4 m features, 0.08 m each. The member's
## is 4.0 p-units (8 m) at one unit across its box; what bends a lattice is the STRAIN,
## amplitude x frequency, and 0.08 x 2.5 keeps that at about the member's 0.4-0.5.
const WARP_AMP := 0.08
const WARP_FREQ := 2.5

## The marching-cubes edge and triangle tables, borrowed from the SDF bus rather than
## retyped: 4,352 integers that have already been rendered from.
const MC := preload("res://commons/morphology/sdf/sdf_marching_cubes.gd")
## Bourke corner order, (x, y, z) offsets. The tables above index edges against THIS.
const CORNER: Array[Vector3i] = [
	Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1),
	Vector3i(0, 1, 0), Vector3i(1, 1, 0), Vector3i(1, 1, 1), Vector3i(0, 1, 1),
]
const EDGE: Array = [
	[0, 1], [1, 2], [2, 3], [3, 0],
	[4, 5], [5, 6], [6, 7], [7, 4],
	[0, 4], [1, 5], [2, 6], [3, 7],
]

var _built: Array[Node3D] = []
var _batch: bool = false

var _grain: FastNoiseLite
var _drift: FastNoiseLite
var _rough: FastNoiseLite
var _warp_x: FastNoiseLite
var _warp_y: FastNoiseLite
var _warp_z: FastNoiseLite


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	_batch = true
	if config_data.has("layout"):
		var l: String = str(config_data["layout"]).strip_edges().to_lower()
		if l == "ladder" or l == "single":
			layout = l
	if config_data.has("intrusion"):
		var i: String = str(config_data["intrusion"]).strip_edges().to_lower()
		if INTRUSIONS.has(i):
			intrusion = i
	if config_data.has("surface"):
		var s: String = str(config_data["surface"]).strip_edges().to_lower()
		if SURFACES.has(s):
			surface = s
	if config_data.has("cells"):
		cells = clampi(int(config_data["cells"]), 8, 48)
	if config_data.has("extent"):
		extent = maxf(float(config_data["extent"]), 0.4)
	if config_data.has("noise_seed"):
		noise_seed = int(config_data["noise_seed"])
	_batch = false
	_rebuild()


func _rebuild() -> void:
	for old in _built:
		if is_instance_valid(old):
			old.queue_free()
	_built.clear()
	_setup_noise()
	if layout == "ladder":
		var n: int = LADDER.size()
		for i in range(n):
			var holder := Node3D.new()
			holder.name = String(LADDER[i])
			holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, 0.0, 0.0)
			holder.scale = Vector3(LADDER_SCALE, LADDER_SCALE, LADDER_SCALE)
			add_child(holder)
			_built.append(holder)
			_build_body(holder, String(LADDER[i]))
	else:
		var holder := Node3D.new()
		holder.name = intrusion
		add_child(holder)
		_built.append(holder)
		_build_body(holder, intrusion)


func _setup_noise() -> void:
	_grain = _noise(noise_seed + 1, GRAIN_FREQ)
	_drift = _noise(noise_seed + 2, DRIFT_FREQ)
	_rough = _noise(noise_seed + 3, ROUGH_FREQ)
	_warp_x = _noise(noise_seed + 4, WARP_FREQ)
	_warp_y = _noise(noise_seed + 5, WARP_FREQ)
	_warp_z = _noise(noise_seed + 6, WARP_FREQ)


func _noise(s: int, f: float) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.fractal_type = FastNoiseLite.FRACTAL_NONE
	n.seed = s
	n.frequency = f
	return n


# --- the field --------------------------------------------------------------------------

## The undamaged formula. Negative inside, positive outside, metres near the surface.
func _base(p: Vector3) -> float:
	if surface == "torus":
		var ring := Vector2(Vector2(p.x, p.z).length() - TORUS_MAJOR, p.y)
		return ring.length() - TORUS_MINOR
	if surface == "sphere":
		return p.length() - SPHERE_RADIUS
	# The gyroid block: Schoen's gyroid, solid where g >= iso, cut to a box so an
	# infinite surface has an outside. The box is part of the formula, so the bands land
	# on its faces too — an intrusion is applied to the FIELD, whatever the field is.
	var q: Vector3 = p * GYROID_K
	var g: float = sin(q.x) * cos(q.y) + sin(q.y) * cos(q.z) + sin(q.z) * cos(q.x)
	var d_g: float = (GYROID_ISO - g) / (GYROID_K * GYROID_GRAD)
	var b: Vector3 = p.abs() - Vector3(GYROID_HALF, GYROID_HALF, GYROID_HALF)
	var outside: float = Vector3(maxf(b.x, 0.0), maxf(b.y, 0.0), maxf(b.z, 0.0)).length()
	var inside: float = minf(maxf(b.x, maxf(b.y, b.z)), 0.0)
	return maxf(d_g, outside + inside)


## The formula under one intrusion. Every band is added to the VALUE, in metres, except
## melted's warp, which is added to the COORDINATE the formula is read at.
func _field(p: Vector3, kind: String) -> float:
	var q: Vector3 = p
	if kind == "melted":
		q = p + Vector3(_warp_x.get_noise_3dv(p), _warp_y.get_noise_3dv(p),
				_warp_z.get_noise_3dv(p)) * WARP_AMP
	var d: float = _base(q)
	if kind == "eroded" or kind == "drifting" or kind == "melted":
		d += GRAIN_AMP * _grain.get_noise_3dv(p)
	if kind == "drifting" or kind == "melted":
		d += DRIFT_AMP * _drift.get_noise_3dv(p)
	if kind == "rippled" or kind == "melted":
		d += _ripple(p)
	if kind == "roughened" or kind == "melted":
		d += _rough_sum(p)
	return d


func _ripple(p: Vector3) -> float:
	var theta: float = atan2(p.z, p.x)
	return RIPPLE_TWIST_AMP * sin(3.0 * theta + RIPPLE_TWIST_Y * p.y) \
			+ RIPPLE_BULGE_AMP * sin(5.0 * theta) * cos(RIPPLE_BULGE_Y * p.y)


func _rough_sum(p: Vector3) -> float:
	var total: float = 0.0
	var amp: float = 1.0
	var mult: float = 1.0
	for _octave in range(ROUGH_OCTAVES):
		total += amp * _rough.get_noise_3dv(p * mult)
		amp *= 0.5
		mult *= 2.0
	return ROUGH_AMP * total


# --- sampling and marching cubes --------------------------------------------------------

func _build_body(holder: Node3D, kind: String) -> void:
	var n: int = maxi(cells, 8)
	var ns: int = n + 1
	var step: float = 2.0 * extent / float(n)
	var origin := Vector3(-extent, -extent, -extent)
	# Sample the whole field once; index (ix * ns + iy) * ns + iz.
	var field := PackedFloat32Array()
	field.resize(ns * ns * ns)
	var idx: int = 0
	for ix in range(ns):
		for iy in range(ns):
			for iz in range(ns):
				field[idx] = _field(origin + Vector3(ix, iy, iz) * step, kind)
				idx += 1

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri_count: int = 0
	var c := PackedFloat32Array()
	c.resize(8)
	var vlist: Array = []
	vlist.resize(12)
	for ix in range(n):
		for iy in range(n):
			for iz in range(n):
				var cube: int = 0
				for k in range(8):
					var o: Vector3i = CORNER[k]
					c[k] = field[((ix + o.x) * ns + (iy + o.y)) * ns + (iz + o.z)]
					if c[k] < 0.0:
						cube |= 1 << k
				if cube == 0 or cube == 255:
					continue
				var emask: int = int(MC.EDGE_TABLE[cube])
				if emask == 0:
					continue
				var cell_origin: Vector3 = origin + Vector3(ix, iy, iz) * step
				for e in range(12):
					if emask & (1 << e):
						var a: int = EDGE[e][0]
						var b: int = EDGE[e][1]
						var pa: Vector3 = cell_origin + Vector3(CORNER[a]) * step
						var pb: Vector3 = cell_origin + Vector3(CORNER[b]) * step
						vlist[e] = _interp(pa, pb, c[a], c[b])
				var row: Array = MC.TRI_TABLE[cube]
				var t: int = 0
				while t < row.size() and int(row[t]) != -1:
					var v0: Vector3 = vlist[int(row[t])]
					var v1: Vector3 = vlist[int(row[t + 1])]
					var v2: Vector3 = vlist[int(row[t + 2])]
					var n0: Vector3 = _grad(c, (v0 - cell_origin) / step)
					var n1: Vector3 = _grad(c, (v1 - cell_origin) / step)
					var n2: Vector3 = _grad(c, (v2 - cell_origin) / step)
					# WIND OUTWARD. The field gradient points from inside (negative) to
					# outside (positive) by construction, so the face normal has to agree
					# with it; if the table's winding disagrees, swap two corners.
					if (v1 - v0).cross(v2 - v0).dot(n0 + n1 + n2) < 0.0:
						var tv: Vector3 = v1
						v1 = v2
						v2 = tv
						var tn: Vector3 = n1
						n1 = n2
						n2 = tn
					st.set_normal(n0)
					st.add_vertex(v0)
					st.set_normal(n1)
					st.add_vertex(v1)
					st.set_normal(n2)
					st.add_vertex(v2)
					tri_count += 1
					t += 3
	if tri_count == 0:
		push_warning("intrusion_bench: %s on %s left no surface in the field" % [kind, surface])
		return
	var mi := MeshInstance3D.new()
	mi.name = "Body_%s_%s" % [surface, kind]
	mi.mesh = st.commit()
	mi.material_override = _mat()
	holder.add_child(mi)


func _interp(pa: Vector3, pb: Vector3, va: float, vb: float) -> Vector3:
	if absf(va - vb) < 0.000001:
		return (pa + pb) * 0.5
	var t: float = clampf(va / (va - vb), 0.0, 1.0)
	return pa + (pb - pa) * t


## Gradient of the cell's trilinear interpolant at local (u, v, w) in [0, 1]^3, in the
## Bourke corner order. Free — it reads the eight samples already in hand — and it is
## the outward normal, because the field is negative inside.
func _grad(c: PackedFloat32Array, l: Vector3) -> Vector3:
	var u: float = clampf(l.x, 0.0, 1.0)
	var v: float = clampf(l.y, 0.0, 1.0)
	var w: float = clampf(l.z, 0.0, 1.0)
	var gx: float = (1.0 - v) * (1.0 - w) * (c[1] - c[0]) + (1.0 - v) * w * (c[2] - c[3]) \
			+ v * (1.0 - w) * (c[5] - c[4]) + v * w * (c[6] - c[7])
	var gy: float = (1.0 - u) * (1.0 - w) * (c[4] - c[0]) + u * (1.0 - w) * (c[5] - c[1]) \
			+ u * w * (c[6] - c[2]) + (1.0 - u) * w * (c[7] - c[3])
	var gz: float = (1.0 - u) * (1.0 - v) * (c[3] - c[0]) + u * (1.0 - v) * (c[2] - c[1]) \
			+ u * v * (c[6] - c[5]) + (1.0 - u) * v * (c[7] - c[4])
	var g := Vector3(gx, gy, gz)
	if g.length_squared() < 0.000000001:
		return Vector3.UP
	return g.normalized()


## One material for every value and every surface, so the only thing that differs
## between two frames is geometry. Culling is off: a marching-cubes body has no
## guaranteed winding at the field's open faces, and the inside of a pitted channel is
## something the bench wants seen.
func _mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.80, 0.76, 0.68)
	m.roughness = 0.62
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
