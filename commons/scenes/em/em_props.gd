class_name EmProps
extends RefCounted
# em_props.gd — the service furniture. What a museum has on its walls, its
# ceiling and its floor that is NOT art.
#
#   EmProps.dress(seg, tile, w, h, allowance, mats) -> Array[Dictionary]
#
# THE MEASUREMENT THIS ANSWERS. A critic cropped 420x360 px of this corridor's
# wall — about 2 m2 of plaster — and counted the features in it: exactly one, a
# light blob. No socket, no vent, no seam, no signage. em_detail since supplied
# skirting, cornice, door reveals, wall cards and hung showings, all of which are
# UNTEXTURED BOXES it draws itself. This file supplies the other half: the 87
# real prop scenes that already exist on disk, already have DNA, and already
# photograph — ada_encyclopedia/public/props-dna-gallery/manifest.json, 279
# rendered variants across 87 props, every one of them a registry artifact.
#
# THIS FILE PLACES NOTHING. It returns a list of placements and the host stamps
# them. That is not squeamishness, it is the safety property: the one way this
# build breaks is an object standing on a floor cell that never left
# `_walk_cells`, after which the autopilot's BFS plans through solid geometry and
# the gate fails. A module that cannot add_child cannot cause that failure by
# accident; every record says explicitly whether it costs a walk cell, and the
# host is the single place that erases one.
#
# ── HOW THE 87 WERE CLASSIFIED ───────────────────────────────────────────────
# Not by vibes and not by the manifest's `dna` keys alone. Three signals, in
# order of authority, and the CATALOGUE below records which one decided:
#
#   1. THE PROP'S OWN DOCUMENTED ORIGIN. Nearly every one of these scripts states
#      its mounting convention in its class docstring, and the statement is
#      load-bearing because this module positions by that origin and nothing
#      else. Verbatim examples:
#        floor_grate      "Origin is at the CENTER OF THE TOP (WALKABLE) SURFACE
#                          — y=0 is the surface you walk on."      -> EDGE, flush
#        ceiling_vent     "Origin is at the OPENING PLANE ... the recess extends
#                          UP into the ceiling (+Y)."              -> CEILING
#        cable_tray       "Origin is at the TRAY CENTER ... mount with the tray's
#                          local +Y pointing UP toward the ceiling."-> CEILING
#        electrical_panel "Origin is at the CENTER OF THE PANEL BACK FACE —
#                          back faces -Z, front faces +Z."         -> WALL
#        lab_stool        "Origin is at the bottom center of the base, the post
#                          points up +Y."                          -> FLOOR
#   2. A MOUNTING-BEARING DNA KEY. `mounting` (emergency_button, palm_scanner:
#      wall | podium), `wall_bracket` (fire_extinguisher), `bar_count_x` +
#      `bar_count_z` + `wear_factor` (floor_grate — a lattice in the floor
#      PLANE), `vent_width`/`slat_count` (ceiling_vent), `tray_height`/
#      `tray_length` (cable_tray), `seat_height`/`base_radius` (lab_stool),
#      `length_cells`/`height_cells` (the station kit — modules measured in
#      floor cells, so they stand on the floor).
#   3. THE SURFACE NOUN IN THE NAME, and ONLY where 1 and 2 agree with it:
#      wall_clock, hangar_wall_panel, ceiling_vent, floor_grate. A name alone
#      never decided anything here — station_luminaire is named like a ceiling
#      fitting and is NOT classified as one, see the declaration note below.
#
# ── THE DECLARATION NOTE (the science_screen trap, one class of it caught) ────
# The gallery manifest lists `mount`, `drop` and `fixture_style` in
# station_luminaire's dna. The script on disk exports `mode`, `height`,
# `arm_reach` — no `mount`, no `drop`, no `fixture_style`. So the manifest's dna
# for that prop describes something the code does not have, exactly the failure
# `tools/check_dna_declarations.py` exists to catch. This file therefore takes
# its config keys from the EXPORTS, never from the manifest, and station_luminaire
# is classified UNVERIFIED and never placed. Same reason artifact_readout_screen
# (manifest `mount`) is classified but not placed.
#
# ── RESOLUTION, MEASURED 2026-08-10 ──────────────────────────────────────────
# 80 of the 87 gallery props resolve against the registry as ALIVE — scene
# declared, map_ready true, file present on disk. The seven that do not are
# station_console_desk, station_door, station_frame, station_gantry,
# station_handrail, station_ladder and station_stair_run: all seven have a
# rendered gallery entry and a dna block, and none of them has a registry row
# in commons/artifacts/registry/station.json, which holds the other eight
# station pieces. That is a gap in the registry, not in this file, and it is
# reported rather than worked around. None of the seven is in PLACEABLE.
# All 19 PLACEABLE tokens resolve. Resolution is nevertheless re-checked at
# RUNTIME against `allowance.live`, because a registry measured once is a
# registry that will be wrong later.
#
# ── WHAT IS DELIBERATELY NOT HERE ────────────────────────────────────────────
# 34 of the 87 are TABLETOP: objects whose own origin is a bottom centre and
# whose body is roughly half a metre or less — microscope (measured 0.40 m),
# petri_dish, test_tube_rack, specimen_jar, lock_box, computer_keyboard. Those
# belong to the OTHER finding: 308 of 662 measured spine artifacts stand below
# the viewing band and need lifting onto something. Putting a 0.20 m instrument
# on this deck would add one more object the walker has to look at their feet to
# find. They are classified so the lifting pass can find them, and this module
# refuses to place a single one.
#
# ── DENSITY ──────────────────────────────────────────────────────────────────
# Three hard promises, all checkable:
#   * props never outnumber the artworks. The cap is min(rate x wall run,
#     MAX_PROPS_PER_SEGMENT, the segment's own artwork budget).
#   * props never block a walk cell UNLESS the record says occupies_floor, which
#     only two of the thirteen rules ever set (R10's hose box and R11's pocket
#     furniture), at most MAX_FLOOR_TAKEN of them per segment, each one passing
#     the same clearance test the host's own bench rule uses — both neighbours
#     along the wall are floor, the squeeze-past cell beyond is floor — AND
#     never on the walker's own route. Measured over the thirty museum-tagged
#     templates: 0 violations, and no segment surrendered more than 3 cells.
#   * a building whose stated mechanism forbids service furniture gets none.
#     em_budget reads a wall-furniture rate off each museum's own text; below
#     0.6 per 10 m (teshima 0.3 "a socket would be a scandal"; sando 0.5 "the
#     only thing a body can look at is the frame it is currently passing
#     through") this file returns an EMPTY ARRAY. Below 1.5 (chichu 0.8, whose
#     72% wall is deliberately empty — the passage is the frame; katsura,
#     mesdag, neue, libeskind 1.0) it returns at most the one exit sign over the
#     threshold, which is the only fitting in the catalogue that is there by law
#     rather than by taste.
#
# Deterministic throughout: no randf(), every scan in a fixed order, so two runs
# of one seed dress the same building and two proof shots are the same
# photograph.

# ── GEOMETRY THE HOST OWNS. Every constant here is mirrored from the file that
# actually stamps it, named, so a drift is a one-line fix instead of a hunt.
const VESTIBULE_H := 4        # endless_museum.gd VESTIBULE_H
const LOBBY_W := 17           # endless_museum.gd LOBBY_W
# the building contract, IMPORTED from its owners rather than duplicated.
# These were hand-copied literals, and the 3.0 -> 4.5 wall raise proved the
# point: every copy below went stale the day the owner moved, and this file
# would have dressed 4.5 m walls as if they were 3.0 (cable tray at 2.86 in
# open air, nothing hung above a cornice that no longer exists at 2.72).
const _Detail := preload("res://commons/scenes/em/em_detail.gd")
const _Lighting := preload("res://commons/scenes/em/em_lighting.gd")
const WALL_H := _Detail.WALL_H
const FLOOR_TOP := 0.0        # floor boxes: y -0.1, size 0.2 -> top at 0.0
const DOOR_HEAD := _Detail.DOOR_HEAD
const HEAD_LINING := _Detail.HEAD_LINING
const PORTAL_HEAD := _Detail.PORTAL_HEAD
const PORTAL_HEAD_LINING := 0.16
const MAX_DOOR_CELLS := _Detail.MAX_DOOR_CELLS
const CORNICE_BOTTOM := _Detail.CORNICE_BOTTOM  # nothing may be hung above this
const SKIRT_H := _Detail.SKIRT_H                # nothing hangs below this
const CEIL_SOFFIT := _Detail.CEIL_SOFFIT        # the ceiling plane
const CEIL_THICK := _Detail.CEIL_THICK          # the slab a recessed vent recesses INTO
const BAY := _Detail.BAY      # ceiling coffer and floor seam module
const SLOT_W := _Detail.SLOT_W                  # the OPEN daylight slot per bay
const RIB_W := _Detail.RIB_W  # longitudinal ribs at x = 0, 3, 6 ...
const RIB_UNDERSIDE := _Detail.CEIL_SOFFIT - _Detail.RIB_DROP
const SKY_Y := _Lighting.SKY_Y  # nothing hangs between the ribs and this plane

# ── THE WALKER. endless_museum.gd builds a CharacterBody3D with
# CapsuleShape3D.radius = 0.32 and the autopilot plans cell centre to cell
# centre. So a body standing in the middle of a 1 m cell leaves exactly
# 0.5 - 0.32 = 0.18 m between its capsule and the wall face. Anything hung
# proud of that grazes the walker, and a graze on the streaming frame is how a
# gate turns red. WALL_PROUD_MAX takes 20 mm of that as margin.
const WALKER_RADIUS := 0.32
const WALL_CLEARANCE := 0.18  # 0.5 - WALKER_RADIUS
const WALL_PROUD_MAX := 0.16
# A prop deeper than this is REFUSED by the wall emitter — silently, so a rule
# can offer a fitting without knowing its dimensions and the gate decides. Two
# fittings that genuinely need the depth (the 0.25 m fire hose box, the pocket
# furniture) go through the floor emitter instead, which stands them on the deck
# in front of the face and surrenders that cell exactly the way the host's own
# bench does.

# ── MOUNTING HEIGHTS, and what each is measured against ──────────────────────
const H_EXTINGUISHER := 1.10  # base of the cylinder. EN 3 hangs a portable unit
                              # with its base 0.8-1.1 m off the floor; the top of
                              # that band puts this 0.55 m body at 1.10..1.65,
                              # its valve landing on the 1.65 m eye line
const H_ESTOP := 1.05         # palm height, standing
const H_PANEL := 1.50         # centre of a breaker panel — the switchgear band
const H_SCANNER := 1.35       # a hand offered at a door, not reached up to
const H_CLOCK := 2.25         # above the picture band (em_detail hangs at 1.58),
                              # below the cornice at 2.72
const H_SCREEN := 1.55        # centre of an info screen, near the hang centre line
const H_BOARD := 1.30         # a whiteboard's centre: written on standing
const H_WINDOW := 1.70        # an observation window, sighted over
const H_HOSE_BOX := 1.00      # centre of a 0.6 m box -> 0.70..1.30
# over the portal / the door: these were literals whose reasoning was
# door-head arithmetic ("2.10 + 0.12 lining + 0.08") — now they ARE that
# arithmetic, so they rode the door raise without being touched
const Y_EXIT_PORTAL := PORTAL_HEAD + PORTAL_HEAD_LINING + 0.16
const Y_EXIT_WALL := DOOR_HEAD + HEAD_LINING + 0.08
const Y_CABLE_TRAY := RIB_UNDERSIDE - 0.10  # tray top clears under the ribs

# ── THE HAND'S MOUNTING RULES — the editable reference wall ─────────────────
# Every constant above is the CODE's convention. The hand's convention lives
# in commons/data/prop_wall_rules.json, written by the prop reference wall
# (res://commons/scenes/prop_reference_wall.tscn — walk it, nudge a prop,
# F5). A token with a hand rule mounts at the hand's height everywhere;
# absent file or absent token, the code convention applies unchanged.
# V1 scope: one height per TOKEN — an exit_sign rule moves both the door
# and the portal sign.
const RULES_PATH := "res://commons/data/prop_wall_rules.json"
static var _hand_rules: Dictionary = {}
static var _hand_loaded: bool = false


## Every wall-hung token with its CODE default height. The reference wall
## reads this to know what to hang; the emitters read through _ruled_y.
static func mount_defaults() -> Dictionary:
	return {
		"fire_extinguisher": H_EXTINGUISHER,
		"emergency_button": H_ESTOP,
		"electrical_panel": H_PANEL,
		"palm_scanner": H_SCANNER,
		"wall_clock": H_CLOCK,
		"info_screen": H_SCREEN,
		"whiteboard": H_BOARD,
		"large_window": H_WINDOW,
		"fire_hose_box": H_HOSE_BOX,
		"exit_sign": Y_EXIT_WALL,
		"cable_tray": Y_CABLE_TRAY,
		# the rest of the wall class, rule-able since the corridor grew
		# zones (2026-08-14): defaults borrow the nearest band constant
		"mirror": H_WINDOW,
		"hangar_wall_panel": H_PANEL,
		"artifact_readout_screen": H_SCREEN,
	}


static func _ruled_y(token: String, code_y: float) -> float:
	if not _hand_loaded:
		_hand_loaded = true
		if FileAccess.file_exists(RULES_PATH):
			var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
			if doc is Dictionary and (doc as Dictionary).get("rules") is Dictionary:
				_hand_rules = (doc as Dictionary)["rules"]
				print("[em_props] %d hand mounting rule(s) from %s" % [_hand_rules.size(), RULES_PATH])
	var r: Variant = _hand_rules.get(token, null)
	if r is Dictionary and (r as Dictionary).has("h"):
		return float((r as Dictionary)["h"])
	return code_y

# ── DENSITY ──────────────────────────────────────────────────────────────────
## Of em_budget's wall-furniture licence, the share that buys SERVICE furniture.
## The rest stays with em_detail's hung showings — they are two families spending
## one measurement and neither may take all of it.
const PROP_SHARE := 0.40
const CORPUS_WALL_FEATURES := 2.2   # em_budget.CORPUS_WALL_FEATURES
## Below this rate the building's own text forbids service furniture outright.
const RATE_SILENT := 0.6            # teshima 0.3, sando 0.5
## Below this, one statutory sign and nothing else.
const RATE_STATUTORY_ONLY := 1.5    # chichu/katsura/mesdag 0.8, neue/libeskind 1.0
## These are real scenes with real _ready() work, unlike em_detail's boxes, so
## the ceiling is stated against the same three-live-segments arithmetic
## em_budget uses: 16 x 3 = 48 live prop instances alongside its 24 x 3 = 72
## artifacts, against a worst case of 96 that budget already accepts. 16 rather
## than 12 because eleven rules were measured competing for twelve places and
## the tail — the cable tray and the floor grate, both named in the brief —
## fired 3 and 0 times in thirty buildings. A cap that silently deletes a third
## of the rule set is a cap that lies about what the file does.
const MAX_PROPS_PER_SEGMENT := 16
const MAX_FLOOR_TAKEN := 3          # walk cells this module may ever surrender
const FLOOR_PROP_SPACING := 4       # cells between two floor-standing props
const GRATE_SPACING := 3

## QUOTAS, and the measurement that put them here. Without them the rules ran
## first-come-first-served against one total, and the first-come families ate
## it: over the 30 museum-tagged templates, floor grates took 66 placements and
## ceiling vents 56 — 45% of everything — while the wall-run features that this
## whole file exists to supply fired THREE times in thirty buildings and the
## backing panels never fired at all. A cap spent in arrival order is not a
## budget, it is a race. So each family gets a share of the segment's cap and
## the FEATURE family — the fittings that answer the bare-plaster crop — takes
## the remainder rather than the leftovers.
## Each family takes a fraction of the segment's cap, floored at nothing and
## ceilinged at what the family is actually for. The RULE ORDER below is the
## ranking when the total cap bites first: what a thin building keeps is the way
## out, the door, and the wall.
const Q: Dictionary = {
	"statutory": [0.25, 1, 4],      # the two exit signs and one door's pair
	"feature":   [0.25, 0, 4],      # the answer to the bare-plaster crop
	"gate":      [0.13, 0, 2],      # the lobby's own fittings
	"ceiling":   [0.13, 0, 2],      # vents
	"run":       [0.07, 0, 1],      # the cable tray, one per segment
	"edge":      [0.07, 0, 1],      # a floor grate
	"backing":   [0.07, 0, 1],      # a panel behind one podium
	"pocket":    [0.19, 0, 3],      # body-scale objects in dead corners
}

# ── CLASSES ──────────────────────────────────────────────────────────────────
const C_WALL := "wall"          # origin on a vertical plane, body faces +Z
const C_CEILING := "ceiling"    # origin at or near the soffit, body flat in XZ
const C_FLOOR := "floor"        # origin a bottom centre, stands on the deck
const C_EDGE := "edge"          # lies in the floor plane or hugs a wall base
const C_TABLETOP := "tabletop"  # bottom centre, body under ~0.6 m: needs lifting
const C_APERTURE := "aperture"  # a door leaf; belongs IN an opening, not on a wall
const C_EXHIBIT := "exhibit"    # a teaching artifact that happens to be in the
                                # props gallery — art, not furniture
const C_UNVERIFIED := "unverified"  # manifest dna and code exports disagree

## The catalogue. `by` names the signal that classified it (see the header):
## "origin" = the prop's own documented origin sentence, "dna" = a
## mounting-bearing export, "size" = a measured or declared body height,
## "identity" = the @identity block's own statement of what it is.
## `back`/`front` are metres of body behind and in front of the origin along the
## mounting normal, read off the exports, and they decide whether a wall prop
## clears the walker. Only the placed props carry them.
const CATALOGUE: Dictionary = {
	# ── WALL ─────────────────────────────────────────────────────────────────
	"exit_sign": {"class": C_WALL, "by": "origin",
		"why": "back face on the local plane at mount_offset_z; faces +Z, mount on a -Z wall",
		"back": 0.0, "front": 0.10},
	"electrical_panel": {"class": C_WALL, "by": "origin",
		"why": "origin at the CENTER OF THE PANEL BACK FACE, panel_depth 0.08",
		"back": 0.0, "front": 0.08},
	"emergency_button": {"class": C_WALL, "by": "dna",
		"why": "mounting = wall | podium; on wall the back of the plate is at z=0",
		"back": 0.0, "front": 0.10},
	"palm_scanner": {"class": C_WALL, "by": "dna",
		"why": "mounting = wall | podium; panel_depth 0.05",
		"back": 0.05, "front": 0.04},
	"wall_clock": {"class": C_WALL, "by": "origin",
		"why": "origin at the CENTER of the clock face, face points +Z; clock_depth 0.04",
		"back": 0.02, "front": 0.02},
	"info_screen": {"class": C_WALL, "by": "identity",
		"why": "wall-mounted display, faces +Z; frame_thickness 0.04, measured aabb z 0.05",
		"back": 0.0, "front": 0.09},
	"whiteboard": {"class": C_WALL, "by": "identity",
		"why": "board faces +Z, mount on a -Z wall; measured aabb 2.50 x 1.34 x 0.10",
		"back": 0.0, "front": 0.10},
	"large_window": {"class": C_WALL, "by": "identity",
		"why": "flat in the XY plane, faces +Z; frame_thickness 0.08",
		"back": 0.0, "front": 0.10},
	"fire_extinguisher": {"class": C_WALL, "by": "dna",
		"why": "wall_bracket; origin the cylinder base ON the mounting surface, bracket behind on -Z",
		"back": 0.0975, "front": 0.0625},
	"fire_hose_box": {"class": C_WALL, "by": "origin",
		"why": "origin the centre of the back face; box_depth 0.25 — deeper than the walker's clearance",
		"back": 0.0, "front": 0.25},
	"hangar_wall_panel": {"class": C_WALL, "by": "identity",
		"why": "origin at the floor, wall plane XY facing +Z, thin in Z; a backing for a thing to be against",
		"back": 0.0, "front": 0.14},
	"station_wall": {"class": C_WALL, "by": "dna",
		"why": "length_cells / height / panel_style / screen_slot — a wall module measured in floor cells"},
	"artifact_readout_screen": {"class": C_WALL, "by": "dna",
		"why": "manifest dna `mount` (stalk | wall_plate); measured 0.56 x 1.99 x 0.32 — 0.32 deep, exceeds clearance"},
	"mirror": {"class": C_WALL, "by": "identity",
		"why": "mirror_arrangement / mirror_count, but the origin is a BOTTOM CENTER — a standing mirror rig, not a hung glass"},
	# ── CEILING ──────────────────────────────────────────────────────────────
	"ceiling_vent": {"class": C_CEILING, "by": "origin",
		"why": "origin at the OPENING PLANE, recess extends UP into the ceiling (+Y); flat in XZ",
		"back": 0.0, "front": 0.0},
	"cable_tray": {"class": C_CEILING, "by": "origin",
		"why": "origin at the TRAY CENTER, extends +-X along tray_length, mount local +Y toward the ceiling",
		"back": 0.0, "front": 0.0},
	"station_luminaire": {"class": C_UNVERIFIED, "by": "dna",
		"why": "manifest declares mount / drop / fixture_style; the script exports mode / height / arm_reach. Declaration and code disagree — never placed"},
	# ── EDGE ─────────────────────────────────────────────────────────────────
	"floor_grate": {"class": C_EDGE, "by": "origin",
		"why": "origin at the CENTER OF THE TOP (WALKABLE) SURFACE, bars extend down — flush, walked over, costs no cell",
		"back": 0.0, "front": 0.0},
	"hangar_barrier_fence": {"class": C_EDGE, "by": "origin",
		"why": "posts on foot plates, origin at floor; height 1.1, panel_width 1.4 — it stops a body",
		"back": 0.0, "front": 0.0},
	"station_barrier": {"class": C_EDGE, "by": "dna",
		"why": "length_cells / rail_count / top_rail — a run of guarding measured in floor cells"},
	"station_handrail": {"class": C_EDGE, "by": "dna",
		"why": "length_cells / with_midrail / with_kickplate — a rail run"},
	"station_stair_run": {"class": C_EDGE, "by": "dna",
		"why": "rise_cells / step_count / going — floor-to-floor, and this corridor has one level"},
	"station_ladder": {"class": C_EDGE, "by": "dna",
		"why": "height_cells / rung_count / with_cage — climbs a wall this corridor has no top to"},
	"hangar_step_base": {"class": C_EDGE, "by": "identity",
		"why": "origin at the floor, rises a single step (<=0.35) you MOUNT — a walkable kerb, not an obstacle"},
	# ── FLOOR ────────────────────────────────────────────────────────────────
	"lab_stool": {"class": C_FLOOR, "by": "origin",
		"why": "origin the bottom centre of the base; seat_height 0.65, base_radius 0.32",
		"span": 0.64, "h": 0.72},
	"iv_stand": {"class": C_FLOOR, "by": "origin",
		"why": "origin the bottom centre; pole_height 1.6, base_radius 0.25",
		"span": 0.50, "h": 1.75},
	"clamp_stand": {"class": C_FLOOR, "by": "origin",
		"why": "origin the bottom centre; a rod on a weighted base",
		"span": 0.40, "h": 1.10},
	"gas_canister": {"class": C_FLOOR, "by": "origin",
		"why": "origin the bottom centre; canister_height 0.85, canister_radius 0.13",
		"span": 0.40, "h": 0.95},
	"safety_shower": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom-centre; a pipe and a pull chain"},
	"lab_sink": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER of the cabinet"},
	"server_rack": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom centre of the rack"},
	"metal_storage_cabinet": {"class": C_FLOOR, "by": "origin", "why": "origin the BASE CENTER on the floor"},
	"wooden_pallet": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER of the deck"},
	"push_cart": {"class": C_FLOOR, "by": "origin", "why": "origin at the floor, centred under the frame"},
	"hangar_podium": {"class": C_FLOOR, "by": "identity", "why": "origin at the floor; a pedestal an artifact stands ON"},
	"hangar_supply_pile": {"class": C_FLOOR, "by": "dna", "why": "crate_count / with_cylinder / with_cone — a heap on a floor"},
	"hangar_worktable": {"class": C_FLOOR, "by": "identity", "why": "origin at the floor; width x depth work surface"},
	"hangar_cabinet_cluster": {"class": C_FLOOR, "by": "identity", "why": "origin at the floor; unit_count cabinets in a row"},
	"large_table": {"class": C_FLOOR, "by": "origin", "why": "origin the centre of the floor footprint; height / length / depth"},
	"conveyor_belt": {"class": C_FLOOR, "by": "origin", "why": "origin the centre; belt_length / support_legs"},
	"fume_hood": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom centre of the front; hood_width x hood_depth"},
	"glove_box": {"class": C_FLOOR, "by": "origin", "why": "origin at floor level (bottom of legs); legs_visible"},
	"autoclave": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom centre; a chamber with a door"},
	"vacuum_chamber": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER"},
	"robot_arm": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom centre of the base"},
	"computer_console": {"class": C_FLOOR, "by": "origin", "why": "origin the BASE CENTER on the floor"},
	"station_console_desk": {"class": C_FLOOR, "by": "identity", "why": "origin at the floor; a desk with a switchboard"},
	"station_cabinet": {"class": C_FLOOR, "by": "dna", "why": "width_cells / depth / toe_kick — a carcass measured in floor cells"},
	"station_pillar": {"class": C_FLOOR, "by": "dna", "why": "post_width / height / cap_style — a post standing on the deck"},
	"station_plinth": {"class": C_FLOOR, "by": "dna", "why": "width_cells / depth_cells / top_height — a pedestal footprint"},
	"station_stage": {"class": C_FLOOR, "by": "dna", "why": "width_cells / depth_cells / step_height — a platform footprint"},
	"station_frame": {"class": C_FLOOR, "by": "dna", "why": "frame_width / frame_height / frame_depth — a portal frame on the deck"},
	"station_gantry": {"class": C_FLOOR, "by": "dna", "why": "span_cells / leg_mode / with_hoist — legs on the deck, span overhead"},
	"station_task_light": {"class": C_FLOOR, "by": "dna", "why": "post_height / clamp_style / reach — a task lamp on a post or a clamp"},
	"terrarium": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER; a tank on a stand"},
	"fishbowl": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER"},
	"pendulum": {"class": C_FLOOR, "by": "origin", "why": "origin the bottom centre; a swing needs headroom, not a bench"},
	"slide_projector": {"class": C_FLOOR, "by": "origin", "why": "origin the BOTTOM CENTER; beam_visible wants a room, not a table"},
	"monitor_setup": {"class": C_FLOOR, "by": "size", "why": "measured aabb 2.0 x 2.0 x 2.0 — a rig, not a desk object"},
	"work_station": {"class": C_FLOOR, "by": "identity", "why": "a bench assembly; it IS the surface others sit on"},
	"milk_triangle": {"class": C_FLOOR, "by": "identity", "why": "a floor-standing demonstration object"},
	"fluid_flag": {"class": C_FLOOR, "by": "identity", "why": "a mast and a cloth — floor-standing"},
	# ── TABLETOP: bottom-centre origin, body under ~0.6 m. NEVER placed here;
	# these are the artifacts the lifting pass exists for.
	"microscope": {"class": C_TABLETOP, "by": "size", "why": "measured height 0.40 m — 24% of the 1.65 m eye line"},
	"petri_dish": {"class": C_TABLETOP, "by": "size", "why": "a dish; lid_present / colony_density are read from above, close"},
	"test_tube_rack": {"class": C_TABLETOP, "by": "origin", "why": "origin the bottom-centre; a rack of tubes is a bench object"},
	"specimen_jar": {"class": C_TABLETOP, "by": "origin", "why": "origin the bottom-centre; jar_height default well under 0.5"},
	"chemistry_flask": {"class": C_TABLETOP, "by": "origin", "why": "origin the bottom centre; flask_height is a hand's span"},
	"bunsen_burner": {"class": C_TABLETOP, "by": "origin", "why": "origin the BOTTOM CENTER; it stands ON a bench, beside a flask"},
	"lock_box": {"class": C_TABLETOP, "by": "origin", "why": "origin the BOTTOM CENTER; dials are read at arm's length"},
	"computer_keyboard": {"class": C_TABLETOP, "by": "origin", "why": "origin the CENTER; a keyboard on a desk"},
	"oscilloscope": {"class": C_TABLETOP, "by": "size", "why": "measured 0.86 x 0.59 x 0.16 — an instrument on a bench"},
	"scales": {"class": C_TABLETOP, "by": "origin", "why": "origin the BOTTOM CENTER; a balance is read from above"},
	"probability_box": {"class": C_TABLETOP, "by": "origin", "why": "origin the bottom centre; dice are read close"},
	"kaleidoscope": {"class": C_TABLETOP, "by": "origin", "why": "origin the BOTTOM CENTER; held to the eye"},
	"abacus": {"class": C_TABLETOP, "by": "origin", "why": "origin the BOTTOM CENTER; beads are moved by hand"},
	"prism": {"class": C_TABLETOP, "by": "size", "why": "measured 1.0 m cube but its subject is a beam through glass — a bench demo"},
	# ── APERTURE: a leaf that belongs IN an opening. Placing one on a wall face
	# would seal a door the walker is planned through.
	"sliding_door": {"class": C_APERTURE, "by": "size", "why": "measured 3.5 x 2.5 x 0.2; panels_open_amount 0 seals a 4-cell opening"},
	"lead_safety_door": {"class": C_APERTURE, "by": "origin", "why": "origin the door's BOTTOM; a leaf, not a panel"},
	"station_door": {"class": C_APERTURE, "by": "dna", "why": "leaf_mode / open_amount / with_threshold_light — a leaf in an opening"},
	# ── EXHIBIT: art that happens to be in the props gallery. The corridor
	# already deals these through the spine pool; dealing them again as
	# furniture would double-count the curriculum.
	"cantor_diagonal_workbench": {"class": C_EXHIBIT, "by": "identity", "why": "a teaching bench; initial_n is a curriculum parameter"},
	"riemann_sum_workbench": {"class": C_EXHIBIT, "by": "identity", "why": "a teaching bench; initial_n"},
	"shannon_workbench": {"class": C_EXHIBIT, "by": "identity", "why": "a teaching bench; initial_p"},
	"tangent_slope_workbench": {"class": C_EXHIBIT, "by": "identity", "why": "a teaching bench; initial_x"},
	"triangle_curvature_workbench": {"class": C_EXHIBIT, "by": "identity", "why": "a teaching bench; initial_k"},
	"curation_station": {"class": C_EXHIBIT, "by": "identity", "why": "a composer of whole rooms — 29 dna keys including `artifacts`"},
	"control_console": {"class": C_EXHIBIT, "by": "identity", "why": "houses a teaching machine's own controls (demo_apparatus)"},
	"map_table": {"class": C_EXHIBIT, "by": "identity", "why": "grid_visible / path_visible — a pathfinding exhibit"},
}

## Every prop this module is willing to STAMP, in priority order. Everything else
## in the catalogue is classified for the next pass and refused by this one.
const PLACEABLE: Array = ["exit_sign", "fire_extinguisher", "emergency_button",
	"ceiling_vent", "cable_tray", "floor_grate", "electrical_panel",
	"palm_scanner", "wall_clock", "info_screen", "whiteboard", "large_window",
	"hangar_wall_panel", "fire_hose_box", "lab_stool", "iv_stand", "clamp_stand",
	"gas_canister", "hangar_barrier_fence"]


# ═══════════════════════════════════════════════════════════════════════════
# THE CONTRACT
# ═══════════════════════════════════════════════════════════════════════════

## Dress one streamed segment with service furniture.
##
## seg        the segment Node3D. Read only — this function never adds a child.
##            Passed so the caller's call site matches every other em_* module
##            and so a future debug pass can hang a marker off it.
## tile       the template rows, cell codes "1" / "1s" / "2" / "2s" / "3s" / "4".
## w, h       the tile's declared width and height in cells. The tile occupies
##            local z from VESTIBULE_H to VESTIBULE_H + h.
## allowance  OPTIONAL, fully defaulted, and normally em_budget.for_segment()
##            handed straight through. Keys read:
##              wall_features_per_10m  the building's own service rate
##              props_per_10m          overrides the derived share
##              wall_run_m             em_budget's measure; else measured here
##              fill_walls             may non-slot walls carry furniture
##              max_objects/artworks   the artwork budget props may not outnumber
##              prev_w                 the previous segment's width
##              live                   lookup -> anything. A token absent from
##                                     this dictionary is DROPPED. Pass the
##                                     host's `_live` and nothing unresolvable
##                                     can ever be emitted.
## mats       accepted and unused. Props are real scenes and carry their own
##            materials; the host's material library dresses architecture only.
##
## Returns an Array of placement Dictionaries:
##   token           registry lookup name — the host resolves the scene
##   cell            Vector2i(x, z) in SEGMENT-LOCAL cells, vestibule included
##   surface         "wall" | "ceiling" | "floor" | "edge"
##   pos             Vector3 for node.position, segment-local, exact
##   rot_y           degrees about Y. Every prop here faces its own local +Z
##   config          export overrides, keys taken from the script's own @export
##   occupies_floor  TRUE means the host MUST erase _walk_cells[(x, zbase + z)]
##                   before the walker plans. FALSE means the placement is above
##                   or flush with the walked plane and costs nothing
##   why             the geometry this placement keys off, in words
##   rule            the rule id, so a report can group them
@warning_ignore("unused_parameter")
static func dress(seg: Node3D, tile: Array, w: int, h: int,
		allowance: Dictionary = {}, mats = null) -> Array:
	var out: Array = []
	if tile.is_empty() or w <= 0:
		return out
	if h <= 0:
		h = tile.size()

	# ── the allowance, resolved before any geometry work ────────────────────
	var geo: Dictionary = _geometry(tile, w, h, int(allowance.get("prev_w", -1)))
	var run_m: float = float(allowance.get("wall_run_m", 0.0))
	if run_m <= 0.0:
		run_m = float(geo["perimeter_m"])
	var wf_rate: float = float(allowance.get("wall_features_per_10m", CORPUS_WALL_FEATURES))
	var rate: float = float(allowance.get("props_per_10m", wf_rate * PROP_SHARE))
	var statutory_only: bool = false
	var cap: int = 0
	if wf_rate < RATE_SILENT:
		cap = 0
	elif wf_rate < RATE_STATUTORY_ONLY:
		cap = 1
		statutory_only = true
	else:
		cap = int(round(run_m * 0.1 * rate))
	cap = clampi(cap, 0, MAX_PROPS_PER_SEGMENT)
	var artworks: int = int(allowance.get("artworks", 0))
	if artworks <= 0:
		artworks = int(allowance.get("max_objects", 0))
	if artworks <= 0:
		artworks = int(geo["slot_count"])
	cap = mini(cap, artworks)          # props never outnumber the art
	if cap <= 0:
		return out
	var fill_walls: bool = bool(allowance.get("fill_walls", true))
	var live: Dictionary = allowance.get("live", {})

	# ── the rules, in the order they are allowed to spend the cap ───────────
	var quota: Dictionary = {}
	for fam in Q:
		var spec: Array = Q[fam]
		quota[str(fam)] = clampi(int(round(float(cap) * float(spec[0]))),
			mini(int(spec[1]), cap), int(spec[2]))
	var state: Dictionary = {"cap": cap, "floor_taken": 0, "used_cells": {},
		"live": live, "counts": {}, "quota": quota, "spent": {}}

	# ── RULE ORDER IS THE RANKING ──────────────────────────────────────────
	# Under the cap, what comes first survives. The order is the order the
	# critique named: the way out, the door, then the wall — and only then the
	# services overhead and underfoot, which are atmosphere rather than answer.
	_rule_exit_portal(out, state, w)
	if not statutory_only:
		_rule_exit_endwall(out, state, geo)
		_rule_door_furniture(out, state, geo)
		if fill_walls:
			_rule_wall_run_features(out, state, geo)
		_rule_lobby_gate(out, state, geo, w)
		_rule_ceiling_vents(out, state, geo, w, h)
		_rule_cable_tray(out, state, geo)
		_rule_floor_grates(out, state, geo, h)
		if fill_walls:
			_rule_backing_panels(out, state, geo)
			_rule_hose_box(out, state, geo)
		_rule_floor_pockets(out, state, geo)
	if seg != null:
		# a debug hook, not a placement: the segment can report what it was
		# offered without this file ever adding a child to it.
		seg.set_meta("em_props_offered", out.size())
	return out


## The classification table, so a report or a gate reads the same words this
## file placed by. Returns a COPY — a const Dictionary handed out by reference
## is a const nobody can trust.
static func catalogue() -> Dictionary:
	var out: Dictionary = {}
	for k in CATALOGUE:
		var row: Dictionary = CATALOGUE[k]
		out[str(k)] = row.duplicate()
	return out


## How many of the catalogue's tokens actually resolve against the host's living
## registry. `live` is endless_museum's `_live`: lookup -> {scene, fp}, already
## filtered to map_ready + on disk. Returns
## {total, resolved, missing: Array, placeable_resolved, placeable_missing}.
static func resolve_report(live: Dictionary) -> Dictionary:
	var missing: Array = []
	var resolved: int = 0
	var keys: Array = CATALOGUE.keys()
	keys.sort()
	for k in keys:
		if live.has(str(k)):
			resolved += 1
		else:
			missing.append(str(k))
	var p_res: int = 0
	var p_missing: Array = []
	for t in PLACEABLE:
		if live.has(str(t)):
			p_res += 1
		else:
			p_missing.append(str(t))
	return {"total": keys.size(), "resolved": resolved, "missing": missing,
		"placeable": PLACEABLE.size(), "placeable_resolved": p_res,
		"placeable_missing": p_missing}


# ═══════════════════════════════════════════════════════════════════════════
# GEOMETRY — everything below is derived from the tile, deterministically
# ═══════════════════════════════════════════════════════════════════════════

## The graph the generator already owns, gathered once. Mirrors em_detail's own
## occupancy pass exactly (_map_vestibule / _map_tile / _dressed_faces) so the
## two files cannot disagree about where a wall is; adds the door list, the
## portal, the slot list and the walker's own route.
static func _geometry(tile: Array, w: int, h: int, prev_w: int) -> Dictionary:
	var walls: Dictionary = {}
	var floors: Dictionary = {}
	# the lobby: floor across the full LOBBY_W, side walls both edges, closing
	# strips where a width jump is sealed
	for zr in range(VESTIBULE_H):
		for x in range(LOBBY_W):
			floors[Vector2i(x, zr)] = true
		walls[Vector2i(0, zr)] = true
		walls[Vector2i(LOBBY_W - 1, zr)] = true
	for x1 in range(maxi(w - 1, 0), LOBBY_W):
		walls[Vector2i(x1, VESTIBULE_H - 1)] = true
	if prev_w > 0:
		for x2 in range(maxi(prev_w - 1, 0), LOBBY_W):
			walls[Vector2i(x2, 0)] = true
	# the tile, plus the outer skin the host stamps at x = -1 and x = w
	var slots: Array = []
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		var z: int = y + VESTIBULE_H
		walls[Vector2i(-1, z)] = true
		walls[Vector2i(w, z)] = true
		for x in range(row.size()):
			var c: String = str(row[x])
			if c == "4":
				walls[Vector2i(x, z)] = true
			elif c == "1" or c == "1s":
				floors[Vector2i(x, z)] = true
			if c == "1s":
				slots.append({"x": x, "z": z, "rank": 2})
			elif c == "2s":
				slots.append({"x": x, "z": z, "rank": 1})
			elif c == "3s":
				slots.append({"x": x, "z": z, "rank": 0})

	var faces: Array = _dressed_faces(walls, floors)
	return {
		"walls": walls,
		"floors": floors,
		"faces": faces,
		"runs": _runs_of(faces),
		"doors": _doors(walls, floors, w, h),
		"slots": slots,
		"slot_count": slots.size(),
		"path": _walker_path(floors, w, h),
		"perimeter_m": _perimeter_m(tile),
		"w": w,
		"h": h,
	}


## Every wall face that actually fronts a floor cell, sorted, as
## {x, z, along_x, cell, nx, nz} — the same record em_detail derives, because a
## prop and a skirting board have to agree about what a wall face is.
static func _dressed_faces(walls: Dictionary, floors: Dictionary) -> Array:
	var out: Array = []
	var dirs: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var cells: Array = walls.keys()
	cells.sort_custom(func(a, b):
		var av: Vector2i = a
		var bv: Vector2i = b
		if av.y != bv.y:
			return av.y < bv.y
		return av.x < bv.x)
	for key in cells:
		var cell: Vector2i = key
		for d in dirs:
			var dv: Vector2i = d
			var nb := Vector2i(cell.x + dv.x, cell.y + dv.y)
			if walls.has(nb):
				continue
			if not floors.has(nb):
				continue
			out.append({
				"x": float(cell.x) + 0.5 + float(dv.x) * 0.5,
				"z": float(cell.y) + 0.5 + float(dv.y) * 0.5,
				"along_x": dv.y != 0,
				"cell": cell,
				"front": nb,               # the floor cell this face looks into
				"nx": float(dv.x),
				"nz": float(dv.y),
			})
	return out


## Faces grouped into RUNS: same plane, same outward normal, contiguous. A run is
## where a service fitting is allowed to be, and its ENDS are where one belongs —
## em_detail centres its hung showings inside a stretch, so taking the ends keeps
## the two families off each other without either needing to know the other ran.
static func _runs_of(faces: Array) -> Array:
	var groups: Dictionary = {}
	for f in faces:
		var fd: Dictionary = f
		var along_x: bool = bool(fd["along_x"])
		var fixed: float = float(fd["z"]) if along_x else float(fd["x"])
		var key: String = "%s|%.1f|%.0f|%.0f" % [str(along_x), fixed,
			float(fd["nx"]), float(fd["nz"])]
		if not groups.has(key):
			groups[key] = []
		var bucket: Array = groups[key]
		bucket.append(fd)
	var out: Array = []
	var gk: Array = groups.keys()
	gk.sort()
	for k in gk:
		var bucket2: Array = groups[k]
		bucket2.sort_custom(func(a, b):
			var ad: Dictionary = a
			var bd: Dictionary = b
			var au: float = float(ad["x"]) if bool(ad["along_x"]) else float(ad["z"])
			var bu: float = float(bd["x"]) if bool(bd["along_x"]) else float(bd["z"])
			return au < bu)
		var cur: Array = []
		var last: float = -999.0
		for f2 in bucket2:
			var fd2: Dictionary = f2
			var u: float = float(fd2["x"]) if bool(fd2["along_x"]) else float(fd2["z"])
			if not cur.is_empty() and absf(u - last) > 1.01:
				out.append(cur)
				cur = []
			cur.append(fd2)
			last = u
		if not cur.is_empty():
			out.append(cur)
	return out


## Genuine door openings: a gap of 1..MAX_DOOR_CELLS floor cells through a wall
## run, walled at both ends, clear on both flanks, the jambs not corridor cheeks.
## The rule is em_detail._add_doors verbatim, because a fire extinguisher beside
## a door and a lined reveal at that door have to mean the same door.
static func _doors(walls: Dictionary, floors: Dictionary, w: int, h: int) -> Array:
	var out: Array = []
	var x_lo: int = -2
	var x_hi: int = maxi(LOBBY_W, w + 1)
	var z_hi: int = VESTIBULE_H + h - 1
	for z in range(0, z_hi + 1):
		if z == VESTIBULE_H - 1:
			continue                       # the monumental threshold, not a door
		var x: int = x_lo
		while x <= x_hi:
			if walls.has(Vector2i(x, z)) or not floors.has(Vector2i(x, z)):
				x += 1
				continue
			var s: int = x
			while x <= x_hi and not walls.has(Vector2i(x, z)) and floors.has(Vector2i(x, z)):
				x += 1
			var e: int = x - 1
			if e - s + 1 > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(s - 1, z)) or not walls.has(Vector2i(e + 1, z)):
				continue
			if _pier_through(walls, Vector2i(s - 1, z), true):
				continue
			if _pier_through(walls, Vector2i(e + 1, z), true):
				continue
			var clear: bool = true
			for xx in range(s, e + 1):
				if walls.has(Vector2i(xx, z - 1)) or walls.has(Vector2i(xx, z + 1)):
					clear = false
					break
			if not clear:
				continue
			out.append({"along_x": true, "z": z, "s": s, "e": e,
				"jamb_a": Vector2i(s - 1, z), "jamb_b": Vector2i(e + 1, z)})
	for x2 in range(x_lo, x_hi + 1):
		var z2: int = 0
		while z2 <= z_hi:
			if walls.has(Vector2i(x2, z2)) or not floors.has(Vector2i(x2, z2)):
				z2 += 1
				continue
			var s2: int = z2
			while z2 <= z_hi and not walls.has(Vector2i(x2, z2)) and floors.has(Vector2i(x2, z2)):
				z2 += 1
			var e2: int = z2 - 1
			if e2 - s2 + 1 > MAX_DOOR_CELLS:
				continue
			if not walls.has(Vector2i(x2, s2 - 1)) or not walls.has(Vector2i(x2, e2 + 1)):
				continue
			if _pier_through(walls, Vector2i(x2, s2 - 1), false):
				continue
			if _pier_through(walls, Vector2i(x2, e2 + 1), false):
				continue
			var clear2: bool = true
			for zz in range(s2, e2 + 1):
				if walls.has(Vector2i(x2 - 1, zz)) or walls.has(Vector2i(x2 + 1, zz)):
					clear2 = false
					break
			if not clear2:
				continue
			out.append({"along_x": false, "x": x2, "s": s2, "e": e2,
				"jamb_a": Vector2i(x2, s2 - 1), "jamb_b": Vector2i(x2, e2 + 1)})
	return out


static func _pier_through(walls: Dictionary, p: Vector2i, wall_runs_x: bool) -> bool:
	if wall_runs_x:
		return walls.has(Vector2i(p.x, p.y - 1)) and walls.has(Vector2i(p.x, p.y + 1))
	return walls.has(Vector2i(p.x - 1, p.y)) and walls.has(Vector2i(p.x + 1, p.y))


## The walker's own route, planned the way the autopilot plans it: a BFS over
## floor cells from the portal opening to the deepest reachable row. A floor
## prop is forbidden from standing on any cell of this, so the route the gate
## walks is the one route this module never touches.
static func _walker_path(floors: Dictionary, w: int, h: int) -> Dictionary:
	var start: Vector2i = Vector2i(-1, -1)
	for x in range(1, maxi(w - 1, 2)):
		var c := Vector2i(x, VESTIBULE_H)
		if floors.has(c):
			start = c
			break
	if start.x < 0:
		return {}
	var prev: Dictionary = {}
	var seen: Dictionary = {}
	seen[start] = true
	var q: Array = [start]
	var qi: int = 0
	var deepest: Vector2i = start
	var dirs: Array = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]
	while qi < q.size():
		var cur: Vector2i = q[qi]
		qi += 1
		if cur.y > deepest.y:
			deepest = cur
		for d in dirs:
			var dv: Vector2i = d
			var n := Vector2i(cur.x + dv.x, cur.y + dv.y)
			if n.y < VESTIBULE_H or n.y >= VESTIBULE_H + h:
				continue
			if not floors.has(n) or seen.has(n):
				continue
			seen[n] = true
			prev[n] = cur
			q.append(n)
	var path: Dictionary = {}
	var node: Vector2i = deepest
	var guard: int = 0
	while guard < 4096:
		guard += 1
		path[node] = true
		if not prev.has(node):
			break
		node = prev[node]
	return path


## em_budget's own measure, reproduced so this file's rate is spent against the
## same denominator the rate was written for: every edge of a walkable cell
## whose neighbour is not walkable.
static func _perimeter_m(tile: Array) -> float:
	var m: float = 0.0
	for y in range(tile.size()):
		if not (tile[y] is Array):
			continue
		var row: Array = tile[y]
		for x in range(row.size()):
			if not _is_walk(tile, x, y):
				continue
			if not _is_walk(tile, x + 1, y):
				m += 1.0
			if not _is_walk(tile, x - 1, y):
				m += 1.0
			if not _is_walk(tile, x, y + 1):
				m += 1.0
			if not _is_walk(tile, x, y - 1):
				m += 1.0
	return m


static func _is_walk(tile: Array, x: int, y: int) -> bool:
	if y < 0 or y >= tile.size() or not (tile[y] is Array):
		return false
	var row: Array = tile[y]
	if x < 0 or x >= row.size():
		return false
	var c: String = str(row[x])
	return c == "1" or c == "1s"


# ═══════════════════════════════════════════════════════════════════════════
# THE RULES. Every one names the geometry it keys off in its own `why`.
# ═══════════════════════════════════════════════════════════════════════════

## R1 — EXIT SIGN OVER THE THRESHOLD.
## Geometry key: the portal. em_detail._add_portal stamps a head lining across
## x in [1, w-1] at cell row VESTIBULE_H - 1, topping out at PORTAL_HEAD +
## PORTAL_HEAD_LINING = 2.56, with solid wall above it to 3.00. A 0.18 m sign
## centred at 2.72 sits inside that overpanel — over the way through, and above
## the 2.40 opening the axial vista is composed on, so it cannot repeat the
## banner's mistake of standing on the vanishing point.
## The only fitting a building at the statutory rate is still allowed.
static func _rule_exit_portal(out: Array, state: Dictionary, w: int) -> void:
	if w < 4:
		return
	var mid: float = (1.0 + float(w - 1)) * 0.5
	var z: float = float(VESTIBULE_H - 1) + 0.5
	_emit(out, state, "exit_sign",
		Vector2i(int(mid), VESTIBULE_H - 1),
		Vector3(mid, Y_EXIT_PORTAL, z - 0.5), 180.0, "wall", false,
		{"text": "EXIT", "arrow_direction": "none"},
		"over the portal opening (em_detail head lining tops at 2.56, wall to 3.00), facing back down the lobby",
		"R1-exit-portal", "statutory")


## R2 — DOOR FURNITURE.
## Geometry key: the door list — a gap of 1..3 floor cells through a wall run
## with walls at both ends and clear flanks, found by em_detail._add_doors'
## exact test. One jamb takes the extinguisher, the other takes the E-stop, so
## the pair reads as a door and not as decoration.
## THE RADIUS NOTE, and the one measurement that decided it. At its shipped
## defaults the extinguisher is 0.185 m proud — BRACKET_DEPTH 0.035 behind the
## origin plus 2 x extinguisher_radius 0.075 in front — against a walker
## clearance of exactly 0.180. It grazes. Demoting it to a floor stander (the
## bench rule) was tried and measured: it fired ZERO times in thirty museum
## templates, because the cells beside a door are almost always ON the walker's
## own route, which that rule correctly refuses. A rule that never fires is not
## a conservative rule, it is a missing one. So the placement asks for
## extinguisher_radius 0.0625 instead — a 125 mm body, an ordinary 2 kg unit —
## which puts it 0.160 m proud, inside the clearance, hung on the wall where it
## belongs and costing no cell. The artifact's own default is untouched: this is
## a config on one instance, not an edit to a scene with 302 placements.
static func _rule_door_furniture(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var doors: Array = geo["doors"]
	# ONE door, both of its jambs. A pair reads as a door; the same two fittings
	# spread over two doors read as litter.
	var n: int = 0
	for d in doors:
		if n >= 1:
			return
		var dd: Dictionary = d
		var a: Vector2i = dd["jamb_a"]
		var b: Vector2i = dd["jamb_b"]
		# the door's own centre, so each jamb offers the face that looks at the
		# opening rather than whichever face of that wall cell came first
		var mid: Vector2 = _door_centre(dd)
		var fa: Dictionary = _face_on(geo, a, mid)
		var fb: Dictionary = _face_on(geo, b, mid)
		var did: bool = false
		if not fb.is_empty():
			did = _emit_wall(out, state, "emergency_button", fb, H_ESTOP,
				{"mounting": "wall", "pressed": false},
				"on the far jamb of a door opening (em_detail door test: 1..3 cell gap, walls both ends, flanks clear)",
				"R2-estop-jamb", "statutory") or did
		if not fa.is_empty():
			did = _emit_wall(out, state, "fire_extinguisher", fa, H_EXTINGUISHER,
				{"wall_bracket": true, "hose_visible": true, "support": "bracket",
					"extinguisher_radius": 0.0625},
				"beside the near jamb of the same door, base at 1.10 m, sized to clear the walker (see the radius note)",
				"R2-extinguisher-jamb", "statutory") or did
		if did:
			n += 1


## R3 — THE FAR EXIT SIGN.
## Geometry key: the deepest wall face in the tile whose outward normal points
## back down the corridor (nz = -1) — the wall the walker is looking at as the
## museum ends. The arrow points at whichever side of that wall the walker's own
## BFS route leaves through, so the sign is derived from the route, not guessed.
static func _rule_exit_endwall(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var faces: Array = geo["faces"]
	var best: Dictionary = {}
	for f in faces:
		var fd: Dictionary = f
		if float(fd["nz"]) > -0.5:
			continue
		if best.is_empty() or float(fd["z"]) > float(best["z"]):
			best = fd
	if best.is_empty():
		return
	var path: Dictionary = geo["path"]
	var exit_x: float = float(best["x"])
	for k in path:
		var c: Vector2i = k
		if float(c.y) + 0.5 > float(best["z"]):
			exit_x = float(c.x) + 0.5
	var arrow: String = "none"
	if exit_x < float(best["x"]) - 0.6:
		arrow = "left"
	elif exit_x > float(best["x"]) + 0.6:
		arrow = "right"
	_emit_wall(out, state, "exit_sign", best, Y_EXIT_WALL,
		{"text": "EXIT", "arrow_direction": arrow},
		"the deepest wall face facing back down the corridor; the arrow follows the walker's own BFS route out",
		"R3-exit-endwall", "statutory")


## R4 — CEILING VENTS.
## Geometry key: em_detail's coffered ceiling. Solid panels of BAY - SLOT_W =
## 2.45 m on a 3.0 m module from z = 0, with a 0.55 m OPEN daylight slot between
## them, and longitudinal ribs at every x = 0, 3, 6 ... A vent has to be in a
## PANEL — a vent floating in an open slot is a vent in a hole — so its z is
## pinned to the middle of a panel and its x kept a half vent-width clear of a
## rib. Origin at the opening plane, so y is the soffit exactly and the recess
## goes up into the 0.26 m slab.
static func _rule_ceiling_vents(out: Array, state: Dictionary, geo: Dictionary, w: int, h: int) -> void:
	var z_end: float = float(VESTIBULE_H + h)
	var placed: int = 0
	var k: int = 1                                  # skip the lobby bay
	while placed < 3:
		var z0: float = float(k) * BAY
		if z0 + 0.4 >= z_end:
			return
		var zc: float = z0 + (BAY - SLOT_W) * 0.5   # middle of the solid panel
		var x: float = float(w) * 0.25
		# keep 0.20 (vent half-width) + 0.10 (rib half-width) off any rib line
		var to_rib: float = absf(x - round(x / BAY) * BAY)
		if to_rib < 0.30:
			x += 0.45
		var cell := Vector2i(int(x), int(zc))
		if geo["floors"].has(cell):
			var ok: bool = _emit(out, state, "ceiling_vent", cell,
				Vector3(x, CEIL_SOFFIT, zc), 0.0, "ceiling", false,
				{"vent_length": 0.9, "vent_width": 0.4, "slat_count": 8},
				"in the middle of a solid ceiling panel (3.0 m bay, 2.45 m panel, 0.55 m open slot), clear of the ribs at x = 0, 3, 6",
				"R4-ceiling-vent", "ceiling")
			if ok:
				placed += 1
		k += 2                                       # every other bay
		if float(k) * BAY > z_end:
			return


## R5 — THE CABLE TRAY.
## Geometry key: the walker's own BFS route. Its longest straight run in z is
## the corridor, by definition — that is what the walker walks — so the tray runs
## along it, which is what a service run in a real building does. Hung at 2.86,
## which is under em_lighting's sky plane at 2.92 and well under the rib
## underside at 2.96, so it is in the air the ceiling left empty. Rotated 90 deg
## because the tray's own length axis is local X.
static func _rule_cable_tray(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var path: Dictionary = geo["path"]
	if path.is_empty():
		return
	var by_x: Dictionary = {}
	for k in path:
		var c: Vector2i = k
		if not by_x.has(c.x):
			by_x[c.x] = []
		var col: Array = by_x[c.x]
		col.append(c.y)
	var best_x: int = -1
	var best_z0: int = 0
	var best_len: int = 0
	var xs: Array = by_x.keys()
	xs.sort()
	for xk in xs:
		var col2: Array = by_x[xk]
		col2.sort()
		var run: int = 1
		var z0: int = int(col2[0])
		for i in range(1, col2.size()):
			if int(col2[i]) == int(col2[i - 1]) + 1:
				run += 1
			else:
				run = 1
				z0 = int(col2[i])
			if run > best_len:
				best_len = run
				best_x = int(xk)
				best_z0 = int(col2[i]) - run + 1
	if best_len < 4 or best_x < 0:
		return
	var x: float = float(best_x) + 0.5
	var to_rib: float = absf(x - round(x / BAY) * BAY)
	if to_rib < 0.19:            # rib half 0.10 + tray half-width 0.09
		x += 0.30
	var length: float = float(best_len) - 0.5
	var zc: float = float(best_z0) + float(best_len) * 0.5
	_emit(out, state, "cable_tray", Vector2i(best_x, int(zc)),
		Vector3(x, Y_CABLE_TRAY, zc), 90.0, "ceiling", false,
		{"tray_length": length, "rung_count": maxi(4, int(length * 4.0))},
		"along the longest straight z-run of the walker's own BFS route (%d cells), hung at 2.86 under the sky plane at 2.92" % best_len,
		"R5-cable-tray", "run")


## R6 — FLOOR GRATES.
## Geometry key (a): the OPEN daylight slots in em_detail's ceiling. Panels run
## 2.45 m on a 3.0 m module from z = 0, so the open 0.55 m falls at
## z in [3k + 2.45, 3k + 3.0] and lands in floor cell row 3k + 2. The sun comes
## through there in bands; a porous floor under a porous ceiling is where a
## grate belongs, and it is the one place in the room where a thing at ankle
## height is lit well enough to read.
## Geometry key (b): the stop pocket in front of a hero plinth, under
## em_lighting's HeroKey — a 24 deg cone throwing a 0.9 m pool.
## Costs NO walk cell: the grate's origin is the centre of its top WALKABLE
## surface and its bars hang below the floor plane. You walk over it.
static func _rule_floor_grates(out: Array, state: Dictionary, geo: Dictionary, h: int) -> void:
	var path: Dictionary = geo["path"]
	var placed: int = 0
	var last_z: int = -99
	var z: int = VESTIBULE_H
	while z < VESTIBULE_H + h and placed < 3:
		if z % 3 == 2 and z - last_z >= GRATE_SPACING:
			var hit := Vector2i(-1, -1)
			for k in path:
				var c: Vector2i = k
				if c.y == z:
					if hit.x < 0 or c.x < hit.x:
						hit = c
			if hit.x >= 0:
				var ok: bool = _emit(out, state, "floor_grate", hit,
					Vector3(float(hit.x) + 0.5, FLOOR_TOP, float(hit.y) + 0.5),
					0.0, "edge", false,
					{"bar_count_x": 8, "bar_count_z": 8, "wear_factor": 0.25},
					"under an open daylight slot in the coffered ceiling (panel 2.45 of a 3.0 bay, so the slot lands in cell row z = 3k+2)",
					"R6-grate-daylight", "edge")
				if ok:
					placed += 1
					last_z = z
		z += 1
	if placed >= 2:
		return
	for s in geo["slots"]:
		var sd: Dictionary = s
		if int(sd["rank"]) != 0:
			continue
		var pocket := Vector2i(int(sd["x"]), int(sd["z"]) - 1)
		if not geo["floors"].has(pocket):
			continue
		if not _emit(out, state, "floor_grate", pocket,
				Vector3(float(pocket.x) + 0.5, FLOOR_TOP, float(pocket.y) + 0.5),
				0.0, "edge", false,
				{"bar_count_x": 10, "bar_count_z": 10, "wear_factor": 0.4},
				"the stop pocket in front of a hero plinth, under em_lighting's HeroKey (24 deg cone, ~0.9 m pool)",
				"R6-grate-heropocket", "edge"):
			continue
		return


## R7 — THE LOBBY GATE.
## Geometry key: the vestibule's own side walls, stamped by the host at x = 0 and
## x = LOBBY_W - 1 for all four rows, facing into the lobby. That lobby is the
## one room in the segment with no art in it and no slots — it is circulation, so
## it takes the circulation fittings: the breaker panel that runs the building
## and the scanner beside the way in. The panel's door is forced shut because an
## open one swings 90 deg about its left edge and stands 0.45 m into the room.
static func _rule_lobby_gate(out: Array, state: Dictionary, geo: Dictionary, w: int) -> void:
	if w < 4:
		return                            # no portal, so no gate to stand beside
	var walls: Dictionary = geo["walls"]
	var east: bool = walls.has(Vector2i(LOBBY_W - 1, 1))
	if walls.has(Vector2i(0, 1)):
		_emit(out, state, "electrical_panel", Vector2i(0, 1),
			Vector3(1.0, H_PANEL, 1.5), 90.0, "wall", false,
			{"door_open": false, "breaker_count": 12, "breakers_on_count": 9},
			"the vestibule's west side wall (host stamps x = 0 for all VESTIBULE_H rows) — circulation, no art on it",
			"R7-lobby-panel", "gate")
	if east:
		# the face is at x = LOBBY_W - 1; the scanner's origin is the centre of
		# its panel face, so it is set back by its own 0.05 m depth
		var x: float = float(LOBBY_W - 1) - 0.05
		_emit(out, state, "palm_scanner", Vector2i(LOBBY_W - 1, 2),
			Vector3(x, H_SCANNER, 2.5), -90.0, "wall", false,
			{"mounting": "wall", "scan_active": true},
			"the vestibule's east side wall beside the threshold — a hand offered at the way in",
			"R7-lobby-scanner", "gate")


## R8 — THE WALL RUN FEATURES. The direct answer to the 2 m2 crop.
## Geometry key: wall RUNS — contiguous faces sharing a plane and an outward
## normal. em_detail centres its hung showings INSIDE a stretch, one per 2 m; so
## this rule takes the run's END faces, where services cluster in a real building
## and where a picture never hangs. Four fittings cycle by run index, so a long
## enfilade does not repeat one object down its whole length, and each sits at
## its own height — 1.30, 1.55, 1.70, 2.25 — none of them the 1.58 hang centre.
static func _rule_wall_run_features(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var runs: Array = geo["runs"]
	var i: int = -1
	for r in runs:
		var run: Array = r
		if run.size() < 3:
			continue
		i += 1
		var pick: int = i % 4
		var f: Dictionary = run[0] if (i % 2) == 0 else run[run.size() - 1]
		var token: String = "wall_clock"
		var y: float = H_CLOCK
		var cfg: Dictionary = {"is_digital": false}
		if pick == 1:
			token = "info_screen"
			y = H_SCREEN
			cfg = {"header_text": "GALLERY", "text_size": 18}
		elif pick == 2:
			if run.size() < 4:
				continue
			token = "whiteboard"
			y = H_BOARD
			cfg = {"show_tray": true}
			f = run[run.size() / 2]
		elif pick == 3:
			if run.size() < 4:
				continue
			token = "large_window"
			y = H_WINDOW
			cfg = {"accent_strip": true}
			f = run[run.size() / 2]
		_emit_wall(out, state, token, f, y, cfg,
			"on a wall run of %d faces, at the %s where em_detail's stretch-centred showings never land" % [
				run.size(), "end" if pick < 2 else "middle"],
			"R8-wall-run", "feature")
		if int(state["cap"]) <= out.size():
			return


## R9 — BACKING PANELS.
## Geometry key: a wall face whose facing cell is a PODIUM ("2s"), not a floor
## cell. Two things follow. The artifact dealt onto that podium gets a surface to
## be against instead of floating in front of plaster, which is the panel's own
## stated reason to exist; and because the cell in front is not walkable, the
## panel's depth cannot graze anybody, so a 0.14 m fitting is safe where it would
## not be on a corridor wall.
static func _rule_backing_panels(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var walls: Dictionary = geo["walls"]
	var placed: int = 0
	for s in geo["slots"]:
		if placed >= 2:
			return
		var sd: Dictionary = s
		if int(sd["rank"]) != 1:
			continue
		var sx: int = int(sd["x"])
		var sz: int = int(sd["z"])
		for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var dv: Vector2i = d
			var wc := Vector2i(sx + dv.x, sz + dv.y)
			if not walls.has(wc):
				continue
			var px: float = float(sx) + 0.5 - float(dv.x) * 0.5
			var pz: float = float(sz) + 0.5 - float(dv.y) * 0.5
			var rot: float = rad_to_deg(atan2(float(-dv.x), float(-dv.y)))
			if _emit(out, state, "hangar_wall_panel", Vector2i(sx, sz),
					Vector3(px, FLOOR_TOP, pz), rot, "wall", false,
					{"width": 1.8, "height": 2.6, "panel_style": "greebled"},
					"the wall face behind a podium slot — the cell in front is not walkable, so depth costs no clearance",
					"R9-backing-panel", "backing"):
				placed += 1
			break


## R10 — THE HOSE BOX.
## Geometry key: a wall run of at least 4 faces with no door within 2 m — the
## long blank stretch, which is where a building puts the thing that must be
## found in smoke. 0.25 m deep against a 0.18 m clearance, so like the
## extinguisher it stands as floor furniture and surrenders its cell.
static func _rule_hose_box(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var runs: Array = geo["runs"]
	for r in runs:
		var run: Array = r
		if run.size() < 4:
			continue
		var f: Dictionary = run[1]
		if _emit_floor_against_wall(out, state, geo, "fire_hose_box", f, H_HOSE_BOX,
				{"door_open": false, "has_window": true, "show_pictogram": true},
				"one face in from the end of a blank wall run of %d faces — 0.25 m deep, so the cell is surrendered" % run.size(),
				"R10-hose-box", "pocket"):
			return


## R11 — FLOOR POCKETS.
## Geometry key: a walk cell that is (a) NOT on the walker's BFS route, (b)
## against a wall face, (c) clear on both sides along that wall and on the
## squeeze-past cell — the host's own bench test — and (d) at least
## FLOOR_PROP_SPACING cells from anything else this module stood on the floor.
## This is the body-scale object the critic asked for: something a human can be
## measured against every few metres, at 0.72, 1.10 and 1.75 m.
static func _rule_floor_pockets(out: Array, state: Dictionary, geo: Dictionary) -> void:
	var order: Array = ["lab_stool", "clamp_stand", "iv_stand", "gas_canister"]
	var i: int = 0
	for f in geo["faces"]:
		if int(state["floor_taken"]) >= MAX_FLOOR_TAKEN:
			return
		if i >= order.size():
			return
		var fd: Dictionary = f
		var token: String = str(order[i])
		if _emit_floor_against_wall(out, state, geo, token, fd, FLOOR_TOP, {},
				"a dead pocket against a wall face, off the walker's route, both flanks and the squeeze-past cell open",
				"R11-floor-pocket", "pocket"):
			i += 1


# ═══════════════════════════════════════════════════════════════════════════
# EMISSION — the three ways a placement can be refused
# ═══════════════════════════════════════════════════════════════════════════

## A wall face's own normal turned into a placement. The prop's origin is set
## back from the face by its `back` extent so its body is flush, and the whole
## thing is refused if front + back would reach past the walker's clearance.
static func _emit_wall(out: Array, state: Dictionary,
		token: String, face: Dictionary, y: float, cfg: Dictionary,
		why: String, rule: String, family: String) -> bool:
	y = _ruled_y(token, y)  # the hand's height wins over the caller's constant
	var row: Dictionary = CATALOGUE.get(token, {})
	var back: float = float(row.get("back", 0.0))
	var front: float = float(row.get("front", 0.0))
	# a millimetre of tolerance on a metre-scale comparison, so a fitting sized
	# EXACTLY to the limit is not refused by a float's last bit
	if back + front > WALL_PROUD_MAX + 0.001:
		return false
	var nx: float = float(face["nx"])
	var nz: float = float(face["nz"])
	var px: float = float(face["x"]) + nx * back
	var pz: float = float(face["z"]) + nz * back
	var cell: Vector2i = face["front"]
	return _emit(out, state, token, cell, Vector3(px, y, pz),
		rad_to_deg(atan2(nx, nz)), "wall", false, cfg, why, rule, family)


## A prop that stands on the deck in front of a wall face. Every clearance test
## the host's own bench rule applies, applied here, plus two of this module's
## own: never on the walker's route, and never within FLOOR_PROP_SPACING of
## another floor prop. Sets occupies_floor, which is the host's instruction to
## erase the cell before the autopilot plans.
static func _emit_floor_against_wall(out: Array, state: Dictionary, geo: Dictionary,
		token: String, face: Dictionary, y: float, cfg: Dictionary,
		why: String, rule: String, family: String) -> bool:
	y = _ruled_y(token, y)  # the hand's height wins over the caller's constant
	if int(state["floor_taken"]) >= MAX_FLOOR_TAKEN:
		return false
	var cell: Vector2i = face["front"]
	var floors: Dictionary = geo["floors"]
	var path: Dictionary = geo["path"]
	if path.has(cell):
		return false
	var nx: float = float(face["nx"])
	var nz: float = float(face["nz"])
	# both neighbours ALONG the wall must be floor, so the prop never plugs a
	# one-cell passage or stands in a doorway
	var ax := Vector2i(cell.x + int(nz), cell.y + int(nx))
	var bx := Vector2i(cell.x - int(nz), cell.y - int(nx))
	if not floors.has(ax) or not floors.has(bx):
		return false
	# and the cell the walker squeezes past on, one further OUT along the face's
	# own outward normal — the wall is behind `cell`, so the room is in front
	var past := Vector2i(cell.x + int(nx), cell.y + int(nz))
	if not floors.has(past):
		return false
	var used: Dictionary = state["used_cells"]
	for k in used:
		var u: Vector2i = k
		if absi(u.x - cell.x) + absi(u.y - cell.y) < FLOOR_PROP_SPACING:
			return false
	# stand it against the face: half a body depth off the wall, 0.28 m, which
	# is inside the 0.5 m cell and leaves the far half of it clear
	var px: float = float(face["x"]) + nx * 0.28
	var pz: float = float(face["z"]) + nz * 0.28
	var ok: bool = _emit(out, state, token, cell, Vector3(px, y, pz),
		rad_to_deg(atan2(nx, nz)), "floor", true, cfg, why, rule, family)
	if ok:
		state["floor_taken"] = int(state["floor_taken"]) + 1
	return ok


## The single gate every placement passes through. Four refusals:
##   * the segment's cap is spent;
##   * this family's share of it is spent;
##   * the token does not resolve against the host's living registry;
##   * the cell already carries a prop.
static func _emit(out: Array, state: Dictionary, token: String, cell: Vector2i,
		pos: Vector3, rot_y: float, surface: String, occupies_floor: bool,
		cfg: Dictionary, why: String, rule: String, family: String) -> bool:
	if out.size() >= int(state["cap"]):
		return false
	var quota: Dictionary = state["quota"]
	var spent: Dictionary = state["spent"]
	if int(spent.get(family, 0)) >= int(quota.get(family, 0)):
		return false
	var live: Dictionary = state["live"]
	if not live.is_empty() and not live.has(token):
		return false
	var used: Dictionary = state["used_cells"]
	if used.has(cell):
		return false
	used[cell] = true
	spent[family] = int(spent.get(family, 0)) + 1
	var counts: Dictionary = state["counts"]
	counts[token] = int(counts.get(token, 0)) + 1
	out.append({
		"token": token,
		"cell": cell,
		"surface": surface,
		"pos": pos,
		"rot_y": rot_y,
		"config": cfg,
		"occupies_floor": occupies_floor,
		"why": why,
		"rule": rule,
		"family": family,
	})
	return true


## The face of a given wall cell that looks at `toward` — a jamb has up to four
## faces and only one of them is beside the opening. Used by the door rules,
## which know the jamb CELL and need its face on the door's side.
static func _face_on(geo: Dictionary, cell: Vector2i, toward: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_d: float = 1e9
	for f in geo["faces"]:
		var fd: Dictionary = f
		var c: Vector2i = fd["cell"]
		if c != cell:
			continue
		var d: float = Vector2(float(fd["x"]), float(fd["z"])).distance_to(toward)
		if d < best_d:
			best_d = d
			best = fd
	return best


## A door's clear opening, at its middle, in face coordinates.
static func _door_centre(d: Dictionary) -> Vector2:
	var s: float = float(int(d["s"]))
	var e: float = float(int(d["e"]))
	if bool(d["along_x"]):
		return Vector2((s + e + 1.0) * 0.5, float(int(d["z"])) + 0.5)
	return Vector2(float(int(d["x"])) + 0.5, (s + e + 1.0) * 0.5)
