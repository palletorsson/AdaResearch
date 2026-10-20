extends "res://tools/probes/void_barriers_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	var host := Node3D.new()
	host.position=Vector3(80,0,0)
	game.add_child(host)
	for kind in ["blue_barricade","warning_tape","steel_barrier","traffic_cone","workbench"]:
		var definition: Dictionary = game.building.content.catalog.props[kind]
		var prop: Node3D = Dressing.build(game.building,host,{"id":kind,"kind":kind,"position":[0,0],"facing":90,"scale":1},definition)
		await frames(3)
		var bounds := prefab_bounds(prop)
		var size := Vector3(definition.size[0],definition.size[1],definition.size[2])
		check(kind+": real geometry fits placement envelope",bounds.size.length()>.2 and bounds.size.x<=size.x+.01 and bounds.size.y<=size.y+.01 and bounds.size.z<=size.z+.01)
		print("PROP_BOUNDS ",kind,": ",bounds)
		var y: float = {"blue_barricade":1.1,"warning_tape":1.1,"steel_barrier":.7,"traffic_cone":.35,"workbench":.9}[kind]
		var hit := ray(prop.to_global(Vector3(0,y,2)),prop.to_global(Vector3(0,y,-2)))
		check(kind+": collision follows rotated placement",not hit.is_empty() and (hit.collider==prop or prop.is_ancestor_of(hit.collider)))
		if kind in ["blue_barricade","warning_tape"]:
			check(kind+": sign reads DO NOT CROSS",prop.get_node("Prefab").legend_text=="DO NOT CROSS")
		prop.free()
	var directions: Node3D = load("res://commons/void/lines_area.gd").new()
	directions.area="directions"
	host.add_child(directions)
	check("Point Lines and its copied barricades use DO NOT CROSS",directions.get_node("PoliceBarricade").legend_text=="DO NOT CROSS" and directions.get_node("PoliceBarricade_2").legend_text=="DO NOT CROSS")
	host.free()
	game.queue_free()
	await frames(5)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	quit(0 if failed.is_empty() else 1)
