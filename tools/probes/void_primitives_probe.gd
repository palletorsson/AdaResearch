extends "res://tools/probes/void_grid_probe.gd"
const MAPS := ["Point_Animatedcube","Primitives_Ignorance","Primitives_Godot","Primitives_Columns","Primitives_Profiles","Primitives_Portals","Primitives_Melencolia"]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	check("full sequence has fourteen tower floors",game.building.spec.levels.size()==14 and game.building.content.data.floors.size()==14)
	check("Grid still shares Trace",game.building.content.data.floors[4].map=="Point_Trace")
	for index in range(7,14):
		game.checkpoint=index
		game.place_player(game.spawn_for(index))
		var content: Node3D=game.building.content
		var timeout := Time.get_ticks_msec()+30000
		while not content.pending.is_empty() and Time.get_ticks_msec()<timeout:
			await frames(1)
		await frames(30)
		check("floor %d follows the authored spine"%index,content.data.floors[index].map==MAPS[index-7])
		check("floor %d finishes loading"%index,content.pending.is_empty() and content.exhibits.has("%d/hall"%index))
		if not content.exhibits.has("%d/hall"%index): continue
		var area: Node3D=content.exhibits["%d/hall"%index].get_node("Artifact")
		var y: float=game.building.spec.levels[index]
		check("floor %d supplies editor parts without the old timber assembly"%index,area.part_defaults.size()>5 and not area.part_defaults.has("TimberDescent"))
		check("floor %d has a safe checkpoint"%index,not ray(Vector3(-6,y+.5,4.5),Vector3(-6,y-.2,4.5)).is_empty())
		check("floor %d keeps shaft A open"%index,ray(Vector3(-10,y+.4,0),Vector3(-10,y-.2,0)).is_empty())
		var corner_z := 1.9 if index%2==1 else -1.9
		check("floor %d has a corner pad flush to its slab"%index,not ray(Vector3(11.7,y+.2,corner_z),Vector3(11.7,y-.2,corner_z)).is_empty())
		match index:
			7:
				var pair: Node3D=area.get_node("PairedCubeDiagonals")
				pair.cubes[0].handle_nodes[6].position.z+=.2
				await frames(4)
				check("cube carries the original paired-corner relation",pair.cubes[0].vertices==pair.cubes[1].vertices)
				pair.restore()
				check("cube carries twenty-four pickable box editions",area.get_node("BoxLibrary").items.size()==24)
			8:
				check("five original solids are pickable",area.get_node("Tetrahedron/Solid").has_method("pick_up") and area.has_node("Icosahedron/Solid"))
				var budget: Node3D=area.get_node("BudgetOfSmoothness")
				check("resolution comparison retains actual mesh counts",budget._counts.size()==4 and budget.discovery)
			9:
				check("engine vocabulary includes all eight original types",area.has_node("PrismMesh") and area.has_node("PointMesh") and area.has_node("TubeTrailMesh"))
			10:
				var count := 0
				for child in area.get_children():
					if child.has_meta("radial_segments"): count+=1
				check("all twenty-five column recipes return",count==25)
				check("controlled comparison uses 4 6 8 12 16 sides",area.has_node("Sides_04") and area.has_node("Sides_06") and area.has_node("Sides_08") and area.has_node("Sides_12") and area.has_node("Sides_16"))
			11:
				var count := 0
				for child in area.get_children():
					if str(child.name).begins_with("Profile_"): count+=1
				check("all six original glyph sweeps return",count==6)
			12:
				check("seven original progressively refined portals",area.get_node("RefinementPassage")._portals.size()==7)
				check("Zeno study keeps its manual controls",area.get_node("AchillesAndTortoise").discovery)
			13:
				check("Melencolia keeps the existing sculptural interpretation",area.has_node("MelencoliaEngraving"))
				check("known solids return for composition",area.has_node("CompositionSolid0") and area.has_node("CompositionSolid2") and area.get_node("ReturnToTheBoxLibrary").items.size()==24)
		# Exercise a reversible editor transform through the same native adapter.
		var movable: Node3D=area.get_child(0)
		var key := str(movable.name)
		var before: Vector3=movable.position
		area.apply_grid_config({"parts":{key:{"position":[before.x+.25,before.y,before.z]}}})
		check("floor %d applies editor placement"%index,is_equal_approx(movable.position.x,before.x+.25))
		area.apply_grid_config({"parts":{key:{"position":[before.x,before.y,before.z]}}})
		# Walk the authored route with the real desktop body and collision.
		var route: Array=content.data.floors[index].route
		game.place_player(Vector3(route[0].position[0],y+.06,route[0].position[1]))
		await frames(12)
		for j in range(1,route.size()):
			var stop: Array=route[j].position
			var reached: bool=await move_to(Vector3(stop[0],y,stop[1]))
			check("floor %d walk route %d"%[index,j],reached)
			if not reached: break
		if "--capture" in OS.get_cmdline_user_args():
			var at := Vector3(6.4,y+2.5,6.6)
			var target := Vector3(-1,y+1.3,-2)
			match index:
				7: at=Vector3(-13,y+1.8,3.8);target=Vector3(-16,y+1,0)
				8: at=Vector3(0,y+1.8,-.2);target=Vector3(0,y+1.2,-4.7)
				10: at=Vector3(2,y+1.8,0);target=Vector3(-3,y+2,-5.5)
				11: at=Vector3(0,y+1.8,0);target=Vector3(0,y+1.5,-4.2)
				12: at=Vector3(-16,y+1.8,7.8);target=Vector3(-16,y+2,-4)
				13: at=Vector3(-13,y+1.8,3.8);target=Vector3(-16,y+1.5,-1)
			await photograph("floor-%02d.png"%index,at,target)
			await photograph("floor-%02d-wide.png"%index,Vector3(6.4,y+2.5,6.6),Vector3(-1,y+1.3,-2))
		check("floor %d remains current and active"%index,game.floor_stream.focus==index and area.can_process())
		if index<13:
			var next_corner_z := 1.9 if (index+1)%2==1 else -1.9
			game.place_player(Vector3(13.4,y+.06,next_corner_z))
			await frames(10)
			var lower: bool=await move_to(Vector3(11.7,y-6,next_corner_z),true)
			check("floor %d descent reaches the next corner pad alive"%index,lower and game.checkpoint==index+1)
	game.checkpoint=13
	game.die("Complete primitives retry")
	await wait_for_recovery(0)
	check("last floor restart works at the new depth",game.checkpoint==13 and not game.recovering)
	game.queue_free()
	await frames(30)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot, real artifacts, loading, placements and checkpoint. Headset comfort remains a physical VR review."},"\t"))
	quit(0 if failed.is_empty() else 1)
