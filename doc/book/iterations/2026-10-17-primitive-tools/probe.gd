extends "res://doc/book/iterations/2026-10-17-primitive-encounters/probe.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1.0).timeout
	pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	root.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false);pointer.set("_camera",camera)
	match map_id:
		"Point_Trace":await trace_trial()
		"Point_Line_Grid":await grid_trial()
		"Point_Animatedcube":await cube_trial()
		"Primitives_Melencolia":await skull_trial()
func trace_trial() -> void:
	var wall:=find_scene("/glass_paint_wall.gd")
	check("glass wall installed",wall!=null)
	if wall==null:return
	var tools:Node3D=wall.get_node("DrawingTools");var canvas=tools.canvas
	check("empty ink pixels are transparent",canvas._image.get_pixel(10,10).a==0)
	check("pens require contact with glass",tools.sample_uv(tools.to_global(Vector3(0,.5,.25)),0).x<0)
	check("glass contact admitted",tools.sample_uv(tools.to_global(Vector3(0,.5,.044)),0).x>=0)
	var pen:Node3D=tools.pens[1]
	pointer.call("_grab_held",pen);await tick()
	for i in 18:
		var at:Vector3=tools.to_global(Vector3(-.7+i*.05,.45+.16*sin(i*.3),.044))
		pen.global_position+=at-pen.get_node("WritingTip").global_position;await tick()
	pointer.call("_drop_held");await tick()
	check("desktop pen contact paints",tools.stroke_events>8)
	canvas.draw_point(Vector2(.5,.5),Color.RED,5);check("ink retained in image",canvas._image.get_pixel(canvas.texture_size.x/2,canvas.texture_size.y/2).a==1)
	tools.paint(Vector2(-1,-1),Vector2(.5,.5),Color.WHITE,true)
	check("eraser restores transparent glass",canvas._image.get_pixel(canvas.texture_size.x/2,canvas.texture_size.y/2).a==0)
	check("ink visible from both sides",canvas.material_override.cull_mode==BaseMaterial3D.CULL_DISABLED)
	var plain=load("res://commons/artifacts/whiteboard/whiteboard_canvas.gd").new();root.add_child(plain)
	check("ordinary board still starts opaque white",plain._image.get_pixel(10,10)==Color.WHITE)
	plain.draw_point(Vector2(.5,.5),Color.RED,5);plain.reset_canvas()
	check("ordinary board reset stays opaque",plain._image.get_pixel(plain.texture_size.x/2,plain.texture_size.y/2)==Color.WHITE)
	plain.queue_free()
	await snapshot("glass-front",wall.to_global(Vector3(1.3,1.6,4.5)),wall.to_global(Vector3(0,.6,0)),53)
	await snapshot("glass-back",wall.to_global(Vector3(-1.3,1.6,-4.5)),wall.to_global(Vector3(0,.6,0)),53)
	var beads:Array=[]
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script()!=null and str(n.get_script().resource_path).ends_with("/draw_dot.gd") and n.spatial_bead:beads.append(n)
	check("three spatial beads preserve resolutions",beads.size()==3)
	if beads.is_empty():return
	var source:Node3D=beads[0];var bead:Node3D=source._grab_point
	check("bead centre is the recorded point",source._draw_sphere==bead and not bead.has_node("Barrel"))
	var archive=root.get_node("TraceData");archive.clear_traces()
	pointer.call("_grab_held",bead);await tick()
	var start:Vector3=bead.global_position
	for i in 24:
		bead.global_position=start+Vector3(i*.025,sin(i*.18)*.23,i*.018);await tick()
	pointer.call("_drop_held");await tick()
	check("release preserves session trace",archive.saved_traces.size()==1 and archive.saved_traces[0].size()>12)
	check("bead ignores nearby writing planes",source._nearest_board_face(wall.to_global(Vector3(0,.5,.04))).is_empty())
	var frozen_count:int=source._trail_points.size();await tick()
	check("released bead stops recording",source._trail_points.size()==frozen_count)
	await xr_grab(bead,true)
	var sampler:=find_scene("/trace_sampling_monitor.gd")
	sampler.discover_sources();check("same-gesture monitor still discovers beads",sampler.sources.size()==3)
	var grid=load("res://commons/primitives/line/grid_lines.tscn").instantiate()
	grid.position=source.global_position+Vector3(100,0,0);root.add_child(grid);await tick()
	check("next-hall renderer receives exact carried points",grid._trace_data_list.size()>=1 and grid._trace_data_list[0].raw_points==archive.saved_traces[0])
	grid.queue_free()
	await snapshot("spatial-beads",source.to_global(Vector3(2.1,1.1,4.3)),source.to_global(Vector3(-1,0,0)),58)
	var origin:Vector3=wall.global_position-Vector3(7,.75,5)
	await walk_route(origin,[Vector2(12,2),Vector2(12,7),Vector2(11,11),Vector2(13,14),Vector2(15,20),Vector2(12,22)])
func grid_trial() -> void:
	var grid:=find_scene("/grid_lines.gd");check("grid with linked selection installed",grid!=null and grid.point_selection!=null)
	if grid==null or grid.point_selection==null:return
	var points:Array[Vector3]=[Vector3.ZERO,Vector3(.001,0,0),Vector3(0,.3,.15),Vector3(.6,.1,.25),Vector3.ZERO]
	for i in 10:points.append(Vector3(i*.06,.1+i*.01,.2))
	root.get_node("TraceData").add_trace(points);await create_timer(1.5).timeout
	var select:Node3D=grid.point_selection
	select.select_point(0);await tick();var a:Vector3=select.selected_source;var b:Vector3=select.selected_snapped
	select.step_point(1);await tick()
	check("distinct sources move pink marker",not select.selected_source.is_equal_approx(a))
	check("duplicate snap address retains correspondence",select.selected_snapped.is_equal_approx(b))
	select.select_point(4);check("repeated coordinates keep source identity",select.point_index==4)
	select.step_page(1);check("paging preserves selection",select.point_index==4 and select.page==1)
	var target:Node3D=select.row_targets.get_child(0)
	XRToolsPointerEvent.pressed(pointer,target,target.global_position);await tick()
	check("row pointer selects source on page two",select.point_index==10)
	var point_target:Node3D=select.targets.get_child(3)
	XRToolsPointerEvent.pressed(pointer,point_target,point_target.global_position);await tick()
	check("geometry pointer selects corresponding row",select.point_index==11)
	target=select.row_targets.get_child(0)
	var ray:=PhysicsRayQueryParameters3D.create(target.global_position+target.global_basis.z*.2,target.global_position-target.global_basis.z*.1,1048576)
	check("row target reachable by actual pointer ray",not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
	select.select_point(2);await tick()
	await snapshot("selected-trace",grid.to_global(Vector3(2.5,3.4,4.0)),grid.to_global(Vector3(0,1,0)),62)
	var panel:Node3D=grid._data_panel
	await snapshot("selected-row",panel.to_global(Vector3(0,.12,1.55)),panel.global_position,48)
func cube_trial() -> void:
	var pair:=find_scene("/paired_cubes.gd");check("paired cube comparison installed",pair!=null)
	if pair==null:return
	check("two cubes begin with identical vertices",pair.cubes[0].vertices==pair.cubes[1].vertices)
	check("opposite front diagonals",pair.cubes[0].triangles[4]==[4,5,7] and pair.cubes[1].triangles[4]==[4,5,6])
	check("baseline surfaces coincide",is_equal_approx(pair.centre_depth(0),pair.centre_depth(1)))
	await snapshot("cube-baseline",pair.to_global(Vector3(3.0,2.4,5.0)),pair.to_global(Vector3(0,1.05,0)),50)
	var h:Node3D=pair.cubes[0].handle_nodes[6]
	await carry_release(h,pair.cubes[0].to_global(pair.initial[6]+Vector3(0,0,.25)))
	check("moving A changes corresponding B corner",pair.cubes[0].vertices==pair.cubes[1].vertices)
	check("one changed corner yields 12.5 cm centre-depth difference",is_equal_approx(pair.centre_depth(1)-pair.centre_depth(0),.125))
	for i in 8:
		if i!=6:check("control corner %d fixed"%i,pair.cubes[0].vertices[i].is_equal_approx(pair.initial[i]))
	await snapshot("cube-fold",pair.to_global(Vector3(3.0,2.4,5.0)),pair.to_global(Vector3(0,1.05,0)),50)
	var altered:Array=pair.cubes[0].vertices.duplicate()
	pair.replay();await create_timer(4.5).timeout
	check("replay keeps changed positions",pair.cubes[0].vertices==altered and not pair.replaying)
	pair.restore();await tick();check("restore resets both cubes",pair.cubes[0].vertices==pair.initial and pair.cubes[1].vertices==pair.initial)
	await xr_grab(h,true)
	pair.toggle_free();check("free editing enables remaining A handles",pair.cubes[0].handle_nodes[0].collision_layer!=0 and pair.cubes[1].handle_nodes[0].collision_layer==0)
	check("net and prefab library retained",find_scene("/prefab_box_library.gd")!=null and find_scene("/cube_sorting_line.gd")!=null)
	await walk_route(pair.global_position-Vector3(13,0,6),[Vector2(13,2),Vector2(16,4),Vector2(16,9),Vector2(13,10),Vector2(13,13),Vector2(16,18),Vector2(13,22),Vector2(13,29),Vector2(13,34)])
	await snapshot("cube-workshop",pair.global_position+Vector3(0,3.0,6),pair.global_position+Vector3(0,1.1,18),66)
func skull_trial() -> void:
	var scene:=find_scene("/EngravingScene.gd");check("tableau installed",scene!=null)
	if scene==null:return
	check("main figure replaced by skull",scene.has_node("SkullStudy/Skull") and not scene.groups.has("Melencolia"))
	check("polyhedron and tools preserved",scene.groups.has("Polyhedron") and scene.groups.has("Sphere"))
	var skull:Node3D=scene.get_node("SkullStudy/Skull")
	check("skull has carved sockets",skull.get_node("CarvedBone").get_child_count()>=7)
	await create_timer(1.0).timeout
	await snapshot("skull-detail",skull.to_global(Vector3(1.1,1.0,4.5)),skull.to_global(Vector3(0,-.1,.1)),45)
	await snapshot("tableau",scene.to_global(Vector3(.3,3.3,8.6)),scene.to_global(Vector3(0,2,0)),58)

func walk_route(origin:Vector3,route:Array) -> void:
	var walker:CharacterBody3D=museum.get("_player")
	walker.global_position=origin+Vector3(route[0].x,.03,route[0].y);walker.velocity=Vector3.ZERO;await tick()
	for at in route.slice(1):
		check("walk clear route "+str(at),await walk_to(walker,origin+Vector3(at.x,0,at.y),300))
