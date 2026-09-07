extends SceneTree
## DOES THE RECOVERY CLOCK SURVIVE A SLOWED ENGINE?
##
## 2026-09-07. The museum's death is a ~3 s chain of awaits, and DeathEffect drops
## Engine.time_scale to 0.05 for its flash. A plain SceneTree timer OBEYS that
## scale, so a 0.85 s beat becomes 17 s and the fade looks stopped — which is one
## of the ways "it fades to black and then nothing else happens" can happen with
## every line of the death sequence working exactly as written.
##
## The watchdog is only worth anything if its own clock cannot be slowed with the
## thing it is watching. That is the 4th argument of SceneTree.create_timer —
## ignore_time_scale — and this measures it rather than trusting the signature.
##
## endless_museum.gd itself cannot be probed: it names GameManager and every probe
## here is `extends SceneTree`, which cannot see an autoload. So this tests the
## MECHANISM the fix rests on, and says plainly that it is not testing the museum.

func _init() -> void:
	var fails := 0

	# WARM UP BEFORE TIMING ANYTHING. The first version measured 2742 ms for a
	# 400 ms timer and reported the flag broken — while the unflagged timer in the
	# same run came back at 7997 ms against a predicted 8000, which is dead on and
	# proves frames were plentiful. The 2.3 s went into the FIRST await, which is
	# where this project's autoloads finish booting (66 ambient presets, a 2886
	# artifact registry). A clock probe that starts its stopwatch before the engine
	# has settled measures the engine, not the clock.
	for i in range(20):
		await process_frame

	Engine.time_scale = 0.05
	print("Engine.time_scale = %.2f  (DeathEffect's flash value)" % Engine.time_scale)

	var t0 := Time.get_ticks_msec()
	# 4th arg = ignore_time_scale. 0.40 s of WALL time, whatever the engine does.
	await create_timer(0.40, true, false, true).timeout
	var guarded_ms := Time.get_ticks_msec() - t0

	var t1 := Time.get_ticks_msec()
	# the same wait WITHOUT the flag: at 0.05 scale this should take ~20x longer,
	# and it is the negative — if both come back alike the flag does nothing and
	# the watchdog is as stallable as what it guards.
	await create_timer(0.40).timeout
	var scaled_ms := Time.get_ticks_msec() - t1

	Engine.time_scale = 1.0
	print("")
	print("ignore_time_scale timer: %d ms of wall clock (want ~400)" % guarded_ms)
	print("plain timer at 0.05x   : %d ms of wall clock (want ~8000)" % scaled_ms)

	if guarded_ms > 1200:
		print("  FAIL the watchdog clock is being slowed with the thing it watches")
		fails += 1
	if scaled_ms < 2000:
		print("  FAIL the plain timer was NOT slowed, so this proves nothing about the flag")
		fails += 1
	if scaled_ms <= guarded_ms:
		print("  FAIL the two clocks behave alike — the flag is doing nothing")
		fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
