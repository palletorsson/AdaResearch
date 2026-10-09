extends "res://doc/book/iterations/2026-09-23-moving-boundary/capture-probe.gd"
## Reuse the real hall and door study; add checks for the cleared observation floor.
func landing_checks() -> void:
	var hazards: Array[String] = []
	for n in hall.find_children("*", "Node", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("/DangerZone.gd"):
			hazards.append(str(n.get_path()))
	observations["remaining_hazards"] = hazards
	check("no legacy DangerZone instances remain in this hall", hazards.is_empty())
	await super.landing_checks()
	if not completed: return
	var origin := door.global_position - Vector3(7,0,29)
	observations["source_grid_origin"] = xyz(origin)
	for z in [11,12,13]:
		for x in [1,2,6,7,8,12,13]:
			var at := origin + Vector3(x,0,z)
			var hit := floor_at(at)
			check("cleared observation floor %d,%d" % [x,z], not hit.is_empty() and absf(hit.position.y-origin.y)<0.03)
	for entry in [[7,10,14,"middle route"],[1,11,13,"left observation strip"],[13,11,13,"right observation strip"]]:
		actor.global_position=origin+Vector3(entry[0],0.04,entry[1]);actor.velocity=Vector3.ZERO
		await create_timer(0.15).timeout
		await walk_to(origin+Vector3(entry[0],0,entry[2]),"walk cleared "+str(entry[3]))
	actor.global_position=Vector3(-100,0,-100);actor.velocity=Vector3.ZERO
	await snapshot("rotation-observation-floor",origin+Vector3(7,1.7,9.8),origin+Vector3(7,0.6,12.5),83)
