extends SceneTree

func _init():
	var path = "res://algorithms/array/grid_2d_4x4.gd"
	var uid = ResourceLoader.get_resource_uid(path)
	var uid_text = ResourceUID.id_to_text(uid)
	print("UID for %s is %s" % [path, uid_text])
	quit()
