extends Node3D
class_name SubstanceRoom

## substance_room — one body, six substances, and the two questions the word `substance`
## has been answering as if they were one.
##
## THE FAMILY. Three artifacts declare an axis called `substance` and between them use
## seven words, three of which appear twice:
##
##   breathing_room   solid | flesh | glass | fabric
##                    (breathing_room_scene.gd — NOT breathing_room.gd, see `declines`)
##   rainbow          light | glass | solid
##   sculpt_one       mixed | glossy | fabric | granular
##                    (SculptOne.gd — again not the file named after the token)
##
## THE FIRST THING THE CODE SAYS, and it corrects the brief this bench was built from:
## IN ALL THREE MEMBERS, `substance` NEVER TOUCHES GEOMETRY. Not once. breathing_room
## re-skins two SoftBody3D slabs that are the same slabs under every value; rainbow
## re-skins arc bands whose vertices are computed before the axis is read; sculpt_one
## says it outright in its own header — "`substance` rewrites roughness / metallic /
## clearcoat / normal only", and gives the geometry to a SECOND axis, `hand`, with the
## rule "the axis moves the geometry; it must not move the surfaces underneath it".
##
## So the family's `substance` is unanimously a claim about a SURFACE: what light does
## when it arrives. And yet four of the seven words — flesh, fabric, granular, and solid
## itself — are borrowed from materials whose everyday meaning is MECHANICAL. Flesh
## yields. Fabric drapes. A granular heap pours. Solid is the word for a thing that does
## neither. The vocabulary promises an answer about the body and delivers an answer about
## the skin, and nothing in the corpus has ever made the promise payable.
##
## THE TWO QUESTIONS, then, stated as this bench states them:
##
##   Q1  TRANSMISSION — does light get through?      answered by the members' code
##   Q2  STANCE       — does the body hold its shape?  answered by nobody's code
##
## `solid` is the only word that answers both, which is why it is the one word in two
## members and why it is both members' default. `glass` answers Q1 and the members' code
## says nothing about Q2. `fabric`, `flesh` and `granular` are Q2 words that the members'
## code spends entirely on Q1 — on roughness and a normal map. A two-word vocabulary is
## being asked to name a two-axis space, and cells of that space have no word at all: a
## body that is transparent AND slumps is not something this family can say.
##
## WHAT THIS BENCH DOES ABOUT IT. One body — a 0.72 x 0.24 x 0.34 m bar spanning two
## piers with a 0.30 m gap under its middle — is rendered under each of six substances,
## and `reading` separates the two questions into two rigs:
##
##   body     both answers at once, each substance's own optics on its own stance. This
##            is the family's condition: the confound, drawn.
##   through  a TRANSMISSION rig. The bar is pinned to the reference stance and given
##            only the three things in the members' code that let light past a surface —
##            alpha, subsurface scatter, unshaded — against a striped screen standing
##            directly behind it. Hue, roughness and metallic are pinned to one reference.
##   bear     a LOAD rig. The bar is at its own stance with a load plate resting on it,
##            and every substance wears ONE neutral matte. Only the silhouette and the
##            height of the plate can differ.
##
## And then the two rigs produce their own nulls, which ARE the argument:
##   in `through`, solid, fabric and granular are ONE PICTURE, to the byte, because three
##   substances that are equally opaque cannot be told apart by a question about light;
##   in `bear`, solid and glass are ONE PICTURE, to the byte, because two substances that
##   hold their shape equally cannot be told apart by a question about force.
## Neither null is a spare check. Each is one question failing to see the other.
##
## Deterministic: no randf, no noise, no _process, no Timer, no texture that bakes on a
## worker thread. Every vertex is arithmetic on eight constants, so two builds of one
## value are the same mesh.


## WHAT THE BODY IS MADE OF. Six words, the honest union of three vocabularies, and the
## `note` in the registry says which member each came from and whether the members that
## share a word agree about it.
##
##   solid     TWO MEMBERS, and they agree. breathing_room's branch never constructs a
##             material at all (the shipped walls are Godot's default grey); rainbow
##             builds TRANSPARENCY_DISABLED, metallic 0.0, roughness 0.6. Both mean
##             opaque and diffuse. It is the only word here with no albedo anywhere in
##             the family, so it ships the reference neutral — which is also what makes
##             it the honest default. ANSWERS BOTH QUESTIONS.
##   glass     TWO MEMBERS, and they agree about the KIND of claim and differ about the
##             amount by roughly 2x each way. Both implement it as transparency AND a
##             specular change, not one or the other: breathing_room alpha 0.32,
##             roughness 0.05, metallic 0.15; rainbow alpha 0.70, roughness 0.15,
##             metallic 0.35. breathing_room's numbers are used here, verbatim.
##             ANSWERS Q1. SILENT ON Q2 in every member.
##   light     rainbow only. TRANSPARENCY_ALPHA plus unshaded — "an optical event with no
##             location", its own truth line. Note the arithmetic: rainbow's band alpha
##             is 0.70, so the family's word for pure light is more than TWICE AS OPAQUE
##             as its word for glass. ANSWERS Q1. HAS NO Q2 ANSWER AT ALL — which is
##             different from being silent, and `bear` is where the difference shows.
##   flesh     breathing_room only, and the one value in the whole family whose optics
##             are neither opaque nor alpha: subsurface scattering, skin mode, strength
##             0.8. Light gets IN and comes back out without going through. ANSWERS Q1
##             in a third way, and its ordinary meaning answers Q2 too.
##   fabric    TWO MEMBERS, and they DISAGREE. Both say opaque, fully rough, zero
##             metallic — breathing_room roughness 1.0 with albedo (0.62, 0.60, 0.55),
##             sculpt_one roughness 0.9 with a simplex normal map at bump 2.0. Only
##             sculpt_one gives it a weave. Neither gives it a drape. Q2 word, spent on
##             Q1.
##   granular  sculpt_one only: roughness 0.7, metallic 0.2, CELLULAR normal map at bump
##             5.0. A heap has no tensile strength and is the clearest Q2 answer in the
##             family — and in the source it is a bump map. Q2 word, spent on Q1.
## (One line, deliberately over the column guide: check_dna_declarations.py matches
## `@export_enum(...)` and its `var` on the SAME line, and a wrapped declaration reports
## NO EXPORT — a declared axis the gate cannot verify, which is the whole failure class.)
@export_enum("solid", "glass", "light", "flesh", "fabric", "granular") var substance: String = "solid":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SUBSTANCES.has(picked):
			return                      ## an unreachable value keeps the standing body
		substance = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH QUESTION IS BEING ASKED. The two rigs are the two questions separated; `body` is
## them together, which is the state the family ships in.
##
##   body     the substance's own optics on the substance's own stance. Confounded on
##            purpose — a reader cannot tell, from this frame alone, whether two tiles
##            differ because of what light did or because of what force did.
##   through  the transmission rig. STANCE IS PINNED to the reference bar and the surface
##            is pinned to one reference hue, roughness and metallic; what survives is
##            alpha, subsurface scatter and unshaded. The striped screen behind the bar
##            makes transmission a fact rather than an impression: you are reading the
##            stripes, not the bar.
##   bear     the load rig. OPTICS ARE PINNED to one neutral matte and a load plate rests
##            on the bar's own top surface, at a height read off the built geometry
##            rather than typed in. What survives is the silhouette and where the plate
##            came to rest.
@export_enum("body", "through", "bear") var reading: String = "body":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not READINGS.has(picked):
			return
		reading = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One substance, or all six in a row. NOT PART OF EITHER AXIS, and that is wave 13's
## lesson paid forward: capture_config_sweep unions the AABB across a spec's variants, so
## an all-substances value declared inside `substance` would frame every single cell
## against seven and a half metres and photograph the bar as a smear. The registry
## fixture pins `single`. `ladder` is a design view, not a map placement.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const SUBSTANCES: PackedStringArray = [
	"solid", "glass", "light", "flesh", "fabric", "granular"]
const READINGS: PackedStringArray = ["body", "through", "bear"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the stage, and every millimetre of it is identical in all eighteen cells ────────────
## THE SCREEN IS AN L, not a wall, and that is a measurement decision. A single flat
## backdrop has to be placed where the camera happens to stand, because at the sweep's
## standpoint (yaw 0.62) everything "behind" the bar is displaced 0.71 m in -X for every
## metre of -Z; a plane at z = -0.34 alone would have to be 1.5 m wide to catch the bar's
## far corner, and it would stop being behind the bar the moment anyone looked from
## somewhere else. Two panels meeting at the back-left corner catch the bar's whole
## silhouette from any standpoint in the +X +Z quadrant, so the `through` reading survives
## the anamorphic test that five of seven dead verdicts in this corpus failed.
const PLATE_HALF_X: float = 0.50
const PLATE_HALF_Z: float = 0.40
const PLATE_T: float = 0.024
## The two piers, and the 0.30 m of nothing between them. This is the ONLY reason a stance
## is visible at all: a bar resting on a continuous floor holds its shape whatever it is
## made of, because the floor is holding it.
const PIER_INNER: float = 0.15
const PIER_OUTER: float = 0.36
const PIER_HALF_Z: float = 0.18
const PIER_TOP: float = 0.26
## The screen. Vertical stripes, high contrast, so that "how much got through" is a
## quantity a greyscale critic can read rather than a mood.
const SCREEN_T: float = 0.022
const SCREEN_TOP: float = 0.52
const SCREEN_A_Z: float = -0.34
const SCREEN_A_X0: float = -0.50
const SCREEN_A_X1: float = 0.28
const SCREEN_B_X: float = -0.44
const SCREEN_B_Z0: float = -0.318
const SCREEN_B_Z1: float = 0.26
const STRIPE_W: float = 0.065
## The load. One box, the same box in every cell of `bear`; only its height is a fact
## about the substance, and that height is MEASURED off the built lattice.
##
## IT IS A STRAIGHTEDGE, 0.09 m ACROSS, AND THE WIDTH IS THE WHOLE INSTRUMENT. The first
## build made it 0.30 m — exactly the width of the gap — and the replica caught what that
## costs: a plate as wide as the span rests on the SHOULDERS of a sag instead of sinking
## into it, so fabric's load came to rest at 0.462 against solid's 0.500 while the cloth
## below it hung 0.145 m down. The gauge disagreed with the body it was gauging. Narrow
## enough to fall into the dip, long enough in z to read as a bar laid across the beam.
const LOAD_HALF_X: float = 0.045
const LOAD_HALF_Z: float = 0.17
const LOAD_T: float = 0.045

# ── the body ───────────────────────────────────────────────────────────────────────────
## 0.72 x 0.24 x 0.34 m, a 0.833 m diagonal. One form, six substances — the whole point is
## that nothing about the form is a variable.
const BODY_HALF_L: float = 0.36
const BODY_Y0: float = 0.26
const BODY_H: float = 0.24
const BODY_HALF_D: float = 0.17
const NX: int = 16
const NY: int = 3
const NZ: int = 6

# ── Q2: the stance, and every number here is CAPPED so the extents stay comparable ─────
## MEASURED ON THE BUILT LATTICE by a Python replica of this file, x by y by z in metres,
## with the height the load came to rest at in the `bear` reading:
##   solid     0.720 x 0.240 x 0.340   load rests 0.5000   (the reference, untouched)
##   glass     0.720 x 0.240 x 0.340   load rests 0.5000   (identical to solid, on purpose)
##   light     0.720 x 0.240 x 0.340   load rests 0.0240   (the body is the reference; the
##                                                          load is on the floor)
##   flesh     0.720 x 0.257 x 0.418   load rests 0.4479
##   fabric    0.720 x 0.385 x 0.340   load rests 0.3655
##   granular  0.878 x 0.249 x 0.442   load rests 0.2728
## Widest is granular at 0.878 m, 1.22x the reference — under the 1.2 m ceiling and inside
## the plate, so the union AABB is the STAGE (1.00 x 0.545 x 0.80) in every one of the
## eighteen cells and the camera never moves. An uncapped heap spread past the plate and
## took the framing with it.
const FLESH_SPAN: float = 0.24
const FLESH_DIP: float = 0.055
const FLESH_BULGE: float = 0.045
const FAB_SPAN: float = 0.15
const FAB_SAG: float = 0.145
const GRAN_SPAN: float = 0.40
const GRAN_SQUASH: float = 0.62
const GRAN_CROWN: float = 0.10
const GRAN_SPREAD_X: float = 0.22
const GRAN_SPREAD_Z: float = 0.30

# ── Q1: the optics, every number lifted from a member ──────────────────────────────────
## THE ALPHAS ARE PER FACE AND THE BODY HAS TWO, which is arithmetic worth writing down
## before someone reads it as a bug. Every material here is CULL_DISABLED — wave 13's
## lesson, and a transparent hull needs it or the far wall vanishes — so a viewing ray
## crosses the front face AND the back face. Effective opacity is 1 - (1 - a)^2: glass at
## 0.32 per face is 0.538 through the body, so 46 percent of the stripe pattern survives;
## light at 0.70 per face is 0.910, so 9 percent survives. The word that means pure light
## is the one that photographs nearly solid, and the reason is in the source, not here.
const GLASS_ALPHA: float = 0.32          ## breathing_room_scene.gd:181
const GLASS_ROUGH: float = 0.05          ## breathing_room_scene.gd:184
const GLASS_METAL: float = 0.15          ## breathing_room_scene.gd:185
const LIGHT_ALPHA: float = 0.70          ## rainbow.gd:150, band_color.a *= 1.0 * 0.7
const FLESH_SSS: float = 0.8             ## breathing_room_scene.gd:178
const SOLID_ROUGH: float = 0.60          ## rainbow.gd:214
const FABRIC_ROUGH: float = 1.00         ## breathing_room_scene.gd:188
const GRAN_ROUGH: float = 0.70           ## SculptOne.gd:335
const GRAN_METAL: float = 0.20           ## SculptOne.gd:334
## The two rigs' pinned surfaces. Neither is a member's number, and neither pretends to
## be: they are the CONSTANTS the rigs hold still so that one question can be asked.
const THROUGH_ROUGH: float = 0.55
const BEAR_ROUGH: float = 0.85

# ── colour ─────────────────────────────────────────────────────────────────────────────
## NO PAIR IN THIS SHEET IS SEPARATED BY HUE ALONE, and that is checked rather than hoped:
## every pair in `body` also differs in transmission, in specular or in silhouette; in
## `through` and in `bear` the hue is pinned to C_REF for all six, so a colour-only
## difference is not constructible there. The critic measures luminance by default and
## flesh (0.564), fabric (0.601) and granular (0.645) sit within 0.081 of each other on
## Rec.709 — if hue were doing the work, three of six tiles would be greyscale twins.
const C_REF: Color = Color(0.72, 0.71, 0.68)
const C_GLASS: Color = Color(0.55, 0.72, 0.78)     ## breathing_room_scene.gd:181
const C_FLESH: Color = Color(0.80, 0.50, 0.50)     ## breathing_room_scene.gd:176
const C_FABRIC: Color = Color(0.62, 0.60, 0.55)    ## breathing_room_scene.gd:187
const C_GRAN: Color = Color(0.95, 0.60, 0.20)      ## SculptOne.gd:251, granular_orange
const C_PLATE: Color = Color(0.19, 0.20, 0.23)
const C_PIER: Color = Color(0.34, 0.35, 0.38)
const C_STRIPE_HI: Color = Color(0.90, 0.90, 0.92)
const C_STRIPE_LO: Color = Color(0.10, 0.10, 0.13)
const C_LOAD: Color = Color(0.26, 0.60, 0.72)

const LADDER_PITCH: float = 1.30
## Iterated rather than written inline, so no loop variable is untyped.
const SIGNS: PackedFloat32Array = [-1.0, 1.0]

var _built: Array[Node3D] = []
## Set while a whole config dictionary lands, so three keys cost one rebuild, not three.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("substance"):
		substance = str(config_data["substance"])
	if config_data.has("reading"):
		reading = str(config_data["reading"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = SUBSTANCES.duplicate()
	else:
		names.append(_pick(substance, SUBSTANCES, "solid"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Cell_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_stage(holder)
		_build_body(holder, names[i])


# ── Q2, the stance ─────────────────────────────────────────────────────────────────────

## A capped bump over the unsupported span: 1 at the centre, 0 at |x| >= span, and the
## exponent shapes the profile. p = 0.8 is flat-bottomed like a hanging chain, p = 1.5 is
## a soft dish, p = 0.7 is the shoulder of a heap.
func _bump(x: float, span: float, p: float) -> float:
	var t: float = x / span
	var base: float = maxf(0.0, 1.0 - t * t)
	if base <= 0.0:
		return 0.0
	return pow(base, p)


## WHERE ONE LATTICE POINT ENDS UP. This is the answer to Q2 and it is the half of the
## family's vocabulary that no member implements — so it is DERIVED FROM THE WORD, not
## from a member's code, and that weaker warrant is recorded in the registry rather than
## dressed up. What is derived from the code is that the code answers nothing here.
##
##   solid    holds. No displacement at all.
##   glass    holds. No displacement at all — IDENTICAL to solid, which is the point.
##   light    holds nothing, which is not the same as holding. Its lattice is the
##            reference, because light does not deform; what it cannot do is CARRY, and
##            `bear` reports that by letting the load fall through it to the floor.
##   flesh    yields. The middle sinks 0.055 m at the top and 0.017 m at the bottom, and
##            the flanks bulge 0.045 m outward in z, most at mid-height — a compression
##            that puts the volume somewhere rather than deleting it.
##   fabric   drapes. No bending stiffness, so the unsupported 0.30 m hangs as a chain,
##            0.145 m at the centre, moving the whole thickness together: cloth does not
##            get thinner where it sags. Zero at the pier edge by construction.
##   granular no tensile strength: the heap falls to the plate, keeps 0.62 of its height,
##            spreads 1.22x in x and 1.30x in z at its base and not at all at its crest,
##            and banks against the piers it can no longer stand on. Volume out by 2%.
func _stance(sub: String, x0: float, y0: float, z0: float) -> Vector3:
	var v: float = (y0 - BODY_Y0) / BODY_H
	if sub == "flesh":
		var g: float = _bump(x0, FLESH_SPAN, 1.5)
		var dy: float = -FLESH_DIP * g * (0.30 + 0.70 * v)
		var lat: float = 1.0 - absf(2.0 * v - 1.0) * 0.4
		var dz: float = FLESH_BULGE * g * lat * (z0 / BODY_HALF_D)
		return Vector3(x0, y0 + dy, z0 + dz)
	if sub == "fabric":
		var gf: float = _bump(x0, FAB_SPAN, 0.8)
		return Vector3(x0, y0 - FAB_SAG * gf, z0)
	if sub == "granular":
		var sx: float = 1.0 + GRAN_SPREAD_X * (1.0 - v)
		var sz: float = 1.0 + GRAN_SPREAD_Z * (1.0 - v)
		var crown: float = GRAN_CROWN * _bump(x0, GRAN_SPAN, 0.7) * v
		var y1: float = PLATE_T + (y0 - BODY_Y0) * GRAN_SQUASH + crown
		return Vector3(x0 * sx, y1, z0 * sz)
	return Vector3(x0, y0, z0)


## cube[i][j] is a PackedVector3Array over k. i runs the length, j the height, k the depth.
func _lattice(sub: String) -> Array:
	var cube: Array = []
	for i in range(NX + 1):
		var x0: float = -BODY_HALF_L + 2.0 * BODY_HALF_L * float(i) / float(NX)
		var plane_row: Array = []
		for j in range(NY + 1):
			var y0: float = BODY_Y0 + BODY_H * float(j) / float(NY)
			var col: PackedVector3Array = PackedVector3Array()
			for k in range(NZ + 1):
				var z0: float = -BODY_HALF_D + 2.0 * BODY_HALF_D * float(k) / float(NZ)
				col.append(_stance(sub, x0, y0, z0))
			plane_row.append(col)
		cube.append(plane_row)
	return cube


## WHERE THE LOAD COMES TO REST — read off the built geometry, never typed in. A hand-typed
## table is the science_screen fault waiting to happen: change a stance constant and the
## plate would float, and every frame would still look finished. `light` is the one
## override, and it is the claim: there is nothing here to carry anything, so the plate
## goes to the floor and the bar is where it always was.
func _carry_y(sub: String, cube: Array) -> float:
	if sub == "light":
		return PLATE_T
	var best: float = PLATE_T
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			for k in range(col.size()):
				var p: Vector3 = col[k]
				if absf(p.x) <= LOAD_HALF_X and p.y > best:
					best = p.y
	return best


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stage(holder: Node3D) -> void:
	var plate := SurfaceTool.new()
	plate.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(plate, Vector3(0.0, PLATE_T * 0.5, 0.0),
		Vector3(PLATE_HALF_X * 2.0, PLATE_T, PLATE_HALF_Z * 2.0))
	_commit(holder, "Plate", plate, C_PLATE, 1.0, 0.0, false)

	var piers := SurfaceTool.new()
	piers.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pier_w: float = PIER_OUTER - PIER_INNER
	var pier_h: float = PIER_TOP - PLATE_T
	for sx in SIGNS:
		_add_box(piers, Vector3(sx * (PIER_INNER + pier_w * 0.5),
			PLATE_T + pier_h * 0.5, 0.0),
			Vector3(pier_w, pier_h, PIER_HALF_Z * 2.0))
	_commit(holder, "Piers", piers, C_PIER, 0.75, 0.0, false)

	var hi := SurfaceTool.new()
	hi.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo := SurfaceTool.new()
	lo.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_screen(hi, lo, true)
	_add_screen(hi, lo, false)
	_commit(holder, "ScreenLight", hi, C_STRIPE_HI, 0.80, 0.0, false)
	_commit(holder, "ScreenDark", lo, C_STRIPE_LO, 0.80, 0.0, false)


## One leg of the L. `along_x` true builds the panel at z = SCREEN_A_Z running in x; false
## builds the panel at x = SCREEN_B_X running in z. Stripe count is derived from the
## panel's own length so both legs carry the same pitch to within a millimetre.
func _add_screen(hi: SurfaceTool, lo: SurfaceTool, along_x: bool) -> void:
	var a: float = SCREEN_A_X0 if along_x else SCREEN_B_Z0
	var b: float = SCREEN_A_X1 if along_x else SCREEN_B_Z1
	var span: float = b - a
	var count: int = maxi(3, int(round(span / STRIPE_W)))
	var w: float = span / float(count)
	var h: float = SCREEN_TOP - PLATE_T
	for s in range(count):
		var mid: float = a + w * (float(s) + 0.5)
		var st: SurfaceTool = hi if (s % 2) == 0 else lo
		if along_x:
			_add_box(st, Vector3(mid, PLATE_T + h * 0.5, SCREEN_A_Z),
				Vector3(w, h, SCREEN_T))
		else:
			_add_box(st, Vector3(SCREEN_B_X, PLATE_T + h * 0.5, mid),
				Vector3(SCREEN_T, h, w))


func _build_body(holder: Node3D, sub: String) -> void:
	# THE ONE PLACE THE TWO RIGS BITE. `through` is asking about light, so it pins the
	# stance to the reference bar; every other reading lets the substance answer Q2.
	var stance_key: String = sub
	if reading == "through":
		stance_key = "solid"
	var cube: Array = _lattice(stance_key)

	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_shell(body, cube)
	_commit_material(holder, "Body", body, _mat_for(sub))

	if reading != "bear":
		return
	var load_st := SurfaceTool.new()
	load_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rest: float = _carry_y(sub, cube)
	_add_box(load_st, Vector3(0.0, rest + LOAD_T * 0.5, 0.0),
		Vector3(LOAD_HALF_X * 2.0, LOAD_T, LOAD_HALF_Z * 2.0))
	_commit(holder, "Load", load_st, C_LOAD, 0.45, 0.05, false)


## The six boundary faces of the (i, j, k) lattice.
func _add_shell(st: SurfaceTool, cube: Array) -> void:
	var ni: int = cube.size()
	var plane_row: Array = cube[0]
	var nj: int = plane_row.size()
	var col: PackedVector3Array = plane_row[0]
	var nk: int = col.size()
	var centre: Vector3 = _centroid(cube)
	_add_face(st, _slice_k(cube, 0), centre)
	_add_face(st, _slice_k(cube, nk - 1), centre)
	_add_face(st, _slice_j(cube, 0), centre)
	_add_face(st, _slice_j(cube, nj - 1), centre)
	_add_face(st, _slice_i(cube, 0), centre)
	_add_face(st, _slice_i(cube, ni - 1), centre)


func _centroid(cube: Array) -> Vector3:
	var acc: Vector3 = Vector3.ZERO
	var n: int = 0
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			for k in range(col.size()):
				acc += col[k]
				n += 1
	if n == 0:
		return Vector3.ZERO
	return acc / float(n)


## A boundary face, wound so its normal points AWAY from the body's centroid. Winding is
## checked per quad rather than assumed per face, because three of the six faces of a
## slumped heap are no longer planar and a face-level assumption puts the normal through
## the object on the quads that curl. Every material is CULL_DISABLED besides.
func _add_face(st: SurfaceTool, grid: Array, centre: Vector3) -> void:
	var ni: int = grid.size()
	if ni < 2:
		return
	var probe: PackedVector3Array = grid[0]
	var nj: int = probe.size()
	if nj < 2:
		return
	for i in range(ni - 1):
		var r0: PackedVector3Array = grid[i]
		var r1: PackedVector3Array = grid[i + 1]
		for j in range(nj - 1):
			_quad(st, r0[j], r1[j], r1[j + 1], r0[j + 1], centre)


func _slice_k(cube: Array, k: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		var row: PackedVector3Array = PackedVector3Array()
		for j in range(plane_row.size()):
			var col: PackedVector3Array = plane_row[j]
			row.append(col[k])
		out.append(row)
	return out


func _slice_j(cube: Array, j: int) -> Array:
	var out: Array = []
	for i in range(cube.size()):
		var plane_row: Array = cube[i]
		out.append(plane_row[j])
	return out


func _slice_i(cube: Array, i: int) -> Array:
	var out: Array = []
	var plane_row: Array = cube[i]
	for j in range(plane_row.size()):
		out.append(plane_row[j])
	return out


# ── mesh primitives ────────────────────────────────────────────────────────────────────

## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], at)
	_quad(st, p[5], p[4], p[7], p[6], at)
	_quad(st, p[3], p[2], p[6], p[7], at)
	_quad(st, p[4], p[5], p[1], p[0], at)
	_quad(st, p[1], p[5], p[6], p[2], at)
	_quad(st, p[4], p[0], p[3], p[7], at)


## Two triangles a -> b -> c -> d, with the normal taken from the winding and FLIPPED if
## it points back at `inside`. A transparent body is where this stops being cosmetic: with
## CULL_DISABLED both faces of the bar are drawn and both are lit, so an inward normal on
## the far wall photographs as a dark band that reads exactly like a missing pane.
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		inside: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a)
	if n.length() < 0.0000001:
		return
	n = n.normalized()
	var mid: Vector3 = (a + b + c + d) * 0.25
	if n.dot(mid - inside) < 0.0:
		n = -n
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for vtx in tri:
		st.set_normal(n)
		st.add_vertex(vtx)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		rough: float, metal: float, unshaded: bool) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_commit_material(holder, mesh_name, st, m)


## SurfaceTool.commit() on a tool that was begun and never given a vertex is not a mesh
## with no surfaces, it is an error in the log.
func _commit_material(holder: Node3D, mesh_name: String, st: SurfaceTool,
		mat: StandardMaterial3D) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = mat
	holder.add_child(mi)


# ── Q1, the optics ─────────────────────────────────────────────────────────────────────

## WHAT LIGHT DOES WHEN IT ARRIVES. Under `body` every branch is a member's material,
## number for number. Under the two rigs the surface is pinned and only the half of it
## belonging to that rig's question survives.
func _mat_for(sub: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.0
	m.albedo_color = C_REF

	if reading == "bear":
		# EVERY OPTICAL CLAIM PINNED. One matte for all six, so `bear` cannot see Q1 at
		# all — which is what makes solid and glass one picture here.
		m.roughness = BEAR_ROUGH
		return m

	if reading == "through":
		# HUE, ROUGHNESS AND METALLIC PINNED — the three that are about the SURFACE. What
		# survives is alpha, subsurface scatter and unshaded: the only three ways any
		# member's code lets light past a surface. Which is why the three opaque words
		# are one picture here.
		m.roughness = THROUGH_ROUGH
		match sub:
			"glass":
				var ga: Color = C_REF
				ga.a = GLASS_ALPHA
				m.albedo_color = ga
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"light":
				var la: Color = C_REF
				la.a = LIGHT_ALPHA
				m.albedo_color = la
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			"flesh":
				m.subsurf_scatter_enabled = true
				m.subsurf_scatter_strength = FLESH_SSS
				m.subsurf_scatter_skin_mode = true
		return m

	# reading == "body" — the member's own material.
	match sub:
		"glass":
			var gb: Color = C_GLASS
			gb.a = GLASS_ALPHA
			m.albedo_color = gb
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.roughness = GLASS_ROUGH
			m.metallic = GLASS_METAL
		"light":
			var lb: Color = C_REF
			lb.a = LIGHT_ALPHA
			m.albedo_color = lb
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.roughness = SOLID_ROUGH
		"flesh":
			m.albedo_color = C_FLESH
			m.roughness = FABRIC_ROUGH
			m.subsurf_scatter_enabled = true
			m.subsurf_scatter_strength = FLESH_SSS
			m.subsurf_scatter_skin_mode = true
		"fabric":
			m.albedo_color = C_FABRIC
			m.roughness = FABRIC_ROUGH
		"granular":
			m.albedo_color = C_GRAN
			m.roughness = GRAN_ROUGH
			m.metallic = GRAN_METAL
		_:
			m.roughness = SOLID_ROUGH
	return m
