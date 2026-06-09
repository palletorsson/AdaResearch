extends SceneTree
func _initialize() -> void:
	var scn = load("res://commons/grid/GridEditorDesktop3D.tscn").instantiate()
	get_root().add_child(scn)
