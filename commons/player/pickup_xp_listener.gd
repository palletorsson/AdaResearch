extends Node
## Listens to ALL pickups and awards XP via GameManager.
## Add this as a child of XROrigin3D.

## XP awarded per pickup (can be overridden per object if it has xp_on_pickup property)
@export var default_xp: int = 1

## Only award XP once per object (prevents XP farming by dropping and picking up)
@export var once_per_object: bool = true

# Track objects that have already awarded XP
var _awarded_objects: Array[Node3D] = []

func _ready() -> void:
	# Wait for scene to be ready
	await get_tree().process_frame

	# Find all FunctionPickup nodes and connect to their signals
	_connect_to_pickups()

func _connect_to_pickups() -> void:
	var pickups = get_tree().get_nodes_in_group("pickup_functions")

	# If no group, search manually
	if pickups.is_empty():
		var left = XRToolsFunctionPickup.find_left(self)
		var right = XRToolsFunctionPickup.find_right(self)
		if left:
			pickups.append(left)
		if right:
			pickups.append(right)

	for pickup in pickups:
		if pickup is XRToolsFunctionPickup:
			if not pickup.has_picked_up.is_connected(_on_object_picked_up):
				pickup.has_picked_up.connect(_on_object_picked_up)
				print("PickupXPListener: Connected to ", pickup.name)

func _on_object_picked_up(what: Node3D) -> void:
	if not is_instance_valid(what):
		return

	# Check if already awarded XP for this object
	if once_per_object and what in _awarded_objects:
		return

	# Determine XP amount
	var xp_amount = default_xp
	if "xp_on_pickup" in what:
		xp_amount = what.xp_on_pickup

	# Award XP if amount > 0
	if xp_amount > 0 and GameManager:
		GameManager.add_points(xp_amount, what.global_position)
		print("PickupXPListener: +%d XP for picking up %s" % [xp_amount, what.name])

	# Track this object
	if once_per_object:
		_awarded_objects.append(what)

	# Clean up freed objects from tracking
	_awarded_objects = _awarded_objects.filter(func(obj): return is_instance_valid(obj))
