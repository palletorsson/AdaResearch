extends Node3D
class_name PatternMachineD

# @identity
# essence: a TILE-STAMP PRESS — a sci-fi printing press for wallpaper. The player
#          arranges a small NxN stamp matrix on the angled press bed, pulls the
#          press lever, and the head slams down and STAMPS the symmetry-tiled
#          carpet onto a conveyor tray that feeds it off the front of the machine.
#          The 17 wallpaper groups stop being a flat sample and become a print run.
# desire: to show that a pattern is MADE by a machine and editable in the same
#         breath. pattern_maker_station edits; pattern_loom manufactures; this does
#         both — an editable matrix + a press stroke + carpet rolling off a tray.
# critical_parameter: wallpaper_group — the symmetry operator engraved into the
#         press. The same 9-cell matrix, run through p1..p6m, prints 17 different
#         universes from one arrangement of stamps.
# triggers: touch-paint the bed cells via Area3D; palette buttons pick the stamp
#           ink; GROUP cycles the engraved symmetry; PRESS pulls the lever (head
#           punch + flash) and re-stamps the carpet; CLEAR empties the bed.
# emerges: the federated move — reuse WallpaperGroups.get_symmetric_color for the
#          live carpet and PatternSim.render_to_image for the proof sheet, then
#          wrap both in an apparatus. The press is a body for a rule.
# needs: a dark machine frame with emissive accents [present]; an angled press bed
#        of editable stamp cells [present]; a press head on rails + a pull lever
#        [present]; a conveyor tray that feeds the printed carpet off the front
#        [present]; a small proof-sheet readout [present]; DNA for group/palette/
#        seed/machine params [present]
# relationships: sibling to pattern_loom (loom weaves, press stamps — same engine,
#        different machine verb) & conveyor_belt (the carpet feeds off a belt-tray);
#        re-bodies pattern_maker_station as a MACHINE (that station is a flat panel;
#        this is an apparatus with a stroke); draws frame/accent vocabulary from
#        props-dna-gallery.
# truth: a print is a rule pressed into a surface. The matrix is the type, the
#        symmetry group is the forme, and the carpet is the impression — pull the
#        lever and the almost-nothing becomes architecture.

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")

# ── DNA ────────────────────────────────────────────────────────────────
## Wallpaper symmetry group engraved into the press (p1..p6m).
@export var group: String = "p4m"
## Palette name (bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome).
@export var palette: String = "bauhaus"
## Motif seed — feeds the proof-sheet render only (the bed is hand-edited).
@export var motif_seed: int = 7
## Edited stamp-matrix side length (2-6).
@export var matrix_size: int = 3
## Pick a fresh random group / motif each load (a map that pins one turns this off).
@export var randomize_on_start: bool = true

@export_group("Machine")
@export var frame_color: Color = Color(0.13, 0.12, 0.16)
@export var accent_color: Color = Color(1.0, 0.55, 0.12)    # press-orange accent
@export var ink_glow_color: Color = Color(1.0, 0.7, 0.25)
## Side length of the printed carpet that feeds off the tray (metres).
@export var carpet_width: float = 1.1
@export var carpet_length: float = 2.4
## How many matrix repeats span the carpet width.
@export var carpet_repeats: int = 8
@export var feed_speed: float = 0.10

# ── Stamp ink palette (Bauhaus textile, matches the station) ───────────
const INK: Array[Color] = [
	Color(0.93, 0.92, 0.88),  # 0 cream / blank
	Color(0.76, 0.22, 0.18),  # 1 red
	Color(0.14, 0.31, 0.44),  # 2 blue
	Color(0.94, 0.77, 0.18),  # 3 gold
	Color(0.10, 0.12, 0.18),  # 4 ink black
	Color(0.30, 0.55, 0.40),  # 5 green
]

const GROUP_ORDER: Array = [
	WallpaperGroups.Group.P1,   WallpaperGroups.Group.P2,
	WallpaperGroups.Group.PM,   WallpaperGroups.Group.PG,
	WallpaperGroups.Group.CM,   WallpaperGroups.Group.PMM,
	WallpaperGroups.Group.PMG,  WallpaperGroups.Group.PGG,
	WallpaperGroups.Group.CMM,  WallpaperGroups.Group.P4,
	WallpaperGroups.Group.P4M,  WallpaperGroups.Group.P4G,
	WallpaperGroups.Group.P3,   WallpaperGroups.Group.P3M1,
	WallpaperGroups.Group.P31M, WallpaperGroups.Group.P6,
	WallpaperGroups.Group.P6M,
]

const BED_TILT_DEG: float = 35.0   # press bed angled toward player
const CELL: float = 0.085          # metres per bed cell

# ── Runtime state ──────────────────────────────────────────────────────
var PUSH_BUTTON: PackedScene
var _grid: Array = []                       # matrix_size x matrix_size of ink indices
var _selected_ink: int = 1
var _group_index: int = 0
var _current_group: int = WallpaperGroups.Group.P4M

# Scene refs
var _bed_root: Node3D
var _cell_mats: Array = []                  # 2D StandardMaterial3D
var _carpet_mat: StandardMaterial3D
var _proof_mat: StandardMaterial3D
var _group_label: Label3D
var _ink_dots: Array[MeshInstance3D] = []
var _touch_area: Area3D
var _last_cell: Vector2i = Vector2i(-1, -1)

# Animation
var _press_head: Node3D
var _lever: Node3D
var _accent_mats: Array[StandardMaterial3D] = []
var _press_anim: float = -1.0               # <0 idle, else 0..1 stroke progress
var _stamped_this_stroke: bool = false      # re-stamp once per press, at the bottom
var _elapsed: float = 0.0

# ═══════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_read_overrides()
	matrix_size = clampi(matrix_size, 2, 6)
	_group_index = _index_of_group(group)
	if randomize_on_start:
		_group_index = randi() % GROUP_ORDER.size()
		motif_seed = 1 + randi() % 8
	_current_group = GROUP_ORDER[_group_index]
	PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	_init_grid()
	_build_chassis()
	_build_press_bed()
	_build_press_head_and_lever()
	_build_palette()
	_build_controls()
	_build_proof_sheet()
	_build_tray_and_carpet()
	_build_touch_area()
	_build_capture_camera()
	_update_carpet()
	_build_control_plate()
	print("[PatternMachineD] Tile-stamp press built — %dx%d matrix, group %s" % [
		matrix_size, matrix_size, WallpaperGroups.get_group_name(_current_group)])


# ═══════════════════════════════════════════════════════════════════════
# CONTROL CONSOLE — the shared display_console (same as loom / mill / tunnel)
# ═══════════════════════════════════════════════════════════════════════

func _build_control_plate() -> void:
	if has_node("ControlConsole"):
		return
	var scene := load("res://commons/artifacts/pattern_tunnel/display_console.tscn")
	if scene == null:
		return
	var plate: Node = scene.instantiate()
	plate.name = "ControlConsole"
	if plate.has_method("configure"):
		var gnames: Array = []
		for g in GROUP_ORDER:
			gnames.append(WallpaperGroups.get_group_name(g).to_upper())
		plate.call("configure", "TILE-STAMP  PRESS", [
			{"key": "group", "label": "GROUP", "names": gnames, "init": _group_index},
			{"key": "motif", "label": "MOTIF", "names": ["I","II","III","IV","V","VI","VII","VIII"], "init": clampi(motif_seed - 1, 0, 7)},
		])
	# operator station: a step the player stands on (the carpet stamps out toward +Z), with
	# the console at its front edge facing the player, so they look DOWN past it at the output.
	_build_operator_platform(Vector3(0.0, 0.0, 3.9), Vector3(2.4, 0.36, 1.7))
	add_child(plate)
	(plate as Node3D).position = Vector3(0.0, 0.36, 3.3)
	(plate as Node3D).rotation_degrees = Vector3(0.0, 0.0, 0.0)   # screen faces the player at +Z
	if plate.has_signal("changed") and not plate.is_connected("changed", _on_plate):
		plate.connect("changed", _on_plate)
	if plate.has_signal("randomized") and not plate.is_connected("randomized", _on_plate_random):
		plate.connect("randomized", _on_plate_random)


func _on_plate(key: String, value: float) -> void:
	match key:
		"group":
			_group_index = clampi(int(value), 0, GROUP_ORDER.size() - 1)
			_current_group = GROUP_ORDER[_group_index]
			group = WallpaperGroups.get_group_name(_current_group)
			if _group_label:
				_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
		"motif":
			motif_seed = int(value) + 1
	_update_carpet()


func _on_plate_random() -> void:
	_group_index = randi() % GROUP_ORDER.size()
	_current_group = GROUP_ORDER[_group_index]
	group = WallpaperGroups.get_group_name(_current_group)
	if _group_label:
		_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
	motif_seed = 1 + randi() % 8
	_update_carpet()


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


func _process(delta: float) -> void:
	_elapsed += delta
	_check_touch_paint()
	_animate_feed(delta)
	_animate_press(delta)
	_pulse_accents()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("group") or config_data.has("motif_seed"):
		randomize_on_start = false
	if config_data.has("randomize_on_start"): randomize_on_start = bool(config_data["randomize_on_start"])
	if config_data.has("group"):
		group = str(config_data["group"])
		_group_index = _index_of_group(group)
		_current_group = GROUP_ORDER[_group_index]
		if _group_label:
			_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
	if config_data.has("palette"):
		palette = str(config_data["palette"])
	if config_data.has("motif_seed"):
		motif_seed = int(config_data["motif_seed"])
	if config_data.has("matrix_size"):
		matrix_size = clampi(int(config_data["matrix_size"]), 2, 6)
	if config_data.has("carpet_repeats"):
		carpet_repeats = maxi(1, int(config_data["carpet_repeats"]))
	if config_data.has("feed_speed"):
		feed_speed = float(config_data["feed_speed"])
	# Rebuild from scratch so geometry tracks new matrix size / DNA.
	if is_inside_tree() and _bed_root != null:
		for c in get_children():
			c.queue_free()
		_cell_mats.clear()
		_ink_dots.clear()
		_accent_mats.clear()
		_bed_root = null
		call_deferred("_ready")


func _read_overrides() -> void:
	for k in ["group", "palette"]:
		if has_meta("config_%s" % k):
			set(k, str(get_meta("config_%s" % k)))
	if has_meta("config_motif_seed"):
		motif_seed = int(str(get_meta("config_motif_seed")))
	if has_meta("config_matrix_size"):
		matrix_size = int(str(get_meta("config_matrix_size")))

# ═══════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════

func _init_grid() -> void:
	_grid.clear()
	for y in matrix_size:
		var row: Array = []
		for x in matrix_size:
			row.append(0)
		_grid.append(row)
	# Seed a readable glyph so the first print isn't blank.
	var c: int = matrix_size / 2
	_grid[c][c] = 1
	if matrix_size >= 3:
		_grid[0][0] = 2
		_grid[matrix_size - 1][matrix_size - 1] = 3
		_grid[0][matrix_size - 1] = 3
		_grid[matrix_size - 1][0] = 2


func _index_of_group(name: String) -> int:
	var target: int = PatternSim.group_enum(name)
	for i in GROUP_ORDER.size():
		if int(GROUP_ORDER[i]) == target:
			return i
	return 0

# ═══════════════════════════════════════════════════════════════════════
# BUILDERS — MACHINE BODY
# ═══════════════════════════════════════════════════════════════════════

func _build_chassis() -> void:
	# Heavy press base — a cast-iron block the bed sits on.
	_box(Vector3(0.95, 0.18, 0.70), Vector3(0, 0.09, 0), frame_color, 0.45, 0.55)
	# Two side cheeks (the press uprights) holding the head rails.
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.10, 1.15, 0.62), Vector3(sx * 0.42, 0.66, 0.0), frame_color, 0.45, 0.55)
	# Top crown beam spanning the cheeks — the press anvil mount.
	_box(Vector3(0.98, 0.12, 0.30), Vector3(0, 1.20, 0.0), frame_color.lightened(0.06), 0.5, 0.45)
	# Emissive accent strip across the crown — the machine "power rail".
	_emissive_box(Vector3(0.92, 0.02, 0.02), Vector3(0, 1.14, 0.16), accent_color, 1.8)
	# Maker's plate label.
	var plate := Label3D.new()
	plate.text = "TILE-STAMP PRESS"
	plate.pixel_size = 0.0008
	plate.font_size = 14
	plate.modulate = accent_color
	plate.position = Vector3(0, 1.30, 0.12)
	add_child(plate)


func _build_press_bed() -> void:
	# Angled bed mounted on the base, tilted toward the player on +Z.
	_bed_root = Node3D.new()
	_bed_root.name = "PressBed"
	_bed_root.position = Vector3(0, 0.20, 0.16)
	_bed_root.rotation_degrees.x = -BED_TILT_DEG
	add_child(_bed_root)

	var span: float = matrix_size * CELL
	# Bed plate behind the cells.
	var plate := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(span + 0.10, span + 0.10, 0.03)
	plate.mesh = bm
	plate.material_override = _std(Color(0.20, 0.19, 0.22), 0.4, 0.5)
	plate.position = Vector3(0, 0, -0.02)
	_bed_root.add_child(plate)

	# Editable stamp cells.
	_cell_mats.clear()
	var start: float = -span * 0.5 + CELL * 0.5
	for y in matrix_size:
		var row_mats: Array = []
		for x in matrix_size:
			var cell := MeshInstance3D.new()
			var qm := BoxMesh.new()
			qm.size = Vector3(CELL * 0.88, CELL * 0.88, 0.02)
			cell.mesh = qm
			var mat := _std(INK[_grid[y][x]], 0.15, 0.6)
			cell.material_override = mat
			cell.position = Vector3(
				start + x * CELL,
				start + (matrix_size - 1 - y) * CELL,
				0.01)
			_bed_root.add_child(cell)
			row_mats.append(mat)
		_cell_mats.append(row_mats)

	# Bed frame bezel.
	var bezel := _std(accent_color.darkened(0.4), 0.4, 0.5)
	var fw: float = 0.012
	var half: float = span * 0.5 + fw * 0.5
	for d in [
		[Vector3(span + fw * 2.0, fw, 0.03), Vector3(0, half, 0.005)],
		[Vector3(span + fw * 2.0, fw, 0.03), Vector3(0, -half, 0.005)],
		[Vector3(fw, span, 0.03), Vector3(-half, 0, 0.005)],
		[Vector3(fw, span, 0.03), Vector3(half, 0, 0.005)],
	]:
		var b := MeshInstance3D.new()
		var mm := BoxMesh.new(); mm.size = d[0]
		b.mesh = mm; b.material_override = bezel; b.position = d[1]
		_bed_root.add_child(b)

	# "MATRIX" caption above the bed.
	var cap := Label3D.new()
	cap.text = "MATRIX"
	cap.pixel_size = 0.0006
	cap.font_size = 9
	cap.modulate = Color(0.75, 0.72, 0.68)
	cap.position = Vector3(0, span * 0.5 + 0.04, 0.02)
	_bed_root.add_child(cap)


func _build_press_head_and_lever() -> void:
	# Press head slides on the crown rails directly above the bed.
	_press_head = Node3D.new()
	_press_head.name = "PressHead"
	_press_head.position = Vector3(0, 0.95, 0.16)
	add_child(_press_head)

	var head := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(matrix_size * CELL + 0.14, 0.10, 0.34)
	head.mesh = hb
	head.material_override = _std(frame_color.lightened(0.12), 0.55, 0.4)
	_press_head.add_child(head)
	# Glowing punch face underneath the head.
	var face := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(matrix_size * CELL + 0.04, 0.02, 0.24)
	face.mesh = fb
	var fm := _std(ink_glow_color, 0.2, 0.5)
	fm.emission_enabled = true
	fm.emission = ink_glow_color
	fm.emission_energy_multiplier = 1.5
	face.material_override = fm
	face.position = Vector3(0, -0.06, 0)
	_press_head.add_child(face)
	_accent_mats.append(fm)

	# Two guide rods from crown down past the head.
	for sx in [-1.0, 1.0]:
		var rod := _cyl(0.95, 0.018, Vector3(sx * (matrix_size * CELL * 0.5 + 0.04), 0.74, 0.16),
			Color(0.55, 0.55, 0.60), 0.7, 0.3)
		rod.rotation_degrees = Vector3(0, 0, 0)

	# Pull lever on the right cheek — pivots, reads as the "operate" handle.
	_lever = Node3D.new()
	_lever.name = "Lever"
	_lever.position = Vector3(0.50, 0.95, 0.0)
	add_child(_lever)
	var arm := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.02; am.bottom_radius = 0.02; am.height = 0.40
	arm.mesh = am
	arm.material_override = _std(Color(0.5, 0.5, 0.55), 0.7, 0.3)
	arm.position = Vector3(0.0, 0.18, 0.10)
	arm.rotation_degrees = Vector3(-30, 0, 0)
	_lever.add_child(arm)
	var knob := MeshInstance3D.new()
	var km := SphereMesh.new(); km.radius = 0.05; km.height = 0.10
	knob.mesh = km
	var kmat := _std(accent_color, 0.2, 0.4)
	kmat.emission_enabled = true; kmat.emission = accent_color
	kmat.emission_energy_multiplier = 1.6
	knob.material_override = kmat
	knob.position = Vector3(0.0, 0.34, 0.20)
	_lever.add_child(knob)
	_accent_mats.append(kmat)

# ═══════════════════════════════════════════════════════════════════════
# BUILDERS — CONTROLS
# ═══════════════════════════════════════════════════════════════════════

func _build_palette() -> void:
	# Ink wells along the front of the base — pick the stamp colour.
	var start_x: float = -0.36
	var spacing: float = 0.13
	var lbl := Label3D.new()
	lbl.text = "INK"
	lbl.pixel_size = 0.0005
	lbl.font_size = 8
	lbl.modulate = Color(0.7, 0.68, 0.64)
	lbl.position = Vector3(start_x - 0.07, 0.22, 0.37)
	add_child(lbl)

	_ink_dots.clear()
	for i in INK.size():
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "InkBtn_%d" % i
		btn.position = Vector3(start_x + i * spacing, 0.20, 0.36)
		btn.scale = Vector3(0.5, 0.5, 0.5)
		btn.set("pressed_color", INK[i])
		btn.set("released_color", INK[i].darkened(0.35))
		add_child(btn)
		var idx := i
		_connect_pressed(btn, func(): _select_ink(idx))

		# Selected-ink indicator dot.
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new(); sm.radius = 0.012; sm.height = 0.024
		dot.mesh = sm
		var dm := StandardMaterial3D.new()
		dm.albedo_color = INK[i]
		dm.emission_enabled = true
		dm.emission = INK[i]
		dm.emission_energy_multiplier = 2.5 if i == _selected_ink else 0.0
		dot.material_override = dm
		dot.position = Vector3(start_x + i * spacing, 0.155, 0.37)
		add_child(dot)
		_ink_dots.append(dot)


func _build_controls() -> void:
	var cx: float = 0.30
	# GROUP cycle button.
	var grp := PUSH_BUTTON.instantiate()
	grp.name = "GroupCycle"
	grp.position = Vector3(cx, 0.20, 0.36)
	grp.scale = Vector3(0.6, 0.6, 0.6)
	grp.set("pressed_color", accent_color)
	grp.set("released_color", accent_color.darkened(0.5))
	add_child(grp)
	_connect_pressed(grp, _cycle_group)
	_caption(Vector3(cx, 0.255, 0.37), "GROUP", 7)

	_group_label = Label3D.new()
	_group_label.text = WallpaperGroups.get_group_name(_current_group).to_upper()
	_group_label.pixel_size = 0.0008
	_group_label.font_size = 12
	_group_label.modulate = accent_color
	_group_label.position = Vector3(cx, 0.155, 0.37)
	add_child(_group_label)

	# PRESS button — pulls the lever, punches the head, re-stamps.
	var prs := PUSH_BUTTON.instantiate()
	prs.name = "Press"
	prs.position = Vector3(cx + 0.14, 0.20, 0.36)
	prs.scale = Vector3(0.7, 0.7, 0.7)
	prs.set("pressed_color", Color(0.2, 0.9, 0.4))
	prs.set("released_color", Color(0.12, 0.40, 0.20))
	add_child(prs)
	_connect_pressed(prs, _pull_press)
	_caption(Vector3(cx + 0.14, 0.255, 0.37), "PRESS", 7)

	# CLEAR button.
	var clr := PUSH_BUTTON.instantiate()
	clr.name = "Clear"
	clr.position = Vector3(cx + 0.28, 0.20, 0.36)
	clr.scale = Vector3(0.5, 0.5, 0.5)
	clr.set("pressed_color", Color(0.85, 0.2, 0.2))
	clr.set("released_color", Color(0.4, 0.12, 0.12))
	add_child(clr)
	_connect_pressed(clr, _clear_bed)
	_caption(Vector3(cx + 0.28, 0.245, 0.37), "CLEAR", 6)


func _build_proof_sheet() -> void:
	# Small upright "proof sheet" on the crown — a high-res render of the
	# current run via PatternSim, so the player sees the catalogue print.
	var sheet := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.28, 0.28)
	sheet.mesh = qm
	_proof_mat = StandardMaterial3D.new()
	_proof_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_proof_mat.roughness = 0.7
	_proof_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sheet.material_override = _proof_mat
	sheet.position = Vector3(-0.30, 1.20, 0.18)
	add_child(sheet)
	_caption(Vector3(-0.30, 1.38, 0.18), "PROOF", 7)


func _build_tray_and_carpet() -> void:
	# Output tray: a short conveyor deck running forward off the front,
	# carrying the printed carpet off the machine (conveyor_belt vocabulary).
	var tray := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(carpet_width + 0.12, 0.04, carpet_length)
	tray.mesh = tb
	tray.material_override = _std(Color(0.10, 0.10, 0.12), 0.4, 0.7)
	tray.position = Vector3(0, 0.02, 0.40 + carpet_length * 0.5)
	add_child(tray)
	# Tray side rails with accent edge.
	for sx in [-1.0, 1.0]:
		var rail := _box(Vector3(0.03, 0.06, carpet_length), Vector3(
			sx * (carpet_width * 0.5 + 0.05), 0.05, 0.40 + carpet_length * 0.5),
			frame_color, 0.4, 0.5)
		var em := _std(accent_color, 0.2, 0.5)
		em.emission_enabled = true; em.emission = accent_color
		em.emission_energy_multiplier = 1.2
		rail.material_override = em
		_accent_mats.append(em)
	# Feed roller at the print line (where the carpet emerges).
	var roller := _cyl(carpet_width + 0.14, 0.04, Vector3(0, 0.06, 0.40),
		frame_color.lightened(0.15), 0.6, 0.3)
	roller.rotation_degrees = Vector3(0, 0, 90)

	# The printed carpet — feeds forward off the tray, scrolling like a print run.
	var carpet := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_width, carpet_length)
	carpet.mesh = pm
	carpet.position = Vector3(0, 0.045, 0.40 + carpet_length * 0.5)
	_carpet_mat = StandardMaterial3D.new()
	_carpet_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_carpet_mat.roughness = 0.85
	_carpet_mat.metallic = 0.0
	_carpet_mat.uv1_scale = Vector3(1.0, carpet_length / carpet_width, 1.0)
	carpet.material_override = _carpet_mat
	add_child(carpet)


func _build_touch_area() -> void:
	# Touch volume sitting over the angled bed cells for hand painting.
	_touch_area = Area3D.new()
	_touch_area.name = "TouchArea"
	_touch_area.collision_layer = 1048576   # bit 20 (interactive)
	_touch_area.collision_mask = 393216     # bits 18+19 (hands + pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false
	var col := CollisionShape3D.new()
	var shp := BoxShape3D.new()
	var span: float = matrix_size * CELL
	shp.size = Vector3(span + 0.04, span + 0.04, 0.12)
	col.shape = shp
	col.position = Vector3(0, 0, 0.02)
	_touch_area.add_child(col)
	_bed_root.add_child(_touch_area)


func _build_capture_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "CaptureCamera"
	cam.fov = 58.0
	cam.position = Vector3(1.7, 1.6, 2.6)
	cam.rotation_degrees = Vector3(-22, 26, 0)
	add_child(cam)

# ═══════════════════════════════════════════════════════════════════════
# INTERACTIONS
# ═══════════════════════════════════════════════════════════════════════

func _select_ink(idx: int) -> void:
	_selected_ink = idx
	for i in _ink_dots.size():
		var m: StandardMaterial3D = _ink_dots[i].material_override
		m.emission_energy_multiplier = 2.5 if i == _selected_ink else 0.0


func _cycle_group() -> void:
	_group_index = (_group_index + 1) % GROUP_ORDER.size()
	_current_group = GROUP_ORDER[_group_index]
	group = WallpaperGroups.get_group_name(_current_group)
	if _group_label:
		_group_label.text = group.to_upper()
	_update_carpet()


func _pull_press() -> void:
	# Kick off the press stroke; carpet re-stamps at the bottom of the punch.
	_press_anim = 0.0
	_stamped_this_stroke = false


func _clear_bed() -> void:
	for y in matrix_size:
		for x in matrix_size:
			_grid[y][x] = 0
	_refresh_bed_visuals()
	_update_carpet()


func _paint_cell(gx: int, gy: int) -> void:
	if gx < 0 or gx >= matrix_size or gy < 0 or gy >= matrix_size:
		return
	if _grid[gy][gx] == _selected_ink:
		return
	_grid[gy][gx] = _selected_ink
	_cell_mats[gy][gx].albedo_color = INK[_selected_ink]
	_update_carpet()


func _check_touch_paint() -> void:
	if _touch_area == null or _bed_root == null:
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_cell = Vector2i(-1, -1)
		return
	var span: float = matrix_size * CELL
	var start: float = -span * 0.5 + CELL * 0.5
	for body in bodies:
		var lp := _bed_root.to_local(body.global_position)
		var gx := int(round((lp.x - start) / CELL))
		var gy := matrix_size - 1 - int(round((lp.y - start) / CELL))
		if gx >= 0 and gx < matrix_size and gy >= 0 and gy < matrix_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_cell:
				_last_cell = cell
				_paint_cell(gx, gy)
			return


func _refresh_bed_visuals() -> void:
	for y in matrix_size:
		for x in matrix_size:
			_cell_mats[y][x].albedo_color = INK[_grid[y][x]]

# ═══════════════════════════════════════════════════════════════════════
# OUTPUT — CARPET + PROOF SHEET
# ═══════════════════════════════════════════════════════════════════════

func _update_carpet() -> void:
	# Live carpet: tile the hand-edited matrix through the active wallpaper
	# group using the same engine the station/loom use.
	var tex_size: int = carpet_repeats * matrix_size
	if tex_size <= 0:
		return
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	for py in tex_size:
		for px in tex_size:
			var ci: int = WallpaperGroups.get_symmetric_color(
				px, py, matrix_size, _grid, _current_group)
			var col: Color = INK[ci] if ci >= 0 and ci < INK.size() else INK[0]
			img.set_pixel(px, py, col)
	var tex := ImageTexture.create_from_image(img)
	if _carpet_mat:
		_carpet_mat.albedo_texture = tex
	_update_proof_sheet()


func _update_proof_sheet() -> void:
	# Proof sheet: a denser PatternSim render of the same group + palette,
	# the "catalogue impression" pinned to the crown.
	if _proof_mat == null:
		return
	var cfg := {
		"group": WallpaperGroups.get_group_name(_current_group),
		"palette": palette,
		"motif_seed": motif_seed,
		"tile_size": 16,
		"canvas_size": 192,
		"density": 0.55,
	}
	var pimg: Image = PatternSim.render_to_image(cfg)
	_proof_mat.albedo_texture = ImageTexture.create_from_image(pimg)

# ═══════════════════════════════════════════════════════════════════════
# ANIMATION
# ═══════════════════════════════════════════════════════════════════════

func _animate_feed(delta: float) -> void:
	if _carpet_mat == null:
		return
	var o := _carpet_mat.uv1_offset
	o.y = fposmod(o.y + feed_speed * delta, 1.0)
	_carpet_mat.uv1_offset = o


func _animate_press(delta: float) -> void:
	if _press_anim < 0.0:
		return
	_press_anim += delta * 2.2     # ~0.45s full stroke
	var p: float = _press_anim
	# Down-punch on the first half, retract on the second.
	var down: float = sin(clampf(p, 0.0, 1.0) * PI)   # 0->1->0
	if _press_head:
		_press_head.position.y = 0.95 - 0.60 * down
	if _lever:
		_lever.rotation_degrees.z = -45.0 * down
	if p >= 0.5 and not _stamped_this_stroke:
		# At bottom of stroke: re-stamp + flash the punch face. Once per pull.
		_stamped_this_stroke = true
		_update_carpet()
	if p >= 1.0:
		_press_anim = -1.0
		if _press_head:
			_press_head.position.y = 0.95
		if _lever:
			_lever.rotation_degrees.z = 0.0


func _pulse_accents() -> void:
	var pulse: float = 1.2 + 0.8 * (0.5 + 0.5 * sin(_elapsed * 4.0))
	# Press face flashes harder during a stroke.
	if _press_anim >= 0.0:
		pulse += 2.5 * sin(clampf(_press_anim, 0.0, 1.0) * PI)
	for m in _accent_mats:
		m.emission_energy_multiplier = pulse

# ═══════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════

func _std(color: Color, metallic: float = 0.0, roughness: float = 0.5) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


func _box(size: Vector3, pos: Vector3, color: Color, metallic: float = 0.35,
		roughness: float = 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new(); bm.size = size
	mi.mesh = bm; mi.position = pos
	mi.material_override = _std(color, metallic, roughness)
	add_child(mi)
	return mi


func _emissive_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := _box(size, pos, color)
	var m: StandardMaterial3D = mi.material_override
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	_accent_mats.append(m)
	return mi


func _cyl(height: float, radius: float, pos: Vector3, color: Color,
		metallic: float = 0.6, roughness: float = 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius; cm.bottom_radius = radius; cm.height = height
	cm.radial_segments = 18
	mi.mesh = cm; mi.position = pos
	mi.material_override = _std(color, metallic, roughness)
	add_child(mi)
	return mi


func _caption(pos: Vector3, text: String, font_size: int) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0006
	lbl.font_size = font_size
	lbl.modulate = Color(0.72, 0.70, 0.66)
	lbl.position = pos
	add_child(lbl)


func _connect_pressed(btn: Node, callback: Callable) -> void:
	# push_button exposes a top-level `pressed` signal (no args); its inner
	# InteractableAreaButton emits `button_pressed(button)`. Use the inner
	# area like the station/loom do — most reliable across VR + desktop.
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area and area.has_signal("button_pressed"):
		area.connect("button_pressed", func(_b): callback.call())
	elif btn.has_signal("pressed"):
		btn.connect("pressed", callback)
