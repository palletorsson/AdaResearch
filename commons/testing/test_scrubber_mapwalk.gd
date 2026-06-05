extends SceneTree
## Headless proof that the biome scrubber walks map-to-map (not stage-to-stage).
##   godot --headless --xr-mode off --path . --script res://commons/testing/test_scrubber_mapwalk.gd

const Scr = preload("res://commons/biome_layers/BiomeScrubberDesktop3D.gd")

func _initialize() -> void:
	var eco = get_root().get_node_or_null("EcosystemManager")
	if eco and eco.has_method("get_ordered_map_list"):
		var ml: Array = eco.get_ordered_map_list()
		print("ORDERED total = ", ml.size())
		print("ORDERED first 8 = ", ml.slice(0, 8))
	else:
		print("FAIL: EcosystemManager.get_ordered_map_list missing")
		quit(1); return

	var s = Scr.new()
	get_root().add_child(s)            # runs _ready (builds accrual, map list)
	await process_frame
	await process_frame
	print("all_maps = ", s._all_maps.size(), "  start_index = ", s._map_index)

	s._goto_map(0)
	await process_frame
	var m0: String = s._loaded_map
	print("goto(0): map=%s idx=%d grid=%dx%d seq=%s" % [m0, s._map_index, s.grid_w, s.grid_d, s._map_seq])

	s._goto_map(1)
	await process_frame
	var m1: String = s._loaded_map
	print("goto(1): map=%s idx=%d grid=%dx%d seq=%s" % [m1, s._map_index, s.grid_w, s.grid_d, s._map_seq])

	# Step back.
	s._goto_map(0)
	await process_frame
	print("goto(0) again: map=%s idx=%d" % [s._loaded_map, s._map_index])

	var ok: bool = s._all_maps.size() > 0 and m0 != "" and m1 != "" and m0 != m1 and s._loaded_map == m0
	print("RESULT: ", "WALK OK" if ok else "WALK FAIL")
	quit(0 if ok else 1)
