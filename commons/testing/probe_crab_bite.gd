extends SceneTree
## DOES IT ACTUALLY KILL YOU (2026-08-27, Palle: "put the spider in the point
## one map so I can see it walk, attack and kill the player").
##
## Until today the answer was no, in a way nothing would have reported: the
## registry files head_crab as a hazard and it instantiated no collider, no
## area and no physics body — it walked up to within 0.35 m, stopped, and stood
## there. This runs the whole sequence against a stand-in player that records
## every hit: detect, close, commit to a leap, land it, and take a health bar
## of 100 down to zero.
##
## The stand-in is in group "player" and owns take_damage, which is the first of
## the three method names the animal tries. The live game has a fourth path —
## GameManager.apply_health_damage — checked separately at the end.
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const TXT := "res://ada_run/crab_bite.txt"

var _l: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)


func _run() -> void:
	var st := Node3D.new(); get_root().add_child(st)
	var fb := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bx := BoxShape3D.new()
	bx.size = Vector3(60, 1.0, 60); cs.shape = bx; cs.position = Vector3(0, 0.0, 0)
	fb.add_child(cs); st.add_child(fb)

	# the stand-in: a body that stands on the floor at 0.5 and counts its wounds
	var player := Node3D.new()
	player.name = "PlayerBody"
	player.add_to_group("player")
	player.set_script(preload("res://commons/testing/probe_crab_bite_dummy.gd"))
	st.add_child(player)
	player.global_position = Vector3(0, 0.5, 0)

	var c: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
	st.add_child(c)
	c.global_position = Vector3(0, 0.5, -8.0)     # eight metres away, on the deck
	c.set("detect_m", 14.0)
	await create_timer(1.4).timeout

	_say("THE BITE, END TO END")
	_say("  player at origin, 100 health; crab 8.00 m away, detect 14 m")
	_say("  contact %.0f   lunge %.0f   lunge range %.2f m   bite range %.2f m   cooldown %.2f s"
		% [float(c.get("contact_damage")), float(c.get("lunge_damage")),
		   float(c.get("lunge_range")), float(c.get("bite_range")), float(c.get("bite_cooldown"))])
	_say("")

	var t := 0.0
	var closed_at := -1.0
	var first_hit := -1.0
	var dead_at := -1.0
	var lunges := 0
	var was_lunging := false
	var last_hits := 0
	while t < 26.0:
		await create_timer(0.05).timeout
		t += 0.05
		var d: float = c.global_position.distance_to(player.global_position)
		if closed_at < 0.0 and d < 2.0:
			closed_at = t
			_say("  %5.2f s  closed to %.2f m" % [t, d])
		var lung: bool = float(c.get("_lunge_t")) > 0.0
		if lung and not was_lunging:
			lunges += 1
		was_lunging = lung
		var hits: int = int(player.get("hits"))
		if hits > last_hits:
			last_hits = hits
			if first_hit < 0.0: first_hit = t
			_say("  %5.2f s  HIT %d for %.0f — health %.0f  (%s)"
				% [t, hits, float(player.get("last_amount")), float(player.get("health")),
				   "leap" if lung else "contact"])
		if float(player.get("health")) <= 0.0 and dead_at < 0.0:
			dead_at = t
			_say("  %5.2f s  DEAD" % t)
			break

	_say("")
	_say("  travelled to contact in %.2f s" % closed_at if closed_at > 0.0 else "  never closed")
	_say("  first bite at %.2f s" % first_hit if first_hit > 0.0 else "  never bit")
	_say("  leaps committed: %d" % lunges)
	_say("  total hits: %d for %.0f damage" % [int(player.get("hits")), float(player.get("taken"))])
	if dead_at > 0.0:
		_say("  KILLED THE PLAYER in %.2f s" % dead_at)
	else:
		_say("  player survived 26 s on %.0f health" % float(player.get("health")))

	# the live path, which the stand-in bypasses
	_say("")
	var gm: Node = get_root().get_node_or_null("GameManager")
	if gm != null and gm.has_method("apply_health_damage"):
		_say("  live fallback: /root/GameManager.apply_health_damage present")
	else:
		_say("  live fallback: GameManager NOT loaded in this probe (autoload runs in the game)")

	var ok: bool = dead_at > 0.0 and lunges > 0
	_say("")
	_say("VERDICT: %s" % ("it walks, it leaps, it bites, it kills" if ok else "INCOMPLETE"))
	var f := FileAccess.open(TXT, FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	quit(0 if ok else 1)
