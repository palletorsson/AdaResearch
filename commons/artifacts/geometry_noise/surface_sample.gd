extends RefCounted
## One saved Gaussian vector per logical vertex. No scene/global RNG mutation.
const SEGMENTS := 16
const SIZE_M := 2.0
const MAX_SIGMA_M := 0.25
var base := PackedVector3Array()
var indices := PackedInt32Array()
var unit_noise := PackedVector3Array()
var sample_seed: int = 1847

func _init() -> void:
	for z in range(SEGMENTS + 1):
		for x in range(SEGMENTS + 1):
			base.append(Vector3(float(x) / SEGMENTS - 0.5, 0.0, float(z) / SEGMENTS - 0.5) * SIZE_M)
	for z in range(SEGMENTS):
		for x in range(SEGMENTS):
			var a := z * (SEGMENTS + 1) + x
			var b := a + 1
			var c := a + SEGMENTS + 1
			var d := c + 1
			# Clockwise from above: Godot's front face convention.
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	resample(sample_seed)

func resample(value: int) -> void:
	sample_seed = value
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	unit_noise.clear()
	for i in base.size():
		unit_noise.append(Vector3(rng.randfn(), rng.randfn(), rng.randfn()))

func evaluate(strength: float) -> Dictionary:
	var amount := clampf(strength, 0.0, 1.0) if is_finite(strength) else 0.0
	var sigma := amount * MAX_SIGMA_M
	var positions := PackedVector3Array()
	var sum_squared := 0.0
	var maximum := 0.0
	var centroid := Vector3.ZERO
	for i in base.size():
		var displacement: Vector3 = unit_noise[i] * sigma
		positions.append(base[i] + displacement)
		# Measure the stored coordinates, including their float32 rounding.
		var measured: Vector3 = positions[i] - base[i]
		sum_squared += measured.length_squared()
		maximum = maxf(maximum, measured.length())
		centroid += measured
	centroid /= float(base.size())
	return {"positions":positions, "seed":sample_seed, "strength":amount,
		"sigma_m":sigma, "population_rms_m":sqrt(3.0)*sigma,
		"rms_m":sqrt(sum_squared / base.size()), "maximum_m":maximum,
		"centroid_drift_m":centroid.length(), "centroid_vector":centroid,
		"vertices":base.size(), "triangles":indices.size()/3}

func mesh_for(positions: PackedVector3Array) -> ArrayMesh:
	assert(positions.size() == base.size())
	var normals := PackedVector3Array()
	normals.resize(base.size())
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i+1]
		var c := indices[i+2]
		var normal := (positions[c]-positions[a]).cross(positions[b]-positions[a])
		normals[a] += normal
		normals[b] += normal
		normals[c] += normal
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-18 else Vector3.UP
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices.duplicate()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
