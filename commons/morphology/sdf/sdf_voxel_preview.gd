# sdf_voxel_preview.gd
# Minimal visualization of any FormSDF. Samples the field on a voxel grid,
# renders every cell with signed_distance < 0 as a MultiMesh cube. Fast,
# coarse, readable — good for tuning the field or previewing a transition.
#
# Not a production mesh — use marching cubes for that. This is what the
# editor UI shows while you drag a slider.

extends Node3D

@export var sdf: Resource  # FormSDF
@export var resolution: Vector3i = Vector3i(40, 20, 40)
@export var voxel_color_inside: Color = Color(0.9, 0.9, 0.95)
@export var voxel_color_surface: Color = Color(1.0, 0.7, 0.4)
@export var surface_threshold: float = 0.15
@export var auto_rebuild_on_ready: bool = true
## If true, scale voxel size by (1 - normalized_distance) so inner voxels
## read bigger and surface voxels smaller — more sculptural.
@export var size_by_depth: bool = true
## VR perf: when true, only emit voxels that have at least one neighbor
## outside the surface (i.e. skip fully-enclosed interior voxels the
## camera can never see). Saves 70-90% of instances on solid forms.
@export var surface_only: bool = true
## VR perf: disable shadow casting on the voxel cloud. These are
## visualizations, not lighting volumes — shadows double draw calls.
@export var cast_shadows: bool = false

var _mmi: MultiMeshInstance3D = null


func _ready() -> void:
	if auto_rebuild_on_ready and sdf != null:
		rebuild()


## Set a new SDF and re-render. Cheap for voxel preview at low resolution.
func set_sdf(new_sdf: Resource) -> void:
	sdf = new_sdf
	rebuild()


func rebuild() -> void:
	if _mmi:
		_mmi.queue_free()
		_mmi = null
	if sdf == null:
		return

	var aabb: AABB = sdf.get_aabb()
	var origin: Vector3 = aabb.position
	var size: Vector3 = aabb.size
	var step: Vector3 = size / Vector3(resolution)
	# Voxel cube size is the min of the three step axes — keeps cubes cubic.
	var vsize: float = minf(minf(step.x, step.y), step.z) * 0.9

	# Sample the whole grid
	var field: PackedFloat32Array = sdf.sample_grid(origin, size, resolution)

	# Two-pass emission so we can optionally skip interior voxels. Pass 1
	# builds a boolean mask of "is this voxel inside the form". Pass 2
	# emits transforms only for voxels that (if surface_only=true) have at
	# least one 6-neighbor outside the form — i.e. voxels the camera can
	# actually see. Saves ~70-90% of MultiMesh instances on solid forms.
	var res_x: int = resolution.x
	var res_y: int = resolution.y
	var res_z: int = resolution.z
	var slab: int = res_x * res_y * res_z

	# Pass 1: inside mask (small bit of extra memory, big rendering saving)
	var inside := PackedByteArray()
	inside.resize(slab)
	for i in slab:
		inside[i] = 1 if field[i] < surface_threshold else 0

	# Collect transforms + colors
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var max_inner_depth: float = 0.0
	var stats_inside: int = 0
	var stats_emitted: int = 0

	var idx := 0
	for z in res_z:
		for y in res_y:
			for x in res_x:
				if inside[idx] == 0:
					idx += 1
					continue
				stats_inside += 1
				var d: float = field[idx]
				idx += 1

				# Surface-only test: skip this voxel if ALL 6 neighbors are
				# also inside (it's fully enclosed — never visible).
				if surface_only:
					var all_neighbors_inside: bool = true
					# If we're on the grid boundary, neighbor is implicitly
					# outside (no field data there), so this voxel counts
					# as surface and passes.
					if x > 0 and x < res_x - 1 and y > 0 and y < res_y - 1 and z > 0 and z < res_z - 1:
						var base: int = z * res_y * res_x + y * res_x + x
						if inside[base - 1] == 1 and inside[base + 1] == 1 \
							and inside[base - res_x] == 1 and inside[base + res_x] == 1 \
							and inside[base - res_x * res_y] == 1 and inside[base + res_x * res_y] == 1:
							all_neighbors_inside = true
						else:
							all_neighbors_inside = false
					else:
						all_neighbors_inside = false
					if all_neighbors_inside:
						continue

				stats_emitted += 1
				var p: Vector3 = origin + Vector3(x, y, z) * step + step * 0.5
				var inner: float = maxf(-d, 0.0)
				if inner > max_inner_depth:
					max_inner_depth = inner
				var t := 1.0
				if size_by_depth and max_inner_depth > 0.0:
					t = clampf(0.55 + 0.45 * smoothstep(0.0, 0.5, inner), 0.5, 1.0)
				transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(t, t, t)), p))
				var col: Color = voxel_color_inside if inner > surface_threshold else voxel_color_surface
				colors.append(col)

	if transforms.is_empty():
		push_warning("SDFVoxelPreview: no voxels below surface_threshold — field may be all positive")
		return

	var mesh := BoxMesh.new()
	mesh.size = Vector3(vsize, vsize, vsize)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.6
	mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "SDFPreview"
	_mmi.multimesh = mm
	_mmi.custom_aabb = aabb.grow(2.0)
	# VR perf: shadows halve fill rate. Previews are visualizations, not
	# geometry that needs to occlude the world.
	if not cast_shadows:
		_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mmi)
	print("[SDFVoxelPreview] inside=%d emitted=%d (%.0f%% reduction)" % [
		stats_inside, stats_emitted,
		0.0 if stats_inside == 0 else 100.0 * (1.0 - float(stats_emitted) / float(stats_inside))
	])
