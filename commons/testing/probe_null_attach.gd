extends SceneTree
func _init() -> void:
	var f := FileAccess.open("res://ada_run/probe_null_attach.txt", FileAccess.WRITE)
	var pen: Node = (load("res://commons/primitives/point/draw_dot.tscn") as PackedScene).instantiate()
	var left: Node3D = null
	f.store_line("before add_child; pen valid=" + str(is_instance_valid(pen)))
	f.flush()
	left.add_child(pen)
	f.store_line("AFTER add_child — reached")
	f.flush()
	f.close()
	quit()
