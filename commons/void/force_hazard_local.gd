extends "res://commons/hazards/force_field/force_field.gd"
## The same hazard/mediator rules address the same charge in desktop and VR.
func _deal_damage(amount: float) -> void:
	var host = get_tree().get_first_node_in_group("void_game")
	if host != null and amount > 0:
		host.charge.discharge(amount,"force field")
		damage_dealt.emit(amount)

func _heal_player(amount: float) -> void:
	var host = get_tree().get_first_node_in_group("void_game")
	if host != null and amount > 0: host.charge.set_charge(host.charge.get_charge()+amount,"force field")
