extends StaticBody3D
## An explicitly selected runner target. Kept until its section is recycled.
var destroyed := false
var fragment_colour := Color("ede6d7")

func hit_by_runner_shot() -> bool:
	if destroyed: return false
	destroyed = true
	# Disable the real collision now, before the runner's next swept query.
	collision_layer = 0
	collision_mask = 0
	hide()
	return true
