# CubeWrapperLibrary.gd — the sim-cube wrapper: THE GRID CELL MADE VISIBLE.
# One chassis (the invariant hand-grammar: base plate, label plate, touch
# corner, accent line, centered mount point) + five FAMILY expressions so
# housed artifacts stay recognizable by nature (Palle: "room for more cube
# families so we do not collapse all objects"):
#   gridglass — glazed, steel-cool, grid-lined: discrete worlds (CA, arrays)
#   tank      — liquid tint, brass-warm, hover+shadow: continuous physics
#   cage      — mesh bars, dark: agents — things that could get out
#   shadowbox — one open face, dark, backlit: luminous curves
#   openframe — edges only, lab-white: growth — things that should breathe
# Declarations: commons/data/principal_artifacts.json (wrappers.cube_families).
# Consumers: sim_cube artifact (runtime), export_cube_gltf.gd (browser).
#
# ── SURFACE PASS — 2026-08-10 ────────────────────────────────────────────────
# This library shipped nine materials built by one helper that took a colour, a
# roughness scalar and a metallic scalar. Every surface therefore had a single
# perfectly uniform highlight, four of the nine sat at a physically meaningless
# mid metallic (0.2 / 0.4 / 0.6 / 0.7 — neither metal nor dielectric), and every
# box was a BoxMesh with zero-radius edges that catch no highlight at all. The
# result read as flat-shaded blocking, which is a problem here specifically:
# sim_cube is FURNITURE. It is the vitrine, the plinth, the table that another
# artifact stands on, so it has to read as fabricated museum kit — powder-coated
# steel, brushed stainless, laminated glass, an anodised label plate — while
# staying quiet enough that the specimen inside is still the subject.
#
# Nothing about the ARGUMENT moved. Not one size, position, rotation, mount
# point, fit budget or family branch changed; both DNA axes (family, fit) build
# exactly the geometry they built before, and the default (gridglass / metric)
# still produces the shipped silhouette. What changed is the finish.
#
# GRAIN SCALE, which is the expensive one. PbrKit's triplanar is LOCAL, and this
# library builds parts spanning two and a half orders of magnitude in the same
# scene: a 2 m base plate and an 8 mm grid line, a 1 m plinth and a 35 mm edge
# post. The kit's builders author their tiling for hand-sized parts (3-6 tiles
# per metre). Left alone, the 2 m chassis plate takes the powder coat at its
# authored 3 tiles/m, which on the BRUSH field is one noise period every 5.9 mm.
# With the whole 3 m housing framed at 760 px that is 1.3 pixels: not detail,
# television static — and the failure that gets misdiagnosed as SSIL, SSR,
# debanding, SSAO, DOF or soft shadows in turn. So every material is re-fitted to
# the part it is about to dress, by size class, in _fit_grain below. The same
# plate now lands at 22.6 mm, 5.2 px. See the table below for the rest.
#
# The .tscn root (commons/artifacts/sim_cube/sim_cube.tscn) carries NO transform:
# a bare Node3D with the script and nothing else, scale (1,1,1). Every metre in
# this file is therefore a metre in the map, and the tiling numbers can be trusted.
extends RefCounted

const PBR := preload("res://commons/render/pbr_kit.gd")

const S := 2.0            # the housing: 2m (artifacts overflowed 1m — Palle)
const PLINTH_H := 1.0     # every sim-cube stands on a 1m cube plinth by default
const EDGE := 0.035
const BASE_H := 0.06

var mat_steel: StandardMaterial3D
var mat_brass: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_dark_matte: StandardMaterial3D
var mat_white: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_tankglass: StandardMaterial3D
var mat_amber: StandardMaterial3D
var mat_plate: StandardMaterial3D
var mat_backlight: StandardMaterial3D

const FAMILIES := ["gridglass", "tank", "cage", "shadowbox", "openframe",
	"table_display_1m", "table_display_2m", "podium", "plinth", "frame", "pedestal"]

# ── GRAIN SCALE ──────────────────────────────────────────────────────────────
# PbrKit's grain textures are 256 px of FastNoiseLite. The MICRO field runs at
# frequency 0.095, so its dominant feature is about 10.5 px — near 4% of one
# tile. A material tiling at T tiles per metre therefore puts a feature at
# 0.041 / T metres. The BRUSH field is 2.3x finer again (frequency 0.22), which
# is why the four brushed roles carry a 0.6 correction below.
#
# The housing families are 2 m across and 3 m tall (1 m plinth + 2 m housing),
# so a 760 px frame around one lands near 230 px per metre. The stand families
# are much smaller — a podium is 1.16 m top to floor — and the same frame gives
# them nearer 600 px/m, which is why the mid class can afford a finer grain than
# it looks like it can. Working backwards from "a feature several pixels wide":
#
#   class   ref part   T (micro)   feature   px on its own family
#   l       1.8 m      1.30        31 mm     7.2 px   the 2 m base plate, the
#                                                     1 m plinth, glass panes
#   m       0.45 m     4.89          8 mm    3-4 px   label plate, podium top
#                                                     and lip, plinth foot
#   s       0.08 m    11.00          4 mm    <1 px    edge posts, grid lines,
#                                                     cage bars, touch corner
#
# Sub-pixel on the small parts is not a failure — a 35 mm post is 8 px wide in
# that frame, and the micro normal's job there is to break the specular, not to
# be seen. Sub-pixel on the 2 m PLATE is the failure, and that is the one this
# table exists to prevent. The four brushed roles carry the 0.6 correction, so
# read their numbers off the same rows: the 2 m plate lands at 23 mm, 5.2 px.
const GRAIN_REF: float = 2.2      # tiles per metre for a 1 m part
const GRAIN_MIN: float = 1.3      # never coarser (the 2 m slab)
const GRAIN_MAX: float = 11.0     # never finer (the 35 mm post)
const CLASS_L_REF: float = 1.8
const CLASS_M_REF: float = 0.45
const CLASS_S_REF: float = 0.08
const CLASS_L_MIN: float = 0.9    # longest dimension at or above this is "l"
const CLASS_M_MIN: float = 0.25
const WEAR_MIN_SIZE: float = 0.4  # below this, vertex wear is invisible; skip it

## Baked-in vertex wear per role: chamfers stay bright, faces dull a touch, the
## underside darkens where a floor is. Kept modest — the dark role already takes
## a grime multiply from PbrKit.weather(), and three "slight" darkenings stacked
## on a charcoal surface is how display furniture arrives at black. Two is the
## limit here: grime + this. No crevice AO anywhere in this file.
const ROLE_WEAR := {
	"dark": 0.20, "dark_matte": 0.10, "steel": 0.14, "brass": 0.16,
	"white": 0.08, "plate": 0.10, "glass": 0.0, "tankglass": 0.0,
	"amber": 0.0, "backlight": 0.0,
}

## Roles whose grain comes off the BRUSH field, which is 2.3x finer than MICRO
## at the same tiling. Without this correction a brushed 2 m rail lands at 3 px
## and speckles.
const ROLE_BRUSHED := ["dark", "steel", "brass", "plate"]

## Roles that are LIGHT rather than finish. One instance, no size classes, no
## grain fitting, and — per the standing rule that emissive is already loud —
## exactly the emission energies this library has always shipped.
const ROLE_EMISSIVE := ["amber", "backlight"]

## Roles whose builder actually READS the brush axis. Everything else (the
## powder coat, the matte paints, the glazing) is isotropic, so keying its cache
## on an axis would mint identical duplicate materials per part orientation.
const ROLE_AXIAL := ["steel", "brass", "plate"]

var _mats: Dictionary = {}


func _init() -> void:
	# The public fields are the canonical large-class instances; _box re-resolves
	# each one to the right size class and brush axis for the part it dresses.
	mat_steel = _role_mat("steel", "y", "l")
	mat_brass = _role_mat("brass", "y", "l")
	mat_dark = _role_mat("dark", "y", "l")
	mat_dark_matte = _role_mat("dark_matte", "y", "l")
	mat_white = _role_mat("white", "y", "l")
	mat_glass = _role_mat("glass", "y", "l")
	mat_tankglass = _role_mat("tankglass", "y", "l")
	mat_amber = _role_mat("amber", "y", "l")
	mat_plate = _role_mat("plate", "x", "m")
	mat_backlight = _role_mat("backlight", "y", "l")


# ── MATERIALS ────────────────────────────────────────────────────────────────

## Build (or reuse) the material for one role at one brush axis and size class.
## Cached per library instance, so a gridglass build mints six materials rather
## than one per box.
func _role_mat(role: String, axis: String, cls: String) -> StandardMaterial3D:
	if role in ROLE_EMISSIVE:
		axis = "y"
		cls = "l"
	elif not (role in ROLE_AXIAL):
		axis = "y"
	var key: String = "%s|%s|%s" % [role, axis, cls]
	if _mats.has(key):
		var hit: StandardMaterial3D = _mats[key]
		return hit
	var m: StandardMaterial3D = _build_role(role, axis)
	m.set_meta("cube_role", role)
	var fine: float = 0.6 if role in ROLE_BRUSHED else 1.0
	_fit_grain(m, _class_ref(cls), fine)
	_mats[key] = m
	return m


## The nine finishes, plus the matte twin the shadowbox needs.
##
## `axis` is the brush direction, derived from the part in _brush_axis(): rolled
## and extruded stock is brushed along its length, so a 2 m rail streaks along
## its run and a 1 m lid streaks across its face. That is free read for nothing.
func _build_role(role: String, axis: String) -> StandardMaterial3D:
	match role:
		"dark":
			# Powder-coated steel: a dielectric coat with a clear film, thinning
			# to bare brushed metal at the wear points. Albedo is lifted off the
			# old (0.10, 0.11, 0.12) because a charcoal with nothing left to
			# shade reads as a hole punched in the room, not as a dark object.
			#
			# ARITHMETIC, because this is the surface three darkenings could meet
			# on. terminal_body(wear 0.22) darkens 3.1% then lightens 5%, landing
			# albedo at 0.174; its internal weather() grime multiplies down to
			# 0.90 at worst; the vertex wear in _box takes another 2.8% off the
			# faces. Darkest visible pixel 0.152 — RGB 39, a legible charcoal.
			# That is TWO material darkenings plus the vertex pass and no AO map;
			# adding crevice_ao here is what would tip it into black.
			#
			# The resulting metallic is 0.256, inside the band PbrKit.audit()
			# calls "neither metal nor dielectric". That is not an oversight: a
			# powder coat thinning to bare steel legitimately ramps through the
			# middle, which is why terminal_body drives metallic off wear at all.
			return PBR.terminal_body(Color(0.135, 0.142, 0.152), 0.22)
		"dark_matte":
			# The shadowbox interior. Its whole job is to be the dark the backlit
			# subject glows against, so it gets no clear coat and no anisotropic
			# sheen to streak that backlight across.
			return PBR.rams_body(Color(0.118, 0.124, 0.134), 0.20)
		"steel":
			# Brushed stainless. Metallic 1.0 with a measured albedo instead of
			# the old 0.6 — kept a shade cool and dark of PbrKit.STEEL so the
			# family's steel-cool tone survives the move to a real metal.
			return PBR.brushed_metal(Color(0.520, 0.545, 0.575), 0.30, 0.14, axis)
		"brass":
			return PBR.brushed_metal(Color(0.655, 0.545, 0.315), 0.30, 0.20, axis)
		"plate":
			# The label plate — a brushed anodised blank waiting for its text.
			return PBR.brushed_metal(Color(0.665, 0.650, 0.620), 0.26, 0.08, axis)
		"white":
			# Matte industrial paint: the openframe edges and the display panels.
			return PBR.rams_body(Color(0.885, 0.885, 0.865), 0.05)
		"glass":
			# Vitrine glazing. The rim term is the important part — real glass
			# goes near-opaque at grazing angles, and without it a glass box is a
			# faint tinted ghost with no edges, which is what shipped.
			return PBR.glass(PBR.GLASS_TINT, 0.035, 0.16)
		"tankglass":
			# Slightly frosted and tinted: the liquid read.
			return PBR.glass(Color(0.46, 0.72, 0.70), 0.06, 0.30)
		"amber":
			# Touch corner and accent line. Energy 1.4 — the shipped value,
			# unchanged. The gain is that the albedo is now darkened relative to
			# the emission, so the accent keeps its hue instead of clipping white
			# the moment a scene light lands on it.
			return PBR.led(Color(1.0, 0.60, 0.17), 1.4)
		"backlight":
			# The panel a subject is read against. Energy 0.9 — shipped value.
			# Roughness raised back up after emissive(): this is a diffuser, and
			# a glossy one would carry a mirror highlight across its own glow.
			var bl: StandardMaterial3D = PBR.emissive(Color(0.74, 0.82, 1.0), 0.9)
			bl.roughness = 0.72
			return bl
	return PBR.rams_body(PBR.BODY_LIGHT, 0.08)


## Land a kit material's detail frequency on the part it is about to dress.
##
## scale_detail MULTIPLIES, so the factor is derived from whatever tiling the
## builder chose rather than assigned over the top of it — each finish keeps its
## own character and only the frequency moves. The base is the SMALLEST uv1
## component because the brushed builders are anisotropic (3 across, 40 along):
## taking the minimum picks the across-grain rate whichever axis the brush runs,
## and preserves the 40:3 stretch that IS the brush.
func _fit_grain(m: StandardMaterial3D, longest: float, fine: float) -> void:
	if m == null or not m.uv1_triplanar:
		return
	var base: float = minf(minf(m.uv1_scale.x, m.uv1_scale.y), m.uv1_scale.z)
	if base < 0.001:
		return
	var want: float = clampf(GRAIN_REF / maxf(longest, 0.02), GRAIN_MIN, GRAIN_MAX)
	PBR.scale_detail(m, (want * fine) / base)


func _size_class(longest: float) -> String:
	if longest >= CLASS_L_MIN:
		return "l"
	if longest >= CLASS_M_MIN:
		return "m"
	return "s"


func _class_ref(cls: String) -> float:
	if cls == "l":
		return CLASS_L_REF
	if cls == "m":
		return CLASS_M_REF
	return CLASS_S_REF


## Brush direction = the part's long axis. Stock is brushed along its length.
func _brush_axis(size: Vector3) -> String:
	var ax: float = absf(size.x)
	var ay: float = absf(size.y)
	var az: float = absf(size.z)
	if ay >= ax and ay >= az:
		return "y"
	if ax >= az:
		return "x"
	return "z"


## Swap a role material for the variant fitted to this part. A material handed in
## from outside (build()'s custom `accent`) carries no role and is used as given.
func _sized(mat: StandardMaterial3D, size: Vector3) -> StandardMaterial3D:
	if mat == null or not mat.has_meta("cube_role"):
		return mat
	var role: String = str(mat.get_meta("cube_role"))
	var longest: float = maxf(absf(size.x), maxf(absf(size.y), absf(size.z)))
	return _role_mat(role, _brush_axis(size), _size_class(longest))


## Every part in this library is a box, and every box is now CHAMFERED. A real
## object has no zero-radius edges; a 1-2 mm break is what draws the highlight
## line that separates a plinth from a grey rectangle. 44 triangles instead of
## 12 — 3.7x, inside the VR budget, and the heaviest family (cage) still totals
## about 1,700 triangles.
##
## Signature and call sites are unchanged: the size class, the brush axis, the
## vertex wear and the shadow flag are all derived from the arguments already
## being passed.
func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var use: StandardMaterial3D = _sized(mat, size)
	var longest: float = maxf(absf(size.x), maxf(absf(size.y), absf(size.z)))
	var w: float = 0.0
	if longest >= WEAR_MIN_SIZE and use != null and use.has_meta("cube_role"):
		w = float(ROLE_WEAR.get(str(use.get_meta("cube_role")), 0.0))
	var mi: MeshInstance3D = PBR.box(pos, size, use, -1.0, w)
	# Glazing that casts an opaque black shadow is the oldest vitrine tell, and
	# on the Quest it is a shadow-map draw bought for nothing.
	if use != null and use.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func build(family: String, accent: StandardMaterial3D = null) -> Node3D:
	"""origin at bottom-centre (plinth base); interior clear for the mount."""
	var n := Node3D.new()
	var acc := accent if accent != null else mat_amber
	# stand families: no plinth, no housing — table displays and the podium
	if family == "table_display_1m":
		_table_display(n, acc, 1.0)
		return n
	if family == "table_display_2m":
		_table_display(n, acc, 2.0)
		return n
	if family == "podium":
		_podium(n, acc)
		return n
	if family == "pedestal":
		_pedestal(n, acc)
		return n
	if family == "plinth":
		_plinth(n, acc)
		return n
	if family == "frame":
		_frame(n, acc)
		return n
	# the default 1m cube plinth under every housing
	_box(n, Vector3(1.0, PLINTH_H, 1.0), Vector3(0, PLINTH_H * 0.5, 0), mat_dark)
	_box(n, Vector3(1.06, 0.05, 1.06), Vector3(0, PLINTH_H - 0.025, 0), mat_steel)
	var housing := Node3D.new()
	housing.name = "Housing"
	housing.position.y = PLINTH_H
	n.add_child(housing)
	var hover := 0.0
	if family in ["tank", "openframe"]:
		hover = 0.05                        # the momo shadow gap
	_chassis(housing, acc, hover)
	match family:
		"gridglass": _f_gridglass(housing, hover)
		"tank": _f_tank(housing, hover)
		"cage": _f_cage(housing, hover)
		"shadowbox": _f_shadowbox(housing, hover)
		"openframe": _f_openframe(housing, hover, mat_white)
		_: _f_openframe(housing, hover, mat_steel)
	return n


func mount_rotation(family: String) -> Vector3:
	"""radians. Families made for FLAT content stand it upright: a plane
	lying in XZ (normal +Y) rotates -90deg about X to face the viewer."""
	if family == "frame":
		return Vector3(-PI * 0.5, 0, 0)
	return Vector3.ZERO


func mount_point(family: String) -> Vector3:
	"""where the housed artifact's origin should sit (local)."""
	if family == "pedestal":
		return Vector3(0, 1.02, 0)          # on the platform top
	if family in ["table_display_1m", "table_display_2m"]:
		return Vector3(0, 0.82, -0.28)     # on the table, against the panel
	if family == "podium":
		return Vector3(0, 1.14, 0)          # the operating surface
	if family == "plinth":
		return Vector3(0, 1.0, 0)           # on the top plate
	if family == "frame":
		return Vector3(0, 0.85, 0.06)       # in front of the backing, low anchor
	var hover := 0.05 if family in ["tank", "openframe"] else 0.0
	return Vector3(0, PLINTH_H + hover + BASE_H + 0.01, 0)


# ── stand families ───────────────────────────────────────────────────────────
func _table_display(n: Node3D, acc: StandardMaterial3D, w: float) -> void:
	"""a table with a FRAMELESS vertical panel — 2D content edge to edge."""
	var top_y := 0.78
	# slim steel legs + dark top slab
	for sx in [-w * 0.5 + 0.06, w * 0.5 - 0.06]:
		for sz in [-0.32, 0.32]:
			_box(n, Vector3(0.05, top_y, 0.05), Vector3(sx, top_y * 0.5, sz), mat_steel)
	_box(n, Vector3(w, 0.05, 0.8), Vector3(0, top_y + 0.025, 0), mat_dark)
	# the frameless panel: one thin bright surface, no border, full width
	var panel_h := 1.25
	_box(n, Vector3(w, panel_h, 0.022),
		Vector3(0, top_y + 0.05 + panel_h * 0.5, -0.34), mat_white)
	# two small stand tabs behind (invisible from the front)
	for sx in [-w * 0.25, w * 0.25]:
		_box(n, Vector3(0.05, 0.3, 0.05), Vector3(sx, top_y + 0.2, -0.395), mat_dark)
	# the hand-grammar on the table's front edge
	_box(n, Vector3(0.34, 0.08, 0.012), Vector3(-w * 0.5 + 0.24, top_y - 0.06, 0.4), mat_plate)
	_box(n, Vector3(0.08, 0.08, 0.02), Vector3(w * 0.5 - 0.12, top_y - 0.06, 0.4), acc)
	_box(n, Vector3(w, 0.018, 0.014), Vector3(0, top_y + 0.055, 0.4), acc)
	# GROUNDING. Every other family meets the floor with a flush foot plate; this
	# one stands on four 5 cm legs and floated. One projected contact pool, a
	# Decal so it conforms to whatever it lands on. No light, no probe.
	n.add_child(PBR.ground_shadow(w * 0.44, 0.5, 0.06))


func _pedestal(n: Node3D, acc: StandardMaterial3D) -> void:
	"""the 1m elevation base — a broad sturdy platform for self-standing
	instruments (the galton class): elevation, not housing."""
	_box(n, Vector3(1.3, 0.08, 1.3), Vector3(0, 0.04, 0), mat_dark)      # foot
	_box(n, Vector3(1.1, 0.86, 1.1), Vector3(0, 0.08 + 0.43, 0), mat_dark)
	_box(n, Vector3(1.24, 0.06, 1.24), Vector3(0, 0.97, 0), mat_steel)   # platform
	# hand-grammar on the front face
	_box(n, Vector3(0.34, 0.09, 0.012), Vector3(-0.3, 0.8, 0.56), mat_plate)
	_box(n, Vector3(0.08, 0.08, 0.02), Vector3(0.4, 0.8, 0.56), acc)
	_box(n, Vector3(1.1, 0.018, 0.014), Vector3(0, 0.94, 0.56), acc)


func _podium(n: Node3D, acc: StandardMaterial3D) -> void:
	"""the operating stand — a small interactive at hand height (coin_toss)."""
	_box(n, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.04, 0), mat_dark)      # foot
	_box(n, Vector3(0.4, 0.96, 0.4), Vector3(0, 0.08 + 0.48, 0), mat_dark)
	_box(n, Vector3(0.62, 0.06, 0.62), Vector3(0, 1.1, 0), mat_steel)    # top
	_box(n, Vector3(0.62, 0.03, 0.08), Vector3(0, 1.085, 0.31), mat_dark)  # lip
	# hand-grammar on the column front
	_box(n, Vector3(0.3, 0.08, 0.012), Vector3(-0.04, 0.9, 0.21), mat_plate)
	_box(n, Vector3(0.07, 0.07, 0.018), Vector3(0.14, 0.78, 0.21), acc)
	_box(n, Vector3(0.4, 0.016, 0.014), Vector3(0, 1.07, 0.21), acc)


func _plinth(n: Node3D, acc: StandardMaterial3D) -> void:
	"""the display column — a small thing held to the eye on a top plate."""
	_box(n, Vector3(0.66, 0.05, 0.66), Vector3(0, 0.025, 0), mat_dark)     # foot plate
	_box(n, Vector3(0.5, 0.95, 0.5), Vector3(0, 0.05 + 0.475, 0), mat_dark)  # column
	_box(n, Vector3(0.6, 0.04, 0.6), Vector3(0, 0.98, 0), mat_steel)       # top plate
	# hand-grammar on the column front (+Z)
	_box(n, Vector3(0.3, 0.08, 0.012), Vector3(-0.04, 0.78, 0.251), mat_plate)
	_box(n, Vector3(0.07, 0.07, 0.018), Vector3(0.15, 0.66, 0.251), acc)
	_box(n, Vector3(0.4, 0.016, 0.014), Vector3(0, 0.92, 0.251), acc)


func _frame(n: Node3D, acc: StandardMaterial3D) -> void:
	"""a freestanding framed display for flat work — the panel HOVERS above the base."""
	_box(n, Vector3(1.2, 0.08, 0.3), Vector3(0, 0.04, 0), mat_dark)        # base bar
	# two slim posts rising from the ends
	for px in [-0.56, 0.56]:
		_box(n, Vector3(0.05, 2.2, 0.05), Vector3(px, 0.08 + 1.1, 0), mat_dark)
	# the framed panel — dark border around an inset white backing, centred ~1.45m
	var pw := 1.1
	var ph := 1.4
	var cy := 1.45
	_box(n, Vector3(pw, ph, 0.05), Vector3(0, cy, 0), mat_dark)            # frame border
	_box(n, Vector3(pw - 0.1, ph - 0.1, 0.03), Vector3(0, cy, 0.011), mat_white)  # inset backing
	# hand-grammar on the base bar front (+Z)
	_box(n, Vector3(0.3, 0.05, 0.012), Vector3(-0.4, 0.05, 0.151), mat_plate)
	_box(n, Vector3(0.06, 0.06, 0.018), Vector3(0.48, 0.05, 0.151), acc)
	_box(n, Vector3(1.2, 0.014, 0.014), Vector3(0, 0.075, 0.151), acc)


# ── the chassis: the one hand-grammar ────────────────────────────────────────
func _chassis(n: Node3D, acc: StandardMaterial3D, hover: float) -> void:
	var y0 := hover
	_box(n, Vector3(S, BASE_H, S), Vector3(0, y0 + BASE_H * 0.5, 0), mat_dark)
	# label plate — lower front left
	_box(n, Vector3(0.34, 0.1, 0.012), Vector3(-0.28, y0 + BASE_H + 0.07, S * 0.5), mat_plate)
	# touch corner — lower front right, emissive
	_box(n, Vector3(0.09, 0.09, 0.02), Vector3(0.4, y0 + BASE_H + 0.065, S * 0.5), acc)
	# accent line along the base front edge
	_box(n, Vector3(S, 0.02, 0.015), Vector3(0, y0 + BASE_H + 0.005, S * 0.5), acc)


func _edges(n: Node3D, mat: StandardMaterial3D, y0: float, h: float) -> void:
	var hs := S * 0.5
	for sx in [-hs, hs]:
		for sz in [-hs, hs]:
			_box(n, Vector3(EDGE, h, EDGE), Vector3(sx, y0 + h * 0.5, sz), mat)
	for sy in [y0, y0 + h]:
		for sz in [-hs, hs]:
			_box(n, Vector3(S, EDGE, EDGE), Vector3(0, sy, sz), mat)
		for sx in [-hs, hs]:
			_box(n, Vector3(EDGE, EDGE, S), Vector3(sx, sy, 0), mat)


# ── the families ─────────────────────────────────────────────────────────────
func _f_gridglass(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_steel, y0, h)
	for sz in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(S - 0.08, h - 0.08, 0.012), Vector3(0, y0 + h * 0.5, sz), mat_glass)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.012, h - 0.08, S - 0.08), Vector3(sx, y0 + h * 0.5, 0), mat_glass)
	_box(n, Vector3(S - 0.08, 0.012, S - 0.08), Vector3(0, y0 + h, 0), mat_glass)
	# the grid lines — back pane carries the substrate look
	for i in 3:
		var t := -S * 0.5 + (i + 1) * S * 0.25
		_box(n, Vector3(0.008, h - 0.1, 0.014), Vector3(t, y0 + h * 0.5, -S * 0.5 + 0.002), mat_steel)
		_box(n, Vector3(S - 0.1, 0.008, 0.014), Vector3(0, y0 + BASE_H + (i + 1) * (h - 0.1) * 0.25, -S * 0.5 + 0.002), mat_steel)


func _f_tank(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_brass, y0, h)
	for sz in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(S - 0.06, h - 0.06, 0.014), Vector3(0, y0 + h * 0.5, sz), mat_tankglass)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.014, h - 0.06, S - 0.06), Vector3(sx, y0 + h * 0.5, 0), mat_tankglass)
	_box(n, Vector3(S - 0.06, 0.014, S - 0.06), Vector3(0, y0 + h, 0), mat_tankglass)
	# low backlight panel inside the back wall
	_box(n, Vector3(S - 0.12, h - 0.2, 0.008), Vector3(0, y0 + h * 0.5, -S * 0.5 + 0.03), mat_backlight)


func _f_cage(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	_edges(n, mat_dark, y0, h)
	for i in 5:
		var t := -S * 0.5 + (i + 1) * S / 6.0
		for sz in [-S * 0.5, S * 0.5]:
			_box(n, Vector3(0.018, h, 0.018), Vector3(t, y0 + h * 0.5, sz), mat_dark)
		for sx in [-S * 0.5, S * 0.5]:
			_box(n, Vector3(0.018, h, 0.018), Vector3(sx, y0 + h * 0.5, t), mat_dark)
	_box(n, Vector3(S, 0.03, S), Vector3(0, y0 + h, 0), mat_dark)


func _f_shadowbox(n: Node3D, hover: float) -> void:
	var y0 := hover + BASE_H
	var h := S - BASE_H
	# matte shell: this box is the dark a subject is read against, so the walls
	# do not carry the powder-coat's clear film or its anisotropic sheen.
	_box(n, Vector3(S, h, 0.03), Vector3(0, y0 + h * 0.5, -S * 0.5), mat_dark_matte)
	for sx in [-S * 0.5, S * 0.5]:
		_box(n, Vector3(0.03, h, S), Vector3(sx, y0 + h * 0.5, 0), mat_dark_matte)
	_box(n, Vector3(S, 0.03, S), Vector3(0, y0 + h, 0), mat_dark_matte)
	# the backlight the subject glows against
	_box(n, Vector3(S - 0.1, h - 0.1, 0.01), Vector3(0, y0 + h * 0.5, -S * 0.5 + 0.03), mat_backlight)


func _f_openframe(n: Node3D, hover: float, mat: StandardMaterial3D) -> void:
	_edges(n, mat, hover + BASE_H, S - BASE_H)

# ── THE EM-SQUARE LAYOUT ENGINE ──────────────────────────────────────────────
# Font metrics for artifacts: every housed artifact carries a base contract
# (anchor_y / size / pose / base — commons/data/artifact_metrics.json) and
# this ONE setter fits any artifact into any family without looking inside —
# the way a layout engine sets type. Wang tiles = the space's edge contract;
# this = the artifact's base contract.

const PANEL_SPECS := {
	"frame": {"center": Vector3(0, 1.45, 0.055), "w": 1.06, "h": 1.36},
	"table_display_1m": {"center": Vector3(0, 1.46, -0.31), "w": 0.96, "h": 1.2},
	"table_display_2m": {"center": Vector3(0, 1.46, -0.31), "w": 1.96, "h": 1.2},
}
const FIT_BUDGETS := {
	"gridglass": [1.8, 1.8], "tank": [1.8, 1.8], "cage": [1.8, 1.8],
	"shadowbox": [1.8, 1.8], "openframe": [1.9, 1.9],
	"podium": [0.55, 0.9], "plinth": [0.55, 1.0], "pedestal": [1.15, 2.0],
	"table_display_1m": [0.9, 0.7], "table_display_2m": [1.9, 0.7],
	"frame": [1.0, 1.3],
}


func fit_artifact(inst: Node3D, family: String, m: Dictionary) -> Dictionary:
	"""fit a mounted artifact by its em-square metrics. Returns what it did."""
	if m.is_empty() or m.get("unreliable_rest_aabb", false):
		inst.position = mount_point(family)
		inst.rotation = mount_rotation(family)
		return {"mode": "fallback"}
	var size: Array = m.get("size", [1.0, 1.0, 1.0])
	var w := float(size[0])
	var h := float(size[1])
	var dd := float(size[2])
	var anchor := float(m.get("anchor_y", 0.0))
	var pose := str(m.get("pose", "volume"))
	# PANEL branch: flat content standing on a display surface
	if pose == "flat" and PANEL_SPECS.has(family):
		var spec: Dictionary = PANEL_SPECS[family]
		var s2: float = minf(1.0, minf(float(spec["w"]) / maxf(w, 0.01),
				float(spec["h"]) / maxf(dd, 0.01)))
		inst.rotation = Vector3(PI * 0.5, 0, 0)   # cells face the viewer (+Z)
		inst.scale = Vector3.ONE * s2
		inst.position = spec["center"]
		return {"mode": "panel", "scale": s2}
	# BASE branch: base sits on the mount point, contain-scaled to budget
	var bud: Array = FIT_BUDGETS.get(family, [1.8, 1.8])
	var s3: float = minf(1.0, minf(float(bud[0]) / maxf(maxf(w, dd), 0.01),
			float(bud[1]) / maxf(h, 0.01)))
	inst.rotation = Vector3.ZERO
	inst.scale = Vector3.ONE * s3
	var mp := mount_point(family)
	inst.position = Vector3(mp.x, mp.y + anchor * s3, mp.z)
	return {"mode": "base", "scale": s3, "anchor": anchor}
