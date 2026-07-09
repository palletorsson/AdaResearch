# probe_light_palettes.gd — deterministic check of the per-zone accent colors,
# now through the MARRIAGE 3 path: build WallKit_LightStrip's walls headless
# (settings passed properly so compiled wall_runs + the variant library are
# active) and count accent-line materials whose emission matches one of the
# map's DECLARED palette accents. Expected: all three (amber / cyan / red).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_light_palettes.gd
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://commons/maps/WallKit_LightStrip/map_data.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var settings: Dictionary = data.get("settings", {})
	var comp := GridWallSegmentsComponent.new()
	var gs := Node3D.new()
	root.add_child(gs)
	gs.add_child(comp)
	comp.initialize(gs, null, settings)
	comp.generate_segments(data["layers"]["walls"], data["layers"]["structure"],
			settings.get("wall_segments", {}))
	# the declared accents are the truth to match against
	var declared := {}
	for p in settings.get("wall_segments", {}).get("palettes", []):
		var a: Array = p.get("accent", [])
		if a.size() >= 3:
			declared["%.2f,%.2f,%.2f" % [a[0], a[1], a[2]]] = p.get("name", "?")
	var counts := {}
	var container: Node3D = gs.get_node_or_null("WallSegments")
	if container:
		for body in container.get_children():
			for child in body.get_children():
				if child is MeshInstance3D and child.material_override is StandardMaterial3D:
					var m: StandardMaterial3D = child.material_override
					if m.emission_enabled:
						var key := "%.2f,%.2f,%.2f" % [m.emission.r, m.emission.g, m.emission.b]
						if declared.has(key):
							counts[key] = counts.get(key, 0) + 1
	print("PROBE declared accents: ", declared)
	print("PROBE accent counts: ", counts)
	print("PROBE distinct accents: %d of %d declared (expect all)" % [counts.size(), declared.size()])
	quit()
