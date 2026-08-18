# @identity
# essence: a 3D placard that pulls tutorial text from a library by ID — the in-world reader for code / explanation content
# desire: bring authored text into the scene without breaking immersion — readable, formatted, addressable by name
# critical_parameter: current_tutorial_id — picks which entry from tutorial_text.json is shown
# triggers: _ready() instantiates TutorialTextLibrary and waits a frame to locate the RichTextLabel inside the Viewport2Din3D
# emerges: a readable in-VR text panel that the map-author addresses by tt:<name> tokens
# needs: TutorialTextLibrary [present]; Viewport2Din3D child [scene-required]; rich text label resolution [present, deferred]; commons/render/pbr_kit.gd for every apparatus surface [present — the placard's own face is an unshaded viewport and stays one, but the thing HOLDING it is now cast, anodised and machined rather than one grey]
# relationships: clipboard/context companion to science_screen (in-world readout) and reader_table (extended reading); the placement-by-token side of the tutorial-content pipeline
# truth: A tutorial is a placement-of-words. The library holds the words, the placard holds the placement — separating them lets the same text appear in many maps.

extends Node3D

# Tutorial Text Display component
# Supports tt:name format to display tutorial text from tutorial_text.json

const PBR := preload("res://commons/render/pbr_kit.gd")

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `support`
# ═══════════════════════════════════════════════════════════════════
#
# The identity line above says it plainly: *a tutorial is a placement-of-words.*
# The library holds the words; this placard holds the PLACEMENT. Until now only
# half of that was ever built. The whole script below is about WHICH text
# (current_tutorial_id) and not one line of it was about how the text stands —
# so across 30 placements, in every sequence, authored language hung in mid-air
# with no relationship to the room it was speaking in.
#
# `support` is the project's one word for "what apparatus holds this thing up".
# Same ladder, same meaning, same spelling as on exit_sign and science_screen:
# two panels, one question, one vocabulary. What varies is MASS and PRESENCE —
# nothing here is time-domain, and every value is legible in a single still.
#
#   none   the bare panel. No apparatus. What all 30 shipped placements are.
#   stand  a slender post to a disc foot — demountable, provisional furniture;
#          the room shows through beside it.
#   frame  a bezel and a back panel — the screen reads as a hung SIGN rather
#          than as floating light.
#   pylon  a pier of building, floor to over-head, with the panel sunk into a
#          reveal cut in its face — the building itself is speaking.
#
# The four make genuinely different claims about who is talking. That is the
# axis: not decoration, but the authority the words are delivered with.
const SUPPORTS: PackedStringArray = ["none", "stand", "frame", "pylon"]

# ═══════════════════════════════════════════════════════════════════
# THE FINISH PASS — why the apparatus is three substances, not one grey
# ═══════════════════════════════════════════════════════════════════
#
# The axis shipped built, and the sweep measured `support=pylon` FLAT: tonal
# spread 0.032 against a 0.055 threshold, sixteen distinct colours against forty.
#
# TWO faults, and they are not the same size. Read the published frame before
# believing either.
#
# The first is a material fault and it is real. Every one of the eleven boxes
# below was HangarKit.painted_metal() — one albedo, one roughness, one metallic,
# and the metallic sat at 0.34, which is neither a metal nor a dielectric but
# the value a renderer uses when nobody decided. A pier, a bezel and a
# demountable post were all made of the same nothing.
#
# The second is why the number was 0.032 and not 0.09. The pylon's reveal rim
# was built as a SOLID box across the whole opening, so the panel — a page of
# lit text, the brightest and most varied thing this artifact has — was behind
# a plate. `none`, `stand` and `frame` all peak at luminance 247; the pylon
# peaked at 140 and showed no text at all. The frame was a photograph of a lid.
#
# Fixing materials alone would have moved 0.032 to maybe 0.05 and left the value
# flagged, and the next round would have gone looking for a better concrete. The
# order matters: find out WHAT IS IN THE FRAME first, then argue about how it is
# surfaced. Both are fixed below, the occlusion at the reveal liner.
#
# The argument the axis makes is about AUTHORITY, and authority is carried by
# SUBSTANCE before it is carried by size. So each value now gets the material
# its claim needs, from commons/render/pbr_kit.gd:
#
#   stand  black-anodised extrusion on a SAND-CAST foot. Two different metals,
#          visibly made in two different ways — the reason a demountable stand
#          does not fall over is a lump of iron, and you can see that it is one.
#   frame  anodised bezel with a clear coat, matte powder-coated back. A hung
#          sign is a manufactured object: it has a bright made edge and a dull
#          unseen behind, and those are not the same finish.
#   pylon  CAST, not painted. The docstring already called it "a pier of
#          building"; it was rendered as sheet metal. Concrete at metallic 0
#          with cellular pitting is what the sentence was always describing.
#
# The albedos come UP as the metallic comes DOWN, and the two cancel. A charcoal
# at albedo 0.17 and metallic 0.34 loses a third of its energy to a specular lobe
# with nothing in the room to reflect, so it renders far darker than 0.17 and
# renders it FLAT. The same part at albedo 0.26, metallic 0.0 and a roughness map
# lands at roughly the same screen value with shading inside it. Nothing here got
# lighter; it got lit.
#
# `none` IS UNTOUCHED — zero nodes, exactly as shipped, because 29 placements are
# standing in that value right now and a finish pass is not permission to move
# them.
#
# ── GRAIN SCALE (the one that costs a pass if you guess) ───────────
#
# Sizes, off the constants below rather than off a feeling:
#   pylon  1.30 w x 2.65 h x 0.30 d   (AABB diagonal 2.97 m)
#   stand  0.42 w x 2.34 h x 0.42 d   (with the panel; diagonal 2.41 m)
#   frame  1.12 w x 1.32 h x 0.05 d   (diagonal 1.73 m)
#
# And the scale on screen MEASURED off the published 760 px frames, not
# estimated from the frame size. This matters: the estimate here was 220 px/m
# for the pylon, from PAD alone. The pylon's own bounding box in its own render
# is 379 px tall for 2.65 m, so the truth is 143 px/m — a third smaller, which
# is the difference between a feature that is legible and one that shimmers.
#
#   pylon  143 px/m     stand  158 px/m     frame  254 px/m
#
# (They differ because the sweep frames each variant to its own AABB, so the
# smaller the apparatus the closer the camera. A grain that is right on the
# pier is not automatically right on the foot.)
#
# Every grain below is checked against THOSE numbers, aiming for a feature
# several pixels across:
#
#   concrete   1.4 tiles/m -> 0.71 m period; a GRAIN_CAST cell is ~8% of a
#              period = 58 mm = 8.3 px on the pier, and the field repeats 3.7
#              times over 2.65 m — enough to read as a surface, not so much
#              that it reads as a tile. The kit picked 1.4 for "a whole plinth
#              or floor slab", and a 2.65 m pier IS that object. LEFT ALONE.
#   cast_metal 4 tiles/m -> cell 20 mm = 3.2 px on the 0.42 m foot. Too fine.
#              SCALED to 0.6 -> 34 mm = 5.3 px. Note the direction: the rule of
#              thumb (factor ~ 1 / longest dimension) would have said 2.4 and
#              made it worse, because the rule assumes the default is too
#              coarse for a small part and here it was already too fine.
#   brushed    25 mm streak period. On the bezel at 254 px/m that is 6.4 px
#              across a 15 px member — LEFT ALONE, it is a brushed extrusion.
#              On the 0.05 m post at 158 px/m the member is only 7.9 px wide
#              and 4 px of streak inside it is a two-cycle ripple, so the post
#              alone is SCALED to 0.55 -> 7 px, one gradient across the section.
#              The naive 1/longest_dimension rule would read the bezel's 0.06 m
#              section and multiply by 16.7, putting the streak at 0.4 px:
#              not detail, static.
#   grunge     on the reveal liner, 0.42 m period, blotch ~150 mm = 21 px along
#              a 1.24 m strip that is only 3 px WIDE. Nothing varies across the
#              strip and that is correct — a hairline should be a clean dark
#              line, and anything tiled fine enough to vary across 3 px would
#              sparkle. The variation it does get runs along its length.
#
# Normals are NOT flattened. The kit's strengths stand as authored; three of the
# four scale decisions above are "leave it", and the two that move, move the
# TILING, never the strength.

## Default is `none` — the exact pre-promotion look, zero nodes added. Promotion
## is not permission to move 30 shipped placements.
@export_enum("none", "stand", "frame", "pylon") var support: String = "none"

# ── Panel geometry, read off codeDisplay.tscn ────────────────────────
# Viewport2Din3D: screen_size 1.0 x 1.2, sitting a few mm off local origin.
# Everything the axis builds is dimensioned from these so the apparatus stays
# registered to the face if the scene is ever re-seated.
const PANEL_W: float = 1.0
const PANEL_H: float = 1.2
const PANEL_CY: float = 0.0045     ## Viewport2Din3D's own y offset in the scene
const PANEL_CZ: float = -0.0013    ## ...and its z offset; the face looks down +Z

# ── stand ──
const STAND_POST: float = 0.05     ## square post section
const STAND_DROP: float = 1.10     ## panel bottom edge → floor
const STAND_BASE_R: float = 0.21   ## 0.42 m diameter disc
const STAND_BASE_T: float = 0.04

# ── frame ──
const BEZEL_W: float = 0.06        ## outer becomes 1.12 x 1.32
const BEZEL_D: float = 0.03
const BACK_T: float = 0.02

# ── pylon ──
const PIER_DEPTH: float = 0.30
const PIER_DROP: float = 1.10      ## panel bottom edge → floor
const PIER_RISE: float = 0.35      ## panel top edge → head of the pier
const PIER_REVEAL: float = 0.03    ## how far the panel is sunk behind the face
const PIER_JAMB: float = 0.15      ## face left standing either side of the opening
## The mass's front face sits THIS far behind the panel plane. It was 0.0, which
## put a 1.30 x 2.65 m concrete plane in exactly the same place as the
## Viewport2Din3D quad and left the two z-fighting for every pixel of the text.
const PIER_BACKSET: float = 0.008

@onready var viewport_2d: Node = $Viewport2Din3D
var tutorial_library: TutorialTextLibrary
var current_tutorial_id: String = ""
var rich_text_label: RichTextLabel

## Nodes THIS script created. The teardown walks this list and nothing else —
## the grid adds label plates, packaging and tag markers as siblings, and a
## get_children() sweep would take them with it.
var _support_nodes: Array[Node3D] = []
var _built: bool = false

func _ready() -> void:
	# Initialize tutorial library
	tutorial_library = TutorialTextLibrary.new()

	# Support geometry is built SYNCHRONOUSLY: children exist by the time the
	# first await below yields, which is what apply_grid_config (call_deferred,
	# ahead of grounding and label framing) and curation_station both count on.
	_build_all()
	_built = true

	# Wait a frame for Viewport2Din3D to set up its scene
	await get_tree().process_frame

	# Find the RichTextLabel in the Viewport2Din3D's scene
	_find_rich_text_label()


# ═══════════════════════════════════════════════════════════════════
# SUPPORT BUILD
# ═══════════════════════════════════════════════════════════════════

func _panel_bottom() -> float:
	return PANEL_CY - PANEL_H * 0.5

func _panel_top() -> float:
	return PANEL_CY + PANEL_H * 0.5

## Track and parent in one step so nothing this script makes can escape teardown.
func _add_support_node(n: Node3D) -> void:
	add_child(n)
	_support_nodes.append(n)

func _build_all() -> void:
	match support:
		"stand":
			_build_support_stand()
		"frame":
			_build_support_frame()
		"pylon":
			_build_support_pylon()
		_:
			pass  # "none" — the bare panel and its HandPoseArea. Zero nodes.


## A 0.05 m post from the centre of the panel's bottom edge down to a 0.42 m
## disc. Hardware you could carry in one hand: the words are visiting the room
## for the duration of a lesson, and the room shows through on both sides.
##
## Two metals, because a stand is two problems. The post is a black-anodised
## extrusion — light, straight, sold by the metre, brushed along its length
## before the oxide went on. The foot is SAND-CAST iron, and the whole reason
## the thing stays upright is that it is heavy: pitted, matte, made in a mould
## rather than pulled through a die. Rendering both as the same grey threw away
## the only argument the stand has.
func _build_support_stand() -> void:
	# Brush runs UP the post, which is how an upright extrusion is finished and
	# how the eye reads "this is a pole, not a bar". That wants _anodised_bar's
	# "x", not PbrKit.anodized()'s hard-coded "y" — see the note on that helper;
	# uv1_scale is a tiling RATE, so the axis carrying 40 is the one the streaks
	# run ACROSS, not along.
	#
	# Then scaled to the post's own size. At 158 px/m the 50 mm section is under
	# 8 px wide, and the kit's 40 tiles/m puts a streak every 25 mm = 4 px: two
	# ripples across an 8 px bar, which is the definition of static. 0.55 takes
	# the streak period to 45 mm = 7 px, about one soft gradient across the
	# section, which is what a brushed upright actually does at arm's length.
	var post_mat: StandardMaterial3D = PBR.scale_detail(
		_anodised_bar(Color(0.16, 0.16, 0.19), 0.32, 0.16, "x"), 0.55)
	var post_top: float = _panel_bottom()
	var post_bottom: float = post_top - STAND_DROP
	# Chamfered: a 3.5 mm break on the four arrises of a 50 mm post is the
	# highlight line that separates a post from a rectangle of colour.
	_add_support_node(PBR.box(
		Vector3(0.0, post_top - STAND_DROP * 0.5, PANEL_CZ),
		Vector3(STAND_POST, STAND_DROP, STAND_POST),
		post_mat, -1.0, 0.10))

	# cast_metal, not worn_metal: worn_metal is scuffed sheet, and this was never
	# sheet. Cellular pitting at roughness 0.65 gives a broad lobe that catches
	# whatever light a map has — a polished foot in an unlit room is just black.
	#
	# Tiling DOWN, not up. The rule of thumb (factor ~ 1 / longest dimension)
	# would read the 0.42 m disc and multiply by 2.4, which takes a pit from
	# 20 mm to 8 mm — 1.3 px at this artifact's measured 158 px/m, i.e. exactly
	# the one-pixel-feature failure the rule exists to prevent. The rule assumes
	# the default tiling is too COARSE for a small part; here the kit's 4 tiles/m
	# is already too fine for a 66 px disc. 0.6 puts a pit at 34 mm = 5 px, with
	# five or six of them across the top face.
	var base_mat: StandardMaterial3D = PBR.scale_detail(
		PBR.cast_metal(Color(0.235, 0.235, 0.255), 0.32), 0.6)
	var base: MeshInstance3D = PBR.chamfer_cylinder(
		STAND_BASE_R, STAND_BASE_T, -1.0, base_mat, 28, 0.14)
	base.position = Vector3(0.0, post_bottom - STAND_BASE_T * 0.5, PANEL_CZ)
	_add_support_node(base)

	# The stand is the one value that reads as HOVERING without help: a slender
	# post on a thin disc, and nothing else touching the ground. A Decal conforms
	# to whatever floor a map puts under it, costs nothing against the light
	# budget, and is not a MeshInstance3D — so every framing number ever measured
	# on this artifact survives it untouched.
	var contact: Decal = PBR.ground_shadow(0.30, 0.5, 0.06)
	contact.position += Vector3(0.0, post_bottom - STAND_BASE_T, PANEL_CZ)
	_add_support_node(contact)

	# The stand was the one built value with no spill, and it is the value that
	# most needs one: 1.10 m of dark anodised post is a single tone unless
	# something nearby grades it. Shorter reach than the frame's, deliberately —
	# it should die around the middle of the post and leave the cast foot in the
	# map's own light, so the two metals are lit differently as well as finished
	# differently.
	_panel_spill(0.45, 1.0)


## A 0.06 m bezel around all four edges (outer 1.12 x 1.32) and a back panel
## behind the viewport. Nothing touches the floor — but the text stops being
## light in the air and becomes a hung sign, a made object with an edge and a
## back, fixed to something.
##
## The bezel is an anodised aluminium extrusion and the back is powder-coated
## sheet, which is what a hung sign is actually made of — and they are finished
## differently on purpose. The bezel is the edge you are meant to see: metal
## under a coloured oxide film under a clear coat, so it holds a tight second
## highlight. The back is the side nobody looks at: matte, chalkier, no coat.
## A sign that is the same finish front and back is not a made object, it is a
## solid.
func _build_support_frame() -> void:
	# Two bezel materials, because the brush follows the member: streaks run along
	# a stile and along a rail, and those are perpendicular. Which kit axis gives
	# which is derived at _anodised_bar, not assumed — the naming inverts. The
	# vertical stiles need "x" and the horizontal head and sill need "y", which
	# is what PbrKit.anodized() hard-codes, so the rails can use the kit directly
	# and only the stiles need the helper. Cost is one extra material; both share
	# the cached textures.
	#
	# No scale_detail here. The bezel section is 0.06 m and the frame renders at
	# 254 px/m, so a member is 15 px wide and the kit's 25 mm streak period lands
	# at 6.4 px — two or three streaks across each member, running its full
	# length. That is a brushed extrusion. Fitting the grain to the 0.06 m
	# section instead would multiply by 16.7 and put the streak at 0.4 px.
	var stile_mat: StandardMaterial3D = _anodised_bar(Color(0.19, 0.20, 0.23), 0.30, 0.14, "x")
	var rail_mat: StandardMaterial3D = PBR.anodized(Color(0.19, 0.20, 0.23), 0.30, 0.14)
	var back_mat: StandardMaterial3D = PBR.painted_metal(Color(0.115, 0.115, 0.135), 0.24, 0.30, 0.72)

	var outer_w: float = PANEL_W + BEZEL_W * 2.0
	var outer_h: float = PANEL_H + BEZEL_W * 2.0
	var half_bez: float = BEZEL_W * 0.5

	# Head and sill run the full outer width; the stiles fill between them.
	_add_support_node(PBR.box(
		Vector3(0.0, _panel_top() + half_bez, PANEL_CZ),
		Vector3(outer_w, BEZEL_W, BEZEL_D), rail_mat, -1.0, 0.06))
	_add_support_node(PBR.box(
		Vector3(0.0, _panel_bottom() - half_bez, PANEL_CZ),
		Vector3(outer_w, BEZEL_W, BEZEL_D), rail_mat, -1.0, 0.06))
	for i in range(2):
		var s: float = -1.0 if i == 0 else 1.0
		_add_support_node(PBR.box(
			Vector3(s * (PANEL_W * 0.5 + half_bez), PANEL_CY, PANEL_CZ),
			Vector3(BEZEL_W, outer_h, BEZEL_D), stile_mat, -1.0, 0.06))

	_add_support_node(PBR.box(
		Vector3(0.0, PANEL_CY, PANEL_CZ - BACK_T),
		Vector3(outer_w, outer_h, BACK_T), back_mat, -1.0, 0.10))

	# A lit screen in a bezel throws light on its own bezel. Short range, so it
	# grades the inner return of the frame and dies before it reaches anything
	# the map is responsible for lighting.
	_panel_spill(0.55, 0.9)


## A pier of building: 0.30 m deep, running 1.1 m below the panel to the floor
## and 0.35 m above its head, with the panel sunk 0.03 m into a reveal cut in
## the front face. Contradicting a stand costs a screwdriver; contradicting this
## costs money. Same words, entirely different authority.
##
## And it is CAST. This is the value the render lint caught, and it had two
## faults, not one. The material fault: a pier of building was surfaced as
## painted sheet metal at metallic 0.34, so it is now concrete — metallic 0, a
## cellular pit field in the roughness and the normal, one material instance
## shared by the mass and all four skin returns so the face reads as one pour
## rather than five parts. The larger fault was GEOMETRY, and it is the one the
## first pass talked itself out of looking for: a solid box across the opening,
## which meant the frame the linter measured did not contain the text at all.
## See the reveal liner below.
func _build_support_pylon() -> void:
	# One instance, five meshes. Triplanar is LOCAL, so the pattern still restarts
	# per mesh — but sharing the material guarantees they at least share a SCALE,
	# and a mismatched scale across a single face is the loudest of the two tells.
	var pier_mat: StandardMaterial3D = PBR.concrete(Color(0.26, 0.26, 0.285), 0.26)
	# The liner is the one metal in the pylon: a dark gunmetal shadow gasket set
	# into the concrete around the opening. Metal here is deliberate — it is the
	# only thing in the recess with a specular lobe, so it is what the panel's own
	# spill light has to catch, and it draws the edge of the reveal in flat light.
	var reveal_mat: StandardMaterial3D = PBR.worn_metal(Color(0.13, 0.13, 0.15), 0.40)

	var pier_top: float = _panel_top() + PIER_RISE
	var pier_bottom: float = _panel_bottom() - PIER_DROP
	var pier_h: float = pier_top - pier_bottom
	var pier_cy: float = (pier_top + pier_bottom) * 0.5
	var pier_w: float = PANEL_W + PIER_JAMB * 2.0

	# Opening: the panel plus a hairline margin, so the face frames it rather
	# than clipping it.
	var open_w: float = PANEL_W + 0.04
	var open_h: float = PANEL_H + 0.04
	var open_top: float = PANEL_CY + open_h * 0.5
	var open_bottom: float = PANEL_CY - open_h * 0.5

	# Mass behind, its front face PIER_BACKSET behind the panel plane. It used to
	# land EXACTLY on that plane — "seated against building rather than floating
	# in a hole" — and the sentence was right about the intent and wrong about
	# the consequence: two coplanar surfaces, one of them 1.30 x 2.65 m of
	# concrete and the other the text, fighting for the depth buffer.
	var mass_d: float = PIER_DEPTH - PIER_REVEAL
	# 14 mm arris on the mass (the kit's cap), 2 mm on the 30 mm skin returns.
	# Cast concrete has no zero-radius edges — the formwork chamfers them — and
	# that break is where a 2.65 m grey slab gets its silhouette back.
	_add_support_node(PBR.box(
		Vector3(0.0, pier_cy, PANEL_CZ - PIER_BACKSET - mass_d * 0.5),
		Vector3(pier_w, pier_h, mass_d), pier_mat, -1.0, 0.12))

	# Front skin, PIER_REVEAL proud of the panel — the four returns that make
	# the recess read as a recess.
	var skin_cz: float = PANEL_CZ + PIER_REVEAL * 0.5
	for i in range(2):
		var s: float = -1.0 if i == 0 else 1.0
		_add_support_node(PBR.box(
			Vector3(s * (open_w + pier_w) * 0.25, pier_cy, skin_cz),
			Vector3((pier_w - open_w) * 0.5, pier_h, PIER_REVEAL), pier_mat, -1.0, 0.12))
	_add_support_node(PBR.box(
		Vector3(0.0, (pier_top + open_top) * 0.5, skin_cz),
		Vector3(open_w, pier_top - open_top, PIER_REVEAL), pier_mat, -1.0, 0.12))
	_add_support_node(PBR.box(
		Vector3(0.0, (open_bottom + pier_bottom) * 0.5, skin_cz),
		Vector3(open_w, open_bottom - pier_bottom, PIER_REVEAL), pier_mat, -1.0, 0.12))

	# THE REVEAL LINER — four strips lining the hole, and this is the line the
	# render lint was actually measuring.
	#
	# It used to be ONE box, 1.052 x 1.252 x 0.008, centred 4 mm in front of the
	# panel. Its comment called it "a shadow rim on the reveal's inner return",
	# and every word of that intent is right — but PbrKit.box() builds a SOLID
	# box, so what shipped was a dark gunmetal LID over the whole opening. The
	# published frame proves it: peak luminance 140 where the other three values
	# reach 247, sixteen distinct colours, sd 0.032. The pylon did not measure
	# FLAT because concrete was surfaced as painted sheet. It measured FLAT
	# because the brightest, most detailed thing in the picture — a page of text —
	# was behind a plate, and what the linter photographed was the plate.
	#
	# So the liner becomes what it always claimed to be: the four inner returns of
	# the recess, each exactly as wide as the margin between panel and opening
	# (20 mm), running the full PIER_REVEAL depth from the panel plane out to the
	# face. It lines the hole and touches nothing else. Nothing overlaps the text.
	#
	# BEVEL EXPLICITLY 0. One box became four, and PbrKit.box() chamfers by
	# default — 44 triangles each instead of 12. On a 20 mm strip the kit's
	# derived chamfer is 1.5 mm, which at 143 px/m is a fifth of a pixel: 128
	# triangles for something no frame can resolve. Passing 0 takes the kit's
	# own plain-BoxMesh path, and the pylon lands at 268 triangles against the
	# 72 it shipped with — 3.7x, inside the budget. The chamfers that are worth
	# paying for are on the mass (14 mm, 2 px along a 2.65 m silhouette) and the
	# skin returns, which draw the reveal.
	var liner_w: float = (open_w - PANEL_W) * 0.5
	for k in range(2):
		var ls: float = -1.0 if k == 0 else 1.0
		_add_support_node(PBR.box(
			Vector3(ls * (open_w - liner_w) * 0.5, PANEL_CY, skin_cz),
			Vector3(liner_w, open_h, PIER_REVEAL), reveal_mat, 0.0))
	var liner_span: float = open_w - liner_w * 2.0
	_add_support_node(PBR.box(
		Vector3(0.0, open_top - liner_w * 0.5, skin_cz),
		Vector3(liner_span, liner_w, PIER_REVEAL), reveal_mat, 0.0))
	_add_support_node(PBR.box(
		Vector3(0.0, open_bottom + liner_w * 0.5, skin_cz),
		Vector3(liner_span, liner_w, PIER_REVEAL), reveal_mat, 0.0))

	# The building is speaking, and what a lit reveal does to the wall around it
	# is the whole read: a gradient down 2.65 m of pier from a source the viewer
	# can see. Longer range than the frame's because there is far more surface to
	# grade, still short enough to be a prop light and not a room light.
	_panel_spill(0.85, 1.7)


## PbrKit.anodized() with a brush AXIS, because the kit hard-codes "y".
##
## MIND THE NAMING — it inverts, and this file assumed otherwise for one round.
## brushed_metal("y") sets uv1_scale to (3, 40, 3), and uv1_scale is a TILING
## RATE: a surface point moving one metre in Y advances 40 units through the
## noise while a metre in X advances 3. The pattern therefore decorrelates 13x
## faster vertically, its iso-value contours stretch HORIZONTALLY, and "y"
## renders horizontal streaks. The kit's docstring reads it the other way ("3
## tiles across the grain, 40 along it"), which is the intuition for stretching
## a texture rather than for scaling a UV.
##
## So, for streaks that RUN along a member, pass the axis PERPENDICULAR to it:
## "x" for uprights, "y" for horizontal runs. Reported upstream rather than
## patched — commons/render/pbr_kit.gd is shared by six shipped artifacts and
## flipping it would silently rotate the grain on all of them.
##
## The three lines after the call are the kit's own oxide film, copied verbatim
## so the two bezel materials cannot drift apart.
func _anodised_bar(c: Color, rough: float, wear: float, axis: String) -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.brushed_metal(c, rough, wear, axis)
	m.metallic = 0.85
	m.metallic_specular = 0.5
	m.clearcoat_enabled = true
	m.clearcoat = 0.35
	m.clearcoat_roughness = clampf(0.10 + wear * 0.4, 0.0, 1.0)
	return m


## The light the panel itself throws on the apparatus holding it.
##
## The Viewport2Din3D face is UNSHADED — it is bright, and it emits nothing. So
## every value of this axis had a glowing rectangle sitting in a bezel or a
## reveal that the glow did not touch, which is the specific reason the pylon
## measured as one tone: 2.65 m of pier lit only by whatever the map happened to
## provide, evenly, from far away.
##
## One OmniLight3D, shadows OFF, bake DISABLED. It is a prop light: `reach` is
## sized to the apparatus it is mounted in and it dies well before it reaches
## anything the map is responsible for. Only one branch of the match ever runs,
## so an instance carries at most one of these — and `none`, which is where all
## 29 shipped placements live, carries zero nodes and therefore zero lights.
##
## attenuation 1.6 rather than the default 1.0 on purpose: the falloff IS the
## effect. A flat-lit 2.65 m pier is exactly the "one value across the object"
## the lint measures, and a light that reaches everything equally would not fix
## it — it would just make it brighter.
func _panel_spill(energy: float, reach: float) -> void:
	var l := OmniLight3D.new()
	l.name = "PanelSpill"
	# Just proud of the panel face, on its centre. Slightly cool, because a page
	# of text on a dark ground is the coolest thing in this family's palette and
	# the warm concrete and warm-grey anodising are what it has to play against.
	l.position = Vector3(0.0, PANEL_CY, PANEL_CZ + 0.12)
	l.light_color = Color(0.86, 0.89, 0.96)
	l.light_energy = energy
	l.light_specular = 0.6
	l.omni_range = reach
	l.omni_attenuation = 1.6
	l.shadow_enabled = false
	l.light_bake_mode = Light3D.BAKE_DISABLED
	_add_support_node(l)


## Accept an axis value only if it names something we actually build. A typo in
## a map token has to fall back to the shipped look, not strand a placement with
## half an apparatus.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Resolve the axis from a grid config and rebuild ONLY if it actually moved.
##
## curation_station calls apply_grid_config({"emissive": false}) on every artifact
## it curates — one line after it has un-billboarded, dimmed and back-plated the
## labels. An unconditional rebuild there throws that framing away and it is never
## re-applied. So: no support key, or the same value, means touch nothing and say
## nothing.
func _apply_support_config(config_data: Dictionary) -> void:
	var before_support: String = support
	if config_data.has("support"):
		support = _pick_axis(str(config_data["support"]), SUPPORTS, support)

	if not _built:
		return  # nothing built yet — _ready() will use the value we just resolved
	if support == before_support:
		return

	_rebuild_now()
	print("[CodeDisplay] Config applied — support=%s" % [support])


## Synchronous teardown + rebuild. remove_child() takes the old nodes out of the
## tree in this same frame (queue_free alone would leave them rendering), and
## nothing is deferred: a deferred rebuild would have the grid's auto-ground pass
## measure an empty AABB and skip grounding entirely.
func _rebuild_now() -> void:
	for c in _support_nodes:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_support_nodes.clear()
	_build_all()

func _find_rich_text_label() -> void:
	"""Find the RichTextLabel within the Viewport2Din3D's viewport scene"""
	print("CodeDisplay: _find_rich_text_label() called")

	if not viewport_2d:
		push_warning("CodeDisplay: Viewport2Din3D not found")
		return

	print("CodeDisplay: Waiting for scene to load...")
	# Wait for scene to load
	# out-of-tree guard: get_tree() is null once a map is torn down mid-build
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	await get_tree().process_frame
	print("CodeDisplay: Scene load wait complete")

	# Try to find by path first (faster and more reliable)
	# Try TextUIControl.tscn path first (used by codeDisplay.tscn)
	var textui_path = "Viewport/Control/ScrollContainer/RichTextLabel"
	print("CodeDisplay: Trying TextUIControl path: %s" % textui_path)
	rich_text_label = viewport_2d.get_node_or_null(textui_path)
	if rich_text_label:
		print("CodeDisplay: ✅ Found RichTextLabel at path: %s" % textui_path)
		return

	# Fallback to tutorial_display_2d.tscn path
	var tutorial_path = "Viewport/TutorialDisplay2D/MarginContainer/ScrollContainer/TutorialContent"
	print("CodeDisplay: Trying TutorialDisplay2D path: %s" % tutorial_path)
	rich_text_label = viewport_2d.get_node_or_null(tutorial_path)
	if rich_text_label:
		print("CodeDisplay: ✅ Found RichTextLabel at path: %s" % tutorial_path)
		return
	else:
		print("CodeDisplay: ❌ Both direct paths failed")

	# Try to get the scene instance from Viewport2Din3D
	print("CodeDisplay: Checking if viewport_2d has get_scene_instance method...")
	if viewport_2d.has_method("get_scene_instance"):
		print("CodeDisplay: Method exists, calling it...")
		var scene_instance = viewport_2d.get_scene_instance()
		if scene_instance:
			print("CodeDisplay: Got scene instance: %s, searching recursively..." % scene_instance.name)
			rich_text_label = _find_rich_text_label_recursive(scene_instance)
			if rich_text_label:
				print("CodeDisplay: ✅ Found RichTextLabel via scene instance")
				return
			else:
				print("CodeDisplay: ❌ Recursive search in scene instance failed")
		else:
			print("CodeDisplay: ❌ get_scene_instance returned null")
	else:
		print("CodeDisplay: ❌ viewport_2d does not have get_scene_instance method")

	# Fallback: search in Viewport node
	print("CodeDisplay: Trying fallback - searching in Viewport node...")
	var viewport = viewport_2d.get_node_or_null("Viewport")
	if viewport:
		print("CodeDisplay: Found Viewport node, searching recursively...")
		rich_text_label = _find_rich_text_label_recursive(viewport)
		if rich_text_label:
			print("CodeDisplay: ✅ Found RichTextLabel in viewport")
		else:
			push_warning("CodeDisplay: ❌ Could not find RichTextLabel in viewport")
			print("CodeDisplay: Viewport children count: %d" % viewport.get_child_count())
			if viewport.get_child_count() > 0:
				print("CodeDisplay: First child: %s" % viewport.get_child(0).name)
	else:
		push_warning("CodeDisplay: ❌ Could not find Viewport node")
		var child_names = []
		for child in viewport_2d.get_children():
			child_names.append(child.name)
		print("CodeDisplay: Available children of viewport_2d: %s" % str(child_names))

func _find_rich_text_label_recursive(node: Node) -> RichTextLabel:
	"""Recursively search for RichTextLabel in the node tree"""
	if node is RichTextLabel:
		return node
	
	for child in node.get_children():
		var result = _find_rich_text_label_recursive(child)
		if result:
			return result
	
	return null

func set_tutorial(tutorial_id: String) -> void:
	"""Set the tutorial content by ID"""
	print("CodeDisplay: set_tutorial() called with ID: '%s'" % tutorial_id)

	if not tutorial_library:
		push_warning("CodeDisplay: Tutorial library not initialized")
		return

	current_tutorial_id = tutorial_id.to_lower()
	print("CodeDisplay: Loading tutorial: '%s'" % current_tutorial_id)

	var content = tutorial_library.get_tutorial_content(current_tutorial_id)

	if content.is_empty():
		push_warning("CodeDisplay: Tutorial '%s' not found or has no content" % tutorial_id)
		print("CodeDisplay: Available tutorials: %s" % str(tutorial_library.get_all_tutorial_ids()))
		return

	print("CodeDisplay: Got content (length: %d)" % content.length())
	await _display_content(content)

func set_tutorial_from_text(text: String) -> void:
	"""Parse tt:name format from text and display tutorial content"""
	if not tutorial_library:
		push_warning("CodeDisplay: Tutorial library not initialized")
		return

	# Check if text contains tt:name format
	var expanded_text = tutorial_library.expand_text(text)

	# If expansion occurred, display it
	if expanded_text != text:
		await _display_content(expanded_text)
	else:
		# No tt:name found, just display the text as-is
		await _display_content(text)

func _display_content(content: String) -> void:
	"""Display content in the RichTextLabel"""
	print("CodeDisplay: _display_content() called, rich_text_label is: %s" % ("FOUND" if rich_text_label else "NULL"))

	if not rich_text_label:
		# Try to find it again if not set
		print("CodeDisplay: Searching for RichTextLabel...")
		await _find_rich_text_label()
		print("CodeDisplay: After search, rich_text_label is: %s" % ("FOUND" if rich_text_label else "NULL"))

		if not rich_text_label:
			push_warning("CodeDisplay: Cannot display content - RichTextLabel not found")
			return

	if rich_text_label:
		print("CodeDisplay: Setting content on RichTextLabel...")
		rich_text_label.clear()
		rich_text_label.text = ""
		if _should_render_plain_text(content):
			# Content often includes code-style indexing (e.g. foo[cell]) which is parsed as BBCode tags.
			rich_text_label.bbcode_enabled = false
			rich_text_label.text = content
		else:
			rich_text_label.bbcode_enabled = true
			rich_text_label.bbcode_text = content
		print("CodeDisplay: Content set successfully! Length: %d" % content.length())
	else:
		push_error("CodeDisplay: rich_text_label is still null after search!")

func _should_render_plain_text(content: String) -> bool:
	# Markdown code fences should be shown literally in this display.
	if content.find("```") != -1:
		return true
	
	# Array/dictionary indexing such as grid[cell] causes RichTextLabel to interpret [cell] as a BBCode table cell tag.
	var indexing_regex := RegEx.new()
	if indexing_regex.compile("[A-Za-z_][A-Za-z0-9_]*\\s*\\[[^\\]\\n]+\\]") == OK:
		if indexing_regex.search(content) != null:
			return true
	
	# Fallback: if bracket tags are present but not in our safe BBCode subset, render as plain text.
	var tag_regex := RegEx.new()
	if tag_regex.compile("\\[/?([A-Za-z_][A-Za-z0-9_]*)[^\\]]*\\]") == OK:
		var safe_tags := {
			"b": true,
			"i": true,
			"u": true,
			"s": true,
			"code": true,
			"color": true,
			"font_size": true,
			"url": true,
			"img": true,
			"center": true,
			"right": true,
			"left": true,
			"font": true,
			"hr": true,
			"indent": true,
			"ul": true,
			"ol": true,
			"li": true,
			"quote": true
		}
		for match in tag_regex.search_all(content):
			var tag_name := match.get_string(1).to_lower()
			if not safe_tags.has(tag_name):
				return true
	
	return false

func apply_grid_config(config_data: Dictionary) -> void:
	"""Apply configuration from grid system, similar to clipboard
	Supports both explicit and shorthand syntax:
	  - #tutorial:line_axioms  (explicit)
	  - #line_axioms           (shorthand - value used as tutorial key)
	"""
	print("CodeDisplay: apply_grid_config() called with: %s" % config_data)
	print("CodeDisplay: tutorial_library initialized? %s" % ("YES" if tutorial_library else "NO"))
	print("CodeDisplay: rich_text_label found? %s" % ("YES" if rich_text_label else "NO"))

	# Ensure we're ready before trying to set content
	if not is_node_ready():
		print("CodeDisplay: Node not ready yet, waiting...")
		await ready

	# Ensure RichTextLabel is found
	if not rich_text_label:
		print("CodeDisplay: RichTextLabel not found, searching...")
		await get_tree().process_frame
		_find_rich_text_label()

	# Check for explicit tutorial key first
	if config_data.has("tutorial"):
		var tutorial_key = str(config_data.tutorial).strip_edges()
		print("CodeDisplay: Found explicit 'tutorial' key: '%s'" % tutorial_key)
		if tutorial_key.begins_with("tt:"):
			# Extract tutorial ID from tt:name format
			var parts = tutorial_key.split(":")
			if parts.size() >= 2:
				set_tutorial(parts[1])
		else:
			# Direct tutorial ID
			set_tutorial(tutorial_key)

	elif config_data.has("content"):
		var content_config = str(config_data.content)
		print("CodeDisplay: Found 'content' key: '%s'" % content_config)
		set_tutorial_from_text(content_config)

	else:
		# Check for shorthand syntax (e.g., #line_axioms)
		# Parser stores these as { line_axioms: true }
		print("CodeDisplay: Checking for shorthand syntax...")
		for key in config_data.keys():
			print("CodeDisplay: Key '%s' = %s" % [key, config_data[key]])
			if config_data[key] == true:
				var tutorial_key = key.strip_edges()
				print("CodeDisplay: Using shorthand tutorial key: '%s'" % tutorial_key)
				set_tutorial(tutorial_key)
				break

func refresh_content() -> void:
	"""Reload tutorial library and refresh current content"""
	if tutorial_library:
		tutorial_library.reload_tutorials()
	
	if not current_tutorial_id.is_empty():
		set_tutorial(current_tutorial_id)
