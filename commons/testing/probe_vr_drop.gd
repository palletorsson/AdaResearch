extends SceneTree
## THE HEADSET LANDS ON THE SAVE POINT (2026-08-25, Palle: "in VR we are after
## death we are re-dropped in the same spot meaning we die again and again").
## No headset here, so the arithmetic is the test: given where the rig stands
## and where the headset stands inside it, does the rig move so that the
## HEADSET — not the origin — ends on the save point?
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_vr_drop.gd

const OUT := "res://ada_run/vr_drop.txt"
const EM = preload("res://commons/scenes/endless_museum.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rep := "THE VR DROP\n"
	var cases: Array = [
		{"why": "centred in the play space", "rig": Vector3(0, 0, 0), "eye": Vector3(0, 1.7, 0)},
		{"why": "two metres from the origin", "rig": Vector3(5, 0, 20), "eye": Vector3(7, 1.6, 21.5)},
		{"why": "behind and left of it", "rig": Vector3(5, 0, 20), "eye": Vector3(3.2, 1.8, 18.4)},
		{"why": "a deep hall, rig at height", "rig": Vector3(2, -2.5, 60), "eye": Vector3(2.8, -0.9, 61.2)},
	]
	var target := Vector3(6.0, 0.25, 2.5)      # a real save point from the walk
	var pass_n := 0
	for c_v in cases:
		var c: Dictionary = c_v
		var rig: Vector3 = c["rig"]
		var eye: Vector3 = c["eye"]
		var moved: Vector3 = EM._vr_drop(rig, eye, target)
		# where does the HEADSET end up? it keeps its offset inside the rig
		var eye_after: Vector3 = moved + Vector3(eye.x - rig.x, eye.y - rig.y, eye.z - rig.z)
		var dx: float = absf(eye_after.x - target.x)
		var dz: float = absf(eye_after.z - target.z)
		var ok: bool = dx < 0.001 and dz < 0.001 and absf(moved.y - target.y) < 0.001
		if ok:
			pass_n += 1
		rep += "  %-28s rig %s eye %s\n" % [String(c["why"]), str(rig), str(eye)]
		rep += "      rig -> %s, headset -> (%.2f, %.2f, %.2f)  %s\n" % [str(moved),
			eye_after.x, eye_after.y, eye_after.z, "ok" if ok else "WRONG"]
	rep += "\n  %d of %d land the HEADSET on the save point\n" % [pass_n, cases.size()]
	# and the fault it replaces: dropping the ORIGIN on the target instead
	var naive_eye: Vector3 = target + Vector3(2.0, 1.6, 1.5)
	rep += "  the old way (origin onto the point) would leave the headset %.1f m away\n" % \
		Vector2(naive_eye.x - target.x, naive_eye.z - target.z).length()
	rep += "  %s\n" % ("PASS" if pass_n == cases.size() else "FAIL")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
