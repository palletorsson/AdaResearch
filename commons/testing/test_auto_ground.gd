extends SceneTree

## Quick test: instantiate a few known artifacts, verify auto-ground shifts them up.
## Usage: godot_console --path . --xr-mode off --no-window --script res://commons/testing/test_auto_ground.gd

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("=== Auto-ground test ===")

	var holder := Node3D.new()
	holder.name = "TestHolder"
	root.add_child(holder)
	await process_frame

	# Test artifacts: scene path, expected behavior
	var test_cases: Array = [
		# [scene_path, description, expected_grounded]
		["res://commons/primitives/cubes/cube_scene.tscn", "cube (centered, should shift up ~0.5)", true],
		["res://commons/primitives/capsule/capsule.tscn", "capsule (centered, should shift up ~0.5)", true],
		["res://commons/primitives/sphere/light_sphere.tscn", "light_sphere (40m env sphere, skip or cap)", false],
	]

	for test in test_cases:
		var scene_path: String = test[0]
		var desc: String = test[1]
		var expect_ground: bool = test[2]

		print("\n--- Test: %s ---" % desc)
		print("  Scene: %s" % scene_path)

		if not ResourceLoader.exists(scene_path):
			print("  SKIP: Scene not found")
			continue

		var packed: PackedScene = ResourceLoader.load(scene_path)
		if not packed:
			print("  SKIP: Failed to load")
			continue

		var instance: Node = packed.instantiate()
		if not instance:
			print("  SKIP: Failed to instantiate")
			continue

		holder.add_child(instance)
		await process_frame

		# Compute AABB before any grounding
		var target: Node3D = instance as Node3D if instance is Node3D else null
		if not target:
			for child in instance.get_children():
				if child is Node3D:
					target = child
					break

		if target:
			var aabb: AABB = _get_combined_aabb(target)
			# Apply the same clamping as auto-ground
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
			print("  AABB: min_y=%.3f max_y=%.3f size_y=%.3f" % [min_y, max_y, aabb.size.y])
			print("  Position.y = %.3f" % target.position.y)

			if min_y < -0.01:
				var correction: float = abs(min_y)
				if correction > 5.0:
					print("  RESULT: Would be CAPPED (correction %.2f > 5.0)" % correction)
				else:
					print("  RESULT: Should be auto-grounded (shift up %.3f)" % correction)
			else:
				print("  RESULT: Already grounded (min_y >= -0.01)")
		else:
			print("  SKIP: No Node3D target found")

		instance.queue_free()
		await process_frame

	print("\n=== Auto-ground test complete ===")
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
