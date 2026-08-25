extends SceneTree
## DOES THE BEAM BITE (2026-08-25, Palle: "I am not killed by the laser").
## Stand a lethal laser in a museum hall, put the walker in its beam past arm's
## length, and count the deaths. The chain is long — _is_player_body, the
## lethal flag, the distance floor, the em_lethal group, the end scene — so
## this asserts the END of it, which is the walker being somewhere else.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_laser_kill.gd

const OUT := "res://ada_run/laser_kill.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_lk_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_lk_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var rep := "THE BEAM\n"
	var player: Node3D = inst.get("_player") as Node3D
	rep += "  walker: name=%s groups=%s layer=%d\n" % [player.name, str(player.get_groups()),
		(player as CollisionObject3D).collision_layer]
	# a laser on the deck, armed the way the museum arms one
	var lm: Node3D = (load("res://commons/primitives/laser_measure/grab_laser_measure.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(lm)
	var armed: int = int(inst.call("_arm_laser", lm))
	rep += "  armed %d node(s)\n" % armed
	await create_timer(0.5).timeout
	# put the walker four metres down the beam: past lethal_min_distance, and
	# far enough that a held tool's own arm's-length hit is not what fires
	lm.rotation = Vector3.ZERO
	var ray: RayCast3D = lm.find_child("RayCast3D", true, false) as RayCast3D
	# THE RAY'S OWN AXIS, not the root's: it fires along its local -Z, and the
	# scene rotates the barrel 90 degrees about Y, so the root's forward is not
	# the beam's. Then stand the laser 1.5 m from the walker AIMING AT IT —
	# far enough to clear lethal_min_distance, close enough that no wall of
	# the hall gets between them (the first two runs measured a wall).
	var fwd: Vector3 = -(ray.global_transform.basis.z if ray != null else lm.global_transform.basis.z)
	player.position = Vector3(5.5, 0.0, 8.0)
	lm.global_position = player.position + Vector3(0.0, 1.0, 0.0) - fwd * 1.5
	await create_timer(0.4).timeout
	rep += "  beam axis %s, laser at %s, walker at %s (%.1f m)
" % [
		str(fwd.snapped(Vector3(0.01, 0.01, 0.01))), str(lm.global_position),
		str(player.position), lm.global_position.distance_to(player.position)]
	# the baseline AFTER the settle is already too late: the beam kills within
	# a frame of the walker entering it, so d0 was read as 1 and the probe
	# reported FAIL over a working kill
	var d0: int = 0
	var p0: Vector3 = player.position
	for i in range(20):
		await create_timer(0.35).timeout
		if i == 2 and ray != null:
			rep += "  ray hits: %s
" % (String((ray.get_collider() as Node).name)
				if ray.is_colliding() and ray.get_collider() != null else "nothing")
		if int(inst.get("_deaths")) > d0:
			break
	# the walker is moved BEHIND THE BLACK, three seconds into the end scene —
	# measuring the moment the counter ticks reads zero every time
	await create_timer(4.0).timeout
	var d1: int = int(inst.get("_deaths"))
	rep += "  deaths %d -> %d, walker moved %.1f m\n" % [d0, d1, player.position.distance_to(p0)]
	rep += "  %s\n" % ("KILLED" if d1 > d0 else "FAIL the beam passed through")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
