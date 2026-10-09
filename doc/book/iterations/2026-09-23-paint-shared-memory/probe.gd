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
	var balls:Array=painter.get_node("PaintBalls").get_children()
	check("thirty pigments remain on their tray",balls.size()==30 and balls.all(func(b):return b.global_transform.is_equal_approx(b._paint_home)))
	check("unheld pigments have written no samples",balls.all(func(b):return b.get_node("BallPaintTip").painted_samples==0))
	check("placed canvas uses its rectangular wet white-ground configuration",surface.mesh.size==Vector2(4,2.5) and surface.wet_paint and surface.priming=="white")
	var initial:int=painter.strokes
	await create_timer(1.0).timeout
	check("automatic painter advances before any pickup",painter.strokes>initial)
	await snapshot("studio",painter.to_global(Vector3(-1.5,1.2,4.4)),painter.to_global(Vector3(0,1.2,-0.5)),63)
	await frame_photo("before-hand")
	# Use an existing broad brush with a finer snap, retaining its actual settings.
	var ball:Node3D=balls[0];var score:float=-1.0
	for b in balls:
		var t:Node3D=b.get_node("BallPaintTip")
		var s:float=t.brush_size+(30 if t.snap_grid_size>=16 else 0)
		if s>score:score=s;ball=b
	var tip:Node3D=ball.get_node("BallPaintTip")
	var original:Transform3D=ball.global_transform
	observations["chosen_pigment"]={"node":str(ball.name),"colour":tip.brush_color.to_html(false),"brush_radius_px":tip.brush_size,"snap_divisions":tip.snap_grid_size,"scale":xyz(ball.scale)}
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=ball.global_transform
	ball.pick_up(grabber);check("actual pigment can be picked up",ball.is_picked_up())
	var auto_start:int=painter.strokes
	var points:Array[Vector2]=[Vector2(0.12,0.2),Vector2(0.4,0.3),Vector2(0.15,0.45),Vector2(0.45,0.6)]
	for segment in 3:
		for step in 9:
			var uv:Vector2=points[segment].lerp(points[segment+1],float(step)/8.0)
			var hit:Vector3=surface.to_global(Vector3((uv.x-0.5)*4.0,0,(uv.y-0.5)*2.5))
			grabber.global_position=hit+surface.global_basis.y*0.6
			grabber.look_at(hit,Vector3.UP)
			for frame in 3:await physics_frame
	for frame in 6:await physics_frame
	check("held pigment paints through the actual canvas ray",tip.painted_samples>0 and tip.raycast.is_colliding() and tip.paper_surface==surface)
	check("manual UV matches final rectangular target",tip.last_uv_position.distance_to(points[-1])<0.025)
	check("automatic brush continues during the supplied gesture",painter.strokes>auto_start)
	observations["manual_samples"]=tip.painted_samples
	await frame_photo("shared-canvas")
	var manual_count:int=tip.painted_samples
	ball.let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	for frame in 12:await physics_frame
	check("release stops manual input",tip.painted_samples==manual_count and not tip.is_painting)
	check("release restores the ball's own dock",ball.global_transform.is_equal_approx(original))
	await frame_photo("after-release")
	var im1:Image=surface.viewport.get_texture().get_image()
	var count1:int=painter.strokes
	await create_timer(3.0).timeout
	await frame_photo("after-wait")
	var im2:Image=surface.viewport.get_texture().get_image()
	check("automatic brush and image continue after release",painter.strokes>count1 and im1.get_data()!=im2.get_data() and tip.painted_samples==manual_count)
	# A bounded diagnostic isolates feedback; this pause is not a visitor control.
	painter.set_process(false)
	for frame in 3:await process_frame
	await RenderingServer.frame_post_draw
	var diagnostic_start:=Engine.get_frames_drawn()
	var before_image:Image=surface.viewport.get_texture().get_image();before_image.save_png(folder+"feedback-before.png")
	var d0:=darkness(before_image)
	for frame in 120:await process_frame
	await RenderingServer.frame_post_draw
	var after_image:Image=surface.viewport.get_texture().get_image();after_image.save_png(folder+"feedback-after.png")
	var d1:=darkness(after_image)
	check("with both inputs quiet feedback still changes the image",before_image.get_data()!=after_image.get_data() and tip.painted_samples==manual_count)
	check("quiet feedback reduces mean distance from white",d1<d0)
	check("brush queue is consumed instead of retaining gesture history",surface.brush_layer.strokes.is_empty())
	observations["feedback_diagnostic"]={"before_mean_distance_from_white":d0,"after_mean_distance_from_white":d1,"rendered_frame_difference":Engine.get_frames_drawn()-diagnostic_start,"automatic_input_paused_only_for_diagnostic":true}
	painter.set_process(true)
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
	observations["states"]=states;observations["walks"]=paths
	completed=true
func finish() -> void:
	if driver!=null:driver.release();driver.set_physics_process(false)
	check("focused encounter completed",completed)
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Isolated production museum. Existing ball settings; supplied grabber with real ray hits, native GPU images, a separately labelled quiet-input feedback diagnostic, and ordinary-controller approach. No tracked hand, headset, colour calibration, learner or performance claim."},"  "))
	print("PAINT SHARED MEMORY ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
