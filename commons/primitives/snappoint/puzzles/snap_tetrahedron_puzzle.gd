extends SnapPointPuzzleBase
class_name SnapTetrahedronPuzzle

# @identity
# essence: tetrahedron = 4 vertices, 6 edges, 4 triangular faces — the minimal 3D solid
# desire: learner constructs the simplest possible polyhedron from 4 floating snap points
# critical_parameter: 4 snap target positions — form the unique convex hull of 4 non-coplanar points
# triggers: snapping all 4 snap points to their targets → puzzle complete signal fires
# emerges: the tetrahedron as the 3D analog of the triangle — irreducible, minimum faces for enclosure
# needs: [missing VR controls besides snapping — no label or slider]
# relationships: extends SnapPointPuzzleBase; logical successor to triangle_line_puzzle in 3D
# truth: you cannot enclose volume with fewer than 4 faces — the tetrahedron is the minimum

## Snap Tetrahedron Puzzle Controller
## Manages a 4-point tetrahedron puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

func _ready() -> void:
	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()
	
	# Call parent ready
	super._ready()

func _connect_signals() -> void:
	# Connect to tetrahedron formation signal
	if connection_manager:
		if not connection_manager.tetrahedron_formed.is_connected(_on_tetrahedron_formed):
			connection_manager.tetrahedron_formed.connect(_on_tetrahedron_formed)
		print("SnapTetrahedronPuzzle: Connected to tetrahedron_formed signal")

func _on_tetrahedron_formed(points: Array) -> void:
	# Check if this tetrahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 4 points are ours, this is our tetrahedron!
	if our_points_count == 4:
		print("SnapTetrahedronPuzzle: Tetrahedron completed with our points!")
		_complete_puzzle()  # Call base class completion method

func _apply_puzzle_materials() -> void:
	# Wait for snap points to be found
	await get_tree().process_frame
	
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(0.3, 1.0, 0.8, 0.6)  # Cyan-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(0.3, 1.0, 0.8, 1.0)
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
			print("SnapTetrahedronPuzzle: Applied transparent material to ", point.name)
