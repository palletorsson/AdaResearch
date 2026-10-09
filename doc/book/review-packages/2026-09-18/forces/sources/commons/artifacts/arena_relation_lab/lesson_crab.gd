extends "res://commons/hazards/head_crab/head_crab.gd"
## Scoped experiment: the original rig, movement, avoidance and feeding;
## selection limited to one nominated visitor/beacon and this station's food.
## No sight memory or damage. Base creature behavior elsewhere is unchanged.
var station: Node3D
var selection: Dictionary = {}
func _find_target() -> void:
	_target=null
func choose() -> Dictionary:
	if _rooted:return {}
	var best: Node3D=null
	var distance:=6.0
	var bait:=false
	var candidates: Array=[station.food,station.recipient()]
	for candidate in candidates:
		if not is_instance_valid(candidate) or _ignore.has(candidate):continue
		if candidate==station.food and not candidate.is_bait():continue
		var d=global_position.distance_to(candidate.global_position)
		if d<distance and _sees(candidate.global_position):
			best=candidate;distance=d;bait=candidate==station.food
	return {"node":best,"bait":bait,"dist":distance} if best!=null else {}
func _nearest_food() -> Dictionary:
	_target=null # no stale target when the nominated candidates disappear
	selection=choose()
	return selection
