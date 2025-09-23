# ROIViewer.gd
extends Node3D

@export var voxel_field: NodePath
@export var extractor_scene: PackedScene   # a scene with VoxelExtractor as root
@export var search_aabb := AABB(Vector3(-12,-12,-12), Vector3(24,24,24))
@export var coarse := 18          # coarse grid for scoring
@export var keep := 1             # how many ROIs to keep
@export var roi_resolution := Vector3i(32,32,32)

# Grid arrangement
@export var arrange_in_grid := true
@export var grid_spacing := 0.1
@export var grid_size := Vector3i(1, 1, 1)  # 3x3x1 grid for 8 samples
@export var grid_center := Vector3.ZERO

# Async generation
@export var async_generation := true
@export var generation_delay := 0.1  # seconds between each sample

func _ready():
	assert(voxel_field != NodePath(), "Assign voxel_field.")
	assert(extractor_scene, "Assign extractor_scene (a scene with VoxelExtractor).")

	var field_node = get_node(voxel_field) as VoxelField
	assert(field_node, "voxel_field must point to a VoxelField node.")
	
	if async_generation:
		_generate_async(field_node)
	else:
		_generate_sync(field_node)

func _generate_sync(field_node: VoxelField):
	"""Generate all samples synchronously (blocking)"""
	var rois = field_node.find_interesting_rois(search_aabb, coarse, keep)
	print("ROIViewer: Found ", rois.size(), " ROIs (sync)")
	
	for i in range(rois.size()):
		var r = rois[i]
		_create_sample(field_node, r, i)

func _generate_async(field_node: VoxelField):
	"""Generate samples asynchronously (non-blocking)"""
	print("ROIViewer: Starting async generation...")
	var rois = field_node.find_interesting_rois(search_aabb, coarse, keep)
	print("ROIViewer: Found ", rois.size(), " ROIs (async)")
	
	# Start the async generation process
	_generate_samples_gradually(field_node, rois)

func _generate_samples_gradually(field_node: VoxelField, rois: Array):
	"""Generate samples one by one with delays"""
	for i in range(rois.size()):
		var r = rois[i]
		print("ROIViewer: Generating sample ", i + 1, "/", rois.size())
		_create_sample(field_node, r, i)
		
		# Wait before generating next sample
		if i < rois.size() - 1:  # Don't wait after the last one
			await get_tree().create_timer(generation_delay).timeout

func _create_sample(field_node: VoxelField, roi: Dictionary, index: int):
	"""Create a single voxel sample"""
	var r = roi
	print("ROI ", index, ": score=", r.score, " center=", r.center)
	
	var aabb: AABB = r["cell"]
	var ex := extractor_scene.instantiate() as VoxelExtractor
	add_child(ex)
	ex.field = field_node
	ex.iso = field_node.iso
	ex.resolution = roi_resolution
	
	# Position the sample
	if arrange_in_grid:
		ex.transform.origin = _get_grid_position(index)
	else:
		# Use original ROI position
		ex.transform.origin = aabb.position + aabb.size * 0.5
	
	# Generate the mesh using the actual world space AABB
	ex.generate_chunk(aabb)

func _get_grid_position(index: int) -> Vector3:
	"""Calculate position along line centered around origin"""
	# Center the line around origin instead of (1,1,1) to (3,3,3)
	var start_pos = Vector3(-1, -1, -1)
	var end_pos = Vector3(1, 1, 1)
	
	var total_samples = keep
	var t = 0.0
	
	if total_samples > 1:
		t = float(index) / float(total_samples - 1)  # 0.0 to 1.0
	
	# Linear interpolation from start to end
	return start_pos.lerp(end_pos, t)
