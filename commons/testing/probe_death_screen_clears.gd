extends SceneTree

## After a silhouette kills you, does the screen come BACK? (2026-09-06)
##
## Palle: "when I get killed by silhouette the screen goes dark and nothing
## happens."
##
## The three bites of a silhouette end in on_lethal_touch("crab") -> _museum_death,
## and that is a COROUTINE: roughly three seconds of tweens and timers with the
## visitor moved to a save point in the middle of them, behind a black veil, and
## the veil taken away again at the end. Everything the visitor sees is in the
## last two lines of it.
##
## A coroutine that dies partway through leaves no trace. There is no error state,
## no failed return, nothing in the log: the awaits simply never resume, the veil
## is never faded, `_dying` is never cleared — so the screen stays dark AND no
## further death can ever run, because _museum_death returns at `if _dying`. One
## dropped frame of that function and the museum is over for the session, which is
## exactly the shape of "nothing happens".
##
## So this probe does not ask whether the death RAN. It asks whether it FINISHED:
## the veil back to nothing, `_dying` back to false, the visitor moved. In both
## lanes, because the two draw the dark with different machinery — a CanvasLayer
## on the desktop, a quad in front of the eye in VR — and only one of them can be
## the one Palle is looking at.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_death_screen_clears.gd -- --em-segments=2
##   ...and again with --em-vr

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const REPORT := "res://ada_run/death_screen_probe.txt"

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
	for _i in range(25):
		await physics_frame

	var vr: bool = bool(mus.get("_vr"))
	_lines.append("[probe] lane: %s" % ("headset (fake rig)" if vr else "desktop walker"))

	var where0: Vector3 = _visitor(mus, vr)
	# THREE BITES, which is what a silhouette actually does — walker_bitten counts
	# them and the third is the death. Firing _museum_death directly would skip
	# the counter and test a path no silhouette takes.
	# SPACED PAST BITE_MIN_S, or they are not three bites. walker_bitten now
	# rate-limits itself (2026-09-06) so a per-frame hazard cannot kill in three
	# frames — and this probe fired its three on three consecutive frames, so
	# after that change they counted as ONE. It still passed: it saw the bite's
	# flash and shove and took them for the death's veil, reporting peak 0.43
	# instead of 0.90 and "put back 1.1 m" instead of 4.8. A real crab bites on a
	# contact cooldown near a second; so does this now.
	var gap: float = float(mus.get("BITE_MIN_S")) + 0.15 if mus.get("BITE_MIN_S") != null else 0.7
	# ...and NOT after the last one. The third bite IS the death, and the veil it
	# raises fades over 0.9 s — so waiting the gap again before starting to watch
	# spent most of that fade not looking. VR came back with a peak of 0.03 beside
	# a visitor who had plainly been moved 4.8 m: the death ran, the probe arrived
	# after the curtain.
	for i in range(3):
		mus.call("walker_bitten", where0 + Vector3(1.2, 0.0, 0.0))
		if i == 2:
			break
		var tb: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - tb < int(gap * 1000.0):
			await process_frame
	# SAMPLED IN THE SAME FRAME THE DEATH SET IT. The VR veil is a 0.9 s fade with
	# no await between raising it and this line, and the probe's own frames run
	# 100-200 ms under streaming — so the first reading taken after an await had
	# already missed most of it and came back 0.06 against a set value of 0.90.
	# The peak is a fact about the death; how fast this probe can loop is not.
	var raised: float = _darkness(mus, vr)
	_lines.append("[probe] three bites delivered %.2f s apart — the third is the museum's death, which raised %.2f over the eye" % [gap, raised])

	# ── the screen must come back ────────────────────────────────────────
	# The whole sequence is about three seconds. Six is generous; if it has not
	# cleared by then it is not going to.
	var cleared_ms: int = -1
	var dark_peak: float = 0.0
	var t0: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 6000:
		await process_frame
		var a: float = _darkness(mus, vr)
		dark_peak = maxf(dark_peak, a)
		if a <= 0.02 and not bool(mus.get("_dying")) and Time.get_ticks_msec() - t0 > 400:
			cleared_ms = Time.get_ticks_msec() - t0
			break

	dark_peak = maxf(dark_peak, raised)
	_check(dark_peak > 0.35,
		"the death drew %.2f over the eye — this probe is watching the right screen" % dark_peak,
		"the eye never darkened past %.2f: the death did not run, or it draws on a surface this probe cannot see" % dark_peak)
	_check(cleared_ms >= 0,
		"the screen came back after %.2f s, and _dying is false again" % (float(cleared_ms) / 1000.0),
		"the screen never came back: %.2f still over the eye after 6 s, _dying=%s — the death coroutine stopped partway and no further death can ever run" % [
			_darkness(mus, vr), str(mus.get("_dying"))])

	# ── and the visitor was actually moved ───────────────────────────────
	var where1: Vector3 = _visitor(mus, vr)
	_check(where0.distance_to(where1) > 0.3,
		"the visitor was put back: %.1f m from where they died" % where0.distance_to(where1),
		"the visitor never moved (%.2f m) — the death darkened the screen and did nothing else" % where0.distance_to(where1))

	_finish()


## How much is drawn over the eye right now, 0..1. Two different machines: a
## CanvasLayer on the desktop, a quad parented to the XR camera in VR.
func _darkness(mus: Node3D, vr: bool) -> float:
	if vr:
		var q: Variant = mus.get("_vr_veil_node")
		if q is MeshInstance3D and is_instance_valid(q):
			var m: Material = (q as MeshInstance3D).material_override
			if m is StandardMaterial3D:
				return (m as StandardMaterial3D).albedo_color.a
		return 0.0
	var layer: Variant = mus.get("_death_layer")
	if layer is CanvasLayer and is_instance_valid(layer) and (layer as CanvasLayer).visible:
		var veil: Variant = mus.get("_death_veil")
		if veil is ColorRect and is_instance_valid(veil):
			return (veil as ColorRect).color.a
	return 0.0


func _visitor(mus: Node3D, vr: bool) -> Vector3:
	if vr:
		return _eye.global_position
	var p: Variant = mus.get("_player")
	return (p as Node3D).global_position if p is Node3D and is_instance_valid(p) else Vector3.ZERO


func _make_rig() -> void:
	_rig = XROrigin3D.new()
	_rig.name = "ProbeRig"
	_rig.set("current", true)
	var cam := XRCamera3D.new()
	cam.name = "ProbeEye"
	cam.position = Vector3(0.0, 1.65, 0.0)
	_rig.add_child(cam)
	_rig.position = Vector3(7.5, 0.0, 6.0)
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
