extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var ui:Node3D
var station:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
func press(id:String) -> void:
	var area:Area3D=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.08).timeout
func field_photo(title:String) -> PackedByteArray:
	await snapshot(title,ui.to_global(Vector3(0,1.65,4.8)),ui.to_global(Vector3(0,1.3,-0.15)),65)
	# Sample only the two fixed prints; the middle status label must change.
	var frame=root.get_texture().get_image()
	var result=frame.get_region(Rect2i(325,355,215,220)).get_data()
	result.append_array(frame.get_region(Rect2i(906,355,215,220)).get_data())
	return result
func floor_photo(title:String) -> PackedByteArray:
	await snapshot(title,ui.to_global(Vector3(1.25,1.65,1.3)),ui.to_global(Vector3(1.25,0.005,0.1)),44)
	return root.get_texture().get_image().get_region(Rect2i(460,360,520,400)).get_data()
func difference(a:PackedByteArray,b:PackedByteArray) -> int:
	var result:=0
	for i in mini(a.size(),b.size()):
		if a[i]!=b[i]:result+=1
	return result
func travel(p:Vector3,title:String) -> void:
	driver.target=ui.to_global(p);driver.arrived=false;driver.moving=true
	var start=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<8000:await physics_frame
	driver.moving=false;driver.release();check(title,driver.arrived)
	observations[title]=xyz(ui.to_local(actor.global_position))
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid=hall.get_node_or_null("SimGrid_Tutorial_Pattern")
	for i in 3600:
		if grid and grid.has_meta("stage_grid_ready"):break
		await process_frame
	ui=find_scene("/fixed_motif_lesson.gd")
	check("fixed motif lesson is placed",ui!=null)
	if ui==null:return
	station=ui.station
	check("source has sixteen cells and eight paints",ui.cells.size()==16 and ui.buttons.size()==30)
	check("source buttons read top row first",ui.cells[0].global_position.y>ui.cells[4].global_position.y)
	check("legacy touch editor remains inactive",not station.is_processing() and not station._panel_root.visible)
	var initial=station._grid_data.duplicate(true)
	var bytes=station._domain_texture.get_image().get_data()
	var left:ShaderMaterial=ui.panels[0].material_override;var right:ShaderMaterial=ui.panels[1].material_override
	check("reference fields retain independent P1 and PM rules",left!=right and left.get_shader_parameter("wallpaper_group")==0 and right.get_shader_parameter("wallpaper_group")==2)
	check("panels share one source image",left.get_shader_parameter("domain_texture")==right.get_shader_parameter("domain_texture"))
	check("panels and floor give each motif forty centimetres",is_equal_approx(1.6/left.get_shader_parameter("tile_scale"),0.4) and is_equal_approx(station.carpet_world_size/station.carpet_repeats,0.4))
	var geometry=station._carpet_mesh.global_transform
	var original_fields=await field_photo("two-fixed-fields")
	var original_floor=await floor_photo("floor-p1")
	await press("PM")
	check("PM leaves source cells and bytes unchanged",initial==station._grid_data and bytes==station._domain_texture.get_image().get_data())
	check("PM reaches the floor rule",station._carpet_shader_material.get_shader_parameter("wallpaper_group")==2)
	var changed_floor=await floor_photo("floor-pm")
	check("rule switch changes the visible floor",difference(original_floor,changed_floor)>10000)
	observations["floor_changed_bytes"]=difference(original_floor,changed_floor)
	var unchanged_fields=await field_photo("floor-rule-only")
	check("rule switch preserves visible reference fields",difference(original_fields,unchanged_fields)<100)
	observations["reference_rule_switch_changed_bytes"]=difference(original_fields,unchanged_fields)
	await press("P1")
	check("P1 returns the translating floor",station._group_index==0 and station._grid_data==initial)
	await press("FLIP X")
	check("FLIP X changes source cells",station._grid_data!=initial and station._grid_data[0][0]==initial[0][3])
	var flipped=await field_photo("source-flipped")
	check("source edit changes visible reference fields",difference(original_fields,flipped)>10000)
	check("source edit leaves reference rules fixed",left.get_shader_parameter("wallpaper_group")==0 and right.get_shader_parameter("wallpaper_group")==2)
	await press("FLIP X");check("two source reflections return the motif",station._grid_data==initial)
	await press("ROTATE");check("first quarter turn changes the asymmetric source",station._grid_data!=initial)
	await field_photo("source-turned")
	for i in 3:await press("ROTATE")
	check("four quarter turns return the source",station._grid_data==initial)
	await press("paint_4");await press("cell_2_3")
	check("pointer paint changes only the chosen address",station._grid_data[3][2]==4 and station._grid_data!=initial)
	var painted=await field_photo("an-interruption-repeated")
	check("new mark reaches both reference images",difference(original_fields,painted)>10000 and left.get_shader_parameter("domain_texture")==right.get_shader_parameter("domain_texture"))
	await snapshot("source-with-one-new-cell",ui.to_global(Vector3(0,1.65,1.25)),ui.to_global(Vector3(0,1.23,0)),49)
	var edited=station._grid_data.duplicate(true)
	await press("RESET");check("RESET returns source and P1",station._grid_data==ui.SEED and station._group_index==0)
	await press("UNDO");check("RESET can itself be undone",station._grid_data==edited)
	await press("UNDO");check("paint can be undone",station._grid_data==initial)
	check("all edits leave physical floor geometry unchanged",station._carpet_mesh.global_transform==geometry)
	actor=museum.get("_player");museum.set("_dollhouse",false)
	actor.global_position=ui.to_global(Vector3(-7,0.05,2));actor.velocity=Vector3.ZERO
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	await travel(Vector3(0,0.05,2),"ordinary body enters bay through existing opening")
	await travel(Vector3(0,0.05,1.7),"ordinary body approaches editor")
	await travel(Vector3(0.7,0.05,1.6),"ordinary body changes viewing position")
	await travel(Vector3(0,0.05,2),"ordinary body returns to approach")
	await travel(Vector3(-7,0.05,2),"ordinary body leaves bay through same opening")
	check("walking preserves source and reference rules",station._grid_data==initial and left.get_shader_parameter("wallpaper_group")==0 and right.get_shader_parameter("wallpaper_group")==2)
	observations["station_world"]=xyz(station.global_position);completed=true
func finish() -> void:
	if driver:driver.release();driver.set_physics_process(false)
	check("reading encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations,"scope":"Real museum with pointer callbacks, rendered-image comparisons, stored-source comparisons and ordinary-controller approach/return. No recipe saved. Headset reach/comfort, performance and learner experience remain unverified."},"  "))
	print("FACING RETURN ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
