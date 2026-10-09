extends SceneTree
var OUT := ""
var checks := 0
var failures: Array[String] = []
var evidence: Dictionary = {}
const NOW = preload("res://algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd")
const OLD = preload("res://doc/book/iterations/2026-09-19-wavefunctions-review/middle/before-source/algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd")
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): OUT = a.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("CONTROLS ", "PASS " if ok else "FAIL ", message)
func state(n: Node) -> Array:
	var values: Array = []
	for o in n.oscillators: values.append([o.displacement, o.velocity, o.acceleration])
	return values
func run() -> void:
	var old = OLD.new(); var legacy = NOW.new(); var c = NOW.new()
	c.apply_grid_config({"comparison":"true"})
	check(c.get_child_count() == 0, "pre-tree configuration stores option without building")
	for n in [old, legacy, c]: root.add_child(n); n.set_process(false)
	c.apply_grid_config({"comparison":"true"})
	check(c.oscillators.size() == 144, "one complete144-sphere lattice")
	check(c.find_children("Comparison", "Node3D", false, false).size() == 1, "one console after repeated config")
	check(c.buttons.size() == 3, "three existing push-button controls")
	check(not legacy.comparison and legacy.buttons.is_empty(), "unconfigured legacy placement unchanged")
	for i in 240: old._process(1.0/120); legacy._process(1.0/120)
	check(state(old) == state(legacy), "legacy integrator exactly matches frozen source at240steps")
	c.buttons.RESET.pressed.emit()
	for i in 480: c.comparison_step(1.0/120)
	var sine_state := state(c)
	evidence.sine_peak_neighbor_m = c._neighbor_peak
	check(c._neighbor_peak > .01 and c._neighbor_peak < .04, "default sine retains subtle measured response")
	c.buttons.RESET.pressed.emit()
	for i in 480: c.comparison_step(1.0/120)
	check(state(c) == sine_state, "RESET reproduces exact same sine state")
	c.buttons.COUPLING.pressed.emit()
	check(c.coupling_strength == 0 and c.time == 0 and c.excitation_frequency == 2, "coupling toggles and resets without retuning")
	for i in 480: c.comparison_step(1.0/120)
	var center: int = 6 * 12 + 6
	check(c.oscillators.filter(func(o): return o.index != center and o.displacement != 0).is_empty(), "independent sine leaves every noncentral cell still")
	c.buttons.DRIVE.pressed.emit()
	check(c.excitation_mode == "Pulse" and not c.pulse_triggered and c.time == 0, "drive selects existing pulse and resets")
	for i in 480: c.comparison_step(1.0/120)
	check(c._neighbor_peak == 0, "independent pulse leaves neighbour still")
	c.buttons.COUPLING.pressed.emit()
	for i in 480: c.comparison_step(1.0/120)
	evidence.pulse_peak_neighbor_m = c._neighbor_peak
	check(c._neighbor_peak > .3, "same pulse propagates when coupling returns")
	var pulse_state := state(c)
	c.buttons.RESET.pressed.emit()
	for i in 480: c.comparison_step(1.0/120)
	check(state(c) == pulse_state, "RESET reproduces exact same coupled pulse state")
	c.buttons.RESET.pressed.emit()
	for i in 120: c._process(1.0/30)
	check(c.simulation_steps == 480 and state(c) == pulse_state, "30fps render batches preserve same480fixedsteps")
	c._refresh_comparison()
	check(c._comparison_readout.text.contains("COUPLED / PULSE") and c._comparison_readout.text.contains("Neighbour peak"), "readout reports chosen condition and measured peak")
	check(c.buttons.COUPLING.global_position.y > .8 and c.buttons.COUPLING.global_position.y < 1.15, "controls at reachable desktop/VR hand height")
	evidence.steps = c.simulation_steps; evidence.readout = c._comparison_readout.text
	var f = FileAccess.open(OUT + "controls.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"evidence":evidence,"headset_tested":false}, "  ")); f.close()
	print("CONTROLS COMPLETE ", checks, " / ", failures.size())
	quit(0 if failures.is_empty() else 1)
