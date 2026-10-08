extends SceneTree

var _lines: Array[String] = []

func _count(n: Node, out: Array) -> void:
	if n is XRController3D:
		out.append(str(n.name))
	for c in n.get_children():
		_count(c, out)

func _say(s: String) -> void:
	_lines.append(s)
	var f := FileAccess.open("res://ada_run/probe_zero_controllers.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines) + "\n")
		f.close()

func _init() -> void:
	for p in ["res://commons/scenes/grid_desktop.tscn",
			  "res://commons/scenes/grid.tscn",
			  "res://commons/maps/catalog/MapCatalogDesktop3D.tscn",
			  "res://commons/scenes/endless_museum.tscn"]:
		var ps := load(p) as PackedScene
		if ps == null:
			_say(p + " -> LOAD FAILED")
			continue
		var inst: Node = ps.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		var found: Array = []
		_count(inst, found)
		_say("%s -> %d XRController3D %s" % [p, found.size(), str(found)])
		inst.free()
	var pen: Node = (load("res://commons/primitives/point/draw_dot.tscn") as PackedScene).instantiate()
	_say("pen instantiated: " + str(pen != null) + "  children=" + str(pen.get_child_count()))
	var left: Node3D = null
	_say("about to call add_child on a null XRController3D...")
	left.add_child(pen)
	_say("REACHED THE LINE AFTER add_child — execution continued")
	pen.free()
	quit()
