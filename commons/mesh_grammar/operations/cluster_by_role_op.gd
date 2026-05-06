## ClusterByRoleOp — Partition role-tagged faces into K sub-clusters.
##
## The part-individuation step. Where tag_by_grammar gives you regions
## ("flower_petal" = annular ring of 24 faces), this op splits each
## region into K named sub-parts ("flower_petal_0" … "flower_petal_11"),
## each of which downstream ops (extrude_by_role, lsystem_branch_by_role,
## replace_with_mesh_by_role) can act on independently.
##
## Without this op, extruding a petal ring gives a frill. With this op
## and K=12, extrude gives 12 splaying petals.
##
## Two clustering methods:
##   "angular" — sort faces by atan2(dz, dx) around the role's centroid,
##               slice into K equal arcs. Ideal for ring-shaped flower
##               bands or radial layouts.
##   "kmeans"  — Lloyd's algorithm on centroids, ~10 iterations. For
##               irregular regions like insect legs or bird wing feathers.
##
## Params:
##   role_params: Dictionary{role_name -> {k: int, method: "angular"|"kmeans"}}
##   tag_prefix: String = "" — strip this from face tag before role match
##   keep_role_tag: bool = true — retain the original role tag alongside
extends MeshRule
class_name ClusterByRoleOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var role_params: Dictionary = params.get("role_params", {})
	var tag_prefix: String = String(params.get("tag_prefix", ""))
	var keep_role_tag: bool = bool(params.get("keep_role_tag", true))

	# Group selected face indices by role.
	var by_role: Dictionary = {}  # role_key -> Array[int]
	for fi in selected:
		if fi >= mesh.faces.size() or fi >= mesh.face_tags.size():
			continue
		for raw_tag in mesh.face_tags[fi]:
			var tag := String(raw_tag)
			var key := tag if tag_prefix.is_empty() else (
				tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else "")
			if not key.is_empty() and role_params.has(key):
				if not by_role.has(key):
					by_role[key] = []
				(by_role[key] as Array).append(fi)
				break
			if role_params.has(tag):
				if not by_role.has(tag):
					by_role[tag] = []
				(by_role[tag] as Array).append(fi)
				break

	# For each role, compute centroids and partition.
	for role_key in by_role.keys():
		var face_indices: Array = by_role[role_key]
		var p: Dictionary = role_params[role_key]
		var k: int = max(int(p.get("k", 6)), 1)
		var method: String = String(p.get("method", "angular")).to_lower()

		var centroids: Array[Vector3] = []
		for fi in face_indices:
			var f := mesh.faces[fi]
			var c := (mesh.vertices[f[0]] + mesh.vertices[f[1]] + mesh.vertices[f[2]]) / 3.0
			centroids.append(c)
		var labels: PackedInt32Array
		if method == "kmeans":
			labels = _kmeans_labels(centroids, k)
		else:
			labels = _angular_labels(centroids, k)

		for i in range(face_indices.size()):
			var fi: int = face_indices[i]
			var sub_tag := "%s_%d" % [role_key, labels[i]]
			if not keep_role_tag:
				# Remove the original role tag; keep everything else.
				var kept := PackedStringArray()
				for raw_tag in mesh.face_tags[fi]:
					var tag := String(raw_tag)
					var bare := tag if tag_prefix.is_empty() else (
						tag.substr(tag_prefix.length()) if tag.begins_with(tag_prefix) else tag)
					if bare != role_key and tag != role_key:
						kept.append(tag)
				mesh.face_tags[fi] = kept
			mesh.face_tags[fi].append(sub_tag)


# Sort by angle around the role's centroid (XZ plane), slice into K arcs.
func _angular_labels(centroids: Array[Vector3], k: int) -> PackedInt32Array:
	var n: int = centroids.size()
	var labels := PackedInt32Array()
	labels.resize(n)
	if n == 0:
		return labels
	var mean := Vector3.ZERO
	for c in centroids:
		mean += c
	mean /= float(n)
	# Pair each face with its angle, sort, slice into K equal-count buckets.
	var indexed: Array = []
	for i in range(n):
		var dx: float = centroids[i].x - mean.x
		var dz: float = centroids[i].z - mean.z
		var ang: float = atan2(dz, dx)
		indexed.append([ang, i])
	indexed.sort_custom(func(a, b): return a[0] < b[0])
	# Equal-count slicing keeps clusters balanced even when faces aren't
	# uniformly distributed — important for ring topology with seams.
	for rank in range(n):
		var face_i: int = indexed[rank][1]
		labels[face_i] = int(float(rank) / float(n) * float(k)) % k
	return labels


# Lloyd's k-means on Vector3 centroids. ~10 iterations is plenty for
# small region sizes (a flower band has ~24 faces, an insect leg <50).
func _kmeans_labels(centroids: Array[Vector3], k: int) -> PackedInt32Array:
	var n: int = centroids.size()
	var labels := PackedInt32Array()
	labels.resize(n)
	if n == 0 or k <= 1:
		return labels  # all zero
	# Seed: pick K evenly-spaced points by index.
	var means: Array[Vector3] = []
	for i in range(k):
		means.append(centroids[int(float(i) / float(k) * float(n))])
	for _iter in range(10):
		# Assign.
		for i in range(n):
			var best: int = 0
			var best_d: float = INF
			for j in range(k):
				var d: float = centroids[i].distance_squared_to(means[j])
				if d < best_d:
					best_d = d
					best = j
			labels[i] = best
		# Update.
		var sums: Array[Vector3] = []
		var counts: PackedInt32Array = PackedInt32Array()
		sums.resize(k); counts.resize(k)
		for j in range(k):
			sums[j] = Vector3.ZERO; counts[j] = 0
		for i in range(n):
			sums[labels[i]] += centroids[i]
			counts[labels[i]] += 1
		for j in range(k):
			if counts[j] > 0:
				means[j] = sums[j] / float(counts[j])
	return labels
