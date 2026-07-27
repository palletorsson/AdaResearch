extends Node3D
class_name StationCrates

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR supply stack of a curation station — a footprint_cells × footprint_cells (1 m per cell) cluster of stacked crates and canisters of varying size, with hazard labels, that fills a corner cell with the read of "stored, in transit, in use". Origin at the floor centre.
# desire: to give a clean staged room the lived-in counterweight of stuff — boxes that say work happens here, things arrive and are kept, this is a real facility and not a render.
# critical_parameter: crate_count + palette — how much clutter and what material (cardboard / wood / metal); the composer drops these into spare corner cells; upkeep — WHICH MOMENT of the bay's working life this corner is caught in (service | works | store | scrap), the shared axis with [[station_pillar]].
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds (deterministic per seed, no per-frame randomness).
# emerges: a tidy few reads "a delivery"; a tall stack reads "storage"; hazard labels + a canister read "lab supply". Sits inside one grid cell so it never breaks the layout.
# needs: 2-5 stacked boxes of varied size [present]; optional canister + hazard labels [present].
# relationships: the set-dressing sibling of [[station_cabinet]] (loose vs shelved storage); dropped into corners by [[curation_station]]; shares the HangarKit look with the packaging supply pile; KIN of [[station_pillar]] — the two halves of one `upkeep` vocabulary, the stuff and the structure telling the same time.
# truth: every presented place rests on an unpresented one. The crates are the back-of-house showing through — the honest clutter that makes the clean stage believable.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — the KIN PAIR axis, shared verbatim with
# station_pillar.gd. Read that file's block too; they are one promotion.
#
# The station kit could only ever render ONE moment: opening day. Every crate in
# the corpus is a freshly-delivered, correctly-stacked, lightly-dusted stack, and
# every pillar is a commissioned, powered, unscuffed column. That is a claim —
# that a facility exists only in the instant it is handed over — and it is exactly
# the claim these two artifacts' own truth lines contradict. The crates say
# "every presented place rests on an unpresented one". The pillar says "how it
# meets the floor is the proof that it was MEANT". Both are statements about the
# WORK behind the presentation, and neither could be varied.
#
#   upkeep   WHICH MOMENT of the working life   service · works · store · scrap
#
#   service  the bay in commission — the legacy lineage, byte for byte
#   works    the bay mid-job      — lid off, strapped, a tool tray, IN USE
#   store    the bay packed down  — one palletised bale, sheeted, banded, SEALED
#   scrap    the bay robbed       — flats leaning, a crate on its side, rust, tape
#
# Deliberately an ARRANGEMENT axis, not a grime slider: the kit already has
# `wear`, `dust` and `grime` and cranking those would have produced four tiles
# that differ only in albedo. Each value here changes the SILHOUETTE — the count
# of masses, their height, and where the brightest thing in the frame sits.
#
# What it cost: `_build()` no longer describes a single object, and two of the
# four values discard the seeded stack entirely, so `seed_index` stops meaning
# anything under `store`. That is honest — a bale has no scatter to seed — but it
# does mean two exports now silently do nothing on two of the four values.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Grid")
@export var footprint_cells: int = 1
@export_group("Content")
@export var crate_count: int = 4
## "cardboard" | "wood" | "metal".
@export var palette: String = "metal"
@export var hazard_labels: bool = true
@export var with_canister: bool = true
@export_group("Upkeep")
## THE AXIS (shared with station_pillar) — which moment of the bay's working life
## this corner is caught in. "service" is the legacy default and reproduces the
## old stack exactly. "works" dresses that same stack mid-job; "store" and "scrap"
## replace it with their own arrangement.
## service | works | store | scrap
@export var upkeep: String = "service"
@export_group("Surface")
@export var wear: float = 0.12
@export var seed_index: int = 0

const CELL := 1.0

var _built := false
var _rng := RandomNumberGenerator.new()
# Bookkeeping only — where the legacy loop actually put each crate, so the
# "works" dressing can find the top of the stack instead of guessing. Written
# during the build, never read by it.
var _stack: Array = []

func _ready() -> void:
	_read_metadata_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()

func _read_metadata_overrides() -> void:
	if has_meta("config_footprint_cells"): footprint_cells = int(str(get_meta("config_footprint_cells")))
	if has_meta("config_crate_count"): crate_count = int(str(get_meta("config_crate_count")))
	if has_meta("config_palette"): palette = str(get_meta("config_palette")).to_lower()
	if has_meta("config_hazard_labels"): hazard_labels = _b(get_meta("config_hazard_labels"))
	if has_meta("config_with_canister"): with_canister = _b(get_meta("config_with_canister"))
	if has_meta("config_upkeep"): upkeep = str(get_meta("config_upkeep")).to_lower()
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_seed_index"): seed_index = int(str(get_meta("config_seed_index")))

func _palette_color() -> Color:
	match palette:
		"cardboard": return Color(0.62, 0.50, 0.36)
		"wood": return Color(0.55, 0.42, 0.28)
		_: return Color(0.70, 0.70, 0.72)

func _build() -> void:
	_built = true
	_rng.seed = hash("station_crates_%d" % seed_index)
	var fc: float = float(maxi(footprint_cells, 1)) * CELL
	var base := _palette_color()
	var n: int = clampi(crate_count, 1, 6)
	var area: float = fc * 0.78

	# UPKEEP dispatch. "store" and "scrap" REPLACE the loose stack with their own
	# arrangement and return before it. "service" (the default) and "works" both
	# fall through to the legacy loop below, which is untouched — "works" only
	# dresses the result afterwards.
	if upkeep == "store":
		_upkeep_store(base, area)
		return
	if upkeep == "scrap":
		_upkeep_scrap(base, area, n)
		return
	_stack.clear()

	# A small floor cluster + a stacked column.
	var y := 0.0
	var col_x: float = -area * 0.18
	for i in range(n):
		var sz: float = _rng.randf_range(0.28, 0.42)
		var c := base.lightened(_rng.randf_range(-0.08, 0.08))
		var mat := HangarKit.painted_metal(c, wear, 0.2 if palette == "metal" else 0.0, 0.7) if palette == "metal" else _matte(c)
		var px: float = col_x + _rng.randf_range(-0.06, 0.06)
		var pz: float = _rng.randf_range(-area * 0.18, area * 0.18)
		add_child(_box(Vector3(px, y + sz * 0.5, pz), Vector3(sz, sz, sz), mat))
		_stack.append({"px": px, "pz": pz, "sz": sz, "y": y, "c": c})
		# a seam line + optional hazard label on the front
		add_child(_box(Vector3(px, y + sz * 0.5, pz + sz * 0.5 + 0.005), Vector3(sz * 0.9, 0.012, 0.01), HangarKit.worn_metal(c)))
		if hazard_labels and i % 2 == 0:
			var lab: MeshInstance3D = HangarKit.stencil("CARE", Vector2(sz * 0.6, sz * 0.22), Color(0.12, 0.12, 0.14))
			if lab:
				lab.position = Vector3(px, y + sz * 0.62, pz + sz * 0.5 + 0.012)
				add_child(lab)
		y += sz * (0.96 if i < 2 else 0.0)
		if i == 1:
			y = 0.0
			col_x = area * 0.2   # start a second short stack beside the first

	if with_canister:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.1
		cyl.bottom_radius = 0.1
		cyl.height = 0.5
		var mi := MeshInstance3D.new()
		mi.mesh = cyl
		mi.material_override = HangarKit.painted_metal(base.lightened(0.1), wear, 0.4, 0.5)
		mi.position = Vector3(area * 0.32, 0.25, -area * 0.2)
		add_child(mi)
		add_child(_box(Vector3(area * 0.32, 0.5, -area * 0.2), Vector3(0.12, 0.04, 0.12), HangarKit.worn_metal(base)))

	# The only line the legacy lineage does not reach: upkeep == "service" skips it.
	if upkeep == "works":
		_upkeep_works(base, area)


# ── UPKEEP ───────────────────────────────────────────────────────────────────
# One axis, four moments, shared word-for-word with station_pillar.gd. Each value
# is built out of HangarKit so the whole kit stays inside the cabinet grammar.

# The crate whose top face is highest — the one a lid comes off. Reads the
# bookkeeping the legacy loop leaves behind rather than re-deriving the RNG,
# which would be wrong the moment crate_count or seed_index changes.
func _top_crate() -> Dictionary:
	var best: Dictionary = {}
	var best_y: float = -1.0
	for e in _stack:
		var d: Dictionary = e
		var t: float = float(d["y"]) + float(d["sz"])
		if t > best_y:
			best_y = t
			best = d
	return best


# WORKS — the same delivery, caught mid-job. Purely additive on top of the legacy
# cluster: the top crate loses its lid (a dark mouth ringed by a rim, the lid
# itself leaning on the floor against the stack), the bottom crate wears a
# caution strap, a tool tray sits open on the floor and an IN USE patch is stuck
# on the front. The bright pale lid and the yellow strap are the point — they put
# the frame's hottest pixels somewhere the tidy stack never had them.
func _upkeep_works(base: Color, area: float) -> void:
	var top: Dictionary = _top_crate()
	if top.is_empty():
		return
	var px: float = float(top["px"])
	var pz: float = float(top["pz"])
	var sz: float = float(top["sz"])
	var ty: float = float(top["y"]) + sz
	var dark_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.06, 0.06, 0.07), 0.2, 0.05, 0.94)
	var rim: StandardMaterial3D = HangarKit.worn_metal(base)

	# The open mouth. It has to be built ON TOP of the crate, not sunk into it: the
	# legacy crate is a SOLID box, so a dark floor placed inside it would be
	# invisible from every angle. A raised rim with a dark pan just above the top
	# face reads as an opened crate and costs the legacy cube nothing.
	add_child(_box(Vector3(px, ty + 0.005, pz), Vector3(sz * 0.86, 0.012, sz * 0.86), dark_mat))
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var lip_c: Vector3 = Vector3(px, ty + 0.05, pz) + nrm * (sz * 0.5 - 0.024)
		var lip_s: Vector3 = Vector3(0.048, 0.10, sz) if absf(nrm.x) > 0.5 else Vector3(sz, 0.10, 0.048)
		add_child(_box(lip_c, lip_s, rim))

	# the lid, stood on the floor leaning back against the stack
	var ll: float = sz * 1.04
	# y is ll*0.49, not ll*0.5: the plate's lower edge lands ~4 mm ABOVE the floor.
	# Nothing in any variant may dip below y=0 — the grid auto-grounds an artifact
	# base-to-floor, so one buried corner would lift the whole cluster into the air.
	var lid_mat: StandardMaterial3D = HangarKit.rams_body(base.lightened(0.36), 0.03)
	add_child(_tilted(Vector3(px + 0.03, ll * 0.49, pz + sz * 0.5 + 0.10),
			Vector3(sz * 0.98, 0.034, ll), lid_mat, Vector3(68, 0, 0)))

	# a caution strap girdling the bottom crate
	var bot: Dictionary = _stack[0]
	var bx: float = float(bot["px"])
	var bz: float = float(bot["pz"])
	var bs: float = float(bot["sz"])
	var strap: StandardMaterial3D = HangarKit.striped_mat()
	for nrm2 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var sc: Vector3 = Vector3(bx, bs * 0.52, bz) + nrm2 * (bs * 0.5 + 0.006)
		var ss: Vector3 = Vector3(0.012, 0.058, bs * 0.98) if absf(nrm2.x) > 0.5 else Vector3(bs * 0.98, 0.058, 0.012)
		add_child(_box(sc, ss, strap))

	# an open tool tray on the floor, three tools in it
	var tray_mat: StandardMaterial3D = HangarKit.worn_metal(base.darkened(0.12))
	var tx: float = -area * 0.40
	var tz: float = area * 0.34
	add_child(_box(Vector3(tx, 0.014, tz), Vector3(0.30, 0.026, 0.20), tray_mat))
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(tx + sx * 0.148, 0.043, tz), Vector3(0.014, 0.058, 0.20), tray_mat))
		add_child(_box(Vector3(tx, 0.043, tz + sx * 0.098), Vector3(0.30, 0.058, 0.014), tray_mat))
	for i in range(3):
		add_child(_box(Vector3(tx - 0.09 + float(i) * 0.09, 0.046, tz - 0.02 + float(i) * 0.02),
				Vector3(0.022, 0.022, 0.13), HangarKit.worn_metal(Color(0.22, 0.22, 0.24))))

	# the state, printed where CARE used to be the only word on the stack
	var tag: MeshInstance3D = HangarKit.brand_patch("IN USE", Vector2(minf(bs * 0.78, 0.30), 0.072),
			Color(0.95, 0.75, 0.05), Color(0.10, 0.10, 0.12))
	if tag:
		tag.position = Vector3(bx, bs * 0.24, bz + bs * 0.5 + 0.014)
		add_child(tag)


# STORE — the bay packed down. The scatter is gone: one palletised bale, sheeted
# in pale wrap, banded with two straps over the top, corner-protected and sealed.
# The single biggest silhouette move in the family — four small grey cubes become
# one tall bright block, so it is legible from the door and unmistakable in a still.
func _upkeep_store(base: Color, area: float) -> void:
	var w: float = clampf(area * 0.86, 0.30, 0.88)
	var d: float = clampf(area * 0.78, 0.28, 0.80)
	# 0.108 is not arbitrary: bearers 0 -> 0.056, slats 0.056 -> 0.108, so the bale
	# sits ON the deck with no gap and the lowest point of the whole piece is 0.
	var deck_y: float = 0.108
	var bale_h: float = 0.58

	# pallet: three bearers under a slatted deck
	var timber: StandardMaterial3D = HangarKit.rams_body(Color(0.52, 0.40, 0.26), 0.45)
	for i in range(3):
		var bx: float = (float(i) - 1.0) * (w * 0.36)
		add_child(_box(Vector3(bx, 0.028, 0.0), Vector3(0.10, 0.056, d), timber))
	for i in range(4):
		var sz2: float = -d * 0.5 + d * (float(i) + 0.5) / 4.0
		add_child(_box(Vector3(0.0, deck_y - 0.026, sz2), Vector3(w, 0.052, d * 0.19), timber))

	# the sheeted bale
	var sheet: StandardMaterial3D = HangarKit.painted_metal(base.lightened(0.44), 0.02, 0.0, 0.40)
	var cy: float = deck_y + bale_h * 0.5
	add_child(_box(Vector3(0, cy, 0), Vector3(w, bale_h, d), sheet))
	# gathered folds down the front — three thin ridges, so the wrap does not read as a box
	for i in range(3):
		var fx: float = (float(i) - 1.0) * (w * 0.26)
		add_child(_box(Vector3(fx, cy, d * 0.5 + 0.007), Vector3(0.018, bale_h * 0.92, 0.014), sheet))

	# two straps over the top, one ring round the waist
	var band: StandardMaterial3D = HangarKit.worn_metal(Color(0.15, 0.14, 0.13))
	for sx in [-1.0, 1.0]:
		var ox: float = float(sx) * w * 0.26
		add_child(_box(Vector3(ox, cy, d * 0.5 + 0.010), Vector3(0.042, bale_h, 0.012), band))
		add_child(_box(Vector3(ox, cy, -d * 0.5 - 0.010), Vector3(0.042, bale_h, 0.012), band))
		add_child(_box(Vector3(ox, deck_y + bale_h + 0.008, 0.0), Vector3(0.042, 0.012, d), band))
	for nrm in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var rc: Vector3 = Vector3(0, deck_y + bale_h * 0.30, 0) + nrm * (Vector3(w, 0, d) * 0.5 + Vector3(0.010, 0, 0.010))
		var rs: Vector3 = Vector3(0.012, 0.034, d) if absf(nrm.x) > 0.5 else Vector3(w, 0.034, 0.012)
		add_child(_box(rc, rs, band))

	# corner protectors on the top edge
	for sx2 in [-1.0, 1.0]:
		for sz3 in [-1.0, 1.0]:
			add_child(_box(Vector3(sx2 * (w * 0.5 - 0.035), deck_y + bale_h - 0.035, sz3 * (d * 0.5 - 0.035)),
					Vector3(0.075, 0.075, 0.075), HangarKit.worn_metal(base.darkened(0.24))))

	# the seal, and the dust line where the pallet meets the floor
	var seal: MeshInstance3D = HangarKit.brand_patch("SEALED", Vector2(minf(w * 0.56, 0.32), 0.082),
			HangarKit.BRAUN_ACCENT, Color(0.98, 0.96, 0.92))
	if seal:
		seal.position = Vector3(0, deck_y + bale_h * 0.64, d * 0.5 + 0.018)
		add_child(seal)
	var gb: MeshInstance3D = HangarKit.grime_band(w * 0.92, 0.05, d * 0.5 + 0.006, base)
	if gb:
		add_child(gb)


# SCRAP — the bay robbed. Nothing stacks any more: the crates have been emptied
# and knocked down to flats leaning in the corner, one is on its side with its
# mouth open, one is crushed, the canister is on the floor. Torn barrier tape
# gives the variant its own bright signature, so the difference from "service" is
# a relocation of the frame's highlights and not merely a darkening.
func _upkeep_scrap(base: Color, area: float, n: int) -> void:
	var dull: StandardMaterial3D = HangarKit.painted_metal(base.darkened(0.32), 0.78, 0.10, 0.92)
	var rust: StandardMaterial3D = HangarKit.painted_metal(Color(0.38, 0.19, 0.09), 0.55, 0.15, 0.94)
	var dark_mat: StandardMaterial3D = HangarKit.painted_metal(Color(0.05, 0.05, 0.06), 0.2, 0.05, 0.95)

	# knocked-down flats leaning in the corner
	var flats: int = clampi(n - 1, 2, 4)
	for i in range(flats):
		var t: float = float(i) / float(maxi(flats - 1, 1))
		var fl: float = 0.40
		add_child(_tilted(Vector3(-area * 0.30 + t * 0.34, fl * 0.50, -area * 0.30 + t * 0.045),
				Vector3(0.42, 0.026, fl), dull if i % 2 == 0 else rust, Vector3(-72.0 + t * 5.0, 8.0 * t, 0)))

	# a crate on its side, mouth open toward the viewer
	var cs: float = 0.36
	var ox2: float = area * 0.24
	var oz2: float = area * 0.14
	var oy: float = cs * 0.5
	add_child(_box(Vector3(ox2, 0.011, oz2), Vector3(cs, 0.022, cs), dull))                       # down face
	add_child(_box(Vector3(ox2, cs - 0.011, oz2), Vector3(cs, 0.022, cs), dull))                  # up face
	for sx in [-1.0, 1.0]:
		add_child(_box(Vector3(ox2 + sx * (cs * 0.5 - 0.011), oy, oz2), Vector3(0.022, cs, cs), dull))
	add_child(_box(Vector3(ox2, oy, oz2 - cs * 0.5 + 0.011), Vector3(cs, cs, 0.022), dark_mat))   # dark back

	# a crushed one, shoved aside
	add_child(_tilted(Vector3(-area * 0.22, 0.078, area * 0.30), Vector3(0.36, 0.11, 0.34), dull,
			Vector3(0, 14.0, 6.0)))

	# the canister down on the floor
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.1
	cyl.height = 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.material_override = rust
	mi.position = Vector3(area * 0.10, 0.10, -area * 0.34)
	mi.rotation_degrees = Vector3(90, 22, 0)
	add_child(mi)

	# torn barrier tape — one length across the flats, one trailing on the floor
	var tape: StandardMaterial3D = HangarKit.striped_mat(Color(0.92, 0.72, 0.06), Color(0.14, 0.13, 0.12))
	add_child(_tilted(Vector3(-area * 0.10, 0.28, -area * 0.16), Vector3(0.62, 0.052, 0.008), tape,
			Vector3(0, 16.0, -13.0)))
	add_child(_tilted(Vector3(area * 0.02, 0.006, area * 0.26), Vector3(0.46, 0.006, 0.052), tape,
			Vector3(0, 34.0, 0)))

	# rust bloom on the floor, and the state named once
	var gb2: MeshInstance3D = HangarKit.grime_band(area * 1.10, 0.085, area * 0.42, Color(0.34, 0.17, 0.08))
	if gb2:
		add_child(gb2)
	var mark: MeshInstance3D = HangarKit.stencil("SCRAP", Vector2(0.20, 0.058), Color(0.46, 0.22, 0.10))
	if mark:
		mark.position = Vector3(ox2, cs * 0.72, oz2 + cs * 0.5 + 0.014)
		add_child(mark)


func _tilted(center: Vector3, size: Vector3, mat: Material, rot_deg: Vector3) -> MeshInstance3D:
	var mi: MeshInstance3D = _box(center, size, mat)
	mi.rotation_degrees = rot_deg
	return mi


func _matte(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)

func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi

func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]
