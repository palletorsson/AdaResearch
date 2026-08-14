extends Node
## Stick drift, answered with CALIBRATION instead of a wall.
##
## The January version of this file raised the y deadzone to 0.5 to mask a
## left stick that already drifted to 0.42 at rest. That wall worked while the
## stick's forward throw still cleared it — and stopped working the day wear
## pushed the reachable range down to the wall's height: full forward produced
## almost nothing, and the walk was dead. Nothing in the repo changed; the
## HARDWARE crossed a threshold the software had built.
##
## This version samples each stick AT REST during the first seconds of a
## session, writes the measured rest point into
## XRToolsUserSettings.stick_rest_offsets, and drops the deadzone to a normal
## 0.2 — get_adjusted_vector2 recentres and rescales, so a stick resting at
## +0.42 recovers its full range in both directions. If calibration fails
## (controller missing, stick held, offset absurd) the old 0.5/0.3 wall is
## applied EXACTLY as before, so the fallback is the behavior this file
## always had.
##
## TWO WRITERS live on these numbers (the hidden-dependencies clause): this
## calibrator and the XR Tools settings UI / user://xtools_user_settings.json.
## The calibrator runs after the settings load and says what it did, loudly.
##
## The debug stream is the evidence channel: watch the log for
## `JoystickCalibrate:` lines — rest offsets at boot, then a rolling
## min/max reach per stick every few seconds while you push it. One VR
## session tells you exactly how worn each axis is.

@export var calibrate: bool = true
@export var deadzone_after_calibration: float = 0.2
@export var fallback_y_deadzone: float = 0.5   # the January wall, kept as fallback
@export var fallback_x_deadzone: float = 0.3
@export var settle_delay: float = 1.0          # controllers need a moment to exist
@export var sample_window: float = 1.5         # seconds of rest sampling
@export var debug_joystick: bool = true
@export var debug_interval: float = 5.0

var _left: XRController3D
var _right: XRController3D
var _debug_timer: float = 0.0
var _reach: Dictionary = {}   # tracker -> {min: Vector2, max: Vector2}


func _ready() -> void:
	print("JoystickCalibrate: waiting %.1fs for controllers..." % settle_delay)
	await get_tree().create_timer(settle_delay).timeout
	_left = XRHelpers.get_left_controller(self)
	_right = XRHelpers.get_right_controller(self)
	if calibrate:
		await _calibrate()
	else:
		_apply_fallback("calibration disabled")


func _calibrate() -> void:
	var samples: Dictionary = {}  # tracker -> Array[Vector2]
	var t := 0.0
	while t < sample_window:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		for c in [_left, _right]:
			if c == null:
				continue
			var key := str(c.tracker)
			if not samples.has(key):
				samples[key] = []
			(samples[key] as Array).append(c.get_vector2("primary"))

	if samples.is_empty():
		_apply_fallback("no controllers found in the sample window")
		return

	var settings := XRToolsUserSettings
	if settings == null:
		_apply_fallback("XRToolsUserSettings autoload missing")
		return
	# the offset store lives in a PATCHED user_settings.gd (tracked with -f
	# inside the otherwise-gitignored addon — the July lesson about code
	# landing outside the repo). A stock addon has no such property; write
	# nothing and keep the old wall, with the missing patch named.
	if not ("stick_rest_offsets" in settings):
		_apply_fallback("user_settings.gd lacks stick_rest_offsets — stock XR Tools, patch not applied")
		return

	var calibrated := 0
	for key in samples:
		var arr: Array = samples[key]
		var mean := Vector2.ZERO
		for v in arr:
			mean += v
		mean /= arr.size()
		var spread := 0.0
		for v in arr:
			spread = maxf(spread, (v as Vector2 - mean).length())
		# a held or waggled stick is not a rest measurement; an offset near
		# full deflection is a broken read, not drift
		if spread > 0.15 or mean.length() > 0.7:
			print("JoystickCalibrate: %s REJECTED (rest %.3f,%.3f spread %.3f) — stick moving or reading absurd"
				% [key, mean.x, mean.y, spread])
			continue
		settings.stick_rest_offsets[key] = mean
		calibrated += 1
		print("JoystickCalibrate: %s rest offset (%.3f, %.3f) over %d samples"
			% [key, mean.x, mean.y, arr.size()])

	if calibrated == 0:
		_apply_fallback("every controller rejected calibration")
		return
	settings.y_axis_dead_zone = deadzone_after_calibration
	settings.x_axis_dead_zone = deadzone_after_calibration
	print("JoystickCalibrate: SUCCESS — %d stick(s) recentred, deadzone %.2f (was the 0.5 wall)"
		% [calibrated, deadzone_after_calibration])


func _apply_fallback(why: String) -> void:
	if XRToolsUserSettings:
		XRToolsUserSettings.y_axis_dead_zone = fallback_y_deadzone
		XRToolsUserSettings.x_axis_dead_zone = fallback_x_deadzone
		print("JoystickCalibrate: FALLBACK (%s) — deadzone y=%.2f x=%.2f, the pre-calibration wall"
			% [why, fallback_y_deadzone, fallback_x_deadzone])
	else:
		push_warning("JoystickCalibrate: XRToolsUserSettings not found — deadzone NOT applied (%s)" % why)


func _physics_process(delta: float) -> void:
	if not debug_joystick:
		return
	for c in [_left, _right]:
		if c == null:
			continue
		var key: String = str(c.tracker)
		var raw: Vector2 = c.get_vector2("primary")
		if not _reach.has(key):
			_reach[key] = {"min": Vector2.ZERO, "max": Vector2.ZERO}
		var r: Dictionary = _reach[key]
		r["min"] = Vector2(minf((r["min"] as Vector2).x, raw.x), minf((r["min"] as Vector2).y, raw.y))
		r["max"] = Vector2(maxf((r["max"] as Vector2).x, raw.x), maxf((r["max"] as Vector2).y, raw.y))
	_debug_timer += delta
	if _debug_timer < debug_interval:
		return
	_debug_timer = 0.0
	for key in _reach:
		var r: Dictionary = _reach[key]
		var lo: Vector2 = r["min"]
		var hi: Vector2 = r["max"]
		if lo.length() > 0.05 or hi.length() > 0.05:
			print("JoystickCalibrate: %s reach x[%.2f..%.2f] y[%.2f..%.2f]"
				% [key, lo.x, hi.x, lo.y, hi.y])
