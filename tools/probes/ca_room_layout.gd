extends "res://tools/probes/transformation_encounters.gd"
## Spatial review cameras only. No saved map edits or teaching-state changes.
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(.7).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false); stream.set_physics_process(false)
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide(); walker.set_process(false); walker.set_physics_process(false)
		walker.global_position=Vector3(0,-100,0)
	var previous = museum.get("_cam")
	if previous is Node3D: previous.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe= museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")): wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child != hall: child.hide()
	var inventory: Array = []
	var seen: Dictionary = {}
	for item in hall.find_children("*","Node3D",true,false):
		if not item.has_meta("artifact_lookup_name"): continue
		var key: String = str(item.get_meta("artifact_lookup_name"))
		if seen.has(key): continue
		seen[key]=true
		item.show()
		item.process_mode=Node.PROCESS_MODE_INHERIT
		inventory.append({"key":key,"hall_position":xyz(hall.to_local(item.global_position)),"world":xyz(item.global_position),"node":str(item.get_path())})
	var work := find_scene("/ca_rule_explorer.gd")
	if work != null:
		work.auto_run=false; work.rule=90; work._reset()
		for i in 16: work.step()
		work.get_node("NeighbourStudy").refresh()
	await create_timer(.5).timeout
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=29
	camera.global_position=hall.to_global(Vector3(7.5,31,12))
	camera.look_at(hall.to_global(Vector3(7.5,0,12)),Vector3.FORWARD)
	camera.current=true
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	check("Overhead camera remains active",root.get_camera_3d()==camera)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	for item in inventory:
		var p: Array = item.world
		var screen:=camera.unproject_position(Vector3(p[0],p[1],p[2]))
		item["top_pixel"]=[screen.x,screen.y]
	observations["inventory"]=inventory
	observations["hall_origin"]=xyz(hall.global_position)
	observations["top_camera"]={"hall_local":[7.5,31,12],"size":29,"entry_at":"top; negative Z","pixels":[root.size.x,root.size.y]}
	camera.size=31
	await snapshot("raised-oblique",hall.to_global(Vector3(19,36,34)),hall.to_global(Vector3(7,0,12)),55)
	check("Explorer present with its current shared receiver",work!=null and work.get_node("NeighbourStudy").room_ring!=null)
	observations["scope"]="Current installed hall from above and a raised oblique viewpoint, using its existing environment. Neighbouring halls and player hidden for capture only. No map arrangement or production logic changed."
