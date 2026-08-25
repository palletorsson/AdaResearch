extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var l: Node = m.find_child("FoyerIntro", true, false)
	if l == null: print("INTRO: none"); quit(0); return
	var t: String = (l as Label3D).text
	print("INTRO lines=%d nbsp=%d autowrap=%d text=%s" % [t.split("\n").size(), t.count("\u00a0"), (l as Label3D).autowrap_mode, t.replace("\n", "|").left(160)])
	quit(0)
