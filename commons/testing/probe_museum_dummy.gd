extends Node3D
## A stand-in for endless_museum: it answers walker_bitten and records what the
## real one would do — flash, shove, and on the third bite its own death.
var walker: Node3D = null
var bites: int = 0
var killed: bool = false
var kind: String = ""
var _at: float = 0.0

func walker_bitten(from: Vector3) -> void:
	if killed: return
	var now: float = float(Time.get_ticks_msec()) * 0.001
	if now - _at > 8.0: bites = 0
	_at = now
	bites += 1
	if walker != null and is_instance_valid(walker):
		var away: Vector3 = walker.global_position - from
		away.y = 0.0
		if away.length() > 0.001:
			walker.position += away.normalized() * 1.1
	if bites >= 3:
		on_lethal_touch("crab", from)

func on_lethal_touch(k: String, _at2: Vector3 = Vector3.ZERO) -> void:
	killed = true
	kind = k
