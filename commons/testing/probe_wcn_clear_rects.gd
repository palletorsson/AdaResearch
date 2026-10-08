extends SceneTree
## The shared placement key, checked both ways (2026-09-10, after Astra's runtime
## review): does `map_info.museum.sculpture_clear_rects` keep the museum's dealt
## sculpture plinths out of a protected rectangle in a map-authored hall, and does
## a hall WITHOUT the key build exactly as it did — no rects meta, plinths dealt
## wherever the sculptor chose?
##
## Positive: WaveFunctions_Sine_Space declares [[1,1,11,6]] (the antechamber).
## Negative: WaveFunctions_AirMusic declares no such key.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_wcn_clear_rects.gd
## Writes res://ada_run/waves_chance_noise/probe_clear_rects.json. Exit 1 on failure.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const OUT := "res://ada_run/waves_chance_noise/probe_clear_rects.json"

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-rects] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	var positive: Dictionary = await _hall("WaveFunctions_Sine_Space", "wavefunctions")
	var negative: Dictionary = await _hall("WaveFunctions_AirMusic", "wavefunctions")
	measurements["positive"] = positive
	measurements["negative"] = negative
	# the key reached the segment as a Rect2 list; none reached the negative hall
	check(positive.get("rects_meta_count", 0) == 1, "the protected hall carries one clear rect in its segment meta (%d)" % int(positive.get("rects_meta_count", 0)))
	check(negative.get("rects_meta_count", -1) == 0, "the hall without the key carries no clear-rect meta (%d)" % int(negative.get("rects_meta_count", -1)))
	# the protected rectangle: no plinth inside it
	var inside: int = 0
	for p in positive.get("plinths", []):
		var c: Array = p.get("cell", [0, 0])
		if int(c[0]) >= 1 and int(c[0]) <= 11 and int(c[1]) >= 1 and int(c[1]) <= 6: inside += 1
	check(inside == 0, "no dealt plinth stands inside the protected antechamber [[1,1,11,6]] (%d inside, %d plinths in the hall)" % [inside, (positive.get("plinths", []) as Array).size()])
	# the sculptor still deals: the negative hall gets plinths, or says why not
	check(negative.get("sculptures_on", false), "the museum's sculpture dealing is on for the negative hall (otherwise this proves nothing)")
	var neg_n: int = (negative.get("plinths", []) as Array).size()
	check(neg_n >= 1 or negative.get("sculpt_dropped", "") != "", "the hall without the key still receives a plinth, or the museum states why not (%d plinths)" % neg_n)
	_finish()

func _hall(map: String, chapter: String) -> Dictionary:
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")
	em.set("start_chapter", chapter); em.set("start_map", map)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.call("flush_stamps")
	for i in range(30): await process_frame
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == map: seg = rec.node; break
	var out := {"map": map, "built": seg != null}
	if seg == null:
		em.queue_free(); await process_frame; await process_frame
		return out
	var vest: int = int(em.get("VESTIBULE_H"))
	var rects: Variant = seg.get_meta("em_sculpture_clear_rects", [])
	out["rects_meta_count"] = (rects as Array).size() if rects is Array else -1
	var rr: Array = []
	for r in (rects if rects is Array else []):
		if r is Rect2: rr.append([r.position.x, r.position.y - vest, r.size.x, r.size.y])
	out["rects_meta"] = rr
	var plinths: Array = []
	for n in seg.find_children("ArtPlinth*", "", true, false):
		var lp: Vector3 = seg.to_local((n as Node3D).global_position)
		plinths.append({"name": n.name, "cell": [int(floor(lp.x)), int(floor(lp.z - vest))], "local": [snappedf(lp.x, 0.01), snappedf(lp.z - vest, 0.01)]})
	out["plinths"] = plinths
	out["sculptures_on"] = float(em.call("_L", "sculptures", "on", 1.0)) > 0.5 if em.has_method("_L") else true
	# what the sculptor itself recorded for this hall, if anything
	var rows: Array = em.get("_built") if em.get("_built") != null else []
	for r in rows:
		if str((r as Dictionary).get("map", "")) == map:
			out["sculpt_dropped"] = str((r as Dictionary).get("sculpt_dropped", ""))
	em.queue_free()
	await process_frame; await process_frame
	return out

func _finish() -> void:
	var report := {"checks": checks, "failures": failures, "measurements": measurements,
		"engine": Engine.get_version_info().string}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-rects] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
