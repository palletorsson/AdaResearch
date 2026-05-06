## TagByGrammarOp — Tag selected faces by an anatomical grammar.
##
## Encodes the part-grammar channel from the substrate into mesh-grammar's
## tag system. Each selected face receives a tag like "flower_petal",
## "flower_stamen", "insect_thorax" based on its centroid position and
## the named grammar's spatial rules.
##
## Downstream ops (paint_by_tag, hide_by_rule, mark_specimen) can then
## select faces by these tags. This is the bridge between substrate's
## GridPartMutator and mesh-grammar's tag system.
##
## Params:
##   grammar: String — "flower" / "insect" / "bird"
##   prefix: String = "" — optional prefix added to each role tag
##                          (e.g. "zone_" makes "zone_flower_petal")
extends MeshRule
class_name TagByGrammarOp


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var grammar: String = String(params.get("grammar", "flower")).to_lower()
	var prefix: String = String(params.get("prefix", ""))
	# Optional band-threshold overrides per grammar.
	var flower_bands: Dictionary = params.get("flower_bands", {})

	# Compute the AABB of selected faces' centroids so the grammar bands
	# scale to the actual extent of what's tagged.
	var centroids: Array[Vector3] = []
	for fi in selected:
		if fi >= mesh.faces.size():
			centroids.append(Vector3.ZERO)
			continue
		var f := mesh.faces[fi]
		var c := (mesh.vertices[f[0]] + mesh.vertices[f[1]] + mesh.vertices[f[2]]) / 3.0
		centroids.append(c)
	if centroids.is_empty():
		return

	var minp := centroids[0]
	var maxp := centroids[0]
	for c in centroids:
		minp.x = min(minp.x, c.x); minp.y = min(minp.y, c.y); minp.z = min(minp.z, c.z)
		maxp.x = max(maxp.x, c.x); maxp.y = max(maxp.y, c.y); maxp.z = max(maxp.z, c.z)
	var size := maxp - minp
	var centre := (minp + maxp) * 0.5

	# Apply per-face role assignment.
	for i in range(selected.size()):
		var fi: int = selected[i]
		if fi >= mesh.faces.size():
			continue
		var c: Vector3 = centroids[i]
		var role: String = _role_for(grammar, c, centre, size, flower_bands)
		if role.is_empty():
			continue
		var tag := prefix + grammar + "_" + role
		_ensure_tags_size(mesh, fi)
		mesh.face_tags[fi].append(tag)


func _role_for(grammar: String, c: Vector3, centre: Vector3, size: Vector3, flower_bands: Dictionary = {}) -> String:
	match grammar:
		"flower":
			# Concentric rings on the xz plane, centre = pistil.
			# Default bands (pistil 0.25, stamen 0.45, petal 0.75) better
			# spread across uniform meshes than the original 0.18 / 0.42 / 0.78.
			var dx: float = c.x - centre.x
			var dz: float = c.z - centre.z
			var r: float = max(size.x, size.z) * 0.5
			if r < 0.001:
				r = 1.0
			var nd: float = sqrt(dx * dx + dz * dz) / r
			var b_pistil: float = float(flower_bands.get("pistil", 0.25))
			var b_stamen: float = float(flower_bands.get("stamen", 0.45))
			var b_petal: float = float(flower_bands.get("petal", 0.75))
			if nd <= b_pistil: return "pistil"
			if nd <= b_stamen: return "stamen"
			if nd <= b_petal: return "petal"
			return "sepal"
		"insect":
			var sz_h: float = max(size.z * 0.5, 0.001)
			var nz: float = (c.z - centre.z) / sz_h
			if nz < -0.33: return "head"
			if nz < 0.33: return "thorax"
			return "abdomen"
		"bird":
			var sx_h: float = max(size.x * 0.5, 0.001)
			var sy_h: float = max(size.y * 0.5, 0.001)
			var sz_h2: float = max(size.z * 0.5, 0.001)
			var nx_off: float = abs(c.x - centre.x) / sx_h
			var ny: float = (c.y - centre.y) / sy_h
			var nz_b: float = (c.z - centre.z) / sz_h2
			if nx_off > 0.7 and abs(nz_b) < 0.5:
				return "wing"
			if nz_b < -0.65: return "head"
			if nz_b < -0.4 and ny < -0.05: return "throat"
			if nz_b > 0.7: return "tail"
			if nz_b > 0.5 and ny < -0.4: return "vent"
			if ny > 0.3: return "back"
			if ny < -0.3:
				return "breast" if nz_b < 0 else "belly"
			return "flanks"
	return ""


func _ensure_tags_size(mesh: MeshData, fi: int) -> void:
	while mesh.face_tags.size() <= fi:
		mesh.face_tags.append(PackedStringArray())
