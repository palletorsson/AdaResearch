extends "res://tools/probes/ignorance_moon_torus.gd"

func station_checks(station: Node3D) -> void:
	var point: Node3D = station.point
	var guide: MeshInstance3D = station.get_node("CatalystGuide")
	check("point meets the entrance side of the court",point.position.is_equal_approx(Vector3(-3.6,1.45,-3.5)))
	check("instructions are beside the actual point",guide.position.distance_to(point.position)<1.1)
	var from := station.to_global(Vector3(-3.6,1.6,-4.2))
	var ray := PhysicsRayQueryParameters3D.create(from,point.global_position,5)
	var hit := station.get_world_3d().direct_space_state.intersect_ray(ray)
	check("front approach reaches the sphere without an intervening collider",hit.get("collider")==point)
	await snapshot("catalyst-in-the-court",station.to_global(Vector3(-5.4,1.7,-6.2)),station.to_global(Vector3(-0.4,2.6,-0.7)),84)
	await snapshot("catalyst-within-reach",station.to_global(Vector3(-4.1,1.65,-5.7)),station.to_global(Vector3(-4.1,1.8,-3.2)),62)
	await super.station_checks(station)
