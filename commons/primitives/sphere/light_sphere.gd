extends Node3D

## The finishing kits. Preloaded rather than reached by their global class_name: this file
## is parsed by a headless harness with no editor to resolve the global class table, and a
## missing global there is a silent no-render rather than a loud error.
const PBR := preload("res://commons/render/pbr_kit.gd")
const MK := preload("res://commons/render/mesh_kit.gd")

# @identity
# essence: the light enclosure's DNA head — a thin root over light_sphere.tscn's authored parts (a 40 m double-sided mirror shell, a reflection probe, one omni lamp), restating what the shell DOES with the light it is given
# desire: to let the artifact named light_sphere argue what its name couples — that light is never seen, only surfaces answering it, and the answer is a property of the surface, not the lamp
# critical_parameter: ground — the optical character of the receiving shell; the shell's authored dimensions (radius 40, height 40 — the squash is authored), its cull mode, the probe and the lamp are never rewritten
# triggers: _ready() reads ground and dresses the one authored MeshInstance3D — every value re-skins it from PbrKit, three of the four also re-mesh it from the authored SphereMesh's own arrays
# emerges: the same lamp inside four shells is four rooms — a source in polished steel, a glow in chalk, a wavelength test against swatches, a glitter across facets — though nothing about the lamp ever changed
# needs: the authored MeshInstance3D shell [present, read live]; its SphereMesh proportions [derived — the authored height is 40, NOT 2 x radius, and rebuilding by assumption would silently reshape the body]; the authored material's cull mode [read live, never assumed — CULL_DISABLED is what lets a 40 m shell be occupied from the inside]; PbrKit for the four finishes and MeshKit for the tangents a rebuilt surface would otherwise lack
# relationships: adopts `ground` — what a light is given to fall on — word for word from [[flashlight_demo]], whose swatch tints are kept character for character; the receiving-surface question asked there of a board is asked here of a total enclosure
# truth: you have never seen light. You have seen mirror, chalk, pigment and facet doing what they do with it — and a sphere around a lamp is the claim that there is no way to stand outside that fact.

## AXIS — WHAT THE LIGHT IS GIVEN TO FALL ON. The lamp never changes, the probe never
## changes, the shell's size, squash and cull mode never change. What changes is the
## optical character of the enclosure, which is the whole of what a photograph of light
## can show. The word is flashlight_demo's `ground` — the surface the beams land on —
## asked of a shell that IS the artifact's whole surface. Its value names are kept where
## the semantics carry: mirror discloses the SOURCE, white returns everything, swatch
## returns per wavelength, relief discloses SHAPE. flashlight_demo's fifth value `none`
## is REFUSED here rather than adapted: there the lamp bodies remain in frame, here the
## shell is the only mesh, and a value that photographs an empty frame measures the
## same as an axis that does nothing.
##
##   mirror   the shipped shell: metallic, polished, double-sided — you can stand inside
##            a forty-metre enclosure and still be given a surface, and what that surface
##            shows you is everything else, returned. THE SHIPPED LINEAGE.
##            Its finish is now a real polished band rather than a mathematical one; see
##            POLISH_ROUGHNESS for why a roughness of exactly zero was costing the axis
##            its own best pair.
##   white    the integrating-sphere reading: the same shell in matte chalk. Nothing
##            is returned but brightness; the enclosure stops being a picture of the
##            room and becomes a picture of illumination itself.
##   swatch   the shell quartered by longitude into the four flashlight_demo tints —
##            red, green, blue, white — each quarter answering the same lamp with its
##            own wavelength. The demo's test card wrapped into a room.
##   relief   the same polished skin broken into coarse flat facets (12 x 6), the skin
##            kept: only the mesh coarsens, so the polish now discloses geometry, the
##            smooth rim goes polygonal, and one reflection becomes a glitter of
##            discrete panes — which it can only do now that the polish has a lobe wide
##            enough for a pane to catch a piece of.
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

# ── THE FINISH ───────────────────────────────────────────────────────────────
# Four numbers and two colours. Everything else about the surfaces comes out of PbrKit.

## The polished band, and the reason this file was re-finished at all. A roughness of
## exactly 0.0 is not a very good mirror, it is a surface with ONE microfacet direction:
## it returns a single hot dot and is otherwise the flat colour of whatever the
## environment happens to be. Under a constant-colour ambient that makes the shell the
## same flat value no matter which way its normal points — which is why `relief` measured
## 0.25% different from `mirror` while every other pair measured 5.4%. The facets were
## there; there was no lobe wide enough for them to catch a piece of. Real polished steel
## lives at 0.10-0.20 WITH variation across it, and PbrKit's brush grain spreads that band
## around 0.12-0.19, so a normal that turns now changes what comes back.
const POLISH_ROUGHNESS: float = 0.14
## Not damage — just enough that the highlight is a field and not a decal.
const POLISH_WEAR: float = 0.06

## The chalk value, kept from the shipped skin character for character.
const CHALK_ALBEDO: Color = Color(0.93, 0.92, 0.90, 1.0)
## An integrating sphere is CLEAN — below PbrKit's 0.2 weathering threshold on purpose,
## so the coat gets its cellular roughness variation without acquiring dirt.
const CHALK_WEAR: float = 0.12
## PbrKit's cast normal is sized for a concrete plinth. On a forty-metre dome the same
## strength would read as geology, so the bump is pulled back to a chalky tooth.
const CHALK_BUMP: float = 0.35

## How many repeats of a skin's own detail texture span the shell — the only numbers here
## that are about SIZE rather than taste, and the ones a forty-metre body cannot inherit.
##
## PbrKit tiles its triplanar detail in LOCAL space at 3-6 tiles per metre and states its
## rule of thumb in TILES (`factor = 1 / longest_dimension`). But a tile is not a feature:
## at 256 px a brush tile holds about fifty-seven noise features, a micro tile about
## twenty-four, a cast tile about twelve. Taken literally across eighty metres that is
## thousands of features, every one of them sub-pixel and every one of them mipmapped back
## to the flat grey the detail was added to prevent. These three are chosen so a FEATURE
## lands near a metre and a half on all three skins — the size that still reads from
## forty metres away and does not turn to fizz when you are standing inside it.
const POLISH_REPEATS: float = 1.0      # brush grain, ~57 features per tile
const CHALK_REPEATS: float = 4.0       # cast grain, ~12 features per tile
const CARD_REPEATS: float = 2.0        # micro grain, ~24 features per tile

var _shell: MeshInstance3D = null
var _src_mesh: Mesh = null
## The authored skin, kept only so its CULL MODE can be read off it and never assumed. It
## is CULL_DISABLED, not front — and that is load-bearing, not an oversight: a player
## standing INSIDE a forty-metre sphere sees its back faces, so a back-culled shell would
## vanish the moment you walked in. Held as a BaseMaterial3D so the mode is copied
## property to property and never round-tripped through an integer.
var _src_material: BaseMaterial3D = null
## The shell's longest authored dimension, for scaling detail to the body.
var _span: float = 80.0


func _ready() -> void:
	_read_dna_meta()
	var g: String = str(ground).strip_edges().to_lower()
	ground = g if GROUNDS.has(g) else "mirror"
	_collect_shell()
	_apply_ground()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. An unknown word keeps the default; no metadata, no change — which is all
## existing placements.
func _read_dna_meta() -> void:
	if has_meta("config_ground"):
		var g: String = str(get_meta("config_ground")).strip_edges().to_lower()
		ground = g if GROUNDS.has(g) else ground


## Late config honours only the ground key. Every branch of _apply_ground sets both mesh
## and skin outright, so switching twice lands where switching once would have.
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


## Find the authored shell once and remember the three facts every value is computed
## from: its mesh, its skin, and the two properties of that skin and mesh — cull mode and
## span — that must survive being re-finished.
func _collect_shell() -> void:
	if _shell != null:
		return
	_shell = get_node_or_null(SHELL_NODE) as MeshInstance3D
	if _shell == null:
		return
	_src_mesh = _shell.mesh
	_src_material = _shell.material_override as BaseMaterial3D
	var s: SphereMesh = _src_mesh as SphereMesh
	if s != null:
		_span = maxf(maxf(s.radius * 2.0, s.height), 0.001)


# ── GROUND ───────────────────────────────────────────────────────────────────
# One axis, four answers a surface can give a lamp. Every branch writes both the mesh and
# the skin, so the branches are idempotent and none of them inherits another's leftovers.
#
# CULLING IS PART OF THE ANSWER, and it is not uniform across the four. The authored skin
# is double-sided, so `mirror` and `relief` — which share it — show you the near hull from
# outside and the far hull from within. The chalk and the card are FRONT-culled, as they
# have shipped: from outside you look through the near wall at the inside of the far one,
# which is what an integrating sphere and a test card are for. Each value keeps exactly
# the culling it shipped with; changing one would make it measure a culling change.

func _apply_ground() -> void:
	if _shell == null or _src_mesh == null:
		return
	_shell.mesh = _src_mesh
	match ground:
		"white":
			_shell.material_override = _chalk_shell()
		"swatch":
			_shell.mesh = _swatch_mesh(_src_mesh)
			_shell.material_override = _card_shell()
		"relief":
			# The polished skin, shared with mirror — only the mesh coarsens. That is the
			# whole claim of this value, and it is only legible because the polish has a
			# lobe now: see POLISH_ROUGHNESS.
			_shell.mesh = _relief_mesh(_src_mesh)
			_shell.material_override = _polished_shell()
		_:
			_shell.material_override = _polished_shell()


# ── SKINS ────────────────────────────────────────────────────────────────────

## The polished enclosure — mirror's skin, and relief's, identical between them.
##
## brushed_metal is the right builder for a body this size: metallic 1.0 with a coloured
## specular off CHROME's albedo, a roughness that varies across the surface instead of
## sitting at one value, and anisotropy that smears the highlight into a vertical band
## rather than a dot. A band is what a facet can cut into pieces.
func _polished_shell() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.brushed_metal(PBR.CHROME, POLISH_ROUGHNESS,
		POLISH_WEAR, "y")
	return _fit(m, false, POLISH_REPEATS)


## Chalk. The barium-sulphate coat of a real integrating sphere is a matte cast surface,
## which is what PbrKit.concrete builds — a dielectric (metallic 0) with cellular
## roughness variation, so the brightness the shell returns is a field and not a wash.
## crevice_ao gives the interior the large-scale occlusion a single unbroken dome cannot
## get from SSAO, which has nothing to bite on.
func _chalk_shell() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.concrete(CHALK_ALBEDO, CHALK_WEAR)
	m.normal_scale = CHALK_BUMP
	PBR.crevice_ao(m, 0.45)
	return _fit(m, true, CHALK_REPEATS)


## The test card. Matte paint, dielectric, with the four tints arriving as VERTEX colours
## so the constant above stays the single source of them.
##
## The albedo is left at pure white and the wear at zero so the tints pass through
## unmultiplied — character for character, as flashlight_demo's card requires.
func _card_shell() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.rams_body(Color(1.0, 1.0, 1.0, 1.0), 0.0)
	# PbrKit.vertex_wear is a PROCESS-GLOBAL static and every PbrKit material reads it at
	# build time. Another artifact switching it off would silently erase this card's only
	# colour, so the flag is asserted here rather than inherited.
	m.vertex_color_use_as_albedo = true
	return _fit(m, true, CARD_REPEATS)


## Two things every skin on this body needs: detail scaled to a forty-metre span rather
## than to a metre, and the culling its value shipped with.
##
## The scaling divides out whatever tiling PbrKit set, so `repeats` lands EXACTLY that
## many texture tiles across the shell's own span whichever builder made the material,
## and the brush's 40:3 stretch survives as a ratio. Read the base off the material
## rather than hard-coding it — the kit is free to retune its builders.
##
## `front_cull` true is the chalk and the card, which have always been front-culled so you
## look through the near wall at the far one. False takes the mode straight off the
## authored skin — property to property, never through an integer — which is what keeps
## `mirror` and `relief` double-sided and therefore occupiable.
func _fit(m: StandardMaterial3D, front_cull: bool, repeats: float) -> StandardMaterial3D:
	if m == null:
		return m
	var base_x: float = maxf(absf(m.uv1_scale.x), 0.001)
	PBR.scale_detail(m, repeats / (base_x * maxf(_span, 0.001)))
	if front_cull:
		m.cull_mode = BaseMaterial3D.CULL_FRONT
	elif _src_material != null:
		m.cull_mode = _src_material.cull_mode
	else:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


# ── MESHES ───────────────────────────────────────────────────────────────────

## The shell quartered by longitude, one flashlight tint per quarter, coloured per FACE
## from the triangle centroid so the boundaries stay hard instead of blending.
##
## The SOURCE normals are carried through. Rebuilding the card with face normals — which
## is what it used to do — faceted a sixty-four-segment sphere that nothing had asked to
## be faceted, and gave `relief` nothing left to be. The card is smooth; only its colour
## steps. Its UVs come across too, because a normal map without tangents is a silent
## no-op and tangents cannot be generated without them.
func _swatch_mesh(src: Mesh) -> Mesh:
	var soup: Dictionary = _soup(src)
	var pos: PackedVector3Array = soup["pos"]
	var nrm: PackedVector3Array = soup["nrm"]
	var uv: PackedVector2Array = soup["uv"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var i: int = 0
	while i + 2 < pos.size():
		var mid: Vector3 = (pos[i] + pos[i + 1] + pos[i + 2]) / 3.0
		var ang: float = atan2(mid.x, mid.z)
		var q: int = int(floor((ang + PI) / (TAU / 4.0))) % 4
		var col: Color = SWATCH_TINTS[q]
		for j in range(3):
			st.set_normal(nrm[i + j])
			st.set_uv(uv[i + j])
			st.set_color(col)
			st.add_vertex(pos[i + j])
		i += 3
	return _tangented(st.commit())


## The same body at 12 x 6, every facet flat. Radius, height (the authored squash) and
## hemisphere flag are read off the source SphereMesh.
##
## Flat per QUAD, not per triangle. A sphere's quad is not planar, so shading its two
## triangles separately gives a hundred and forty-four triangular slivers where the value
## promises seventy-two panes — a triangulation artefact reading as the design. The pair
## is detected by a shared edge rather than assumed from index order, so a source that
## triangulates differently degrades to per-triangle instead of averaging strangers.
func _relief_mesh(src: Mesh) -> Mesh:
	var coarse := SphereMesh.new()
	var s: SphereMesh = src as SphereMesh
	if s != null:
		coarse.radius = s.radius
		coarse.height = s.height
		coarse.is_hemisphere = s.is_hemisphere
	coarse.radial_segments = RELIEF_SEGMENTS
	coarse.rings = RELIEF_RINGS
	var soup: Dictionary = _soup(coarse)
	var pos: PackedVector3Array = soup["pos"]
	var uv: PackedVector2Array = soup["uv"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var i: int = 0
	while i + 2 < pos.size():
		var pane: Vector3 = _face_normal(pos, i)
		var paired: bool = (i + 5) < pos.size() and _shares_edge(pos, i, i + 3)
		if paired:
			var sum: Vector3 = pane + _face_normal(pos, i + 3)
			if sum.length() > 0.0001:
				pane = sum.normalized()
		_emit_flat(st, pos, uv, i, pane)
		if paired:
			_emit_flat(st, pos, uv, i + 3, pane)
			i += 6
		else:
			i += 3
	return _tangented(st.commit())


## A mesh flattened to a non-indexed triangle soup — three parallel arrays, 3N entries
## each, in the mesh's own triangle order. Non-indexed because a per-face colour needs
## every triangle to own its vertices.
##
## Missing normals fall back to the outward direction and missing UVs to a spherical
## unwrap, both of which are exact for the body this artifact actually has. That is a
## guard, not a plan: the authored SphereMesh supplies both.
func _soup(src: Mesh) -> Dictionary:
	var pos := PackedVector3Array()
	var nrm := PackedVector3Array()
	var uv := PackedVector2Array()
	var out: Dictionary = {"pos": pos, "nrm": nrm, "uv": uv}
	if src == null or src.get_surface_count() == 0:
		return out
	var arrays: Array = src.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms := PackedVector3Array()
	if typeof(arrays[Mesh.ARRAY_NORMAL]) == TYPE_PACKED_VECTOR3_ARRAY:
		norms = arrays[Mesh.ARRAY_NORMAL]
	var uvs := PackedVector2Array()
	if typeof(arrays[Mesh.ARRAY_TEX_UV]) == TYPE_PACKED_VECTOR2_ARRAY:
		uvs = arrays[Mesh.ARRAY_TEX_UV]
	var order := PackedInt32Array()
	if typeof(arrays[Mesh.ARRAY_INDEX]) == TYPE_PACKED_INT32_ARRAY:
		order = arrays[Mesh.ARRAY_INDEX]
	if order.is_empty():
		order.resize(verts.size())
		for k in range(verts.size()):
			order[k] = k
	var count: int = (order.size() / 3) * 3
	for k in range(count):
		var vi: int = order[k]
		if vi < 0 or vi >= verts.size():
			continue
		var p: Vector3 = verts[vi]
		pos.append(p)
		if vi < norms.size():
			nrm.append(norms[vi])
		else:
			nrm.append(p.normalized() if p.length() > 0.0001 else Vector3.UP)
		if vi < uvs.size():
			uv.append(uvs[vi])
		else:
			uv.append(_sphere_uv(p))
	out["pos"] = pos
	out["nrm"] = nrm
	out["uv"] = uv
	return out


## Longitude/latitude unwrap, used only when a source arrives without UVs.
func _sphere_uv(p: Vector3) -> Vector2:
	var r: float = p.length()
	if r < 0.0001:
		return Vector2(0.0, 0.0)
	var u: float = atan2(p.x, p.z) / TAU + 0.5
	var v: float = acos(clampf(p.y / r, -1.0, 1.0)) / PI
	return Vector2(u, v)


## The plane normal of triangle `i`. Degenerate triangles — the sphere has a fan of them
## at each pole — fall back to the outward direction of their centroid, which for this
## body is the answer they were trying to give.
func _face_normal(pos: PackedVector3Array, i: int) -> Vector3:
	var a: Vector3 = pos[i]
	var b: Vector3 = pos[i + 1]
	var c: Vector3 = pos[i + 2]
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() > 0.0001:
		return n.normalized()
	var mid: Vector3 = (a + b + c) / 3.0
	return mid.normalized() if mid.length() > 0.0001 else Vector3.UP


## Do triangles `i` and `j` share an edge — that is, two of their three corners?
func _shares_edge(pos: PackedVector3Array, i: int, j: int) -> bool:
	var shared: int = 0
	for a in range(3):
		for b in range(3):
			if pos[i + a].is_equal_approx(pos[j + b]):
				shared += 1
				break
	return shared >= 2


## One flat-shaded triangle: the pane normal on every vertex, its own UVs, white.
func _emit_flat(st: SurfaceTool, pos: PackedVector3Array, uv: PackedVector2Array,
		i: int, n: Vector3) -> void:
	for j in range(3):
		st.set_normal(n)
		st.set_uv(uv[i + j])
		st.set_color(Color(1.0, 1.0, 1.0, 1.0))
		st.add_vertex(pos[i + j])


## Tangents, or the normal maps on these skins do nothing and nothing warns. MeshKit is
## used rather than SurfaceTool.generate_tangents because it passes a surface through with
## a loud warning when the data is not there instead of erroring into the dark.
func _tangented(m: Mesh) -> Mesh:
	if m == null:
		return m
	var out: ArrayMesh = MK.with_tangents(m, 0)
	if out == null:
		return m
	return out
