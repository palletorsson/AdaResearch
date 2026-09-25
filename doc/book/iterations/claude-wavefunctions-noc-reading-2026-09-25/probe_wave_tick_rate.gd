extends SceneTree
## probe_wave_tick_rate.gd — book_wavefunctions.014 and .015, 2026-09-25.
##
## Two predictions about the physics tick rate, measured before either sentence is
## written into a chapter:
##   .014  PendulumWave's FINE sampler (25 ms request) records gaps of 16.7/33.3 ms at
##         60 ticks a second and 22.2/33.3 ms at 90 (one tick short of the request and
##         one tick long, at each rate).
##   .015  control_pendulum's shipped `free` regime multiplies the angular velocity by
##         `damping` (0.995) ONCE PER TICK, so the same release keeps 0.995^60 = 0.740
##         of its velocity per second at 60 Hz and 0.995^90 = 0.637 at 90 Hz: the swing
##         dies sooner in the headset.
##
## Run:
##   python tools/godot_watchdog.py --expect=ada_run/probes/wave_tick_rate.json -- \
##     C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off \
##     --no-window --script res://commons/testing/probe_wave_tick_rate.gd
##
## The report is a JSON file; the verdict lines are printed too.

const OUT := "res://ada_run/probes/wave_tick_rate.json"
const PENDULUM_WAVE := "res://algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn"
const CONTROL_PENDULUM := "res://commons/artifacts/control_pendulum/control_pendulum.tscn"
const RATES: Array[int] = [60, 90]
const RECORD_SECONDS: float = 3.0
const SWING_SECONDS: float = 6.0

var _report: Dictionary = {"probe": "wave_tick_rate", "date": "2026-09-25", "rates": {}}


func _init() -> void:
	var root: Node = get_root()
	for rate in RATES:
		Engine.physics_ticks_per_second = rate
		var entry: Dictionary = {}
		entry["record"] = await _measure_record(root, rate)
		entry["swing"] = await _measure_swing(root, rate)
		_report["rates"][str(rate)] = entry
	Engine.physics_ticks_per_second = 60
	_verdicts()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/probes"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	print("[wave_tick_rate] wrote ", OUT)
	quit()


## .014 — instantiate the recorder, let it sample for RECORD_SECONDS, read the gaps
## between consecutive samples off its own trail (z holds the sample time).
func _measure_record(root: Node, rate: int) -> Dictionary:
	var scene: PackedScene = load(PENDULUM_WAVE)
	var node: Node = scene.instantiate()
	root.add_child(node)
	await physics_frame
	if node.has_method("set_sampler"):
		node.set_sampler("fine")
	if node.has_method("reset_experiment"):
		node.reset_experiment()
	var ticks: int = int(RECORD_SECONDS * rate)
	for i in ticks:
		await physics_frame
	var pts: Array = node.get("trail_points")
	var gaps: Dictionary = {}
	var n: int = 0
	for i in range(pts.size() - 1):
		var gap_ms: float = (pts[i].z - pts[i + 1].z) * 1000.0
		var key: String = "%.1f" % gap_ms
		gaps[key] = int(gaps.get(key, 0)) + 1
		n += 1
	var out: Dictionary = {
		"rate": rate, "tick_ms": 1000.0 / float(rate), "samples": pts.size(),
		"gaps_ms_histogram": gaps, "requested_ms": float(node.get("sample_interval")) * 1000.0,
	}
	print("[wave_tick_rate] record @%d Hz: %d samples, gaps %s" % [rate, pts.size(), JSON.stringify(gaps)])
	node.queue_free()
	await physics_frame
	return out


## .015 — instantiate the pendulum at its START_ANGLE, let it swing SWING_SECONDS in the
## shipped free regime, and take the largest |angle| over the final second as the
## surviving amplitude. The prediction is the per-second velocity factor 0.995^rate.
func _measure_swing(root: Node, rate: int) -> Dictionary:
	var scene: PackedScene = load(CONTROL_PENDULUM)
	var node: Node = scene.instantiate()
	root.add_child(node)
	await physics_frame
	await physics_frame
	var start_angle: float = float(node.get("_angle"))
	var ticks: int = int(SWING_SECONDS * rate)
	var last_second_start: int = ticks - rate
	var peak_last: float = 0.0
	var peak_first: float = 0.0
	for i in ticks:
		await physics_frame
		var a: float = absf(float(node.get("_angle")))
		if i < rate:
			peak_first = maxf(peak_first, a)
		if i >= last_second_start:
			peak_last = maxf(peak_last, a)
	var damping: float = float(node.get("damping"))
	var out: Dictionary = {
		"rate": rate, "regime": str(node.get("regime")), "damping_per_tick": damping,
		"start_angle": start_angle, "peak_first_second": peak_first, "peak_last_second": peak_last,
		"amplitude_kept_over_run": peak_last / maxf(peak_first, 1e-6),
		"predicted_velocity_kept_per_second": pow(damping, rate),
	}
	print("[wave_tick_rate] swing @%d Hz: first-second peak %.4f, last-second peak %.4f (kept %.3f); predicted per-second velocity factor %.3f" % [rate, peak_first, peak_last, out["amplitude_kept_over_run"], out["predicted_velocity_kept_per_second"]])
	node.queue_free()
	await physics_frame
	return out


func _verdicts() -> void:
	var r60: Dictionary = _report["rates"]["60"]
	var r90: Dictionary = _report["rates"]["90"]
	var kept60: float = r60["swing"]["amplitude_kept_over_run"]
	var kept90: float = r90["swing"]["amplitude_kept_over_run"]
	_report["verdict_015"] = "swing keeps %.3f of its amplitude over %.0f s at 60 Hz and %.3f at 90 Hz; %s" % [
		kept60, SWING_SECONDS, kept90, "DIES SOONER at 90 Hz as predicted" if kept90 < kept60 * 0.97 else "NO clear difference - prediction fails"]
	_report["verdict_014"] = "gap histograms: 60 Hz %s | 90 Hz %s" % [JSON.stringify(r60["record"]["gaps_ms_histogram"]), JSON.stringify(r90["record"]["gaps_ms_histogram"])]
	print("[wave_tick_rate] VERDICT .015: ", _report["verdict_015"])
	print("[wave_tick_rate] VERDICT .014: ", _report["verdict_014"])
