@tool
extends EditorScript

# Fixes mis-parented CSG nodes in boolean variants scene(s) and saves back to disk.

const TARGET_SCENES := [
	"res://algorithms/primitives/booleans/CSGVariants_Large.tscn",
]

func _run() -> void:
	for scene_path in TARGET_SCENES:
		_fix_scene(scene_path)
	print("✔ Finished fixing boolean variants scenes.")

func _fix_scene(scene_path: String) -> void:
	var packed: PackedScene = load(scene_path)
	if not packed:
		push_error("Failed to load scene: %s" % scene_path)
		return

	var root := packed.instantiate()
	if not root:
		push_error("Failed to instantiate scene: %s" % scene_path)
		return

	# Repair hierarchy and layout
	_repair_csg_hierarchy(root)
	_layout_variants_on_grid(root)

	# Pack and save back
	var new_packed := PackedScene.new()
	var ok := new_packed.pack(root)
	if ok != OK:
		push_error("Failed to pack scene: %s" % scene_path)
		return
	var save_ok := ResourceSaver.save(new_packed, scene_path)
	if save_ok != OK:
		push_error("Failed to save scene: %s" % scene_path)
		return
	print("✓ Saved fixed scene:", scene_path)

func _repair_csg_hierarchy(root: Node) -> void:
	# Moves nodes named with patterns like:
	# - "CSG_Variant_XXX_Name#CSGCombiner3D" -> parent under variant as "CSGCombiner3D"
	# - "CSG_Variant_XXX_Name_CSGCombiner3D#ChildName" -> parent under variant/CSGCombiner3D as "ChildName"
	# Only processes direct children of root (as observed in the large scene file).
	var children := root.get_children()
	for n in children:
		if not (n is Node3D):
			continue
		var name_str := String(n.name)
		if "#" in name_str:
			var parts := name_str.split("#", false, 1)
			if parts.size() != 2:
				continue
			var left := String(parts[0])
			var right := String(parts[1])
			if left.ends_with("_CSGCombiner3D"):
				var variant_name := left.trim_suffix("_CSGCombiner3D")
				var child_name := right
				var variant_node := _ensure_variant_node(root, variant_name)
				var combiner := _ensure_combiner_node(variant_node)
				if n.get_parent() != combiner:
					root.remove_child(n)
					combiner.add_child(n)
				n.name = child_name
			elif right == "CSGCombiner3D":
				var variant_name2 := left
				var variant_node2 := _ensure_variant_node(root, variant_name2)
				if n.get_parent() != variant_node2:
					root.remove_child(n)
					variant_node2.add_child(n)
				n.name = "CSGCombiner3D"

func _ensure_variant_node(root: Node, variant_name: String) -> Node3D:
	var existing := root.get_node_or_null(variant_name)
	if existing and (existing is Node3D):
		return existing
	var v := Node3D.new()
	v.name = variant_name
	root.add_child(v)
	return v

func _ensure_combiner_node(variant_node: Node3D) -> Node3D:
	var comb := variant_node.get_node_or_null("CSGCombiner3D")
	if comb and (comb is CSGCombiner3D):
		return comb
	if comb and (comb is Node3D) and not (comb is CSGCombiner3D):
		var idx := comb.get_index()
		variant_node.remove_child(comb)
		comb.queue_free()
		var real_csg := CSGCombiner3D.new()
		real_csg.name = "CSGCombiner3D"
		variant_node.add_child(real_csg)
		variant_node.move_child(real_csg, idx)
		return real_csg
	var c := CSGCombiner3D.new()
	c.name = "CSGCombiner3D"
	variant_node.add_child(c)
	return c

func _layout_variants_on_grid(root: Node) -> void:
	var variants: Array = []
	for child in root.get_children():
		if (child is Node3D) and String(child.name).begins_with("CSG_Variant_"):
			variants.append(child)
	variants.sort_custom(func(a, b): return String(a.name) < String(b.name))
	var spacing := 4.0
	var rows := 10
	for i in range(variants.size()):
		var row_i := i % rows
		var col_i := i / rows
		var pos := Vector3(float(col_i) * spacing, 1.0, float(row_i) * spacing)
		(variants[i] as Node3D).position = pos
