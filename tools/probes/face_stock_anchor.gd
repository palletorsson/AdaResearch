extends "res://tools/probes/sine_yoke.gd"
## Stock belongs to the actual editable support, even when moved separately.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	scene=Node3D.new();root.add_child(scene);current_scene=scene
	for path in ["res://commons/artifacts/primitive_encounters/triangle_assembly_table.tscn","res://commons/artifacts/face_assembly/square_assembly.tscn"]:
		var table:Node3D=load(path).instantiate();table.position=Vector3(0,-30,0);scene.add_child(table);await tick(3)
		table.apply_grid_config({"parts":{"Support":{"position":[1,.4,-.2],"rotation":[0,31,0]}}});await tick(3)
		table.buttons.stock.pressed.emit();await tick(5)
		var follows:bool=table.pieces.size()==18
		for p in table.pieces:
			if not p.get_meta("assembly_stock",false):continue
			var local_pose:Transform3D=table.support.global_transform.affine_inverse()*p.global_transform
			follows=follows and local_pose.basis.is_equal_approx(Basis.IDENTITY) and local_pose.origin.y>=.844 and local_pose.origin.y<1.7
		check("%d-sided stock follows separately moved and turned support"%table.sides,follows)
		var held:Node3D=table.pieces[12];held.on_desktop_grab(table)
		var before:int=table.pieces.size();table.reset()
		check("%d-sided reset leaves a held stock face intact"%table.sides,table.pieces.size()==before and is_instance_valid(held))
		held.on_desktop_drop(table);await tick(3);table.reset();await tick(3)
		check("%d-sided reset removes live stock after release"%table.sides,table.pieces.size()==12)
		table.free();await tick(3)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Focused native test of stock frame after independent editor support moves, and held-stock reset safety."},"\t"))
	print("FACE_ASSEMBLY_RESULT ",failed.size());quit(0 if failed.is_empty() else 1)
