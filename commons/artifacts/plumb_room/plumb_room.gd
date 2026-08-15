extends Node3D
class_name PlumbRoom

## plumb_room — a cave is defined by which way is down.
##
## THE FAMILY. Four registry tokens declare the axis `plumb` with the values bedded /
## overturned / weightless / steep: marchingcave, marchingcubes_inside_cave, mc_base,
## mc_inside_cave. They are TWO SCENES on ONE SCRIPT (TerrainGenerator.gd, uid
## c2aji3u2bgmv8): marchingcubes_inside_cave.tscn carries mc_inside_cave and
## marchingcubes_inside_cave and runs MarchingCubes.glsl; marchingcubes.tscn carries mc_base
## and marchingcave and sets use_fallback = true, so on that scene the shader is never
## loaded, the mesh is a hand-written sine tunnel, and `plumb` is inert BY CONSTRUCTION
## (TerrainGenerator.gd:26-31 says so; the two bare declarations in the registry contradict
## the script's own header). So the family is one live scene, one dead alias pair, and one
## vocabulary — which is why the vocabulary can be taken whole.
##
## WHAT THE VALUES ARE, from the code and not the words. Everything that shader knows about
## gravity is one term, MarchingCubes.glsl:214/218:
##
##     density = -(worldPos.y + 100) / 300 * plumbScale + density
##
## the ONLY anisotropic term in the file, added to an isotropic ridged-noise sum. The four
## values are four multipliers on it (TerrainGenerator.gd:89-94, PLUMB_SCALES):
##
##     bedded       1.0   shipped — low is solid, high is air, you have a floor
##     overturned  -1.0   the sign flips — rock overhead, the ground opens
##     weightless   0.0   the term is deleted — an isotropic sponge, no floor, no ceiling
##     steep        3.0   the same down, three times the weight — the crossing band
##                        compresses to a third and the solid retreats into a slab
##
## Note what steep is NOT: it is not a tilt. The brief for this synthesis guessed "the
## down-axis tilted" from the word; the code says the down-axis is unchanged and its weight
## is tripled. This artifact follows the code.
##
## THE ARGUMENT. The rock is ONE scalar field — one ridged sum, one seed, one threshold —
## and the four values are four choices of plumb line drawn through it. What changes is
## not the rock but WHERE A WALKER COULD STAND. Because the walker's down is the room's
## (always -Y) while the field's down is the axis, the standable set runs from nothing
## (overturned: every up-facing surface is a pocket sealed inside the mass) through
## scattered ledges (weightless) to a rough floor with spires (bedded) to a near-flat slab
## top (steep, where gravity has beaten the noise). A cave is not defined by its rock; it
## is defined by which way is down.
##
## THE BODY, NOT A GAUGE. There is no percentage of walkable surface here. The `standing`
## reading lays the standable triangles on the rock as raised copies of themselves, in
## ochre, so the walkable set is geometry you can count patches of. The `line` reading
## hangs the plumb line itself beside the chunk — rod, ticks per quarter of the bias term,
## a bob at the down end — so the instrument that defines down is in the picture with the
## rock it defines.
##
## THE FIELD, so the values can be checked. Local metres, chunk centred at the origin,
## height h = cells * cell. Ridged sum r(p) as the source builds it (1 - |snoise|, squared,
## weight-gated, three octaves halving amplitude and doubling frequency), threshold iso =
## the MEDIAN of r over the interior lattice (so weightless is a fifty-percent sponge by
## construction and every plumb shares one threshold), and
##
##     f(p) = r(p) - iso - k * (p.y - y0) / span,     y0 = -h * 100/280,  span = h * 300/280
##
## solid where f > 0. y0 and span are the source's `+100` and `/300` scaled from its 280 m
## box to this chunk, so the horizon sits where the source's does: a third of the way up.
## The lattice's outer layer is forced to air so the chunk is a closed core sample; its
## cut faces are drawn paler and never count as standable.

## Which way is down for the FIELD. The four words are the family's, the four numbers are
## TerrainGenerator.gd's PLUMB_SCALES, and `bedded` is that script's shipped default.
@export_enum("bedded", "overturned", "weightless", "steep") var plumb: String = "bedded":
	set(v):
		plumb = v
		if is_inside_tree():
			_rebuild()

## What is drawn of the chunk.
##   rock      — the isosurface alone: rock, and the paler cut faces of the core sample.
##   standing  — rock, plus every triangle a walker under the ROOM's gravity could stand
##               on, laid 3 mm proud of the surface in ochre: air-side normal within 35
##               degrees of +Y, air at 1.5 and 3 cells above its centre, not a cut face.
##   line      — rock, plus the plumb line hung beside the chunk: a rod the chunk's height,
##               a tick every 0.25 of the bias term (so steep carries three times as many),
##               a long tick at the term's zero (y0), and a cone bob at the down end.
##               weightless hangs a sphere at mid-height with no rod and no ticks — a bob
##               with nowhere to hang has no line and no point.
@export_enum("rock", "standing", "line") var reading: String = "rock":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

## Whether the four plumbs stand together or one at a time. NOT PART OF THE AXES — a layout
## is not a rung. With an all-rungs value inside an axis the sweep unions the AABBs and
## photographs every single as a speck; the fixture pins this to `single`. Placed in a map
## the artifact stands as the whole comparison, which is what it is for.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## Seed of the ridged field. One seed, one rock, four plumbs — an unseeded field would make
## the four values four different caves and the axis a coin toss.
@export var seed: int = 7
## Lattice cells per side. 14 keeps a chunk under a tenth of a second in GDScript.
@export var cells: int = 14
## Metres per lattice cell. 14 * 0.06 = 0.84 m chunk.
@export var cell: float = 0.06
## Pitch between chunks in the ladder (chunk 0.84 m + its plumb line ~0.10 m + a gap).
@export var spacing: float = 1.10

## TerrainGenerator.gd:89-94, copied by value and by name.
const PLUMB_SCALES: Dictionary = {
	"bedded": 1.0,
	"overturned": -1.0,
	"weightless": 0.0,
	"steep": 3.0,
}
const PLUMBS: PackedStringArray = ["bedded", "overturned", "weightless", "steep"]

## Value forced on the lattice's outer layer. Strongly air, so the cap sits 0.8-0.9 of a
## cell inside the face and reads as a cut rather than as a bump.
const AIR_WALL: float = -4.0
## Base frequency of octave 0 in lattice cells: a wavelength of about 4.5 cells, so the
## first octave clears the lattice's 2-cell Nyquist limit, the second (2.3 cells) barely
## does, and the third (1.1 cells) aliases into grain — the same arithmetic the source
## family does at 4.375 m.
const BASE_FREQ: float = 0.22
const OCTAVES: int = 3
## cos(35 degrees): the steepest slope this artifact calls standable.
const STAND_COS: float = 0.819
## Headroom, in cells, that must be air above a standable patch (checked at half and full).
const HEADROOM_CELLS: float = 3.0
## How far a standing patch is raised off the rock, in metres.
const STAND_LIFT: float = 0.003
## Vertices closer than this many cells to a box face belong to the cut, not the cave.
const CUT_CELLS: float = 0.999
## Distance of the plumb rod from the chunk's +X face.
const LINE_GAP: float = 0.07

var _built: Array[Node3D] = []
var _noise: FastNoiseLite = null
## (cells+1)^3 samples of the ridged sum, before threshold or bias. Shared by every chunk
## in a rebuild, so the ladder is four plumbs of ONE rock.
var _ridged: PackedFloat32Array = PackedFloat32Array()
var _iso: float = 0.0
## Triangle accumulator for the chunk being marched (three vertices per triangle). A member
## rather than a parameter so that no question of packed-array copy semantics arises.
var _tris: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("plumb"):
		plumb = str(config_data["plumb"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	if config_data.has("seed"):
		seed = int(config_data["seed"])
	if config_data.has("cells"):
		cells = clampi(int(config_data["cells"]), 6, 24)
	if config_data.has("cell"):
		cell = float(config_data["cell"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	_sample_ridged()
	var plumbs: Array = []
	if layout == "ladder":
		for p in PLUMBS:
			plumbs.append(String(p))
	else:
		plumbs.append(plumb if PLUMB_SCALES.has(plumb) else "bedded")
	var n: int = plumbs.size()
	var h: float = float(cells) * cell
	for i in range(n):
		var name_i: String = String(plumbs[i])
		var holder: Node3D = Node3D.new()
		holder.name = name_i
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * spacing, h * 0.5, 0.0)
		add_child(holder)
		_built.append(holder)
		var k: float = float(PLUMB_SCALES[name_i])
		_build_chunk(holder, k)
		if reading == "line":
			_add_plumb_line(holder, k)


# ---------------------------------------------------------------------------------------
# The field
# ---------------------------------------------------------------------------------------

## Sample the ridged sum on the lattice once per rebuild and take its median as iso.
func _sample_ridged() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise.frequency = 1.0
	var n1: int = cells + 1
	_ridged.resize(n1 * n1 * n1)
	var interior: Array[float] = []
	for i in range(n1):
		for j in range(n1):
			for kk in range(n1):
				var r: float = _ridged_at(Vector3(float(i), float(j), float(kk)))
				_ridged[_idx(i, j, kk)] = r
				if i > 0 and i < cells and j > 0 and j < cells and kk > 0 and kk < cells:
					interior.append(r)
	interior.sort()
	_iso = interior[interior.size() >> 1] if interior.size() > 0 else 0.5


func _idx(i: int, j: int, kk: int) -> int:
	var n1: int = cells + 1
	return (i * n1 + j) * n1 + kk


## The source's ridged construction (MarchingCubes.glsl:187-197) with the clean fold:
## 1 - |snoise|, squared, weight-gated by the previous octave, amplitude halving and
## frequency doubling. Coordinates are in lattice cells.
func _ridged_at(c: Vector3) -> float:
	var p: Vector3 = c * BASE_FREQ
	var sum: float = 0.0
	var amp: float = 1.0
	var weight: float = 1.0
	for o in range(OCTAVES):
		var s: float = _noise.get_noise_3dv(p)
		var r: float = 1.0 - absf(s)
		r = r * r * weight
		weight = clampf(r * 10.0, 0.0, 1.0)
		sum += r * amp
		p *= 2.0
		amp *= 0.5
	return sum


## The bias term at local height y (metres, chunk centred at 0), for plumb multiplier k.
## The source's -(y+100)/300 on a 280 m box, scaled to this chunk's height.
func _bias(y: float, k: float) -> float:
	var h: float = float(cells) * cell
	var y0: float = -h * 100.0 / 280.0
	var span: float = h * 300.0 / 280.0
	return k * (y - y0) / span


## Density on the lattice, boundary layer forced to air.
func _lattice_f(i: int, j: int, kk: int, k: float) -> float:
	if i == 0 or j == 0 or kk == 0 or i == cells or j == cells or kk == cells:
		return AIR_WALL
	var y: float = (float(j) - float(cells) * 0.5) * cell
	return float(_ridged[_idx(i, j, kk)]) - _iso - _bias(y, k)


## Density at any local point (metres). Outside the box is air. Used for the headroom
## test above a candidate standing patch.
func _field_at(p: Vector3, k: float) -> float:
	var half: float = float(cells) * cell * 0.5
	if absf(p.x) >= half or absf(p.y) >= half or absf(p.z) >= half:
		return AIR_WALL
	var c: Vector3 = p / cell + Vector3.ONE * (float(cells) * 0.5)
	return _ridged_at(c) - _iso - _bias(p.y, k)


# ---------------------------------------------------------------------------------------
# The rock — marching tetrahedra on the lattice
# ---------------------------------------------------------------------------------------

func _build_chunk(holder: Node3D, k: float) -> void:
	var n1: int = cells + 1
	var f: PackedFloat32Array = PackedFloat32Array()
	f.resize(n1 * n1 * n1)
	for i in range(n1):
		for j in range(n1):
			for kk in range(n1):
				f[_idx(i, j, kk)] = _lattice_f(i, j, kk, k)

	_tris = PackedVector3Array()
	var half: float = float(cells) * cell * 0.5
	# Cube corners in the order the six-tetrahedra split expects.
	var corner: Array = [
		Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 1, 0), Vector3i(0, 1, 0),
		Vector3i(0, 0, 1), Vector3i(1, 0, 1), Vector3i(1, 1, 1), Vector3i(0, 1, 1)]
	var tets: Array = [
		[0, 5, 1, 6], [0, 1, 2, 6], [0, 2, 3, 6],
		[0, 3, 7, 6], [0, 7, 4, 6], [0, 4, 5, 6]]
	var vals: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var pos: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
		Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var tv: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var tp: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var origin: float = -float(cells) * 0.5 * cell

	for i in range(cells):
		for j in range(cells):
			for kk in range(cells):
				var any_solid: bool = false
				var any_air: bool = false
				for q in range(8):
					var c: Vector3i = corner[q]
					var v: float = f[_idx(i + c.x, j + c.y, kk + c.z)]
					vals[q] = v
					if v > 0.0:
						any_solid = true
					else:
						any_air = true
				# Most cubes are wholly rock or wholly air; only a crossing cube is marched.
				if not (any_solid and any_air):
					continue
				for q in range(8):
					var c2: Vector3i = corner[q]
					pos[q] = Vector3(
						origin + float(i + c2.x) * cell,
						origin + float(j + c2.y) * cell,
						origin + float(kk + c2.z) * cell)
				for t in tets:
					for q in range(4):
						var ci: int = int(t[q])
						tv[q] = vals[ci]
						tp[q] = pos[ci]
					_march_tet(tv, tp)

	# Sort the triangles into rock, cut and standing.
	var rock: PackedVector3Array = PackedVector3Array()
	var cut: PackedVector3Array = PackedVector3Array()
	var stand: PackedVector3Array = PackedVector3Array()
	var cut_dist: float = cell * CUT_CELLS
	var want_stand: bool = reading == "standing"
	var count: int = int(float(_tris.size()) / 3.0)
	for t in range(count):
		var a: Vector3 = _tris[t * 3]
		var b: Vector3 = _tris[t * 3 + 1]
		var c: Vector3 = _tris[t * 3 + 2]
		var on_cut: bool = _in_shell(a, half, cut_dist) and _in_shell(b, half, cut_dist) \
				and _in_shell(c, half, cut_dist)
		if on_cut:
			cut.append(a)
			cut.append(b)
			cut.append(c)
			continue
		rock.append(a)
		rock.append(b)
		rock.append(c)
		if not want_stand:
			continue
		var nrm: Vector3 = (b - a).cross(c - a)
		if nrm.length_squared() < 1e-12:
			continue
		nrm = nrm.normalized()
		if nrm.y < STAND_COS:
			continue
		var centre: Vector3 = (a + b + c) / 3.0
		var up1: Vector3 = centre + Vector3.UP * (cell * HEADROOM_CELLS * 0.5)
		var up2: Vector3 = centre + Vector3.UP * (cell * HEADROOM_CELLS)
		if _field_at(up1, k) > 0.0 or _field_at(up2, k) > 0.0:
			continue
		var lift: Vector3 = nrm * STAND_LIFT
		stand.append(a + lift)
		stand.append(b + lift)
		stand.append(c + lift)

	if rock.size() > 0:
		holder.add_child(_tri_mesh("Rock", rock, _mat(Color(0.60, 0.56, 0.50), 0.0, 0.92)))
	if cut.size() > 0:
		holder.add_child(_tri_mesh("Cut", cut, _mat(Color(0.82, 0.79, 0.72), 0.0, 0.80)))
	if stand.size() > 0:
		holder.add_child(_tri_mesh("Standing", stand, _mat(Color(0.98, 0.66, 0.22), 0.45, 0.6)))


func _in_shell(p: Vector3, half: float, cut_dist: float) -> bool:
	var m: float = maxf(absf(p.x), maxf(absf(p.y), absf(p.z)))
	return half - m < cut_dist


## One tetrahedron: 0, 1 or 2 triangles into _tris, wound so the normal faces the air.
func _march_tet(v: Array[float], p: Array[Vector3]) -> void:
	var solid: Array[int] = []
	var air: Array[int] = []
	for q in range(4):
		if v[q] > 0.0:
			solid.append(q)
		else:
			air.append(q)
	var ns: int = solid.size()
	if ns == 0 or ns == 4:
		return
	if ns == 1 or ns == 3:
		var one: int = solid[0] if ns == 1 else air[0]
		var others: Array[int] = air if ns == 1 else solid
		var a: Vector3 = _cross(p[one], v[one], p[others[0]], v[others[0]])
		var b: Vector3 = _cross(p[one], v[one], p[others[1]], v[others[1]])
		var c: Vector3 = _cross(p[one], v[one], p[others[2]], v[others[2]])
		var air_pt: Vector3 = p[one]
		if ns == 1:
			air_pt = (p[others[0]] + p[others[1]] + p[others[2]]) / 3.0
		_emit(a, b, c, air_pt)
		return
	# Two solid, two air: a quad between the pairs.
	var s0: int = solid[0]
	var s1: int = solid[1]
	var a0: int = air[0]
	var a1: int = air[1]
	var e00: Vector3 = _cross(p[s0], v[s0], p[a0], v[a0])
	var e01: Vector3 = _cross(p[s0], v[s0], p[a1], v[a1])
	var e11: Vector3 = _cross(p[s1], v[s1], p[a1], v[a1])
	var e10: Vector3 = _cross(p[s1], v[s1], p[a0], v[a0])
	var air_mid: Vector3 = (p[a0] + p[a1]) * 0.5
	_emit(e00, e01, e11, air_mid)
	_emit(e00, e11, e10, air_mid)


## Where the field crosses zero between two lattice corners.
func _cross(pa: Vector3, va: float, pb: Vector3, vb: float) -> Vector3:
	var d: float = vb - va
	var t: float = 0.5
	if absf(d) > 1e-9:
		t = clampf((0.0 - va) / d, 0.0, 1.0)
	return pa + (pb - pa) * t


## Append a triangle to _tris, wound so its normal points toward `air_pt`.
func _emit(a: Vector3, b: Vector3, c: Vector3, air_pt: Vector3) -> void:
	var nrm: Vector3 = (b - a).cross(c - a)
	if nrm.length_squared() < 1e-14:
		return
	var centre: Vector3 = (a + b + c) / 3.0
	_tris.append(a)
	if nrm.dot(air_pt - centre) < 0.0:
		_tris.append(c)
		_tris.append(b)
	else:
		_tris.append(b)
		_tris.append(c)


func _tri_mesh(mesh_name: String, verts: PackedVector3Array, m: StandardMaterial3D) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = int(float(verts.size()) / 3.0)
	for t in range(count):
		var a: Vector3 = verts[t * 3]
		var b: Vector3 = verts[t * 3 + 1]
		var c: Vector3 = verts[t * 3 + 2]
		var nrm: Vector3 = (b - a).cross(c - a)
		if nrm.length_squared() < 1e-14:
			nrm = Vector3.UP
		else:
			nrm = nrm.normalized()
		st.set_normal(nrm)
		st.add_vertex(a)
		st.set_normal(nrm)
		st.add_vertex(b)
		st.set_normal(nrm)
		st.add_vertex(c)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = st.commit()
	mi.material_override = m
	return mi


# ---------------------------------------------------------------------------------------
# The plumb line — the instrument that defines down, hung beside the rock it defines
# ---------------------------------------------------------------------------------------

func _add_plumb_line(holder: Node3D, k: float) -> void:
	var h: float = float(cells) * cell
	var half: float = h * 0.5
	var x: float = half + LINE_GAP
	var line: Node3D = Node3D.new()
	line.name = "PlumbLine"
	holder.add_child(line)
	var brass: Color = Color(0.86, 0.70, 0.36)
	if absf(k) < 1e-6:
		# weightless — no down, so no line and no point: a bob hanging from nothing.
		var sph: MeshInstance3D = MeshInstance3D.new()
		var sm: SphereMesh = SphereMesh.new()
		sm.radius = 0.014
		sm.height = 0.028
		sm.radial_segments = 12
		sm.rings = 6
		sph.mesh = sm
		sph.name = "Bob"
		sph.material_override = _mat(brass, 0.25, 0.4)
		sph.position = Vector3(x, 0.0, 0.0)
		line.add_child(sph)
		return
	# The rod, the chunk's full height.
	line.add_child(_rod(Vector3(x, -half, 0.0), Vector3(x, half, 0.0),
			Color(0.12, 0.12, 0.14), 0.004))
	# A tick every 0.25 of the bias term; the tick at its zero (y0) is long. bedded and
	# overturned share the same tick positions — the set {y0 + m * 0.25 * span / |k|} does
	# not know the sign — and differ by where the bob hangs. steep packs three ticks into
	# each of bedded's intervals.
	var y0: float = -h * 100.0 / 280.0
	var span: float = h * 300.0 / 280.0
	var step: float = 0.25 * span / absf(k)
	var m_lo: int = int(floor((-half - y0) / step)) - 1
	var m_hi: int = int(ceil((half - y0) / step)) + 1
	for m in range(m_lo, m_hi + 1):
		var y: float = y0 + float(m) * step
		if y < -half or y > half:
			continue
		var tick_len: float = 0.05 if m == 0 else 0.022
		var r: float = 0.0035 if m == 0 else 0.0025
		line.add_child(_rod(Vector3(x - tick_len * 0.5, y, 0.0),
				Vector3(x + tick_len * 0.5, y, 0.0), brass, r))
	# The bob, at the down end, pointing down: down is where the bias term makes rock.
	var down: float = -1.0 if k > 0.0 else 1.0
	var bob: MeshInstance3D = MeshInstance3D.new()
	var cone: CylinderMesh = CylinderMesh.new()
	cone.top_radius = 0.014
	cone.bottom_radius = 0.0
	cone.height = 0.034
	cone.radial_segments = 12
	cone.rings = 0
	bob.mesh = cone
	bob.name = "Bob"
	bob.material_override = _mat(brass, 0.25, 0.4)
	bob.position = Vector3(x, down * (half + 0.017), 0.0)
	if down > 0.0:
		bob.rotation = Vector3(PI, 0.0, 0.0)
	line.add_child(bob)


func _rod(a: Vector3, b: Vector3, c: Color, r: float) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.0001)
	cyl.radial_segments = 6
	cyl.rings = 0
	mi.mesh = cyl
	mi.material_override = _mat(c, 0.15, 0.6)
	mi.position = (a + b) * 0.5
	var dir: Vector3 = (b - a).normalized()
	if absf(dir.dot(Vector3.UP)) < 0.999:
		mi.look_at_from_position(mi.position, mi.position + dir, Vector3.UP)
		mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	return mi


func _mat(c: Color, emit: float, rough: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	# Marching-tetrahedra output is wound toward the air by construction, but a chunk is
	# looked into through its holes, so both faces are drawn.
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	return m
