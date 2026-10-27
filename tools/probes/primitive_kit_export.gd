extends "res://tools/probes/export_void_editor.gd"
## Refresh only the changed assemblies and new palette members. Never rewrite rooms.
func run() -> void:
	var receipt_out := out
	out="C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/void-models"
	public_base="/void-models"
	manifest=JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var rooms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/catalog.json"))
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/layout.json"))
	var defaults: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/line_parts.json"))
	var host := Node3D.new();root.add_child(host);current_scene=host
	var updates: Array=[]
	for target in [[3,"assembly"],[4,"release"],[5,"assembly"],[6,"obstruction"],[12,"hall"]]:
		var index: int=target[0]
		var record: Dictionary={}
		for item in rooms.floors[index].artifacts:
			if item.id==target[1]:record=item;break
		assert(not record.is_empty(),"Missing expected source assembly")
		var node: Node3D=load(catalog.artifacts[record.artifact].scene).instantiate()
		node.position=Vector3(record.position[0],layout.levels[index]+float(record.get("height",0)),record.position[1])
		node.rotation_degrees.y=float(record.get("facing",0));node.scale=Vector3.ONE*float(record.get("scale",1));host.add_child(node)
		if node.has_method("apply_grid_config"):node.apply_grid_config(record.get("config",{}))
		for i in 20:await physics_frame
		await RenderingServer.frame_post_draw
		node.process_mode=Node.PROCESS_MODE_DISABLED
		var model: Dictionary={"artifact":record.artifact,"config":record.get("config",{}).duplicate(true),"parts":{}}
		for key in node.part_defaults:
			var part: Node3D=node.get_node(NodePath(key))
			var exported := snapshot(part,"kit-%d-%s-%s"%[index,record.id,key])
			exported.default=node.part_defaults[key];exported.scale=[part.scale.x,part.scale.y,part.scale.z]
			model.parts[key]=exported
		manifest.floors[str(index)].artifacts[record.id]=model
		defaults[record.artifact]=node.part_defaults.duplicate(true)
		updates.append({"floor":index,"id":record.id,"parts":model.parts.size()})
		node.queue_free();await process_frame
	for kind in catalog.props:
		if catalog.props[kind].get("group","")!="Primitives kit":continue
		var dressing=load("res://commons/void/set_dressing.gd")
		var node: Node3D=dressing.build(host,host,{"id":kind,"kind":kind,"position":[0,0],"facing":0,"scale":1},catalog.props[kind])
		await process_frame
		manifest.props[kind]=snapshot(node,"kit-prop-"+str(kind))
		manifest.props[kind].thumbnail=await thumbnail(node,"kit-prop-"+str(kind))
		node.queue_free();await process_frame
	manifest.revision="primitives-kit-"+str(Time.get_unix_time_from_system())
	manifest.notes.append("Primitives kit: targeted real-scene refresh of Lines assembly, Trace release, Triangle assembly, Polyhedra obstruction and Melencolia; saved rooms preserved.")
	assert(failures.is_empty(),str(failures))
	FileAccess.open("res://commons/void/line_parts.json",FileAccess.WRITE).store_string(JSON.stringify(defaults,"  ")+"\n")
	FileAccess.open(out.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ")+"\n")
	FileAccess.open(receipt_out.path_join("export-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"updates":updates,"failures":failures,"scope":"Targeted real geometry refresh; no saved rooms changed."},"  "))
	print("PRIMITIVE_KIT_EXPORT ",updates)
	quit(0)
