extends Node3D
class_name HaltingWorkbench

# @identity
# essence: an interactive halting-problem workbench — the player turns a slider to pick one of 8 Turing machines from the gallery, presses STEP (or pulls the budget slider) to run the machine on a live tape, and watches the head move, the state cycle, and the halt banner flip from RUNNING to HALTED if and when the machine actually stops. Eight cells from /halting-bench-gallery come alive: BB(2) halts in 6, BB(3) in 14, BB(4) in 107 with 13 ones; shift-right runs forever; the bouncer oscillates; the deceptive halter writes its tape with no stopping in sight; STATUS_UNKNOWN keeps running past the 1000-step budget. You can SEE which halts — you cannot, in general, PREDICT.
# desire: learner viscerally feels the halting problem — every step is computable; the question "will the entire run halt" is not. Each machine looks like every other machine at any given step; only the trajectory tells you which is which, and only sometimes.
# critical_parameter: machine_index (0..7) — picks which transition table to seed; step_budget — picks how far to auto-run
# triggers: _ready() builds plate + machine slider + budget slider + STEP button + tape display + state/step/banner panel + rules panel; machine slider selects + resets a TuringMachine; STEP button advances 1; budget slider auto-runs to N steps or halt
# emerges: the halting problem made literal — same chassis, 8 different transition tables, 8 different fates. Three halt (Σ(2)=6, Σ(3)=14, Σ(4)=107). Three never halt (shift-right, bouncer, deceptive). Two run past their visible budget (long_halter — actually Σ(4) again, and STATUS_UNKNOWN). The player learns by watching which halt-banner turns green.
# needs: slider_horizontal [present]; push_button [present]; TuringMachine class [sibling file]; Label3D for readouts and rules
# relationships: paired with /halting-bench-gallery (web cells frozen at end-of-budget snapshots) — this is the live version that runs them step-by-step. Sibling to shannon_workbench, cantor_diagonal_workbench, russell_paradox_workbench, complexity_dial_workbench — together the workbench substrate covers the limits-of-X corner of the curriculum.
# truth: every machine is decidable PER STEP — you can always do the next step. Whether the whole run halts is, in general, undecidable. The workbench is a window onto that gap: the green banner is the only honest answer, and it appears only when (and if) it does.

## A horizontal workbench for the halting problem.
##
## Picks a Turing machine via the LEFT slider (8 discrete positions), advances
## one step via the STEP button, OR auto-runs to N steps via the RIGHT slider.
## The tape, the head, the state, the step counter, the rules, and the
## halt/run banner all update live.
##
## Eight machines come from the gallery; see turing_machine.gd. The rules below
## are copied verbatim from commons/testing/capture_halting_bench_gallery.gd
## (canonical: BB(2) Rado 1962; BB(3) Rado/Lin 1965; BB(4) Brady 1983).

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
@export var plate_tilt_deg: float = -25.0
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Tape")
## Number of cells visible at once. Odd → head is exactly centered.
@export var tape_visible: int = 31
## Horizontal span of the tape (meters, before plate scale).
@export var tape_width: float = 1.2
## Height above plate origin.
@export var tape_height: float = 1.45
## Forward distance in front of the plate.
@export var tape_depth: float = -0.20
@export var color_zero: Color = Color(0.94, 0.94, 0.96)
@export var color_one_halted: Color = Color(0.42, 0.86, 0.50)
@export var color_one_running: Color = Color(0.96, 0.58, 0.32)
@export var color_head: Color = Color(0.98, 0.82, 0.28)
@export var color_cell_border: Color = Color(0.18, 0.20, 0.26)

@export_group("Auto-Run")
## When auto-stepping to a budget, how many steps to take per process tick.
## Small → smoother animation, but slow for long machines. Large → snappy.
@export var steps_per_tick: int = 5

# ── Internal state ────────────────────────────────────────────────────

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const DisplayMount = preload("res://commons/ui/display_mount.gd")

var _machine_index: int = 0
var _target_steps: int = 0
var _auto_running: bool = false

var _tm: TuringMachine

var _plate_root: Node3D
var _display_root: Node3D            # anchor that carries the viz cluster
var _machine_slider: Node
var _budget_slider: Node
var _step_button: Node
var _plate_readout

var _tape_root: Node3D
var _tape_cell_materials: Array[StandardMaterial3D] = []
var _head_arrow_inst: MeshInstance3D

var _readout_root: Node3D
var _state_label: Label3D
var _step_label: Label3D
var _ones_label: Label3D
var _banner_label: Label3D
var _banner_bg_mat: StandardMaterial3D
var _machine_name_label: Label3D

var _rules_root: Node3D
var _rule_labels: Array[Label3D] = []
var _rules_title: Label3D

# ── Machine specs (copied verbatim from capture_halting_bench_gallery.gd) ─

const MACHINES: Array = [
	{
		"id": "1_bb2_busy_beaver",
		"name": "BB(2) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "H"],
		},
		"halt_state": "H",
		"step_budget": 10,
		"expected_halt": true,
		"category": "halts",
		"notes": "Σ(2) = 6 steps, 4 ones — Rado 1962",
	},
	{
		"id": "2_bb3_busy_beaver",
		"name": "BB(3) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", 1, "H"],
			"B|0": ["0", 1, "C"],
			"B|1": ["1", 1, "B"],
			"C|0": ["1", -1, "C"],
			"C|1": ["1", -1, "A"],
		},
		"halt_state": "H",
		"step_budget": 20,
		"expected_halt": true,
		"category": "halts",
		"notes": "Σ(3) = 14 steps, 6 ones — Rado/Lin 1965",
	},
	{
		"id": "3_shift_right_forever",
		"name": "Shift-right forever",
		"rules": {
			"A|0": ["1", 1, "A"],
			"A|1": ["1", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 30,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "1 state, always 1, always R — never halts",
	},
	{
		"id": "4_bouncer",
		"name": "Bouncer",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["0", -1, "A"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", 1, "B"],
		},
		"halt_state": "H",
		"step_budget": 50,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "Two states ping-ponging — cycles forever",
	},
	{
		"id": "5_deceptive_halter",
		"name": "Deceptive halter",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "C"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "B"],
			"C|0": ["0", 1, "A"],
			"C|1": ["1", -1, "C"],
		},
		"halt_state": "H",
		"step_budget": 200,
		"expected_halt": false,
		"category": "never_halts",
		"notes": "Looks like it might halt — never does in 200 steps",
	},
	{
		"id": "6_long_halter",
		"name": "Long halter (~107 steps)",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", -1, "C"],
			"C|0": ["1", 1, "H"],
			"C|1": ["1", -1, "D"],
			"D|0": ["1", 1, "D"],
			"D|1": ["0", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 200,
		"expected_halt": true,
		"category": "halts",
		"notes": "Halts ~step 107 — Brady's BB(4) structure",
	},
	{
		"id": "7_bb4_busy_beaver",
		"name": "BB(4) busy beaver",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["1", -1, "B"],
			"B|0": ["1", -1, "A"],
			"B|1": ["0", -1, "C"],
			"C|0": ["1", 1, "H"],
			"C|1": ["1", -1, "D"],
			"D|0": ["1", 1, "D"],
			"D|1": ["0", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 150,
		"expected_halt": true,
		"category": "halts",
		"notes": "Σ(4) = 107 steps, 13 ones — Brady 1983",
	},
	{
		"id": "8_unknown_at_budget",
		"name": "Unknown — undecidable case",
		"rules": {
			"A|0": ["1", 1, "B"],
			"A|1": ["0", -1, "C"],
			"B|0": ["1", -1, "A"],
			"B|1": ["1", 1, "D"],
			"C|0": ["1", 1, "D"],
			"C|1": ["0", -1, "B"],
			"D|0": ["1", -1, "C"],
			"D|1": ["1", 1, "A"],
		},
		"halt_state": "H",
		"step_budget": 1000,
		"expected_halt": false,
		"category": "unknown",
		"notes": "1000 steps in, no halt — undecidable in general",
	},
]


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_tm = TuringMachine.new()
	_load_machine(_machine_index)
	_build_plate_and_controls()
	_build_tape()
	_build_readout_panel()
	_build_rules_panel()
	_refresh_all()
	_mount_display.call_deferred()


## Gather the viz roots onto a composer-placed anchor + floor stand (DisplayMount).
func _mount_display() -> void:
	var center := Vector3(0.0, tape_height, tape_depth)
	_display_root = DisplayMount.make_anchor(self, "halting_workbench", center, 1.0, 0.0)
	DisplayMount.mount_cluster(_display_root, [_tape_root, _readout_root, _rules_root], center)
	DisplayMount.build_stand(self, _display_root)


func _process(_delta: float) -> void:
	# Auto-run controller: when the budget slider is non-zero and the machine
	# is below the target, advance steps_per_tick steps per frame until we
	# reach the target or the machine halts.
	if not _auto_running:
		return
	if _tm == null:
		return
	if _tm.halted or _tm.steps >= _target_steps:
		_auto_running = false
		_refresh_readout()
		_refresh_tape()
		return
	var n: int = steps_per_tick
	while n > 0 and not _tm.halted and _tm.steps < _target_steps:
		_tm.step()
		n -= 1
	_refresh_tape()
	_refresh_readout()


# ── Machine selection ─────────────────────────────────────────────────

func _load_machine(idx: int) -> void:
	idx = clampi(idx, 0, MACHINES.size() - 1)
	_machine_index = idx
	_tm.load_spec(MACHINES[idx])
	_target_steps = 0
	_auto_running = false


func _machine_index_for_normalized(frac: float) -> int:
	var count: int = MACHINES.size()
	var idx: int = int(roundf(clampf(frac, 0.0, 1.0) * float(count - 1)))
	return clampi(idx, 0, count - 1)


func _normalized_for_machine_index(idx: int) -> float:
	var count: int = MACHINES.size()
	if count <= 1:
		return 0.0
	return float(idx) / float(count - 1)


# ── Plate + controls ──────────────────────────────────────────────────

func _build_plate_and_controls() -> void:
	# Canonical desktop ControlConsole (workbench principal): machine slider, STEP
	# button, budget slider + a summary readout. Tape / rules / detail readout stay
	# as world-space viz. Replaces the hand-built plate + jumpy slider_horizontal.
	_plate_root = InterfacePresets.build("workbench", "Halting", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")

	_machine_slider = _plate_root.add_slider("machine (1..8)", "machine")
	if _machine_slider and _machine_slider.has_method("set_normalized_value"):
		_machine_slider.call("set_normalized_value", _normalized_for_machine_index(_machine_index))
	if _machine_slider and _machine_slider.has_signal("slider_moved"):
		_machine_slider.connect("slider_moved", Callable(self, "_on_machine_slider_changed"))

	_step_button = _plate_root.add_button("STEP")
	if _step_button:
		if "released_color" in _step_button:
			_step_button.set("released_color", Color(0.98, 0.82, 0.28, 1.0))
			_step_button.set("pressed_color", Color(0.30, 0.95, 1.0, 1.0))
		if _step_button.has_signal("pressed"):
			_step_button.connect("pressed", Callable(self, "_on_step_pressed"))

	_budget_slider = _plate_root.add_slider("auto-run budget", "budget")
	if _budget_slider and _budget_slider.has_method("set_normalized_value"):
		_budget_slider.call("set_normalized_value", 0.0)
	if _budget_slider and _budget_slider.has_signal("slider_moved"):
		_budget_slider.connect("slider_moved", Callable(self, "_on_budget_slider_changed"))


func _on_machine_slider_changed(_value) -> void:
	if _machine_slider == null or not _machine_slider.has_method("get_normalized_value"):
		return
	var frac: float = float(_machine_slider.call("get_normalized_value"))
	var idx: int = _machine_index_for_normalized(frac)
	if idx == _machine_index:
		return
	_load_machine(idx)
	# Reset the budget slider so a new machine starts at step 0.
	if _budget_slider and _budget_slider.has_method("set_normalized_value"):
		_budget_slider.call("set_normalized_value", 0.0)
	_rebuild_rules_panel()
	_refresh_all()


func _on_budget_slider_changed(_value) -> void:
	if _budget_slider == null or not _budget_slider.has_method("get_normalized_value"):
		return
	var frac: float = clampf(float(_budget_slider.call("get_normalized_value")), 0.0, 1.0)
	var budget: int = int(MACHINES[_machine_index].get("step_budget", 200))
	_target_steps = int(roundf(frac * float(budget)))
	# If the new target is below current steps (slider dragged back), reset and
	# replay — same machine, less far. This keeps the slider a true "budget"
	# scrubber rather than a one-way valve.
	if _target_steps < _tm.steps:
		_tm.reset()
	_auto_running = (_target_steps > _tm.steps and not _tm.halted)
	if not _auto_running:
		# If we already overshot or halted, just refresh the readout.
		_refresh_tape()
		_refresh_readout()


func _on_step_pressed() -> void:
	if _tm == null:
		return
	if _tm.halted:
		return
	_tm.step()
	_target_steps = max(_target_steps, _tm.steps)  # keep budget consistent
	_refresh_tape()
	_refresh_readout()


# ── Tape display ──────────────────────────────────────────────────────

func _build_tape() -> void:
	_tape_root = Node3D.new()
	_tape_root.name = "Tape"
	_tape_root.position = Vector3(0.0, tape_height, tape_depth)
	add_child(_tape_root)

	# Backplate behind the tape for contrast.
	var back := MeshInstance3D.new()
	back.name = "TapeBackplate"
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(tape_width + 0.05, 0.18)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.02, 0.04)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(0.0, 0.0, -0.005)
	_tape_root.add_child(back)

	# Build TAPE_VISIBLE cells.
	var pitch: float = tape_width / float(tape_visible)
	var cell_size: float = pitch * 0.86
	var origin_x: float = -tape_width * 0.5 + pitch * 0.5

	_tape_cell_materials.clear()
	for i in range(tape_visible):
		var cell := MeshInstance3D.new()
		cell.name = "Cell_%d" % i
		var qm := QuadMesh.new()
		qm.size = Vector2(cell_size, cell_size)
		cell.mesh = qm
		cell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_zero
		mat.emission_enabled = true
		mat.emission = Color(0, 0, 0)
		mat.emission_energy_multiplier = 0.6
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cell.material_override = mat

		var x: float = origin_x + i * pitch
		cell.position = Vector3(x, 0.0, 0.0)
		_tape_root.add_child(cell)
		_tape_cell_materials.append(mat)

	# Head arrow — a triangle pointing UP at the center cell.
	# Built from a small PrismMesh rotated so its tip points +Y.
	_head_arrow_inst = MeshInstance3D.new()
	_head_arrow_inst.name = "HeadArrow"
	var arrow_mesh := PrismMesh.new()
	arrow_mesh.size = Vector3(cell_size * 0.7, cell_size * 0.7, 0.02)
	arrow_mesh.left_to_right = 0.5  # symmetric
	_head_arrow_inst.mesh = arrow_mesh
	_head_arrow_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = color_head
	arrow_mat.emission_enabled = true
	arrow_mat.emission = color_head
	arrow_mat.emission_energy_multiplier = 1.6
	arrow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_head_arrow_inst.material_override = arrow_mat
	# Position: below the center cell, tip pointing up.
	_head_arrow_inst.position = Vector3(0.0, -cell_size * 0.75, 0.01)
	_tape_root.add_child(_head_arrow_inst)


func _refresh_tape() -> void:
	if _tm == null or _tape_cell_materials.is_empty():
		return
	var symbols: PackedStringArray = _tm.tape_window(tape_visible)
	var one_color: Color = color_one_halted if _tm.halted else color_one_running
	for i in range(symbols.size()):
		var mat := _tape_cell_materials[i]
		if symbols[i] == "1":
			mat.albedo_color = one_color
			mat.emission = one_color
			mat.emission_energy_multiplier = 1.4
		else:
			mat.albedo_color = color_zero
			mat.emission = Color(0, 0, 0)
			mat.emission_energy_multiplier = 0.0


# ── Readout panel ─────────────────────────────────────────────────────

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	# Floats above the tape.
	_readout_root.position = Vector3(0.0, tape_height + 0.32, tape_depth)
	add_child(_readout_root)

	# Banner background.
	var banner_bg := MeshInstance3D.new()
	banner_bg.name = "BannerBG"
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(0.7, 0.10)
	banner_bg.mesh = bg_mesh
	_banner_bg_mat = StandardMaterial3D.new()
	_banner_bg_mat.albedo_color = Color(0.92, 0.40, 0.42)
	_banner_bg_mat.emission_enabled = true
	_banner_bg_mat.emission = Color(0.92, 0.40, 0.42)
	_banner_bg_mat.emission_energy_multiplier = 0.7
	_banner_bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	banner_bg.material_override = _banner_bg_mat
	banner_bg.position = Vector3(0.0, 0.04, -0.005)
	_readout_root.add_child(banner_bg)

	# Banner label (HALTED / RUNNING / STATUS UNKNOWN).
	_banner_label = Label3D.new()
	_banner_label.font_size = 48
	_banner_label.outline_size = 6
	_banner_label.pixel_size = 0.001
	_banner_label.modulate = Color(0.05, 0.06, 0.09)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.position = Vector3(0.0, 0.04, 0.0)
	_readout_root.add_child(_banner_label)

	# Machine name (below banner).
	_machine_name_label = Label3D.new()
	_machine_name_label.font_size = 26
	_machine_name_label.outline_size = 3
	_machine_name_label.pixel_size = 0.001
	_machine_name_label.modulate = Color(0.85, 0.9, 1.0)
	_machine_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_machine_name_label.position = Vector3(0.0, -0.04, 0.0)
	_readout_root.add_child(_machine_name_label)

	# State label (top-left of the tape).
	_state_label = Label3D.new()
	_state_label.font_size = 32
	_state_label.outline_size = 3
	_state_label.pixel_size = 0.001
	_state_label.modulate = Color(1.0, 0.97, 0.7)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_state_label.position = Vector3(-0.45, -0.09, 0.0)
	_readout_root.add_child(_state_label)

	# Step counter (top-right).
	_step_label = Label3D.new()
	_step_label.font_size = 28
	_step_label.outline_size = 3
	_step_label.pixel_size = 0.001
	_step_label.modulate = Color(0.7, 0.85, 1.0)
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_step_label.position = Vector3(0.45, -0.09, 0.0)
	_readout_root.add_child(_step_label)

	# Ones counter (below the state/step).
	_ones_label = Label3D.new()
	_ones_label.font_size = 22
	_ones_label.outline_size = 3
	_ones_label.pixel_size = 0.001
	_ones_label.modulate = Color(0.62, 0.66, 0.74)
	_ones_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ones_label.position = Vector3(0.0, -0.14, 0.0)
	_readout_root.add_child(_ones_label)


func _refresh_readout() -> void:
	if _tm == null:
		return
	var spec: Dictionary = MACHINES[_machine_index]

	# Banner.
	var category: String = spec.get("category", "")
	var budget: int = int(spec.get("step_budget", 200))
	var banner_text: String
	var banner_color: Color
	if _tm.halted:
		banner_text = "HALTED ✓"
		banner_color = Color(0.42, 0.86, 0.50)
	elif category == "unknown" and _tm.steps >= budget:
		banner_text = "STATUS UNKNOWN"
		banner_color = Color(0.55, 0.45, 0.95)
	else:
		banner_text = "RUNNING…"
		banner_color = Color(0.92, 0.40, 0.42)
	_banner_label.text = banner_text
	if _plate_readout:
		_plate_readout.text = "machine %d / 8\n%s · %d steps" % [_machine_index + 1, banner_text, _tm.steps]
	if _banner_bg_mat:
		_banner_bg_mat.albedo_color = banner_color
		_banner_bg_mat.emission = banner_color

	# State.
	if _tm.halted:
		_state_label.text = "STATE: HALT"
		_state_label.modulate = Color(0.42, 0.86, 0.50)
	else:
		_state_label.text = "STATE: %s" % _tm.state
		_state_label.modulate = Color(1.0, 0.97, 0.7)

	# Step counter.
	if _tm.halted:
		_step_label.text = "halted at step %d/%d" % [_tm.steps, budget]
	else:
		_step_label.text = "step %d/%d" % [_tm.steps, budget]

	# Ones.
	var ones_prefix: String = "ones written: " if _tm.halted else "ones on tape: "
	_ones_label.text = "%s%d" % [ones_prefix, _tm.ones_written]

	# Machine name.
	_machine_name_label.text = "%d/%d — %s" % [_machine_index + 1, MACHINES.size(), spec.get("name", "?")]


# ── Rules panel ───────────────────────────────────────────────────────

func _build_rules_panel() -> void:
	_rules_root = Node3D.new()
	_rules_root.name = "Rules"
	# Floats to the right of the tape.
	_rules_root.position = Vector3(tape_width * 0.5 + 0.18, tape_height, tape_depth)
	add_child(_rules_root)

	# Dark backing card.
	var card := MeshInstance3D.new()
	card.name = "RulesCard"
	var card_mesh := QuadMesh.new()
	card_mesh.size = Vector2(0.32, 0.40)
	card.mesh = card_mesh
	var card_mat := StandardMaterial3D.new()
	card_mat.albedo_color = Color(0.03, 0.05, 0.08)
	card_mat.roughness = 0.7
	card.material_override = card_mat
	card.position = Vector3(0.0, 0.0, -0.005)
	_rules_root.add_child(card)

	# Title.
	_rules_title = Label3D.new()
	_rules_title.text = "RULES"
	_rules_title.font_size = 24
	_rules_title.outline_size = 3
	_rules_title.pixel_size = 0.001
	_rules_title.modulate = Color(0.62, 0.66, 0.74)
	_rules_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules_title.position = Vector3(0.0, 0.16, 0.0)
	_rules_root.add_child(_rules_title)

	_rebuild_rules_panel()


func _rebuild_rules_panel() -> void:
	# Tear down any existing rule labels.
	for lbl in _rule_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_rule_labels.clear()

	if _rules_root == null:
		return

	var spec: Dictionary = MACHINES[_machine_index]
	var rules: Dictionary = spec.get("rules", {})
	var lines: Array = _format_rules(rules)

	# Vertical stack — up to 8 lines fit.
	var line_height: float = 0.030
	var y0: float = 0.13 - line_height
	for i in range(lines.size()):
		var rule_lab := Label3D.new()
		rule_lab.text = lines[i]
		rule_lab.font_size = 22
		rule_lab.outline_size = 3
		rule_lab.pixel_size = 0.001
		rule_lab.modulate = Color(0.85, 0.9, 1.0)
		rule_lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rule_lab.position = Vector3(0.0, y0 - i * line_height, 0.0)
		_rules_root.add_child(rule_lab)
		_rule_labels.append(rule_lab)


static func _format_rules(rules: Dictionary) -> Array:
	# Sort keys for deterministic display: A|0, A|1, B|0, B|1, ...
	var keys: Array = rules.keys()
	keys.sort()
	var out: Array = []
	for k in keys:
		var rule: Array = rules[k]
		var parts: PackedStringArray = str(k).split("|")
		var state: String = parts[0]
		var read_sym: String = parts[1]
		var write_sym: String = str(rule[0])
		var move: String = "R" if int(rule[1]) > 0 else "L"
		var next_state: String = str(rule[2])
		out.append("%s,%s → %s,%s,%s" % [state, read_sym, write_sym, move, next_state])
	return out


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_tape()
	_refresh_readout()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_machine"):
		var idx: int = int(config_data["initial_machine"])
		_load_machine(idx)
		if _machine_slider and _machine_slider.has_method("set_normalized_value"):
			_machine_slider.call("set_normalized_value", _normalized_for_machine_index(idx))
		_rebuild_rules_panel()
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("steps_per_tick"):
		steps_per_tick = int(config_data["steps_per_tick"])
