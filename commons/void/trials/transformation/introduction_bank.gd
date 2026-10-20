extends "res://commons/artifacts/adjustable_landing/adjustable_landing.gd"
## The original museum landing, with its controls on the approach deck.
func _update_readout() -> void:
	if not is_instance_valid(readout): return
	var relation := "EDGES MEET" if is_zero_approx(displacement) else "GAP %.2f m" % displacement
	readout.text = "BANK +%.2f m\n%s\nRESET BEFORE CROSSING" % [displacement, relation]
