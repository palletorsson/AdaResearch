extends SceneTree
## A SAVE POINT THAT KILLS YOU IS NOT A SAVE POINT (2026-08-29).
##
## The museum returns a dead visitor to the threshold of the hall they had
## reached. A hall whose threshold stands inside a lethal beam therefore returns
## them into the beam, which kills them, which returns them into the beam: one
## autopilot run logged sixty-one deaths at (8.0, 0.25, 36.5), every one
## identical, and nothing in the museum or the gate could tell it was happening.
##
## The fix strikes a save point off when it kills you again within SAVE_BURN_S of
## putting you there. This measures that it fires, that it fires only on a fast
## repeat, and that being struck off actually changes where you are put — because
## a rule that burns the right point and then returns to it anyway would pass a
## test that only read `_burned_saves`.
##
##   godot --headless --path . --xr-mode off --log-file <log> \
##       --script res://commons/testing/probe_save_point_burn.gd
const OUT := "res://ada_run/save_point_burn.txt"

var _l: Array = []
var fails: Array = []
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)
func _fail(s: String) -> void: fails.append(s)


## Kill the visitor and wait out the end scene. Returns where they were put.
func _kill_and_settle(inst: Node3D, player: Node3D) -> Vector3:
	inst.call("on_lethal_touch", "laser", player.global_position)
	var waited := 0.0
	while bool(inst.get("_dying")) and waited < 8.0:
		await create_timer(0.05).timeout
		waited += 0.05
	return player.global_position


func _run() -> void:
	# THE TRIAL FILES, NOT THE LIVE ONES. Palle plays the desktop museum while
	# probes run, so this never touches em_control.json or the overrides a live
	# session reads.
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_burn_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_burn_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_burn_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_burn_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(4.0).timeout

	var player: Node3D = inst.get("_player") as Node3D
	if player == null:
		_say("FAIL the museum built no walker")
		_finish()
		return

	var saves: Array = inst.get("_save_points")
	_say("THE THRESHOLDS THE MUSEUM WOULD PUT YOU BACK ON")
	for sp_v in saves:
		var sp: Dictionary = sp_v
		_say("  z %.1f  ->  %s" % [float(sp.get("z", 0.0)), str(sp.get("pos"))])
	if saves.size() < 2:
		_say("  only %d save point(s) — cannot show a fall-back; build a second segment" % saves.size())
		_fail("fewer than two save points to choose between")
		_finish()
		return

	# STAND PAST THE DEEPEST THRESHOLD, NOT ON IT. A save point's position is
	# 1.5 m short of its own threshold line, and _save_point_now takes the
	# deepest threshold with `z <= eye_z + 1.0` — so standing exactly on the
	# save spot resolves to the PREVIOUS one, and the first run of this probe
	# measured a fall-back that had never been reached. In the real loop the
	# visitor is always further in than that: they are put back, walk on, and
	# are killed some metres ahead.
	var deep: Dictionary = saves[0]
	for sp_v2 in saves:
		if float((sp_v2 as Dictionary).get("z", 0.0)) > float(deep.get("z", 0.0)):
			deep = sp_v2
	var deep_pos: Vector3 = deep.get("pos")
	player.global_position = Vector3(deep_pos.x, deep_pos.y + 0.05,
		float(deep.get("z", 0.0)) + 2.0)      # two metres past the threshold
	await create_timer(0.4).timeout
	_say("")
	_say("  standing at z %.1f, two metres past the deepest threshold (z %.1f)"
		% [player.global_position.z, float(deep.get("z", 0.0))])

	# ── the first death: an ordinary one ─────────────────────────────────
	_say("")
	_say("KILLED ONCE")
	var at1: Vector3 = await _kill_and_settle(inst, player)
	var z1: float = float(inst.get("_last_save_z"))
	_say("  put back at %s (threshold z %.1f)" % [str(at1), z1])
	if inst.get("_burned_saves").size() != 0:
		_fail("one death struck a save point off — it takes a REPEAT to prove one is lethal")

	# ── the second, at once: the threshold itself is the thing killing us ─
	_say("")
	_say("KILLED AGAIN IMMEDIATELY, HAVING WALKED ON FROM WHERE IT PUT US")
	# the loop's own shape: put back, walk forward, killed again by the same
	# thing. Without the step forward the threshold does not even re-qualify.
	player.global_position = Vector3(at1.x, at1.y, at1.z + 3.0)
	await create_timer(0.2).timeout
	var at2: Vector3 = await _kill_and_settle(inst, player)
	var z2: float = float(inst.get("_last_save_z"))
	var burned: Dictionary = inst.get("_burned_saves")
	_say("  struck off: %d save point(s) %s" % [burned.size(), str(burned.keys())])
	_say("  put back at %s (threshold z %.1f)" % [str(at2), z2])
	if burned.size() != 1:
		_fail("a fast repeat did not strike the save point off (%d burned)" % burned.size())
	if is_equal_approx(z2, z1):
		_fail("it returned to the same threshold z %.1f that had just killed us" % z2)
	elif z2 > z1:
		_fail("it fell FORWARD to z %.1f from z %.1f — the fall-back must go back" % [z2, z1])
	if at1.distance_to(at2) < 0.5:
		_fail("both deaths put us within %.2f m of the same spot" % at1.distance_to(at2))

	# ── and the negative: a death long after is not the threshold's fault ─
	_say("")
	_say("KILLED AGAIN, BUT LONG AFTER — THE THRESHOLD IS INNOCENT")
	var burn_s: float = float(inst.get("SAVE_BURN_S"))
	_say("  waiting out the %.0f s window" % burn_s)
	await create_timer(burn_s + 1.0).timeout
	var before: int = (inst.get("_burned_saves") as Dictionary).size()
	player.global_position = Vector3(at2.x, at2.y, at2.z + 3.0)
	await create_timer(0.2).timeout
	await _kill_and_settle(inst, player)
	var after: int = (inst.get("_burned_saves") as Dictionary).size()
	_say("  struck off before %d, after %d" % [before, after])
	if after != before:
		_fail("a death %.0f s after being put back still blamed the threshold" % burn_s)

	_say("")
	_say("  deaths in total: %d" % int(inst.get("_deaths")))
	_finish()


func _finish() -> void:
	_say("")
	for f in fails:
		_say("FAIL %s" % f)
	_say("VERDICT: %s" % ("a threshold that kills you twice is struck off, and the fall-back goes backwards"
		if fails.is_empty() else "%d fault(s)" % fails.size()))
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	if fh != null:
		fh.store_string("\n".join(PackedStringArray(_l)) + "\n")
		fh.close()
	quit(0 if fails.is_empty() else 1)
