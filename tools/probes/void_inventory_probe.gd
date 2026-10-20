extends SceneTree
const Architecture = preload("res://commons/void/architecture.gd")
var records: Array = []
var bounds: Array = []
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var building := Architecture.new()
	building.stream_content = true
	root.add_child(building)
	for index in range(building.spec.levels.size()):
		var floor_root: Node3D = building.content.load_floor(index)
		for i in range(30): await physics_frame
		walk(floor_root, index)
		for item in building.content.data.floors[index].artifacts:
			var mount: Node3D = building.content.exhibits["%d/%s"%[index,item.id]]
			var box := mesh_bounds(mount, mount)
			bounds.append({"floor":index,"id":item.id,"bounds":[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]})
	FileAccess.open("res://inventory.json", FileAccess.WRITE).store_string(JSON.stringify(records,"\t"))
	FileAccess.open("res://inventory-bounds.json", FileAccess.WRITE).store_string(JSON.stringify(bounds,"\t"))
	building.queue_free()
	for i in range(10): await process_frame
	quit()
func mesh_bounds(origin: Node3D, node: Node) -> AABB:
	var result := AABB()
	if node is SubViewport: return result
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		result = (origin.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
	for child in node.get_children():
		var box := mesh_bounds(origin,child)
		if box.size.length()>0: result = box if result.size.length()==0 else result.merge(box)
	return result
func walk(node: Node, index: int) -> void:
	var path := node.scene_file_path
	if path.is_empty(): path = str(node.get_meta("void_source", ""))
	var script: String = node.get_script().resource_path if node.get_script() != null else ""
	if not path.is_empty() or (script.begins_with("res://commons/") and not script.begins_with("res://commons/void/")):
		var config := {}
		for key in node.get_meta_list():
			if str(key).begins_with("config_"): config[str(key).trim_prefix("config_")] = node.get_meta(key)
		records.append({"floor":index,"node":str(node.get_path()),"scene":path,"script":script,"config":config})
	for child in node.get_children(): walk(child,index)
