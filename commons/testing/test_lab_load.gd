extends SceneTree

## Verify the Point One lab JSON loads every prop through the real
## LabLoader path (registry index -> scene -> instantiate). Run:
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_lab_load.gd

const LAB := "res://commons/labs/point_one.lab.json"
const LOADER := "res://commons/artifacts/lab_room/lab_loader.gd"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var loader_script: GDScript = load(LOADER)
	if loader_script == null:
		print("[lab-test] FAIL: cannot load lab_loader")
		quit(1)
		return

	var host := Node3D.new()
	get_root().add_child(host)

	# LabLoader.load_into is static — call through the script.
	var nodes: Array = loader_script.call("load_into", host, ProjectSettings.globalize_path(LAB) if false else LAB)

	# Settle so each prop's _ready/_build fires.
	for i in range(20):
		await get_root().get_tree().process_frame

	print("[lab-test] props instantiated: %d" % nodes.size())
	for n in nodes:
		if is_instance_valid(n):
			print("[lab-test]   OK  %s (children=%d)" % [n.name, n.get_child_count()])
		else:
			print("[lab-test]   FREED  (a prop was freed during load)")

	print("[lab-test] DONE")
	quit(0)
