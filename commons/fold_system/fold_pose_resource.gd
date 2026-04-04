class_name FoldPoseResource
extends Resource
## A stored pose — target transforms for all segments at one fold state.

@export var pose_name: StringName = &""
@export var segment_transforms: Dictionary = {}   ## StringName -> Transform3D
@export var compatible_states: PackedInt32Array = []
@export var blend_curve: Curve = null              ## null = linear lerp
@export var has_latch: bool = false
@export var latch_threshold: float = 0.95
