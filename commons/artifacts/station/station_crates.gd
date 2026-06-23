extends Node3D
class_name StationCrates

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR supply stack of a curation station — a footprint_cells × footprint_cells (1 m per cell) cluster of stacked crates and canisters of varying size, with hazard labels, that fills a corner cell with the read of "stored, in transit, in use". Origin at the floor centre.
# desire: to give a clean staged room the lived-in counterweight of stuff — boxes that say work happens here, things arrive and are kept, this is a real facility and not a render.
# critical_parameter: crate_count + palette — how much clutter and what material (cardboard / wood / metal); the composer drops these into spare corner cells.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds (deterministic per seed, no per-frame randomness).
# emerges: a tidy few reads "a delivery"; a tall stack reads "storage"; hazard labels + a canister read "lab supply". Sits inside one grid cell so it never breaks the layout.
# needs: 2-5 stacked boxes of varied size [present]; optional canister + hazard labels [present].
# relationships: the set-dressing sibling of [[station_cabinet]] (loose vs shelved storage); dropped into corners by [[curation_station]]; shares the HangarKit look with the packaging supply pile.
# truth: every presented place rests on an unpresented one. The crates are the back-of-house showing through — the honest clutter that makes the clean stage believable.

@export_group("Grid")
@export var footprint_cells: int = 1
@export_group("Content")
@export var crate_count: int = 4
## "cardboard" | "wood" | "metal".
@export var palette: String = "metal"
@export var hazard_labels: bool = true
@export var with_canister: bool = true
@export_group("Surface")
@export var wear: float = 0.12
@export var seed_index: int = 0

const CELL := 1.0

var _built := false
var _rng := RandomNumberGenerator.new()

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
