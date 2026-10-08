extends SceneTree

## GATE — ML_Sequence_Memory: a cell state that actually carries a past.
##
## The hall's own prose said this artifact "does not yet carry an input sequence through
## a computed recurrent memory", and its @identity header claimed the LSTM update as its
## essence while no such expression existed in 516 lines. This probe holds the new one to
## the only standard that matters: two histories ending in the SAME final input must
## produce different outputs, and they must do so BY COMPUTATION.
##
## The rule is linear on purpose: c = f*c + i*x, h = o*c. That makes the divergence exact
## and checkable — two histories differing only at step 1 end up differing by exactly
## 2*f*i in c — so the forget gate is not a mood, it is the coefficient on the past.
##
##   A  default off             -> the artifact that ships in two other maps is untouched
##   B  two histories           -> same last input, different h
##   C  the arithmetic          -> the gap in c is exactly 2*f*i, to floating point
##   D  forget gate at zero     -> the two histories land IDENTICALLY. The past is gone.
##   E  the band                -> from cleared, one admission cannot pass |h| = 1
##   F  memory passes it        -> accumulation can, which is what the band marks
##   G  it computes             -> the same history with different gates gives different h
##   I  the reach            -> gates and tokens answer pick_up, so a headset can grab them
##   H  the gate datum          -> measured in the artifact frame, not world, so the
##                                resting value no longer depends on the map's floor

const LSTM := "res://algorithms/machinelearning/LSTMs/LSTMs_VR.tscn"

var _fails: Array = []
var _finished: bool = false


func _initialize() -> void:
	await _run()
	if not _finished:
		_fails.append("the probe aborted before the last case — the checks after it never ran")
	if _fails.is_empty():
		print("\nprobe_lstm_recurrence: ALL 9 CASES PASS")
		quit(0)
	else:
		print("\nprobe_lstm_recurrence: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line: String = "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if ok:
		print("  ok    %s" % line)
	else:
		_fails.append(line)
		print("  FAIL  %s" % line)


func _make(recurrent: bool) -> Node3D:
	var n: Node3D = load(LSTM).instantiate()
	if recurrent:
		n.set_meta("config_recurrent", "on")
	root.add_child(n)
	return n


func _gates(n: Node3D, f: float, i: float, o: float) -> void:
	n.forget_gate_activation = f
	n.input_gate_activation = i
	n.output_gate_activation = o


func _run() -> void:
	print("probe_lstm_recurrence")

	# --- A: the default must not move ---
	var off := _make(false)
	await process_frame
	_check("A default off leaves recurrence inert", off.recurrent == false and off.cell_state == 0.0,
		"recurrent=%s c=%.3f" % [str(off.recurrent), off.cell_state])
	off.queue_free()

	var a := _make(true)
	await process_frame
	_check("A the map key turns it on", a.recurrent == true, str(a.recurrent))

	# --- B: the whole assignment, in one comparison ---
	# Both histories END IN THE SAME INPUT (-1). They differ only at step one.
	_gates(a, 0.5, 0.5, 0.5)
	var h_pale: float = a.run_history([1.0, -1.0], "pale then dark")
	var c_pale: float = a.cell_state
	var h_dark: float = a.run_history([-1.0, -1.0], "dark then dark")
	var c_dark: float = a.cell_state
	_check("B two histories, same last input, different output",
		absf(h_pale - h_dark) > 0.0001,
		"h = %+.4f after pale-dark, %+.4f after dark-dark" % [h_pale, h_dark])

	# --- C: and the gap is exactly the arithmetic, not a vibe ---
	var expected: float = 2.0 * 0.5 * 0.5
	_check("C the gap in c is exactly 2*f*i", absf((c_pale - c_dark) - expected) < 0.000001,
		"measured %.6f, 2*f*i = %.6f" % [c_pale - c_dark, expected])

	# --- D: the forget gate IS the coefficient on the past ---
	_gates(a, 0.0, 0.5, 0.5)
	var h0_pale: float = a.run_history([1.0, -1.0])
	var h0_dark: float = a.run_history([-1.0, -1.0])
	_check("D with forget at zero the two histories are identical",
		absf(h0_pale - h0_dark) < 0.000001,
		"h = %+.6f and %+.6f — the past cannot survive" % [h0_pale, h0_dark])

	# --- E: the band's claim, which the rail paints ---
	_gates(a, 1.0, 1.0, 1.0)
	a.recurrent_reset()
	a.recurrent_step(1.0)
	_check("E from cleared, one admission cannot pass |h| = 1",
		absf(a.hidden_out) <= a.MEMORY_ONLY + 0.000001 and not a.beyond_one_admission(),
		"strongest single step gives h = %+.4f" % a.hidden_out)

	# --- F: but carrying can ---
	a.recurrent_step(1.0)
	_check("F a carried past does pass it", a.beyond_one_admission(),
		"after a second same-sign token h = %+.4f" % a.hidden_out)

	# --- G: computation, not animation. Same history, different gates, different answer.
	_gates(a, 0.9, 0.5, 0.5)
	var h_hi: float = a.run_history([1.0, -1.0])
	_gates(a, 0.1, 0.5, 0.5)
	var h_lo: float = a.run_history([1.0, -1.0])
	_check("G the same history through different gates gives a different h",
		absf(h_hi - h_lo) > 0.0001,
		"forget 0.9 -> %+.4f, forget 0.1 -> %+.4f" % [h_hi, h_lo])

	# --- H: the datum fix. Move the whole artifact up; the resting gate must not care.
	var before_g: float = a._gate_value(a.forget_gate_body)
	a.position.y += 7.0
	await process_frame
	var after_g: float = a._gate_value(a.forget_gate_body)
	_check("H the gate value is floor-independent now",
		absf(before_g - after_g) < 0.000001,
		"%.4f at y=0, %.4f at y=7 — was world-referenced before" % [before_g, after_g])

	# --- I: without this the whole encounter is desktop-only ---
	var grabbable: int = 0
	for body in [a.forget_gate_body, a.input_gate_body, a.output_gate_body]:
		if is_instance_valid(body) and body.has_method("pick_up"):
			grabbable += 1
	var tok_ok: int = 0
	for t in a.input_tokens:
		if is_instance_valid(t) and t.has_method("pick_up"):
			tok_ok += 1
	_check("I all three gates answer pick_up, so XR Tools will grab them", grabbable == 3,
		"%d of 3" % grabbable)
	_check("I the tokens do too", tok_ok == a.input_tokens.size() and tok_ok > 0,
		"%d of %d" % [tok_ok, a.input_tokens.size()])

	a.queue_free()
	await process_frame
	_finished = true
