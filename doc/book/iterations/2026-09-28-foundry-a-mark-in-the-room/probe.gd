extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var study:Node3D
var studio:Node3D
var room:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
func press(button:Node3D) -> void:
	var area=button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.12).timeout
func pixels(mesh:MeshInstance3D) -> PackedByteArray:
	var mat=mesh.material_override
	var tex:Texture2D=mat.get_shader_parameter("domain_texture") if mat is ShaderMaterial else mat.albedo_texture
	return tex.get_image().get_data() if tex else PackedByteArray()
func sample_photo(title:String) -> void:
	await snapshot(title,study.to_global(Vector3(-3.1,1.65,-0.65)),study.to_global(Vector3(-3.1,1.35,1.2)),76)
func room_photo(title:String) -> void:
	await snapshot(title,room.to_global(Vector3(1.6,1.65,2.2)),room.to_global(Vector3(-0.5,1.0,-2.4)),88)
func floor_photo(title:String) -> PackedByteArray:
	await snapshot(title,room.to_global(Vector3(2.2,1.65,0.9)),room.to_global(Vector3(2.2,0.04,0.3)),50)
	return root.get_texture().get_image().get_region(Rect2i(320,300,800,540)).get_data()
func different_bytes(a:PackedByteArray,b:PackedByteArray) -> int:
	var changed:=0
	for i in mini(a.size(),b.size()):
		if a[i]!=b[i]:changed+=1
	return changed
func walk(p:Vector3,label:String) -> void:
	driver.target=room.to_global(p);driver.arrived=false;driver.moving=true
	var start=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<8000:await physics_frame
	driver.moving=false;driver.release();check(label,driver.arrived)
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid=hall.get_node_or_null("SimGrid_Pattern_Foundry")
	for frame in 3600:
		if grid and grid.has_meta("stage_grid_ready"):break
		await process_frame
	study=find_scene("/recipe_study.gd");studio=find_scene("/pattern_studio_console.gd")
	var architecture=find_scene("/pattern_architecture.gd")
	check("loom study studio and architecture are placed",study!=null and studio!=null and architecture!=null)
	if study==null or studio==null:return
	for i in 240:
		room=studio.surface_controls.room
		if room:break
		await process_frame
	check("curved room is built",room!=null)
	if room==null:return
	var loom=study.loom
	check("loom starts with a five-cell translation card",loom.group=="p1" and loom.card_size==5)
	var geometry=study.flat.transform;var curve_geometry=study.curved.transform
	var initial=pixels(study.flat)
	check("flat and curved sheets begin with the same image",initial==pixels(study.curved))
	check("curved sheet retains the flat sheet UV addresses",study.flat.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]==study.curved.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV])
	await sample_photo("samples-before")
	var old_wall=pixels(study.wall)
	await press(study.buttons[0])
	check("pointer mark changes both live samples",pixels(study.flat)!=initial and pixels(study.flat)==pixels(study.curved))
	check("same mark also changes the registered low wall",pixels(study.wall)!=old_wall)
	await sample_photo("samples-marked")
	while study.TARGETS[study.target_index]!="CURVE":await press(study.buttons[4])
	await press(study.buttons[3]);var held=pixels(study.curved)
	await press(study.buttons[0])
	check("held curve keeps the older mark while flat follows",pixels(study.curved)==held and pixels(study.flat)!=held)
	await sample_photo("curve-keeps-a-mark")
	check("edits and hold preserve both sample transforms",study.flat.transform==geometry and study.curved.transform==curve_geometry)
	await press(study.buttons[3])
	check("relinked curve catches up",pixels(study.flat)==pixels(study.curved))
	check("whole-hall controller reads the loom carpet output",architecture.source_texture()==loom._carpet_mat.albedo_texture)
	var skins_have_no_collision=architecture.skins.size()==2
	for skin in architecture.skins:
		skins_have_no_collision=skins_have_no_collision and skin.find_children("*","CollisionShape3D",true,false).is_empty() and not skin.get_parent() is CollisionObject3D
	check("hall pattern skins add no collision",skins_have_no_collision)
	var adapter=studio.surface_controls
	check("room starts live with the studio as source",study.receivers["ROOM WALL"].linked and study.receivers["ROOM FLOOR"].linked and study.receivers["ROOM WALL"].source.get_ref()==studio and study.receivers["ROOM FLOOR"].source.get_ref()==studio)
	check("ROOM initially selected on its surface console",adapter.targets[adapter.target_index]=="ROOM")
	var hall_floor:MeshInstance3D=architecture.skins[0]
	var skin_vertex:Vector3=hall_floor.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
	var skin_height=hall.to_local(hall_floor.to_global(skin_vertex)).y
	check("hall floor skin stays on grid despite raised console",absf(skin_height-0.026)<0.001)
	observations["hall_floor_skin_height"]=skin_height
	observations["room_floor_visible"]=room.floor_mesh.is_visible_in_tree()
	observations["room_floor_global"]=xyz(room.floor_mesh.global_position)
	observations["architecture_global"]=xyz(architecture.global_position)
	observations["room_floor_shader"]=room.floor_mesh.material_override.shader.code.substr(0,300)
	observations["room_floor_aabb"]=str(room.floor_mesh.get_aabb())
	var point=room.to_global(Vector3(2.2,0,0.3))
	var cover=[]
	for mesh in hall.find_children("*","MeshInstance3D",true,false):
		var bounds:AABB=mesh.global_transform*mesh.get_aabb()
		if bounds.position.x<=point.x and bounds.end.x>=point.x and bounds.position.z<=point.z and bounds.end.z>=point.z and bounds.position.y<0.5 and bounds.end.y>-0.01:
			cover.append({"name":str(mesh.get_path()),"bounds":str(bounds),"visible":mesh.is_visible_in_tree()})
	observations["covering_meshes"]=cover
	var original_room=pixels(room.wall)
	check("room domain texture is available",not original_room.is_empty())
	await room_photo("room-before")
	var ground_before=await floor_photo("floor-before")
	var selected=(studio.model.get_cell(0,0)+1)%studio.model.palette.size()
	await press(studio.controls["paint_%d"%selected]);await press(studio.cell_buttons[0])
	check("one painted source cell reaches wall and floor",pixels(room.wall)!=original_room and pixels(room.wall)==pixels(room.floor_mesh))
	await room_photo("room-one-mark")
	var ground_first=await floor_photo("floor-one-mark")
	var ground_change=different_bytes(ground_before,ground_first)
	check("source edit changes the visible floor pixels",ground_change>10000)
	observations["visible_floor_changed_bytes"]=ground_change
	while adapter.targets[adapter.target_index]!="ROOM FLOOR":await press(adapter.buttons["NEXT"])
	await press(adapter.buttons["HOLD"])
	var old_ground=pixels(room.floor_mesh);var wall_transform=room.wall.global_transform
	var floor_transform=room.floor_mesh.global_transform;var supports=room.find_children("WallSupport_*","StaticBody3D",true,false)
	selected=(studio.model.get_cell(0,0)+1)%studio.model.palette.size()
	await press(studio.controls["paint_%d"%selected]);await press(studio.cell_buttons[0])
	check("held floor stays while the room wall follows",pixels(room.floor_mesh)==old_ground and pixels(room.wall)!=old_ground)
	check("room keeps its physical wall and floor geometry",room.wall.global_transform==wall_transform and room.floor_mesh.global_transform==floor_transform and supports.size()==80)
	await room_photo("room-two-moments")
	var ground_held=await floor_photo("floor-held")
	var ground_stays=different_bytes(ground_first,ground_held)
	check("held floor retains its visible pixels after source edit",ground_stays<100)
	observations["held_floor_changed_bytes"]=ground_stays
	actor=museum.get("_player");museum.set("_dollhouse",false)
	actor.global_position=room.to_global(Vector3(1.6,0.08,4.4));actor.velocity=Vector3.ZERO
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	await walk(Vector3(1.6,0.06,2.2),"ordinary body enters the patterned room")
	await walk(Vector3(2.7,0.06,1.3),"ordinary body moves sideways inside")
	await walk(Vector3(1.6,0.06,2.2),"ordinary body returns to its approach")
	await walk(Vector3(1.6,0.06,4.4),"ordinary body leaves through the same opening")
	check("walking does not relink the held floor",not study.receivers["ROOM FLOOR"].linked and pixels(room.floor_mesh)==old_ground)
	await press(adapter.buttons["APPLY LIVE"])
	check("APPLY LIVE catches the floor up to its wall",pixels(room.wall)==pixels(room.floor_mesh) and study.receivers["ROOM FLOOR"].linked)
	await press(adapter.buttons["UNDO LINK"])
	check("UNDO LINK restores the held floor image",not study.receivers["ROOM FLOOR"].linked and pixels(room.floor_mesh)==old_ground)
	observations["room_start"]=xyz(room.global_position);observations["source_count"]=architecture.sources.size();completed=true
func finish() -> void:
	if driver:driver.release();driver.set_physics_process(false)
	check("Foundry encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Real museum, pointer callbacks at source/receiver controls, material-domain comparisons and ordinary-controller entry/return. No saved recipes written. Standing-height native images. Headset comfort and learner reading remain untested."},"  "))
	print("FOUNDRY RETURN ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
