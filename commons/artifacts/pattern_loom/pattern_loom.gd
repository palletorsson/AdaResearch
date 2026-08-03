extends Node3D
class_name PatternLoom

# @identity
# essence: a sci-fi loom that manufactures wallpaper. The 17 wallpaper groups
#          stop being a flat sample on a plate and become OUTPUT — a carpet woven
#          on glowing warp threads and fed continuously out of the machine, the
#          symmetry group scrolling past like fabric off a mill.
# desire: to show that a pattern is produced, not given. A plate says "here is
#         p6m"; a loom says "watch p6m being made, metre after metre, by a rule."
# critical_parameter: loom_style — roller | warp | mirror. Same wallpaper engine,
#         three machines: a press that rolls carpet onto the floor, an upright
#         tapestry loom that drops a banner, a mirror-loom that weaves the pattern
#         against its own reflection.
# triggers: _ready renders the wallpaper image via PatternSim, dresses the chosen
#           machine, hangs the textured cloth; _process scrolls the weave + pulses
#           the warp glow so the thing is always producing.
# emerges: the same federated move as the assembler — reuse the grammar's
#          render_to_image, wrap it in an apparatus. The loom is a body for a rule.
# needs: a dark machine frame with emissive accents [present]; glowing warp
#        threads + a weave bar [present]; a wallpaper-textured cloth that scrolls
#        out of the weave line [present]; DNA for group/palette/seed/style [present]
# relationships: sibling to primitive_assembler & conveyor_belt (machines that
#        output the algorithm); re-bodies pattern_maker_station / pattern_tile_plate
#        (those edit the carpet; this manufactures it); draws machine vocabulary
#        from props-dna-gallery (autoclave, cable tray, electrical panel)
# truth: every textile in history was a loom's output before it was a floor. The
#        wallpaper group is the program; the loom is the press that runs it.

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

# ── DNA ────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m).
@export var group: String = "p4m"
## Palette name (bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome).
@export var palette: String = "alhambra"
## Motif seed — two digits of DNA decide the whole tiling.
@export var motif_seed: int = 7
## Machine form: roller | warp | mirror.
@export var loom_style: String = "roller"
## Fill density of the source motif.
@export var density: float = 0.55
## When true, a reachable VR console runs out from the loom with live pattern-maker
## controls (group/palette/density/seed + preview). Default false keeps every
## existing loom variant pixel-identical.
@export var interactive: bool = false
## What the loom admits about where its pattern came from. The seventeen plane symmetry
## groups are a CLOSED SET, so a loom is a machine for manufacturing something already
## fully enumerated — and this is how much of that it prints.
##   none      — seamless cloth. The pattern arrives as if it were invented here.
##   repeat    — the lattice printed into the weave, and one block blown up on a card at
##               the feed: a metre of fabric is one small square, copied.
##   symmetry  — the group's translations, mirrors, glides and rotation centres drawn
##               over the cloth. The rule, not the result.
##   catalogue — a selvage of seventeen chips down BOTH edges of the bolt with this one
##               lit, and the whole index on the card: entry N of a finished list.
## Default `none` reproduces every existing loom placement exactly.
@export_enum("none", "repeat", "symmetry", "catalogue") var colophon: String = "none"
## Which moment of its working life the machine is caught in. The word, the four values and
## the unknown-word contract are taken verbatim from [[station_wall]] / [[station_pillar]] /
## [[station_crates]], which already share `upkeep` across the curation kit — a bay whose
## walls read "packed down" must not hold a loom that still reads "in commission".
##   service  in commission — the legacy lineage, byte for byte
##   works    mid-job       — a trestle deck stood off the flank, a conduit run over the head,
##                            the cover panel leaned against the frame, WORKS on the deck
##   store    packed down   — a sheet strapped over the head (which covers the accent rail and
##                            the weave bar, the brightest pixels the loom owns) and the run's
##                            output banded into finished bolts stacked on the floor
##   scrap    robbed        — the flank cladding gone and the studs bared, the cover lying on
##                            the floor where it was dropped, hazard tape crossed over the hole
## The CLOTH is never covered by any of them: the carpet is what the artifact teaches.
## Default `service` reproduces every existing loom placement exactly.
@export_enum("service", "works", "store", "scrap") var upkeep: String = "service"

@export_group("Machine")
@export var frame_color: Color = Color(0.12, 0.12, 0.15)
@export var accent_color: Color = Color(0.30, 0.85, 0.95)   # cyan sci-fi accent
@export var warp_color: Color = Color(0.45, 0.95, 1.0)
@export var carpet_width: float = 1.2
@export var carpet_length: float = 2.6
@export var scroll_speed: float = 0.16
## Procedural industrial detailing (props-dna-gallery vocabulary): a machine
## plinth, pipes + valves, a cable tray, an electrical panel, gauges and a hazard
## band. Dresses every loom variant by default so the thing reads as a serious
## lab machine. Set false for a bare frame (lightest variant).
@export var dress_machine: bool = true

# ── Runtime ────────────────────────────────────────────────────────────
var _carpet_tex: ImageTexture
var _carpet_mat: StandardMaterial3D
var _scroll_axis: int = 1          # which uv axis the cloth feeds along (0=x,1=y)
var _weave_mats: Array[StandardMaterial3D] = []
var _warp_mats: Array[StandardMaterial3D] = []
var _spinners: Array = []          # [{node, axis, speed}] — drum/roller/disc rotation
var _elapsed: float = 0.0

# ── Industrial-dressing shared materials (built once per (re)build) ──────
# All dressing geometry reuses these so the props-dna detailing adds a handful
# of materials, not one per mesh. Rebuilt fresh each _ready/apply_grid_config.
var _mat_dark: StandardMaterial3D       # plinth / housing dark steel
var _mat_steel: StandardMaterial3D      # pipes / panel body / brushed metal
var _mat_accent: StandardMaterial3D     # emissive cyan accent (animated)
var _mat_hazard: StandardMaterial3D     # hazard-yellow band
var _gauge_needles: Array = []          # [{node, base_deg, amp_deg, speed}]

# ── Interactive console state ──────────────────────────────────────────
const GROUP_NAMES: Array = [
	"p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
	"p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m",
]
const PALETTE_NAMES: Array = [
	"bauhaus", "escher", "alhambra", "tatami",
	"pastel", "memphis", "persian", "monochrome",
]
const SEED_MAX: int = 40           # SEED slider runs 0..SEED_MAX (integer-stepped)

var PUSH_BUTTON: PackedScene        # loaded in _ready (may be null headless)
var SLIDER_H: PackedScene
var _group_index: int = 10          # index into GROUP_NAMES
var _palette_index: int = 2         # index into PALETTE_NAMES
var _preview_mat: StandardMaterial3D
var _group_label: Label3D
var _palette_label: Label3D
var _seed_label: Label3D
var _density_slider: Node          # SliderHorizontal instance (or null)
var _seed_slider: Node             # SliderHorizontal instance (or null)


func _ready() -> void:
	_read_overrides()
	_sync_indices()
	_render_pattern()
	match loom_style:
		"warp":     _build_warp()
		"mirror":   _build_mirror()
		"drum":     _build_drum()
		"bolt":     _build_bolt()
		"fountain": _build_fountain()
		_:          _build_roller()
	if dress_machine:
		_build_machine_dressing()
	if interactive:
		_build_console()
		if dress_machine:
			_build_cable_run_to_console()
	# Machine extent measured BEFORE the colophon card is added, so the upkeep dressing lands
	# against the frame and not at the far end of a 2.6 m carpet run. On the default path the
	# walk never runs at all.
	var mb: AABB = _machine_bounds() if upkeep != "service" else AABB()
	# LAST, so nothing above it moves: the colophon reads the finished machine and adds
	# a card at the feed. `none` builds nothing at all.
	if colophon != "none":
		_build_colophon_card()
	# LAST OF ALL, appended after the colophon for the same reason: every child index and
	# position above is untouched. `service` falls through and adds nothing.
	match upkeep:
		"works":
			_upkeep_works(mb)
		"store":
			_upkeep_store(mb)
		"scrap":
			_upkeep_scrap(mb)
		_:
			pass                                  # "service" — the legacy lineage


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("group"): group = str(cfg["group"])
	if cfg.has("palette"): palette = str(cfg["palette"])
	if cfg.has("motif_seed"): motif_seed = int(cfg["motif_seed"])
	if cfg.has("loom_style"): loom_style = str(cfg["loom_style"])
	if cfg.has("density"): density = float(cfg["density"])
	if cfg.has("interactive"): interactive = _to_bool(cfg["interactive"])
	if cfg.has("dress_machine"): dress_machine = _to_bool(cfg["dress_machine"])
	if cfg.has("colophon"): colophon = _norm_colophon(str(cfg["colophon"]))
	if cfg.has("upkeep"): upkeep = _norm_upkeep(str(cfg["upkeep"]))
	if cfg.has("scale"):
		var s: float = float(cfg["scale"])
		if s > 0.0: scale = Vector3.ONE * s
	for c in get_children(): c.queue_free()
	_weave_mats.clear(); _warp_mats.clear(); _spinners.clear()
	_gauge_needles.clear()
	_mat_dark = null; _mat_steel = null; _mat_accent = null; _mat_hazard = null
	_preview_mat = null; _carpet_mat = null
	_group_label = null; _palette_label = null; _seed_label = null
	_density_slider = null; _seed_slider = null
	call_deferred("_ready")


func _read_overrides() -> void:
	for k in ["group", "palette", "loom_style", "colophon"]:
		if has_meta("config_%s" % k): set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"): motif_seed = int(str(get_meta("config_motif_seed")))
	if has_meta("config_density"): density = float(str(get_meta("config_density")))
	if has_meta("config_interactive"): interactive = _to_bool(get_meta("config_interactive"))
	if has_meta("config_dress_machine"): dress_machine = _to_bool(get_meta("config_dress_machine"))
	# Normalising read: an unknown word leaves the shipped default standing rather than
	# asking the match block below for a moment nothing in this file knows how to build.
	if has_meta("config_upkeep"): upkeep = _norm_upkeep(str(get_meta("config_upkeep")))


## Coerce a config value (bool / int / string "true"/"1") to bool.
func _to_bool(v: Variant) -> bool:
	if v is bool: return bool(v)
	if v is int or v is float: return float(v) != 0.0
	if v is String:
		var s: String = (v as String).strip_edges().to_lower()
		return s == "true" or s == "1" or s == "yes"
	return false


## Keep the cycling indices in step with the current group/palette strings.
func _sync_indices() -> void:
	var gi: int = GROUP_NAMES.find(group.to_lower())
	_group_index = gi if gi >= 0 else 10            # default p4m
	group = GROUP_NAMES[_group_index]
	var pi: int = PALETTE_NAMES.find(palette.to_lower())
	_palette_index = pi if pi >= 0 else 2           # default alhambra
	palette = PALETTE_NAMES[_palette_index]
	density = clampf(density, 0.1, 0.95)
	motif_seed = clampi(motif_seed, 0, SEED_MAX)
	colophon = _norm_colophon(colophon)
	upkeep = _norm_upkeep(upkeep)


# ── Wallpaper texture ──────────────────────────────────────────────────

## Reusable render: rebuild the wallpaper Image from the current DNA and feed it
## into the SHARED ImageTexture. Every carpet/banner/drum/preview material points
## at _carpet_tex, so updating it in place re-textures the whole machine live.
## Called once at build time and again on every console control change.
func _render_pattern() -> void:
	var cfg := {
		"group": group, "palette": palette, "motif_seed": motif_seed,
		"tile_size": 16, "canvas_size": 256, "density": density,
	}
	var img: Image = PatternSim.render_to_image(cfg)
	# The colophon is PRINTED IN THE CLOTH, not hung beside it: every material on the
	# machine shares _carpet_tex, so marks drawn here land on the carpet, the banner,
	# the drum, the preview plate and every repeat of the bolt at once. Skipped whole
	# when colophon is none, so the default texture is byte-identical to before.
	if colophon != "none":
		_print_colophon(img)
	if _carpet_tex:
		_carpet_tex.update(img)          # in-place: all sharers re-paint, no re-link
	else:
		_carpet_tex = ImageTexture.create_from_image(img)


func _make_carpet_material(rep_x: float, rep_y: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _carpet_tex
	m.uv1_scale = Vector3(rep_x, rep_y, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST   # crisp tiles
	m.cull_mode = BaseMaterial3D.CULL_DISABLED                 # cloth visible from both sides
	m.roughness = 0.85
	m.metallic = 0.0
	return m


# ── Style: roller (carpet rolls onto the floor) ────────────────────────

func _build_roller() -> void:
	_scroll_axis = 1
	# Back frame: two posts + top crossbar holding the feed roller.
	var w := carpet_width * 0.5 + 0.18
	_box(Vector3(0.08, 1.2, 0.08), Vector3(-w, 0.6, 0), frame_color)
	_box(Vector3(0.08, 1.2, 0.08), Vector3(w, 0.6, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.08, 0.09, 0.12), Vector3(0, 1.18, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, 1.0, 0.07), accent_color, 1.6)

	# Feed roller — the carpet emerges over it.
	var roller := _cyl(carpet_width + 0.16, 0.09, Vector3(0, 1.0, 0.12), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)

	# Warp threads (vertical, behind the roller) — the loom reading.
	_warp_threads(Vector3(0, 0.18, -0.02), 1.0, carpet_width, 13)
	# Glowing weave bar at the feed line.
	_weave_bar(Vector3(0, 1.0, 0.12), carpet_width + 0.1, 0)

	# Carpet: drops from the roller and runs forward across the floor.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	pm.subdivide_depth = 1
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.01, 0.12 + carpet_length * 0.5)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: warp (upright tapestry loom, banner drops) ──────────────────

func _build_warp() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.16
	var top := carpet_length + 0.4
	_box(Vector3(0.09, top, 0.09), Vector3(-w, top * 0.5, 0), frame_color)
	_box(Vector3(0.09, top, 0.09), Vector3(w, top * 0.5, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.09, 0.1, 0.13), Vector3(0, top, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, top - 0.05, 0.07), accent_color, 1.6)

	# Top beam roller.
	var roller := _cyl(carpet_width + 0.14, 0.08, Vector3(0, top - 0.12, 0.0), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)

	# Vertical warp threads down the full frame.
	_warp_threads(Vector3(0, 0.1, -0.04), top - 0.2, carpet_width, 15)
	# Weave bar partway down (the active shed).
	_weave_bar(Vector3(0, top - 0.12, 0.04), carpet_width + 0.08, 0)

	# The banner: hangs vertically from the top roller.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	carpet.rotation_degrees = Vector3(-90, 0, 0)             # stand it up facing +Z
	carpet.position = Vector3(0, top - 0.12 - carpet_length * 0.5, 0.04)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: mirror (twin panels woven against a reflection) ─────────────

func _build_mirror() -> void:
	_scroll_axis = 0
	var h := carpet_length * 0.6
	var pw := carpet_width
	# Frame.
	_box(Vector3(0.08, h + 0.2, 0.08), Vector3(-pw - 0.05, (h + 0.2) * 0.5, 0), frame_color)
	_box(Vector3(0.08, h + 0.2, 0.08), Vector3(pw + 0.05, (h + 0.2) * 0.5, 0), frame_color)
	_box(Vector3((pw + 0.05) * 2.0, 0.09, 0.1), Vector3(0, h + 0.2, 0), frame_color)
	# Central glowing seam — the mirror axis.
	_emissive_box(Vector3(0.03, h + 0.1, 0.06), Vector3(0, (h + 0.2) * 0.5, 0.03), accent_color, 2.2)
	_weave_bar(Vector3(0, h + 0.16, 0.04), (pw + 0.05) * 2.0, 0)

	# Two panels, the right one mirrored on X.
	for side in [-1.0, 1.0]:
		var panel := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(pw, h)
		panel.mesh = pm
		panel.rotation_degrees = Vector3(-90, 0, 0)
		panel.position = Vector3(side * (pw * 0.5 + 0.02), (h + 0.2) * 0.5, 0.02)
		var mat := _make_carpet_material(1.0, h / pw * 1.0)
		if side > 0.0:
			mat.uv1_scale = Vector3(-1.0, mat.uv1_scale.y, 1.0)   # reflect
		panel.material_override = mat
		if side < 0.0:
			_carpet_mat = mat       # scroll the left one (right tracks via shared feel)
		add_child(panel)


# ── Shared machine parts ───────────────────────────────────────────────

func _warp_threads(base: Vector3, height: float, span: float, count: int) -> void:
	for i in range(count):
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004; cm.bottom_radius = 0.004; cm.height = height
		cm.radial_segments = 6
		t.mesh = cm
		var x := lerpf(-span * 0.5, span * 0.5, float(i) / float(maxi(1, count - 1)))
		t.position = base + Vector3(x, height * 0.5, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = warp_color
		m.emission_enabled = true; m.emission = warp_color
		m.emission_energy_multiplier = 0.9
		t.material_override = m
		_warp_mats.append(m)
		add_child(t)


func _weave_bar(pos: Vector3, length: float, axis: int) -> void:
	var bar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.025; cm.bottom_radius = 0.025; cm.height = length
	cm.radial_segments = 12
	bar.mesh = cm
	bar.rotation_degrees = Vector3(0, 0, 90)
	bar.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = accent_color
	m.emission_enabled = true; m.emission = accent_color
	m.emission_energy_multiplier = 2.0
	bar.material_override = m
	_weave_mats.append(m)
	add_child(bar)


func _box(size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = 0.5; m.metallic = 0.35
	mi.material_override = m
	add_child(mi)
	return mi


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := _box(size, pos, color)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true; m.emission = color
	m.emission_energy_multiplier = energy
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	cm.radial_segments = 20
	mi.mesh = cm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.metallic = 0.6; m.roughness = 0.35
	mi.material_override = m
	add_child(mi)
	return mi


# ── Style: drum (rotary press — carpet feeds off a spinning print drum) ─

func _build_drum() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.22
	_box(Vector3(0.12, 1.15, 0.12), Vector3(-w, 0.575, 0), frame_color)
	_box(Vector3(0.12, 1.15, 0.12), Vector3(w, 0.575, 0), frame_color)
	_box(Vector3(w * 2.0 + 0.12, 0.09, 0.55), Vector3(0, 1.1, 0), frame_color)
	_emissive_box(Vector3(w * 2.0, 0.02, 0.02), Vector3(0, 1.02, 0.28), accent_color, 1.6)
	# Big print drum — the wallpaper wraps it; it spins on its X axle.
	var pivot := Node3D.new()
	pivot.position = Vector3(0, 0.78, 0)
	add_child(pivot)
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.42; dm.bottom_radius = 0.42; dm.height = carpet_width
	dm.radial_segments = 44
	drum.mesh = dm
	drum.rotation_degrees = Vector3(0, 0, 90)
	var drum_mat := _make_carpet_material(1.0, 3.0)
	drum.material_override = drum_mat
	pivot.add_child(drum)
	_spinners.append({"node": pivot, "axis": Vector3.RIGHT, "speed": 0.8})
	# End caps.
	for sx in [-1.0, 1.0]:
		_cyl(0.04, 0.44, Vector3(sx * carpet_width * 0.5, 0.78, 0), frame_color.lightened(0.15)).rotation_degrees = Vector3(0, 0, 90)
	_warp_threads(Vector3(0, 1.0, -0.2), 0.42, carpet_width, 11)
	_weave_bar(Vector3(0, 0.78, 0.42), carpet_width + 0.1, 0)
	# Carpet feeds off the drum front onto the floor.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.01, 0.42 + carpet_length * 0.5)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


# ── Style: bolt (wall dispenser — a bolt of wallpaper unrolls down) ─────

func _build_bolt() -> void:
	_scroll_axis = 1
	var w := carpet_width * 0.5 + 0.16
	var top := carpet_length + 0.55
	# Header mounting plate (behind the roller only) + brackets + top supply roller.
	_box(Vector3(carpet_width + 0.5, 0.42, 0.08), Vector3(0, top - 0.12, -0.16), frame_color.darkened(0.2))
	_box(Vector3(0.1, 0.34, 0.34), Vector3(-w, top - 0.12, 0.02), frame_color)
	_box(Vector3(0.1, 0.34, 0.34), Vector3(w, top - 0.12, 0.02), frame_color)
	var roller := _cyl(carpet_width + 0.22, 0.11, Vector3(0, top - 0.12, 0.08), frame_color.lightened(0.1))
	roller.rotation_degrees = Vector3(0, 0, 90)
	_emissive_box(Vector3(carpet_width + 0.22, 0.02, 0.02), Vector3(0, top - 0.26, 0.12), accent_color, 1.6)
	_warp_threads(Vector3(0, top - 0.55, -0.08), 0.32, carpet_width, 9)
	# The bolt: wallpaper hangs down the wall, unrolling (uv scrolls down).
	var sheet := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(carpet_width, carpet_length)
	sheet.mesh = pm
	sheet.rotation_degrees = Vector3(-90, 0, 0)
	sheet.position = Vector3(0, top - 0.12 - carpet_length * 0.5, 0.1)
	_carpet_mat = _make_carpet_material(2.0, carpet_length / carpet_width * 2.0)
	sheet.material_override = _carpet_mat
	add_child(sheet)
	# Weighted cutter bar at the hem.
	_emissive_box(Vector3(carpet_width + 0.12, 0.05, 0.07), Vector3(0, top - 0.12 - carpet_length, 0.12), accent_color, 1.3)


# ── Style: fountain (radial — a round rug spins out of a central spout) ─

func _build_fountain() -> void:
	# Central spout column + glowing head.
	_cyl(1.0, 0.13, Vector3(0, 0.5, 0), frame_color)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.19; sm.height = 0.38
	head.mesh = sm; head.position = Vector3(0, 1.08, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = accent_color
	hmat.emission_enabled = true; hmat.emission = accent_color
	hmat.emission_energy_multiplier = 2.0
	head.material_override = hmat
	add_child(head)
	_weave_mats.append(hmat)
	_warp_threads(Vector3(0, 0.12, 0), 0.92, carpet_width * 0.5, 8)
	# Round carpet on the floor, radiating from centre, slowly turning.
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = carpet_length * 0.6; dm.bottom_radius = carpet_length * 0.6
	dm.height = 0.02; dm.radial_segments = 56
	disc.mesh = dm; disc.position = Vector3(0, 0.01, 0)
	var disc_mat := _make_carpet_material(3.0, 3.0)
	disc.material_override = disc_mat
	add_child(disc)
	_spinners.append({"node": disc, "axis": Vector3.UP, "speed": 0.18})
	# Glowing rim ring.
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = carpet_length * 0.58; tm.outer_radius = carpet_length * 0.63
	ring.mesh = tm; ring.position = Vector3(0, 0.02, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = accent_color
	rmat.emission_enabled = true; rmat.emission = accent_color
	rmat.emission_energy_multiplier = 1.4
	ring.material_override = rmat
	add_child(ring)


# ═══════════════════════════════════════════════════════════════════════════
# INDUSTRIAL DRESSING — props-dna-gallery vocabulary (pipes, valves, cable tray,
# electrical panel, gauges, hazard band). Procedural, shared materials, applied
# to EVERY loom variant so the machine reads as serious lab kit, not a bare frame.
# Gate with `dress_machine = false` for the lightest variant.
# ═══════════════════════════════════════════════════════════════════════════

const DR_HALF_GAP: float = 0.42          # how far out to the side the housing reaches


## Build the four shared dressing materials once, then assemble the props. Holds
## the whole dressing to ~4 materials no matter how many meshes it spawns.
func _build_machine_dressing() -> void:
	_mat_dark = _con_mat(frame_color.darkened(0.35), 0.45, 0.6)
	_mat_steel = _con_mat(Color(0.40, 0.42, 0.46), 0.75, 0.4)
	_mat_accent = StandardMaterial3D.new()
	_mat_accent.albedo_color = accent_color
	_mat_accent.metallic = 0.2
	_mat_accent.roughness = 0.45
	_mat_accent.emission_enabled = true
	_mat_accent.emission = accent_color
	_mat_accent.emission_energy_multiplier = 1.6
	_weave_mats.append(_mat_accent)        # breathes with the rest of the machine
	_mat_hazard = StandardMaterial3D.new()
	_mat_hazard.albedo_color = Color(0.98, 0.78, 0.12)
	_mat_hazard.metallic = 0.1
	_mat_hazard.roughness = 0.6
	_mat_hazard.emission_enabled = true
	_mat_hazard.emission = Color(0.98, 0.78, 0.12)
	_mat_hazard.emission_energy_multiplier = 0.5

	_build_machine_base()
	_build_side_housing()
	_build_frame_pipes()
	_build_electrical_panel()
	_build_gauges()
	_build_hazard_band()


## Reusable plain box with one of the shared dressing materials.
func _dr_box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi


## Reusable cylinder (pipe / valve hub / gauge ring) with a shared material.
func _dr_cyl(height: float, radius: float, pos: Vector3, mat: StandardMaterial3D,
		segments: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	cm.radial_segments = segments
	mi.mesh = cm; mi.position = pos
	mi.material_override = mat
	add_child(mi)
	return mi


# ── Chunky dark plinth the drum + console sit on ───────────────────────

func _build_machine_base() -> void:
	# A low dark plinth running under the machine footprint, slightly into the
	# feed direction so the drum/frame visibly sit ON something.
	var base_w: float = carpet_width + DR_HALF_GAP * 2.0 + 0.3
	var base_d: float = 0.7
	var base_h: float = 0.12
	_dr_box(Vector3(base_w, base_h, base_d), Vector3(0, base_h * 0.5, -0.05), _mat_dark)
	# A thin brushed-steel skirt cap for a machined edge.
	_dr_box(Vector3(base_w + 0.04, 0.025, base_d + 0.04),
		Vector3(0, base_h, -0.05), _mat_steel)
	# Four stubby feet so it reads as freestanding kit.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_dr_cyl(0.06, 0.05,
				Vector3(sx * base_w * 0.42, 0.03, -0.05 + sz * base_d * 0.4),
				_mat_steel, 10)


# ── Boxy machine housing flanking the frame (the +X side, opposite console) ──

func _build_side_housing() -> void:
	# A boxy enclosure on the -X side of the frame: the "guts" the electrical panel
	# and gauges mount onto, and the cable tray runs from. Kept off the carpet lane.
	var hx: float = -(carpet_width * 0.5 + DR_HALF_GAP)
	var hous := _dr_box(Vector3(0.34, 0.95, 0.5), Vector3(hx, 0.6, -0.02), _mat_dark)
	hous.name = "DrumHousing"
	# Brushed-steel top plate + a couple of louvre slots (thin dark insets).
	_dr_box(Vector3(0.36, 0.03, 0.52), Vector3(hx, 1.08, -0.02), _mat_steel)
	for i in range(3):
		_dr_box(Vector3(0.26, 0.012, 0.02),
			Vector3(hx, 0.78 + float(i) * 0.07, 0.24), _mat_steel)
	# Emissive accent rib down the housing face.
	_dr_box(Vector3(0.02, 0.7, 0.02), Vector3(hx + 0.18, 0.62, 0.16), _mat_accent)


# ── Pipes with elbow bends + round valve wheels along the frame ────────

func _build_frame_pipes() -> void:
	var hx: float = -(carpet_width * 0.5 + DR_HALF_GAP)
	# A horizontal run of pipe across the top of the housing, with a vertical
	# down-leg joined by an elbow, ending at a valve wheel near the base.
	var pipe_r: float = 0.035
	var run_y: float = 0.92
	var run_len: float = 0.55
	var run := _dr_cyl(run_len, pipe_r, Vector3(hx + 0.05, run_y, 0.28), _mat_steel)
	run.rotation_degrees = Vector3(0, 0, 90)        # lay horizontal along X
	# Elbow joint (a small sphere) at the bend.
	var elbow := MeshInstance3D.new()
	var esm := SphereMesh.new(); esm.radius = pipe_r * 1.25; esm.height = pipe_r * 2.5
	elbow.mesh = esm
	elbow.position = Vector3(hx + 0.05 - run_len * 0.5, run_y, 0.28)
	elbow.material_override = _mat_steel
	add_child(elbow)
	# Vertical down-leg from the elbow.
	var leg_len: float = 0.6
	_dr_cyl(leg_len, pipe_r,
		Vector3(hx + 0.05 - run_len * 0.5, run_y - leg_len * 0.5, 0.28), _mat_steel)
	# Round valve wheel at the bottom of the leg.
	_build_valve_wheel(Vector3(hx + 0.05 - run_len * 0.5, run_y - leg_len, 0.34), 0.09)
	# A second, shorter pipe + valve higher up the frame on the same side.
	var leg2_len: float = 0.35
	_dr_cyl(leg2_len, pipe_r * 0.8,
		Vector3(hx + 0.05 + run_len * 0.5, run_y - leg2_len * 0.5 - 0.05, 0.28), _mat_steel)
	_build_valve_wheel(Vector3(hx + 0.05 + run_len * 0.5, run_y - 0.05, 0.34), 0.06)


## A valve hand-wheel: a hub + a torus rim + four spokes, facing +Z.
func _build_valve_wheel(pos: Vector3, radius: float) -> void:
	var wheel := Node3D.new()
	wheel.position = pos
	add_child(wheel)
	# Rim.
	var rim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.78; tm.outer_radius = radius
	tm.rings = 8; tm.ring_segments = 16
	rim.mesh = tm
	rim.rotation_degrees = Vector3(90, 0, 0)        # ring faces +Z
	rim.material_override = _mat_accent
	wheel.add_child(rim)
	# Hub.
	var hub := MeshInstance3D.new()
	var hc := CylinderMesh.new()
	hc.top_radius = radius * 0.22; hc.bottom_radius = radius * 0.22
	hc.height = 0.03; hc.radial_segments = 12
	hub.mesh = hc
	hub.rotation_degrees = Vector3(90, 0, 0)
	hub.material_override = _mat_steel
	wheel.add_child(hub)
	# Four spokes.
	for i in range(4):
		var spoke := MeshInstance3D.new()
		var sbm := BoxMesh.new()
		sbm.size = Vector3(radius * 1.5, 0.012, 0.012)
		spoke.mesh = sbm
		spoke.rotation_degrees = Vector3(0, 0, 45.0 * float(i))
		spoke.material_override = _mat_steel
		wheel.add_child(spoke)


# ── Electrical panel: box + door + breaker toggles + indicator LEDs ────

func _build_electrical_panel() -> void:
	# Mounts on the +Z face of the side housing, turned to face the player (+Z).
	var hx: float = -(carpet_width * 0.5 + DR_HALF_GAP)
	var panel := Node3D.new()
	panel.name = "ElectricalPanel"
	panel.position = Vector3(hx, 0.62, 0.26)
	add_child(panel)
	# Panel body (boxy unit).
	var body := MeshInstance3D.new()
	var bbm := BoxMesh.new(); bbm.size = Vector3(0.26, 0.34, 0.05)
	body.mesh = bbm
	body.material_override = _mat_steel
	panel.add_child(body)
	# Hinged door, cracked slightly open so the breakers read.
	var door_pivot := Node3D.new()
	door_pivot.position = Vector3(-0.13, 0.0, 0.026)
	door_pivot.rotation_degrees = Vector3(0, -32.0, 0)
	panel.add_child(door_pivot)
	var door := MeshInstance3D.new()
	var dbm := BoxMesh.new(); dbm.size = Vector3(0.26, 0.34, 0.012)
	door.mesh = dbm
	door.position = Vector3(0.13, 0.0, 0.006)
	door.material_override = _mat_dark
	door_pivot.add_child(door)
	# A few breaker toggles in two columns on the body face.
	var brk_mat: StandardMaterial3D = _con_mat(Color(0.08, 0.08, 0.10), 0.2, 0.55)
	var lev_mat: StandardMaterial3D = _con_mat(Color(0.92, 0.92, 0.94), 0.15, 0.4)
	for i in range(6):
		var col: int = i % 2
		var row: int = i / 2
		var bx: float = -0.06 + float(col) * 0.12
		var by: float = 0.08 - float(row) * 0.07
		var bz: float = 0.026
		var bdy := MeshInstance3D.new()
		var bdm := BoxMesh.new(); bdm.size = Vector3(0.05, 0.035, 0.014)
		bdy.mesh = bdm; bdy.position = Vector3(bx, by, bz)
		bdy.material_override = brk_mat
		panel.add_child(bdy)
		# Lever tilts up (ON) for even breakers, down for odd.
		var lev := MeshInstance3D.new()
		var lvm := BoxMesh.new(); lvm.size = Vector3(0.006, 0.02, 0.006)
		lev.mesh = lvm
		var tilt: float = -22.0 if (i % 2 == 0) else 22.0
		lev.rotation_degrees = Vector3(0, 0, tilt)
		lev.position = Vector3(bx, by, bz + 0.012)
		lev.material_override = lev_mat
		panel.add_child(lev)
	# Indicator LED row along the panel top — share the animated accent glow.
	# Built panel-relative (NOT via _dr_cyl, which parents to the loom root).
	for i in range(3):
		var led := MeshInstance3D.new()
		var lcm := CylinderMesh.new()
		lcm.top_radius = 0.009; lcm.bottom_radius = 0.009
		lcm.height = 0.006; lcm.radial_segments = 10
		led.mesh = lcm
		led.position = Vector3(-0.07 + float(i) * 0.07, 0.15, 0.028)
		led.rotation_degrees = Vector3(90, 0, 0)
		led.material_override = _mat_accent
		panel.add_child(led)


# ── Gauges: dial + sweeping needle on the housing ──────────────────────

func _build_gauges() -> void:
	var hx: float = -(carpet_width * 0.5 + DR_HALF_GAP)
	# Two round gauges on the housing face above the panel.
	_build_gauge(Vector3(hx - 0.09, 0.95, 0.26), 0.07, 0.9, 38.0)
	_build_gauge(Vector3(hx + 0.07, 0.95, 0.26), 0.05, 1.4, 24.0)


## A single dial gauge: bezel ring + face + a needle pivot that sweeps in _process.
func _build_gauge(pos: Vector3, radius: float, speed: float, amp_deg: float) -> void:
	var gauge := Node3D.new()
	gauge.position = pos
	add_child(gauge)
	# Bezel ring.
	var bez := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.82; tm.outer_radius = radius
	tm.rings = 8; tm.ring_segments = 18
	bez.mesh = tm
	bez.rotation_degrees = Vector3(90, 0, 0)
	bez.material_override = _mat_steel
	gauge.add_child(bez)
	# Dark dial face.
	var face := MeshInstance3D.new()
	var fc := CylinderMesh.new()
	fc.top_radius = radius * 0.82; fc.bottom_radius = radius * 0.82
	fc.height = 0.01; fc.radial_segments = 24
	face.mesh = fc
	face.rotation_degrees = Vector3(90, 0, 0)
	face.position = Vector3(0, 0, -0.01)
	face.material_override = _con_mat(Color(0.06, 0.07, 0.09), 0.1, 0.5)
	gauge.add_child(face)
	# Needle on its own pivot (so _process can sweep it cheaply).
	var needle_pivot := Node3D.new()
	needle_pivot.position = Vector3(0, 0, 0.005)
	gauge.add_child(needle_pivot)
	var needle := MeshInstance3D.new()
	var nbm := BoxMesh.new(); nbm.size = Vector3(0.006, radius * 1.3, 0.004)
	needle.mesh = nbm
	needle.position = Vector3(0, radius * 0.45, 0)   # offset so it pivots near the dial centre
	needle.material_override = _mat_accent
	needle_pivot.add_child(needle)
	_gauge_needles.append({
		"node": needle_pivot, "base_deg": 0.0, "amp_deg": amp_deg, "speed": speed,
	})


# ── Hazard stripe band ─────────────────────────────────────────────────

func _build_hazard_band() -> void:
	# A readable hazard band along the front lip of the plinth: alternating
	# yellow/dark angled chevrons. Sits low so it never crosses the carpet.
	var band_z: float = 0.28
	var band_w: float = carpet_width + DR_HALF_GAP * 1.4
	var n: int = 14
	var seg_w: float = band_w / float(n)
	for i in range(n):
		var x: float = -band_w * 0.5 + seg_w * (float(i) + 0.5)
		var chev := MeshInstance3D.new()
		var cbm := BoxMesh.new()
		cbm.size = Vector3(seg_w * 0.9, 0.06, 0.012)
		chev.mesh = cbm
		chev.position = Vector3(x, 0.135, band_z)
		chev.rotation_degrees = Vector3(0, 0, 28.0)
		var use_hazard: bool = (i % 2 == 0)
		chev.material_override = _mat_hazard if use_hazard else _mat_dark
		add_child(chev)


# ── Cable tray: shallow channel + bundled cables, housing → console ────

func _build_cable_run_to_console() -> void:
	# Only when interactive (a console exists to run to). A shallow tray with a
	# couple of bundled cables sweeping from the side housing toward the console.
	if _mat_dark == null:
		return                              # dressing was gated off — nothing to run from
	var hx: float = -(carpet_width * 0.5 + DR_HALF_GAP)
	var console_x: float = CON_SIDE * (carpet_width * 0.5 + 0.5)
	var mid_x: float = (hx + console_x) * 0.5
	var run_len: float = absf(console_x - hx) + 0.1
	var tray_y: float = 0.16
	var tray_z: float = -0.18
	# Tray floor + two low side walls forming a channel.
	_dr_box(Vector3(run_len, 0.015, 0.1), Vector3(mid_x, tray_y, tray_z), _mat_dark)
	for sz in [-1.0, 1.0]:
		_dr_box(Vector3(run_len, 0.035, 0.012),
			Vector3(mid_x, tray_y + 0.018, tray_z + sz * 0.05), _mat_steel)
	# Bundled cables: thin emissive-accent + steel cylinders lying in the tray.
	for i in range(3):
		var cz: float = tray_z - 0.025 + float(i) * 0.025
		var cab := _dr_cyl(run_len * 0.96, 0.011,
			Vector3(mid_x, tray_y + 0.03, cz), _mat_steel if i != 1 else _mat_accent)
		cab.rotation_degrees = Vector3(0, 0, 90)   # lie along X


# ── Animate: the machine is always producing ───────────────────────────

func _process(delta: float) -> void:
	_elapsed += delta
	for s in _spinners:
		(s["node"] as Node3D).rotate(s["axis"], s["speed"] * delta)
	if _carpet_mat:
		var o := _carpet_mat.uv1_offset
		if _scroll_axis == 0:
			o.x = fposmod(o.x + scroll_speed * delta, 1.0)
		else:
			o.y = fposmod(o.y + scroll_speed * delta, 1.0)
		_carpet_mat.uv1_offset = o
	var weave_pulse := 1.6 + 1.2 * (0.5 + 0.5 * sin(_elapsed * 5.0))
	for m in _weave_mats:
		m.emission_energy_multiplier = weave_pulse
	# Warp threads shimmer in a travelling wave.
	for i in range(_warp_mats.size()):
		_warp_mats[i].emission_energy_multiplier = 0.6 + 0.6 * (0.5 + 0.5 * sin(_elapsed * 4.0 - i * 0.5))
	# Gauge needles ease back and forth around their rest angle — the machine "reads".
	for g in _gauge_needles:
		var n: Node3D = g["node"] as Node3D
		if n != null and is_instance_valid(n):
			var sweep: float = g["base_deg"] + g["amp_deg"] * sin(_elapsed * g["speed"])
			n.rotation_degrees = Vector3(0, 0, sweep)


# ═══════════════════════════════════════════════════════════════════════════
# INTERACTIVE CONSOLE — a reachable lectern that runs out from the loom
# ═══════════════════════════════════════════════════════════════════════════

# Console geometry (metres). The lectern lives at the OUTPUT end — beside where
# the carpet feeds out the front (+Z) — so a player watching the cloth emerge can
# reach the controls. It sits off to one side of the carpet lane (never on it),
# near the start of the feed line, and the whole desk FACES the player (toward
# +Z). The top surface is angled ~15° up toward the standing viewer.
const CON_TOP_Y: float = 1.10            # top surface height (standing reach)
const CON_TILT_DEG: float = -15.0        # pitch the top toward the player
const CON_W: float = 0.62                # console desk width
const CON_D: float = 0.34                # console desk depth
const CON_SIDE: float = 1.0              # which side of the lane: -1 left, +1 right
const CON_FEED_Z: float = 0.45           # z near the output/feed start


func _build_console() -> void:
	# Load VR interactables; degrade to plain geometry if they fail (headless).
	if PUSH_BUTTON == null:
		PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	if SLIDER_H == null:
		SLIDER_H = load("res://commons/interactables/slider_horizontal.tscn")

	# Park the lectern at the OUTPUT/front, beside the carpet lane so it never
	# covers the feeding cloth. x is one desk-width clear of the lane edge; z is
	# down at the feed/output start where the player stands to watch.
	var side_x: float = CON_SIDE * (carpet_width * 0.5 + 0.5)
	var console := Node3D.new()
	console.name = "Console"
	console.position = Vector3(side_x, 0.0, CON_FEED_Z)
	# The console's local +Z (the direction the desk tilt and labels face) must
	# point toward the player, who stands out in front of the output at large +Z.
	# So keep yaw near 0 (face +Z) and cant it slightly inward toward the lane so
	# an operator beside the carpet sees the controls square-on. CON_SIDE=+1 puts
	# the desk on the +X side, so cant -ve (toward -X / the lane); mirror for left.
	console.rotation_degrees = Vector3(0, -CON_SIDE * 22.0, 0)
	add_child(console)

	# Short pedestal up to the desk.
	var ped := MeshInstance3D.new()
	var pcm := CylinderMesh.new()
	pcm.top_radius = 0.10; pcm.bottom_radius = 0.14
	pcm.height = CON_TOP_Y - 0.10; pcm.radial_segments = 16
	ped.mesh = pcm
	ped.position = Vector3(0, (CON_TOP_Y - 0.10) * 0.5, 0)
	ped.material_override = _con_mat(frame_color, 0.4, 0.6)
	console.add_child(ped)
	# Base foot.
	var foot := MeshInstance3D.new()
	var fcm := CylinderMesh.new()
	fcm.top_radius = 0.20; fcm.bottom_radius = 0.24
	fcm.height = 0.05; fcm.radial_segments = 20
	foot.mesh = fcm
	foot.position = Vector3(0, 0.025, 0)
	foot.material_override = _con_mat(frame_color.lightened(0.05), 0.5, 0.5)
	console.add_child(foot)

	# Angled desk top (the lectern surface the controls sit on).
	var desk := Node3D.new()
	desk.name = "DeskTop"
	desk.position = Vector3(0, CON_TOP_Y, 0.04)
	desk.rotation_degrees = Vector3(CON_TILT_DEG, 0, 0)
	console.add_child(desk)

	var slab := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(CON_W, 0.04, CON_D)
	slab.mesh = sbm
	slab.material_override = _con_mat(frame_color.lightened(0.08), 0.4, 0.55)
	desk.add_child(slab)
	# Emissive lip along the desk's front edge — "powered console".
	var lip := MeshInstance3D.new()
	var lbm := BoxMesh.new()
	lbm.size = Vector3(CON_W, 0.015, 0.015)
	lip.mesh = lbm
	lip.position = Vector3(0, 0.02, CON_D * 0.5)
	var lmat := _con_mat(accent_color, 0.2, 0.5)
	lmat.emission_enabled = true; lmat.emission = accent_color
	lmat.emission_energy_multiplier = 1.6
	lip.material_override = lmat
	_weave_mats.append(lmat)   # let it breathe with the rest of the machine
	desk.add_child(lip)

	# Controls + preview live on the desk surface (local space of `desk`).
	_build_console_controls(desk)
	_build_console_preview(desk)
	_build_console_labels(desk)


func _build_console_controls(desk: Node3D) -> void:
	# Surface is in the desk's local XY (Z+ toward player after the tilt). Buttons
	# and sliders lie flat on the top, slightly proud in +Y.
	var top_y: float = 0.03
	var row_z: float = -CON_D * 0.30          # back row (toward the loom)

	# GROUP  ◀ / ▶  with a row of cycle controls along the left.
	_make_arrow_pair(desk, Vector3(-CON_W * 0.32, top_y, row_z),
		func(): _cycle_group(-1), func(): _cycle_group(1), "GROUP")

	# PALETTE  ◀ / ▶
	_make_arrow_pair(desk, Vector3(CON_W * 0.10, top_y, row_z),
		func(): _cycle_palette(-1), func(): _cycle_palette(1), "PALETTE")

	# DENSITY slider (front-left) — 0.1 .. 0.95.
	_density_slider = _make_slider(desk, Vector3(-CON_W * 0.22, top_y, CON_D * 0.22),
		"DENSITY", 0.1, 0.95, density, func(n): _on_density(n))

	# SEED slider (front-right) — 0 .. SEED_MAX, integer-stepped, plus ◀ / ▶ nudge.
	_seed_slider = _make_slider(desk, Vector3(CON_W * 0.16, top_y, CON_D * 0.22),
		"SEED", 0.0, float(SEED_MAX), float(motif_seed), func(n): _on_seed(n))
	_make_arrow_pair(desk, Vector3(CON_W * 0.16, top_y, -CON_D * 0.02),
		func(): _nudge_seed(-1), func(): _nudge_seed(1), "")


func _build_console_preview(desk: Node3D) -> void:
	# A small lit quad (~0.3m) on the back of the desk showing the live pattern.
	var quad := MeshInstance3D.new()
	quad.name = "PreviewPlate"
	var qm := QuadMesh.new()
	qm.size = Vector2(0.30, 0.30)
	quad.mesh = qm
	# Stand it up slightly, facing the player, at the back of the desk.
	quad.position = Vector3(0, 0.18, -CON_D * 0.5 + 0.02)
	quad.rotation_degrees = Vector3(90.0 - CON_TILT_DEG * 0.0, 0, 0)  # face +Z/up toward player
	_preview_mat = StandardMaterial3D.new()
	_preview_mat.albedo_texture = _carpet_tex
	_preview_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_preview_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_preview_mat.roughness = 0.7
	# Self-lit so it reads as a freshly-rendered proof under any lighting.
	_preview_mat.emission_enabled = true
	_preview_mat.emission = Color(1, 1, 1)
	_preview_mat.emission_texture = _carpet_tex
	_preview_mat.emission_energy_multiplier = 0.6
	quad.material_override = _preview_mat
	desk.add_child(quad)
	# Bezel frame around the preview.
	var bez := MeshInstance3D.new()
	var bbm := BoxMesh.new()
	bbm.size = Vector3(0.34, 0.34, 0.012)
	bez.mesh = bbm
	bez.position = Vector3(0, 0.18, -CON_D * 0.5)
	bez.rotation_degrees = Vector3(90, 0, 0)
	bez.material_override = _con_mat(frame_color, 0.5, 0.5)
	desk.add_child(bez)


func _build_console_labels(desk: Node3D) -> void:
	_group_label = _con_label(desk, group.to_upper(),
		Vector3(-CON_W * 0.32, 0.05, -CON_D * 0.30 - 0.06), accent_color, 12)
	_palette_label = _con_label(desk, palette.to_upper(),
		Vector3(CON_W * 0.16, 0.05, -CON_D * 0.30 - 0.06), warp_color, 11)
	_seed_label = _con_label(desk, "SEED %d" % motif_seed,
		Vector3(CON_W * 0.16, 0.05, CON_D * 0.34), Color(0.85, 0.9, 0.95), 10)
	# Console title plate.
	_con_label(desk, "RE-PATTERN", Vector3(0, 0.05, -CON_D * 0.5 + 0.20),
		accent_color, 9)


# ── Console widget factories (guard every interactable; degrade gracefully) ──

func _make_arrow_pair(desk: Node3D, base: Vector3, on_prev: Callable,
		on_next: Callable, label_text: String) -> void:
	var dx: float = 0.085
	var prev := _spawn_button(desk, base + Vector3(-dx * 0.5, 0, 0),
		accent_color.darkened(0.2), on_prev)
	var nxt := _spawn_button(desk, base + Vector3(dx * 0.5, 0, 0),
		accent_color, on_next)
	# Glyph caps (◀ / ▶) — Label3D so they read even if the button is degraded.
	_con_label(desk, "<", base + Vector3(-dx * 0.5, 0.03, 0), Color(0.95, 0.95, 1.0), 14)
	_con_label(desk, ">", base + Vector3(dx * 0.5, 0.03, 0), Color(0.95, 0.95, 1.0), 14)
	if prev == null and nxt == null and label_text != "":
		# Both interactables failed — leave a static plate so the console still loads.
		pass


# Spawn a push_button laid flat on the desk top, wired to `cb`. Returns the node
# (or null if the scene failed to load — caller degrades to plain geometry).
func _spawn_button(desk: Node3D, pos: Vector3, color: Color, cb: Callable) -> Node:
	if PUSH_BUTTON == null:
		_con_stub(desk, pos, color)      # static cap so the spot isn't empty
		return null
	var btn: Node = PUSH_BUTTON.instantiate()
	if btn == null:
		_con_stub(desk, pos, color)
		return null
	btn.position = pos
	# push_button's local +Y is its press axis; the scene roots it lying down, so
	# placing it on the (tilted) desk top already orients the cap upward.
	btn.scale = Vector3(0.55, 0.55, 0.55)
	if btn.has_method("set"):
		btn.set("pressed_color", color)
		btn.set("released_color", color.darkened(0.45))
	desk.add_child(btn)
	_connect_btn(btn, cb)
	return btn


# Spawn a slider_horizontal on the desk, wired to `cb(normalized)`. Returns node
# or null (degrades to a static groove plate).
func _make_slider(desk: Node3D, pos: Vector3, pname: String, rng_min: float,
		rng_max: float, init_value: float, cb: Callable) -> Node:
	if SLIDER_H == null:
		_con_stub(desk, pos, frame_color.lightened(0.1))
		_con_label(desk, pname, pos + Vector3(0, 0.03, -0.05), Color(0.8, 0.8, 0.85), 9)
		return null
	var sl: Node = SLIDER_H.instantiate()
	if sl == null:
		_con_stub(desk, pos, frame_color.lightened(0.1))
		return null
	sl.position = pos
	sl.scale = Vector3(0.8, 0.8, 0.8)
	desk.add_child(sl)
	# Configure AFTER add_child so the slider's _ready has run and nodes exist.
	if sl.has_method("set_range"):
		sl.set_range(rng_min, rng_max)
	if sl.has_method("set_param_name"):
		sl.set_param_name(pname)
	if sl.has_method("set_normalized_value") and rng_max > rng_min:
		var norm: float = clampf((init_value - rng_min) / (rng_max - rng_min), 0.0, 1.0)
		sl.set_normalized_value(norm)
	if sl.has_signal("slider_moved"):
		sl.connect("slider_moved", func(_v): cb.call(_slider_norm(sl)))
	return sl


# Read a slider's 0..1 value, guarding the method.
func _slider_norm(sl: Node) -> float:
	if sl != null and is_instance_valid(sl) and sl.has_method("get_normalized_value"):
		return clampf(sl.get_normalized_value(), 0.0, 1.0)
	return 0.5


# Connect a push_button instance's inner area signal to `cb` (no-arg).
# push_button's inner InteractableAreaButton emits button_pressed(button).
func _connect_btn(btn: Node, cb: Callable) -> void:
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.connect("button_pressed", func(_b): cb.call())
	elif btn.has_signal("pressed"):
		btn.connect("pressed", cb)


# Static cap used when an interactable fails to load — keeps the console legible.
func _con_stub(desk: Node3D, pos: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022; cm.bottom_radius = 0.024; cm.height = 0.014
	mi.mesh = cm
	mi.position = pos
	mi.material_override = _con_mat(color, 0.4, 0.5)
	desk.add_child(mi)


func _con_label(desk: Node3D, text: String, pos: Vector3, color: Color, size: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0011
	lbl.font_size = size
	lbl.modulate = color
	lbl.position = pos
	lbl.rotation_degrees = Vector3(-90, 0, 0)   # lie flat-readable on the tilted desk
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	desk.add_child(lbl)
	return lbl


func _con_mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


# ── Console interactions → live re-render ────────────────────────────────

func _cycle_group(dir: int) -> void:
	_group_index = wrapi(_group_index + dir, 0, GROUP_NAMES.size())
	group = GROUP_NAMES[_group_index]
	if _group_label: _group_label.text = group.to_upper()
	_render_pattern()


func _cycle_palette(dir: int) -> void:
	_palette_index = wrapi(_palette_index + dir, 0, PALETTE_NAMES.size())
	palette = PALETTE_NAMES[_palette_index]
	if _palette_label: _palette_label.text = palette.to_upper()
	_render_pattern()


func _on_density(norm: float) -> void:
	density = clampf(lerpf(0.1, 0.95, norm), 0.1, 0.95)
	_render_pattern()


func _on_seed(norm: float) -> void:
	motif_seed = clampi(int(round(lerpf(0.0, float(SEED_MAX), norm))), 0, SEED_MAX)
	if _seed_label: _seed_label.text = "SEED %d" % motif_seed
	_render_pattern()


func _nudge_seed(dir: int) -> void:
	motif_seed = clampi(motif_seed + dir, 0, SEED_MAX)
	if _seed_label: _seed_label.text = "SEED %d" % motif_seed
	# Keep the SEED slider handle in step with the nudge.
	if _seed_slider != null and is_instance_valid(_seed_slider) \
			and _seed_slider.has_method("set_normalized_value"):
		_seed_slider.set_normalized_value(clampf(float(motif_seed) / float(SEED_MAX), 0.0, 1.0))
	_render_pattern()


# ═══════════════════════════════════════════════════════════════════════════
# COLOPHON — what the loom admits about where the pattern came from
# ═══════════════════════════════════════════════════════════════════════════
#
# A colophon is the tailpiece a printer puts on a book stating how the book was
# made, and a woven bolt carries the same thing on its selvage: the mill's mark
# and the colour chips. This loom's colophon is that claim one level down. The
# seventeen plane symmetry groups were enumerated in 1891 and there is no
# eighteenth — so a machine that "makes" p4m is running a catalogue entry, and
# how much of that it prints on the goods is the argument:
#
#   none      the cloth arrives seamless — pattern as invention
#   repeat    the lattice, everywhere, plus one block blown up — pattern as copy
#   symmetry  the operations themselves — pattern as rule
#   catalogue seventeen chips, one lit — pattern as lookup
#
# Everything below is appended: nothing above it moved, no draw order changed,
# and `none` executes not one line of it.

const COLOPHON_VALUES: PackedStringArray = ["none", "repeat", "symmetry", "catalogue"]
## Must match the canvas_size / tile_size handed to PatternSim in _render_pattern.
const COL_CANVAS: int = 256
const COL_TILE: int = 16
const COL_INK: Color = Color(0.97, 0.97, 0.99, 1.0)
const COL_RULE: Color = Color(0.30, 0.85, 0.95, 1.0)
const COL_MARK: Color = Color(1.00, 0.86, 0.25, 1.0)
const COL_DARK: Color = Color(0.06, 0.06, 0.08, 1.0)
const COL_BLANK: Color = Color(0.17, 0.18, 0.21, 1.0)


## An unknown word keeps the DEFAULT rather than crashing or inventing a fifth value —
## the same contract station_wall.upkeep uses, so a typo in a map token is inert.
func _norm_colophon(v: String) -> String:
	var s: String = v.strip_edges().to_lower()
	return s if COLOPHON_VALUES.has(s) else "none"


## Clipped fill, so a mark that runs off the canvas is trimmed instead of throwing.
func _ink(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var mx: int = img.get_width()
	var my: int = img.get_height()
	var x0: int = clampi(x, 0, mx)
	var y0: int = clampi(y, 0, my)
	var x1: int = clampi(x + w, 0, mx)
	var y1: int = clampi(y + h, 0, my)
	if x1 <= x0 or y1 <= y0:
		return
	img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), c)


func _print_colophon(img: Image) -> void:
	match colophon:
		"repeat":
			_print_repeat(img)
		"symmetry":
			_print_symmetry(img)
		"catalogue":
			_print_catalogue(img)


## The lattice, printed into the weave. One cell is COL_TILE px of a canvas that tiles
## across the whole bolt, so this lands on every repeat at once — the cloth stops being
## a metre of fabric and becomes one small square, copied.
func _print_repeat(img: Image) -> void:
	var cells: int = COL_CANVAS / COL_TILE
	for i in range(cells):
		var p: int = i * COL_TILE
		_ink(img, p, 0, 2, COL_CANVAS, COL_INK)
		_ink(img, 0, p, COL_CANVAS, 2, COL_INK)
	# The canvas edge — where the PRINTED IMAGE starts over, a coarser repeat than the
	# lattice — in accent, so the two scales of copying are told apart.
	_ink(img, 0, 0, 4, COL_CANVAS, COL_RULE)
	_ink(img, 0, 0, COL_CANVAS, 4, COL_RULE)
	_ink(img, COL_CANVAS - 4, 0, 4, COL_CANVAS, COL_RULE)
	_ink(img, 0, COL_CANVAS - 4, COL_CANVAS, 4, COL_RULE)


## A SCHEMATIC reading of the IUC name — not a proof. The leading digit is the highest
## rotation order, "m" means the cell carries mirrors, "g" a glide, and the centred,
## four- and six-fold groups also carry diagonal mirrors. Enough to draw the difference
## between p1 (translation and nothing else) and p6m (mirrors everywhere).
func _group_marks(g: String) -> Dictionary:
	var rot: int = 1
	for d in ["6", "4", "3", "2"]:
		if g.contains(str(d)):
			rot = int(str(d))
			break
	return {
		"rot": rot,
		"mirror": g.contains("m"),
		"glide": g.contains("g"),
		"diagonal": ["cm", "cmm", "p4m", "p4g", "p6m", "p3m1", "p31m"].has(g),
	}


## The operations, over the cloth. Every group gets its translation lattice; mirrors are
## solid bars, glides are dashed (a mirror you have to walk along), rotation centres are
## blocks sized by order. p1 shows the lattice alone, which is the honest picture of it.
func _print_symmetry(img: Image) -> void:
	var mk: Dictionary = _group_marks(group)
	var cells: int = COL_CANVAS / COL_TILE
	for j in range(cells + 1):
		for i in range(cells + 1):
			_ink(img, i * COL_TILE - 1, j * COL_TILE - 1, 3, 3, COL_RULE)
	if bool(mk["mirror"]):
		for i2 in range(cells):
			var p: int = i2 * COL_TILE
			_ink(img, p, 0, 3, COL_CANVAS, COL_MARK)
			_ink(img, 0, p, COL_CANVAS, 3, COL_MARK)
	if bool(mk["diagonal"]):
		var t: int = 0
		while t < COL_CANVAS:
			_ink(img, t, t, 3, 3, COL_MARK)
			_ink(img, t, COL_CANVAS - t - 3, 3, 3, COL_MARK)
			t += 2
	if bool(mk["glide"]):
		for i3 in range(cells):
			var q: int = i3 * COL_TILE + COL_TILE / 2
			var y: int = 0
			while y < COL_CANVAS:
				_ink(img, q, y, 3, 6, COL_INK)
				y += 12
	var order: int = int(mk["rot"])
	if order > 1:
		var s: int = 3 + order
		for j2 in range(cells + 1):
			for i4 in range(cells + 1):
				_ink(img, i4 * COL_TILE - s / 2, j2 * COL_TILE - s / 2, s, s, COL_INK)


## The selvage. Real woven cloth carries the mill's chips down both edges; this bolt
## carries the whole closed set — seventeen groups, sixteen dark, this one lit — so the
## goods say which entry of the list they are.
func _print_catalogue(img: Image) -> void:
	var idx: int = GROUP_NAMES.find(group)
	if idx < 0:
		idx = 10
	var n: int = GROUP_NAMES.size()
	var strip: int = 34
	var pitch: int = COL_CANVAS / n
	var left: int = 0
	var right: int = COL_CANVAS - strip
	_ink(img, left, 0, strip, COL_CANVAS, COL_DARK)
	_ink(img, right, 0, strip, COL_CANVAS, COL_DARK)
	for i in range(n):
		var y: int = i * pitch + 2
		var lit: bool = i == idx
		var c: Color = COL_RULE if lit else COL_BLANK
		_ink(img, left + 6, y, strip - 12, pitch - 4, c)
		_ink(img, right + 6, y, strip - 12, pitch - 4, c)
		if lit:
			_ink(img, left + 2, y - 3, strip - 4, 2, COL_INK)
			_ink(img, left + 2, y + pitch - 3, strip - 4, 2, COL_INK)
			_ink(img, right + 2, y - 3, strip - 4, 2, COL_INK)
			_ink(img, right + 2, y + pitch - 3, strip - 4, 2, COL_INK)
	_ink(img, strip, 0, 2, COL_CANVAS, COL_INK)
	_ink(img, COL_CANVAS - strip - 2, 0, 2, COL_CANVAS, COL_INK)


## The cloth is whichever child wears the wallpaper texture. Matched on the TEXTURE and
## not on _carpet_mat because _build_fountain never assigns _carpet_mat (see the bug
## note in the promotion report) and its rug would otherwise be invisible to this.
func _find_cloth() -> MeshInstance3D:
	if _carpet_tex == null:
		return null
	for c in get_children():
		if c is MeshInstance3D:
			var mi: MeshInstance3D = c as MeshInstance3D
			var mat: Material = mi.material_override
			if mat is StandardMaterial3D:
				var sm: StandardMaterial3D = mat as StandardMaterial3D
				if sm.albedo_texture == _carpet_tex:
					return mi
	return null


## The card at the feed: what the cloth is printed with, blown up where a standing player
## (and the capture camera, which sits off to +Z and 15 degrees up) can read it. Nearest-
## neighbour and unshaded so the block stays crisp under any lighting.
func _card_image() -> Image:
	var cfg := {
		"group": group, "palette": palette, "motif_seed": motif_seed,
		"tile_size": COL_TILE, "canvas_size": COL_CANVAS, "density": density,
	}
	var src: Image = PatternSim.render_to_image(cfg)
	var card: Image = Image.create(COL_CANVAS, COL_CANVAS, false, Image.FORMAT_RGBA8)
	card.fill(COL_DARK)
	if colophon == "catalogue":
		_card_catalogue(card, src)
	else:
		_card_block(card, src)
	return card


## Four lattice cells at 4x — the block the whole bolt is copies of. Upscaled by hand
## rather than by Image.get_region + resize, which was renamed under this project's feet.
func _card_block(card: Image, src: Image) -> void:
	var inset: int = 12
	var span: int = COL_CANVAS - inset * 2
	var block: int = COL_TILE * 4
	for y in range(span):
		var sy: int = clampi(int(float(y) / float(span) * float(block)), 0, COL_CANVAS - 1)
		for x in range(span):
			var sx: int = clampi(int(float(x) / float(span) * float(block)), 0, COL_CANVAS - 1)
			card.set_pixel(inset + x, inset + y, src.get_pixel(sx, sy))
	var pitch: int = span / 4
	if colophon == "symmetry":
		var mk: Dictionary = _group_marks(group)
		for i in range(5):
			var p: int = inset + i * pitch
			if bool(mk["mirror"]):
				_ink(card, p - 3, inset, 6, span, COL_MARK)
				_ink(card, inset, p - 3, span, 6, COL_MARK)
			_ink(card, p - 4, inset - 4, 8, 8, COL_RULE)
		if bool(mk["glide"]):
			for i2 in range(4):
				var q: int = inset + i2 * pitch + pitch / 2
				var y2: int = inset
				while y2 < inset + span:
					_ink(card, q - 2, y2, 5, 12, COL_INK)
					y2 += 24
		var order: int = int(mk["rot"])
		if order > 1:
			var s: int = 8 + order * 2
			for j in range(5):
				for i3 in range(5):
					_ink(card, inset + i3 * pitch - s / 2, inset + j * pitch - s / 2,
						s, s, COL_INK)
	else:
		# repeat: the same lattice the cloth carries, at readable size, with the two
		# lattice vectors laid out from the corner.
		for i4 in range(5):
			var p2: int = inset + i4 * pitch
			_ink(card, p2 - 2, inset, 4, span, COL_INK)
			_ink(card, inset, p2 - 2, span, 4, COL_INK)
		_ink(card, inset, inset, pitch, 9, COL_RULE)
		_ink(card, inset, inset, 9, pitch, COL_RULE)
		_ink(card, inset + pitch - 14, inset - 5, 14, 19, COL_RULE)
		_ink(card, inset - 5, inset + pitch - 14, 19, 14, COL_RULE)
	_ink(card, 0, 0, COL_CANVAS, 6, COL_RULE)
	_ink(card, 0, COL_CANVAS - 6, COL_CANVAS, 6, COL_RULE)
	_ink(card, 0, 0, 6, COL_CANVAS, COL_RULE)
	_ink(card, COL_CANVAS - 6, 0, 6, COL_CANVAS, COL_RULE)


## Seventeen chips: the whole plane-group catalogue, sixteen blanks and the one this
## machine is running, printed with the actual goods.
func _card_catalogue(card: Image, src: Image) -> void:
	var idx: int = GROUP_NAMES.find(group)
	if idx < 0:
		idx = 10
	var cols: int = 5
	var cw: int = 44
	var ch: int = 52
	var ox: int = 14
	var oy: int = 18
	for i in range(GROUP_NAMES.size()):
		var cx: int = ox + (i % cols) * (cw + 4)
		var cy: int = oy + (i / cols) * (ch + 6)
		if i == idx:
			_ink(card, cx - 4, cy - 4, cw + 8, ch + 8, COL_INK)
			for y in range(ch):
				var sy: int = clampi(int(float(y) / float(ch) * float(COL_TILE * 2)),
					0, COL_CANVAS - 1)
				for x in range(cw):
					var sx: int = clampi(int(float(x) / float(cw) * float(COL_TILE * 2)),
						0, COL_CANVAS - 1)
					card.set_pixel(cx + x, cy + y, src.get_pixel(sx, sy))
		else:
			_ink(card, cx, cy, cw, ch, COL_BLANK)
			_ink(card, cx, cy, cw, 3, Color(0.28, 0.29, 0.33, 1.0))
	_ink(card, 0, 0, COL_CANVAS, 6, COL_RULE)
	_ink(card, 0, COL_CANVAS - 6, COL_CANVAS, 6, COL_RULE)


## Stand the card at the OUTPUT end of the cloth, facing +Z and tilted back like a shade
## card on an easel. Derived from the cloth's own bounds, so every loom_style puts it
## where that machine's goods come out — the carpet's far edge, the banner's hem, the
## rug's rim — and never behind the frame where the camera cannot see it.
func _build_colophon_card() -> void:
	var cloth: MeshInstance3D = _find_cloth()
	var bounds: AABB = AABB(Vector3(-carpet_width * 0.5, 0.0, 0.0),
		Vector3(carpet_width, 0.02, carpet_length))
	if cloth != null and cloth.mesh != null:
		bounds = cloth.transform * cloth.mesh.get_aabb()
	var pw: float = clampf(bounds.size.x, 0.9, 1.6)
	var ph: float = pw * 0.7
	var cx: float = bounds.position.x + bounds.size.x * 0.5
	var front: float = bounds.position.z + bounds.size.z
	var base: float = bounds.position.y

	var tex: ImageTexture = ImageTexture.create_from_image(_card_image())
	var card: MeshInstance3D = MeshInstance3D.new()
	card.name = "ColophonCard"
	var pm: PlaneMesh = PlaneMesh.new()
	pm.size = Vector2(pw, ph)
	card.mesh = pm
	card.rotation_degrees = Vector3(78, 0, 0)
	card.position = Vector3(cx, base + ph * 0.48 + 0.04, front + 0.07)
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	card.material_override = m
	add_child(card)

	# Backing plate + two posts, so it reads as mounted stock and not a floating decal.
	var back: MeshInstance3D = _box(Vector3(pw + 0.06, 0.02, ph + 0.06), Vector3.ZERO,
		frame_color.darkened(0.3))
	back.rotation_degrees = card.rotation_degrees
	back.position = card.position + Vector3(0.0, -0.006, -0.022)
	_box(Vector3(0.035, ph * 0.5, 0.035),
		Vector3(cx - pw * 0.42, base + ph * 0.24, front + 0.09), frame_color)
	_box(Vector3(0.035, ph * 0.5, 0.035),
		Vector3(cx + pw * 0.42, base + ph * 0.24, front + 0.09), frame_color)


# ═══════════════════════════════════════════════════════════════════════════
# UPKEEP — which moment of its working life the machine is caught in
# ═══════════════════════════════════════════════════════════════════════════
#
# ADOPTED, NOT INVENTED. The word, the four values and the unknown-word contract come
# verbatim from station_wall.gd / station_pillar.gd / station_crates.gd, where `upkeep`
# already runs across seven pieces of the curation kit. A loom is the older machine in
# the same room and it should not need a private synonym: a bay whose walls read "packed
# down" cannot hold a loom that still reads "in commission".
#
# What the loom argues with it that a wall cannot. The colophon axis above is about the
# CLOTH — how much of a closed set of seventeen the goods admit to. This one is about the
# MACHINE, and it is the older argument: every textile in history came off a loom that was
# oiled, opened, stopped, sheeted and eventually broken up, and the default sci-fi machine
# here runs frictionlessly forever with nobody at it. `works`, `store` and `scrap` put the
# labour back.
#
#   service  in commission — the legacy lineage, byte for byte; not one line below runs
#   works    mid-job       — a trestle deck stood off the flank with tools on it, a conduit
#                            run over the head, the cover panel leaned against the frame
#   store    packed down   — a sheet strapped over the head and the run's output banded into
#                            finished bolts stacked on the floor beside it
#   scrap    robbed        — the flank cladding gone and the studs bared, the cover dropped
#                            flat on the floor, hazard tape crossed over the hole
#
# THE PIVOT IS THE HEAD, exactly as the lit seam is the pivot on station_wall. Every one of
# the six loom_style bodies puts its emissive accent rail and its weave bar at the top of
# the frame, and those are the brightest pixels the loom owns in any capture. `store` puts
# a sheet over precisely that, which is why it reads from across a room.
#
# THE CLOTH IS NEVER COVERED. The carpet / banner / bolt / rug is what the artifact teaches,
# so _machine_bounds() excludes every mesh carrying the wallpaper texture and the dressing
# is placed against the frame and on the floor beside the run. A packed-down loom still
# shows you p4m — as finished stock, which is what packed down means for a textile.
#
# Everything below is appended: nothing above it moved, no draw order changed, and
# `service` executes not one line of it.

const UPKEEPS: PackedStringArray = ["service", "works", "store", "scrap"]
const UPK_BOARD: Color = Color(0.55, 0.44, 0.28)   # scratch-board deck
const UPK_STEEL: Color = Color(0.42, 0.44, 0.48)   # trestle legs / bared studs
const UPK_SHEET: Color = Color(0.30, 0.31, 0.33)   # dust sheeting
const UPK_STRAP: Color = Color(0.86, 0.34, 0.11)   # safety-orange banding
const UPK_VOID: Color = Color(0.04, 0.04, 0.05)    # the dark where cladding was


## An unknown word keeps the DEFAULT rather than crashing or inventing a fifth moment —
## the same contract _norm_colophon and station_wall.upkeep use, so a typo in a map token
## is inert instead of silently re-dressing a placement.
func _norm_upkeep(v: String) -> String:
	var s: String = v.strip_edges().to_lower()
	return s if UPKEEPS.has(s) else "service"


## The built machine's extent, EXCLUDING anything wearing the wallpaper texture. Six
## loom_style bodies put their frame in six different places (a 1.2 m press, a 3 m upright,
## a wall header, a floor spout), so the dressing is measured off the frame rather than
## hardcoded against the roller. Called only when upkeep != "service".
func _machine_bounds() -> AABB:
	var acc: AABB = AABB()
	var got: bool = false
	for c in get_children():
		if not (c is MeshInstance3D):
			continue
		var mi: MeshInstance3D = c as MeshInstance3D
		if mi.mesh == null:
			continue
		var mat: Material = mi.material_override
		if _carpet_tex != null and mat is StandardMaterial3D:
			if (mat as StandardMaterial3D).albedo_texture == _carpet_tex:
				continue                          # the cloth — never dressed over
		var b: AABB = mi.transform * mi.mesh.get_aabb()
		if got:
			acc = acc.merge(b)
		else:
			acc = b
			got = true
	if not got:
		acc = AABB(Vector3(-carpet_width * 0.5, 0.0, -0.2), Vector3(carpet_width, 1.2, 0.5))
	return acc


## Where the dressing stands: the +X flank (the side the capture camera is on), pushed back
## along Z toward the machine's rear so it never lands on the carpet lane — and, when the
## interactive console is out, kept clear of the lectern that already occupies that flank.
## Returns [flank_x, centre_z, length_z, top_y].
func _upk_station(mb: AABB) -> Array:
	var fx: float = maxf(mb.position.x + mb.size.x, carpet_width * 0.5) + 0.10
	var dz: float = clampf(mb.size.z + 0.40, 0.55, 1.00)
	var cz: float = mb.position.z + mb.size.z * 0.30
	if interactive:
		cz = minf(cz, CON_FEED_Z - CON_D * 0.5 - dz * 0.5 - 0.06)
	return [fx, cz, dz, maxf(mb.position.y + mb.size.y, 0.55)]


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


## WORKS — the loom mid-job. A scratch-board deck on trestle legs stands off the flank at
## working height with tools laid on it, a conduit run crosses over the head, and the cover
## panel that came off the side is leaned against the frame. The deck is the silhouette
## change: a horizontal mass projecting 0.4 m into the room off a flank that had nothing.
func _upkeep_works(mb: AABB) -> void:
	var st: Array = _upk_station(mb)
	var fx: float = st[0]
	var cz: float = st[1]
	var dz: float = st[2]
	var top: float = st[3]

	var deck_y: float = 0.86
	_box(Vector3(0.42, 0.05, dz), Vector3(fx + 0.23, deck_y, cz), UPK_BOARD)
	for sz in [-1.0, 1.0]:
		var lz: float = cz + sz * dz * 0.36
		_box(Vector3(0.05, deck_y, 0.05), Vector3(fx + 0.07, deck_y * 0.5, lz), UPK_STEEL)
		_box(Vector3(0.05, deck_y, 0.05), Vector3(fx + 0.39, deck_y * 0.5, lz), UPK_STEEL)

	# Tools laid out on the deck — three small blocks, the sign that someone is coming back.
	_box(Vector3(0.22, 0.035, 0.05), Vector3(fx + 0.20, deck_y + 0.04, cz - dz * 0.24), UPK_STEEL.lightened(0.15))
	_box(Vector3(0.07, 0.05, 0.16), Vector3(fx + 0.30, deck_y + 0.05, cz + dz * 0.06), UPK_STRAP.darkened(0.15))
	_cyl(0.19, 0.022, Vector3(fx + 0.14, deck_y + 0.04, cz + dz * 0.28), UPK_STEEL).rotation_degrees = Vector3(90, 0, 0)

	# Conduit run over the head — the sign that the machine is opened, not merely parked.
	_cyl(dz + 0.80, 0.035, Vector3(fx + 0.06, top + 0.10, cz),
		accent_color.darkened(0.35)).rotation_degrees = Vector3(90, 0, 0)

	# The cover panel that came off, leaned against the frame.
	var lean: MeshInstance3D = _box(Vector3(0.03, 0.86, dz * 0.62),
		Vector3(fx + 0.13, 0.43, cz - dz * 0.04), UPK_STEEL.darkened(0.18))
	lean.rotation_degrees = Vector3(0, 0, -13)

	_upk_stencil("WORKS", Vector3(fx + 0.46, deck_y + 0.13, cz + dz * 0.34))


## STORE — packed down. A sheet is pulled over the head and strapped, which covers the accent
## rail and the weave bar together: the loom stops being a thing that glows and becomes a
## wrapped volume. The run's output is not deleted, it is FINISHED — banded into three bolts
## stacked on the floor at the flank, still carrying the wallpaper, because that is what
## packed down means for a textile.
func _upkeep_store(mb: AABB) -> void:
	var st: Array = _upk_station(mb)
	var fx: float = st[0]
	var cz: float = st[1]
	var top: float = st[3]

	var drape: float = 0.34
	var y0: float = maxf(top - drape, 0.10)
	var cx: float = mb.position.x + mb.size.x * 0.5
	var mz: float = mb.position.z + mb.size.z * 0.5
	var sx: float = maxf(mb.size.x, carpet_width) + 0.14
	var sz: float = maxf(mb.size.z, 0.30) + 0.14
	var sh: float = maxf(top - y0, 0.16) + 0.06

	_box(Vector3(sx, sh, sz), Vector3(cx, (y0 + top) * 0.5 + 0.03, mz), UPK_SHEET)
	for f in [0.24, 0.54, 0.84]:
		_box(Vector3(sx + 0.03, 0.045, sz + 0.03),
			Vector3(cx, y0 + sh * f, mz), UPK_STRAP)

	# Three finished bolts, banded and stood on end against the flank. Ranged along Z rather
	# than piled outward along X on purpose: the run already owns that depth, so the dressing
	# adds mass without widening the artifact's AABB and handing the sweep a re-frame to
	# measure instead of a change.
	var bl: float = minf(carpet_width, 1.05)
	var stack: Array[Vector3] = [
		Vector3(fx + 0.15, bl * 0.5, cz - 0.30),
		Vector3(fx + 0.15, bl * 0.5, cz),
		Vector3(fx + 0.15, bl * 0.5, cz + 0.30)]
	for p in stack:
		var roll: MeshInstance3D = _cyl(bl, 0.10, p, frame_color)
		roll.material_override = _make_carpet_material(1.0, 2.0)
		for by in [0.28, 0.74]:
			_cyl(0.045, 0.112, Vector3(p.x, bl * by, p.z), UPK_STRAP)

	_upk_stencil("PACKED", Vector3(fx + 0.30, bl + 0.14, cz))


## SCRAP — robbed. The flank cladding is gone and the studs it was hiding stand bare in the
## dark, the cover is lying flat on the floor where it was dropped, and two runs of hazard
## tape are crossed over the opening. The frame is still there; what was ON it is not.
func _upkeep_scrap(mb: AABB) -> void:
	var st: Array = _upk_station(mb)
	var fx: float = st[0]
	var cz: float = st[1]
	var dz: float = st[2]
	var top: float = st[3]

	var h: float = clampf(top - 0.12, 0.35, 1.15)
	var yc: float = 0.08 + h * 0.5
	_box(Vector3(0.03, h, dz), Vector3(fx + 0.02, yc, cz), UPK_VOID)

	var n: int = maxi(int(dz / 0.28), 2)
	for i in range(n + 1):
		var zz: float = cz - dz * 0.5 + dz * (float(i) / float(n))
		_box(Vector3(0.045, h, 0.045), Vector3(fx + 0.05, yc, zz), UPK_STEEL)

	# The cover, dropped flat on the floor in the lane beside the run — forward along Z, which
	# the artifact already occupies, rather than out along X, which it does not.
	var cover: MeshInstance3D = _box(Vector3(0.03, 0.46, dz * 0.80),
		Vector3(fx + 0.14, 0.03, cz + 0.85), UPK_STEEL.darkened(0.25))
	cover.rotation_degrees = Vector3(0, 12, 90)

	var tex: ImageTexture = _upk_tape_tex()
	_upk_tape_bar(Vector3(0.012, 0.075, dz * 1.04), Vector3(fx + 0.09, 0.08 + h * 0.34, cz),
		Vector3(10, 0, 0), tex)
	_upk_tape_bar(Vector3(0.012, 0.075, dz * 1.04), Vector3(fx + 0.09, 0.08 + h * 0.68, cz),
		Vector3(-10, 0, 0), tex)
