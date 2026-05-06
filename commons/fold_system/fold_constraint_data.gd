class_name FoldConstraintData
extends Resource
## Joint limit for one segment. Constraints prevent over-extension,
## provide latch points, and define break thresholds for misfold.

@export var segment_name: StringName = &""
@export var min_angle: float = 0.0
@export var max_angle: float = 90.0
@export var latch_angle: float = -1.0        ## -1 = no latch; snap to this angle when close
@export var latch_threshold: float = 5.0     ## Degrees — snap if within this range
@export var break_force: float = -1.0        ## -1 = unbreakable; positive = misfold if exceeded
