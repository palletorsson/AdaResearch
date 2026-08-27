extends SceneTree
## probe_necklace_tiles.gd — (a) do the ten beads actually carry pictures, and
## (b) where did 3.8 GB go during a full traverse?  Attribution, not a guess.

const SCENE := "res://commons/scenes/desktop_necklace.tscn"
const EFFECTIVE := "res://commons/data/spine_order_effective.json"
const TRIAL_OPS := "user://_tiles_necklace_ops.json"

var R: Dictionary = {"checks": [], "data": {}}
var report: String = ""


func _ck(n: String, ok: bool, d: String = "") -> void:
	R["checks"].append({"name": n, "ok": ok, "detail": d})


func _write() -> void:
	var bad: int = 0
	for c in R["checks"]:
		if not bool((c as Dictionary)["ok"]):
			bad += 1
	R["failed"] = bad
	R["total"] = (R["checks"] as Array).size()
	R["pass"] = bad == 0
	var f := FileAccess.open(report, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(R, "  ", false))
		f.close()


func _initialize() -> void:
	_run()


func _mem() -> float:
	return float(OS.get_static_memory_usage()) / 1048576.0


func _cap_path(token: String) -> String:
	var gh := ProjectSettings.globalize_path("res://").rstrip("/").get_base_dir()
	var cands: Array = [
		gh + "/ada_encyclopedia/public/artifact-gallery/captures/%s/front.png" % token,
		gh + "/ada_encyclopedia/public/scene-catalog/%s.png" % token,
		ProjectSettings.globalize_path("user://multi_shots/%s/front.png" % token),
		ProjectSettings.globalize_path("user://multi_shots/%s/angle_0.png" % token),
	]
	for c in cands:
		if FileAccess.file_exists(str(c)):
			return str(c)
	return ""


func _run() -> void:
	report = ProjectSettings.globalize_path("user://probe_necklace_tiles.json")
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--report="):
			report = str(a).split("=", true, 1)[1]

	# ── coverage of the capture chain over the whole order ─────────────────
	var eff: Dictionary = {}
	var pe: Variant = JSON.parse_string(FileAccess.get_file_as_string(EFFECTIVE))
	if pe is Dictionary:
		eff = pe
	var rows: Array = eff.get("order", []) if eff.get("order") is Array else []
	var toks: PackedStringArray = PackedStringArray()
	var have: int = 0
	var gaps: Array = []
	for r in rows:
		var t := str((r as Dictionary).get("lookup", ""))
		toks.append(t)
		if _cap_path(t) != "":
			have += 1
		else:
			gaps.append(t)
	R["data"]["order_n"] = toks.size()
	R["data"]["with_capture"] = have
	R["data"]["without_capture"] = gaps
	_ck("the report's 798-of-810 capture coverage", have == 798,
		"%d of %d have a capture; %d without" % [have, toks.size(), gaps.size()])

	# ── the ten beads at the head: pictures, or blanks? ────────────────────
	var ps := load(SCENE) as PackedScene
	var inst: Node = ps.instantiate()
	inst.set("ops_path", TRIAL_OPS)
	root.add_child(inst)
	await process_frame
	await process_frame
	inst.call("settle_scroll")
	await process_frame
	var tiles: Array = []
	var pictured: int = 0
	for ch in inst.get_children():
		if not str(ch.name).begins_with("bead_"):
			continue
		if not (ch as Node3D).visible:
			continue
		var sp: Sprite3D = ch.get_node_or_null("Tile") as Sprite3D
		var w: int = 0
		var h: int = 0
		if sp != null and sp.texture != null:
			w = sp.texture.get_width()
			h = sp.texture.get_height()
		var vis: bool = sp != null and sp.visible and w > 0
		if vis:
			pictured += 1
		tiles.append({"bead": str(ch.name), "tex": "%dx%d" % [w, h], "visible": vis,
			"world_w_m": snappedf(float(w) * (sp.pixel_size if sp != null else 0.0), 0.01)})
	R["data"]["head_tiles"] = tiles
	_ck("at least 9 of the 10 head beads carry a real picture", pictured >= 9,
		"%d of 10 pictured" % pictured)
	var widths: Array = []
	for t in tiles:
		widths.append(float((t as Dictionary)["world_w_m"]))
	var wmin: float = 99.0
	var wmax: float = 0.0
	for w2 in widths:
		if float(w2) > 0.0:
			wmin = minf(wmin, float(w2))
			wmax = maxf(wmax, float(w2))
	R["data"]["tile_world_width_m"] = [snappedf(wmin, 0.01), snappedf(wmax, 0.01)]
	_ck("every tile is normalised to the same world width", absf(wmax - wmin) < 0.02,
		"%.2f .. %.2f m" % [wmin, wmax])
	inst.queue_free()
	await process_frame
	_write()

	# ── attribution: what does ONE texture through that chain cost? ────────
	var m0: float = _mem()
	var keep: Array = []
	var bytes_est: int = 0
	var loaded: int = 0
	for i in mini(300, toks.size()):
		var p := _cap_path(toks[i])
		if p == "":
			continue
		var img: Image = Image.load_from_file(p)
		if img == null or img.is_empty():
			continue
		var tex := ImageTexture.create_from_image(img)
		keep.append(tex)
		bytes_est += img.get_width() * img.get_height() * 4
		loaded += 1
	var m1: float = _mem()
	R["data"]["textures_loaded"] = loaded
	R["data"]["mem_mb_before"] = snappedf(m0, 0.1)
	R["data"]["mem_mb_after"] = snappedf(m1, 0.1)
	R["data"]["mem_mb_growth"] = snappedf(m1 - m0, 0.1)
	R["data"]["mb_per_texture"] = snappedf((m1 - m0) / maxf(1.0, float(loaded)), 0.01)
	R["data"]["rgba8_bytes_est_mb"] = snappedf(float(bytes_est) / 1048576.0, 0.1)
	R["data"]["projected_all_810_mb"] = snappedf((m1 - m0) / maxf(1.0, float(loaded)) * 810.0, 0.1)
	_ck("the traverse's memory growth is the capture cache, not leaked nodes",
		(m1 - m0) > 500.0,
		"%d textures cost %.1f MB (%.2f MB each) -> %.0f MB for all 810" % [
			loaded, m1 - m0, (m1 - m0) / maxf(1.0, float(loaded)),
			(m1 - m0) / maxf(1.0, float(loaded)) * 810.0])
	keep.clear()
	_write()
	quit(0)
