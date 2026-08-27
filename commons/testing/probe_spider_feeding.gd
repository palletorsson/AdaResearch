extends SceneTree
## THE FEEDING LOOP (2026-08-27, Palle: "Let the spider look for mushrooms, eat,
## consume the mushrooms of 2 sec, loop, if no mushroom play is also food").
##
## Five mushrooms on a floor and a visitor standing still. The claims:
##   it goes to a mushroom rather than to the visitor, every time
##   each meal takes about two seconds and the mushroom is still there DURING it
##   it loops — five mushrooms, five meals, without being told to
##   the visitor is untouched while there is food
##   when the food is gone the visitor IS the food
##   it roots at the last degree, not the first
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const MUSH := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
const TXT := "res://ada_run/spider_feeding.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	current_scene = st
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(80, 1.0, 80); cs.shape = bx; cs.position = Vector3(0, -0.5, 0)
	fb.add_child(cs); st.add_child(fb)

	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	st.add_child(player); player.global_position = Vector3(0, 0.5, 0)

	# five mushrooms in a line, all further from the spider than the visitor is,
	# so going for one is a CHOICE and never an accident of distance
	var ps: PackedScene = load(MUSH) as PackedScene
	var shrooms: Array = []
	for i in range(5):
		var m: Node3D = ps.instantiate() as Node3D
		st.add_child(m)
		var at := Vector3(-4.0 - float(i) * 2.0, 0.0, 0.0)
		m.global_position = at
		shrooms.append(m)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c); c.global_position = Vector3(2.6, 0, 0)
	c.set("detect_m", 24.0)
	await create_timer(1.6).timeout

	var to_player: float = c.global_position.distance_to(player.global_position)
	var to_first: float = c.global_position.distance_to((shrooms[0] as Node3D).global_position)
	_say("FIVE MUSHROOMS AND A VISITOR")
	_say("  spider to visitor %.2f m, to the nearest mushroom %.2f m — the food is %s"
		% [to_player, to_first, "FURTHER" if to_first > to_player else "nearer"])
	_say("  feed_time %.1f s" % float(c.get("feed_time")))
	_say("")

	var meals: Array = []
	var meal_start := -1.0
	var was_eating := false
	var last_degree := 0
	var t := 0.0
	var bait_present_during_meal := true
	while t < 60.0:
		await create_timer(0.05).timeout
		t += 0.05
		var eating: bool = float(c.get("_meal_t")) > 0.0
		if eating and not was_eating:
			meal_start = t
		if eating:
			# the mushroom must still exist while it is being eaten
			var meal = c.get("_meal")
			if meal == null or not is_instance_valid(meal):
				bait_present_during_meal = false
		if was_eating and not eating:
			var d: int = int(c.get("_degree"))
			if d > last_degree:
				meals.append(t - meal_start)
				_say("  %5.2f s  meal %d took %.2f s — degree %d" % [t, meals.size(), t - meal_start, d])
				last_degree = d
		was_eating = eating
		if int(c.get("_degree")) >= 5 and bool(c.get("_rooted")):
			break

	_say("")
	_say("  meals eaten: %d" % meals.size())
	var avg := 0.0
	for m2 in meals: avg += float(m2)
	if not meals.is_empty(): avg /= float(meals.size())
	_say("  average meal: %.2f s (asked for %.1f)" % [avg, float(c.get("feed_time"))])
	_say("  degree %d, rooted %s" % [int(c.get("_degree")), str(c.get("_rooted"))])
	var bites_while_feeding: int = int(player.get("hits"))
	_say("  the visitor was bitten %d time(s) while there was food" % bites_while_feeding)

	# ── no food left: the visitor IS the food ─────────────────────────────
	_say("")
	_say("NOTHING LEFT TO EAT")
	var c2: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c2); c2.global_position = Vector3(0, 0, -6.0)
	c2.set("detect_m", 24.0)
	await create_timer(1.4).timeout
	var t2 := 0.0
	var bit := false
	while t2 < 25.0:
		await create_timer(0.05).timeout
		t2 += 0.05
		if int(player.get("hits")) > bites_while_feeding:
			bit = true
			break
	_say("  a second spider, no mushrooms on the floor: it bit the visitor after %.2f s: %s"
		% [t2, str(bit)])

	var fails: Array = []
	if meals.size() < 5: fails.append("only %d of five mushrooms were eaten" % meals.size())
	if not meals.is_empty() and absf(avg - float(c.get("feed_time"))) > 0.45:
		fails.append("a meal took %.2f s, not %.1f" % [avg, float(c.get("feed_time"))])
	if not bait_present_during_meal:
		fails.append("the mushroom vanished at the START of a meal instead of the end")
	if bites_while_feeding != 0: fails.append("it bit the visitor while there was food")
	if int(c.get("_degree")) != 5: fails.append("it did not reach the last degree")
	if not bool(c.get("_rooted")): fails.append("it never rooted")
	if not bit: fails.append("with no food left it still did not hunt the visitor")
	_say("")
	for f in fails: _say("FAIL %s" % f)
	_say("VERDICT: %s" % ("it eats five, two seconds each, roots at the last, and hunts when the floor is bare"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(TXT, FileAccess.WRITE)
	fh.store_string("\n".join(PackedStringArray(_l)) + "\n"); fh.close()
	quit(0 if fails.is_empty() else 1)
