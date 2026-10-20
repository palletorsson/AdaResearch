extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await point_light_trial()
	# Reuse the established contract: both hands, world/local readouts and retry.
	await coordinate_checks()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Mobile-rendered tower, real XRTools pickup with synthetic trackers. Physical headset not tested."},"\t"))
	quit(0 if failed.is_empty() else 1)

func point_light_trial() -> void:
	await start(true)
	game.checkpoint=2
	game.place_player(Vector3(0,-11.94,-1.8))
	await frames(45)
	game.atmosphere.animate_sky=false
	game.atmosphere.set_sky_time(180)
	var point: RigidBody3D=game.coordinate_point
	var identity := point.get_instance_id()
	var lamp: OmniLight3D=point.get_node("CarriedLight")
	var work: Node3D=game.building.content.props["2/coordinates-work-light"].get_node("Prefab")
	var surface: MeshInstance3D=point.get_node("MeshInstance3D")
	var finish := surface.material_override as StandardMaterial3D
	check("Point rests without casting the carried light",not lamp.visible and not point._is_held)
	check("Black glossy surface has no emission",finish.albedo_color.r<.02 and is_equal_approx(finish.roughness,.1) and not finish.emission_enabled and finish.clearcoat_enabled)
	check("One short-range shadowless carried light",lamp.omni_range<=4 and not lamp.shadow_enabled and point.find_children("CarriedLight","OmniLight3D",false,false).size()==1)
	check("Work light is reduced only for Coordinates",is_equal_approx(work.beam_energy,1.2) and is_equal_approx(work.get_node("WorkBeam").light_energy,1.2) and is_equal_approx(game.building.content.catalog.props.work_light.settings.beam_energy,7.5))
	var at := Vector3(1.7,-10.35,-1.8)
	var target := Vector3(-2.7,-11.2,2.3)
	work.beam_energy=7.5
	await photograph("before-work-light.png",at,target,80)
	work.beam_energy=1.2
	await photograph("resting.png",at,target,80)
	hand_at(right,point.global_position); await frames(15)
	right.set_input("grip",1.0); await frames(15)
	check("Real XR grip activates the existing point light",game.pickups[1].picked_up_object==point and lamp.is_visible_in_tree())
	var first := Vector3(-2.8,-11.05,1.0)
	hand_at(right,first); await frames(20)
	check("Light follows the same point over the basin",point.global_position.distance_to(first)<.05 and lamp.global_position.distance_to(point.global_position)<.001)
	check("Pickup preserves black material",surface.material_override==finish and not finish.emission_enabled)
	await photograph("held-west.png",at,target,80)
	lamp.hide()
	await photograph("held-west-light-off.png",at,target,80)
	lamp.show()
	await photograph("held-close.png",Vector3(-.8,-10.35,-.45),Vector3(-2.8,-11.05,1.0),64)
	var second := Vector3(-.6,-11.05,3.0)
	hand_at(right,second); await frames(20)
	check("Moving the hand moves the pool source in world space",lamp.global_position.distance_to(second)<.05 and lamp.global_position.distance_to(first)>2)
	await photograph("held-north.png",at,target,80)
	lamp.hide()
	await photograph("held-north-light-off.png",at,target,80)
	lamp.show()
	# The point stays live across streaming while held; no detached lamp is left.
	game.place_player(game.spawn_for(3)); await frames(25)
	check("Carried point light survives the floor transition",game.pickups[1].picked_up_object==point and lamp.is_visible_in_tree())
	right.set_input("grip",0.0); await frames(15)
	check("Release switches the light off",not lamp.visible and not point._is_held)
	game.place_player(game.spawn_for(2)); await frames(25)
	game._restore_point(); await frames(15)
	check("Returning keeps the same point and does not wake a released light",point.get_instance_id()==identity and not lamp.is_visible_in_tree() and point.global_transform.is_equal_approx(game.point_home))
	await photograph("released.png",at,target,80)
	# Move the authored holder: the component remains part of its real point.
	var host: Node3D=game.building.content.exhibits["2/held"]
	var original := host.transform
	host.position.x+=.4
	check("Editor placement carries the point and its attached light together",lamp.get_parent()==point and lamp.global_position.is_equal_approx(point.global_position))
	host.transform=original
	game.place_player(Vector3(0,-11.94,-1.8)); await frames(15)
	hand_at(left,point.global_position); await frames(15)
	left.set_input("grip",1.0); await frames(15)
	check("Left hand can activate the same light",game.pickups[0].picked_up_object==point and lamp.visible)
	right.set_input("by_button",true); await frames(100)
	right.set_input("by_button",false);left.set_input("grip",0.0);await frames(10)
	check("Retry leaves the lamp off and restores the point",not lamp.visible and point.global_transform.is_equal_approx(game.point_home) and game.pickups[0].picked_up_object==null)
	game.queue_free();await frames(15)
	for item in [head,left,right]: XRServer.remove_tracker(item)
