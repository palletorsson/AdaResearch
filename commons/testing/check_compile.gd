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
		# COMPILE IT, do not merely LOAD it. ResourceLoader.load() on a syntactically
		# broken GDScript still hands back a GDScript resource — it reports the parse
		# error to the console and returns a non-null object — so a null check passes a
		# file that cannot run. This version of the probe reported "ok" for a file whose
		# comment was missing its leading '#', the sweep then rendered an empty scene
		# sixteen times, and the DNA critic dutifully called two working axes INERT at
		# 0.69%. The instrument was the fault, again.
		#
		# The signal that actually separates them is can_instantiate(). Measured on a
		# known-broken file and a known-good one rather than assumed:
		#     broken   load=obj  can_instantiate=false  reload=43
		#     good     load=obj  can_instantiate=true   reload=0
		# NOT `GDScript.new()` + source_code + reload(): a script built that way has no
		# resource_path, so its own preload() calls cannot resolve and it reports a parse
		# error for every file including the healthy ones. That second attempt failed both
		# files and would have sent me hunting a bug in dark_sphere that did not exist.
		# CACHE_MODE_IGNORE so a script already held by an autoload is re-read from disk.
		var gd := ResourceLoader.load(p, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if gd == null or not gd.can_instantiate():
			print("FAIL     %s" % p)
			failed.append(p)
		else:
			print("ok       %s" % p)

	print("\n%d checked, %d failed" % [paths.size(), failed.size()])
	for p in failed:
		print("  broken: %s" % p)
	quit(1 if failed.size() > 0 else 0)
