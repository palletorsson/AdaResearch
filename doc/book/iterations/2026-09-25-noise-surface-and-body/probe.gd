extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.8).timeout
	var host := find_scene("/noisesphere.gd")
	var study := find_scene("/warp_study.gd")
	check("enclosing study loaded", host != null and study != null)
	if host == null or study == null: return
	var shell: Node3D = study.enclosure
	check("museum retains original artifact scale",host.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("study is not shrunk to eighty percent",study.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("enclosing body keeps unit world scale",shell.global_basis.get_scale().is_equal_approx(Vector3.ONE))
	check("base sphere retains five metre radius",is_equal_approx(shell.RADIUS,5.0))
	check("enclosure begins in relief",study.relief)
	var physical_radius: float = shell.to_global(shell.CENTRE+Vector3.UP*shell.RADIUS).distance_to(shell.to_global(shell.CENTRE))
	check("world base radius is five metres",is_equal_approx(physical_radius,5.0))
	var space := hall.get_world_3d().direct_space_state
	var floor_ray := PhysicsRayQueryParameters3D.create(shell.to_global(Vector3(3.8,0.3,0.2)),shell.to_global(Vector3(3.8,-0.1,0.2)),1)
	var hit := space.intersect_ray(floor_ray)
	check("circular floor supports doorway approach",not hit.is_empty() and absf(shell.to_local(hit.position).y-shell.FLOOR_Y)<0.005)
	var door_rays: Array = []
	for side in [-1.0,1.0]:
		for height in [0.45,1.35,2.2]:
			var ray := PhysicsRayQueryParameters3D.create(shell.to_global(Vector3(side*4.4,height,0.2)),shell.to_global(Vector3(side*5.35,height,0.2)),1)
			var door_hit := space.intersect_ray(ray)
			door_rays.append({"side":side,"height":height,"hit":str(door_hit.get("collider","none")),"path":str(door_hit.collider.get_path()) if not door_hit.is_empty() else "none","position":xyz(shell.to_local(door_hit.position)) if not door_hit.is_empty() else []})
			check("shell doorway clear at side %s height %s"%[side,height],door_hit.is_empty())
	var eye := host.to_global(Vector3(-4,1.7,0.2))
	var target := host.to_global(Vector3(1.1,3.3,0.2))
	await snapshot("enclosing-relief",eye,target,95)
	var button_area: Node = study.get_node("Controls").find_child("Btn_2",true,false).get_node("InteractableAreaButton")
	button_area.button_pressed.emit(button_area)
	await physics_frame
	check("actual RELIEF button returns to skin",not study.relief)
	check("skin returns enclosing radius to five metres",is_equal_approx(shell.radius_at(Vector3.UP,study),5.0))
	await snapshot("enclosing-skin",eye,target,95)
	button_area.button_pressed.emit(button_area)
	check("comparison can return to relief",study.relief)
	observations={"door_rays":door_rays,"host_scale":xyz(host.global_basis.get_scale()),"study_scale":xyz(study.global_basis.get_scale()),"enclosure_scale":xyz(shell.global_basis.get_scale()),"world_base_radius_m":physical_radius,"doorway_top_m":shell.DOOR_TOP,"scope":"Current native museum, measured scale, doorway/floor rays, actual console signal, fixed-camera photographs. No headset/body traversal claim."}

func finish() -> void:
	var result := {"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Current native geometry, supplied control signal and fixed cameras; no headset or learner acceptance."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("NOISE ENCLOSURE ",checks.size()-failures.size(),"/",checks.size())
	quit(0 if failures.is_empty() else 1)
