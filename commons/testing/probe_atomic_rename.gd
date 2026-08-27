extends SceneTree
## DOES A RENAME LAND ON TOP OF AN EXISTING FILE? (2026-08-27)
##
## _page_save writes the book to a sibling and renames over the original, so a
## crash between open and store cannot leave a zero-length chapter. That is only
## true if the rename actually SUCCEEDS onto a file that already exists. On
## Windows the C rename() fails when the destination exists, and a save that
## silently does nothing is worse than the truncating write it replaced — the
## museum would report "the book would not open for writing" forever, or worse,
## report success while the original stood.
##
## So this is measured, not assumed, on the platform it has to work on.
## godot --headless --path . --xr-mode off --script res://commons/testing/probe_atomic_rename.gd

const OUT := "res://ada_run/atomic_rename_probe.txt"
const DIR := "res://ada_run"
const OLD := "res://ada_run/_rename_target.json"
const TMP := "res://ada_run/_rename_target.json.tmp"


func _initialize() -> void:
	call_deferred("_run")


func _put(path: String, body: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(body)
	f.close()


func _run() -> void:
	var fails: Array = []
	var notes: Array = []

	# the destination EXISTS and has content — the whole point
	_put(OLD, "{\"the\": \"original\"}")
	_put(TMP, "{\"the\": \"replacement\"}")
	if not FileAccess.file_exists(OLD) or not FileAccess.file_exists(TMP):
		fails.append("could not set the fixture up")
		_report(fails, notes)
		return

	var da := DirAccess.open(DIR)
	if da == null:
		fails.append("DirAccess.open(%s) returned null - the save's first step fails" % DIR)
		_report(fails, notes)
		return
	var err: int = da.rename(TMP.get_file(), OLD.get_file())
	if err != OK:
		fails.append("rename over an EXISTING file returned error %d - the atomic write "
			% err + "never lands and every save is silently refused")
	else:
		notes.append("rename lands on top of an existing file (err OK)")

	var back := FileAccess.get_file_as_string(OLD)
	if not back.contains("replacement"):
		fails.append("the file still says %s - the rename reported OK and did nothing" % back.substr(0, 40))
	else:
		notes.append("the destination now holds the replacement")
	if FileAccess.file_exists(TMP):
		fails.append("the temp file is still there - it would accumulate beside every book")
	else:
		notes.append("the temp file is consumed, not left behind")

	# and the same call with a RELATIVE name pair, which is what _page_save passes
	_put(OLD, "{\"round\": 2}")
	_put(TMP, "{\"round\": 2, \"new\": true}")
	var da2 := DirAccess.open(DIR)
	if da2 != null and da2.rename(TMP.get_file(), OLD.get_file()) == OK 			and FileAccess.get_file_as_string(OLD).contains("new"):
		notes.append("it repeats — a second save overwrites the first")
	else:
		fails.append("the SECOND save did not land, so only the first write would ever work")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(OLD))
	_report(fails, notes)


func _report(fails: Array, notes: Array) -> void:
	var r := "ATOMIC RENAME PROBE\n"
	for n in notes:
		r += "  ok   %s\n" % n
	for f in fails:
		r += "  FAIL %s\n" % f
	r += "%d fail(s)\n" % fails.size()
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	fh.store_string(r)
	fh.close()
	print(r)
	quit(1 if not fails.is_empty() else 0)
