@tool
extends Node3D

# Minimal stub used by CSGVariants_Large.tscn.
# Keeps compatibility if the real viewer script is absent.


class_name CSGViewer

func _ready() -> void:
	# Organize scene so each example sits at a unique location
	# and all boolean meshes are children of their main parent.
	_repair_csg_hierarchy()
	_layout_variants_on_grid()

func _process(_delta: float) -> void:
	pass

func _repair_csg_hierarchy() -> void:
	# Expected naming patterns (observed in scene):
	# 1) "CSG_Variant_XXX_Name#CSGCombiner3D"  => should be node name "CSGCombiner3D" parent "CSG_Variant_XXX_Name"
	# 2) "CSG_Variant_XXX_Name_CSGCombiner3D#ChildName" => should be node name "ChildName" parent "CSG_Variant_XXX_Name/CSGCombiner3D"
	# 3) Properly formed nodes are ignored
	var nodes := get_children()
	for n in nodes:
		if not (n is Node3D):
			continue
		var name_str := n.name
		if "#" in name_str:
			var parts := name_str.split("#", false, 1)
			if parts.size() == 2:
				var left := String(parts[0])
				var right := String(parts[1])
				if left.ends_with("_CSGCombiner3D"):
					# Child under combiner
					var variant_name := left.trim_suffix("_CSGCombiner3D")
					var child_name := right
					var variant_node := _ensure_variant_node(variant_name)
					var combiner := _ensure_combiner_node(variant_node)
					# Reparent and rename
					if n.get_parent() != combiner:
						n.get_parent().remove_child(n)
						combiner.add_child(n)
					n.name = child_name
				elif right == "CSGCombiner3D":
					# This is the combiner under variant
					var variant_name2 := left
					var variant_node2 := _ensure_variant_node(variant_name2)
					# Reparent and rename to CSGCombiner3D
					if n.get_parent() != variant_node2:
						n.get_parent().remove_child(n)
						variant_node2.add_child(n)
					n.name = "CSGCombiner3D"

func _ensure_variant_node(variant_name: String) -> Node3D:
	var existing := get_node_or_null(variant_name)
	if existing and (existing is Node3D):
		return existing
	var v := Node3D.new()
	v.name = variant_name
	add_child(v)
	return v

func _ensure_combiner_node(variant_node: Node3D) -> Node3D:
	var comb := variant_node.get_node_or_null("CSGCombiner3D")
	if comb and (comb is CSGCombiner3D):
		return comb
	# If an incorrectly typed node exists, replace it with a real CSGCombiner3D
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

func _layout_variants_on_grid() -> void:
	# Place each variant at a unique grid position based on index.
	# Only moves top-level variant nodes named like "CSG_Variant_*".
	var variants: Array = []
	for child in get_children():
		if (child is Node3D) and String(child.name).begins_with("CSG_Variant_"):
			variants.append(child)
	# Sort by name for deterministic layout
	variants.sort_custom(func(a, b): return String(a.name) < String(b.name))
	var spacing := 4.0
	var rows := 10
	for i in range(variants.size()):
		var row_i := i % rows
		var col_i := i / rows
		var pos := Vector3(float(col_i) * spacing, 1.0, float(row_i) * spacing)
		variants[i].position = pos
