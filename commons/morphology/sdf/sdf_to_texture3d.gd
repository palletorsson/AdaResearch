# sdf_to_texture3d.gd
# Bake any FormSDF into an ImageTexture3D of signed distances. The result
# is sampled by the sdf_raymarch.gdshader on the GPU — one texture read
# per march step, per pixel. Thousands of voxel draw calls collapse to
# one.
#
# Format is FORMAT_RF (single 32-bit float per voxel in the R channel).
# At 64³ that's 1 MB; at 128³ it's 8 MB. Pick the smallest that resolves
# your form's thinnest feature.

extends RefCounted


## Bake the given SDF on a voxel grid. If `aabb_override` has non-zero
## size, use it instead of sdf.get_aabb() — useful when you want padding.
static func bake(sdf: Resource, resolution: Vector3i, aabb_override: AABB = AABB()) -> ImageTexture3D:
	if sdf == null:
		return null
	var aabb: AABB = aabb_override if aabb_override.size.length_squared() > 0.0 else sdf.get_aabb()
	var origin: Vector3 = aabb.position
	var size: Vector3 = aabb.size

	# Sample the whole grid using the protocol's batch sampler.
	var field: PackedFloat32Array = sdf.sample_grid(origin, size, resolution)

	# Build one Image per z-slice (FORMAT_RGBAF — 16 bytes per voxel). We
	# pack the SDF value into the R channel and leave GBA = 0. Single-
	# channel RF 3D textures are not universally supported in Godot 4
	# shader samplers across Vulkan drivers, but RGBAF is safe.
	var slice_count: int = resolution.x * resolution.y
	var images: Array[Image] = []
	for z in resolution.z:
		var slice_floats := PackedFloat32Array()
		slice_floats.resize(slice_count * 4)
		var src_base: int = z * slice_count
		for i in slice_count:
			slice_floats[i * 4 + 0] = field[src_base + i]  # R = signed distance
			# GBA left at 0.0
		var bytes: PackedByteArray = slice_floats.to_byte_array()
		var img := Image.create_from_data(resolution.x, resolution.y, false, Image.FORMAT_RGBAF, bytes)
		images.append(img)

	var tex := ImageTexture3D.new()
	var err: int = tex.create(Image.FORMAT_RGBAF, resolution.x, resolution.y, resolution.z, false, images)
	if err != OK:
		push_error("SDFToTexture3D: create() failed with code %d" % err)
		return null
	return tex
