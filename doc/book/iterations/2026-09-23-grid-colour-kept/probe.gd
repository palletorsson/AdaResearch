extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
var lesson:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
var paths:Array=[]
var states:Array=[]
func close_colour(a:Color,b:Color) -> bool:
	return maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))<=1.0/255.0
func press(index:int) -> void:
	var area:Node3D=lesson.buttons[index].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(camera,area,area.global_position)
	XRToolsPointerEvent.released(camera,area,area.global_position)
	await create_timer(0.13).timeout
func travel(point:Vector3) -> bool:
	driver.target=lesson.to_global(point);driver.arrived=false;driver.moving=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<10000:await physics_frame
	driver.moving=false;driver.release()
	paths.append({"target":xyz(point),"reached":xyz(lesson.to_local(actor.global_position)),"arrived":driver.arrived})
	return driver.arrived
func floor_view(label:String) -> void:
	states.append({"state":label,"selected":[lesson.selected.x,lesson.selected.y],"stored_at_10_10":lesson.colorizer.multimesh.get_instance_color(lesson.cells[Vector2i(10,10)]).to_html(false),"readout":lesson.readout.text})
	await snapshot(label,lesson.to_global(Vector3(10,3.8,13.3)),lesson.to_global(Vector3(10.3,0,10.2)),50)
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Grid_Pallet")
	check("authored grid present",grid!=null)
	if grid==null:return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	check("grid complete",grid.has_meta("stage_grid_ready"))
	lesson=find_scene("/address_lesson.gd")
	check("actual address lesson present",lesson!=null)
	if lesson==null:return
	for frame in 600:
		if lesson.ready_for_input:break
		await process_frame
	check("console has indexed this room's floor",lesson.ready_for_input and lesson.cells.size()>25)
	if not lesson.ready_for_input:return
	var mm:MultiMesh=lesson.colorizer.multimesh
	var poses:Array=[];var colours:Array=[]
	for i in mm.instance_count:poses.append(mm.get_instance_transform(i));colours.append(mm.get_instance_color(i))
	var chosen:int=lesson.cells[Vector2i(10,10)]
	check("selected address resolves to actual floor coordinate",lesson.colorizer.grid_structure.cube_positions[chosen]==Vector3i(10,0,10))
	check("five console controls and no automatic overwrite",lesson.buttons.size()==5 and not lesson.colorizer.auto_cycle_enabled)
	await snapshot("console-and-floor",lesson.to_global(Vector3(7.7,1.65,17.5)),lesson.to_global(Vector3(9.6,0.5,10.5)),72)
	await floor_view("rule-before")
	await press(2)
	var painted:Color=mm.get_instance_color(chosen)
	check("actual COLOUR control writes first pink ink",close_colour(painted,lesson.INKS[0]))
	var changed:=0
	for i in mm.instance_count:
		if not mm.get_instance_color(i).is_equal_approx(colours[i]):changed+=1
	check("only the selected floor instance changes",changed==1)
	check("console swatch reads actual stored value",lesson.swatch.material_override.albedo_color.is_equal_approx(painted) and lesson.readout.text.contains(painted.to_html(false)))
	await floor_view("edited")
	await snapshot("readout-edited",lesson.to_global(Vector3(7.45,1.5,16.3)),lesson.to_global(Vector3(7.45,1.15,15)),55)
	await press(0)
	check("X moves selection without moving the exception",lesson.selected==Vector2i(11,10) and mm.get_instance_color(chosen).is_equal_approx(painted))
	await floor_view("attention-away")
	for step in 4:await press(0)
	check("five X steps return to the stored exception",lesson.selected==Vector2i(10,10) and mm.get_instance_color(chosen).is_equal_approx(painted))
	await press(1)
	check("Z advances the other coordinate",lesson.selected==Vector2i(10,11))
	for step in 4:await press(1)
	check("five Z steps return without rewriting colour",lesson.selected==Vector2i(10,10) and mm.get_instance_color(chosen).is_equal_approx(painted))
	await floor_view("returned")
	actor=museum.get("_player");actor.global_position=lesson.to_global(Vector3(7,0.05,17));actor.velocity=Vector3.ZERO;museum.set("_dollhouse",false)
	driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
	await create_timer(0.2).timeout
	check("ordinary walk passes beside the console",await travel(Vector3(9.4,0.05,16.7)))
	check("ordinary walk reaches the painted square",await travel(Vector3(10,0.05,10)))
	check("edited floor supports the walker",actor.is_on_floor() and absf(lesson.to_local(actor.global_position).y)<0.12)
	await snapshot("standing-on-colour",actor.global_position+Vector3.UP*1.65,lesson.to_global(Vector3(10.1,0,10.35)),70)
	await press(3)
	check("RULE overwrites the exception with its original value",mm.get_instance_color(chosen).is_equal_approx(colours[chosen]) and not mm.get_instance_color(chosen).is_equal_approx(painted))
	check("rewrite keeps selected address and standing support",lesson.selected==Vector2i(10,10) and actor.is_on_floor() and absf(lesson.to_local(actor.global_position).y)<0.12)
	check("equal coordinate sums share a colour",mm.get_instance_color(lesson.cells[Vector2i(8,9)]).is_equal_approx(mm.get_instance_color(lesson.cells[Vector2i(9,8)])))
	await floor_view("rule-after")
	await press(4)
	var palette:Array=lesson.colorizer._get_palette_colors(lesson.PALETTES[1])
	check("PALETTE uses another collection with the same rule",lesson.palette_index==1 and lesson.cells.keys().all(func(a):return close_colour(mm.get_instance_color(lesson.cells[a]),palette[(a.x+a.y)%palette.size()])))
	check("rule reaches addresses outside manual region",lesson.cells.has(Vector2i(6,6)) and close_colour(mm.get_instance_color(lesson.cells[Vector2i(6,6)]),palette[12%palette.size()]))
	await floor_view("another-palette")
	await press(4);await press(4)
	check("three palette steps restore original collection",lesson.palette_index==0 and mm.get_instance_color(chosen).is_equal_approx(colours[chosen]))
	check("ordinary walk returns from the recoloured floor",await travel(Vector3(9.4,0.05,16.7)))
	check("ordinary walk returns to the console approach",await travel(Vector3(7,0.05,17)))
	var unchanged:=true
	for i in mm.instance_count:unchanged=unchanged and mm.get_instance_transform(i).is_equal_approx(poses[i])
	check("all instance transforms remain unchanged",unchanged)
	lesson.ink_index=0
	observations["states"]=states;observations["walks"]=paths;observations["manual_addresses"]=25;observations["rule_addresses"]=lesson.cells.size()
	observations["instance_count"]=mm.instance_count
	observations["colour_precision"]={"requested":lesson.INKS[0].to_html(false),"stored":painted.to_html(false),"tolerance_per_channel":1.0/255.0}
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("focused encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Supplied pointer callbacks and ordinary-controller key journeys, actual MultiMesh values and transforms, native captures. No headset, tracked reach, colour calibration, learner or performance claim."},"  "))
	print("GRID KEPT ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
