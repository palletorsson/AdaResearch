extends "res://commons/artifacts/concept_monitor/concept_monitor.gd"
## The existing gaze-controlled feed, with a separate row for trying its model.
var experiment_labels: Dictionary = {}
var _trying := false

func _ready() -> void:
	super._ready()
	if not stage.has_method("experiment_controls"): return
	box("ExperimentControls", Vector3(2.15, .22, .16), Vector3(0, .54, .10), Color("d9d6d0"))
	var controls: Array = stage.call("experiment_controls")
	for i in range(controls.size()):
		var item: Dictionary = controls[i]
		var key := "try_" + str(item.key)
		var label := add_button(key, Vector3((i - (controls.size()-1)*.5)*.52, .55, .21))
		label.font_size = 27
		experiment_labels[key] = label
	_refresh_labels()

func activate(key: String) -> void:
	if key.begins_with("try_"):
		stage.call("experiment_action", key.trim_prefix("try_"))
		stage.set("running", false)
		_trying = true
		pause_label.text = "DEMO"
		_refresh_labels()
		refresh_once()
		return
	if _trying and key in ["pause", "replay", "step"]:
		stage.call("replay")
		_trying = false
		if key == "step": stage.call("step_sample")
		pause_label.text = "PAUSE" if bool(stage.get("running")) else "PLAY"
		refresh_once()
	else:
		super.activate(key)
	_refresh_labels()

func _refresh_labels() -> void:
	if _trying: pause_label.text = "DEMO"
	for item: Dictionary in stage.call("experiment_controls"):
		var key := "try_" + str(item.key)
		if experiment_labels.has(key):
			var label: Label3D = experiment_labels[key]
			label.text = str(item.label)
			label.font_size = 38 if label.text.length() <= 7 else (31 if label.text.length() <= 10 else 27)
