extends Node3D
## THE NECKLACE — an artifact order as a string of beads, ten at a time.
##
## 2026-08-26, Palle: "Can we build a tool in godot where we can horizontally
## scroll the current order of the artifacts as a necklace showing 10 artifacts
## at the time, we can add artifacts from a list and we can remove artifacts."
## 2026-08-27, Palle: "I also want a version where I can see the artifact in 1 d
## like that but for the artifact in the actual museum."
##
## SO THE SCENE CARRIES TWO STRINGS, AND TAB SWAPS BETWEEN THEM. Not two scenes:
## a second copy of 2,200 lines drifts from this one on the first repair, and the
## whole point of the museum view is that it is the SAME instrument pointed at a
## different order.
##
##   THE SPINE    commons/data/spine_order_effective.json    810 beads
##                the dealing order. Position is an INDEX, 1..810. EDITABLE:
##                every add / drop / move appends an op to the hand file.
##   THE MUSEUM   commons/data/museum_order_effective.json  1,633 beads
##                the artifacts as they STAND in the long museum, in the order a
##                visitor meets them from 0 m to 4,270 m. Position is a METRE
##                MARK. READ-ONLY, and the scene says so rather than letting the
##                curator discover it by pressing a key and having nothing happen.
##
## THE FOUR PLACES THE TWO SHAPES DIFFER (museum_order_effective.json's own
## _readme names them, and every one of them is a silent wrong answer if missed):
##   1. THE BEAD'S IDENTITY IS `at`, NOT `lookup`. 173 tokens repeat on the museum
##      string — science_screen and dark_sphere stand 26 times each, and
##      Point_Lines holds laser_measure FIVE times inside one hall. Anything that
##      keys a bead by token collides. `at` looks like "Point_Lines@9,12".
##   2. `origin` IS "map", NOT "spine". _style_bead paints anything that is not
##      the neutral origin as a hand edit, so read _meta.neutral_origin or the
##      entire string reads as edited.
##   3. `map` IS THE HALL YOU ARE STANDING IN, not the spine's "first met in".
##      Relabel by schema.
##   4. `candidates` IS EMPTY BY DESIGN. There is no add pool, because the only
##      file an edit here could touch is a map's interactables layer.
##
##   Run:  open commons/scenes/desktop_necklace.tscn in the editor and press F6.
##         (F6 = Run Current Scene. It reuses the editor's OWN engine instance,
##         which is why it is the path Palle types: a second CLI Godot fights the
##         open editor for the user:// lock and dies silently.)
##   Or:   & "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe" --path . \
##             --xr-mode off res://commons/scenes/desktop_necklace.tscn
##
##   STRING   TAB swaps the spine and the museum. Each keeps its own scroll
##            position, its own edits and its own failure, so a missing museum
##            file never takes the spine down with it.
##   SCROLL   wheel · LEFT/RIGHT one bead · PgUp/PgDn ten · Home/End the ends
##            · [ / ] previous / next BAND (chapter on the spine, HALL in the
##            museum) · Shift+[ / ] jumps a whole chapter in the museum, because
##            207 halls is a long walk one room at a time
##            · click a bead to bring it to focus
##   EDIT     A open the add list · click a row to insert it at the chosen
##            position · X drop the bead under the cursor from the deal
##            · , / . move the focused bead within its chapter
##            · U (or Ctrl+Z) take the last edit back — it pops the trailing op
##              from the hand file, so the file agrees with the screen
##            ALL FIVE REFUSE ON THE MUSEUM STRING, each with the reason.
##   LOOK     L live body on the focus bead (off by default: cold, it costs ~98 ms
##            and one of the fifteen GPU tokens costs a great deal more)
##            · C push the camera in · R what this string is, verbatim from its
##            own _report · H help · F10 back to the menu
##
## WHAT IT WRITES, AND WHAT IT MUST NEVER WRITE.
##
## commons/data/spine_artifact_order.json is GENERATED — build_spine_artifact_order.py
## rewrites all 810 rows from 23 sequences and 261 maps, and it has already been
## regenerated twice this summer (25 ribbon halls landed in one month). An edit
## made in that file survives until the next run and then vanishes with no error.
## So this scene never opens it. It reads the DERIVED answer and appends to the
## HAND:
##
##   READ   commons/data/spine_order_effective.json   the order + liveness +
##                                                    chapter bands + add pool
##   WRITE  commons/data/spine_order_ops.json         ops appended, never rewritten
##
## and `python tools/necklace_order.py --apply` replays the ops over a freshly
## re-read generated order to rebuild both derived files. That is the same
## separation commons/data/map_authored.json + tools/em_map_halls.py already
## carry, for the same reason.
##
## Positions in an op are ANCHOR-RELATIVE and never an index. em_map_halls.py
## carries the scar verbatim: cropping a tile to its content bbox moved (0,0) and
## "silently re-addressed every saved ruling". {"lookup": "origin", "index": 4}
## is that failure — insert one artifact upstream and the op is about a different
## neighbour, with nothing visible until someone walks it.
##
## A BEAD IS A CAPTURE TILE, AND ONLY THE FOCUS CAN BE A LIVE BODY.
##
## Measured over the 810: 798 (98.5%) already have a capture on disk, so a tile
## is the artifact's own likeness and not a gauge of it. Ten LIVE bodies was
## refused on numbers, not taste:
##   · the fifteen GPU/marching-cubes tokens sit at order indices 656-673, so ONE
##     ten-wide window holds NINE of them, built and freed on every scroll notch —
##     the documented queue_free-mid-generation segfault class;
##   · 143 of 810 declare dna.fixture, meaning _ready() is gated and builds
##     nothing standalone: one bead in six would be an empty slot;
##   · registry max_dimension_m runs 0.00 m to 300.00 m, a 175x spread, and
##   · ~98 ms per interactable (1281 ms for thirteen, GridInteractablesComponent.gd:133)
##     is a full second of frozen scroll for a window of ten.
## So: ten tiles, one optional live body at the focus, normalised into a fixed
## bead volume so a 12 m artifact and a 0.2 m one both read on the line, with the
## real metres on the label where the size information belongs.

# ── the store ───────────────────────────────────────────────────────────────
const EFFECTIVE_DEFAULT := "res://commons/data/spine_order_effective.json"
const MUSEUM_DEFAULT := "res://commons/data/museum_order_effective.json"
const OPS_DEFAULT := "res://commons/data/spine_order_ops.json"
const MUSEUM_APPLY_CMD := "python tools/museum_necklace.py --apply"
const SRC_SPINE := 0
const SRC_MUSEUM := 1
## The one sentence every refused verb ends with. Written once so the four
## refusals cannot drift into four different explanations of the same rule.
const READ_ONLY_WHY := ("this string is the maps as they STAND. The only file an edit "
	+ "here could touch is a map's interactables layer — a heavier, different act, and "
	+ "the repo's own pathfinder cannot certify such an edit. TAB back to the spine to "
	+ "change the deal.")
## NAMED SO THE BAN IS GREPPABLE. This scene never opens this path — not for
## reading either, so no future edit can quietly promote a read into a write.
const GENERATED_NEVER_TOUCHED := "res://commons/data/spine_artifact_order.json"
const SELF_PATH := "commons/scenes/desktop_necklace.gd"
const APPLY_CMD := "python tools/necklace_order.py --apply"

const WHS := preload("res://commons/scenes/wall_hangar/WHStyle.gd")

# ── the string ──────────────────────────────────────────────────────────────
const WINDOW := 10          ## ten beads across, the whole request
const FOCUS_SLOT := 4       ## four to the left of the focus, five to the right
const PITCH := 2.25         ## metres between kin
## The ribbon ruling, measured from the color chapter: 3 cells between strangers,
## 1 between kin. A chapter seam therefore reads as a WIDER gap before the eye
## ever reaches the banner naming it.
const SEAM_EXTRA := 1.5
## THE MUSEUM'S SEAMS ARE SMALLER, AND THE NUMBER IS THE FRUSTUM'S, NOT TASTE.
## The spine has 23 chapters over 810 beads, so a ten-wide window crosses at most
## one seam and 1.5 m of extra fits. The museum has 207 HALLS over 1,633 beads and
## runs of one- and two-bead ribbon halls, so a window can cross FIVE seams in the
## five steps between the focus and bead ten — measured, not assumed.
##   The frustum half-width at the string plane is 15.4 * tan(42) = 13.87 m and the
## widest caption reaches 0.83 m past a bead centre, so a bead centre may sit at
## most 13.04 m out. At 0.25 / 0.50 the worst window in the whole 1,633 puts a
## bead centre at 12.75 m — the SAME worst case the spine already survives, so the
## museum adds no new clipping class. At 0.30 / 0.60 it is 13.05 and bead ten's
## caption starts leaving the frame.
const MUSEUM_SEAM_HALL := 0.25
const MUSEUM_SEAM_CHAPTER := 0.50
## A necklace sags. 90 m of radius drops the fifth bead out by 0.67 m — enough
## that the line reads as one strung curve rather than a row of tiles.
const ARC_R := 90.0
## THE CAPTIONS HANG BELOW THE BEAD, SO THE STRING'S HEIGHT IS THE CAPTIONS'
## CLEARANCE. At 1.52 they were UNDER THE FLOOR: the plate sits at local y -0.80,
## the token caption at -1.62 and the status line at -1.98, so the caption landed
## at world -0.10 — INSIDE the 0.12 m floor slab built by _build_stage — and the
## status line at -0.46, beneath it. Label3D is depth-tested and an opaque slab in
## front of it wins, so the first frame anyone rendered showed nine of ten beads
## with no name on them and the entire DEAD / NOT A BODY / HAND / MOVED apparatus
## invisible. probe_necklace_floor.gd measured 20 of 70 parts occluded.
##   3.40 - 1.62 = 1.78 m for the caption and 3.40 - 1.98 = 1.42 m for the status
## line; at the worst measured anchor sag (0.70 m at the window ends) the status
## line still stands at 0.72 m, clear of the floor's 0.00 m top surface.
## The camera derives from this (_build_stage and the C key both read STRING_Y),
## so the framing is unchanged — only the ground falls away.
const STRING_Y := 3.40
## THE MUSEUM STRING HANGS HIGHER, AND ONLY BECAUSE OF THE FLOOR. A museum bead
## carries two lines the spine bead does not, so its lowest text reaches local
## -2.65 against the spine's -2.10. At STRING_Y 3.40 and the worst window sag
## (0.90 m at a 12.75 m offset) that lands at -0.15 m — UNDER the 0.12 m slab, the
## exact fault the note above was written about, reintroduced by a taller bead.
##   The camera derives from the string (see _apply_camera and _string_y), so
## raising both together moves NOTHING on screen: the bead band, the ten-wide
## framing and the panel bounds are all unchanged, and only the floor falls away.
## 4.20 leaves 0.65 m of clearance at the worst sag.
const STRING_Y_MUSEUM := 4.20
const BEAD_M := 1.30        ## the fixed bead volume every body is normalised into
const TILE_W := 1.16
const SEGMENTS := 72        ## string segments drawn, recoloured per chapter run

## Hysteresis. Tiles are cheap, so build a slack band either side of the ten and
## free only well beyond it: a one-notch scroll must never free and rebuild a
## bead, which at ~98 ms each is a visible hitch even before a GPU token is in
## the window.
const SLACK_BUILD := 3
const SLACK_FREE := 7

const SCROLL_LERP := 12.0

# ── the live body ───────────────────────────────────────────────────────────
## probe_aabb_hogs.gd:55 — two process frames photographs a half-built artifact.
const LIVE_SETTLE := 0.35
## Never build during an active scroll gesture.
const LIVE_DEBOUNCE := 0.30
## Never free a body younger than this. queue_free() is not what segfaults a
## marching-cubes artifact; freeing it inside its own generation window is.
const LIVE_MIN_DWELL := 0.60
## A 4 cm token blown to 1.3 m is a lie about the corpus. Cap the up-scale and
## let the label carry the truth.
const MAX_UPSCALE := 8.0

const PALETTE_CAP := 150    ## WHPalette has no cap; 1,875 Buttons in one frame is a stall

# ── injectable paths (probe isolation) ──────────────────────────────────────
## Palle plays the desktop museum while probes run, so a probe must never write
## a file a live session reads. Set these with inst.set("ops_path", ...) BEFORE
## add_child, or pass --necklace-ops= / --necklace-effective= on the command
## line. Plain String vars: Object.set() on a typed property of the wrong type is
## refused in SILENCE, so both sides speak String and the resolved value is read
## back into the HUD.
var ops_path: String = ""
var effective_path: String = ""
var museum_path: String = ""

# ── state ───────────────────────────────────────────────────────────────────
var _order: Array = []          # the effective order, bead 0 first
## THE BAND, not "the chapter". On the spine a band IS a chapter (a sequence run).
## In the museum a band is a HALL — the room the visitor is standing in — because
## at bead scale that is the boundary the walk actually has: 207 halls over 22
## chapters, average 7.6 beads to a room. Colour still runs by chapter, so the eye
## reads twenty-two colour runs cut by two hundred room seams.
var _bands: Array = []          # [{key, sequence, i0, n, in_spine, built_n, states}]
var _candidates: Array = []     # the add pool, already liveness-filtered
var _meta: Dictionary = {}
var _report: Dictionary = {}
var _station: PackedFloat32Array = PackedFloat32Array()   # cumulative x per bead

## ── the two strings ─────────────────────────────────────────────────────────
## Each source keeps its OWN order, bands, scroll position, undo stack and
## failure. Switching must not discard the spine's in-session edits (they are
## already appended to the hand file, so dropping the screen state would leave the
## file ahead of the view), and a museum file that will not parse must not take
## the spine down with it — which is exactly what one global _fatal did.
var _source: int = SRC_SPINE
var _slots: Array = [{}, {}]
## Read from _meta, per source, on every load and every switch. Never hardcoded:
## the file names its own shape and the scene obeys it.
var _schema: String = ""
var _is_museum: bool = false
var _read_only: bool = false
var _neutral_origin: String = "spine"
var _identity_field: String = "lookup"

var _pos: float = 0.0           # the bead standing at the focus, animated
var _want: float = 0.0
var _hover: int = -1
var _beads: Dictionary = {}     # order index -> {anchor, plate, edge, tile, cap, sub, mount}
var _tex_cache: Dictionary = {} # token -> ImageTexture or null

var _ops_rev_file: int = -1     # ops file revision, as last written/read
var _ops_rev_derived: int = -1  # the revision spine_order_effective.json was built from
var _pending: int = 0           # ops appended this session, not yet applied
var _fatal: String = ""
var _notice: String = ""
var _ops_broken: bool = false   # the hand file exists and will not parse
var _ops_broken_why: String = ""
## The undo stack, this session only. Each entry is the scene state an edit
## changed, so undo_last() can reverse the screen AND pop the trailing op — the
## scene never re-derives the applier's semantics, it only takes back what it
## itself appended.
var _undo: Array = []

var _live_on: bool = false
var _live_node: Node3D = null
var _live_index: int = -1
var _live_born: float = 0.0
var _live_want_index: int = -1
var _live_still: float = 0.0
var _live_note: String = ""
var _live_fitted: bool = false
var _chapter_in_spine_cache: Dictionary = {}
var _last_focus: int = -1
var _registry_params: Dictionary = {}   # token -> merged config, scanned on demand
var _registry_scanned: bool = false

var _cam: Camera3D
var _cam_near: bool = false
var _string_segs: Array = []
var _hud: Label
var _help: Label
var _detail_box: VBoxContainer
var _detail_panel: PanelContainer
var _fatal_panel: PanelContainer
var _fatal_label: Label
var _why_panel: PanelContainer
var _why_box: VBoxContainer
var _palette: PanelContainer
var _pal_search: LineEdit
var _pal_cat: OptionButton
var _pal_where: OptionButton
var _pal_scope: CheckBox
var _pal_count: Label
var _pal_list: VBoxContainer
var _banner: Label


# ────────────────────────────────────────────────────────────────── lifecycle
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--necklace-ops="):
			ops_path = s.split("=", true, 1)[1]
		elif s.begins_with("--necklace-effective="):
			effective_path = s.split("=", true, 1)[1]
		elif s.begins_with("--necklace-museum="):
			museum_path = s.split("=", true, 1)[1]
	if ops_path.strip_edges() == "":
		ops_path = OPS_DEFAULT
	if effective_path.strip_edges() == "":
		effective_path = EFFECTIVE_DEFAULT
	if museum_path.strip_edges() == "":
		museum_path = MUSEUM_DEFAULT

	_build_stage()
	_build_ui()
	_load_effective()
	_read_ops_revision()
	_reindex()
	_refresh_window(true)
	_update_hud()


func _process(delta: float) -> void:
	if _fatal != "":
		return
	var moved := absf(_want - _pos) > 0.0005
	if moved:
		_pos = lerpf(_pos, _want, clampf(delta * SCROLL_LERP, 0.0, 1.0))
		if absf(_want - _pos) <= 0.0005:
			_pos = _want
		_place_beads()
		_live_still = 0.0
	else:
		_live_still += delta
	_update_hover()
	_tick_live(delta)


# ─────────────────────────────────────────────────────────────────── the data
func _load_effective() -> void:
	_load_source(_source)


## Read one source's derived file into the live arrays. Sets _fatal for THAT
## source (the caller stashes it), and derives the schema-driven fields from
## _meta rather than assuming either shape.
func _load_source(which: int) -> void:
	var path: String = museum_path if which == SRC_MUSEUM else effective_path
	var cmd: String = MUSEUM_APPLY_CMD if which == SRC_MUSEUM else APPLY_CMD
	_fatal = ""
	_order = []
	_bands = []
	_candidates = []
	_meta = {}
	_report = {}
	_chapter_in_spine_cache = {}
	var est: Dictionary = _read_json_state(path)
	var doc: Dictionary = est.get("doc", {}) as Dictionary
	if doc.is_empty():
		# REQUIREMENT: open and SAY SO. An empty line with no explanation is the
		# failure this project keeps writing memory files about. And say WHICH:
		# "missing" and "there but broken" are different repairs.
		var what := ""
		match str(est.get("state", "")):
			"absent": what = "is missing"
			"empty": what = "exists and is EMPTY"
			"ok": what = "parses but holds nothing"
			_: what = "EXISTS AND WILL NOT PARSE — " + str(est.get("why", ""))
		_fatal = ("the derived order %s:\n    %s\n\n" % [what, path]
			+ "build it with\n    %s\n\n" % cmd
			+ "This scene deliberately does not fall back to reading\n"
			+ "commons/data/spine_artifact_order.json: that file is generated,\n"
			+ "and a tool that opens it is one edit away from writing it.\n\n"
			+ "TAB still swaps strings — the other one is unaffected.")
		_apply_schema()
		_show_fatal()
		return
	_meta = doc.get("_meta", {}) if doc.get("_meta") is Dictionary else {}
	_report = doc.get("_report", {}) if doc.get("_report") is Dictionary else {}
	_schema = str(doc.get("schema", ""))
	var raw: Variant = doc.get("order", [])
	_order = (raw as Array) if raw is Array else []
	var ch: Variant = doc.get("chapters", [])
	var chapters: Array = (ch as Array) if ch is Array else []
	var cd: Variant = doc.get("candidates", [])
	_candidates = (cd as Array) if cd is Array else []
	# The derived file already judged which chapters the spine still owns
	# (array_tutorial: 31 artifacts, dissolved 2026-08-24, still in the generated
	# order). Keep that judgement across a local reindex rather than re-deciding.
	for c in chapters:
		_chapter_in_spine_cache[str((c as Dictionary).get("sequence", ""))] = \
			bool((c as Dictionary).get("in_spine", true))
	_apply_schema()
	if which == SRC_SPINE:
		_ops_rev_derived = int(_meta.get("ops_revision", -1))
	if _order.is_empty():
		_fatal = ("the derived order is present but holds no beads:\n    %s\n\n"
			+ "re-derive it with\n    %s") % [path, cmd]
		_show_fatal()
		return
	_candidates.sort_custom(func(a, b) -> bool:
		return str((a as Dictionary).get("lookup", "")).naturalnocasecmp_to(
			str((b as Dictionary).get("lookup", ""))) < 0)


## THE FILE NAMES ITS OWN SHAPE. Every one of these is a silent wrong answer if
## assumed: neutral_origin absent means every museum bead paints as a hand add,
## identity_field absent means 173 repeating tokens collide, read_only absent
## means the edit verbs write ops nobody can apply.
func _apply_schema() -> void:
	_is_museum = _schema.begins_with("museum_order_effective")
	_neutral_origin = str(_meta.get("neutral_origin", "spine"))
	_identity_field = str(_meta.get("identity_field", "lookup"))
	_read_only = bool(_meta.get("read_only", false))
	if _fatal != "":
		# a source that would not load still knows WHICH source it is, so the HUD,
		# the help text and the refusals stay correct while it is on screen
		_is_museum = _source == SRC_MUSEUM
		_read_only = _is_museum


func _read_ops_revision() -> void:
	var st: Dictionary = _read_json_state(ops_path)
	var state := str(st.get("state", "absent"))
	_ops_broken = not _state_is_writable(state)
	_ops_broken_why = str(st.get("why", ""))
	if _ops_broken:
		# LOUD, AND EVERY EDIT REFUSED. _append_op re-probes and returns false in
		# this state, so A / X / , / . all decline rather than writing a fresh
		# document over a file that is somebody's unparsed hand.
		_ops_rev_file = -1
		_notice = "the hand file EXISTS and will not parse — do not edit (%s)" % _ops_broken_why
		return
	var doc: Dictionary = st.get("doc", {}) as Dictionary
	if doc.is_empty():
		_ops_rev_file = -1
		# Not fatal: no hand file yet IS the shipped state, and it means the
		# museum follows the generated order. Say which, do not imply an error.
		_notice = "no hand file yet (%s) — this is the generated order, untouched" % ops_path.get_file()
		return
	var m: Dictionary = doc.get("_meta", {}) if doc.get("_meta") is Dictionary else {}
	_ops_rev_file = int(m.get("ops_revision", 0))
	var n: int = int(m.get("ops", 0))
	if n == 0:
		_notice = "no hand edits yet (0 ops) — this is the generated order"
	else:
		_notice = "%d hand op(s), revision %d" % [n, _ops_rev_file]


# ────────────────────────────────────────────────────────────── the two strings
## THE BEAD'S IDENTITY. `lookup` on the spine, where a token appears once; `at` in
## the museum, where 173 tokens repeat and Point_Lines holds laser_measure five
## times inside one hall. Read from _meta.identity_field, so the file decides.
func _identity_of(row: Dictionary) -> String:
	var v: Variant = row.get(_identity_field)
	if v == null or str(v) == "":
		return str(row.get("lookup", ""))
	return str(v)


func toggle_source() -> void:
	set_source_index(SRC_MUSEUM if _source == SRC_SPINE else SRC_SPINE)


## Swap the string under the same instrument. The outgoing source is STASHED
## whole — order, bands, scroll, undo stack, its own failure — because the spine
## may carry this session's edits and dropping them would leave the hand file
## ahead of the screen, which is the one disagreement this tool exists to prevent.
func set_source_index(which: int) -> void:
	var w: int = clampi(which, SRC_SPINE, SRC_MUSEUM)
	if w == _source:
		return
	_stash_slot()
	# every bead and any live body belongs to the OUTGOING order; nothing about
	# them survives the swap
	_free_live()
	_live_index = -1
	_live_want_index = -1
	for k in _beads.keys():
		var node: Node3D = _node_or_null((_beads[k] as Dictionary).get("anchor"))
		if node != null:
			node.queue_free()
	_beads.clear()
	_last_focus = -1
	_hover = -1
	_source = w
	if _palette != null:
		_palette.visible = false
	if _why_panel != null:
		_why_panel.visible = false
	var slot: Dictionary = _slots[w] as Dictionary
	if slot.is_empty():
		_undo = []
		_notice = ""
		_load_source(w)
	else:
		_restore_slot(slot)
	_apply_schema()
	_apply_camera()
	_restring()
	_update_help()
	_reindex()
	_show_fatal()
	if _fatal == "":
		_refresh_window(true)
	_refresh_why()
	_update_hud()


func _stash_slot() -> void:
	_slots[_source] = {
		"order": _order, "bands": _bands, "candidates": _candidates,
		"meta": _meta, "report": _report, "schema": _schema,
		"pos": _pos, "want": _want, "undo": _undo, "notice": _notice,
		"fatal": _fatal, "in_spine_cache": _chapter_in_spine_cache,
		"size": _order.size(),
	}


func _restore_slot(slot: Dictionary) -> void:
	_order = slot.get("order", []) as Array
	_bands = slot.get("bands", []) as Array
	_candidates = slot.get("candidates", []) as Array
	_meta = slot.get("meta", {}) as Dictionary
	_report = slot.get("report", {}) as Dictionary
	_schema = str(slot.get("schema", ""))
	_undo = slot.get("undo", []) as Array
	_notice = str(slot.get("notice", ""))
	_fatal = str(slot.get("fatal", ""))
	_chapter_in_spine_cache = slot.get("in_spine_cache", {}) as Dictionary
	_pos = float(slot.get("pos", 0.0))
	_want = float(slot.get("want", 0.0))


func source_name() -> String:
	return "museum" if _source == SRC_MUSEUM else "spine"


## seq_i / seq_n and the chapter bands are DERIVED here rather than trusted from
## the file, because a local add or drop changes both and the scene must show the
## edit immediately — the derived file is only rebuilt by --apply.
func _reindex() -> void:
	_bands.clear()
	var i: int = 0
	while i < _order.size():
		var key := _band_key(_order[i])
		var j: int = i
		while j < _order.size() and _band_key(_order[j]) == key:
			j += 1
		var n: int = j - i
		var built_n: int = 0
		var spine_n: int = 0
		var states: Dictionary = {}
		for k in range(i, j):
			var r: Dictionary = _order[k]
			r["band_i"] = k - i
			r["band_n"] = n
			r["band_ord"] = _bands.size()
			if _is_museum:
				# seq_i / seq_n are the FILE's position-within-chapter and the museum
				# string cannot be edited, so they are left exactly as derived. On
				# the spine the band IS the chapter, so the two agree by definition
				# and an edit must move both.
				if bool(r.get("built", true)):
					built_n += 1
				if bool(r.get("in_spine", true)):
					spine_n += 1
				var st := str(r.get("state", ""))
				states[st] = int(states.get(st, 0)) + 1
			else:
				r["seq_i"] = k - i
				r["seq_n"] = n
		var seq := str((_order[i] as Dictionary).get("sequence", ""))
		_bands.append({
			"key": key, "sequence": seq, "i0": i, "n": n,
			"in_spine": (spine_n > 0) if _is_museum else _in_spine(seq),
			"built_n": built_n, "in_spine_n": spine_n, "states": states,
		})
		i = j
	_rebuild_stations()


## The run the string is cut into. Spine: the chapter. Museum: the HALL — see the
## note on _bands. A band change is what SEAM_EXTRA widens, so in the museum the
## eye reads a room boundary before it reads the banner naming it.
func _band_key(row: Dictionary) -> String:
	if _is_museum:
		return str(row.get("hall", ""))
	return str(row.get("sequence", ""))


func _in_spine(seq: String) -> bool:
	return bool(_chapter_in_spine_cache.get(seq, true))


func _rebuild_stations() -> void:
	_station.resize(_order.size())
	var x: float = 0.0
	var prev := ""
	var prev_seq := ""
	for i in _order.size():
		var row: Dictionary = _order[i]
		var key := _band_key(row)
		var seq := str(row.get("sequence", ""))
		if i > 0:
			var extra: float = 0.0
			if _is_museum:
				# a chapter seam is a whole building ending, so it opens wider than
				# the room seam inside it — both bounded by the frustum, see the
				# MUSEUM_SEAM_* note
				if seq != prev_seq:
					extra = MUSEUM_SEAM_CHAPTER
				elif key != prev:
					extra = MUSEUM_SEAM_HALL
			elif key != prev:
				extra = SEAM_EXTRA
			x += PITCH + extra
		_station[i] = x
		prev = key
		prev_seq = seq


func _station_at(p: float) -> float:
	if _station.is_empty():
		return 0.0
	var lo: int = clampi(int(floorf(p)), 0, _station.size() - 1)
	var hi: int = clampi(lo + 1, 0, _station.size() - 1)
	var t: float = clampf(p - float(lo), 0.0, 1.0)
	return lerpf(_station[lo], _station[hi], t)


# ─────────────────────────────────────────────────────────────────── the stage
func _build_stage() -> void:
	# floor and backdrop, flat museum tones — the pearl-lab end of the house
	# palette (0.10,0.10,0.12), so a photographic tile reads against it.
	_slab(Vector3(0, -0.06, 0), Vector3(140, 0.12, 26), Color(0.115, 0.12, 0.145))
	_slab(Vector3(0, 4.2, -7.0), Vector3(140, 12.0, 0.4), Color(0.085, 0.09, 0.11))

	_cam = Camera3D.new()
	# KEEP_WIDTH so `fov` is HORIZONTAL: the ten beads must stay ten beads when
	# the window is resized, and a vertical fov would eat the ends on a wide one.
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	## 78.0 CUT THE TENTH BEAD OFF AT EVERY CHAPTER SEAM. probe_necklace_frame.gd
	## unprojected every plate centre and both edges at all 801 window positions:
	## 110 of them clipped a bead, and in all 110 the bead's CENTRE was outside the
	## frustum — 22 chapter boundaries x 5 window positions, 13.7% of every scroll
	## position. SEAM_EXTRA adds 1.5 m at a seam and the window is anchored at slot
	## 4, so a seam to the RIGHT of the focus pushes bead ten past the edge.
	##   At 78 the half-width at the string plane is 15.4 * tan(39) = 12.47 m; the
	## worst case needs 12.71 (centre) + 0.66 (plate half) = 13.37 m, and the
	## caption is wider still at ~0.73 m half. 84 gives 15.4 * tan(42) = 13.87 m.
	## KEEP_WIDTH means fov is HORIZONTAL, so this holds on every window size.
	_cam.fov = 84.0
	_cam.rotation_degrees = Vector3(-2.0, 0, 0)
	add_child(_cam)
	_apply_camera()
	_cam.make_current()

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 34, 0)
	sun.light_energy = 1.05
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-14, -128, 0)
	fill.light_energy = 0.35
	add_child(fill)

	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.075, 0.08, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.66, 0.68, 0.74)
	e.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = e
	add_child(we)
	# AND on the camera. 61 of the 810 carry their own WorldEnvironment; a
	# camera-level Environment overrides every one of them for this view
	# (room_line_sketcher.gd:127), which a WorldEnvironment node cannot.
	_cam.environment = e

	_build_string()


func _build_string() -> void:
	# The line itself, drawn once and recoloured per chapter run. Beads flow
	# ALONG it; it never moves, which is what makes the scroll read as travel
	# down one continuous string rather than a conveyor of tiles.
	var span: float = float(SLACK_BUILD + WINDOW) * (PITCH + SEAM_EXTRA * 0.3)
	for s in SEGMENTS:
		var t0: float = -span + (2.0 * span) * (float(s) / float(SEGMENTS))
		var t1: float = -span + (2.0 * span) * (float(s + 1) / float(SEGMENTS))
		var mid: float = (t0 + t1) * 0.5
		var seg := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(absf(t1 - t0) * 1.04, 0.028, 0.028)
		seg.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.43, 0.47)
		mat.roughness = 0.5
		seg.material_override = mat
		_place_on_arc(seg, mid)
		add_child(seg)
		_string_segs.append({"node": seg, "mat": mat, "x": mid})


## Position and tilt a node at arc-length `d` from the focus. The tangent angle
## is -a, so a bead threaded here tips exactly the way the string does.
func _place_on_arc(n: Node3D, d: float) -> void:
	var a: float = d / ARC_R
	n.position = Vector3(ARC_R * sin(a), _string_y() - ARC_R * (1.0 - cos(a)), 0.0)
	n.rotation = Vector3(0.0, 0.0, -a)


func _string_y() -> float:
	return STRING_Y_MUSEUM if _is_museum else STRING_Y


## The camera is DERIVED from the string, both here and on the C key, so the two
## can never drift apart. Everything on screen is a function of local y.
func _apply_camera() -> void:
	if _cam == null:
		return
	_cam.position = Vector3(0.0, _string_y() + (0.0 if _cam_near else 0.18),
		7.4 if _cam_near else 15.4)


## The string itself does not move with the scroll, but it DOES move with the
## source, because the two strings hang at different heights.
func _restring() -> void:
	for s in _string_segs:
		var seg: Dictionary = s
		var node: Node3D = _node_or_null(seg.get("node"))
		if node != null:
			_place_on_arc(node, float(seg["x"]))


# ────────────────────────────────────────────────────────────────── the beads
func _refresh_window(force: bool) -> void:
	if _fatal != "":
		return
	var wf: int = _win_first()
	var lo: int = maxi(0, wf - SLACK_BUILD)
	var hi: int = mini(_order.size() - 1, wf + WINDOW - 1 + SLACK_BUILD)
	for i in range(lo, hi + 1):
		if not _beads.has(i):
			_beads[i] = _build_bead(i)
	# Free only well outside the band. A tile is cheap, but rebuilding one per
	# notch is churn, and churn is what put a GPU body inside its own generation
	# window in the first place.
	var flo: int = wf - SLACK_FREE
	var fhi: int = wf + WINDOW - 1 + SLACK_FREE
	for k in _beads.keys():
		var idx: int = int(k)
		if idx < flo or idx > fhi:
			var b: Dictionary = _beads[idx]
			var node: Node3D = _node_or_null(b.get("anchor"))
			if node != null:
				node.queue_free()
			_beads.erase(idx)
	if force:
		for i2 in _beads.keys():
			_style_bead(int(i2))
	_place_beads()


func _build_bead(i: int) -> Dictionary:
	var row: Dictionary = _order[i]
	var token := str(row.get("lookup", ""))
	var anchor := Node3D.new()
	# THE IDENTITY, NOT THE TOKEN. 173 museum tokens repeat and Point_Lines holds
	# laser_measure five times, so `bead_25_laser_measure` names four other beads
	# as well. `at` is unique by construction. Godot rejects @ , : . / in a node
	# name and substitutes silently, so sanitise here rather than letting the
	# engine invent one.
	var ident := _identity_of(row).replace("@", "-at-").replace(",", "_")
	anchor.name = "bead_%d_%s" % [i, ident]
	# force_readable_name: add_child defaults to FALSE, and a bead rebuilt in the
	# same frame as a queue_free of the same name gets @Node3D@N instead. Every
	# necklace probe finds beads by node name, so in that state a probe measures an
	# EMPTY SET and reports a clean pass.
	add_child(anchor, true)

	# the bail — the little ring the string threads through. It is what makes
	# ten tiles read as a necklace instead of a filmstrip.
	var bail := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.045
	tm.outer_radius = 0.085
	bail.mesh = tm
	bail.rotation_degrees = Vector3(90, 0, 0)
	bail.position = Vector3(0, 0.02, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.62, 0.63, 0.67)
	bmat.metallic = 0.5
	bmat.roughness = 0.35
	bail.material_override = bmat
	anchor.add_child(bail)

	# the status edge, behind the plate: red dead, amber not-a-body, accent hand
	var edge := MeshInstance3D.new()
	var em := BoxMesh.new()
	em.size = Vector3(1.44, 1.44, 0.035)
	edge.mesh = em
	edge.position = Vector3(0, -0.80, -0.055)
	var emat := StandardMaterial3D.new()
	edge.material_override = emat
	anchor.add_child(edge)

	# the bead body — a locket carrying the artifact's own likeness
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.32, 1.32, 0.07)
	plate.mesh = pm
	plate.position = Vector3(0, -0.80, -0.02)
	var pmat := StandardMaterial3D.new()
	pmat.roughness = 0.62
	plate.material_override = pmat
	anchor.add_child(plate)

	var tile := Sprite3D.new()
	tile.name = "Tile"
	tile.position = Vector3(0, -0.80, 0.03)
	# no billboard: the camera is fixed at +Z and never crosses the string plane,
	# so the tile faces it and stays square to the arc's tilt.
	tile.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	# unshaded: a capture is an already-lit photograph, and letting the stage's
	# key light fall on it again darkens the one thing the bead exists to show
	tile.shaded = false
	tile.double_sided = false
	tile.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	anchor.add_child(tile)
	var tex: ImageTexture = _capture_texture(token)
	if tex != null:
		tile.texture = tex
		tile.pixel_size = TILE_W / maxf(1.0, float(tex.get_width()))
	else:
		tile.visible = false

	# 12 of the 810 have no capture anywhere. Spell the token on the plate
	# rather than showing a blank bead that reads as a broken slot.
	var noimg := Label3D.new()
	noimg.text = token.replace("_", "\n")
	noimg.font_size = 30
	noimg.position = Vector3(0, -0.80, 0.05)
	noimg.modulate = Color(0.72, 0.74, 0.80)
	noimg.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	noimg.visible = tex == null
	anchor.add_child(noimg)

	# where a live body stands when L is on: in FRONT of the plate, so the tile
	# it replaces is still the same bead.
	var mount := Node3D.new()
	mount.name = "Mount"
	mount.position = Vector3(0, -1.46, 0.62)
	anchor.add_child(mount)

	# CAPTIONS ARE Label3D, NOT TextScreen, on purpose. TextScreen is the
	# canonical way to hang text in the MUSEUM, and it bakes glyphs into an
	# albedo — ten of those rebuilt on every scroll notch is a bake per bead per
	# notch. The reversal Label3D is banned for cannot happen here: the camera is
	# fixed at +Z and never gets behind the string. Scaffolding, not an exhibit.
	var cap := Label3D.new()
	cap.text = token
	cap.font_size = 34
	# WRAPPED, because the beads are 2.25 m apart and the corpus holds tokens
	# like `interactive_point_origin_force` — 30 characters, about 3 m unwrapped,
	# straight through both neighbours. 290 px is a shade wider than the plate.
	cap.width = 290.0
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.position = Vector3(0, -1.62, 0.05)
	cap.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	anchor.add_child(cap)

	var sub := Label3D.new()
	sub.font_size = 24
	sub.width = 330.0
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	## WHERE THE SPACE ACTUALLY IS, measured off the rendered frame rather than
	## guessed. On a 900 px window the HUD holds 12-196, the banner 202-234, the
	## detail panel 12-396 on the right, and the help 750-890. The bead band itself
	## occupies 430-575. So there is 34 px of usable room above the string on the
	## right-hand beads and 165 px below every bead — and 165 px is 2.86 m at the
	## string plane, which is where two more lines have to go.
	##   The first attempt stacked all three above the string and the panel covered
	## the top two lines of beads nine and ten. The second put the status line at
	## -1.98 and it collided with the focus bead's two-line 46 pt caption, which
	## reaches -1.85. This is the third: caption, metre, hall, state, each with its
	## own lane, and the string raised so the last of them clears the floor.
	sub.position = Vector3(0, -2.58 if _is_museum else -1.98, 0.05)
	if _is_museum:
		# 380 px is 1.90 m of world, half of it 0.95 — and a bead centre may sit
		# 12.75 m out, so 13.70 against the frustum's 13.87. The last 17 cm is the
		# whole margin; do not widen this without redoing the MUSEUM_SEAM sum.
		sub.width = 380.0
	sub.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sub.modulate = Color(0.68, 0.70, 0.76)
	anchor.add_child(sub)

	## THE MUSEUM'S TWO EXTRA LINES HANG ABOVE THE STRING, NOT BELOW IT, AND THE
	## REASON IS THE FLOOR. Everything below the bead is already spoken for down to
	## y -1.98, which at the worst window sag (0.90 m at a 12.75 m offset) lands the
	## status line at 0.52 m — a third line at -2.26 would sit at 0.24 m and the
	## next repair that widened a seam would push it under the slab, which is the
	## exact fault STRING_Y's note was written about. Above the string there is
	## 7.8 m of frame on a 16:9 window and nothing to collide with.
	##   It also reads better: a metre mark is a position on a ruler, and the string
	## IS the ruler. Hidden on the spine, where position is an index and the HUD
	## already carries it.
	## THE SIZES ARE WHAT THE RENDERED FRAME SAID, NOT WHAT THE GEOMETRY SUGGESTED.
	## At the spine's 22 / 24, both lines came back as unreadable grey smears in a
	## 1600x900 shot — the string sits ~1/6 of the frame high and a Label3D glyph is
	## font_size * pixel_size metres, so 22 is 0.11 m of world text seen from 15.4 m.
	## 28 and 44 read. The wrap WIDTHS are unchanged, because width is what the
	## frustum pays for: a bead centre may sit 13.04 m out and the widest caption
	## already reaches 0.83 m past one. Bigger type in the same box wraps to two
	## lines, which is free; a wider box would push bead ten out of frame.
	## THE METRE MARK IS THE ONE LINE THAT GOES ABOVE THE STRING, because the string
	## is the ruler and that is where a ruler's numbers belong — and because it is
	## the only one short enough to fit the 34 px of room the detail panel leaves.
	## At local +0.42 its top edge lands around 424 px on the two beads nearest the
	## panel, which now ends at 378. Do not raise it further without moving the
	## panel: that is a 46 px margin, and it was 0 px two renders ago.
	var mark := Label3D.new()
	mark.name = "Mark"
	mark.font_size = 44
	mark.position = Vector3(0, 0.42, 0.05)
	mark.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	mark.modulate = WHS.ACCENT
	mark.visible = false
	anchor.add_child(mark)

	var place := Label3D.new()
	place.name = "Place"
	place.font_size = 30
	place.width = 380.0
	place.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	## Between the caption (which reaches -1.85 when a long token wraps at 46 pt)
	## and the status line at -2.50.
	place.position = Vector3(0, -2.04, 0.05)
	place.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	place.modulate = Color(0.72, 0.75, 0.82)
	place.visible = false
	anchor.add_child(place)

	var b: Dictionary = {
		"anchor": anchor, "plate": plate, "edge": edge, "tile": tile,
		"noimg": noimg, "cap": cap, "sub": sub, "mount": mount,
		"mark": mark, "place": place,
		"pmat": pmat, "emat": emat, "token": token,
	}
	_beads[i] = b
	_style_bead(i)
	return b


## Everything on a bead that answers "should this stay in the deal?" — the
## fields the survey named, on the object itself rather than only in a panel.
func _style_bead(i: int) -> void:
	if not _beads.has(i) or i < 0 or i >= _order.size():
		return
	var b: Dictionary = _beads[i]
	var row: Dictionary = _order[i]
	var focus: bool = i == _focus_i()
	var hover: bool = i == _hover
	var alive: bool = bool(row.get("alive", true))
	var body: bool = bool(row.get("body", true))
	var origin := str(row.get("origin", _neutral_origin))

	# STANDS: is there a body in the world at this bead, right now? On the spine
	# every bead is a dealing decision and the question does not arise, so it is
	# true. In the museum it is the ONE fact the view exists to carry, and it is
	# what separates 524 beads from the other 1,109.
	var stands: bool = true
	var state := ""
	if _is_museum:
		state = str(row.get("state", ""))
		stands = state == "placed"

	var base: Color = _chapter_color(str(row.get("sequence", "")))
	if not alive:
		base = base.darkened(0.42)
	if not stands:
		# A PROPOSAL MUST NOT LOOK LIKE A ROOM. 1,049 of the 1,583 placements are in
		# a chapter the museum does not build today; if they carried the same bright
		# plate as a standing body, two thirds of the string would be a claim
		# dressed as a fact.
		base = base.darkened(0.55).lerp(Color(0.16, 0.17, 0.21), 0.45)
	var pmat: StandardMaterial3D = b["pmat"]
	pmat.albedo_color = base.lightened(0.10 if focus else 0.0)
	pmat.emission_enabled = focus and stands
	pmat.emission = base
	pmat.emission_energy_multiplier = 0.28 if (focus and stands) else 0.0

	var emat: StandardMaterial3D = b["emat"]
	var ec := Color(0.26, 0.28, 0.33)
	if _is_museum:
		ec = _state_color(state)
	elif not alive:
		ec = Color(0.80, 0.22, 0.20)          # dead: the museum will skip it
	elif not body:
		ec = Color(0.92, 0.62, 0.12)          # instantiate() as Node3D returns NULL
	elif origin == "hand":
		ec = WHS.ACCENT                        # added by the hand
	elif origin == "moved":
		ec = Color(0.42, 0.70, 0.92)          # moved by the hand
	if focus:
		ec = ec.lightened(0.30)
	elif hover:
		ec = ec.lightened(0.16)
	emat.albedo_color = ec
	emat.emission_enabled = focus or hover
	emat.emission = ec
	emat.emission_energy_multiplier = 0.5 if focus else (0.25 if hover else 0.0)

	# THE PHOTOGRAPH IS THE LOUDEST THING ON A BEAD, SO IT CARRIES THE RULE TOO.
	# A capture is a picture of a body that exists somewhere; on a bead where no
	# body stands it is shown as a ghost, at a third of its light. That is the
	# difference the eye reads first, before any word.
	var tile: Sprite3D = b["tile"] as Sprite3D
	var noimg: Label3D = b["noimg"] as Label3D
	var ghost: Color = Color(1, 1, 1) if stands else Color(0.40, 0.44, 0.54)
	if tile != null:
		tile.modulate = ghost
	if noimg != null:
		noimg.modulate = Color(0.72, 0.74, 0.80) if stands else Color(0.44, 0.46, 0.54)

	var cap: Label3D = b["cap"]
	cap.font_size = 46 if focus else 34
	if not stands:
		cap.modulate = Color(0.82, 0.62, 0.34) if focus else Color(0.58, 0.60, 0.66)
	else:
		cap.modulate = Color(1.0, 0.62, 0.1) if focus else Color(0.95, 0.9, 0.75)

	var mark: Label3D = b["mark"]
	var place: Label3D = b["place"]
	mark.visible = _is_museum
	place.visible = _is_museum
	if _is_museum:
		_style_museum_bead(row, b, focus, stands, state)
		return

	var marks: Array = []
	if not alive:
		marks.append("DEAD: " + str(row.get("dead", "not dealt")))
	if not body:
		marks.append("NOT A BODY (%s)" % str(row.get("root", "?")))
	if origin != _neutral_origin:
		marks.append(origin.to_upper())
	if row.has("delegate_to"):
		marks.append("via " + str(row.get("delegate_to", "")))
	var size_txt := "size ?"
	if row.get("size_m") != null:
		size_txt = "%.2f m" % float(row.get("size_m"))
	var sub: Label3D = b["sub"]
	sub.text = "%s %d/%d  ·  fp %d  ·  %s%s" % [
		str(row.get("sequence", "")), int(row.get("seq_i", 0)) + 1, int(row.get("seq_n", 0)),
		int(row.get("fp", 1)), size_txt,
		("  ·  " + "  ·  ".join(PackedStringArray(marks))) if not marks.is_empty() else "",
	]
	sub.modulate = Color(0.94, 0.55, 0.5) if not alive else (
		Color(0.94, 0.74, 0.36) if not body else Color(0.68, 0.70, 0.76))


## The five states, and each one is a different fact about the world.
##   placed     a body stands on the floor the visitor walks
##   refused    the hall is built and this body does NOT stand — 8 of 1,583
##   unplanned  the pack put a body here that no map cell asked for
##   unbuilt    the chapter is a proposal; nobody has ever walked this hall
##   nowhere    the curriculum names it and it stands in no hall at all
static func _state_color(state: String) -> Color:
	match state:
		"placed": return Color(0.28, 0.72, 0.46)
		"refused": return Color(0.86, 0.24, 0.22)
		"unplanned": return Color(0.95, 0.60, 0.15)
		"unbuilt": return Color(0.27, 0.31, 0.42)
		"nowhere": return Color(0.70, 0.38, 0.88)
	return Color(0.26, 0.28, 0.33)


## Everything the museum bead must show that the spine bead cannot: the metre
## mark and the hall in place of the index and "first met in", the state, where
## the body actually stands when it is not on the cell the map named, the
## nth-of-N when a token repeats, and whether the curriculum has ever heard of it.
func _style_museum_bead(row: Dictionary, b: Dictionary, focus: bool,
		stands: bool, state: String) -> void:
	var mark: Label3D = b["mark"]
	var place: Label3D = b["place"]
	var sub: Label3D = b["sub"]
	var col: Color = _state_color(state)

	# ── the metre mark, above the string, where a ruler's numbers go
	if row.get("z_m") == null:
		mark.text = "no metre"
		mark.modulate = _state_color("nowhere").lightened(0.30)
	else:
		mark.text = "%d m" % int(row.get("z_m"))
		# A PROPOSAL'S METRE MARK IS STILL A FACT AND MUST STAY READABLE. At
		# (0.52,0.48,0.40) the first render came back with "1341 m" as a grey smear
		# on ten beads running — dimmer than standing is the point, invisible is a
		# different claim.
		mark.modulate = WHS.ACCENT if stands else Color(0.74, 0.68, 0.54)
	mark.font_size = 52 if focus else 44

	# ── the hall, and where in it
	var hall := str(row.get("hall", ""))
	if hall == "":
		place.text = "in NO hall"
		place.modulate = _state_color("nowhere").lightened(0.30)
	else:
		place.text = "%s   %d / %d" % [hall, int(row.get("band_i", 0)) + 1, int(row.get("band_n", 0))]
		place.modulate = Color(0.82, 0.85, 0.92) if stands else Color(0.64, 0.67, 0.74)
	place.font_size = 34 if focus else 30

	# ── what is actually true of this bead
	var parts: Array = []
	var of: int = int(row.get("of", 1))
	if of > 1:
		# 173 tokens repeat; science_screen stands 26 times. Without this the same
		# photograph appears again and again with nothing saying which one it is.
		parts.append("#%d of %d" % [int(row.get("nth", 1)), of])
	# THE STATE WORD GOES ON EVERY BEAD. The first render had the two beads that
	# were re-homed without a ring search reading only "re-homed by the pack" —
	# true, and it left the reader to infer from an edge colour whether anything
	# stands there at all. The state is the headline; the movement is the footnote.
	match state:
		"placed":
			parts.append("PLACED")
			# `rings` is the DISCRIMINATOR, not `why`: 191 beads stand off their map
			# cell but only 43 were moved by the ring search. The other 148 were
			# aimed elsewhere by the pack before any search ran and carry no rings.
			if row.has("rings"):
				parts.append("slid %d ring%s" % [
					int(row.get("rings", 0)), "" if int(row.get("rings", 0)) == 1 else "s"])
			elif row.has("slid_to"):
				parts.append("re-homed")
		"refused":
			# the full reason is on the HUD line and in the panel; three wrapped
			# lines of it on a 1.65 m label buried the caption underneath
			parts.append("REFUSED")
			parts.append(_clip(str(row.get("why", "no body stands here")), 26))
		"unplanned":
			parts.append("UNPLANNED")
			parts.append("no map cell asked")
		"unbuilt":
			parts.append("NOT BUILT — a proposal")
		"nowhere":
			parts.append("NOWHERE — in no hall")
		_:
			parts.append(state.to_upper())
	if not bool(row.get("in_spine", true)):
		# 517 of 1,583. They stand in the building and no curriculum has heard of
		# them, which is a fact about the spine, not about the artifact.
		parts.append("off-curriculum")
	if not bool(row.get("alive", true)):
		parts.append("DEAD: " + str(row.get("dead", "not dealt")))
	sub.text = "  ·  ".join(PackedStringArray(parts))
	sub.font_size = 34 if focus else 30
	sub.modulate = col.lightened(0.22) if stands else col.lightened(0.34)


static func _clip(s: String, n: int) -> String:
	return s if s.length() <= n else s.substr(0, maxi(1, n - 1)) + "…"


func _focus_i() -> int:
	## The bead standing at the focus slot. Read from _want, not _pos: the window
	## is decided the instant the scroll is asked for, so the incoming bead
	## SLIDES in with the string instead of popping into existence when the
	## animation lands.
	return clampi(int(roundf(_want)), 0, maxi(0, _order.size() - 1))


## THE WINDOW IS TEN WIDE EVERYWHERE, INCLUDING AT THE ENDS. Anchoring the
## window on the focus alone showed SIX beads at bead 0 — there is nothing to the
## left of the first artifact — which the headless probe caught on its first run.
## So the window start is clamped into [0, n-10] and the focus rides inside it:
## dead centre through the middle of the order, and off-centre at the two ends,
## which is how a necklace held near its clasp actually reads.
func _win_first() -> int:
	return clampi(_focus_i() - FOCUS_SLOT, 0, maxi(0, _order.size() - WINDOW))


func _win_first_f() -> float:
	## The same clamp on the ANIMATED position, so the string glides and then
	## stops dead at the ends instead of sliding past them.
	return clampf(_pos - float(FOCUS_SLOT), 0.0, maxf(0.0, float(_order.size() - WINDOW)))


func _place_beads() -> void:
	# the arc's origin is the FOCUS SLOT, wherever the window has been clamped to
	var here: float = _station_at(_win_first_f() + float(FOCUS_SLOT))
	var centre: int = _focus_i()
	# EXACTLY TEN, by index and not by distance. A distance cut would show
	# eleven or twelve as the seam gaps opened and closed, and "ten at a time"
	# is the request.
	var lo: int = _win_first()
	var hi: int = lo + WINDOW - 1
	for k in _beads.keys():
		var i: int = int(k)
		var b: Dictionary = _beads[i]
		var anchor: Node3D = _node_or_null(b.get("anchor"))
		if anchor == null:
			continue
		if i < lo or i > hi:
			anchor.visible = false
			continue
		anchor.visible = true
		_place_on_arc(anchor, _station[i] - here)
		# the focus steps forward out of the line, so the eye finds it without
		# a marker cluttering the string
		if i == centre:
			anchor.position.z += 0.42
	if centre != _last_focus:
		var was: int = _last_focus
		_last_focus = centre
		if was >= 0:
			_style_bead(was)
		_style_bead(centre)
		_update_hud()
	_recolour_string()


func _recolour_string() -> void:
	# the SAME origin _place_beads uses, or the bands drift off the beads they
	# are naming the moment the window clamps at either end
	var here: float = _station_at(_win_first_f() + float(FOCUS_SLOT))
	for s in _string_segs:
		var seg: Dictionary = s
		var x: float = float(seg["x"]) + here
		var idx: int = _index_at_station(x)
		var mat: StandardMaterial3D = seg["mat"]
		if idx < 0:
			mat.albedo_color = Color(0.22, 0.23, 0.26)   # past the ends of the order
			continue
		var r: Dictionary = _order[idx]
		var c: Color = _chapter_color(str(r.get("sequence", ""))).lightened(0.15)
		if _is_museum:
			# THE STRING CARRIES THE ROOMS, BECAUSE THE GAPS CANNOT. The museum's
			# seam is only 0.25 m — the frustum will not pay for more — so a hall
			# boundary is nearly invisible as a gap. Alternating the string's own
			# lightness per hall makes the 207 rooms readable as runs while the
			# twenty-two chapters stay readable as colour.
			if int(r.get("band_ord", 0)) % 2 == 1:
				c = c.darkened(0.28)
			# and a chapter nobody has built is not the same road
			if not bool(r.get("built", true)):
				c = c.lerp(Color(0.24, 0.25, 0.30), 0.6)
		mat.albedo_color = c


func _index_at_station(x: float) -> int:
	if _station.is_empty():
		return -1
	if x < _station[0] - PITCH * 0.5 or x > _station[_station.size() - 1] + PITCH * 0.5:
		return -1
	var best: int = 0
	var bd: float = 1.0e9
	# The string is only ~20 beads wide on screen, so a linear scan over the
	# built band is cheaper than the branch-heavy binary search it replaces.
	var lo: int = maxi(0, int(_pos) - FOCUS_SLOT - SLACK_FREE)
	var hi: int = mini(_station.size() - 1, int(_pos) + WINDOW + SLACK_FREE)
	for i in range(lo, hi + 1):
		var d: float = absf(_station[i] - x)
		if d < bd:
			bd = d
			best = i
	return best


# ─────────────────────────────────────────────────────────── capture textures
## The capture as a texture — encyclopedia gallery first, then the scene-catalog,
## then this project's own user://multi_shots. Measured coverage of the 810
## through this chain: 798 (98.5%). Same three sources and same order as
## map_tool_editor.gd:1369, so the necklace and the map editor never disagree
## about what an artifact looks like.
func _capture_texture(token: String) -> ImageTexture:
	if _tex_cache.has(token):
		return _tex_cache[token]
	var gh := ProjectSettings.globalize_path("res://").rstrip("/").get_base_dir()
	var cands: Array = [
		gh + "/ada_encyclopedia/public/artifact-gallery/captures/%s/front.png" % token,
		gh + "/ada_encyclopedia/public/scene-catalog/%s.png" % token,
		ProjectSettings.globalize_path("user://multi_shots/%s/front.png" % token),
		ProjectSettings.globalize_path("user://multi_shots/%s/angle_0.png" % token),
	]
	var tex: ImageTexture = null
	for c in cands:
		if not FileAccess.file_exists(str(c)):
			continue
		var img: Image = Image.load_from_file(str(c))
		if img != null and not img.is_empty():
			tex = ImageTexture.create_from_image(img)
			break
	_tex_cache[token] = tex
	return tex


# ────────────────────────────────────────────────────────────── the live body
func _tick_live(delta: float) -> void:
	if not _live_on or _fatal != "":
		return
	var focus_i: int = _focus_i()
	if focus_i != _live_index and _live_still >= LIVE_DEBOUNCE:
		if _live_node != null and (Time.get_ticks_msec() - _live_born) < int(LIVE_MIN_DWELL * 1000.0):
			return   # never free a body younger than its dwell
		_free_live()
		_spawn_live(focus_i)
	elif _live_node != null and not _live_fitted \
			and (Time.get_ticks_msec() - _live_born) >= int(LIVE_SETTLE * 1000.0):
		_fit_live()


func _spawn_live(i: int) -> void:
	if i < 0 or i >= _order.size():
		return
	_live_index = i
	_live_fitted = false
	var row: Dictionary = _order[i]
	var token := str(row.get("lookup", ""))
	var why := _live_refusal(row)
	if why != "":
		_live_note = "%s: no live body — %s" % [token, why]
		_set_tile_hidden(i, false)
		return
	var scene := str(row.get("scene", ""))
	if not ResourceLoader.exists(scene):
		_live_note = "%s: scene not on disk" % token
		return
	var ps: PackedScene = load(scene) as PackedScene
	if ps == null:
		_live_note = "%s: not a PackedScene" % token
		return
	var n: Node = ps.instantiate()
	# `instantiate() as Node3D` returns NULL for a Control/Node/Node2D root and
	# is not an error. Three of the 810 do this, all map_ready true.
	if not (n is Node3D):
		if n != null:
			n.free()
		_live_note = "%s: root is %s, not a 3D node" % [token, str(row.get("root", "?"))]
		return
	var n3: Node3D = n as Node3D

	# THE STAMP, AND IT MUST PRECEDE add_child. GridInteractablesComponent sets
	# artifact_lookup_name at :1210 and adds the child at :1287 — 77 lines apart —
	# because 73 of the 810 share a scene with a sibling and pick their variant
	# from that meta inside _ready(). artifact_runner.gd omits it and silently
	# renders every one of those as its family default.
	n3.set_meta("artifact_lookup_name", token)
	var params: Dictionary = _params_for(token)
	for k in params.keys():
		n3.set_meta("config_" + str(k), params[k])
	if n3.has_method("apply_grid_config"):
		n3.call("apply_grid_config", params)

	var mount: Node3D = _mount_for(i)
	if mount == null:
		n3.free()
		return
	mount.add_child(n3)          # _ready() fires HERE, into a settled tree
	_suppress_chrome(n3)
	_make_inert(n3)
	# The grid calls the suppressor immediately AND deferred (:1295-1296),
	# because artifacts that build their CanvasLayer late escape a single call.
	call_deferred("_suppress_chrome", n3)
	_live_node = n3
	_live_born = Time.get_ticks_msec()
	_live_note = "%s: live" % token
	_set_tile_hidden(i, true)


## The refusal list, and why each entry is on it.
func _live_refusal(row: Dictionary) -> String:
	if not bool(row.get("body", true)):
		return "root is %s — instantiate() as Node3D returns null" % str(row.get("root", "?"))
	if not bool(row.get("alive", true)):
		return str(row.get("dead", "the museum will not deal it"))
	var scene := str(row.get("scene", "")).to_lower()
	# The fifteen GPU/compute tokens. DERIVED from the path rather than
	# transcribed as a token list: all fifteen live under
	# algorithms/proceduralgeneration/isosurfaces/, and TerrainGeneratorBase
	# submits a compute dispatch that only syncs ~12 frames later. Its release()
	# is self-hooked on NOTIFICATION_PREDELETE, so a free is survivable — but it
	# BLOCKS on thread.wait_to_finish() and rendering_device.sync(), and nine of
	# them sit inside one ten-wide window at order index 656.
	if scene.contains("isosurfaces") or scene.contains("marchingcube") or scene.contains("marchingcave"):
		return "GPU compute (marching cubes) — building and freeing it on a scroll is the documented segfault class"
	# boid_flocking is the documented headless-hang artifact; it is also a
	# CanvasLayer root, so the body check above already caught it. Belt and
	# braces, because the root type is read from a file that can go stale.
	if str(row.get("lookup", "")) == "boid_flocking":
		return "never yields headless"
	return ""


func _fit_live() -> void:
	_live_fitted = true
	var n3: Node3D = _node_or_null(_live_node)
	if n3 == null:
		return
	var box: AABB = _local_aabb(n3)
	if box.size.length() < 0.001:
		# 143 of the 810 declare dna.fixture: _ready() is gated and builds
		# nothing standalone. The sweep's rescue (capture_config_sweep.gd:404) is
		# to hand the params in again and settle once more.
		if n3.has_method("apply_grid_config"):
			n3.call("apply_grid_config", _params_for(str(_order[_live_index].get("lookup", ""))))
			_live_fitted = false
			_live_born = Time.get_ticks_msec()
			return
		_live_note += " — builds nothing standalone (dna.fixture)"
		_set_tile_hidden(_live_index, false)
		return
	var m: float = maxf(box.size.x, maxf(box.size.y, box.size.z))
	# NORMALISE INTO THE BEAD VOLUME. registry max_dimension_m runs 0.00 to
	# 300.00 m across the corpus — a 175x spread — so the beads cannot share one
	# scale. Cap the UP-scale: a 4 cm token blown to 1.3 m is a lie, and the real
	# metres are on the label where the size information belongs.
	var s: float = minf(BEAD_M / maxf(m, 0.001), MAX_UPSCALE)
	n3.scale = Vector3.ONE * s
	n3.position = Vector3(-box.position.x * s - box.size.x * 0.5 * s, -box.position.y * s, 0.0)
	_live_note = "%s: live · %.2f x %.2f x %.2f m · shown at %.2fx" % [
		str(_order[_live_index].get("lookup", "")), box.size.x, box.size.y, box.size.z, s]
	_update_hud()


func _free_live() -> void:
	var n3: Node3D = _node_or_null(_live_node)
	_live_node = null
	if _live_index >= 0:
		_set_tile_hidden(_live_index, false)
	if n3 == null:
		return
	# release() IS NOT ON THE ROOT. In 13 of 13 GPU tokens the TerrainGenerator*
	# script sits on a child (`Terrain`, `GyroidShape`), so the repo's own guard —
	# probe_artifact_elements.gd:224, `if artifact.has_method("release")` on the
	# root — is false in every case it exists to cover. Walk the subtree and
	# flush on a frame we control, rather than inside the engine's teardown.
	var stack: Array = [n3]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c.has_method("release"):
			c.call("release")
	n3.queue_free()


func _set_tile_hidden(i: int, hidden: bool) -> void:
	if not _beads.has(i):
		return
	var b: Dictionary = _beads[i]
	var tile: Node3D = _node_or_null(b.get("tile"))
	if tile != null and (tile as Sprite3D).texture != null:
		tile.visible = not hidden
	var noimg: Node3D = _node_or_null(b.get("noimg"))
	if noimg != null and (tile == null or (tile as Sprite3D).texture == null):
		noimg.visible = not hidden


func _mount_for(i: int) -> Node3D:
	if not _beads.has(i):
		return null
	return _node_or_null((_beads[i] as Dictionary).get("mount"))


## capture_config_sweep.gd:541, NOT GridInteractablesComponent.gd:1085. The grid's
## version stands down CanvasLayer and Camera3D only; the sweep's also hides bare
## Control children, because a Control under a Node3D draws STRAIGHT into the
## viewport with no CanvasLayer — and one such debug panel was once measured AS
## the subject. WorldEnvironment and DirectionalLight3D are added here on top:
## 61 of the 810 carry a sky and 120 carry a sun, and with a body on the string
## those would fight the stage's own light.
func _suppress_chrome(node: Node) -> void:
	if not is_instance_valid(node):
		return
	for child in node.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
		elif child is Camera3D:
			(child as Camera3D).current = false
		elif child is Control:
			(child as Control).visible = false
		elif child is WorldEnvironment:
			(child as WorldEnvironment).environment = null
		elif child is DirectionalLight3D:
			# layers = 0, not visible = false: visibility is hierarchical in
			# Godot and would hide every descendant of the light's node.
			(child as DirectionalLight3D).light_cull_mask = 0
			(child as DirectionalLight3D).light_energy = 0.0
		_suppress_chrome(child)


## Out of the physics world entirely: no collisions in or out, rigidbodies
## frozen, character bodies not stepping. artifact_runner.gd:215, including the
## SoftBody3D branch — it is a MeshInstance3D, not a CollisionObject3D, and has
## its own layers.
func _make_inert(node: Node) -> void:
	if node is CollisionObject3D:
		(node as CollisionObject3D).collision_layer = 0
		(node as CollisionObject3D).collision_mask = 0
		if node is RigidBody3D:
			(node as RigidBody3D).freeze = true
		elif node is CharacterBody3D:
			(node as CharacterBody3D).set_physics_process(false)
	elif node is SoftBody3D:
		(node as SoftBody3D).collision_layer = 0
		(node as SoftBody3D).collision_mask = 0
	for c in node.get_children():
		_make_inert(c)


## The merged local AABB, ROOT INCLUDED. GridInteractablesComponent._compute_local_aabb
## (:2260) iterates node.get_children() and never inspects the node itself, so for
## the six tokens whose scene root IS a MeshInstance3D it returns a children-only
## box. MultiMeshInstance3D and CSGShape3D count; GPUParticles3D deliberately does
## not, because a particle box is weather, not the artifact.
func _local_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var got := false
	var stack: Array = [node]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c is GPUParticles3D:
			continue
		if c is VisualInstance3D and c is Node3D:
			var a: AABB = (c as VisualInstance3D).get_aabb()
			if a.size.length() <= 0.0:
				continue
			var rel: Transform3D = node.global_transform.affine_inverse() * (c as Node3D).global_transform
			var w: AABB = rel * a
			if got:
				out = out.merge(w)
			else:
				out = w
				got = true
	return out


## default_params -> delegate_params -> dna.fixture, weakest first, the grid's own
## precedence (GridInteractablesComponent.gd:1240-1261). Scanned ON DEMAND, the
## first time a live body is asked for: the registry warm costs ~720 ms and there
## is no reason to spend it on a curator who only ever scrolls.
func _params_for(token: String) -> Dictionary:
	if not _registry_scanned:
		_scan_registry_params()
	var p: Variant = _registry_params.get(token, {})
	return (p as Dictionary).duplicate(true) if p is Dictionary else {}


func _scan_registry_params() -> void:
	_registry_scanned = true
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return
	var raw: Dictionary = {}
	for fname in dir.get_files():
		if not str(fname).to_lower().ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string("res://commons/artifacts/registry/" + str(fname))
		if text == "":
			continue
		var parsed: Variant = JSON.parse_string(text)
		if not (parsed is Dictionary):
			continue
		var data: Dictionary = parsed
		var nested: Variant = data.get("artifacts")
		var entries: Dictionary = (nested as Dictionary) if nested is Dictionary else data
		for key in entries.keys():
			if entries[key] is Dictionary and not raw.has(str(key)):
				raw[str(key)] = entries[key]
	for token in raw.keys():
		var e: Dictionary = raw[token]
		var out: Dictionary = {}
		var dp: Variant = e.get("default_params")
		if dp is Dictionary:
			out.merge((dp as Dictionary).duplicate(true), true)
		var deleg := str(e.get("delegate_to", "")).strip_edges()
		if deleg != "":
			# prebaked_loader backs 13 of the 810 and its _ready() is
			# `if scene_path.is_empty(): return` — without delegate_params those
			# thirteen are empty holders, and the failure is silent.
			var dpar: Variant = e.get("delegate_params")
			if dpar is Dictionary:
				out.merge((dpar as Dictionary).duplicate(true), true)
		var dna: Variant = e.get("dna")
		if dna is Dictionary and (dna as Dictionary).get("fixture") is Dictionary:
			out.merge(((dna as Dictionary)["fixture"] as Dictionary).duplicate(true), true)
		_registry_params[str(token)] = out


# ─────────────────────────────────────────────────────────────────────── edits
## THE REFUSAL, AND IT MUST BE A SENTENCE. Palle asked to SEE the museum string;
## an edit here would mean rewriting a map's interactables layer, which is a
## different and heavier act than appending an op to a hand file. The rule the
## project keeps re-learning is that a key which silently does nothing reads as a
## broken tool, so every refused verb says what it refused and why, and the HUD
## says the string is read-only before anyone presses a key at all.
func _refuse_edit(verb: String) -> bool:
	_notice = "REFUSED — %s here: %s" % [verb, READ_ONLY_WHY]
	_update_hud()
	return false


## ADD. `where` is one of "after" | "before" | "first_in" | "last_in" and is
## turned into an ANCHOR-RELATIVE position clause; never an index.
func add_candidate(lookup: String, where: String = "after") -> bool:
	if _read_only:
		return _refuse_edit("nothing can be added to the deal")
	if _fatal != "" or _order.is_empty():
		return false
	var cand: Dictionary = _candidate(lookup)
	if cand.is_empty():
		_notice = "%s is not in the add pool — the museum would deal it and drop it" % lookup
		_update_hud()
		return false
	var focus_i: int = _focus_i()
	var frow: Dictionary = _order[focus_i]
	var chapter := str(frow.get("sequence", ""))
	var op: Dictionary = {"op": "add", "lookup": lookup, "sequence": chapter}
	var at: int = focus_i
	match where:
		"before":
			op["before"] = str(frow.get("lookup", ""))
			at = focus_i
		"first_in":
			op["first_in"] = chapter
			at = _chapter_bounds(chapter)[0]
		"last_in":
			op["last_in"] = chapter
			at = _chapter_bounds(chapter)[1] + 1
		_:
			op["after"] = str(frow.get("lookup", ""))
			at = focus_i + 1
	op["why"] = "added from the necklace, %s %s" % [where, chapter]
	if not _append_op(op):
		return false
	var row: Dictionary = {
		"lookup": lookup, "sequence": chapter,
		"map": "",                      # a hand add has no spine map; the museum
		                                # reads only lookup and sequence anyway
		"origin": "hand", "alive": true,
		"scene": str(cand.get("scene", "")), "root": str(cand.get("root", "")),
		"body": bool(cand.get("body", true)), "fp": int(cand.get("fp", 1)),
		"size_m": cand.get("size_m"), "category": str(cand.get("category", "")),
		"desc": str(cand.get("desc", "")), "why": str(op["why"]),
	}
	if cand.has("delegate_to"):
		row["delegate_to"] = cand["delegate_to"]
	at = clampi(at, 0, _order.size())
	_order.insert(at, row)
	# The candidate is kept whole so U can hand it straight back to the pool.
	_undo.append({"kind": "add", "lookup": lookup, "index": at,
		"cand": cand.duplicate(true)})
	_drop_candidate(lookup)
	_after_edit(clampi(at, 0, _order.size() - 1))
	_notice = "added %s — %s %s" % [lookup, where, chapter]
	_refresh_palette()
	return true


## REMOVE. "drop from the deal", the wording the web editor already uses, because
## that is what it is: the artifact stays in its map, the player still meets it
## walking the grid, and build_spine_artifact_order.py puts it back in the
## GENERATED order on the next run — which is exactly why removal has to be a
## persistent op rather than a deletion.
func drop_bead(i: int) -> bool:
	if _read_only:
		return _refuse_edit("a bead cannot be dropped")
	if _fatal != "" or i < 0 or i >= _order.size():
		return false
	if _order.size() <= 1:
		_notice = "refusing to empty the string"
		return false
	var row: Dictionary = _order[i]
	var lookup := str(row.get("lookup", ""))
	if str(row.get("origin", "")) == "hand":
		# An add and a remove of the same token would both stay in the file and
		# argue with each other on every replay. But the case that actually
		# happens — added it, looked at it, want it gone — is the TRAILING op, and
		# taking that back is exactly what U does. Do it here too, so X on the bead
		# you just placed does the obvious thing instead of citing the CLI.
		if _trailing_undo_is("add", lookup):
			return undo_last()
		_notice = ("%s was added by the hand in an earlier session — take that op "
			+ "back with `python tools/necklace_order.py --list-ops` then `--undo N`") % lookup
		_update_hud()
		return false
	var op: Dictionary = {
		"op": "remove", "lookup": lookup,
		"why": "dropped from the deal at the necklace",
	}
	if not bool(row.get("alive", true)):
		op["why"] = "dropped from the deal: " + str(row.get("dead", "dead"))
	elif not bool(row.get("body", true)):
		op["why"] = "dropped from the deal: root is %s, instantiate() as Node3D returns null" % str(row.get("root", "?"))
	if not _append_op(op):
		return false
	_undo.append({"kind": "remove", "lookup": lookup, "index": i,
		"row": row.duplicate(true)})
	_order.remove_at(i)
	# PUT IT BACK IN THE ADD LIST. Without this a dropped token simply vanished
	# from the tool — the pool is only ever removed from — so the one thing you
	# cannot do after a drop was put back what you just dropped. This is not an
	# invention either: --apply rebuilds `candidates` as live-minus-in_order, so
	# the derived file will list it in the pool on the next run regardless.
	var back := _candidate_from_row(row)
	if back.is_empty():
		_notice = ("dropped %s (it stays in its map). NOT back in the add list — "
			+ "the museum's liveness rule refuses it. U undoes.") % lookup
	else:
		_candidates.append(back)
		_sort_candidates()
		_notice = "dropped %s (it stays in its map) — back in the add list; U undoes" % lookup
	_after_edit(clampi(i, 0, _order.size() - 1))
	_refresh_palette()
	return true


## MOVE, one step, within the chapter. A bead may NEVER cross a band: the chapter
## is the museum building it is dealt into, and moving across one is a curriculum
## decision that belongs in curriculum_spine.json. The web editor refuses the same
## drag for the same reason (page.tsx:67).
func move_focus(step: int) -> bool:
	if _read_only:
		return _refuse_edit("a bead cannot be moved")
	if _fatal != "":
		return false
	var i: int = _focus_i()
	var j: int = i + step
	if j < 0 or j >= _order.size():
		return false
	var a: Dictionary = _order[i]
	var b: Dictionary = _order[j]
	var chapter := str(a.get("sequence", ""))
	if str(b.get("sequence", "")) != chapter:
		_notice = "%s cannot leave %s — that is a curriculum_spine.json decision" % [
			str(a.get("lookup", "")), chapter]
		_update_hud()
		return false
	var op: Dictionary = {"op": "move", "lookup": str(a.get("lookup", ""))}
	if step > 0:
		op["after"] = str(b.get("lookup", ""))
	else:
		op["before"] = str(b.get("lookup", ""))
	op["why"] = "nudged at the necklace"
	if not _append_op(op):
		return false
	_undo.append({"kind": "move", "lookup": str(a.get("lookup", "")),
		"from": i, "to": j, "prev_origin": str(a.get("origin", "spine"))})
	_order.remove_at(i)
	_order.insert(j, a)
	if str(a.get("origin", "spine")) == "spine":
		a["origin"] = "moved"
	_after_edit(j)
	_want = float(j)
	_notice = "moved %s within %s" % [str(a.get("lookup", "")), chapter]
	return true


func _after_edit(focus_i: int) -> void:
	_reindex()
	for k in _beads.keys():
		var node: Node3D = _node_or_null((_beads[k] as Dictionary).get("anchor"))
		if node != null:
			node.queue_free()
	_beads.clear()
	if _live_node != null:
		_free_live()
	_live_index = -1
	_want = float(clampi(focus_i, 0, maxi(0, _order.size() - 1)))
	_pos = _want
	_refresh_window(true)
	_update_hud()


func _chapter_bounds(seq: String) -> Array:
	var lo: int = -1
	var hi: int = -1
	for i in _order.size():
		if str((_order[i] as Dictionary).get("sequence", "")) == seq:
			if lo < 0:
				lo = i
			hi = i
	return [maxi(lo, 0), maxi(hi, 0)]


func _candidate(lookup: String) -> Dictionary:
	for c in _candidates:
		if str((c as Dictionary).get("lookup", "")) == lookup:
			return c
	return {}


## UNDO, INSIDE THE TOOL. Both verbs used to be one-way: _candidates was only
## ever removed from, so a dropped bead left no way back, and drop_bead refused a
## hand-added one outright. Both answers were "go and run the CLI", for a tool
## whose entire vocabulary is add and remove.
##   This takes back only what THIS SESSION appended, and it pops the trailing op
## so the file agrees with the screen. It deliberately does not reach further:
## the ops list is a script replayed in order, and rewriting its middle is
## `necklace_order.py --undo N`, which knows the replay semantics this scene does
## not. The file is popped FIRST — if the write is refused, nothing on screen moves.
func undo_last() -> bool:
	if _read_only:
		# not "nothing to undo" — that would imply an edit was possible and simply
		# had not happened yet
		return _refuse_edit("there is nothing to take back, because nothing can be edited")
	if _fatal != "":
		return false
	if _undo.is_empty():
		_notice = ("nothing to take back from this session — `python tools/"
			+ "necklace_order.py --list-ops` names the older ones, `--undo N` pops one")
		_update_hud()
		return false
	if not _pop_op():
		return false
	var u: Dictionary = _undo.pop_back()
	var lookup := str(u.get("lookup", ""))
	var focus: int = 0
	match str(u.get("kind", "")):
		"add":
			# by lookup, with the recorded index only as the hint: an index is the
			# thing this whole file refuses to trust.
			var at: int = _index_near(lookup, int(u.get("index", 0)))
			if at >= 0:
				_order.remove_at(at)
			var cand: Dictionary = u.get("cand", {}) as Dictionary
			if not cand.is_empty():
				_candidates.append(cand)
				_sort_candidates()
			focus = clampi(at, 0, maxi(0, _order.size() - 1))
			_notice = "took back the add of %s — it is back in the add list" % lookup
		"remove":
			var at2: int = clampi(int(u.get("index", 0)), 0, _order.size())
			_order.insert(at2, (u.get("row", {}) as Dictionary))
			_drop_candidate(lookup)
			focus = clampi(at2, 0, maxi(0, _order.size() - 1))
			_notice = "put %s back on the string" % lookup
		"move":
			var to: int = _index_near(lookup, int(u.get("to", 0)))
			var from: int = int(u.get("from", 0))
			if to >= 0:
				var row: Dictionary = _order[to]
				_order.remove_at(to)
				from = clampi(from, 0, _order.size())
				_order.insert(from, row)
				row["origin"] = str(u.get("prev_origin", "spine"))
			focus = clampi(from, 0, maxi(0, _order.size() - 1))
			_notice = "moved %s back" % lookup
		_:
			_notice = "took back one op"
	_after_edit(focus)
	_refresh_palette()
	return true


func _trailing_undo_is(kind: String, lookup: String) -> bool:
	if _undo.is_empty():
		return false
	var last: Dictionary = _undo[_undo.size() - 1]
	return str(last.get("kind", "")) == kind and str(last.get("lookup", "")) == lookup


## The row's index, preferring the remembered one but confirming the token — the
## anchor-relative discipline the ops file itself is built on.
func _index_near(lookup: String, hint: int) -> int:
	if hint >= 0 and hint < _order.size() \
			and str((_order[hint] as Dictionary).get("lookup", "")) == lookup:
		return hint
	return index_of(lookup)


## An order row turned back into an add-list candidate, in the shape
## necklace_order.py's build() writes. {} when the museum would refuse it: the
## pool's contract is "every token the museum would deal", and offering a dead
## one would produce an add op the applier refuses after the fact.
func _candidate_from_row(row: Dictionary) -> Dictionary:
	if not bool(row.get("alive", true)):
		return {}
	var c: Dictionary = {
		"lookup": str(row.get("lookup", "")),
		# the chapter it was just dealt in IS the honest hint
		"hint_sequences": [str(row.get("sequence", ""))],
		"category": str(row.get("category", "")),
		"scene": str(row.get("scene", "")),
		"root": str(row.get("root", "")),
		"body": bool(row.get("body", true)),
		"fp": int(row.get("fp", 1)),
		"size_m": row.get("size_m"),
		"desc": str(row.get("desc", "")),
	}
	if row.has("delegate_to"):
		c["delegate_to"] = row["delegate_to"]
	return c


func _sort_candidates() -> void:
	## The same comparator _load_effective uses, so a restored token lands where
	## the eye already expects it rather than at the bottom of the list.
	_candidates.sort_custom(func(a, b) -> bool:
		return str((a as Dictionary).get("lookup", "")).naturalnocasecmp_to(
			str((b as Dictionary).get("lookup", ""))) < 0)


## by index, not Array.erase: Dictionary equality in Godot 4 is by reference, and
## a value-erase that silently matches nothing leaves the token offerable twice —
## the second add would be refused by the applier, after the fact.
func _drop_candidate(lookup: String) -> void:
	for ci in _candidates.size():
		if str((_candidates[ci] as Dictionary).get("lookup", "")) == lookup:
			_candidates.remove_at(ci)
			return


# ─────────────────────────────────────────────────────── writing the hand file
## THE ONLY WRITE THIS SCENE PERFORMS. Read the whole document, APPEND to `ops`,
## bump `_meta.ops_revision` by one, set `_meta.ops` and `_meta.generator`, keep
## `_readme` and `_meta.base_generated` as they were, write it back. Never
## reorder or rewrite an existing op: the list is a SCRIPT replayed in file
## order, which is what lets an edit be appended instead of the history rewritten.
func _append_op(op: Dictionary) -> bool:
	var doc: Dictionary = _open_ops_for_write()
	if doc.is_empty() and _ops_broken:
		return false
	var raw: Variant = doc.get("ops", [])
	var ops: Array = (raw as Array) if raw is Array else []
	ops.append(op)
	return _save_ops(doc, ops, +1)


## POP THE TRAILING OP. The mirror of _append_op and the only other write: undo
## in the tool means the file must agree with the screen, and the screen has just
## taken an edit back. It never reaches further than the last op — the ops list is
## a script, and rewriting its middle from here is the applier's `--undo N`.
func _pop_op() -> bool:
	var doc: Dictionary = _open_ops_for_write()
	if doc.is_empty() and _ops_broken:
		return false
	var raw: Variant = doc.get("ops", [])
	var ops: Array = (raw as Array) if raw is Array else []
	if ops.is_empty():
		_notice = "the hand file holds no ops to take back"
		_update_hud()
		return false
	ops.pop_back()
	return _save_ops(doc, ops, -1)


## Re-probe on EVERY write, not once at load: a file corrupted (or repaired)
## behind the scene's back must change what the next keystroke is allowed to do.
## Returns {} with _ops_broken set when the document must not be overwritten.
func _open_ops_for_write() -> Dictionary:
	var st: Dictionary = _read_json_state(ops_path)
	var state := str(st.get("state", "absent"))
	if not _state_is_writable(state):
		_ops_broken = true
		_ops_broken_why = str(st.get("why", ""))
		_notice = ("REFUSED — the hand file EXISTS and will not parse, so nothing "
			+ "was written: %s. Repair or move %s first; a fresh document written "
			+ "over it would be the whole hand, gone.") % [_ops_broken_why, ops_path]
		_update_hud()
		return {}
	_ops_broken = false
	_ops_broken_why = ""
	var doc: Dictionary = st.get("doc", {}) as Dictionary
	if doc.is_empty():
		doc = _fresh_ops_doc()
	return doc


func _save_ops(doc: Dictionary, ops: Array, pending_delta: int) -> bool:
	doc["ops"] = ops
	var m: Dictionary = doc.get("_meta", {}) if doc.get("_meta") is Dictionary else {}
	m["generated"] = Time.get_datetime_string_from_system(false, true).replace("T", " ")
	m["generator"] = SELF_PATH
	if not m.has("base_generated"):
		m["base_generated"] = str(_meta.get("base_generated", ""))
	# BUMPED ON EVERY WRITE, INCLUDING A POP — necklace_order.py's write_ops does
	# the same for its own `--undo`, so the revision counts writes and never runs
	# backwards. The derived file records the revision it was built from, so two
	# integers still answer "are my edits applied yet".
	m["ops_revision"] = int(m.get("ops_revision", 0)) + 1
	m["ops"] = ops.size()
	doc["_meta"] = m
	# sort_keys=false: JSON.stringify DEFAULTS TO TRUE and would alphabetise
	# every key, so `schema`/`_readme`/`_meta`/`ops` would come back shuffled and
	# each op would read `after, lookup, op, sequence, why`. The applier parses
	# either, but a hand file a human cannot skim is a hand file nobody audits.
	# indent=1 space + trailing newline, byte-for-byte the shape
	# tools/necklace_order.py and /api/spine-order already write.
	var err: String = _write_json_atomic(ops_path, JSON.stringify(doc, " ", false) + "\n")
	if err != "":
		_notice = "COULD NOT WRITE %s — %s. Nothing was saved." % [ops_path, err]
		_update_hud()
		return false
	_ops_rev_file = int(m["ops_revision"])
	_pending = maxi(0, _pending + pending_delta)
	return true


## FileAccess.open(path, WRITE) TRUNCATES ON OPEN. Everything after that line —
## the store_string, the close — happens to a file that is already empty, so any
## failure between the two leaves the hand as a zero-byte file. (This project has
## the scar written down: a bad argument to a Python write() emptied a 17,305-line
## source, because the truncate precedes the argument check.)
##   So: serialise to .tmp, READ IT BACK AND PARSE IT, keep the previous file as
## .bak, and only then rename over the real path. Returns "" on success.
func _write_json_atomic(path: String, text: String) -> String:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return "cannot open %s (error %d)" % [tmp, FileAccess.get_open_error()]
	f.store_string(text)
	f.close()
	# The size floor and the parse: a truncated or half-flushed temp must never
	# be promoted over a good file.
	var back := FileAccess.get_file_as_string(tmp)
	if back.length() < text.length():
		return "the temp file came back short (%d of %d bytes)" % [back.length(), text.length()]
	if JSON.parse_string(back) == null:
		return "the temp file does not parse back as JSON"
	if FileAccess.file_exists(path):
		var cerr: int = DirAccess.copy_absolute(path, path + ".bak")
		if cerr != OK:
			return "cannot keep a .bak of the previous file (error %d)" % cerr
		# rename_absolute onto an existing path is not portable; the .bak is
		# already the safety net, so clear the target first.
		var rerr: int = DirAccess.remove_absolute(path)
		if rerr != OK:
			return "cannot clear %s before the rename (error %d)" % [path, rerr]
	var mv: int = DirAccess.rename_absolute(tmp, path)
	if mv != OK:
		return "cannot rename %s into place (error %d) — the previous file is at %s.bak" % [
			tmp, mv, path]
	return ""


## Deliberately minimal. `python tools/necklace_order.py --init` is the canonical
## creator and owns the long readme; duplicating that text here would make the
## scene a second source of the contract's own explanation.
func _fresh_ops_doc() -> Dictionary:
	return {
		"schema": "spine_order_ops/1",
		"_readme": ("THE NECKLACE'S HAND - ops replayed over the generated spine order by "
			+ "`" + APPLY_CMD + "`. Never a snapshot, never an index. Created by "
			+ SELF_PATH + "; `python tools/necklace_order.py --init` writes the full readme."),
		"_meta": {
			"generated": Time.get_datetime_string_from_system(false, true).replace("T", " "),
			"generator": SELF_PATH,
			"base_generated": str(_meta.get("base_generated", "")),
			"ops_revision": 0,
			"ops": 0,
		},
		"ops": [],
	}


# ──────────────────────────────────────────────────────────────────────── UI
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hud = Label.new()
	## IT USED TO BE A BARE position = (14, 12) WITH NO RECT, so the Label's width
	## was its longest line and nothing bounded it. On the spine the head line is
	## "[SPINE] bead 1 / 810 · primitives 1 / 73" and that was never tested; the
	## museum's is three times longer, and a refusal notice carries a whole
	## sentence. The rendered frame showed both running off the right edge of a
	## 1600 px window and under the detail panel. Anchored and wrapped, with the
	## right edge held clear of the panel at -370.
	_hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_hud.offset_left = 14
	_hud.offset_right = -382
	_hud.offset_top = 12
	_hud.offset_bottom = 196
	_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_theme_font_size_override("font_size", 15)
	_hud.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_hud.add_theme_constant_override("shadow_offset_x", 1)
	_hud.add_theme_constant_override("shadow_offset_y", 1)
	layer.add_child(_hud)

	_banner = Label.new()
	# set_anchors_AND_OFFSETS_preset: set_anchors_preset alone leaves a fresh
	# Control at a 0x0 rect painting nothing, while every counter reads correct.
	# TOP_WIDE rather than CENTER_TOP because the banner's text length changes
	# with the chapter name, and a centred rect sized from a 0x0 Control stays 0x0.
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	## BELOW THE HUD, NOT ACROSS IT. At offset_top 12 the centred banner sat on the
	## HUD's own first line; with one short line above it that never showed, and
	## with the museum's six it printed chapter name straight through bead counts —
	## two texts in the same pixels, both unreadable. The rendered frame is the only
	## place that shows; nothing in the geometry could.
	_banner.offset_top = 202
	_banner.offset_bottom = 268
	# a centred Label overflows BOTH edges, and "formfinding · chapter 6 ·
	# Ribbon_Formfinding_02 — NOT BUILT" is 68 characters at 16 pt: the rendered
	# frame cut it mid-word on the right
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.add_theme_color_override("font_color", WHS.ACCENT)
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_banner)

	_build_detail(layer)
	_build_palette(layer)
	_build_why(layer)
	_build_fatal(layer)

	_help = Label.new()
	_help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_help.offset_left = 14
	_help.offset_right = -14
	_help.offset_top = -150
	_help.offset_bottom = -10
	# same fault as the HUD: the read-only line is a sentence and ran off the edge
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.add_theme_font_size_override("font_size", 13)
	_help.add_theme_color_override("font_color", WHS.DIM)
	_help.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	# on by default: an instrument nobody can drive is an instrument nobody uses,
	# and H puts it away once the keys are in the hand
	_help.visible = true
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_help)
	_update_help()


## THE HELP MUST NOT OFFER A KEY THE STRING REFUSES. Listing "A add list" under a
## read-only string is the same fault as a key that silently does nothing, one
## step earlier.
func _update_help() -> void:
	if _help == null:
		return
	var common := ("wheel / LEFT RIGHT  scroll        PgUp PgDn  ten        Home End  the ends\n"
		+ "click a bead to focus it        L  live body on the focus        C  camera in"
		+ "        H  help        F10  menu\n")
	if _is_museum:
		# the full reason lives in R and in every refusal notice; repeating the
		# whole sentence here was three wrapped lines of standing text
		_help.text = (common
			+ "[ ]  hall        Shift+[ ]  chapter        R  what this string is, verbatim\n"
			+ "TAB  back to the SPINE (the dealing order, editable)\n"
			+ "READ-ONLY — A · X · , · . · U all refuse here.  R says why.")
	else:
		_help.text = (common
			+ "[ ]  chapter        R  what this string is, verbatim\n"
			+ "A  add list        X  drop the bead under the cursor from the deal\n"
			+ ",  .  move the focused bead inside its chapter        U / Ctrl+Z  take the last edit back\n"
			+ "TAB  the MUSEUM — every artifact where it actually stands, 0 m to 4,270 m")


func _build_detail(layer: CanvasLayer) -> void:
	_detail_panel = PanelContainer.new()
	_detail_panel.add_theme_stylebox_override("panel", WHS.panel_box())
	_detail_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_detail_panel.offset_left = -370
	_detail_panel.offset_right = -12
	_detail_panel.offset_top = 12
	## IT USED TO REACH 470 AND SIT ON TOP OF BEADS EIGHT TO TEN. The string is
	## drawn at a fixed offset below the camera (plate centre ~0.98 m down at
	## 15.4 m), so the bead band lands at roughly 0.42..0.62 of the viewport
	## height whatever the window size — the plate tops are around y 436 on a
	## 900 px window. A panel ending at 470 covered them.
	##   So the panel is bounded by the STRING and by a FRACTION of the viewport,
	## not by a round pixel count. The plate tops sit 0.218 m above the view axis
	## at the string plane and the half-height in metres scales with the aspect,
	## so that lands at 0.486..0.490 of the height on everything from 4:3 to 16:9.
	## 0.44 stops the panel a clear 5% of the height above them. The
	## ScrollContainer inside already carries the overflow.
	##   0.44 held while the tallest thing on a bead was its bail at local +0.10. A
	## museum bead now carries its metre mark at +0.42, whose top edge lands near
	## 424 px on the two beads the panel sits over — so the bound moves to 0.42
	## (378 px on a 900 px window) and the same rule still holds: the panel is
	## bounded by the STRING, and the string grew a line.
	_detail_panel.anchor_bottom = 0.42
	_detail_panel.offset_bottom = -6.0
	layer.add_child(_detail_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_panel.add_child(scroll)
	_detail_box = VBoxContainer.new()
	_detail_box.add_theme_constant_override("separation", 3)
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail_box)


## The add list. It is WHPalette's shape — search box, category dropdown, a
## "%d / %d" count, a scrolling button list — but fed from the derived file's
## `candidates` rather than a fresh registry scan, for two measured reasons:
## the candidates are already filtered by the MUSEUM's own liveness rule (a
## scene, map_ready, the file on disk) so the list can never offer a token the
## museum would deal and drop, and they already exclude the 810 on the string.
## A registry scan offers 2,802 and a WHPalette with no render cap allocates one
## Button per match in a single frame — hence PALETTE_CAP.
func _build_palette(layer: CanvasLayer) -> void:
	_palette = PanelContainer.new()
	_palette.add_theme_stylebox_override("panel", WHS.panel_box())
	_palette.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_palette.offset_left = 12
	_palette.offset_right = 352
	_palette.offset_top = 96
	_palette.offset_bottom = 620
	_palette.visible = false
	layer.add_child(_palette)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette.add_child(col)
	col.add_child(WHS.heading("ADD TO THE DEAL"))

	_pal_where = OptionButton.new()
	_pal_where.add_item("insert AFTER the focus bead", 0)
	_pal_where.add_item("insert BEFORE the focus bead", 1)
	_pal_where.add_item("FIRST in the focus chapter", 2)
	_pal_where.add_item("LAST in the focus chapter", 3)
	col.add_child(_pal_where)

	_pal_search = LineEdit.new()
	_pal_search.placeholder_text = "filter…"
	_pal_search.clear_button_enabled = true
	_pal_search.add_theme_color_override("font_color", WHS.TEXT)
	_pal_search.text_changed.connect(func(_t: String) -> void: _refresh_palette())
	col.add_child(_pal_search)

	_pal_cat = OptionButton.new()
	_pal_cat.item_selected.connect(func(_i: int) -> void: _refresh_palette())
	col.add_child(_pal_cat)

	_pal_scope = CheckBox.new()
	_pal_scope.text = "the whole corpus"
	_pal_scope.tooltip_text = ("off: only candidates the registry says belong to the focus "
		+ "chapter (map_sequences). That is a HINT, not the chapter — the chapter "
		+ "is chosen by where you insert.")
	_pal_scope.toggled.connect(func(_v: bool) -> void: _refresh_palette())
	col.add_child(_pal_scope)

	_pal_count = Label.new()
	_pal_count.add_theme_color_override("font_color", WHS.DIM)
	_pal_count.add_theme_font_size_override("font_size", 11)
	col.add_child(_pal_count)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	_pal_list = VBoxContainer.new()
	_pal_list.add_theme_constant_override("separation", 3)
	_pal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_pal_list)


func _rebuild_palette_categories() -> void:
	if _pal_cat == null:
		return
	var sel := _pal_cat.get_selected_id()
	_pal_cat.clear()
	_pal_cat.add_item("All categories", 0)
	var seen: Dictionary = {}
	for c in _candidates:
		seen[str((c as Dictionary).get("category", "unknown"))] = true
	var cats: Array = seen.keys()
	cats.sort()
	var id: int = 1
	for cat in cats:
		_pal_cat.add_item(str(cat), id)
		id += 1
	for i in _pal_cat.item_count:
		if _pal_cat.get_item_id(i) == sel:
			_pal_cat.select(i)
			break


func _refresh_palette() -> void:
	if _pal_list == null:
		return
	for c in _pal_list.get_children():
		c.queue_free()
	var needle := _pal_search.text.strip_edges().to_lower()
	var cat_filter := ""
	if _pal_cat.get_selected_id() != 0 and _pal_cat.selected >= 0:
		cat_filter = _pal_cat.get_item_text(_pal_cat.selected)
	var chapter := _focus_chapter()
	var whole: bool = _pal_scope.button_pressed
	var matched: int = 0
	var shown: int = 0
	for cv in _candidates:
		var c: Dictionary = cv
		var cat := str(c.get("category", "unknown"))
		if cat_filter != "" and cat != cat_filter:
			continue
		if not whole and needle == "":
			var hints: Array = c.get("hint_sequences", []) if c.get("hint_sequences") is Array else []
			if not hints.has(chapter):
				continue
		if needle != "":
			var hay := (str(c.get("lookup", "")) + " " + cat + " " + str(c.get("desc", ""))).to_lower()
			if not hay.contains(needle):
				continue
		matched += 1
		if shown >= PALETTE_CAP:
			continue
		_pal_list.add_child(_palette_row(c))
		shown += 1
	_pal_count.text = "%d shown of %d matched   (%d in the pool)" % [shown, matched, _candidates.size()]
	if matched > shown:
		_pal_count.text += "  ·  narrow the filter"
	elif matched == 0:
		# the default filter is the focus chapter's registry HINT, and plenty of
		# chapters have none — say which filter emptied the list rather than
		# showing a blank panel
		_pal_count.text += "  ·  nothing hints at %s — tick 'the whole corpus'" % chapter


func _palette_row(c: Dictionary) -> Button:
	var lookup := str(c.get("lookup", ""))
	var b := Button.new()
	var size_txt := "?"
	if c.get("size_m") != null:
		size_txt = "%.1fm" % float(c.get("size_m"))
	b.text = "%s   ·  fp %d  ·  %s" % [lookup, int(c.get("fp", 1)), size_txt]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.tooltip_text = "%s\n%s\n%s\n%s" % [
		lookup, str(c.get("category", "")), str(c.get("scene", "")), str(c.get("desc", ""))]
	b.custom_minimum_size = Vector2(0, 26)
	WHS.style_button(b)
	if not bool(c.get("body", true)):
		# 9 of the 1,875 have a non-3D root. Offer them, say so — the necklace is
		# a dealing decision and the curator may want one badged on the string.
		b.add_theme_color_override("font_color", Color(0.92, 0.62, 0.12))
		b.text = "! " + b.text
	b.pressed.connect(func() -> void:
		var modes: PackedStringArray = ["after", "before", "first_in", "last_in"]
		add_candidate(lookup, str(modes[clampi(_pal_where.selected, 0, 3)])))
	return b


func _focus_chapter() -> String:
	var i: int = _focus_i()
	if _order.is_empty():
		return ""
	return str((_order[i] as Dictionary).get("sequence", ""))


func _update_hud() -> void:
	if _fatal != "":
		return
	var i: int = _focus_i()
	if _order.is_empty():
		_hud.text = "the string is empty"
		return
	var row: Dictionary = _order[i]
	var lines: Array = []
	if _is_museum:
		var where := "nowhere on the walk  ·  no hall"
		if row.get("z_m") != null:
			where = "%d m of %d  ·  %s  ·  %s (chapter %s)" % [
				int(row.get("z_m")), int(_meta.get("metres", 0)), _hall_text(row),
				str(row.get("sequence", "")), _chapter_text(row)]
		lines.append("[MUSEUM]  bead %d / %d  ·  %s" % [i + 1, _order.size(), where])
		lines.append(_museum_focus_line(row))
		lines.append("READ-ONLY — the maps as they stand. A · X · , · . · U all refuse.  R: why, verbatim")
		lines.append(_museum_census_line())
		if _notice != "":
			lines.append(_notice)
	else:
		lines.append("[SPINE]  bead %d / %d  ·  %s %d / %d" % [
			i + 1, _order.size(), str(row.get("sequence", "")),
			int(row.get("seq_i", 0)) + 1, int(row.get("seq_n", 0))])
		var counts := _hand_counts()
		lines.append("hand: %d added · %d dropped · %d moved   (%s)" % [
			counts[0], counts[1], counts[2], _notice])
	lines.append("TAB  %s" % _other_source_label())
	# A CORRUPT HAND FILE SET _ops_rev_file TO -1, WHICH IS THE SUPPRESSING VALUE
	# ON THE LINE BELOW — so the one state that most needed saying was the one
	# state that said nothing. It gets its own line, above everything else, and
	# every edit verb is already refusing.
	# BOTH OF THESE ARE FACTS ABOUT THE HAND FILE, AND THE MUSEUM HAS NONE. Printing
	# them under the museum string would be reporting the health of a file this view
	# neither reads nor writes.
	if not _is_museum:
		if _ops_broken:
			lines.append("THE HAND FILE EXISTS AND WILL NOT PARSE — every edit is refused")
			lines.append("   %s" % ops_path)
			lines.append("   %s" % _ops_broken_why)
			lines.append("   repair it, or move it aside and re-init with `python tools/necklace_order.py --init`")
		# STALENESS IS TWO INTEGERS. While the ops file's revision differs from the
		# one the derived file was built from, the derived answer is BEHIND and the
		# scene must say so instead of implying the edit has landed.
		if _pending > 0 or (_ops_rev_file >= 0 and _ops_rev_file != _ops_rev_derived):
			lines.append("SAVED — run `%s` to derive it" % APPLY_CMD)
			lines.append(str(_meta.get("plan_note", "")))
	if _live_note != "":
		lines.append(_live_note)
	_hud.text = "\n".join(PackedStringArray(lines))
	_banner.text = _banner_text()
	_update_detail(i)


## The metre mark as text. `null` for the 50 orphans, and "0 m" would be a lie
## about them — 0 m is the museum's front door, not "nowhere".
static func _metre_text(row: Dictionary) -> String:
	if row.get("z_m") == null:
		return "—"
	return str(int(row.get("z_m")))


static func _hall_text(row: Dictionary) -> String:
	var h := str(row.get("hall", ""))
	return h if h != "" else "no hall"


## `chapter` IS PRESENT AND NULL on the 50 orphans, so Dictionary.get's default
## never fires and str() would print the literal "<null>" on the banner.
static func _chapter_text(row: Dictionary) -> String:
	var c: Variant = row.get("chapter")
	return "—" if c == null else str(int(c))


## The focus bead in one line: what it is, whether it stands, and where.
func _museum_focus_line(row: Dictionary) -> String:
	var bits: Array = [str(row.get("lookup", ""))]
	if int(row.get("of", 1)) > 1:
		bits.append("#%d of %d" % [int(row.get("nth", 1)), int(row.get("of", 1))])
	bits.append(str(row.get("state", "?")))
	# the bead's own label clips this to 26 characters so it does not bury the
	# caption; the whole sentence belongs somewhere, and this line is where
	if str(row.get("state", "")) != "placed" and str(row.get("why", "")) != "":
		bits.append(str(row.get("why", "")))
	if row.get("cx") != null:
		bits.append("map cell %d,%d" % [int(row.get("cx")), int(row.get("cz"))])
	if row.has("slid_to"):
		var to: Array = row.get("slid_to", []) as Array
		if to.size() >= 2:
			# THE CELL IS THE DECLARATION, NOT THE FLOOR. 191 beads stand somewhere
			# other than the cell their map names; `rings` says the ring search moved
			# it, its absence says the pack aimed it elsewhere before any search ran.
			if row.has("rings"):
				bits.append("stands at %d,%d after a %d-ring search" % [
					int(to[0]), int(to[1]), int(row.get("rings", 0))])
			else:
				bits.append("stands at %d,%d — the pack re-homed it" % [int(to[0]), int(to[1])])
	if not bool(row.get("in_spine", true)):
		bits.append("in NO curriculum")
	elif row.get("spine_i") != null:
		bits.append("spine bead %d" % (int(row.get("spine_i")) + 1))
	return "  ·  ".join(PackedStringArray(bits))


## The two numbers that make the whole string honest, straight from _meta.
func _museum_census_line() -> String:
	return ("%d of %d placements stand today (%d halls of %d built)  ·  "
		+ "%d off-curriculum  ·  %d claimed and nowhere built") % [
		int(_meta.get("built_artifacts", 0)), int(_meta.get("placements", 0)),
		_built_band_count(), _bands.size(),
		int(_meta.get("off_curriculum_artifacts", 0)), int(_meta.get("orphans_n", 0))]


func _built_band_count() -> int:
	var n: int = 0
	for bd in _bands:
		if int((bd as Dictionary).get("built_n", 0)) > 0:
			n += 1
	return n


func _other_source_label() -> String:
	if _source == SRC_MUSEUM:
		return "the SPINE — the dealing order, %s and editable" % (
			"810 beads" if _slots[SRC_SPINE].is_empty() else
			"%d beads" % int((_slots[SRC_SPINE] as Dictionary).get("size", 810)))
	return "the MUSEUM — every artifact as it stands, 0 m to 4,270 m, read-only"


func _banner_text() -> String:
	var i: int = _focus_i()
	if _order.is_empty():
		return ""
	var row: Dictionary = _order[i]
	var seq := str(row.get("sequence", ""))
	if _is_museum:
		var hall := str(row.get("hall", ""))
		if hall == "":
			return ("— claimed, nowhere built —   %d artifacts the curriculum names "
				+ "that stand in NO hall") % int(_meta.get("orphans_n", 0))
		var built: bool = bool(row.get("built", true))
		return "%s  ·  chapter %s  ·  %s%s" % [
			seq, _chapter_text(row), hall,
			"" if built else "   —   NOT BUILT, a proposal"]
	for c in _bands:
		var ch: Dictionary = c
		if str(ch.get("sequence", "")) == seq and not bool(ch.get("in_spine", true)):
			return "%s  —  DISSOLVED: in the generated order but not in curriculum_spine.json" % seq
	return seq


func _hand_counts() -> Array:
	var a: int = 0
	var m: int = 0
	for r in _order:
		match str((r as Dictionary).get("origin", "spine")):
			"hand": a += 1
			"moved": m += 1
	var d: int = int(_meta.get("base_artifacts", _order.size())) - (_order.size() - a)
	return [a, maxi(d, 0), m]


func _update_detail(i: int) -> void:
	if _detail_box == null or i < 0 or i >= _order.size():
		return
	for c in _detail_box.get_children():
		c.queue_free()
	var row: Dictionary = _order[i]
	var head := WHS.heading(str(row.get("lookup", "")))
	head.clip_text = true
	head.custom_minimum_size = Vector2(0, 0)
	_detail_box.add_child(head)
	var alive: bool = bool(row.get("alive", true))
	var body: bool = bool(row.get("body", true))
	if _is_museum:
		_museum_detail(i, row)
	else:
		_detail_box.add_child(_kv("chapter", "%s   %d / %d" % [
			str(row.get("sequence", "")), int(row.get("seq_i", 0)) + 1, int(row.get("seq_n", 0))]))
		_detail_box.add_child(_kv("bead", "%d of %d" % [i + 1, _order.size()]))
		# `map` MEANS SOMETHING DIFFERENT IN THE TWO FILES, and museum_order's own
		# schema says so: here it is where the spine FIRST meets the artifact; there
		# it is the hall you are standing in. Same key, different fact.
		_detail_box.add_child(_kv("first met in", str(row.get("map", "")) if str(row.get("map", "")) != "" else "— (hand add)"))
		_detail_box.add_child(_kv("origin", str(row.get("origin", _neutral_origin))))
	_detail_box.add_child(_kv("dealt", "yes" if alive else "NO — " + str(row.get("dead", ""))))
	_detail_box.add_child(_kv("root", "%s%s" % [
		str(row.get("root", "?")), "" if body else "   NOT A 3D NODE"]))
	if row.has("delegate_to"):
		_detail_box.add_child(_kv("delegates to", str(row.get("delegate_to", ""))))
	_detail_box.add_child(_kv("footprint", "%d cells" % int(row.get("fp", 1))))
	if row.get("size_m") != null:
		_detail_box.add_child(_kv("size", "%.2f m" % float(row.get("size_m"))))
	else:
		_detail_box.add_child(_kv("size", "unmeasured"))
	_detail_box.add_child(_kv("category", str(row.get("category", ""))))
	# the tail of a res:// path names the file, so trim the HEAD of this one
	_detail_box.add_child(_kv("scene", str(row.get("scene", "")), true))
	if str(row.get("why", "")) != "":
		_detail_box.add_child(_kv("why", str(row.get("why", ""))))
	var d := str(row.get("desc", ""))
	if d != "":
		var dl := Label.new()
		dl.text = d
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.add_theme_font_size_override("font_size", WHS.FS_BODY)
		dl.add_theme_color_override("font_color", WHS.TEXT)
		# 0 minimum, EXPAND_FILL: a fixed 330 is a floor on the panel's width, and
		# a floor is exactly what pushed it off the screen. Let it take the width
		# the panel has and wrap into it.
		dl.custom_minimum_size = Vector2(0, 0)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_detail_box.add_child(dl)


## The museum half of the inspector. Every row here is a question the spine bead
## cannot answer, and the labels are the museum's own words, not the spine's.
func _museum_detail(i: int, row: Dictionary) -> void:
	var state := str(row.get("state", ""))
	# AN ORPHAN HAS NO HALL, SO IT MUST NOT BE DESCRIBED AS ONE. The first render
	# showed "in the hall 50 of 50" and "chapter built: NO — nobody has walked this
	# hall" on wiki_fragment, which stands in no hall at all: both rows were the
	# generic branch answering a question that does not apply.
	var orphan: bool = state == "nowhere"
	_detail_box.add_child(_kv("at", _identity_of(row)))
	if orphan:
		_detail_box.add_child(_kv("metre", "— it is nowhere on the walk"))
		_detail_box.add_child(_kv("hall", "NONE — no hall holds it"))
		_detail_box.add_child(_kv("the band", "%d of %d claimed and nowhere built" % [
			int(row.get("band_i", 0)) + 1, int(row.get("band_n", 0))]))
	else:
		_detail_box.add_child(_kv("metre", "%s m of %d" % [
			_metre_text(row), int(_meta.get("metres", 0))]))
		_detail_box.add_child(_kv("hall", _hall_text(row)))
		_detail_box.add_child(_kv("in the hall", "%d of %d" % [
			int(row.get("band_i", 0)) + 1, int(row.get("band_n", 0))]))
		_detail_box.add_child(_kv("chapter", "%s   ch %s   %d / %d" % [
			str(row.get("sequence", "")), _chapter_text(row),
			int(row.get("seq_i", 0)) + 1, int(row.get("seq_n", 0))]))
	_detail_box.add_child(_kv("bead", "%d of %d" % [i + 1, _order.size()]))
	_detail_box.add_child(_kv("state", state.to_upper() + (
		"" if state == "placed" else "   NO BODY STANDS HERE")))
	if str(row.get("why", "")) != "" and state != "placed":
		_detail_box.add_child(_kv("because", str(row.get("why", ""))))
	if not orphan:
		_detail_box.add_child(_kv("chapter built", "yes" if bool(row.get("built", true))
			else "NO — a proposal; nobody has walked this hall"))
	if row.get("cx") != null:
		_detail_box.add_child(_kv("map cell", "%d,%d   rot %d" % [
			int(row.get("cx")), int(row.get("cz")), int(row.get("rot", 0))]))
	if row.has("slid_to"):
		var to: Array = row.get("slid_to", []) as Array
		if to.size() >= 2:
			var how := "the pack aimed it here before any search ran"
			if row.has("rings"):
				how = "%d-ring search" % int(row.get("rings", 0))
			_detail_box.add_child(_kv("stands at", "%d,%d   (%s)" % [
				int(to[0]), int(to[1]), how]))
			if row.get("slid_x_m") != null and row.get("slid_z_m") != null:
				_detail_box.add_child(_kv("stands at, m", "x %d   z %d" % [
					int(row.get("slid_x_m")), int(row.get("slid_z_m"))]))
			# `why` on a PLACED bead is the reason it MOVED, not a failure. The word
			# is shared with `refused`, where it is the reason nothing stands — so
			# say which one this is rather than printing a bare "why".
			if str(row.get("why", "")) != "" and state == "placed":
				_detail_box.add_child(_kv("moved because", str(row.get("why", ""))))
	if int(row.get("of", 1)) > 1:
		_detail_box.add_child(_kv("this token", "#%d of %d on the string" % [
			int(row.get("nth", 1)), int(row.get("of", 1))]))
	if bool(row.get("in_spine", true)):
		_detail_box.add_child(_kv("in the spine", "yes — %s, bead %d" % [
			str(row.get("spine_sequence", "?")), int(row.get("spine_i", 0)) + 1]))
	else:
		_detail_box.add_child(_kv("in the spine", "NO — it stands here and no curriculum names it"))
	if str(row.get("cell_raw", "")) != "":
		_detail_box.add_child(_kv("the map says", str(row.get("cell_raw", "")), true))
	_detail_box.add_child(_kv("origin", "%s%s" % [
		str(row.get("origin", _neutral_origin)),
		"   (the museum's neutral origin)" if str(row.get("origin", "")) == _neutral_origin else ""]))


## A kv_row THAT CANNOT WIDEN THE PANEL. WHStyle.kv_row's value Label neither
## clips nor wraps, so its minimum width is the full text width — and a Control's
## combined minimum size OVERRIDES its anchors and offsets. One 60-character
## res:// scene path therefore stretched the inspector straight off the right
## edge of the window, taking the description and half the values with it. The
## rendered frame is where that showed; nothing in the geometry could.
##   clip_text drops the Label's minimum width to zero; the full value stays on
## the tooltip, so nothing is lost, only bounded.
func _kv(k: String, v: String, trim_head: bool = false) -> HBoxContainer:
	var r := WHS.kv_row(k, v)
	var vl := r.get_child(1) as Label
	if vl != null:
		vl.clip_text = true
		vl.custom_minimum_size = Vector2(0, 0)
		vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if trim_head:
			# right-aligned + clip trims from the LEFT, which keeps the filename
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.tooltip_text = v
		vl.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


## REQUIREMENT: it must open and SAY SO. A stage with no beads and no sentence is
## indistinguishable from a broken tool.
##   BUILT ONCE AND REUSED. It used to add a fresh CanvasLayer every call, which
## was harmless while there was one string and one load; with TAB it would stack a
## new panel on every failed switch, and the second one would never be dismissed.
func _show_fatal() -> void:
	if _fatal_panel == null:
		return
	_fatal_panel.visible = _fatal != ""
	if _fatal_label != null:
		_fatal_label.text = _fatal
	if _fatal == "":
		return
	if _hud != null:
		_hud.text = "[%s]  no order — see the panel.  TAB: %s" % [
			"MUSEUM" if _is_museum else "SPINE", _other_source_label()]
	# AND CLEAR THE OTHER STRING'S LEFTOVERS. _update_hud returns early while a
	# source is fatal, so the banner and the inspector kept whatever the string we
	# just switched AWAY from had in them — the rendered failure frame showed
	# "postfoundationscrisis" on the banner and a full spine bead in the panel,
	# under a headline saying there is no order to show. Two answers on screen,
	# one of them about a different string.
	if _banner != null:
		_banner.text = ""
	if _detail_box != null:
		for c in _detail_box.get_children():
			c.queue_free()


func _build_fatal(layer: CanvasLayer) -> void:
	_fatal_panel = PanelContainer.new()
	_fatal_panel.add_theme_stylebox_override("panel", WHS.panel_box())
	_fatal_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_fatal_panel.offset_left = -400
	_fatal_panel.offset_right = 400
	_fatal_panel.offset_top = -180
	_fatal_panel.offset_bottom = 180
	_fatal_panel.visible = false
	layer.add_child(_fatal_panel)
	var box := VBoxContainer.new()
	_fatal_panel.add_child(box)
	box.add_child(WHS.heading("THE NECKLACE HAS NO ORDER TO SHOW"))
	_fatal_label = Label.new()
	_fatal_label.add_theme_font_size_override("font_size", 14)
	_fatal_label.add_theme_color_override("font_color", WHS.TEXT)
	_fatal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fatal_label.custom_minimum_size = Vector2(0, 0)
	_fatal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_fatal_label)


## WHAT THIS STRING IS, IN ITS OWN WORDS. museum_order_effective.json's readme
## asks for _meta.source_check.note and _report VERBATIM, and it is right to: the
## bake it derives state from is ADVISORY, three of its segments are silent rather
## than empty, and a view that quietly smoothed that over would be the third place
## in this repo to publish a confident number over an unread caveat.
func _build_why(layer: CanvasLayer) -> void:
	_why_panel = PanelContainer.new()
	_why_panel.add_theme_stylebox_override("panel", WHS.panel_box())
	_why_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_why_panel.offset_left = 12
	_why_panel.offset_right = 620
	_why_panel.offset_top = 96
	_why_panel.offset_bottom = 640
	_why_panel.visible = false
	layer.add_child(_why_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_why_panel.add_child(scroll)
	_why_box = VBoxContainer.new()
	_why_box.add_theme_constant_override("separation", 4)
	_why_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_why_box)


func _refresh_why() -> void:
	if _why_box == null:
		return
	for c in _why_box.get_children():
		c.queue_free()
	_why_box.add_child(WHS.heading("WHAT THIS STRING IS"))
	_why_para(str(_meta.get("generator", "")) + "   ·   generated " + str(_meta.get("generated", "")))
	if _read_only:
		_why_para("READ-ONLY. " + READ_ONLY_WHY)
	var sc: Variant = _meta.get("source_check")
	if sc is Dictionary:
		_why_para(str((sc as Dictionary).get("note", "")))
	# _report VERBATIM, every bucket, in the file's own order. No summarising: the
	# whole value of these lines is that they are the generator's own hedges.
	for key in ["applied", "stale", "degraded", "refused", "notes"]:
		var v: Variant = _report.get(key)
		if not (v is Array) or (v as Array).is_empty():
			continue
		_why_box.add_child(WHS.heading(str(key).to_upper()))
		for line in (v as Array):
			_why_para("· " + str(line))


func _why_para(text: String) -> void:
	if text.strip_edges() == "":
		return
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", WHS.FS_BODY)
	l.add_theme_color_override("font_color", WHS.TEXT)
	l.custom_minimum_size = Vector2(0, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_why_box.add_child(l)


# ───────────────────────────────────────────────────────────────────── input
## TAB IS TAKEN BY THE GUI, SO IT IS CAUGHT ONE STAGE EARLIER. Godot's input order
## is _input → Control focus navigation → _shortcut_input → _unhandled_input, and
## ui_focus_next is bound to Tab: whenever any Control in this scene holds focus —
## a palette button the curator has just clicked, the category dropdown — the
## viewport consumes Tab to move focus and NOTHING downstream ever sees it. The
## key would work until the moment somebody used the add list, and then stop, which
## is worse than not binding it. So Tab is claimed in _input, before the GUI, and
## marked handled; the LineEdit guard still stands, because inside a filter box Tab
## is the curator's own word and not a command.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if (event as InputEventKey).keycode != KEY_TAB:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	get_viewport().set_input_as_handled()
	toggle_source()


func _unhandled_input(event: InputEvent) -> void:
	# _unhandled_input, not _input: it only fires for events the UI did not
	# consume, so typing in the filter never reaches a shortcut. AND the explicit
	# focus guard as well, because the two mechanisms catch different cases
	# (WallHangarEditor.gd:550).
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return
	if _fatal != "":
		# EVERYTHING is refused while a string will not load — except leaving. F10
		# and the source swap must survive, or a missing museum file traps the
		# curator on a blank stage with no key that does anything. (TAB is handled
		# in _input above and never reaches here.)
		if (event is InputEventKey) and event.pressed \
				and (event as InputEventKey).keycode == KEY_F10:
			get_tree().change_scene_to_file("res://commons/scenes/vr_staging.tscn")
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				_scroll(-3 if mb.shift_pressed else -1)
			MOUSE_BUTTON_WHEEL_DOWN:
				_scroll(3 if mb.shift_pressed else 1)
			MOUSE_BUTTON_LEFT:
				if _hover >= 0:
					_want = float(_hover)
					_refresh_window(false)
					_update_hud()
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	# Ctrl+Z as well as U: the match below is on keycode alone and cannot see a
	# modifier, and undo is the one verb everybody reaches for by reflex.
	if (event as InputEventKey).keycode == KEY_Z and (event as InputEventKey).ctrl_pressed:
		undo_last()
		return
	# `match` sees the keycode alone and cannot read a modifier, so the bracket
	# pair is handled before it: in the museum a band is a HALL, and 207 rooms one
	# at a time is a long walk to the far end of a chapter.
	var kc: int = (event as InputEventKey).keycode
	if kc == KEY_BRACKETLEFT or kc == KEY_BRACKETRIGHT:
		var dir: int = -1 if kc == KEY_BRACKETLEFT else 1
		if _is_museum and (event as InputEventKey).shift_pressed:
			_chapter_jump(dir)
		else:
			_band_step(dir)
		return
	match kc:
		KEY_LEFT: _scroll(-1)
		KEY_RIGHT: _scroll(1)
		KEY_PAGEUP: _scroll(-WINDOW)
		KEY_PAGEDOWN: _scroll(WINDOW)
		KEY_HOME: _scroll_to(0)
		KEY_END: _scroll_to(_order.size() - 1)
		KEY_R:
			_why_panel.visible = not _why_panel.visible
			if _why_panel.visible:
				_refresh_why()
		KEY_A:
			# refuse BEFORE opening: `candidates` is empty by design in the museum
			# file, so the panel would open, show "0 in the pool" and leave the
			# curator to work out why
			if _read_only:
				_refuse_edit("there is no add list")
			else:
				_palette.visible = not _palette.visible
				if _palette.visible:
					_rebuild_palette_categories()
					_refresh_palette()
		KEY_X, KEY_DELETE:
			drop_bead(_hover if _hover >= 0 else _focus_i())
		KEY_COMMA: move_focus(-1)
		KEY_PERIOD: move_focus(1)
		KEY_U: undo_last()
		KEY_L:
			_live_on = not _live_on
			if not _live_on:
				_free_live()
				_live_index = -1
				_live_note = "live body off"
			else:
				_live_note = "live body on — building at the focus"
				_live_still = LIVE_DEBOUNCE
			_update_hud()
		KEY_C:
			_cam_near = not _cam_near
			_apply_camera()
		KEY_H:
			_help.visible = not _help.visible
		KEY_ESCAPE:
			if _palette.visible:
				_palette.visible = false
			elif _why_panel.visible:
				_why_panel.visible = false
		KEY_F10:
			if _pending > 0:
				print("[necklace] leaving with %d op(s) written but not applied — run `%s`"
					% [_pending, APPLY_CMD])
			get_tree().change_scene_to_file("res://commons/scenes/vr_staging.tscn")


func _scroll(n: int) -> void:
	_scroll_to(_focus_i() + n)


func _scroll_to(i: int) -> void:
	_want = float(clampi(i, 0, maxi(0, _order.size() - 1)))
	_refresh_window(false)
	_update_hud()


## One band forward or back — a chapter on the spine, a HALL in the museum.
func _band_step(dir: int) -> void:
	var here: int = _focus_i()
	if dir > 0:
		for c in _bands:
			if int((c as Dictionary).get("i0", 0)) > here:
				_scroll_to(int((c as Dictionary).get("i0", 0)))
				return
		_scroll_to(_order.size() - 1)
	else:
		var target: int = 0
		for c in _bands:
			var i0: int = int((c as Dictionary).get("i0", 0))
			if i0 < here:
				target = i0
		_scroll_to(target)


## Museum only: the head of the next / previous CHAPTER, skipping its halls. 207
## rooms is thirty minutes of bracket-tapping to cross the building otherwise.
func _chapter_jump(dir: int) -> void:
	var here: int = _focus_i()
	if _order.is_empty():
		return
	var seq := str((_order[here] as Dictionary).get("sequence", ""))
	if dir > 0:
		for i in range(here + 1, _order.size()):
			if str((_order[i] as Dictionary).get("sequence", "")) != seq:
				_scroll_to(i)
				return
		_scroll_to(_order.size() - 1)
		return
	# back: the head of THIS chapter first, then the head of the one before it
	var head: int = here
	while head > 0 and str((_order[head - 1] as Dictionary).get("sequence", "")) == seq:
		head -= 1
	if head < here:
		_scroll_to(head)
		return
	if head == 0:
		_scroll_to(0)
		return
	var prev := str((_order[head - 1] as Dictionary).get("sequence", ""))
	var i2: int = head - 1
	while i2 > 0 and str((_order[i2 - 1] as Dictionary).get("sequence", "")) == prev:
		i2 -= 1
	_scroll_to(i2)


func _update_hover() -> void:
	if _cam == null or not is_inside_tree():
		return
	var vp := get_viewport()
	if vp == null:
		return
	var mp: Vector2 = vp.get_mouse_position()
	var o: Vector3 = _cam.project_ray_origin(mp)
	var d: Vector3 = _cam.project_ray_normal(mp)
	var best: int = -1
	var bd: float = 0.95           # the bead plate is 1.32 m; half of that plus slack
	for k in _beads.keys():
		var i: int = int(k)
		var anchor: Node3D = _node_or_null((_beads[i] as Dictionary).get("anchor"))
		if anchor == null or not anchor.visible:
			continue
		# distance from the bead centre to the cursor ray — no physics, so a bead
		# with no collider is still pickable (EmEditor.pick's reason, its geometry)
		var c: Vector3 = anchor.global_position + anchor.global_transform.basis * Vector3(0, -0.80, 0)
		var t: float = (c - o).dot(d)
		if t <= 0.0:
			continue
		var dist: float = (c - (o + d * t)).length()
		if dist < bd:
			bd = dist
			best = i
	if best != _hover:
		var was: int = _hover
		_hover = best
		if was >= 0:
			_style_bead(was)
		if best >= 0:
			_style_bead(best)


# ───────────────────────────────────────────────────────────── small helpers
## `as Node3D` on a FREED object ABORTS the function rather than yielding null,
## so the is_instance_valid() on the next line never runs. Documented in
## em_editor.gd:40 after it made the whole museum unselectable. A window that
## frees beads on every scroll walks straight into it.
static func _node_or_null(v: Variant) -> Node3D:
	if v == null or not is_instance_valid(v):
		return null
	return v as Node3D


## ABSENT IS NOT UNREADABLE, AND THE OLD READER COULD NOT TELL THEM APART.
## It returned {} for a missing file, an empty file, a truncated file and a file
## holding a JSON array — so the scene said "no hand file yet … untouched" over a
## hand file that EXISTS and will not parse, and _append_op then built a fresh
## document ON TOP OF IT. That is the whole hand, silently overwritten, on the
## next keystroke.
##   Returns {"state": absent|empty|corrupt|not_a_dict|ok, "doc": {}, "why": ""}.
func _read_json_state(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"state": "absent", "doc": {}, "why": ""}
	var text := FileAccess.get_file_as_string(path)
	if text == "" and FileAccess.get_open_error() != OK:
		return {"state": "corrupt", "doc": {}, "why":
			"the file exists but will not open (error %d)" % FileAccess.get_open_error()}
	if text.strip_edges() == "":
		return {"state": "empty", "doc": {}, "why": "the file exists and is empty"}
	var j := JSON.new()
	var err: int = j.parse(text)
	if err != OK:
		return {"state": "corrupt", "doc": {}, "why":
			"JSON error on line %d: %s" % [j.get_error_line(), j.get_error_message()]}
	if not (j.data is Dictionary):
		return {"state": "not_a_dict", "doc": {}, "why":
			"the file parses but holds a %s, not an object" % type_string(typeof(j.data))}
	return {"state": "ok", "doc": j.data as Dictionary, "why": ""}


## A state is READABLE when overwriting it loses nothing: it is not there, or it
## is there and empty. Anything else is somebody's work and must not be clobbered.
static func _state_is_writable(state: String) -> bool:
	return state == "ok" or state == "absent" or state == "empty"


func _read_json_dict(path: String) -> Dictionary:
	return _read_json_state(path).get("doc", {}) as Dictionary


static func _chapter_color(seq: String) -> Color:
	# a stable hash so a chapter keeps its colour across sessions and across the
	# 23 bands, the tokenColor() trick the hall editor already uses
	var h: int = 0
	for i in seq.length():
		h = (h * 31 + seq.unicode_at(i)) % 1000003
	return Color.from_hsv(float(h % 360) / 360.0, 0.34, 0.56)


func _slab(pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	add_child(m)


# ───────────────────────────────────────────────── public API (probe + keys)
## Everything the headless probe drives. Keys call the same functions, so the
## probe exercises the tool and not a parallel path.
func bead_count() -> int:
	var n: int = 0
	for k in _beads.keys():
		var a: Node3D = _node_or_null((_beads[k] as Dictionary).get("anchor"))
		if a != null and a.visible:
			n += 1
	return n


func window_first() -> int:
	return _win_first()


func focus_index() -> int:
	return _focus_i()


func focus_lookup() -> String:
	if _order.is_empty():
		return ""
	return str((_order[focus_index()] as Dictionary).get("lookup", ""))


func order_size() -> int:
	return _order.size()


func candidate_count() -> int:
	return _candidates.size()


func candidate_lookup_at(i: int) -> String:
	if i < 0 or i >= _candidates.size():
		return ""
	return str((_candidates[i] as Dictionary).get("lookup", ""))


func origin_at(i: int) -> String:
	if i < 0 or i >= _order.size():
		return ""
	return str((_order[i] as Dictionary).get("origin", "spine"))


func visible_lookups() -> PackedStringArray:
	## The ten on the string right now, left to right — what the eye sees.
	var out: PackedStringArray = PackedStringArray()
	var keys: Array = _beads.keys()
	keys.sort()
	for k in keys:
		var i: int = int(k)
		var a: Node3D = _node_or_null((_beads[i] as Dictionary).get("anchor"))
		if a != null and a.visible:
			out.append(lookup_at(i))
	return out


func lookup_at(i: int) -> String:
	if i < 0 or i >= _order.size():
		return ""
	return str((_order[i] as Dictionary).get("lookup", ""))


## THE BEAD'S IDENTITY, NOT ITS TOKEN. A probe that checks visible_lookups() on
## the museum string is checking a list with `laser_measure` in it four times.
func identity_at(i: int) -> String:
	if i < 0 or i >= _order.size():
		return ""
	return _identity_of(_order[i])


func visible_identities() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var keys: Array = _beads.keys()
	keys.sort()
	for k in keys:
		var i: int = int(k)
		var a: Node3D = _node_or_null((_beads[i] as Dictionary).get("anchor"))
		if a != null and a.visible:
			out.append(identity_at(i))
	return out


## The three Label3D lines a museum bead carries, read back off the NODES rather
## than recomputed — a probe that re-derives the text proves nothing about what
## was drawn. [mark, place, cap, sub]; empty strings on a bead not built.
func bead_lines(i: int) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray(["", "", "", ""])
	if not _beads.has(i):
		return out
	var b: Dictionary = _beads[i]
	for pair in [["mark", 0], ["place", 1], ["cap", 2], ["sub", 3]]:
		var n: Node3D = _node_or_null(b.get(str((pair as Array)[0])))
		if n != null and n is Label3D and n.visible:
			out[int((pair as Array)[1])] = (n as Label3D).text
	return out


func state_at(i: int) -> String:
	if i < 0 or i >= _order.size():
		return ""
	return str((_order[i] as Dictionary).get("state", ""))


func metre_at(i: int) -> int:
	if i < 0 or i >= _order.size():
		return -1
	var z: Variant = (_order[i] as Dictionary).get("z_m")
	return -1 if z == null else int(z)


func band_label_at(i: int) -> String:
	if i < 0 or i >= _order.size():
		return ""
	return _band_key(_order[i])


func band_count() -> int:
	return _bands.size()


func is_read_only() -> bool:
	return _read_only


func is_museum() -> bool:
	return _is_museum


func neutral_origin() -> String:
	return _neutral_origin


func notice() -> String:
	return _notice


func scroll_to_index(i: int) -> void:
	_scroll_to(i)


func set_source(name: String) -> void:
	set_source_index(SRC_MUSEUM if str(name).to_lower().begins_with("mus") else SRC_SPINE)


func show_why(on: bool) -> void:
	if _why_panel == null:
		return
	_why_panel.visible = on
	if on:
		_refresh_why()


func why_lines() -> int:
	return 0 if _why_box == null else _why_box.get_child_count()


## The first focusable Control in the scene, for the probe that has to prove TAB
## survives a Control holding keyboard focus — the case that made _input, rather
## than _unhandled_input, the right place to catch it.
func first_focusable() -> Control:
	var stack: Array = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		for c in n.get_children():
			stack.append(c)
		if n is OptionButton and (n as Control).is_visible_in_tree():
			return n as Control
	return null


func scroll_by(n: int) -> void:
	_scroll(n)


func settle_scroll() -> void:
	## Jump the animation to its target — a probe has no seconds to spend
	## watching a lerp, and every other read depends on where the string IS.
	_pos = _want
	_refresh_window(true)
	_update_hud()


func index_of(lookup: String) -> int:
	for i in _order.size():
		if str((_order[i] as Dictionary).get("lookup", "")) == lookup:
			return i
	return -1


func set_live(on: bool) -> void:
	_live_on = on
	if not on:
		_free_live()
		_live_index = -1
	else:
		_live_still = LIVE_DEBOUNCE     # build at the next tick, not in three frames
	_update_hud()


func live_refusal_at(i: int) -> String:
	## The guard, callable without instantiating anything — which is the point:
	## a test that had to BUILD boid_flocking to learn it must not be built would
	## hang, since that is the documented headless-hang artifact.
	if i < 0 or i >= _order.size():
		return "out of range"
	return _live_refusal(_order[i])


func live_mounted() -> bool:
	return _node_or_null(_live_node) != null


func live_scale() -> float:
	var n3: Node3D = _node_or_null(_live_node)
	return 0.0 if n3 == null else n3.scale.x


func live_note() -> String:
	return _live_note


func ops_broken() -> bool:
	## The hand file exists and will not parse. Every edit verb refuses while this
	## is true; the probe reads it rather than inferring from a suppressed HUD line.
	return _ops_broken


func ops_broken_why() -> String:
	return _ops_broken_why


func undo_depth() -> int:
	## How many edits this session can still take back.
	return _undo.size()


func resolved_ops_path() -> String:
	return ops_path


func fatal_message() -> String:
	return _fatal
