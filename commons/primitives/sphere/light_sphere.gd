extends Node3D

# @identity
# essence: the light enclosure's DNA head — a thin root over light_sphere.tscn's authored parts (a 40 m front-culled mirror shell, a reflection probe, one omni lamp), restating what the shell DOES with the light it is given
# desire: to let the artifact named light_sphere argue what its name couples — that light is never seen, only surfaces answering it, and the answer is a property of the surface, not the lamp
# critical_parameter: ground — the optical character of the receiving shell; the shell's authored dimensions (radius 40, height 40 — the squash is authored), the probe and the lamp are never rewritten
# triggers: _ready() reads ground, returns immediately on the default, and otherwise re-skins or re-meshes the one authored MeshInstance3D from its own SphereMesh arrays
# emerges: the same lamp inside four shells is four rooms — a source in a mirror, a glow in chalk, a wavelength test against swatches, a glitter across facets — though nothing about the lamp ever changed
# needs: the authored MeshInstance3D shell [present, read live]; its SphereMesh proportions [derived — the authored height is 40, NOT 2 x radius, and rebuilding by assumption would silently reshape the body]; the authored mirror material for `relief` [reused byte for byte]
# relationships: adopts `ground` — what a light is given to fall on — word for word from [[flashlight_demo]], whose swatch tints are kept character for character; the receiving-surface question asked there of a board is asked here of a total enclosure
# truth: you have never seen light. You have seen mirror, chalk, pigment and facet doing what they do with it — and a sphere around a lamp is the claim that there is no way to stand outside that fact.

## AXIS — WHAT THE LIGHT IS GIVEN TO FALL ON. The lamp never changes, the probe never
## changes, the shell's size and squash never change. What changes is the optical
## character of the enclosure, which is the whole of what a photograph of light can
## show. The word is flashlight_demo's `ground` — the surface the beams land on — asked
## of a shell that IS the artifact's whole surface. Its value names are kept where the
## semantics carry: mirror discloses the SOURCE, white returns everything, swatch
## returns per wavelength, relief discloses SHAPE. flashlight_demo's fifth value `none`
## is REFUSED here rather than adapted: there the lamp bodies remain in frame, here the
## shell is the only mesh, and a value that photographs an empty frame measures the
## same as an axis that does nothing.
##
##   mirror   the shipped shell: metallic, polished, front-culled — you look through
##            the near side at the inside of the far side, and what you see is
##            everything else, returned. THE SHIPPED LINEAGE, byte for byte.
##   white    the integrating-sphere reading: the same shell in matte chalk. Nothing
##            is returned but brightness; the enclosure stops being a picture of the
##            room and becomes a picture of illumination itself.
##   swatch   the shell quartered by longitude into the four flashlight_demo tints —
##            red, green, blue, white — each quarter answering the same lamp with its
##            own wavelength. The demo's test card wrapped into a room.
##   relief   the same mirror broken into coarse flat facets (12 x 6), the authored
##            skin kept: the polish now discloses geometry, the smooth rim goes
##            polygonal, and one reflection becomes a glitter of discrete panes.
@export_enum("mirror", "white", "swatch", "relief") var ground: String = "mirror"
const GROUNDS: PackedStringArray = ["mirror", "white", "swatch", "relief"]

## The receiving quarters for `swatch`, character for character flashlight_demo's
## SWATCH_TINTS — one shared test card across the corpus.
const SWATCH_TINTS: Array = [
	Color(0.72, 0.07, 0.07, 1.0),
	Color(0.07, 0.58, 0.13, 1.0),
	Color(0.07, 0.12, 0.68, 1.0),
	Color(0.95, 0.95, 0.95, 1.0),
]

## The authored shell inside light_sphere.tscn.
const SHELL_NODE := "MeshInstance3D"
## Facet counts for `relief` — coarse enough that the rim reads polygonal at 40 m.
const RELIEF_SEGMENTS: int = 12
const RELIEF_RINGS: int = 6

var _shell: MeshInstance3D = null
var _src_mesh: Mesh = null
var _src_material: Material = null


func _ready() -> void:
	_read_dna_meta()
	var g: String = str(ground).strip_edges().to_lower()
	ground = g if GROUNDS.has(g) else "mirror"

	# THE LEGACY PATH. "mirror" is the scene exactly as authored — the shell is not
	# even looked up. Nothing below runs.
	if ground == "mirror":
		return

	_collect_shell()
	_apply_ground()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. An unknown word keeps the default; no metadata, no change — which is all
## existing placements.
func _read_dna_meta() -> void:
	if has_meta("config_ground"):
		var g: String = str(get_meta("config_ground")).strip_edges().to_lower()
		ground = g if GROUNDS.has(g) else ground


## Late config honours only the ground key, and restores the authored mesh and skin
## before applying, so switching twice lands where switching once would have.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("ground"):
		return
	var g: String = str(config_data["ground"]).strip_edges().to_lower()
	if not GROUNDS.has(g) or g == ground:
		return
	ground = g
	if is_node_ready():
		_collect_shell()
		_apply_ground()


## Find the authored shell once and remember its authored mesh and material — the
## baseline every value is computed from.
func _collect_shell() -> void:
	if _shell != null:
		return
	_shell = get_node_or_null(SHELL_NODE) as MeshInstance3D
	if _shell == null:
		return
	_src_mesh = _shell.mesh
	_src_material = _shell.material_override


# ── GROUND ───────────────────────────────────────────────────────────────────
# One axis, four answers a surface can give a lamp. Appended LAST in the file and
# reached only off the default path: `mirror` never arrives here. Baseline restored
# before every apply, so the branches are idempotent.

func _apply_ground() -> void:
	if _shell == null or _src_mesh == null:
		return
	_shell.mesh = _src_mesh
	_shell.material_override = _src_material
	match ground:
		"white":
			var chalk := StandardMaterial3D.new()
			chalk.albedo_color = Color(0.93, 0.92, 0.90, 1.0)
			chalk.roughness = 0.96
			chalk.metallic = 0.0
			# The authored shell is front-culled so the interior stays visible; every
			# re-skin keeps that, or the value would be measuring a culling change.
			chalk.cull_mode = BaseMaterial3D.CULL_FRONT
			_shell.material_override = chalk
		"swatch":
			_shell.mesh = _swatch_mesh(_src_mesh)
			var card := StandardMaterial3D.new()
			card.vertex_color_use_as_albedo = true
			card.roughness = 0.9
			card.metallic = 0.0
			card.cull_mode = BaseMaterial3D.CULL_FRONT
			_shell.material_override = card
		"relief":
			# The authored skin, kept byte for byte — only the mesh coarsens. The
			# proportions are read off the authored SphereMesh: its height is authored
			# at 40, NOT 2 x radius, and assuming a round sphere would reshape it.
			_shell.mesh = _relief_mesh(_src_mesh)
		_:
			pass                                  # "mirror": the baseline restore above IS the value


## The shell quartered by longitude, one flashlight tint per quarter, coloured per FACE
## from the triangle centroid so the boundaries stay hard instead of blending.
func _swatch_mesh(src: Mesh) -> Mesh:
	var tris: Array = _triangles(src)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var c: Vector3 = t[2]
		var mid: Vector3 = (a + b + c) / 3.0
		var ang: float = atan2(mid.x, mid.z)
		var q: int = int(floor((ang + PI) / (TAU / 4.0))) % 4
		_tri(st, a, b, c, SWATCH_TINTS[q])
	return st.commit()


## The same body at 12 x 6, every facet flat. Radius, height (the authored squash) and
## hemisphere flag are read off the source SphereMesh.
func _relief_mesh(src: Mesh) -> Mesh:
	var coarse := SphereMesh.new()
	var s: SphereMesh = src as SphereMesh
	if s != null:
		coarse.radius = s.radius
		coarse.height = s.height
		coarse.is_hemisphere = s.is_hemisphere
	coarse.radial_segments = RELIEF_SEGMENTS
	coarse.rings = RELIEF_RINGS
	var tris: Array = _triangles(coarse)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in tris:
		_tri(st, t[0], t[1], t[2], Color(1.0, 1.0, 1.0, 1.0))
	return st.commit()


## A mesh's triangles as [a, b, c] triples, in the mesh's own order.
func _triangles(src: Mesh) -> Array:
	var arrays: Array = src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var out: Array = []
	if idx.is_empty():
		var j: int = 0
		while j + 2 < verts.size():
			out.append([verts[j], verts[j + 1], verts[j + 2]])
			j += 3
		return out
	var i: int = 0
	while i + 2 < idx.size():
		out.append([verts[idx[i]], verts[idx[i + 1]], verts[idx[i + 2]]])
		i += 3
	return out


## One flat-shaded triangle: face normal on every vertex, one colour.
func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
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
