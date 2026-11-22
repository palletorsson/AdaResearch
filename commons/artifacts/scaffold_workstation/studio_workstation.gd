extends Node3D
## Bauhaus Architectural Studio Workstation (Unified Mini Interface + 1:4 Glass Box + VR Visor).
## Connects the workstation visually and narratively to the rest of the Void Tower:
## - Matte-black & off-white Bauhaus shell matching Floor 13 Trans_Pre & F209 stock plinths.
## - Flat near-edge hand-principle template strip (NO floating overhead arc):
##     point + trigger picks one building block -> point on mini grid + trigger stamps the template.
## - Expanded 20 m x 14 m x 6 m grid domain at 1:16 tabletop scale (6.25 cm per 1 m cell)
##   mirrored LIVE at 1:4 scale inside the 6.6 m glass box so wearing the VR Visor steps into
##   a 1:1 full-size playground matching Trans_Pre (20.4 x 12.5 m) and motion/revolving (19 x 14 m).
## - Stages the evolving humanoid playground architect (WorkerBeing) beside the console to embody
##   the tower's General Intellect story as capabilities unlock floor by floor.

const Model = preload("model.gd")
const Bauhaus = preload("bauhaus_kit.gd")
const Furniture = preload("shop_furniture.gd")
const Kit = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const PrefabPiece = preload("prefab_piece.gd")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")
const WorkerBeingScript = preload("res://commons/artifacts/worker_being/worker_being.gd")
const WorkerAssemblageScript = preload("res://commons/artifacts/worker_assemblage/worker_assemblage.gd")
const Layer = preload("res://commons/artifacts/scaffold_workstation/playground_layer.gd")

const DOMAIN_MIN := Vector3(-5.0, 0.0, -3.5)   # 20 m wide (-10..+10), 14 m deep (-7..+7), 6 m tall (0..6)
const DOMAIN_MAX := Vector3(5.0, 3.0, 3.5)
const MINI_UNIT := 0.125                     # 1:16 tabletop scale: 2 m module = 12.5 cm, 1 m cell = 6.25 cm
const PAD_ORIGIN := Vector3(-0.24, 1.015, -0.12)
const GLASS_OFFSET := Vector3(0.0, 0.0, -0.60)
const STUDIO_START := Vector3(0.0, 0.025, 2.35)
const STUDIO_SCALE := 0.25                   # 1:4 glass box & VR visor -> 20 m x 14 m feels 1:1 inside!
const AIM_REACH := 3.6
const NEAR_CONSOLE := 3.8

## Strict progression ladder on the flat near-edge template strip (never shuffles between floors).
const TEMPLATE_TILES := [
	{"id": "point", "label": "POINT", "tier": 0, "prefab": false, "floor": 1},
	{"id": "rod_short", "label": "1M ROD", "tier": 1, "prefab": false, "floor": 3},
	{"id": "rod", "label": "2M ROD", "tier": 1, "prefab": false, "floor": 3},
	{"id": "panel", "label": "TRIANGLE", "tier": 2, "prefab": false, "floor": 5},
	{"id": "wedge", "label": "WEDGE", "tier": 2, "prefab": true, "floor": 6},
	{"id": "pyramid", "label": "PYRAMID", "tier": 2, "prefab": true, "floor": 6},
	{"id": "quad", "label": "QUAD", "tier": 3, "prefab": false, "floor": 7},
	{"id": "erase", "label": "ERASE", "tier": 0, "prefab": false, "floor": 1},
]

var work: Node3D
var studio_floor: int = 209
var layer_caps: Dictionary = {}
var active_tool: String = "point"
var draft_level: float = 0.0                 # 0.0 (0 m), 0.5 (1 m), 1.0 (2 m) in 2 m address units
var rot_quarter: int = 0                     # 0..3 quarter turns for wedge / triangle / rod / iso orientation
var active_palette: String = "monochrome"    # unlocked on Color floors (F28+): monochrome/bauhaus/queer/albers/mondrian/memphis
var array_mode: String = "1x"                # unlocked on Arrays (F23+): 1x / 1d / 2d / 3d
var panel_pattern: String = "plain"          # unlocked on Pattern (F37+): plain / checker / diamond / stripe
var basin_mode: String = "flat"              # unlocked on Randomness (F74+ spikes) & Noise (F89+ noise)
var noise_config: Dictionary = {"generator": "simplex", "octaves": 3, "amplitude": 0.72, "frequency": 0.24, "seed": 42}
var random_walk_seed: int = 101
var play_objects: Array[Dictionary] = []     # live kinetic/gameplay objects: package, coin, bomb, jump_pad, iso_cutout

var console_root: Node3D
var mini_root: Node3D
var mini_basin: Node3D
var mini_built: Node3D
var mini_ghost: Node3D
var glass_basin: Node3D
var level_indicator: Node3D
var strip_root: Node3D
var palette_strip_root: Node3D
var layer_strip_root: Node3D
var tile_nodes: Dictionary = {}              # id -> {root, plate, border, label, unlocked, floor}
var palette_nodes: Dictionary = {}           # palette_id -> {root, plate, border, label, size}
var layer_nodes: Dictionary = {}             # id -> {root, plate, border, label, kind, size}
var palette_button: Node3D
var status_label: Label3D
var count_label: Label3D
var level_caption: Label3D
var rot_caption: Label3D
var palette_caption: Label3D
var aim_ray: MeshInstance3D
var worker_unit: Node3D
var worker_assemblage: Node3D
var visor_dock: Node3D
var hover_state: Dictionary = {}             # {tile: id} or {palette: id} or {stamp: [records]} or {erase: idx}
var _last_aim: Node3D = null
var _studio_ready := false


func configure(station: Node3D) -> void:
	work = station
	studio_floor = int(work.get_meta("void_capability_floor", work.get_meta("config_space_floor", _default_floor_for_tier())))
	layer_caps = Layer.capabilities_for_floor(studio_floor)
	if work.has_meta("config_space_floor") or work.has_meta("void_capability_floor"):
		work.prefabs_enabled = work.prefabs_enabled and studio_floor >= 6
	if color_unlocked():
		var cfg_pal: String = str(work.get_meta("config_color_palette", "bauhaus"))
		active_palette = Bauhaus.resolve_palette(cfg_pal)
	else:
		active_palette = "monochrome"
	work.model_scale = STUDIO_SCALE
	work.visitor_scale = STUDIO_SCALE
	work.workshop_look = Bauhaus.PALETTE_BAUHAUS
	work.fitted_offset = GLASS_OFFSET
	work.model.domain_min = DOMAIN_MIN
	work.model.domain_max = DOMAIN_MAX
	work.model.free_ground_points = true

	# Hide legacy hospital-white table, PartsArc, cyan PlaceParameters, wire basket, and detached visor table.
	_hide_legacy_furniture()

	# Rebuild the 6.6 m Glass Box in crisp Bauhaus architectural steel + off-white deck.
	_build_bauhaus_glass_box()

	# Build the single unified Bauhaus architectural console (mini grid + flat template strip + right operate wing + integrated visor).
	_build_console()

	# Place the evolving humanoid Playground Work Unit beside the left end of the console.
	_build_humanoid_worker()

	# Build subtle aim ray for hand-principle picking & stamping.
	_build_aim_ray()

	# Pick the highest unlocked architectural block as initial active template so the first trigger click delights immediately.
	active_tool = _default_tool()

	# Load per-floor save if persisting, or seed an expressive floor-appropriate starter study when empty.
	_load_or_seed_study()

	_studio_ready = true
	work.add_to_group("space_editors")
	refresh_tiles()
	refresh_palette_tiles()
	refresh_layer_tiles()
	redraw_all()


func _default_floor_for_tier() -> int:
	if work.tier >= 3:
		return 209 if work.material_phase == "colour" else 7
	if work.tier == 2:
		return 6 if work.prefabs_enabled else 5
	if work.tier == 1:
		return 3
	return 1


func _default_tool() -> String:
	if _tile_unlocked(TEMPLATE_TILES[6]):
		return "quad"
	if _tile_unlocked(TEMPLATE_TILES[4]):
		return "wedge"
	if _tile_unlocked(TEMPLATE_TILES[3]):
		return "panel"
	if _tile_unlocked(TEMPLATE_TILES[2]):
		return "rod"
	return "point"


func color_unlocked() -> bool:
	return work.material_phase == "colour" or studio_floor >= 28


func effective_phase() -> String:
	if not color_unlocked():
		return "monochrome"
	return Bauhaus.resolve_palette(active_palette)


func _hide_legacy_furniture() -> void:
	for child in work.support.get_children():
		child.hide()
		work.disable_collisions(child)
	for child in work.bench.get_children():
		child.hide()
		work.disable_collisions(child)
	for stock in work.tools.values():
		if stock is RigidBody3D:
			stock.enabled = false
			stock.collision_layer = 0
			stock.collision_mask = 0
	for child in work.controls.get_children():
		if child.name == "HeadsetDock":
			# Keep headset functional; we reparent the visor onto our integrated console dock below.
			for dc in child.get_children():
				if dc.name != "ModelHeadset":
					dc.hide()
					work.disable_collisions(dc)
			continue
		child.hide()
		work.disable_collisions(child)
	if work.brush_timer != null:
		work.brush_timer.stop()


func _build_bauhaus_glass_box() -> void:
	var bay: Node3D = work.output.get_node("Bay")
	work.clear_children(bay)
	var size: float = work.CHAMBER
	var height: float = work.chamber_height
	var half: float = size * 0.5
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_deck := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")

	# Flush architectural concrete/off-white floor slab inside the glass enclosure (top at y = 0.000).
	_box(bay, "GlassBase", Vector3(0, -0.065, 0), Vector3(size, 0.13, size), m_deck, true)
	# Crisp matte-black perimeter rim framing the glass box base.
	for sx in [-half + 0.04, half - 0.04]:
		_box(bay, "BaseTrimX", Vector3(sx, 0.004, 0), Vector3(0.08, 0.012, size), m_black, false)
	for sz in [-half + 0.04, half - 0.04]:
		_box(bay, "BaseTrimZ", Vector3(0, 0.004, sz), Vector3(size, 0.012, 0.08), m_black, false)

	# 1:4 scale playground grid lines matching the 20 m x 14 m active build field (5.0 m x 3.5 m at 1:4).
	var field_w: float = (DOMAIN_MAX.x - DOMAIN_MIN.x) * work.output_unit()
	var field_d: float = (DOMAIN_MAX.z - DOMAIN_MIN.z) * work.output_unit()
	var fc_z: float = GLASS_OFFSET.z
	var cell: float = 0.5 * work.output_unit()   # 0.25 m = 1 m in VR scale
	var cols: int = int(roundf(field_w / cell))
	var rows: int = int(roundf(field_d / cell))
	for i in range(cols + 1):
		var gx: float = -field_w * 0.5 + i * cell
		var major: bool = (i % 2 == 0)
		_box(bay, "GridZ_%d" % i, Vector3(gx, 0.003, fc_z), Vector3(0.012 if major else 0.005, 0.003, field_d),
			m_black if major else m_slate, false)
	for j in range(rows + 1):
		var gz: float = fc_z - field_d * 0.5 + j * cell
		var major: bool = (j % 2 == 0)
		_box(bay, "GridX_%d" % j, Vector3(0, 0.003, gz), Vector3(field_w, 0.003, 0.012 if major else 0.005),
			m_black if major else m_slate, false)

	# Matte-black structural corner posts, slate shoes, and perimeter roof frame (matching Trans_Pre portal).
	for x in [-half, half]:
		for z in [-half, half]:
			_box(bay, "GlassCorner", Vector3(x, height * 0.5, z), Vector3(0.11, height, 0.11), m_black, false)
			_box(bay, "GroundShoe", Vector3(x, 0.025, z), Vector3(0.22, 0.05, 0.22), m_slate, false)
	for y in [0.02, height]:
		for side in [-half, half]:
			_box(bay, "GlassEdgeX", Vector3(0, y, side), Vector3(size, 0.055, 0.055), m_black, false)
			_box(bay, "GlassEdgeZ", Vector3(side, y, 0), Vector3(0.055, 0.055, size), m_black, false)

	# Crystal-clear architectural glass walls (subtle cool reflection, unobstructed sightline).
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.90, 0.94, 0.96, 0.055)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	glass.roughness = 0.14
	glass.metallic = 0.06
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-half, half]:
		for axis in [0, 2]:
			var pos := Vector3(0, height * 0.5, 0)
			pos[axis] = side
			var dims := Vector3(size, height, 0.014) if axis == 2 else Vector3(0.014, height, size)
			var pane := _box(bay, "GlassPane", pos, dims, glass, true)
			pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var roof := _box(bay, "GlassRoof", Vector3(0, height, 0), Vector3(size, 0.014, size), glass, true)
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	glass_basin = Node3D.new()
	glass_basin.name = "GlassBasinSurface"
	bay.add_child(glass_basin)

	# Bold Bauhaus overhead title fascia on the front top beam (matching Trans_Pre's ArchBeam + ArchTrimTop).
	_box(bay, "ChamberHeader", Vector3(0, height - 0.18, half), Vector3(4.2, 0.34, 0.10), m_black, false)
	_box(bay, "HeaderTrimTop", Vector3(0, height + 0.005, half), Vector3(4.26, 0.03, 0.12), m_accent, false)
	var stage_name := _stage_title()
	_label(bay, "PLAYGROUND WORKSTATION · %s" % stage_name, Vector3(0, height - 0.13, half + 0.056), Vector3.ZERO, 28, 0.0030, Color("ffffff"))
	_label(bay, "UNIT 02 VIRTUAL STUDIO  ·  20 x 14 M AT 1:4  ·  WEAR VISOR FOR 1:1", Vector3(0, height - 0.25, half + 0.056), Vector3.ZERO, 18, 0.0024, Color("cfd4d8"))

	# Clean START arrival pad inside the front clear promenade (facing -Z into the 20 x 14 m playground).
	var start := Marker3D.new()
	start.name = "VisitorStart"
	start.position = STUDIO_START
	bay.add_child(start)
	for sx in [-0.36, 0.36]:
		_box(start, "StartEdge", Vector3(sx, -STUDIO_START.y + 0.008, 0), Vector3(0.025, 0.005, 0.66), m_black, false)
	for sz in [-0.33, 0.33]:
		_box(start, "StartEdge", Vector3(0, -STUDIO_START.y + 0.008, sz), Vector3(0.74, 0.005, 0.025), m_black, false)
	_label(start, "START · 1:1", Vector3(0, -STUDIO_START.y + 0.012, 0.14), Vector3(-90, 0, 0), 22, 0.0024, Color("131519"))
	for side in [-1.0, 1.0]:
		var arrow := _box(start, "FaceInward", Vector3(side * 0.065, -STUDIO_START.y + 0.012, -0.13), Vector3(0.020, 0.005, 0.18), m_black, false)
		arrow.rotation.y = side * PI * 0.25

	# Safe working footprint metadata so electrical floors cut cleanly around the studio (zero yellow caution tape!).
	var zone := Node3D.new()
	zone.name = "StudioSafetyZone"
	work.support.add_child(zone)
	var back_z: float = work.output.position.z - half - 0.25
	var front_z: float = 1.65
	zone.set_meta("workshop_safe_rect", Rect2(-half - 0.25, back_z, size + 0.50, front_z - back_z))
	zone.add_to_group("workshop_safe_zones")
	# Subtle crisp matte-black flush threshold frame around the studio bay.
	for sx in [-half - 0.20, half + 0.20]:
		_box(zone, "StudioLine", Vector3(sx, 0.006, (back_z + front_z) * 0.5), Vector3(0.045, 0.004, front_z - back_z), m_black, false)
	_box(zone, "StudioLineBack", Vector3(0, 0.006, back_z), Vector3(size + 0.44, 0.004, 0.045), m_black, false)


func _stage_title() -> String:
	if work.tier >= 3:
		return "06 / COLOUR PALETTE GRID" if color_unlocked() else "05 / QUADS · FULL GRID"
	if work.tier == 2 and work.prefabs_enabled:
		return "04 / SOLIDS · WEDGE & PYRAMID"
	if work.tier == 2:
		return "03 / TRIANGLES · DIAGONAL & FACE"
	if work.tier == 1:
		return "02 / LINES · 1M & 2M RODS"
	return "01 / POINTS · GRID NODES"


func _build_console() -> void:
	console_root = Node3D.new()
	console_root.name = "BauhausStudioConsole"
	add_child(console_root)

	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")

	# Single sleek architectural drafting console (extends rearward cleanly when Sequence Layer / Palette strips unlock).
	var has_layer_strip: bool = bool(layer_caps.get("kinetic_objects", false))
	var deck_d: float = 1.24
	var deck_z: float = 0.05
	if color_unlocked() and has_layer_strip:
		deck_d = 1.54
		deck_z = -0.10
	elif color_unlocked() or has_layer_strip:
		deck_d = 1.42
		deck_z = -0.04
	_box(console_root, "ConsoleDeck", Vector3(0, 0.96, deck_z), Vector3(2.24, 0.08, deck_d), m_black, true)
	_box(console_root, "ConsoleTopSurface", Vector3(0, 1.004, deck_z), Vector3(2.18, 0.010, deck_d - 0.06), m_white, false)
	# Crisp front architectural accent edge strip.
	_box(console_root, "ConsoleFrontTrim", Vector3(0, 0.995, 0.672), Vector3(2.24, 0.022, 0.014), m_accent, false)
	# Clean matte-black architectural slab legs with slate feet (matches F209 stock plinths & Trans_Pre legs).
	for sx in [-0.94, 0.94]:
		_box(console_root, "ConsoleLeg", Vector3(sx, 0.46, 0.05), Vector3(0.11, 0.92, 0.90), m_black, true)
		_box(console_root, "ConsoleFoot", Vector3(sx, 0.02, 0.05), Vector3(0.18, 0.04, 1.02), m_slate, false)
	_box(console_root, "ConsoleCrossTie", Vector3(0, 0.22, -0.10), Vector3(1.88, 0.07, 0.07), m_black, false)
	# Low dark service umbilical visually connecting console straight to the glass box base.
	for sx in [-0.62, 0.62]:
		_box(console_root, "GlassUmbilical", Vector3(sx, 0.025, -0.74), Vector3(0.08, 0.045, 0.50), m_black, false)

	# ── 1. Recessed Virtual Miniature Drafting Grid (1:16 scale = 20 m x 14 m playground) ──
	var pad_w: float = (DOMAIN_MAX.x - DOMAIN_MIN.x) * MINI_UNIT    # 1.25 m
	var pad_d: float = (DOMAIN_MAX.z - DOMAIN_MIN.z) * MINI_UNIT    # 0.875 m
	_box(console_root, "DraftBezel", PAD_ORIGIN + Vector3(0, -0.004, 0), Vector3(pad_w + 0.05, 0.018, pad_d + 0.05), m_black, false)
	_box(console_root, "DraftSurface", PAD_ORIGIN + Vector3(0, 0.003, 0), Vector3(pad_w, 0.008, pad_d), m_white, false)

	var cell: float = 0.5 * MINI_UNIT   # 6.25 cm per 1 m cell
	var cols: int = int(roundf(pad_w / cell))
	var rows: int = int(roundf(pad_d / cell))
	for i in range(cols + 1):
		var gx: float = -pad_w * 0.5 + i * cell
		var major: bool = (i % 2 == 0)
		_box(console_root, "MiniGridZ_%d" % i, PAD_ORIGIN + Vector3(gx, 0.008, 0),
			Vector3(0.0035 if major else 0.0016, 0.0015, pad_d), m_black if major else m_slate, false)
	for j in range(rows + 1):
		var gz: float = -pad_d * 0.5 + j * cell
		var major: bool = (j % 2 == 0)
		_box(console_root, "MiniGridX_%d" % j, PAD_ORIGIN + Vector3(0, 0.008, gz),
			Vector3(pad_w, 0.0015, 0.0035 if major else 0.0016), m_black if major else m_slate, false)

	# Hollow 4-bar amber perimeter frame showing active drafting elevation (0 m / 1 m / 2 m) without tinting the grid.
	level_indicator = Node3D.new()
	level_indicator.name = "LevelPlaneFrame"
	var l_mat := StandardMaterial3D.new()
	l_mat.albedo_color = Color("f59e0b")
	l_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fw: float = pad_w + 0.018
	var fd: float = pad_d + 0.018
	_box(level_indicator, "BarN", Vector3(0, 0, -fd * 0.5), Vector3(fw, 0.005, 0.008), l_mat, false)
	_box(level_indicator, "BarS", Vector3(0, 0, fd * 0.5), Vector3(fw, 0.005, 0.008), l_mat, false)
	_box(level_indicator, "BarW", Vector3(-fw * 0.5, 0, 0), Vector3(0.008, 0.005, fd), l_mat, false)
	_box(level_indicator, "BarE", Vector3(fw * 0.5, 0, 0), Vector3(0.008, 0.005, fd), l_mat, false)
	level_indicator.position = PAD_ORIGIN + Vector3(0, 0.010, 0)
	level_indicator.visible = false
	console_root.add_child(level_indicator)

	mini_root = Node3D.new()
	mini_root.name = "MiniPlaygroundRoot"
	mini_root.position = PAD_ORIGIN + Vector3(0, 0.009, 0)
	console_root.add_child(mini_root)

	mini_basin = Node3D.new()
	mini_basin.name = "MiniBasinSurface"
	mini_root.add_child(mini_basin)

	mini_built = Node3D.new()
	mini_built.name = "MiniBuilt"
	mini_root.add_child(mini_built)

	mini_ghost = Node3D.new()
	mini_ghost.name = "MiniGhost"
	mini_root.add_child(mini_ghost)

	# ── 2. Flat Near-Edge Hand-Principle Template Strip (NO floating arc!) ──
	strip_root = Node3D.new()
	strip_root.name = "TemplateStrip"
	strip_root.position = Vector3(-0.24, 1.032, 0.495)
	strip_root.rotation.x = deg_to_rad(18.0)
	console_root.add_child(strip_root)

	var strip_w: float = 1.38
	_box(strip_root, "StripBase", Vector3(0, -0.014, 0), Vector3(strip_w, 0.026, 0.21), m_black, false)

	var tile_count := TEMPLATE_TILES.size()
	var tile_w: float = 0.152
	var tile_gap: float = 0.014
	var total_w: float = tile_count * tile_w + (tile_count - 1) * tile_gap
	for i in tile_count:
		var spec: Dictionary = TEMPLATE_TILES[i]
		var tx: float = -total_w * 0.5 + tile_w * 0.5 + i * (tile_w + tile_gap)
		var t_node := Node3D.new()
		t_node.name = "Tile_" + spec.id
		t_node.position = Vector3(tx, 0.004, 0)
		strip_root.add_child(t_node)

		var border := _box(t_node, "Border", Vector3(0, 0.002, 0), Vector3(tile_w, 0.008, 0.165), m_slate, false)
		var plate := _box(t_node, "Plate", Vector3(0, 0.007, 0), Vector3(tile_w - 0.012, 0.008, 0.153), m_black, false)
		var unlocked: bool = _tile_unlocked(spec)

		# Real crisp 3D miniature icon on every unlocked tile (immediately readable without guessing).
		var icon_holder := Node3D.new()
		icon_holder.name = "Icon"
		icon_holder.position = Vector3(0, 0.028, -0.020)
		t_node.add_child(icon_holder)
		if spec.id == "erase":
			var er := _box(icon_holder, "EraseIcon", Vector3.ZERO, Vector3(0.055, 0.016, 0.032),
				Kit.material(Color("e6554e")), false)
			er.rotation.y = deg_to_rad(25.0)
		else:
			var icon_mesh := _make_tile_icon(spec.id, unlocked)
			if icon_mesh != null:
				icon_holder.add_child(icon_mesh)

		var cap_text: String = spec.label if unlocked else "FLOOR %d" % int(spec.floor)
		var cap := _label(t_node, cap_text, Vector3(0, 0.014, 0.048), Vector3(-90, 0, 0), 13, 0.00145,
			Color("ededeb") if unlocked else Color("68707a"))
		tile_nodes[spec.id] = {
			"root": t_node, "plate": plate, "border": border, "label": cap,
			"icon": icon_holder, "spec": spec, "unlocked": unlocked,
			"size": Vector2(tile_w, 0.165),
		}

	# ── 2B. Far-Edge Color-Sequence Palette Chooser Strip (ONLY unlocked on Color floors F28+ & F209!) ──
	if color_unlocked():
		_build_palette_strip(m_black, m_slate)

	# ── 2C. Sequence General-Intellect Capability Strip (ONLY unlocked F13+ Transformation onward!) ──
	if bool(layer_caps.get("kinetic_objects", false)):
		_build_layer_strip(m_black, m_slate)

	# ── 3. Integrated Right Operate Wing + Flush VR Visor Dock (NO detached side table!) ──
	var wing := Node3D.new()
	wing.name = "OperateWing"
	wing.position = Vector3(0.76, 1.015, 0.03)
	console_root.add_child(wing)

	# Matte-black recessed instrument plate for minimal controls & live readout.
	_box(wing, "OperatePlate", Vector3(0, 0.006, -0.22), Vector3(0.56, 0.018, 0.64), m_black, false)
	_box(wing, "OperateTrim", Vector3(0, 0.016, -0.53), Vector3(0.54, 0.004, 0.012), m_accent, false)

	status_label = _label(wing, "SELECT BLOCK · PULL TO STAMP", Vector3(0, 0.019, -0.45), Vector3(-90, 0, 0), 13, 0.00155, Color("ffffff"))
	status_label.width = 340
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	count_label = _label(wing, "", Vector3(0, 0.019, -0.34), Vector3(-90, 0, 0), 11, 0.0014, Color("b8c0c8"))

	# Clean flush Bauhaus buttons (physical press + ray trigger + desktop click).
	level_caption = _add_wing_button(wing, "Level", "LEVEL 0M", Vector3(-0.13, 0.020, -0.20), Color("ededeb"), cycle_level)
	rot_caption = _add_wing_button(wing, "Rotate", "ROT 0°", Vector3(0.13, 0.020, -0.20), Color("ededeb"), cycle_rotation)
	_add_wing_button(wing, "Undo", "UNDO", Vector3(-0.13, 0.020, -0.06), Color("d5d8dc"), func(): work.undo(); redraw_all())
	_add_wing_button(wing, "DropTest", "DROP TEST", Vector3(0.13, 0.020, -0.06), Color("d5d8dc"), func(): work.start_test())
	_add_wing_button(wing, "Clear", "CLEAR", Vector3(-0.13, 0.020, 0.05), Color("404650"), clear_playground)
	if color_unlocked():
		palette_caption = _add_wing_button(wing, "Palette", Bauhaus.palette_label(active_palette), Vector3(0.13, 0.020, 0.05), Color("f0c430"), cycle_palette)
		palette_button = wing.get_node_or_null("StudioBtn_Palette")

	# Integrated VR Visor Docking Pad right on the front-right corner of the console.
	visor_dock = Node3D.new()
	visor_dock.name = "StudioVisorDock"
	visor_dock.position = Vector3(0.76, 1.022, 0.37)
	console_root.add_child(visor_dock)
	_box(visor_dock, "VisorPad", Vector3(0, 0.004, 0), Vector3(0.56, 0.016, 0.42), m_black, false)
	_box(visor_dock, "VisorRest", Vector3(0, 0.014, -0.03), Vector3(0.36, 0.012, 0.24), m_slate, false)
	_label(visor_dock, "VR VISOR · STEP IN 1:1 (20x14M)", Vector3(0, 0.016, 0.145), Vector3(-90, 0, 0), 12, 0.00145, Color("ffffff"))

	# Reparent and restyle the existing ModelHeadset cleanly onto this integrated Bauhaus pad.
	if work.visit != null and is_instance_valid(work.visit.headset):
		var hs: RigidBody3D = work.visit.headset
		hs.reparent(visor_dock, false)
		hs.position = Vector3(0, 0.072, -0.03)
		hs.rotation = Vector3.ZERO
		hs.home = hs.transform
		hs.enabled = true
		_restyle_headset(hs)
		hs.dock()


func _build_palette_strip(m_black: Material, m_slate: Material) -> void:
	palette_strip_root = Node3D.new()
	palette_strip_root.name = "PaletteChooserStrip"
	palette_strip_root.position = Vector3(-0.24, 1.032, -0.655)
	palette_strip_root.rotation.x = deg_to_rad(20.0)
	console_root.add_child(palette_strip_root)

	var count: int = Bauhaus.PALETTE_ORDER.size()
	var tile_w: float = 0.205
	var tile_gap: float = 0.015
	var total_w: float = count * tile_w + (count - 1) * tile_gap
	_box(palette_strip_root, "PaletteBase", Vector3(0, -0.012, 0), Vector3(total_w + 0.05, 0.022, 0.16), m_black, false)

	for i in count:
		var pid: String = Bauhaus.PALETTE_ORDER[i]
		var tx: float = -total_w * 0.5 + tile_w * 0.5 + i * (tile_w + tile_gap)
		var p_node := Node3D.new()
		p_node.name = "Palette_" + pid
		p_node.position = Vector3(tx, 0.004, 0)
		palette_strip_root.add_child(p_node)

		var border := _box(p_node, "Border", Vector3(0, 0.002, 0), Vector3(tile_w, 0.008, 0.132), m_slate, false)
		var plate := _box(p_node, "Plate", Vector3(0, 0.007, 0), Vector3(tile_w - 0.012, 0.008, 0.120), m_black, false)

		# 4 crisp real colour swatch chips (rod, quad, wedge, pyramid) showing the palette at a glance!
		var chips: Array[Color] = Bauhaus.swatch_colors(pid)
		var chip_w: float = 0.036
		var chip_gap: float = 0.006
		var row_w: float = 4.0 * chip_w + 3.0 * chip_gap
		for c_idx in 4:
			var cx: float = -row_w * 0.5 + chip_w * 0.5 + c_idx * (chip_w + chip_gap)
			var c_mat := StandardMaterial3D.new()
			c_mat.albedo_color = chips[c_idx]
			c_mat.roughness = 0.42
			_box(p_node, "Swatch_%d" % c_idx, Vector3(cx, 0.014, -0.018), Vector3(chip_w, 0.008, 0.044), c_mat, false)

		var lbl := _label(p_node, Bauhaus.palette_label(pid), Vector3(0, 0.014, 0.034), Vector3(-90, 0, 0), 12, 0.0014, Color("ededeb"))
		palette_nodes[pid] = {
			"root": p_node, "plate": plate, "border": border, "label": lbl,
			"size": Vector2(tile_w, 0.132),
		}


func _build_layer_strip(m_black: Material, m_slate: Material) -> void:
	layer_strip_root = Node3D.new()
	layer_strip_root.name = "SequenceLayerStrip"
	var z_at: float = -0.805 if color_unlocked() else -0.655
	layer_strip_root.position = Vector3(-0.24, 1.036, z_at)
	layer_strip_root.rotation.x = deg_to_rad(22.0)
	console_root.add_child(layer_strip_root)

	var entries: Array[Dictionary] = []
	if bool(layer_caps.get("kinetic_objects", false)):
		entries.append({"id": "package", "label": "PACKAGE", "kind": "tool", "col": Color("28c98a")})
		entries.append({"id": "coin", "label": "COIN", "kind": "tool", "col": Color("f0c430")})
		entries.append({"id": "bomb", "label": "BOMB", "kind": "tool", "col": Color("e0524d")})
	if bool(layer_caps.get("arrays", false)):
		entries.append({"id": "array_mode", "label": "ARR 1X", "kind": "action", "col": Color("cfd4d8")})
	if bool(layer_caps.get("panel_patterns", false)):
		entries.append({"id": "panel_pattern", "label": "PAT PLAIN", "kind": "action", "col": Color("cfd4d8")})
	if bool(layer_caps.get("force_pads", false)):
		entries.append({"id": "jump_pad", "label": "JUMP PAD", "kind": "tool", "col": Color("38bdf8")})
	if bool(layer_caps.get("random_walk", false)):
		entries.append({"id": "rnd_walk", "label": "RND WALK", "kind": "action", "col": Color("f59e0b")})
		entries.append({"id": "basin_mode", "label": "FLAT", "kind": "action", "col": Color("a0a2a6")})
	if bool(layer_caps.get("iso_cutouts", false)):
		entries.append({"id": "iso_cutout", "label": "ISO 4x4", "kind": "tool", "col": Color("e88aa8")})

	if entries.is_empty():
		return

	var count: int = entries.size()
	var max_span: float = 1.44
	var tile_gap: float = 0.010
	var tile_w: float = minf(0.185, (max_span - (count - 1) * tile_gap) / float(count))
	var total_w: float = count * tile_w + (count - 1) * tile_gap
	_box(layer_strip_root, "LayerBase", Vector3(0, -0.012, 0), Vector3(total_w + 0.04, 0.022, 0.125), m_black, false)

	var mono_mode: bool = not color_unlocked()
	for i in count:
		var e: Dictionary = entries[i]
		var eid: String = str(e.id)
		var tx: float = -total_w * 0.5 + tile_w * 0.5 + i * (tile_w + tile_gap)
		var l_node := Node3D.new()
		l_node.name = "Layer_" + eid
		l_node.position = Vector3(tx, 0.004, 0)
		layer_strip_root.add_child(l_node)

		var border := _box(l_node, "Border", Vector3(0, 0.002, 0), Vector3(tile_w, 0.008, 0.108), m_slate, false)
		var plate := _box(l_node, "Plate", Vector3(0, 0.007, 0), Vector3(tile_w - 0.010, 0.008, 0.098), m_black, false)

		var dot_col: Color = Color("ededeb") if mono_mode else (e.col as Color)
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = dot_col
		dmat.roughness = 0.45
		_box(l_node, "Badge", Vector3(0, 0.014, -0.024), Vector3(tile_w * 0.52, 0.007, 0.018), dmat, false)

		var lbl := _label(l_node, str(e.label), Vector3(0, 0.014, 0.018), Vector3(-90, 0, 0), 10, 0.00125, Color("ededeb"))
		layer_nodes[eid] = {
			"root": l_node, "plate": plate, "border": border, "label": lbl,
			"kind": str(e.kind), "size": Vector2(tile_w, 0.108),
		}


func _restyle_headset(hs: Node3D) -> void:
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")
	for child in hs.get_children():
		if not child is MeshInstance3D:
			continue
		if child.name == "Visor":
			child.material_override = m_black
		elif child.name == "FaceSeal":
			child.material_override = m_white
		elif child.name == "Lens":
			child.material_override = m_accent
		else:
			child.material_override = Bauhaus.mat("slate", "monochrome")


func _add_wing_button(parent: Node3D, id: String, words: String, at: Vector3, colour: Color, action: Callable) -> Label3D:
	var button: Node3D = Furniture.rectangular_button(ButtonScene)
	button.name = "StudioBtn_" + id
	button.rotation = Vector3.ZERO
	button.position = at + Vector3(-0.075, 0.006, 0)
	button.released_color = colour
	button.pressed.connect(action)
	parent.add_child(button)
	var cap := _label(parent, words, at + Vector3(0.055, 0.005, 0), Vector3(-90, 0, 0), 11, 0.00145, Color("ededeb"))
	return cap


func _make_tile_icon(kind: String, unlocked: bool) -> Node3D:
	var rec: Dictionary = {"kind": kind, "at": [0, 0, 0], "end": [0, 1, 0], "plane": [0, 2], "half": 0, "turn": [0, 0, 0]}
	if kind == "rod_short":
		rec.end = [0, 0.5, 0]
	var icon_unit: float = 0.068
	if kind == "point":
		icon_unit = 0.24
	elif kind in ["rod", "rod_short"]:
		icon_unit = 0.095
	var mesh := Bauhaus.visual(rec, icon_unit, effective_phase())
	if kind in ["rod", "rod_short"]:
		mesh.rotation = Vector3(0, 0, PI * 0.5)
	elif kind == "wedge":
		mesh.position.y = -0.016
		mesh.rotation.y = deg_to_rad(-35.0)
	elif kind == "pyramid":
		mesh.position.y = -0.016
	elif kind in ["quad", "panel"]:
		mesh.position.y = -0.005
	if not unlocked:
		var dim := StandardMaterial3D.new()
		dim.albedo_color = Color("3a404a")
		dim.roughness = 0.85
		_override_all(mesh, dim)
	elif kind in ["point", "rod", "rod_short"] and effective_phase() == "monochrome":
		# High-contrast off-white icon silhouette so dark structural primitives pop on matte-black tiles.
		_override_all(mesh, Bauhaus.mat("quad", "monochrome"))
	return mesh


func _override_all(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for c in node.get_children():
		_override_all(c, mat)


func _build_humanoid_worker() -> void:
	# The evolving humanoid Playground Work Unit + Endless Museum Dream-Body Form & Assemblage plinth
	# seated cleanly inside the studio's left (and optional right) pocket beside the console.
	var stage_name := "Point_One"
	if color_unlocked():
		stage_name = "color"
	elif work.tier >= 3:
		stage_name = "Point_Animatedcube"
	elif work.tier == 2 and work.prefabs_enabled:
		stage_name = "Primitives_Polythedra"
	elif work.tier == 2:
		stage_name = "Point_Triangle_Context"
	elif work.tier == 1:
		stage_name = "Point_Lines"

	var assem := Node3D.new()
	assem.name = "PlaygroundWorkUnit"
	assem.set_script(WorkerAssemblageScript)
	assem.position = Vector3(-1.58, 0.0, 0.02)
	var cfg: Dictionary = {
		"formation": "workbench_arc",
		"floor": studio_floor,
		"stage": stage_name,
		"monochrome": "auto" if color_unlocked() else "true",
		"palette": active_palette,
		"interactive": true,
		"submode": str(work.get_meta("config_assemblage_mode", "dyad")),
	}
	if work.has_meta("config_assemblage_figure"):
		cfg["figure"] = str(work.get_meta("config_assemblage_figure"))
	assem.call("apply_grid_config", cfg)
	add_child(assem)
	worker_assemblage = assem
	worker_unit = assem.call("get_worker_host") as Node3D
	assem.connect("rebuilt", func():
		if is_instance_valid(assem):
			worker_unit = assem.call("get_worker_host") as Node3D
	)


func _build_aim_ray() -> void:
	aim_ray = MeshInstance3D.new()
	aim_ray.name = "StudioAimRay"
	aim_ray.top_level = true
	aim_ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0035
	cyl.bottom_radius = 0.0035
	cyl.height = 1.0
	cyl.radial_segments = 6
	cyl.rings = 1
	aim_ray.mesh = cyl
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.no_depth_test = true
	aim_ray.material_override = rm
	aim_ray.visible = false
	add_child(aim_ray)


func _tile_unlocked(spec: Dictionary) -> bool:
	if spec.id == "erase":
		return true
	if bool(spec.prefab) and not work.prefabs_enabled:
		return false
	return int(spec.tier) <= work.tier


# ── Starter floor-appropriate grammar studies (so every glass box immediately teaches & invites play!) ──

func _save_path() -> String:
	return "user://void_studio_build_%d.json" % studio_floor


func _load_or_seed_study() -> void:
	work.model.records.clear()
	work.edit_history.clear()
	if work.persist and FileAccess.file_exists(_save_path()):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(_save_path()))
		if parsed is Dictionary and parsed.get("records") is Array and not parsed.records.is_empty():
			if color_unlocked() and parsed.has("color_palette"):
				active_palette = Bauhaus.resolve_palette(str(parsed.color_palette))
			if work.model.restore(parsed.records):
				return
	_seed_floor_study()


func _seed_floor_study() -> void:
	# Strictly uses ONLY the primitives unlocked on this floor — 100% pure canonical model.gd grammar!
	work.model.records.clear()
	if work.tier == 0:
		# Floor 1 (Point_One): a crisp 4 m x 4 m point constellation marking the grid datum.
		for p in [[1, 0, 0], [0, 0, 1], [1, 0, 1], [-1, 0, 0], [0, 0, -1]]:
			work.model.add({"kind": "point", "at": p}, work.tier)
	elif work.tier == 1:
		# Floor 3 (Point_Lines): open matte-black post-and-beam structural frame (4 m x 2 m x 2 m).
		_stamp_raw_frame(Vector3(-1, 0, -1), 1.0, 0.5, true)
		_stamp_raw_frame(Vector3(0, 0, -1), 1.0, 0.5, true)
	elif work.tier == 2 and not work.prefabs_enabled:
		# Floor 5 (Point_Triangle_Context): framed square split across its diagonal into two crisp Bauhaus triangles.
		_stamp_triangle_at(Vector3(-1, 0.5, -0.5), 0, 1.0, true)
		_stamp_triangle_at(Vector3(-1, 0.5, -0.5), 1, 1.0, true)
		_stamp_triangle_at(Vector3(0, 0.5, -0.5), 2, 1.0, true)
	elif work.tier == 2 and work.prefabs_enabled:
		# Floor 6 (Primitives_Polythedra): walkable triangular-decked landing + Bauhaus wedge ramp + pyramid.
		_stamp_triangle_at(Vector3(-0.5, 0.5, -0.5), 0, 1.0, true)
		_stamp_triangle_at(Vector3(-0.5, 0.5, -0.5), 1, 1.0, true)
		work.model.add({"kind": "wedge", "at": [0, 0, 1], "turn": [0, 2, 0]}, work.tier)
		work.model.add({"kind": "pyramid", "at": [1.5, 0, 0], "turn": [0, 0, 0]}, work.tier)
	else:
		# Floor 7 / F209 (Full Quads): a crisp walkable elevated Bauhaus play path (12 m x 6 m inside 20 x 14 m!)
		# Entry ramp on the front-left -> 3 elevated 1 m framed quad bays -> turn -> exit ramp back to slab.
		for bx in [-2.0, -1.0, 0.0, 1.0]:
			_stamp_quad_at(Vector3(bx, 0.5, -1.0), 1.0, true)
		_stamp_quad_at(Vector3(1.0, 0.5, 0.0), 1.0, true)
		# Entry ramp rising North (-Z) from z=+1 onto the (-2.. -1, z=-1..0) elevated quad:
		work.model.add({"kind": "wedge", "at": [-1.5, 0, 0.5], "turn": [0, 2, 0]}, work.tier)
		# Exit ramp descending South (+Z) from (1..2, z=0..1) onto z=+1..+2:
		work.model.add({"kind": "wedge", "at": [1.5, 0, 1.5], "turn": [0, 2, 0]}, work.tier)
		# Sculptural pyramid landmark flanking the court.
		work.model.add({"kind": "pyramid", "at": [-1.5, 0, -2.5], "turn": [0, 0, 0]}, work.tier)


func _stamp_raw_frame(p: Vector3, span: float, rise_y: float, commit: bool) -> Array[Dictionary]:
	var plan := _build_quad_records(p + Vector3(0, rise_y, 0), span, false)
	if commit:
		for r in plan:
			work.model.add(r, work.tier)
	return plan


func _stamp_triangle_at(p: Vector3, half: int, span: float, commit: bool) -> Array[Dictionary]:
	var plan := _build_triangle_records(p, half, span)
	if commit:
		for r in plan:
			work.model.add(r, work.tier)
	return plan


func _stamp_quad_at(p: Vector3, span: float, commit: bool) -> Array[Dictionary]:
	var plan := _build_quad_records(p, span, true)
	if commit:
		for r in plan:
			work.model.add(r, work.tier)
	return plan


# ── Hand-principle single-trigger atomic template planners (pure canonical model.gd records) ──

func _ensure_point(sim, p: Vector3, out: Array[Dictionary]) -> bool:
	if not sim.in_domain(p):
		return false
	var k: String = Model.key(p)
	if sim.points().has(k):
		return true
	# If elevated, drop a vertical support column down to y = 0 so every piece stays grounded in the grammar!
	if p.y > 0.001:
		var steps: int = int(roundf(p.y * 2.0))
		for s in range(0, steps + 1):
			var q := Vector3(p.x, float(s) * 0.5, p.z)
			if not sim.points().has(Model.key(q)):
				var pr := {"kind": "point", "at": Model.arr(q)}
				if not sim.add(pr, work.tier):
					return false
				out.append(pr)
			if s > 0 and work.tier >= 1:
				var prev := Vector3(p.x, float(s - 1) * 0.5, p.z)
				if not sim.edge(prev, q) and not sim.rod_overlaps(prev, q):
					var rr := {"kind": "rod_short", "at": Model.arr(prev), "end": Model.arr(q)}
					if sim.add(rr, work.tier):
						out.append(rr)
		return true
	var r := {"kind": "point", "at": Model.arr(p)}
	if not sim.add(r, work.tier):
		return false
	out.append(r)
	return true


func _ensure_edge(sim, a: Vector3, b: Vector3, out: Array[Dictionary]) -> bool:
	if not _ensure_point(sim, a, out) or not _ensure_point(sim, b, out):
		return false
	if sim.edge(a, b):
		return true
	var dist := a.distance_to(b)
	var rkind := "rod_short" if is_equal_approx(dist, 0.5) else "rod"
	if not sim.rod_overlaps(a, b):
		var rr := {"kind": rkind, "at": Model.arr(a), "end": Model.arr(b)}
		if sim.add(rr, work.tier):
			out.append(rr)
			return true
	# If a 2 m span is partially occupied by a 1 m rod, fill the remaining 1 m half cleanly.
	if is_equal_approx(dist, 1.0):
		var mid := (a + b) * 0.5
		if _ensure_point(sim, mid, out):
			var ok_a: bool = sim.edge(a, mid) or _ensure_edge(sim, a, mid, out)
			var ok_b: bool = sim.edge(mid, b) or _ensure_edge(sim, mid, b, out)
			return ok_a and ok_b
	return false


func _build_point_records(at: Vector3) -> Array[Dictionary]:
	var sim = work.model._clone_empty()
	sim.records = work.model.records.duplicate(true)
	var out: Array[Dictionary] = []
	if not _ensure_point(sim, at, out):
		return []
	return out


func _build_rod_records(at: Vector3, span: float, axis_idx: int) -> Array[Dictionary]:
	var sim = work.model._clone_empty()
	sim.records = work.model.records.duplicate(true)
	var dir := Vector3(Model.AXES[axis_idx]) * span
	var b := at + dir
	var out: Array[Dictionary] = []
	if not _ensure_edge(sim, at, b, out):
		return []
	return out


func _build_triangle_records(p: Vector3, half: int, span: float = 1.0) -> Array[Dictionary]:
	var sim = work.model._clone_empty()
	sim.records = work.model.records.duplicate(true)
	var u := Vector3(1, 0, 0) * span
	var v := Vector3(0, 0, 1) * span
	if not sim.in_domain(p) or not sim.in_domain(p + u + v):
		return []
	if sim.face_occupied(Model.arr(p), [0, 2], half, span):
		return []
	var out: Array[Dictionary] = []
	var edges: Array = []
	var diag_a: Vector3; var diag_b: Vector3
	match half:
		0:
			edges = [[p, p + u], [p + u, p + u + v]]
			diag_a = p; diag_b = p + u + v
		1:
			edges = [[p, p + v], [p + v, p + u + v]]
			diag_a = p; diag_b = p + u + v
		2:
			edges = [[p, p + u], [p, p + v]]
			diag_a = p + u; diag_b = p + v
		_:
			edges = [[p + u, p + u + v], [p + v, p + u + v]]
			diag_a = p + u; diag_b = p + v
	for e in edges:
		if not _ensure_edge(sim, e[0], e[1], out):
			return []
	if not sim.diag_exists(diag_a, diag_b):
		var dr := {"kind": "diag", "at": Model.arr(diag_a), "end": Model.arr(diag_b)}
		if not sim.add(dr, work.tier):
			return []
		out.append(dr)
	var tr := {"kind": "panel", "at": Model.arr(p), "plane": [0, 2], "half": half}
	if not is_equal_approx(span, 1.0):
		tr.span = span
	if not sim.add(tr, work.tier):
		return []
	out.append(tr)
	return out


func _build_quad_records(p: Vector3, span: float = 1.0, include_face: bool = true) -> Array[Dictionary]:
	var sim = work.model._clone_empty()
	sim.records = work.model.records.duplicate(true)
	var u := Vector3(1, 0, 0) * span
	var v := Vector3(0, 0, 1) * span
	if not sim.in_domain(p) or not sim.in_domain(p + u + v):
		return []
	if include_face and sim.face_occupied(Model.arr(p), [0, 2], -1, span):
		return []
	var out: Array[Dictionary] = []
	for e in [[p, p + u], [p, p + v], [p + u, p + u + v], [p + v, p + u + v]]:
		if not _ensure_edge(sim, e[0], e[1], out):
			return []
	if include_face:
		var qr := {"kind": "quad", "at": Model.arr(p), "plane": [0, 2]}
		if not is_equal_approx(span, 1.0):
			qr.span = span
		if not sim.add(qr, work.tier):
			return []
		out.append(qr)
	return out


func _build_solid_records(kind: String, at: Vector3, turn: int) -> Array[Dictionary]:
	var r := Model.canonical({"kind": kind, "at": Model.arr(at), "turn": [0, turn, 0]})
	if r.is_empty() or not work.model.prefab_fits(r):
		return []
	return [r]


# ── Controls actions ──

func select_tool(id: String) -> bool:
	if tile_nodes.has(id):
		var info: Dictionary = tile_nodes[id]
		if not bool(info.unlocked):
			status_label.text = "%s UNLOCKS ON FLOOR %d" % [str(info.spec.label), int(info.spec.floor)]
			return false
		active_tool = id
		refresh_tiles()
		refresh_layer_tiles()
		_update_status()
		return true
	if layer_nodes.has(id) and str(layer_nodes[id].kind) == "tool":
		active_tool = id
		refresh_tiles()
		refresh_layer_tiles()
		_update_status()
		return true
	return false


func cycle_array_mode() -> String:
	if not bool(layer_caps.get("arrays", false)):
		return array_mode
	var idx: int = Layer.ARRAY_MODES.find(array_mode)
	array_mode = Layer.ARRAY_MODES[(idx + 1) % Layer.ARRAY_MODES.size()]
	refresh_layer_tiles()
	_update_status()
	return array_mode


func cycle_panel_pattern() -> String:
	if not bool(layer_caps.get("panel_patterns", false)):
		return panel_pattern
	var idx: int = Layer.PATTERN_MODES.find(panel_pattern)
	panel_pattern = Layer.PATTERN_MODES[(idx + 1) % Layer.PATTERN_MODES.size()]
	refresh_layer_tiles()
	save_studio_build()
	redraw_all()
	return panel_pattern


func cycle_basin_surface() -> String:
	if not bool(layer_caps.get("random_walk", false)):
		return basin_mode
	var allowed: Array[String] = ["flat", "spikes"]
	if bool(layer_caps.get("noise_surface", false)):
		allowed.append("noise")
	var idx: int = allowed.find(basin_mode)
	basin_mode = allowed[(idx + 1) % allowed.size()]
	refresh_layer_tiles()
	save_studio_build()
	redraw_all()
	return basin_mode


func set_basin_surface(mode: String, cfg: Dictionary = {}) -> bool:
	var clean: String = mode.to_lower()
	if clean == "spikes" and not bool(layer_caps.get("random_walk", false)):
		return false
	if clean == "noise" and not bool(layer_caps.get("noise_surface", false)):
		return false
	if clean not in Layer.SURFACE_MODES:
		return false
	basin_mode = clean
	if not cfg.is_empty():
		configure_noise(cfg)
	refresh_layer_tiles()
	save_studio_build()
	redraw_all()
	return true


func configure_noise(cfg: Dictionary) -> Dictionary:
	for k in ["generator", "octaves", "amplitude", "frequency", "seed"]:
		if cfg.has(k):
			noise_config[k] = cfg[k]
	if basin_mode == "noise" and _studio_ready:
		redraw_all()
	return noise_config.duplicate(true)


func generate_random_walk(seed_val: int = -1) -> Dictionary:
	if not bool(layer_caps.get("random_walk", false)):
		return {}
	if seed_val >= 0:
		random_walk_seed = seed_val
	else:
		random_walk_seed += 17
	var before: Array = work.model.records.duplicate(true)
	var plan: Dictionary = Layer.generate_random_walk_plan(random_walk_seed, layer_caps)
	work.model.records.clear()
	play_objects.clear()
	for qp: Vector3 in plan.quads:
		_stamp_quad_at(qp, 1.0, true)
	for rr: Dictionary in plan.ramps:
		work.model.add(rr, work.tier)
	for ob: Dictionary in plan.objects:
		play_objects.append(ob.duplicate(true))
	work.remember_edit(before)
	save_studio_build()
	redraw_all()
	if status_label != null:
		status_label.text = "RANDOM WALK #%d · %d BAYS · %d OBJECTS" % [random_walk_seed, plan.steps, play_objects.size()]
	return plan


func stamp_play_object(kind: String, at_addr: Vector3, turn_q: int = 0) -> Dictionary:
	var rec: Dictionary = {
		"kind": kind,
		"at": Model.arr(at_addr),
		"turn": [0, turn_q % 4, 0],
	}
	if kind == "iso_cutout":
		rec["form"] = Layer.ISO_FORMS[turn_q % Layer.ISO_FORMS.size()]
	play_objects.append(rec)
	save_studio_build()
	redraw_all()
	return rec


func get_layer_state() -> Dictionary:
	return {
		"floor": studio_floor,
		"capabilities": layer_caps.duplicate(true),
		"active_tool": active_tool,
		"active_palette": active_palette,
		"array_mode": array_mode,
		"panel_pattern": panel_pattern,
		"basin_mode": basin_mode,
		"noise_config": noise_config.duplicate(true),
		"play_objects": play_objects.duplicate(true),
		"records_count": work.model.records.size(),
		"layer_tile_count": layer_nodes.size(),
	}


func refresh_layer_tiles() -> void:
	if layer_nodes.is_empty():
		return
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")
	var hovered_layer: String = str(hover_state.get("layer", ""))
	for id in layer_nodes:
		var info: Dictionary = layer_nodes[id]
		var plate: MeshInstance3D = info.plate
		var border: MeshInstance3D = info.border
		var lbl: Label3D = info.label
		if id == "array_mode":
			lbl.text = "ARR " + array_mode.to_upper()
		elif id == "panel_pattern":
			lbl.text = "PAT " + panel_pattern.substr(0, 5).to_upper()
		elif id == "basin_mode":
			lbl.text = basin_mode.to_upper()
		var selected: bool = (str(info.kind) == "tool" and active_tool == id) \
			or (id == "array_mode" and array_mode != "1x") \
			or (id == "panel_pattern" and panel_pattern != "plain") \
			or (id == "basin_mode" and basin_mode != "flat")
		var hovered: bool = (id == hovered_layer)
		if selected:
			plate.material_override = m_accent
			border.material_override = m_black
			lbl.modulate = Color("131519")
		elif hovered:
			plate.material_override = m_slate
			border.material_override = m_white
			lbl.modulate = Color("ffffff")
		else:
			plate.material_override = m_black
			border.material_override = m_slate
			lbl.modulate = Color("ededeb")


func cycle_level() -> void:
	var levels := [0.0, 0.5, 1.0]
	var idx := 0
	for i in levels.size():
		if is_equal_approx(draft_level, levels[i]):
			idx = (i + 1) % levels.size()
			break
	draft_level = levels[idx]
	if level_caption != null:
		level_caption.text = "LEVEL %dM" % int(roundf(draft_level * Model.WORLD_STEP))
	if level_indicator != null:
		level_indicator.position = PAD_ORIGIN + Vector3(0, 0.010 + draft_level * MINI_UNIT, 0)
		level_indicator.visible = draft_level > 0.01
	_update_status()


func cycle_rotation() -> void:
	rot_quarter = (rot_quarter + 1) % 4
	if rot_caption != null:
		rot_caption.text = "ROT %d°" % (rot_quarter * 90)
	_update_status()


func select_palette(pid: String) -> bool:
	if not color_unlocked():
		return false
	var resolved := Bauhaus.resolve_palette(pid)
	active_palette = resolved
	if palette_caption != null:
		palette_caption.text = Bauhaus.palette_label(active_palette)
	if palette_button != null and palette_button.get("released_color") != null:
		var chips: Array[Color] = Bauhaus.swatch_colors(active_palette)
		palette_button.released_color = chips[1]
	if worker_assemblage != null and is_instance_valid(worker_assemblage) and worker_assemblage.has_method("set_palette_mode"):
		worker_assemblage.call("set_palette_mode", active_palette)
	_rebuild_tile_icons()
	refresh_tiles()
	refresh_palette_tiles()
	save_studio_build()
	redraw_all()
	if status_label != null:
		status_label.text = "PALETTE: %s" % str(Bauhaus.PALETTES[active_palette].title).to_upper()
	return true


func cycle_palette() -> void:
	if not color_unlocked():
		return
	var idx: int = Bauhaus.PALETTE_ORDER.find(active_palette)
	var next_id: String = Bauhaus.PALETTE_ORDER[(idx + 1) % Bauhaus.PALETTE_ORDER.size()]
	select_palette(next_id)


func toggle_palette() -> void:
	cycle_palette()


func _rebuild_tile_icons() -> void:
	for id in tile_nodes:
		if id == "erase":
			continue
		var info: Dictionary = tile_nodes[id]
		var holder: Node3D = info.icon
		work.clear_children(holder)
		var icon_mesh := _make_tile_icon(id, bool(info.unlocked))
		if icon_mesh != null:
			holder.add_child(icon_mesh)


func refresh_palette_tiles() -> void:
	if palette_nodes.is_empty():
		return
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")
	var hovered_pal: String = str(hover_state.get("palette", ""))
	for pid in palette_nodes:
		var info: Dictionary = palette_nodes[pid]
		var selected: bool = (pid == active_palette)
		var hovered: bool = (pid == hovered_pal)
		var plate: MeshInstance3D = info.plate
		var border: MeshInstance3D = info.border
		var lbl: Label3D = info.label
		if selected:
			plate.material_override = m_accent
			border.material_override = m_black
			lbl.modulate = Color("131519")
		elif hovered:
			plate.material_override = m_slate
			border.material_override = m_white
			lbl.modulate = Color("ffffff")
		else:
			plate.material_override = m_black
			border.material_override = m_slate
			lbl.modulate = Color("ededeb")


func clear_playground() -> void:
	if work.visit != null and work.visit.active:
		return
	var before: Array = work.model.records.duplicate(true)
	work.model.records.clear()
	play_objects.clear()
	work.remember_edit(before)
	save_studio_build()
	redraw_all()
	status_label.text = "GRID CLEARED · PULL TO STAMP OR UNDO"


func refresh_tiles() -> void:
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_slate := Bauhaus.mat("slate", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var m_accent := Bauhaus.mat("accent", "monochrome")
	var hovered_tile: String = str(hover_state.get("tile", ""))
	for id in tile_nodes:
		var info: Dictionary = tile_nodes[id]
		var unlocked: bool = bool(info.unlocked)
		var selected: bool = (id == active_tool)
		var hovered: bool = (id == hovered_tile)
		var plate: MeshInstance3D = info.plate
		var border: MeshInstance3D = info.border
		var lbl: Label3D = info.label
		if selected:
			plate.material_override = m_accent
			border.material_override = m_black
			lbl.modulate = Color("131519")
			if id in ["point", "rod", "rod_short"] and effective_phase() == "monochrome":
				_override_all(info.icon, m_black)
		elif hovered and unlocked:
			plate.material_override = m_slate
			border.material_override = m_white
			lbl.modulate = Color("ffffff")
			if id in ["point", "rod", "rod_short"] and effective_phase() == "monochrome":
				_override_all(info.icon, m_white)
		elif unlocked:
			plate.material_override = m_black
			border.material_override = m_slate
			lbl.modulate = Color("ededeb")
			if id in ["point", "rod", "rod_short"] and effective_phase() == "monochrome":
				_override_all(info.icon, m_white)
		else:
			plate.material_override = m_black
			border.material_override = m_black
			lbl.modulate = Color("555c66")


func _update_status() -> void:
	if status_label == null:
		return
	var nice: String = active_tool.to_upper().replace("_", " ")
	var lvl_m := int(roundf(draft_level * Model.WORLD_STEP))
	if hover_state.has("palette"):
		var pid: String = str(hover_state.palette)
		status_label.text = "CLICK PALETTE: %s" % Bauhaus.palette_label(pid)
	elif hover_state.has("tile"):
		var tid: String = str(hover_state.tile)
		var tinfo: Dictionary = tile_nodes[tid]
		status_label.text = ("CLICK TO PICK: %s" % str(tinfo.spec.label)) if bool(tinfo.unlocked) else ("LOCKED · FLOOR %d" % int(tinfo.spec.floor))
	elif hover_state.has("layer"):
		var lid: String = str(hover_state.layer)
		status_label.text = "CLICK LAYER: %s" % lid.to_upper().replace("_", " ")
	elif hover_state.has("erase"):
		status_label.text = "PULL / GRIP: REMOVE PIECE"
	elif hover_state.has("stamp") or hover_state.has("stamp_objects"):
		var arr_tag: String = (" · " + array_mode.to_upper()) if array_mode != "1x" else ""
		status_label.text = "PULL: STAMP %s · LVL %dM%s" % [nice, lvl_m, arr_tag]
	else:
		var pal_tag: String = (" · " + Bauhaus.palette_label(active_palette)) if color_unlocked() else ""
		var arr_tag: String = (" · " + array_mode.to_upper()) if array_mode != "1x" else ""
		status_label.text = "HAND: %s · LVL %dM · ROT %d°%s%s" % [nice, lvl_m, rot_quarter * 90, pal_tag, arr_tag]


# ── Rendering both Miniature (1:16) and Glass Box (1:4) from the exact same record ──

func redraw_all() -> void:
	if not _studio_ready:
		return
	var phase := effective_phase()
	var records: Array[Dictionary] = work.geometry_records()

	# 0. Basin Surface (Randomness Spiky Basin / Configurable Smooth Noise Basin) at BOTH 1:16 & 1:4!
	if mini_basin != null:
		work.clear_children(mini_basin)
		if basin_mode != "flat":
			var pad_w: float = (DOMAIN_MAX.x - DOMAIN_MIN.x) * MINI_UNIT
			var pad_d: float = (DOMAIN_MAX.z - DOMAIN_MIN.z) * MINI_UNIT
			var mb := Layer.build_basin_surface(basin_mode, pad_w, pad_d, 0.0, MINI_UNIT / Model.WORLD_STEP, phase, noise_config, false)
			mini_basin.add_child(mb)

	if glass_basin != null and (work.visit == null or not work.visit.active):
		work.clear_children(glass_basin)
		if basin_mode != "flat":
			var field_w: float = (DOMAIN_MAX.x - DOMAIN_MIN.x) * work.output_unit()
			var field_d: float = (DOMAIN_MAX.z - DOMAIN_MIN.z) * work.output_unit()
			var gb := Layer.build_basin_surface(basin_mode, field_w, field_d, GLASS_OFFSET.z, STUDIO_SCALE, phase, noise_config, true)
			glass_basin.add_child(gb)

	# 1. Miniature on drafting pad (1:16 scale, non-colliding crisp architectural model).
	work.clear_children(mini_built)
	for r in records:
		var vis := Bauhaus.visual(r, MINI_UNIT, phase)
		if panel_pattern != "plain" and r.kind in ["panel", "quad"]:
			_apply_panel_pattern(vis, r.kind, phase)
		var pose := Model.pose(r)
		pose.origin *= MINI_UNIT
		vis.transform = pose
		mini_built.add_child(vis)
	for ob in play_objects:
		var m_ob := _make_play_object_mini(ob, MINI_UNIT, phase)
		var p_ob := Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2])) * MINI_UNIT
		m_ob.position = p_ob
		m_ob.rotation.y = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5
		mini_built.add_child(m_ob)

	# 2. Live 1:4 scale physical copy inside the 6.6 m glass box (unless visitor is actively standing inside!).
	if work.visit == null or not work.visit.active:
		work.fitted_offset = GLASS_OFFSET
		var unit: float = work.output_unit()
		var structure: Node3D = work.output.get_node("Structure")
		work.clear_children(structure)
		for r in records:
			var body: PhysicsBody3D = PrefabPiece.new() if Model.is_prefab(r.kind) else StaticBody3D.new()
			body.collision_layer = 7 if Model.is_prefab(r.kind) else 1
			body.name = "Built" + str(structure.get_child_count())
			var gvis := Bauhaus.visual(r, unit, phase)
			if panel_pattern != "plain" and r.kind in ["panel", "quad"]:
				_apply_panel_pattern(gvis, r.kind, phase)
			body.add_child(gvis)
			var shape := CollisionShape3D.new()
			shape.name = "Collision"
			shape.shape = Bauhaus.shape_for(r, unit)
			body.add_child(shape)
			structure.add_child(body)
			body.transform = work.copy_pose(r)
			body.set_meta("workshop_kind", r.kind)
			if Model.is_prefab(r.kind):
				# Keep ramps/pyramids seated cleanly as walkable fixtures on the studio floor.
				body.freeze = true
				body.grid = work.output
				body.grid_offset = body.transform.origin - Model.pose(r).origin * unit
				body.unit_scale = unit / Model.WORLD_STEP * Model.prefab_span(r)
				body.gravity_scale = unit / Model.WORLD_STEP
		for ob in play_objects:
			var live_ob := _spawn_play_object_live(ob, unit, phase)
			if live_ob != null:
				structure.add_child(live_ob)
		work.built = work.visible_records().duplicate(true)

	if count_label != null:
		var pts: int = work.model.points().size()
		var rods: int = work.model.records.filter(func(r): return r.kind in ["rod", "rod_short", "diag"]).size()
		var faces: int = work.model.records.filter(func(r): return r.kind in ["panel", "quad"]).size()
		var solids: int = work.model.records.filter(func(r): return Model.is_prefab(r.kind)).size()
		var obj_tag: String = (" · %d OBJ" % play_objects.size()) if not play_objects.is_empty() else ""
		count_label.text = "%d PTS · %d RODS · %d FACES · %d SOLIDS%s" % [pts, rods, faces, solids, obj_tag]
	_update_status()


func _apply_panel_pattern(vis: Node3D, kind: String, phase: String) -> void:
	var pal: Dictionary = Bauhaus.PALETTES.get(Bauhaus.resolve_palette(phase), Bauhaus.PALETTES["monochrome"])
	var base_col: Color = pal.get(kind, Color("ededeb")) as Color
	var pmat := Layer.pattern_material(base_col, panel_pattern, phase)
	for child in vis.get_children():
		if child is MeshInstance3D and not str(child.name).begins_with("Trim"):
			(child as MeshInstance3D).material_override = pmat


func _make_play_object_mini(ob: Dictionary, unit: float, phase: String) -> Node3D:
	var root := Node3D.new()
	var kind: String = str(ob.get("kind", "package"))
	root.name = "MiniObj_" + kind
	var mono: bool = (phase == "monochrome")
	var m_black := Bauhaus.mat("frame", "monochrome")
	var m_white := Bauhaus.mat("quad", "monochrome")
	var s: float = unit * 0.5  # 1 m in miniature units
	match kind:
		"package":
			var box_col := m_white if mono else _flat_color_mat(Color("f0f0ec"))
			var rib_col := m_black if mono else _flat_color_mat(Color("b33871"))
			var plus_col := m_white if mono else _flat_color_mat(Color("28c98a"))
			_box(root, "PkgBody", Vector3(0, s * 0.28, 0), Vector3(s * 0.52, s * 0.52, s * 0.52), box_col, false)
			_box(root, "PkgRibA", Vector3(0, s * 0.28, 0), Vector3(s * 0.54, s * 0.54, s * 0.10), rib_col, false)
			_box(root, "PkgRibB", Vector3(0, s * 0.28, 0), Vector3(s * 0.10, s * 0.54, s * 0.54), rib_col, false)
			_box(root, "PkgPlusH", Vector3(0, s * 0.56, 0), Vector3(s * 0.28, s * 0.04, s * 0.09), plus_col, false)
			_box(root, "PkgPlusV", Vector3(0, s * 0.56, 0), Vector3(s * 0.09, s * 0.04, s * 0.28), plus_col, false)
		"coin":
			var mi := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = s * 0.24
			cyl.bottom_radius = s * 0.24
			cyl.height = s * 0.08
			mi.mesh = cyl
			mi.rotation.x = PI * 0.5
			mi.position = Vector3(0, s * 0.42, 0)
			mi.material_override = m_white if mono else _flat_color_mat(Color("f0c430"))
			root.add_child(mi)
		"bomb":
			var mi := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = s * 0.28
			sph.height = s * 0.56
			mi.mesh = sph
			mi.position = Vector3(0, s * 0.30, 0)
			mi.material_override = m_black
			root.add_child(mi)
			var ring := MeshInstance3D.new()
			var tor := TorusMesh.new()
			tor.inner_radius = s * 0.38
			tor.outer_radius = s * 0.43
			ring.mesh = tor
			ring.position = Vector3(0, s * 0.04, 0)
			ring.material_override = m_white if mono else _flat_color_mat(Color("e0524d"))
			root.add_child(ring)
		"jump_pad":
			var pcol := m_black
			var glow := m_white if mono else _flat_color_mat(Color("38bdf8"))
			_box(root, "PadBase", Vector3(0, s * 0.05, 0), Vector3(s * 0.88, s * 0.08, s * 0.88), pcol, false)
			_box(root, "PadTop", Vector3(0, s * 0.10, 0), Vector3(s * 0.64, s * 0.03, s * 0.64), glow, false)
			_box(root, "PadArrow", Vector3(0, s * 0.22, -s * 0.10), Vector3(s * 0.16, s * 0.20, s * 0.28), glow, false)
		"iso_cutout":
			var outer := m_white if mono else _flat_color_mat(Color("e88aa8"))
			var cut := m_black
			# Crisp architectural representation of a 4x4x4 carved boolean/isosurface block!
			_box(root, "IsoL", Vector3(-s * 0.55, s * 0.65, 0), Vector3(s * 0.45, s * 1.30, s * 1.55), outer, false)
			_box(root, "IsoR", Vector3(s * 0.55, s * 0.65, 0), Vector3(s * 0.45, s * 1.30, s * 1.55), outer, false)
			_box(root, "IsoTop", Vector3(0, s * 1.15, 0), Vector3(s * 1.55, s * 0.32, s * 1.55), outer, false)
			_box(root, "IsoRim", Vector3(0, s * 0.04, 0), Vector3(s * 1.58, s * 0.06, s * 1.58), cut, false)
	return root


func _spawn_play_object_live(ob: Dictionary, unit: float, phase: String) -> Node3D:
	var kind: String = str(ob.get("kind", "package"))
	var mono: bool = (phase == "monochrome")
	var mount := Node3D.new()
	mount.name = "LiveObj_" + kind
	var at_v := Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2]))
	mount.position = at_v * unit + GLASS_OFFSET
	mount.rotation.y = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5

	var scene_path := ""
	var cfg: Dictionary = {}
	match kind:
		"package":
			scene_path = "res://commons/void/gift_cube.tscn"
			cfg = {"gift": "health_powerup", "health_boost": 25.0, "drop_powerup": true, "instant_powerup": true, "monochrome": mono, "motion": "idle", "support": false}
		"coin":
			scene_path = "res://commons/void/coin_pickup.tscn"
			cfg = {"battery_boost": 8.0, "monochrome": mono, "motion": "idle", "support": false}
		"bomb":
			scene_path = "res://commons/hazards/electrical_mine/rolling.tscn"
			cfg = {"behavior": "static", "monochrome": mono, "dna": "061", "show_sweep": true, "proximity_radius": 1.35, "shock_radius": 2.4, "battery_damage": 20.0, "rearm_seconds": 5.0}
		"jump_pad":
			scene_path = "res://commons/artifacts/force_pad/force_pad.tscn"
			cfg = {"forward_force": 5.0, "up_force": 6.0}
		"iso_cutout":
			scene_path = "res://commons/artifacts/iso_prefabs/iso_prefab.tscn"
			cfg = {"form": str(ob.get("form", "tunnel")), "finish": "cast" if mono else "provenance"}

	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return mount
	var packed := load(scene_path) as PackedScene
	if packed == null:
		return mount
	var inst := packed.instantiate() as Node3D
	inst.name = "Live_" + kind
	inst.scale = Vector3.ONE * STUDIO_SCALE
	for k in cfg:
		inst.set_meta("config_" + str(k), cfg[k])
	if kind == "iso_cutout":
		inst.set("form", str(cfg.get("form", "tunnel")))
		inst.set("finish", str(cfg.get("finish", "provenance")))
	mount.add_child(inst)
	if inst.has_method("apply_grid_config"):
		inst.call("apply_grid_config", cfg)
	return mount


func _flat_color_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.48
	return m


func save_studio_build() -> void:
	if not work.persist:
		return
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"version": 3, "floor": studio_floor, "color_palette": active_palette,
			"panel_pattern": panel_pattern, "basin_mode": basin_mode,
			"noise_config": noise_config, "play_objects": play_objects,
			"records": work.model.records,
		}, "\t"))


# ── Hand-principle aiming, picking, stamping & erasing (plugs straight into inventory_wand.gd) ──

func studio_active(hand: Node, aim: Node3D) -> bool:
	if not _studio_ready or not work._interactive or aim == null:
		return false
	if work.visit != null and work.visit.active:
		return false
	if hand != null:
		var holding = hand.get("current")
		if holding != null and str(holding) != "":
			return false
	# Only claim the empty hand when the player is near the drafting console AND aiming at the strip or pad!
	if aim.global_position.distance_to(to_global(PAD_ORIGIN)) > NEAR_CONSOLE:
		return false
	return not _compute_hover(aim).is_empty()


func studio_hide() -> void:
	hover_state = {}
	if mini_ghost != null:
		work.clear_children(mini_ghost)
	if aim_ray != null:
		aim_ray.visible = false
	refresh_tiles()
	refresh_palette_tiles()
	refresh_layer_tiles()


func studio_update(aim: Node3D, _hand: Node = null) -> void:
	_last_aim = aim
	work.clear_children(mini_ghost)
	hover_state = _compute_hover(aim)
	refresh_tiles()
	refresh_palette_tiles()
	refresh_layer_tiles()
	_update_status()
	if hover_state.is_empty():
		if aim_ray != null:
			aim_ray.visible = false
		return

	var ray_col := Color("f59e0b")
	var target_global: Vector3 = hover_state.get("hit_global", to_global(PAD_ORIGIN))
	if hover_state.has("tile") or hover_state.has("palette") or hover_state.has("layer"):
		ray_col = Color("fafaf6")
	elif hover_state.has("stamp_objects"):
		for ob: Dictionary in hover_state.stamp_objects:
			var g_ob := _make_play_object_mini(ob, MINI_UNIT, effective_phase())
			Bauhaus.apply_ghost(g_ob, Color(0.96, 0.62, 0.04, 0.64), 0.7)
			g_ob.position = Vector3(float(ob.at[0]), float(ob.at[1]), float(ob.at[2])) * MINI_UNIT
			g_ob.rotation.y = float(ob.get("turn", [0, 0, 0])[1]) * PI * 0.5
			mini_ghost.add_child(g_ob)
		ray_col = Color("f59e0b")
	elif hover_state.has("stamp"):
		for r: Dictionary in hover_state.stamp:
			var ghost_vis := Bauhaus.visual(r, MINI_UNIT, effective_phase())
			Bauhaus.apply_ghost(ghost_vis, Color(0.96, 0.62, 0.04, 0.58), 0.65)
			var pose := Model.pose(r)
			pose.origin *= MINI_UNIT
			ghost_vis.transform = pose
			mini_ghost.add_child(ghost_vis)
		ray_col = Color("f59e0b")
	elif hover_state.has("erase"):
		var idx: int = int(hover_state.erase)
		var r: Dictionary = Model.fit_record(work.model.records[idx], work.visible_records())
		var ghost_vis := Bauhaus.visual(r, MINI_UNIT, effective_phase())
		Bauhaus.apply_ghost(ghost_vis, Color(0.94, 0.36, 0.34, 0.72), 0.7)
		var pose := Model.pose(r)
		pose.origin *= MINI_UNIT
		ghost_vis.transform = pose
		mini_ghost.add_child(ghost_vis)
		ray_col = Color("ef5a54")
	_draw_ray(aim.global_position, target_global, ray_col)


func studio_press(aim: Node3D, hand: Node = null) -> String:
	studio_update(aim, hand)
	if hover_state.is_empty():
		return ""
	if hover_state.has("layer"):
		var lid: String = str(hover_state.layer)
		if lid == "array_mode":
			cycle_array_mode()
			return "layer_action"
		if lid == "panel_pattern":
			cycle_panel_pattern()
			return "layer_action"
		if lid == "rnd_walk":
			generate_random_walk()
			return "layer_action"
		if lid == "basin_mode":
			cycle_basin_surface()
			return "layer_action"
		var ok_l := select_tool(lid)
		work.space_notice = status_label.text
		return "selected" if ok_l else "refused"
	if hover_state.has("palette"):
		var ok := select_palette(str(hover_state.palette))
		work.space_notice = status_label.text
		return "palette" if ok else "refused"
	if hover_state.has("tile"):
		var ok := select_tool(str(hover_state.tile))
		work.space_notice = status_label.text
		return "selected" if ok else "refused"
	if hover_state.has("erase"):
		var ok := _remove_index(int(hover_state.erase))
		return "removed" if ok else "refused"
	if hover_state.has("stamp_objects"):
		for ob: Dictionary in hover_state.stamp_objects:
			play_objects.append(ob.duplicate(true))
		save_studio_build()
		studio_hide()
		redraw_all()
		work.space_notice = "Placed %s" % active_tool.to_upper()
		return "placed"
	if hover_state.has("stamp"):
		var before: Array = work.model.records.duplicate(true)
		var added := 0
		for r: Dictionary in hover_state.stamp:
			if work.model.add(r, work.tier):
				added += 1
		if added == 0:
			work.model.records.assign(before)
			work.space_notice = "Cannot place here"
			return "refused"
		work.remember_edit(before)
		save_studio_build()
		studio_hide()
		redraw_all()
		work.space_notice = "Stamped %s" % active_tool.to_upper()
		return "placed"
	return "refused"


func studio_grip(aim: Node3D = null) -> bool:
	var use_aim: Node3D = aim if aim != null else _last_aim
	if use_aim != null and is_instance_valid(use_aim):
		hover_state = _compute_hover(use_aim)
	# If hovering a placed piece (or aiming at one even while holding a build template), remove it directly!
	if hover_state.has("erase"):
		return _remove_index(int(hover_state.erase))
	if use_aim != null and is_instance_valid(use_aim):
		var erase_hit := _find_placed_under_ray(use_aim)
		if erase_hit.has("erase"):
			return _remove_index(int(erase_hit.erase))
	if not hover_state.is_empty():
		cycle_rotation()
		return true
	return false


func _remove_index(idx: int) -> bool:
	if idx < 0 or idx >= work.model.records.size():
		return false
	var res: Dictionary = work.model.revision(idx, {})
	if not res.ok:
		work.space_notice = "Supporting another piece — remove top piece first (or press UNDO)"
		status_label.text = "REMOVE TOP PIECE FIRST"
		return false
	var before: Array = work.model.records.duplicate(true)
	work.model.records.assign(res.records)
	work.remember_edit(before)
	save_studio_build()
	studio_hide()
	redraw_all()
	work.space_notice = "Removed piece"
	return true


func _compute_hover(aim: Node3D) -> Dictionary:
	var a_global: Vector3 = aim.global_position
	var d_global: Vector3 = -aim.global_basis.z.normalized()

	# 1. Check flat Template Strip tiles first (crisp plane intersection in strip_root local space).
	var s_a: Vector3 = strip_root.to_local(a_global)
	var s_b: Vector3 = strip_root.to_local(a_global + d_global * AIM_REACH)
	var s_d: Vector3 = s_b - s_a
	if absf(s_d.y) > 0.0001:
		var t_plane: float = (0.012 - s_a.y) / s_d.y
		if t_plane > 0.0 and t_plane <= 1.0:
			var hit_s: Vector3 = s_a + s_d * t_plane
			for id in tile_nodes:
				var info: Dictionary = tile_nodes[id]
				var pos: Vector3 = (info.root as Node3D).position
				var sz: Vector2 = info.size
				if absf(hit_s.x - pos.x) <= sz.x * 0.52 and absf(hit_s.z - pos.z) <= sz.y * 0.55:
					return {"tile": id, "hit_global": strip_root.to_global(hit_s)}

	# 1B. Check Far-Edge Color-Sequence Palette Chooser Strip (unlocked on F28+ & F209).
	if palette_strip_root != null and not palette_nodes.is_empty():
		var p_a: Vector3 = palette_strip_root.to_local(a_global)
		var p_b: Vector3 = palette_strip_root.to_local(a_global + d_global * AIM_REACH)
		var p_d: Vector3 = p_b - p_a
		if absf(p_d.y) > 0.0001:
			var t_pal: float = (0.012 - p_a.y) / p_d.y
			if t_pal > 0.0 and t_pal <= 1.0:
				var hit_p: Vector3 = p_a + p_d * t_pal
				for pid in palette_nodes:
					var pinfo: Dictionary = palette_nodes[pid]
					var ppos: Vector3 = (pinfo.root as Node3D).position
					var psz: Vector2 = pinfo.size
					if absf(hit_p.x - ppos.x) <= psz.x * 0.52 and absf(hit_p.z - ppos.z) <= psz.y * 0.55:
						return {"palette": pid, "hit_global": palette_strip_root.to_global(hit_p)}

	# 1C. Check Sequence General-Intellect Capability Strip (unlocked F13+ Transformation onward).
	if layer_strip_root != null and not layer_nodes.is_empty():
		var l_a: Vector3 = layer_strip_root.to_local(a_global)
		var l_b: Vector3 = layer_strip_root.to_local(a_global + d_global * AIM_REACH)
		var l_d: Vector3 = l_b - l_a
		if absf(l_d.y) > 0.0001:
			var t_lay: float = (0.012 - l_a.y) / l_d.y
			if t_lay > 0.0 and t_lay <= 1.0:
				var hit_l: Vector3 = l_a + l_d * t_lay
				for lid in layer_nodes:
					var linfo: Dictionary = layer_nodes[lid]
					var lpos: Vector3 = (linfo.root as Node3D).position
					var lsz: Vector2 = linfo.size
					if absf(hit_l.x - lpos.x) <= lsz.x * 0.52 and absf(hit_l.z - lpos.z) <= lsz.y * 0.55:
						return {"layer": lid, "hit_global": layer_strip_root.to_global(hit_l)}

	# 2. If ERASE is active, test placed miniature pieces directly.
	if active_tool == "erase":
		return _find_placed_under_ray(aim)

	# 3. Intersect aim ray with the active drafting elevation plane inside mini_root.
	var m_a: Vector3 = mini_root.to_local(a_global)
	var m_b: Vector3 = mini_root.to_local(a_global + d_global * AIM_REACH)
	var m_d: Vector3 = m_b - m_a
	var plane_y: float = draft_level * MINI_UNIT
	if absf(m_d.y) < 0.0001:
		return {}
	var t_grid: float = (plane_y - m_a.y) / m_d.y
	if t_grid <= 0.0 or t_grid > 1.0:
		return {}
	var hit_m: Vector3 = m_a + m_d * t_grid
	var addr: Vector3 = hit_m / MINI_UNIT
	if addr.x < DOMAIN_MIN.x - 0.15 or addr.x > DOMAIN_MAX.x + 0.15 or addr.z < DOMAIN_MIN.z - 0.15 or addr.z > DOMAIN_MAX.z + 0.15:
		return {}
	addr.x = clampf(addr.x, DOMAIN_MIN.x, DOMAIN_MAX.x)
	addr.z = clampf(addr.z, DOMAIN_MIN.z, DOMAIN_MAX.z)
	addr.y = draft_level

	if active_tool in ["package", "coin", "bomb", "jump_pad", "iso_cutout"]:
		var objs: Array[Dictionary] = _plan_play_objects(active_tool, addr)
		if objs.is_empty():
			return {}
		return {"stamp_objects": objs, "hit_global": mini_root.to_global(hit_m)}

	var plan: Array[Dictionary] = _plan_for_tool_array(active_tool, addr)
	if plan.is_empty():
		return {}
	return {"stamp": plan, "hit_global": mini_root.to_global(hit_m)}


func _plan_play_objects(kind: String, addr: Vector3) -> Array[Dictionary]:
	var snapped := Vector3(roundf(addr.x * 2.0) * 0.5, draft_level, roundf(addr.z * 2.0) * 0.5)
	var out: Array[Dictionary] = []
	var offsets: Array[Vector3] = Layer.array_offsets(array_mode, rot_quarter) if array_mode != "1x" else [Vector3.ZERO]
	for off in offsets:
		var pos: Vector3 = snapped + off
		if not work.model.in_domain(pos):
			continue
		var rec: Dictionary = {"kind": kind, "at": Model.arr(pos), "turn": [0, rot_quarter, 0]}
		if kind == "iso_cutout":
			rec["form"] = Layer.ISO_FORMS[rot_quarter % Layer.ISO_FORMS.size()]
		out.append(rec)
	return out


func _plan_for_tool_array(tool: String, addr: Vector3) -> Array[Dictionary]:
	if array_mode == "1x":
		return _plan_for_tool(tool, addr)
	var offsets: Array[Vector3] = Layer.array_offsets(array_mode, rot_quarter)
	var sim = work.model._clone_empty()
	sim.records = work.model.records.duplicate(true)
	var combined: Array[Dictionary] = []
	var saved_records: Array = work.model.records.duplicate(true)
	for off in offsets:
		var p_addr := addr + off
		if not sim.in_domain(p_addr):
			continue
		work.model.records.assign(sim.records)
		var sub := _plan_for_tool(tool, p_addr)
		for r in sub:
			if sim.add(r, work.tier):
				combined.append(r)
	work.model.records.assign(saved_records)
	return combined


func _plan_for_tool(tool: String, addr: Vector3) -> Array[Dictionary]:
	var lvl: float = addr.y
	match tool:
		"point":
			var snapped := Vector3(roundf(addr.x * 2.0) * 0.5, lvl, roundf(addr.z * 2.0) * 0.5)
			return _build_point_records(snapped)
		"rod_short":
			var snapped := Vector3(floorf(addr.x * 2.0) * 0.5, lvl, floorf(addr.z * 2.0) * 0.5)
			var axis := 0 if (rot_quarter % 2 == 0) else 2
			return _build_rod_records(snapped, 0.5, axis)
		"rod":
			var snapped := Vector3(floorf(addr.x), lvl, floorf(addr.z))
			var axis := 0 if (rot_quarter % 2 == 0) else 2
			return _build_rod_records(snapped, 1.0, axis)
		"panel":
			var snapped := Vector3(floorf(addr.x), lvl, floorf(addr.z))
			return _build_triangle_records(snapped, rot_quarter % 4, 1.0)
		"quad":
			var snapped := Vector3(floorf(addr.x), lvl, floorf(addr.z))
			return _build_quad_records(snapped, 1.0, true)
		"wedge":
			var snapped := Vector3(roundf(addr.x * 2.0) * 0.5, lvl, roundf(addr.z * 2.0) * 0.5)
			return _build_solid_records("wedge", snapped, rot_quarter)
		"pyramid":
			var snapped := Vector3(roundf(addr.x * 2.0) * 0.5, lvl, roundf(addr.z * 2.0) * 0.5)
			return _build_solid_records("pyramid", snapped, rot_quarter)
	return []


func _find_placed_under_ray(aim: Node3D) -> Dictionary:
	var a: Vector3 = mini_root.to_local(aim.global_position)
	var b: Vector3 = mini_root.to_local(aim.global_position - aim.global_basis.z.normalized() * AIM_REACH)
	var length: float = a.distance_to(b)
	if length < 0.001:
		return {}
	var d: Vector3 = (b - a) / length
	var best_s := INF
	var best_idx := -1
	var best_at := Vector3.ZERO
	# Prefer faces/solids slightly over supporting rods/points so erasing removes top-down cleanly.
	for i in work.model.records.size():
		var r: Dictionary = work.model.records[i]
		var center: Vector3 = Model.pose(r).origin * MINI_UNIT
		var radius: float = 0.055 if r.kind in ["quad", "panel", "wedge", "pyramid"] else 0.035
		var s: float = clampf((center - a).dot(d), 0.0, length)
		var dist: float = (a + d * s).distance_to(center)
		if dist <= radius:
			var bias: float = 0.0 if r.kind in ["quad", "panel", "wedge", "pyramid"] else (0.02 if r.kind in ["rod", "rod_short", "diag"] else 0.04)
			if s + bias < best_s:
				best_s = s + bias
				best_idx = i
				best_at = center
	if best_idx < 0:
		return {}
	return {"erase": best_idx, "hit_global": mini_root.to_global(best_at)}


func _draw_ray(from: Vector3, to: Vector3, colour: Color) -> void:
	if aim_ray == null:
		return
	var length := from.distance_to(to)
	if length < 0.01:
		aim_ray.visible = false
		return
	(aim_ray.material_override as StandardMaterial3D).albedo_color = colour
	aim_ray.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, (to - from) / length)) * Basis.from_scale(Vector3(1, length, 1)), (from + to) * 0.5)
	aim_ray.visible = true


static func _box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, material: Material, solid: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.position = at
	parent.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.name = node_name + "_Body"
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func _label(parent: Node3D, text: String, at: Vector3, rot_deg: Vector3, font_sz: int, px_sz: float, col: Color) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font_sz
	lb.pixel_size = px_sz
	lb.modulate = col
	lb.outline_size = 0
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.position = at
	lb.rotation_degrees = rot_deg
	parent.add_child(lb)
	return lb
