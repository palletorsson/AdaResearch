extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	AudioServer.set_bus_mute(0,true);museum.call("flush_stamps");await create_timer(0.5).timeout
	var bench:=find_scene("/prefab_disorder.gd");var ghost: Node3D=bench.ghost;ghost.auto_enabled=false
	ghost.actor.position=Vector3(0,0,2.15)
	ghost.continue_to_next()
	for i in 2000:
		await process_frame
		if not ghost.walk.requested and not ghost.walk.walking: break
	check("safe approach reaches ledger",ghost.walk.receipt.get("status")=="arrived")
	observations.walk=ghost.walk.receipt
	observations.samples=[]
	for at in [Vector3(13.5,0,1.35),Vector3(13.5,0,2),Vector3(11.5,0,2),Vector3(10,0,2),Vector3(8.5,0,2),Vector3(10,0,1.8),Vector3(10,0,2.2),Vector3(12.65,0,1.3),Vector3(12.65,0,1.65),Vector3(12.65,0,2.1)]:
		observations.samples.append(ghost.walk.inspect_at(at))
