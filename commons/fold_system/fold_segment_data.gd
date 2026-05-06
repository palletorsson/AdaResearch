class_name FoldSegmentData
extends Resource
## One segment in a foldable body. Defines the axis, range, SIZE, and material
## of a single articulation point.
##
## Size matters because the solver must know whether folded pieces fit:
##   - A wing folded against the body must not clip through it
##   - Accordion segments compressed must not overlap beyond thickness
##   - Nested shells need each layer larger than the inner one
##   - All segments must fit inside the egg volume when fold_amount = 0

@export var segment_name: StringName = &""

@export_group("Fold Geometry")
@export var fold_axis: Vector3 = Vector3.RIGHT   ## Local rotation axis
@export var angle_closed: float = 0.0            ## Degrees at fold_amount = 0
@export var angle_open: float = 90.0             ## Degrees at fold_amount = 1
@export var pivot_offset: Vector3 = Vector3.ZERO ## Where this segment hinges relative to parent attachment
## Activation window: this segment only moves when fold_amount is in [start, end].
## At fold_amount < start, segment stays at angle_closed.
## At fold_amount > end, segment stays at angle_open.
## Between start and end, segment interpolates its full range.
## Default 0.0-1.0 = segment uses the full fold_amount range (backward compatible).
@export var activation_start: float = 0.0
@export var activation_end: float = 1.0
## Size of this segment's solid volume (bounding box of the mesh).
## Used by solvers to compute clearance, stacking, and nesting.
@export var size: Vector3 = Vector3(0.1, 0.1, 0.1)
## Thickness along the fold axis — how much space this segment occupies when stacked/nested.
## For accordion: minimum spacing between neighbors when fully compressed.
## For shells: radial thickness of this layer.
## For bones: width of the hinge joint.
@export var thickness: float = 0.02

@export_group("Hierarchy")
@export var parent_segment: StringName = &""
@export var parent_min_fold: float = 0.0     ## Parent must be this open before child opens

@export_group("Material")
@export var material_type: StringName = &"bone"  ## bone, membrane, flesh

@export_group("Dynamics")
@export var spring_stiffness: float = -1.0   ## -1 = use FoldRig default
@export var spring_damping: float = -1.0     ## -1 = use FoldRig default
@export var mass: float = 1.0                ## Affects inertia and tension contribution
