extends SceneTree

## Fire, the spider and the silhouette: does each of them restart only the
## CURRENT LEVEL? (2026-09-06)
##
## Palle: "when we die from a spider from fire or silhouette I only want to
## restart the current level."
##
## There are two deaths in this codebase and they are not alike.
##
##   THE MUSEUM'S      on_lethal_touch / walker_bitten -> _museum_death, which
##                     stands the visitor up at a save point in the hall they
##                     died in. The walk continues. This is the one Palle wants.
##   THE GAME'S        GameManager.apply_health_damage -> _handle_player_death,
##                     which RELOADS THE SCENE. In the museum that is the whole
##                     4.8 km building rebuilt from its first hall: not the
##                     current level, the whole game.
##
## Nothing distinguishes them from inside the hazard. Both are "the player died",
## both look right in a log, and the difference only shows up as a loading screen
## thirty seconds later — by which time it reads as a streaming hitch.
##
## So this probe asks each source to kill, and then asks GameManager whether it
## was told anything. A museum death must leave the health bar untouched: the
## moment health moves, that lane is live and a full reload is one more bite away.
##
## AND IT RUNS IN VR, with a fake rig, because that is where the spider was
## wrong: its museum branch tested whether the target was in group `em_walker`,
## and in a headset nothing rides the walker.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_death_routes_to_museum.gd -- --em-vr --em-segments=2

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const CRAB := "res://commons/hazards/head_crab/head_crab.tscn"
const FOE := "res://commons/hazards/catalyst_foe/catalyst_foe.tscn"
const REPORT := "res://ada_run/death_routes_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []
var _rig: Node3D = null
var _eye: Camera3D = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_make_rig()
	var mus: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	root.add_child(mus)
	var waited: int = 0
	while waited < 5400:
		await process_frame
		waited += 1
		var segs: Variant = mus.get("_segments")
		if segs is Array and not (segs as Array).is_empty():
			break
	for _i in range(20):
		await physics_frame

	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		_health0 = float(gm.get("player_health"))
		_lines.append("[probe] the health bar reads %.1f before anything kills anyone" % _health0)
	if gm == null:
		_lines.append("[probe] no GameManager autoload in this boot — the health lane cannot be watched, and every check below is weaker for it")
	_lines.append("[probe] museum on the headset path: %s, walker: %s, in group em_lethal: %s" % [
		str(bool(mus.get("_vr"))), str(mus.get("_player") != null),
		str(mus.is_in_group("em_lethal"))])
	_check(mus.is_in_group("em_lethal"),
		"the museum is findable by group — a hazard can reach its death without knowing what a walker is",
		"the museum is NOT in group em_lethal: every hazard that looks it up by group falls through to the health lane")

	# ── 1. FIRE ──────────────────────────────────────────────────────────
	await _one(mus, gm, "fire", func(): mus.call("on_lethal_touch", "fire"))

	# ── 2. THE SPIDER ────────────────────────────────────────────────────
	# Its own _damage(), called on a target that is NOT the museum's walker —
	# which is what a headset visitor is. That is the exact shape of the bug.
	if ResourceLoader.exists(CRAB):
		var crab: Node3D = (load(CRAB) as PackedScene).instantiate() as Node3D
		root.add_child(crab)
		await physics_frame
		var bit: bool = false
		if crab.has_method("_damage"):
			bit = bool(crab.call("_damage", _eye, 100.0))
		_check(bit,
			"the spider's bite was delivered to a target that is not the museum's walker",
			"the spider's _damage() refused a headset visitor outright — it bit nothing at all")
		await _settle(mus, gm, "the spider")
		crab.queue_free()
		await process_frame
	else:
		_lines.append("[probe] no head_crab scene — the spider is not in this tree")

	# ── 3. THE SILHOUETTE, THROUGH ITS OWN CONTACT ──────────────────────
	# NOT by calling the museum's walker_bitten, which is what the first version of
	# this probe did — that tests the museum's lane and never touches the foe's
	# routing at all. It passed while the silhouette was fading Palle's screen to
	# black, because the thing it exercised was not the thing that was wrong.
	#
	# _try_damage_target is the base class's contact path: _handle_contact_damage
	# calls it off slide collisions every physics frame, and it is the road the
	# silhouette actually took to GameManager. catalyst_foe's own
	# _sil_contact_tick knows about the museum; this did not.
	if ResourceLoader.exists(FOE):
		var foe: Node3D = (load(FOE) as PackedScene).instantiate() as Node3D
		root.add_child(foe)
		await physics_frame
		if foe.has_method("_try_damage_target"):
			foe.call("_try_damage_target", _eye)
		await _settle(mus, gm, "the silhouette's contact damage")
		foe.queue_free()
		await process_frame
	else:
		_lines.append("[probe] no catalyst_foe scene — the silhouette is not in this tree")

	# ── 4. THE CHOKE POINT, for the twenty-six that never went through a base ─
	# DangerZone, fireball, plasma_critter, octapod_crawler, the vines and the
	# fields all call GameManager.apply_health_damage directly. Teaching each of
	# them is 26 chances to miss one; the rule lives at the function they all
	# arrive through, so this asks that function itself.
	if gm != null and gm.has_method("apply_health_damage"):
		gm.call("apply_health_damage", 15.0)
		await _settle(mus, gm, "a direct GameManager.apply_health_damage")

	# ── 5. AND A PER-FRAME HAZARD MUST NOT BE A TRAPDOOR ─────────────────
	# branching_vine, maze_spinner and swarm_hive pass `damage * delta` EVERY
	# FRAME. Forwarded raw, the museum's counter — which kills on the third bite —
	# would kill in three frames, about 50 ms. walker_bitten rate-limits itself for
	# exactly this; sixty calls in one frame must count as one bite, not sixty.
	var bites_before: int = int(mus.get("_bite_n"))
	var deaths_before: int = int(mus.get("_deaths"))
	for _k in range(60):
		gm.call("apply_health_damage", 1.0) if gm != null else mus.call("walker_bitten", Vector3.ZERO)
	await physics_frame
	var bites_after: int = int(mus.get("_bite_n"))
	var deaths_after: int = int(mus.get("_deaths"))
	_check(deaths_after == deaths_before and bites_after - bites_before <= 1,
		"sixty damage ticks in one frame counted as %d bite(s) and killed nobody — a hazard you stand in is not a trapdoor" % (
			bites_after - bites_before),
		"sixty ticks in one frame counted as %d bite(s) and %d death(s): a per-frame hazard kills in three frames" % [
			bites_after - bites_before, deaths_after - deaths_before])

	# ── 6. ...AND IT MUST STILL KILL YOU IF YOU STAND IN IT ──────────────
	# The other half of the rate limit, and the one it would be easy not to write.
	# A limit that swallowed everything would pass check 5 perfectly while making
	# all twenty-six hazards harmless inside the museum — a trapdoor traded for a
	# no-op, and both look like "nothing happened" from the outside. So: keep the
	# damage coming, and the museum must take exactly one death out of it.
	# WAIT FOR THE PREVIOUS DEATH TO FINISH FIRST. The desktop death is a ~4 s
	# coroutine and walker_bitten returns at `if _dying` for the whole of it, so a
	# 2.6 s window opened straight after an earlier check measured a museum that
	# was busy dying and reported the rate limit had swallowed the hazard. The
	# checks were interfering with each other, not the code.
	var tw0: int = Time.get_ticks_msec()
	while bool(mus.get("_dying")) and Time.get_ticks_msec() - tw0 < 8000:
		await process_frame
	_lines.append("[probe] the museum finished its earlier death after %.2f s — now the standing test" % (
		float(Time.get_ticks_msec() - tw0) / 1000.0))
	var d0: int = int(mus.get("_deaths"))
	var t1: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 2600:
		if gm != null:
			gm.call("apply_health_damage", 1.0)
		await physics_frame
	var d1: int = int(mus.get("_deaths"))
	_check(d1 > d0,
		"standing in it for 2.6 s cost %d death(s) — the rate limit slows a hazard, it does not disarm one" % (d1 - d0),
		"2.6 s of continuous damage killed nobody (deaths %d -> %d): the rate limit swallowed the hazard whole" % [d0, d1])
	_check(d1 - d0 <= 2,
		"  ...and only %d, not one per frame" % (d1 - d0),
		"  ...but %d of them in 2.6 s — the limit is not holding" % (d1 - d0))

	# ── AND THE BUILDING IS STILL STANDING ───────────────────────────────
	# A scene reload would have taken this instance with it. Cheap, and it is the
	# claim in its plainest form: after three deaths, the same museum.
	_check(is_instance_valid(mus) and mus.is_inside_tree(),
		"after all three, the same museum is still in the tree — nothing reloaded the building",
		"the museum instance is gone: something reloaded the scene, which is the whole game and not the current level")

	# ── 7. AND THE GRID IS UNTOUCHED ─────────────────────────────────────
	# Everything above is guarded by "while a museum stands in the tree". A grid
	# map has no em_lethal node, and there the health bar, the red flash and the
	# reload are the RIGHT answer — reloading a scene there is restarting the one
	# map you are in. So take the museum out of the group and check that the old
	# lane comes straight back: if it does not, this sweep did not scope a rule to
	# the museum, it deleted health from the game.
	#
	# LAST, deliberately: this one drains the bar on purpose.
	if gm != null:
		mus.remove_from_group("em_lethal")
		var h_before: float = float(gm.get("player_health"))
		gm.call("apply_health_damage", 12.0)
		await physics_frame
		var h_after: float = float(gm.get("player_health"))
		mus.add_to_group("em_lethal")
		_check(h_after < h_before,
			"with no museum in the tree the bar moved again, %.1f -> %.1f — the grid keeps its own death" % [h_before, h_after],
			"with no museum in the tree the bar STILL did not move (%.1f): the interception is not scoped to the museum, it is global" % h_after)

	_finish()


## Fire one death and read the health bar on the other side of it.
func _one(mus: Node3D, gm: Node, what: String, fire: Callable) -> void:
	fire.call()
	await _settle(mus, gm, what)


## AGAINST THE BAR THIS PROBE STARTED WITH, not against a reading taken after the
## kill. The first version sampled "before" inside here — which runs AFTER the
## bite — so for the spider it read 0.0 and 0.0 and reported the bar had not
## moved. It had: 100 to 0, in the frame before the measurement, and the probe
## passed on the exact bug it was written to catch. One invariant instead: the
## museum's own death never touches the bar, so the bar is what it was at boot.
var _health0: float = -1.0


func _settle(mus: Node3D, gm: Node, what: String) -> void:
	for _i in range(8):
		await physics_frame
	if gm == null:
		_lines.append("[probe] %s: fired (no GameManager to watch)" % what)
		return
	var now: float = float(gm.get("player_health"))
	_check(absf(now - _health0) < 0.001,
		"%s: the health bar is untouched at %.1f — the museum took the death, not the game" % [what, now],
		"%s: health is %.1f against the %.1f this probe booted with, so it routed through GameManager — and a depleted bar there RELOADS THE SCENE" % [
			what, now, _health0])


func _make_rig() -> void:
	_rig = XROrigin3D.new()
	_rig.name = "ProbeRig"
	_rig.set("current", true)
	var cam := XRCamera3D.new()
	cam.name = "ProbeEye"
	cam.position = Vector3(0.0, 1.65, 0.0)
	_rig.add_child(cam)
	_rig.position = Vector3(7.5, 0.0, 6.0)
	# IN GROUP "player", because the real one is. _try_damage_target only reaches
	# the health bar for a target that answers apply_health_damage or joins this
	# group — xr-tools' player body joins it, a bare XRCamera3D does not. Without
	# it the probe's victim was un-damageable, so the negative run came back green
	# with the fix ripped out: the gate was measuring a target nothing could hurt.
	_rig.add_to_group("player")
	cam.add_to_group("player")
	root.add_child(_rig)
	_eye = cam


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL",
		"" if ok else " — " + String(";  ").join(PackedStringArray(_fails))])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)
