extends XRToolsPickable

## Subdivision Cube - Recursive Division on Touch/Pickup
## When touched or picked up, the cube halves in size and creates two copies
## Stops after max_divisions

@export var max_divisions: int = 3
@export var division_color_shift: float = 0.15
@export var divide_on_touch: bool = true  # Enable touch-to-divide
@export var touch_cooldown: float = 0.5  # Prevent rapid re-triggering
@export var impulse_strength: float = 1.0  # How hard children fly apart

var current_division: int = 0
var has_divided: bool = false
var touch_cooldown_timer: float = 0.0

# Store references
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _ready():
	super._ready()

	# Find mesh and collision shape
	mesh_instance = find_child("MeshInstance3D", true, false)
	collision_shape = find_child("CollisionShape3D", true, false)

	# Connect body_entered signal for touch detection
	if divide_on_touch:
		body_entered.connect(_on_body_entered)

	# Update initial color
	update_color_by_division()

func _process(delta: float):
	if touch_cooldown_timer > 0:
		touch_cooldown_timer -= delta

func _on_body_entered(body: Node):
	"""Handle touch/collision to trigger division"""
	if not divide_on_touch:
		return

	if has_divided or current_division >= max_divisions:
		return

	if touch_cooldown_timer > 0:
		return

	# Check if it's a hand/controller or another physics body
	var is_hand = body.name.contains("Hand") or body.name.contains("Controller")
	var is_player = body.is_in_group("player") or body.name.contains("Player")

	# Divide on hand touch or player collision
	if is_hand or is_player or body is CharacterBody3D:
		touch_cooldown_timer = touch_cooldown
		print("SubdivisionCube: Touched by %s, dividing!" % body.name)
		divide_cube_delayed()

func pick_up(by: Node3D) -> void:
	"""Override XRToolsPickable pick_up to trigger division"""
	if not has_divided and current_division < max_divisions:
		# Don't actually pick up - just divide
		# We need to reject the pickup gracefully without causing errors
		# Mark as divided first to prevent re-entry
		has_divided = true

		# Clear pickup state in the controller immediately, since this cube
		# intentionally rejects being held while it is dividing.
		if by and by.has_method("drop_object"):
			by.drop_object()

		# Use call_deferred to let the pickup system complete its frame
		call_deferred("_do_division_from_pickup")
		return

	# If at max divisions, act like a normal pickable
	super.pick_up(by)

func _do_division_from_pickup():
	"""Deferred division to avoid pickup system conflicts"""
	# Reset has_divided so divide_cube can set it properly
	has_divided = false

	# Disable pickable
	enabled = false

	# Disable collision
	if collision_shape:
		collision_shape.disabled = true

	# Small delay then divide
	await get_tree().create_timer(0.05).timeout
	divide_cube()

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

	# Apply impulse for visual effect - scales with division level
	var direction = (pos - global_position).normalized()
	var impulse_scale = impulse_strength * (1.0 + current_division * 0.5)
	new_cube.apply_central_impulse(direction * impulse_scale)

	# Add some spin for visual interest
	var random_torque = Vector3(
		randf_range(-1, 1),
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized() * impulse_scale * 0.3
	new_cube.apply_torque_impulse(random_torque)

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
