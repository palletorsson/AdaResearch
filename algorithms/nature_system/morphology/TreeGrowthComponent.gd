class_name TreeGrowthComponent
extends Node3D

## TreeGrowthComponent
## A strictly typed component demonstrating token-efficient architecture.
## It only requires `CritterDNA` as input and returns a mathematical skeleton.
## It has no dependency on the larger Nature System, no giant scene references,
## and is under 100 lines of code.

# The interface contract: We only accept a validated CritterDNA resource.
@export var dna: CritterDNA

## Returns an Array of Transform3D representing the positions/rotations of branches.
## We abstract away the visual mesh generation to save context complexity.
func generate_skeleton() -> Array[Transform3D]:
	if not dna:
		push_error("TreeGrowthComponent: No CritterDNA provided.")
		return []
		
	var skeleton: Array[Transform3D] = []
	var base_transform := Transform3D.IDENTITY.scaled(Vector3.ONE * dna.scale)
	
	# Pass the recursive call
	# Depth is governed by dna.segments (constrained by nature to prevent infinite loops)
	_grow_branch(base_transform, int(dna.segments), skeleton)
	
	return skeleton

## Recursive L-System style branching decoupled from visuals.
func _grow_branch(current_transform: Transform3D, depth_remaining: int, skeleton: Array[Transform3D]) -> void:
	if depth_remaining <= 0:
		return
		
	# Store current node
	skeleton.append(current_transform)
	
	# The DNA dictates how quickly branches diminish in size
	var new_scale = current_transform.basis.get_scale() * dna.branch_decay
	
	# Calculate forward growth (part_length dictates segment distance)
	var forward_step = current_transform.basis.y * dna.part_length * new_scale.y
	var next_pos = current_transform.origin + forward_step
	
	# Biological Symmetry dictatates how many branches split off this node
	var branch_count = int(dna.symmetry)
	var angle_step = deg_to_rad(360.0 / float(max(1, branch_count)))
	
	for i in range(branch_count):
		# DNA dictates the split angle and twisting forces
		var twist = angle_step * i + deg_to_rad(dna.part_twist)
		var pitch = deg_to_rad(dna.branch_angle)
		
		# Apply rotations
		var new_basis = current_transform.basis.rotated(current_transform.basis.y.normalized(), twist)
		new_basis = new_basis.rotated(new_basis.x.normalized(), pitch)
		
		# Create the child branch transform
		var next_transform = Transform3D(new_basis, next_pos)
		
		# Recurse
		_grow_branch(next_transform, depth_remaining - 1, skeleton)
