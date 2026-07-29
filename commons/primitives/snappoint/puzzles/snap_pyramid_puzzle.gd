extends SnapPointPuzzleBase
class_name SnapPyramidPuzzle

# @identity
# essence: square pyramid = 5 vertices, 8 edges, 5 faces (1 square + 4 triangles) — non-Platonic mixed solid
# desire: learner places 5 points and observes how a square base plus apex forces triangular sides
# critical_parameter: 5 snap target positions — 4 corners of a square base plus 1 apex above center
# triggers: snapping all 5 snap points to their targets → puzzle complete signal fires
# emerges: that the apex position determines whether the pyramid is regular or skewed — height is a free variable
# needs: apex height as a real, turnable parameter [has, 2026-07-29 — the `apex` axis]. Missing: VR controls besides snapping — no label or slider.
# relationships: extends SnapPointPuzzleBase; sibling to snap_tetrahedron_puzzle; pyramid.gd is its static version
# truth: a pyramid has a free parameter — apex height — that tetrahedra and octahedra do not

## Snap Square Pyramid Puzzle Controller
## Manages a 5-point pyramid puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

# ── DNA (promoted 2026-07-29, stage 2) ───────────────────────────────────────
# apex — the free parameter this artifact's own truth statement names: "a pyramid
# has a free parameter, apex height, that tetrahedra and octahedra do not". It was
# frozen in the scene file at y=0.7, so the claim was made but never demonstrated.
#   tall     apex 0.20 above the base (the historical scene)
#   regular  apex 0.1414 = s/sqrt(2) — lateral faces become equilateral (Johnson J1)
#   flat     apex 0.07 — a squat cap, the base dominates
#   spire    apex 0.35 — a needle, the base nearly vanishes
#   inverted apex 0.20 BELOW the base — the detector says "above/below", so this is
#            still a square pyramid, just not one gravity agrees with
@export_enum("tall", "regular", "flat", "spire", "inverted") var apex: String = "tall"

# base_shape — the 4 base points. The name says "square pyramid" but the detector
# only checks the 4-cycle + an apex joined to all of it. Turning this exposes the
# gap between what the solid is called and what is actually being recognised.
#   square   0.2 x 0.2 (the historical scene)
#   rect     0.28 x 0.14 — right angles, unequal edges
#   rhombus  equal edges, unequal diagonals — every side the same and still no square
@export_enum("square", "rect", "rhombus") var base_shape: String = "square"

const BASE_Y: float = 0.5
const APEX_Y: Dictionary = {
	"tall": 0.7,
	"regular": 0.6414,
	"flat": 0.57,
	"spire": 0.85,
	"inverted": 0.3,
}

var _geometry_applied: bool = false

func _ready() -> void:
	# Seat the 5 points at the declared geometry BEFORE the base stores initial
	# positions, so the reset timer returns them to the promoted shape. At the
	# defaults the geometry IS the scene file, so we do not touch the bodies at
	# all — shipped placements take no code path they did not take before.
	if not _is_scene_default():
		_apply_geometry()
	_geometry_applied = true

	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()

	# Call parent ready
	super._ready()

func _connect_signals() -> void:
	# Connect to square_pyramid formation signal
	if connection_manager:
		if not connection_manager.square_pyramid_formed.is_connected(_on_pyramid_formed):
			connection_manager.square_pyramid_formed.connect(_on_pyramid_formed)
		print("SnapPyramidPuzzle: Connected to square_pyramid_formed signal")

func _on_pyramid_formed(points: Array) -> void:
	# Check if this pyramid uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 5 points are ours, this is our pyramid!
	if our_points_count == 5:
		print("SnapPyramidPuzzle: Pyramid completed with our points!")
		_complete_puzzle()  # Call base class completion method

# ── Geometry (apex height + base outline) ───────────────────────────────────

## True when the declared axes describe exactly what snap_pyramid_puzzle.tscn
## already contains, so applying them would be a no-op write.
func _is_scene_default() -> bool:
	return apex == "tall" and base_shape == "square"

## (x, z) offsets per snap point name for the current base_shape.
func _base_offsets() -> Dictionary:
	var out: Dictionary = {
		"PointBaseBackLeft": Vector2(-0.1, -0.1),
		"PointBaseBackRight": Vector2(0.1, -0.1),
		"PointBaseFrontLeft": Vector2(-0.1, 0.1),
		"PointBaseFrontRight": Vector2(0.1, 0.1),
	}
	if base_shape == "rect":
		out = {
			"PointBaseBackLeft": Vector2(-0.14, -0.07),
			"PointBaseBackRight": Vector2(0.14, -0.07),
			"PointBaseFrontLeft": Vector2(-0.14, 0.07),
			"PointBaseFrontRight": Vector2(0.14, 0.07),
		}
	elif base_shape == "rhombus":
		# Diagonals 0.32 and 0.16 — all four edges sqrt(0.16^2 + 0.08^2), no right angles.
		out = {
			"PointBaseBackLeft": Vector2(0.0, -0.16),
			"PointBaseBackRight": Vector2(0.08, 0.0),
			"PointBaseFrontLeft": Vector2(-0.08, 0.0),
			"PointBaseFrontRight": Vector2(0.0, 0.16),
		}
	return out

func _apply_geometry() -> void:
	var offsets: Dictionary = _base_offsets()
	for point_name in offsets:
		var node: Node3D = get_node_or_null(str(point_name)) as Node3D
		if node == null:
			continue
		var off: Vector2 = offsets[point_name]
		_reseat_point(node, Vector3(off.x, BASE_Y, off.y))
	var apex_node: Node3D = get_node_or_null("PointApex") as Node3D
	if apex_node:
		_reseat_point(apex_node, Vector3(0.0, float(APEX_Y.get(apex, 0.7)), 0.0))

## Snap points are RigidBody3D pickables — move them without letting physics
## fight the change, and restore whatever freeze state they were in.
func _reseat_point(node: Node3D, pos: Vector3) -> void:
	if node is RigidBody3D:
		var body: RigidBody3D = node as RigidBody3D
		var was_frozen: bool = body.freeze
		body.freeze = true
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.position = pos
		body.freeze = was_frozen
	else:
		node.position = pos

## Grid config arrives deferred, i.e. after _ready has already stored the initial
## positions — so a real change must reseat AND re-store. Unchanged values do
## nothing at all, which is why the 17 existing placements are untouched.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var changed: bool = false
	if config_data.has("apex"):
		var a: String = str(config_data["apex"])
		if APEX_Y.has(a) and a != apex:
			apex = a
			changed = true
	if config_data.has("base_shape"):
		var b: String = str(config_data["base_shape"])
		if b in ["square", "rect", "rhombus"] and b != base_shape:
			base_shape = b
			changed = true
	if changed and _geometry_applied:
		_apply_geometry()
		_store_initial_positions()

func _apply_puzzle_materials() -> void:
	# Wait for snap points to be found
	await get_tree().process_frame
	
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(1.0, 0.3, 0.8, 0.6)  # Pink-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(1.0, 0.3, 0.8, 1.0)
	puzzle_material.emission_energy_multiplier = 2.0
	
	# Apply to all snap points
	for point in snap_points:
		if not point:
			continue
		
		# Find the MeshInstance3D child
		var mesh_instance = point.get_node_or_null("MeshInstance3D")
		if mesh_instance and mesh_instance is MeshInstance3D:
			# Apply material to the mesh instance
			mesh_instance.material_override = puzzle_material
			print("SnapPyramidPuzzle: Applied transparent material to ", point.name)
