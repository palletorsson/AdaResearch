extends SceneTree
func _initialize() -> void:
	var scene=load("res://algorithms/randomness/proceduralrandomness/movementbased/scenes/randombutterflies/butterfly.tscn").instantiate()
	for name in ["pngegg_rightwing","pngegg_leftwing"]:
		var mesh: Mesh=scene.find_child(name,true,false).mesh
		var a:=mesh.surface_get_arrays(0)
		print(name," vertices ",a[Mesh.ARRAY_VERTEX]," UV ",a[Mesh.ARRAY_TEX_UV]," normals ",a[Mesh.ARRAY_NORMAL])
	scene.free();quit()
