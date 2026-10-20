extends "res://tools/probes/void_triangle_probe.gd"
const Dressing := preload("res://commons/void/set_dressing.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	game.place_player(game.spawn_for(7)); await frames(45)
	# Temporary specimens only: this never writes the user's rooms.json.
	var host := Node3D.new(); host.position=Vector3(80,0,0); game.add_child(host)
	for kind in ["striped_barricade","chainlink_panel"]:
		var definition: Dictionary = game.building.content.catalog.props[kind]
		var prop: Node3D = Dressing.build(game.building,host,{"id":kind,"kind":kind,"position":[0,0],"facing":0,"scale":1},definition)
		await frames(3)
		var bounds := prefab_bounds(prop)
		var size := Vector3(definition.size[0],definition.size[1],definition.size[2])
		check(kind+": actual geometry fits editor envelope",bounds.size.x>.5 and bounds.size.y>1 and bounds.size.x<=size.x+.005 and bounds.size.y<=size.y+.005 and bounds.size.z<=size.z+.005 and bounds.position.y>=-.01)
		var draws := 0
		var triangles := 0
		for node in prop.find_children("*","MeshInstance3D",true,false):
			if node.mesh!=null:
				draws+=node.mesh.get_surface_count()
				for surface in node.mesh.get_surface_count():
					var indices: int = node.mesh.surface_get_array_index_len(surface)
					triangles+=(indices if indices>0 else node.mesh.surface_get_array_len(surface))/3
		check(kind+": batched into at most five surfaces",draws<=5 and draws>0)
		print("PREFAB_METRICS ",kind," surfaces=",draws," triangles=",triangles," bounds=",bounds)
		var y := .87 if kind=="striped_barricade" else 1.8
		var hit := ray(prop.to_global(Vector3(0,y,1)),prop.to_global(Vector3(0,y,-1)))
		check(kind+": physical barrier blocks passage",not hit.is_empty() and prop.is_ancestor_of(hit.collider))
		var gap := ray(prop.to_global(Vector3(0,.20,1)),prop.to_global(Vector3(0,.20,-1)))
		check(kind+": collision follows the intended opening",gap.is_empty() if kind=="striped_barricade" else not gap.is_empty())
		var outside := ray(prop.to_global(Vector3(size.x*.5+.2,1,1)),prop.to_global(Vector3(size.x*.5+.2,1,-1)))
		check(kind+": no invisible collision past its sides",outside.is_empty())
		var copied: Node3D = Dressing.build(game.building,host,{"id":kind+"-copy","kind":kind,"position":[5,0],"facing":90,"scale":1.25},definition)
		await frames(3)
		var copy_hit := ray(copied.to_global(Vector3(0,y,1)),copied.to_global(Vector3(0,y,-1)))
		check(kind+": moved rotated scaled copy retains collision",not copy_hit.is_empty() and copied.is_ancestor_of(copy_hit.collider) and copied.get_node("Prefab")!=prop.get_node("Prefab"))
		copied.free(); prop.free()
	host.free()
	if "--capture" in OS.get_cmdline_user_args():
		game._set_enabled(false)
		game.atmosphere.animate_sky=false; game.atmosphere.set_sky_time(180)
		var floor_root: Node3D = game.building.content.roots[7]
		Dressing.build(game.building,floor_root,{"id":"preview-fence","kind":"chainlink_panel","position":[1,5.4],"facing":0,"scale":1},game.building.content.catalog.props.chainlink_panel)
		Dressing.build(game.building,floor_root,{"id":"preview-barricade","kind":"striped_barricade","position":[-1.6,5.8],"facing":20,"scale":1},game.building.content.catalog.props.striped_barricade)
		var light := OmniLight3D.new(); light.position=Vector3(-2,-39.7,8.2);light.omni_range=8;light.light_energy=3;light.light_color=Color("ffead1");game.add_child(light)
		await photograph("barriers-in-tower.png",Vector3(-4,-40.25,9.5),Vector3(.1,-40.8,5.4),62)
		await photograph("striped-barricade.png",Vector3(-3.0,-41.0,7.6),Vector3(-1.6,-41.45,5.8),48)
		await photograph("chainlink-panel.png",Vector3(-1.0,-40.35,9.3),Vector3(1,-40.6,5.4),58)
	game.queue_free();await frames(6)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot geometry and collision, catalog placement/copy/rotation/scale; temporary specimens on Cube floor for screenshots."},"\t"))
	quit(0 if failed.is_empty() else 1)

func prefab_bounds(host: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for node in host.find_children("*","MeshInstance3D",true,false):
		# Batch construction leaves empty mesh nodes holding their colliders.
		if node.mesh == null: continue
		var bounds: AABB = (host.global_transform.affine_inverse()*node.global_transform)*node.mesh.get_aabb()
		result = bounds if first else result.merge(bounds)
		first = false
	return result
