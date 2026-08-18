extends Node3D
class_name CurationStation

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const ArtifactIdentity := preload("res://commons/grid/artifact_identity.gd")
const StationStageScene := preload("res://commons/artifacts/station/station_stage.tscn")
const StationPlinthScene := preload("res://commons/artifacts/station/station_plinth.tscn")
const StationWallScene := preload("res://commons/artifacts/station/station_wall.tscn")
const StationPillarScene := preload("res://commons/artifacts/station/station_pillar.tscn")
const StationCabinetScene := preload("res://commons/artifacts/station/station_cabinet.tscn")
const StationBarrierScene := preload("res://commons/artifacts/station/station_barrier.tscn")
const StationCratesScene := preload("res://commons/artifacts/station/station_crates.tscn")
const StationGantryScene := preload("res://commons/artifacts/station/station_gantry.tscn")
const StationConsoleDeskScene := preload("res://commons/artifacts/station/station_console_desk.tscn")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the COMPOSER — give it 1 to 5 artifact lookup-names and it assembles a whole curation bay on the 1 m grid: a step-stage sized to the set, a plinth per item in an even row, a tiling backing wall with end caps, framing pillars, and each artifact grounded inert on its plinth. Origin at the stage centre on the floor.
# desire: to turn a loose handful of artifacts into a presented set — to place them, lift them, back them, and frame them so a viewer reads "these belong together, here, on purpose", with everything landing on grid lines.
# critical_parameter: artifacts (1..5) — the set being curated; their count drives the stage width, the plinth row, and the wall length, all snapped to whole cells. bay — how much architecture wraps the set (hall | apse | gate | none). duty — what the bay is FOR (show | depot | handling | watch). upkeep — which moment the kit is caught in, passed down to every pillar and crate stack this bay builds.
# triggers: _ready builds the kit, then defers artifact loading so each item enters a settled tree; apply_grid_config re-curates with a new set.
# emerges: one item reads "a single specimen on show"; five read "a collection, a comparison, a shelf made architecture"; the tiling wall + pillars turn the floor into a bay.
# needs: a [[station_stage]] [present]; N [[station_plinth]] columns [present]; a [[station_wall]] backing [present]; framing [[station_pillar]] uprights [present]; the artifacts themselves, inert and grounded [present].
# relationships: the assembler of the whole station family; loads any registered artifact by lookup_name the way [[artifact_review_station]] does; the multi-item sibling of that single-item review tool.
# truth: curation is an argument made with placement. To choose five things, raise them to a line, and put a wall behind is to say they share a question. The grid keeps the argument honest — measured, repeatable, buildable.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). 656 placements across 360 maps, 36 @export
# knobs, and not one of them ever varied — because only 12 of the 36 were ever
# readable from map data in the first place. What the corpus DID vary was three
# booleans, always together, in exactly three states:
#
#     with_wall:false  with_pillars:false  with_barrier:false   244 maps
#     with_wall:true   with_pillars:true   with_barrier:true    205 maps
#     (no tokens at all — which is the same all-true state)     205 maps
#     with_wall:true   with_pillars:false  with_barrier:true      2 maps
#
# That is not three independent flags. That is one axis with two well-worn ends
# and no name, hand-spelled three times per placement, 451 times over. So the
# promotion here is SELECTION, not invention:
#
#   bay    HOW MUCH ARCHITECTURE   hall · apse · gate · none          (body / mass)
#   duty   WHAT THE BAY IS FOR     show · depot · handling · watch    (register)
#   upkeep WHICH MOMENT, PASSED ON service · works · store · scrap    (the kit's own)
#
# `bay` DERIVES the three booleans and never overrides them: an explicit
# with_wall / with_pillars / with_barrier token in the map still wins, so all 451
# hand-spelled placements are byte-identical and the two odd (true,false,true)
# maps keep their odd state. bay=hall is (true,true,true) — the export defaults —
# so the 205 un-tokened placements are byte-identical too.
#
# `duty` is the other 33 exports finally admitting they were a family. The kit
# already ships a cabinet, a crate stack, an overhead gantry and an operator
# console, every one of them wired into _build_kit and every one of them dead:
# with_cabinets / with_crates / with_gantry / with_console appear in ZERO maps.
# Turning them on in named combinations — plus the palette, which no map could
# reach either — is the difference between a gallery, a store, a handling bay and
# a control room. Same set of objects, four institutions.
#
# What it cost: the three colour exports are no longer the source of truth for a
# station's palette — duty writes them, so an author setting body_color in the
# inspector must also leave duty at "show" or their colour is overwritten on the
# next _read_overrides(). The alternative (only writing colours when they are at
# their literal defaults) would have made duty silently inert half the time,
# which is worse.
#
# Deliberately NOT routed through duty: the stage geometry, the plinth heights,
# the artifact grounding maths, _make_inert's INTERACT_LAYERS mask, and the
# START/EXIT pads. Nothing in this station has a collider — the whole kit is
# meshes — but the pads are wayfinding and the grounding is load-bearing for
# every curated artifact, so both stay outside the family.
#
# NOT routed through `finish` either, though the HangarKit family has exactly
# such an axis (rams | terminal): only 4 of the 9 kit pieces this composer builds
# honour a finish token (stage, pillar, barrier, cabinet — plinth, wall, crates,
# gantry and console do not), so passing it would half-repaint the bay and read
# as a bug. duty carries the palette by colour instead, which all 9 honour.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Set")
## 1 to 5 artifact lookup-names to curate. Missing names leave an empty plinth.
## Default set spans the full size range — a tiny point on a 1x1 podium up to a room-scale 3D CA grid
## on a 4x4 platform — and keeps two INTERACTIVE artifacts (ca_rule_explorer, distribution_sampler) so
## you can test the desktop crosshair / VR pointer out of the box. Swap in any registered artifact.
@export var artifacts: Array[String] = ["point", "ca_rule_explorer", "", "distribution_sampler", "grid_3d_4x4x4"]

@export_group("Family (DNA)")
## AXIS 1 — how much architecture wraps the set. DERIVES with_wall / with_pillars /
## with_barrier: a map token for any of those still wins, but an inspector tick does
## NOT — _read_overrides re-derives from bay every time, so change bay, not the flags.
## hall (legacy default: backed, framed and thresholded) | apse (the backing wall alone) |
## gate (uprights + rail, open sky behind) | none (the stage and the plinths, nothing else).
@export var bay: String = "hall"
## AXIS 2 — what the bay is FOR. Chooses which of the kit's dead furniture wakes up and
## repaints the whole composition (body / panel / accent below are written by duty).
## show (legacy default: the gallery) | depot (the store behind it) |
## handling (the works bay) | watch (the control room).
## NOT store/works: station_pillar and station_crates already own those two words on
## `upkeep`, and there they mean the opposite — a sealed bale, not an active depot.
@export var duty: String = "show"
## AXIS 3 — WHICH MOMENT the kit is caught in, handed straight to every station_pillar
## and station_crates this bay builds. Deliberately NOT derived from duty: duty says what
## the room is for, upkeep says what time it is, and duty:depot (an active store) is the
## opposite of upkeep:store (a sealed bale). service | works | store | scrap.
@export var upkeep: String = "service"

@export_group("Layout (grid cells)")
## Cells between plinth centres along the row.
@export var plinth_spacing_cells: int = 2
## Stage depth in cells (front-to-back).
@export var stage_depth_cells: int = 3
## Extra cells of stage margin each side of the plinth row.
@export var stage_margin_cells: int = 2
## Bay shape: row (a single front-facing line) | corner (an L — two walls meeting at a 90° corner,
## plinths along both legs). More shapes (two_side | u | ring) build on the same perimeter-path model.
@export var layout: String = "row"

@export_group("Heights (m)")
@export var plinth_height: float = 1.0
@export var stage_step_height: float = 0.22
@export var wall_height: float = 2.6

@export_group("Pieces")
@export var with_wall: bool = true
@export var with_pillars: bool = true
## A low front barrier (threshold) across the stage front. Open "rail" by default so it never blocks the set.
@export var with_barrier: bool = true
@export var barrier_style: String = "rail"
## Flank the back wall with storage/display cabinets (the "archive behind" read).
@export var with_cabinets: bool = false
## Drop supply crates in the back corners (lived-in dressing).
@export var with_crates: bool = false
@export var with_wall_screen: bool = true
## START + EXIT pads at the two ends of the bay front, so the hangar reads as a walkable hall.
@export var with_endpoints: bool = true

@export_group("Large artifacts")
## Footprint (cells) above which an artifact gets a forward platform + bridge instead of a plinth.
@export var large_cells: int = 3
## n-size platform cap — how big a footprint a platform can grow to.
@export var max_platform_cells: int = 12
## Wrap each large platform in an open portal frame (frames the artifact + its negative space).
@export var frame_large: bool = true
## Build an empty slot ("" / missing name) as a framed VOID — negative space presented on purpose.
@export var frame_voids: bool = true

@export_group("Text frames")
## Harvest each artifact's own text into a framed 2D-in-3D panel above it, joined by a connector line.
@export var with_text_frames: bool = true

@export_group("Furniture")
## An overhead StationGantry rig spanning over the bay.
@export var with_gantry: bool = false
## A StationConsoleDesk operator terminal at one end of the bay.
@export var with_console: bool = false
@export var label_plinths: bool = true
## Hide the loaded artifacts' floating billboard Label3D text, so the only text on show is the
## station's own 2D-in-3D plates/screens (surface-pinned). Surface-baked artifact text is kept.
@export var hide_floating_labels: bool = true

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var panel_color: Color = Color(0.70, 0.68, 0.64)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

const CELL := 1.0

# AXIS 1 — bay. Each value is just the three booleans, named. Nothing else moves:
# the stage, the plinth row and the artifact grounding are identical across all
# four, so a map can change how enclosed a set reads without shifting a single
# curated object by a millimetre.
const BAYS := {
	# The legacy lineage — the export defaults, and what 410 placements already
	# build (205 by naming all three true, 205 by naming nothing at all).
	"hall": {"wall": true, "pillars": true, "barrier": true},
	# Backed but not framed: the 2.6 m tiling wall stands behind the row and
	# nothing stands in front of it. You walk straight in from three sides.
	"apse": {"wall": true, "pillars": false, "barrier": false},
	# The threshold without the room: two lit 2.6 m uprights at the front corners
	# with the rail strung between them, and open air where the wall was.
	"gate": {"wall": false, "pillars": true, "barrier": true},
	# The read 244 maps already hand-spell: the step, the plinths, the set, and
	# no architecture at all.
	"none": {"wall": false, "pillars": false, "barrier": false},
}

# AXIS 2 — duty. Every entry writes the four furniture booleans, the text-frame
# flag, the barrier style, the three colours and the two strings the stage and
# the wall screen print. "show" is the legacy lineage: every value below is
# lifted verbatim from the export defaults it replaces, including the two
# slightly different greys of body and panel.
const DUTIES := {
	# THE GALLERY. Nothing but the set: plinths, plaques, and a framed readout
	# hovering over each item on a lit accent rod. Warm off-white Braun body,
	# grey-beige panels, one orange accent. Open rail across the front.
	"show": {
		"cabinets": false, "crates": false, "gantry": false, "console": false,
		"text_frames": true, "barrier_style": "rail",
		"body": Color(0.81, 0.79, 0.75), "panel": Color(0.70, 0.68, 0.64),
		"accent": Color(0.86, 0.34, 0.11),
		"stencil": "CURATION", "verb": "ON SHOW",
	},
	# THE STORE. Two glass-fronted cabinets with lit shelves flank the back wall,
	# crate stacks fill both back corners, the front rail goes solid panelled, and
	# the hovering readouts go dark — a store keeps things, it does not interpret
	# them. Repainted raw-ply brown with a safety-orange stripe.
	"depot": {
		"cabinets": true, "crates": true, "gantry": false, "console": false,
		"text_frames": false, "barrier_style": "panel",
		"body": Color(0.66, 0.50, 0.30), "panel": Color(0.48, 0.35, 0.21),
		"accent": Color(0.98, 0.62, 0.05),
		"stencil": "STORE", "verb": "IN STORE",
	},
	# THE HANDLING BAY. A double-portal gantry throws a beam clear over the whole
	# bay at 2.8 m with a drop hoist and a lit underside, crates in the corners, an
	# operator desk at the front, solid barrier, no readouts. Cold steel body,
	# graphite panels, hazard yellow.
	"handling": {
		"cabinets": false, "crates": true, "gantry": true, "console": true,
		"text_frames": false, "barrier_style": "panel",
		"body": Color(0.55, 0.58, 0.62), "panel": Color(0.30, 0.32, 0.35),
		"accent": Color(0.95, 0.78, 0.06),
		"stencil": "HANDLING", "verb": "IN TRANSIT",
	},
	# THE CONTROL ROOM. The same set, watched instead of shown: the operator desk
	# is there, the readouts stay lit, and the entire composition drops into the
	# HangarKit terminal register — near-black housing where every edge light, lit
	# seam, plaque groove and connector rod burns green.
	"watch": {
		"cabinets": false, "crates": false, "gantry": false, "console": true,
		"text_frames": true, "barrier_style": "rail",
		"body": Color(0.14, 0.14, 0.155), "panel": Color(0.09, 0.09, 0.10),
		"accent": Color(0.36, 0.94, 0.44),
		"stencil": "CONTROL", "verb": "MONITORED",
	},
}

var _name_scene: Dictionary = {}
var _name_disp: Dictionary = {}   # lookup_name -> human display name
## lookup_name -> the artifact's own registry entry. Kept because the index used to hold
## only the scene path, which is why a composed artifact could never receive the
## default_params its registry entry declares.
var _name_entry: Dictionary = {}
var _plinth_tops: Array = []   # [{x, z, top_y}] per item, set during kit build
var _built := false

func _ready() -> void:
	_read_overrides()
	_build_name_index()
	_assemble()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_plinth_tops.clear()
		_built = false
		_assemble()


func _read_overrides() -> void:
	if has_meta("config_artifacts"):
		var raw = get_meta("config_artifacts")
		if raw is Array:
			artifacts = []
			for a in raw:
				artifacts.append(str(a))
		elif raw is String and str(raw).strip_edges() != "":
			artifacts = []
			for a in str(raw).split(","):
				artifacts.append(a.strip_edges())
	if has_meta("config_plinth_spacing_cells"): plinth_spacing_cells = int(str(get_meta("config_plinth_spacing_cells")))
	if has_meta("config_plinth_height"): plinth_height = float(str(get_meta("config_plinth_height")))
	# ── the two family axes, read and DERIVED BEFORE the low-level flags below, so
	# that any with_* / barrier_style a map spells out by hand still has the last
	# word. This ordering is the whole promise of the promotion: 451 placements
	# name those flags explicitly and none of them may move.
	if has_meta("config_bay"): bay = str(get_meta("config_bay")).to_lower()
	if has_meta("config_duty"): duty = str(get_meta("config_duty")).to_lower()
	if has_meta("config_upkeep"): upkeep = str(get_meta("config_upkeep")).to_lower()
	_apply_bay()
	_apply_duty()
	if has_meta("config_with_wall"): with_wall = _b(get_meta("config_with_wall"))
	if has_meta("config_with_pillars"): with_pillars = _b(get_meta("config_with_pillars"))
	if has_meta("config_with_barrier"): with_barrier = _b(get_meta("config_with_barrier"))
	if has_meta("config_barrier_style"): barrier_style = str(get_meta("config_barrier_style")).to_lower()
	if has_meta("config_with_cabinets"): with_cabinets = _b(get_meta("config_with_cabinets"))
	if has_meta("config_with_crates"): with_crates = _b(get_meta("config_with_crates"))
	if has_meta("config_with_gantry"): with_gantry = _b(get_meta("config_with_gantry"))
	if has_meta("config_with_console"): with_console = _b(get_meta("config_with_console"))
	if has_meta("config_layout"): layout = str(get_meta("config_layout")).to_lower()


# ── the family axes ──────────────────────────────────────────────────────────

# An unknown bay / duty falls back to the legacy lineage rather than to nothing,
# so a typo in a map token degrades to today's station instead of a bare stage.
func _bay_spec() -> Dictionary:
	var s: Dictionary = BAYS.get(bay, BAYS["hall"])
	return s


func _duty_spec() -> Dictionary:
	var s: Dictionary = DUTIES.get(duty, DUTIES["show"])
	return s


func _duty_col(slot: String, fallback: Color) -> Color:
	var v: Variant = _duty_spec().get(slot, fallback)
	if v is Color:
		var c: Color = v
		return c
	return fallback


func _duty_str(slot: String, fallback: String) -> String:
	return str(_duty_spec().get(slot, fallback))


# AXIS 1 — name the enclosure, derive the three flags. Idempotent: _read_overrides
# may run twice (once from _ready, once from apply_grid_config) and this writes the
# same values both times, after which the explicit config_with_* reads run again.
func _apply_bay() -> void:
	var s: Dictionary = _bay_spec()
	with_wall = bool(s.get("wall", true))
	with_pillars = bool(s.get("pillars", true))
	with_barrier = bool(s.get("barrier", true))


# AXIS 2 — name the institution, wake the furniture it needs and repaint the kit.
# The colours are written unconditionally (they are unreachable from map data, so
# there is nothing to defer to); barrier_style IS reachable, so the explicit read
# that follows in _read_overrides still overrides this.
func _apply_duty() -> void:
	var s: Dictionary = _duty_spec()
	with_cabinets = bool(s.get("cabinets", false))
	with_crates = bool(s.get("crates", false))
	with_gantry = bool(s.get("gantry", false))
	with_console = bool(s.get("console", false))
	with_text_frames = bool(s.get("text_frames", true))
	barrier_style = str(s.get("barrier_style", "rail"))
	body_color = _duty_col("body", Color(0.81, 0.79, 0.75))
	panel_color = _duty_col("panel", Color(0.70, 0.68, 0.64))
	accent_color = _duty_col("accent", Color(0.86, 0.34, 0.11))


func _count() -> int:
	return clampi(artifacts.size(), 1, 5)


# Measure each artifact's footprint, then build a kit sized to the set — each item gets a plinth that
# fits it (tall+narrow for small things, low+broad for big ones), the row laid out by cumulative width.
func _assemble() -> void:
	_built = true
	var n: int = _count()
	# 1. Instantiate + prep each artifact (hidden until we know where it goes).
	var items: Array = []
	for i in range(n):
		var nm := str(artifacts[i]) if i < artifacts.size() else ""
		var inst: Node = null
		if nm != "" and _name_scene.has(nm):
			var packed = load(_name_scene[nm])
			if packed != null:
				inst = packed.instantiate()
		if inst != null:
			if inst is Node3D:
				(inst as Node3D).visible = false
			# STAMP BEFORE add_child. The grid does this for every artifact a map places;
			# a composer that skips it hands the artifact no identity and none of the
			# defaults its registry entry declares, so a one-scene-many-names artifact
			# cannot know which member to build and a declared colour never arrives.
			ArtifactIdentity.stamp(inst, nm, _name_entry.get(nm, {}))
			add_child(inst)
			_make_inert(inst)
			if hide_floating_labels:
				_hide_labels(inst)
			if inst.has_method("apply_grid_config"):
				inst.apply_grid_config({"emissive": false})
		items.append({"inst": inst, "name": nm})
	# 2. Let each artifact's _ready (and any deferred build) settle, then measure its footprint in cells.
	# The station can be assembling while OUT of the tree: a map torn down or reloaded mid-build
	# leaves the artifact detached but still valid, and get_tree() is null there. Wait for a tree
	# instead of crashing; a station that is never added never resumes, which is the right
	# answer for a dead map.
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	await get_tree().process_frame
	for item in items:
		var wc := 1
		var dc := 1
		var base_y := 0.0
		var cx := 0.0
		var cz := 0.0
		var ah := 0.0
		if item["inst"] != null:
			var ab := _combined_aabb(item["inst"])
			if ab.size.length() > 0.0:
				wc = clampi(int(ceil(ab.size.x - 0.1)), 1, max_platform_cells)
				dc = clampi(int(ceil(ab.size.z - 0.1)), 1, max_platform_cells)
				base_y = ab.position.y
				cx = ab.position.x + ab.size.x * 0.5   # footprint centre offset from the artifact origin
				cz = ab.position.z + ab.size.z * 0.5
				ah = ab.size.y
		item["cx"] = cx
		item["cz"] = cz
		item["ah"] = ah
		var is_large := maxi(wc, dc) > large_cells
		item["large"] = is_large
		item["true_w"] = wc
		item["true_d"] = dc
		# Large items take only a narrow bridge-anchor slot in the row; their true footprint goes to the platform.
		item["w"] = 2 if is_large else wc
		item["d"] = 2 if is_large else dc
		item["base_y"] = base_y
	# 3. Build the kit sized to the measured set.
	_build_kit(items)


# Plinth height drops as the footprint grows: small things stand tall and narrow, big things sit low.
func _plinth_height_for(max_dim: int) -> float:
	match max_dim:
		1: return plinth_height
		2: return plinth_height * 0.68
		3: return plinth_height * 0.46
		_: return plinth_height * 0.32


func _build_kit(items: Array) -> void:
	# A layout builder fills a PERIMETER PATH: _slots (plinths, each with a yaw) + _segments (walls,
	# each with a yaw) + pillars (junctions/corners) + barriers (open edges). The instancing below is
	# layout-agnostic — row / corner / (later) two_side / u / ring are all the same emitter.
	var L: Dictionary = _compute_layout(items)
	var slots: Array = L["slots"]

	# Stage sized to the layout.
	var stage: Node3D = StationStageScene.instantiate()
	add_child(stage)
	stage.apply_grid_config({
		"width_cells": int(L["w_cells"]), "depth_cells": int(L["d_cells"]),
		"step_height": stage_step_height, "hazard_edge": bool(L["hazard"]), "edge_light": true,
		"stencil_text": _duty_str("stencil", "CURATION"), "body_color": _cs(body_color),
		"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
	})

	# Plinths (sized to each artifact) + the artifact grounded on the cap + a caption plaque.
	# Only the plinth + plaque rotate to the slot yaw; the ARTIFACT stays axis-aligned so its
	# measured base_y grounding stays valid.
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		var item: Dictionary = slot["item"]
		if bool(item.get("large", false)):
			_build_platform_bridge(slot, item, i)
			continue
		if item["inst"] == null and frame_voids:
			# an empty slot becomes a framed VOID — negative space presented on purpose
			_build_frame(float(slot["x"]), float(slot["z"]), int(slot["w"]) + 1, int(slot["d"]) + 1, wall_height * 0.85)
			continue
		var wc: int = int(slot["w"])
		var dc: int = int(slot["d"])
		var yaw: float = float(slot["yaw"])
		var h: float = _plinth_height_for(maxi(wc, dc))
		var p: Node3D = StationPlinthScene.instantiate()
		add_child(p)
		p.position = Vector3(float(slot["x"]), stage_step_height, float(slot["z"]))
		p.rotation.y = yaw
		p.apply_grid_config({
			"width_cells": wc, "depth_cells": dc, "top_height": h, "top_style": "tray",
			"edge_light": true, "stencil_text": "", "three_bar": false, "body_color": _cs(body_color),
			"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
		})
		var inst = item["inst"]
		if inst != null and inst is Node3D:
			(inst as Node3D).visible = true
			(inst as Node3D).position = Vector3(float(slot["x"]), stage_step_height + h - float(item["base_y"]), float(slot["z"]))
		if label_plinths:
			var nm := str(item["name"])
			var disp: String = _clean_name(str(_name_disp.get(nm, nm))) if nm != "" else "ITEM-%d" % (i + 1)
			var plaque := _make_label_plaque(disp, "%02d" % (i + 1))
			var off: Vector3 = Vector3(0, 0, float(dc) * 0.5 * CELL - 0.17).rotated(Vector3.UP, yaw)
			plaque.position = Vector3(float(slot["x"]) + off.x, stage_step_height + clampf(h * 0.5, 0.22, 0.62), float(slot["z"]) + off.z)
			plaque.rotation.y = yaw
			add_child(plaque)
		if with_text_frames and inst != null:
			var tl: Array = []
			_collect_labels(inst, tl)
			_build_text_frame(float(slot["x"]), float(slot["z"]), stage_step_height + h, float(item.get("ah", 0.3)),
				_clean_name(str(_name_disp.get(str(item["name"]), str(item["name"])))), tl)

	# Backing wall — one tiling run per segment, rotated to face into the room.
	if with_wall:
		var segs: Array = L["segments"]
		for seg in segs:
			var wall: Node3D = StationWallScene.instantiate()
			add_child(wall)
			wall.position = Vector3(float(seg["x"]), 0, float(seg["z"]))
			wall.rotation.y = float(seg["yaw"])
			wall.apply_grid_config({
				"length_cells": int(seg["length_cells"]), "start_cap": bool(seg["start_cap"]), "end_cap": bool(seg["end_cap"]),
				"height": wall_height, "panel_style": "panel", "screen_slot": with_wall_screen and bool(seg.get("screen", false)),
				"screen_header": _duty_str("stencil", "CURATION"),
				"screen_lines": ["%d %s" % [slots.size(), _duty_str("verb", "ON SHOW")], "LINK  OK"],
				"lit_seam": true, "body_color": _cs(body_color), "panel_color": _cs(panel_color),
				"accent_color": _cs(accent_color),
			})

	# Framing pillars (front corners of a row; the inside corner of an L).
	if with_pillars:
		for pp in L["pillars"]:
			var pil: Node3D = StationPillarScene.instantiate()
			add_child(pil)
			pil.position = pp
			pil.apply_grid_config({
				"height": wall_height, "lit_groove": true, "body_color": _cs(body_color),
				"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
				"upkeep": upkeep,
			})

	# Barrier(s) — a low front rail, SPLIT to leave a gap where each bridge crosses out to a platform.
	if with_barrier:
		for b in L["barriers"]:
			if absf(float(b["yaw"])) > 0.01:
				_emit_barrier(float(b["x"]), float(b["z"]), float(b["yaw"]), int(b["length_cells"]))
				continue
			var bz: float = float(b["z"])
			var left: float = float(b["x"]) - float(int(b["length_cells"])) * 0.5 * CELL
			var right: float = float(b["x"]) + float(int(b["length_cells"])) * 0.5 * CELL
			var cuts: Array = []
			for slot in slots:
				if bool(slot["item"].get("large", false)):
					cuts.append(float(slot["x"]))   # bridge crosses the rail here — leave a gap
			cuts.sort()
			var gap_half: float = 1.5 * CELL
			var cursor: float = left
			for gx in cuts:
				var gs: float = float(gx) - gap_half
				if gs - cursor > 0.4:
					_emit_barrier((cursor + gs) * 0.5, bz, 0.0, int(round((gs - cursor) / CELL)))
				cursor = maxf(cursor, float(gx) + gap_half)
			if right - cursor > 0.4:
				_emit_barrier((cursor + right) * 0.5, bz, 0.0, int(round((right - cursor) / CELL)))

	# START + EXIT pads at the two ends of the bay front — enter one end, walk the hall, exit the other.
	if with_endpoints:
		var hw: float = float(int(L["w_cells"])) * 0.5 * CELL
		var fz: float = float(int(L["d_cells"])) * 0.5 * CELL - 0.45
		_build_endpoint(-hw - CELL, fz, "START", Color(0.30, 0.85, 0.45))
		_build_endpoint(hw + CELL, fz, "EXIT", Color(0.62, 0.42, 0.95))

	# Overhead gantry + operator console — the new kit pieces composed into the bay.
	if with_gantry:
		_build_gantry(L)
	if with_console:
		_build_console(L)

	# Flanking cabinets / crates — back-wall dressing (row layout only for now).
	if str(L["layout"]) == "row":
		var half_w: float = float(int(L["w_cells"])) * 0.5 * CELL
		var back_z: float = -float(int(L["d_cells"])) * 0.5 * CELL
		if with_cabinets:
			for sx in [-1.0, 1.0]:
				var cab: Node3D = StationCabinetScene.instantiate()
				add_child(cab)
				cab.position = Vector3(sx * (half_w - 1.0), 0, back_z + 0.45)
				cab.apply_grid_config({
					"width_cells": 2, "shelf_count": 4, "front_style": "glass",
					"body_color": _cs(body_color), "panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
				})
		if with_crates:
			for sx2 in [-1.0, 1.0]:
				var cr: Node3D = StationCratesScene.instantiate()
				add_child(cr)
				cr.position = Vector3(sx2 * (half_w - 0.55), 0, back_z + 0.6)
				cr.apply_grid_config({"footprint_cells": 1, "crate_count": 4,
					"palette": "wood" if duty == "depot" else "metal",
					"upkeep": upkeep, "seed_index": int(sx2) + 3})


# Dispatch to a layout builder. Each returns {layout, w_cells, d_cells, hazard, slots, segments, pillars, barriers}.
# Large artifact: an n-size platform out in front of the bay, reached by a bridge from the row — so the
# wall hangar controls the placement of big artifacts too, not just small ones on plinths.
func _build_platform_bridge(slot: Dictionary, item: Dictionary, i: int) -> void:
	var sx: float = float(slot["x"])
	var sz: float = float(slot["z"])
	var tw: int = int(item.get("true_w", 4))
	var td: int = int(item.get("true_d", 4))
	var reach_cells: int = td + 3
	var pz: float = sz + float(reach_cells) * CELL
	# the platform (n-size, sized to the artifact)
	var platform: Node3D = StationStageScene.instantiate()
	add_child(platform)
	platform.position = Vector3(sx, 0, pz)
	platform.apply_grid_config({
		"width_cells": tw + 2, "depth_cells": td + 2, "step_height": stage_step_height,
		"hazard_edge": true, "edge_light": true, "stencil_text": "", "body_color": _cs(body_color),
		"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
	})
	# the bridge — a narrow walkway from the bay to the platform
	var bridge: Node3D = StationStageScene.instantiate()
	add_child(bridge)
	bridge.position = Vector3(sx, 0, (sz + pz) * 0.5)
	bridge.apply_grid_config({
		"width_cells": 2, "depth_cells": reach_cells, "step_height": stage_step_height,
		"hazard_edge": false, "edge_light": true, "stencil_text": "", "body_color": _cs(body_color),
		"panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
	})
	# the artifact grounded on the platform
	var inst = item["inst"]
	if inst != null and inst is Node3D:
		(inst as Node3D).visible = true
		# centre the artifact's footprint on the platform (its origin may be off-centre)
		(inst as Node3D).position = Vector3(
			sx - float(item.get("cx", 0.0)), stage_step_height - float(item["base_y"]), pz - float(item.get("cz", 0.0))
		)
	# frame the platform — the artifact (often open) presented inside an open portal frame
	if frame_large:
		var fh: float = maxf(wall_height, float(item.get("ah", 0.0)) + 0.6)
		_build_frame(sx, pz, tw + 2, td + 2, fh)
	# caption plaque at the platform front
	if label_plinths:
		var nm := str(item["name"])
		var disp: String = _clean_name(str(_name_disp.get(nm, nm))) if nm != "" else "ITEM-%d" % (i + 1)
		var plaque := _make_label_plaque(disp, "%02d" % (i + 1))
		plaque.position = Vector3(sx, stage_step_height + 0.3, pz + float(td) * 0.5 * CELL + 0.2)
		add_child(plaque)
	if with_text_frames and inst != null:
		var tl: Array = []
		_collect_labels(inst, tl)
		_build_text_frame(sx, pz, stage_step_height, float(item.get("ah", 0.3)),
			_clean_name(str(_name_disp.get(str(item["name"]), str(item["name"])))), tl)


# One run of front rail (used to build the barrier in segments, leaving bridge gaps).
func _emit_barrier(x: float, z: float, yaw: float, length_cells: int) -> void:
	if length_cells < 1:
		return
	var bar: Node3D = StationBarrierScene.instantiate()
	add_child(bar)
	bar.position = Vector3(x, 0, z)
	bar.rotation.y = yaw
	bar.apply_grid_config({
		"length_cells": length_cells, "height": 1.0, "style": barrier_style,
		"hazard_base": true, "panel_color": _cs(body_color), "post_color": _cs(panel_color),
		"accent_color": _cs(accent_color),
	})


# Harvest every text string an artifact carries (its own Label3D / Label nodes), capped + deduped.
func _collect_labels(node: Node, out: Array, in_sign: bool = false) -> void:
	if out.size() >= 6:
		return
	var sig := in_sign or node.name == "Signage" or node.name == "Readout"
	var t := ""
	if node is Label3D and not sig:
		t = String((node as Label3D).text).strip_edges()
	elif node is Label and not sig:
		t = String((node as Label).text).strip_edges()
	if t != "" and not out.has(t):
		out.append(t)
	for c in node.get_children():
		_collect_labels(c, out, sig)


# A framed 2D-in-3D text panel above an artifact showing its harvested text, joined by a connector line.
func _build_text_frame(x: float, z: float, grounded_y: float, ah: float, header: String, lines: Array) -> void:
	var disp: Array = lines if not lines.is_empty() else ["—"]
	var top: float = grounded_y + maxf(ah, 0.3) + 0.7
	var ph: float = 0.12 + 0.055 * float(mini(disp.size(), 6))
	var panel: Node3D = HangarKit.readout(header.substr(0, 18), disp, Vector2(0.72, ph),
		Color(0.09, 0.10, 0.12), Color(0.90, 0.92, 0.96), accent_color)
	if panel != null:
		panel.position = Vector3(x, top, z)
		add_child(panel)
	var bottom: float = grounded_y + maxf(ah, 0.3)
	var conn := _box(Vector3.ZERO, Vector3(0.022, top - bottom, 0.022), _emi(accent_color, 0.7))
	conn.position = Vector3(x, (bottom + top) * 0.5, z)
	add_child(conn)


# An overhead StationGantry rig spanning over the bay stage.
func _build_gantry(L: Dictionary) -> void:
	var g: Node3D = StationGantryScene.instantiate()
	add_child(g)
	g.position = Vector3(0, 0, 0)
	if g.has_method("apply_grid_config"):
		g.apply_grid_config({
			"span_cells": clampi(int(L["w_cells"]) - 2, 3, 11), "height": wall_height + 0.2,
			"leg_mode": "double_portal", "with_hoist": true, "with_lights": true,
			"body_color": _cs(body_color), "panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
		})


# A StationConsoleDesk operator terminal at the right-front end of the bay, facing the viewer.
func _build_console(L: Dictionary) -> void:
	var c: Node3D = StationConsoleDeskScene.instantiate()
	add_child(c)
	var hw: float = float(int(L["w_cells"])) * 0.5 * CELL
	var fz: float = float(int(L["d_cells"])) * 0.5 * CELL
	# Was (hw - 0.9, 0, fz - 0.7), which put the 1.2 x 0.7 desk straight through the
	# right framing pillar (0.42 square at hw - 0.45, fz - 0.45). Never seen, because
	# with_console has never been true in any map; duty:handling / duty:watch are the
	# first things to build it. Moved inboard so the desk clears the pillar by 0.49 m
	# and still sits in front of the plinth line (which _layout_row fixes at fz - 0.9).
	c.position = Vector3(hw - 1.75, 0, fz - 0.45)
	if c.has_method("apply_grid_config"):
		c.apply_grid_config({
			"body_color": _cs(body_color), "panel_color": _cs(panel_color), "accent_color": _cs(accent_color),
			"screen_lines": "BAY|RDY", "label_text": "OPERATOR",
		})


# A small labelled pad — START (entry) or EXIT — at an end of the bay, marking where you walk in/out.
func _build_endpoint(x: float, z: float, label_text: String, accent: Color) -> void:
	var pad: Node3D = StationStageScene.instantiate()
	add_child(pad)
	pad.position = Vector3(x, 0, z)
	pad.apply_grid_config({
		"width_cells": 2, "depth_cells": 2, "step_height": stage_step_height,
		"hazard_edge": true, "edge_light": true, "stencil_text": label_text,
		"body_color": _cs(body_color), "panel_color": _cs(panel_color), "accent_color": _cs(accent),
	})
	var plaque := _make_label_plaque(label_text, "")
	plaque.position = Vector3(x, stage_step_height + 0.4, z)
	add_child(plaque)


# An open portal frame around a footprint — 4 corner posts + a top rectangle. Frames the artifact (often
# open/lattice) and the negative space it sits in; with no artifact it frames pure negative space.
func _build_frame(x: float, z: float, w_cells: int, d_cells: int, height: float) -> void:
	var hw: float = float(maxi(w_cells, 1)) * 0.5 * CELL
	var hd: float = float(maxi(d_cells, 1)) * 0.5 * CELL
	var post: float = 0.16
	var beam: float = 0.14
	var mat: Material = _emi(accent_color, 0.5)
	for ix in [-1.0, 1.0]:
		for iz in [-1.0, 1.0]:
			add_child(_box(Vector3(x + ix * hw, height * 0.5 + stage_step_height, z + iz * hd), Vector3(post, height, post), mat))
	var top: float = height + stage_step_height
	add_child(_box(Vector3(x, top, z - hd), Vector3(hw * 2.0 + post, beam, beam), mat))
	add_child(_box(Vector3(x, top, z + hd), Vector3(hw * 2.0 + post, beam, beam), mat))
	add_child(_box(Vector3(x - hw, top, z), Vector3(beam, beam, hd * 2.0 + post), mat))
	add_child(_box(Vector3(x + hw, top, z), Vector3(beam, beam, hd * 2.0 + post), mat))


func _compute_layout(items: Array) -> Dictionary:
	match layout:
		"corner":
			return _layout_corner(items)
		_:
			return _layout_row(items)


# ROW — a single front-facing line of plinths with a back wall, front pillars + barrier (the original bay).
func _layout_row(items: Array) -> Dictionary:
	var n: int = items.size()
	var gap: int = 1
	var total_w: int = 0
	var max_d: int = 1
	for item in items:
		total_w += int(item["w"])
		max_d = maxi(max_d, int(item["d"]))
	total_w += gap * maxi(n - 1, 0)
	var w_cells: int = total_w + maxi(stage_margin_cells, 1) * 2
	var d_cells: int = maxi(max_d + 2, maxi(stage_depth_cells, 2))
	var front_line: float = float(d_cells) * 0.5 * CELL - 0.9
	var back_z: float = -float(d_cells) * 0.5 * CELL
	var front_z: float = float(d_cells) * 0.5 * CELL
	var half_w: float = float(w_cells) * 0.5 * CELL
	var slots: Array = []
	var cursor: float = -float(total_w) * 0.5 * CELL
	for item in items:
		var wc: int = int(item["w"])
		var dc: int = int(item["d"])
		slots.append({
			"x": cursor + float(wc) * 0.5 * CELL, "z": front_line - float(dc) * 0.5 * CELL,
			"w": wc, "d": dc, "yaw": 0.0, "item": item,
		})
		cursor += float(wc + gap) * CELL
	return {
		"layout": "row", "w_cells": w_cells, "d_cells": d_cells, "hazard": true,
		"slots": slots,
		"segments": [{"x": 0.0, "z": back_z - 0.12, "length_cells": w_cells, "yaw": 0.0, "start_cap": true, "end_cap": true, "screen": true}],
		"pillars": [Vector3(-(half_w - 0.45), 0, front_z - 0.45), Vector3(half_w - 0.45, 0, front_z - 0.45)],
		"barriers": [{"x": 0.0, "z": front_z + 0.05, "length_cells": w_cells, "yaw": 0.0}],
	}


# CORNER (L) — two walls meeting at a 90° back-left corner; plinths split along both legs, facing into
# the room; one junction pillar fills the corner notch. The first step of the perimeter-path family.
func _layout_corner(items: Array) -> Dictionary:
	var n: int = items.size()
	var gap: int = 1
	var n_back: int = int(ceil(float(n) / 2.0))   # back leg gets the extra item
	var back_items: Array = items.slice(0, n_back)
	var side_items: Array = items.slice(n_back)
	var back_w: int = 0
	for it in back_items:
		back_w += int(it["w"])
	back_w += gap * maxi(back_items.size() - 1, 0)
	var side_w: int = 0
	for it in side_items:
		side_w += int(it["w"])
	side_w += gap * maxi(side_items.size() - 1, 0)
	var corner_clear: int = 2   # cells of clearance at the corner so the legs don't collide
	var run: int = maxi(back_w, side_w) + corner_clear
	var side_cells: int = run + maxi(stage_margin_cells, 1) * 2
	var half: float = float(side_cells) * 0.5 * CELL
	var back_z: float = -half
	var left_x: float = -half
	var inset: float = 0.6   # plinth front sits this far in front of its wall
	var slots: Array = []
	# Back leg — runs along +X from near the corner, plinths facing +Z (into the room).
	var cx: float = left_x + float(corner_clear) * CELL
	for it in back_items:
		var wcA: int = int(it["w"])
		var dcA: int = int(it["d"])
		slots.append({
			"x": cx + float(wcA) * 0.5 * CELL, "z": back_z + float(dcA) * 0.5 * CELL + inset,
			"w": wcA, "d": dcA, "yaw": 0.0, "item": it,
		})
		cx += float(wcA + gap) * CELL
	# Side leg — runs along +Z from near the corner, plinths rotated +90° to face +X (into the room).
	var cz: float = back_z + float(corner_clear) * CELL
	for it in side_items:
		var wcB: int = int(it["w"])
		var dcB: int = int(it["d"])
		slots.append({
			"x": left_x + float(dcB) * 0.5 * CELL + inset, "z": cz + float(wcB) * 0.5 * CELL,
			"w": wcB, "d": dcB, "yaw": PI * 0.5, "item": it,
		})
		cz += float(wcB + gap) * CELL
	return {
		"layout": "corner", "w_cells": side_cells, "d_cells": side_cells, "hazard": false,
		"slots": slots,
		"segments": [
			{"x": 0.0, "z": back_z - 0.12, "length_cells": side_cells, "yaw": 0.0, "start_cap": false, "end_cap": true, "screen": true},
			{"x": left_x - 0.12, "z": 0.0, "length_cells": side_cells, "yaw": PI * 0.5, "start_cap": true, "end_cap": false, "screen": false},
		],
		"pillars": [Vector3(left_x, 0, back_z)],
		"barriers": [],
	}




# ---------------------------------------------------------------- registry + helpers
func _build_name_index() -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry")
	if dir == null:
		return
	for fn in dir.get_files():
		if not fn.ends_with(".json"):
			continue
		var f := FileAccess.open("res://commons/artifacts/registry/" + fn, FileAccess.READ)
		if f == null:
			continue
		var data = JSON.parse_string(f.get_as_text())
		if not (data is Dictionary):
			continue
		for k in (data.get("artifacts", {}) as Dictionary).keys():
			var v = data["artifacts"][k]
			if v is Dictionary and v.has("scene") and ResourceLoader.exists(str(v["scene"])):
				var ln := str(v.get("lookup_name", k))
				_name_scene[ln] = str(v["scene"])
				_name_disp[ln] = str(v.get("name", ln))
				_name_entry[ln] = v


# Layers an artifact KEEPS even when made inert, so its controls stay usable:
# 3 (pickable) + 19 (grab handles) + 21 (area buttons). World/body layers are dropped.
const INTERACT_LAYERS := 1310724

func _make_inert(node: Node) -> void:
	# Non-blocking + non-falling, but PRESERVE interaction layers so the artifact's
	# buttons / sliders / knobs / grab still respond — you can test them with the desktop
	# crosshair (LMB press / drag, RMB grab) or in VR, instead of just looking at them.
	if node is CollisionObject3D:
		node.collision_layer = node.collision_layer & INTERACT_LAYERS
		node.collision_mask = 0
		if node is RigidBody3D:
			node.freeze = true
	elif node is SoftBody3D:
		node.collision_layer = node.collision_layer & INTERACT_LAYERS
		node.collision_mask = 0
	for c in node.get_children():
		_make_inert(c)


func _combined_aabb(node: Node) -> AABB:
	var out := AABB()
	var got := false
	if node is VisualInstance3D:
		out = (node as VisualInstance3D).global_transform * (node as VisualInstance3D).get_aabb()
		got = true
	for c in node.get_children():
		var ca := _combined_aabb(c)
		if ca.size.length() > 0.0:
			out = out.merge(ca) if got else ca
			got = true
	return out


func _short_label(nm: String, i: int) -> String:
	if nm == "":
		return "ITEM-%d" % (i + 1)
	var up := nm.to_upper()
	return up.substr(0, 14)


# Hide the artifact's floating billboard text (Label3D) so the station's 2D-in-3D
# plates are the only captions; surface-baked text (MeshInstance3D) is untouched.
func _hide_labels(node: Node, in_sign: bool = false) -> void:
	# Despite the name, this now FRAMES each curated artifact's floating text instead of hiding it:
	# the Label3D is pinned (billboard off) and gets a dark back-plate + light bezel behind it, so
	# every artifact's text reads as a framed 2D-on-surface readout. Skips text already inside a
	# HangarKit Signage/Readout (the hand-mounted signs) to avoid double-framing.
	var sig := in_sign or node.name == "Signage" or node.name == "Readout"
	if node is Label3D and not sig:
		var L := node as Label3D
		L.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		L.modulate = Color(0.09, 0.09, 0.11)   # black text on the off-white label plate
		L.outline_size = 0
		var ls := L.text.split("
")
		var ml := 1
		for ss in ls:
			ml = maxi(ml, str(ss).length())
		var w: float = clampf(float(ml) * float(L.font_size) * L.pixel_size * 0.6 + 0.05, 0.08, 1.5)
		var hh: float = clampf(float(ls.size()) * float(L.font_size) * L.pixel_size * 1.4 + 0.04, 0.05, 0.8)
		L.add_child(HangarKit.box(Vector3(0, 0, -0.014), Vector3(w + 0.03, hh + 0.03, 0.012), HangarKit.rams_body(Color(0.70, 0.68, 0.64), 0.06)))
		L.add_child(HangarKit.box(Vector3(0, 0, -0.007), Vector3(w, hh, 0.008), HangarKit.rams_body(Color(0.88, 0.86, 0.80), 0.04)))
	for c in node.get_children():
		_hide_labels(c, sig)


# Strip a leading curriculum number prefix (e.g. "1.0 a Point" -> "Point") for clean plates.
func _clean_name(s: String) -> String:
	var re := RegEx.new()
	re.compile("^\\s*\\d+(\\.\\d+)?\\s+([a-zA-Z]\\s+)?")
	var out := re.sub(s, "", false)
	out = out.strip_edges()
	return out if out != "" else s


# A framed, multi-line 2D-in-3D caption plaque (museum label) that stands PROUD of a surface:
# a light bezel + a dark emissive screen + an accent catalogue number + the wrapped name.
# Origin at the plaque centre on the mounting plane; it builds forward (+Z).
func _make_label_plaque(name_text: String, number: String) -> Node3D:
	var root := Node3D.new()
	var name_lines: Array = _wrap(name_text.to_upper(), 11)
	if name_lines.is_empty():
		name_lines = [name_text.to_upper()]
	var num_h := 0.034
	var name_h := 0.052
	var pad := 0.03
	var pw := 0.5
	var ph: float = pad * 2.0 + num_h + name_h * float(name_lines.size())
	var depth := 0.03
	# Light bezel frame.
	root.add_child(_box(Vector3(0, 0, depth * 0.5), Vector3(pw + 0.05, ph + 0.05, depth), HangarKit.rams_body(panel_color.lightened(0.06), 0.05)))
	# Dark emissive screen face, proud of the frame.
	root.add_child(_box(Vector3(0, 0, depth + 0.005), Vector3(pw, ph, 0.008), _emi(Color(0.09, 0.10, 0.12), 0.3)))
	# Accent groove under the number line.
	root.add_child(_box(Vector3(0, ph * 0.5 - pad - num_h - 0.004, depth + 0.01), Vector3(pw * 0.82, 0.006, 0.006), _emi(accent_color, 0.7)))
	# Text — number then wrapped name, stacked top-down, all crisp 2D-in-3D.
	var tz: float = depth + 0.014
	var ty: float = ph * 0.5 - pad
	var num: MeshInstance3D = BakedText.make_label_mesh(number, accent_color, Vector2(pw * 0.5, num_h * 0.85), 1400, true)
	if num:
		num.position = Vector3(0, ty - num_h * 0.5, tz)
		root.add_child(num)
	ty -= num_h
	for ln in name_lines:
		var q: MeshInstance3D = BakedText.make_label_mesh(str(ln), Color(0.94, 0.92, 0.87), Vector2(pw * 0.92, name_h * 0.82), 1400, true)
		if q:
			q.position = Vector3(0, ty - name_h * 0.5, tz)
			root.add_child(q)
		ty -= name_h
	return root


# Word-wrap a string to lines of at most max_chars (keeps whole words).
func _wrap(s: String, max_chars: int) -> Array:
	var lines: Array = []
	var cur := ""
	for w in s.split(" "):
		var word := str(w)
		if word == "":
			continue
		if cur == "":
			cur = word
		elif cur.length() + 1 + word.length() <= max_chars:
			cur += " " + word
		else:
			lines.append(cur)
			cur = word
	if cur != "":
		lines.append(cur)
	return lines


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _cs(c: Color) -> String:
	return "%f,%f,%f" % [c.r, c.g, c.b]


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]
