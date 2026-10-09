extends SceneTree
## Method-level handler probe. No headset or pointer dispatch is simulated.

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var results: Array = []
	for component in ["RackSliderH", "RackSliderV", "RackSliderStepped", "RackSliderBipolar"]:
		var script_path := "res://commons/audio/rack_controls/%s.gd" % component
		var component_script = load(script_path)
		if component_script == null:
			results.append({"component": component, "error": "script load failed"})
			continue
		var control = component_script.new()
		root.add_child(control)
		control.size = Vector2(100.0, 200.0)
		control.set_normalized_value(0.1)
		var before: float = control.get_normalized_value()
		control._on_pointer_pressed(Vector2(50.0, 50.0))
		control._on_pointer_dragged(Vector2(75.0, 20.0))
		var after: float = control.get_normalized_value()
		results.append({"component": component, "before": before, "after": after,
			"handler_changed_value": not is_equal_approx(before, after)})
		control.queue_free()
	var output := FileAccess.open("res://doc/reports/interfaces-2026-09-20/rack-handler-probe.json", FileAccess.WRITE)
	output.store_string(JSON.stringify({"method": "Direct calls to press and drag handlers; no actual GUI event, 3D hit, or headset input", "results": results}, "\t"))
	output.close()
	quit()
