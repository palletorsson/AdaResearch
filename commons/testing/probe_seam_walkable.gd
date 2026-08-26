extends SceneTree
## CAN YOU ACTUALLY WALK FROM ONE CHAPTER TO THE NEXT? (2026-08-26, Palle: "I
## got stuck between the primitive sequence and transformation in VR.")
##
## Every walk probe in this repo TELEPORTS - it sets position.z and lets the
## museum stream around it - so not one of them has ever tested whether a
## walker can reach the next hall on foot. The segments meet exactly at z, and
## that proves nothing: a wall with no door in it also meets exactly.
##
## This floods the museum's own walk map from a cell inside hall A and asks
## whether any cell of hall B is reached. Doors, chicanes and carved passages
## are cells in that map; a sealed join is not.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_seam_walkable.gd -- --metres=300

const OUT := "res://ada_run/seam_walkable.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var metres := float(_arg("metres", "300"))
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_sw_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("_force_patient", true)
	var ctl := FileAccess.open("res://ada_run/_trial_sw_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	# FLOOD AS YOU WALK, not once at the end. A repair may lay a catwalk, and a
	# catwalk's cells are pruned when its hall is freed — the geometry dies with
	# the hall, so the cells must too, or the walk map promises floor over an open
	# fire pool. Measured once at the end, every route through a hall the visitor
	# has already left reads as closed. The honest question is whether the walk
	# was open WHEN THE VISITOR WAS THERE.
	var player: Node3D = inst.get("_player") as Node3D
	var seen: Dictionary = {}
	var ever: Dictionary = {}
	var z := 0.0
	while z < metres:
		z += 3.0
		if player != null:
			player.position.z = z
		await create_timer(0.16).timeout
		var now: Dictionary = inst.get("_walk_cells")
		if now == null:
			continue
		var rid: Dictionary = inst.get("_ride_cells")
		var pass_now: Dictionary = now.duplicate()
		if rid != null:
			for r_v in rid:
				pass_now[r_v] = true
		for k_v in now:
			ever[k_v] = true
		var front: Array = []
		if seen.is_empty():
			var lo := Vector2i(0, 99999)
			for k2 in now:
				if (k2 as Vector2i).y < lo.y:
					lo = k2
			if lo.y == 99999:
				continue
			seen[lo] = true
			front.append(lo)
		else:
			front = seen.keys()
		var h := 0
		while h < front.size():
			var cur: Vector2i = front[h]
			h += 1
			for d_v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: Vector2i = cur + (d_v as Vector2i)
				if pass_now.has(nx) and not seen.has(nx):
					seen[nx] = true
					front.append(nx)

	var cells: Dictionary = ever
	var segs: Array = inst.get("_segments")
	# A RIDE IS A WAY ACROSS. Trans_Introduction walls both side lanes at its
	# ninth row: the ferry over the pool IS the crossing, so a flood that only
	# steps declares the whole transformation chapter unreachable and is wrong
	# about the museum rather than about the hall.
	var rides: Dictionary = inst.get("_ride_cells")
	if rides == null:
		rides = {}
	var passable: Dictionary = cells.duplicate()
	for r_v in rides:
		passable[r_v] = true
	var rep := "THE SEAMS, WALKED — %d cell(s) in the walk map\n\n" % cells.size()
	# every hall's z band, from the plan the museum actually built
	var bands: Array = []
	var built: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://ada_run/_trial_em_built.json"))
	if built is Dictionary:
		for s_v in ((built as Dictionary).get("segments", []) as Array):
			var sd: Dictionary = s_v
			bands.append({"name": String(sd.get("pearl", "?")),
				"z0": float(sd.get("z0", 0.0)), "z1": float(sd.get("z1", 0.0))})
	if bands.size() < 2:
		rep += "  FAIL fewer than two halls were built\n"
	else:
		var on_foot: int = 0
		for k9 in seen:
			if cells.has(k9):
				on_foot += 1
		rep += "  walked, hall by hall: %d of %d walk cell(s) reached, %d ferried

" % [
			on_foot, cells.size(), seen.size() - on_foot]
		rep += "  %-26s %7s %7s %9s\n" % ["hall", "cells", "reached", ""]
		var last_ok := true
		for b_v in bands:
			var b: Dictionary = b_v
			var tot := 0
			var got := 0
			for k2 in cells:
				var c2: Vector2i = k2
				if float(c2.y) >= float(b["z0"]) and float(c2.y) < float(b["z1"]):
					tot += 1
					if seen.has(c2):
						got += 1
			var mark := ""
			if tot > 0 and got == 0:
				mark = "  <-- SEALED: no way in on foot"
			elif tot > 0 and got < tot / 2:
				mark = "  <-- mostly cut off"
			if tot > 0 and got == 0 and last_ok:
				mark += "   THE STRANDING IS HERE"
			last_ok = (tot == 0 or got > 0)
			rep += "  %-26s %7d %7d%s\n" % [String(b["name"]).substr(0, 26), tot, got, mark]
		# DRAW THE FRONTIER. Counts say where the walk dies; a picture says why.
		# "." reachable on foot, "#" in the walk map but cut off, " " never walkable.
		var frontier: Dictionary = {}
		var sealed: Dictionary = {}
		var prev_live: Dictionary = {}
		for b_v2 in bands:
			var b2: Dictionary = b_v2
			var tot2 := 0
			var got2 := 0
			for k4 in cells:
				var c4: Vector2i = k4
				if float(c4.y) >= float(b2["z0"]) and float(c4.y) < float(b2["z1"]):
					tot2 += 1
					if seen.has(c4):
						got2 += 1
			if tot2 > 0 and got2 == 0 and frontier.is_empty() and not prev_live.is_empty():
				frontier = prev_live
				sealed = b2
			if tot2 > 0 and got2 > 0:
				prev_live = b2
			if false:
				frontier = b2
		if not frontier.is_empty():
			rep += "\n  the hall where the walk dies: %s (z %.0f..%.0f)\n" % [
				String(frontier["name"]), float(frontier["z0"]), float(frontier["z1"])]
			var zlo := maxi(int(frontier["z0"]), int(frontier["z1"]) - 14)
			var zhi := int(sealed["z1"]) if not sealed.is_empty() else int(frontier["z1"])
			for zz2 in range(zlo, mini(zhi, zlo + 30)):
				var line := "    %4d " % zz2
				for xx in range(-2, 22):
					var cc := Vector2i(xx, zz2)
					if not cells.has(cc):
						line += " "
					elif seen.has(cc):
						line += "."
					else:
						line += "#"
				rep += line + "\n"
			# THE CHOKE. The picture says where; this says WHICH CELL and WHOSE BODY.
			var zstop := -9999
			for k5 in seen:
				var c5: Vector2i = k5
				if c5.y >= int(frontier["z0"]) and c5.y < int(frontier["z1"]) and c5.y > zstop:
					zstop = c5.y
			var er: Dictionary = inst.get("_walk_erased")
			if er == null:
				er = {}
			rep += "\n  the choke: the walk reaches z=%d and stops.\n" % zstop
			for zz3 in range(zstop, zstop + 4):
				var line2 := "    z=%d  " % zz3
				for xx2 in range(-3, 23):
					var cc2 := Vector2i(xx2, zz3)
					if seen.has(cc2):
						line2 += "  %d:walked" % xx2
					elif cells.has(cc2):
						line2 += "  %d:CUT-OFF" % xx2
					elif er.has(cc2):
						line2 += "  %d:%s" % [xx2, String(er[cc2])]
				rep += line2 + "\n"
	# WHY A CELL LEFT THE WALK MAP. The museum erases cells with a reason -
	# _walk_erased[cell] = "seal:<token>" - so a severed route can name the body
	# that severed it instead of being a mystery.
	var erased: Dictionary = inst.get("_walk_erased")
	if erased != null and not erased.is_empty():
		var by: Dictionary = {}
		for k3 in erased:
			var why := String(erased[k3])
			by[why] = int(by.get(why, 0)) + 1
		var rows: Array = []
		for w in by:
			rows.append({"w": w, "n": int(by[w])})
		rows.sort_custom(func(a, b): return int(a["n"]) > int(b["n"]))
		rep += "\n  cells taken OUT of the walk map, and by what:\n"
		for i3 in range(mini(10, rows.size())):
			rep += "    %-46s %4d cell(s)\n" % [String((rows[i3] as Dictionary)["w"]), int((rows[i3] as Dictionary)["n"])]
		rep += "    %d cell(s) erased in total\n" % erased.size()
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
