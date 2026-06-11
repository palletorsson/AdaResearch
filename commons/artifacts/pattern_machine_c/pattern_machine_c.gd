# pattern_machine_c.gd — THE KALEIDOSCOPE MILL
#
# A pattern MACHINE where the wallpaper SYMMETRY is the visible mechanism.
# The player feeds a small motif grid into a central HOPPER on the machine head;
# rotating mirror-wedge ROTORS multiply the fragment; the mill spits out a live
# wallpaper-group carpet onto the floor. Edit the hopper -> carpet updates live.
#
# This is NOT a flat plate: it is a dark industrial frame with legs, a feed
# column, a glowing core, spinning kaleidoscope mirror wedges, a warp-thread
# cage, emissive accent rails, and an output chute that the carpet rolls from.
#
# Reuses:
#   - WallpaperGroups.get_symmetric_color()  (live per-pixel tiling for the carpet)
#   - PatternSim.PALETTES / GROUPS          (palette + group vocabulary)
#   - push_button.tscn                       (VR controls: paint color, group, spin, clear, mill)
#   - Area3D touch-paint                     (paint the hopper grid with VR hands)
#   - pattern_loom machine vocabulary        (frame boxes, warp threads, weave bar, emissive accents)

# @identity
# essence: kaleidoscope_mill(hopper[x][y]) -> radial_carpet — drop a handful of motif
#   cells into a central hopper, watch spinning mirror wedges multiply the fragment and
#   the mill spit out an infinite wallpaper-group carpet. The symmetry IS the machine.
# desire: to make wallpaper symmetry physically legible — not a number on a plate but a
#   set of rotating mirrors you feed and watch multiply your fragment into architecture.
# critical_parameter: wallpaper_group — the 17 ways the rotor reflects the hopper into a
#   plane. Cycling the group visibly re-geometries the mill: 2-fold, 4-fold, 6-fold rotors.
# triggers: touch-paint the hopper grid via Area3D; palette buttons pick paint color;
#   GROUP button cycles all 17 groups; SPIN reverses rotor direction; SEED reseeds a
#   procedural motif; CLEAR empties the hopper; every edit re-mills the carpet live.
# emerges: the same federated move as pattern_loom — reuse WallpaperGroups + PatternSim,
#   wrap them in an apparatus. But here the apparatus is interactive: the player is the
#   feedstock source, and the mirrors are the algorithm made mechanism.
# needs: [has] push_button palette + control row; [has] Area3D touch-paint hopper;
#   [has] spinning mirror-wedge rotors; [has] warp-thread cage + glowing core;
#   [has] live carpet via WallpaperGroups; [has] output chute. [missing] no sliders yet.
# relationships: interactive sibling to pattern_loom (loom manufactures, mill manufactures
#   AND is edited); re-bodies pattern_maker_station as a radial mill instead of a flat panel;
#   draws machine vocabulary from props-dna-gallery (autoclave, electrical panel, cable tray).
# truth: a wallpaper group is not a label — it is a finite set of mirrors. Feed the mirrors
#   almost nothing and they return a universe. The mill makes the multiplication visible.

extends Node3D
class_name PatternMachineC

const PatternSim = preload("res://commons/pattern_grammar/pattern_sim.gd")
const WallpaperGroupsScript = preload("res://commons/primitives/arrays/wallpaper_groups.gd")

# ── DNA ─────────────────────────────────────────────────────────────────
## Wallpaper symmetry group (p1..p6m) — the mirrors the rotor enforces.
@export var group: String = "p6m"
## Palette name: bauhaus, escher, alhambra, tatami, pastel, memphis, persian, monochrome.
@export var palette: String = "alhambra"
## Motif seed — reseeds the procedural fallback motif.
@export var motif_seed: int = 7
## Hopper grid resolution (NxN cells the player paints). 2..8.
@export var hopper_size: int = 4
## Pick a fresh random group / motif each load (a map that pins one turns this off).
@export var randomize_on_start: bool = true

@export_group("Machine")
@export var frame_color: Color = Color(0.10, 0.11, 0.14)      # dark industrial
@export var metal_color: Color = Color(0.32, 0.34, 0.40)      # brushed metal
@export var accent_color: Color = Color(1.0, 0.55, 0.15)      # warm amber accent
@export var core_color: Color = Color(0.35, 0.9, 1.0)         # cyan core glow
@export var carpet_world_size: float = 5.4                    # carpet side length (m)
@export var carpet_repeats: int = 9                           # domain repeats across carpet
@export var rotor_speed: float = 0.6                          # rad/s base spin of mirror wedges

# ── Palette (Italian textile, matches pattern_maker_station) ──────────────
const PALETTE: Array[Color] = [
	Color(0.95, 0.92, 0.85),  # 0 cream / empty
	Color(0.80, 0.20, 0.15),  # 1 deep red
	Color(0.15, 0.25, 0.50),  # 2 navy blue
	Color(0.70, 0.55, 0.20),  # 3 gold / ochre
	Color(0.20, 0.40, 0.25),  # 4 forest green
	Color(0.40, 0.20, 0.15),  # 5 brown
	Color(0.10, 0.10, 0.12),  # 6 near black
	Color(0.60, 0.30, 0.50),  # 7 dusty purple
]

# ── Group order (cycled by the GROUP button) ──────────────────────────────
const GROUP_NAMES: Array = [
	"p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
	"p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m",
]

# ── State ─────────────────────────────────────────────────────────────────
var _grid_data: Array = []                 # hopper cells [y][x] -> color index
var _selected_color: int = 1
var _group_index: int = 0
var _current_group: int = WallpaperGroupsScript.Group.P1
var _spin_dir: float = 1.0
var _elapsed: float = 0.0

# ── Scene refs ─────────────────────────────────────────────────────────────
var PUSH_BUTTON: PackedScene
var _hopper_root: Node3D
var _cell_meshes: Array = []               # [y][x] -> MeshInstance3D
var _cell_materials: Array = []            # [y][x] -> StandardMaterial3D
var _carpet_mesh: MeshInstance3D
var _carpet_material: StandardMaterial3D
var _carpet_tex: ImageTexture
var _group_label: Label3D
var _palette_indicators: Array[MeshInstance3D] = []
var _touch_area: Area3D
var _last_painted_cell: Vector2i = Vector2i(-1, -1)

# Animated machine parts
var _rotor_assembly: Node3D                # container for the whole rotor drum
var _rotor_ring_mat: StandardMaterial3D    # the rotor ring's accent material
var _rotor_wedges: Array[Node3D] = []      # spinning mirror-wedge pivots
var _warp_mats: Array[StandardMaterial3D] = []
var _core_mat: StandardMaterial3D
var _accent_mats: Array[StandardMaterial3D] = []
var _chute_mat: StandardMaterial3D         # scrolls a feed band down the chute

# Geometry constants (machine head sits up at this height)
const HOPPER_Y: float = 1.25               # height of the hopper grid face
const HOPPER_CELL: float = 0.07            # metres per hopper cell
const CORE_Y: float = 0.95                 # rotor / core height

# ═══════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	PUSH_BUTTON = load("res://commons/interactables/push_button.tscn")
	_group_index = _name_to_index(group)
	if randomize_on_start:
		_group_index = randi() % GROUP_NAMES.size()
		group = GROUP_NAMES[_group_index]
		motif_seed = 1 + randi() % 8
	_current_group = _index_to_enum(_group_index)
	_init_hopper()

	_build_base_and_frame()
	_build_core_and_rotors()
	_build_warp_cage()
	_build_hopper_grid()
	_build_palette_row()
	_build_control_row()
	_build_output_chute()
	_build_carpet()
	_build_labels()
	_build_capture_camera()
	_update_carpet()
	_build_control_plate()

	print("[PatternMachineC] Kaleidoscope Mill built — %dx%d hopper, group %s, carpet %.1fm" % [
		hopper_size, hopper_size, GROUP_NAMES[_group_index], carpet_world_size])


# ═══════════════════════════════════════════════════════════════════════
# CONTROL CONSOLE — the shared display_console (same as loom + tunnel)
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
		for g in GROUP_NAMES:
			gnames.append(String(g).to_upper())
		plate.call("configure", "KALEIDOSCOPE  MILL", [
			{"key": "group", "label": "GROUP", "names": gnames, "init": _group_index},
			{"key": "motif", "label": "MOTIF", "names": ["I","II","III","IV","V","VI","VII","VIII"], "init": clampi(motif_seed - 1, 0, 7)},
		])
	# operator station: a step the player stands on (the carpet mills out toward +Z), with the
	# console at its front edge facing the player, so they look DOWN past it at the carpet.
	_build_operator_platform(Vector3(0.0, 0.0, 6.4), Vector3(2.4, 0.36, 1.7))
	add_child(plate)
	(plate as Node3D).position = Vector3(0.0, 0.36, 5.8)
	(plate as Node3D).rotation_degrees = Vector3(0.0, 0.0, 0.0)   # screen faces the player at +Z
	if plate.has_signal("changed") and not plate.is_connected("changed", _on_plate):
		plate.connect("changed", _on_plate)
	if plate.has_signal("randomized") and not plate.is_connected("randomized", _on_plate_random):
		plate.connect("randomized", _on_plate_random)


func _on_plate(key: String, value: float) -> void:
	match key:
		"group":
			_group_index = clampi(int(value), 0, GROUP_NAMES.size() - 1)
			group = GROUP_NAMES[_group_index]
			_current_group = _index_to_enum(_group_index)
			_rebuild_rotors()
		"motif":
			motif_seed = int(value) + 1
	_update_carpet()


func _on_plate_random() -> void:
	_group_index = randi() % GROUP_NAMES.size()
	group = GROUP_NAMES[_group_index]
	_current_group = _index_to_enum(_group_index)
	motif_seed = 1 + randi() % 8
	_rebuild_rotors()
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
	# Spin the kaleidoscope mirror wedges — the symmetry made mechanism.
	for w in _rotor_wedges:
		if is_instance_valid(w):
			w.rotation.y += rotor_speed * _spin_dir * delta
	# Pulse the glowing core.
	if _core_mat:
		_core_mat.emission_energy_multiplier = 1.8 + 1.0 * (0.5 + 0.5 * sin(_elapsed * 3.0))
	# Travelling shimmer along the warp threads.
	for i in range(_warp_mats.size()):
		_warp_mats[i].emission_energy_multiplier = 0.6 + 0.6 * (0.5 + 0.5 * sin(_elapsed * 4.0 - i * 0.4))
	# Accent rails breathe.
	var ap := 1.4 + 0.8 * (0.5 + 0.5 * sin(_elapsed * 2.2))
	for m in _accent_mats:
		m.emission_energy_multiplier = ap
	# Output chute feeds the carpet band forward.
	if _chute_mat:
		var o := _chute_mat.uv1_offset
		o.y = fposmod(o.y + 0.18 * delta, 1.0)
		_chute_mat.uv1_offset = o

	_check_touch_paint()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("group") or config.has("wallpaper_group") or config.has("motif_seed"):
		randomize_on_start = false
	if config.has("randomize_on_start"): randomize_on_start = bool(config["randomize_on_start"])
	if config.has("group"):
		group = str(config["group"])
		_group_index = _name_to_index(group)
		_current_group = _index_to_enum(_group_index)
	if config.has("wallpaper_group"):
		_group_index = clampi(int(config["wallpaper_group"]), 0, GROUP_NAMES.size() - 1)
		group = GROUP_NAMES[_group_index]
		_current_group = _index_to_enum(_group_index)
	if config.has("palette"):
		palette = str(config["palette"])
	if config.has("motif_seed"):
		motif_seed = int(config["motif_seed"])
	if config.has("hopper_size"):
		hopper_size = clampi(int(config["hopper_size"]), 2, 8)
	if config.has("carpet_size"):
		carpet_world_size = float(config["carpet_size"])
	if config.has("carpet_repeats"):
		carpet_repeats = int(config["carpet_repeats"])
	if config.has("rotor_speed"):
		rotor_speed = float(config["rotor_speed"])
	# Rebuild from scratch with new DNA.
	for c in get_children():
		c.queue_free()
	_rotor_wedges.clear(); _warp_mats.clear(); _accent_mats.clear()
	_palette_indicators.clear(); _cell_meshes.clear(); _cell_materials.clear()
	_core_mat = null; _chute_mat = null
	_rotor_assembly = null; _rotor_ring_mat = null
	call_deferred("_ready")

# ═══════════════════════════════════════════════════════════════════════════
# HOPPER DATA
# ═══════════════════════════════════════════════════════════════════════════

func _init_hopper() -> void:
	_grid_data.clear()
	for y in hopper_size:
		var row: Array = []
		for x in hopper_size:
			row.append(0)
		_grid_data.append(row)
	# Seed a small fragment so the mill isn't empty on first sight.
	if hopper_size >= 4:
		_grid_data[0][0] = 1; _grid_data[0][3] = 2
		_grid_data[1][1] = 3; _grid_data[1][2] = 4
		_grid_data[2][1] = 4; _grid_data[2][2] = 3
		_grid_data[3][0] = 2; _grid_data[3][3] = 1
	elif hopper_size >= 2:
		_grid_data[0][0] = 1
		_grid_data[hopper_size - 1][hopper_size - 1] = 2

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — MACHINE BODY
# ═══════════════════════════════════════════════════════════════════════════

func _build_base_and_frame() -> void:
	# Heavy base plinth.
	_box(Vector3(1.5, 0.12, 1.5), Vector3(0, 0.06, 0), frame_color, 0.4, 0.6)
	# Four bolted feet.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_cyl(0.10, 0.07, Vector3(sx * 0.62, 0.05, sz * 0.62), metal_color, 0.7, 0.4)
	# Two side gantry columns rising to the head.
	for sx in [-1.0, 1.0]:
		_box(Vector3(0.10, HOPPER_Y + 0.2, 0.12), Vector3(sx * 0.62, (HOPPER_Y + 0.2) * 0.5, -0.42), frame_color, 0.5, 0.5)
	# Top crossbeam carrying the head.
	_box(Vector3(1.46, 0.10, 0.14), Vector3(0, HOPPER_Y + 0.18, -0.42), frame_color, 0.5, 0.5)
	# Emissive accent rail along the crossbeam.
	_accent_mats.append(_emissive_box(Vector3(1.3, 0.018, 0.018), Vector3(0, HOPPER_Y + 0.10, -0.34), accent_color, 1.6))
	# Side service panel (reads as electrical panel).
	_box(Vector3(0.34, 0.5, 0.06), Vector3(-0.62, 0.55, 0.36), metal_color.darkened(0.2), 0.4, 0.6)
	for i in range(3):
		_emissive_box(Vector3(0.05, 0.05, 0.02), Vector3(-0.62 + (i - 1) * 0.09, 0.72, 0.40), accent_color, 1.2)
	# Central feed column connecting core up to the hopper head.
	_cyl(HOPPER_Y - CORE_Y + 0.3, 0.09, Vector3(0, (CORE_Y + HOPPER_Y) * 0.5, -0.42), metal_color, 0.6, 0.4)


func _build_core_and_rotors() -> void:
	# Everything in the rotor head lives under one container so the whole drum
	# can be replaced wholesale when the group (and thus the fold order) changes.
	var assembly := Node3D.new()
	assembly.name = "RotorAssembly"
	add_child(assembly)
	_rotor_assembly = assembly

	# The MILL HOUSING — a drum where the kaleidoscope rotors live.
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

	# Mirror-wedge ROTORS — the visible symmetry. Number of wedges reflects
	# the rotational order of the current group (2 / 3 / 4 / 6 fold).
	var fold := _rotor_fold_for_group(_group_index)
	var wedge_mat := StandardMaterial3D.new()
	wedge_mat.albedo_color = Color(0.85, 0.88, 0.95)
	wedge_mat.metallic = 0.9
	wedge_mat.roughness = 0.12       # mirror-like
	wedge_mat.emission_enabled = true
	wedge_mat.emission = core_color
	wedge_mat.emission_energy_multiplier = 0.25

	# A pivot we spin; wedges are children radiating from the core front face.
	var pivot := Node3D.new()
	pivot.name = "RotorPivot"
	pivot.position = Vector3(0, CORE_Y, -0.18)   # in front of the drum, facing player
	assembly.add_child(pivot)
	_rotor_wedges.append(pivot)

	for i in range(fold):
		var wedge := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.06, 0.30, 0.02)
		wedge.mesh = pm
		wedge.material_override = wedge_mat
		var ang := TAU * float(i) / float(fold)
		# Radiate the wedge outward from centre, pointing along its angle.
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


func _build_warp_cage() -> void:
	# Glowing warp threads stretched across the front of the head — the loom
	# vocabulary, reading the fed motif into the mill.
	var count := 11
	var span := 1.0
	var base_x := -span * 0.5
	for i in range(count):
		var t := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.004; cm.bottom_radius = 0.004
		cm.height = 0.55; cm.radial_segments = 6
		t.mesh = cm
		var x := base_x + span * float(i) / float(count - 1)
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
# BUILDERS — INTERACTIVE HOPPER GRID
# ═══════════════════════════════════════════════════════════════════════════

func _build_hopper_grid() -> void:
	# The hopper is an upright tray on the machine head facing the player (+Z).
	_hopper_root = Node3D.new()
	_hopper_root.name = "Hopper"
	_hopper_root.position = Vector3(0, HOPPER_Y, -0.05)
	add_child(_hopper_root)

	var total := hopper_size * HOPPER_CELL
	var start := -total * 0.5

	# Backing plate.
	var plate := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(total + 0.05, total + 0.05, 0.03)
	plate.mesh = bm
	plate.material_override = _mat(Color(0.16, 0.17, 0.20), 0.4, 0.6)
	plate.position = Vector3(0, 0, -0.02)
	_hopper_root.add_child(plate)

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
		_hopper_root.add_child(b)

	# Cells.
	_cell_meshes.clear(); _cell_materials.clear()
	for y in hopper_size:
		var row_m: Array = []
		var row_mat: Array = []
		for x in hopper_size:
			var cell := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(HOPPER_CELL * 0.9, HOPPER_CELL * 0.9)
			cell.mesh = qm
			var ci: int = _grid_data[y][x]
			var cm := StandardMaterial3D.new()
			cm.albedo_color = PALETTE[ci]
			cm.roughness = 0.8
			if ci != 0:
				cm.emission_enabled = true
				cm.emission = PALETTE[ci]
				cm.emission_energy_multiplier = 0.25
			cell.material_override = cm
			cell.position = Vector3(
				start + x * HOPPER_CELL + HOPPER_CELL * 0.5,
				start + (hopper_size - 1 - y) * HOPPER_CELL + HOPPER_CELL * 0.5,
				0.01
			)
			_hopper_root.add_child(cell)
			row_m.append(cell)
			row_mat.append(cm)
		_cell_meshes.append(row_m)
		_cell_materials.append(row_mat)

	# Grid lines.
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.5, 0.52, 0.55, 0.8)
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in hopper_size + 1:
		var vl := MeshInstance3D.new()
		var vm := BoxMesh.new(); vm.size = Vector3(0.0015, total, 0.0015)
		vl.mesh = vm; vl.material_override = line_mat
		vl.position = Vector3(start + i * HOPPER_CELL, 0, 0.012)
		_hopper_root.add_child(vl)
		var hl := MeshInstance3D.new()
		var hm := BoxMesh.new(); hm.size = Vector3(total, 0.0015, 0.0015)
		hl.mesh = hm; hl.material_override = line_mat
		hl.position = Vector3(0, start + i * HOPPER_CELL, 0.012)
		_hopper_root.add_child(hl)

	# Touch-paint Area3D over the grid (hands + pointers).
	_touch_area = Area3D.new()
	_touch_area.name = "TouchArea"
	_touch_area.collision_layer = 1048576   # bit 20 (interactive)
	_touch_area.collision_mask = 393216     # bits 18+19 (hands + pointers)
	_touch_area.monitoring = true
	_touch_area.monitorable = false
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(total + 0.02, total + 0.02, 0.10)
	col.shape = sh
	col.position = Vector3(0, 0, 0.02)
	_touch_area.add_child(col)
	_hopper_root.add_child(_touch_area)

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — CONTROLS
# ═══════════════════════════════════════════════════════════════════════════

func _build_palette_row() -> void:
	# Palette buttons along the left gantry column, facing the player.
	var col_x := -0.62
	var base_y := 0.45
	var spacing := 0.085
	_palette_indicators.clear()
	for i in PALETTE.size():
		var btn := PUSH_BUTTON.instantiate()
		btn.name = "PaletteBtn_%d" % i
		btn.position = Vector3(col_x, base_y + i * spacing, 0.10)
		btn.scale = Vector3(0.45, 0.45, 0.45)
		btn.set("pressed_color", PALETTE[i])
		btn.set("released_color", PALETTE[i].darkened(0.35))
		add_child(btn)
		var area := btn.get_node_or_null("InteractableAreaButton")
		if area:
			var idx := i
			area.connect("button_pressed", func(_b): _select_color(idx))
		# Glow indicator dot next to button.
		var dot := MeshInstance3D.new()
		var dm := SphereMesh.new(); dm.radius = 0.009; dm.height = 0.018
		dot.mesh = dm
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = PALETTE[i]
		dmat.emission_enabled = true
		dmat.emission = PALETTE[i]
		dmat.emission_energy_multiplier = 2.5 if i == _selected_color else 0.0
		dot.material_override = dmat
		dot.position = Vector3(col_x + 0.07, base_y + i * spacing, 0.10)
		add_child(dot)
		_palette_indicators.append(dot)


func _build_control_row() -> void:
	# Control buttons along the right gantry column.
	var col_x := 0.62
	var by := 0.95

	var group_btn := PUSH_BUTTON.instantiate()
	group_btn.name = "GroupCycle"
	group_btn.position = Vector3(col_x, by, 0.10)
	group_btn.scale = Vector3(0.55, 0.55, 0.55)
	group_btn.set("pressed_color", accent_color)
	group_btn.set("released_color", frame_color)
	add_child(group_btn)
	_connect_btn(group_btn, _cycle_group)
	_add_btn_label(group_btn, "GROUP")

	var spin_btn := PUSH_BUTTON.instantiate()
	spin_btn.name = "Spin"
	spin_btn.position = Vector3(col_x, by - 0.16, 0.10)
	spin_btn.scale = Vector3(0.45, 0.45, 0.45)
	spin_btn.set("pressed_color", core_color)
	spin_btn.set("released_color", frame_color)
	add_child(spin_btn)
	_connect_btn(spin_btn, _toggle_spin)
	_add_btn_label(spin_btn, "SPIN")

	var seed_btn := PUSH_BUTTON.instantiate()
	seed_btn.name = "Seed"
	seed_btn.position = Vector3(col_x, by - 0.30, 0.10)
	seed_btn.scale = Vector3(0.45, 0.45, 0.45)
	seed_btn.set("pressed_color", Color(0.4, 0.8, 0.4))
	seed_btn.set("released_color", frame_color)
	add_child(seed_btn)
	_connect_btn(seed_btn, _reseed_motif)
	_add_btn_label(seed_btn, "SEED")

	var clear_btn := PUSH_BUTTON.instantiate()
	clear_btn.name = "Clear"
	clear_btn.position = Vector3(col_x, by - 0.44, 0.10)
	clear_btn.scale = Vector3(0.45, 0.45, 0.45)
	clear_btn.set("pressed_color", Color(0.85, 0.2, 0.2))
	clear_btn.set("released_color", frame_color)
	add_child(clear_btn)
	_connect_btn(clear_btn, _clear_hopper)
	_add_btn_label(clear_btn, "CLEAR")


func _build_output_chute() -> void:
	# A slanted chute the carpet rolls out of, from the head down to the floor
	# in front of the machine. Visually connects mill -> carpet.
	var chute := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.0, 0.7)
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
		rail.position = Vector3(sx * 0.5, 0.55, 0.30)
		_accent_mats.append(_assign_emissive(rail, accent_color, 1.2, metal_color))
		add_child(rail)

	# Output roller at the chute lip where the carpet meets the floor.
	var roller := _cyl(1.1, 0.05, Vector3(0, 0.05, 0.62), metal_color.lightened(0.1), 0.7, 0.3)
	roller.rotation_degrees = Vector3(0, 0, 90)

# ═══════════════════════════════════════════════════════════════════════════
# BUILDERS — OUTPUT CARPET (the milled wallpaper)
# ═══════════════════════════════════════════════════════════════════════════

func _build_carpet() -> void:
	_carpet_mesh = MeshInstance3D.new()
	_carpet_mesh.name = "MilledCarpet"
	var pm := PlaneMesh.new()
	pm.size = Vector2(carpet_world_size, carpet_world_size)
	_carpet_mesh.mesh = pm
	# Lies flat, in front of the machine (where the chute feeds it out).
	_carpet_mesh.position = Vector3(0, 0.01, 0.62 + carpet_world_size * 0.5)
	_carpet_material = StandardMaterial3D.new()
	_carpet_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_carpet_material.roughness = 0.9
	_carpet_material.metallic = 0.0
	_carpet_mesh.material_override = _carpet_material
	add_child(_carpet_mesh)


func _build_labels() -> void:
	var title := Label3D.new()
	title.text = "KALEIDOSCOPE MILL"
	title.pixel_size = 0.0011
	title.font_size = 24
	title.modulate = accent_color
	title.position = Vector3(0, HOPPER_Y + 0.30, -0.20)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(title)

	_group_label = Label3D.new()
	_group_label.text = GROUP_NAMES[_group_index].to_upper()
	_group_label.pixel_size = 0.0012
	_group_label.font_size = 20
	_group_label.modulate = core_color
	_group_label.position = Vector3(0.62, 1.12, 0.12)
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

func _select_color(idx: int) -> void:
	_selected_color = idx
	for i in _palette_indicators.size():
		var m: StandardMaterial3D = _palette_indicators[i].material_override
		m.emission_energy_multiplier = 2.5 if i == _selected_color else 0.0
	print("[PatternMachineC] paint colour -> %d" % idx)


func _cycle_group() -> void:
	_group_index = (_group_index + 1) % GROUP_NAMES.size()
	group = GROUP_NAMES[_group_index]
	_current_group = _index_to_enum(_group_index)
	if _group_label:
		_group_label.text = group.to_upper()
	# Rebuild rotors so the mirror count matches the new group's fold order.
	_rebuild_rotors()
	_update_carpet()
	print("[PatternMachineC] group -> %s" % group)


func _toggle_spin() -> void:
	_spin_dir = -_spin_dir
	print("[PatternMachineC] rotor spin reversed (dir=%.0f)" % _spin_dir)


func _reseed_motif() -> void:
	motif_seed = (motif_seed * 1103515245 + 12345) & 0x7fffffff
	var n := PALETTE.size()
	var motif: Array = PatternSim.generate_dot_motif(hopper_size, n, motif_seed, 0.4)
	for y in hopper_size:
		for x in hopper_size:
			_grid_data[y][x] = clampi(int(motif[y][x]), 0, n - 1)
	_refresh_hopper_visuals()
	_update_carpet()
	print("[PatternMachineC] reseeded motif (seed=%d)" % motif_seed)


func _clear_hopper() -> void:
	for y in hopper_size:
		for x in hopper_size:
			_grid_data[y][x] = 0
	_refresh_hopper_visuals()
	_update_carpet()


func _paint_cell(gx: int, gy: int) -> void:
	if gx < 0 or gx >= hopper_size or gy < 0 or gy >= hopper_size:
		return
	if _grid_data[gy][gx] == _selected_color:
		return
	_grid_data[gy][gx] = _selected_color
	_apply_cell_visual(gx, gy)
	_update_carpet()


func _check_touch_paint() -> void:
	if not _touch_area:
		return
	var bodies := _touch_area.get_overlapping_bodies()
	if bodies.is_empty():
		_last_painted_cell = Vector2i(-1, -1)
		return
	var total := hopper_size * HOPPER_CELL
	var start := -total * 0.5
	for body in bodies:
		var local_pos := _hopper_root.to_local(body.global_position)
		var gx := int((local_pos.x - start) / HOPPER_CELL)
		var gy := hopper_size - 1 - int((local_pos.y - start) / HOPPER_CELL)
		if gx >= 0 and gx < hopper_size and gy >= 0 and gy < hopper_size:
			var cell := Vector2i(gx, gy)
			if cell != _last_painted_cell:
				_last_painted_cell = cell
				_paint_cell(gx, gy)
			return


func _apply_cell_visual(gx: int, gy: int) -> void:
	var ci: int = _grid_data[gy][gx]
	var m: StandardMaterial3D = _cell_materials[gy][gx]
	m.albedo_color = PALETTE[ci]
	m.emission_enabled = ci != 0
	if ci != 0:
		m.emission = PALETTE[ci]
		m.emission_energy_multiplier = 0.25
	else:
		m.emission_energy_multiplier = 0.0


func _refresh_hopper_visuals() -> void:
	for y in hopper_size:
		for x in hopper_size:
			_apply_cell_visual(x, y)

# ═══════════════════════════════════════════════════════════════════════════
# CARPET TEXTURE — milled live via WallpaperGroups
# ═══════════════════════════════════════════════════════════════════════════

func _update_carpet() -> void:
	var tex_size: int = carpet_repeats * hopper_size
	if tex_size <= 0:
		return
	var image := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	for py in tex_size:
		for px in tex_size:
			var ci: int = WallpaperGroupsScript.get_symmetric_color(
				px, py, hopper_size, _grid_data, _current_group
			)
			var color: Color = PALETTE[ci] if ci >= 0 and ci < PALETTE.size() else PALETTE[0]
			image.set_pixel(px, py, color)
	if _carpet_tex:
		_carpet_tex.update(image)
	else:
		_carpet_tex = ImageTexture.create_from_image(image)
		_carpet_material.albedo_texture = _carpet_tex

# ═══════════════════════════════════════════════════════════════════════════
# ROTOR REBUILD (mirror count tracks the group's rotational order)
# ═══════════════════════════════════════════════════════════════════════════

func _rebuild_rotors() -> void:
	# Free the whole previous drum (housing, core, pivot, ring) in one shot, then
	# rebuild so the mirror-wedge count matches the new group's fold order.
	if is_instance_valid(_rotor_assembly):
		# Drop the ring's accent material so _process() stops poking the dead one.
		var ring_mat := _rotor_ring_mat
		if ring_mat:
			_accent_mats.erase(ring_mat)
		_rotor_assembly.queue_free()
	_rotor_assembly = null
	_rotor_wedges.clear()
	_core_mat = null
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
	return 2   # p1/pm/pg/cm — show a minimal 2-blade rotor

# ═══════════════════════════════════════════════════════════════════════════
# GROUP HELPERS
# ═══════════════════════════════════════════════════════════════════════════

func _name_to_index(n: String) -> int:
	var idx := GROUP_NAMES.find(n.to_lower())
	return idx if idx >= 0 else 0


func _index_to_enum(gi: int) -> int:
	return PatternSim.group_enum(GROUP_NAMES[gi])

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
	var area := btn.get_node_or_null("InteractableAreaButton")
	if area:
		area.connect("button_pressed", func(_b): callback.call())


func _add_btn_label(btn: Node, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0013
	lbl.font_size = 9
	lbl.modulate = Color(0.85, 0.85, 0.88)
	lbl.position = Vector3(0, 0, 0.06)
	btn.add_child(lbl)
