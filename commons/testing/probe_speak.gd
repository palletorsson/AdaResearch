extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var lines: Array = m.call("_speak_lines", "primitives", "point")
	print("SPEAK lines: %d — %s" % [lines.size(), str(lines.slice(0, 4))])
	var an: Dictionary = m.call("_speak_anchors")
	print("SPEAK anchors: %s" % str(an))
	var it: Node = m.find_child("FoyerIntro", true, false)
	print("FOYER intro: %s" % ((it as Label3D).text.left(80).replace("\n", " / ") if it != null else "none"))
	var n: int = 0
	for c in m.find_children("Speak*", "Label3D", true, false):
		n += 1
		print("SPEAK node %s at %s: %s" % [c.name, (c as Node3D).global_position, (c as Label3D).text.left(40).replace("\n", " / ")])
	print("SPEAK nodes: %d" % n)
	quit(0)
