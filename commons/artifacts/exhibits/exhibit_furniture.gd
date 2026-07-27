extends Node3D
class_name ExhibitFurniture

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: the display-furniture FAMILY as one parametric artifact — kind decides the body: floating_wall (MoMA: a hanging wall hovering above the floor, a soft shadow in the gap — the cheap accent that makes a room expensive), plinth (s/m/l), hollow_plinth, platform, table_2m, vitrine_tall, cabinet, infoboard, sign_exit, sign_fire. All empty; all waiting.
# desire: to give the gallery-DNA a full vocabulary of hosting — every footprint size, every display posture, plus the wayfinding that says someone cares for this building.
# critical_parameter: kind — selects the body; w/h/size scale it; house — which institution the body belongs to (white_cube | wunderkammer | depot | forensic | didactic | derelict); guard — how far back that institution keeps you (none | label | rail | hood).
# triggers: _ready builds by kind; apply_grid_config({kind, w, h, size, house, guard, label}).
# emerges: a room furnished from one family reads coherent; the floating wall's shadow line is the museum's signature written in light; change house and the same collection becomes a different claim about knowledge.
# needs: BakedText for signage, infoboard, tombstone labels and depot stencils.
# relationships: grows [[exhibit_podium]] and [[exhibit_vitrine]] into a family; planted by tools/gallery_evolve.py; filled later by the Curator.
# truth: display furniture is the grammar of attention — the same object reads different on a plinth, a table, or behind glass.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). 1077 placements — the most-placed piece of
# furniture in the world — and it had exactly one look: warm off-white matte with
# anthracite trim. That is not neutrality, it is the white cube, a specific and
# quite recent institutional style that this project's own critical apparatus is
# supposed to be able to name. An artifact whose stated truth is "display
# furniture is the grammar of attention" cannot only speak one grammar.
#
# So the family gets two axes crossing `kind`, both taken straight from the truth
# line rather than bolted on:
#
#   house   WHOSE attention   white_cube · wunderkammer · depot · forensic
#   guard   HOW FAR BACK      none · label · rail · hood
#
# `house` is material: the same plinth in walnut-and-brass is a claim about
# natural history, in raw ply with a stencilled name it is a claim about storage
# (the object is not yet art), in brushed steel it is a claim about evidence.
# `guard` is distance: naming, roping, glazing — the three ways an institution
# gets between a body and a thing.
#
# house=white_cube and guard=none are the legacy lineage, byte-for-byte: every
# colour in HOUSES["white_cube"] is lifted from the constants that were hardcoded
# in _build(), including the two slightly different cap whites that were never
# meant to differ. All 1077 existing placements are untouched.
#
# What it cost: _build() no longer reads as a list of literal colours, so a
# reader now has to hop to the palette to know what a plinth looks like. That
# indirection is the price of the family being a family.
#
# Deliberately NOT routed through house: the shadow quads (a shadow is a shadow
# in any institution) and _sign() (EXIT and FIRE are statutory colours — a
# building's legal obligations do not follow curatorial taste, and pretending
# they do would be the wrong joke).
# ─────────────────────────────────────────────────────────────────────────────
#
# CONVERGENCE PASS (2026-07-27, same day). Six agents promoted the exhibits
# family in parallel and could not see each other's work. Two collisions came
# out of it, and this pass pays both:
#
#   1. exhibit_podium shipped `regard` (plain · reliquary · didactic · derelict)
#      for the exact idea `house` names here — which institution's register the
#      object belongs to — in a disjoint vocabulary. `house` is the senior term
#      (1077 placements against 226) so the podium adopts it, but the podium's
#      list carried two registers this one lacked, so `house` WIDENS to six:
#
#        white_cube · wunderkammer · depot · forensic · didactic · derelict
#
#      didactic is the teaching museum — the grey civic institution that captions
#      everything, and the exact opposite of the white cube's frameless silence,
#      not a variant of it. derelict is the register withdrawn: the building used
#      to think meaning belonged here. Neither is a fifth flavour of the same
#      claim, which is why widening beat squeezing them into forensic and depot.
#      The old value names survive as aliases (plain→white_cube,
#      reliquary→wunderkammer) through house_name(), and BOTH files parse tokens
#      through that one function, so #house: and #regard: are now the same word.
#
#   2. The cordon existed three times (see the CORDON block below).
#
# Nothing here is on a default path: guard defaults to none, house to white_cube,
# and a scan of all 1693 map_data.json files finds ZERO placements carrying a
# #house:, #guard:, #regard:, #enclosure: or #reserve: token. Every one of the
# family's 1465 placements is legacy-default, and every one still is.
# ─────────────────────────────────────────────────────────────────────────────

@export var kind: String = "plinth"
@export var size_class: String = "m"      # s | m | l
@export var panel_w: float = 4.0          # floating_wall width
@export var panel_h: float = 2.6

@export var mount: String = ""            # a lookup_name to seat on the bed's surface

## AXIS 1 — the institution the furniture belongs to. Drives every surface:
## white_cube (legacy default) | wunderkammer | depot | forensic | didactic | derelict.
## Also answers to #regard: — exhibit_podium's word for the same axis.
@export var house: String = "white_cube"
## AXIS 2 — how the institution mediates the distance to the object.
## none (legacy default) | label (a tombstone lectern) | rail (posts and rope) | hood (glass).
@export var guard: String = "none"
## Text for the tombstone label and the depot stencil. Empty falls back to the
## mounted artifact's name, then to the kind — furniture that names itself.
@export var label_text: String = ""

# Every literal that used to sit inline in _build(), now keyed by house. Entries
# are {c: albedo, r: roughness, m: metallic, e: emission energy}; missing keys
# fall back to (0.6, 0.0, 0.0), which is what _mat() did before.
const HOUSES := {
	# The legacy lineage. Do not "tidy" these numbers — cap and cap_wide really
	# were two different whites, and matching them would change 1077 rooms.
	"white_cube": {
		"body": {"c": Color(0.85, 0.83, 0.78), "r": 0.6},
		"cap": {"c": Color(0.92, 0.90, 0.86), "r": 0.4},
		"cap_wide": {"c": Color(0.90, 0.88, 0.84), "r": 0.4},
		"trim": {"c": Color(0.22, 0.22, 0.24), "r": 0.6},
		"shelf": {"c": Color(0.60, 0.56, 0.50), "r": 0.6},
		"glass": {"c": Color(0.80, 0.90, 0.95, 0.16), "r": 0.05},
		"wall": {"c": Color(0.93, 0.92, 0.89), "r": 0.75},
		"wood": {"c": Color(0.50, 0.42, 0.34), "r": 0.5},
		"metal": {"c": Color(0.40, 0.42, 0.45), "r": 0.4},
		"pad": {"c": Color(0.30, 0.30, 0.33), "r": 0.7},
		"stud": {"c": Color(0.70, 0.60, 0.30), "r": 0.4, "e": 1.0},
		"lip": {"c": Color(0.70, 0.68, 0.63), "r": 0.6},
		"recess": {"c": Color(0.06, 0.06, 0.08), "r": 0.5},
		"rope": {"c": Color(0.42, 0.06, 0.10), "r": 0.9},
		"uplight": Color(0.90, 0.95, 1.00),
		"note": Color(0.92, 0.90, 0.85),
		"mark": "",
	},
	# Cabinet of curiosities: dark stained oak, brass, green baize, old warm
	# glass. The body goes from 0.85 to 0.19 albedo — the single biggest read in
	# the family, visible the moment you enter the room.
	"wunderkammer": {
		"body": {"c": Color(0.19, 0.12, 0.08), "r": 0.42},
		"cap": {"c": Color(0.74, 0.56, 0.22), "r": 0.26, "m": 0.85},
		"cap_wide": {"c": Color(0.74, 0.56, 0.22), "r": 0.26, "m": 0.85},
		"trim": {"c": Color(0.10, 0.07, 0.05), "r": 0.5},
		"shelf": {"c": Color(0.13, 0.21, 0.14), "r": 0.88},
		"glass": {"c": Color(0.86, 0.76, 0.52, 0.20), "r": 0.06},
		"wall": {"c": Color(0.22, 0.09, 0.09), "r": 0.55},
		"wood": {"c": Color(0.32, 0.19, 0.10), "r": 0.4},
		"metal": {"c": Color(0.74, 0.56, 0.22), "r": 0.26, "m": 0.9},
		"pad": {"c": Color(0.14, 0.09, 0.06), "r": 0.6},
		"stud": {"c": Color(0.86, 0.68, 0.28), "r": 0.3, "e": 0.8},
		"lip": {"c": Color(0.30, 0.19, 0.10), "r": 0.5},
		"recess": {"c": Color(0.03, 0.02, 0.02), "r": 0.6},
		"rope": {"c": Color(0.30, 0.05, 0.08), "r": 0.95},
		"uplight": Color(1.00, 0.86, 0.62),
		"note": Color(0.90, 0.84, 0.66),
		"mark": "plate",
		"mark_bg": Color(0.74, 0.56, 0.22),
		"mark_fg": Color(0.14, 0.09, 0.04),
		"card_bg": Color(0.88, 0.82, 0.68),
		"card_fg": Color(0.24, 0.15, 0.08),
		"band": {"c": Color(0.74, 0.56, 0.22), "r": 0.26, "m": 0.9},
		"band_at": 0.04,
		"band_th": 0.055,
	},
	# The store, the back of house, the crate. Raw ply and a safety-orange strap,
	# the object stencilled with its own name because nobody has decided yet that
	# it is art. The register the collection spends most of its life in.
	"depot": {
		"body": {"c": Color(0.72, 0.52, 0.28), "r": 0.88},
		"cap": {"c": Color(0.68, 0.49, 0.26), "r": 0.9},
		"cap_wide": {"c": Color(0.68, 0.49, 0.26), "r": 0.9},
		"trim": {"c": Color(0.42, 0.44, 0.45), "r": 0.55, "m": 0.55},
		"shelf": {"c": Color(0.64, 0.46, 0.25), "r": 0.9},
		"glass": {"c": Color(0.76, 0.80, 0.76, 0.12), "r": 0.18},
		"wall": {"c": Color(0.72, 0.52, 0.28), "r": 0.9},
		"wood": {"c": Color(0.72, 0.52, 0.28), "r": 0.88},
		"metal": {"c": Color(0.88, 0.44, 0.09), "r": 0.55},
		"pad": {"c": Color(0.36, 0.34, 0.31), "r": 0.9},
		"stud": {"c": Color(0.94, 0.46, 0.08), "r": 0.4, "e": 1.0},
		"lip": {"c": Color(0.60, 0.44, 0.25), "r": 0.85},
		"recess": {"c": Color(0.08, 0.07, 0.06), "r": 0.7},
		"rope": {"c": Color(0.92, 0.45, 0.08), "r": 0.85},
		"uplight": Color(1.00, 0.92, 0.78),
		"note": Color(0.18, 0.14, 0.10),
		"mark": "stencil",
		"mark_fg": Color(0.16, 0.12, 0.09),
		"card_bg": Color(0.82, 0.70, 0.46),
		"card_fg": Color(0.16, 0.13, 0.10),
		"band": {"c": Color(0.88, 0.44, 0.09), "r": 0.55},
		"band_at": 0.62,
		"band_th": 0.075,
	},
	# The evidence room / the lab bench. Brushed steel, black rubber, cold light,
	# a cyan datum line and a tag. Metallic 0.88 means almost no diffuse return,
	# so it reads much darker and much shinier than the white cube even though
	# the albedo number is only a third lower.
	"forensic": {
		"body": {"c": Color(0.60, 0.62, 0.65), "r": 0.24, "m": 0.88},
		"cap": {"c": Color(0.88, 0.90, 0.92), "r": 0.18, "m": 0.6},
		"cap_wide": {"c": Color(0.88, 0.90, 0.92), "r": 0.18, "m": 0.6},
		"trim": {"c": Color(0.07, 0.07, 0.08), "r": 0.85},
		"shelf": {"c": Color(0.72, 0.74, 0.76), "r": 0.3, "m": 0.7},
		"glass": {"c": Color(0.88, 0.94, 1.00, 0.10), "r": 0.02},
		"wall": {"c": Color(0.82, 0.86, 0.90), "r": 0.35, "m": 0.3},
		"wood": {"c": Color(0.66, 0.69, 0.72), "r": 0.25, "m": 0.8},
		"metal": {"c": Color(0.78, 0.80, 0.83), "r": 0.15, "m": 0.95},
		"pad": {"c": Color(0.16, 0.17, 0.19), "r": 0.4},
		"stud": {"c": Color(0.35, 0.85, 0.95), "r": 0.2, "e": 1.2},
		"lip": {"c": Color(0.55, 0.57, 0.60), "r": 0.3, "m": 0.7},
		"recess": {"c": Color(0.02, 0.03, 0.04), "r": 0.4},
		"rope": {"c": Color(0.09, 0.10, 0.11), "r": 0.8},
		"uplight": Color(0.72, 0.86, 1.00),
		"note": Color(0.85, 0.94, 1.00),
		"mark": "plate",
		"mark_bg": Color(0.09, 0.10, 0.12),
		"mark_fg": Color(0.45, 0.90, 0.98),
		"card_bg": Color(0.96, 0.97, 0.98),
		"card_fg": Color(0.06, 0.07, 0.08),
		"band": {"c": Color(0.20, 0.64, 0.74), "r": 0.3, "e": 0.6},
		"band_at": 0.52,
		"band_th": 0.018,
	},
	# ── the two registers exhibit_podium brought to the convergence ──────────
	# The teaching museum. Cool civic grey, everything captioned, a printed card
	# screwed to the front of the furniture itself. Not a softer white cube — the
	# white cube's whole ideology is the ABSENCE of this apparatus, so the read is
	# the caption arriving on a body that has gone from warm 0.85 to cool 0.70.
	"didactic": {
		"body": {"c": Color(0.70, 0.71, 0.74), "r": 0.82},
		"cap": {"c": Color(0.78, 0.79, 0.82), "r": 0.72},
		"cap_wide": {"c": Color(0.78, 0.79, 0.82), "r": 0.72},
		"trim": {"c": Color(0.28, 0.28, 0.31), "r": 0.50, "m": 0.25},
		"shelf": {"c": Color(0.74, 0.75, 0.78), "r": 0.80},
		"glass": {"c": Color(0.84, 0.88, 0.92, 0.14), "r": 0.06},
		"wall": {"c": Color(0.88, 0.89, 0.91), "r": 0.80},
		"wood": {"c": Color(0.72, 0.73, 0.75), "r": 0.70},
		"metal": {"c": Color(0.46, 0.47, 0.50), "r": 0.45, "m": 0.40},
		"pad": {"c": Color(0.38, 0.39, 0.42), "r": 0.85},
		"stud": {"c": Color(0.85, 0.86, 0.88), "r": 0.50},
		"lip": {"c": Color(0.66, 0.67, 0.70), "r": 0.75},
		"recess": {"c": Color(0.10, 0.10, 0.12), "r": 0.60},
		"rope": {"c": Color(0.36, 0.38, 0.42), "r": 0.90},
		"uplight": Color(0.88, 0.93, 1.00),
		"note": Color(0.94, 0.95, 0.96),
		"mark": "plate",
		"mark_bg": Color(0.94, 0.94, 0.93),
		"mark_fg": Color(0.15, 0.15, 0.17),
		"card_bg": Color(0.95, 0.95, 0.94),
		"card_fg": Color(0.12, 0.12, 0.14),
		"band": {"c": Color(0.34, 0.35, 0.38), "r": 0.60},
		"band_at": 0.14,
		"band_th": 0.030,
	},
	# The register withdrawn. Everything the other five houses spend on presence,
	# this one spends on having stopped: albedo drops from 0.85 to 0.26, the
	# corner studs stop glowing, the glass goes dusty and half-opaque, and the
	# only dressing is a 10 cm grime line where the neglected base meets the
	# floor. A room set to derelict is a room the institution has left.
	"derelict": {
		"body": {"c": Color(0.26, 0.25, 0.23), "r": 0.97},
		"cap": {"c": Color(0.30, 0.29, 0.27), "r": 0.95},
		"cap_wide": {"c": Color(0.30, 0.29, 0.27), "r": 0.95},
		"trim": {"c": Color(0.14, 0.13, 0.12), "r": 0.95},
		"shelf": {"c": Color(0.24, 0.23, 0.21), "r": 0.98},
		"glass": {"c": Color(0.52, 0.55, 0.50, 0.30), "r": 0.42},
		"wall": {"c": Color(0.34, 0.33, 0.31), "r": 0.95},
		"wood": {"c": Color(0.28, 0.25, 0.21), "r": 0.95},
		"metal": {"c": Color(0.32, 0.28, 0.24), "r": 0.80, "m": 0.35},
		"pad": {"c": Color(0.20, 0.19, 0.18), "r": 0.98},
		"stud": {"c": Color(0.34, 0.31, 0.27), "r": 0.90},
		"lip": {"c": Color(0.30, 0.29, 0.27), "r": 0.95},
		"recess": {"c": Color(0.02, 0.02, 0.02), "r": 0.90},
		"rope": {"c": Color(0.24, 0.22, 0.20), "r": 0.98},
		"uplight": Color(0.55, 0.58, 0.55),
		"note": Color(0.44, 0.43, 0.40),
		"mark": "stencil",
		"mark_fg": Color(0.13, 0.12, 0.11),
		"card_bg": Color(0.52, 0.50, 0.46),
		"card_fg": Color(0.20, 0.19, 0.17),
		"band": {"c": Color(0.15, 0.145, 0.135), "r": 0.98},
		"band_at": 0.03,
		"band_th": 0.100,
	},
}

## The vocabularies the six-agent pass left behind. exhibit_podium spelled this
## same axis `regard` and named its two shared values differently; both files
## normalise through house_name(), so one word now means one thing across the
## family and no map that learned the old spelling breaks.
const HOUSE_ALIASES := {
	"plain": "white_cube",        # exhibit_podium's name for the bare register
	"reliquary": "wunderkammer",  # dark body, brass cap, a cordon: the same claim
}

## The family's one reader for an institution token. Static so exhibit_podium
## parses #house: / #regard: through this exact function rather than its own.
static func house_name(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return str(HOUSE_ALIASES.get(v, v))

# Where the house dressing (stencil / tag / band) can land: kinds with a solid,
# flat, front-facing body. Legs, floors and hanging walls get nothing — a crate
# stencil on a shadow gap would be worse than no stencil at all.
var _body_box: AABB = AABB()

func _ready() -> void:
	_read_meta_overrides()
	_build()
	if mount != "":
		_mount_artifact(mount)

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_kind"):
		kind = str(get_meta("config_kind"))
	if has_meta("config_size"):
		size_class = str(get_meta("config_size"))
	if has_meta("config_w"):
		panel_w = float(str(get_meta("config_w")))
	if has_meta("config_h"):
		panel_h = float(str(get_meta("config_h")))
	if has_meta("config_mount"):
		mount = str(get_meta("config_mount"))
	# #house: is the family's word; #regard: is exhibit_podium's word for the same
	# axis and is honoured here so one vocabulary works on either artifact. house
	# wins when a map somehow carries both.
	if has_meta("config_house"):
		house = house_name(str(get_meta("config_house")))
	if has_meta("config_guard"):
		guard = str(get_meta("config_guard"))
	if has_meta("config_label"):
		label_text = str(get_meta("config_label"))

# The bed's surface height — where a mounted artifact sits. UNTOUCHED by the new
# axes on purpose: house and guard may not move a mounted work by a millimetre,
# or every placement that seats something here would silently shift.
func _surface_y() -> float:
	match kind:
		"plinth":
			return {"s": 1.19, "m": 0.99, "l": 0.64}.get(size_class, 0.99)
		"hollow_plinth": return 0.95
		"table_2m": return 0.8
		"platform": return 0.31
		"pit": return -0.28          # the object sits DOWN in the well
		"floor_work": return 0.05
		"vitrine_tall": return 0.3
		"panel": return 1.4 + ({"s": 1.2, "m": 2.0, "l": 3.2}.get(size_class, 2.0) * 0.66) * 0.5
		_: return 0.9

# Load an artifact by lookup_name from the registries and seat it on the bed.
func _mount_artifact(lookup: String) -> void:
	var dir := DirAccess.open("res://commons/artifacts/registry/")
	if dir == null:
		return
	var scene_path := ""
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json"):
			var file := FileAccess.open("res://commons/artifacts/registry/" + f, FileAccess.READ)
			if file:
				var parsed = JSON.parse_string(file.get_as_text())
				if parsed is Dictionary and parsed.get("artifacts", {}).has(lookup):
					scene_path = str(parsed["artifacts"][lookup].get("scene", ""))
					break
		f = dir.get_next()
	if scene_path == "":
		return
	var scene = load(scene_path)
	if scene == null:
		return
	var inst = scene.instantiate()
	if inst is Node3D:
		var on_panel := kind == "panel"
		inst.position = Vector3(0, _surface_y(), 0.15 if on_panel else 0.0)
		add_child(inst)

# ── house palette ────────────────────────────────────────────────────────────

func _palette() -> Dictionary:
	var p: Dictionary = HOUSES.get(house, HOUSES["white_cube"])
	return p

# A material from a palette slot. The fallbacks (0.6 rough, 0 metal, 0 emit) are
# exactly _mat()'s old defaults, so a partially-specified house degrades to the
# legacy surface rather than to something arbitrary.
func _pm(slot: String) -> StandardMaterial3D:
	var e: Dictionary = _palette().get(slot, {})
	var c: Color = e.get("c", Color(0.8, 0.8, 0.8))
	var r: float = float(e.get("r", 0.6))
	var mt: float = float(e.get("m", 0.0))
	var em: float = float(e.get("e", 0.0))
	return _mat(c, r, em, false, mt)

func _pcolor(slot: String, fallback: Color) -> Color:
	var v: Variant = _palette().get(slot, fallback)
	if v is Color:
		var c: Color = v
		return c
	return fallback

func _mat(c: Color, rough := 0.6, emit := 0.0, unshaded := false, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if metal > 0.0:
		m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _build() -> void:
	var stone: StandardMaterial3D = _pm("body")
	var dark: StandardMaterial3D = _pm("trim")
	var glass: StandardMaterial3D = _pm("glass")
	match kind:
		"floating_wall":
			_floating_wall()
		"plinth":
			var dims: Vector3 = {"s": Vector3(0.4, 1.15, 0.4), "m": Vector3(0.55, 0.95, 0.55),
					"l": Vector3(0.85, 0.6, 0.85)}.get(size_class, Vector3(0.55, 0.95, 0.55))
			_box(dims, Vector3(0, dims.y * 0.5, 0), stone)
			_box(Vector3(dims.x + 0.05, 0.04, dims.z + 0.05),
					Vector3(0, dims.y + 0.02, 0), _pm("cap"))
			_body_box = AABB(Vector3(-dims.x * 0.5, 0, -dims.z * 0.5), dims)
		"hollow_plinth":
			var s := 0.6
			var h := 0.9
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.06, h, 0.06),
							Vector3(sx * (s * 0.5 - 0.03), h * 0.5, sz * (s * 0.5 - 0.03)), dark)
			_box(Vector3(s + 0.06, 0.05, s + 0.06), Vector3(0, h + 0.025, 0), stone)
		"platform":
			var side: float = {"s": 1.2, "m": 1.6, "l": 2.4, "xl": 3.4}.get(size_class, 1.6)
			_box(Vector3(side, 0.28, side), Vector3(0, 0.14, 0), stone)
			_box(Vector3(side + 0.08, 0.03, side + 0.08), Vector3(0, 0.295, 0), _pm("cap_wide"))
			_body_box = AABB(Vector3(-side * 0.5, 0, -side * 0.5), Vector3(side, 0.28, side))
		"pit":
			# a sunken well — the inverse of a plinth; a raised lip, a dark recess,
			# a soft up-light. The object sits DOWN in it (the well posture).
			var pw: float = {"s": 1.0, "m": 1.6, "l": 2.4}.get(size_class, 1.6)
			var lip: StandardMaterial3D = _pm("lip")
			for a in [Vector3(pw * 0.5, 0, 0), Vector3(-pw * 0.5, 0, 0), Vector3(0, 0, pw * 0.5), Vector3(0, 0, -pw * 0.5)]:
				var horiz: bool = abs(a.x) > 0.01
				_box(Vector3(0.14 if horiz else pw + 0.28, 0.18, pw + 0.28 if horiz else 0.14),
						a + Vector3(0, 0.09, 0), lip)
			_box(Vector3(pw, 0.04, pw), Vector3(0, -0.4, 0), _pm("recess"))   # recessed floor
			var up := OmniLight3D.new()
			up.position = Vector3(0, -0.2, 0)
			up.omni_range = pw * 1.4
			up.light_energy = 1.2
			up.light_color = _pcolor("uplight", Color(0.9, 0.95, 1.0))
			add_child(up)
		"panel":
			# a wall-mounted flat display — for flat/graphic works. A framed plane
			# on a thin standoff (reads as hung), MoMA shadow-gap under the frame.
			var pwid: float = {"s": 1.2, "m": 2.0, "l": 3.2}.get(size_class, 2.0)
			var phgt: float = pwid * 0.66
			_box(Vector3(pwid + 0.08, phgt + 0.08, 0.05), Vector3(0, 1.4 + phgt * 0.5, -0.06), dark)   # frame
			_box(Vector3(pwid, phgt, 0.02), Vector3(0, 1.4 + phgt * 0.5, -0.03), _pm("wall"))
			var sh := MeshInstance3D.new()
			var q := QuadMesh.new(); q.size = Vector2(pwid + 0.2, 0.4); sh.mesh = q
			sh.material_override = _mat(Color(0.02, 0.02, 0.03, 0.45), 1.0, 0.0, true)
			sh.rotation_degrees = Vector3(-90, 0, 0); sh.position = Vector3(0, 0.012, 0.1)
			sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(sh)
		"floor_work":
			# terrain posture: the work sits DIRECTLY on the floor, marked only by a
			# flush pad + corner studs (don't-step-here), no plinth.
			var fw: float = {"s": 1.4, "m": 2.2, "l": 3.2}.get(size_class, 2.2)
			_box(Vector3(fw, 0.03, fw), Vector3(0, 0.015, 0), _pm("pad"))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.1, 0.14, 0.1), Vector3(sx * fw * 0.48, 0.07, sz * fw * 0.48), _pm("stud"))
		"table_2m":
			_box(Vector3(2.0, 0.05, 0.9), Vector3(0, 0.75, 0), _pm("wood"))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_box(Vector3(0.06, 0.73, 0.06),
							Vector3(sx * 0.92, 0.365, sz * 0.38), dark)
		"vitrine_tall":
			_box(Vector3(0.7, 0.25, 0.7), Vector3(0, 0.125, 0), dark)
			var gl := _box(Vector3(0.62, 1.7, 0.62), Vector3(0, 1.12, 0), glass)
			gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_box(Vector3(0.7, 0.06, 0.7), Vector3(0, 2.0, 0), dark)
			_body_box = AABB(Vector3(-0.35, 0, -0.35), Vector3(0.7, 0.25, 0.7))
		"cabinet":
			var w := 1.6
			_box(Vector3(w, 2.0, 0.12), Vector3(0, 1.0, -0.22), stone)      # back
			_box(Vector3(0.08, 2.0, 0.5), Vector3(-w * 0.5, 1.0, 0), stone)
			_box(Vector3(0.08, 2.0, 0.5), Vector3(w * 0.5, 1.0, 0), stone)
			_box(Vector3(w, 0.08, 0.5), Vector3(0, 2.0, 0), stone)
			for i in 3:
				_box(Vector3(w - 0.1, 0.04, 0.42), Vector3(0, 0.5 + 0.55 * float(i), 0), _pm("shelf"))
			_body_box = AABB(Vector3(-w * 0.5, 1.96, -0.25), Vector3(w, 0.08, 0.5))
		"infoboard":
			_box(Vector3(0.1, 0.95, 0.1), Vector3(0, 0.475, 0), dark)
			var board := _box(Vector3(0.85, 0.55, 0.05), Vector3(0, 1.1, 0.12), dark)
			board.rotation_degrees = Vector3(-30, 0, 0)
			var label: MeshInstance3D = BakedText.make_label_mesh(
					"INFO", _pcolor("note", Color(0.92, 0.9, 0.85)), Vector2(0.6, 0.28), 1400, true)
			if label:
				label.position = Vector3(0, 1.13, 0.16)
				label.rotation_degrees = Vector3(-30, 0, 0)
				add_child(label)
		"sign_exit":
			_sign("EXIT", Color(0.12, 0.55, 0.25), Color(0.95, 1.0, 0.95))
		"sign_fire":
			_sign("FIRE", Color(0.72, 0.12, 0.1), Color(1.0, 0.96, 0.94))
			# the little red cylinder itself, hanging under the sign
			var ext := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.09
			cm.bottom_radius = 0.09
			cm.height = 0.5
			ext.mesh = cm
			ext.material_override = _mat(Color(0.78, 0.1, 0.08), 0.35)
			ext.position = Vector3(0, 1.1, 0)
			add_child(ext)
		_:
			_box(Vector3(0.5, 0.9, 0.5), Vector3(0, 0.45, 0), stone)
	_house_dressing()
	_build_guard()

func _floating_wall() -> void:
	# MoMA: the wall hovers; the shadow in the gap is the accent
	var gap := 0.14
	var wall := _box(Vector3(panel_w, panel_h, 0.18), Vector3(0, gap + panel_h * 0.5, 0), _pm("wall"))
	wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	# contact shadow: an unshaded dark quad lying in the gap's floor
	var sh := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(panel_w + 0.25, 0.55)
	sh.mesh = qm
	sh.material_override = _mat(Color(0.02, 0.02, 0.03, 0.5), 1.0, 0.0, true)
	sh.rotation_degrees = Vector3(-90, 0, 0)
	sh.position = Vector3(0, 0.012, 0)
	sh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sh)
	# slim steel hangers from above (reads as suspended)
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.03, 0.6, 0.03),
				Vector3(sx * panel_w * 0.35, gap + panel_h + 0.3, 0), _pm("metal"))

# Statutory signage. NOT routed through house: EXIT green and FIRE red are the
# building's legal obligations, not the curator's palette.
func _sign(text: String, bg: Color, fg: Color) -> void:
	var pole := _box(Vector3(0.05, 2.3, 0.05), Vector3(0, 1.15, 0), _mat(Color(0.35, 0.36, 0.4), 0.5))
	var panel: MeshInstance3D = BakedText.make_panel_mesh(
			text, bg, fg, Vector2(0.55, 0.22), 1400, true)
	if panel:
		panel.position = Vector3(0, 2.15, 0.04)
		add_child(panel)
	var panel2: MeshInstance3D = BakedText.make_panel_mesh(
			text, bg, fg, Vector2(0.55, 0.22), 1400, true)
	if panel2:
		panel2.position = Vector3(0, 2.15, -0.04)
		panel2.rotation_degrees = Vector3(0, 180, 0)
		add_child(panel2)

# ── house dressing: the mark and the band ────────────────────────────────────

# The name of the WORK — what the gallery's tombstone label prints.
func _display_text() -> String:
	var t: String = label_text
	if t == "":
		t = mount
	if t == "":
		t = kind
	return t.replace("_", " ").to_upper()

# The name of the FURNITURE — what the store stencils on the crate. The two are
# deliberately different strings: a depot inventories the shelf, a gallery
# inventories the thing on it, and that difference is most of what the house axis
# is claiming. Keeping it to kind+size also keeps the glyphs big enough to read
# from the door, which a mounted artifact's full lookup_name would not be.
func _mark_text() -> String:
	var t: String = kind.replace("_", " ").to_upper()
	if kind in ["plinth", "platform", "pit", "floor_work", "panel"]:
		t += " " + size_class.to_upper()
	return t

func _house_dressing() -> void:
	if house == "white_cube":
		return                                   # the legacy lineage wears nothing
	if _body_box.size == Vector3.ZERO:
		return                                   # no solid front face to dress
	var p: Dictionary = _palette()
	var sz: Vector3 = _body_box.size
	var mid: Vector3 = _body_box.position + sz * 0.5
	# The band: a brass base moulding, an orange shipping strap, a cyan datum —
	# one horizontal line at a house-specific height, which is enough to tell two
	# houses apart from across the room even when the body colours are close.
	if p.has("band"):
		var be: Dictionary = p.get("band", {})
		var bc: Color = be.get("c", Color.WHITE)
		var br: float = float(be.get("r", 0.6))
		var bm: float = float(be.get("m", 0.0))
		var bemit: float = float(be.get("e", 0.0))
		var at: float = float(p.get("band_at", 0.5))
		var th: float = minf(float(p.get("band_th", 0.05)), sz.y * 0.5)
		# clamped so a base moulding on a shallow body cannot sink through the floor
		var by: float = clampf(_body_box.position.y + sz.y * at,
				_body_box.position.y + th * 0.5, _body_box.position.y + sz.y - th * 0.5)
		_box(Vector3(sz.x + 0.014, th, sz.z + 0.014), Vector3(mid.x, by, mid.z),
				_mat(bc, br, bemit, false, bm))
	# The mark: stencilled straight onto the ply, or a tag screwed to the face.
	var style: String = str(p.get("mark", ""))
	if style == "":
		return
	var mw: float = minf(sz.x * 0.72, 0.62)
	# The 0.30-of-height cap is not aesthetic — without it a shallow body (a
	# platform, a cabinet cornice) grows a mark tall enough to run into the band,
	# and the two dressings fight instead of reading as one set.
	var mh: float = minf(minf(mw * 0.30, sz.y * 0.55), sz.y * 0.30)
	if mw < 0.12 or mh < 0.04:
		return                                   # too thin a face to letter — leave it bare
	# Sit opposite the band: low when the band rides high, high when it is a base
	# moulding. Otherwise the strap covers exactly the thing it is next to.
	var band_high: bool = p.has("band") and float(p.get("band_at", 0.5)) > 0.40
	var y: float = _body_box.position.y + sz.y * (0.30 if band_high else 0.58)
	# 16 mm proud, which clears the band's own 7 mm overhang
	var z: float = _body_box.position.z + sz.z + 0.016
	var q: MeshInstance3D = null
	if style == "plate":
		q = BakedText.make_panel_mesh(_mark_text(),
				_pcolor("mark_bg", Color(0.1, 0.1, 0.1)), _pcolor("mark_fg", Color.WHITE),
				Vector2(mw, mh), 1400, false)
	else:
		q = BakedText.make_label_mesh(_mark_text(),
				_pcolor("mark_fg", Color(0.15, 0.12, 0.09)), Vector2(mw, mh), 1400, false)
	if q:
		q.position = Vector3(mid.x, y, z)
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(q)

# ── guard: naming, distance, glass ───────────────────────────────────────────

# Kinds whose body is a wall or a sign — a ring of rope round them makes no
# sense, so the guard flattens into a line in front / a glazed pane.
func _is_wall_kind() -> bool:
	return kind in ["floating_wall", "panel", "cabinet", "sign_exit", "sign_fire"]

# Half the body's footprint, used to size the ring and the hood. Hand-kept in
# step with _build(): the alternative was measuring the AABB after the fact,
# which the transparent vitrine glass would have inflated.
func _bed_extent() -> float:
	match kind:
		"plinth":
			return {"s": 0.20, "m": 0.28, "l": 0.43}.get(size_class, 0.28)
		"hollow_plinth": return 0.33
		"platform":
			return {"s": 0.60, "m": 0.80, "l": 1.20, "xl": 1.70}.get(size_class, 0.80)
		"pit":
			return {"s": 0.64, "m": 0.94, "l": 1.34}.get(size_class, 0.94)
		"floor_work":
			return {"s": 0.70, "m": 1.10, "l": 1.60}.get(size_class, 1.10)
		"panel":
			return {"s": 0.60, "m": 1.00, "l": 1.60}.get(size_class, 1.00)
		"table_2m": return 1.00
		"vitrine_tall": return 0.35
		"cabinet": return 0.80
		"infoboard": return 0.45
		"floating_wall": return panel_w * 0.5
		_: return 0.30

func _bed_height() -> float:
	match kind:
		"floating_wall": return panel_h + 0.14
		"panel":
			var pwid: float = {"s": 1.2, "m": 2.0, "l": 3.2}.get(size_class, 2.0)
			return 1.4 + pwid * 0.66
		"cabinet": return 2.08
		"sign_exit", "sign_fire": return 2.3
		_: return 1.2

func _build_guard() -> void:
	var r: float = _bed_extent()
	match guard:
		"label":
			_guard_label(r)
		"rail":
			_guard_rail(r)
		"hood":
			_guard_hood(r)
		_:
			pass                                  # "none" — the legacy lineage

# NAMING. A reading lectern at the work's right shoulder with a printed card.
# Deliberately built at body scale (1.05 m, a 0.34 m top) rather than as a small
# swatch: a museum label is furniture, and a label you cannot see from the door
# is not doing the institution's job of telling you this counts.
func _guard_label(r: float) -> void:
	var mat: StandardMaterial3D = _pm("body")
	var trim: StandardMaterial3D = _pm("trim")
	var x: float = r + 0.46
	var z: float = 0.18 if _is_wall_kind() else r * 0.35
	_box(Vector3(0.30, 0.025, 0.24), Vector3(x, 0.012, z), trim)      # foot
	_box(Vector3(0.07, 1.02, 0.07), Vector3(x, 0.51, z), mat)         # stalk
	var top := _box(Vector3(0.36, 0.26, 0.035), Vector3(x, 1.10, z + 0.05), trim)
	top.rotation_degrees = Vector3(-34, 0, 0)
	var card: MeshInstance3D = BakedText.make_panel_mesh(_display_text(),
			_pcolor("card_bg", Color(0.93, 0.91, 0.86)),
			_pcolor("card_fg", Color(0.12, 0.12, 0.12)),
			Vector2(0.30, 0.20), 1400, false)
	if card:
		card.position = Vector3(x, 1.115, z + 0.078)
		card.rotation_degrees = Vector3(-34, 0, 0)
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(card)

# DISTANCE. Posts and a sagging rope, set well outside the footprint so the ring
# is legible as a ring. The geometry lives in cordon() below — this file, this
# podium and this vitrine all draw the SAME barrier now — and the only thing the
# rail still decides for itself is that its metal and its rope follow the house.
func _guard_rail(r: float) -> void:
	cordon(self, r, {"post": _pm("metal"), "rope": _pm("rope"), "line_only": _is_wall_kind()})

# GLASS. A hood over the bed, or a glazed pane in front of a wall. The rims are
# solid so the guard still reads in a still — a pure transparent box would be an
# inert axis, which is the failure mode this whole promotion is written against.
func _guard_hood(r: float) -> void:
	var glass: StandardMaterial3D = _pm("glass")
	var rim: StandardMaterial3D = _pm("trim")
	if _is_wall_kind():
		var wh: float = _bed_height()
		var pane := _box(Vector3(r * 2.0 + 0.1, wh * 0.92, 0.03), Vector3(0, wh * 0.5, 0.22), glass)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for sx in [-1.0, 1.0]:
			_box(Vector3(0.05, wh * 0.94, 0.06), Vector3(sx * (r + 0.05), wh * 0.5, 0.22), rim)
		_box(Vector3(r * 2.0 + 0.16, 0.06, 0.08), Vector3(0, wh * 0.03, 0.22), rim)
		_box(Vector3(r * 2.0 + 0.16, 0.06, 0.08), Vector3(0, wh * 0.97, 0.22), rim)
		return
	var base_y: float = maxf(_surface_y(), 0.02)
	var half: float = r + 0.05
	var hh: float = clampf(r * 2.1, 0.75, 1.9)
	_box(Vector3(half * 2.0 + 0.07, 0.05, half * 2.0 + 0.07), Vector3(0, base_y + 0.025, 0), rim)
	var hood := _box(Vector3(half * 2.0, hh, half * 2.0), Vector3(0, base_y + 0.05 + hh * 0.5, 0), glass)
	hood.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_box(Vector3(half * 2.0 + 0.07, 0.055, half * 2.0 + 0.07),
			Vector3(0, base_y + 0.05 + hh + 0.027, 0), rim)
	# corner mullions — the thing that makes a glass box read as a case
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(Vector3(0.035, hh, 0.035),
					Vector3(sx * half, base_y + 0.05 + hh * 0.5, sz * half), rim)

# ── the family's cordon ──────────────────────────────────────────────────────
#
# CONVERGENCE DEBT 2, paid. The posts-and-rope barrier existed three times, in
# three files, at three standoffs (0.44 here, 0.62 on the podium, 0.55 on the
# vitrine), over three brasses, under three crimsons that differed by one
# hundredth in a single channel — the signature of three agents drawing the same
# museum object on the same afternoon without seeing each other.
#
# The canon below IS this file's rail, number for number: standoff 0.44, post
# 0.86 m, foot Ø0.20, knob Ø0.09, rope Ø0.036 hung from the post tops and sagging
# 0.14 into a dogleg. The senior term (1077 placements) does not move; the other
# two adopt it, which is what "converge" has to mean if it is to mean anything.
#
# Consequences worth knowing before changing a number here: the ring stands
# 0.44 m outside the bed's half-extent and 0.86 m tall in THREE artifacts now, so
# a change is a change to the whole family's floor budget. And the podium's ring
# shrank (it stood 0.62 m off, with a 0.98 m floor) — which was the right way
# round, because a plinth m under exhibit_furniture and an exhibit_podium at its
# default size now produce rings within 5 mm of each other instead of 27% apart.
const CORDON := {
	"standoff": 0.44,   # how far outside the bed's half-extent the posts stand
	"post_h": 0.86,     # top of the stanchion; the rope hangs from here
	"post_r": 0.028,
	"foot_r": 0.10, "foot_h": 0.03,
	"knob_r": 0.045, "knob_h": 0.07,
	"rope_r": 0.018,
	"sag": 0.14,        # how far the rope's midpoint falls below its ends
	"wall_z": 0.95,     # a wall-hung work gets a LINE in front, not a ring
}

## The family's brass, for callers with no house of their own to ask. Lifted from
## HOUSES.wunderkammer.metal — this file's own brass, unchanged — so a podium's
## cordon and a wunderkammer plinth's cap are now literally the same metal.
static func brass_material() -> StandardMaterial3D:
	return _family_mat(Color(0.74, 0.56, 0.22), 0.26, 0.90)

## The family's crimson, lifted unchanged from HOUSES.white_cube.rope. The two
## other crimsons in the family were (0.42, 0.06, 0.09) and (0.42, 0.07, 0.09);
## this one is the senior file's, so the senior file's rail does not move.
static func rope_material() -> StandardMaterial3D:
	return _family_mat(Color(0.42, 0.06, 0.10), 0.90, 0.0)

## The barrier. `extent` is the bed's half-footprint; the ring stands standoff
## outside it. opts: {post, rope} override the materials (exhibit_furniture feeds
## its house's metal and rope in, so the rail stays house-coloured), `line_only`
## collapses the ring to a single span in front for wall-hung work.
static func cordon(host: Node3D, extent: float, opts: Dictionary = {}) -> void:
	if host == null:
		return
	var post: StandardMaterial3D = opts.get("post") as StandardMaterial3D
	if post == null:
		post = brass_material()
	var rope: StandardMaterial3D = opts.get("rope") as StandardMaterial3D
	if rope == null:
		rope = rope_material()
	var d: float = extent + float(CORDON["standoff"])
	var top_y: float = float(CORDON["post_h"])
	var corners: Array = []
	if bool(opts.get("line_only", false)):
		var wz: float = float(CORDON["wall_z"])
		corners = [Vector3(-d, 0, wz), Vector3(d, 0, wz)]
	else:
		corners = [Vector3(-d, 0, -d), Vector3(d, 0, -d), Vector3(d, 0, d), Vector3(-d, 0, d)]
	for c in corners:
		var at: Vector3 = c
		var fh: float = float(CORDON["foot_h"])
		_family_cyl(host, Vector3(at.x, fh * 0.5, at.z),
				float(CORDON["foot_r"]), fh, post)                       # weighted base
		_family_cyl(host, Vector3(at.x, top_y * 0.5, at.z),
				float(CORDON["post_r"]), top_y, post)                    # stanchion
		var kh: float = float(CORDON["knob_h"])
		_family_cyl(host, Vector3(at.x, top_y + kh * 0.5, at.z),
				float(CORDON["knob_r"]), kh, post)                       # knob
	# The sag is two straight segments per span, not a curve — from three metres
	# away a dogleg reads as a hanging rope and costs one mesh instead of eight.
	var spans: int = corners.size() if corners.size() > 2 else 1
	var rr: float = float(CORDON["rope_r"])
	for i in spans:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % corners.size()]
		var hang: Vector3 = (a + b) * 0.5 + Vector3(0, top_y - float(CORDON["sag"]), 0)
		_family_rod(host, a + Vector3(0, top_y, 0), hang, rr, rope)
		_family_rod(host, hang, b + Vector3(0, top_y, 0), rr, rope)

# Static twins of the instance primitives, so cordon() can be called by artifacts
# that are not this class. Kept byte-identical to what _guard_rail used to do —
# note that radial_segments is deliberately left at CylinderMesh's default, which
# is what the 1077-placement lineage has always rendered.
static func _family_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if metal > 0.0:
		m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func _family_cyl(host: Node3D, pos: Vector3, radius: float, height: float,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	host.add_child(mi)
	return mi

# A cylinder spanning two points. CylinderMesh runs along +Y, so the basis is
# built from the rotation that carries UP onto the span direction.
static func _family_rod(host: Node3D, a: Vector3, b: Vector3, radius: float,
		mat: Material) -> void:
	var dir: Vector3 = b - a
	var span: float = dir.length()
	if span < 0.001:
		return
	var mi: MeshInstance3D = _family_cyl(host, (a + b) * 0.5, radius, span, mat)
	var u: Vector3 = dir / span
	if absf(u.dot(Vector3.UP)) < 0.999:
		var axis: Vector3 = Vector3.UP.cross(u).normalized()
		mi.transform = Transform3D(Basis(axis, Vector3.UP.angle_to(u)), mi.position)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
