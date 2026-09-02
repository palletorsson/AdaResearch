extends Node3D

## Do the silhouettes draw, and do they walk the grid one metre at a time?
## (2026-08-29)
##
## Two claims, both of the kind that fail silently. A procedural sprite can come
## out as an empty texture and still be "built"; a stepping body can drift by a
## collider's thickness per step and still look like it moved. So this writes six
## seeds to disk as PNGs, then stands three silhouettes on a floor with a fake
## player and watches them for four seconds, asserting that every position change
## is EXACTLY one metre along exactly one axis, and that they close the distance.
##
## A SCENE, run windowed or headless (physics runs either way):
##   godot --path . --headless --xr-mode off res://commons/testing/probe_silhouettes.tscn

const FOE := preload("res://commons/hazards/catalyst_foe/catalyst_foe.tscn")
const Sprite := preload("res://commons/hazards/catalyst_foe/silhouette_sprite.gd")

var _foes: Array[Node3D] = []
var _last: Array[Vector3] = []
var _steps: int = 0
var _bad: int = 0
var _centrings: Dictionary = {}
var _player: Node3D = null
var _t: float = 0.0


func _ready() -> void:
	# ── 1. six figures to disk ─────────────────────────────────────────
	DirAccess.make_dir_recursive_absolute("user://silhouettes")
	var opaque: Array = []
	for s in [1, 2, 3, 4, 5, 6]:
		var img: Image = Sprite.make_image(s * 7919)
		var n := 0
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				if img.get_pixel(x, y).a > 0.5:
					n += 1
		opaque.append(n)
		img.save_png("user://silhouettes/seed_%d.png" % s)
	print("[probe] six figures written; opaque pixels per seed: %s" % str(opaque))
	var empty: int = 0
	for n in opaque:
		if int(n) < 400:
			empty += 1
	print("[probe] figures with fewer than 400 opaque px: %d  %s" % [empty, "OK" if empty == 0 else "*** an empty sprite ***"])
	var same := opaque.count(opaque[0]) == opaque.size()
	print("[probe] all six identical: %s  %s" % [str(same), "OK (they differ)" if not same else "*** seed ignored ***"])

	# ── 2. a floor on layer 1, a fake player, three silhouettes ──────────
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 0.2, 30)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

	_player = Node3D.new()
	_player.name = "FakePlayer"
	_player.position = Vector3(0.5, 0.0, 0.5)
	add_child(_player)

	for i in range(3):
		var f: Node3D = FOE.instantiate() as Node3D
		f.set("body", "silhouette")
		f.set("silhouette_seed", 100 + i)
		f.set("silhouette_step_s", 0.3)
		f.set("phase", "foe")
		f.position = Vector3(6.5 + i, 0.0, 4.5 - i * 2)
		add_child(f)
		_foes.append(f)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for f in _foes:
		f.set("_player_node", _player)
		f.set("_state", 3)   # BaseState.CHASE
		_last.append(f.global_position)
	var before: float = _mean_dist()
	print("[probe] three silhouettes standing; mean distance to player %.2f m" % before)
	set_meta("before", before)


func _physics_process(delta: float) -> void:
	if _foes.is_empty() or _last.is_empty():
		return
	_t += delta
	for i in range(_foes.size()):
		var f := _foes[i]
		if not is_instance_valid(f):
			continue
		var p: Vector3 = f.global_position
		var d: Vector3 = p - _last[i]
		if d.length() > 0.001 and d.length() < 0.5:
			# a CENTRING, not a step: the body settling onto its cell before its
			# first walk. Allowed once per foe, and counted apart so it cannot hide
			# among the walks or be hidden by them.
			_centrings[i] = int(_centrings.get(i, 0)) + 1
			_last[i] = p
			continue
		if d.length() > 0.001:
			_steps += 1
			var one_axis: bool = (absf(d.x) > 0.001) != (absf(d.z) > 0.001)
			var one_metre: bool = absf(absf(d.x) + absf(d.z) - 1.0) < 0.01
			var level: bool = absf(d.y) < 0.02
			if not (one_axis and one_metre and level):
				_bad += 1
				print("[probe]   BAD step on foe %d: %s" % [i, str(d)])
			_last[i] = p
	if _t >= 4.0:
		_finish()


func _finish() -> void:
	set_physics_process(false)
	var after: float = _mean_dist()
	var before: float = float(get_meta("before", 0.0))
	print("[probe] %d step(s) taken in 4 s, %d not exactly one metre on one axis  %s" % [
		_steps, _bad, "OK" if _steps >= 6 and _bad == 0 else "*** FAIL ***"])
	print("[probe] mean distance to player %.2f m -> %.2f m  %s" % [
		before, after, "OK (they closed in)" if after < before - 1.5 else "*** did not approach ***"])
	var over: int = 0
	for k in _centrings:
		if int(_centrings[k]) > 1:
			over += 1
	print("[probe] centrings: %s  %s" % [str(_centrings), "OK (at most one each)" if over == 0 else "*** a body re-centred: it is drifting ***"])
	var ok: bool = _steps >= 6 and _bad == 0 and over == 0 and after < before - 1.5
	print("[probe] %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)


func _mean_dist() -> float:
	var s := 0.0
	var n := 0
	for f in _foes:
		if is_instance_valid(f):
			var a: Vector3 = f.global_position
			var b: Vector3 = _player.global_position
			s += Vector2(a.x - b.x, a.z - b.z).length()
			n += 1
	return s / maxf(1.0, float(n))
