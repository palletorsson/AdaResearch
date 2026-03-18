extends RigidBody3D

@export var damage: float = 5.0
@export var speed: float = 8.0
@export var lifetime: float = 5.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_body_entered(body: Node) -> void:
	# Check if body is player or player part
	# Often XR players are composed of multiple bodies (Head, Hands, etc.)
	# We'll check for methods or groups, or fallback to GameManager if we hit a "Player" named thing
	
	var handled = false
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		handled = true
	elif body.get_parent() and body.get_parent().has_method("take_damage"):
		body.get_parent().take_damage(damage)
		handled = true
	
	# Fallback: Check if it's likely the player and use GameManager
	if not handled and (body.name.contains("Player") or body.name.contains("Origin") or body.name.contains("Camera") or body.is_in_group("player") or body.is_in_group("player_body")):
		GameManager.apply_health_damage(damage)
		handled = true
	
	if handled:
		# Hit effect?
		queue_free()
	else:
		# Hit wall/floor
		queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
