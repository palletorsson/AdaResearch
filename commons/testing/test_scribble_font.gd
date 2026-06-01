extends SceneTree

## Diagnose why the chalkboard renders symbols but not Latin text. The
## scribble renderer uses a TTF for Latin/digits and hand-strokes only for
## STROKE_ONLY symbols. If the font fails to load (or has_char fails), Latin
## chars fall through to an empty glyph table and draw NOTHING — exactly the
## "only symbols show" symptom.
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/test_scribble_font.gd

const FONT_PATH := "res://commons/font/handwriting/ArchitectsDaughter.ttf"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("[font] file exists (ResourceLoader)=%s" % ResourceLoader.exists(FONT_PATH))
	print("[font] FileAccess exists=%s" % FileAccess.file_exists(FONT_PATH))

	# Reproduce scribble_control._load_font() exactly.
	var f := FontFile.new()
	var err := f.load_dynamic_font(FONT_PATH)
	print("[font] load_dynamic_font err=%s (0=OK)" % err)
	if err == OK:
		for ch in ["P", "A", "t", "h", "e", "0", "=", "(", ")"]:
			print("[font]   has_char('%s')=%s  size=%s" %
				[ch, f.has_char(ch.unicode_at(0)),
				 f.get_char_size(ch.unicode_at(0), 100)])

	# Does loading via load() (imported resource) behave differently?
	var imported = load(FONT_PATH)
	print("[font] load() type=%s" % (imported.get_class() if imported else "null"))
	if imported is FontFile:
		print("[font] imported.has_char('P')=%s" % imported.has_char("P".unicode_at(0)))

	# Can the scribble control itself load it?
	var sc_script: GDScript = load("res://commons/primitives/scribble/scribble_control.gd")
	print("[font] scribble script loaded=%s" % (sc_script != null))

	quit(0)
