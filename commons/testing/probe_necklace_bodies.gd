extends SceneTree
## WHAT TEN LIVE BODIES ACTUALLY COST (2026-08-27).
##
## Palle: "we want to load the actual scenes and no fog what actually is in the
## maps from x to z". The necklace deals CAPTURE TILES because a survey said one
## cold instance is ~98 ms and a ten-wide window is therefore a second of frozen
## scroll. That number came from GridInteractablesComponent.gd:133 — thirteen
## interactables in 1281 ms inside a MAP BUILD — and ada_run/artifact_cost.txt
## already hints it is the wrong number to plan against: of 382 ms for four
## tokens, 361 ms was `load()` and 21 ms was `_ready()`, and the SECOND
## animatedcubebuilder cost 0.0 ms to load.
##
## So this probe separates the three costs the design actually needs kept apart:
##   LOAD    ResourceLoader, paid ONCE per scene path per process, cached after
##   INST    PackedScene.instantiate(), paid per body
##   READY   add_child() — the procedural build, paid per body
## and measures each token TWICE, so the warm row is what a pool actually pays.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_necklace_bodies.gd
##         -- --set=all
##
## --set=  head,mid,museum_head,museum_mid,worst,gpu,all   (default: all-but-gpu)
## --gpu-ready=1  also add_child() the marching-cubes tokens. OFF by default:
##                that is the documented segfault class and this probe is the
##                thing measuring it, not the thing dying to it.
##
## IT WRITES AFTER EVERY TOKEN. A hang or a segfault must still leave the rows
## it already had, and ada_run/necklace_bodies_cursor.txt names the token that
## was on the bench when the lights went out.

const OUT_JSON := "res://ada_run/necklace_bodies.json"
const OUT_TXT := "res://ada_run/necklace_bodies.txt"
const CURSOR := "res://ada_run/necklace_bodies_cursor.txt"
const SPINE := "res://commons/data/spine_order_effective.json"
const MUSEUM := "res://commons/data/museum_order_effective.json"
## The scene's own LIVE_SETTLE. probe_aabb_hogs.gd:55 — two process frames
## photographs a half-built artifact.
const SETTLE := 0.35

var _rows: Array = []
var _host: Node3D
var _spine: Array = []
var _mus: Array = []
var _gpu_ready: bool = false
var _windows: Array = []
var _jobs_n: Dictionary = {}   ## set -> jobs handed to pass one. A zero here is the tell.


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		var s := str(a)
		if s.begins_with("--%s=" % n):
			return s.substr(n.length() + 3)
	return fb


func _order_of(path: String) -> Array:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (doc is Dictionary):
		return []
	var o: Variant = (doc as Dictionary).get("order", [])
	return o if o is Array else []


## The necklace's own merged local AABB (desktop_necklace.gd:1515): root
## INCLUDED, GPUParticles3D excluded, MultiMesh and CSG counted.
func _local_aabb(node: Node3D) -> AABB:
	var out := AABB()
	var got := false
	var stack: Array = [node]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c is GPUParticles3D:
			continue
		if c is VisualInstance3D and c is Node3D:
			var a: AABB = (c as VisualInstance3D).get_aabb()
			if a.size.length() <= 0.0:
				continue
			var rel: Transform3D = node.global_transform.affine_inverse() * (c as Node3D).global_transform
			var w: AABB = rel * a
			if got:
				out = out.merge(w)
			else:
				out = w
				got = true
	return out


func _count(node: Node) -> Array:
	var nodes := 0
	var meshes := 0
	var stack: Array = [node]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		nodes += 1
		if c is MeshInstance3D or c is MultiMeshInstance3D or c is CSGShape3D:
			meshes += 1
		for g in c.get_children():
			stack.append(g)
	return [nodes, meshes]


## desktop_necklace.gd:1424 — release() is NOT on the root in 13 of 13 GPU
## tokens, so walk the subtree before the free.
func _release_walk(n: Node) -> int:
	var hits := 0
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for g in c.get_children():
			stack.append(g)
		if c.has_method("release"):
			c.call("release")
			hits += 1
	return hits


func _mem() -> int:
	return int(Performance.get_monitor(Performance.MEMORY_STATIC))


func _cursor(s: String) -> void:
	var f := FileAccess.open(CURSOR, FileAccess.WRITE)
	if f != null:
		f.store_string(s + "\n")
		f.close()


## One token, cold or warm. Returns the row.
func _bench(setname: String, token: String, path: String, do_ready: bool, warm: bool) -> Dictionary:
	var row: Dictionary = {"set": setname, "token": token, "warm": warm, "scene": path}
	if path == "" or not ResourceLoader.exists(path):
		row["note"] = "scene not on disk"
		return row
	var m0: int = _mem()
	var t0 := Time.get_ticks_usec()
	var ps: PackedScene = load(path) as PackedScene
	var t1 := Time.get_ticks_usec()
	row["load_ms"] = float(t1 - t0) / 1000.0
	if ps == null:
		row["note"] = "not a PackedScene"
		return row
	var n: Node = ps.instantiate()
	var t2 := Time.get_ticks_usec()
	row["inst_ms"] = float(t2 - t1) / 1000.0
	if not (n is Node3D):
		if n != null:
			n.free()
		row["note"] = "root is not a 3D node"
		return row
	var n3: Node3D = n as Node3D
	n3.set_meta("artifact_lookup_name", token)
	if not do_ready:
		row["note"] = "load+instantiate only (no _ready)"
		n3.free()
		return row
	var t2b := Time.get_ticks_usec()
	_host.add_child(n3)
	var t3 := Time.get_ticks_usec()
	row["ready_ms"] = float(t3 - t2b) / 1000.0

	# settle, exactly as the scene does before it measures an AABB
	var settled := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - settled) / 1000000.0 < SETTLE:
		await process_frame
	var box: AABB = _local_aabb(n3)
	row["aabb"] = [
		snappedf(box.size.x, 0.01), snappedf(box.size.y, 0.01), snappedf(box.size.z, 0.01)]
	row["max_m"] = snappedf(maxf(box.size.x, maxf(box.size.y, box.size.z)), 0.01)
	var cn: Array = _count(n3)
	row["nodes"] = cn[0]
	row["meshes"] = cn[1]
	row["mem_kb"] = int(float(_mem() - m0) / 1024.0)

	var t4 := Time.get_ticks_usec()
	row["release_hits"] = _release_walk(n3)
	var t5 := Time.get_ticks_usec()
	row["release_ms"] = float(t5 - t4) / 1000.0
	n3.queue_free()
	await process_frame
	await process_frame
	row["note"] = ""
	return row


func _flush() -> void:
	var doc: Dictionary = {
		"probe": "commons/testing/probe_necklace_bodies.gd",
		"when": Time.get_datetime_string_from_system(),
		"headless": DisplayServer.get_name() == "headless",
		"driver": DisplayServer.get_name(),
		## THE GPU ROWS ARE ONLY WORTH READING IF THIS IS TRUE. Headless has no
		## RenderingDevice, so a marching-cubes _ready() that submits a compute
		## dispatch does not dispatch anything and its cost is a floor, not a cost.
		"has_rendering_device": RenderingServer.get_rendering_device() != null,
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"settle_s": SETTLE,
		"rows": _rows,
		"windows": _windows,
		"jobs": _jobs_n,
	}
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(doc, "\t"))
		f.close()


func _pick(order: Array, idx: Array, setname: String) -> Array:
	var out: Array = []
	for i in idx:
		var k: int = int(i)
		if k < 0 or k >= order.size():
			continue
		var r: Dictionary = order[k]
		out.append({"set": setname, "i": k, "token": str(r.get("lookup", "")),
			"scene": str(r.get("scene", "")), "alive": bool(r.get("alive", true)),
			"body": bool(r.get("body", true)), "size_m": _f(r.get("size_m"))})
	return out


## float(null) IS AN INVALID CONVERSION, and 38 spine rows / 45 museum rows carry
## size_m: null (coordinate_readout is spine index 4 and museum index 7). The
## first two runs of this probe called float() on it, _pick ABORTED mid-loop, both
## head sets came back EMPTY, and the head windows reported built=0 refused=0 —
## a clean pass over nothing. The 4.6 exe is non-console, so headless printed no
## error. desktop_necklace.gd guards this in all four places it reads size_m.
func _f(v: Variant) -> float:
	if v == null:
		return 0.0
	return float(v)


## A while loop, not `for i in range(a, b)`. The first cut of this probe used
## range() and _range(0, 10) came back EMPTY while _range(400, 410) and
## _range(810, 820) both returned ten — so both head sets and both head windows
## measured nothing and reported built=0, refused=0, which reads exactly like a
## refusal. If a probe reports zero of anything, check the count before believing it.
func _range(a: int, b: int) -> Array:
	var out: Array = []
	var i: int = a
	while i < b:
		out.append(i)
		i += 1
	return out


## The refusal the scene already carries (desktop_necklace.gd:1370), so the
## probe and the scene cannot drift about what is a GPU token.
func _is_gpu(scene: String) -> bool:
	var s := scene.to_lower()
	return s.contains("isosurfaces") or s.contains("marchingcube") or s.contains("marchingcave")


## CAN THE LOAD COME OFF THE MAIN THREAD? Everything above says a cold ten-window
## is ~85% ResourceLoader and ~15% _ready, so this is the whole question: if
## load() can run on a worker while the scroll keeps its frames, the necklace can
## deal real bodies and only pay _ready on the main thread.
##   Two disjoint sets of ten scenes, both COLD in this process. One is fetched
## with load_threaded_request + poll, the other with a blocking load(). What is
## reported for the threaded set is MAIN-THREAD time only: the poll, the get, the
## instantiate and the add_child. The wall clock is reported beside it, because a
## worker that takes 900 ms of wall to save 400 ms of main thread is still the
## right trade for a scroll, and the wrong one for a jump.
func _threaded_run() -> void:
	# The two sets are DIFFERENT TOKENS, so the comparison is only worth
	# anything run both ways round: --ta / --ba swap which ten goes on which
	# path, and a real speed-up has to survive the swap.
	var ta: int = int(_arg("ta", "100"))
	var ba: int = int(_arg("ba", "110"))
	var a: Array = _pick(_spine, _range(ta, ta + 10), "threaded")
	var b: Array = _pick(_spine, _range(ba, ba + 10), "blocking")
	var paths: Array = []
	for j_v in a:
		var j: Dictionary = j_v
		var sc := str(j["scene"])
		if sc != "" and ResourceLoader.exists(sc) and not _is_gpu(sc) 				and bool(j["body"]) and bool(j["alive"]):
			paths.append(sc)

	# ── threaded ────────────────────────────────────────────────────────────
	_cursor("threaded request")
	var wall0 := Time.get_ticks_usec()
	var main_us: int = 0
	var r0 := Time.get_ticks_usec()
	for pth in paths:
		ResourceLoader.load_threaded_request(str(pth))
	main_us += Time.get_ticks_usec() - r0
	var frames: int = 0
	var pending: Array = paths.duplicate()
	while not pending.is_empty() and frames < 600:
		await process_frame
		frames += 1
		var f0 := Time.get_ticks_usec()
		var still: Array = []
		for pth2 in pending:
			var st: int = ResourceLoader.load_threaded_get_status(str(pth2))
			if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				still.append(pth2)
		pending = still
		main_us += Time.get_ticks_usec() - f0
	var ready_wall := Time.get_ticks_usec()
	var built: int = 0
	var g0 := Time.get_ticks_usec()
	var live: Array = []
	for pth3 in paths:
		var ps: PackedScene = ResourceLoader.load_threaded_get(str(pth3)) as PackedScene
		if ps == null:
			continue
		var n: Node = ps.instantiate()
		if not (n is Node3D):
			if n != null:
				n.free()
			continue
		_host.add_child(n)
		live.append(n)
		built += 1
	main_us += Time.get_ticks_usec() - g0
	var wall1 := Time.get_ticks_usec()
	_windows.append({
		"window": "threaded_ten_%d" % ta, "built": built, "refused": paths.size() - built,
		"build_ms": snappedf(float(main_us) / 1000.0, 0.1),
		"wall_ms": snappedf(float(wall1 - wall0) / 1000.0, 0.1),
		"worker_wait_ms": snappedf(float(ready_wall - wall0) / 1000.0, 0.1),
		"frames_waited": frames, "free_ms": 0.0, "mem_kb": 0,
	})
	for n_v in live:
		var nn: Node = n_v
		_release_walk(nn)
		nn.queue_free()
	await process_frame
	await process_frame
	_flush()

	# ── blocking, the same shape ────────────────────────────────────────────
	_cursor("blocking ten")
	await _window_run("blocking_ten_%d" % ba, b, true)


func _run() -> void:
	_gpu_ready = _arg("gpu-ready", "0") == "1"
	var want := _arg("set", "default")
	_spine = _order_of(SPINE)
	_mus = _order_of(MUSEUM)
	_host = Node3D.new()
	get_root().add_child(_host)

	if _arg("bench", "") == "env":
		# "no fog" — is there any? A fresh Environment's own defaults, so the
		# recipe can say "already off, and here is the proof" or "on, turn it off".
		var e := Environment.new()
		var env: Dictionary = {
			"fog_enabled": e.fog_enabled,
			"volumetric_fog_enabled": e.volumetric_fog_enabled,
			"fog_density": e.fog_density,
			"fog_light_color": [e.fog_light_color.r, e.fog_light_color.g, e.fog_light_color.b],
			"fog_aerial_perspective": e.fog_aerial_perspective,
			"fog_sky_affect": e.fog_sky_affect,
			"ssao_enabled": e.ssao_enabled,
			"ssil_enabled": e.ssil_enabled,
			"sdfgi_enabled": e.sdfgi_enabled,
			"glow_enabled": e.glow_enabled,
			"tonemap_mode": e.tonemap_mode,
			"tonemap_white": e.tonemap_white,
			"ambient_light_source": e.ambient_light_source,
			"ambient_light_energy": e.ambient_light_energy,
			"background_mode": e.background_mode,
			"adjustment_enabled": e.adjustment_enabled,
		}
		_windows.append({"window": "environment_defaults", "built": 0, "refused": 0,
			"build_ms": 0.0, "free_ms": 0.0, "mem_kb": 0, "env": env})
		_flush()
		_cursor("done")
		quit(0)
		return

	if _arg("bench", "") == "threaded":
		await _threaded_run()
		_flush()
		_write_text()
		_cursor("done")
		quit(0)
		return

	var jobs: Array = []
	var do_head: bool = want == "default" or want == "all" or want.contains("head")
	if do_head:
		jobs.append_array(_pick(_spine, _range(0, 10), "spine_head"))
	if want == "default" or want == "all" or want.contains("mid"):
		jobs.append_array(_pick(_spine, _range(400, 410), "spine_mid"))
	if want == "default" or want == "all" or want.contains("museum"):
		jobs.append_array(_pick(_mus, _range(0, 10), "museum_head"))
		jobs.append_array(_pick(_mus, _range(810, 820), "museum_mid"))
	if want == "default" or want == "all" or want.contains("worst"):
		# the heaviest NON-GPU bodies in the corpus: biggest size_m and biggest
		# footprint cells, which is where a normalised bead volume is tested
		jobs.append_array(_pick(_spine, [334, 529, 537, 714, 578, 637, 166, 221, 436, 389],
			"worst"))
	var idx_arg := _arg("idx", "")
	if idx_arg != "":
		var ii: Array = []
		for tok in idx_arg.split(","):
			ii.append(int(str(tok)))
		jobs.append_array(_pick(_spine, ii, "idx"))
	if want == "all" or want.contains("gpu"):
		jobs.append_array(_pick(_spine, [656, 663, 671, 658, 677, 654], "gpu"))

	for j_c in jobs:
		var kk := str((j_c as Dictionary)["set"])
		_jobs_n[kk] = int(_jobs_n.get(kk, 0)) + 1
	_flush()

	# ── pass one: cold, one row per token ───────────────────────────────────
	var seen: Dictionary = {}
	for j_v in jobs:
		var j: Dictionary = j_v
		var token := str(j["token"])
		var scene := str(j["scene"])
		if token == "boid_flocking":
			_rows.append({"set": j["set"], "token": token, "note": "REFUSED: never yields headless"})
			continue
		if not bool(j["body"]):
			_rows.append({"set": j["set"], "token": token, "note": "REFUSED: root is not a 3D node"})
			continue
		if not bool(j["alive"]):
			_rows.append({"set": j["set"], "token": token, "note": "REFUSED: dead"})
			continue
		var gpu: bool = _is_gpu(scene)
		var do_ready: bool = (not gpu) or _gpu_ready
		var warm: bool = seen.has(scene)
		seen[scene] = true
		_cursor("%s / %s%s" % [str(j["set"]), token, " [GPU]" if gpu else ""])
		var row: Dictionary = await _bench(str(j["set"]), token, scene, do_ready, warm)
		row["i"] = j["i"]
		row["size_m"] = j["size_m"]
		row["gpu"] = gpu
		_rows.append(row)
		_flush()

	# ── pass two: the ten-window, as a wall clock ───────────────────────────
	# Cold and warm, on the spine head and the museum head. The museum head is
	# the interesting one: 1,633 rows hold 1,302 distinct tokens, so a window
	# repeats scenes and the cache is what the design leans on.
	await _window_run("spine_head_cold", _pick(_spine, _range(0, 10), "w"), true)
	await _window_run("spine_head_warm", _pick(_spine, _range(0, 10), "w"), true)
	await _window_run("museum_head_cold", _pick(_mus, _range(0, 10), "w"), true)
	await _window_run("museum_head_warm", _pick(_mus, _range(0, 10), "w"), true)
	# one notch: the steady-state scroll cost — build ONE, free ONE
	await _window_run("one_notch_cold", _pick(_spine, [10], "w"), true)
	await _window_run("one_notch_warm", _pick(_spine, [10], "w"), true)

	_flush()
	_write_text()
	_cursor("done")
	quit(0)


func _window_run(label: String, jobs: Array, do_ready: bool) -> void:
	_cursor("window " + label)
	var m0: int = _mem()
	var live: Array = []
	var t0 := Time.get_ticks_usec()
	var built := 0
	var refused := 0
	for j_v in jobs:
		var j: Dictionary = j_v
		var scene := str(j["scene"])
		if str(j["token"]) == "boid_flocking" or not bool(j["body"]) \
				or not bool(j["alive"]) or _is_gpu(scene):
			refused += 1
			continue
		if not ResourceLoader.exists(scene):
			refused += 1
			continue
		var ps: PackedScene = load(scene) as PackedScene
		if ps == null:
			refused += 1
			continue
		var n: Node = ps.instantiate()
		if not (n is Node3D):
			if n != null:
				n.free()
			refused += 1
			continue
		var n3: Node3D = n as Node3D
		n3.set_meta("artifact_lookup_name", str(j["token"]))
		if do_ready:
			_host.add_child(n3)
			live.append(n3)
			built += 1
		else:
			n3.free()
	var t1 := Time.get_ticks_usec()
	var settled := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - settled) / 1000000.0 < SETTLE:
		await process_frame
	var mem_kb: int = int(float(_mem() - m0) / 1024.0)
	var t2 := Time.get_ticks_usec()
	for n_v in live:
		var n3b: Node3D = n_v
		_release_walk(n3b)
		n3b.queue_free()
	var t3 := Time.get_ticks_usec()
	await process_frame
	await process_frame
	_windows.append({
		"window": label, "built": built, "refused": refused,
		"build_ms": snappedf(float(t1 - t0) / 1000.0, 0.1),
		"free_ms": snappedf(float(t3 - t2) / 1000.0, 0.1),
		"mem_kb": mem_kb,
	})
	_flush()


func _write_text() -> void:
	var s := "TEN LIVE BODIES — what it costs  (%s, driver %s)\n\n" % [
		Time.get_datetime_string_from_system(), DisplayServer.get_name()]
	s += "  %-8s %-32s %7s %7s %7s %7s %6s %6s %8s\n" % [
		"set", "token", "load", "inst", "_ready", "sum", "max_m", "mesh", "mem_kb"]
	var by_set: Dictionary = {}
	for r_v in _rows:
		var r: Dictionary = r_v
		if str(r.get("note", "")) != "":
			s += "  %-8s %-32s  %s\n" % [str(r.get("set", "")), str(r.get("token", "")),
				str(r["note"])]
			continue
		var lo: float = float(r.get("load_ms", 0.0))
		var ins: float = float(r.get("inst_ms", 0.0))
		var rd: float = float(r.get("ready_ms", 0.0))
		s += "  %-8s %-32s %7.1f %7.1f %7.1f %7.1f %6.1f %6d %8d\n" % [
			str(r.get("set", "")), str(r.get("token", "")), lo, ins, rd, lo + ins + rd,
			float(r.get("max_m", 0.0)), int(r.get("meshes", 0)), int(r.get("mem_kb", 0))]
		var k := str(r.get("set", ""))
		if not by_set.has(k):
			by_set[k] = [0.0, 0.0, 0.0, 0]
		var acc: Array = by_set[k]
		acc[0] += lo
		acc[1] += ins
		acc[2] += rd
		acc[3] += 1
		by_set[k] = acc
	s += "\n  per set: load / instantiate / _ready, and the count\n"
	for k2 in by_set.keys():
		var a: Array = by_set[k2]
		s += "    %-14s %8.1f %8.1f %8.1f   n=%d\n" % [str(k2), a[0], a[1], a[2], int(a[3])]
	s += "\n  WINDOWS (build all, settle, free all)\n"
	s += "    %-20s %6s %8s %8s %9s\n" % ["window", "built", "build_ms", "free_ms", "mem_kb"]
	for w_v in _windows:
		var w: Dictionary = w_v
		s += "    %-20s %6d %8.1f %8.1f %9d\n" % [str(w["window"]), int(w["built"]),
			float(w["build_ms"]), float(w["free_ms"]), int(w["mem_kb"])]
	var f := FileAccess.open(OUT_TXT, FileAccess.WRITE)
	if f != null:
		f.store_string(s)
		f.close()
	print(s)
