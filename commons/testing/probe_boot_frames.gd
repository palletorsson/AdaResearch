extends SceneTree
## WHERE A BOOT'S SECONDS GO WHEN NO STAMP COVERS THEM (2026-09-14).
##
## A New Game boot measured 22 s, and 5-8 s of it sat between the museum's boot_tail and
## first_frame stamps — a window with no physics tick, no idle frame and no draw, so no
## stamp could split it. This probe loads the museum as the current scene and records:
##   events   every physics tick, idle frame, pre/post draw
##   added    every node that enters the tree before the first draw, with its script
##   logs     every engine log line, timestamped (an OS Logger)
##   markers  a DEFERRED call queued behind every added node and every main-thread log
##            line, stamped when it runs. Deferred calls run in queue order, so the first
##            marker that runs after a gap names the moment the slow call was QUEUED.
## That is how the 5.1 s was found: ~20 NoiseTexture2D warmed by em_materials, whose first
## generation the engine runs synchronously (fixed in em_materials.gd::_tex).
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_boot_frames.gd \
##       -- --em-chapter=primitives --em-map=Point_One [--em-no-costume] [--em-quality=perf]
##
## Writes <evidence root>/boot-frames/probe_boot_frames.json and quits. Read the largest jump
## between consecutive markers' run times.

const Evidence := preload("res://commons/testing/evidence_root.gd")

var t0 := 0
var events: Array = []
var em: Node = null
var draws := 0
var idles := 0
var added: Array = []
var logs: Array = []
var markers: Array = []


class Stamp extends Logger:
	var sink: Array
	var marks = null
	var t0: int
	var m := Mutex.new()

	func _log_message(message: String, error: bool) -> void:
		m.lock()
		sink.append([Time.get_ticks_msec() - t0, message.strip_edges().left(160)])
		m.unlock()
		if OS.get_thread_caller_id() == OS.get_main_thread_id() and marks != null:
			var idx: int = marks.size()
			marks.append([Time.get_ticks_msec() - t0, -1, "LOG " + message.strip_edges().left(100)])
			(func(): marks[idx][1] = Time.get_ticks_msec() - t0).call_deferred()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		m.lock()
		sink.append([Time.get_ticks_msec() - t0, "ERR " + rationale.left(150)])
		m.unlock()


func _stamp(kind: String) -> void:
	events.append([kind, Time.get_ticks_msec() - t0])


func _initialize() -> void:
	t0 = Time.get_ticks_msec()
	var st := Stamp.new()
	st.sink = logs
	st.t0 = t0
	st.marks = markers
	OS.add_logger(st)
	physics_frame.connect(func(): _stamp("physics"))
	process_frame.connect(func():
		idles += 1
		_stamp("idle"))
	RenderingServer.frame_pre_draw.connect(func(): _stamp("pre_draw"))
	RenderingServer.frame_post_draw.connect(func():
		draws += 1
		_stamp("post_draw"))
	node_added.connect(func(n: Node):
		if draws == 0 and added.size() < 60000:
			var s = n.get_script()
			added.append([Time.get_ticks_msec() - t0, str(n.get_path()), s.resource_path if s != null else n.get_class()])
			var idx := markers.size()
			markers.append([Time.get_ticks_msec() - t0, -1, str(n.get_path())])
			(func(): markers[idx][1] = Time.get_ticks_msec() - t0).call_deferred())
	var scene: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	_stamp("scene_loaded")
	em = scene.instantiate()
	root.add_child(em)
	current_scene = em
	_stamp("added")
	_watch.call_deferred()


func _watch() -> void:
	while Time.get_ticks_msec() - t0 < 90000:
		await process_frame
		var bm = em.get("_boot_ms") if em != null else null
		if bm is Dictionary and (bm as Dictionary).has("content_ready") and draws > 40:
			break
	var out := {"events": events.slice(0, 600), "boot_ms": em.get("_boot_ms") if em != null else {},
		"draws": draws, "idles": idles, "added": added, "logs": logs, "markers": markers}
	var path: String = Evidence.dir("boot-frames").path_join("probe_boot_frames.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(out, " "))
	f.close()
	print("BOOT FRAMES -> %s" % path)
	quit(0)
