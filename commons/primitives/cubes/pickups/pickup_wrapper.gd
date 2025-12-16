extends "res://commons/scenes/mapobjects/pick_up_cube.gd"

func _ready() -> void:
	super._ready()
	_disable_internal_collision()

func _disable_internal_collision() -> void:
	# Recursively find all StaticBody3D nodes in the visual instance
	# and disable them so they don't block the player from entering the pickup area
	_disable_collision_recursive(self)

func _disable_collision_recursive(node: Node) -> void:
	if node is StaticBody3D:
		# Disable collision layers/masks so it passes through everything
		node.collision_layer = 0
		node.collision_mask = 0
		# Also try to disable the collision shape specifically if present
		for child in node.get_children():
			if child is CollisionShape3D:
				child.disabled = true
				
	for child in node.get_children():
		_disable_collision_recursive(child)
