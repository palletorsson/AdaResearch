extends SnapPointPuzzleBase
class_name SnapPyramidPuzzle

# @identity
# essence: square pyramid = 5 vertices, 8 edges, 5 faces (1 square + 4 triangles) — non-Platonic mixed solid
# desire: learner places 5 points and observes how a square base plus apex forces triangular sides
# critical_parameter: 5 snap target positions — 4 corners of a square base plus 1 apex above center
# triggers: snapping all 5 snap points to their targets → puzzle complete signal fires
# emerges: that the apex position determines whether the pyramid is regular or skewed — height is a free variable
# needs: [missing VR controls besides snapping — no label or slider]
# relationships: extends SnapPointPuzzleBase; sibling to snap_tetrahedron_puzzle; pyramid.gd is its static version
# truth: a pyramid has a free parameter — apex height — that tetrahedra and octahedra do not

## Snap Square Pyramid Puzzle Controller
## Manages a 5-point pyramid puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

func _ready() -> void:
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
