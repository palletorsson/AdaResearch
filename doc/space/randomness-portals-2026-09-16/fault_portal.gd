extends "res://commons/scenes/em/em_portal_stream.gd"
## Test seam: simulate a destination whose floor is missing.
var reject_destination := false

func _supported(p: Vector3) -> bool:
	if reject_destination and p.x > -500:
		return false
	return super._supported(p)
