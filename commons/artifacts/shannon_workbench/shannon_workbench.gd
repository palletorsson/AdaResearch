extends Node3D
class_name ShannonWorkbench

# @identity
# essence: A fixed-seed Bernoulli sample and binary source entropy H(p).
# desire: Distinguish source uncertainty from errors made by a particular predictor.
# critical_parameter: p changes the source; EXPECT 0/1 changes only the optional predictor.
# triggers: Threshold the same stored draws; compute H from p and count mismatches in the sample.
# emerges: Equal source entropy can coexist with opposite predictor performance.
# needs: Headset reach/readability and learner checks; no variational free-energy calculation.
# relationships: Returns to the introduction's equal totals; prepares the E hall's explicit alternatives.
# truth: H(p) is a source quantity, not the exact shortest encoding of a particular finite grid.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
## Tilt of the slider plate toward the player.
@export var plate_tilt_deg: float = -25.0
## Plate height above the artifact origin.
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

# ─────────────────────────────────────────────────────────────────────────────
# The evidence axis changes sample size without changing the source formula:
# none (no observation), anecdote (4x4), sample (16x16), census (32x32).
# "census" is a legacy preset name; even 1024 draws remain a finite sample.
# Fixed stored draws are re-thresholded as p changes. Unsampled grey differs
# from observed zero. All presets use the same physical monitor size.

@export_group("Evidence")
## AXIS — how many independent draws this bench is standing on when you find it.
## Shared vocabulary with galton_board. sample (legacy default) = 256 bits.
@export_enum("none", "anecdote", "sample", "census") var evidence: String = "sample"

## The ladder. `side` sets grid_side; `drawn` false means the field was never
## sampled at all, which is a different picture from a field of zeros.
const EVIDENCE_DRAWS := {
	"none": {"side": 16, "drawn": false},
	"anecdote": {"side": 4, "drawn": true},
	"sample": {"side": 16, "drawn": true},     # the legacy lineage
	"census": {"side": 32, "drawn": true},
}

## The colour of a cell that holds no measurement — deliberately far from
## color_zero (near-black) so "we did not look" cannot be misread as "we looked
## and found a zero".
@export var color_unsampled: Color = Color(0.20, 0.20, 0.23)

@export_group("Bit Grid")
## Side count of the bit grid. 16 → 256 cells. OWNED BY `evidence` since the
## 2026-07-27 promotion — set the axis, not this.
@export var grid_side: int = 16
## Total width of the bit grid display (meters, before plate scale).
@export var grid_width: float = 0.6
## Vertical placement of the grid (eye/chest level — above slider).
## Default 1.45 = roughly chest height for a 1.7m player, so the grid sits
## naturally in the player's visual field while the slider is at hand height.
@export var grid_height: float = 1.68
## BEHIND the slider in -Z (artifact-local), so the slider sits between the
## player and the visualization. Negative = away from the player.
@export var grid_depth: float = -0.25
@export var color_zero: Color = Color(0.05, 0.05, 0.08)
@export var color_one: Color = Color(0.25, 0.95, 1.0)

@export_group("Entropy Hill")
## Where the hill sits relative to plate origin. Above and behind the slider.
@export var hill_offset: Vector3 = Vector3(0.0, 2.12, -0.20)
## Horizontal span of the curve.
@export var hill_width: float = 1.0
## Vertical scale: peak of H(p)=1 maps to this height.
@export var hill_peak_height: float = 0.5
## Sample resolution of the hill polyline.
@export var hill_samples: int = 100
@export var hill_color: Color = Color(1.0, 0.97, 0.7)
## Marker dot color.
@export var marker_color: Color = Color(1.0, 0.2, 0.2)
@export var marker_radius: float = 0.025

@export_group("Random Source")
## Seed for the Bernoulli draws. Fixed so the same 256 numbers are re-thresholded
## as p changes — making the visual progression read as one sequence reshaped.
@export var draw_seed: int = 1234

## Compare constant predictors against this same displayed sample. Default off.
@export var prediction_study: bool = false
var _prediction: int = 0
var _prediction_buttons: Array = []
var _error_marks: Array[MeshInstance3D] = []
var _prediction_monitor: Node3D
var _prediction_text: Node3D
var _prediction_lines: Array = []
var _observed_errors: int = 0

# ── Internal state ────────────────────────────────────────────────────

const SLIDER_SCENE_PATH: String = "res://commons/interactables/slider_horizontal.tscn"
const ControlPanelScript = preload("res://commons/ui/control_panel.gd")
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

var _p: float = 0.5
var _draws: PackedFloat32Array = PackedFloat32Array()  # 256 fixed [0,1) draws

var _plate_root: Node3D
var _slider: Node                        # SliderHorizontal instance
var _plate_readout: Label                # 2D-in-3D readout integrated on the console board

var _grid_root: Node3D
var _grid_materials: Array[StandardMaterial3D] = []

var _hill_mesh_inst: MeshInstance3D
var _hill_mesh: ImmediateMesh
var _hill_material: StandardMaterial3D

var _marker_inst: MeshInstance3D
var _marker_material: StandardMaterial3D

var _hill_origin_node: Node3D  # parent for hill geometry — gives stable local coords


# ── Lifecycle ─────────────────────────────────────────────────────────

## Starting p — the critical parameter, settable as DNA (gallery / map config).
@export var initial_p: float = 0.5

func _ready() -> void:
	# Map tokens land as metadata BEFORE the node enters the tree
	# (GridInteractablesComponent._apply_artifact_config at :1162, add_child at
	# :1187), so the axis is known here — before the grid is sized.
	_read_meta_overrides()
	_apply_evidence()
	_p = clampf(initial_p, 0.0, 1.0)
	_initialize_draws()
	_build_plate_and_slider()
	_build_bit_grid()
	_build_entropy_hill()
	_build_axis_labels()
	_build_prediction_controls()
	_refresh_all()


# ── Random draws ──────────────────────────────────────────────────────

func _initialize_draws() -> void:
	# Fixed 256 draws in [0,1). Thresholding by p turns each draw into a bit:
	#   bit = 1 if draw < p else 0
	# Same draws → consistent visual identity of the sequence; only the
	# threshold migrates as the slider moves.
	var rng := RandomNumberGenerator.new()
	rng.seed = draw_seed
	var n := grid_side * grid_side
	_draws.resize(n)
	for i in range(n):
		_draws[i] = rng.randf()


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical floor-standing ControlConsole, built from the "workbench" PRINCIPAL
	# CONFIG (InterfacePresets) — one source of truth for desktop form / body /
	# viz floor. Houses the Braun plate with the seated P(1) slider AND the live
	# readout as a 2D-in-3D screen on the board.
	_plate_root = InterfacePresets.build("workbench", "Shannon Entropy", plate_height, "braun", "instrument")
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)

	# Readout screen (2D-in-3D) at the top of the board.
	_plate_readout = _plate_root.add_readout("")

	# add_slider returns the seated slider — configure its value + signal.
	_slider = _plate_root.add_slider("P(1)", "P(1)")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _p)
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var n: Variant = _slider.call("get_normalized_value")
	_p = clampf(float(n), 0.0, 1.0)
	# Don't rebuild in the grab signal (fires every frame while dragging — the
	# hitch stalls the physics grab and the slider fights the hand). Mark dirty;
	# _process refreshes at most every VIZ_REFRESH_INTERVAL.
	_viz_dirty = true


var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Bit grid (16×16) ──────────────────────────────────────────────────

func _build_bit_grid() -> void:
	# The sample grid lives on the apparatus' primary MONITOR in front of the
	# console (the monitor's dark screen is the backplate). Cells are quads in
	# the content root's X-Y plane — unchanged layout.
	_grid_root = _plate_root.add_monitor(Vector2(grid_width + 0.10, grid_width + 0.10))
	_grid_root.name = "BitGrid"
	_populate_bit_grid()


## The cells themselves, split out of _build_bit_grid so the sample can be
## re-drawn at a different size without minting a second monitor. The monitor
## and its backplate are sized from grid_width, which `evidence` never touches:
## the panel is the same panel at every rung, only the sample on it changes.
func _populate_bit_grid() -> void:
	var cell_size := grid_width / float(grid_side)
	var cell_visible := cell_size * 0.86  # leave a little dark gutter between cells
	var origin_x := -grid_width * 0.5 + cell_size * 0.5
	var origin_y := -grid_width * 0.5 + cell_size * 0.5

	_grid_materials.clear()
	for r in range(grid_side):
		for c in range(grid_side):
			var cell := MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [r, c]
			var qm := QuadMesh.new()
			qm.size = Vector2(cell_visible, cell_visible)
			cell.mesh = qm
			cell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

			var mat := StandardMaterial3D.new()
			mat.albedo_color = color_zero
			mat.emission_enabled = true
			mat.emission = Color(0, 0, 0)
			mat.emission_energy_multiplier = 1.0
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cell.material_override = mat

			# Grid is laid out so row 0 is at the top, row 15 at the bottom.
			var x := origin_x + c * cell_size
			var y := -(origin_y + r * cell_size)  # negate so row 0 is on top
			cell.position = Vector3(x, y, 0.0)

			_grid_root.add_child(cell)
			_grid_materials.append(mat)
			if prediction_study:
				var mark := MeshInstance3D.new()
				mark.name = "Error_%d_%d" % [r, c]
				var bar := QuadMesh.new()
				bar.size = Vector2(cell_visible, cell_size * 0.13)
				mark.mesh = bar
				var amber := StandardMaterial3D.new()
				amber.albedo_color = Color(1.0, 0.55, 0.12)
				amber.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mark.material_override = amber
				mark.position = Vector3(x, y - cell_size * 0.36, 0.004)
				_grid_root.add_child(mark)
				_error_marks.append(mark)


func _refresh_bit_grid() -> void:
	if _grid_materials.is_empty():
		return
	var drawn: bool = _sample_drawn()
	var n: int = _grid_materials.size()
	for i in range(n):
		var mat := _grid_materials[i]
		if not drawn:
			# evidence=none: the field was never measured. Neutral grey, no
			# emission — visibly not the near-black a zero-bit gets.
			mat.albedo_color = color_unsampled
			mat.emission = Color(0, 0, 0)
			mat.emission_energy_multiplier = 0.0
			continue
		var bit: bool = _draws[i] < _p
		if bit:
			mat.albedo_color = color_one
			mat.emission = color_one
			mat.emission_energy_multiplier = 1.4
		else:
			mat.albedo_color = color_zero
			mat.emission = Color(0, 0, 0)
			mat.emission_energy_multiplier = 0.0


# ── Readout ───────────────────────────────────────────────────────────
# The live H(p) readout is a 2D-in-3D screen on the console board
# (_plate_readout, built in _build_plate_and_slider) — no floating text.

func _refresh_readout() -> void:
	if _plate_readout == null:
		return
	var h: float = _binary_entropy(_p)
	if not _sample_drawn():
		_plate_readout.text = "Source H = %.3f bits/symbol\nno sample drawn" % h
		return
	var total_bits: int = grid_side * grid_side
	_plate_readout.text = "Source H = %.3f bits/symbol\nN = %d draws (not encoded size)" % [h, total_bits]


static func _binary_entropy(p: float) -> float:
	# H(p) = -p·log₂(p) - (1-p)·log₂(1-p), with 0·log0 := 0
	if p <= 0.0 or p >= 1.0:
		return 0.0
	var q := 1.0 - p
	return -p * (log(p) / log(2.0)) - q * (log(q) / log(2.0))


# ── Entropy hill ──────────────────────────────────────────────────────

func _build_entropy_hill() -> void:
	# The H(p) landscape lives on a SECOND monitor stacked above the grid one
	# (one apparatus, two screens — the dual-display operator station).
	var hill_screen: Node3D = _plate_root.add_monitor(Vector2(hill_width + 0.16, hill_peak_height + 0.16), Vector3(0, grid_width * 0.5 + hill_peak_height * 0.5 + 0.16, 0))
	# Local frame for curve + marker: baseline near the screen's lower edge.
	_hill_origin_node = Node3D.new()
	_hill_origin_node.name = "EntropyHill"
	_hill_origin_node.position = Vector3(0.0, -hill_peak_height * 0.5, 0.0)
	hill_screen.add_child(_hill_origin_node)

	# Build the curve as a LINE_STRIP ImmediateMesh.
	_hill_mesh = ImmediateMesh.new()
	_hill_mesh_inst = MeshInstance3D.new()
	_hill_mesh_inst.name = "HillCurve"
	_hill_mesh_inst.mesh = _hill_mesh
	_hill_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_hill_material = StandardMaterial3D.new()
	_hill_material.albedo_color = hill_color
	_hill_material.emission_enabled = true
	_hill_material.emission = hill_color
	_hill_material.emission_energy_multiplier = 1.6
	_hill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_hill_material.vertex_color_use_as_albedo = false
	_hill_mesh_inst.material_override = _hill_material
	_hill_origin_node.add_child(_hill_mesh_inst)

	_emit_hill_curve()

	# Add baseline (horizontal reference line) to make the landscape read
	# as a hill rising from a floor, not just a floating curve.
	_emit_baseline()

	# Marker dot — a glowing red sphere that rides the curve.
	_marker_inst = MeshInstance3D.new()
	_marker_inst.name = "Marker"
	var sphere := SphereMesh.new()
	sphere.radius = marker_radius
	sphere.height = marker_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_marker_inst.mesh = sphere
	_marker_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_marker_material = StandardMaterial3D.new()
	_marker_material.albedo_color = marker_color
	_marker_material.emission_enabled = true
	_marker_material.emission = marker_color
	_marker_material.emission_energy_multiplier = 2.5
	_marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker_inst.material_override = _marker_material
	_hill_origin_node.add_child(_marker_inst)

	# Marker leader line — thin vertical line from baseline up to the dot,
	# anchoring the dot's height to the floor and making the H(p) value
	# read as elevation above ground rather than just a position.
	var leader := MeshInstance3D.new()
	leader.name = "MarkerLeader"
	var leader_cyl := CylinderMesh.new()
	leader_cyl.top_radius = 0.004
	leader_cyl.bottom_radius = 0.004
	leader_cyl.height = 1.0  # rescaled per frame
	leader_cyl.radial_segments = 6
	leader.mesh = leader_cyl
	leader.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var leader_mat := StandardMaterial3D.new()
	leader_mat.albedo_color = Color(marker_color, 0.6)
	leader_mat.emission_enabled = true
	leader_mat.emission = marker_color
	leader_mat.emission_energy_multiplier = 0.8
	leader_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	leader_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	leader.material_override = leader_mat
	leader.name = "MarkerLeader"
	_hill_origin_node.add_child(leader)


func _emit_hill_curve() -> void:
	_hill_mesh.clear_surfaces()
	_hill_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(hill_samples + 1):
		var p: float = float(i) / float(hill_samples)
		var pt := _curve_point(p)
		_hill_mesh.surface_add_vertex(pt)
	_hill_mesh.surface_end()


func _emit_baseline() -> void:
	# Separate immediate mesh for the floor line — gives the curve a horizon
	# to rise above, which is what makes it land as a landscape and not a
	# floating squiggle.
	var base_mesh := ImmediateMesh.new()
	base_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	base_mesh.surface_add_vertex(Vector3(-hill_width * 0.5, 0.0, 0.0))
	base_mesh.surface_add_vertex(Vector3(hill_width * 0.5, 0.0, 0.0))
	base_mesh.surface_end()

	var base_inst := MeshInstance3D.new()
	base_inst.name = "Baseline"
	base_inst.mesh = base_mesh
	base_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.4, 0.45, 0.55)
	base_mat.emission_enabled = true
	base_mat.emission = Color(0.4, 0.45, 0.55)
	base_mat.emission_energy_multiplier = 0.6
	base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_inst.material_override = base_mat
	_hill_origin_node.add_child(base_inst)


func _curve_point(p: float) -> Vector3:
	# Map p ∈ [0, 1] → local x ∈ [-w/2, +w/2]; H(p) ∈ [0, 1] → local y ∈ [0, peak].
	var x := -hill_width * 0.5 + p * hill_width
	var y := _binary_entropy(p) * hill_peak_height
	return Vector3(x, y, 0.0)


func _refresh_marker() -> void:
	if _marker_inst == null:
		return
	var pt := _curve_point(_p)
	_marker_inst.position = pt

	# Update the leader line so it spans from y=0 to the marker.
	var leader := _hill_origin_node.get_node_or_null("MarkerLeader") as MeshInstance3D
	if leader and leader.mesh is CylinderMesh:
		var h: float = max(0.001, pt.y)
		(leader.mesh as CylinderMesh).height = h
		leader.position = Vector3(pt.x, h * 0.5, pt.z)


# ── Axis labels ───────────────────────────────────────────────────────

func _build_axis_labels() -> void:
	# Three p-axis ticks (0, 0.5, 1) under the baseline, plus a peak label
	# for the y-axis showing "H = 1 bit/symbol". Framed 2D-in-3D tags
	# (R-027) — lifted slightly off the screen plane so they don't z-fight.
	var label_color := Color(0.65, 0.7, 0.8)

	var l0: Node3D = BakedText.make_tag("0", Color(0.55, 0.6, 0.7), 0.035)
	if l0:
		l0.position = _curve_point(0.0) + Vector3(0.0, -0.06, 0.01)
		_hill_origin_node.add_child(l0)

	var l_mid: Node3D = BakedText.make_tag("0.5", label_color, 0.035)
	if l_mid:
		l_mid.position = _curve_point(0.5) + Vector3(0.0, -0.06, 0.01)
		_hill_origin_node.add_child(l_mid)

	var l1: Node3D = BakedText.make_tag("1", Color(0.55, 0.6, 0.7), 0.035)
	if l1:
		l1.position = _curve_point(1.0) + Vector3(0.0, -0.06, 0.01)
		_hill_origin_node.add_child(l1)

	# p-axis title under the midpoint.
	var p_title: Node3D = BakedText.make_tag("p  →", Color(0.5, 0.55, 0.65), 0.03)
	if p_title:
		p_title.position = Vector3(0.0, -0.13, 0.01)
		_hill_origin_node.add_child(p_title)

	# Peak y-axis label — INSIDE the screen now (the hill lives on a monitor),
	# shifted right from the curve's left edge so the centered tag stays on-screen.
	var peak_label: Node3D = BakedText.make_tag("H = 1 bit/symbol  (max)", Color(1.0, 1.0, 0.7), 0.03)
	if peak_label:
		peak_label.position = Vector3(-hill_width * 0.5 + 0.24, hill_peak_height + 0.035, 0.01)
		_hill_origin_node.add_child(peak_label)

	# Origin "H" axis label, just inside the screen's left edge.
	var y_label: Node3D = BakedText.make_tag("H", Color(0.7, 0.75, 0.85), 0.035)
	if y_label:
		y_label.position = Vector3(-hill_width * 0.5 + 0.035, hill_peak_height * 0.5, 0.01)
		_hill_origin_node.add_child(y_label)


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_bit_grid()
	_refresh_readout()
	_refresh_marker()
	_refresh_prediction()


func _build_prediction_controls() -> void:
	if _prediction_buttons.is_empty() and prediction_study:
		for bit in range(2):
			var button: Node3D = _plate_root.add_button("EXPECT %d" % bit)
			button.pressed.connect(_set_prediction.bind(bit))
			_prediction_buttons.append(button)
		_prediction_monitor = _plate_root.add_monitor(Vector2(0.84, 0.60), Vector3(0.87, 0.05, 0))
		_prediction_monitor.name = "PredictionReadout"
		_plate_root.refit_housing()
	for button in _prediction_buttons:
		button.visible = prediction_study
	if _prediction_monitor != null:
		_prediction_monitor.get_parent().visible = prediction_study


func _set_prediction(bit: int) -> void:
	_prediction = clampi(bit, 0, 1)
	_refresh_prediction()


## Expected error comes from the chosen source. Observed error counts THIS sample.
## No draws or source settings are changed when a prediction button is pressed.
func prediction_reading() -> Dictionary:
	var n := _draws.size() if _sample_drawn() else 0
	var errors := 0
	for i in range(n):
		if int(_draws[i] < _p) != _prediction:
			errors += 1
	return {"p":_p, "prediction":_prediction, "source_h":_binary_entropy(_p),
		"expected_error":_p if _prediction == 0 else 1.0-_p,
		"observed_errors":errors, "sample_count":n}


func _refresh_prediction() -> void:
	for bit in _prediction_buttons.size():
		_prediction_buttons[bit].set_selected(prediction_study and bit == _prediction)
	if not prediction_study:
		for mark in _error_marks: mark.hide()
		return
	var reading := prediction_reading()
	_observed_errors = int(reading.observed_errors)
	for i in range(_error_marks.size()):
		_error_marks[i].visible = _sample_drawn() and int(_draws[i] < _p) != _prediction
	_prediction_lines = ["EXPECT %d" % _prediction, "Source p(1) = %.2f" % _p,
		"Source H = %.3f bits/symbol" % reading.source_h,
		"Expected errors: %.1f%%" % (100.0*float(reading.expected_error))]
	if int(reading.sample_count) > 0:
		_prediction_lines.append("Observed: %d / %d (%.1f%%)" % [_observed_errors, reading.sample_count, 100.0*_observed_errors/float(reading.sample_count)])
	else:
		_prediction_lines.append("Observed: no sample drawn")
	_prediction_lines.append("Amber underlines mark misses")
	_prediction_lines.append("Change the guess; keep the grid")
	if _prediction_monitor == null: return
	if is_instance_valid(_prediction_text):
		_prediction_monitor.remove_child(_prediction_text)
		_prediction_text.queue_free()
	_prediction_text = BakedText.make_text_block(_prediction_lines, Color(0.95,0.95,0.91), 0.033, 0.77, 0.014, true)
	if _prediction_text != null:
		_prediction_text.position.z = 0.006
		_prediction_monitor.add_child(_prediction_text)


# ── DNA: evidence ─────────────────────────────────────────────────────

## The family's reader for an axis token. Strips and lower-cases before
## matching, and falls back to the CURRENT value, so an unrecognised word is the
## absence of a token and never a silent third state. Same function, same
## contract, in galton_board — the two files are in different domains
## (algorithms/ and commons/artifacts/) and neither should preload the other, so
## the VOCABULARY is shared by canon rather than by inheritance: same four
## words, same order, same meaning.
static func _axis_value(raw: String, allowed, fallback: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return v if v in allowed else fallback


func _read_meta_overrides() -> void:
	if has_meta("config_prediction_study"):
		prediction_study = str(get_meta("config_prediction_study")).to_lower() in ["on", "true", "1"]
	if has_meta("config_evidence"):
		evidence = _axis_value(str(get_meta("config_evidence")),
				EVIDENCE_DRAWS.keys(), evidence)


func _evidence_entry() -> Dictionary:
	var e: Dictionary = EVIDENCE_DRAWS.get(evidence, EVIDENCE_DRAWS["sample"])
	return e


func _sample_drawn() -> bool:
	return bool(_evidence_entry().get("drawn", true))


## Hand grid_side to the axis. At the default rung this writes 16 — the same
## value the export already held — so the build does not move.
func _apply_evidence() -> void:
	grid_side = int(_evidence_entry().get("side", 16))


## Re-draw the sample at a new size. Reuses the existing monitor (calling
## _build_bit_grid again would mount a second one) and rebuilds only the cells.
func _rebuild_sample() -> void:
	_apply_evidence()
	_initialize_draws()
	if _grid_root != null:
		for child in _grid_root.get_children():
			# remove BEFORE freeing: queue_free() defers, and the new cells would
			# spend a frame overlapping the old ones at a different pitch.
			_grid_root.remove_child(child)
			child.queue_free()
		_grid_materials.clear()
		_error_marks.clear()
		_populate_bit_grid()
	_refresh_all()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("prediction_study"):
		var enabled := str(config_data["prediction_study"]).to_lower() in ["on", "true", "1"]
		if enabled != prediction_study:
			prediction_study = enabled
			if _plate_root != null:
				_build_prediction_controls()
				_rebuild_sample()
	# The late path for `evidence`: in the real grid flow the metadata is set
	# before add_child, so _ready() has already sized the grid and this deferred
	# call finds nothing changed. It matters for a caller holding the scene by
	# hand.
	if config_data.has("evidence"):
		var prev: String = evidence
		evidence = _axis_value(str(config_data["evidence"]), EVIDENCE_DRAWS.keys(), evidence)
		if evidence != prev:
			_rebuild_sample()
	if config_data.has("draw_seed"):
		draw_seed = int(config_data["draw_seed"])
		_initialize_draws()
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("hill_peak_height"):
		hill_peak_height = float(config_data["hill_peak_height"])
		if _hill_mesh:
			_emit_hill_curve()
			_refresh_marker()
	if config_data.has("initial_p"):
		_p = clampf(float(config_data["initial_p"]), 0.0, 1.0)
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _p)
		_refresh_all()


# ─────────────────────────────────────────────────────────────────────────────
# LATENT BUG FOUND DURING THE DNA PASS — reported, NOT fixed
#
# `plate_scale` (@export = 2.0, near the top of this file) is never read by the
# build path. _build_plate_and_slider() calls InterfacePresets.build() and never
# touches scale, so every one of the 5 placements renders at scale 1 while the
# export advertises 2.0. The only reader is the apply_grid_config branch above,
# which means a map that writes the export's OWN DEFAULT — #plate_scale:2.0 —
# instantly doubles the artifact, and a map that writes nothing gets a bench
# half the documented size.
#
# Not fixed here for the obvious reason: honouring the export in _ready() would
# double every existing placement, which is the opposite of what a promotion is
# allowed to do. It needs its own change — most likely defaulting the export to
# 1.0 and applying it at build time — and its own look at the five rooms.
# ─────────────────────────────────────────────────────────────────────────────
