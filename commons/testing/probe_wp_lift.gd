extends SceneTree
## Where does a walkable prism actually stand?
##
## `wp` grew a third parameter — a hand lift in cube units — because the wedge in
## Trans_Translation at (2,8) sat half a cube below the step it was meant to bridge
## and the token had no way to say so. This probe is the evidence for both halves of
## that change: run it against a map whose wp carries no third parameter and the Y
## must be unchanged (the gate); run it against one that does and the Y must move by
## exactly that many cubes (the bite).
##
##   godot --path . --headless --xr-mode off \
##       --script res://commons/testing/probe_wp_lift.gd -- --map=Trans_Translation

const GridSystemScene := "res://commons/scenes/grid_system.tscn"


func _initialize() -> void:
	var map_name := "Trans_Translation"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			map_name = a.split("=", 1)[1]

	var path := "res://commons/maps/%s/map_data.json" % map_name
	if not FileAccess.file_exists(path):
		print("probe_wp_lift: no map_data.json for '%s'" % map_name)
		quit(2)
		return

	# Read the token straight from the map rather than from the built tree: the
	# question is what the DATA asks for, and what the loader would do with it.
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if not (parsed is Dictionary):
		print("probe_wp_lift: map_data.json did not parse")
		quit(2)
		return

	var d: Dictionary = parsed
	var layers: Dictionary = d.get("layers", d)
	var util: Variant = layers.get("utilities", [])
	var struct: Variant = layers.get("structure", [])
	if not (util is Array) or not (struct is Array):
		print("probe_wp_lift: no utilities/structure layers")
		quit(2)
		return

	var found := 0
	for z in range((util as Array).size()):
		var row: Variant = (util as Array)[z]
		if not (row is Array):
			continue
		for x in range((row as Array).size()):
			var tok := str((row as Array)[x])
			if not tok.begins_with("wp"):
				continue
			found += 1
			var parts := tok.split(":")
			var yaw := "(none — no rotation applied)"
			if parts.size() > 1:
				yaw = parts[1]
			# parameter 1 is DUAL: a number is the lift, anything else is a colour.
			# It cannot be parameter 2 with an empty 1 — parse_utility_cell drops
			# empty parts, so a hole in the list collapses and the lift would land
			# in the colour slot (which is exactly how this shipped broken once).
			var lift := 0.0
			if parts.size() > 2 and str(parts[2]).strip_edges().is_valid_float():
				lift = str(parts[2]).strip_edges().to_float()

			var cell_h := 0
			if z < (struct as Array).size():
				var srow: Variant = (struct as Array)[z]
				if srow is Array and x < (srow as Array).size():
					cell_h = int(str((srow as Array)[x]).strip_edges())

			# what the loader will do: seat on the cube top, + half a cube (the
			# derived bridge), + the hand lift.
			var base_y := float(cell_h)
			var seated := base_y + 0.5
			print("wp at (x=%d, z=%d)  token '%s'" % [x, z, tok])
			print("    yaw           %s" % yaw)
			print("    cell height   %d" % cell_h)
			print("    seat          %.2f  (cell top %.2f + derived 0.50)" % [seated, base_y])
			print("    hand lift     %.2f" % lift)
			print("    PRISM BASE    %.2f   peak %.2f" % [seated + lift - 0.5, seated + lift + 0.5])

	if found == 0:
		print("probe_wp_lift: no wp token in '%s'" % map_name)
	print("\n%d wedge(s) in %s" % [found, map_name])
	quit(0)
