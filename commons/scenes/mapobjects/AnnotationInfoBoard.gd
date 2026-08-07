# AnnotationInfoBoard.gd
# Uses the existing info board structure to display map name and description
# Automatically loads info from the GridDataComponent JSON

extends Node3D
class_name AnnotationInfoBoard

# @identity
# essence: the room reading its own paperwork aloud — a 1.2 x 1.6 m panel standing on the floor with nothing holding it up, filled at runtime from the map's own map_data.json and blurb.md: a serial number, a sequence position, the title, the blurb, a hashed barcode, and the player's XP and health tacked underneath.
# desire: to make a space able to say what it is without an author having to write anything twice — the caption is the metadata, so the caption can never drift from the map.
# critical_parameter: voice — whose institution is speaking, and therefore who is allowed to write on it (system | directory | noticeboard | flap | tape); support — what apparatus holds the sheet up, on the vocabulary the whole family now shares (none | bracket | stand | cradle | frame | gantry | cabinet | pylon), of which this board builds none, stand, cabinet and pylon with its own geometry and degrades the other four.
# triggers: _ready dresses the board from voice/support, then defers to the GridSystem; map_loaded refills the text; apply_grid_config({voice, support}).
# emerges: the same sentence changes authority with its surface — pinned to cork it reads as provisional and amendable, milled into a lit monolith it reads as the building's official position, taped up crooked it reads as one person's stopgap.
# needs: a GridSystem with a GridDataComponent to read map_info from; MapProgressionManager for the sequence index; GameManager for the XP and health line.
# relationships: the scene behind the 'an' utility (415 placements) and the 'info_board' artifact (247 placements) — the same board twice; captioned successor is [[wall_placard]], which drops the XP/health chrome; sibling to [[exhibit_furniture]]'s 'infoboard' kind, which is the furniture without the text.
# truth: a building's signage is a claim about who gets to amend it — the cork board invites a hand, the lit monolith forbids one, and the sentence on both is identical.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). This artifact is the reason the "visible
# in a still" rule exists: it was swept across all five exports of its script and
# produced six identical tiles. The sweep was not wrong about the exports — it was
# reading the WRONG FILE. See the LATENT BUGS note at the foot of this block.
#
# What the board actually was: an unshaded 600x800 SubViewport sprite, charcoal
# (0.12) with a 3 px red hairline, standing on the floor, with an empty
# MeshInstance3D called "Board" where a body should be. No frame, no post, no
# mount, no housing — the engine's own HUD, hung in a room and asked to pass for
# architecture. That is a look, and a very specific one: it is a debug readout.
#
# So the family gets the two axes the object already argued for:
#
#   voice    WHO MAY WRITE ON IT   system · directory · noticeboard · flap · tape
#   support  WHAT HOLDS IT UP      none · stand · cabinet · pylon  (of eight)
#
# `voice` repaints the board's own face (the StyleBoxFlat behind the labels and
# every label colour) and adds the two or three pieces of face furniture that make
# the register unmistakable — an aluminium header and a light slot for the lobby
# directory, four brass drawing pins for the cork board, a header rail and two
# flap seams for the departure board, four tape tabs and a 2.5-degree list for the
# sheet somebody printed at their desk. The field goes from 0.12 charcoal to 0.93
# near-white (directory) or 0.035 black with amber ink (flap): the largest read in
# the family, and it lands on every pixel of the panel.
#
# `support` is mass. Nothing, then a stand — a leaning easel with a picture ledge
# — then a glazed cabinet with hinges and a lock, then a 1.92 x 2.20 m monolith
# with the panel sunk into a reveal. Read as a ladder it is personal,
# institutional, civic — how expensive it is to contradict what the board says.
#
# ── CONVERGENCE PASS (2026-07-27) ────────────────────────────────────────────
# This axis shipped as `carriage`. The same question shipped as `station` on
# fire_hose_box and fire_extinguisher, `rig` on catalyst_target and `housing` on
# science_screen: one question, four names, and inside one of them (`rig`) the
# same word naming both a category and one of its members. All four are now the
# single token `support` on one eight-value vocabulary:
#
#   none · bracket · stand · cradle · frame · gantry · cabinet · pylon
#
# THE VALUE RENAMES HERE: easel -> stand (an easel IS a stand — hyponym folded
# into hypernym, no gesture lost) and case -> cabinet (converging with the fire
# pieces' glazed box). `none` and `pylon` were already canonical. On the other
# axis, voice's `taped` -> `tape`: a participle is not a noun, and every value in
# this grammar is a lowercase snake_case noun. All three old spellings, plus the
# token `carriage` itself, still resolve — see SUPPORT_ALIAS / VOICE_ALIAS.
#
# THE FOUR VALUES THIS BOARD DOES NOT BUILD are the actual subject of the pass.
# Before it, `carriage:gantry` fell through `match carriage:`'s `_:` arm to
# `pass`, built nothing, and said nothing about having done so — a shared
# vocabulary makes that silence a bug rather than a curiosity, because the word
# is now one an author legitimately learned somewhere else. The DEGRADE table
# names the substitution out loud and is consulted BEFORE the build match.
#
# voice=system and support=none are the legacy lineage. Both are hard-guarded to
# return before touching anything: no theme override is added, no node is created,
# the Sprite3D's authored transform is never assigned. All 662 live instances
# (247 artifact placements + 415 'an' utility placements) are byte-identical.
#
# Everything new lives under ONE container child, deliberately: the placer's
# _auto_ground_artifact() walks only DIRECT MeshInstance3D children, and today
# this scene has none with a mesh, so grounding is a no-op. Putting the new
# geometry one level down keeps it a no-op for every variant, which means no axis
# can shift the board vertically by even a millimetre.
#
# What it cost: the board's look is no longer legible from the .tscn — a reader
# has to come here for the palette. And `voice` overrides label colours at
# runtime, so any future theme work on info_board.tscn will be silently overruled
# for four of the five values.
#
# Deliberately NOT routed through either axis: the Area3D and its CollisionShape3D
# (a trigger volume is not a look), the text content itself, and the barcode hash.
#
# LATENT BUGS FOUND, NOT FIXED — reported upward:
#   1. commons/scenes/mapobjects/info_board.gd is ORPHANED. Nothing in the repo
#      loads it (uid://bo7fb2yiasu40 appears in zero .tscn files). info_board.tscn
#      runs THIS script. Its five duration exports were the ones swept.
#   2. info_board.tscn:236-237 connect Area3D.body_entered/body_exited to
#      _on_area_entered/_on_area_exited — methods that exist only in the orphaned
#      info_board.gd, not here. Any body on collision layer 2 entering the trigger
#      raises "nonexistent function" at emit time.
#   3. info_board.tscn:218 "Board" is a MeshInstance3D with no mesh — it draws
#      nothing. Left alone; the new support geometry does not reuse it.
#   4. @export animate_text (line ~21 below) is set true by the .tscn and read by
#      nothing. set_animation_enabled() writes it and nothing reads that either.
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# RENDER PASS (2026-08-07). tools/render_lint.py measured
# `voice-noticeboard x support-cabinet` as FLAT: tonal spread under 0.055 and
# fewer than 40 distinct colours across the subject, which is the numeric
# signature of one albedo, one roughness, one metallic over a whole object. It
# was reading a fact about _mat3(): four scalars and no texture of any kind, on
# every box the two axes have ever built.
#
# So the surfaces move to commons/render/pbr_kit.gd. NOTHING ABOUT THE AXES
# MOVES: the same five voices, the same four native supports, the same
# geometry per value, the same palette colours (the colour IS the voice's
# argument), the same emission energies, and the legacy guard still returns
# before touching a node — so all 1,123 placements, every one of which is
# voice:system + support:none, remain byte-identical. What changed is that a
# voice's colour now arrives on a surface with a roughness texture, a micro
# normal, an honest metallic and a chamfered edge, instead of on a scalar.
#
# THE MEASUREMENT THAT DECIDED IT — see the GRAIN_* block below. This artifact
# is the one place in the corpus where PbrKit's defaults are WRONG out of the
# box, because the .tscn root bakes a 0.2 scale and the kit's triplanar is
# local: used raw, its grain lands a texture feature on 0.7 of a pixel. That is
# not detail, it is static. Every material here is re-scaled by one over the
# assembly's longest LOCAL dimension.
#
# THE SECOND THING, ADDED AFTER RE-READING THE VERDICT: a texture is not an
# albedo. Grunge on one colour moves the tonal spread by roughly a tenth of the
# base value, and the cabinet — the variant actually measured — was reading the
# `body` slot on nine tenths of its new solid: back slab, both stiles, head
# rail, sill, lock keep. So the pieces standing proud of the carcass now take a
# second tone derived from the same slot (_vm_tone), lighter and at 55% of the
# wear. On a timber voice that one number also crosses PbrKit's grunge/micro
# threshold, so the door is a different SURFACE and not just a different value.
# The tone is derived from `body` rather than read from `trim` on purpose:
# `trim` is the palette's LIT slot in three of the five voices, and a glowing
# bezel around a reading surface is the one thing this artifact may not grow.
#
# THE ONE THING THAT MAY NOT REGRESS is the text. This artifact exists to be
# read, so no new surface may reduce contrast on the reading plane: the
# Sprite3D, its unshaded ViewportTexture and every label colour are untouched,
# nothing new was moved in front of a glyph, and the two changes that do land
# over text — the emissive slot and the flap's amber slivers — got DARKER
# albedo under the same emission energy, which is the safe direction. The one
# piece that does cross the sheet, the cabinet's sill, moved to the LIGHTER of
# the two body tones; it occludes the same 34 rows it always did and now
# separates from the field behind it instead of merging with it.
# ─────────────────────────────────────────────────────────────────────────────

const PBR := preload("res://commons/render/pbr_kit.gd")

# ── GRAIN SCALE — the number that decides material from static ───────────────
#
# THE UNIT TRAP, AND IT IS SPECIFIC TO THIS ARTIFACT. The .tscn root bakes a 0.2
# scale (see SPRITE_Y below), so 1 local unit = 0.2 m of world. PbrKit's
# triplanar is LOCAL — it samples the mesh's own model-space vertex position —
# so every uv1_scale in the kit means "tiles per local unit", and the kit's
# defaults (rams_body 4.0, brushed 3 across / 40 along) were tuned on artifacts
# where a local unit IS a metre. Used raw here they land 5x too fine:
#
#     4.0 tiles/unit = 20 tiles/m -> 50 mm tile -> ~2 mm feature -> 0.7 PIXELS
#
# in a 760 px frame. A feature under a pixel is the television-static fault, and
# it is invisible in the code, in the material inspector and under flat ambient
# — it only appears once a directional key lands on it.
#
# PbrKit's rule of thumb is factor ~= 1 / longest_dimension_in_METRES. Fold the
# unit conversion in and the 0.2 cancels exactly:
#
#     factor = (1 / L_metres) * 0.2 = 1 / L_units
#
# so the number to pass is one over the assembly's longest LOCAL dimension.
# Measured, at roughly 3 mm per pixel for a 2 m board photographed at 760 px:
#
#   pylon    11.00 u = 2.20 m -> 0.09 -> 1.8 tiles/m -> 23 mm feature -> 7.6 px
#   cabinet   8.62 u = 1.72 m -> 0.12 -> 2.3 tiles/m -> 18 mm feature -> 6.0 px
#   stand     9.10 u = 1.82 m -> 0.11 -> 2.2 tiles/m -> 19 mm feature -> 6.3 px
#   face      8.00 u = 1.60 m -> 0.13 -> 2.5 tiles/m -> 17 mm feature -> 5.6 px
#
# ONE FACTOR PER ASSEMBLY, NOT PER PART, and that is not laziness. Local
# triplanar is POSITION-based, so a single uv1_scale already gives every part of
# an assembly the same texel density: the 2.6 cm pin head gets a slow tonal
# drift and the 2.2 m slab gets visible blotches, out of the same number.
# Sizing the grain per part would do the opposite — it would put the FINEST
# grain on the SMALLEST parts, which are also the smallest in frame, which is
# how the static gets made.
#
# The strengths are not cut to compensate. Micro normal is the only thing making
# brushed aluminium and moulded plastic read as anything, and the fault here was
# never that a grain existed, only that it was sized for a different object.
const GRAIN_PYLON := 0.09
const GRAIN_CABINET := 0.12
const GRAIN_STAND := 0.11
const GRAIN_FACE := 0.13

# Build the shared grain set once per process, the first time any variant
# actually dresses. Everything in PbrKit is lazy and cached anyway; doing it up
# front means no material can render against a still-white noise texture on the
# first frame of a capture. Never reached on the legacy path, so the default
# placements pay nothing for it.
static var _warmed: bool = false

# References to UI elements
@onready var level_number_label = $Viewport/InfoBoardUI/MainPanel/LevelNumber
@onready var level_id_label = $Viewport/InfoBoardUI/MainPanel/LevelID
@onready var title_label = $Viewport/InfoBoardUI/MainPanel/Title
@onready var summary_label = $Viewport/InfoBoardUI/MainPanel/Summary
@onready var barcode = $Viewport/InfoBoardUI/MainPanel/Barcode
@onready var xp_label = $Viewport/InfoBoardUI/MainPanel/XPLabel
@onready var health_label = $Viewport/InfoBoardUI/MainPanel/HealthLabel

# Configuration
@export var auto_update_on_map_load: bool = true
@export var show_level_number: bool = true
@export var show_metadata: bool = true
@export var animate_text: bool = false

## AXIS 1 — whose institution is speaking, and therefore who is allowed to write
## on the board. Repaints the panel field, every label colour, and adds the face
## furniture that names the register.
##   system      (legacy default) charcoal slab, red hairline, white text — the HUD
##   directory   near-white backlit field, aluminium header + light slot, dark ink
##   noticeboard cork-tan field, dark ink, four brass drawing pins
##   flap        black field, amber ink, header rail + two split-flap seams
##   tape        paper-white field, black ink, four tape tabs, listing 2.5 degrees
##               (spelled `taped` before 2026-07-27; the old spelling still works)
@export var voice: String = "system"

## AXIS 2 — `support`: what apparatus holds this object up. ONE token and ONE
## vocabulary across the family, replacing this board's `carriage`, the fire
## pieces' `station`, catalyst_target's `rig` and science_screen's `housing`.
## The eight canonical values, in ascending order of how much building they put
## behind the object:
##   none     no apparatus — the object meets the room on its own
##   bracket  minimal hardware fixing it to a vertical surface
##   stand    a slender floor member under it — pole, splayed legs, easel
##   cradle   a low wide base at its feet, grips reaching up to touch its body
##   frame    an open upright structure standing around it
##   gantry   an open structure over it; the load comes from above
##   cabinet  a body of cabinetwork takes the floor or wall and serves it
##   pylon    a mass of building; the object is sunk into a slab with a reveal
##
## THIS BOARD BUILDS FOUR OF THE EIGHT with its own geometry:
##   none     (legacy default) the panel stands on the floor, nothing holds it
##   stand    the board leans back 11 degrees on splayed legs with a picture ledge
##   cabinet  a glazed bezel with hinges, a lock and a weather pediment
##   pylon    a 1.92 x 2.20 m monolith with the panel sunk into a reveal
## The other four are neither refused nor silently dropped: the DEGRADE table
## maps each to the nearest thing this artifact actually builds, and says so.
@export var support: String = "none"

# ── the two axes' data ───────────────────────────────────────────────────────

# Panel geometry, in ROOT-LOCAL units. The root's authored transform bakes in a
# 0.2 scale and a 180-degree yaw, so 1 local unit = 0.2 m of world. The Sprite3D
# is 600x800 px at the default pixel_size of 0.01 → 6.0 x 8.0 local = 1.2 x 1.6 m.
# Read from the .tscn; changing either there means changing them here.
const SPRITE_Y := 4.02246                  # authored Sprite3D local Y
const PANEL_HW := 3.0                      # half width
const PANEL_HH := 4.0                      # half height
const PANEL_BOT := SPRITE_Y - PANEL_HH     # 0.02246 — the board is already on the floor
const PANEL_TOP := SPRITE_Y + PANEL_HH
const DNA_NODE := "InfoBoardDNA"

# Every surface either axis can reach, keyed by voice. `field` and the ink colours
# dress the SubViewport UI; `body` / `trim` / `glass` dress the support. The
# "system" entry exists only so a support built under the legacy voice has
# somewhere to get its charcoal from — with support:none nothing reads it.
#
# EACH 3D SLOT NOW NAMES A PbrKit FAMILY (`k`) AND HOW WORN IT IS (`w`). The
# colours, the roughnesses and the emission energies below are the ones that
# shipped — they are what the voice ARGUES and R1 protects them. `k` only says
# which physical surface that colour lands on, which is the whole render pass:
#
#   brushed    rolled-and-brushed metal, metallic 1.0, anisotropic highlight
#   steelcoat  powder-coated steel thinning to bare metal as it wears
#   timber     a dielectric film over a body — varnished board, stained frame
#   plastic    injection-moulded hard plastic with a clear coat
#   matte      the calm Rams housing; no coat, no metal, soft roughness field
#   lamp       self-lit, at the palette's OWN energy, with the albedo pulled
#              down under it so a lit face cannot clip white
#   glass      one dielectric pane, alpha from the colour, Fresnel rim
#
# Nothing sits at the physically meaningless 0.3-0.6 metallic any more except
# steelcoat, where a failing coat legitimately ramps through the middle.
const VOICES := {
	# The legacy lineage. These numbers are lifted from info_board.tscn's
	# StyleBoxFlat_yc54e and the label defaults; they are never APPLIED (the
	# guard in _dress_face returns first) — they are here as the record of what
	# the board was, and as the palette for a support under the legacy voice.
	"system": {
		"field": Color(0.12, 0.12, 0.12), "border_w": 3, "border_c": Color(0.8, 0.0, 0.0),
		"ink": Color(1, 1, 1), "dim": Color(0.72, 0.72, 0.74),
		"accent": Color(0.9137757, 0.5173696, 1.0), "sep": Color(0.5, 0.5, 0.5),
		# Charcoal was 0.16 flat — a near-black with no diffuse left to shade,
		# which reads as a hole rather than as a dark object. steelcoat lifts it
		# and gives it a brushed grain to catch on.
		"body": {"c": Color(0.16, 0.16, 0.17), "r": 0.55, "k": "steelcoat", "w": 0.30},
		"trim": {"c": Color(0.55, 0.06, 0.06), "r": 0.45, "e": 0.7, "k": "lamp"},
		"glass": {"c": Color(0.60, 0.75, 0.85, 0.14), "r": 0.05, "k": "glass"},
		"face": "",
	},
	# The lobby directory: a lit sheet of white behind a brushed frame. Nobody
	# writes on this without a work order. The field inverts 0.12 → 0.93, which
	# is the single loudest change in the family.
	"directory": {
		"field": Color(0.93, 0.94, 0.96), "border_w": 2, "border_c": Color(0.62, 0.65, 0.70),
		"ink": Color(0.07, 0.08, 0.10), "dim": Color(0.30, 0.32, 0.36),
		"accent": Color(0.03, 0.35, 0.62), "sep": Color(0.72, 0.74, 0.78),
		# metallic 0.85 was neither metal nor dielectric. brushed_metal takes it to
		# a true 1.0 with a coloured specular and a roughness that VARIES 0.19-0.31,
		# so the highlight is a lobe smeared along the brush rather than one
		# mirror-smooth sweep — which is also what stops it going black in a room
		# with nothing to reflect.
		"body": {"c": Color(0.66, 0.68, 0.71), "r": 0.22, "m": 0.85, "k": "brushed", "w": 0.16},
		"trim": {"c": Color(0.88, 0.92, 0.97), "r": 0.15, "m": 0.5, "e": 0.9, "k": "lamp"},
		"glass": {"c": Color(0.88, 0.94, 1.00, 0.10), "r": 0.02, "k": "glass"},
		"face": "header",
	},
	# The cork board by the lift. Anyone with a pin may add to it, and everyone
	# knows it, which is why nothing on it is ever quite current.
	"noticeboard": {
		"field": Color(0.62, 0.44, 0.26), "border_w": 0, "border_c": Color(0.36, 0.22, 0.11),
		"ink": Color(0.12, 0.09, 0.06), "dim": Color(0.27, 0.20, 0.14),
		"accent": Color(0.45, 0.11, 0.08), "sep": Color(0.44, 0.31, 0.18),
		# THE FRAME THE LINTER CALLED FLAT was this timber under support:cabinet.
		# The carcass sits at 0.36, deliberately ABOVE painted_metal's 0.30
		# threshold, so it picks up the big warped grunge blotches AND a grime
		# pass. Its door is the same entry read through _vm_tone at 55% of that
		# wear, which lands UNDER the threshold: fine micro grain, clear coat
		# intact, no grime. Old wood next to newer wood, which is what a board
		# that has been repaired looks like — and note that the second tone is
		# derived, not stored, because `trim` here reaches only the hinges, the
		# lock and the pediment and could never have carried the read.
		"body": {"c": Color(0.36, 0.22, 0.11), "r": 0.72, "k": "timber", "w": 0.36},
		"trim": {"c": Color(0.52, 0.34, 0.17), "r": 0.65, "k": "timber", "w": 0.26},
		"glass": {"c": Color(0.82, 0.86, 0.80, 0.13), "r": 0.12, "k": "glass"},
		"face": "pins",
	},
	# The departure board. Only the timetable writes here, and it writes by
	# machinery. Static slats only — a flap that flips is invisible to a still.
	"flap": {
		"field": Color(0.035, 0.035, 0.045), "border_w": 0, "border_c": Color(0.07, 0.07, 0.08),
		"ink": Color(1.00, 0.72, 0.15), "dim": Color(0.84, 0.59, 0.12),
		"accent": Color(0.98, 0.80, 0.28), "sep": Color(0.22, 0.17, 0.06),
		# 0.07 was effectively pure black — PbrKit's own audit flags that as "nothing
		# left to shade". Same charcoal, but as a worn powder coat: it keeps its
		# darkness and gains a surface. Amber energy is UNCHANGED at 1.1; only the
		# albedo under it comes down, which if anything lifts contrast on the two
		# slivers that cross the text.
		"body": {"c": Color(0.07, 0.07, 0.08), "r": 0.45, "k": "steelcoat", "w": 0.34},
		"trim": {"c": Color(1.00, 0.68, 0.12), "r": 0.35, "e": 1.1, "k": "lamp"},
		"glass": {"c": Color(0.20, 0.20, 0.22, 0.18), "r": 0.06, "k": "glass"},
		"face": "seams",
	},
	# A4, printed at somebody's desk, taped up crooked. The most amendable
	# surface in the set and the only one whose author is a person. Spelled
	# "taped" until the 2026-07-27 grammar pass; a value is a noun, not a
	# participle, so the tape is the value and the old spelling is an alias.
	"tape": {
		"field": Color(0.95, 0.94, 0.90), "border_w": 0, "border_c": Color(0.80, 0.79, 0.76),
		"ink": Color(0.06, 0.06, 0.07), "dim": Color(0.32, 0.32, 0.32),
		"accent": Color(0.55, 0.10, 0.10), "sep": Color(0.62, 0.61, 0.58),
		# The quietest voice keeps the quietest surface: matte is the family default,
		# no coat and no metal, a roughness that varies just enough that the
		# highlight is a soft field instead of a flat wash.
		"body": {"c": Color(0.80, 0.79, 0.76), "r": 0.85, "k": "matte", "w": 0.24},
		"trim": {"c": Color(0.92, 0.90, 0.84), "r": 0.60, "k": "plastic", "w": 0.12},
		"glass": {"c": Color(0.90, 0.90, 0.88, 0.10), "r": 0.30, "k": "glass"},
		"face": "tape",
	},
}

# How far the sheet leans/lists per axis value. Both are 0.0 on the legacy path,
# so the Sprite3D's authored transform is never written.
#
# THE LEAN KEY IS READ FROM TWO PLACES — here via LEAN_DEG.get(support) in
# _sheet_xform(), and again as a literal inside _support_stand() where the legs
# have to be built in the leaned frame. Both moved from "easel" to "stand"
# together. Split them and the stand keeps its splayed legs but loses its
# 11-degree tip, which is the entire read.
const LEAN_DEG := {"stand": -11.0}
const LIST_DEG := {"tape": 2.5}

# ── the shared support vocabulary ────────────────────────────────────────────

# The whole eight. A value in this list is a sibling — something a map author
# learned on another artifact in the family and is entitled to type here. A value
# NOT in this list is a typo, and only a typo falls back to the export default.
const SUPPORTS: Array = ["none", "bracket", "stand", "cradle", "frame", "gantry",
		"cabinet", "pylon"]

# The four this board builds with its own geometry. Everything else routes here.
const NATIVE: Array = ["none", "stand", "cabinet", "pylon"]

# THE ANTI-SILENCE TABLE — the point of the convergence pass. Every canonical
# value this artifact does not build names the nearest one it does, and is
# resolved BEFORE the build match, so no shared word can land on a `_:` arm and
# quietly produce nothing.
#   bracket -> none    The board is placed free in a cell; it has no wall relation
#                      anywhere in its build, so the least-apparatus state it owns
#                      is its legacy one.
#   cradle  -> stand   The easel's picture ledge and splayed feet are its only
#                      hold-from-below.
#   frame   -> stand   Cut on FORM, not on nearness. The stand's two uprights plus
#                      top rail are OPEN where the cabinet is glazed, so the open
#                      value maps to the open build even though the cabinet's
#                      bezel is geometrically the closer object.
#   gantry  -> pylon   The only value carrying real structure ABOVE the sheet: the
#                      monolith stands 11.0 local against a panel top of 8.02 and
#                      adds a cap course at 11.15. The stand's top rail sits BELOW
#                      the panel head at 7.30, and the cabinet's pediment belongs
#                      to an enclosure, not to an open span.
const DEGRADE: Dictionary = {
	"bracket": "none",
	"cradle": "stand",
	"frame": "stand",
	"gantry": "pylon",
}

# Spellings that predate the convergence, kept so nothing valid yesterday breaks
# today. `easel` and `case` were this board's own words; `carriage` was the token
# (read as config_carriage in _read_dna_meta); `taped` was a voice.
#
# READ THROUGH A HELPER, NEVER AS `TABLE.get(support)`, ON PURPOSE. The value list
# in the registry is DERIVED from this file by tools/apply_dna_block.py, which
# harvests the keys of any constant indexed by the axis variable. Index these
# tables that way and the dead spellings come back as declared values — the sweep
# would then render `easel` and `stand` as two tiles of the same geometry and the
# critic would report the axis inert. An alias must never become a variant.
const SUPPORT_ALIAS := {"easel": "stand", "case": "cabinet"}
const VOICE_ALIAS := {"taped": "tape"}

var _dressed_as: String = ""               # "<voice>|<support>" actually built

# Current map info
var current_map_name: String = ""
var current_lookup_name: String = ""
var current_map_id: String = ""
var current_description: String = ""
var current_metadata: Dictionary = {}

# Sequence parameter support
var sequence_name: String = ""
var sequence_data: Dictionary = {}

func _ready():
	# DNA first: the placer sets config_* metadata BEFORE add_child (see
	# GridInteractablesComponent._apply_artifact_config), so the axes are already
	# readable here. Done ahead of the GameManager hookups so a missing autoload
	# cannot skip the dressing.
	_read_dna_meta()
	_dress()

	print("----------------------------------------------------------------------")
	print("AnnotationInfoBoard: Initializing map info display board")

	# Connect to GameManager for XP updates if available
	if GameManager and GameManager.has_signal("score_updated"):
		GameManager.score_updated.connect(_update_xp_display)
		_update_xp_display(GameManager.get_score())
	
	# Connect to GameManager for Health updates if available
	if GameManager and GameManager.has_signal("health_updated"):
		GameManager.health_updated.connect(_on_health_updated_signal)

	
	# Delay initialization to allow utilities to be placed first
	call_deferred("_delayed_initialization")

func _delayed_initialization():
	"""Delayed initialization to ensure utilities are placed first"""
	# This runs via call_deferred from _ready, by which point the node may
	# already have been removed from the tree (e.g. a parent that rebuilds
	# its children, like lab_room's apply_grid_config). get_tree() is null on
	# a detached node, so bail out instead of crashing on .process_frame.
	if not is_inside_tree():
		return
	print("AnnotationInfoBoard: Starting delayed initialization...")

	# Wait additional frames to ensure grid utilities are fully loaded.
	# Re-check after each await — the node can be freed/detached mid-wait.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return

	# Check for sequence parameter from utility placement
	_check_for_sequence_parameter()
	
	# Connect to grid system for map data
	_connect_to_grid_system()

func _check_for_sequence_parameter():
	"""Check if a sequence parameter was provided via utility placement"""
	if "sequence_name" in self:
		sequence_name = self.sequence_name
		print("AnnotationInfoBoard: Using sequence from property: " + sequence_name)
	elif has_meta("sequence_name"):
		sequence_name = get_meta("sequence_name")
		print("AnnotationInfoBoard: Using sequence from metadata: " + sequence_name)
	
	if not sequence_name.is_empty():
		print("AnnotationInfoBoard: Will load sequence data for: " + sequence_name)
		_load_sequence_data()

func _load_sequence_data():
	"""Load sequence data from MapProgressionManager"""
	# Use the global manager if available
	if not MapProgressionManager:
		print("AnnotationInfoBoard: MapProgressionManager not found")
		return

	# Access sequences directly from manager
	var sequences = MapProgressionManager.sequences
	
	# Find the specific sequence
	if sequences.has(sequence_name):
		var sequence = sequences[sequence_name]
		sequence_data = sequence.duplicate(true)  # Deep copy to preserve array types
		sequence_data["sequence_name"] = sequence_name
		
		# Ensure maps array is properly typed and accessible
		if sequence.has("maps"):
			var maps_array = sequence["maps"]
			# Convert to Array[String] if needed to ensure type consistency
			var typed_maps: Array[String] = []
			for map_id in maps_array:
				typed_maps.append(str(map_id).strip_edges())  # Strip whitespace
			sequence_data["maps"] = typed_maps
			print("AnnotationInfoBoard: Loaded %d maps from sequence: %s" % [typed_maps.size(), typed_maps])
		else:
			sequence_data["maps"] = []
		
		# Map index will be calculated in _update_info_board based on current map
		sequence_data["map_index"] = 0 
		sequence_data["total_maps"] = sequence_data["maps"].size()
		print("AnnotationInfoBoard: ✅ Loaded sequence data for: " + sequence_name)
		
		# Also load current map info so we can display both sequence and map details
		_load_current_map_info_for_display()
		
		# Update the info board immediately with sequence data
		_update_info_board()
	else:
		print("AnnotationInfoBoard: ❌ Sequence '" + sequence_name + "' not found")
		print("AnnotationInfoBoard: Available sequences: " + str(sequences.keys()))

func _load_current_map_info_for_display():
	"""Load current map info for display purposes (without updating the board)"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")

	if grid_system:
		var data_component = grid_system.get_data_component()
		if data_component:
			# Get map_info section directly from JSON
			if data_component.json_loader and data_component.json_loader.map_data:
				var map_info = data_component.json_loader.map_data.get("map_info", {})
				current_map_name = map_info.get("name", "Unknown Map")
				current_lookup_name = map_info.get("lookup_name", "")
				current_metadata = map_info.get("metadata", {})

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

				print("AnnotationInfoBoard: Loaded current map info for display - Name: '%s'" % current_map_name)
			else:
				# Fallback to metadata method
				var metadata = data_component.get_map_metadata()
				current_map_name = metadata.get("name", "Unknown Map")
				current_lookup_name = metadata.get("lookup_name", "")
				current_metadata = metadata

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
				print("AnnotationInfoBoard: Loaded current map info from metadata fallback")
		else:
			print("AnnotationInfoBoard: No data component found for map info display")

func _connect_to_grid_system():
	"""Connect to grid system to get map data"""
	call_deferred("_find_grid_system")

func _find_grid_system():
	"""Find and connect to the grid system"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		# Connect to map loaded signal
		if grid_system.has_signal("map_loaded") and not grid_system.map_loaded.is_connected(_on_map_loaded):
			grid_system.map_loaded.connect(_on_map_loaded)
			print("AnnotationInfoBoard: Connected to GridSystem.map_loaded")
		
		# Get current map info
		_load_current_map_info(grid_system)
	else:
		print("AnnotationInfoBoard: WARNING - Could not find GridSystem")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	"""Find node by class name"""
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func _on_map_loaded(map_name: String, format: String):
	"""Handle when a new map is loaded"""
	print("AnnotationInfoBoard: Map loaded - %s (%s)" % [map_name, format])
	
	# Find grid system to get data
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if grid_system:
		grid_system_ref = grid_system # Cache it
		_load_current_map_info(grid_system)

var grid_system_ref: Node # Cache for ID lookup

func _load_current_map_info(grid_system):
	"""Load map info from grid system data component"""
	var data_component = grid_system.get_data_component()
	if not data_component:
		print("AnnotationInfoBoard: No data component found")
		return

	# Get map_info section directly from JSON
	if data_component.json_loader and data_component.json_loader.map_data:
		var map_info = data_component.json_loader.map_data.get("map_info", {})
		current_map_name = map_info.get("name", "Unknown Map")
		current_lookup_name = map_info.get("lookup_name", "")
		current_metadata = map_info.get("metadata", {})

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

		print("AnnotationInfoBoard: Loaded from map_info - Name: '%s'" % current_map_name)
		print("AnnotationInfoBoard: Description: '%s'" % current_description)
	else:
		# Fallback to metadata method
		var metadata = data_component.get_map_metadata()
		current_map_name = metadata.get("name", "Unknown Map")
		current_lookup_name = metadata.get("lookup_name", "")
		current_metadata = metadata

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
		print("AnnotationInfoBoard: Loaded from metadata fallback")

	# Update the info board display
	_update_info_board()

func _update_info_board():
	"""Update the info board with current map information"""
	print("DEBUG INFOBOARD: Current Map: '%s'" % current_map_name)
	
	# ALWAYS try to determine the true Map ID (filename)
	var check_id = MapProgressionManager.current_map if MapProgressionManager else ""
	
	if check_id.is_empty() and grid_system_ref: 
		# Try to get from grid system if manager is empty (e.g. direct scene load)
		var gs_map_name = grid_system_ref.get("map_name")
		if gs_map_name:
			check_id = gs_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.map_name" % check_id)
		elif "current_map_name" in grid_system_ref:
			check_id = grid_system_ref.current_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.current_map_name" % check_id)
		
		# If GridSystem property failed, try DataComponent (MOST RELIABLE)
		if check_id.is_empty():
			var data_comp = grid_system_ref.get_data_component()
			if data_comp and data_comp.has_method("get_current_map_name"):
				var dc_name = data_comp.get_current_map_name()
				if not dc_name.is_empty():
					check_id = dc_name
					print("AnnotationInfoBoard: Got ID '%s' from GridDataComponent.get_current_map_name()" % check_id)
	
	# Fallback: Get from scene filename
	if check_id.is_empty():
		var scene_path = get_tree().current_scene.scene_file_path
		if not scene_path.is_empty():
			check_id = scene_path.get_file().get_basename()
			print("AnnotationInfoBoard: Extracted ID '%s' from scene path" % check_id)
			
	if not check_id.is_empty():
		current_map_id = str(check_id).strip_edges() # Store valid ID for index lookup (normalized)
		print("AnnotationInfoBoard: Stored normalized map ID: '%s'" % current_map_id)
	
	# 1. Primary Check: current_map_id
	var candidates = []
	if not current_map_id.is_empty():
		candidates.append(current_map_id)
		# candidates.append(str(current_map_id).strip_edges()) # Duplicate if normalized above

	# 2. Secondary Check: Lookup Name (Explicit Override)
	if not current_lookup_name.is_empty():
		candidates.append(current_lookup_name)
		print("AnnotationInfoBoard: Added lookup_name candidate: '%s'" % current_lookup_name)

	
	# 2. Secondary Check: Display Name -> ID conversion (Point Zero -> Point_Zero)
	if not current_map_name.is_empty():
		var underscores = current_map_name.replace(" ", "_")
		candidates.append(underscores)
		# Also try stripping edges from name
		candidates.append(current_map_name.strip_edges())

	if sequence_data.is_empty() and MapProgressionManager:
		for cand in candidates:
			if cand.is_empty(): continue
			
			for seq_id in MapProgressionManager.sequences:
				var seq = MapProgressionManager.sequences[seq_id]
				if seq.has("maps"):
					if cand in seq.maps:
						sequence_name = seq_id
						current_map_id = cand # Update to the working ID
						_load_sequence_data()
						break
			if not sequence_data.is_empty():
				break

	# Use sequence data if available, otherwise fall back to map data
	if not sequence_data.is_empty():
		_update_info_board_with_sequence_data()
	else:
		_update_info_board_with_map_data()

func _update_info_board_with_sequence_data():
	"""Update info board using sequence data from MapProgressionManager"""
	var sequence_name = sequence_data.get("sequence_name", "Unknown")
	
	# Calculate correct map index based on current map ID
	var map_index = 0
	if sequence_data.has("maps"):
		var maps = sequence_data["maps"]
		var found = maps.find(current_map_id)
		
		# If exact ID not found, try the fallback candidates again within the known sequence
		if found == -1:
			var candidates = []
			if not current_lookup_name.is_empty():
				candidates.append(current_lookup_name)
			candidates.append(current_map_name.replace(" ", "_"))
			candidates.append(current_map_name)
			
			for cand in candidates:
				found = maps.find(cand)
				if found != -1:
					print("AnnotationInfoBoard: Found map ID '%s' at index %d via fallback search" % [cand, found])
					break
		
		if found != -1:
			map_index = found
			
	var total_maps = sequence_data.get("total_maps", 1)
	
	# Update level number (show progress in sequence)
	# Use 1-based indexing for human readability (01, 02, 03...)
	var display_index = map_index + 1
	if show_level_number:
		level_number_label.text = "%02d" % display_index
	else:
		level_number_label.text = str(display_index)

	# Update level ID (sequence/progress format + current map name)
	var level_id_text = "%s/%02d of %d" % [sequence_name, display_index, total_maps]
	if not current_map_name.is_empty():
		level_id_text += " - %s" % current_map_name
	level_id_label.text = level_id_text
	
	# Update title (use map name only)
	if not current_map_name.is_empty():
		title_label.text = current_map_name
	else:
		title_label.text = sequence_data.get("name", "Unknown Sequence")
	
	# Update summary (prioritize current map info, no prefixes)
	if not current_description.is_empty():
		summary_label.text = current_description
	else:
		# Fallback to sequence description only if map has no description
		summary_label.text = sequence_data.get("description", "No description available")
	
	# Update barcode (decorative) - use combination of sequence and map name
	var barcode_text = sequence_name
	if not current_map_name.is_empty():
		barcode_text += "_" + current_map_name
	barcode.text = _generate_barcode_pattern(barcode_text)
	
	# Update health to show completion status
	_update_completion_status()

func _update_info_board_with_map_data():
	"""Update info board using map data from map_data.json"""
	# Extract level number from map name if possible
	var level_number = _extract_level_number(current_map_name)
	
	# Update level number
	if show_level_number:
		level_number_label.text = "%02d" % level_number
	else:
		level_number_label.text = str(level_number)
	
	# Update level ID (category/name format)
	var category = _get_map_category(current_map_name)
	level_id_label.text = "%s/%s" % [category, current_map_name]
	
	# Update title (use map name)
	title_label.text = current_map_name
	
	# Update summary (use description + metadata if available)
	var summary_text = current_description
	if show_metadata and not current_metadata.is_empty():
		summary_text += _format_metadata_summary()
	
	summary_label.text = summary_text
	
	# Update barcode (decorative)
	barcode.text = _generate_barcode_pattern(current_map_name)
	
	# Update health to show completion status
	_update_completion_status()

func _extract_level_number(map_name: String) -> int:
	"""Extract level number from map name"""
	# Try to find numbers in the map name
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(map_name)
	
	if result:
		return int(result.get_string())
	
	return -1

func _get_map_category(map_name: String) -> String:
	"""Get category based on map name"""
	if map_name.begins_with("Tutorial"):
		return "tutorial"
	elif map_name.begins_with("Lab"):
		return "lab"
	elif map_name.begins_with("Algorithm"):
		return "algorithm"
	else:
		return "map"

func _format_metadata_summary() -> String:
	"""Format metadata into readable summary"""
	var metadata_text = ""

	
	# User requested to hide difficulty, time, and objectives
	# Keeping function structure in case other metadata needs to be added later
	
	return metadata_text

func _generate_barcode_pattern(map_name: String) -> String:
	"""Generate decorative barcode based on map name"""
	var pattern = ""
	var hash_val = map_name.hash()
	
	for i in range(32):
		if (hash_val >> i) & 1:
			pattern += "█"
		else:
			pattern += "▌"
	
	return pattern

func _update_completion_status():
	"""Update health label to show completion status"""
	# Show actual health if available, or default to 100%
	var health_val = 100
	if is_instance_valid(GameManager) and "player_health" in GameManager:
		health_val = GameManager.player_health
	
	health_label.text = "Health: %d%%" % health_val

func _on_health_updated_signal(_new_health: float):
	"""Signal handler for health updates"""
	_update_completion_status()


func _update_xp_display(new_score: int):
	"""Update XP display from GameManager"""
	if xp_label:
		xp_label.text = "XP: %d" % new_score

func _load_blurb_or_description(map_name: String, fallback_description: String) -> String:
	"""Load blurb.md content if it exists, otherwise return the fallback description"""
	if map_name.is_empty():
		return fallback_description

	# Try multiple path candidates:
	# 1. lookup_name (folder name, e.g., "Point_One")
	# 2. map_name with spaces replaced by underscores
	# 3. map_name as-is (unlikely but try anyway)
	var path_candidates: Array[String] = []

	if not current_lookup_name.is_empty():
		path_candidates.append(current_lookup_name)

	var underscored_name = map_name.replace(" ", "_")
	if underscored_name != current_lookup_name:
		path_candidates.append(underscored_name)

	if map_name != underscored_name and map_name != current_lookup_name:
		path_candidates.append(map_name)

	for candidate in path_candidates:
		var blurb_path = "res://commons/maps/%s/blurb.md" % candidate
		print("AnnotationInfoBoard: Trying blurb path: %s" % blurb_path)
		if FileAccess.file_exists(blurb_path):
			var file = FileAccess.open(blurb_path, FileAccess.READ)
			if file:
				var content = file.get_as_text().strip_edges()
				file.close()
				if not content.is_empty():
					print("AnnotationInfoBoard: ✅ Loaded blurb.md from '%s'" % blurb_path)
					return content

	print("AnnotationInfoBoard: No blurb.md found, using JSON description")
	return fallback_description

# Public API
func force_update():
	"""Force update the display"""
	_find_grid_system()

func set_animation_enabled(enabled: bool):
	"""Enable/disable text animation"""
	animate_text = enabled

func set_metadata_display(enabled: bool):
	"""Enable/disable metadata display"""
	show_metadata = enabled
	_update_info_board()

func get_current_info() -> Dictionary:
	"""Get current map information"""
	return {
		"name": current_map_name,
		"description": current_description,
		"metadata": current_metadata
	}

# ═════════════════════════════════════════════════════════════════════════════
# DNA — voice (who may write on it) x support (what apparatus holds it up)
# ═════════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_dna_meta()
	_dress()

func _read_dna_meta() -> void:
	if has_meta("config_voice"):
		voice = _canon_voice(str(get_meta("config_voice")))
	if has_meta("config_support"):
		support = _resolve_support(str(get_meta("config_support")))

# RESOLVE ONCE, HERE, AND STORE IT IN `support`.
#
# Two consumers switch on this axis: _sheet_xform(), which decides whether the
# sheet leans, and _build_support(), which decides what geometry appears under it.
# Resolve the degrade independently at each site — or at one and not the other —
# and `support:frame` tips the board 11 degrees onto nothing. So the alias fold and
# the degrade both happen at this single point, and every consumer downstream reads
# the stored native value. The function is idempotent (a native value resolves to
# itself), so calling it again on a later apply_grid_config is safe.
func _resolve_support(v: String) -> String:
	# Normalise FIRST. "#support: stand" — with the space a human types after a colon —
	# otherwise misses the alias table and the allow-list and silently returns "none"
	# across 662 live instances. The same silent no-op this pass exists to remove,
	# relocated from the dispatcher into the parser.
	var s: String = str(SUPPORT_ALIAS.get(v.strip_edges().to_lower(), v.strip_edges().to_lower()))
	if not SUPPORTS.has(s):
		return "none"                                # outside the eight: a typo
	if DEGRADE.has(s):
		s = str(DEGRADE[s])                          # canonical, but not built here
	return s if NATIVE.has(s) else "none"

# Same shape on the other axis, but only one entry: `taped` was a participle where
# the grammar wants a noun.
func _canon_voice(v: String) -> String:
	var s: String = str(VOICE_ALIAS.get(v, v))
	return s if VOICES.has(s) else "system"

# THE LEGACY GUARD. voice=system + support=none returns before touching a single
# node: no theme override, no child, no transform write. That is the path all 662
# existing instances take.
func _dress() -> void:
	# Both axes normalised before anything reads them, so a value set in the
	# inspector or written straight to the property (rather than routed through
	# apply_grid_config) resolves the same way a map token does. Both calls are
	# identity on the defaults, so the guard below still fires unchanged.
	voice = _canon_voice(voice)
	support = _resolve_support(support)
	var want: String = "%s|%s" % [voice, support]
	if want == _dressed_as:
		return
	if voice == "system" and support == "none":
		_dressed_as = want
		return
	if not _warmed:
		_warmed = true
		PBR.warm_cache()
	var old: Node = get_node_or_null(DNA_NODE)
	if old:
		old.free()
	var holder := Node3D.new()
	holder.name = DNA_NODE
	add_child(holder)
	# The sheet's plane: the stand's lean composed with the taped sheet's list.
	# Applied here rather than inside _dress_face so that support:stand leans the
	# board even under the legacy voice, which returns early from the face pass.
	var xf: Transform3D = _sheet_xform()
	if xf != Transform3D.IDENTITY:
		var sprite: Node = get_node_or_null("Sprite3D")
		if sprite and sprite is Node3D:
			(sprite as Node3D).transform = xf * Transform3D(Basis.IDENTITY, Vector3(0, SPRITE_Y, 0))
	var face := Node3D.new()
	face.name = "Face"
	face.transform = xf
	holder.add_child(face)
	_dress_face(face)
	_build_support(holder)
	_dressed_as = want

# ── the sheet's own plane ────────────────────────────────────────────────────

# Rotation about `pivot` — used so the lean tips the board about its bottom edge
# (which stays planted on the floor) rather than about the sprite's centre.
func _about(pivot: Vector3, b: Basis) -> Transform3D:
	return Transform3D(b, pivot - b * pivot)

# lean (stand) composed with list (tape). Identity on every other combination, and
# _dress() only assigns the Sprite3D transform when this is NOT identity — so the
# authored transform survives untouched by default. `support` has already been
# resolved to a native value by the time this runs.
func _sheet_xform() -> Transform3D:
	var lean: float = float(LEAN_DEG.get(support, 0.0))
	var list: float = float(LIST_DEG.get(voice, 0.0))
	var t := Transform3D.IDENTITY
	if lean != 0.0:
		t = _about(Vector3(0, PANEL_BOT, 0), Basis(Vector3.RIGHT, deg_to_rad(lean)))
	if list != 0.0:
		t = t * _about(Vector3(0, SPRITE_Y, 0), Basis(Vector3.BACK, deg_to_rad(list)))
	return t

# ── voice: the face ──────────────────────────────────────────────────────────

func _pal() -> Dictionary:
	var p: Dictionary = VOICES.get(voice, VOICES["system"])
	return p

func _col(slot: String, fallback: Color) -> Color:
	var v: Variant = _pal().get(slot, fallback)
	if v is Color:
		var c: Color = v
		return c
	return fallback

func _label_color(path: String, c: Color) -> void:
	var n: Node = get_node_or_null(path)
	if n and n is Label:
		(n as Label).add_theme_color_override("font_color", c)

func _dress_face(face: Node3D) -> void:
	if voice == "system":
		return                                    # the legacy lineage keeps its charcoal

	# Repaint the field the labels sit on. A fresh StyleBoxFlat rather than an
	# edit of the .tscn's sub-resource: the sub-resource is shared by every
	# instance in the scene tree, so mutating it would leak across placements.
	var panel: Node = get_node_or_null("Viewport/InfoBoardUI/MainPanel")
	if panel and panel is Panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = _col("field", Color(0.12, 0.12, 0.12))
		var bw: int = int(_pal().get("border_w", 0))
		sb.border_width_left = bw
		sb.border_width_top = bw
		sb.border_width_right = bw
		sb.border_width_bottom = bw
		sb.border_color = _col("border_c", Color(0.8, 0, 0))
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_right = 2
		sb.corner_radius_bottom_left = 2
		(panel as Panel).add_theme_stylebox_override("panel", sb)

	var ink: Color = _col("ink", Color.WHITE)
	var dim: Color = _col("dim", Color(0.72, 0.72, 0.74))
	var base := "Viewport/InfoBoardUI/MainPanel/"
	_label_color(base + "LevelNumber", ink)
	_label_color(base + "Title", ink)
	_label_color(base + "Summary", ink)
	_label_color(base + "LevelID", dim)
	_label_color(base + "Barcode", dim)
	_label_color(base + "XPLabel", dim)
	_label_color(base + "HealthLabel", dim)
	_label_color(base + "Aperture", dim)
	_label_color(base + "ContextHint", _col("accent", Color(0.91, 0.52, 1.0)))
	var sep: Node = get_node_or_null(base + "Separator")
	if sep and sep is ColorRect:
		(sep as ColorRect).color = _col("sep", Color(0.5, 0.5, 0.5))

	# `face` already carries the sheet's plane (set in _dress), so the furniture
	# stays coplanar when the stand leans or the taped sheet lists.
	match str(_pal().get("face", "")):
		"header":
			_face_header(face)
		"pins":
			_face_pins(face)
		"seams":
			_face_seams(face)
		"tape":
			_face_tape(face)

# DIRECTORY. A brushed header capping the board, a lit slot under it, and two
# stiles standing just outside the panel edge. All of it clears the text: the
# header covers the top 0.47 local, where the .tscn leaves 60 px of dead margin.
func _face_header(face: Node3D) -> void:
	var alu: StandardMaterial3D = _vm("body", GRAIN_FACE)
	var lit: StandardMaterial3D = _vm("trim", GRAIN_FACE)
	_vbox(face, Vector3(6.9, 0.62, 0.36), Vector3(0, PANEL_TOP - 0.24, 0.18), alu)
	_vbox(face, Vector3(5.8, 0.10, 0.10), Vector3(0, PANEL_TOP - 0.60, 0.22), lit)
	for sx in [-1.0, 1.0]:
		_vbox(face, Vector3(0.30, PANEL_TOP + 0.10, 0.30),
				Vector3(sx * 3.15, (PANEL_TOP + 0.10) * 0.5, 0.10), alu)
	# No kick rail: the .tscn runs the ContextHint line to within 5 px of the
	# panel's bottom edge, so anything sitting proud down there eats "Press (X)
	# for Context". The stiles carry the frame instead.

# NOTICEBOARD. Four brass drawing pins at the corners of the cork, seated in the
# margins the .tscn leaves outside its 500 px label boxes. No paper slips: they
# would land on the blurb, and a caption you cannot read is not a variant.
func _face_pins(face: Node3D) -> void:
	# Brass and steel at a true metallic 1.0 — 0.85 and 0.7 were the physically
	# meaningless middle. A 2.6 cm ball's read is its HIGHLIGHT, not its texture:
	# at GRAIN_FACE the whole head sits inside a single noise blob, so each pin
	# gets a slow tonal drift rather than speckle on a nine-pixel object. That is
	# the right answer for a small part, and the opposite of what sizing the
	# grain to the PART would have given.
	var brass: StandardMaterial3D = PBR.scale_detail(
			PBR.machined_metal(Color(0.78, 0.60, 0.24), 0.28, 0.10), GRAIN_FACE)
	var shaft: StandardMaterial3D = PBR.scale_detail(
			PBR.worn_metal(Color(0.55, 0.42, 0.18), 0.30), GRAIN_FACE)
	for sx in [-1.0, 1.0]:
		for py in [0.55, 7.50]:
			var head := SphereMesh.new()
			head.radius = 0.13
			head.height = 0.20
			# Godot's SphereMesh defaults to 64 x 32 — about 4,000 triangles for
			# a 2.6 cm pin head, four of them, on an artifact that ships to a
			# Quest. 16 x 8 is 256 and identical in silhouette at this size, and
			# it buys back more than the chamfers cost. The oblate height stays
			# authored: the pin's shape is not what this pass is changing.
			head.radial_segments = 16
			head.rings = 8
			var mi := MeshInstance3D.new()
			mi.mesh = head
			mi.material_override = brass
			mi.position = Vector3(sx * 2.62, py, 0.13)
			face.add_child(mi)
			_vbox(face, Vector3(0.07, 0.07, 0.13), Vector3(sx * 2.62, py, 0.05), shaft)

# FLAP. A header rail and two seams: one through the waist of the giant "01"
# (which is what a split-flap does to a glyph) and one on the separator row.
# Deliberately static — the flip is a per-second event and invisible to a still.
func _face_seams(face: Node3D) -> void:
	var black: StandardMaterial3D = _vm("body", GRAIN_FACE)
	var amber: StandardMaterial3D = _vm("trim", GRAIN_FACE)
	_vbox(face, Vector3(6.9, 0.62, 0.34), Vector3(0, PANEL_TOP - 0.29, 0.17), black)
	_vbox(face, Vector3(5.9, 0.09, 0.09), Vector3(0, PANEL_TOP - 0.66, 0.21), amber)
	for sy in [6.57, 5.31]:
		_vbox(face, Vector3(6.0, 0.05, 0.05), Vector3(0, sy, 0.05), black)
		_vbox(face, Vector3(6.0, 0.014, 0.055), Vector3(0, sy + 0.033, 0.055), amber)
	for sx in [-1.0, 1.0]:
		_vbox(face, Vector3(0.22, PANEL_TOP, 0.22), Vector3(sx * 3.11, PANEL_TOP * 0.5, 0.08), black)

# TAPED. Four tabs at 45 degrees over the sheet corners. The 2.5-degree list that
# sells it comes from _sheet_xform(), which has already been applied to `face`.
func _face_tape(face: Node3D) -> void:
	# Matte packing tape: a dielectric film light gets THROUGH rather than off.
	# hard_plastic supplies the micro-roughness and the thin-edge rim; the alpha
	# and the backlight are what make it tape and not a white sticker.
	# Deliberately low gloss — a specular sheet over the sheet's own corners
	# would fight the text it is holding up, and legibility outranks finish here.
	var tape: StandardMaterial3D = PBR.hard_plastic(Color(0.86, 0.85, 0.79), 0.22, 0.10)
	tape.albedo_color = Color(0.86, 0.85, 0.79, 0.72)
	tape.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tape.backlight_enabled = true
	tape.backlight = Color(0.26, 0.26, 0.24)
	PBR.scale_detail(tape, GRAIN_FACE)
	var i := 0
	for sx in [-1.0, 1.0]:
		for py in [0.45, 7.60]:
			var q := QuadMesh.new()
			q.size = Vector2(0.95, 0.36)
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = tape
			mi.position = Vector3(sx * 2.78, py, 0.07)
			mi.rotation_degrees = Vector3(0, 0, 45.0 if i % 2 == 0 else -45.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			face.add_child(mi)
			i += 1

# ── support: the body ────────────────────────────────────────────────────────

# `support` reaches this match ALREADY RESOLVED to one of NATIVE — aliases
# folded, degrades applied, typos collapsed to the default — so no canonical value
# can fall through to the wildcard and quietly build nothing. The only value that
# lands on `_:` is "none", where building nothing IS the value: it is the reference
# state the other seven are measured against, not a variant that has to bite.
func _build_support(holder: Node3D) -> void:
	match support:
		"stand":
			_support_stand(holder)
		"cabinet":
			_support_cabinet(holder)
		"pylon":
			_support_pylon(holder)
		_:
			pass                                  # "none" — the legacy lineage

# STAND. An easel: the board leans back 11 degrees (applied in _dress via the
# shared sheet transform) onto two splayed legs and a rear strut, with a picture
# ledge under the front edge. Slender floor members, open air under and around the
# sheet, demountable — the board is visiting the room rather than built into it.
# The lean is what carries the read: a 1.2 x 1.6 m bright rectangle tipping 0.31 m
# back changes the silhouette everywhere.
#
# THE SECOND LEAN SITE. _sheet_xform() tips the sheet; this tips the legs to match.
# The key is "stand" in both (it was "easel" in both before the convergence) and
# they must move together or the board leans off its own frame.
func _support_stand(holder: Node3D) -> void:
	var wood: StandardMaterial3D = _vm("body", GRAIN_STAND)
	var trim: StandardMaterial3D = _vm("trim", GRAIN_STAND)
	var lean := Node3D.new()
	lean.name = "Lean"
	holder.add_child(lean)
	var lean_deg: float = float(LEAN_DEG.get("stand", -11.0))
	lean.transform = _about(Vector3(0, PANEL_BOT, 0), Basis(Vector3.RIGHT, deg_to_rad(lean_deg)))
	# Uprights running the panel plane, splayed out beyond the sheet. They stop
	# 0.30 short at the bottom: the 11-degree lean swings their rear corner down,
	# and starting them at 0 would sink them ~1.8 cm through the floor.
	for sx in [-1.0, 1.0]:
		var up := _vbox(lean, Vector3(0.34, 9.10, 0.34), Vector3(sx * 3.22, 4.85, -0.30), wood)
		up.rotation_degrees = Vector3(0, 0, sx * -3.0)
	_vbox(lean, Vector3(7.1, 0.30, 0.30), Vector3(0, 7.30, -0.30), wood)        # top rail
	# picture ledge — the shelf the sheet actually rests on
	_vbox(lean, Vector3(7.1, 0.34, 0.34), Vector3(0, 0.40, 0.02), wood)
	_vbox(lean, Vector3(7.1, 0.12, 0.62), Vector3(0, 0.55, 0.30), trim)
	# Rear strut + feet, in the UNLEANED frame so they meet the floor square. The
	# strut tips 11.6 degrees the OTHER way, so its foot lands 0.64 m behind the
	# sheet's own foot — the splay that stops an easel folding shut.
	_vbox(holder, Vector3(0.32, 0.30, 3.7), Vector3(0, 0.15, -1.65), wood)
	var strut := _vbox(holder, Vector3(0.30, 8.5, 0.30), Vector3(0, 4.20, -2.35), wood)
	strut.rotation_degrees = Vector3(11.6, 0, 0)
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.90, 0.26, 2.6), Vector3(sx * 3.05, 0.13, 0.20), trim)
	# The feet reach 3.05 out and the rear foot 1.65 back; a pool a touch wider
	# than the feet reads as contact without becoming a puddle.
	_contact(holder, 3.6)

# CABINET. A glazed bezel with two hinge barrels, a lock and a sloped pediment —
# the parish/university board you may read but not open. Joinery integrated with
# the object: a door, a pane, a head rail, a sill, so the outline stops being the
# board and becomes a box. The bezel alone puts 0.56 m2 of new solid outside the
# panel's silhouette.
func _support_cabinet(holder: Node3D) -> void:
	var body: StandardMaterial3D = _vm("body", GRAIN_CABINET)
	# THE DOOR IS NOT THE CARCASS. Every piece standing PROUD of the back slab —
	# both stiles, the head rail, the sill, the lock keep — is the leaf you would
	# open, so it carries its own tone: 0.16 lighter and at 55% of the carcass's
	# wear. See _vm_tone for why it is derived from `body` and not read from
	# `trim`. This is the largest single change the render pass makes to the
	# variant the linter actually measured — the front of the box stops being one
	# colour with the back of it.
	var door: StandardMaterial3D = _vm_tone("body", GRAIN_CABINET, 0.16, 0.55)
	var trim: StandardMaterial3D = _vm("trim", GRAIN_CABINET)
	var glass: StandardMaterial3D = _vm("glass", GRAIN_CABINET)
	_vbox(holder, Vector3(7.1, 8.5, 0.35), Vector3(0, 4.25, -0.30), body)        # back slab
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.55, 8.5, 0.48), Vector3(sx * 3.28, 4.25, 0.14), door)
	_vbox(holder, Vector3(7.1, 0.55, 0.48), Vector3(0, 8.22, 0.14), door)        # head rail
	# The sill is the one place the case has to eat into the poster: the panel's
	# bottom edge is 4.5 mm off the floor, so there is nowhere below it to put a
	# rail. Held to 0.34 (UI rows 768+) and the hint line is lifted clear below.
	# It takes the DOOR tone, which on every voice is the lighter of the two —
	# the safe direction for a piece that sits in front of the reading surface.
	_vbox(holder, Vector3(7.1, 0.34, 0.48), Vector3(0, 0.17, 0.14), door)        # sill
	var hint: Node = get_node_or_null("Viewport/InfoBoardUI/MainPanel/ContextHint")
	if hint and hint is Label:
		var h := hint as Label
		h.offset_top = -88.0
		h.offset_bottom = -63.0
	var pane := _vbox(holder, Vector3(6.6, 7.8, 0.06), Vector3(0, 4.25, 0.30), glass)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# hinges left, lock right — the asymmetry is the whole claim
	for hy in [2.30, 6.20]:
		_vcyl(holder, Vector3(-3.28, hy, 0.34), 0.13, 0.55, trim, Vector3(0, 0, 0))
	_vcyl(holder, Vector3(3.34, 4.25, 0.34), 0.20, 0.12, trim, Vector3(90, 0, 0))
	_vbox(holder, Vector3(0.09, 0.30, 0.10), Vector3(3.34, 4.05, 0.40), door)    # lock keep
	# pediment — a board that lives outdoors gets a roof
	var roof := _vbox(holder, Vector3(7.7, 0.24, 1.30), Vector3(0, 8.62, 0.28), trim)
	roof.rotation_degrees = Vector3(-14, 0, 0)
	_contact(holder, 3.9)

# PYLON. 1.92 x 2.20 m of monolith with the panel sunk into a reveal, on a stepped
# base with a capping course. Nearly 3x the object's projected area — the heaviest
# thing the family can say, and the point at which contradicting the board costs
# money. Also where `gantry` lands: the cap course at 11.15 against a panel top of
# 8.02 is the only real structure this artifact carries ABOVE the sheet.
func _support_pylon(holder: Node3D) -> void:
	var body: StandardMaterial3D = _vm("body", GRAIN_PYLON)
	var trim: StandardMaterial3D = _vm("trim", GRAIN_PYLON)
	_vbox(holder, Vector3(9.6, 11.0, 1.20), Vector3(0, 5.50, -0.66), body)       # slab
	# Base course and reveal both sit wholly BEHIND the panel plane (z < 0). Pushed
	# forward they would occlude the bottom two text rows and the whole sheet
	# respectively; they still read because they overhang the panel sideways.
	_vbox(holder, Vector3(10.6, 0.50, 2.00), Vector3(0, 0.25, -1.05), trim)      # base course
	_vbox(holder, Vector3(10.2, 0.38, 1.70), Vector3(0, 11.15, -0.55), trim)     # cap
	# the reveal: a darker recess ringing the panel so it reads as sunk, not stuck on
	# A reveal is the one place in this artifact a crevice map earns its keep:
	# a recess is exactly where ambient light does not reach, and a large flat
	# slab is exactly where scene SSAO has nothing to bite on. It is also the
	# darkening budget spent in full — the colour is already 55% down off the
	# field — so this material takes no vertex wear and no weathering pass.
	var rec: StandardMaterial3D = PBR.rams_body(
			_col("field", Color(0.1, 0.1, 0.1)).darkened(0.55), 0.05)
	PBR.crevice_ao(rec, 0.45)
	PBR.scale_detail(rec, GRAIN_PYLON)
	rec.set_meta("vwear", 0.0)
	_vbox(holder, Vector3(6.9, 8.6, 0.30), Vector3(0, PANEL_BOT + 4.30, -0.20), rec)
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.26, 8.9, 0.26), Vector3(sx * 3.36, PANEL_BOT + 4.30, 0.02), trim)
	_vbox(holder, Vector3(7.4, 0.26, 0.26), Vector3(0, PANEL_BOT + 8.72, 0.02), trim)
	_contact(holder, 5.4)

# ── primitives ───────────────────────────────────────────────────────────────

# A material from a voice palette slot, built by PbrKit rather than by hand.
#
# `grain` is the assembly's 1 / longest-local-dimension — see the GRAIN_* block.
# It is a required argument on purpose: the old _mat3 could be called without
# thinking about scale, and that is the fault this pass exists to fix.
#
# The fallbacks keep a half-specified voice degrading to plain matte rather than
# to nothing, which is what the hand-rolled version did.
func _vm(slot: String, grain: float) -> StandardMaterial3D:
	var d: Dictionary = _pal().get(slot, {})
	var c: Color = d.get("c", Color(0.8, 0.8, 0.8))
	return _vm_build(str(d.get("k", "matte")), c, float(d.get("r", 0.6)),
			float(d.get("e", 0.0)), float(d.get("w", 0.18)), grain)

# A SECOND TONE OFF THE SAME SLOT — same wood, same coat, different age.
#
# THE FLAT VERDICT WAS ABOUT AREA, NOT ABOUT TEXTURE. A grunge map on one albedo
# moves the tonal spread by about a tenth of the base value; a second albedo
# moves it by half. The cabinet was the variant the linter measured and it read
# `body` on the back slab, both stiles, the head rail, the sill AND the lock
# keep — nine tenths of the new solid in frame, all one colour. So the DOOR gets
# its own tone and the carcass keeps the palette's.
#
# LIGHTER, then LESS WORN, in that order and for reasons:
#   lighter    two of the five voices put a near-black in `body` (flap 0.07,
#              system 0.16), and on a near-black the only direction with any
#              room in it is up. Darkening a second piece would have produced
#              the hole PbrKit's own audit warns about, twice.
#   less worn  under PbrKit.painted_metal's 0.30 threshold the same colour
#              switches from big warped grunge WITH a grime pass to fine micro
#              grain with its clear coat intact. One number therefore buys two
#              different SURFACES, not just two values — which is the "old wood
#              next to newer wood" the noticeboard palette already claimed and
#              did not previously deliver anywhere it could be seen.
#
# DERIVED FROM `body`, NOT READ FROM `trim`, and that is the whole care in this
# function. `trim` is the palette's LIT slot: three of the five voices put an
# emissive there (system red 0.7, directory white 0.9, flap amber 1.1). A bezel
# routed to it would become a glowing frame around the reading surface, which is
# the one thing this artifact may not do — and it would raise the emissive area
# of an already lamp-heavy corpus for nothing.
func _vm_tone(slot: String, grain: float, lift: float, wear_scale: float) -> StandardMaterial3D:
	var d: Dictionary = _pal().get(slot, {})
	var c: Color = d.get("c", Color(0.8, 0.8, 0.8))
	return _vm_build(str(d.get("k", "matte")), c.lightened(clampf(lift, 0.0, 1.0)),
			float(d.get("r", 0.6)), float(d.get("e", 0.0)),
			float(d.get("w", 0.18)) * maxf(wear_scale, 0.0), grain)

func _vm_build(kind: String, c: Color, r: float, em: float, w: float,
		grain: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = null
	# How much edge-lighter / base-darker wear PbrKit.box may bake into the
	# vertex colours. THREE SUBTLE DARKENINGS AGREE ON BLACK: a grime multiply,
	# an AO map and baked vertex wear each take "a little" off and the result is
	# a hole. So any family that already runs its own weathering pass gets zero
	# here, and no surface in this file carries more than two.
	var vwear: float = 0.22
	match kind:
		"brushed":
			m = PBR.brushed_metal(c, r, w, "y")
		"steelcoat":
			# terminal_body darkens its albedo AND weathers itself above wear 0.18.
			# That is already two.
			m = PBR.terminal_body(c, w)
			vwear = 0.0
		"timber":
			# painted_metal at metal 0 is a dielectric film over a body, which is
			# exactly a varnished board. Above wear 0.30 it swaps micro grain for
			# the big warped grunge and adds a grime pass of its own.
			m = PBR.painted_metal(c, w, 0.0, r)
			if w > 0.30:
				vwear = 0.0
		"plastic":
			m = PBR.hard_plastic(c, clampf(1.0 - r, 0.0, 1.0), w)
			vwear = 0.18
		"lamp":
			# Energy is the palette's OWN, unchanged. This corpus is already full
			# of lit lines and the capture rig has bloom off because it fattened
			# every one of them past its own silhouette; the only move available
			# is downward, and PbrKit's is to pull the albedo out from under the
			# emission so a lit face cannot clip to white.
			m = PBR.emissive(c, em)
			vwear = 0.0
		"glass":
			# One pane, never stacked — transparency is overdraw and overdraw is
			# the Quest's tightest budget. Roughness stays above 0.01 in every
			# voice, so the pane keeps a specular LOBE instead of being a perfect
			# mirror with nothing to reflect.
			m = PBR.glass(c, r, c.a)
			vwear = 0.0
		_:
			m = PBR.rams_body(c, w)
	PBR.scale_detail(m, grain)
	m.set_meta("vwear", vwear)
	return m

# Vertex-wear budget carried on the material, so _vbox can honour it without
# every call site having to repeat it.
func _vwear_of(mat: StandardMaterial3D) -> float:
	if mat != null and mat.has_meta("vwear"):
		return float(mat.get_meta("vwear"))
	return 0.0

# Chamfer width in LOCAL units. Real objects have no zero-radius edges, and a
# chamfer catching a highlight line is the clearest single difference between a
# render and a box.
#
# PbrKit.box derives its own default from the smallest dimension and clamps it
# to 14 mm — right when a local unit is a metre, 2.8 mm here, which is under a
# pixel on a 2 m board. So the clamp is restated in this artifact's units:
# 12 mm to 75 mm local, which is 2.4 mm to 15 mm of world, or 1-5 px in frame.
#
# Below 0.12 units (24 mm) a part is a hairline strip — the flap's seam slivers,
# the directory's lit slot, the pin shafts. Returning 0 there sends PbrKit.box
# down its plain-BoxMesh path: 12 triangles instead of 44, and identical on
# screen. That is most of the part count, and it is how the R2 budget survives
# chamfering everything that is actually thick enough to show one.
func _bev(size: Vector3) -> float:
	var mn: float = minf(minf(absf(size.x), absf(size.y)), absf(size.z))
	if mn < 0.12:
		return 0.0
	return clampf(mn * 0.09, 0.012, 0.075)

func _vbox(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi: MeshInstance3D = PBR.box(pos, size, mat, _bev(size), _vwear_of(mat))
	parent.add_child(mi)
	return mi

# Chamfered rims rather than CylinderMesh's zero-radius corner, which disappears
# against any background. Also CHEAPER than what it replaces: Godot's
# CylinderMesh defaults to 64 radial segments, and nothing here is bigger than a
# 5 cm hinge barrel, so 20 is generous.
func _vcyl(parent: Node3D, pos: Vector3, radius: float, height: float,
		mat: StandardMaterial3D, rot: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = PBR.chamfer_cylinder(radius, height, -1.0, mat, 20,
			_vwear_of(mat))
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

# A projected contact pool, so a support MEETS the floor instead of hovering
# over it. It is a Decal, so it conforms to whatever it lands on rather than
# z-fighting a floor quad, and a Decal is not a light — this spends nothing
# against the R2 light budget. One per support, never on support:none, which
# never reaches here.
func _contact(holder: Node3D, radius: float) -> void:
	holder.add_child(PBR.ground_shadow(radius, 0.45, 0.10))
