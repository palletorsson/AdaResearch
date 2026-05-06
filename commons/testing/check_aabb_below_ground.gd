extends SceneTree

## Diagnostic script: loads each scene, computes AABB, reports if geometry sits below Y=0.
## Usage:
## godot_console --path . --xr-mode off --no-window --script res://commons/testing/check_aabb_below_ground.gd -- --list=<path_to_json>
## The JSON file should be an array of scene paths: ["res://path/to/scene.tscn", ...]
## Outputs a JSON report to stdout with scenes that have geometry below Y=0.

var _list_path: String = ""

func _initialize() -> void:
	for raw_arg in OS.get_cmdline_user_args():
		var arg: String = String(raw_arg).strip_edges()
		if arg.begins_with("--list="):
			_list_path = arg.substr(7)
	if _list_path.is_empty():
		push_error("check_aabb: --list=<path> required")
		quit(1)
		return
	call_deferred("_run_check")

func _run_check() -> void:
	# Load scene list
	var file := FileAccess.open(_list_path, FileAccess.READ)
	if not file:
		push_error("check_aabb: Cannot open %s" % _list_path)
		quit(1)
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("check_aabb: JSON parse error")
		quit(1)
		return
	var scene_paths: Array = json.data

	print("check_aabb: Checking %d scenes..." % scene_paths.size())

	var holder := Node3D.new()
	holder.name = "AABBChecker"
	root.add_child(holder)

	await process_frame

	var below_ground: Array = []
	var checked: int = 0

	for scene_path in scene_paths:
		if not ResourceLoader.exists(scene_path):
			continue

		var packed: PackedScene = ResourceLoader.load(scene_path)
		if not packed:
			continue

		var instance: Node = packed.instantiate()
		if not instance:
			continue

		holder.add_child(instance)

		# Give _ready() a frame
		await process_frame

		var target: Node3D = instance as Node3D if instance is Node3D else null
		if not target:
			for child in instance.get_children():
				if child is Node3D:
					target = child
					break

		if target:
			var aabb: AABB = _get_combined_aabb(target)
			# Filter hidden instances
			if aabb.size.y > 50.0:
				var cmin: float = max(aabb.position.y, -10.0)
				var cmax: float = min(aabb.position.y + aabb.size.y, 50.0)
				if cmax > cmin:
					aabb.position.y = cmin
					aabb.size.y = cmax - cmin
				else:
					aabb = AABB()

			var min_y: float = aabb.position.y
			var max_y: float = aabb.position.y + aabb.size.y

			if aabb.size.length() > 0.01 and min_y < -0.05:
				below_ground.append({
					"path": scene_path,
					"min_y": snapped(min_y, 0.01),
					"max_y": snapped(max_y, 0.01),
					"size_y": snapped(aabb.size.y, 0.01)
				})

		# Cleanup
		instance.queue_free()
		await process_frame

		checked += 1
		if checked % 100 == 0:
			print("check_aabb: %d / %d checked, %d below ground" % [checked, scene_paths.size(), below_ground.size()])

	# Report
	print("===RESULTS===")
	print("check_aabb: Checked %d scenes, %d have geometry below Y=0" % [checked, below_ground.size()])
	for entry in below_ground:
		print("  BELOW: %s  min_y=%.2f  max_y=%.2f" % [entry.path, entry.min_y, entry.max_y])

	# Save to file
	var out_file := FileAccess.open("user://aabb_check_results.json", FileAccess.WRITE)
	if out_file:
		out_file.store_string(JSON.stringify(below_ground, "  "))
		out_file.close()
		var abs_path: String = ProjectSettings.globalize_path("user://aabb_check_results.json")
		print("check_aabb: Results saved to %s" % abs_path)

	quit(0)

func _get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * child.visibility_aabb
			has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				sub_aabb = child.transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result
