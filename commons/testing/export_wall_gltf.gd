# export_wall_gltf.gd — export the ONE wall library (WallVariantLibrary.gd)
# as .glb variants for the Three.js map-viewer. Run headless:
#   godot --path . --xr-mode off --no-window --script res://commons/testing/export_wall_gltf.gd
# Output: ../ada_encyclopedia/public/wall-gltf/<name>.glb + manifest.json
# MARRIAGE 3: the same builders GridWallSegmentsComponent uses at map load —
# a wall looks identical in headset and browser because it IS identical.
extends SceneTree

const WallLib := preload("res://commons/grid/WallVariantLibrary.gd")

func _init() -> void:
	var lib := WallLib.new()
	var out_dir := ProjectSettings.globalize_path("res://").path_join("../ada_encyclopedia/public/wall-gltf")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var manifest := []
	for vname in WallLib.VARIANTS:
		var node: Node3D = lib.build(vname)
		node.name = "wall_" + vname
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_scene(node, state)
		if err != OK:
			print("EXPORT FAIL append %s: %d" % [vname, err])
			continue
		var path := out_dir.path_join(vname + ".glb")
		err = doc.write_to_filesystem(state, path)
		if err != OK:
			print("EXPORT FAIL write %s: %d" % [vname, err])
			continue
		manifest.append({"name": vname, "file": vname + ".glb",
			"weight": WallLib.WEIGHTS.get(vname, 1)})
		print("exported ", path)
		node.free()
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"length": WallLib.L, "height": WallLib.H,
		"thickness": WallLib.T, "variants": manifest}, " "))
	f.close()
	print("manifest: %d variants (from WallVariantLibrary)" % manifest.size())
	quit()
