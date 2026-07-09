# probe_light_palettes.gd — deterministic check of the per-zone accent colors:
# build WallKit_LightStrip's walls headless and count accent-line materials by
# emission color. Expected: three distinct accents (amber / cyan / red).
#   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_light_palettes.gd
extends SceneTree

func _init() -> void:
	var f := FileAccess.open("res://commons/maps/WallKit_LightStrip/map_data.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var comp := GridWallSegmentsComponent.new()
	var gs := Node3D.new()
	root.add_child(gs)
	gs.add_child(comp)
	comp.initialize(gs, null, {})
	comp.generate_segments(data["layers"]["walls"], data["layers"]["structure"],
			data["settings"]["wall_segments"])
	var counts := {}
	var container: Node3D = gs.get_node_or_null("WallSegments")
	if container:
		for body in container.get_children():
			for child in body.get_children():
				if child is MeshInstance3D and child.material_override is StandardMaterial3D:
					var m: StandardMaterial3D = child.material_override
					if m.emission_enabled:
						var key := "%.2f,%.2f,%.2f" % [m.emission.r, m.emission.g, m.emission.b]
						counts[key] = counts.get(key, 0) + 1
	print("PROBE accent colors -> counts: ", counts)
	print("PROBE distinct accents: ", counts.size(), " (expect 3)")
	quit()
