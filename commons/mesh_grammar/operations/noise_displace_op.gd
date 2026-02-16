## NoiseDisplaceOp — Displace vertices using FastNoiseLite.
## Creates organic crumpled/rough surfaces.
## Inspired by: erupting ceramic vessels, cabbage bowls.
## Params:
##   amplitude: float = 0.1     — maximum displacement
##   frequency: float = 2.0     — noise frequency (higher = more detail)
##   noise_seed: int = 0        — noise seed (0 = random)
##   direction: String = "normal" — "normal", "radial", or "y"
##   noise_type: String = "simplex" — "simplex", "perlin", "cellular"
extends MeshRule
class_name NoiseDisplaceOp

func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var amplitude: float = params.get("amplitude", 0.1)
	var frequency: float = params.get("frequency", 2.0)
	var noise_seed_val: int = params.get("noise_seed", 0)
	var direction: String = params.get("direction", "normal")
	var noise_type_str: String = params.get("noise_type", "simplex")

	# Setup noise
	var noise := FastNoiseLite.new()
	match noise_type_str:
		"perlin":
			noise.noise_type = FastNoiseLite.TYPE_PERLIN
		"cellular":
			noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		_:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = frequency
	if noise_seed_val != 0:
		noise.seed = noise_seed_val
	else:
		noise.seed = randi()

	# Collect vertices from selected faces
	var affected_verts: Dictionary = {}  # vert_idx -> true
	if selector.target_type == MeshSelector.TargetType.VERTEX:
		for vi in selected:
			affected_verts[vi] = true
	else:
		for fi in selected:
			if fi < mesh.faces.size():
				for vi in mesh.faces[fi]:
					affected_verts[vi] = true

	# Compute vertex normals for normal-direction displacement
	var vert_normals: Dictionary = {}
	if direction == "normal":
		for vi in affected_verts:
			var normal := Vector3.ZERO
			var v_faces := mesh.get_vertex_faces(vi)
			for fi in v_faces:
				normal += mesh.get_face_normal(fi)
			if normal.length_squared() > 0:
				normal = normal.normalized()
			else:
				normal = Vector3.UP
			vert_normals[vi] = normal

	# Center for radial direction
	var center := Vector3.ZERO
	if direction == "radial":
		var bb := mesh.get_bounding_box()
		center = bb.get_center()

	# Apply displacement
	for vi in affected_verts:
		if vi >= mesh.vertices.size():
			continue
		var pos: Vector3 = mesh.vertices[vi]
		var noise_val: float = noise.get_noise_3d(pos.x, pos.y, pos.z)

		var displace_dir: Vector3
		match direction:
			"normal":
				displace_dir = vert_normals.get(vi, Vector3.UP)
			"radial":
				displace_dir = (pos - center)
				if displace_dir.length_squared() > 0:
					displace_dir = displace_dir.normalized()
				else:
					displace_dir = Vector3.UP
			"y":
				displace_dir = Vector3.UP
			_:
				displace_dir = Vector3.UP

		mesh.vertices[vi] += displace_dir * noise_val * amplitude

	mesh._adjacency_dirty = true
