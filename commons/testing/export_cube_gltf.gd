# export_cube_gltf.gd â€” export the five sim-cube families (CubeWrapperLibrary)
# as .glb for the Three.js map-viewer + galleries. Run headless:
#   godot --path . --xr-mode off --no-window --script res://commons/testing/export_cube_gltf.gd
# Output: external public/cube-gltf/<family>.glb + manifest.json; web junction serves it.
extends SceneTree
const ModelStorage = preload("res://tools/generated_storage.gd")

const CubeLib := preload("res://commons/grid/CubeWrapperLibrary.gd")

func _init() -> void:
	var lib := CubeLib.new()
	var out_dir := ModelStorage.public_directory("cube-gltf")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var manifest := []
	for fam in CubeLib.FAMILIES:
		var node: Node3D = lib.build(fam)
		node.name = "cube_" + fam
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_scene(node, state) != OK:
			print("EXPORT FAIL append ", fam)
			continue
		var path := out_dir.path_join(fam + ".glb")
		if ModelStorage.write_gltf(doc,state,path) != OK:
			print("EXPORT FAIL write ", fam)
			continue
		manifest.append({"name": fam, "file": fam + ".glb"})
		print("exported ", path)
		node.free()
	var f := FileAccess.open(out_dir.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"size_m": CubeLib.S, "families": manifest}, " "))
	f.close()
	print("manifest: %d cube families" % manifest.size())
	quit()
