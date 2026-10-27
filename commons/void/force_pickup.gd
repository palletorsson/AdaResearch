extends XRToolsFunctionPickup
## Void-only two-metre attraction; ordinary near-hand grabs retain XRTools behavior.
const Pull := preload("force_pull.gd")
const Rules := preload("player_rules.gd")

func _get_closest_ranged() -> Node3D:
	var best: Node3D
	var angle := cos(deg_to_rad(ranged_angle))
	for target in _object_in_ranged_area:
		if not is_instance_valid(target) or not target.can_pick_up(self) or not Pull.reachable(self,target):continue
		var alignment: float = (-global_basis.z).dot(global_position.direction_to(target.global_position))
		if alignment>angle:best = target;angle = alignment
	return best

func _pick_up_object(target: Node3D) -> void:
	if not is_instance_valid(target):return
	var ranged := not _object_in_grab_area.has(target)
	if ranged and not Pull.reachable(self,target):return
	if ranged and target is XRToolsPickable:
		var method: int = target.ranged_grab_method;var speed: float = target.ranged_grab_speed
		if method==XRToolsPickable.RangedMethod.NONE:return
		target.ranged_grab_method = XRToolsPickable.RangedMethod.LERP;target.ranged_grab_speed = Rules.PULL_SPEED
		super(target)
		# Some collectible tools consume themselves on pickup.
		if not is_instance_valid(target) or target.is_queued_for_deletion():return
		target.ranged_grab_method = method;target.ranged_grab_speed = speed
		if target.is_picked_up():Pull.begin(self,target)
	else:super(target)
