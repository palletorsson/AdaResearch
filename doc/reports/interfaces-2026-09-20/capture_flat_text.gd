extends "res://commons/testing/test_console_allcontrols.gd"
## Reuse the existing console capture; keep its outputs in this audit folder.

func _shot(scene_root: Node3D, direction: Vector3, path: String) -> void:
	await super._shot(scene_root, direction,
		"res://doc/reports/interfaces-2026-09-20/flat_text_" + path.get_file())
	var glyph_meshes := 0
	var legacy_labels: Array = []
	var stack: Array = [_console]
	while not stack.is_empty():
		var node = stack.pop_back()
		if node is MeshInstance3D and node.mesh is TextMesh:
			glyph_meshes += 1
		if node is Label3D and not node.text.is_empty() and node.is_visible_in_tree():
			legacy_labels.append(str(_console.get_path_to(node)))
		stack.append_array(node.get_children())
	var panel = _console.panel()
	panel.label_mesh = true
	var legacy_example = panel._label_node("LEGACY CONFIG", Color.BLACK, Vector2(0.3, 0.05))
	var legacy_is_flat: bool = legacy_example is MeshInstance3D and legacy_example.mesh is QuadMesh
	legacy_example.free()
	panel.label_mesh = false
	var result := {"extruded_text_meshes": glyph_meshes,
		"legacy_label_mesh_setting_produces_quad": legacy_is_flat,
		"remaining_visible_child_label3d": legacy_labels,
		"scope": "Shared console title and generated labels; child-control labels remain migration work"}
	var output := FileAccess.open("res://doc/reports/interfaces-2026-09-20/flat-text-check.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(result, "\t"))
	output.close()
