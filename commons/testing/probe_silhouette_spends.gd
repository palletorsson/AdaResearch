extends SceneTree

## Does a silhouette SPEND itself on its attack? (2026-09-08, Palle: "Make it so
## that after an attack the silhouette becomes a sculpture for 5 sec. and then
## fades and disappears.")
##
## The arc, asserted end to end with no headset and no museum: a foe that lands
## one hit stops being a foe (out of "enemy", into "statue", contact_damage 0,
## a plinth under it), holds still, fades, and frees itself. The fade is the part
## worth probing rather than reading — the sprite ships ALPHA_SCISSOR, which is
## a binary per-pixel cut, so an albedo alpha tween under it does nothing until
## the figure blinks out in one frame. This asserts the material was actually
## moved to alpha blending and that the alpha really falls.
##
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_silhouette_spends.gd

const FOE := "res://commons/hazards/catalyst_foe/catalyst_foe.tscn"

var _fail := 0


func _init() -> void:
	call_deferred("_run")


func _check(ok: bool, said: String, why: String = "") -> void:
	if ok:
		print("[probe] %s  OK" % said)
	else:
		_fail += 1
		print("[probe] %s  FAIL%s" % [said, ("  — " + why) if why != "" else ""])


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	# a body the foe will accept as the player, one cell away
	var player := CharacterBody3D.new()
	player.name = "FakePlayer"
	player.add_to_group("player")
	world.add_child(player)
	player.global_position = Vector3(0.6, 0, 0)

	# BEFORE the tree, because _ready builds the body: a config applied after
	# add_child sets the property on a foe that has already built a different
	# creature, which is how the first run of this probe read body=silhouette
	# with no drawing in the tree and contact_damage 0.
	var foe: Node3D = (load(FOE) as PackedScene).instantiate() as Node3D
	foe.set("body", "silhouette")
	foe.set("phase", "foe")
	foe.set("silhouette_seed", 12345)
	world.add_child(foe)
	foe.global_position = Vector3.ZERO
	await physics_frame
	await create_timer(0.6).timeout

	_check(String(foe.get("body")) == "silhouette", "it is a silhouette", str(foe.get("body")))
	# NOT ARMED BY HAND. A foe takes its contact_damage and its "enemy"
	# membership from HazardManager and soft_stages, and a bare SceneTree brings
	# up neither. An earlier draft of this probe forced both from outside and
	# then asserted that the statue cleared them — which measured the probe
	# fighting the creature's own state machine, not this change. What the spend
	# owns is the STOP: statue, plinth, groups, the fade, the free.
	print("[probe] as spawned (unmanaged): contact_damage %.2f, in enemy %s"
		% [float(foe.get("contact_damage")), str(foe.is_in_group("enemy"))])

	# the drawing before the attack: a scissor-cut sprite
	var sil: MeshInstance3D = null
	for n in _all(foe):
		if n is MeshInstance3D and String(n.name) == "Silhouette":
			sil = n as MeshInstance3D
			break
	_check(sil != null, "the drawing is in the tree")
	# read it the way the base ATTACHES it: _add_mesh uses a surface override,
	# not material_override (hazard_creature_base.gd:665)
	var m0: StandardMaterial3D = null
	if sil != null:
		m0 = sil.material_override as StandardMaterial3D
		if m0 == null and sil.get_surface_override_material_count() > 0:
			m0 = sil.get_surface_override_material(0) as StandardMaterial3D
	_check(m0 != null, "the drawing's material is reachable")
	print("[probe] before: the sprite's transparency mode is %d (2 = ALPHA_SCISSOR, 1 = ALPHA)"
		% (m0.transparency if m0 != null else -1))

	# ── the attack ───────────────────────────────────────────────────────
	var where0: Vector3 = player.global_position
	foe.call("_sil_spend_after_attack")
	await physics_frame

	_check(bool(foe.get("_sil_statue")), "after the attack it is a statue")
	_check(bool(foe.get("_sil_spent")), "it is marked spent (a SHOT statue is not)")
	_check(foe.is_in_group("statue"), "it joined the statue group")
	_check(not foe.is_in_group("enemy"), "it is not in the enemy group",
		"groups: %s" % str(foe.get_groups()))
	_check(float(foe.get("contact_damage")) == 0.0 and not bool(foe.get("_can_damage")),
		"it can no longer bite",
		"contact_damage %.2f, _can_damage %s" % [float(foe.get("contact_damage")), str(foe.get("_can_damage"))])
	var plinth: Node = foe.get_node_or_null("Plinth")
	_check(plinth != null, "it stands on a plinth")
	_check(player.global_position.is_equal_approx(where0),
		"the attack did not move the player", str(player.global_position))
	_check(m0 != null and m0.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA,
		"the sprite moved to real alpha blending, so a fade can be seen")

	# ── it holds, then goes ──────────────────────────────────────────────
	await create_timer(3.0).timeout
	_check(is_instance_valid(foe), "3.0 s later it is still standing (holds 5 s)")
	var a_hold: float = m0.albedo_color.a if m0 != null else -1.0
	_check(a_hold > 0.99, "and still fully opaque while it holds (alpha %.2f)" % a_hold)

	# SAMPLE THE FADE RATHER THAN GUESS AN INSTANT. Asserting one alpha at one
	# timestamp made the probe a clock comparison — the first run read 0.00 at
	# what should have been a third of the way down, which says nothing about
	# whether it faded or blinked. Poll instead, and require that the alpha was
	# actually SEEN between 0 and 1: that is the difference between a fade and a
	# disappearance.
	var seen_mid := false
	var lowest: float = 1.0
	for _i in range(40):                       # 40 x 0.1 s = 4 s, past hold + fade
		await create_timer(0.1).timeout
		if not is_instance_valid(foe) or m0 == null:
			break
		var a: float = m0.albedo_color.a
		lowest = minf(lowest, a)
		if a < 0.98 and a > 0.02:
			seen_mid = true
	_check(seen_mid, "the alpha passed through the middle — it faded, it did not blink",
		"never observed between 0.02 and 0.98; lowest seen %.2f" % lowest)
	_check(not is_instance_valid(foe), "it is gone")

	print("[probe] %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(1 if _fail > 0 else 0)


func _all(x: Node) -> Array:
	var out: Array = [x]
	for c in x.get_children():
		out.append_array(_all(c))
	return out
