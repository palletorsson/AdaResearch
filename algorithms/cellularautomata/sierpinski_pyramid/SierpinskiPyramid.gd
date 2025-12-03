@tool
extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var depth: int = 4:
	set(value):
		depth = value
		if Engine.is_editor_hint():
			generate()

@export var size: float = 1.0:
	set(value):
		size = value
		if Engine.is_editor_hint():
			generate()

@export var generate_on_ready: bool = true

func _ready() -> void:
	if generate_on_ready and not Engine.is_editor_hint():
		generate()

func generate() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Start recursion
	# We start centered at (0,0,0) or base at (0,0,0)?
	# Let's put the base center at (0,0,0)
	_recursive_build(Vector3.ZERO, size * pow(2, depth - 1), depth)

func _recursive_build(pos: Vector3, current_size: float, current_depth: int) -> void:
	if current_depth == 0:
		_spawn_cube(pos)
		return
	
	var half_size = current_size / 2.0
	var quarter_size = half_size / 2.0
	
	# 5 sub-pyramids
	# Top
	_recursive_build(pos + Vector3(0, half_size, 0), half_size, current_depth - 1)
	
	# Base 4 corners
	# Assuming square base in XZ plane
	# Offsets should be half_size/2 from the center of the current volume?
	# If current volume is centered at 'pos' in XZ...
	
	# Let's visualize:
	# Depth 1 (1 iteration):
	# Top at (0, 0.5, 0) (relative)
	# Base at (+-0.25, -0.25, +-0.25)?
	# Height is 'current_size'.
	# If depth 0 is a cube of size 1.
	# Depth 1 should be height 2.
	
	# Let's rethink units.
	# Depth 0: 1 cube. Height 1.
	# Depth 1: 5 cubes. Height 2.
	# Top cube at y=1.5 (sitting on top of y=0.5 cubes).
	# Base cubes at y=0.5.
	# Base centers: (+-0.5, 0.5, +-0.5).
	# Top center: (0, 1.5, 0).
	
	# Offset distance = 0.5 * (2^(depth-1))?
	
	# Let's use the 'size' param as the size of the *base unit cube*.
	# 'current_depth' tells us how large the structure is.
	
	if current_depth == 1:
		# Base case for recursion logic (depth 1 -> 5 cubes)
		# Or just recurse until depth 0 (1 cube)
		pass
		
	# Recursive step:
	# We are building a pyramid of height H.
	# It consists of 5 pyramids of height H/2.
	# Top one is shifted up by H/2.
	# Bottom ones are shifted in X/Z by H/4?
	
	# Let's trace positions.
	# Center of the pyramid is 'pos'.
	# Height is 'current_size' (in units of distance, not cubes).
	
	# If we want them to stack perfectly:
	# The top pyramid sits on the intersection of the 4 bottom ones.
	# Shift Y: +half_size / 2.0
	# Shift XZ: +- half_size / 2.0 ?
	
	# Let's try:
	# Top: pos + (0, half_size/2, 0)
	# Bottoms: pos + (+-half_size/2, -half_size/2, +-half_size/2)
	
	# Wait, if H=2.
	# Top center y = 0.5.
	# Bottom center y = -0.5.
	# Distance = 1.0. Correct.
	
	# X offset:
	# Bottom centers x = +-0.5.
	# Distance = 1.0.
	# So they touch at x=0. Correct.
	
	var offset = half_size / 2.0
	
	# Top
	_recursive_build(pos + Vector3(0, offset, 0), half_size, current_depth - 1)
	
	# Bottoms
	_recursive_build(pos + Vector3(-offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, -offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(-offset, -offset, offset), half_size, current_depth - 1)
	_recursive_build(pos + Vector3(offset, -offset, offset), half_size, current_depth - 1)

func _spawn_cube(pos: Vector3) -> void:
	var cube = CUBE_SCENE.instantiate()
	add_child(cube)
	cube.position = pos
	# Scale the cube? The scene is 1x1x1.
	# If 'size' is 1.0, we use scale 1.
	# If 'size' is different, we might need to scale.
	# But the recursion logic assumes 'size' is the total size, reducing down.
	# At depth 0, 'current_size' is what?
	# In my logic:
	# Call: size * 2^(depth-1)
	# Depth 1: size * 1.
	# Recursive: half_size = size/2.
	# Depth 0: size/2?
	
	# Let's adjust the initial call so that at depth 0, current_size == size.
	# Initial call size: size * pow(2, depth)
	# Then at depth 0, size is 'size'.
	
	# Actually, let's just use 'size' as the unit cube size.
	# And the offsets are based on that.
	
	cube.scale = Vector3(size, size, size)
