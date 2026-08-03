# pattern_mill.gd — THE PATTERN MILL
#
# One apparatus that EDITS and MANUFACTURES a wallpaper-group carpet. The player
# touch-paints a small motif grid on the machine head; the mill re-tiles that
# fragment through one of the 17 wallpaper groups into a live texture and feeds
# the carpet forward off a roller/tray (uv1_offset scroll). Spinning mirror-wedge
# ROTORS make the symmetry mechanical — their blade count tracks the current
# group's rotational order (2/3/4/6-fold), so cycling the GROUP re-geometries the
# machine. Painting updates the carpet live; a discrete PRESS lever punches the
# head down and re-stamps, the tactile "I made this" stroke.
#
# This is the synthesis of four prototypes:
#   A (Jacquard loom)  — touch-toggle head, CPU re-tile via get_symmetric_color,
#                        _read_overrides meta pattern.
#   B (Holo press)     — bake-on-edit into ONE reusable ImageTexture (.update());
#                        dual output (vertical proof sheet + floor carpet) from one
#                        texture; the WORKING palette resolution from PatternSim.PALETTES.
#   C (Kaleidoscope)   — FOLD-ORDER ROTORS whose blade count = group rotational order;
#                        one freeable rotor container + material discipline on rebuild.
#   D (Tile-stamp)     — discrete operate-stroke: press head on guide rods + pull lever
#                        that punches down with a flash; conveyor output tray.
#
# @identity
# essence: motif_grid(NxN) -> wallpaper_group -> live carpet. An editable
#   manufacturing machine: paint a handful of cells on the head, watch spinning
#   mirror rotors multiply the fragment, and the mill feeds out endless symmetric
#   fabric. The symmetry IS the visible mechanism.
# desire: to fuse the editor and the machine — pattern_maker_station edits,
#   pattern_loom manufactures; the mill does both, and makes the group's fold
#   order legible as rotating mirror blades you can watch change when you cycle.
# critical_parameter: wallpaper_group — the symmetry operator. A few painted cells,
#   read through one of 17 groups, become a carpet. Cycling the group re-counts the
#   rotor blades (2/3/4/6 fold), so the program is written into the machine's body.
# triggers: touch-paint the head grid (Area3D); INK row picks paint colour; GROUP
#   cycles all 17 symmetry programs + rebuilds the rotors; SEED rerolls a procedural
#   motif; CLEAR blanks the grid; PRESS pulls the lever (head punch + flash + re-stamp).
#   Every edit re-tiles the live carpet.
# emerges: the federated move — reuse WallpaperGroups.get_symmetric_color +
#   PatternSim.PALETTES, wrap them in an interactive apparatus with a stroke.
# needs: [has] push_button INK + control row; [has] Area3D touch-paint head;
#   [has] fold-order mirror-wedge rotors; [has] press head + lever + guide rods;
#   [has] live carpet + proof sheet via one reusable texture; [has] output tray.
# relationships: sibling to pattern_loom (manufactures) and pattern_maker_station
#   (edits) — this does both. Reuses WallpaperGroups + PatternSim. Machine vocabulary
#   from pattern_loom / conveyor_belt / props-dna-gallery.
# truth: a pattern is a program plus a fragment. Hand someone the fragment and the
#   press — and the rotors that show them the rule turning — and they discover that
#   structure comes from constraint, not complexity. You mill architecture from almost
#   nothing.

extends Node3D
class_name PatternMill

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")
const WallpaperGroupsScript = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

# ── DNA ──────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m) — the mirrors the rotor enforces.
@export var group: String = "p4m"
## Palette name: bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome.
@export var palette: String = "bauhaus"
## Motif seed — deterministic starting motif; rerolled by SEED.
@export var motif_seed: int = 7
## Editable head grid (NxN cells the player paints). 3..8.
@export var motif_size: int = 5
## Fill density when (re)seeding the motif.
@export var density: float = 0.5

## AXIS — WHAT THE MILL PUTS ON SHOW OF A CLOSED SET.
##
## There are exactly seventeen wallpaper groups and there will never be an eighteenth. So a
## pattern mill is a machine for manufacturing something already completely enumerated, and
## the only real choice it has is how much of that closure it admits to the person standing
## in front of it. Each value is a different answer to "did you make this, or did you look
## it up?".
##
##   bolt       the finished cloth and nothing else — the legacy lineage, byte for byte.
##              Carpet, proof sheet and tray; the rule stays inside the machine and
##              invention is implied by silence.
##   unit       the run admits it is one tile. The domain lattice is scored across the whole
##              carpet, one domain is lifted bodily out of the field onto a pedestal leaving
##              a dark hole behind it, and a sample plate stands that same domain up beside
##              the run. The claim: one 16 cm fragment was made and the rest is translation.
##   operation  the cloth admits it is a group acting. Mirror axes as unbroken bars, glide
##              axes as broken runs, and a rotation-centre marker standing proud at the
##              lattice nodes whose sides count the fold order — a lens for 2, a triangle
##              for 3, a square for 4, a hexagon for 6, the same count the rotors turn.
##   catalogue  the mill stops pretending. A two-tier index board stands at the end of the
##              run carrying all seventeen groups, each swatch milled from THIS hopper so
##              the seventeen are genuinely comparable, the one in the machine lit and the
##              other sixteen dark. Entry k of a closed set was selected; here is k, and
##              here are the sixteen you did not pick.
##
## Shared word for word with [[pattern_machine_c]], the larger body of the same argument, so
## a room holding both cannot have one of them claiming authorship while the other admits to
## a lookup. The three registry names mill_alhambra_p6m / mill_escher_p4g / mill_persian_p4
## are all delegates onto THIS script, so they inherit the axis and measure alike — the
## group and palette they carry are the program, not the identity.
@export var exhibit: String = "bolt"
const EXHIBITS: PackedStringArray = ["bolt", "unit", "operation", "catalogue"]

## AXIS — WHICH MOMENT OF ITS WORKING LIFE THE MACHINE IS CAUGHT IN.
##
## Adopted word for word (and value for value) from [[station_wall]] / [[station_pillar]] /
## [[station_crates]], where `upkeep` already runs across seven pieces of the curation kit,
## and shared with [[pattern_loom]], which takes the same four values in the same order. A
## bay whose walls read "packed down" must not hold a mill that still reads "in commission".
##
## Where `exhibit` above is about the CLOTH — how much of a closed set of seventeen the goods
## admit to — this one is about the MACHINE. Every textile in history came off a press that
## was oiled, opened, stopped, sheeted and eventually broken up; the shipped mill runs
## frictionlessly forever with nobody at it. These three values put the labour back.
##
##   service  in commission — the legacy lineage, byte for byte
##   works    mid-job       — a trestle deck stood off the flank with tools on it, a conduit
##                            run over the head, the side cover leaned against the frame
##   store    packed down   — a sheet strapped over the core, the rotors and the head grid
##                            together, and the run's output banded into finished bolts
##                            stacked on the floor beside it
##   scrap    robbed        — the flank cladding gone and the studs bared, the cover dropped
##                            flat on the floor, hazard tape crossed over the hole
##
## THE PIVOT IS THE HEAD. The core glow, the fold-order rotors and the accent rail are the
## brightest pixels the mill owns; `store` covers all three at once, which is why it reads
## from across a room and why the four values do not measure alike.
##
## THE CARPET IS NEVER COVERED. The milled cloth and the proof sheet are what the artifact
## teaches, so every value is dressed onto the machine body and the floor at its flank.
## Default `service` reproduces every existing mill placement exactly.
@export_enum("service", "works", "store", "scrap") var upkeep: String = "service"
const UPKEEPS: PackedStringArray = ["service", "works", "store", "scrap"]

@export_group("Machine")
@export var frame_color: Color = Color(0.11, 0.12, 0.16)     # dark industrial
@export var metal_color: Color = Color(0.32, 0.34, 0.40)     # brushed metal
@export var accent_color: Color = Color(0.95, 0.55, 0.18)    # warm amber accent
@export var core_color: Color = Color(0.35, 0.9, 1.0)        # cyan core glow
@export var carpet_width: float = 1.3                        # output carpet width (m)
@export var carpet_length: float = 2.6                       # floor carpet run (m)
@export var sheet_height: float = 1.0                        # vertical proof-sheet height (m)
@export var carpet_repeats: int = 8                          # domain repeats across the carpet
@export var rotor_speed: float = 0.6                         # rad/s base rotor spin
@export var scroll_speed: float = 0.14                       # uv feed speed

# ── Group order (string + enum, indexed for cycling) ──────────────────────
const GROUP_NAMES: Array = [
	"p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
	"p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m",
]

# ── Layout constants ──────────────────────────────────────────────────────
const HEAD_Y: float = 1.25            # height of the editable head grid
const HEAD_CELL: float = 0.075        # metres per head cell
const CORE_Y: float = 0.95            # rotor / core height
const HEAD_Z: float = -0.05           # head sits just behind machine origin

# ── State ─────────────────────────────────────────────────────────────────
var _grid: Array = []                 # head cells [y][x] -> color index into _palette
var _palette: Array = []              # Array of Color, resolved from PatternSim.PALETTES
var _ink: int = 1                     # selected paint index
var _group_index: int = 10            # index into GROUP_NAMES (p4m default)
var _current_group: int = WallpaperGroupsScript.Group.P4M
var _spin_dir: float = 1.0
var _elapsed: float = 0.0

# ── Scene refs ────────────────────────────────────────────────────────────
var PUSH_BUTTON: PackedScene
var _head_root: Node3D                # holds the editable cell grid
var _cell_mats: Array = []            # [y][x] -> StandardMaterial3D (head cells)
var _ink_indicators: Array[MeshInstance3D] = []
var _touch_area: Area3D
var _last_cell: Vector2i = Vector2i(-1, -1)

var _output_tex: ImageTexture        # ONE reusable texture feeding both outputs
var _carpet_mat: StandardMaterial3D  # floor carpet
var _sheet_mat: StandardMaterial3D   # vertical proof sheet
var _group_label: Label3D

# Animated machine parts
var _rotor_assembly: Node3D          # ONE freeable container for the whole rotor drum
var _rotor_ring_mat: StandardMaterial3D
var _rotor_pivot: Node3D             # the spinning pivot carrying the wedges
var _core_mat: StandardMaterial3D
var _warp_mats: Array[StandardMaterial3D] = []
var _accent_mats: Array[StandardMaterial3D] = []
var _chute_mat: StandardMaterial3D   # scrolls a feed band down the chute

# Press stroke (discrete operate)
var _press_head: Node3D
var _lever: Node3D
var _press_anim: float = -1.0         # <0 idle, else 0..1 stroke progress
var _stamped_this_stroke: bool = false

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	_read_overrides()
	motif_size = clampi(motif_size, 3, 8)
	_group_index = _name_to_index(group)
	_current_group = _index_to_enum(_group_index)
	_resolve_palette()
	_seed_motif()

	_build_base_and_frame()
	_build_core_and_rotors()
	_build_warp_cage()
	_build_head_grid()
	_build_palette_row()
	_build_control_row()
	_build_press_head_and_lever()
	_build_output_chute()
	_build_carpet()
	_build_proof_sheet()
	_build_touch_area()
	_build_labels()
	_build_capture_camera()
	_rebake_output()
	_build_exhibit()
	# LAST OF ALL, appended after the exhibit for the same reason it was appended after the
	# machine: every child index and position above is untouched. `service` adds nothing.
	_build_upkeep()

	print("[PatternMill] Built — %dx%d head, group %s, palette %s, exhibit %s" % [
		motif_size, motif_size, GROUP_NAMES[_group_index], palette, exhibit])


func _process(delta: float) -> void:
	_elapsed += delta
	_check_touch_paint()

	# Spin the kaleidoscope mirror wedges — the symmetry made mechanism.
	if is_instance_valid(_rotor_pivot):
		_rotor_pivot.rotation.y += rotor_speed * _spin_dir * delta

	# Carpet + proof sheet feed (uv1_offset scroll).
	if _carpet_mat:
		var co := _carpet_mat.uv1_offset
		co.y = fposmod(co.y + scroll_speed * delta, 1.0)
		_carpet_mat.uv1_offset = co
	if _sheet_mat:
		var so := _sheet_mat.uv1_offset
		so.y = fposmod(so.y - scroll_speed * delta, 1.0)
		_sheet_mat.uv1_offset = so

	# Pulse the glowing core.
	if _core_mat:
		_core_mat.emission_energy_multiplier = 1.8 + 1.0 * (0.5 + 0.5 * sin(_elapsed * 3.0))
	# Travelling shimmer along the warp threads.
	for i in range(_warp_mats.size()):
		_warp_mats[i].emission_energy_multiplier = 0.6 + 0.6 * (0.5 + 0.5 * sin(_elapsed * 4.0 - i * 0.4))
	# Accent rails breathe (press face flashes harder during a stroke).
	var ap := 1.4 + 0.8 * (0.5 + 0.5 * sin(_elapsed * 2.2))
	if _press_anim >= 0.0:
		ap += 2.5 * sin(clampf(_press_anim, 0.0, 1.0) * PI)
	for m in _accent_mats:
		m.emission_energy_multiplier = ap
	# Output chute feeds the carpet band forward.
	if _chute_mat:
		var o := _chute_mat.uv1_offset
		o.y = fposmod(o.y + 0.18 * delta, 1.0)
		_chute_mat.uv1_offset = o

	_animate_press(delta)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("group"):
		group = str(config["group"])
	if config.has("wallpaper_group"):
		_group_index = clampi(int(config["wallpaper_group"]), 0, GROUP_NAMES.size() - 1)
		group = GROUP_NAMES[_group_index]
	if config.has("palette"): palette = str(config["palette"])
	if config.has("motif_seed"): motif_seed = int(config["motif_seed"])
	if config.has("motif_size"): motif_size = clampi(int(config["motif_size"]), 3, 8)
	if config.has("density"): density = clampf(float(config["density"]), 0.0, 1.0)
	if config.has("exhibit"):
		var _e: String = str(config["exhibit"]).strip_edges().to_lower()
		exhibit = _e if EXHIBITS.has(_e) else exhibit
	if config.has("upkeep"):
		upkeep = _norm_upkeep(str(config["upkeep"]))
	if config.has("carpet_width"): carpet_width = float(config["carpet_width"])
	if config.has("carpet_length"): carpet_length = float(config["carpet_length"])
	if config.has("carpet_repeats"): carpet_repeats = maxi(1, int(config["carpet_repeats"]))
	if config.has("rotor_speed"): rotor_speed = float(config["rotor_speed"])
	if config.has("scroll_speed"): scroll_speed = float(config["scroll_speed"])
	# Rebuild from scratch with the new DNA.
	for c in get_children():
		c.queue_free()
	_cell_mats.clear(); _ink_indicators.clear()
	_warp_mats.clear(); _accent_mats.clear()
	_grid.clear(); _palette.clear()
	_core_mat = null; _chute_mat = null
	_rotor_assembly = null; _rotor_ring_mat = null; _rotor_pivot = null
	_carpet_mat = null; _sheet_mat = null; _output_tex = null
	_press_head = null; _lever = null
	_last_cell = Vector2i(-1, -1)
	_press_anim = -1.0
	call_deferred("_ready")


func _read_overrides() -> void:
	for k in ["group", "palette"]:
		if has_meta("config_%s" % k):
			set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"):
		motif_seed = int(str(get_meta("config_motif_seed")))
	if has_meta("config_motif_size"):
		motif_size = clampi(int(str(get_meta("config_motif_size"))), 3, 8)
	if has_meta("config_density"):
		density = clampf(float(str(get_meta("config_density"))), 0.0, 1.0)
	if has_meta("config_exhibit"):
		# Normalising read: an unknown word leaves the shipped default standing rather than
		# silently milling a value nothing in this file knows how to build.
		var e: String = str(get_meta("config_exhibit")).strip_edges().to_lower()
		if EXHIBITS.has(e):
			exhibit = e
	if has_meta("config_upkeep"):
		# Same normalising read: an unknown word leaves the shipped default standing rather
		# than asking the match block for a moment nothing in this file knows how to build.
		upkeep = _norm_upkeep(str(get_meta("config_upkeep")))

# ═══════════════════════════════════════════════════════════════════════════
# DATA — palette + motif
# ═══════════════════════════════════════════════════════════════════════════

func _resolve_palette() -> void:
	# B's working palette resolution: map the named palette from PatternSim.PALETTES
	# into actual Colors. This is the bit prototype A admitted it never wired up.
	var raw: Array = PatternSim.PALETTES.get(palette, PatternSim.PALETTES["bauhaus"])
	_palette.clear()
	for c in raw:
		_palette.append(Color(float(c[0]), float(c[1]), float(c[2])))
	# Guarantee at least two inks (index 0 = ground/empty).
	while _palette.size() < 2:
		_palette.append(Color(0.1, 0.1, 0.12))


func _seed_motif() -> void:
	# Deterministic starting motif from the seed — a fragment the player then edits.
	var n_colors: int = _palette.size()
	_grid = PatternSim.generate_motif(motif_size, n_colors, motif_seed, density)
	# generate_motif returns grid[y][x] indices already in 0..n_colors-1.

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — MACHINE BODY
# ═══════════════════════════════════════════════════════════════════════════

func _build_base_and_frame() -> void:
	var half := carpet_width * 0.5 + 0.22
	# Heavy base plinth.
	_box(Vector3(half * 2.0, 0.12, 1.4), Vector3(0, 0.06, -0.2), frame_color, 0.4, 0.6)
	# Four bolted feet.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(0.10, 0.07, Vector3(sx * (half - 0.12), 0.05, -0.2 + sz * 0.55), metal_color, 0.7, 0.4)
	# Two side gantry columns rising to the head.
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.10, HEAD_Y + 0.2, 0.12), Vector3(sx * half, (HEAD_Y + 0.2) * 0.5, -0.42), frame_color, 0.5, 0.5)
	# Top crossbeam carrying the head.
	_box(Vector3(half * 2.0 + 0.10, 0.10, 0.14), Vector3(0, HEAD_Y + 0.18, -0.42), frame_color, 0.5, 0.5)
	# Emissive accent rail along the crossbeam — "powered apparatus".
	_accent_mats.append(_emissive_box(Vector3(half * 2.0 - 0.1, 0.018, 0.018), Vector3(0, HEAD_Y + 0.10, -0.34), accent_color, 1.6))
	# Side service panel (reads as electrical panel).
	_box(Vector3(0.34, 0.5, 0.06), Vector3(-half, 0.55, 0.30), metal_color.darkened(0.2), 0.4, 0.6)
	for i in range(3):
		_accent_mats.append(_emissive_box(Vector3(0.05, 0.05, 0.02), Vector3(-half + (i - 1) * 0.09, 0.72, 0.34), accent_color, 1.2))
	# Central feed column connecting the core up to the head.
	_cyl(HEAD_Y - CORE_Y + 0.3, 0.09, Vector3(0, (CORE_Y + HEAD_Y) * 0.5, -0.42), metal_color, 0.6, 0.4)


func _build_core_and_rotors() -> void:
	# Everything in the rotor head lives under ONE container so the whole drum can
	# be replaced wholesale when the group (and thus the fold order) changes.
	var assembly := Node3D.new()
	assembly.name = "RotorAssembly"
	add_child(assembly)
	_rotor_assembly = assembly

	# Mill housing — a drum where the kaleidoscope rotors live.
	var housing := MeshInstance3D.new()
	var hcm := CylinderMesh.new()
	hcm.top_radius = 0.34; hcm.bottom_radius = 0.34
	hcm.height = 0.40; hcm.radial_segments = 20
	housing.mesh = hcm
	housing.material_override = _mat(frame_color.lightened(0.05), 0.5, 0.5)
	housing.position = Vector3(0, CORE_Y, -0.42)
	housing.rotation_degrees = Vector3(90, 0, 0)   # drum faces +Z toward the player
	assembly.add_child(housing)

	# Glowing inner core (the feedstock burns bright here).
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.13; sm.height = 0.26
	core.mesh = sm
	core.position = Vector3(0, CORE_Y, -0.42)
	_core_mat = StandardMaterial3D.new()
	_core_mat.albedo_color = core_color
	_core_mat.emission_enabled = true
	_core_mat.emission = core_color
	_core_mat.emission_energy_multiplier = 2.0
	core.material_override = _core_mat
	assembly.add_child(core)

	# Mirror-wedge ROTORS — the visible symmetry. The wedge count reflects the
	# rotational order of the current group (2 / 3 / 4 / 6 fold).
	var fold := _rotor_fold_for_group(_group_index)
	var wedge_mat := StandardMaterial3D.new()
	wedge_mat.albedo_color = Color(0.85, 0.88, 0.95)
	wedge_mat.metallic = 0.9
	wedge_mat.roughness = 0.12       # mirror-like
	wedge_mat.emission_enabled = true
	wedge_mat.emission = core_color
	wedge_mat.emission_energy_multiplier = 0.25

	# A pivot we spin; wedges radiate from the core front face toward the player.
	var pivot := Node3D.new()
	pivot.name = "RotorPivot"
	pivot.position = Vector3(0, CORE_Y, -0.18)
	assembly.add_child(pivot)
	_rotor_pivot = pivot

	for i in range(fold):
		var wedge := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.06, 0.30, 0.02)
		wedge.mesh = pm
		wedge.material_override = wedge_mat
		var ang := TAU * float(i) / float(fold)
		wedge.position = Vector3(sin(ang) * 0.14, cos(ang) * 0.14, 0.0)
		wedge.rotation = Vector3(PI * 0.5, 0.0, -ang)
		pivot.add_child(wedge)

	# A bright reflective ring framing the rotor.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.30; tm.outer_radius = 0.345
	tm.rings = 28; tm.ring_segments = 14
	ring.mesh = tm
	ring.position = Vector3(0, CORE_Y, -0.16)
	_rotor_ring_mat = _assign_emissive(ring, accent_color, 1.5, metal_color)
	_accent_mats.append(_rotor_ring_mat)
	assembly.add_child(ring)

	# Fold-order readout etched on the rotor (2/3/4/6).
	var fold_lbl := Label3D.new()
	fold_lbl.name = "FoldLabel"
	fold_lbl.text = "%d-FOLD" % fold
	fold_lbl.pixel_size = 0.0009
	fold_lbl.font_size = 12
	fold_lbl.modulate = core_color
	fold_lbl.position = Vector3(0, CORE_Y - 0.30, -0.12)
	assembly.add_child(fold_lbl)


func _build_warp_cage() -> void:
	# Glowing warp threads across the front of the head — the loom vocabulary,
	# reading the fed motif into the mill.
	var count := 13
	var span := carpet_width * 0.8
	var base_x := -span * 0.5
	for i in range(count):
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004; cm.bottom_radius = 0.004
		cm.height = 0.55; cm.radial_segments = 6
		t.mesh = cm
		var x := base_x + span * float(i) / float(maxi(1, count - 1))
		t.position = Vector3(x, CORE_Y + 0.02, -0.30)
		var m := StandardMaterial3D.new()
		m.albedo_color = core_color
		m.emission_enabled = true
		m.emission = core_color
		m.emission_energy_multiplier = 0.9
		t.material_override = m
		_warp_mats.append(m)
		add_child(t)

	# Weave bar across the warp line.
	var bar := MeshInstance3D.new()
	var bcm := CylinderMesh.new()
	bcm.top_radius = 0.022; bcm.bottom_radius = 0.022
	bcm.height = span + 0.12; bcm.radial_segments = 12
	bar.mesh = bcm
	bar.rotation_degrees = Vector3(0, 0, 90)
	bar.position = Vector3(0, CORE_Y + 0.30, -0.28)
	_accent_mats.append(_assign_emissive(bar, accent_color, 2.0, accent_color))
	add_child(bar)

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — INTERACTIVE HEAD GRID (touch-paint)
# ═══════════════════════════════════════════════════════════════════════════

func _build_head_grid() -> void:
	# The head is an upright tray on the machine head facing the player (+Z).
	_head_root = Node3D.new()
	_head_root.name = "Head"
	_head_root.position = Vector3(0, HEAD_Y, HEAD_Z)
	add_child(_head_root)

	var total := motif_size * HEAD_CELL
	var start := -total * 0.5

	# Backing plate.
	var plate := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(total + 0.05, total + 0.05, 0.03)
	plate.mesh = bm
	plate.material_override = _mat(Color(0.16, 0.17, 0.20), 0.4, 0.6)
	plate.position = Vector3(0, 0, -0.02)
	_head_root.add_child(plate)

	# Bezel frame (4 bars).
	var fw := 0.014
	var bz := _mat(frame_color, 0.5, 0.5)
	var half := (total + 0.05) * 0.5
	for d in [
		[Vector3(total + 0.05 + fw, fw, 0.04), Vector3(0, half, 0.0)],
		[Vector3(total + 0.05 + fw, fw, 0.04), Vector3(0, -half, 0.0)],
		[Vector3(fw, total + 0.05, 0.04), Vector3(-half, 0, 0.0)],
		[Vector3(fw, total + 0.05, 0.04), Vector3(half, 0, 0.0)],
	]:
		var b := MeshInstance3D.new()
		var bbm := BoxMesh.new(); bbm.size = d[0]
		b.mesh = bbm; b.material_override = bz
		b.position = d[1]
		_head_root.add_child(b)

	# Editable cells.
	_cell_mats.clear()
	for y in motif_size:
		var row_mat: Array = []
		for x in motif_size:
			var cell := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(HEAD_CELL * 0.9, HEAD_CELL * 0.9)
			cell.mesh = qm
			var ci: int = _grid[y][x]
			var cm := StandardMaterial3D.new()
			cm.albedo_color = _color_for(ci)
			cm.roughness = 0.8
			if ci != 0:
				cm.emission_enabled = true
				cm.emission = _color_for(ci)
				cm.emission_energy_multiplier = 0.25
			cell.material_override = cm
			cell.position = Vector3(
				start + x * HEAD_CELL + HEAD_CELL * 0.5,
				start + (motif_size - 1 - y) * HEAD_CELL + HEAD_CELL * 0.5,
				0.01)
			_head_root.add_child(cell)
			row_mat.append(cm)
		_cell_mats.append(row_mat)

	# Grid lines.
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.5, 0.52, 0.55, 0.8)
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in motif_size + 1:
		var vl := MeshInstance3D.new()
		var vm := BoxMesh.new(); vm.size = Vector3(0.0015, total, 0.0015)
		vl.mesh = vm; vl.material_override = line_mat
		vl.position = Vector3(start + i * HEAD_CELL, 0, 0.012)
		_head_root.add_child(vl)
		var hl := MeshInstance3D.new()
		var hm := BoxMesh.new(); hm.size = Vector3(total, 0.0015, 0.0015)
		hl.mesh = hm; hl.material_override = line_mat
		hl.position = Vector3(0, start + i * HEAD_CELL, 0.012)
		_head_root.add_child(hl)


func _build_touch_area() -> void:
	# Touch volume over the head grid (paints cells under the player's hand).
	_touch_area = Area3D.new()
	_touch_area.name = "TouchArea"
	_touch_area.collision_layer = 1048576   # bit 20 (interactive)
	_touch_area.collision_mask = 393216     # bits 18+19 (hands + pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false
	var total := motif_size * HEAD_CELL
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(total + 0.02, total + 0.02, 0.12)
	col.shape = shape
	col.position = Vector3(0, 0, 0.02)
	_touch_area.add_child(col)
	_head_root.add_child(_touch_area)

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — CONTROLS
# ═══════════════════════════════════════════════════════════════════════════

func _build_palette_row() -> void:
	# Ink selectors along the left gantry column, facing the player.
	var half := carpet_width * 0.5 + 0.22
	var col_x := -half
	var base_y := 0.45
	var spacing := 0.085
	_ink_indicators.clear()
	for i in _palette.size():
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "InkBtn_%d" % i
		btn.position = Vector3(col_x, base_y + i * spacing, 0.10)
		btn.scale = Vector3(0.45, 0.45, 0.45)
		btn.set("pressed_color", _palette[i])
		btn.set("released_color", _palette[i].darkened(0.35))
		add_child(btn)
		var idx := i
		_connect_btn(btn, func(): _select_ink(idx))
		# Glow indicator dot next to the button.
		var dot := MeshInstance3D.new()
		var dm := SphereMesh.new(); dm.radius = 0.009; dm.height = 0.018
		dot.mesh = dm
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = _palette[i]
		dmat.emission_enabled = true
		dmat.emission = _palette[i]
		dmat.emission_energy_multiplier = 2.5 if i == _ink else 0.0
		dot.material_override = dmat
		dot.position = Vector3(col_x + 0.07, base_y + i * spacing, 0.10)
		add_child(dot)
		_ink_indicators.append(dot)

	var lbl := Label3D.new()
	lbl.text = "INK"
	lbl.pixel_size = 0.0009
	lbl.font_size = 10
	lbl.modulate = accent_color
	lbl.position = Vector3(col_x, base_y - 0.08, 0.10)
	add_child(lbl)


func _build_control_row() -> void:
	# Control buttons along the right gantry column.
	var half := carpet_width * 0.5 + 0.22
	var col_x := half
	var by := 0.95

	var group_btn := PUSH_BUTTON.instantiate()
	group_btn.name = "GroupCycle"
	group_btn.position = Vector3(col_x, by, 0.10)
	group_btn.scale = Vector3(0.55, 0.55, 0.55)
	group_btn.set("pressed_color", accent_color)
	group_btn.set("released_color", accent_color.darkened(0.5))
	add_child(group_btn)
	_connect_btn(group_btn, _cycle_group)
	_add_btn_label(group_btn, "GROUP")

	var seed_btn := PUSH_BUTTON.instantiate()
	seed_btn.name = "Seed"
	seed_btn.position = Vector3(col_x, by - 0.16, 0.10)
	seed_btn.scale = Vector3(0.45, 0.45, 0.45)
	seed_btn.set("pressed_color", Color(0.4, 0.8, 0.4))
	seed_btn.set("released_color", frame_color)
	add_child(seed_btn)
	_connect_btn(seed_btn, _reseed_motif)
	_add_btn_label(seed_btn, "SEED")

	var clear_btn := PUSH_BUTTON.instantiate()
	clear_btn.name = "Clear"
	clear_btn.position = Vector3(col_x, by - 0.30, 0.10)
	clear_btn.scale = Vector3(0.45, 0.45, 0.45)
	clear_btn.set("pressed_color", Color(0.85, 0.2, 0.2))
	clear_btn.set("released_color", frame_color)
	add_child(clear_btn)
	_connect_btn(clear_btn, _clear_head)
	_add_btn_label(clear_btn, "CLEAR")

	var press_btn := PUSH_BUTTON.instantiate()
	press_btn.name = "Press"
	press_btn.position = Vector3(col_x, by - 0.44, 0.10)
	press_btn.scale = Vector3(0.6, 0.6, 0.6)
	press_btn.set("pressed_color", Color(0.2, 0.9, 0.4))
	press_btn.set("released_color", Color(0.12, 0.40, 0.20))
	add_child(press_btn)
	_connect_btn(press_btn, _pull_press)
	_add_btn_label(press_btn, "PRESS")


func _build_press_head_and_lever() -> void:
	# Press head slides on guide rods directly above the editable head grid.
	# (D's tactile operate-stroke.)
	var span: float = motif_size * HEAD_CELL
	_press_head = Node3D.new()
	_press_head.name = "PressHead"
	_press_head.position = Vector3(0, HEAD_Y + 0.42, HEAD_Z + 0.04)
	add_child(_press_head)

	var head := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(span + 0.14, 0.10, 0.20)
	head.mesh = hb
	head.material_override = _mat(frame_color.lightened(0.12), 0.55, 0.4)
	_press_head.add_child(head)
	# Glowing punch face underneath the head.
	var face := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(span + 0.04, 0.02, 0.14)
	face.mesh = fb
	var fm := _mat(accent_color, 0.2, 0.5)
	fm.emission_enabled = true
	fm.emission = accent_color
	fm.emission_energy_multiplier = 1.5
	face.material_override = fm
	face.position = Vector3(0, -0.06, 0)
	_press_head.add_child(face)
	_accent_mats.append(fm)

	# Two guide rods from the crossbeam down past the head.
	for sx in [-1.0, 1.0]:
		var rod := _cyl(0.95, 0.018, Vector3(sx * (span * 0.5 + 0.06), HEAD_Y + 0.18, HEAD_Z + 0.04),
			Color(0.55, 0.55, 0.60), 0.7, 0.3)
		rod.rotation_degrees = Vector3(0, 0, 0)

	# Pull lever on the right — pivots, reads as the "operate" handle.
	var half := carpet_width * 0.5 + 0.22
	_lever = Node3D.new()
	_lever.name = "Lever"
	_lever.position = Vector3(half - 0.06, HEAD_Y - 0.05, 0.05)
	add_child(_lever)
	var arm := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.02; am.bottom_radius = 0.02; am.height = 0.40
	arm.mesh = am
	arm.material_override = _mat(Color(0.5, 0.5, 0.55), 0.7, 0.3)
	arm.position = Vector3(0.0, 0.18, 0.10)
	arm.rotation_degrees = Vector3(-30, 0, 0)
	_lever.add_child(arm)
	var knob := MeshInstance3D.new()
	var km := SphereMesh.new(); km.radius = 0.05; km.height = 0.10
	knob.mesh = km
	var kmat := _mat(accent_color, 0.2, 0.4)
	kmat.emission_enabled = true; kmat.emission = accent_color
	kmat.emission_energy_multiplier = 1.6
	knob.material_override = kmat
	knob.position = Vector3(0.0, 0.34, 0.20)
	_lever.add_child(knob)
	_accent_mats.append(kmat)


func _build_output_chute() -> void:
	# A slanted chute the carpet rolls out of, from the head down to the floor in
	# front of the machine. Visually connects mill -> carpet.
	var chute := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, 0.7)
	chute.mesh = pm
	chute.rotation_degrees = Vector3(-58, 0, 0)
	chute.position = Vector3(0, 0.55, 0.30)
	_chute_mat = StandardMaterial3D.new()
	_chute_mat.albedo_color = metal_color.darkened(0.1)
	_chute_mat.metallic = 0.6
	_chute_mat.roughness = 0.35
	_chute_mat.emission_enabled = true
	_chute_mat.emission = accent_color
	_chute_mat.emission_energy_multiplier = 0.15
	chute.material_override = _chute_mat
	add_child(chute)

	# Chute side rails.
	for sx in [-1.0, 1.0]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new(); rm.size = Vector3(0.03, 0.78, 0.03)
		rail.mesh = rm
		rail.rotation_degrees = Vector3(-58, 0, 0)
		rail.position = Vector3(sx * carpet_width * 0.5, 0.55, 0.30)
		_accent_mats.append(_assign_emissive(rail, accent_color, 1.2, metal_color))
		add_child(rail)

	# Output roller at the chute lip where the carpet meets the floor.
	var roller := _cyl(carpet_width + 0.16, 0.05, Vector3(0, 0.05, 0.62), metal_color.lightened(0.1), 0.7, 0.3)
	roller.rotation_degrees = Vector3(0, 0, 90)

	# Output tray rails running forward along the carpet (conveyor vocabulary).
	for sx in [-1.0, 1.0]:
		var trail := _box(Vector3(0.03, 0.06, carpet_length), Vector3(
			sx * (carpet_width * 0.5 + 0.05), 0.05, 0.62 + carpet_length * 0.5),
			frame_color, 0.4, 0.5)
		var em := _mat(accent_color, 0.2, 0.5)
		em.emission_enabled = true; em.emission = accent_color
		em.emission_energy_multiplier = 1.0
		trail.material_override = em
		_accent_mats.append(em)

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — OUTPUT (carpet + proof sheet from ONE reusable texture)
# ═══════════════════════════════════════════════════════════════════════════

func _build_carpet() -> void:
	var carpet := MeshInstance3D.new()
	carpet.name = "MilledCarpet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	# Lies flat, in front of the machine where the chute feeds it out.
	carpet.position = Vector3(0, 0.01, 0.62 + carpet_length * 0.5)
	_carpet_mat = StandardMaterial3D.new()
	_carpet_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # crisp tiles
	_carpet_mat.roughness = 0.9
	_carpet_mat.metallic = 0.0
	# uv1_scale.y > 1 so the carpet shows several courses along its length.
	_carpet_mat.uv1_scale = Vector3(1.0, carpet_length / carpet_width, 1.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


func _build_proof_sheet() -> void:
	# B's dual output: a short vertical "proof sheet" rising from the head, fed by
	# the SAME texture as the carpet. Lit from within so it reads as freshly milled.
	var sheet := MeshInstance3D.new()
	sheet.name = "ProofSheet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width * 0.7, sheet_height)
	pm.orientation = PlaneMesh.FACE_Z
	sheet.mesh = pm
	sheet.position = Vector3(0, CORE_Y + 0.55 + sheet_height * 0.5, -0.26)
	_sheet_mat = StandardMaterial3D.new()
	_sheet_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sheet_mat.roughness = 0.8
	_sheet_mat.metallic = 0.0
	_sheet_mat.uv1_scale = Vector3(1.0, sheet_height / (carpet_width * 0.7), 1.0)
	sheet.material_override = _sheet_mat
	add_child(sheet)


func _build_labels() -> void:
	var title := Label3D.new()
	title.text = "PATTERN MILL"
	title.pixel_size = 0.0011
	title.font_size = 24
	title.modulate = accent_color
	title.position = Vector3(0, HEAD_Y + 0.30, -0.20)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(title)

	var half := carpet_width * 0.5 + 0.22
	_group_label = Label3D.new()
	_group_label.text = GROUP_NAMES[_group_index].to_upper()
	_group_label.pixel_size = 0.0012
	_group_label.font_size = 20
	_group_label.modulate = core_color
	_group_label.position = Vector3(half, 1.12, 0.12)
	add_child(_group_label)


func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 60.0
	cam.position = Vector3(2.2, 2.0, 3.2)
	cam.rotation_degrees = Vector3(-26, 30, 0)
	add_child(cam)

# ═══════════════════════════════════════════════════════════════════════════
# INTERACTIONS
# ═══════════════════════════════════════════════════════════════════════════

func _select_ink(idx: int) -> void:
	_ink = clampi(idx, 0, _palette.size() - 1)
	for i in _ink_indicators.size():
		var m: StandardMaterial3D = _ink_indicators[i].material_override
		m.emission_energy_multiplier = 2.5 if i == _ink else 0.0
	print("[PatternMill] ink -> %d" % _ink)


func _cycle_group() -> void:
	_group_index = (_group_index + 1) % GROUP_NAMES.size()
	group = GROUP_NAMES[_group_index]
	_current_group = _index_to_enum(_group_index)
	if _group_label:
		_group_label.text = group.to_upper()
	# Rebuild the rotors so the mirror count matches the new group's fold order.
	_rebuild_rotors()
	_rebake_output()
	print("[PatternMill] group -> %s (%d-fold)" % [group, _rotor_fold_for_group(_group_index)])


func _reseed_motif() -> void:
	motif_seed = (motif_seed * 1103515245 + 12345) & 0x7fffffff
	var n := _palette.size()
	var motif: Array = PatternSim.generate_dot_motif(motif_size, n, motif_seed, 0.4)
	for y in motif_size:
		for x in motif_size:
			_grid[y][x] = clampi(int(motif[y][x]), 0, n - 1)
	_refresh_head_visuals()
	_rebake_output()
	print("[PatternMill] reseeded motif (seed=%d)" % motif_seed)


func _clear_head() -> void:
	for y in motif_size:
		for x in motif_size:
			_grid[y][x] = 0
	_refresh_head_visuals()
	_rebake_output()


func _pull_press() -> void:
	# Kick off the press stroke; carpet re-stamps at the bottom of the punch.
	_press_anim = 0.0
	_stamped_this_stroke = false


func _paint_cell(gx: int, gy: int) -> void:
	if gx < 0 or gx >= motif_size or gy < 0 or gy >= motif_size:
		return
	if _grid[gy][gx] == _ink:
		return
	_grid[gy][gx] = _ink
	_apply_cell_visual(gx, gy)
	_rebake_output()


func _check_touch_paint() -> void:
	if _touch_area == null or _head_root == null:
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_cell = Vector2i(-1, -1)
		return
	var total := motif_size * HEAD_CELL
	var start := -total * 0.5
	for body in bodies:
		var local_pos := _head_root.to_local(body.global_position)
		var gx := int((local_pos.x - start) / HEAD_CELL)
		var gy := motif_size - 1 - int((local_pos.y - start) / HEAD_CELL)
		if gx >= 0 and gx < motif_size and gy >= 0 and gy < motif_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_cell:
				_last_cell = cell
				_paint_cell(gx, gy)
			return


func _apply_cell_visual(gx: int, gy: int) -> void:
	var ci: int = _grid[gy][gx]
	var m: StandardMaterial3D = _cell_mats[gy][gx]
	m.albedo_color = _color_for(ci)
	m.emission_enabled = ci != 0
	if ci != 0:
		m.emission = _color_for(ci)
		m.emission_energy_multiplier = 0.25
	else:
		m.emission_energy_multiplier = 0.0


func _refresh_head_visuals() -> void:
	for y in motif_size:
		for x in motif_size:
			_apply_cell_visual(x, y)

# ═══════════════════════════════════════════════════════════════════════════
# OUTPUT — symmetrise the fragment, bake ONE texture, feed carpet + proof sheet
# ═══════════════════════════════════════════════════════════════════════════

func _rebake_output() -> void:
	# CPU-tile the head grid through the active wallpaper group into ONE texture.
	# Same engine call as pattern_maker_station / loom / press, driven by the live
	# painted grid. Texture is created once then updated in place (B's pattern).
	var tex_size: int = carpet_repeats * motif_size
	if tex_size <= 0:
		return
	var n_colors: int = _palette.size()
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	for py in tex_size:
		for px in tex_size:
			var ci: int = WallpaperGroupsScript.get_symmetric_color(
				px, py, motif_size, _grid, _current_group)
			ci = clampi(ci, 0, n_colors - 1)
			img.set_pixel(px, py, _palette[ci])
	if _output_tex:
		_output_tex.update(img)
	else:
		_output_tex = ImageTexture.create_from_image(img)
		if _carpet_mat:
			_carpet_mat.albedo_texture = _output_tex
		if _sheet_mat:
			_sheet_mat.albedo_texture = _output_tex
			_sheet_mat.emission_enabled = true
			_sheet_mat.emission = Color(1, 1, 1)
			_sheet_mat.emission_texture = _output_tex
			_sheet_mat.emission_energy_multiplier = 0.25

# ═══════════════════════════════════════════════════════════════════════════
# PRESS STROKE (discrete operate — D's lever/head punch)
# ═══════════════════════════════════════════════════════════════════════════

func _animate_press(delta: float) -> void:
	if _press_anim < 0.0:
		return
	_press_anim += delta * 2.2     # ~0.45s full stroke
	var p: float = _press_anim
	var down: float = sin(clampf(p, 0.0, 1.0) * PI)   # 0 -> 1 -> 0
	if is_instance_valid(_press_head):
		_press_head.position.y = HEAD_Y + 0.42 - 0.38 * down
	if is_instance_valid(_lever):
		_lever.rotation_degrees.z = -45.0 * down
	if p >= 0.5 and not _stamped_this_stroke:
		# At the bottom of the stroke: re-stamp once. (Output already updates live;
		# the stroke makes the production read explicit and tactile.)
		_stamped_this_stroke = true
		_rebake_output()
	if p >= 1.0:
		_press_anim = -1.0
		if is_instance_valid(_press_head):
			_press_head.position.y = HEAD_Y + 0.42
		if is_instance_valid(_lever):
			_lever.rotation_degrees.z = 0.0

# ═══════════════════════════════════════════════════════════════════════════
# ROTOR REBUILD (mirror count tracks the group's rotational order)
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild_rotors() -> void:
	# REBUILD DISCIPLINE: free the whole previous drum (housing, core, pivot, ring,
	# fold label) in ONE shot, then rebuild so the mirror-wedge count matches the new
	# group's fold order. Erase any animated material that belonged to the dead drum
	# from the arrays so _process() never pokes a freed node.
	if is_instance_valid(_rotor_assembly):
		if _rotor_ring_mat:
			_accent_mats.erase(_rotor_ring_mat)   # ring accent lived under the drum
		_rotor_assembly.queue_free()
	_rotor_assembly = null
	_rotor_ring_mat = null
	_rotor_pivot = null
	_core_mat = null            # core glow lived under the drum too
	_build_core_and_rotors()


func _rotor_fold_for_group(gi: int) -> int:
	# Rotational order implied by the group name (visible mirror count).
	var gname: String = GROUP_NAMES[gi]
	if gname.begins_with("p6"):
		return 6
	if gname.begins_with("p4"):
		return 4
	if gname.begins_with("p3") or gname.begins_with("p31"):
		return 3
	if gname == "p2" or gname == "pmm" or gname == "pmg" or gname == "pgg" or gname == "cmm":
		return 2
	return 2   # p1/pm/pg/cm — minimal 2-blade rotor

# ═══════════════════════════════════════════════════════════════════════════
# GROUP / COLOR HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _name_to_index(n: String) -> int:
	var idx := GROUP_NAMES.find(n.to_lower())
	return idx if idx >= 0 else 10   # default p4m


func _index_to_enum(gi: int) -> int:
	return PatternSim.group_enum(GROUP_NAMES[gi])


func _color_for(ci: int) -> Color:
	if ci >= 0 and ci < _palette.size():
		return _palette[ci]
	return _palette[0] if _palette.size() > 0 else Color(0.9, 0.9, 0.9)

# ═══════════════════════════════════════════════════════════════════════════
# PRIMITIVE BUILDERS
# ═══════════════════════════════════════════════════════════════════════════

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


func _box(size: Vector3, pos: Vector3, color: Color, metallic: float = 0.35, roughness: float = 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	mi.material_override = _mat(color, metallic, roughness)
	add_child(mi)
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color, metallic: float = 0.6, roughness: float = 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius
	cm.height = height; cm.radial_segments = 20
	mi.mesh = cm; mi.position = pos
	mi.material_override = _mat(color, metallic, roughness)
	add_child(mi)
	return mi


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> StandardMaterial3D:
	var mi := _box(size, pos, color, 0.4, 0.5)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


func _assign_emissive(mi: MeshInstance3D, emit: Color, energy: float, albedo: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = 0.6
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = emit
	m.emission_energy_multiplier = energy
	mi.material_override = m
	return m


func _connect_btn(btn: Node, callback: Callable) -> void:
	# push_button's inner InteractableAreaButton emits button_pressed(button).
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.connect("button_pressed", func(_b): callback.call())
	elif btn.has_signal("pressed"):
		btn.connect("pressed", callback)


func _add_btn_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0013
	lbl.font_size = 9
	lbl.modulate = Color(0.85, 0.85, 0.88)
	lbl.position = Vector3(0, 0, 0.06)
	btn.add_child(lbl)

# ═══════════════════════════════════════════════════════════════════════════
# EXHIBIT — what the mill puts on show of a closed set
# ═══════════════════════════════════════════════════════════════════════════
# Appended LAST in _ready(), after the output has been baked, so every child index and
# every position above it is untouched on the legacy path. "bolt" falls through and adds
# nothing at all.
#
# Everything below is placed INSIDE the extents the mill already occupies — the gantry
# columns reach x = ±(carpet_width/2 + 0.22) and the carpet ends at z = 0.62 + carpet_length,
# and no value crosses either. That is deliberate: a capture is framed on the bounding box,
# so a value that grew the box would reframe the shot and the reframing would be measured
# as evidence. All four values share one box and differ only in what stands inside it.

func _build_exhibit() -> void:
	match exhibit:
		"unit":
			_exhibit_unit()
		"operation":
			_exhibit_operation()
		"catalogue":
			_exhibit_catalogue()
		_:
			pass                                  # "bolt" — the legacy lineage


## UNIT — the run admits it is one tile. The domain lattice is scored across the carpet, one
## domain is lifted bodily out of the field onto a pedestal (leaving a dark hole where it
## came from), and a sample plate stands that same domain up beside the run. No new pattern
## is drawn: every mark points at the fact that the mill made one fragment and fed out
## translations of it.
func _exhibit_unit() -> void:
	var x0: float = -carpet_width * 0.5
	var z0: float = 0.62
	var reps_x: int = maxi(carpet_repeats, 1)
	var step: float = carpet_width / float(reps_x)
	var reps_z: int = maxi(1, int(round(carpet_length / maxf(step, 0.001))))
	var bar: float = maxf(step * 0.16, 0.022)

	# The lattice — a bar on every domain boundary, both directions. The outermost bars are
	# tucked half their own width inboard so the run's bounding box is exactly the box "bolt"
	# already had, and the sweep is not handed a reframing to measure.
	for i in range(reps_x + 1):
		_emissive_box(Vector3(bar, 0.008, carpet_length),
			Vector3(clampf(x0 + float(i) * step, x0 + bar * 0.5, -x0 - bar * 0.5),
				0.024, z0 + carpet_length * 0.5), core_color, 1.5)
	for j in range(reps_z + 1):
		_emissive_box(Vector3(carpet_width, 0.008, bar),
			Vector3(0.0, 0.024, clampf(z0 + float(j) * step,
				z0 + bar * 0.5, z0 + carpet_length - bar * 0.5)), core_color, 1.5)

	# One domain lifted out of the field, and the hole it left behind.
	var ci: int = reps_x / 2
	var ri: int = maxi(reps_z / 3, 1)
	var cx: float = x0 + (float(ci) + 0.5) * step
	var cz: float = z0 + (float(ri) + 0.5) * step
	var post: float = maxf(step * 0.34, 0.05)
	_box(Vector3(step - bar, 0.012, step - bar), Vector3(cx, 0.018, cz), Color(0.04, 0.04, 0.05), 0.0, 0.95)
	_box(Vector3(post, 0.26, post), Vector3(cx, 0.13, cz), frame_color, 0.4, 0.6)
	_emissive_box(Vector3(step + 0.03, 0.018, step + 0.03), Vector3(cx, 0.26, cz), accent_color, 2.2)
	var tile: MeshInstance3D = _domain_quad(Vector2(step, step), reps_x, ci, ri)
	tile.position = Vector3(cx, 0.275, cz)
	tile.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	add_child(tile)

	# The sample plate — the same single domain, stood up beside the run so it can be read
	# against the cloth it was taken from.
	var px: float = x0 + step * 1.4
	var pz: float = z0 + carpet_length * 0.30
	var sw: float = minf(0.35, carpet_width * 0.28)
	_box(Vector3(sw * 0.75, 0.03, 0.20), Vector3(px, 0.02, pz), frame_color, 0.4, 0.6)
	_box(Vector3(0.05, 0.72, 0.05), Vector3(px, 0.36, pz), metal_color, 0.6, 0.4)
	_emissive_box(Vector3(sw + 0.05, sw + 0.05, 0.010), Vector3(px, 0.90, pz - 0.014), accent_color, 1.6)
	var sample: MeshInstance3D = _domain_quad(Vector2(sw, sw), reps_x, ci, ri)
	sample.position = Vector3(px, 0.90, pz)
	add_child(sample)


## OPERATION — the cloth admits it is a group acting. Mirror axes as unbroken bars for any
## group whose name carries an "m", glide axes as broken runs for any "g", and a
## rotation-centre marker standing proud at the lattice nodes whose sides count the fold
## order — the same number _rotor_fold_for_group hands the mirror wedges upstairs.
##
## This is the machine's own schematic and not a crystallographic plate: the axes are drawn
## on the domain boundaries rather than at their true offsets, exactly as the rotor reads its
## fold off the group NAME rather than off the group. Sharpening one and not the other would
## make the body contradict itself.
func _exhibit_operation() -> void:
	var x0: float = -carpet_width * 0.5
	var z0: float = 0.62
	var reps_x: int = maxi(carpet_repeats, 1)
	var step: float = carpet_width / float(reps_x)
	var reps_z: int = maxi(1, int(round(carpet_length / maxf(step, 0.001))))
	var gname: String = str(GROUP_NAMES[_group_index])
	var fold: int = _rotor_fold_for_group(_group_index)
	var has_mirror: bool = gname.find("m") >= 0
	var has_glide: bool = gname.find("g") >= 0
	var bar: float = maxf(step * 0.14, 0.022)

	# Mirror axes — unbroken, because a reflection holds everywhere along its line.
	if has_mirror:
		for i in range(reps_x + 1):
			_emissive_box(Vector3(bar, 0.008, carpet_length),
				Vector3(clampf(x0 + float(i) * step, x0 + bar * 0.5, -x0 - bar * 0.5),
					0.024, z0 + carpet_length * 0.5), accent_color, 2.0)
		for j in range(reps_z + 1):
			_emissive_box(Vector3(carpet_width, 0.008, bar),
				Vector3(0.0, 0.024, clampf(z0 + float(j) * step,
					z0 + bar * 0.5, z0 + carpet_length - bar * 0.5)), accent_color, 2.0)

	# Glide axes — broken, because a glide is a reflection you have to walk into.
	if has_glide:
		var dash: float = step * 0.42
		for i in range(reps_x):
			var t: float = (float(i) + 0.5) * step
			for j in range(reps_z):
				var u: float = (float(j) + 0.25) * step
				_emissive_box(Vector3(bar * 0.8, 0.008, dash),
					Vector3(x0 + t, 0.024, z0 + u), core_color, 1.8)

	# Rotation centres — thinned out so a marker on every node of a 16 cm domain does not
	# close up into a solid sheet.
	var stride: int = 1
	if step < 0.24:
		stride = 2
	if step < 0.09:
		stride = 3
	var mr: float = maxf(step * 0.20, 0.030)
	# A pure-rotation group — p1, p2, p3, p4, p6, and mill_persian_p4 is one of them — has no
	# axes to draw at all, so the rotation centres ARE the whole argument. Set them denser and
	# larger there rather than shipping those groups a run with almost nothing on it.
	if not has_mirror and not has_glide:
		stride = maxi(1, stride / 2)
		mr *= 1.5
	var i2: int = 0
	while i2 <= reps_x:
		var j2: int = 0
		while j2 <= reps_z:
			# Clamped inboard for the same reason as the lattice: a marker centred on the
			# outer node would hang over the carpet edge and widen the bounding box.
			var mx: float = clampf(x0 + float(i2) * step, x0 + mr, -x0 - mr)
			var mz: float = clampf(z0 + float(j2) * step, z0 + mr, z0 + carpet_length - mr)
			_rotation_marker(Vector3(mx, 0.048, mz), fold, mr)
			j2 += stride
		i2 += stride


## CATALOGUE — the mill stops pretending. A two-tier index board stands at the end of the run
## carrying all SEVENTEEN plane groups, each swatch milled from this same hopper so the
## seventeen are genuinely comparable rather than decorative, the one currently in the
## machine lit and the other sixteen dark. Nothing on this run was invented: entry k of a
## closed set was selected, and the board says which k and what the sixteen alternatives were.
func _exhibit_catalogue() -> void:
	var n: int = GROUP_NAMES.size()
	var z: float = 0.62 + carpet_length * 0.94
	var top_n: int = n / 2                        # 8 on the upper tier, 9 on the lower
	var bot_n: int = n - top_n
	# Derived from the gantry's own half-width, not a constant, so the board can never grow
	# wider than the machine and reframe the capture on a mill built at another carpet_width.
	var edge: float = carpet_width * 0.5 + 0.20
	var pitch: float = (edge * 2.0 - 0.14) / float(maxi(bot_n - 1, 1))
	var plate: float = pitch * 0.80

	# Frame — an open border rather than a solid panel, so the board never hides its own
	# swatches from whichever side the camera happens to stand on.
	_box(Vector3(edge * 2.0, 0.035, 0.035), Vector3(0.0, 1.13, z), frame_color, 0.4, 0.6)
	_box(Vector3(edge * 2.0, 0.035, 0.035), Vector3(0.0, 0.60, z), frame_color, 0.4, 0.6)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.035, 0.53, 0.035), Vector3(sx * edge, 0.865, z), frame_color, 0.4, 0.6)
		_box(Vector3(0.05, 0.60, 0.05), Vector3(sx * (edge - 0.07), 0.30, z), frame_color, 0.4, 0.6)

	for i in range(n):
		var row: int = 0 if i < bot_n else 1
		var col: int = i if row == 0 else i - bot_n
		var count: int = bot_n if row == 0 else top_n
		var px: float = (float(col) - (float(count) - 1.0) * 0.5) * pitch
		var py: float = 0.76 if row == 0 else 1.02
		_catalogue_plate(i, Vector3(px, py, z), plate)


## One entry on the index board: the hopper milled through group `gi`, on a double-sided
## plate so the board reads from either side of the line, with a bright rim and a brighter
## emission if this is the group the machine is actually running.
func _catalogue_plate(gi: int, pos: Vector3, plate: float) -> void:
	var lit: bool = gi == _group_index
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(plate, plate)
	pm.orientation = PlaneMesh.FACE_Z
	mi.mesh = pm
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.8
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tex: ImageTexture = _group_swatch_texture(gi)
	m.albedo_texture = tex
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_texture = tex
	m.emission_energy_multiplier = 1.6 if lit else 0.18
	mi.material_override = m
	add_child(mi)

	if lit:
		var h: float = plate * 0.5 + 0.018
		_emissive_box(Vector3(plate + 0.05, 0.026, 0.03), pos + Vector3(0.0, h, 0.0), core_color, 3.2)
		_emissive_box(Vector3(plate + 0.05, 0.026, 0.03), pos + Vector3(0.0, -h, 0.0), core_color, 3.2)
		_emissive_box(Vector3(0.026, plate + 0.05, 0.03), pos + Vector3(h, 0.0, 0.0), core_color, 3.2)
		_emissive_box(Vector3(0.026, plate + 0.05, 0.03), pos + Vector3(-h, 0.0, 0.0), core_color, 3.2)

	var lbl := Label3D.new()
	lbl.text = str(GROUP_NAMES[gi]).to_upper()
	lbl.font_size = 22
	lbl.pixel_size = 0.0021
	lbl.modulate = core_color if lit else Color(0.60, 0.62, 0.68)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = pos + Vector3(0.0, -plate * 0.5 - 0.038, 0.012)
	add_child(lbl)


## A double-sided quad carrying exactly ONE domain of the milled output — the fragment the
## mill actually made. uv1_scale crops the live texture down to a single repeat and
## uv1_offset picks which one, so the plate is guaranteed to be the same cloth rather than a
## redrawing of it. Returned unparented; the caller places it.
func _domain_quad(size: Vector2, reps: int, ci: int, ri: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.orientation = PlaneMesh.FACE_Z
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.85
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var f: float = 1.0 / float(maxi(reps, 1))
	m.uv1_scale = Vector3(f, f, 1.0)
	m.uv1_offset = Vector3(float(ci) * f, float(ri % maxi(reps, 1)) * f, 0.0)
	if _output_tex:
		m.albedo_texture = _output_tex
		m.emission_enabled = true
		m.emission = Color(1, 1, 1)
		m.emission_texture = _output_tex
		m.emission_energy_multiplier = 0.35
	else:
		m.albedo_color = _color_for(1)
	mi.material_override = m
	return mi


## A crystallographic rotation-centre marker standing a few cm proud of the run: a lens for a
## 2-fold, a triangle for 3, a square for 4, a hexagon for 6. Proud rather than painted so
## the field of them survives the shallow angle a floor is photographed at.
func _rotation_marker(pos: Vector3, fold: int, r: float) -> void:
	if fold <= 2:
		var lens: MeshInstance3D = _box(Vector3(r * 1.9, r * 0.55, r * 0.55), pos, core_color, 0.3, 0.4)
		var lm: StandardMaterial3D = lens.material_override
		lm.emission_enabled = true
		lm.emission = core_color
		lm.emission_energy_multiplier = 2.4
		return
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = r * 0.55
	cm.radial_segments = fold
	mi.mesh = cm
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = core_color
	m.metallic = 0.3
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = core_color
	m.emission_energy_multiplier = 2.4
	mi.material_override = m
	add_child(mi)


## Mill the CURRENT head grid through group `gi` into a small swatch texture. The catalogue
## uses this seventeen times, so every plate on the board is the same fragment under a
## different program — which is the whole claim, and would be a lie if the swatches were
## seventeen unrelated decorations.
func _group_swatch_texture(gi: int) -> ImageTexture:
	var reps: int = clampi(carpet_repeats, 2, 4)
	var n: int = maxi(motif_size, 1)
	var size: int = reps * n
	var genum: int = _index_to_enum(gi)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for py in size:
		for px in size:
			var ci: int = WallpaperGroupsScript.get_symmetric_color(px, py, n, _grid, genum)
			img.set_pixel(px, py, _color_for(ci))
	return ImageTexture.create_from_image(img)


# ═══════════════════════════════════════════════════════════════════════════
# UPKEEP — which moment of its working life the machine is caught in
# ═══════════════════════════════════════════════════════════════════════════
#
# The second axis, and deliberately NOT a second way of saying the first. `exhibit` argues
# about the cloth and a closed set of seventeen; `upkeep` argues about the machine and the
# labour that a frictionless sci-fi press quietly deletes. The word and its four values are
# adopted verbatim from the curation kit (station_wall / station_pillar / station_crates)
# and shared with pattern_loom, so the two pattern machines and the room they stand in speak
# one vocabulary instead of three synonyms.
#
# All three dressed values are pure APPENDS onto the +X flank and the floor beside it — the
# side the capture camera is on, and the one side of this machine that carries nothing (the
# service panel is at -X, the lever sits inboard at x = half - 0.06 and forward of z = 0).
# Nothing above is moved, recoloured or hidden, and `service` runs none of it.

const UPK_BOARD: Color = Color(0.55, 0.44, 0.28)   # scratch-board deck
const UPK_STEEL: Color = Color(0.42, 0.44, 0.48)   # trestle legs / bared studs
const UPK_SHEET: Color = Color(0.30, 0.31, 0.33)   # dust sheeting
const UPK_STRAP: Color = Color(0.86, 0.34, 0.11)   # safety-orange banding
const UPK_VOID: Color = Color(0.04, 0.04, 0.05)    # the dark where cladding was
const UPK_CZ: float = -0.22                        # dressing centre along Z (machine body)
const UPK_DZ: float = 1.10                         # dressing length along Z


## An unknown word keeps the DEFAULT rather than crashing or inventing a fifth moment — the
## same contract the exhibit read uses, so a typo in a map token is inert.
func _norm_upkeep(v: String) -> String:
	var s: String = v.strip_edges().to_lower()
	return s if UPKEEPS.has(s) else "service"


func _build_upkeep() -> void:
	match upkeep:
		"works":
			_upkeep_works()
		"store":
			_upkeep_store()
		"scrap":
			_upkeep_scrap()
		_:
			pass                                  # "service" — the legacy lineage


## A short stencilled word standing on the flank, facing +X so it reads from the camera side.
func _upk_stencil(text: String, pos: Vector3) -> void:
	var q: Label3D = Label3D.new()
	q.text = text
	q.pixel_size = 0.0016
	q.font_size = 28
	q.modulate = UPK_STRAP
	q.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	q.position = pos
	q.rotation_degrees = Vector3(0, 90, 0)
	add_child(q)


## Diagonal hazard stripes — built per call, only on the `scrap` path.
func _upk_tape_tex() -> ImageTexture:
	var img: Image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var d: int = (x + y) % 16
			img.set_pixel(x, y, UPK_STRAP if d < 8 else Color(0.08, 0.08, 0.09, 1.0))
	return ImageTexture.create_from_image(img)


func _upk_tape_bar(size: Vector3, pos: Vector3, rot: Vector3, tex: ImageTexture) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	var bm: BoxMesh = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.rotation_degrees = rot
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(maxf(size.z, size.x) * 5.0, 1.0, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.8
	mi.material_override = m
	add_child(mi)


## WORKS — the mill mid-job. A scratch-board deck on trestle legs stands off the flank at
## working height with tools laid on it, a conduit run crosses over the head, and the side
## cover that came off is leaned against the frame. The deck is the silhouette change: a
## horizontal mass projecting 0.4 m into the room off a flank that had nothing on it.
func _upkeep_works() -> void:
	var half: float = carpet_width * 0.5 + 0.22
	var fx: float = half + 0.06
	var deck_y: float = 0.86

	_box(Vector3(0.42, 0.05, UPK_DZ), Vector3(fx + 0.23, deck_y, UPK_CZ), UPK_BOARD, 0.1, 0.85)
	for sz in [-1.0, 1.0]:
		var lz: float = UPK_CZ + sz * UPK_DZ * 0.36
		_box(Vector3(0.05, deck_y, 0.05), Vector3(fx + 0.07, deck_y * 0.5, lz), UPK_STEEL, 0.6, 0.4)
		_box(Vector3(0.05, deck_y, 0.05), Vector3(fx + 0.39, deck_y * 0.5, lz), UPK_STEEL, 0.6, 0.4)

	# Tools laid out on the deck — three small blocks, the sign that someone is coming back.
	_box(Vector3(0.22, 0.035, 0.05), Vector3(fx + 0.20, deck_y + 0.04, UPK_CZ - 0.26),
		UPK_STEEL.lightened(0.15), 0.7, 0.35)
	_box(Vector3(0.07, 0.05, 0.16), Vector3(fx + 0.30, deck_y + 0.05, UPK_CZ + 0.07),
		UPK_STRAP.darkened(0.15), 0.2, 0.6)
	_cyl(0.19, 0.022, Vector3(fx + 0.14, deck_y + 0.04, UPK_CZ + 0.31),
		UPK_STEEL, 0.7, 0.3).rotation_degrees = Vector3(90, 0, 0)

	# Conduit run over the head — the sign that the machine is opened, not merely parked.
	# Held out at the flank so it never crosses the proof sheet (x within +-0.46).
	_cyl(UPK_DZ + 0.80, 0.035, Vector3(fx + 0.06, 1.62, UPK_CZ),
		accent_color.darkened(0.35), 0.5, 0.5).rotation_degrees = Vector3(90, 0, 0)

	# The side cover that came off, leaned against the frame.
	var lean: MeshInstance3D = _box(Vector3(0.03, 0.86, UPK_DZ * 0.62),
		Vector3(fx + 0.13, 0.43, UPK_CZ - 0.04), UPK_STEEL.darkened(0.18), 0.5, 0.5)
	lean.rotation_degrees = Vector3(0, 0, -13)

	_upk_stencil("WORKS", Vector3(fx + 0.46, deck_y + 0.13, UPK_CZ + 0.37))


## STORE — packed down. A sheet is pulled over the core, the fold-order rotors and the head
## grid together and strapped in three places: the mill stops being a thing that glows and
## turns and becomes a wrapped volume. The output is not deleted, it is FINISHED — banded
## into three bolts stacked on the floor at the flank, still carrying the milled pattern,
## because that is what packed down means for a textile.
func _upkeep_store() -> void:
	var half: float = carpet_width * 0.5 + 0.22
	var fx: float = half + 0.06
	# Drape box: stops at y = 1.46, below the proof sheet's bottom edge (CORE_Y + 0.55), and
	# at z = -0.02, behind the lever pivot, so neither is swallowed.
	var y0: float = 0.70
	var y1: float = 1.46
	var z0: float = -0.72
	var z1: float = -0.02
	var sx: float = (half + 0.08) * 2.0
	var sz: float = z1 - z0

	_box(Vector3(sx, y1 - y0, sz), Vector3(0, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		UPK_SHEET, 0.0, 0.95)
	for f in [0.20, 0.50, 0.80]:
		_box(Vector3(sx + 0.03, 0.045, sz + 0.03),
			Vector3(0, y0 + (y1 - y0) * f, (z0 + z1) * 0.5), UPK_STRAP, 0.1, 0.6)

	# Three finished bolts, banded and stood on end against the flank. Ranged along Z rather
	# than piled outward along X on purpose: the run already owns that depth, so the dressing
	# adds mass without widening the artifact's AABB and handing the sweep a re-frame to
	# measure instead of a change.
	var bl: float = minf(carpet_width, 1.05)
	var stack: Array[Vector3] = [
		Vector3(fx + 0.15, bl * 0.5, UPK_CZ - 0.30),
		Vector3(fx + 0.15, bl * 0.5, UPK_CZ),
		Vector3(fx + 0.15, bl * 0.5, UPK_CZ + 0.30)]
	for p in stack:
		var roll: MeshInstance3D = _cyl(bl, 0.10, p, frame_color, 0.1, 0.85)
		roll.material_override = _upk_bolt_material()
		for by in [0.28, 0.74]:
			_cyl(0.045, 0.112, Vector3(p.x, bl * by, p.z), UPK_STRAP, 0.1, 0.6)

	_upk_stencil("PACKED", Vector3(fx + 0.30, bl + 0.14, UPK_CZ))


## The cloth on a finished bolt — the SAME reusable output texture the carpet and the proof
## sheet are fed from, so a packed-down mill is showing you exactly what it was milling.
func _upk_bolt_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 0.9
	m.metallic = 0.0
	m.uv1_scale = Vector3(2.0, 1.0, 1.0)
	if _output_tex:
		m.albedo_texture = _output_tex
	else:
		m.albedo_color = _color_for(1)
	return m


## SCRAP — robbed. The flank cladding is gone and the studs it was hiding stand bare in the
## dark, the cover is lying flat on the floor where it was dropped, and two runs of hazard
## tape are crossed over the opening. The frame is still there; what was ON it is not.
func _upkeep_scrap() -> void:
	var half: float = carpet_width * 0.5 + 0.22
	var fx: float = half + 0.06
	var h: float = 1.05
	var yc: float = 0.10 + h * 0.5

	_box(Vector3(0.03, h, UPK_DZ), Vector3(fx + 0.02, yc, UPK_CZ), UPK_VOID, 0.0, 0.95)

	var n: int = maxi(int(UPK_DZ / 0.28), 2)
	for i in range(n + 1):
		var zz: float = UPK_CZ - UPK_DZ * 0.5 + UPK_DZ * (float(i) / float(n))
		_box(Vector3(0.045, h, 0.045), Vector3(fx + 0.05, yc, zz), UPK_STEEL, 0.6, 0.4)

	# The cover, dropped flat on the floor in the lane beside the run — forward along Z, which
	# the artifact already occupies, rather than out along X, which it does not.
	var cover: MeshInstance3D = _box(Vector3(0.03, 0.46, UPK_DZ * 0.80),
		Vector3(fx + 0.14, 0.03, UPK_CZ + 0.95), UPK_STEEL.darkened(0.25), 0.5, 0.5)
	cover.rotation_degrees = Vector3(0, 12, 90)

	var tex: ImageTexture = _upk_tape_tex()
	_upk_tape_bar(Vector3(0.012, 0.075, UPK_DZ * 1.04),
		Vector3(fx + 0.09, 0.10 + h * 0.34, UPK_CZ), Vector3(10, 0, 0), tex)
	_upk_tape_bar(Vector3(0.012, 0.075, UPK_DZ * 1.04),
		Vector3(fx + 0.09, 0.10 + h * 0.68, UPK_CZ), Vector3(-10, 0, 0), tex)
