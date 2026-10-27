extends "res://commons/hazards/head_crab/head_crab.gd"
## Keep the original pursuit, bite cooldown and amount; the Void owns recovery.
func _damage(_target: Node, amount: float) -> bool:
	var charge: Node = get_tree().get_first_node_in_group("void_health")
	if charge == null or not charge.has_method("apply_bite_damage"):
		return false
	if charge.suspended or charge.get_health() <= 0:
		return false
	charge.apply_bite_damage(amount)
	return true
