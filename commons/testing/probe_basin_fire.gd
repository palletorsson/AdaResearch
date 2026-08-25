extends SceneTree
## FIRE AT THE BOTTOM, AND A WAY BACK (2026-08-24, Palle: "at every basin pool
## place deadly fire to the bottom, if the player falls reset to save point.
## Create save points after each map"). Asks the built hall three things: is
## there fire, is there a save point, and does falling in put you back on it.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_basin_fire.gd -- --map=Trans_Introduction

const OUT := "res://ada_run/basin_fire.txt"

var _seen := 0


func _saw(_b: Node3D) -> void:
	_seen += 1


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var map_name := _arg("map", "Trans_Introduction")
	var chapter := _arg("chapter", "transformation")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_bf_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", map_name)
	var ctl := FileAccess.open("res://ada_run/_trial_bf_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "first_map": map_name,
		"dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(2.5).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var rep := "BASIN FIRE — %s\n" % map_name
	var segs: Array = inst.get("_segments")
	var seg: Node3D = null
	var z0 := 0.0
	for s_v in segs:
		var s: Dictionary = s_v
		if String(s.get("pearl", "")).to_lower() == map_name.replace("_", " ").to_lower():
			seg = s.get("node")
			z0 = float(s.get("z0", 0.0))
	if seg == null:
		rep += "  FAIL the hall never built\n"
	else:
		var cells := 0
		var lo := 99.0
		for a_v in seg.find_children("BasinFire", "Area3D", true, false):
			var a := a_v as Area3D
			for c in a.get_children():
				if c is CollisionShape3D:
					cells += 1
					lo = minf(lo, (c as CollisionShape3D).position.y)
		rep += "  fire: %d cell(s), lowest shape at y %.2f\n" % [cells, lo]
		var glow := 0
		for m_v in seg.find_children("*", "MeshInstance3D", true, false):
			var mi := m_v as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is StandardMaterial3D and (mat as StandardMaterial3D).emission_enabled \
					and (mat as StandardMaterial3D).emission.r > 0.9 \
					and (mat as StandardMaterial3D).emission.b < 0.2:
				glow += 1
		rep += "  glowing beds: %d\n" % glow

		var sps: Array = inst.get("_save_points")
		rep += "  save points: %d\n" % sps.size()
		for sp_v in sps:
			var sp: Dictionary = sp_v
			rep += "    z %6.1f  ->  %s\n" % [float(sp.get("z", 0.0)), str(sp.get("pos"))]

		# THE FALL: stand the walker in the fire and let physics run
		var player: Node3D = inst.get("_player") as Node3D
		if player == null or cells == 0:
			rep += "  SKIP no player or no fire\n"
		else:
			var a0: Area3D = seg.find_children("BasinFire", "Area3D", true, false)[0] as Area3D
			var sh: CollisionShape3D = null
			for c2 in a0.get_children():
				if c2 is CollisionShape3D:
					sh = c2 as CollisionShape3D
					break
			var target: Vector3 = sh.global_position
			player.position = target + Vector3(0.0, 0.3, 0.0)
			rep += "  dropped the walker at %s\n" % str(player.position)
			rep += "  walker: %s  area mask %d  monitoring %s\n" % [
				player.get_class(), a0.collision_mask, str(a0.monitoring)]
			var bodies := 0
			for _k in range(4):
				await physics_frame
				bodies = maxi(bodies, a0.get_overlapping_bodies().size())
			rep += "  area sees %d body(ies)\n" % bodies
			for b_v in a0.get_overlapping_bodies():
				rep += "    overlapping %s (%s)\n" % [String((b_v as Node).name), (b_v as Node).get_class()]
			rep += "  _player is %s #%d\n" % [String(player.name), player.get_instance_id()]
			rep += "  body_entered has %d connection(s)\n" % a0.body_entered.get_connections().size()
			# LEAVE and RE-ENTER: does the signal fire at all?
			_seen = 0
			a0.body_entered.connect(_saw)
			player.position = Vector3(player.position.x, 3.0, player.position.z - 6.0)
			for _j in range(6):
				await physics_frame
			player.position = target + Vector3(0.0, 0.3, 0.0)
			for _j2 in range(6):
				await physics_frame
			rep += "  re-entry fired the signal %d time(s)\n" % _seen
			# THE DEATH IS A CINEMATIC — splatter, veil, one line, and the walker
			# is moved BEHIND the black at about two seconds. Thirty physics
			# frames is half a second, which reads a working death as a failure.
			var waited := 0.0
			for _i in range(28):
				await create_timer(0.25).timeout
				waited += 0.25
				if player.position.distance_to(target) > 2.0:
					break
			rep += "  after %.2f s: %s\n" % [waited, str(player.position)]
			var moved: float = player.position.distance_to(target)
			rep += "  %s (moved %.1f m from the fire)\n" % ["BURNED — put back" if moved > 2.0 else "FAIL still in the pool", moved]
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
