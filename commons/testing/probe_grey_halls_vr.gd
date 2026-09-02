extends SceneTree

## Do the silhouettes reach a HEADSET? (2026-08-29, Palle: "we should have
## silhouettes in vr")
##
## The desktop probe proved the grey halls get their figures and that a figure
## sees the walker. In VR there is no walker: the museum hands each figure the
## XR eye instead, and the bite has to move the RIG, not a body nothing rides.
## Until today walker_bitten returned at the null walker and _museum_death's
## VR branch sat behind the same guard, so a silhouette in a headset could
## stand on you forever and nothing would happen — the exact silence the
## desktop probe could not hear, because it wore a walker.
##
## This probe wears a FAKE RIG: an XROrigin3D (current) with an XRCamera3D at
## 1.65 m, added before the museum, and the museum forced onto its VR lane
## (_force_vr, what --em-vr sets). No headset is needed: every XR node here is
## a plain Node3D without an interface. Then it asserts:
##
##   every silhouette in the grey hall holds the XR CAMERA as its player
##   standing the eye 0.6 m from one, the rig is SHOVED 1.1 m within a second,
##     a bite is counted, and a red veil hangs in front of the camera
##   three bites within eight seconds are the museum death: the rig is dropped
##     so the EYE lands on the save point, and the count resets
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_grey_halls_vr.gd

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const TRIAL := "res://ada_run/_trial_foes_vr_control.json"
const REPORT := "res://ada_run/grey_halls_vr_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# ── the fake rig, before the museum, so _vr_eye() finds it ──────────
	var origin := XROrigin3D.new()
	origin.name = "XROrigin3D"
	origin.current = true
	var cam := XRCamera3D.new()
	cam.name = "XRCamera3D"
	cam.position = Vector3(0, 1.65, 0)
	origin.add_child(cam)
	origin.position = Vector3(7.5, 0.0, 1.5)
	get_root().add_child(origin)

	var ctl := FileAccess.open(TRIAL, FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	var inst: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL)
	inst.set("_overrides_path", "res://ada_run/_trial_foes_vr_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_foes_vr_hand.json")
	inst.set("start_chapter", "primitives")
	inst.set("start_map", "")
	inst.set("_force_vr", true)
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	_check(bool(inst.get("_vr")), "museum on its VR lane: %s" % str(inst.get("_vr")), "not VR")
	_check(inst.get("_player") == null, "walker: %s" % ("none (VR)" if inst.get("_player") == null else "PRESENT"), "a walker on the VR lane")
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	for i in range(2):
		if (inst.get("_segments") as Array).size() >= 2:
			break
		inst.call("_build_segment")
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(0.8).timeout
	var eye: Node = inst.call("_vr_eye")
	_check(eye == cam, "the museum's eye is the fake camera: %s" % str(eye == cam), "wrong eye")

	# ── the figures, and whom they watch ─────────────────────────────────
	var foes: Array = []
	for s_v in (inst.get("_segments") as Array):
		var node: Node3D = (s_v as Dictionary).get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		for c in node.get_children():
			if c.has_meta("em_foe"):
				foes.append(c)
	_check(foes.size() >= 3, "%d silhouette(s) standing in the built halls" % foes.size(), "no silhouettes")
	var n_eye := 0
	for f in foes:
		if f.get("_player_node") == cam:
			n_eye += 1
	_check(n_eye == foes.size(), "player is the XR camera %d/%d" % [n_eye, foes.size()], "a figure that cannot see the headset")
	if foes.is_empty():
		_finish()
		return

	# ── the bite ─────────────────────────────────────────────────────────
	var foe: Node3D = foes[0]
	var bites_seen := 0
	var last_bite: int = int(inst.get("_bite_n"))
	var shoved := false
	var veil := false
	var deaths_before: int = int(inst.get("_deaths"))
	for i in range(14):
		if int(inst.get("_deaths")) > deaths_before:
			break
		# stand the eye 0.6 m east of the figure — inside the touch
		var fp: Vector3 = foe.global_position
		origin.global_position = Vector3(fp.x + 0.6, fp.y, fp.z)
		var ox: float = origin.global_position.x
		await create_timer(0.45).timeout
		var now_bite: int = int(inst.get("_bite_n"))
		if now_bite != last_bite or int(inst.get("_deaths")) > deaths_before:
			bites_seen += 1
			if now_bite > last_bite and origin.global_position.x - ox > 0.9:
				shoved = true
			if cam.get_node_or_null("EmVeil") != null:
				veil = true
		last_bite = now_bite
	_check(bites_seen >= 3, "%d bite(s) landed" % bites_seen, "the figure never bit the headset")
	_check(shoved, "the rig was shoved >= 0.9 m on a bite: %s" % str(shoved), "no shove")
	_check(veil, "a veil hangs before the camera: %s" % str(veil), "no flash in the headset")
	var deaths: int = int(inst.get("_deaths")) - deaths_before
	_check(deaths == 1, "museum deaths: %d" % deaths, "the third bite did not kill")
	_check(int(inst.get("_bite_n")) == 0, "bite count after death: %d" % int(inst.get("_bite_n")), "count not reset")
	if deaths == 1:
		var save: Vector3 = inst.call("_save_point_now")
		var d: float = Vector2(cam.global_position.x - save.x, cam.global_position.z - save.z).length()
		_check(d < 0.75, "the eye landed %.2f m from the save point %s" % [d, str(save)], "dropped somewhere else")
	_finish()


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
