extends "res://tools/probes/transformation_encounters.gd"
const Journey=preload("res://tools/probes/array_entered_address.gd")
class SuppliedGrabber extends Node3D:
	var picked_up_ranged:=false
var painter:Node3D
var actor:CharacterBody3D
var driver:Journey.KeyJourney
var completed:=false
var states:Array=[]
var paths:Array=[]
func frame_photo(label:String) -> void:
	await snapshot(label,painter.to_global(Vector3(0,1.2,3.8)),painter.to_global(Vector3(0,1.2,-0.5)),53)
	painter.surface.viewport.get_texture().get_image().save_png(folder+label+"-texture.png")
	states.append({"state":label,"elapsed":painter.elapsed,"automatic_strokes":painter.strokes,"rendered_frames":Engine.get_frames_drawn()})
func darkness(im:Image) -> float:
	var value:=0.0;var count:=0
	for y in range(0,im.get_height(),8):
		for x in range(0,im.get_width(),8):
			var c:=im.get_pixel(x,y);value+=(3.0-c.r-c.g-c.b)/3.0;count+=1
	return value/maxi(count,1)
func travel(target:Vector3) -> bool:
	driver.target=target;driver.arrived=false;driver.moving=true
	var start:=Time.get_ticks_msec()
	while not driver.arrived and Time.get_ticks_msec()-start<8000:await physics_frame
	driver.moving=false;driver.release();paths.append({"target":xyz(target),"reached":xyz(actor.global_position),"arrived":driver.arrived})
	return driver.arrived
func aim_can(can:Node3D,grabber:Node3D,surface:MeshInstance3D,uv:Vector2,distance:float) -> void:
	var hit:=surface.to_global(Vector3((uv.x-0.5)*4.0,0,(uv.y-0.5)*2.5))
	var origin:=hit+surface.global_basis.y.normalized()*distance
	var basis:=Basis.looking_at(hit-origin,Vector3.UP)
	grabber.global_transform=Transform3D(basis,origin-basis*Vector3(0,0.16,-0.03))
	for frame in 3:await physics_frame
func landing_checks() -> void:
	root.size=Vector2i(1440,960)
	var grid:Node3D=hall.get_node_or_null("SimGrid_Color_Paint")
	check("authored grid present",grid!=null)
	if grid==null:return
	for frame in 3600:
		if grid.has_meta("stage_grid_ready"):break
		await process_frame
	check("grid complete",grid.has_meta("stage_grid_ready"))
	painter=find_scene("/ball_painting_automation.gd")
	var gallery:=find_scene("/albers_wall_gallery.gd")
	check("both existing primary encounters are placed",painter!=null and gallery!=null)
	if painter==null or gallery==null:return
	var surface:MeshInstance3D=painter.surface
	var cans:Array=painter.get_node("PaintBalls").get_children()
	check("thirty spray cans are parked on their tray",cans.size()==30 and cans.all(func(c):return c.global_transform.is_equal_approx(c._paint_home)))
	check("unheld cans have written no samples",cans.all(func(c):return c.painted_samples==0))
	check("placed rectangular canvas has independent spray feedback",surface.mesh.size==Vector2(4,2.5) and surface.spray_mode and surface.simulation_rect.material.get_shader_parameter("spray_mode"))
	check("automatic painter is a can too",painter.get_node_or_null("AutomatedSprayCan")!=null)
	await create_timer(1.0).timeout
	check("automatic painter works before pickup",painter.strokes>0)
	await RenderingServer.frame_post_draw
	var initial_image:Image=surface.viewport.get_texture().get_image()
	var ground_pixel:Color=initial_image.get_pixel(100,100)
	check("unpainted canvas starts on its white ground",minf(ground_pixel.r,minf(ground_pixel.g,ground_pixel.b))>0.95)
	await snapshot("studio",painter.to_global(Vector3(-1.5,1.2,4.4)),painter.to_global(Vector3(0,1.2,-0.5)),63)
	await snapshot("can-tray",painter.to_global(Vector3(0.35,1.05,2.1)),painter.to_global(Vector3(0,0.83,1.2)),53)
	await frame_photo("before-hand")
	var can:Node3D=cans[3]
	var original:Transform3D=can.global_transform
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=can.global_transform
	can.pick_up(grabber);check("actual can can be picked up",can.is_picked_up())
	# Keep the production automatic painter still for bounded deposition measurements.
	painter.set_process(false)
	var target:=Vector2(0.25,0.3)
	await aim_can(can,grabber,surface,target,0.4)
	var count:int=can.painted_samples
	for frame in 8:await physics_frame
	check("holding and aiming alone do not paint",can.painted_samples==count)
	can.action()
	for frame in 20:await physics_frame
	check("trigger writes via real ray and rectangular UV",can.painted_samples>count and can.paper_surface==surface and can.last_uv_position.distance_to(target)<0.01)
	check("mist emits with a successful spray",can.mist.emitting)
	var near_radius:float=can.last_radius_m
	can.action_release()
	count=can.painted_samples
	for frame in 8:await physics_frame
	check("trigger release stops without dropping",can.painted_samples==count and can.is_picked_up() and not can.mist.emitting)
	await frame_photo("close-spray")
	var near_image:Image=surface.viewport.get_texture().get_image()
	var near_ink:Color=near_image.get_pixel(int(0.25*surface.texture_size.x),int(0.3*surface.texture_size.y))
	check("close nozzle leaves visible pigment in the actual GPU texture",(3.0-near_ink.r-near_ink.g-near_ink.b)>0.15)
	await aim_can(can,grabber,surface,Vector2(0.65,0.3),1.2)
	can.action()
	for frame in 20:await physics_frame
	check("distance broadens the footprint",can.last_radius_m>near_radius*2.0)
	can.action_release()
	await frame_photo("far-spray")
	var far_image:Image=surface.viewport.get_texture().get_image()
	var far_ink:Color=far_image.get_pixel(int(0.65*surface.texture_size.x),int(0.3*surface.texture_size.y))
	check("distant spray also reaches the GPU texture",(3.0-far_ink.r-far_ink.g-far_ink.b)>0.08)
	observations["footprints"]={"near_radius_m":near_radius,"far_radius_m":can.last_radius_m,"range_m":can.max_distance}
	# Point away and past range. Nothing must connect those separated gestures.
	grabber.rotate_y(PI)
	can.action();count=can.painted_samples
	for frame in 8:await physics_frame
	check("aiming away adds no samples",can.painted_samples==count)
	can.action_release()
	await aim_can(can,grabber,surface,Vector2(0.5,0.5),3.5)
	can.action();count=can.painted_samples
	for frame in 8:await physics_frame
	check("nozzle range is bounded",can.painted_samples==count)
	can.action_release()
	# A real body between nozzle and canvas blocks the ray.
	await aim_can(can,grabber,surface,Vector2(0.5,0.5),0.8)
	var blocker:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(0.5,0.5,0.1);shape.shape=box;blocker.add_child(shape);root.add_child(blocker)
	blocker.global_position=surface.to_global(Vector3(0,0,0))+surface.global_basis.y.normalized()*0.3
	for frame in 3:await physics_frame
	can.action();count=can.painted_samples
	for frame in 8:await physics_frame
	check("a blocking body prevents painting through it",can.painted_samples==count)
	can.action_release();blocker.queue_free()
	# Human gesture and automatic trajectory coexist on the same receiver.
	painter.set_process(true)
	await aim_can(can,grabber,surface,Vector2(0.17,0.7),0.65)
	can.action();var auto_start:int=painter.strokes
	for step in 25:
		await aim_can(can,grabber,surface,Vector2(0.17+0.60*float(step)/24.0,0.7+0.06*sin(float(step)*0.5)),0.65)
	can.action_release()
	check("automatic painter continues alongside the hand",painter.strokes>auto_start)
	await frame_photo("shared-canvas")
	count=can.painted_samples
	can.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	for frame in 12:await physics_frame
	check("drop restores the can to its own dock",can.global_transform.is_equal_approx(original))
	check("drop stops all manual emission",not can.is_painting and can.painted_samples==count and not can.mist.emitting)
	await frame_photo("after-release")
	# Make a known deposit, then let only the shader run.
	painter.set_process(false)
	for frame in 6:await process_frame
	await RenderingServer.frame_post_draw
	var before_image:Image=surface.viewport.get_texture().get_image()
	var d0:=darkness(before_image)
	for frame in 100:await process_frame
	await RenderingServer.frame_post_draw
	var after_image:Image=surface.viewport.get_texture().get_image()
	var d1:=darkness(after_image)
	check("sprayed pigment reaches the GPU image",d0>0.003)
	check("quiet feedback changes the retained image",before_image.get_data()!=after_image.get_data())
	check("quiet feedback fades gently toward its ground",d1<d0 and d1>d0*0.25)
	check("spray stamps are bounded and consumed",surface.brush_layer.sprays.is_empty() and surface.brush_layer.spray_pool.size()<=64 and surface.brush_layer.spray_pool.all(func(q):return not q.visible))
	check("legacy splat queue also clears",surface.brush_layer.strokes.is_empty())
	observations["feedback"]={"before_darkness":d0,"after_darkness":d1,"pool_size":surface.brush_layer.spray_pool.size()}
	await frame_photo("after-wait")
	painter.set_process(true)
	# The museum desktop hand carries without XRTools.pick_up; exercise its hooks.
	var pointer:Node3D=museum.get("_player").get_node_or_null("DesktopHand")
	check("museum desktop hand present",pointer!=null)
	if pointer:
		pointer.set_process(false)
		pointer._grab_held(can)
		check("desktop carry activates the can without a VR grab",can._desktop_held and pointer.is_holding())
		var hit:=surface.to_global(Vector3(-0.8,0,0.25))
		var origin:=hit+surface.global_basis.y.normalized()*0.55
		var basis:=Basis.looking_at(hit-origin,Vector3.UP)
		can.global_transform=Transform3D(basis,origin-basis*Vector3(0,0.16,-0.03))
		count=can.painted_samples
		check("desktop left press routes to the nozzle",pointer._try_held_action(true))
		for frame in 12:await physics_frame
		check("desktop carry produces real canvas samples",can.painted_samples>count)
		check("desktop release routes to the same can",pointer._try_held_action(false))
		count=can.painted_samples
		for frame in 5:await physics_frame
		check("desktop trigger release stops pigment",can.painted_samples==count)
		pointer._drop_held()
		for frame in 3:await physics_frame
		check("desktop drop restores dock and stops the nozzle",can.global_transform.is_equal_approx(original) and not can._desktop_held and not can.is_painting)
		pointer.set_process(true)
	var canvases:=gallery.find_children("Canvas_*","Node3D",false,false)
	check("existing Albers studies remain present",canvases.size()==gallery.total_canvases)
	await snapshot("albers-studies",gallery.to_global(Vector3(0,2.15,3.2)),gallery.to_global(Vector3(0,2.15,0)),82)
	# Approach the actual tray with the ordinary controller, using measured floor height.
	var start:Vector3=painter.to_global(Vector3(0,0,3.5))
	var support:=floor_at(start+Vector3.DOWN*0.5)
	check("tray approach has supporting floor",not support.is_empty())
	if not support.is_empty():
		start.y=support.position.y+0.05
		actor=museum.get("_player");actor.global_position=start;actor.velocity=Vector3.ZERO;museum.set("_dollhouse",false)
		driver=Journey.KeyJourney.new();driver.world=museum;driver.actor=actor;driver.view=museum.get("_cam");root.add_child(driver)
		var near:Vector3=painter.to_global(Vector3(0,0,2.05));near.y=start.y
		check("ordinary walker approaches the tray",await travel(near))
		await snapshot("at-the-tray",actor.global_position+Vector3.UP*1.65,painter.to_global(Vector3(0,1.2,-0.5)),68)
		check("ordinary walker returns from tray",await travel(start))
	# Legacy ball placement and a different priming keep independent materials.
	var legacy=load("res://commons/context/drawingboard/ball_painting_demo_v2.tscn").instantiate()
	legacy.set_meta("config_automated",true);legacy.set_meta("config_priming","bole")
	legacy.position=Vector3(1000,0,0);root.add_child(legacy)
	for frame in 8:await process_frame
	var old_surface:MeshInstance3D=legacy.surface
	check("unconfigured tool placement retains thirty balls",legacy.get_node("PaintBalls").get_child_count()==30 and legacy.get_node("PaintBalls").get_child(0).has_node("BallPaintTip"))
	check("legacy feedback stays out of spray mode",not old_surface.spray_mode and not old_surface.simulation_rect.material.get_shader_parameter("spray_mode"))
	check("feedback material is per canvas",old_surface.simulation_rect.material!=surface.simulation_rect.material)
	check("nonwhite priming survives explicit reset setup",old_surface.priming=="bole" and old_surface.simulation_rect.material.get_shader_parameter("ground_color")==Color(0.42,0.2,0.16,1))
	legacy.queue_free()
	observations["states"]=states;observations["walks"]=paths
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("focused encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Supplied grabber and trigger actions with actual nozzle ray, range, obstruction, native GPU images, quiet-input feedback and ordinary-controller approach. No tracked hand, headset, colour calibration, learner or performance claim."},"  "))
	print("PAINT SPRAY CANS ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
