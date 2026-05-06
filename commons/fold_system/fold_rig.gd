class_name FoldRig
extends Resource
## The runtime container for a foldable creature's motion knowledge.
## Owns articulation data, poses, constraints, and solver.

@export var solver: FoldSolver = null
@export var segments: Array[FoldSegmentData] = []
@export var constraints: Array[FoldConstraintData] = []
@export var poses: Dictionary = {}  ## StringName -> FoldPoseResource
@export var material_profile: FoldMaterialProfile = null

@export var base_stiffness: float = 10.0
@export var base_damping: float = 0.82
@export var base_fold_speed: float = 0.5
@export var max_fold_energy: float = 1.0

@export var allowed_fold_states: PackedInt32Array = []
@export var min_fold_amount: float = 0.0
@export var max_fold_amount: float = 1.0

@export var supports_misfold: bool = true
@export var supports_latch: bool = false
@export var is_hatchable: bool = false


func get_pose_for_state(state: int) -> FoldPoseResource:
	for key in poses:
		var pose: FoldPoseResource = poses[key]
		if pose and state in pose.compatible_states:
			return pose
	return null


func is_state_allowed(state: int) -> bool:
	return allowed_fold_states.is_empty() or state in allowed_fold_states


func get_stiffness_for_segment(seg: FoldSegmentData) -> float:
	return seg.spring_stiffness if seg.spring_stiffness > 0.0 else base_stiffness


func get_damping_for_segment(seg: FoldSegmentData) -> float:
	return seg.spring_damping if seg.spring_damping > 0.0 else base_damping
