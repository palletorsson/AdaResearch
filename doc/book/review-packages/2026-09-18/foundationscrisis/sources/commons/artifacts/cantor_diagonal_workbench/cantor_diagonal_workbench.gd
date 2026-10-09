extends Node3D
class_name CantorDiagonalWorkbench

# @identity
# essence: an interactive Cantor diagonal workbench — the player turns a slider for N and watches the list grow, the diagonal extend, and the constructed real d built bit-by-bit underneath. d is guaranteed not to be in the list because it disagrees with row k at position k for every k. The proof of uncountability made into a hand-cranked procedure.
# desire: learner viscerally feels uncountability — you can list "all" reals, and we will construct one that isn't in the list, just by flipping the diagonal
# critical_parameter: N — drives list size, diagonal length, d's bit-length
# triggers: _ready() builds slider + grid + d-row + readout; _on_slider_changed regenerates the list at new N, recomputes d
# emerges: the diagonal argument as a mechanical procedure that scales — the longer the list, the longer the diagonal that excludes from it
# needs: slider_horizontal [present]; small BoxMesh grid (N+1 × N+1 cells) [present]; Label3D readouts [present]
# relationships: paired with /cantor-diagonal-gallery (web cells frozen at 8 (N, rule) combinations); sibling to halting_workbench, russell_paradox_workbench, complexity_dial_workbench — together they make the limits-of-math substrate walkable
# truth: given any countable list of reals, there is always a real not in that list. The slider walks the proof: more rows, longer diagonal, still excluded.

## A horizontal workbench for the Cantor diagonal argument.
##
## One slider drives N ∈ {4, 8, 16, 24, 32}. As you move it:
##   • a list of N random binary reals is regenerated (deterministic seed → same first
##     bits across N values, only the count and width change)
##   • the diagonal positions (row i, column i) are highlighted with GOLD borders
##   • the bottom row shows the constructed real d, where d[i] = 1 − list[i][i] (RED)
##   • thin vertical leaders connect each gold diagonal cell to its red d-cell, showing
##     "this bit became that bit, flipped"
##   • a readout panel reports d's prefix, the "not equal to any row" statement, and N
##
## The argument: for any row k, d disagrees with row k at position k. So d is not in
## the list. So no countable list can contain all reals.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Bit Grid")
## Total width of the grid display (meters, before plate scale). The grid
## always fills this width regardless of N — cells just get smaller.
@export var grid_width: float = 0.7
## Vertical placement of grid above plate origin.
@export var grid_height: float = 1.45
## Forward distance of grid in front of plate.
@export var grid_depth: float = -0.20
## Allowed N values — the slider snaps to one of these.
@export var n_steps: PackedInt32Array = PackedInt32Array([4, 8, 16, 24, 32])
## Colors — matching the gallery vocabulary.
@export var color_zero: Color = Color(0.18, 0.24, 0.32)         # dark blue-grey
@export var color_one: Color = Color(0.78, 0.88, 1.0)            # light blue
@export var color_diagonal_border: Color = Color(1.0, 0.78, 0.18)  # gold
@export var color_d_zero: Color = Color(0.35, 0.10, 0.08)         # dark red
@export var color_d_one: Color = Color(1.0, 0.32, 0.20)           # bright red
@export var color_leader: Color = Color(0.55, 0.30, 0.12)          # muted bronze leader

@export_group("Random Source")
## Seed for the binary list. Fixed so the list keeps its visual identity as N changes;
## the first N×N bits of an infinite deterministic stream are shown.
@export var list_seed: int = 1234

# ── Internal state ────────────────────────────────────────────────────

const SLIDER_SCENE_PATH: String = "res://commons/interactables/slider_horizontal.tscn"
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

var _n: int = 16
var _list: Array[PackedByteArray] = []   # list[row][col] ∈ {0, 1}
var _d: PackedByteArray = PackedByteArray()  # constructed real, length _n

var _plate_root: Node3D
var _slider: Node

var _grid_root: Node3D
# Cell materials indexed by linear position [r * N + c].
# Rebuilt whenever N changes (different cell count).
var _list_cell_materials: Array[StandardMaterial3D] = []
var _d_cell_materials: Array[StandardMaterial3D] = []
var _diagonal_overlays: Array[MeshInstance3D] = []
var _leader_lines: Array[MeshInstance3D] = []

var _readout_root: Node3D
var _readout_d: Label3D
var _readout_neq: Label3D
var _readout_n: Label3D
var _readout_proof: Label3D
var _plate_readout: Label       # 2D-in-3D readout integrated on the console board
var _guidance: Label3D
var _guidance_t: float = 0.0  # time remaining for flash

const GUIDANCE_TEXT: String = "constructed real d (red) flips each diagonal bit. d is not in any row."


# ── Lifecycle ─────────────────────────────────────────────────────────

## Starting N (list size) — the critical parameter, settable as DNA.
@export var initial_n: int = 16

func _ready() -> void:
	_n = maxi(2, initial_n)
	_build_plate_and_slider()
	_build_grid_root()
	_build_guidance_label()
	_regenerate_list()
	_rebuild_grid()
	_refresh_readout()


var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

func _process(delta: float) -> void:
	# Throttled viz rebuild — keeps the grab loop free while dragging.
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_regenerate_list()
		_rebuild_grid()
		_refresh_readout()
		_flash_guidance()
	if _guidance == null:
		return
	if _guidance_t > 0.0:
		_guidance_t -= delta
		var alpha: float = clampf(_guidance_t / 3.0, 0.0, 1.0)
		var c: Color = _guidance.modulate
		c.a = alpha
		_guidance.modulate = c
		if _guidance_t <= 0.0:
			_guidance.visible = false


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole — houses the plate (seated N slider) AND the
	# live readout as a 2D-in-3D screen on the board (replaces the floating card).
	_plate_root = InterfacePresets.build("workbench", "Cantor Diagonal", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)

	_plate_readout = _plate_root.add_readout("")

	_slider = _plate_root.add_slider("N — list size", "N — list size")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _normalized_for_n(_n))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var nfrac: float = clampf(float(_slider.call("get_normalized_value")), 0.0, 1.0)
	var new_n: int = _n_for_normalized(nfrac)
	if new_n == _n:
		return
	_n = new_n
	# Don't rebuild N² cells in the grab signal (the hitch stalls the physics
	# grab and the slider fights the hand) — mark dirty; _process throttles.
	_viz_dirty = true


func _normalized_for_n(n: int) -> float:
	# Map an N value to slider position (0..1) along the n_steps array.
	var count: int = n_steps.size()
	if count <= 1:
		return 0.5
	for i in range(count):
		if n_steps[i] == n:
			return float(i) / float(count - 1)
	# Fallback: nearest.
	var best_i: int = 0
	var best_d: int = abs(n_steps[0] - n)
	for i in range(1, count):
		var dd: int = abs(n_steps[i] - n)
		if dd < best_d:
			best_d = dd
			best_i = i
	return float(best_i) / float(count - 1)


func _n_for_normalized(frac: float) -> int:
	# Snap a slider value (0..1) to one of n_steps.
	var count: int = n_steps.size()
	if count == 0:
		return 16
	var idx: int = int(roundf(clampf(frac, 0.0, 1.0) * float(count - 1)))
	idx = clampi(idx, 0, count - 1)
	return n_steps[idx]


# ── List + diagonal generation ────────────────────────────────────────

func _regenerate_list() -> void:
	# Build _n rows of _n bits each, deterministic on (list_seed, row).
	# Same seed per row across N values → row 0's first bits are identical at
	# N=4 and N=32. Only the row count and bit-count-per-row scale.
	_list.clear()
	for r in range(_n):
		var rng := RandomNumberGenerator.new()
		rng.seed = list_seed + r * 977  # 977 prime keeps streams independent
		var row := PackedByteArray()
		row.resize(_n)
		for c in range(_n):
			row[c] = 0 if rng.randf() < 0.5 else 1
		_list.append(row)

	# Construct d: d[i] = 1 − list[i][i].
	_d = PackedByteArray()
	_d.resize(_n)
	for i in range(_n):
		_d[i] = 1 - _list[i][i]


# ── Grid (built/rebuilt on N change) ──────────────────────────────────

func _build_grid_root() -> void:
	# The list grid lives on the apparatus MONITOR in front of the console
	# (replaces the old free-floating position that intersected the console).
	# Screen tall enough for list + gap + d-row at the smallest N (tallest grid).
	var screen: Node3D = _plate_root.add_monitor(Vector2(grid_width + 0.16, grid_width + 0.42))
	_grid_root = Node3D.new()
	_grid_root.name = "BitGrid"
	_grid_root.position = Vector3(0.0, 0.11, 0.0)   # recentre list+d-row on the screen
	screen.add_child(_grid_root)


func _rebuild_grid() -> void:
	# Remove all previous cells / overlays / leaders.
	for child in _grid_root.get_children():
		_grid_root.remove_child(child)
		child.queue_free()
	_list_cell_materials.clear()
	_d_cell_materials.clear()
	_diagonal_overlays.clear()
	_leader_lines.clear()

	# Cell size derived so the (N+1) rows (list of N + gap + d-row) fit grid_width.
	# Use square cells so the diagonal reads at 45°.
	var cell: float = grid_width / float(_n)
	var cell_visible: float = cell * 0.86
	# Origin: top-left of the list grid.
	var origin_x: float = -grid_width * 0.5 + cell * 0.5
	var origin_y: float = (grid_width * 0.5) - cell * 0.5  # top-row y

	# Backplate sized to enclose list + d-row + gap.
	var gap_to_d: float = cell * 1.4  # separation between list bottom and d-row
	var total_height: float = grid_width + gap_to_d + cell
	var back := MeshInstance3D.new()
	back.name = "GridBackplate"
	var back_mesh := QuadMesh.new()
	var pad := 0.04
	back_mesh.size = Vector2(grid_width + pad, total_height + pad)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.04, 0.06, 0.10)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(0.0, -gap_to_d * 0.5 + cell * 0.5 - grid_width * 0.0, -0.005)
	# Center the backplate vertically over (list + gap + d-row).
	back.position.y = origin_y - (total_height * 0.5) + cell * 0.5
	_grid_root.add_child(back)

	# Build list cells (N rows × N cols).
	for r in range(_n):
		for c in range(_n):
			var cm := MeshInstance3D.new()
			cm.name = "Cell_%d_%d" % [r, c]
			var qm := QuadMesh.new()
			qm.size = Vector2(cell_visible, cell_visible)
			cm.mesh = qm
			cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.emission_enabled = true
			var bit: int = _list[r][c]
			if bit == 1:
				mat.albedo_color = color_one
				mat.emission = color_one
				mat.emission_energy_multiplier = 1.1
			else:
				mat.albedo_color = color_zero
				mat.emission = Color(0, 0, 0)
				mat.emission_energy_multiplier = 0.0
			cm.material_override = mat
			var x: float = origin_x + c * cell
			var y: float = origin_y - r * cell
			cm.position = Vector3(x, y, 0.0)
			_grid_root.add_child(cm)
			_list_cell_materials.append(mat)

	# Diagonal overlay borders — gold outline frames sitting just in front
	# of each (i, i) cell. Built as 4 thin quads per diagonal cell would be
	# expensive; we use a single larger gold quad behind each diagonal cell,
	# slightly oversized, so the gold reads as a halo/border around the cell.
	for i in range(_n):
		var halo := MeshInstance3D.new()
		halo.name = "DiagHalo_%d" % i
		var hqm := QuadMesh.new()
		hqm.size = Vector2(cell_visible * 1.18, cell_visible * 1.18)
		halo.mesh = hqm
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var hmat := StandardMaterial3D.new()
		hmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hmat.albedo_color = color_diagonal_border
		hmat.emission_enabled = true
		hmat.emission = color_diagonal_border
		hmat.emission_energy_multiplier = 1.8
		halo.material_override = hmat
		var x2: float = origin_x + i * cell
		var y2: float = origin_y - i * cell
		halo.position = Vector3(x2, y2, -0.002)  # behind the cell
		_grid_root.add_child(halo)
		_diagonal_overlays.append(halo)

	# d-row — N cells below the grid, separated by `gap_to_d`.
	var d_row_y: float = origin_y - (_n - 1) * cell - gap_to_d
	for i in range(_n):
		var dcm := MeshInstance3D.new()
		dcm.name = "DCell_%d" % i
		var dqm := QuadMesh.new()
		dqm.size = Vector2(cell_visible, cell_visible)
		dcm.mesh = dqm
		dcm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var dmat := StandardMaterial3D.new()
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.emission_enabled = true
		if _d[i] == 1:
			dmat.albedo_color = color_d_one
			dmat.emission = color_d_one
			dmat.emission_energy_multiplier = 1.6
		else:
			dmat.albedo_color = color_d_zero
			dmat.emission = color_d_zero
			dmat.emission_energy_multiplier = 0.5
		dcm.material_override = dmat
		dcm.position = Vector3(origin_x + i * cell, d_row_y, 0.0)
		_grid_root.add_child(dcm)
		_d_cell_materials.append(dmat)

	# Leader lines — thin quads connecting (i, i) diagonal cell to d-cell i.
	# Drawn behind cells. Quad oriented as a thin vertical strip.
	for i in range(_n):
		var leader := MeshInstance3D.new()
		leader.name = "Leader_%d" % i
		var lqm := QuadMesh.new()
		# Height = vertical distance between centers minus half-cell on each end.
		var diag_y: float = origin_y - i * cell
		var span: float = diag_y - d_row_y
		var line_h: float = max(0.001, span - cell * 0.7)
		lqm.size = Vector2(cell * 0.035, line_h)
		leader.mesh = lqm
		leader.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var lmat := StandardMaterial3D.new()
		lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lmat.albedo_color = color_leader
		lmat.emission_enabled = true
		lmat.emission = color_leader
		lmat.emission_energy_multiplier = 0.5
		lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lmat.albedo_color.a = 0.35
		leader.material_override = lmat
		leader.position = Vector3(origin_x + i * cell, (diag_y + d_row_y) * 0.5, -0.004)
		_grid_root.add_child(leader)
		_leader_lines.append(leader)

	# "list" label (above the grid) and "d (constructed real)" label (below d-row).
	var list_label := Label3D.new()
	list_label.text = "list of %d binary reals" % _n
	list_label.font_size = 24
	list_label.outline_size = 3
	list_label.pixel_size = 0.001
	list_label.modulate = Color(0.78, 0.88, 1.0)
	list_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_label.position = Vector3(0.0, origin_y + cell * 0.9, 0.0)
	_grid_root.add_child(list_label)

	var d_label := Label3D.new()
	d_label.text = "d (constructed real)"
	d_label.font_size = 24
	d_label.outline_size = 3
	d_label.pixel_size = 0.001
	d_label.modulate = Color(1.0, 0.5, 0.35)
	d_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_label.position = Vector3(0.0, d_row_y - cell * 0.9, 0.0)
	_grid_root.add_child(d_label)


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_readout_root.position = Vector3(grid_width * 0.5 + 0.10, grid_height, grid_depth)
	add_child(_readout_root)

	var card := MeshInstance3D.new()
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.50, 0.42)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.25, 0.0, -0.005)
	_readout_root.add_child(card)

	_readout_d = Label3D.new()
	_readout_d.name = "ReadoutD"
	_readout_d.font_size = 38
	_readout_d.outline_size = 5
	_readout_d.pixel_size = 0.001
	_readout_d.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_d.modulate = Color(1.0, 0.5, 0.35)
	_readout_d.position = Vector3(0.02, 0.15, 0.0)
	_readout_root.add_child(_readout_d)

	_readout_neq = Label3D.new()
	_readout_neq.name = "ReadoutNeq"
	_readout_neq.font_size = 22
	_readout_neq.outline_size = 3
	_readout_neq.pixel_size = 0.001
	_readout_neq.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_neq.modulate = Color(1.0, 0.78, 0.45)
	_readout_neq.position = Vector3(0.02, 0.05, 0.0)
	_readout_root.add_child(_readout_neq)

	_readout_n = Label3D.new()
	_readout_n.name = "ReadoutN"
	_readout_n.font_size = 22
	_readout_n.outline_size = 3
	_readout_n.pixel_size = 0.001
	_readout_n.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_n.modulate = Color(0.7, 0.85, 1.0)
	_readout_n.position = Vector3(0.02, -0.02, 0.0)
	_readout_root.add_child(_readout_n)

	_readout_proof = Label3D.new()
	_readout_proof.name = "ReadoutProof"
	_readout_proof.font_size = 20
	_readout_proof.outline_size = 3
	_readout_proof.pixel_size = 0.001
	_readout_proof.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_readout_proof.modulate = Color(0.95, 0.95, 0.75)
	_readout_proof.position = Vector3(0.02, -0.13, 0.0)
	_readout_root.add_child(_readout_proof)


func _refresh_readout() -> void:
	# Build d's string. For long N, truncate to first 12 bits + "…".
	var d_str: String = "0."
	var max_show: int = min(_n, 12)
	for i in range(max_show):
		d_str += str(_d[i])
	if _n > 12:
		d_str += "…"
	if _plate_readout:
		_plate_readout.text = "d = %s\nd ≠ any row · N=%d" % [d_str, _n]


# ── Guidance flash ────────────────────────────────────────────────────

func _build_guidance_label() -> void:
	_guidance = Label3D.new()
	_guidance.name = "Guidance"
	_guidance.text = GUIDANCE_TEXT
	_guidance.font_size = 22
	_guidance.outline_size = 3
	_guidance.pixel_size = 0.001
	_guidance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_guidance.modulate = Color(1.0, 0.8, 0.4, 0.0)  # start invisible
	# Under the d-row on the monitor screen. Parented to the screen content
	# (NOT _grid_root — _rebuild_grid clears _grid_root's children every N change).
	_guidance.position = Vector3(0.0, -grid_width * 0.5 - 0.27, 0.01)
	_guidance.visible = false  # hidden until first slider change
	_grid_root.get_parent().add_child(_guidance)


func _flash_guidance() -> void:
	_guidance_t = 3.0  # seconds
	if _guidance:
		_guidance.visible = true
		var c: Color = _guidance.modulate
		c.a = 1.0
		_guidance.modulate = c


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("list_seed"):
		list_seed = int(config_data["list_seed"])
		_regenerate_list()
		_rebuild_grid()
		_refresh_readout()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("initial_n"):
		var requested_n: int = int(config_data["initial_n"])
		# Snap to nearest n_steps value.
		var best_i: int = 0
		var best_d: int = abs(n_steps[0] - requested_n)
		for i in range(1, n_steps.size()):
			var dd: int = abs(n_steps[i] - requested_n)
			if dd < best_d:
				best_d = dd
				best_i = i
		_n = n_steps[best_i]
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _normalized_for_n(_n))
		_regenerate_list()
		_rebuild_grid()
		_refresh_readout()
