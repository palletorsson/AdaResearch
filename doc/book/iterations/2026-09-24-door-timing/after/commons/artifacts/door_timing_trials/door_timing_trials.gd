extends Node3D
## Same walking construction, three times at which its draw becomes available.
const Trial = preload("res://commons/artifacts/door_timing_trials/door_timing_trial.gd")
var trials: Array[Node3D] = []
func _ready() -> void:
	for i in range(3):
		var trial := Trial.new()
		trial.name = ["ShownFirst","DrawnAfter","HiddenFirst"][i]
		trial.schedule = i
		trial.run_seed = 39017+i*101
		trial.position.x = (1-i)*5.0
		add_child(trial);trials.append(trial)
func get_state() -> Dictionary:
	var states: Array = []
	for trial in trials: states.append(trial.get_state())
	return {"trials":states,"spacing":5.0,"scope":"Matched geometry and draw law; different private seeds, independent replay controls."}
