extends "res://tools/probes/export_void_editor.gd"
func run() -> void:
	var receipt := out
	out="C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/void-models"
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var catalogue: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/primitive-prefabs.json"))
	var definition: Dictionary=catalogue.prefabs.filter(func(p):return p.id=="matter_and")[0]
	var host := Node3D.new();root.add_child(host);current_scene=host
	var node: Node3D=load(str(definition.scene)).instantiate();node.position.y=-42;host.add_child(node)
	node.apply_grid_config(definition.placement.config)
	for i in 10:await physics_frame
	await RenderingServer.frame_post_draw
	node.process_mode=Node.PROCESS_MODE_DISABLED
	var model: Dictionary={"artifact":definition.id,"config":definition.placement.config,"parts":{}}
	for key in node.part_defaults:
		var part: Node3D=node.get_node(NodePath(key))
		var exported := snapshot(part,"matter-cube-7-"+str(key))
		exported.default=node.part_defaults[key];exported.scale=[part.scale.x,part.scale.y,part.scale.z]
		model.parts[key]=exported
	manifest.floors["7"].artifacts["matter-and"]=model
	manifest.revision="matter-cube-"+str(Time.get_unix_time_from_system())
	assert(failures.is_empty(),str(failures))
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ")+"\n")
	# The Python runner merges this one definition atomically; the live editor
	# may have the shared catalogue open while native export is running.
	FileAccess.open(receipt.path_join("part-defaults.json"),FileAccess.WRITE).store_string(JSON.stringify(node.part_defaults,"  ")+"\n")
	FileAccess.open(receipt.path_join("export-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"parts":model.parts.size(),"source":definition.scene,"floor":7,"scope":"Actual source geometry; individual named parts, no room rewrite."},"  "))
	print("MATTER_CUBE_EXPORT ",model.parts.size());quit(0)
