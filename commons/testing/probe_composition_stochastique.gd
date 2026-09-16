extends SceneTree
## COMPOSITION STOCHASTIQUE: are the counts EXACT, and is the deal deterministic?
##
## Every count below is read back from the stroke MESH: each stroke is six
## vertices, its cell is the centroid, and its diagonal is the sign of the
## vertices' x-y covariance (rising "/" is positive, a turned "\" negative). The
## script's own turned_cells() is only ever compared AGAINST that readback, never
## trusted alone, because a script can report 30 while drawing 31.
##
## WHAT A PASS DOES NOT PROVE. The RESEED press goes through XRToolsPointerEvent ->
## pointer_event -> _on_button_entered, the handler path the desktop pointer takes
## once its ray has landed on the area. No ray is cast, no rig stands in front of
## the board and no VR fingertip pokes, so reach and occlusion remain a live-lane
## check. The press is still more than an emit_signal: it has to pass through the
## real area script and the real connection the artifact made.
##
##   godot --headless --xr-mode off --path . \
##     --script res://commons/testing/probe_composition_stochastique.gd

const SCENE := "res://commons/artifacts/composition_stochastique/composition_stochastique.tscn"
const COUNTS: Array[int] = [1, 5, 30, 50]
const RESEEDS: int = 25
## InteractableAreaButton's layer (21). The desktop pointer's ray masks it.
const BUTTON_LAYER_BIT: int = 1048576

var _checks: int = 0
var _fails: int = 0
var _emits: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _ok(label: String, cond: bool, detail: String = "") -> void:
	_checks += 1
	var tail: String = ("  (" + detail + ")") if detail != "" else ""
	print("%s %s%s" % ["PASS" if cond else "FAIL", label, tail])
	if not cond:
		_fails += 1


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _count_emit(_button) -> void:
	_emits += 1


## before_tree = the museum lane (config lands before _ready);
## otherwise the grid lane (config lands after add_child).
func _spawn(cfg: Dictionary, before_tree: bool, at: Vector3) -> Node3D:
	var packed := load(SCENE) as PackedScene
	if packed == null:
		return null
	var a := packed.instantiate() as Node3D
	if a == null:
		return null
	a.position = at
	if before_tree and not cfg.is_empty():
		a.call("apply_grid_config", cfg)
	get_root().add_child(a)
	if not before_tree and not cfg.is_empty():
		a.call("apply_grid_config", cfg)
	return a


func _count_prefix(a: Node, prefix: String) -> int:
	var n: int = 0
	for c in a.get_children():
		if String(c.name).begins_with(prefix):
			n += 1
	return n


## One grid read back from its mesh. {} when the grid or its mesh is missing.
func _read_grid(a: Node3D, k: int) -> Dictionary:
	var g := a.get_node_or_null("Grid_%d" % k) as Node3D
	if g == null:
		return {}
	var mi := g.get_node_or_null("Strokes") as MeshInstance3D
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() < 1:
		return {}
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cell: float = float(a.get("cell_m"))
	var half: float = cell * 5.0
	var strokes: int = int(v.size() / 6.0)
	var seen: Dictionary = {}
	var turned: Array = []
	var dup: bool = false
	var outside: bool = false
	for s in range(strokes):
		var cx: float = 0.0
		var cy: float = 0.0
		for j in range(6):
			cx += v[s * 6 + j].x
			cy += v[s * 6 + j].y
		cx /= 6.0
		cy /= 6.0
		var cov: float = 0.0
		for j in range(6):
			cov += (v[s * 6 + j].x - cx) * (v[s * 6 + j].y - cy)
		var col: int = floori((cx + half) / cell)
		var row: int = floori((half - cy) / cell)
		if col < 0 or col > 9 or row < 0 or row > 9:
			outside = true
			continue
		var idx: int = row * 10 + col
		if seen.has(idx):
			dup = true
		seen[idx] = true
		if cov < 0.0:
			turned.append(idx)
	turned.sort()
	return {"strokes": strokes, "cells": seen.size(), "dup": dup, "outside": outside, "turned": turned}


## "" when grid k is exactly right, otherwise what is wrong with it.
func _grid_fault(a: Node3D, k: int) -> String:
	var rb: Dictionary = _read_grid(a, k)
	if rb.is_empty():
		return "Grid_%d or its Strokes mesh is missing" % k
	var t: Array = rb["turned"]
	if int(rb["strokes"]) != 100:
		return "Grid_%d has %d strokes, not 100" % [k, int(rb["strokes"])]
	if int(rb["cells"]) != 100 or bool(rb["dup"]) or bool(rb["outside"]):
		return "Grid_%d covers %d distinct cells (dup=%s outside=%s)" % [k, int(rb["cells"]), str(rb["dup"]), str(rb["outside"])]
	if t.size() != k:
		return "Grid_%d draws %d turned cells, not %d" % [k, t.size(), k]
	var raw: PackedInt32Array = a.call("turned_cells", k)
	var book: Array = Array(raw)
	if book != t:
		return "Grid_%d mesh %s disagrees with the script's record %s" % [k, str(t), str(book)]
	return ""


func _layout(a: Node3D, k: int) -> String:
	var rb: Dictionary = _read_grid(a, k)
	if rb.is_empty():
		return "<missing>"
	return str(rb["turned"])


## The button_pressed connections held by anything OTHER than the PushButton that owns
## the area, as "Class.method" strings. push_button.gd's _ready always connects its own
## _on_button_pressed to this signal, so a bare size() >= 1 passes even when the
## artifact wired nothing.
func _foreign_presses(area: Area3D, owner_btn: Node) -> Array:
	var out: Array = []
	for conn in area.get_signal_connection_list("button_pressed"):
		var cb: Callable = conn["callable"]
		var holder: Object = cb.get_object()
		if holder != owner_btn:
			var who: String = holder.get_class() if holder != null else "<null>"
			out.append("%s.%s" % [who, str(cb.get_method())])
	return out


func _subset(small: Array, big: Array) -> bool:
	for x in small:
		if not big.has(x):
			return false
	return true


func _run() -> void:
	print("COMPOSITION STOCHASTIQUE: exact counts, deterministic deals")
	print("")

	# ── 1. the scene a map places, at defaults ──────────────────────────────
	print("1  default build (series)")
	var a := _spawn({}, false, Vector3.ZERO)
	if a == null:
		print("FAIL the scene did not load")
		quit(1)
		return
	await _frames(4)
	_ok("the .tscn root carries the script", a.get_script() != null and a.has_method("apply_grid_config"))
	_ok("defaults: seed 1959, turned series", int(a.get("seed")) == 1959 and str(a.get("turned")) == "series",
		"seed=%s turned=%s" % [str(a.get("seed")), str(a.get("turned"))])
	_ok("shows the counts 1, 5, 30, 50", str(a.call("shown_counts")) == str([1, 5, 30, 50]), str(a.call("shown_counts")))
	_ok("four grids built, once", _count_prefix(a, "Grid_") == 4, "%d" % _count_prefix(a, "Grid_"))
	_ok("four captions and one plate", _count_prefix(a, "Caption_") == 4 and _count_prefix(a, "Plate") == 1)
	var draw0: Dictionary = {}
	for k in COUNTS:
		var fault: String = _grid_fault(a, k)
		_ok("grid %d reads back from the mesh as exactly %d of 100" % [k, k], fault == "", fault)
		var rb: Dictionary = _read_grid(a, k)
		draw0[k] = rb.get("turned", [])
	_ok("the series is one deal read at four depths (1 in 5 in 30 in 50)",
		_subset(draw0[1], draw0[5]) and _subset(draw0[5], draw0[30]) and _subset(draw0[30], draw0[50]))

	var min_y: float = INF
	var label_text: int = 0
	var stack: Array = [a]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			if mi.mesh != null:
				var box: AABB = mi.global_transform * mi.get_aabb()
				min_y = minf(min_y, box.position.y)
		if n is Label3D and str((n as Label3D).text).strip_edges() != "":
			label_text += 1
		for child in n.get_children():
			stack.append(child)
	_ok("origin is the base: nothing below the floor, and it stands on it", min_y >= -0.001 and min_y <= 0.005, "min y %.4f" % min_y)
	_ok("no Label3D carries text (every word is a text_screen)", label_text == 0, "%d" % label_text)
	var plate := a.get_node_or_null("Plate") as Node3D
	var faces_front: bool = plate != null and plate.global_transform.basis.z.dot(Vector3.BACK) > 0.999
	for k in COUNTS:
		var cap := a.get_node_or_null("Caption_%d" % k) as Node3D
		faces_front = faces_front and cap != null and cap.global_transform.basis.z.dot(Vector3.BACK) > 0.999
	_ok("plate and captions face +Z, unrotated", faces_front)
	_ok("solid by default: a body stands in the board", a.get_node_or_null("Body") is StaticBody3D)
	# The board must rest ON its legs: each leg's front face flush with the reveal's back.
	var edge_mi := a.get_node_or_null("BoardEdge") as MeshInstance3D
	var leg_gaps: PackedStringArray = PackedStringArray()
	var legs_flush: bool = edge_mi != null
	if edge_mi != null:
		var edge_box: AABB = edge_mi.global_transform * edge_mi.get_aabb()
		for leg_name in ["Leg_L", "Leg_R"]:
			var leg_mi := a.get_node_or_null(leg_name) as MeshInstance3D
			if leg_mi == null:
				legs_flush = false
				leg_gaps.append("%s missing" % leg_name)
				continue
			var leg_box: AABB = leg_mi.global_transform * leg_mi.get_aabb()
			var gap: float = edge_box.position.z - leg_box.end.z
			leg_gaps.append("%s gap %.4f m" % [leg_name, gap])
			if absf(gap) > 0.0005:
				legs_flush = false
	_ok("the legs touch the board (front face flush with the reveal's back)", legs_flush, ", ".join(leg_gaps))

	# ── 2. twenty-five reseeds ──────────────────────────────────────────────
	print("2  %d reseeds" % RESEEDS)
	var seen_layouts: Dictionary = {}
	for k in COUNTS:
		seen_layouts[k] = {str(draw0[k]): true}
	var faults: Array = []
	var first_changed: bool = false
	for r in range(RESEEDS):
		a.call("reseed")
		var layouts: Dictionary = {}
		for k in COUNTS:
			var fault2: String = _grid_fault(a, k)
			if fault2 != "":
				faults.append("reseed %d: %s" % [r + 1, fault2])
			var rb: Dictionary = _read_grid(a, k)
			layouts[k] = rb.get("turned", [])
			seen_layouts[k][str(layouts[k])] = true
		if not (_subset(layouts[1], layouts[5]) and _subset(layouts[5], layouts[30]) and _subset(layouts[30], layouts[50])):
			faults.append("reseed %d: the four grids no longer nest" % (r + 1))
		if r == 0:
			first_changed = str(layouts[30]) != str(draw0[30]) and str(layouts[50]) != str(draw0[50])
	_ok("every count stays exactly 1, 5, 30, 50 through %d reseeds" % RESEEDS, faults.is_empty(),
		"; ".join(PackedStringArray(faults.slice(0, 3))))
	_ok("the draw counter advanced once per reseed", int(a.call("draw_index")) == RESEEDS, "%d" % int(a.call("draw_index")))
	_ok("the first reseed moved the turned cells of 30 and 50", first_changed)
	_ok("positions change: thirty took %d distinct layouts in %d draws" % [seen_layouts[30].size(), RESEEDS + 1],
		seen_layouts[30].size() == RESEEDS + 1 and seen_layouts[50].size() == RESEEDS + 1)
	_ok("even the single turned cell moved", seen_layouts[1].size() > 1, "%d positions" % seen_layouts[1].size())
	_ok("grids were reseeded in place, not rebuilt", _count_prefix(a, "Grid_") == 4)

	# ── 3. determinism ──────────────────────────────────────────────────────
	print("3  the same seed gives the same layouts")
	var b := _spawn({}, false, Vector3(6, 0, 0))
	await _frames(4)
	var same0: bool = true
	for k in COUNTS:
		same0 = same0 and _layout(b, k) == str(draw0[k])
	_ok("a second instance at seed 1959 deals the same four grids", same0)
	for r in range(RESEEDS):
		b.call("reseed")
	var same25: bool = true
	for k in COUNTS:
		same25 = same25 and _layout(b, k) == _layout(a, k)
	_ok("and after %d reseeds both still agree cell for cell" % RESEEDS, same25)

	var inst_c := _spawn({"seed": "1959.0"}, true, Vector3(12, 0, 0))
	await _frames(4)
	_ok("seed '1959.0' as text is 1959, not 19590", int(inst_c.get("seed")) == 1959 and _layout(inst_c, 30) == str(draw0[30]),
		"seed=%s" % str(inst_c.get("seed")))
	var d := _spawn({}, false, Vector3(18, 0, 0))
	await _frames(4)
	d.call("apply_grid_config", {"seed": 7})
	await _frames(2)
	var d_fault: String = ""
	for k in COUNTS:
		var f2: String = _grid_fault(d, k)
		if f2 != "":
			d_fault = f2
	_ok("#seed:7 rebuilds with exact counts", d_fault == "" and _count_prefix(d, "Grid_") == 4, d_fault)
	_ok("and a different seed deals different positions", _layout(d, 30) != str(draw0[30]) and _layout(d, 50) != str(draw0[50]))
	d.call("reseed")
	d.call("reseed")
	d.call("apply_grid_config", {"seed": 7.0, "emissive": false})
	_ok("a config that changes nothing touches nothing (draw stays 2)", int(d.call("draw_index")) == 2, "%d" % int(d.call("draw_index")))

	# ── 4. a single grid, for collations ────────────────────────────────────
	print("4  turned: a single grid")
	var e := _spawn({"turned": "five"}, true, Vector3(24, 0, 0))
	await _frames(4)
	_ok("#turned:five (museum lane) builds ONE grid, once", _count_prefix(e, "Grid_") == 1 and e.get_node_or_null("Grid_5") != null,
		"%d grids" % _count_prefix(e, "Grid_"))
	_ok("with one caption and one plate", _count_prefix(e, "Caption_") == 1 and _count_prefix(e, "Plate") == 1)
	var e_fault: String = _grid_fault(e, 5)
	_ok("and that grid reads back as exactly 5 of 100", e_fault == "", e_fault)
	_ok("five alone is the series' five, cell for cell", _layout(e, 5) == str(draw0[5]))

	var inst_f := _spawn({}, false, Vector3(30, 0, 0))
	await _frames(4)
	inst_f.call("apply_grid_config", {"turned": "five"})
	await _frames(2)
	_ok("#turned:five (grid lane, after _ready) leaves one grid and one caption",
		_count_prefix(inst_f, "Grid_") == 1 and _count_prefix(inst_f, "Caption_") == 1 and _grid_fault(inst_f, 5) == "")
	var words: Dictionary = {"one": 1, "thirty": 30, "fifty": 50}
	for w in words.keys():
		var kk: int = int(words[w])
		var g := _spawn({"turned": w}, true, Vector3(36 + 6 * kk, 0, 0))
		await _frames(3)
		var gf: String = _grid_fault(g, kk)
		_ok("#turned:%s builds one grid of exactly %d" % [w, kk], _count_prefix(g, "Grid_") == 1 and gf == "", gf)
		g.queue_free()
	var h := _spawn({"turned": "seven"}, true, Vector3(400, 0, 0))
	await _frames(3)
	_ok("an unknown word keeps the series", str(h.get("turned")) == "series" and _count_prefix(h, "Grid_") == 4)
	h.call("apply_grid_config", {"turned": true})
	_ok("the shorthand trap's boolean true keeps the series", str(h.get("turned")) == "series")
	h.call("apply_grid_config", {"solid": "off"})
	await _frames(2)
	_ok("#solid:off removes the body", h.get_node_or_null("Body") == null)

	# ── 5. RESEED through the button's own input path ───────────────────────
	print("5  RESEED pressed through the pointer-event path")
	var btn: Node = a.find_child("Btn_0", true, false)
	var area: Area3D = null
	if btn != null:
		area = btn.get_node_or_null("InteractableAreaButton") as Area3D
	_ok("RESEED has an InteractableAreaButton", area != null)
	if area != null:
		_ok("on the layer the desktop pointer masks", (area.collision_layer & BUTTON_LAYER_BIT) != 0, "layer %d" % area.collision_layer)
		# Read BEFORE the probe adds _count_emit, which would itself be a foreign connection.
		var foreign: Array = _foreign_presses(area, btn)
		_ok("the artifact connected button_pressed (beyond the PushButton's own)", foreign.size() >= 1,
			"total %d, foreign %s" % [area.get_signal_connection_list("button_pressed").size(), str(foreign)])
		# CONTROL: the same RackTemplates button with nobody wiring it must read as NO
		# foreign connection, or the check above could never have failed.
		var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
		var bare: Node3D = null
		if rack != null:
			bare = rack.create_panel("", [[{"type": "button", "label": "X"}]])
		if bare != null:
			bare.position = Vector3(0, 0, 40)
			get_root().add_child(bare)
			var bare_btn: Node = bare.find_child("Btn_0", true, false)
			var bare_area: Area3D = null
			if bare_btn != null:
				bare_area = bare_btn.get_node_or_null("InteractableAreaButton") as Area3D
			var bare_total: int = -1
			var bare_foreign: Array = ["<no area>"]
			if bare_area != null:
				bare_total = bare_area.get_signal_connection_list("button_pressed").size()
				bare_foreign = _foreign_presses(bare_area, bare_btn)
			_ok("control: an unwired RackTemplates button holds its PushButton's connection and no other",
				bare_total >= 1 and bare_foreign.is_empty(), "total %d, foreign %s" % [bare_total, str(bare_foreign)])
			bare.queue_free()
		else:
			_ok("control: RackTemplates builds an unwired panel", false)
		area.connect("button_pressed", _count_emit)
		var pointer := Node3D.new()
		get_root().add_child(pointer)
		var before_draw: int = int(a.call("draw_index"))
		var before30: String = _layout(a, 30)
		XRToolsPointerEvent.pressed(pointer, area, area.global_position)
		XRToolsPointerEvent.released(pointer, area, area.global_position)
		await _frames(3)
		_ok("one press emitted button_pressed once", _emits == 1, "%d" % _emits)
		_ok("one press advanced the draw by one", int(a.call("draw_index")) == before_draw + 1,
			"%d -> %d" % [before_draw, int(a.call("draw_index"))])
		_ok("and moved the turned cells", _layout(a, 30) != before30)
		XRToolsPointerEvent.pressed(pointer, area, area.global_position)
		XRToolsPointerEvent.released(pointer, area, area.global_position)
		await _frames(3)
		var press_fault: String = ""
		for k in COUNTS:
			var pf: String = _grid_fault(a, k)
			if pf != "":
				press_fault = pf
		_ok("a second press: draw +2, counts still exact", _emits == 2 and int(a.call("draw_index")) == before_draw + 2 and press_fault == "",
			press_fault)

	print("")
	print("COMPOSITION_STOCHASTIQUE_RESULT %d checks, %d failed" % [_checks, _fails])
	print("PROBE %s" % ("PASSED" if _fails == 0 else "FAILED"))
	quit(0 if _fails == 0 else 1)
