# pattern_machine_a.gd
# THE JACQUARD PUNCH-CARD LOOM — an interactive pattern machine.
#
# A sci-fi weaving apparatus whose "program" is a physical PUNCH CARD: an NxN
# peg-board mounted on the machine head. The player toggles pegs by touch (or
# by the punch button), and the loom weaves the corresponding wallpaper-group
# carpet LIVE, scrolling it continuously out over the feed roller onto the
# floor. The card is the program; the loom is the body that runs it.
#
# Reads the wallpaper engine (WallpaperGroups.get_symmetric_color) for live
# per-cell tiling — exactly like pattern_maker_station — but wraps it in the
# pattern_loom machine vocabulary (frame, warp threads, weave bar, feed roller,
# scrolling cloth, emissive accents). Edit the punch card -> the woven carpet
# updates the same frame.

# @identity
# essence: punch_card(NxN pegs) -> wallpaper_group -> woven carpet. The Jacquard
#          insight made literal — the holes in the card ARE the program, and the
#          loom weaves whatever the card says, metre after metre.
# desire: to let hands punch the card on the machine and watch the loom change
#         what it weaves in real time; to feel that a textile is the OUTPUT of a
#         readable, editable program, not a fixed sample on a plate.
# critical_parameter: the punch card (the motif grid). A handful of toggled pegs,
#          read through one of 17 wallpaper groups, becomes endless fabric.
# triggers: touch a peg (Area3D) to toggle it; PUNCH cycles the paint color;
#          GROUP cycles the 17 symmetry programs; WEAVE re-rolls a fresh motif;
#          CLEAR blanks the card. Every edit re-weaves the live carpet.
# emerges: the federated move — reuse the grammar's symmetry operator + the
#          loom's scrolling-cloth machine, add a hands-on punch card on the head.
# needs: [has] push_button for group/punch/weave/clear; [has] touch-toggle pegs
#        via Area3D; [has] glowing warp threads + weave bar + feed roller;
#        [has] live carpet via get_symmetric_color; [has] scroll animation.
# relationships: sibling to pattern_loom (manufactures) and pattern_maker_station
#        (edits) — this does BOTH: an editable loom. Carpet uses WallpaperGroups.
# truth: the Jacquard loom was the first programmable machine. The pattern was
#        never woven by hand — it was punched into a card and read by the rule.

extends Node3D
class_name PatternMachineA

# ── DNA ──────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m) — the weaving program.
@export var group: String = "p4m"
## Palette name (bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome).
@export var palette: String = "bauhaus"
## Motif seed — two digits of DNA decide the starting punch card.
@export var motif_seed: int = 7
## Punch-card resolution (NxN pegs). 4-8.
@export var card_size: int = 5
## Fill density of the seeded card.
@export var density: float = 0.5
## Pick a fresh random group / motif / density each load (a map that pins one turns this off).
@export var randomize_on_start: bool = true

@export_group("Machine")
@export var frame_color: Color = Color(0.11, 0.12, 0.16)
@export var accent_color: Color = Color(0.95, 0.55, 0.18)   # amber/copper sci-fi accent
@export var warp_color: Color = Color(1.0, 0.7, 0.3)
@export var carpet_width: float = 1.3
@export var carpet_length: float = 2.6
@export var carpet_repeats: int = 8        # how many card-repeats across the carpet
@export var scroll_speed: float = 0.14

# ── Group order (string names indexed for cycling) ───────────────────────
const GROUP_NAMES: Array = [
	"p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
	"p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m"
]

# ── Palette (Bauhaus-ish textile colors; index 0 = unpunched/ground) ─────
const PALETTE: Array[Color] = [
	Color(0.93, 0.92, 0.88),  # 0 ground (unpunched)
	Color(0.76, 0.22, 0.18),  # 1 red
	Color(0.94, 0.77, 0.18),  # 2 gold
	Color(0.14, 0.31, 0.44),  # 3 navy
	Color(0.20, 0.45, 0.30),  # 4 green
	Color(0.10, 0.12, 0.18),  # 5 near-black
]

# ── PRESETS — ported from the web Italy study pack (italy-study-pack.ts) ──
# Each is a whole rule-combo, exactly like selecting a SITE in /pattern-maker:
# a wallpaper group + a motif card (the site's field motif domain) + a period
# palette. Picking one loads group+card+palette and pushes a fresh band, so the
# carpet records "the loom was set to Casa del Fauno here". Index 0 of every
# palette is the woven ground (unpunched); 1..N are the period's tesserae colors.
const PRESETS: Array = [
	{   # Casa del Fauno, Pompeii — perspective cubes (P3M1), Roman Imperial
		"name": "FAUNO",
		"group": "p3m1",
		"palette": ["#EBE6D9", "#141418", "#B32719", "#C09933"],
		"motif_size": 6,
		"motif": [
			[0, 0, 1, 1, 2, 2],
			[0, 0, 1, 1, 2, 2],
			[2, 2, 0, 0, 1, 1],
			[2, 2, 0, 0, 1, 1],
			[1, 1, 2, 2, 0, 0],
			[1, 1, 2, 2, 0, 0],
		],
	},
	{   # Casa dei Vettii, Pompeii — checkerboard (P4M), Roman Imperial
		"name": "VETTII",
		"group": "p4m",
		"palette": ["#EBE6D9", "#141418", "#B32719", "#C09933"],
		"motif_size": 2,
		"motif": [
			[0, 1],
			[1, 0],
		],
	},
	{   # Casa dei Cervi, Herculaneum — diamond lozenge (CMM), Roman Imperial
		"name": "CERVI",
		"group": "cmm",
		"palette": ["#EBE6D9", "#141418", "#267366", "#B32719"],
		"motif_size": 4,
		"motif": [
			[0, 0, 1, 0],
			[0, 1, 1, 1],
			[1, 1, 0, 1],
			[0, 1, 0, 0],
		],
	},
	{   # Santa Chiara Cloister, Naples — floral cross (P4M), Baroque majolica
		"name": "CHIARA",
		"group": "p4m",
		"palette": ["#F5F0E1", "#1F3380", "#D9B333", "#2D6633"],
		"motif_size": 8,
		"motif": [
			[0, 0, 0, 1, 1, 0, 0, 0],
			[0, 0, 2, 1, 1, 2, 0, 0],
			[0, 2, 3, 2, 2, 3, 2, 0],
			[1, 1, 2, 0, 0, 2, 1, 1],
			[1, 1, 2, 0, 0, 2, 1, 1],
			[0, 2, 3, 2, 2, 3, 2, 0],
			[0, 0, 2, 1, 1, 2, 0, 0],
			[0, 0, 0, 1, 1, 0, 0, 0],
		],
	},
	{   # Villa San Michele, Capri — octagon & square (P4M), Cosmatesque marble
		"name": "MICHELE",
		"group": "p4m",
		"palette": ["#E8E0D4", "#8C1A26", "#264D26", "#1A3399"],
		"motif_size": 6,
		"motif": [
			[0, 1, 1, 1, 1, 0],
			[1, 1, 0, 0, 1, 1],
			[1, 0, 0, 0, 0, 1],
			[1, 0, 0, 0, 0, 1],
			[1, 1, 0, 0, 1, 1],
			[0, 1, 1, 1, 1, 0],
		],
	},
	{   # Museo Archeologico, Naples — nested diamonds (PMM), Roman Imperial
		"name": "MUSEO",
		"group": "pmm",
		"palette": ["#EBE6D9", "#141418", "#B32719", "#C09933"],
		"motif_size": 8,
		"motif": [
			[0, 0, 0, 1, 1, 0, 0, 0],
			[0, 0, 1, 0, 0, 1, 0, 0],
			[0, 1, 0, 0, 0, 0, 1, 0],
			[1, 0, 0, 1, 1, 0, 0, 1],
			[1, 0, 0, 1, 1, 0, 0, 1],
			[0, 1, 0, 0, 0, 0, 1, 0],
			[0, 0, 1, 0, 0, 1, 0, 0],
			[0, 0, 0, 1, 1, 0, 0, 0],
		],
	},
]

const COL_PEG_HOLE := Color(0.05, 0.05, 0.06)   # empty peg socket
const COL_SEAM := Color(0.04, 0.04, 0.05)       # dark seam line between rule-bands

# ── Card geometry on the machine head ────────────────────────────────────
const CARD_CELL := 0.075         # meters per peg cell
const CARD_Z := 0.06             # how far the card sits in front of the head

# ── Banded chronicle ─────────────────────────────────────────────────────
# The carpet is a TIMELINE: each horizontal band is a frozen snapshot of the
# rule (group + card + palette) at the moment it was woven. Newest band sits at
# the production end (nearest the loom head / console); older bands trail off
# toward the far end. When the history overflows BAND_CAP, the oldest is dropped.
const BAND_CAP := 6              # how many rule-bands the fabric remembers
const BAND_ROWS := 2            # how many card-heights tall each band is woven
const BAND_SEAM_PX := 2         # thickness (px) of the dark seam between bands

# ── State ────────────────────────────────────────────────────────────────
var _card: Array = []             # 2D array [y][x] of color indices (0 = hole)
var _paint_color: int = 1         # color punched in on touch
var _group_index: int = 0
var _palette: Array[Color] = []   # the live palette (a band snapshots whatever this is)
var _bands: Array = []            # capped history; each = {group_index, card(deep copy), palette}

# ── Scene refs ────────────────────────────────────────────────────────────
var _card_root: Node3D
var _peg_meshes: Array = []       # 2D array of MeshInstance3D
var _peg_mats: Array = []         # 2D array of StandardMaterial3D
var _carpet_mesh: MeshInstance3D
var _carpet_mat: StandardMaterial3D
var _group_label: Label3D
var _touch_area: Area3D
var _weave_mats: Array[StandardMaterial3D] = []
var _warp_mats: Array[StandardMaterial3D] = []
var _last_toggled: Vector2i = Vector2i(-999, -999)
var _elapsed: float = 0.0

# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_overrides()
	_palette = PALETTE.duplicate()    # live palette; bands snapshot whatever this is at the time
	_group_index = clampi(GROUP_NAMES.find(group.to_lower()), 0, GROUP_NAMES.size() - 1)
	if _group_index < 0:
		_group_index = 0
	if randomize_on_start:
		_group_index = randi() % GROUP_NAMES.size()
		motif_seed = 1 + randi() % 8
		density = randf_range(0.3, 0.7)
	_seed_card()

	# Seed an initial timeline from the presets so the carpet is ALREADY a
	# chronicle at build — it remembers rules from before the player arrived.
	# The live rule (current card/group/palette) becomes the newest band on top.
	_seed_initial_bands()

	_card_root = Node3D.new()
	_card_root.name = "CardHead"
	# The head faces the player (-Z), raised to chest height.
	_card_root.rotation_degrees.y = 180
	_card_root.position.y = 1.05
	add_child(_card_root)

	_build_frame()
	_build_warp()
	_build_feed_roller()
	_build_card_panel()
	_build_pegs()
	_build_controls()
	_build_touch_area()
	_build_carpet()
	_build_control_plate()
	_build_capture_camera()
	_reweave()
	print("[PatternMachineA] Jacquard loom built — %dx%d card, group %s" % [
		card_size, card_size, GROUP_NAMES[_group_index]])

func _process(delta: float) -> void:
	_elapsed += delta
	_check_touch_toggle()
	# The machine is always producing: scroll the woven cloth out of the loom.
	if _carpet_mat:
		var o := _carpet_mat.uv1_offset
		o.y = fposmod(o.y + scroll_speed * delta, 1.0)
		_carpet_mat.uv1_offset = o
	# Pulse the weave bar + travelling shimmer down the warp.
	var pulse := 1.6 + 1.2 * (0.5 + 0.5 * sin(_elapsed * 5.0))
	for m in _weave_mats:
		m.emission_energy_multiplier = pulse
	for i in range(_warp_mats.size()):
		_warp_mats[i].emission_energy_multiplier = 0.6 + 0.6 * (0.5 + 0.5 * sin(_elapsed * 4.0 - i * 0.5))

func apply_grid_config(config: Dictionary) -> void:
	# an explicit pattern in the map pins it (turns off start-randomisation)
	if config.has("group") or config.has("motif_seed") or config.has("density"):
		randomize_on_start = false
	if config.has("randomize_on_start"): randomize_on_start = bool(config["randomize_on_start"])
	if config.has("group"): group = str(config["group"])
	if config.has("palette"): palette = str(config["palette"])  # reserved; PALETTE is fixed textile set
	if config.has("motif_seed"): motif_seed = int(config["motif_seed"])
	if config.has("card_size"): card_size = clampi(int(config["card_size"]), 4, 8)
	if config.has("density"): density = clampf(float(config["density"]), 0.0, 1.0)
	if config.has("carpet_repeats"): carpet_repeats = maxi(1, int(config["carpet_repeats"]))
	if config.has("scroll_speed"): scroll_speed = float(config["scroll_speed"])
	# Rebuild from scratch with the new DNA.
	for c in get_children():
		c.queue_free()
	_peg_meshes.clear(); _peg_mats.clear()
	_weave_mats.clear(); _warp_mats.clear()
	_card.clear()
	_bands.clear()
	_palette.clear()
	call_deferred("_ready")

func _read_overrides() -> void:
	for k in ["group", "palette"]:
		if has_meta("config_%s" % k):
			set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"):
		motif_seed = int(str(get_meta("config_motif_seed")))
	if has_meta("config_card_size"):
		card_size = clampi(int(str(get_meta("config_card_size"))), 4, 8)


# ═══════════════════════════════════════════════════════════════════════
# CONTROL PLATE — the shared Dieter Rams interface (pattern_control_plate)
# ═══════════════════════════════════════════════════════════════════════

func _build_control_plate() -> void:
	if has_node("ControlConsole"):
		return
	# the same display_console kiosk the Pattern Tunnel uses (plate recessed in a 28°
	# CSG face); it carries the plate at scale 1.0 so the XR sliders work.
	var scene := load("res://commons/artifacts/pattern_tunnel/display_console.tscn")
	if scene == null:
		return
	var plate: Node = scene.instantiate()
	plate.name = "ControlConsole"
	if plate.has_method("configure"):
		var gnames: Array = []
		for g in GROUP_NAMES:
			gnames.append(String(g).to_upper())
		var pnames: Array = []
		for p in PRESETS:
			pnames.append(String(p["name"]))
		plate.call("configure", "JACQUARD  LOOM", [
			{"key": "group",   "label": "GROUP",   "names": gnames, "init": _group_index},
			{"key": "motif",   "label": "MOTIF",   "names": ["I","II","III","IV","V","VI","VII","VIII"], "init": clampi(motif_seed - 1, 0, 7)},
			{"key": "density", "label": "DENSITY", "names": [], "min": 0.0, "max": 1.0, "init": density},
			{"key": "preset",  "label": "PRESET",  "names": pnames, "init": 0},
		])
	# operator station: a step the player stands on (the carpet weaves out toward -Z), with
	# the console at its front edge facing the player, so they look DOWN past the console at
	# the carpet the loom is producing — interface + production in one line of sight.
	_build_operator_platform(Vector3(0.0, 0.0, 3.7), Vector3(2.4, 0.36, 1.7))
	add_child(plate)
	(plate as Node3D).position = Vector3(0.0, 0.36, 3.1)
	(plate as Node3D).rotation_degrees = Vector3(0.0, 0.0, 0.0)   # screen faces the player at +Z, carpet weaves toward them
	if plate.has_signal("changed") and not plate.is_connected("changed", _on_plate):
		plate.connect("changed", _on_plate)
	if plate.has_signal("randomized") and not plate.is_connected("randomized", _on_plate_random):
		plate.connect("randomized", _on_plate_random)


## A small collidable step the player stands on to look down on the production.
func _build_operator_platform(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "OperatorPlatform"
	body.position = center + Vector3(0.0, size.y * 0.5, 0.0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.31, 0.34)
	mat.roughness = 0.85
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)


func _on_plate(key: String, value: float) -> void:
	match key:
		"group":
			_group_index = clampi(int(value), 0, GROUP_NAMES.size() - 1)
			group = GROUP_NAMES[_group_index]
			if _group_label:
				_group_label.text = group.to_upper()
		"motif":
			motif_seed = int(value) + 1
			_seed_card()
			_refresh_pegs()
		"density":
			density = clampf(value, 0.0, 1.0)
			_seed_card()
			_refresh_pegs()
		"preset":
			_apply_preset(int(value))
			return   # _apply_preset pushes its own band + reweaves
	# Any rule change writes a new band into the timeline (newest = the live rule).
	_push_band(_current_snapshot())
	_reweave()


func _on_plate_random() -> void:
	_palette = PALETTE.duplicate()
	_group_index = randi() % GROUP_NAMES.size()
	group = GROUP_NAMES[_group_index]
	if _group_label:
		_group_label.text = group.to_upper()
	motif_seed = 1 + randi() % 8
	density = randf_range(0.25, 0.78)
	_seed_card()
	_refresh_pegs()
	_push_band(_current_snapshot())
	_reweave()


## Recolour the existing peg meshes from the current card (no rebuild).
func _refresh_pegs() -> void:
	for y in range(_peg_mats.size()):
		var row: Array = _peg_mats[y]
		for x in range(row.size()):
			var mat: StandardMaterial3D = row[x]
			if mat == null:
				continue
			var ci: int = 0
			if y < _card.size() and x < _card[y].size():
				ci = int(_card[y][x])
			var col: Color = PALETTE[ci] if ci > 0 and ci < PALETTE.size() else COL_PEG_HOLE
			mat.albedo_color = col

# ═══════════════════════════════════════════════════════════════════════
# CARD DATA
# ═══════════════════════════════════════════════════════════════════════

func _seed_card() -> void:
	## Deterministic starting punch card from the motif seed.
	_card.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = motif_seed
	var n_colors := PALETTE.size()
	for y in card_size:
		var row: Array = []
		for x in card_size:
			if rng.randf() < density:
				row.append(1 + rng.randi() % (n_colors - 1))
			else:
				row.append(0)
		_card.append(row)

# ═══════════════════════════════════════════════════════════════════════
# BANDED CHRONICLE — the fabric remembers every rule it was set to
# ═══════════════════════════════════════════════════════════════════════

func _deep_copy_card(card: Array) -> Array:
	## A real 2D copy (rows duplicated) so a band can't be mutated by later edits.
	var out: Array = []
	for row in card:
		out.append((row as Array).duplicate())
	return out

func _current_snapshot() -> Dictionary:
	## Freeze the live rule (group + card + palette) as a band.
	return {
		"group_index": _group_index,
		"card": _deep_copy_card(_card),
		"size": card_size,
		"palette": _palette.duplicate(),
	}

func _push_band(snapshot: Dictionary) -> void:
	## Append the newest rule; drop the oldest if we exceed the memory cap.
	_bands.append(snapshot)
	while _bands.size() > BAND_CAP:
		_bands.pop_front()

func _update_live_band() -> void:
	## The newest band IS the live rule being woven now — replace it in place
	## (used for fine hand-edits so each peg toggle doesn't spawn a new band).
	if _bands.is_empty():
		_push_band(_current_snapshot())
	else:
		_bands[_bands.size() - 1] = _current_snapshot()

func _seed_initial_bands() -> void:
	## Plant a few preset bands BEFORE the live rule so the carpet is already a
	## timeline at build (it remembers rules from before the player arrived).
	## Newest = the live rule (current card/group/palette) on top of the stack.
	_bands.clear()
	# three historical preset bands (oldest first), distinct groups/palettes
	for idx in [1, 0, 5]:   # VETTII, FAUNO, MUSEO — three clearly different rules
		_bands.append(_band_from_preset(idx))
	# then the current live rule as the newest band at the production end
	_bands.append(_current_snapshot())
	while _bands.size() > BAND_CAP:
		_bands.pop_front()

func _band_from_preset(preset_index: int) -> Dictionary:
	## Build a band snapshot from a preset WITHOUT touching the live rule.
	var p: Dictionary = PRESETS[clampi(preset_index, 0, PRESETS.size() - 1)]
	var card := _fit_motif_to_card(p["motif"], int(p["motif_size"]))
	return {
		"group_index": clampi(GROUP_NAMES.find(String(p["group"]).to_lower()), 0, GROUP_NAMES.size() - 1),
		"card": card,
		"size": card_size,
		"palette": _palette_from_hex(p["palette"]),
	}

func _apply_preset(preset_index: int) -> void:
	## Load a whole rule-combo (group + motif card + palette) in one move, exactly
	## like picking a SITE in the web editor — then push it as a new band.
	var p: Dictionary = PRESETS[clampi(preset_index, 0, PRESETS.size() - 1)]
	_group_index = clampi(GROUP_NAMES.find(String(p["group"]).to_lower()), 0, GROUP_NAMES.size() - 1)
	group = GROUP_NAMES[_group_index]
	_palette = _palette_from_hex(p["palette"])
	_card = _fit_motif_to_card(p["motif"], int(p["motif_size"]))
	if _group_label:
		_group_label.text = group.to_upper()
	_refresh_pegs()
	_push_band(_current_snapshot())
	_reweave()
	print("[PatternMachineA] Loaded preset -> %s (%s)" % [String(p["name"]), group])

func _fit_motif_to_card(motif: Array, motif_size: int) -> Array:
	## Resample any motif grid into the loom's fixed card_size via nearest-neighbour,
	## clamping color indices into the live palette so pegs/weave stay valid.
	var out: Array = []
	var max_ci := maxi(0, _palette.size() - 1)
	for y in card_size:
		var row: Array = []
		var sy := clampi(int(float(y) / float(card_size) * float(motif_size)), 0, motif_size - 1)
		for x in card_size:
			var sx := clampi(int(float(x) / float(card_size) * float(motif_size)), 0, motif_size - 1)
			var ci := 0
			if sy < motif.size() and sx < (motif[sy] as Array).size():
				ci = int(motif[sy][sx])
			row.append(clampi(ci, 0, max_ci))
		out.append(row)
	return out

func _palette_from_hex(hex_list: Array) -> Array[Color]:
	## Period palette -> the loom's color table. Index 0 is the woven ground; the
	## rest are the period's tesserae. Pad to PALETTE's length so every index is safe.
	var pal: Array[Color] = []
	for h in hex_list:
		pal.append(Color(String(h)))
	while pal.size() < PALETTE.size():
		pal.append(pal[pal.size() - 1] if pal.size() > 0 else Color.WHITE)
	return pal

# ═══════════════════════════════════════════════════════════════════════
# MACHINE BUILDERS
# ═══════════════════════════════════════════════════════════════════════

func _build_frame() -> void:
	## Heavy dark frame: two side posts + a top crossbeam carrying the card head.
	var half := carpet_width * 0.5 + 0.22
	var post_h := 1.55
	_box(Vector3(0.10, post_h, 0.12), Vector3(-half, post_h * 0.5, 0.0), frame_color)
	_box(Vector3(0.10, post_h, 0.12), Vector3(half, post_h * 0.5, 0.0), frame_color)
	_box(Vector3(half * 2.0 + 0.10, 0.12, 0.16), Vector3(0, post_h, 0.0), frame_color)
	# Emissive header strip — the machine's status light.
	_emissive_box(Vector3(half * 2.0 - 0.1, 0.025, 0.025),
		Vector3(0, post_h - 0.10, 0.10), accent_color, 1.8)
	# Base skids on the floor.
	_box(Vector3(0.16, 0.08, 0.55), Vector3(-half, 0.04, 0.1), frame_color.lightened(0.05))
	_box(Vector3(0.16, 0.08, 0.55), Vector3(half, 0.04, 0.1), frame_color.lightened(0.05))

func _build_warp() -> void:
	## Glowing vertical warp threads behind the card head — the loom reading.
	var count := 15
	var span := carpet_width
	var base_y := 0.18
	var h := 1.30
	for i in range(count):
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0045; cm.bottom_radius = 0.0045; cm.height = h
		cm.radial_segments = 6
		t.mesh = cm
		var x := lerpf(-span * 0.5, span * 0.5, float(i) / float(maxi(1, count - 1)))
		t.position = Vector3(x, base_y + h * 0.5, -0.08)
		var m := StandardMaterial3D.new()
		m.albedo_color = warp_color
		m.emission_enabled = true
		m.emission = warp_color
		m.emission_energy_multiplier = 0.9
		t.material_override = m
		_warp_mats.append(m)
		add_child(t)

func _build_feed_roller() -> void:
	## The roller the woven carpet emerges over + the glowing weave bar (active shed).
	var roller := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.07; rm.bottom_radius = 0.07; rm.height = carpet_width + 0.18
	rm.radial_segments = 20
	roller.mesh = rm
	roller.rotation_degrees = Vector3(0, 0, 90)
	roller.position = Vector3(0, 0.42, CARD_Z + 0.05)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = frame_color.lightened(0.12)
	rmat.metallic = 0.6; rmat.roughness = 0.35
	roller.material_override = rmat
	add_child(roller)
	# Weave bar — pulsing emissive cylinder right at the feed line.
	_weave_bar(Vector3(0, 0.42, CARD_Z + 0.12), carpet_width + 0.08)

func _weave_bar(pos: Vector3, length: float) -> void:
	var bar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022; cm.bottom_radius = 0.022; cm.height = length
	cm.radial_segments = 12
	bar.mesh = cm
	bar.rotation_degrees = Vector3(0, 0, 90)
	bar.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = accent_color
	m.emission_enabled = true
	m.emission = accent_color
	m.emission_energy_multiplier = 2.0
	bar.material_override = m
	_weave_mats.append(m)
	add_child(bar)

# ═══════════════════════════════════════════════════════════════════════
# PUNCH CARD (interactive head)
# ═══════════════════════════════════════════════════════════════════════

func _build_card_panel() -> void:
	## Dark backing plate the pegs sit in — the "card".
	var total := card_size * CARD_CELL
	var plate := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(total + 0.06, total + 0.10, 0.035)
	plate.mesh = bm
	plate.material_override = _make_mat(frame_color.lightened(0.06), 0.4, 0.5)
	plate.position = Vector3(0, total * 0.5 + 0.02, CARD_Z - 0.02)
	_card_root.add_child(plate)

	# Title
	var title := Label3D.new()
	title.text = "PUNCH CARD"
	title.pixel_size = 0.0008
	title.font_size = 14
	title.modulate = accent_color
	title.position = Vector3(0, total + 0.10, CARD_Z + 0.02)
	_card_root.add_child(title)

func _build_pegs() -> void:
	_card_root_pegs_container()
	var total := card_size * CARD_CELL
	var start_x := -total / 2.0
	var start_y := 0.04

	_peg_meshes.clear()
	_peg_mats.clear()
	for y in card_size:
		var row_mesh: Array = []
		var row_mat: Array = []
		for x in card_size:
			# Socket ring (always-present dark hole)
			var socket := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = CARD_CELL * 0.42; sm.bottom_radius = CARD_CELL * 0.42
			sm.height = 0.012; sm.radial_segments = 10
			socket.mesh = sm
			socket.rotation_degrees = Vector3(90, 0, 0)
			socket.material_override = _make_mat(COL_PEG_HOLE, 0.2, 0.7)
			socket.position = Vector3(
				start_x + x * CARD_CELL + CARD_CELL * 0.5,
				start_y + (card_size - 1 - y) * CARD_CELL + CARD_CELL * 0.5,
				CARD_Z + 0.005)
			_card_root.add_child(socket)

			# Peg (the punched plug — color = card value; hidden if 0)
			var peg := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = CARD_CELL * 0.34; pm.bottom_radius = CARD_CELL * 0.34
			pm.height = 0.03; pm.radial_segments = 10
			peg.mesh = pm
			peg.rotation_degrees = Vector3(90, 0, 0)
			var ci: int = _card[y][x]
			var mat := _make_mat(PALETTE[ci], 0.3, 0.55)
			if ci > 0:
				mat.emission_enabled = true
				mat.emission = PALETTE[ci]
				mat.emission_energy_multiplier = 0.6
			peg.visible = ci > 0
			peg.material_override = mat
			peg.position = Vector3(
				start_x + x * CARD_CELL + CARD_CELL * 0.5,
				start_y + (card_size - 1 - y) * CARD_CELL + CARD_CELL * 0.5,
				CARD_Z + 0.022)
			_card_root.add_child(peg)

			row_mesh.append(peg)
			row_mat.append(mat)
		_peg_meshes.append(row_mesh)
		_peg_mats.append(row_mat)

func _card_root_pegs_container() -> void:
	# Pegs are added directly to _card_root; helper kept for clarity/no-op.
	pass

func _build_controls() -> void:
	var total := card_size * CARD_CELL
	# Controls live on the right post, facing the player.
	var bx := total * 0.5 + 0.16
	var by := total * 0.85

	# GROUP cycle
	var group_btn := _spawn_button("GroupBtn", Vector3(bx, by, CARD_Z), accent_color)
	_connect_btn(group_btn, _cycle_group)
	_btn_label(group_btn, "GROUP")
	_group_label = Label3D.new()
	_group_label.text = GROUP_NAMES[_group_index].to_upper()
	_group_label.pixel_size = 0.0008
	_group_label.font_size = 12
	_group_label.modulate = accent_color
	_group_label.position = Vector3(bx, by - 0.05, CARD_Z + 0.02)
	_card_root.add_child(_group_label)

	# PUNCH (cycle paint color)
	var punch_btn := _spawn_button("PunchBtn", Vector3(bx, by - 0.13, CARD_Z), PALETTE[_paint_color])
	_connect_btn(punch_btn, _cycle_paint)
	_btn_label(punch_btn, "PUNCH")

	# WEAVE (re-roll a fresh random card from a new seed)
	var weave_btn := _spawn_button("WeaveBtn", Vector3(bx, by - 0.26, CARD_Z), Color(0.3, 0.85, 0.55))
	_connect_btn(weave_btn, _reroll_card)
	_btn_label(weave_btn, "WEAVE")

	# CLEAR
	var clr_btn := _spawn_button("ClearBtn", Vector3(bx, by - 0.39, CARD_Z), Color(0.8, 0.25, 0.2))
	_connect_btn(clr_btn, _clear_card)
	_btn_label(clr_btn, "CLEAR")

func _spawn_button(nm: String, pos: Vector3, color: Color) -> Node3D:
	var btn := load("res://commons/interactables/push_button.tscn").instantiate() as Node3D
	btn.name = nm
	btn.position = pos
	btn.scale = Vector3(0.55, 0.55, 0.55)
	# These props are not on Node3D's static type — set dynamically.
	btn.set("pressed_color", color)
	btn.set("released_color", color.darkened(0.45))
	_card_root.add_child(btn)
	return btn

func _btn_label(btn: Node3D, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0006
	lbl.font_size = 7
	lbl.modulate = Color(0.85, 0.85, 0.85)
	lbl.position = Vector3(0, -0.035, 0.0)
	btn.add_child(lbl)

func _connect_btn(btn: Node3D, cb: Callable) -> void:
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.connect("button_pressed", func(_b): cb.call())

# ═══════════════════════════════════════════════════════════════════════
# TOUCH TOGGLE
# ═══════════════════════════════════════════════════════════════════════

func _build_touch_area() -> void:
	_touch_area = Area3D.new()
	_touch_area.name = "CardTouch"
	_touch_area.collision_layer = 1048576   # bit 20 (interactive)
	_touch_area.collision_mask = 393216      # bits 18+19 (hands+pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false

	var total := card_size * CARD_CELL
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(total + 0.04, total + 0.04, 0.12)
	col.shape = shape
	col.position = Vector3(0, 0.04 + total * 0.5, CARD_Z + 0.02)
	_touch_area.add_child(col)
	_card_root.add_child(_touch_area)

func _check_touch_toggle() -> void:
	if not _touch_area:
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_toggled = Vector2i(-999, -999)
		return
	var total := card_size * CARD_CELL
	var start_x := -total / 2.0
	var start_y := 0.04
	for body in bodies:
		var local := _card_root.to_local(body.global_position)
		var gx := int((local.x - start_x) / CARD_CELL)
		var gy := card_size - 1 - int((local.y - start_y) / CARD_CELL)
		if gx >= 0 and gx < card_size and gy >= 0 and gy < card_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_toggled:
				_last_toggled = cell
				_toggle_peg(gx, gy)
			return

func _toggle_peg(gx: int, gy: int) -> void:
	## Touch toggles a peg: empty -> paint color, filled -> empty.
	if _card[gy][gx] == 0:
		_card[gy][gx] = _paint_color
	else:
		_card[gy][gx] = 0
	_refresh_peg(gx, gy)
	# Editing the card by hand is a rule change too — update the newest band in
	# place so the live edit shows at the production end without flooding the
	# history on every single peg toggle.
	_update_live_band()
	_reweave()

func _refresh_peg(gx: int, gy: int) -> void:
	var ci: int = _card[gy][gx]
	var peg: MeshInstance3D = _peg_meshes[gy][gx]
	var mat: StandardMaterial3D = _peg_mats[gy][gx]
	peg.visible = ci > 0
	mat.albedo_color = PALETTE[ci]
	if ci > 0:
		mat.emission_enabled = true
		mat.emission = PALETTE[ci]
		mat.emission_energy_multiplier = 0.6
	else:
		mat.emission_energy_multiplier = 0.0

func _refresh_all_pegs() -> void:
	for y in card_size:
		for x in card_size:
			_refresh_peg(x, y)

# ═══════════════════════════════════════════════════════════════════════
# CONTROL ACTIONS
# ═══════════════════════════════════════════════════════════════════════

func _cycle_group() -> void:
	_group_index = (_group_index + 1) % GROUP_NAMES.size()
	group = GROUP_NAMES[_group_index]
	if _group_label:
		_group_label.text = group.to_upper()
	_push_band(_current_snapshot())
	_reweave()
	print("[PatternMachineA] Program -> %s" % group)

func _cycle_paint() -> void:
	_paint_color = 1 + (_paint_color % (PALETTE.size() - 1))
	# Re-tint the PUNCH button so the player sees the active color.
	var btn := _card_root.get_node_or_null("PunchBtn")
	if btn:
		btn.set("pressed_color", PALETTE[_paint_color])
		btn.set("released_color", PALETTE[_paint_color].darkened(0.45))
		if btn.has_method("update_colors"):
			btn.call("update_colors")
	print("[PatternMachineA] Punch color -> %d" % _paint_color)

func _reroll_card() -> void:
	motif_seed = (motif_seed * 1103515245 + 12345) & 0x7fffffff
	_seed_card()
	_refresh_all_pegs()
	_push_band(_current_snapshot())
	_reweave()
	print("[PatternMachineA] Re-wove fresh card (seed %d)" % motif_seed)

func _clear_card() -> void:
	for y in card_size:
		for x in card_size:
			_card[y][x] = 0
	_refresh_all_pegs()
	_push_band(_current_snapshot())
	_reweave()

# ═══════════════════════════════════════════════════════════════════════
# CARPET (live wallpaper output)
# ═══════════════════════════════════════════════════════════════════════

func _build_carpet() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "WovenCarpet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	_carpet_mesh.mesh = pm
	# Runs forward from the feed roller across the floor.
	_carpet_mesh.position = Vector3(0, 0.01, CARD_Z + 0.12 + carpet_length * 0.5)
	_carpet_mat = StandardMaterial3D.new()
	_carpet_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # crisp tiles
	_carpet_mat.texture_repeat = true   # the timeline scrolls as a loop (wraps)
	_carpet_mat.roughness = 0.88
	_carpet_mat.metallic = 0.0
	# The banded texture already contains the whole timeline (bands stacked +
	# horizontal repeats baked in), so it maps ONCE down the carpet's length.
	# uv1_scale.y is NEGATIVE so the newest band (bottom of the image) sits at the
	# production end (near the feed roller / console) and history trails to the floor.
	_carpet_mat.uv1_scale = Vector3(1.0, -1.0, 1.0)
	_carpet_mat.uv1_offset = Vector3(0.0, 1.0, 0.0)
	_carpet_mesh.material_override = _carpet_mat
	add_child(_carpet_mesh)

func _reweave() -> void:
	## Weave the carpet as a BANDED CHRONICLE: one tall texture in which each
	## horizontal band is a different rule from the history, rendered with that
	## band's own punch card / wallpaper group / palette (same per-cell engine
	## as before, just run band-by-band instead of one uniform fill). A thin dark
	## seam separates the bands so the rule transitions read as a timeline.
	##
	## Image rows run top->bottom = OLDEST band -> NEWEST band. The carpet's UV is
	## flipped (uv1_scale.y = -1) so the newest band lands at the production end
	## (nearest the loom head / console) and history trails off toward the floor.
	if _bands.is_empty():
		_push_band(_current_snapshot())

	var tex_w: int = maxi(1, carpet_repeats * card_size)   # horizontal repeats baked in
	var band_h: int = maxi(1, BAND_ROWS * card_size)        # weave height of one band
	var n: int = _bands.size()
	var tex_h: int = n * band_h + (n - 1) * BAND_SEAM_PX
	if tex_w <= 0 or tex_h <= 0:
		return

	var image := Image.create(tex_w, tex_h, false, Image.FORMAT_RGBA8)
	var y0: int = 0
	for bi in range(n):
		var band: Dictionary = _bands[bi]
		var bcard: Array = band["card"]
		var bsize: int = int(band.get("size", card_size))
		var bpal: Array = band["palette"]
		var genum: int = _group_enum_for(GROUP_NAMES[int(band["group_index"])])
		var ground: Color = bpal[0] if bpal.size() > 0 else PALETTE[0]
		for ry in range(band_h):
			var py: int = y0 + ry
			for px in range(tex_w):
				var ci: int = WallpaperGroups.get_symmetric_color(px, ry, bsize, bcard, genum)
				var color: Color = bpal[ci] if ci >= 0 and ci < bpal.size() else ground
				image.set_pixel(px, py, color)
		y0 += band_h
		# dark seam line marking the rule change (skip after the last band)
		if bi < n - 1:
			for sy in range(BAND_SEAM_PX):
				var py2: int = y0 + sy
				for px2 in range(tex_w):
					image.set_pixel(px2, py2, COL_SEAM)
			y0 += BAND_SEAM_PX

	var tex := ImageTexture.create_from_image(image)
	if _carpet_mat:
		_carpet_mat.albedo_texture = tex

func _group_enum_for(name: String) -> int:
	## Map a group name string to the WallpaperGroups.Group enum value.
	match name.to_lower():
		"p1":   return WallpaperGroups.Group.P1
		"p2":   return WallpaperGroups.Group.P2
		"pm":   return WallpaperGroups.Group.PM
		"pg":   return WallpaperGroups.Group.PG
		"cm":   return WallpaperGroups.Group.CM
		"pmm":  return WallpaperGroups.Group.PMM
		"pmg":  return WallpaperGroups.Group.PMG
		"pgg":  return WallpaperGroups.Group.PGG
		"cmm":  return WallpaperGroups.Group.CMM
		"p4":   return WallpaperGroups.Group.P4
		"p4m":  return WallpaperGroups.Group.P4M
		"p4g":  return WallpaperGroups.Group.P4G
		"p3":   return WallpaperGroups.Group.P3
		"p3m1": return WallpaperGroups.Group.P3M1
		"p31m": return WallpaperGroups.Group.P31M
		"p6":   return WallpaperGroups.Group.P6
		"p6m":  return WallpaperGroups.Group.P6M
	return WallpaperGroups.Group.P1

# ═══════════════════════════════════════════════════════════════════════
# CAPTURE + UTILITIES
# ═══════════════════════════════════════════════════════════════════════

func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 58.0
	cam.position = Vector3(1.8, 1.9, 2.8)
	cam.rotation_degrees = Vector3(-26, 24, 0)
	add_child(cam)

func _make_mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.5
	m.metallic = 0.35
	mi.material_override = m
	add_child(mi)
	return mi

func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := _box(size, pos, color)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return mi
