extends SceneTree
## THE CORRIDOR TAX, AND THE WALL THAT PAYS IT BACK.
##
## Eight checks, against the REAL health provider.
##
## The first version of this registered a stand-in in the "health_provider"
## group and asserted against that, and every health number came back wrong —
## because a SceneTree probe DOES have the autoloads. The standing note in this
## repo is that such a probe "cannot see an autoload", and that is true only of
## naming the class at COMPILE time: `GameManager.set_health()` in a script this
## probe loads is a parse error, while `get_node_or_null("/root/GameManager")`
## at runtime finds it perfectly well. So the artifacts reached the real manager,
## the stand-in sat untouched at 100, and the probe reported failures that were
## its own. Capability lookup is still the right design — it is what lets the
## artifact COMPILE here at all — but the thing to assert against is whatever
## _health_node() actually returned.

func _init() -> void:
	var fails := 0

	var Cross := load("res://commons/artifacts/anamorphic_cross/anamorphic_cross.tscn")
	var Kit := load("res://commons/artifacts/wall_health_station/wall_health_station.tscn")

	var x = Cross.instantiate()
	get_root().add_child(x)
	await process_frame
	await process_frame

	# THE X IS NOW A DANGER ZONE, not a one-shot toll. It composes
	# commons/hazards/DangerZone, so the checks are about the ZONE existing,
	# being sized to the cross, and being wired to flash — not about a hand-rolled
	# arrive() that no longer exists.
	var dz: Node = x.get_node_or_null("DangerZone")
	print("1  danger zone present: %s" % [dz != null])
	if dz == null:
		print("   FAIL a danger X with no danger"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return

	print("2  ticks %.1f every %.2f s, flash_on_damage=%s"
		% [dz.damage_per_tick, dz.tick_interval, dz.flash_on_damage])
	if dz.damage_per_tick <= 0.0 or not dz.flash_on_damage:
		print("   FAIL it takes health without saying so"); fails += 1

	# the two strokes must be a real X — opposite angles, same length
	var st: Array = []
	for c in x.get_children():
		if c is MeshInstance3D:
			st.append(c)
	print("3  strokes: %d" % st.size())
	if st.size() != 2:
		print("   FAIL an X has two strokes"); fails += 1
	else:
		var a1: float = rad_to_deg((st[0] as MeshInstance3D).rotation.z)
		var a2: float = rad_to_deg((st[1] as MeshInstance3D).rotation.z)
		print("4  angles %.0f and %.0f degrees (must be opposite)" % [a1, a2])
		if absf(a1 + a2) > 1.0 or absf(a1) < 20.0:
			print("   FAIL not an X"); fails += 1
		var alpha: float = (st[0] as MeshInstance3D).material_override.albedo_color.a
		print("5  transparency alpha = %.2f (must be < 0.7)" % alpha)
		if alpha >= 0.7:
			print("   FAIL not transparent — you cannot walk into what you can't see through")
			fails += 1

	# NEGATIVE: nobody is in it, so nothing is ticking
	print("6  occupied with no body present: %s (must be false)" % x.is_occupied())
	if x.is_occupied():
		print("   FAIL it thinks someone is standing in it"); fails += 1

	# the flash path must actually exist now, end to end
	var de: Node = x.get_node_or_null("/root/DeathEffect")
	var has_flash: bool = de != null and de.has_method("damage_flash")
	print("7  DeathEffect.damage_flash present: %s" % has_flash)
	if not has_flash:
		print("   FAIL the stub is still a stub; damage stays invisible"); fails += 1

	# ---- the wall ----
	# The kit half needs a health provider, and it must be the one the ARTIFACT
	# resolves — a stand-in in the health_provider group is silently bypassed,
	# because a SceneTree probe does have the autoloads even though it cannot
	# name their classes at compile time.
	var k0 = Kit.instantiate()
	get_root().add_child(k0)
	await process_frame
	var hp: Node = k0._health_node()
	print("8  health provider in use: %s" % [hp.name if hp else "NONE"])
	if hp == null:
		print("   FAIL nothing keeps health"); fails += 1
		print("PROBE FAILED (%d)" % fails); quit(fails); return
	hp.set_health(60.0)
	k0.queue_free()

	var k = Kit.instantiate()
	get_root().add_child(k)
	await process_frame
	await process_frame
	var c0: float = k.charge_left()
	var got: float = k.draw_from(40.0)
	print("5  drew %.0f from the wall (charge %.0f -> %.0f, health %.0f)"
		% [got, c0, k.charge_left(), hp.get_health()])
	if got <= 0.0:
		print("   FAIL the wall gave nothing"); fails += 1
	if absf((c0 - k.charge_left()) - got) > 0.01:
		print("   FAIL the wall's books do not balance"); fails += 1

	# 6. NEGATIVE: it must not drain into a full body. set_health CLAMPS, so a
	#    naive station would happily spend charge on someone already whole.
	hp.set_health(999.0)   # full, whatever the cap is
	var c1: float = k.charge_left()
	var wasted: float = k.draw_from(30.0)
	print("6  drew %.0f into a FULL body (must be 0; charge %.0f -> %.0f)"
		% [wasted, c1, k.charge_left()])
	if wasted != 0.0 or absf(k.charge_left() - c1) > 0.01:
		print("   FAIL the wall drained into someone who did not need it"); fails += 1

	# 7. it runs out, and stays out
	hp.set_health(1.0)
	for i in 12:
		k.draw_from(50.0)
	print("7  after draining: charge=%.0f empty=%s" % [k.charge_left(), k.is_empty()])
	if not k.is_empty():
		print("   FAIL a wall charger with infinite supply is a scoreboard"); fails += 1

	# 8. NEGATIVE: an empty wall gives nothing
	var post: float = k.draw_from(20.0)
	print("8  drew %.0f from an empty wall (must be 0)" % post)
	if post != 0.0:
		print("   FAIL the empty wall still pays out"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
