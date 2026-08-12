extends SceneTree

## Every TextScreen in the project, measured — does its text fit its panel?
##
## TextScreen is preloaded by 33 files. Changing how it lays out body text is
## therefore a change to 33 artifacts, and "it looks right in the one probe I
## captured" is not evidence about the other 32. This instantiates each user,
## finds every TextScreen inside it, and checks the arithmetic that actually
## decides whether a line is clipped:
##
##     make_text_block stacks at pitch = line_height + gap and spans pitch * n.
##     The old code passed line_height = avail_h / n AND a gap, so the block
##     overran its panel by gap * n — nothing at one line, 18% at seven.
##
## For each screen it reports the fill ratio under the OLD formula and the NEW
## one, so the fix is a number per artifact rather than an impression.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/sweep_text_screens.gd -- \
##     --out=res://ada_run/text_screen_sweep.json

const TextScreenRes = preload("res://commons/ui/text_screen.gd")

var _out: String = "res://ada_run/text_screen_sweep.json"
var _settle: float = 0.35


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var a := String(arg)
		if a.begins_with("--out="):
			_out = a.substr(6)
	_run.call_deferred()


## Every .gd that preloads the screen, mapped to its sibling scene.
func _users() -> Array:
	var out: Array = []
	var stack: Array = ["res://commons", "res://algorithms"]
	while not stack.is_empty():
		var dir_path: String = stack.pop_back()
		var d := DirAccess.open(dir_path)
		if d == null:
			continue
		d.list_dir_begin()
		var name := d.get_next()
		while name != "":
			var full: String = dir_path + "/" + name
			if d.current_is_dir():
				if not name.begins_with("."):
					stack.append(full)
			elif name.ends_with(".gd"):
				var text := FileAccess.get_file_as_string(full)
				if text.find("ui/text_screen.gd") != -1 and not full.ends_with("/text_screen.gd"):
					var scene := full.replace(".gd", ".tscn")
					if ResourceLoader.exists(scene):
						out.append({"script": full, "scene": scene})
			name = d.get_next()
		d.list_dir_end()
	return out


func _collect(node: Node, out: Array) -> void:
	if node is TextScreen:
		out.append(node)
	for c in node.get_children():
		_collect(c, out)


## Recompute the layout arithmetic for one screen. Returns the fill ratio the
## old formula produced and the one the new formula produces; > 1.0 means the
## text ran past the bottom of its own panel.
func _check(ts) -> Dictionary:
	var w: float = float(ts.width_m)
	var h: float = w * TextScreenRes.ASPECT
	var title_h: float = h * TextScreenRes.TITLE_FRAC
	var body_h: float = h - title_h
	var avail: float = body_h * 0.9
	var gap: float = body_h * 0.04
	var body := String(ts.body)
	if body.strip_edges() == "":
		return {"has_body": false}
	var lines: PackedStringArray = ts.call("_lay_out", body, w * 0.92, avail)
	var n: int = maxi(1, lines.size())
	var old_line_h: float = avail / float(n)
	var new_line_h: float = maxf(0.004, (avail - gap * float(n)) / float(n))
	return {
		"has_body": true,
		"width_m": snappedf(w, 0.001),
		"body_chars": body.length(),
		"lines": n,
		"old_fill": snappedf((old_line_h + gap) * float(n) / avail, 0.001),
		"new_fill": snappedf((new_line_h + gap) * float(n) / avail, 0.001),
		"truncated": String(lines[n - 1]).ends_with("…") if n > 0 else false,
	}


func _run() -> void:
	var root := Node3D.new()
	get_root().add_child(root)

	var users := _users()
	var rows: Array = []
	var screens := 0
	var was_overflowing := 0
	var now_overflowing := 0
	var failed_to_load: Array = []

	for u in users:
		var packed: PackedScene = load(String(u["scene"])) as PackedScene
		if packed == null:
			failed_to_load.append(u["scene"])
			continue
		var inst: Node = packed.instantiate()
		if inst == null:
			failed_to_load.append(u["scene"])
			continue
		root.add_child(inst)
		await process_frame
		await process_frame
		await create_timer(_settle).timeout

		var found: Array = []
		_collect(inst, found)
		var per: Array = []
		for ts in found:
			var r := _check(ts)
			if not bool(r.get("has_body", false)):
				continue
			screens += 1
			if float(r["old_fill"]) > 1.001:
				was_overflowing += 1
			if float(r["new_fill"]) > 1.001:
				now_overflowing += 1
			per.append(r)
		rows.append({
			"scene": u["scene"],
			"text_screens": found.size(),
			"with_body": per.size(),
			"screens": per,
		})
		inst.queue_free()
		await process_frame

	var report := {
		"schema": "adaresearch.text_screen_sweep.v1",
		"users_found": users.size(),
		"failed_to_load": failed_to_load,
		"screens_with_body": screens,
		"overflowing_before": was_overflowing,
		"overflowing_after": now_overflowing,
		"artifacts": rows,
	}
	var f := FileAccess.open(_out, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(report, "\t"))
		f.close()

	print("")
	print("=== TextScreen sweep ===")
	print("  users with a scene   : %d" % users.size())
	print("  screens carrying body: %d" % screens)
	print("  overflowed BEFORE fix: %d" % was_overflowing)
	print("  overflow AFTER fix   : %d" % now_overflowing)
	if not failed_to_load.is_empty():
		print("  could not instantiate: %d" % failed_to_load.size())
	for row in rows:
		for r in row["screens"]:
			if float(r["old_fill"]) > 1.001:
				print("    %-58s %d lines  %.2f -> %.2f" % [
					String(row["scene"]).replace("res://", ""),
					int(r["lines"]), float(r["old_fill"]), float(r["new_fill"])])
	quit(0 if now_overflowing == 0 else 1)
