extends Node3D
class_name PatternMachineB

# @identity
# essence: a HOLOGRAPHIC PATTERN PRINTER — a sci-fi press that does not show you a
#          finished tiling, it PRINTS one. The player edits a small floating
#          holographic motif grid on the tilted print-head console; the machine
#          symmetrises that fragment through one of the 17 wallpaper groups and
#          EXTRUDES the result two ways at once: a glowing sheet that scrolls
#          upward out of the print head, and a carpet pressed onto the floor.
# desire: to fuse the editor and the machine. pattern_maker_station lets you paint
#         a motif; pattern_loom manufactures a fixed one. This wants both — you
#         touch the hologram, and the press immediately re-prints the world.
# critical_parameter: wallpaper_group — the symmetry operator. A 5x5 painted
#         fragment is almost nothing; the group is the program that multiplies it
#         into endless printed fabric. 17 groups, a hard constraint on 2D repetition.
# triggers: touch the holographic cells (Area3D + hands) to paint with the selected
#           ink; palette buttons pick the ink; CYCLE advances the group; SEED rerolls
#           a fresh motif; CLEAR blanks it; PRINT pulses the head. Every edit re-bakes
#           the symmetric texture and the sheet + carpet update live.
# emerges: the same federated move as pattern_loom — reuse WallpaperGroups +
#          PatternSim PALETTES, wrap them in an apparatus — but here the apparatus
#          is INTERACTIVE. The motif you paint is the cartridge; the printer runs it.
# needs: a dark machine frame with emissive accents [present]; a tilted holographic
#        edit console with touch-paint cells [present]; a print head with feed rollers
#        [present]; an extruded sheet scrolling up + a floor carpet [present]; DNA for
#        group / palette / motif_seed / machine params [present].
# relationships: sibling to pattern_loom (it manufactures a fixed pattern; this lets
#        you edit the cartridge live) and re-bodies pattern_maker_station (that paints
#        onto a plate; this paints into a PRESS). Reuses WallpaperGroups.get_symmetric_color
#        and PatternSim.PALETTES. Machine vocabulary from props-dna-gallery / conveyor_belt.
# truth: a pattern is a program plus a fragment. Hand someone the fragment and the
#        press, and they discover that constraint, not complexity, is where structure
#        comes from. You print architecture out of almost nothing.

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")
const WallpaperGroupsScript = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

# ── DNA ────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m).
@export var group: String = "p4m"
## Palette name (bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome).
@export var palette: String = "memphis"
## Motif seed — rerolls the painted fragment when SEED is pressed.
@export var motif_seed: int = 7
## Edit grid is motif_size x motif_size (3-8).
@export var motif_size: int = 5
## Fill density when (re)seeding the motif.
@export var density: float = 0.5

@export_group("Machine")
@export var frame_color: Color = Color(0.10, 0.10, 0.13)
@export var accent_color: Color = Color(0.35, 0.95, 0.85)   # cyan-mint sci-fi accent
@export var holo_color: Color = Color(0.40, 0.95, 1.0)      # holographic grid glow
@export var sheet_width: float = 1.1                        # printed sheet / carpet width
@export var sheet_height: float = 1.8                       # how tall the extruded sheet rises
@export var carpet_length: float = 2.2                      # floor carpet run
@export var scroll_speed: float = 0.14                      # uv feed speed
@export var carpet_repeats: int = 6                         # tile repeats across the output

# ── Layout constants ───────────────────────────────────────────────────
const CONSOLE_TILT_DEG := -32.0      # tilt of the holographic edit console
const CELL := 0.075                  # metres per holo cell
const TEXTURE_RES := 256             # baked symmetric texture resolution

# ── State ──────────────────────────────────────────────────────────────
var _grid: Array = []                # motif_size x motif_size, color indices into _palette
var _palette: Array = []             # Array of Color, resolved from PatternSim.PALETTES
var _ink: int = 1                    # selected paint index
var _group_index: int = 10           # index into GROUP_ORDER (p4m default)

const GROUP_ORDER: Array = [
	WallpaperGroupsScript.Group.P1,   WallpaperGroupsScript.Group.P2,
	WallpaperGroupsScript.Group.PM,   WallpaperGroupsScript.Group.PG,
	WallpaperGroupsScript.Group.CM,   WallpaperGroupsScript.Group.PMM,
	WallpaperGroupsScript.Group.PMG,  WallpaperGroupsScript.Group.PGG,
	WallpaperGroupsScript.Group.CMM,  WallpaperGroupsScript.Group.P4,
	WallpaperGroupsScript.Group.P4M,  WallpaperGroupsScript.Group.P4G,
	WallpaperGroupsScript.Group.P3,   WallpaperGroupsScript.Group.P3M1,
	WallpaperGroupsScript.Group.P31M, WallpaperGroupsScript.Group.P6,
	WallpaperGroupsScript.Group.P6M,
]
const GROUP_NAMES: Array = [
	"p1","p2","pm","pg","cm","pmm","pmg","pgg","cmm",
	"p4","p4m","p4g","p3","p3m1","p31m","p6","p6m",
]

# ── Scene refs ─────────────────────────────────────────────────────────
var PUSH_BUTTON: PackedScene
var _console_root: Node3D            # holds the tilted holographic edit grid
var _cell_mats: Array = []           # motif_size x motif_size StandardMaterial3D (holo cells)
var _ink_indicators: Array = []      # per-palette glow dots
var _touch_area: Area3D
var _last_cell: Vector2i = Vector2i(-1, -1)

var _output_tex: ImageTexture
var _sheet_mat: StandardMaterial3D   # vertical extruded sheet
var _carpet_mat: StandardMaterial3D  # floor carpet
var _group_label: Label3D
var _emissive_mats: Array[StandardMaterial3D] = []  # head/accent strips to pulse
var _roller: MeshInstance3D
var _elapsed: float = 0.0

# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	_read_overrides()
	_resolve_palette()
	_seed_motif()

	_build_frame()
	_build_print_head()
	_build_console()
	_build_palette_buttons()
	_build_controls()
	_build_output_sheet()
	_build_carpet()
	_build_touch_area()
	_build_capture_camera()
	_rebake_output()

	print("[PatternMachineB] Built — %dx%d motif, group %s, palette %s" % [
		motif_size, motif_size, GROUP_NAMES[_group_index], palette])


func _process(delta: float) -> void:
	_elapsed += delta
	_check_touch_paint()
	# Feed: sheet scrolls up, carpet scrolls forward.
	if _sheet_mat:
		var so := _sheet_mat.uv1_offset
		so.y = fposmod(so.y - scroll_speed * delta, 1.0)
		_sheet_mat.uv1_offset = so
	if _carpet_mat:
		var co := _carpet_mat.uv1_offset
		co.y = fposmod(co.y + scroll_speed * delta, 1.0)
		_carpet_mat.uv1_offset = co
	# Pulse the print-head accents — the machine is always running.
	var pulse := 1.8 + 1.4 * (0.5 + 0.5 * sin(_elapsed * 5.0))
	for m in _emissive_mats:
		m.emission_energy_multiplier = pulse
	if _roller:
		_roller.rotate_z(delta * 4.0)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("group"):
		group = str(config["group"])
		_group_index = _group_name_to_index(group)
	if config.has("palette"): palette = str(config["palette"])
	if config.has("motif_seed"): motif_seed = int(config["motif_seed"])
	if config.has("motif_size"): motif_size = clampi(int(config["motif_size"]), 3, 8)
	if config.has("density"): density = clampf(float(config["density"]), 0.0, 1.0)
	if config.has("sheet_width"): sheet_width = float(config["sheet_width"])
	if config.has("sheet_height"): sheet_height = float(config["sheet_height"])
	if config.has("carpet_length"): carpet_length = float(config["carpet_length"])
	if config.has("carpet_repeats"): carpet_repeats = int(config["carpet_repeats"])
	if config.has("scroll_speed"): scroll_speed = float(config["scroll_speed"])
	# Rebuild from scratch with the new DNA.
	for c in get_children():
		c.queue_free()
	_cell_mats.clear(); _ink_indicators.clear(); _emissive_mats.clear()
	_last_cell = Vector2i(-1, -1)
	call_deferred("_ready")


func _read_overrides() -> void:
	for k in ["group", "palette"]:
		if has_meta("config_%s" % k):
			set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"):
		motif_seed = int(str(get_meta("config_motif_seed")))
	if has_meta("config_motif_size"):
		motif_size = clampi(int(str(get_meta("config_motif_size"))), 3, 8)
	_group_index = _group_name_to_index(group)


# ═══════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════

func _resolve_palette() -> void:
	var raw: Array = PatternSim.PALETTES.get(palette, PatternSim.PALETTES["memphis"])
	_palette.clear()
	for c in raw:
		_palette.append(Color(float(c[0]), float(c[1]), float(c[2])))
	# Guarantee at least a couple of inks.
	if _palette.size() < 2:
		_palette.append(Color(0.1, 0.1, 0.12))


func _seed_motif() -> void:
	# Deterministic fragment from the seed — a starting point the player then edits.
	var n_colors: int = _palette.size()
	_grid = PatternSim.generate_motif(motif_size, n_colors, motif_seed, density)
	# generate_motif returns grid[y][x] color indices already in 0..n_colors-1.


func _group_name_to_index(gname: String) -> int:
	var lname := gname.to_lower()
	var idx := GROUP_NAMES.find(lname)
	return idx if idx >= 0 else 10  # default p4m


# ═══════════════════════════════════════════════════════════════════════
# BUILDERS — MACHINE BODY
# ═══════════════════════════════════════════════════════════════════════

func _build_frame() -> void:
	# Base chassis the whole press stands on.
	var half_w := sheet_width * 0.5 + 0.28
	_box(Vector3(half_w * 2.0, 0.12, 0.9), Vector3(0, 0.06, 0.0), frame_color.lightened(0.04))
	# Two vertical towers carrying the print head up high.
	_box(Vector3(0.14, sheet_height + 0.5, 0.16), Vector3(-half_w, (sheet_height + 0.5) * 0.5, -0.18), frame_color)
	_box(Vector3(0.14, sheet_height + 0.5, 0.16), Vector3(half_w, (sheet_height + 0.5) * 0.5, -0.18), frame_color)
	# Top crossbeam tying the towers together.
	_box(Vector3(half_w * 2.0 + 0.14, 0.12, 0.18), Vector3(0, sheet_height + 0.5, -0.18), frame_color)
	# Emissive accent rails up each tower — reads as "powered apparatus".
	_emissive_box(Vector3(0.02, sheet_height + 0.4, 0.02), Vector3(-half_w + 0.08, (sheet_height + 0.4) * 0.5, -0.10), accent_color, 1.8)
	_emissive_box(Vector3(0.02, sheet_height + 0.4, 0.02), Vector3(half_w - 0.08, (sheet_height + 0.4) * 0.5, -0.10), accent_color, 1.8)


func _build_print_head() -> void:
	# The print head: a dark housing near the floor from which the sheet rises.
	var head_y := 0.42
	var hw := sheet_width * 0.5 + 0.12
	_box(Vector3(hw * 2.0, 0.22, 0.34), Vector3(0, head_y, 0.0), frame_color.lightened(0.06))
	# Glowing extrusion slot across the front — the sheet emerges here.
	var slot := _emissive_box(
		Vector3(sheet_width + 0.04, 0.02, 0.02),
		Vector3(0, head_y + 0.13, 0.16),
		accent_color, 2.4)
	_emissive_mats.append(slot.material_override as StandardMaterial3D)
	# Feed roller spanning the slot (spins in _process).
	_roller = _cyl(sheet_width + 0.1, 0.05, Vector3(0, head_y + 0.13, 0.10), frame_color.lightened(0.15))
	_roller.rotation_degrees = Vector3(0, 0, 90)
	# A pair of warning-grade indicator studs on the head face.
	for sx in [-1.0, 1.0]:
		var stud := _emissive_box(Vector3(0.03, 0.03, 0.02), Vector3(sx * (hw - 0.06), head_y + 0.02, 0.18), accent_color, 1.5)
		_emissive_mats.append(stud.material_override as StandardMaterial3D)


func _build_console() -> void:
	# Tilted console arm that carries the holographic edit grid, jutting toward the player.
	_console_root = Node3D.new()
	_console_root.name = "Console"
	# Place to the right of the sheet so the player can edit and watch the output.
	_console_root.position = Vector3(sheet_width * 0.5 + 0.55, 1.05, 0.45)
	_console_root.rotation_degrees = Vector3(CONSOLE_TILT_DEG, 0, 0)
	add_child(_console_root)

	var grid_total := motif_size * CELL

	# Console backing plate (dark) the hologram floats above — child of console.
	_box(Vector3(grid_total + 0.10, grid_total + 0.16, 0.03),
		Vector3(0, 0, -0.02), frame_color.lightened(0.05), _console_root)

	# Support strut from console down toward the chassis (mounted-arm read).
	# Built in machine space (child of self), not the tilted console.
	var strut := _cyl(0.6, 0.03,
		Vector3(sheet_width * 0.5 + 0.40, 0.7, 0.30), frame_color)
	strut.rotation_degrees = Vector3(40, 0, -20)

	# Holographic edit cells.
	var start := -grid_total * 0.5
	_cell_mats.clear()
	for y in motif_size:
		var row: Array = []
		for x in motif_size:
			var cell := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(CELL * 0.88, CELL * 0.88)
			cell.mesh = qm
			var mat := StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cell.material_override = mat
			cell.position = Vector3(
				start + x * CELL + CELL * 0.5,
				start + (motif_size - 1 - y) * CELL + CELL * 0.5,
				0.01)
			_console_root.add_child(cell)
			row.append(mat)
		_cell_mats.append(row)
	_paint_all_cells()

	# Holographic frame glow around the grid.
	_holo_frame(start, grid_total)

	# Title label on the console.
	var title := Label3D.new()
	title.text = "PATTERN PRINTER"
	title.pixel_size = 0.0007
	title.font_size = 13
	title.modulate = holo_color
	title.position = Vector3(0, grid_total * 0.5 + 0.05, 0.02)
	_console_root.add_child(title)


func _holo_frame(start: float, total: float) -> void:
	var fm := StandardMaterial3D.new()
	fm.albedo_color = holo_color
	fm.emission_enabled = true
	fm.emission = holo_color
	fm.emission_energy_multiplier = 1.6
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var t := 0.006
	var c := start + total * 0.5
	for data in [
		[Vector3(total + t * 2.0, t, t), Vector3(c, start + total + t * 0.5, 0.01)],
		[Vector3(total + t * 2.0, t, t), Vector3(c, start - t * 0.5, 0.01)],
		[Vector3(t, total, t), Vector3(start - t * 0.5, c, 0.01)],
		[Vector3(t, total, t), Vector3(start + total + t * 0.5, c, 0.01)],
	]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = data[0]
		bar.mesh = bm
		bar.material_override = fm
		bar.position = data[1]
		_console_root.add_child(bar)
	_emissive_mats.append(fm)


func _build_palette_buttons() -> void:
	# Ink selectors below the holographic grid, on the console.
	var grid_total := motif_size * CELL
	var base_y := -grid_total * 0.5 - 0.06
	var n := _palette.size()
	var spacing := 0.062
	var row_w := (n - 1) * spacing
	var start_x := -row_w * 0.5

	var lbl := Label3D.new()
	lbl.text = "INK"
	lbl.pixel_size = 0.0005
	lbl.font_size = 8
	lbl.modulate = holo_color
	lbl.position = Vector3(start_x - 0.06, base_y, 0.02)
	_console_root.add_child(lbl)

	_ink_indicators.clear()
	for i in n:
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "InkBtn_%d" % i
		btn.position = Vector3(start_x + i * spacing, base_y, 0.03)
		btn.scale = Vector3(0.45, 0.45, 0.45)
		var col: Color = _palette[i]
		btn.set("pressed_color", col)
		btn.set("released_color", col.darkened(0.35))
		_console_root.add_child(btn)
		_connect_button(btn, _on_ink.bind(i))

		# Glow dot beneath each button to show the active ink.
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.009; sm.height = 0.018
		dot.mesh = sm
		var dm := StandardMaterial3D.new()
		dm.albedo_color = col
		dm.emission_enabled = true
		dm.emission = col
		dm.emission_energy_multiplier = 2.6 if i == _ink else 0.0
		dot.material_override = dm
		dot.position = Vector3(start_x + i * spacing, base_y - 0.035, 0.03)
		_console_root.add_child(dot)
		_ink_indicators.append(dm)


func _build_controls() -> void:
	# Operation buttons on the chassis face, to the LEFT of the sheet.
	var bx := -(sheet_width * 0.5 + 0.42)
	var by := 1.0
	var bz := 0.18
	var step := 0.20

	var ops := [
		["CYCLE", accent_color, Callable(self, "_on_cycle")],
		["SEED",  Color(0.45, 0.75, 1.0), Callable(self, "_on_seed")],
		["CLEAR", Color(0.85, 0.3, 0.3), Callable(self, "_on_clear")],
		["PRINT", Color(0.55, 0.95, 0.5), Callable(self, "_on_print")],
	]
	for i in ops.size():
		var data = ops[i]
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "Op_%s" % data[0]
		btn.position = Vector3(bx, by - i * step, bz)
		btn.scale = Vector3(0.6, 0.6, 0.6)
		btn.set("pressed_color", data[1])
		btn.set("released_color", Color(0.22, 0.22, 0.25))
		add_child(btn)
		_connect_button(btn, data[2])
		var lbl := Label3D.new()
		lbl.text = data[0]
		lbl.pixel_size = 0.0006
		lbl.font_size = 8
		lbl.modulate = Color(0.85, 0.85, 0.88)
		lbl.position = Vector3(0, -0.05, 0)
		btn.add_child(lbl)

	# Live group readout next to the cycle button.
	_group_label = Label3D.new()
	_group_label.text = GROUP_NAMES[_group_index].to_upper()
	_group_label.pixel_size = 0.0011
	_group_label.font_size = 16
	_group_label.modulate = accent_color
	_group_label.position = Vector3(bx, by + 0.16, bz)
	add_child(_group_label)

	var glbl := Label3D.new()
	glbl.text = "GROUP"
	glbl.pixel_size = 0.0005
	glbl.font_size = 7
	glbl.modulate = Color(0.6, 0.6, 0.65)
	glbl.position = Vector3(bx, by + 0.24, bz)
	add_child(glbl)


func _build_output_sheet() -> void:
	# The freshly-printed sheet: a vertical plane rising out of the print head.
	var sheet := MeshInstance3D.new()
	sheet.name = "PrintedSheet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(sheet_width, sheet_height)
	pm.orientation = PlaneMesh.FACE_Z
	sheet.mesh = pm
	sheet.position = Vector3(0, 0.42 + 0.13 + sheet_height * 0.5, 0.13)
	_sheet_mat = _make_output_material(2.0, sheet_height / sheet_width * 2.0)
	# Subtle emissive so the sheet reads as freshly printed / lit from within.
	_sheet_mat.emission_enabled = true
	_sheet_mat.emission_energy_multiplier = 0.0  # set per-update from texture is overkill; keep flat
	sheet.material_override = _sheet_mat
	add_child(sheet)


func _build_carpet() -> void:
	# The pressed carpet: laid flat on the floor, running forward from the head.
	var carpet := MeshInstance3D.new()
	carpet.name = "Carpet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(sheet_width, carpet_length)
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.01, 0.2 + carpet_length * 0.5)
	_carpet_mat = _make_output_material(2.0, carpet_length / sheet_width * 2.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


func _build_touch_area() -> void:
	# Touch volume over the holographic grid (paints cells under the player's hand).
	_touch_area = Area3D.new()
	_touch_area.name = "TouchArea"
	_touch_area.collision_layer = 1048576   # bit 20 (interactive)
	_touch_area.collision_mask = 393216     # bits 18+19 (hands + pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false

	var grid_total := motif_size * CELL
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(grid_total + 0.04, grid_total + 0.04, 0.14)
	col.shape = shape
	col.position = Vector3(0, 0, 0.02)
	_touch_area.add_child(col)
	_console_root.add_child(_touch_area)


func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 58.0
	cam.position = Vector3(2.4, 1.9, 3.0)
	cam.rotation_degrees = Vector3(-22, 32, 0)
	add_child(cam)


# ═══════════════════════════════════════════════════════════════════════
# INTERACTIONS
# ═══════════════════════════════════════════════════════════════════════

func _on_ink(idx: int) -> void:
	_ink = clampi(idx, 0, _palette.size() - 1)
	for i in _ink_indicators.size():
		_ink_indicators[i].emission_energy_multiplier = 2.6 if i == _ink else 0.0


func _on_cycle() -> void:
	_group_index = (_group_index + 1) % GROUP_ORDER.size()
	group = GROUP_NAMES[_group_index]
	if _group_label:
		_group_label.text = GROUP_NAMES[_group_index].to_upper()
	_rebake_output()


func _on_seed() -> void:
	motif_seed = (motif_seed + 1) % 100000
	_seed_motif()
	_paint_all_cells()
	_rebake_output()


func _on_clear() -> void:
	for y in motif_size:
		for x in motif_size:
			_grid[y][x] = 0
	_paint_all_cells()
	_rebake_output()


func _on_print() -> void:
	# A flourish: kick the feed and flash the head. Output already updates live,
	# so PRINT just makes the production read explicit.
	for m in _emissive_mats:
		m.emission_energy_multiplier = 4.0
	_rebake_output()


func _paint_cell(gx: int, gy: int) -> void:
	if gx < 0 or gx >= motif_size or gy < 0 or gy >= motif_size:
		return
	if _grid[gy][gx] == _ink:
		return
	_grid[gy][gx] = _ink
	_update_cell_visual(gx, gy)
	_rebake_output()


func _check_touch_paint() -> void:
	if not _touch_area or not _console_root:
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_cell = Vector2i(-1, -1)
		return
	var grid_total := motif_size * CELL
	var start := -grid_total * 0.5
	for body in bodies:
		var lp := _console_root.to_local(body.global_position)
		var gx := int((lp.x - start) / CELL)
		var gy := motif_size - 1 - int((lp.y - start) / CELL)
		if gx >= 0 and gx < motif_size and gy >= 0 and gy < motif_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_cell:
				_last_cell = cell
				_paint_cell(gx, gy)
			return


# ═══════════════════════════════════════════════════════════════════════
# OUTPUT — symmetrise the fragment, bake one texture, feed to sheet + carpet
# ═══════════════════════════════════════════════════════════════════════

func _rebake_output() -> void:
	# Bake the painted fragment through the current wallpaper group into one
	# texture. Reuses WallpaperGroups.get_symmetric_color — the SAME engine the
	# loom and the maker station use — but driven by the player's live grid.
	var group_val: int = GROUP_ORDER[_group_index]
	var n_colors: int = _palette.size()
	# Resolution-per-cell so a few painted cells become a crisp tiled field.
	var per_tile := maxi(1, int(round(float(TEXTURE_RES) / float(carpet_repeats * motif_size))))
	var canvas := carpet_repeats * motif_size * per_tile
	if canvas <= 0:
		canvas = TEXTURE_RES

	var img := Image.create(canvas, canvas, false, Image.FORMAT_RGBA8)
	for py in canvas:
		# Map output pixel -> source motif pixel coordinate (per_tile upscale).
		var sy := py / per_tile
		for px in canvas:
			var sx := px / per_tile
			var ci: int = WallpaperGroupsScript.get_symmetric_color(
				sx, sy, motif_size, _grid, group_val)
			ci = clampi(ci, 0, n_colors - 1)
			img.set_pixel(px, py, _palette[ci])

	if _output_tex:
		_output_tex.update(img)
	else:
		_output_tex = ImageTexture.create_from_image(img)

	if _sheet_mat:
		_sheet_mat.albedo_texture = _output_tex
		_sheet_mat.emission = Color(1, 1, 1)
		_sheet_mat.emission_texture = _output_tex
		_sheet_mat.emission_energy_multiplier = 0.25
	if _carpet_mat:
		_carpet_mat.albedo_texture = _output_tex


# ═══════════════════════════════════════════════════════════════════════
# CELL VISUALS
# ═══════════════════════════════════════════════════════════════════════

func _paint_all_cells() -> void:
	for y in motif_size:
		for x in motif_size:
			_update_cell_visual(x, y)


func _update_cell_visual(gx: int, gy: int) -> void:
	if gy >= _cell_mats.size() or gx >= _cell_mats[gy].size():
		return
	var mat: StandardMaterial3D = _cell_mats[gy][gx]
	var ci: int = _grid[gy][gx]
	if ci <= 0:
		# Empty cell: faint holographic blue placeholder.
		mat.albedo_color = Color(holo_color.r, holo_color.g, holo_color.b, 0.12)
		mat.emission_enabled = true
		mat.emission = holo_color
		mat.emission_energy_multiplier = 0.25
	else:
		var col: Color = _palette[ci] if ci < _palette.size() else Color.WHITE
		mat.albedo_color = Color(col.r, col.g, col.b, 0.92)
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.1


# ═══════════════════════════════════════════════════════════════════════
# OUTPUT MATERIAL + PRIMITIVE HELPERS
# ═══════════════════════════════════════════════════════════════════════

func _make_output_material(rep_x: float, rep_y: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.uv1_scale = Vector3(rep_x, rep_y, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # crisp tiles
	m.roughness = 0.8
	m.metallic = 0.0
	return m


func _box(size: Vector3, pos: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.roughness = 0.5; m.metallic = 0.4
	mi.material_override = m
	(parent if parent != null else self).add_child(mi)
	return mi


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float, parent: Node = null) -> MeshInstance3D:
	var mi := _box(size, pos, color, parent)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	cm.radial_segments = 18
	mi.mesh = cm; mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = color; m.metallic = 0.6; m.roughness = 0.35
	mi.material_override = m
	(parent if parent != null else self).add_child(mi)
	return mi


func _connect_button(btn: Node, cb: Callable) -> void:
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.connect("button_pressed", func(_b): cb.call())
