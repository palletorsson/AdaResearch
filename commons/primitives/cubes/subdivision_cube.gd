extends XRToolsPickable

## Subdivision Cube - Recursive Division on Pickup
## When picked up, the cube halves in size and creates two copies
## Stops after 3 divisions

@export var max_divisions: int = 3
@export var division_color_shift: float = 0.15

var current_division: int = 0
var has_divided: bool = false

# Store references
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	super._ready()

	# Find mesh and collision shape
	mesh_instance = find_child("MeshInstance3D", true, false)
	collision_shape = find_child("CollisionShape3D", true, false)

	# Update initial color
	update_color_by_division()

func pick_up(by: Node3D) -> void:
	"""Override XRToolsPickable pick_up to trigger division"""
	if not has_divided and current_division < max_divisions:
		# Disable pickable immediately to prevent further interaction
		enabled = false

		# Set collision to non-interactive layer to prevent physics issues
		if collision_shape:
			collision_shape.disabled = true

		# Divide after a brief delay to let physics system release
		divide_cube_delayed()
	else:
		# If at max divisions, act like a normal pickable
		super.pick_up(by)

func divide_cube_delayed():
	"""Divide with a small delay to avoid physics system issues"""
	await get_tree().create_timer(0.05).timeout
	divide_cube()

func divide_cube():
	"""Divide this cube into two smaller cubes"""
	if has_divided:
		return

	has_divided = true
	print("SubdivisionCube: Dividing at level %d" % current_division)

	# Get current properties before any changes
	var current_scale = scale
	var current_position = global_position
	var current_rotation = global_rotation

	# Calculate new scale (half size)
	var new_scale = current_scale * 0.5

	# Calculate offset for positioning the two new cubes
	var offset_distance = (current_scale.x * 0.25)  # Separation distance

	# Create two new cubes
	var offset_right = transform.basis.x * offset_distance

	create_child_cube(current_position + offset_right, new_scale, current_rotation, current_division + 1)
	create_child_cube(current_position - offset_right, new_scale, current_rotation, current_division + 1)

	# Disable and hide before freeing
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED

	# Remove this cube after everything is set up
	queue_free()

func create_child_cube(pos: Vector3, new_scale: Vector3, rot: Vector3, division_level: int):
	"""Create a new subdivision cube at the specified position"""
	var scene = load("res://commons/primitives/cubes/subdivision_cube.tscn")
	if not scene:
		push_error("SubdivisionCube: Failed to load scene")
		return
	var new_cube = scene.instantiate()

	# Set division level before adding to tree
	new_cube.current_division = division_level

	# Add to scene
	get_parent().add_child(new_cube)

	# Position and scale after adding to tree
	new_cube.global_position = pos
	new_cube.scale = new_scale
	new_cube.global_rotation = rot

	# Apply slight velocity for visual effect
	var direction = (pos - global_position).normalized()
	new_cube.apply_central_impulse(direction * 0.5)

func set_division_level(level: int):
	"""Set the division level for this cube"""
	current_division = level
	update_color_by_division()

func update_color_by_division():
	"""Update cube color based on division level"""
	await get_tree().process_frame  # Wait for scene to be ready

	if not mesh_instance:
		mesh_instance = find_child("MeshInstance3D", true, false)

	if not mesh_instance:
		return

	# Get the mesh's material
	var material = mesh_instance.mesh.surface_get_material(0) if mesh_instance.mesh else null

	if material is ShaderMaterial:
		# Update shader parameters for color shift
		var hue_shift = current_division * division_color_shift
		var base_color = Color(0.34130228, 0.46391684, 0.8974577, 1)
		var shifted_color = Color.from_hsv(
			fmod(base_color.h + hue_shift, 1.0),
			base_color.s,
			base_color.v
		)
		material.set_shader_parameter("modelColor", shifted_color)
		material.set_shader_parameter("emissionColor", shifted_color)
