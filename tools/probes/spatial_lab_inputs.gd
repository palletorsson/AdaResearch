extends "res://tools/probes/movable_pivot_probe.gd"
const Inputs = preload("res://commons/modular/lab_input.gd")
const Grammar = preload("res://commons/modular/builder.gd")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	host=Node3D.new();root.add_child(host);current_scene=host
	var models: Dictionary={}
	for token in Inputs.sources():
		var source: Node3D=Grammar.build({"p":"prefab","token":token,"lab_input":true},{})
		host.add_child(source);await ticks(2)
		var box: AABB=Inputs.bounds(source,source)
		check(token+" / original scene and bottom anchor",source.original!=null and source.original.scene_file_path==Inputs.sources()[token].scene and absf(box.position.y)<.0001 and box.size.length()>.001)
		var model: Dictionary=snapshot(source,"source-"+token)
		model["bounds"]=[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]
		model["scene"]=source.source_scene
		models[token]=model
		# Same recipe, same parameters, different input; all sources must produce
		# ten independent copies and retain the original dimensions at 0.3 scale.
		for recipe in ["lab_packed","lab_radial","lab_growing"]:
			var study: Node3D=load("res://commons/modular/recipe_area.tscn").instantiate()
			study.apply_grid_config({"recipe":recipe,"bindings":{"source":token}});host.add_child(study)
			var first: Node3D=study.get_node("Copy01")
			check(token+" / "+recipe+" accepts input",study.part_defaults.size()==(12 if recipe=="lab_growing" else 11) and first.get_node("Source").source_scene==source.source_scene)
			study.free()
		source.free()
	var passed: bool=checks.all(func(c):return c.passed) and failures.is_empty()
	FileAccess.open(out.path_join("inputs.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"models":models,"failures":failures},"  "))
	print("SPATIAL_INPUTS_DONE")
	host.free();quit(0 if passed else 1)
