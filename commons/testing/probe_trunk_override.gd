extends SceneTree

## WILL THE HEADSET READ A PUSHED TRUNK?
##
## 2026-08-31, Palle: "the text does not update in vr, for some reason while the
## artifacts does."
##
## He was right, and the reason is a date. The MAP override landed in e3898abf1
## in August, so the installed build already knows how to read an adb-pushed map
## — which is why artifacts change. The TRUNK override landed today, and it is
## code, so it is not on his headset yet: one export installs it, and after that
## text hot-pushes like maps do.
##
## Which means he is about to spend an APK build on an arm nobody has run. This
## checks it on the desktop first, by calling _shipped_on with android=true and
## putting a file where an adb push would put it.
##
##   1 desktop unchanged   android=false ignores the override entirely — the
##                         editor and PCVR flow must not shift under this
##   2 the override wins   android=true prefers user://override_data/<file>
##   3 it degrades         with no override, android=true returns what it always
##                         returned, rather than a path to nothing
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_trunk_override.gd

const EM := preload("res://commons/scenes/endless_museum.gd")
const TRUNK := "res://commons/data/trunk_branches.json"
const OVERRIDE := "user://override_data/trunk_branches.json"

var _fails: int = 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("")
	print("TRUNK OVERRIDE")
	print("")

	# make sure we start clean, whatever a previous run left
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OVERRIDE))

	var bare_desktop: String = EM._shipped_on(TRUNK, false)
	var bare_android: String = EM._shipped_on(TRUNK, true)
	_check("3 degrades", bare_android, TRUNK,
		"no override present: android returns the ordinary path")

	# now put a file exactly where `say_it.py --quest` puts one
	DirAccess.make_dir_recursive_absolute("user://override_data")
	var f := FileAccess.open(OVERRIDE, FileAccess.WRITE)
	if f == null:
		print("  could not write %s — cannot test" % OVERRIDE)
		quit(2)
		return
	f.store_string("{\"trunk\": [], \"_probe\": true}")
	f.close()

	_check("1 desktop", EM._shipped_on(TRUNK, false), bare_desktop,
		"android=false ignores the override")
	_check("2 override", EM._shipped_on(TRUNK, true), OVERRIDE,
		"android=true prefers the pushed copy")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(OVERRIDE))
	_check("cleanup", EM._shipped_on(TRUNK, true), TRUNK,
		"removed again: back to the ordinary path")

	print("")
	print("  %d FAILED" % _fails)
	quit(1 if _fails > 0 else 0)


func _check(what: String, got: String, want: String, why: String) -> void:
	var ok: bool = got == want
	if not ok:
		_fails += 1
	print("  %-12s %s   %s" % [what, "ok  " if ok else "FAIL", why])
	if not ok:
		print("               got  %s" % got)
		print("               want %s" % want)
