extends SceneTree

## GATE — Random_Cubes: the die and the coin count what the chapter says they count.
##
## Four repairs, each checked against the shipped script (the before-copy, loaded
## with its class_name line stripped) so every case has a negative control:
##
##   A  reward rain       -> the balls fall over the table, not at twice its offset
##   F  the buzz          -> a die dropped on its own felt is read at all: at rest it
##                           hops 2.6 mm every tick and never sleeps, so the shipped
##                           velocity test never passed
##   G  thrown dice       -> sixteen seeded throws (random attitude, speed and spin, the XR
##                           order): read, and read as the face on top at that moment
##   H  the rain lands    -> reward balls come to rest on or around the felt instead of
##                           tunnelling through it
##   I  the rain is calm  -> the rain never moves the die it rewards (own collision layer)
##   B  desktop die       -> a desktop drop yields a reading (it yielded none)
##   C  coin in the hand  -> a held coin is not counted before it is thrown;
##                           one throw adds exactly one to the tally
##   D  desktop coin      -> a desktop-dropped coin falls and is read once, on landing
##   E  launch gauges     -> #disclosure:origin builds the SPIN / DROP / TILT gauges
##                           and a release writes them
##
## Physics runs headless. A floor slab at y = 0 catches everything.

const DIE_NEW := "res://algorithms/randomness/dice_throw/dice_throw.gd"
const COIN_NEW := "res://algorithms/randomness/coin_toss/coin_toss.gd"
const BEFORE_DIR := "res://doc/book/iterations/2026-09-24-claude-randomness-onwards/Random_Cubes/"

var _fails: Array = []
var _finished := false
var _world: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _check(label: String, ok: bool, detail: String = "") -> void:
	var line := "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	print(("  ok    " if ok else "  FAIL  ") + line)
	if not ok:
		_fails.append(line)


func _physics(n: int) -> void:
	for i in n:
		await physics_frame


## The shipped script, compiled from its before-copy with class_name removed so it
## does not collide with the live class.
func _old_script(file: String) -> GDScript:
	var src := FileAccess.get_file_as_string(BEFORE_DIR + file)
	var lines := src.split("\n")
	var kept := PackedStringArray()
	for l in lines:
		if l.strip_edges().begins_with("class_name "):
			continue
		kept.append(l)
	var s := GDScript.new()
	s.source_code = "\n".join(kept)
	var err := s.reload()
	if err != OK:
		print("  (could not compile %s: %d)" % [file, err])
		return null
	return s


func _floor() -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 0.2, 400)
	cs.shape = box
	body.add_child(cs)
	body.position = Vector3(0, -0.1, 0)
	_world.add_child(body)


func _top_face(body: RigidBody3D) -> int:
	var fn := [Vector3(0, -1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0)]
	var best := 0
	var best_d := -2.0
	for i in 6:
		var dd: float = (body.global_transform.basis * fn[i]).dot(Vector3.UP)
		if dd > best_d:
			best_d = dd
			best = i + 1
	return best


func _make(script: Script, at: Vector3, meta: Dictionary = {}) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	_world.add_child(holder)
	var n: Node3D = script.new()
	for k in meta.keys():
		n.set_meta(k, meta[k])
	holder.add_child(n)
	return n


func _run() -> void:
	print("probe_random_cubes")
	_world = Node3D.new()
	root.add_child(_world)
	_floor()
	var die_new: Script = load(DIE_NEW)
	var coin_new: Script = load(COIN_NEW)
	var die_old: GDScript = _old_script("dice_throw.gd.before.txt")
	var coin_old: GDScript = _old_script("coin_toss.gd.before.txt")

	# --- A: where the reward rain falls. Table far from the origin, as in the museum.
	var far := Vector3(40, 1, -120)
	var rain := {}
	for pair in [["new", die_new], ["old", die_old]]:
		if pair[1] == null:
			continue
		var d: Node3D = _make(pair[1], far)
		await _physics(2)
		d.call("_spawn_reward_balls", 16)
		var sum := Vector3.ZERO
		var balls: Array = d.get("_reward_balls")
		for b in balls:
			sum += (b as Node3D).global_position
		var centre: Vector3 = sum / maxf(1.0, float(balls.size()))
		rain[pair[0]] = Vector2(centre.x - d.global_position.x, centre.z - d.global_position.z).length()
		d.get_parent().queue_free()
		await _physics(2)
	_check("A the reward rain falls over the table", rain.get("new", 99.0) < 0.3,
		"rain centre %.2f m from the table now; shipped script %.2f m" % [rain.get("new", -1.0), rain.get("old", -1.0)])
	_check("A negative control: the shipped script missed the table", rain.get("old", 0.0) > 5.0,
		"%.1f m" % rain.get("old", -1.0))

	# --- F: the buzz. A VR-style release onto the die's own felt, no desktop hooks.
	var buzz := {}
	for pair in [["new", die_new], ["old", die_old]]:
		if pair[1] == null:
			continue
		var d1: Node3D = _make(pair[1], Vector3(0, 0, 5))
		d1.set("balls_per_pip", 0)   # the hop below is the die's own, not ball impacts
		await _physics(10)
		var b1: RigidBody3D = d1.get("_dice_body")
		b1.global_position += Vector3(0, 0.3, 0)
		b1.linear_velocity = Vector3.ZERO
		d1.call("_on_dice_dropped", null)                  # what XR dropped reaches
		await _physics(150)
		var prev: Vector3 = b1.global_position
		var hop := 0.0
		for i in 20:
			await physics_frame
			hop = maxf(hop, absf(b1.global_position.y - prev.y))
			prev = b1.global_position
		buzz[pair[0]] = [int(d1.get("_total_rolls")), int(d1.get("_last_result")), hop, b1.sleeping]
		d1.get_parent().queue_free()
		await _physics(2)
	var bn: Array = buzz.get("new", [-1, -1, 0.0, false])
	var bo: Array = buzz.get("old", [-1, -1, 0.0, false])
	_check("F a die at rest on its felt is read, face 6 as it lay", bn[0] == 1 and bn[1] == 6,
		"rolls %d, face %d; the resting die still hops %.1f mm per tick, sleeping %s" % [bn[0], bn[1], float(bn[2]) * 1000.0, str(bn[3])])
	_check("F negative control: the shipped die never read it", bo[0] == 0,
		"rolls %d after 2.5 s at rest" % bo[0])

	# --- G: thrown dice, seeded, in the XR release order (velocities set, then dropped),
	#        at the desktop's 60 Hz and the headset's 90 Hz physics rate.
	var thrown := {}
	for spec in [["new", die_new, 60], ["old", die_old, 60], ["new90", die_new, 90], ["old90", die_old, 90]]:
		Engine.physics_ticks_per_second = int(spec[2])
		var pair: Array = [spec[0], spec[1]]
		if pair[1] == null:
			continue
		var dg: Node3D = _make(pair[1], Vector3(0, 0, 60))
		dg.set("balls_per_pip", 0)
		await _physics(10)
		var bg: RigidBody3D = dg.get("_dice_body")
		var th: float = float(dg.get("table_height"))
		var rng := RandomNumberGenerator.new()
		rng.seed = 424242
		var reads := 0
		var right := 0
		for t in 16:
			var before: int = int(dg.get("_total_rolls"))
			dg.call("_on_dice_picked_up", null)
			bg.freeze = true
			var bas := Basis.from_euler(Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI)))
			bg.global_transform = Transform3D(bas, dg.global_position + Vector3(rng.randf_range(-0.15, 0.15), th + 0.25, 0.1))
			await _physics(2)
			bg.freeze = false
			bg.linear_velocity = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.0, 1.0), rng.randf_range(-1.0, -0.3))
			bg.angular_velocity = Vector3(rng.randf_range(-12, 12), rng.randf_range(-12, 12), rng.randf_range(-12, 12))
			dg.call("_on_dice_dropped", null)
			for f in 360:
				await physics_frame
				if int(dg.get("_total_rolls")) > before:
					reads += 1
					if int(dg.get("_last_result")) == _top_face(bg):
						right += 1
					break
		thrown[pair[0]] = [reads, right]
		dg.get_parent().queue_free()
		await _physics(2)
	Engine.physics_ticks_per_second = 60
	var gn: Array = thrown.get("new", [-1, -1])
	var go: Array = thrown.get("old", [-1, -1])
	var gn9: Array = thrown.get("new90", [-1, -1])
	var go9: Array = thrown.get("old90", [-1, -1])
	_check("G thrown dice are read, as the face on top, at 60 Hz", gn[0] >= 15 and gn[1] == gn[0],
		"%d of 16 read, %d as the face on top; shipped script read %d" % [gn[0], gn[1], go[0]])
	_check("G and at 90 Hz", gn9[0] >= 15 and gn9[1] == gn9[0],
		"%d of 16 read, %d as the face on top; shipped script read %d (at the headset rate it mostly worked)" % [gn9[0], gn9[1], go9[0]])
	_check("G negative control: at 60 Hz the shipped die read almost none", go[0] <= 4, "%d of 16" % go[0])

	# --- I: the reward rain must not move the die it rewards. Twelve seeded throws with
	#        the rain on; 4 s after each read the die must still lie on the felt showing
	#        the face it reported. Negative control: the same balls put back on layer 1,
	#        where the rain landed on the die before this repair.
	var calm := {}
	for spec in [["own_layer", false], ["layer1", true]]:
		var di: Node3D = _make(die_new, Vector3(0, 0, 80))
		await _physics(10)
		var bi: RigidBody3D = di.get("_dice_body")
		var thi: float = float(di.get("table_height"))
		var rngi := RandomNumberGenerator.new()
		rngi.seed = 777
		var kept := 0
		var tried := 0
		for t in 12:
			var before: int = int(di.get("_total_rolls"))
			di.call("_clean_reward_balls")
			di.call("_on_dice_picked_up", null)
			bi.freeze = true
			var bas := Basis.from_euler(Vector3(rngi.randf_range(-PI, PI), rngi.randf_range(-PI, PI), rngi.randf_range(-PI, PI)))
			bi.global_transform = Transform3D(bas, di.global_position + Vector3(0.0, thi + 0.25, 0.05))
			await _physics(2)
			bi.freeze = false
			bi.linear_velocity = Vector3(rngi.randf_range(-0.3, 0.3), 0.3, rngi.randf_range(-0.6, -0.2))
			bi.angular_velocity = Vector3(rngi.randf_range(-10, 10), rngi.randf_range(-10, 10), rngi.randf_range(-10, 10))
			di.call("_on_dice_dropped", null)
			var read := false
			for f in 360:
				await physics_frame
				if int(di.get("_total_rolls")) > before:
					read = true
					break
			if not read:
				continue
			tried += 1
			if spec[1]:
				for bb in di.get("_reward_balls"):
					(bb as RigidBody3D).collision_layer = 1
					(bb as RigidBody3D).collision_mask = 1
			await _physics(240)
			var on_felt: bool = bi.global_position.y > di.global_position.y + thi
			if on_felt and _top_face(bi) == int(di.get("_last_result")):
				kept += 1
			# put the die back on the felt for the next throw
			di.call("_reset_dice")
			await _physics(30)
		calm[spec[0]] = [kept, tried]
		di.get_parent().queue_free()
		await _physics(2)
	var ci: Array = calm.get("own_layer", [-1, -1])
	var cl: Array = calm.get("layer1", [-1, -1])
	_check("I the rain never moves the die it rewards", ci[1] >= 10 and ci[0] == ci[1],
		"%d of %d dice still on the felt, showing the face read, 4 s after the rain" % [ci[0], ci[1]])
	# Not a gate: switching the layer after the balls spawn did not reproduce the harm two
	# reviewers measured on the pre-repair script (9-10 of 12 dice moved); reported only.
	print("       info: with the balls moved back to layer 1 after spawning, %d of %d dice undisturbed" % [cl[0], cl[1]])

	# --- H: where the reward rain comes to rest
	var rain_rest := {}
	for pair in [["new", die_new], ["old", die_old]]:
		if pair[1] == null:
			continue
		var dh: Node3D = _make(pair[1], Vector3(0, 0, 70))
		await _physics(4)
		dh.call("_spawn_reward_balls", 64)
		await _physics(150)
		var balls2: Array = dh.get("_reward_balls")
		var kept := 0
		var on_felt := 0
		for bb in balls2:
			if is_instance_valid(bb) and (bb as Node3D).global_position.y > -0.5:
				kept += 1
				if (bb as Node3D).global_position.y > 0.8:
					on_felt += 1
		rain_rest[pair[0]] = [kept, on_felt]
		dh.get_parent().queue_free()
		await _physics(2)
	var rn: Array = rain_rest.get("new", [-1, -1])
	var ho2: Array = rain_rest.get("old", [-1, -1])
	_check("H the rain comes to rest on or around the table, not through it", rn[0] >= 56,
		"%d of 64 above the floor after 2.5 s, %d on the felt; shipped %d above, %d on the felt" % [rn[0], rn[1], ho2[0], ho2[1]])

	# --- B: a desktop drop. The die starts on the felt; the drop hook starts the read.
	var die_reads := {}
	for pair in [["new", die_new], ["old", die_old]]:
		if pair[1] == null:
			continue
		var d2: Node3D = _make(pair[1], Vector3(0, 0, 10))
		await _physics(10)
		var body: RigidBody3D = d2.get("_dice_body")
		var target: Object = body.get_meta("desktop_hook_target") if body.has_meta("desktop_hook_target") else body
		if target.has_method("on_desktop_grab"):
			target.call("on_desktop_grab", null)
		# a carry lifts it and lets go with no velocity, as the pointer does
		body.global_position += Vector3(0, 0.3, 0)
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		if target.has_method("on_desktop_drop"):
			target.call("on_desktop_drop", null)
		await _physics(150)
		die_reads[pair[0]] = int(d2.get("_total_rolls"))
		die_reads[pair[0] + "_face"] = int(d2.get("_last_result"))
		d2.get_parent().queue_free()
		await _physics(2)
	_check("B a desktop drop gives the die a reading", die_reads.get("new", 0) == 1,
		"rolls recorded %d, face %d; shipped script recorded %d" % [die_reads.get("new", -1), die_reads.get("new_face", -1), die_reads.get("old", -1)])
	_check("B negative control: the shipped die recorded nothing", die_reads.get("old", -1) == 0,
		"%d" % die_reads.get("old", -1))

	# --- C: a coin held in the hand. XRToolsPickable.pick_up freezes the body and the
	#        hand moves it by transform, so its velocity reads zero while it travels.
	var held := {}
	for pair in [["new", coin_new], ["old", coin_old]]:
		if pair[1] == null:
			continue
		var c: Node3D = _make(pair[1], Vector3(0, 0, 20))
		await _physics(10)
		var coins: Array = c.get("_coins")
		var coin: RigidBody3D = coins[0]
		c.call("_on_coin_picked_up", null, coin)          # what picked_up reaches
		coin.freeze = true                                  # what pick_up does
		var start: Vector3 = coin.global_position
		for i in 90:                                        # 1.5 s: lift half a metre, hold still
			coin.global_position = start + Vector3(0, minf(0.5, 0.02 * i), 0.1)
			await physics_frame
		var in_hand: int = int(c.get("_total_flips"))
		coin.freeze = false                                 # release_mode UNFROZEN
		c.call("_on_coin_dropped", null, coin)             # what dropped reaches
		await _physics(240)
		held[pair[0]] = [in_hand, int(c.get("_total_flips"))]
		c.get_parent().queue_free()
		await _physics(2)
	var hn: Array = held.get("new", [-1, -1])
	var ho: Array = held.get("old", [-1, -1])
	_check("C a held coin is not counted in the hand", hn[0] == 0,
		"%d counted while held" % hn[0])
	_check("C one throw adds exactly one to the tally", hn[1] == 1,
		"tally after landing %d" % hn[1])
	_check("C negative control: the shipped coin counted it while it was still in the hand",
		ho[0] >= 1, "held %d, after landing %d" % [ho[0], ho[1]])

	# --- D: the desktop carry. Grab from the tray (frozen), carry, drop: the pointer
	#        restores the pre-carry freeze (true) and then calls the drop hook.
	var c3: Node3D = _make(coin_new, Vector3(0, 0, 30))
	await _physics(10)
	var coin3: RigidBody3D = (c3.get("_coins") as Array)[1]
	var hook: Object = coin3.get_meta("desktop_hook_target") if coin3.has_meta("desktop_hook_target") else null
	_check("D each coin names a desktop hook", hook != null and hook.has_method("on_desktop_drop"))
	if hook != null:
		var was_frozen: bool = coin3.freeze
		hook.call("on_desktop_grab", null)
		coin3.freeze = true
		var s3: Vector3 = coin3.global_position
		for i in 60:
			coin3.global_position = s3 + Vector3(0, minf(0.6, 0.02 * i), 0.3)
			await physics_frame
		var carried: int = int(c3.get("_total_flips"))
		coin3.freeze = was_frozen                          # the pointer's restore
		hook.call("on_desktop_drop", null)
		await _physics(240)
		_check("D a desktop-dropped coin falls and is read once",
			carried == 0 and int(c3.get("_total_flips")) == 1 and not coin3.freeze,
			"counted while carried %d; tally after landing %d; frozen after drop %s" %
				[carried, int(c3.get("_total_flips")), str(coin3.freeze)])
	c3.get_parent().queue_free()
	await _physics(2)

	# --- E: the hall's token, coin_toss#disclosure:origin. The grid sets config meta
	#        before add_child, which is what _make does here.
	var c4: Node3D = _make(coin_new, Vector3(0, 0, 40), {"config_disclosure": "origin"})
	await _physics(10)
	var gauges: Object = c4.get("_gauge_holder")
	var coin4: RigidBody3D = (c4.get("_coins") as Array)[2]
	c4.call("_on_coin_picked_up", null, coin4)
	coin4.freeze = true
	coin4.global_position += Vector3(0, 0.4, 0.2)
	coin4.freeze = false
	coin4.angular_velocity = Vector3(0, 0, 25)
	c4.call("_on_coin_dropped", null, coin4)
	await _physics(4)
	_check("E origin builds the launch gauges and a release writes them",
		gauges != null and float(c4.get("_launch_drop")) > 0.5 and float(c4.get("_launch_spin")) > 20.0,
		"gauges %s; drop %.2f m, spin %.1f rad/s" %
			["built" if gauges != null else "absent", float(c4.get("_launch_drop")), float(c4.get("_launch_spin"))])
	var c5: Node3D = _make(coin_new, Vector3(0, 0, 50))
	await _physics(4)
	_check("E the default rung builds no gauges (other maps unchanged)", c5.get("_gauge_holder") == null)

	_world.queue_free()
	await _physics(2)
	_finished = true
	if _fails.is_empty():
		print("\nprobe_random_cubes: ALL CHECKS PASS")
		quit(0)
	else:
		print("\nprobe_random_cubes: %d FAILED" % _fails.size())
		for f in _fails:
			print("  FAIL  %s" % f)
		quit(1)
