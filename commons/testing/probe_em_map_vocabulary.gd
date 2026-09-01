extends SceneTree
## Three artifacts asked "which hall am I in?" and only ever accepted ONE answer:
## the meta named map_name, which a grid map stamps. The endless museum stamps
## em_map on the hall segment (endless_museum.gd:7611) and never map_name -- so
## in the museum, which is where these halls are actually walked, all three
## resolved nothing. Every one of them failed SILENTLY, in its own way:
##
##   street_talker          built no boards ("unruled room" is a real outcome)
##   code_evolution_screen  fell through to Method 3 and showed the WRONG map
##   info_board             push_error + fallback panel
##
## The discriminating trick below: WaveFunctions_Unit_Circle is alphabetically
## LAST of the 21 maps carrying an evolution.json, and Method 3's fallback scan
## walks the directory in order. So resolving to it proves the ancestor walk
## did the work -- the blind fallback would have returned CA_GameOfLife.

const LATE := "WaveFunctions_Unit_Circle"
const FIRST := "CA_GameOfLife"

func _init() -> void:
	var fails := 0

	# ---------- code_evolution_screen ----------
	var ces := load("res://commons/artifacts/code_evolution_screen/code_evolution_screen.tscn")
	if ces == null:
		print("  FAIL could not load code_evolution_screen.tscn"); fails += 1
	else:
		# POSITIVE: a museum hall segment, em_map only
		var hall := Node3D.new()
		hall.set_meta("em_map", LATE)
		get_root().add_child(hall)
		var s = ces.instantiate()
		hall.add_child(s)
		await process_frame
		await process_frame
		var got: String = str(s.evolution_path)
		print("em_map=%s -> %s" % [LATE, got])
		if not got.contains(LATE):
			print("  FAIL the walk did not read em_map (fallback scan won)"); fails += 1

		# NEGATIVE: an empty em_map must not be believed
		var hall2 := Node3D.new()
		hall2.set_meta("em_map", "")
		get_root().add_child(hall2)
		var s2 = ces.instantiate()
		hall2.add_child(s2)
		await process_frame
		await process_frame
		var got2: String = str(s2.evolution_path)
		print("em_map=\"\"  -> %s" % got2)
		if got2.contains(LATE):
			print("  FAIL an empty em_map resolved to the late map anyway"); fails += 1

		# NEGATIVE: map_name still wins where it is set (no regression)
		var hall3 := Node3D.new()
		hall3.set_meta("map_name", LATE)
		get_root().add_child(hall3)
		var s3 = ces.instantiate()
		hall3.add_child(s3)
		await process_frame
		await process_frame
		print("map_name=%s -> %s" % [LATE, str(s3.evolution_path)])
		if not str(s3.evolution_path).contains(LATE):
			print("  FAIL the original map_name path regressed"); fails += 1

	# ---------- info_board: the helper, tested directly ----------
	# The scene itself names GameManager, so a SceneTree probe cannot always
	# instantiate it. Test the resolution rule where it lives instead.
	var ib_src := FileAccess.open("res://commons/scenes/mapobjects/info_board.gd",
		FileAccess.READ)
	var ib := ib_src.get_as_text()
	ib_src.close()
	# RUNTIME first, if the script will load here at all -- a source-shape check
	# proves the text, not the behaviour.
	var IB = load("res://commons/scenes/mapobjects/info_board.gd")
	if IB != null:
		var probe_node = IB.new()
		var hall4 := Node3D.new()
		hall4.set_meta("em_map", LATE)
		get_root().add_child(hall4)
		hall4.add_child(probe_node)
		var r: String = str(probe_node.call("_resolve_map_from_tree"))
		print("")
		print("info_board _resolve_map_from_tree under em_map=%s -> '%s'" % [LATE, r])
		if r != LATE:
			print("  FAIL the helper did not read em_map at runtime"); fails += 1
		# NEGATIVE: nothing above it resolves to nothing
		var lone = IB.new()
		var bare := Node3D.new()
		get_root().add_child(bare)
		bare.add_child(lone)
		var r2: String = str(lone.call("_resolve_map_from_tree"))
		print("info_board with nothing above it -> '%s' (must be empty)" % r2)
		if r2 != "":
			print("  FAIL it invented a hall"); fails += 1
	else:
		print("info_board script would not load in a SceneTree probe -- source check only")

	var checks := {
		"has the helper": ib.contains("func _resolve_map_from_tree"),
		"helper reads em_map": ib.contains("\"map_name\", \"em_map\""),
		"no grid system is no longer fatal": not ib.contains("push_error(\"InfoBoard: No grid system found!\")"),
		"still falls back when nothing resolves": ib.contains("_show_fallback_info()"),
	}
	print("")
	for k in checks:
		print("info_board: %-38s %s" % [k, checks[k]])
		if not checks[k]:
			print("  FAIL " + k); fails += 1

	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
