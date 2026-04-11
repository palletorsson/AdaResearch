# @identity
# essence: a flat triangle grid folds into a twisted faceted cylinder — pineapple topology as a living creature
# desire: a tube that unfurls flat when dormant and coils shut when alert — the fold IS the body
# critical_parameter: fold_amount — 0 is flat grid, 1 is closed helix cylinder
# triggers: same vertices, same faces, only positions change — folding preserves topology
# truth: a cylinder is a flat grid with its edges identified. twist makes it alive.

class_name HelixCylinderCreature
extends FoldCritter
## Runtime fold creature using helix cylinder topology.
## Flat triangle grid at fold_amount=0, closed twisted tube at fold_amount=1.
## Same vertex count, same face count, always. Only positions change.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

@export var rings: int = 12
@export var segments_per_ring: int = 8
@export var cyl_radius: float = 0.06
@export var cyl_height: float = 0.25
@export var twist_amount: float = 0.5
@export var flat_width: float = 0.35
@export var flat_height: float = 0.25
@export var base_color: Color = Color(0.88, 0.82, 0.72)

# Fixed topology — never changes
var _verts_flat: Array[Vector3] = []
var _verts_helix: Array[Vector3] = []
var _faces: Array = []

# Mesh — created once, positions updated
var _mesh: ArrayMesh = null
var _mesh_instance: MeshInstance3D = null
var _material: StandardMaterial3D = null
var _last_fold: float = -1.0


func _ready() -> void:
	_generate_geometry()
	_create_material()
	_create_fold_rig()

	fold_state = FoldState.FOLDED
	fold_amount = 0.5
	target_fold = 0.5

	_build_fold_mesh()
	_create_collision()
	super._ready()


func _generate_geometry() -> void:
	_verts_flat.clear()
	_verts_helix.clear()
	_faces.clear()

	for row in rings:
		var row_t: float = float(row) / float(rings - 1)
		for col in segments_per_ring:
			var col_t: float = float(col) / float(segments_per_ring)

			# Flat: regular grid
			var fx: float = (col_t - 0.5) * flat_width
			var fz: float = (row_t - 0.5) * flat_height
			_verts_flat.append(Vector3(fx, 0.0, fz))

			# Helix: twisted cylinder
			var angle: float = col_t * TAU + row_t * twist_amount * TAU
			var y: float = (row_t - 0.5) * cyl_height
			_verts_helix.append(Vector3(cos(angle) * cyl_radius, y, sin(angle) * cyl_radius))

	# Faces: wrap columns (col+1 wraps to 0)
	for row in (rings - 1):
		for col in segments_per_ring:
			var cn: int = (col + 1) % segments_per_ring
			var i00: int = row * segments_per_ring + col
			var i01: int = row * segments_per_ring + cn
			var i10: int = (row + 1) * segments_per_ring + col
			var i11: int = (row + 1) * segments_per_ring + cn
			_faces.append([i00, i01, i10])
			_faces.append([i01, i11, i10])


func _create_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = base_color
	_material.roughness = 0.75
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.emission_enabled = true
	_material.emission = base_color * 0.15
	_material.emission_energy_multiplier = 0.4


func _create_fold_rig() -> void:
	fold_rig = FoldRig.new()
	fold_rig.solver = BoneFoldSolver.new()
	fold_rig.base_stiffness = 12.0
	fold_rig.base_damping = 0.86
	fold_rig.max_fold_energy = 1.0
	fold_rig.supports_misfold = true

	var seg := FoldSegmentData.new()
	seg.segment_name = &"body"
	seg.mass = 1.0
	fold_rig.segments = [seg]


func _build_fold_mesh() -> void:
	_segment_nodes.clear()

	var body_node := Node3D.new()
	body_node.name = "body"
	add_child(body_node)
	_segment_nodes[&"body"] = body_node

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "HelixMesh"
	body_node.add_child(_mesh_instance)

	_build_mesh_at_fold(fold_amount)


func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = cyl_radius * 1.5
	shape.height = cyl_height
	col.shape = shape
	add_child(col)


# ═════════════════════════════════════════════════════════════════════════
# FOLD — same faces, same vertex count, only positions change
# ═════════════════════════════════════════════════════════════════════════

func _process_visual(delta: float) -> void:
	if not fold_rig or not fold_rig.solver:
		return
	if abs(fold_amount - _last_fold) > 0.001:
		_build_mesh_at_fold(fold_amount)
		_last_fold = fold_amount


func _build_mesh_at_fold(t: float) -> void:
	if _verts_flat.is_empty() or not _mesh_instance:
		return

	var verts: Array = []
	for i in _verts_flat.size():
		verts.append(_verts_flat[i].lerp(_verts_helix[i], t))

	_mesh = PrimitiveMeshBuilder.build_mesh(verts, _faces, {"double_sided": true})
	if _mesh:
		_mesh_instance.mesh = _mesh
		_mesh_instance.material_override = _material


# ═════════════════════════════════════════════════════════════════════════
# CONFIG
# ═════════════════════════════════════════════════════════════════════════

func configure(config: Dictionary) -> void:
	if config.has("fold_amount"):
		fold_amount = float(config["fold_amount"])
		target_fold = fold_amount
	if config.has("twist"):
		twist_amount = float(config["twist"])
	if config.has("radius"):
		cyl_radius = float(config["radius"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
