class_name MeshMerge
extends RefCounted
## ONE MESH FOR ONE THING. An artifact built from many MeshInstance3D children (the crate: forty-eight planks,
## strips and braces) costs a draw call per mesh surface, which is what a Quest runs out of first
## (commons/data/inventory/costs.json: the crate 48 draws for 552 triangles). `merge(root)` folds every
## MeshInstance3D under `root` into one ArrayMesh with one surface per MATERIAL (materials kept by identity, so
## a build that shares its materials merges to a handful of surfaces), transforms baked relative to `root`,
## then frees the originals and leaves one child "Merged". Collision shapes, lights, labels and anything that
## is not a MeshInstance3D are untouched; a mesh named in `keep`, one on layer 0, or one already queued for
## deletion (a rebuild in progress) is left alone. Returns the merged MeshInstance3D, or null if nothing merged.

static func merge(root: Node3D, keep: Array = []) -> MeshInstance3D:
	var groups: Dictionary = {}      # material -> SurfaceTool
	var order: Array = []            # materials in the order met, so the surfaces are stable
	var victims: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():stack.append(c)
		if n == root or not n is MeshInstance3D:continue
		var mi := n as MeshInstance3D
		if mi.mesh == null or mi.is_queued_for_deletion() or mi.name in keep or mi.name == "Merged" or mi.layers == 0 or not mi.visible:continue
		var xf: Transform3D = root.global_transform.affine_inverse() * mi.global_transform
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override
			if mat == null:mat = mi.get_surface_override_material(s)
			if mat == null:mat = mi.mesh.surface_get_material(s)
			var key: Variant = mat if mat != null else "none"
			if not groups.has(key):
				var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);groups[key] = st;order.append(key)
			(groups[key] as SurfaceTool).append_from(mi.mesh, s, xf)
		victims.append(mi)
	if victims.is_empty():return null
	var mesh := ArrayMesh.new()
	for key in order:
		var st: SurfaceTool = groups[key]
		st.commit(mesh)
		if key is Material:mesh.surface_set_material(mesh.get_surface_count() - 1, key)
	for v in victims:
		v.get_parent().remove_child(v);v.queue_free()
	# a rebuild in the same frame leaves the old "Merged" queued for deletion and still holding the name, which would
	# make this one "@MeshInstance3D@N": the old one leaves the tree now (it is freed at the frame's end anyway)
	var old := root.get_node_or_null("Merged")
	if old != null and old.is_queued_for_deletion():root.remove_child(old)
	var merged := MeshInstance3D.new();merged.name = "Merged";merged.mesh = mesh
	root.add_child(merged)
	return merged
