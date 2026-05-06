extends Node3D
class_name SortingAlgorithmRace

# @identity
# essence: four rows of 16 colored bars sort simultaneously using Bubble, Insertion, Selection, and Merge — each row animates one comparison/swap per tick so you can watch algorithms race
# desire: to see that sorting is not one thing but many strategies, each with a different rhythm — bubble plods, insertion slides, selection scans, merge conquers — and to feel the difference in your body as you watch them finish at different times
# critical_parameter: step_speed — controls ticks per second; at low speed you see every comparison, at high speed you see the emergent motion patterns of each algorithm
# triggers: SHUFFLE resets all rows to the same random permutation; RUN toggles continuous stepping; STEP advances one tick manually; SPEED slider adjusts tick rate
# emerges: merge sort finishes first almost every time, bubble sort last — the visual proof is more convincing than any Big-O lecture because you watched it happen
# needs: RackTemplates panel [has]; 4x16 bar grid [has]; per-algorithm state machines [has]; green flash on completion [has]
# relationships: complements sort_algorithm_animation in primitives (single algorithm focus) by showing comparison; feeds into complexity analysis artifacts
# truth: sorting algorithms are strategies for restoring order — watching four strategies race reveals that the question is never "does it work" but "how does it think"

const BAR_COUNT := 16
const ROW_COUNT := 4
const BAR_WIDTH := 0.012
const BAR_DEPTH := 0.012
const BAR_SPACING := 0.018
const ROW_SPACING := 0.12
const MAX_BAR_HEIGHT := 0.08

var _arrays: Array = []        # Array of Array[int] — one per row
var _bars: Array = []          # Array of Array[MeshInstance3D]
var _states: Array = []        # per-algorithm state dictionaries
var _completed: Array = [false, false, false, false]
var _running: bool = false
var _step_speed: float = 0.5   # normalized 0..1
var _tick_accum: float = 0.0
var _labels: Array = ["BUBBLE", "INSERT", "SELECT", "MERGE"]
var _row_labels: Array = []    # Label3D refs
var _flash_timers: Array = [0.0, 0.0, 0.0, 0.0]

# Panel references
var _speed_slider: Node = null
var _run_btn: Node = null

func _ready() -> void:
	_build_bars()
	_build_panel()
	_shuffle_all()

func apply_grid_config(config_data: Dictionary) -> void:
	pass

# ── Bar construction ────────────────────────────────────────────────

func _build_bars() -> void:
	var total_width := BAR_SPACING * (BAR_COUNT - 1)
	var start_x := -total_width / 2.0

	for row in ROW_COUNT:
		var row_bars: Array = []
		var row_y_offset := -row * ROW_SPACING
		_arrays.append([])

		# Row label
		var lbl := Label3D.new()
		lbl.text = _labels[row]
		lbl.font_size = 14
		lbl.pixel_size = 0.0004
		lbl.modulate = Color(0.85, 0.85, 0.85)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.transform.origin = Vector3(start_x - 0.03, row_y_offset + MAX_BAR_HEIGHT / 2.0, 0)
		add_child(lbl)
		_row_labels.append(lbl)

		for i in BAR_COUNT:
			var bar := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(BAR_WIDTH, MAX_BAR_HEIGHT, BAR_DEPTH)
			bar.mesh = box
			bar.material_override = _make_bar_material(i)
			bar.transform.origin = Vector3(start_x + i * BAR_SPACING, row_y_offset, 0)
			add_child(bar)
			row_bars.append(bar)

		_bars.append(row_bars)

func _make_bar_material(value: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var hue := float(value) / float(BAR_COUNT)
	mat.albedo_color = Color.from_hsv(hue, 0.8, 0.9)
	mat.emission = Color.from_hsv(hue, 0.6, 0.4)
	mat.emission_energy_multiplier = 0.3
	mat.roughness = 0.5
	return mat

# ── Panel ───────────────────────────────────────────────────────────

func _build_panel() -> void:
	var panel := RackTemplates.create_panel("SORT RACE", [
		[{"type": "slider_h", "label": "SPEED", "default": 0.5}],
		[
			{"type": "button", "label": "SHUFFLE"},
			{"type": "button", "label": "STEP"},
			{"type": "button", "label": "RUN"},
		],
	])
	panel.transform.origin = Vector3(0, -ROW_SPACING * ROW_COUNT - 0.06, 0)
	add_child(panel)

	# Wire up controls
	_speed_slider = panel.find_child("Param_0", true, false)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_changed)

	var shuffle_btn := panel.find_child("Btn_0", true, false)
	if shuffle_btn:
		var area := shuffle_btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			area.button_pressed.connect(_on_shuffle_pressed)

	var step_btn := panel.find_child("Btn_1", true, false)
	if step_btn:
		var area := step_btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			area.button_pressed.connect(_on_step_pressed)

	_run_btn = panel.find_child("Btn_2", true, false)
	if _run_btn:
		var area := _run_btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			area.button_pressed.connect(_on_run_pressed)

func _on_speed_changed(_value: float) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		_step_speed = _speed_slider.get_normalized_value()

func _on_shuffle_pressed() -> void:
	_shuffle_all()

func _on_step_pressed() -> void:
	_step_all()

func _on_run_pressed() -> void:
	_running = not _running

# ── Shuffle ─────────────────────────────────────────────────────────

func _shuffle_all() -> void:
	_running = false
	_completed = [false, false, false, false]
	_flash_timers = [0.0, 0.0, 0.0, 0.0]

	# Build a shuffled array
	var base: Array = []
	for i in BAR_COUNT:
		base.append(i)
	base.shuffle()

	# All rows get the same shuffled start
	_arrays.clear()
	for _row in ROW_COUNT:
		_arrays.append(base.duplicate())

	# Reset algorithm states
	_states.clear()
	# Bubble: i, j
	_states.append({"i": 0, "j": 0})
	# Insertion: key_idx (which element we're inserting)
	_states.append({"key_idx": 1, "j": 0, "phase": "pick"})
	# Selection: i, j, min_idx
	_states.append({"i": 0, "j": 1, "min_idx": 0})
	# Merge: pre-computed swap sequence
	_states.append({"steps": _precompute_merge(base.duplicate()), "step_idx": 0})

	_update_all_visuals()

	# Reset label colors
	for lbl in _row_labels:
		lbl.modulate = Color(0.85, 0.85, 0.85)

# ── Process ─────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Flash timers
	for row in ROW_COUNT:
		if _flash_timers[row] > 0:
			_flash_timers[row] -= delta
			if _flash_timers[row] <= 0:
				_row_labels[row].modulate = Color(0.4, 1.0, 0.4)

	if not _running:
		return

	var ticks_per_sec := lerpf(2.0, 60.0, _step_speed)
	_tick_accum += delta * ticks_per_sec
	while _tick_accum >= 1.0:
		_tick_accum -= 1.0
		_step_all()

# ── Step all algorithms ─────────────────────────────────────────────

func _step_all() -> void:
	if not _completed[0]:
		_step_bubble()
	if not _completed[1]:
		_step_insertion()
	if not _completed[2]:
		_step_selection()
	if not _completed[3]:
		_step_merge()
	_update_all_visuals()

	# Check if all done
	var all_done := true
	for c in _completed:
		if not c:
			all_done = false
			break
	if all_done:
		_running = false

# ── Bubble Sort step ────────────────────────────────────────────────

func _step_bubble() -> void:
	var arr: Array = _arrays[0]
	var st: Dictionary = _states[0]
	var i: int = st["i"]
	var j: int = st["j"]

	if i >= BAR_COUNT - 1:
		_mark_completed(0)
		return

	if j < BAR_COUNT - 1 - i:
		if arr[j] > arr[j + 1]:
			var tmp = arr[j]
			arr[j] = arr[j + 1]
			arr[j + 1] = tmp
		st["j"] = j + 1
	else:
		st["i"] = i + 1
		st["j"] = 0

# ── Insertion Sort step ─────────────────────────────────────────────

func _step_insertion() -> void:
	var arr: Array = _arrays[1]
	var st: Dictionary = _states[1]
	var key_idx: int = st["key_idx"]

	if key_idx >= BAR_COUNT:
		_mark_completed(1)
		return

	if st["phase"] == "pick":
		st["j"] = key_idx
		st["phase"] = "shift"

	if st["phase"] == "shift":
		var j: int = st["j"]
		if j > 0 and arr[j - 1] > arr[j]:
			var tmp = arr[j]
			arr[j] = arr[j - 1]
			arr[j - 1] = tmp
			st["j"] = j - 1
		else:
			st["key_idx"] = key_idx + 1
			st["phase"] = "pick"

# ── Selection Sort step ─────────────────────────────────────────────

func _step_selection() -> void:
	var arr: Array = _arrays[2]
	var st: Dictionary = _states[2]
	var i: int = st["i"]
	var j: int = st["j"]
	var min_idx: int = st["min_idx"]

	if i >= BAR_COUNT - 1:
		_mark_completed(2)
		return

	if j < BAR_COUNT:
		if arr[j] < arr[min_idx]:
			st["min_idx"] = j
		st["j"] = j + 1
	else:
		# Swap min to position i
		if min_idx != i:
			var tmp = arr[i]
			arr[i] = arr[min_idx]
			arr[min_idx] = tmp
		st["i"] = i + 1
		st["j"] = i + 2
		st["min_idx"] = i + 1

# ── Merge Sort (pre-computed steps) ─────────────────────────────────

func _precompute_merge(arr: Array) -> Array:
	var steps: Array = []
	_merge_sort_record(arr, 0, arr.size() - 1, steps)
	return steps

func _merge_sort_record(arr: Array, left: int, right: int, steps: Array) -> void:
	if left >= right:
		return
	var mid := (left + right) / 2
	_merge_sort_record(arr, left, mid, steps)
	_merge_sort_record(arr, mid + 1, right, steps)
	_merge_record(arr, left, mid, right, steps)

func _merge_record(arr: Array, left: int, mid: int, right: int, steps: Array) -> void:
	var left_arr: Array = arr.slice(left, mid + 1)
	var right_arr: Array = arr.slice(mid + 1, right + 1)
	var i := 0
	var j := 0
	var k := left
	var result: Array = []
	while i < left_arr.size() and j < right_arr.size():
		if left_arr[i] <= right_arr[j]:
			result.append(left_arr[i])
			i += 1
		else:
			result.append(right_arr[j])
			j += 1
	while i < left_arr.size():
		result.append(left_arr[i])
		i += 1
	while j < right_arr.size():
		result.append(right_arr[j])
		j += 1
	# Record the state change as swap pairs
	for idx in result.size():
		arr[left + idx] = result[idx]
	# Record as a single "set range" step
	steps.append({"left": left, "values": result.duplicate()})

func _step_merge() -> void:
	var arr: Array = _arrays[3]
	var st: Dictionary = _states[3]
	var steps: Array = st["steps"]
	var step_idx: int = st["step_idx"]

	if step_idx >= steps.size():
		_mark_completed(3)
		return

	var step: Dictionary = steps[step_idx]
	var left: int = step["left"]
	var values: Array = step["values"]
	for i in values.size():
		arr[left + i] = values[i]
	st["step_idx"] = step_idx + 1

# ── Completion ──────────────────────────────────────────────────────

func _mark_completed(row: int) -> void:
	_completed[row] = true
	_flash_timers[row] = 0.5
	_row_labels[row].modulate = Color(0.2, 1.0, 0.2)

# ── Visual update ───────────────────────────────────────────────────

func _update_all_visuals() -> void:
	var total_width := BAR_SPACING * (BAR_COUNT - 1)
	var start_x := -total_width / 2.0

	for row in ROW_COUNT:
		var arr: Array = _arrays[row]
		var row_bars: Array = _bars[row]
		var row_y_offset := -row * ROW_SPACING

		for i in BAR_COUNT:
			var val: int = arr[i]
			var bar: MeshInstance3D = row_bars[i]
			var height := lerpf(0.01, MAX_BAR_HEIGHT, float(val) / float(BAR_COUNT - 1))

			# Update mesh height
			var box: BoxMesh = bar.mesh
			box.size.y = height

			# Update position (bar grows from bottom)
			bar.transform.origin = Vector3(
				start_x + i * BAR_SPACING,
				row_y_offset + height / 2.0,
				0
			)

			# Update color by value
			bar.material_override = _make_bar_material(val)
