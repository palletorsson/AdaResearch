extends SceneTree
## STICKERS, THE ROUND TRIP (2026-11-13): the game half of tools/stickers_roundtrip.py. The game's StickerData reads
## a TEST SANDBOX - the Python half's copy of the truth, ada_run/stickers/sandbox/<id>/ - keeps its outbox beside it,
## and posts to the real route NAMING the sandbox (?sandbox=<id>), so the route writes the copy. The truth is never
## read for writing, posted to or restored. Two legs:
##   web -> game: the Python half posts an 'add' to /api/stickers/ops (as the page does); the game must see the new
##               sticker through its own file watch (no bridge), and says how long it took;
##   game -> web: the game sticks one of its own (StickerData.stick, as the pad does) and flushes its outbox to the
##               route; the Python half then reads it back from GET /api/stickers.
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/stickers_roundtrip.gd -- --out=<dir> --web-id=<id>
##       --data-dir=<the sandbox, absolute> --sandbox=<its id>
const StickerData := preload("res://commons/stickers/sticker_data.gd")


func _initialize() -> void:
	run.call_deferred()


func _write(path: String, value: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(value, "\t"))
	f.close()


## The server must refuse an unknown sandbox with 422 and say so: "" when it does, else why not.
func _preflight(url: String) -> String:
	var http := HTTPRequest.new()
	http.timeout = 15.0
	root.add_child(http)
	var err := http.request(url.trim_suffix("/") + "/api/stickers?sandbox=no-such-sandbox-preflight")
	if err != OK:
		http.queue_free()
		return "the preflight could not start (%s)" % error_string(err)
	var res: Array = await http.request_completed
	http.queue_free()
	var body := (res[3] as PackedByteArray).get_string_from_utf8()
	if int(res[1]) == 422 and body.contains("no test sandbox"):
		return ""
	return "the server answered %d to an unknown sandbox: %s" % [int(res[1]), body.left(120)]


func run() -> void:
	var folder := ""
	var web_id := ""
	var box := ""
	var sandbox := ""
	var url := "http://127.0.0.1:3003"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--web-id="): web_id = arg.trim_prefix("--web-id=")
		if arg.begins_with("--data-dir="): box = arg.trim_prefix("--data-dir=")
		if arg.begins_with("--sandbox="): sandbox = arg.trim_prefix("--sandbox=")
		if arg.begins_with("--url="): url = arg.trim_prefix("--url=")
	DirAccess.make_dir_recursive_absolute(folder)
	# no sandbox, no run: this probe must never be pointed at the truth. The arguments are judged AFTER configure() has
	# normalised them (a blank sandbox, a trailing slash or another spelling of the truth's folder cannot slip past),
	# and the server the game posts to must refuse an unknown sandbox first - a server that ignored ?sandbox= would
	# write the truth.
	var data: Node = StickerData.get_or_create(self)
	data.configure({"data_dir": box, "outbox": box.path_join("outbox.json"), "post": true, "sandbox": sandbox, "url": url})
	data.by = "vr:roundtrip"
	var refusal := await _preflight(url)
	var on_truth: bool = data.data_dir == StickerData.DATA_DIR or StickerData.same_dir(data.data_dir, StickerData.DATA_DIR)
	var no_sandbox: bool = data.sandbox == "" or data.sandbox != sandbox or not data.post_enabled
	if on_truth or no_sandbox or not FileAccess.file_exists(str(data.data_dir).path_join("placements.json")) or refusal != "":
		data.configure({"data_dir": "user://stickers_roundtrip_refused", "post": false})
		_write(folder.path_join("roundtrip_gd.json"), {"error": "refused: a sandbox copy (--data-dir, --sandbox) and a server that honours it are required; the truth is never used", "server": refusal})
		quit(1)
		return
	for i in 30: await process_frame
	var result := {"web_id": web_id, "data_dir": data.data_dir, "posting": data.post_enabled, "sandbox": data.sandbox}
	_write(folder.path_join("ready.json"), {"ready": true})
	# web -> game: wait for the web's sticker to arrive by the file watch
	var t0 := Time.get_ticks_msec()
	var seen := -1
	while Time.get_ticks_msec() - t0 < 20000:
		if not data.sticker(web_id).is_empty():
			seen = Time.get_ticks_msec() - t0
			break
		await process_frame
	result["web_to_game_ms"] = seen
	# game -> web: stick one and let the outbox flush to the route
	var made: Dictionary = data.stick("note_question", {"kind": "board", "id": "visitors"}, [-0.6, -0.35, 0.0], [0, 0, 1], [0, 1, 0], 0.2)
	result["game_id"] = str(made.get("id", ""))
	var replies := []
	data.posted.connect(func(reply: Dictionary) -> void: replies.append(reply))
	data.flush()
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 15000 and replies.is_empty():
		await process_frame
	result["post_reply"] = replies[0] if not replies.is_empty() else {}
	result["game_to_route_ms"] = (Time.get_ticks_msec() - t1) if not replies.is_empty() else -1
	var pending := 0
	if FileAccess.file_exists(box.path_join("outbox.json")):
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(box.path_join("outbox.json")))
		if doc is Dictionary: pending = (doc as Dictionary).get("pending", []).size()
	result["outbox_pending_after"] = pending
	_write(folder.path_join("roundtrip_gd.json"), result)
	print("[stickers_roundtrip] web->game %d ms, game id %s, reply %s" % [seen, result.game_id, str(result.post_reply).left(120)])
	quit()
