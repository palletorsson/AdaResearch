extends SceneTree
## Supplied check harness. A kit's verify.gd begins with this line
##   extends "res://supplied/verify_tools.gd"
## and writes ONE function, run(), made of checks. Do not write _initialize().
## Run it headless, from the kit's folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Contract:
##   check(ok, text)   one check: prints PASS or FAIL with the text, and counts it
##   run()             yours. When it returns, the harness writes the result and quits
##   measured          a dictionary of your own: numbers worth keeping
##   result_file       where the result is written: res://verification.json
##   errors, warnings  what Godot logged since the run began, as texts: every
##                     error, script error and shader error; and every warning
##   printed           every line printed since the run began
##   frames(n), physics_frames(n), settle(body), near(a, b), press(action),
##   hold(action, steps), walk(walker, points)    helpers; `await` the ones that wait
## It writes verification.json beside project.godot: `passed`, `checks` (each
## with `name` and `passed`), `measured`. The exit code is the number of checks
## that failed, so 0 when all passed; a run with no check at all exits 1.
## A script error in verify.gd skips the rest of the function it happens in, in
## silence: the checks after it are never made. So the harness watches for one
## and, at the end, adds a failed check that names it. And a run that waits for
## something that never comes (a signal, a body that never lies still) would
## never quit. So: 60 seconds without a new check, and the harness adds one
## failed check, writes the result and exits.

var checks: Array = []
var measured := {}
var result_file := "res://verification.json"

var errors: Array[String]:
	get: return _catcher.copy(_catcher.errors)
var warnings: Array[String]:
	get: return _catcher.copy(_catcher.warnings)
var printed: Array[String]:
	get: return _catcher.copy(_catcher.lines)

var _catcher := Catcher.new()
var _last_sign := 0        # when the last check was written, in milliseconds
var _finished := false

## Godot hands every message to a Logger. This one keeps them as texts.
class Catcher extends Logger:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var lines: Array[String] = []
	var own: Array[String] = []     # the script errors in the files of `watch`
	var watch: Array[String] = []
	var lock := Mutex.new()   # messages can come from other threads

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var said := rationale if rationale != "" else code
		lock.lock()
		if error_type == ERROR_TYPE_WARNING:
			warnings.append("WARNING: " + said)
		elif error_type == ERROR_TYPE_SCRIPT:
			errors.append("SCRIPT ERROR: %s (%s:%d)" % [said, file, line])
			if watch.has(file):
				own.append(errors[-1])
		elif error_type == ERROR_TYPE_SHADER:
			errors.append("SHADER ERROR: %s (%s:%d)" % [said, file, line])
		else:
			errors.append("ERROR: " + said)
		lock.unlock()

	func _log_message(message: String, _error: bool) -> void:
		lock.lock()
		lines.append(message.strip_edges(false, true))
		lock.unlock()

	func copy(list: Array[String]) -> Array[String]:
		lock.lock()
		var out := list.duplicate()
		lock.unlock()
		return out

func _initialize() -> void:
	_catcher.watch = [(get_script() as Script).resource_path, "res://supplied/verify_tools.gd"]
	OS.add_logger(_catcher)
	_begin.call_deferred()
	_give_up.call_deferred()

func _begin() -> void:
	await run()
	finish()

## The kit's own checks go here: write `func run() -> void:` in verify.gd.
func run() -> void:
	pass

func check(ok: bool, text: String) -> void:
	checks.append({"name": text, "passed": ok})
	print(("PASS " if ok else "FAIL ") + text)
	_last_sign = Time.get_ticks_msec()

func _give_up() -> void:
	_last_sign = Time.get_ticks_msec()
	while Time.get_ticks_msec() - _last_sign < 60000:
		await process_frame
	check(false, "verify.gd ran to its end (it did not: 60 seconds passed without a new check; it is waiting for something that does not come)")
	finish()

func finish() -> void:
	if _finished:
		return
	var own := _catcher.copy(_catcher.own)
	if not own.is_empty():
		check(false, "verify.gd ran without a script error of its own (it did not; the rest of that function was skipped: %s)" % own[0])
	_finished = true
	OS.remove_logger(_catcher)
	var failed := write_result(result_file)
	var passed := failed == 0 and not checks.is_empty()
	print("%s: %d checks, %d failed; passed=%s" % [ProjectSettings.get_setting("application/config/name", ""), checks.size(), failed, passed])
	quit(0 if passed else clampi(failed, 1, 100))

## Writes the result as it stands to `path`; returns how many checks failed.
## finish() calls it for result_file. `passed` is true when no check failed
## and at least one was made.
func write_result(path: String) -> int:
	var failed := 0
	for entry: Dictionary in checks:
		if not entry["passed"]:
			failed += 1
	var report := {
		"passed": failed == 0 and not checks.is_empty(), "kit": ProjectSettings.get_setting("application/config/name", ""),
		"godot": Engine.get_version_info().string, "checks_run": checks.size(), "checks_failed": failed,
		"measured": measured, "checks": checks,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()   # a file is whole on the disk once it is closed
	return failed

## Wait `count` frames. A node added to the scene has run _ready() one frame later.
func frames(count: int) -> void:
	for i in count:
		await process_frame

## Wait `count` steps of the physics: 60 of them are one second of the scene's time.
func physics_frames(count: int) -> void:
	for i in count:
		await physics_frame

## Wait until a dropped body lies still (at most ten seconds); returns where it lies.
func settle(body: RigidBody3D) -> Vector3:
	for i in 600:
		await physics_frame
		if i > 60 and body.sleeping:
			break
	return body.global_position

func near(a: Vector3, b: Vector3, slack := 0.0005) -> bool:
	return (a - b).length() < slack

## Press and release an action of the Input Map, as a key would: every script
## that asks is_action_just_pressed() sees it once.
func press(action: String) -> void:
	await process_frame
	Input.action_press(action)
	await physics_frame
	await process_frame
	Input.action_release(action)
	await process_frame

## Hold an action down for `steps` steps of the physics, then let go.
func hold(action: String, steps: int) -> void:
	await process_frame
	Input.action_press(action)
	await physics_frames(steps)
	Input.action_release(action)
	await process_frame

## Send the supplied walker along `points` on its autopilot and wait for the
## end. Returns how the walk ended: "arrived", "blocked", "fell" or "stopped".
func walk(walker: Node, points: Array) -> String:
	walker.walk_to(points)
	var how: String = await walker.walk_ended
	await process_frame   # leave the signal before anything frees the walker
	return how
