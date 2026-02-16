## ScallopEdgeOp — Create wavy/lobed boundary edges on selected faces.
## Turns straight mesh boundaries into scalloped, organic edges.
## Inspired by: gold vessel rims, riveted vessel edges, coral fan edges.
## Works by finding boundary edges of selected faces and adding arc geometry.
## Params:
##   lobes: int = 6              — number of scallop lobes per edge
##   amplitude: float = 0.05     — height of each wave/arc
##   depth: float = 0.03         — inward depth of the scallop curve
##   segments_per_lobe: int = 4  — arc resolution per lobe
##   style: String = "wave"      — "wave" (smooth sine), "arc" (circular arcs), "pointed" (gothic)
##   direction: String = "normal" — "normal" (along face normal), "outward" (away from mesh center)
##   scallop_tag: String = "scallop"
extends MeshRule
class_name ScallopEdgeOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var lobes: int = params.get("lobes", 6)
	var amplitude: float = params.get("amplitude", 0.05)
	var scallop_depth: float = params.get("depth", 0.03)
	var seg_per_lobe: int = params.get("segments_per_lobe", 4)
	var style: String = params.get("style", "wave")
	var direction: String = params.get("direction", "normal")
	var scallop_tag: String = params.get("scallop_tag", "scallop")

	# Collect boundary edges from selected faces
	var boundary_edges: Dictionary = {}  # edge_key_str -> {a, b, normal, face_idx}

	for face_idx in selected:
		if face_idx >= mesh.faces.size():
			continue
		var face_normal := mesh.get_face_normal(face_idx)
		var edges := mesh.get_face_edges(face_idx)
		for edge in edges:
			var ef := mesh.get_edge_faces(edge)
			if ef.size() != 1:
				continue  # Only boundary edges
			var key := "%d_%d" % [edge.x, edge.y]
			if not boundary_edges.has(key):
				boundary_edges[key] = {
					"a": mesh.vertices[edge.x],
					"b": mesh.vertices[edge.y],
					"normal": face_normal,
					"face_idx": face_idx,
					"vi_a": edge.x,
					"vi_b": edge.y
				}

	if boundary_edges.is_empty():
		return

	var mesh_center := mesh.get_bounding_box().get_center()

	# Create scallop geometry for each boundary edge
	for key in boundary_edges:
		var edge_data: Dictionary = boundary_edges[key]
		var a: Vector3 = edge_data["a"]
		var b: Vector3 = edge_data["b"]
		var normal: Vector3 = edge_data["normal"]
		var edge_length := a.distance_to(b)

		if edge_length < 0.001:
			continue

		# Determine the "up" direction for the scallop wave
		var up_dir: Vector3
		match direction:
			"normal":
				up_dir = normal.normalized()
			"outward":
				var mid := (a + b) * 0.5
				up_dir = (mid - mesh_center).normalized()
			_:
				up_dir = normal.normalized()

		# Edge tangent and perpendicular (inward from edge)
		var tangent := (b - a).normalized()
		var inward := tangent.cross(up_dir).normalized()
		if inward.length_squared() < 0.01:
			inward = tangent.cross(Vector3.UP).normalized()

		# Generate scallop vertices along the edge
		var total_segments := lobes * seg_per_lobe
		var prev_vi: int = edge_data["vi_a"]
		var anchor_vi: int = edge_data["vi_a"]  # First vertex stays fixed

		# Create vertices along the scalloped path
		var scallop_verts: PackedInt32Array = PackedInt32Array()
		scallop_verts.append(edge_data["vi_a"])

		for i in range(1, total_segments):
			var t: float = float(i) / float(total_segments)
			var base_pos := a.lerp(b, t)

			# Lobe phase
			var lobe_t := t * float(lobes)
			var lobe_phase := fmod(lobe_t, 1.0)

			# Calculate wave height based on style
			var wave_height: float = 0.0
			var wave_depth: float = 0.0

			match style:
				"wave":
					wave_height = sin(lobe_phase * PI) * amplitude
					wave_depth = sin(lobe_phase * PI) * scallop_depth
				"arc":
					# Circular arc: sqrt(1 - (2t-1)^2) shape
					var x := 2.0 * lobe_phase - 1.0
					wave_height = sqrt(maxf(0.0, 1.0 - x * x)) * amplitude
					wave_depth = sqrt(maxf(0.0, 1.0 - x * x)) * scallop_depth
				"pointed":
					# Gothic pointed arch: two arcs meeting at top
					if lobe_phase < 0.5:
						wave_height = lobe_phase * 2.0 * amplitude
					else:
						wave_height = (1.0 - lobe_phase) * 2.0 * amplitude
					wave_depth = wave_height * scallop_depth / amplitude if amplitude > 0.001 else 0.0
				_:
					wave_height = sin(lobe_phase * PI) * amplitude

			var pos := base_pos + up_dir * wave_height - inward * wave_depth
			var vi := mesh.add_vertex(pos)
			scallop_verts.append(vi)

		scallop_verts.append(edge_data["vi_b"])

		# Create triangle fan from original edge midpoint to scallop curve
		# Use a center point slightly inward from the edge
		var edge_mid := (a + b) * 0.5 - inward * scallop_depth * 0.5
		var center_vi := mesh.add_vertex(edge_mid)

		for i in range(scallop_verts.size() - 1):
			mesh.add_face(
				PackedInt32Array([scallop_verts[i], scallop_verts[i + 1], center_vi]),
				PackedStringArray([scallop_tag]))

	mesh._adjacency_dirty = true
