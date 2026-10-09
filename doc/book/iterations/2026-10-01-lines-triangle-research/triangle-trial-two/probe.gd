extends "res://tools/probes/transformation_encounters.gd"

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func projected_edge_gaps(owner: Node3D, edge: Array, segment: Array) -> Array:
	var a: Vector2=camera.unproject_position(owner.to_global(edge[0]))
	var b: Vector2=camera.unproject_position(owner.to_global(edge[1]))
	var gaps: Array=[]
	for p: Vector3 in segment:
		var q: Vector2=camera.unproject_position(owner.to_global(p))
		gaps.append(absf((q-a).cross((b-a).normalized())))
	return gaps

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(1.5).timeout
	observations["engine"] = Engine.get_version_info()
	if map_id == "Point_Lines": await line_trials()
	else: await triangle_trials()

func photo(id: String, owner: Node3D, eye: Vector3, aim: Vector3, fov: float=65) -> void:
	if not observations.has("cameras"):observations["cameras"]=[]
	observations.cameras.append({"id":id,"eye":xyz(owner.to_global(eye)),"target":xyz(owner.to_global(aim)),"fov":fov})
	await snapshot(id,owner.to_global(eye),owner.to_global(aim),fov)

func line_trials() -> void:
	var gallery := find_scene("/line_relations_gallery.gd")
	check("line gallery loaded",gallery!=null)
	if gallery==null:return
	var eye: Vector3=gallery.get_meta("alignment_eye")
	var edge: Array=gallery.get_meta("alignment_edge")
	var segment: Array=gallery.get_meta("alignment_line")
	var line: MeshInstance3D=gallery.get_node("DetachedCeilingLine")
	var saved: Vector3=line.mesh.size
	var aim: Vector3=(edge[0]+edge[1])*0.5
	observations["line_trials"]=[]
	for trial in [{"id":"line-aligned","eye":eye},{"id":"line-side-step","eye":eye+Vector3.RIGHT*0.65},{"id":"line-lower-eye","eye":eye+Vector3.DOWN*0.35}]:
		await photo(trial.id,gallery,trial.eye,aim,68)
		var gaps: Array=[]
		for i in 2:gaps.append(camera.unproject_position(gallery.to_global(edge[i])).distance_to(camera.unproject_position(gallery.to_global(segment[i]))))
		observations.line_trials.append({"id":trial.id,"endpoint_separation_pixels":gaps,"perpendicular_gap_pixels":projected_edge_gaps(gallery,edge,segment)})
	line.mesh.size=Vector3(saved.x,saved.y*0.25,saved.z*0.25)
	await photo("line-quarter-thickness",gallery,eye+Vector3.RIGHT*0.65,aim,68)
	line.mesh.size=saved
	await photo("line-replay",gallery,eye,aim,68)
	check("line restored after thickness intervention",line.mesh.size.is_equal_approx(saved))
	check("aligned endpoints project within one pixel",observations.line_trials[0].endpoint_separation_pixels[0]<1 and observations.line_trials[0].endpoint_separation_pixels[1]<1)
	check("side step separates image",observations.line_trials[1].perpendicular_gap_pixels[0]>3)
	# Reopen the observer: a lower eye can recover the same projection by
	# moving along the marked strip. Keep every object in its original pose.
	var lower := eye+Vector3.DOWN*0.35
	lower.x += (-0.35)*(edge[0].x-eye.x)/(edge[0].y-eye.y)
	await photo("line-lower-recovered",gallery,lower,aim,68)
	var recovered: Array=projected_edge_gaps(gallery,edge,segment)
	observations["lower_recovered"]={"eye":xyz(lower),"perpendicular_gap_pixels":recovered,"lateral_change_m":lower.x-eye.x}
	check("lower eye recovers alignment within the strip",recovered[0]<1 and recovered[1]<1 and lower.x>=-5.5 and lower.x<=-2.5)
	observations["scope"]="Camera interventions in native hall; no claim about headset perception or reach. Geometry restored before exit."

func triangle_trials() -> void:
	var twin := find_scene("/triangle_live_twin.gd")
	var puzzle := find_scene("/triangle_line_puzzle.gd")
	check("triangle and twin loaded",twin!=null and puzzle!=null)
	if twin==null or puzzle==null:return
	await photo("triangle-entrance",puzzle,Vector3(-3,0.25,-1.2),Vector3(0,0,0),70)
	await photo("triangle-room",twin,Vector3(-2.1,1.7,-4.2),Vector3(-0.6,1.9,-0.7),63)
	await photo("triangle-two-scales",twin,Vector3(-3.5,1.7,-3.6),Vector3(-1,1.7,-0.6),72)
	observations["twin_transform"]={"origin":xyz(twin.global_position),"basis":str(twin.global_basis)}
	observations["source_position"]=xyz(twin.source.global_position)
	observations["puzzle_position"]=xyz(puzzle.global_position)
	observations["puzzle_basis"]=str(puzzle.global_basis)
	observations["hall_origin"]=xyz(hall.global_position)
	observations["points"]=twin.large_points.size()
	observations["scope"]="Native room baseline captures; no visitor or headset trial."
	if not twin.has_method("restore_reference"):return
	# Match the two valid baseline camera poses in WORLD space, despite the
	# revised orientation of the objects. The first baseline camera was a wall.
	var before: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://doc/book/iterations/2026-10-01-lines-triangle-research/triangle-before/report.json"))
	for shot in before.observations.cameras:
		if shot.id=="triangle-entrance":continue
		var e: Array=shot.eye;var t: Array=shot.target
		await snapshot(shot.id+"-matched",Vector3(e[0],e[1],e[2]),Vector3(t[0],t[1],t[2]),shot.fov)
	await snapshot("triangle-entry-improved",Vector3(6.5,1.7,1.5),puzzle.global_position,68)
	await photo("triangle-puzzle-close",puzzle,Vector3(1.25,0.1,0),Vector3.ZERO,60)
	await photo("triangle-maker",twin.source,Vector3(0,0.25,2.1),Vector3(0,0,0),65)
	await photo("triangle-front",twin,Vector3(0,1.7,4),Vector3(0,1.8,0),63)
	await photo("triangle-edge",twin,Vector3(4,1.7,0),Vector3(0,1.8,0),63)
	var source: Node3D=twin.source
	observations["initial_area_m2"]=_area(twin.large_points)
	check("front-to-edge viewpoint keeps a positive area",_area(twin.large_points)>4.9)
	source.toggle_fill_visibility();await tick();twin.refresh(true)
	await photo("triangle-unfilled",twin,Vector3(0,1.7,4),Vector3(0,1.8,0),63)
	check("fill control leaves three shared edges",not twin.faces.visible and twin.edge_pairs.size()==3)
	source.toggle_fill_visibility()
	# The real pickup/drop path, with a supplied hand, must retain collinearity
	# after the editor snaps the released corner onto its grid.
	var collapsed: Vector3=(source.placed_points[0]+source.placed_points[1])*0.5
	var handle: RigidBody3D=source.point_indicators[2]
	var grabber:=SuppliedGrabber.new();root.add_child(grabber);grabber.global_transform=handle.global_transform
	handle.pick_up(grabber)
	check("restore refuses while a corner is held",not twin.restore_reference())
	grabber.global_position=collapsed;await create_timer(0.3).timeout
	handle.let_go(grabber,Vector3.ZERO,Vector3.ZERO);await create_timer(0.2).timeout;twin.refresh(true)
	observations["collapsed_area_m2"]=_area(twin.large_points)
	check("collinearity removes area but retains all three addresses",_area(twin.large_points)<0.00001 and twin.large_points.size()==3 and twin.faces.mesh==null)
	await photo("triangle-collapsed",twin,Vector3(0,1.7,4),Vector3(0,1.8,0),63)
	twin.restore_button.pressed.emit();await tick();twin.refresh(true)
	check("actual restore button recovers face at both scales",source.placed_points.size()==3 and source.completed_triangles.size()==1 and twin.faces.mesh!=null and absf(_area(twin.large_points)-float(observations.initial_area_m2))<0.0001)
	await photo("triangle-restored",twin,Vector3(0,1.7,4),Vector3(0,1.8,0),63)
	grabber.queue_free()
	await route_checks()
	observations["scope"]="Actual museum images, production fill/reset signals, supplied corner positions and physics capsule. No human learner or physical headset trial."

func _area(points: PackedVector3Array) -> float:
	if points.size()<3:return 0
	return (points[1]-points[0]).cross(points[2]-points[0]).length()*0.5

func route_checks() -> void:
	var walker := CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
	capsule.height=1.65;capsule.radius=0.25;shape.shape=capsule;shape.position.y=0.825
	walker.add_child(shape);root.add_child(walker)
	observations["route"]={"body_height":1.65,"radius":0.25,"mask":1,"segments":[]}
	for route in [[Vector3(6.5,0.03,1.5),Vector3(6.5,0.03,28.5)],[Vector3(2,0.03,17.5),Vector3(10.5,0.03,17.5)],[Vector3(2,0.03,11.5),Vector3(10.5,0.03,11.5)]]:
		walker.global_position=route[0];await physics_frame
		var hit:=walker.move_and_collide(route[1]-route[0])
		var record: Dictionary={"from":xyz(route[0]),"to":xyz(route[1]),"clear":hit==null,"end":xyz(walker.global_position)}
		if hit:record["collider"]=str(hit.get_collider().get_path())
		observations.route.segments.append(record)
		check("clear research route "+str(route[0]),hit==null)
	walker.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
