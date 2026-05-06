extends SnapPointPuzzleBase
class_name SnapWedgePuzzle

## Snap Wedge Puzzle Controller
## Manages a 6-point wedge puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

func _ready() -> void:
	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()
	
	# Call parent ready
	super._ready()

func _connect_signals() -> void:
	# Connect to wedge formation signal
	if connection_manager:
		if not connection_manager.wedge_formed.is_connected(_on_wedge_formed):
			connection_manager.wedge_formed.connect(_on_wedge_formed)
		print("SnapWedgePuzzle: Connected to wedge_formed signal")

func _on_wedge_formed(points: Array) -> void:
	# Check if this wedge uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 6 points are ours, this is our wedge!
	if our_points_count == 6:
		print("SnapWedgePuzzle: Wedge completed with our points!")
		_complete_puzzle()  # Call base class completion method

func _apply_puzzle_materials() -> void:
	# Wait for snap points to be found
	await get_tree().process_frame
	
	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(0.3, 0.8, 1.0, 0.6)  # Light blue with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = true
	puzzle_material.emission = Color(0.3, 0.8, 1.0, 1.0)
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
			print("SnapWedgePuzzle: Applied transparent material to ", point.name)
