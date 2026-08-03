# Cube.gd - Regular cube/hexahedron (6 square faces)
extends Node3D
class_name Cube

# @identity
# essence: the unit cube — the project's geometric atom and the grid system's literal cell
# desire: a configurable hexahedron primitive that any map cell, artifact, or compound shape can drop in without subclassing
# critical_parameter: size — sets the cell-edge length; default 0.5 (= 1.0m cube, the grid cell size)
# triggers: _ready() builds 8 vertices and 12 triangle faces with a grid-shader material in base_color
# emerges: a hard-edged six-sided body with consistent grid lines on every face, color uniform across the surface
# needs: GridMaterialFactory [present]; PrimitiveMeshBuilder [present]; size + color knobs via apply_grid_config [present, 2026-05-19]
# relationships: parent vocabulary for boxbeam, dice, design_classics; sibling to cylinder, capsule, dodecahedron, icosahedron, octahedron, tetrahedron under primitives/; the grid system's GridSystem.gd places these directly into cells
# truth: the cube is what every other shape is measured against — the cell, the box, the void's complement. Making it configurable means the grid stops being the only thing that names size.

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


@export var base_color: Color = Color(0.0, 1.0, 1.0)
## Half-edge length. The cube extends ±size on each axis; default 0.5 = 1.0m edge,
## matching the grid cell. Set via apply_grid_config({"size": 0.3}) or directly in
## the inspector for compound primitives.
@export var size: float = 0.5

## AXIS — WHAT STATE OF MAKING THE BODY IS SHOWN IN. The solid never changes: same
## half-edge, same eight corners, same base_color, same place in the cell. What changes is
## how much of its own construction it admits. The word is adopted verbatim from
## [[capsule]] and shared with [[folded_strip]], [[triangleprofiles]] and
## [[platonic_grabbables]] — one vocabulary across the primitives tier, because a room
## that puts a capsule and a cube on the same bench cannot have one of them arguing
## facture and the other arguing finish.
##
## The cube is the hardest case in the family to ask it of, and that is the point. It is
## the grid's own cell: the one body in this project that is supposed to have no history,
## no maker and no wear, because everything else is measured against it. Every value
## except the first is that assumption failing.
##
##   cast      poured — one grid-shaded skin, twelve triangles, no count and no seam
##             admitted. The form as given, and THE LEGACY LINEAGE, byte for byte.
##   facet     counted — every triangle its own flat plane, alternate ones a shade
##             darker. A "square face" is revealed to be two triangles with a diagonal
##             between them: the cube you were shown was never square.
##   armature  wired — the skin gone, the twelve edges left standing as tubes. The
##             Necker figure: what holds a cell up, with nothing draped over it, and
##             the only value you can see all the way through.
##   section   sawn — cut on a horizontal plane through its middle, the upper half
##             removed and the cut face drawn solid in the drawing convention. Half a
##             cell reads as a cell somebody opened.
##   wear      handled — the faces subdivided and every vertex dented inward by a fixed
##             hash of its own position, the skin darkened and roughened. The unit put
##             through use, which is the one thing a unit is not allowed to be.
##
## The cut in `section` is HORIZONTAL on purpose, matching capsule: a vertical cut would
## face the camera at one yaw and away at another, and the sweep would measure what angle
## it was rather than what the value says.
@export_enum("cast", "facet", "armature", "section", "wear") var facture: String = "cast"
const FACTURES: PackedStringArray = ["cast", "facet", "armature", "section", "wear"]

var _mesh_instance: MeshInstance3D

func _ready():
	var f: String = str(facture).strip_edges().to_lower()
	facture = f if FACTURES.has(f) else "cast"
	_build_cube()
	_fac_apply()

func _build_cube() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var geometry := _cube_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Cube",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _cube_geometry() -> Dictionary:
	var vertices: Array[Vector3] = [
		Vector3(-size, -size, size),
		Vector3(size, -size, size),
		Vector3(size, size, size),
		Vector3(-size, size, size),
		Vector3(-size, -size, -size),
		Vector3(size, -size, -size),
		Vector3(size, size, -size),
		Vector3(-size, size, -size)
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],
		[5, 4, 7], [5, 7, 6],
		[4, 0, 3], [4, 3, 7],
		[1, 5, 6], [1, 6, 2],
		[3, 2, 6], [3, 6, 7],
		[4, 5, 1], [4, 1, 0]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
		# Re-state the facture the grid material just overwrote. Returns instantly on
		# "cast", so the legacy call is exactly the two lines above it.
		_fac_apply()

## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "size"    — half-edge length (Float)
##   "color"   — base_color (Color or [r,g,b] array)
##   "facture" — state of making: cast | facet | armature | section | wear
## Unknown keys are ignored. Rebuilds the mesh if it has already been constructed.
func apply_grid_config(config_data: Dictionary) -> void:
	var dirty: bool = false
	if config_data.has("size"):
		size = float(config_data["size"])
		dirty = true
	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			base_color = c
		elif c is Array and c.size() >= 3:
			base_color = Color(float(c[0]), float(c[1]), float(c[2]))
		dirty = true
	# An unrecognised word keeps the value already standing — a typo must not silently
	# recast a body that a map asked to be sawn.
	if config_data.has("facture"):
		var want: String = str(config_data["facture"]).strip_edges().to_lower()
		if FACTURES.has(want) and want != facture:
			facture = want
			dirty = true
	if dirty and _mesh_instance:
		_build_cube()
		_fac_apply()


# ── FACTURE ──────────────────────────────────────────────────────────────────
# One axis, five states of making, shared word for word with capsule.gd. Appended LAST and
# gated on the default: `cast` reads nothing, writes nothing and adds no node, so the
# legacy build is the twelve-triangle grid-shaded hexahedron it always was. The other four
# replace the ONE MeshInstance3D's mesh and material_override — never its parent, its
# name, its transform or its index, so anything that walks this subtree by position still
# finds what it expects.

## Wire gauge for `armature` as a fraction of the half-edge — 0.018 m against the default
## 0.5. A PRIMITIVE_LINES wireframe is one pixel wide and vanishes when a capture is
## downscaled; an axis that vanishes measures the same as an axis that does nothing, so
## the edges are tubes.
const FAC_WIRE := 0.036
## Subdivision per face for `wear`. Eight corners alone dent into a wonky die that reads as
## a modelling error; a 4×4 grid per face dents into a battered body that reads as history.
const FAC_WEAR_DIV := 4


## Dispatch. Returns before touching anything on the legacy value.
func _fac_apply() -> void:
	if facture == "cast":
		return
	if not is_instance_valid(_mesh_instance):
		return
	match facture:
		"facet":
			_fac_facet()
		"armature":
			_fac_armature()
		"section":
			_fac_section()
		"wear":
			_fac_wear()
		_:
			pass


## COUNTED. The same six faces, but each triangle flat and each alternate one a shade
## darker, so the diagonal that splits every "square" face becomes a thing you can point
## at. The grid shader goes with it: a painted grid is somebody's drawing of structure,
## and this value shows the structure instead.
func _fac_facet() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = 0
	for q in _fac_quads():
		var a: Vector3 = q[0]
		var b: Vector3 = q[1]
		var c: Vector3 = q[2]
		var d: Vector3 = q[3]
		_fac_tri(st, a, b, c, _fac_tone(base_color, 0.72 if (n % 2) == 0 else 1.0))
		n += 1
		_fac_tri(st, a, c, d, _fac_tone(base_color, 0.72 if (n % 2) == 0 else 1.0))
		n += 1
	_mesh_instance.mesh = st.commit()
	_mesh_instance.material_override = _fac_mat(false)


## WIRED. The twelve edges once each, as thin three-sided tubes. The skin is not hidden —
## it is not built at all, so there is no VisualInstance3D left standing behind it.
func _fac_armature() -> void:
	var wire: Color = Color(base_color.r, base_color.g, base_color.b, 1.0).lightened(0.35)
	var r: float = maxf(size * FAC_WIRE, 0.002)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for e in _fac_edges():
		_fac_tube(st, e[0], e[1], r, wire)
	_mesh_instance.mesh = st.commit()
	_mesh_instance.material_override = _fac_mat(true)


## SAWN. The upper half gone, the lower half closed, and the cut face drawn SOLID one
## shade off the body — the technical-drawing convention, where a section is a filled
## plane and not an absence.
func _fac_section() -> void:
	var s: float = size
	var lo: float = -s
	var hi: float = 0.0
	var body: Color = base_color
	var cut: Color = Color(base_color.r, base_color.g, base_color.b, 1.0).lightened(0.42)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# floor, seen from below
	_fac_quad(st, Vector3(-s, lo, -s), Vector3(s, lo, -s), Vector3(s, lo, s), Vector3(-s, lo, s), body)
	# four walls, outward
	_fac_quad(st, Vector3(-s, lo, s), Vector3(s, lo, s), Vector3(s, hi, s), Vector3(-s, hi, s), body)
	_fac_quad(st, Vector3(s, lo, -s), Vector3(-s, lo, -s), Vector3(-s, hi, -s), Vector3(s, hi, -s), body)
	_fac_quad(st, Vector3(-s, lo, -s), Vector3(-s, lo, s), Vector3(-s, hi, s), Vector3(-s, hi, -s), body)
	_fac_quad(st, Vector3(s, lo, s), Vector3(s, lo, -s), Vector3(s, hi, -s), Vector3(s, hi, s), body)
	# the cut plane itself, upward, in the section tone
	_fac_quad(st, Vector3(-s, hi, s), Vector3(s, hi, s), Vector3(s, hi, -s), Vector3(-s, hi, -s), cut)
	_mesh_instance.mesh = st.commit()
	_mesh_instance.material_override = _fac_mat(false)


## HANDLED. Each face subdivided, then every vertex pushed in along its own direction from
## the centre by a fixed hash of its QUANTISED POSITION — never randf(), and keyed on
## position rather than index so a vertex shared by three faces dents by the same amount
## and the corners do not split open. The same boot, the same machine, the same dent: the
## sweep measures the axis, not noise.
func _fac_wear() -> void:
	var dull: Color = Color(base_color.r, base_color.g, base_color.b, 1.0).darkened(0.28)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in _fac_quads_div(FAC_WEAR_DIV):
		var a: Vector3 = _fac_dent(q[0])
		var b: Vector3 = _fac_dent(q[1])
		var c: Vector3 = _fac_dent(q[2])
		var d: Vector3 = _fac_dent(q[3])
		# Grime pools where the dent is deepest, so the damage reads as history.
		var g: float = _fac_hash((a + b + c + d) * 0.25)
		var col: Color = _fac_tone(dull, 0.78 + 0.22 * g)
		_fac_tri(st, a, b, c, col)
		_fac_tri(st, a, c, d, col)
	_mesh_instance.mesh = st.commit()
	var mat: StandardMaterial3D = _fac_mat(false)
	mat.roughness = 1.0
	_mesh_instance.material_override = mat


# ── FACTURE helpers ──────────────────────────────────────────────────────────

## Unit vector for axis 0/1/2. u = axis(i+1), v = axis(i+2) always cross to axis(i), so
## every face below winds outward without a per-face special case.
func _fac_axis(i: int) -> Vector3:
	if i == 0:
		return Vector3.RIGHT
	if i == 1:
		return Vector3.UP
	return Vector3.BACK


## The six faces as outward-wound [a, b, c, d] quads.
func _fac_quads() -> Array:
	return _fac_quads_div(1)


## The six faces as outward-wound quads, each split into div × div cells.
func _fac_quads_div(div: int) -> Array:
	var n: int = maxi(div, 1)
	var s: float = size
	var out: Array = []
	for i in range(3):
		for raw_sgn in [-1.0, 1.0]:
			var sgn: float = float(raw_sgn)
			var nrm: Vector3 = _fac_axis(i) * sgn
			var u: Vector3 = _fac_axis((i + 1) % 3)
			var v: Vector3 = _fac_axis((i + 2) % 3) * sgn
			var origin: Vector3 = nrm * s - u * s - v * s
			var step: float = 2.0 * s / float(n)
			for a in range(n):
				for b in range(n):
					var p0: Vector3 = origin + u * (float(a) * step) + v * (float(b) * step)
					out.append([
						p0,
						p0 + u * step,
						p0 + u * step + v * step,
						p0 + v * step,
					])
	return out


## The twelve edges of the hexahedron, each once, as [a, b] pairs.
func _fac_edges() -> Array:
	var s: float = size
	var out: Array = []
	for i in range(3):
		var d: Vector3 = _fac_axis(i) * s
		var u: Vector3 = _fac_axis((i + 1) % 3) * s
		var v: Vector3 = _fac_axis((i + 2) % 3) * s
		for raw_u in [-1.0, 1.0]:
			for raw_v in [-1.0, 1.0]:
				var off: Vector3 = u * float(raw_u) + v * float(raw_v)
				out.append([off - d, off + d])
	return out


## The dented position of a vertex: pushed in along its own direction from the centre.
func _fac_dent(v: Vector3) -> Vector3:
	if v.length_squared() < 0.000001:
		return v
	var h: float = _fac_hash(v)
	var dent: float = size * 0.14 * h
	if h > 0.82:
		dent = size * 0.30                    # a chip, not a scuff
	return v - v.normalized() * dent


## Deterministic 0..1 from a QUANTISED position. Quantised so a vertex written once per
## face hashes identically on all three of them and the corners stay welded.
func _fac_hash(v: Vector3) -> float:
	var qx: float = float(int(round(v.x * 500.0)))
	var qy: float = float(int(round(v.y * 500.0)))
	var qz: float = float(int(round(v.z * 500.0)))
	var s: float = sin(qx * 12.9898 + qy * 78.233 + qz * 37.719) * 43758.5453
	return s - floor(s)


func _fac_tone(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k, 1.0)


func _fac_mat(unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.82
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _fac_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_color(col)
	st.add_vertex(c)


func _fac_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, col: Color) -> void:
	_fac_tri(st, p0, p1, p2, col)
	_fac_tri(st, p0, p2, p3, col)


func _fac_tube(st: SurfaceTool, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d: Vector3 = b - a
	if d.length_squared() < 0.0000001:
		return
	var n: Vector3 = d.normalized()
	var seed_up: Vector3 = Vector3.UP
	if absf(n.dot(Vector3.UP)) > 0.9:
		seed_up = Vector3.RIGHT
	var u: Vector3 = n.cross(seed_up).normalized() * r
	var v: Vector3 = n.cross(u).normalized() * r
	var off: Array = []
	for k in range(3):
		var ang: float = TAU * float(k) / 3.0
		off.append(u * cos(ang) + v * sin(ang))
	for k in range(3):
		var o0: Vector3 = off[k]
		var o1: Vector3 = off[(k + 1) % 3]
		_fac_quad(st, a + o0, a + o1, b + o1, b + o0, col)
