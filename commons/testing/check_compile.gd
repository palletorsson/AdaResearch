extends SceneTree
## check_compile.gd — parse a list of GDScript files in ONE boot and report.
##
## `godot --check-only --script <file>` works but costs a full engine boot per file, so
## checking a dozen touched scripts after a multi-agent pass takes longer than the pass
## did. This loads them all in one boot instead.
##
## It exists because of a specific failure: five agents in a parallel promotion run hit
## a session limit mid-edit, leaving eleven scripts with 200-500 new lines each and no
## way to tell a finished promotion from a truncated one. A file that does not parse is
## the cheapest possible signal that an edit was cut off.
##
## GDScript reports parse errors through push_error at load time rather than as a return
## value, so the verdict is `load()` returning null. A script that parses but references
## a missing symbol at runtime is NOT caught here — this answers "is the file whole?",
## not "is the file correct".
##
## Run:
##   godot --path . --xr-mode off --headless --script res://commons/testing/check_compile.gd \
##       -- --files=res://a.gd,res://b.gd
##   ... or --list=res://ada_run/compile_list.txt  (one res:// path per line)

func _initialize() -> void:
	var paths: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--files="):
			for p in a.split("=", 1)[1].split(","):
				if p.strip_edges() != "":
					paths.append(p.strip_edges())
		elif a.begins_with("--list="):
			var lp: String = a.split("=", 1)[1]
			if FileAccess.file_exists(lp):
				var f := FileAccess.open(lp, FileAccess.READ)
				while not f.eof_reached():
					var line: String = f.get_line().strip_edges()
					if line != "" and not line.begins_with("#"):
						paths.append(line)

	if paths.is_empty():
		print("check_compile: no files given (--files=a,b or --list=path)")
		quit(2)
		return

	var failed: PackedStringArray = []
	for p in paths:
		if not ResourceLoader.exists(p):
			print("MISSING  %s" % p)
			failed.append(p)
			continue
		# CACHE_MODE_IGNORE so a script already loaded by an autoload or a preload
		# elsewhere in the project is re-parsed from disk rather than handed back from
		# the resource cache — otherwise a broken edit can report OK.
		var res: Resource = ResourceLoader.load(p, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null:
			print("FAIL     %s" % p)
			failed.append(p)
		else:
			print("ok       %s" % p)

	print("\n%d checked, %d failed" % [paths.size(), failed.size()])
	for p in failed:
		print("  broken: %s" % p)
	quit(1 if failed.size() > 0 else 0)
