extends "res://tools/probes/transformation_encounters.gd"

class Hand extends Node3D:
	var picked_up_ranged := false

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.flush_stamps();await create_timer(2).timeout
	var puzzle:=find_scene("/triangle_line_puzzle.gd")
	var twin:=find_scene("/triangle_live_twin.gd")
	check("puzzle and drawing twin present",puzzle!=null and twin!=null and twin.source!=null)
	if puzzle==null or twin==null or twin.source==null:return
	var source:Node3D=twin.source
	observations["puzzle"]=xyz(puzzle.global_position);observations["source"]=xyz(source.global_position);observations["twin"]=xyz(twin.global_position)
	await snapshot("puzzle",puzzle.global_position+Vector3(-1.1,0.35,-1.1),puzzle.global_position+Vector3(0,-0.05,0),73)
	await puzzle_checks(puzzle)
	await drawing_checks(source,twin)
	await snapshot("two-scales",source.global_position+Vector3(-2.1,0.4,-1.6),twin.global_position+Vector3(-0.8,1.4,-1.2),71)
	await snapshot("maker",source.to_global(Vector3(0,0.65,1.95)),source.global_position+Vector3(0,-0.08,0),65)
	await snapshot("large-face",twin.to_global(Vector3(-2.2,1.8,3.7)),twin.to_global(Vector3(0,1.7,0)),65)
	await passage_checks(source,twin)

func wait_physics() -> void:
	for i in range(8):await physics_frame

func puzzle_checks(puzzle: Node3D) -> void:
	check("three short edges begin open",puzzle.snap_lines.size()==3 and not puzzle.is_completed)
	var gap_ok:=true
	for i in 3:
		var line:Node3D=puzzle.snap_lines[i]
		var a:Vector3=puzzle.to_global(puzzle.target_positions[i])
		var b:Vector3=puzzle.to_global(puzzle.target_positions[(i+1)%3])
		gap_ok=gap_ok and line.endpoint_a.global_position.distance_to(a.lerp(b,0.16))<0.001 and line.endpoint_b.global_position.distance_to(b.lerp(a,0.16))<0.001
		check("edge %d keeps Lines pink and white materials"%i,line.material.albedo_color==Color("ec8fba") and line.endpoint_a.get_node("MeshInstance3D").material_override.albedo_color==Color("f5f1e9"))
	check("edges lie on triangle axes with 16 percent gaps",gap_ok)
	var hand:=Hand.new();root.add_child(hand)
	for i in 3:
		var line:Node3D=puzzle.snap_lines[i]
		for j in 2:
			var end:Node3D=line.endpoint_a if j==0 else line.endpoint_b
			hand.global_transform=end.global_transform;end.pick_up(hand)
			var target:Vector3=puzzle.to_global(puzzle.target_positions[(i+j)%3])
			hand.global_position=target+Vector3(0.015,0.01,0.01)
			await wait_physics()
			check("held endpoint does not finish puzzle %d/%d"%[i,j],not puzzle.is_completed)
			end.let_go(hand,Vector3.ZERO,Vector3.ZERO)
			await wait_physics()
			check("release snaps endpoint exactly %d/%d"%[i,j],end.global_position.distance_to(target)<0.001)
	check("all three released edges close the triangle",puzzle.is_completed)
	var visible_ends:=0
	for line in puzzle.snap_lines:
		for end in [line.endpoint_a,line.endpoint_b]:
			if end.get_node("MeshInstance3D").is_visible_in_tree():visible_ends+=1
	check("closure retains three visible shared white corners",visible_ends==3)
	puzzle.get_node("ExperimentPanel").buttons.fill.pressed.emit()
	check("face is a separate control after closure",puzzle.discovery_face!=null and puzzle.discovery_face.visible)
	await snapshot("puzzle-closed",puzzle.global_position+Vector3(-1.1,0.35,-1.1),puzzle.global_position+Vector3(0,-0.05,0),73)
	puzzle.get_node("ExperimentPanel").buttons.reset.pressed.emit()
	await wait_physics()
	check("reset reopens puzzle and returns grabbable endpoints",not puzzle.is_completed and puzzle.snap_lines[0].endpoint_a.enabled and puzzle.snap_lines[0].endpoint_a.freeze)
	# Flip the first segment's endpoint order: connectivity must not depend on A/B.
	for i in 3:
		for j in 2:
			var end:Node3D=puzzle.snap_lines[i].endpoint_a if j==0 else puzzle.snap_lines[i].endpoint_b
			hand.global_transform=end.global_transform;end.pick_up(hand)
			var index:int=(i+(1-j if i==0 else j))%3
			hand.global_position=puzzle.to_global(puzzle.target_positions[index]);await wait_physics()
			end.let_go(hand,Vector3.ZERO,Vector3.ZERO);await wait_physics()
	var corner_counts:Array[int]=[0,0,0]
	for line in puzzle.snap_lines:
		for end in [line.endpoint_a,line.endpoint_b]:
			if end.get_node("MeshInstance3D").is_visible_in_tree():
				for i in 3:
					if end.global_position.distance_to(puzzle.to_global(puzzle.target_positions[i]))<0.001:corner_counts[i]+=1
	check("reversed endpoint order still completes with one sphere at each corner",puzzle.is_completed and corner_counts==[1,1,1])
	puzzle.reset_puzzle();await wait_physics()
	hand.queue_free()

func drawing_checks(source: Node3D,twin: Node3D) -> void:
	check("compact creator retains an initial editable triangle",source.museum_style and source.placed_points.size()==3 and source.completed_triangles.size()==1)
	check("hand-scale triangle is 80cm wide",is_equal_approx(source.placed_points[0].distance_to(source.placed_points[1]),0.8))
	check("small boundary and larger added face are distinct",not source.completed_triangles[0].mesh.visible and twin.faces.visible and twin.faces.mesh!=null)
	var panel:Node3D=source.get_node("MuseumWorkbench")
	check("seven visible actions share a reachable compact panel",panel.buttons.size()==7)
	var point:Node3D=source.point_indicators[2]
	var hand:=Hand.new();root.add_child(hand);hand.global_transform=point.global_transform
	var before:Vector3=twin.large_points[2]
	point.pick_up(hand);hand.global_position+=source.global_basis*Vector3(0.15,0.1,0.10)
	await create_timer(0.25).timeout
	check("held small corner changes larger triangle immediately",twin.large_points[2].distance_to(before)>0.4)
	var expected:Vector3=twin.CENTRE+source.to_local(point.global_position)*twin.ENLARGEMENT
	check("large corner is exact 3.3x source coordinate",twin.large_points[2].distance_to(expected)<0.001)
	point.let_go(hand,Vector3.ZERO,Vector3.ZERO);await create_timer(0.1).timeout
	check("release commits to the 5cm grid",source.placed_points[2].is_equal_approx(source.snap_position_to_grid(source.placed_points[2])))
	await snapshot("corner-moved",source.global_position+Vector3(-2.1,0.4,-1.6),twin.global_position+Vector3(-0.8,1.4,-1.2),71)
	panel.buttons.reset.pressed.emit();await create_timer(0.1).timeout
	var originals:Array=source.placed_points.duplicate()
	var pen:Node3D=source._grab_point
	hand.global_transform=pen.global_transform;pen.pick_up(hand)
	panel.buttons.new.pressed.emit()
	check("new face keeps the pen held and the old face",source._is_grabbed and source.current_path.is_empty() and source.completed_triangles.size()==1)
	for p in [originals[0],originals[1],source.to_global(Vector3(0,0.15,0.35))]:
		hand.global_position=p;await wait_physics();pen.action();await process_frame
	check("trigger reuses two existing corners and adds only one new point",source.placed_points.size()==4 and source.current_path.size()==3)
	pen.action();await create_timer(0.2).timeout
	check("repeated trigger at same point creates no duplicates",source.placed_points.size()==4 and source.current_path.size()==3)
	panel.buttons.close.pressed.emit();await create_timer(0.15).timeout
	check("close face adds a second face to both scales",source.completed_triangles.size()==2 and twin.triangle_count==2)
	check("two adjacent triangles share one edge",twin.edge_pairs.size()==5)
	pen.let_go(hand,Vector3.ZERO,Vector3.ZERO);await create_timer(0.1).timeout
	check("release does not place an unwanted extra corner",source.placed_points.size()==4 and source.completed_triangles.size()==2)
	await snapshot("added-face",source.global_position+Vector3(-2.1,0.4,-1.6),twin.global_position+Vector3(-0.8,1.4,-1.2),71)
	panel.buttons.fill.pressed.emit();await create_timer(0.1).timeout
	check("fill control hides surface while retaining edges",not twin.faces.visible and twin.edge_pairs.size()==5)
	panel.buttons.fill.pressed.emit()
	# Undo is bounded to the unfinished outline, so it cannot invalidate old faces.
	hand.global_transform=pen.global_transform;pen.pick_up(hand);panel.buttons.new.pressed.emit()
	hand.global_position=source.to_global(Vector3(0.5,0.3,0.25));await wait_physics();pen.action()
	panel.buttons.undo.pressed.emit();await process_frame
	check("undo removes unfinished point without damaging completed faces",source.placed_points.size()==4 and source.completed_triangles.size()==2 and source.current_path.is_empty())
	check("close rejects fewer than three points",not source.close_current_face())
	pen.let_go(hand,Vector3.ZERO,Vector3.ZERO);await wait_physics()
	panel.buttons.reset.pressed.emit();await create_timer(0.15).timeout
	check("restore returns one triangle at both scales",source.placed_points.size()==3 and twin.triangle_count==1)
	check("restore docks the released drawing point on the plinth",pen.position.is_equal_approx(source.MUSEUM_PEN_HOME))
	# A concave/folded loop still uses the same first-corner fan and SHIFT START.
	source.begin_new_outline()
	for p in [Vector3(-0.35,0,0.1),Vector3(0.35,0,0.1),Vector3(0.35,0.4,0.2),Vector3(-0.35,0.4,0.2)]:source._create_new_point(source.to_global(p))
	check("four-corner loop can close",source.close_current_face())
	await create_timer(0.1).timeout
	var old:Array=twin.edge_pairs.duplicate(true)
	panel.buttons.shift.pressed.emit();await create_timer(0.1).timeout
	check("shift start changes the diagonal while preserving three total faces",twin.edge_pairs!=old and twin.triangle_count==3)
	panel.buttons.reset.pressed.emit();await create_timer(0.1).timeout
	hand.queue_free()

func passage_checks(source: Node3D,twin: Node3D) -> void:
	var walker:=CharacterBody3D.new();walker.collision_layer=0;walker.collision_mask=1
	var collision:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	collision.shape=capsule;collision.position.y=0.8;walker.add_child(collision);root.add_child(walker)
	for x in [-2.2,2.2]:
		walker.global_position=source.global_position+Vector3(x,-source.global_position.y+0.025,-0.7)
		await physics_frame
		var result:=walker.move_and_collide(Vector3(0,0,twin.global_position.z-source.global_position.z+2))
		check("walking passage beside both plinths x="+str(x),result==null)
	walker.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
