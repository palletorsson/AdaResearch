extends SceneTree
func _initialize() -> void:
	var light := DirectionalLight3D.new()
	for p in light.get_property_list():
		if "mask" in str(p.name):print(p.name)
	light.free()
	quit()
