extends "res://tools/probes/void_ignorance_route_probe.gd"
const ENDING := ["Primitives_Ignorance","Primitives_Columns","Primitives_Profiles","Primitives_Portals","Primitives_Melencolia"]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	for use_xr in [false,true]:
		await start(use_xr)
		var tag := "XR: " if use_xr else "Desktop: "
		var content: Node3D=game.building.content
		check(tag+"thirteen floors share one frame",game.building.spec.levels.size()==13 and content.data.floors.size()==13)
		check(tag+"Godot vocabulary is not a separate floor",content.data.floors.all(func(f): return f.map!="Primitives_Godot"))
		for index in range(8,13):
			game.checkpoint=index
			game.place_player(game.spawn_for(index))
			await frames(35)
			var timeout := Time.get_ticks_msec()+30000
			while not content.pending.is_empty() and Time.get_ticks_msec()<timeout: await frames(1)
			await frames(10)
			check(tag+"floor %d follows the retained order"%index,content.data.floors[index].map==ENDING[index-8])
			check(tag+"floor %d loads its original artifacts"%index,content.exhibits.has("%d/hall"%index) and content.pending.is_empty())
			var hall: Node3D=content.exhibits["%d/hall"%index].get_node("Artifact")
			check(tag+"floor %d retains editor parts"%index,hall.part_defaults.size()>5 and is_equal_approx(hall.global_position.y,float(game.building.spec.levels[index])))
			if index==11:
				check(tag+"Portals retains the long span",content.exhibits.has("11/sky-walk"))
			if index<12:
				var y: float=game.building.spec.levels[index]
				var next_z := 1.9 if (index+1)%2==1 else -1.9
				game.place_player(Vector3(13.4,y+.06,next_z));await frames(10)
				var reached := await move_to(Vector3(11.7,y-6,next_z),true,600)
				check(tag+"descent %d to %d lands alive and saves checkpoint"%[index,index+1],reached and game.checkpoint==index+1 and game.deaths==0)
		game.checkpoint=12
		var deaths_before: int=game.deaths
		game.die("Sequence renumbering check")
		await wait_for_recovery(deaths_before)
		check(tag+"last-floor restart uses Melencolia at its new depth",game.checkpoint==12 and not game.recovering and absf(game.body.global_position.y+72)<.2)
		await cleanup(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real desktop and synthetic XR movement, loading and restart; physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)
