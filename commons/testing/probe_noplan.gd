extends SceneTree
## What happens when the scene is run with NO command line — as pressing Play
## in the Godot editor does.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)          # no _plan_path set: exactly the editor's Play
	await create_timer(2.5).timeout
	print("[probe] plan_path=%s  plan rows=%d  chapter=%s" % [
		str(m.get("_plan_path")), (m.get("_plan_by_chapter") as Dictionary).size(),
		str(m.get("_first_chapter"))])
	quit(0)
