extends SnapPointPuzzleBase
class_name SnapOctahedronPuzzle

## Snap Octahedron Puzzle Controller
## Manages a 6-point octahedron puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

func _ready() -> void:
	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()
	
	# Call parent ready
	super._ready()

func _connect_signals() -> void:
	# Connect to octahedron formation signal
	if connection_manager:
		if not connection_manager.octahedron_formed.is_connected(_on_octahedron_formed):
			connection_manager.octahedron_formed.connect(_on_octahedron_formed)
		print("SnapOctahedronPuzzle: Connected to octahedron_formed signal")

func _on_octahedron_formed(points: Array) -> void:
	# Check if this octahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 6 points are ours, this is our octahedron!
	if our_points_count == 6:
		print("SnapOctahedronPuzzle: Octahedron completed with our points!")
		_complete_puzzle()  # Call base class completion method

func _apply_puzzle_materials() -> void:
	# Wait for snap points to be found
	await get_tree().process_frame
	
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(1.0, 0.8, 0.3, 0.6)  # Orange-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(1.0, 0.8, 0.3, 1.0)
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
			print("SnapOctahedronPuzzle: Applied transparent material to ", point.name)
