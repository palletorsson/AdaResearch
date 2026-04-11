# @identity
# essence: fold_amount(0→1) opens bilateral wings and lifts tail — the simplest possible folding body
# desire: a dark teal seed that blooms into a winged form when the world feels safe
# critical_parameter: fold_amount — 0 is compact package, 1 is fully deployed with wings spread
# triggers: FoldCritter FSM drives fold_amount via spring dynamics; affect + proximity gate transitions
# emerges: wing opening reveals hidden membrane color; tail lift is gated behind wing progress
# needs: FoldRig with BoneFoldSolver [has]; FoldCritter base class [has]; VR verb API [has]
# relationships: simplest member of fold creature family; test subject for FoldingZoo; template for real creatures
# truth: Four segments, one spring, and a state machine are enough to make geometry feel alive.

class_name FoldDemoCritter
extends FoldCritter
## A simple 4-segment test creature that demonstrates the fold system.
## Creates its FoldRig and geometry programmatically — no external resources needed.
## Wings spread open and tail lifts as fold_amount increases.


# ── Segment offsets ──────────────────────────────────────────────────────

const _LEFT_WING_OFFSET := Vector3(-0.15, 0.0, 0.0)
const _RIGHT_WING_OFFSET := Vector3(0.15, 0.0, 0.0)
const _TAIL_OFFSET := Vector3(0.0, 0.0, 0.15)

# ── Materials ────────────────────────────────────────────────────────────

var _mat_body: StandardMaterial3D
var _mat_wing: StandardMaterial3D
var _mat_tail: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_create_fold_rig()
	_build_fold_mesh()
	_create_collision()
	super._ready()

	# Start folded — wings closed, tail tucked
	fold_state = FoldState.FOLDED
	fold_amount = 0.0
	target_fold = 0.0


# ═════════════════════════════════════════════════════════════════════════
# FOLD RIG SETUP
# ═════════════════════════════════════════════════════════════════════════

func _create_fold_rig() -> void:
	fold_rig = FoldRig.new()
	fold_rig.solver = BoneFoldSolver.new()
	fold_rig.base_stiffness = 12.0
	fold_rig.base_damping = 0.85

	# Core — the central body, does not rotate
	var core := FoldSegmentData.new()
	core.segment_name = &"core"
	core.fold_axis = Vector3.RIGHT
	core.angle_closed = 0.0
	core.angle_open = 0.0
	core.parent_segment = &""
	core.parent_min_fold = 0.0
	core.material_type = &"bone"
	core.mass = 2.0

	# Left wing — opens forward 0 to 120 degrees
	var left_wing := FoldSegmentData.new()
	left_wing.segment_name = &"left_wing"
	left_wing.fold_axis = Vector3.FORWARD
	left_wing.angle_closed = 0.0
	left_wing.angle_open = 120.0
	left_wing.parent_segment = &"core"
	left_wing.parent_min_fold = 0.0
	left_wing.material_type = &"membrane"
	left_wing.mass = 0.5

	# Right wing — mirrors left wing (negative angle range)
	var right_wing := FoldSegmentData.new()
	right_wing.segment_name = &"right_wing"
	right_wing.fold_axis = Vector3.FORWARD
	right_wing.angle_closed = 0.0
	right_wing.angle_open = -120.0
	right_wing.parent_segment = &"core"
	right_wing.parent_min_fold = 0.0
	right_wing.material_type = &"membrane"
	right_wing.mass = 0.5

	# Tail — lifts 0 to 60 degrees, waits for core to be slightly open
	var tail := FoldSegmentData.new()
	tail.segment_name = &"tail"
	tail.fold_axis = Vector3.RIGHT
	tail.angle_closed = 0.0
	tail.angle_open = 60.0
	tail.parent_segment = &"core"
	tail.parent_min_fold = 0.2
	tail.material_type = &"flesh"
	tail.mass = 0.8

	fold_rig.segments = [core, left_wing, right_wing, tail]

	# Constraints — prevent over-extension
	var left_constraint := FoldConstraintData.new()
	left_constraint.segment_name = &"left_wing"
	left_constraint.min_angle = 0.0
	left_constraint.max_angle = 120.0

	var right_constraint := FoldConstraintData.new()
	right_constraint.segment_name = &"right_wing"
	right_constraint.min_angle = -120.0
	right_constraint.max_angle = 0.0

	var tail_constraint := FoldConstraintData.new()
	tail_constraint.segment_name = &"tail"
	tail_constraint.min_angle = 0.0
	tail_constraint.max_angle = 60.0

	fold_rig.constraints = [left_constraint, right_constraint, tail_constraint]


# ═════════════════════════════════════════════════════════════════════════
# MATERIALS
# ═════════════════════════════════════════════════════════════════════════

func _create_materials() -> void:
	# Dark teal body
	_mat_body = StandardMaterial3D.new()
	_mat_body.albedo_color = Color(0.05, 0.25, 0.3)
	_mat_body.emission_enabled = true
	_mat_body.emission = Color(0.02, 0.12, 0.15)
	_mat_body.emission_energy_multiplier = 0.6

	# Lighter teal wings
	_mat_wing = StandardMaterial3D.new()
	_mat_wing.albedo_color = Color(0.1, 0.45, 0.5)
	_mat_wing.emission_enabled = true
	_mat_wing.emission = Color(0.05, 0.22, 0.25)
	_mat_wing.emission_energy_multiplier = 0.8

	# Orange tail accent
	_mat_tail = StandardMaterial3D.new()
	_mat_tail.albedo_color = Color(0.85, 0.4, 0.1)
	_mat_tail.emission_enabled = true
	_mat_tail.emission = Color(0.45, 0.18, 0.04)
	_mat_tail.emission_energy_multiplier = 1.0


# ═════════════════════════════════════════════════════════════════════════
# MESH CONSTRUCTION
# ═════════════════════════════════════════════════════════════════════════

func _build_fold_mesh() -> void:
	_segment_nodes.clear()

	# ── ALL BONES NESTED IN HIERARCHY ──
	# Wings and tail are children of core so they move when core moves.

	# Core — sphere at origin (root of skeleton)
	var core_node := _create_segment_node(&"core", Vector3.ZERO, self)
	var core_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.30
	sphere.radial_segments = 16
	sphere.rings = 8
	core_mesh.mesh = sphere
	core_mesh.material_override = _mat_body
	core_node.add_child(core_mesh)

	# core → left_wing
	var left_node := _create_segment_node(&"left_wing", _LEFT_WING_OFFSET, core_node)
	var left_mesh := MeshInstance3D.new()
	var left_box := BoxMesh.new()
	left_box.size = Vector3(0.3, 0.02, 0.15)
	left_mesh.mesh = left_box
	left_mesh.material_override = _mat_wing
	left_mesh.position = Vector3(-0.15, 0.0, 0.0)  # Pivot at inner edge
	left_node.add_child(left_mesh)

	# core → right_wing
	var right_node := _create_segment_node(&"right_wing", _RIGHT_WING_OFFSET, core_node)
	var right_mesh := MeshInstance3D.new()
	var right_box := BoxMesh.new()
	right_box.size = Vector3(0.3, 0.02, 0.15)
	right_mesh.mesh = right_box
	right_mesh.material_override = _mat_wing
	right_mesh.position = Vector3(0.15, 0.0, 0.0)  # Pivot at inner edge
	right_node.add_child(right_mesh)

	# core → tail
	var tail_node := _create_segment_node(&"tail", _TAIL_OFFSET, core_node)
	var tail_mesh := MeshInstance3D.new()
	var tail_box := BoxMesh.new()
	tail_box.size = Vector3(0.05, 0.02, 0.2)
	tail_mesh.mesh = tail_box
	tail_mesh.material_override = _mat_tail
	tail_mesh.position = Vector3(0.0, 0.0, 0.1)  # Pivot at base
	tail_node.add_child(tail_mesh)


func _create_segment_node(seg_name: StringName, offset: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.name = String(seg_name)
	node.position = offset
	if parent:
		parent.add_child(node)
	else:
		add_child(node)
	_segment_nodes[seg_name] = node
	return node


# ═════════════════════════════════════════════════════════════════════════
# COLLISION
# ═════════════════════════════════════════════════════════════════════════

func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	add_child(col)
