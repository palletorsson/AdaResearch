from pathlib import Path
p=Path('commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd');s=p.read_text(encoding='utf-8')
# Replace historical promises with the current contract; original source is frozen in review/before.
a=s.index('# @identity');b=s.index('extends Node3D',a)
s=s[:a]+'''# @identity
# essence: Gray-Scott fields integrated with a normalized four-neighbour stencil
# desire: follow a feature and compare numerical resolution before naming a regime
# critical_parameter: lambda follows one authored route through four coefficients
# triggers: lambda and speed rails, reproducible restart, new seed, optional paired timesteps
# truth: a pattern is evidence of this implementation; regime names require additional measurements

'''+s[b:]
a=s.index('# ═');b=s.index('const TENURES:',a)
s=s[:a]+'''# Tenure controls access to lambda, not which equations or integrator are used.
# Earlier capture variants used a different solver from the interactive mode.
# All modes now use the same normalized stencil and bounded timestep.
'''+s[b:]
a=s.index('# The two pole tenures');b=s.index('# Fixed seed:',a)
s=s[:a]+'''# Preset poles advance for the same 192 model-time units as the old stable presets.
const PREROLL_DURATION: float = 192.0
const STABLE_DT: float = 0.3
const MAX_TICKS_PER_FRAME: int = 4

@export var comparison_study: bool = false
var time_step: float = STABLE_DT
var model_time: float = 0.0
var seed_value: int = 0x5EED17
var solver_fault: bool = false
var _time_budget: float = 0.0
var _fine_a: PackedFloat32Array
var _fine_b: PackedFloat32Array
var _fine_a_next: PackedFloat32Array
var _fine_b_next: PackedFloat32Array
var _fine_image: Image
var _fine_texture: ImageTexture
var _fine_display: MeshInstance3D
var _dt_labels: Array[Label3D] = []
var _study_readout: Label
var _study_sliders: Array[Node3D] = []
var _study_buttons: Array[Node3D] = []
var _paused: bool = false
const InterfacePresets = preload("res://commons/ui/interface_presets.gd")

'''+s[b:]
s=s.replace('## Lambda parameter: 0=frozen, 0.4=edge, 1.0=chaos','## Authored route through feed, removal and diffusion coefficients. No measured regime.')
s=s.replace('## Simulation steps per frame','## Legacy speed selector; each unit now requests 3 model-time units per second.')
s=s.replace('\tvar before_tenure: String = tenure','\tvar before_tenure: String = tenure\n\tvar previous_comparison: bool = comparison_study\n\tif config_data.has("comparison_study"):\n\t\tcomparison_study = str(config_data["comparison_study"]).to_lower() in ["on", "true", "1"]')
s=s.replace('if tenure != before_tenure:', 'if tenure != before_tenure or previous_comparison != comparison_study:')
a=s.index('## The poles keep integrating');b=s.index('# ── Build / rebuild',a)
s=s[:a]+'''## Model time follows elapsed visitor time, with bounded work per rendered frame.
## Under load the clock can lag; the readout reports actual integrated time.
func _process(delta: float) -> void:
	if _paused or solver_fault: return
	_frame_count += 1
	_time_budget = minf(_time_budget + delta * float(sim_steps) * 3.0, time_step * MAX_TICKS_PER_FRAME * 2.0)
	var ticks := 0
	while _time_budget + 0.0000001 >= time_step and ticks < MAX_TICKS_PER_FRAME:
		_advance_tick()
		_time_budget = maxf(0.0, _time_budget - time_step)
		ticks += 1
		if solver_fault: break
	if _frame_count % display_rate == 0:
		_update_texture()


'''+s[b:]
s=s.replace('\t_seed_pattern()\n\t_preroll()', '\t_seed_pattern()\n\t_reset_comparison()\n\t_preroll()\n\t_update_texture()')
s=s.replace('\t_frame_count = 0\n\t_build_all()', '\t_frame_count = 0\n\t_dt_labels.clear()\n\t_study_sliders.clear()\n\t_study_buttons.clear()\n\t_fine_display = null\n\t_fine_texture = null\n\t_fine_image = null\n\t_study_readout = null\n\t_build_all()')
a=s.index('## frozen and chaos are the only tenures');b=s.index('# ── Grid Init',a)
s=s[:a]+'''func _preroll() -> void:
	if not _is_pole(): return
	for _i in range(int(round(PREROLL_DURATION / time_step))):
		_advance_tick()


func _reset_comparison() -> void:
	model_time = 0.0
	_time_budget = 0.0
	solver_fault = false
	_fine_a = _grid_a.duplicate()
	_fine_b = _grid_b.duplicate()
	_fine_a_next.resize(_grid_a.size())
	_fine_b_next.resize(_grid_b.size())


func restart() -> void:
	_init_grid()
	_seed_pattern()
	_reset_comparison()
	_update_texture()


func new_seed() -> void:
	seed_value += 1
	restart()


func toggle_step() -> void:
	time_step = 0.15 if time_step > 0.2 else 0.3
	restart()


'''+s[b:]
s=s.replace('rng.seed = SEED_RNG','rng.seed = seed_value')
s=s.replace('# Fixed seed — five tenure stills have to be comparable, which means the\n\t# blots have to land in the same twelve places every run.', '# A numbered seed lets RESTART reproduce the field and NEW SEED change it.')
s=s.replace('# lambda=0: very low feed, high kill -> frozen, nothing grows\n\t# lambda~0.4: feed=0.037, kill=0.06 -> Turing patterns (spots/stripes)\n\t# lambda=1: high feed, low kill -> everything activates, noise', '# This is a coupled parameter path, not a measurement of criticality.')
a=s.index('func _simulate_step()');b=s.index('# ── Display',a)
s=s[:a]+'''## Normalized neighbour mean minus centre; periodic boundaries.
## No concentration clipping: B may legitimately exceed 1 during a transient.
## Palette clipping is separate from this state calculation.
func _integrate(a: PackedFloat32Array, b: PackedFloat32Array, na: PackedFloat32Array, nb: PackedFloat32Array, dt: float) -> bool:
	var gs := grid_size
	for z in range(gs):
		for x in range(gs):
			var idx := z * gs + x
			var xl := (x - 1 + gs) % gs
			var xr := (x + 1) % gs
			var zu := (z - 1 + gs) % gs
			var zd := (z + 1) % gs
			var av := a[idx]
			var bv := b[idx]
			var lap_a := (a[z*gs+xl] + a[z*gs+xr] + a[zu*gs+x] + a[zd*gs+x]) * 0.25 - av
			var lap_b := (b[z*gs+xl] + b[z*gs+xr] + b[zu*gs+x] + b[zd*gs+x]) * 0.25 - bv
			var reaction := av * bv * bv
			na[idx] = av + (_diffusion_a * lap_a - reaction + _feed_rate * (1.0-av)) * dt
			nb[idx] = bv + (_diffusion_b * lap_b + reaction - (_kill_rate+_feed_rate)*bv) * dt
			if not is_finite(na[idx]) or not is_finite(nb[idx]) or na[idx] < 0.0 or nb[idx] < 0.0:
				solver_fault = true
				push_error("Reaction-diffusion calculation stopped: invalid concentration")
				return false
	return true


func _simulate_step() -> void:
	if not _integrate(_grid_a, _grid_b, _grid_a_next, _grid_b_next, time_step): return
	var temp := _grid_a
	_grid_a = _grid_a_next
	_grid_a_next = temp
	temp = _grid_b
	_grid_b = _grid_b_next
	_grid_b_next = temp


# Retained for callers; all tenures now use this same solver.
func _simulate_step_stable() -> void:
	_simulate_step()


func _advance_tick() -> void:
	_simulate_step()
	if solver_fault: return
	if comparison_study:
		for _half in range(2):
			if not _integrate(_fine_a, _fine_b, _fine_a_next, _fine_b_next, time_step * 0.5): return
			var temp := _fine_a
			_fine_a = _fine_a_next
			_fine_a_next = temp
			temp = _fine_b
			_fine_b = _fine_b_next
			_fine_b_next = temp
	model_time += time_step


func comparison_error() -> float:
	if not comparison_study or _fine_b.is_empty(): return 0.0
	var total := 0.0
	for i in range(_grid_b.size()): total += pow(_grid_b[i] - _fine_b[i], 2)
	return sqrt(total / _grid_b.size())


'''+s[b:]
# Display additions; opt-in pair above a common console.
s=s.replace('\t# Base\n', '''	if comparison_study:
		_display_quad.position = Vector3(-0.85, 1.85, 0)
		_display_quad.rotation_degrees.x = 0
		_fine_image = Image.create(grid_size, grid_size, false, Image.FORMAT_RGB8)
		_fine_texture = ImageTexture.create_from_image(_fine_image)
		_fine_display = MeshInstance3D.new()
		_fine_display.name = "HalfStepDisplay"
		_fine_display.mesh = quad
		var fine_mat := mat.duplicate() as StandardMaterial3D
		fine_mat.albedo_texture = _fine_texture
		_fine_display.material_override = fine_mat
		_fine_display.position = Vector3(0.85, 1.85, 0)
		_own(_fine_display)
		for x in [-0.85, 0.85]:
			var dt_label := Label3D.new()
			dt_label.position = Vector3(x, 2.70, 0.02)
			dt_label.pixel_size = 0.0015
			dt_label.font_size = 32
			_own(dt_label)
			_dt_labels.append(dt_label)

	# Base
''',1)
a=s.index('func _update_texture()');b=s.index('# ── Controls',a)
s=s[:a]+'''func _paint_field(field: PackedFloat32Array, target: Image) -> void:
	for z in range(grid_size):
		for x in range(grid_size):
			var b_val: float = field[z * grid_size + x]
			var col: Color
			if b_val < 0.15:
				col = Color(0.05, 0.15, 0.18).lerp(Color(0.1, 0.3, 0.25), b_val / 0.15)
			elif b_val < 0.4:
				col = Color(0.1, 0.3, 0.25).lerp(Color(0.7, 0.55, 0.2), (b_val - 0.15) / 0.25)
			else:
				col = Color(0.7, 0.55, 0.2).lerp(Color(0.95, 0.9, 0.8), clampf((b_val-0.4)/0.6, 0.0, 1.0))
			target.set_pixel(x, z, col)


func _update_texture() -> void:
	if _image == null or _grid_b.is_empty(): return
	_paint_field(_grid_b, _image)
	_texture.update(_image)
	if comparison_study and _fine_image != null and not _fine_b.is_empty():
		_paint_field(_fine_b, _fine_image)
		_fine_texture.update(_fine_image)
		_dt_labels[0].text = "DT %.3f" % time_step
		_dt_labels[1].text = "DT %.3f" % (time_step * 0.5)
		if _study_readout:
			_study_readout.text = "t %.1f | seed %d | B difference %.5f" % [model_time, seed_value, comparison_error()]
	_update_regime_label()


'''+s[b:]
s=s.replace('func _build_controls() -> void:\n','''func _build_controls() -> void:
	if comparison_study:
		_build_comparison_controls()
		return
''')
s=s.replace('_controls.add_button("RESEED", func():\n\t\t_init_grid()\n\t\t_seed_pattern()\n\t)', '_controls.add_button("RESTART", restart)\n\t_controls.add_button("NEW SEED", new_seed)')
a=s.index('## A bar bolted')
s=s[:a]+'''func _build_comparison_controls() -> void:
	_controls = InterfacePresets.build("machine", "Same start / same time", 1.0)
	_controls.position = Vector3(0, 1.0, 0.65)
	_own(_controls)
	_study_readout = _controls.add_readout("")
	var l: Node3D = _controls.add_slider("LAMBDA", "Lambda")
	l.set_normalized_value(lambda)
	l.slider_moved.connect(func(_v):
		if tenure == "unlocked": lambda = l.get_normalized_value()
	)
	var speed: Node3D = _controls.add_slider("SIM SPEED", "Speed")
	speed.set_normalized_value(float(sim_steps - 1) / 7.0)
	speed.slider_moved.connect(func(_v): sim_steps = int(round(speed.get_normalized_value()*7.0))+1)
	_study_sliders = [l, speed]
	var callbacks: Array[Callable] = [restart, new_seed, toggle_step, _toggle_pause]
	var words := ["RESTART", "NEW SEED", "HALVE DT", "HOLD / RUN"]
	for i in range(words.size()):
		var button: Node3D = _controls.add_button(words[i])
		button.pressed.connect(callbacks[i])
		_study_buttons.append(button)


func _toggle_pause() -> void:
	_paused = not _paused


'''+s[a:]
# Use plain label and mark no universal measured regime.
s=s.replace('var word: String = "EDGE OF CHAOS"','var word: String = "LAMBDA MID"').replace('word = "FROZEN"','word = "LAMBDA LOW"').replace('word = "CHAOS"','word = "LAMBDA HIGH"')
s=s.replace('func _build_labels() -> void:\n','''func _build_labels() -> void:
	if comparison_study:
		return  # Per-display timestep labels and the console carry this encounter.
''')
s=s.replace('"EDGE OF CHAOS — WITHHELD"','"PATTERN — WITHHELD"').replace('"EDGE OF CHAOS — UNLOCKED"','"PATTERN — UNLOCKED"')
s=s.replace('screen.title = "EDGE OF CHAOS"','screen.title = "PARAMETER SETTING"')
p.write_text(s,encoding='utf-8');print('Shared solver and paired timestep study implemented')
