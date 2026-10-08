extends SceneTree
## Headless functional test of the canonical slider (slider_smooth) as mounted by
## ControlPanel.add_slider. Verifies the value math round-trips and — the part that
## had a real bug — that the grabbed handle can move in BOTH directions (the
## constrained local joint and free hand now share the same movement).
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_sliders.gd
## Exit code 0 = all pass, 1 = a failure.

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

var _pass := 0
var _fail := 0


class TestGrabber extends Node3D:
	var picked_up_ranged := false
	var held: Node3D
	func drop_object() -> void:
		if is_instance_valid(held): held.let_go(self,Vector3.ZERO,Vector3.ZERO)
		held=null

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

	# 2. Real pickup, in both directions, in the canonical mounted panel.
	s.set_normalized_value(.5)
	var joint:Node3D=s.get_node("SliderOrigin/InteractableSlider")
	var handle:Node3D=joint.get_node("HandleOrigin/InteractableHandle")
	var hand:=TestGrabber.new();root.add_child(hand)
	hand.global_transform=handle.global_transform;hand.held=handle;handle.pick_up(hand)
	var rest:Vector3=joint.to_local(handle.handle_origin.global_position)
	for fraction in [.2,.8]:
		var target:float=lerpf(joint.slider_limit_min,joint.slider_limit_max,fraction)
		hand.global_position=joint.get_parent().to_global(rest+Vector3.RIGHT*target)
		for i in 8:await process_frame;await physics_frame
		_check("Native grab reaches %.1f in mounted mixer" % fraction,_approx(s.get_normalized_value(),fraction))
	hand.drop_object();hand.queue_free()
	_check("Driver idles when released",not joint.is_processing())

	# 3. The physics control must NOT be scaled (the sticky-grab bug).
	print("[slider-test] physics control scale:")
	_check("slider scale == 1 (never scale a RigidBody control)", s is Node3D and (s as Node3D).scale.is_equal_approx(Vector3.ONE))

	print("[slider-test] DONE — %d passed, %d failed" % [_pass, _fail])
	quit(1 if _fail > 0 else 0)
