extends SceneTree
## Headless functional test of the canonical slider (slider_smooth) as mounted by
## ControlPanel.add_slider. Verifies the value math round-trips and — the part that
## had a real bug — that the grabbed handle can move in BOTH directions (the
## one-way clamp fix in slider_smooth._enforce_handle_constraints).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_sliders.gd
## Exit code 0 = all pass, 1 = a failure.

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

var _pass := 0
var _fail := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, cond: bool) -> void:
	if cond:
		_pass += 1
		print("  PASS  ", name)
	else:
		_fail += 1
		print("  FAIL  ", name)


func _approx(a: float, b: float, eps := 0.02) -> bool:
	return absf(a - b) <= eps


func _run() -> void:
	var board := ControlPanelScript.new()
	get_root().add_child(board)
	var s: Node = board.add_slider("TEST", "TEST")
	await process_frame
	await create_timer(0.35).timeout
	await process_frame

	_check("add_slider returned a node", s != null)
	_check("has set_normalized_value", s != null and s.has_method("set_normalized_value"))
	_check("has get_normalized_value", s != null and s.has_method("get_normalized_value"))

	# 1. Value round-trip across the whole range (both ends + middle).
	print("[slider-test] value round-trip (set -> get):")
	for v in [0.0, 0.25, 0.5, 0.75, 1.0]:
		s.call("set_normalized_value", v)
		var g: float = float(s.call("get_normalized_value"))
		_check("set %.2f -> get %.3f" % [v, g], _approx(g, v))

	# 2. Bidirectional handle clamp — the one-way bug fix. At mid-position the
	#    grabbed handle's legal local-x range is [min-pos, max-pos], i.e. it must
	#    be allowed to go NEGATIVE (toward min). The old bug clamped to [0,max].
	print("[slider-test] bidirectional handle clamp (the one-way fix):")
	s.call("set_normalized_value", 0.5)
	await process_frame
	var handle: Node3D = s.get_node_or_null("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle")
	_check("handle node found", handle != null)
	if handle and s.has_method("_enforce_handle_constraints"):
		# toward MIN
		handle.transform.origin = Vector3(-0.04, 0.0, 0.0)
		s.call("_enforce_handle_constraints", 0.016, false)
		var hx_min: float = handle.transform.origin.x
		_check("handle moves toward MIN (x<0 allowed) — x=%.3f" % hx_min, hx_min < -0.001)
		# toward MAX
		handle.transform.origin = Vector3(0.04, 0.0, 0.0)
		s.call("_enforce_handle_constraints", 0.016, false)
		var hx_max: float = handle.transform.origin.x
		_check("handle moves toward MAX (x>0 allowed) — x=%.3f" % hx_max, hx_max > 0.001)
	else:
		_check("_enforce_handle_constraints present", false)

	# 3. The physics control must NOT be scaled (the sticky-grab bug).
	print("[slider-test] physics control scale:")
	_check("slider scale == 1 (never scale a RigidBody control)", s is Node3D and (s as Node3D).scale.is_equal_approx(Vector3.ONE))

	print("[slider-test] DONE — %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
