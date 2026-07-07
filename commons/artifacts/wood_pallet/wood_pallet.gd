extends Node3D
class_name WoodPallet

# @identity
# essence: a weathered wooden shipping pallet — the silvered-grey skeleton beneath every delivery. Three thin bottom boards, nine stacking blocks in a 3×3 grid, a top deck of seven slatted planks with gaps you can see daylight through. This is "Wood Pallet B", aged and sun-bleached, lighter and greyer than the warm crate it serves under. The pallet is the floor of the supply chain — the thing the crate STANDS ON, the layer between the cargo and the ground, the part a forklift's forks slide into. It is never the freight; it is what the freight rides.
# desire: every shipment pretends the goods arrived by themselves. The pallet refuses that fiction. It wants to be the PLATFORM, the load-bearer, the anonymous infrastructure that gets reused a thousand times and thanked never. It desires to be liftable — its whole geometry is an invitation to a forklift, a pump truck, a pair of hands. Even empty it implies a load; even alone it implies a warehouse.
# critical_parameter: top_board_count + block_style — 7 boards over 9 blocks reads as a proper Euro/EPAL block pallet (forkliftable from all four sides). Fewer boards over three stringer planks reads as a cheaper stringer pallet (forks from two sides only). pallet_width / pallet_depth set the standard: 1.2×0.8 = Euro; anything else = custom, one-off, non-poolable.
# triggers: _ready() builds bottom boards + middle blocks-or-stringers + top deck planks from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single empty pallet on a lab floor reads as JUST UNLOADED or ABOUT TO LOAD — the room is mid-logistics. A stack of pallets reads as STORAGE / RETURNS, the warehouse's quiet inventory of its own bones. A pallet UNDER a crate reads as CARGO AT REST, freight staged for the next leg. The gaps in the top deck are the pallet's honesty: it carries weight without pretending to be solid.
# needs: three thin bottom boards running along X [present]; nine stacking blocks in a 3×3 grid (or three stringer boards) [present]; seven gapped top-deck planks running along X [present]; weathered silver-grey wood material [present]; alternating plank tint for rhythm [present]
# relationships: peer to crate (both are SUPPLY-CHAIN VOCABULARY — the crate is the box, the pallet is what the box rides on; together they are a unit of freight); cousin to large_table (both are flat load-bearing platforms, but the table stages WORK and the pallet stages TRANSIT); structural cousin to ceiling_vent (both are utility-not-instrument, the unglamorous plumbing of a lab's lived logistics).
# truth: nothing in the lab arrived without a pallet under it. The pallet is the most reused, least regarded object in the supply chain — a wooden grid that exists only to be lifted, stacked, and lifted again. To place a pallet is to confess that the room is a NODE, not an origin; that goods pass through; that somewhere a forklift waits. The pallet is the grid made furniture: a lattice whose only purpose is to bear and be borne.

## A weathered wooden shipping pallet (block-pallet style, "Wood Pallet B").
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the pallet (floor-stack friendly): the base boards rest on the floor at
## Y≈0, the top deck surface sits at Y = pallet_height. Width = X, depth = Z.
## Default dimensions are a standard EPAL Euro block pallet: ~1.2m × 0.8m
## × 0.14m, aged to a silvered grey.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var pallet_width: float = 1.2
@export var pallet_depth: float = 0.8
@export var pallet_height: float = 0.14

@export_group("Construction")
## Number of planks across the top deck (running along X, spaced over Z).
@export var top_board_count: int = 7
## TRUE = nine stacking blocks in a 3×3 grid (block pallet, forkliftable
## from all four sides). FALSE = three stringer boards running along Z
## (stringer pallet, forks from two sides only).
@export var block_style: bool = true
## Show the three thin bottom boards at the base of the pallet.
@export var show_bottom_boards: bool = true

@export_group("Material")
## Weathered silver-grey-brown — aged, sun-bleached wood.
@export var plank_color: Color = Color(0.55, 0.52, 0.48)
## Slightly warmer/greyer alternate tint for plank rhythm.
@export var plank_color_alt: Color = Color(0.60, 0.57, 0.52)

# ── Constants ─────────────────────────────────────────────────────────

const BOARD_THICKNESS: float = 0.022          # thin board height (Y)
const BOTTOM_BOARD_DEPTH: float = 0.10        # bottom board size along Z
const BLOCK_SIZE_XZ: float = 0.10             # block footprint (X & Z)
const STRINGER_WIDTH: float = 0.10            # stringer board width (X)
const PLANK_GAP_FACTOR: float = 0.85          # plank fills this much of its slot
const LEAD_PLANK_WIDEN: float = 1.25          # front/back planks slightly wider

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_pallet_width"):
		pallet_width = float(str(get_meta("config_pallet_width")))
	if has_meta("config_pallet_depth"):
		pallet_depth = float(str(get_meta("config_pallet_depth")))
	if has_meta("config_pallet_height"):
		pallet_height = float(str(get_meta("config_pallet_height")))
	if has_meta("config_top_board_count"):
		top_board_count = int(str(get_meta("config_top_board_count")))
	if has_meta("config_block_style"):
		var s: String = str(get_meta("config_block_style")).to_lower()
		block_style = s == "true" or s == "1" or s == "yes"
	if has_meta("config_show_bottom_boards"):
		var s2: String = str(get_meta("config_show_bottom_boards")).to_lower()
		show_bottom_boards = s2 == "true" or s2 == "1" or s2 == "yes"
	if has_meta("config_plank_color"):
		plank_color = _parse_color(str(get_meta("config_plank_color")), plank_color)
	if has_meta("config_plank_color_alt"):
		plank_color_alt = _parse_color(str(get_meta("config_plank_color_alt")), plank_color_alt)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hw := pallet_width * 0.5
	var hd := pallet_depth * 0.5

	# Materials reused across the build — weathered, silvered wood.
	var mat_a := _make_wood_mat(plank_color)
	var mat_b := _make_wood_mat(plank_color_alt)

	# Vertical layout (Y):
	#   bottom boards centred at y0
	#   blocks / stringers sit ON the bottom boards
	#   top deck top surface lands at y = pallet_height
	var y_bottom: float = BOARD_THICKNESS * 0.5
	var block_h: float = pallet_height - BOARD_THICKNESS - BOARD_THICKNESS
	if block_h < 0.02:
		block_h = 0.02
	var y_block: float = BOARD_THICKNESS + block_h * 0.5
	var y_top: float = pallet_height - BOARD_THICKNESS * 0.5

	# X / Z positions for the 3×3 grid (and the bottom board / stringer rows).
	var x_positions := [-hw + BLOCK_SIZE_XZ * 0.5, 0.0, hw - BLOCK_SIZE_XZ * 0.5]
	var z_positions := [hd - BOTTOM_BOARD_DEPTH * 0.5, 0.0, -hd + BOTTOM_BOARD_DEPTH * 0.5]

	# ── 1. Bottom deck: three boards running along X ──────────────────
	if show_bottom_boards:
		var bi := 0
		for z in z_positions:
			_add_box("BottomBoard%d" % bi,
				Vector3(pallet_width, BOARD_THICKNESS, BOTTOM_BOARD_DEPTH),
				Vector3(0.0, y_bottom, z),
				mat_a if bi % 2 == 0 else mat_b)
			bi += 1

	# ── 2. Middle support: nine blocks (3×3) OR three stringers ───────
	if block_style:
		var idx := 0
		for x in x_positions:
			for z in z_positions:
				_add_box("Block_%d" % idx,
					Vector3(BLOCK_SIZE_XZ, block_h, BLOCK_SIZE_XZ),
					Vector3(x, y_block, z),
					mat_b if idx % 2 == 0 else mat_a)
				idx += 1
	else:
		# Three stringer boards running along Z at the three X positions.
		var si := 0
		for x in x_positions:
			_add_box("Stringer_%d" % si,
				Vector3(STRINGER_WIDTH, block_h, pallet_depth),
				Vector3(x, y_block, 0.0),
				mat_b if si % 2 == 0 else mat_a)
			si += 1

	# ── 3. Top deck: top_board_count planks running along X ───────────
	_build_top_deck(hd, y_top, mat_a, mat_b)


func _build_top_deck(hd: float, y_top: float,
		mat_a: StandardMaterial3D, mat_b: StandardMaterial3D) -> void:
	var n: int = maxi(2, top_board_count)
	# Divide the depth into n evenly spaced slots; each plank fills part of
	# its slot so visible gaps remain between boards.
	var slot: float = pallet_depth / float(n)
	var plank_depth: float = slot * PLANK_GAP_FACTOR
	for i in range(n):
		var is_lead: bool = (i == 0 or i == n - 1)
		var depth_i: float = plank_depth
		if is_lead:
			depth_i = plank_depth * LEAD_PLANK_WIDEN
		# Centre of slot i, measured from the +Z (front) edge inward.
		var z: float = hd - slot * (i + 0.5)
		_add_box("TopPlank%d" % i,
			Vector3(pallet_width, BOARD_THICKNESS, depth_i),
			Vector3(0.0, y_top, z),
			mat_a if i % 2 == 0 else mat_b)


func _make_wood_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	m.metallic = 0.0
	return m


# Build one box-shaped board/block and add it as a child.
func _add_box(box_name: String, size: Vector3, pos: Vector3,
		mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = box_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
