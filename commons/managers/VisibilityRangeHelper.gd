# VisibilityRangeHelper.gd — Static utility for Godot 4 visibility ranges
#
# Recursively applies visibility_range_begin / visibility_range_end to all
# GeometryInstance3D nodes in a subtree. Used by ChunkManager to enable
# GPU-side distance culling on CritterEntity hierarchies.
#
# Godot's visibility range system hides geometry before it reaches the
# draw call stage, making it the cheapest possible LOD optimization.
#
# Usage:
#   VisibilityRangeHelper.apply_visibility_range(entity, 25.0)
#   VisibilityRangeHelper.clear_visibility_range(entity)

class_name VisibilityRangeHelper
extends RefCounted


## Apply visibility range to all GeometryInstance3D children of [param root].
##
## [param root]         The entity root (typically a CritterEntity).
## [param range_end]    Distance (meters) at which geometry disappears.
##                      Set to 0.0 to disable (always visible).
## [param fade_margin]  Fade distance before range_end for smooth transition.
##                      Set to 0.0 for instant pop (cheaper but jarring in VR).
## [param range_begin]  Distance at which geometry starts being visible.
##                      Default 0.0 = visible from zero distance.
static func apply_visibility_range(
	root: Node3D,
	range_end: float,
	fade_margin: float = 2.0,
	range_begin: float = 0.0
) -> void:
	_walk_geometry(root, range_begin, range_end, fade_margin)


## Remove visibility range from all GeometryInstance3D children.
## Geometry will be visible at any distance (standard behavior).
static func clear_visibility_range(root: Node3D) -> void:
	_walk_geometry(root, 0.0, 0.0, 0.0)


## Apply visibility ranges appropriate for a given LOD tier.
##
## Tier 3 (near):    No range limit — always visible.
## Tier 2 (mid):     Visible up to 15m.
## Tier 1 (far):     Visible up to 25m.
## Tier 0 (distant): Visible up to 35m.
static func apply_lod_tier_ranges(root: Node3D, tier: int) -> void:
	match tier:
		3:
			# Near — no distance culling, always visible
			clear_visibility_range(root)
		2:
			apply_visibility_range(root, 15.0, 2.0)
		1:
			apply_visibility_range(root, 25.0, 3.0)
		0:
			apply_visibility_range(root, 35.0, 4.0)
		_:
			clear_visibility_range(root)


# ═══════════════════════════════════════════════════════════════
# MESH MERGING — Collapse many MeshInstance3D into one draw call
# ═══════════════════════════════════════════════════════════════

## Merge all MeshInstance3D descendants of [param root] into a single mesh.
##
## Each organism's morphology builder creates a separate MeshInstance3D per
## branch/limb/stem/petal — each costs a GPU draw call. A typical tree has
## 80-200 mesh children. Merging them into one mesh reduces draw calls from
## hundreds to one, which is critical for VR at 90fps.
##
## MultiMeshInstance3D nodes are preserved (leaves, petals, gills — already
## GPU-instanced and efficient).
##
## Returns the number of individual meshes that were merged into one.
## Returns 0 if there was nothing to merge (0 or 1 mesh children).
static func merge_mesh_children(root: Node3D) -> int:
	var mesh_nodes: Array[MeshInstance3D] = []
	_collect_mesh_instances(root, mesh_nodes)

	if mesh_nodes.size() <= 1:
		return 0

	# Use the first mesh's material as the base material for the merged mesh.
	# Per-branch color drift is sacrificed for the massive draw call reduction.
	var base_material: Material = null
	for mi in mesh_nodes:
		if mi.material_override:
			base_material = mi.material_override
			break

	# Merge using raw vertex arrays (more reliable than SurfaceTool.append_from
	# which can silently corrupt data when begin() sets a conflicting format).
	var all_verts := PackedVector3Array()
	var all_normals := PackedVector3Array()
	var all_uvs := PackedVector2Array()
	var has_normals: bool = true
	var has_uvs: bool = true

	var merged_count: int = 0
	for mi in mesh_nodes:
		if not mi.mesh or mi.mesh.get_surface_count() == 0:
			continue

		var xform: Transform3D = _relative_transform(mi, root)
		var normal_basis: Basis = xform.basis

		for surface_idx in mi.mesh.get_surface_count():
			var arrays: Array = mi.mesh.surface_get_arrays(surface_idx)
			if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
				continue

			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals = arrays[Mesh.ARRAY_NORMAL]
			var uvs = arrays[Mesh.ARRAY_TEX_UV]
			var indices = arrays[Mesh.ARRAY_INDEX]

			# Expand indexed geometry to non-indexed triangles
			if indices != null and indices.size() > 0:
				var expanded_verts := PackedVector3Array()
				var expanded_normals := PackedVector3Array()
				var expanded_uvs := PackedVector2Array()
				for idx in indices:
					expanded_verts.append(verts[idx])
					if normals != null and normals.size() > idx:
						expanded_normals.append(normals[idx])
					if uvs != null and uvs.size() > idx:
						expanded_uvs.append(uvs[idx])
				verts = expanded_verts
				normals = expanded_normals if expanded_normals.size() > 0 else null
				uvs = expanded_uvs if expanded_uvs.size() > 0 else null

			# Transform vertices and normals into root-local space
			for v in verts:
				all_verts.append(xform * v)

			if normals != null and normals.size() == verts.size():
				for n in normals:
					all_normals.append((normal_basis * n).normalized())
			else:
				has_normals = false

			if uvs != null and uvs.size() == verts.size():
				all_uvs.append_array(uvs)
			else:
				has_uvs = false

		merged_count += 1

	if merged_count <= 1 or all_verts.is_empty():
		return 0

	# Build ArrayMesh from raw arrays
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = all_verts
	if has_normals and all_normals.size() == all_verts.size():
		arrays[Mesh.ARRAY_NORMAL] = all_normals
	if has_uvs and all_uvs.size() == all_verts.size():
		arrays[Mesh.ARRAY_TEX_UV] = all_uvs

	var merged_mesh := ArrayMesh.new()
	merged_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	# Remove old individual mesh nodes
	for mi in mesh_nodes:
		if is_instance_valid(mi):
			mi.get_parent().remove_child(mi)
			mi.queue_free()

	# Add the single merged mesh
	var merged_inst := MeshInstance3D.new()
	merged_inst.name = "MergedMesh"
	merged_inst.mesh = merged_mesh
	if base_material:
		merged_inst.material_override = base_material
	else:
		# Fallback material to avoid "material is null" errors
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.4, 0.5, 0.3)
		merged_inst.material_override = fallback
	root.add_child(merged_inst)

	return merged_count


## Recursively collect MeshInstance3D nodes, skipping MultiMeshInstance3D.
static func _collect_mesh_instances(node: Node, result: Array[MeshInstance3D]) -> void:
	# Check MultiMeshInstance3D first since it extends GeometryInstance3D
	if node is MultiMeshInstance3D:
		return  # Skip — already GPU-instanced, don't merge these
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_mesh_instances(child, result)


## Compute the transform of [param child] relative to [param root].
## Works by walking up the parent chain.
static func _relative_transform(child: Node3D, root: Node3D) -> Transform3D:
	if child == root:
		return Transform3D.IDENTITY
	var xform := child.transform
	var current: Node = child.get_parent()
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


# ═══════════════════════════════════════════════════════════════
# INTERNAL — Visibility range
# ═══════════════════════════════════════════════════════════════

static func _walk_geometry(
	node: Node,
	range_begin: float,
	range_end: float,
	fade_margin: float
) -> void:
	if node is GeometryInstance3D:
		var gi: GeometryInstance3D = node as GeometryInstance3D
		gi.visibility_range_begin = range_begin
		gi.visibility_range_end = range_end
		gi.visibility_range_begin_margin = 0.0
		gi.visibility_range_end_margin = fade_margin
		if range_end > 0.0 and fade_margin > 0.0:
			gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		else:
			gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

	for child in node.get_children():
		_walk_geometry(child, range_begin, range_end, fade_margin)
