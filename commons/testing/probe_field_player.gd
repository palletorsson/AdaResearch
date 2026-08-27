extends Node3D
## A STAND-IN PLAYER FOR A REAL MAP (2026-08-27).
##
## probe_crab_bite proved the animal bites on a bare floor. That is a fact about
## a fixture. This one is injected into Point_One through capture_in_map, so the
## grid seats the crab, the registry resolves the token, and the hunt happens on
## the map the visitor actually walks — the difference that has cost this
## project a pass more than once.
##
## It stands at the spawn cell and does not move: the question is whether the
## crab crosses the room, finds it, and takes it down.
var health: float = 100.0
var taken: float = 0.0
var hits: int = 0
var _t: float = 0.0
var _log: Array = []
var _crab: Node3D = null
var _written: bool = false
var _closest: float = 999.0

func _ready() -> void:
	add_to_group("player")
	add_to_group("player_body")
	_log.append("stand-in player at %s, 100 health" % str(global_position))

func take_damage(amount: float) -> void:
	taken += amount
	hits += 1
	health = maxf(0.0, health - amount)
	_log.append("%5.2f s  HIT %d for %.0f -> health %.0f" % [_t, hits, amount, health])
	if health <= 0.0:
		_log.append("%5.2f s  DEAD" % _t)
		_write()

func _process(delta: float) -> void:
	_t += delta
	if _crab == null or not is_instance_valid(_crab):
		for n in get_tree().get_nodes_in_group("hazards"):
			if String(n.name).to_lower().contains("crab"): _crab = n as Node3D
		if _crab == null:
			_crab = _find_crab(get_tree().root)
		if _crab != null:
			_log.append("%5.2f s  found the crab at %s, %.2f m away" % [_t, str(_crab.global_position), global_position.distance_to(_crab.global_position)])
	elif is_instance_valid(_crab):
		var d: float = global_position.distance_to(_crab.global_position)
		if d < _closest:
			_closest = d
			if d < 1.0 and not _log.is_empty() and not String(_log[_log.size() - 1]).contains("closed"):
				_log.append("%5.2f s  closed to %.2f m" % [_t, d])
	if _t > 30.0:
		_write()

func _find_crab(n: Node) -> Node3D:
	if n.get_script() != null and String(n.get_script().resource_path).contains("head_crab"):
		return n as Node3D
	for c in n.get_children():
		var r := _find_crab(c)
		if r != null: return r
	return null

func _write() -> void:
	if _written: return
	_written = true
	var body := "THE CRAB IN POINT_ONE, THROUGH THE REAL GRID\n\n"
	for l in _log: body += "  " + String(l) + "\n"
	body += "\n  closest approach %.2f m\n" % _closest
	body += "  hits %d for %.0f damage; health %.0f\n" % [hits, taken, health]
	body += "\n  VERDICT: %s\n" % ("it crossed the room and killed the player" if health <= 0.0 else ("it reached the player but did not finish" if hits > 0 else "it never landed a bite"))
	var f := FileAccess.open("res://ada_run/pointone_bite.txt", FileAccess.WRITE)
	if f != null: f.store_string(body); f.close()
	print(body)
