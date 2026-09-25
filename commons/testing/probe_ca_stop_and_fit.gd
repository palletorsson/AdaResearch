extends SceneTree
## Gate for two CA works that kept computing after nothing could change
## (2026-09-24, CA_Introduction and CA_EdgeOfChaos), and for the line network's #size.
## Every stop is checked against the SHIPPED script run from the same seed: the stop
## must lose nothing the shipped script would still have drawn.
##
##   L1 default unchanged  -> with no config the line network draws the same lines as
##                            the shipped script from the same seed, untransformed
##   L2 stops after growth -> is_running false once growth has ended; shipped keeps
##                            scanning 64^3 cells a frame
##   L3 nothing lost       -> the shipped script, run 60 frames longer, draws no more
##   L4 #size bites        -> (#size:2.0, the shipped token) every line end sits inside a box resting
##                            FIT_FLOOR above the origin, largest side == size, and the
##                            scale is uniform (the shape is kept); shipped: about half
##                            of the line ends lie below the origin (5 seeds vary widely)
##   L4b grid-lane order   -> the same box when size arrives AFTER growth (the grid lane
##                            defers apply_grid_config); a config without size puts the
##                            drawing back; the grid tokenizer reads #size:2.4 as a value
##   L5 subclass untouched -> dendrite_growth_ca (own growth rule) keeps growing
##   C1 crack stops        -> set_process(false) once the interior has settled;
##                            shipped keeps stepping
##   C2 nothing lost       -> the shipped script, run 120 frames longer, holds the
##                            same cracked set and the same stress on every cracked
##                            cell (the only inputs of the crack mesh), and draws the
##                            same mesh vertices; negative control: 20 frames before
##                            the stop the shipped mesh is different
##   C3 resumes            -> add_stress_point turns processing back on
##   COST                  -> one frame's script work, after settling, new vs shipped
##
## usage: godot --headless --path . --xr-mode off --script res://commons/testing/probe_ca_stop_and_fit.gd

const LINE_SCENE := "res://algorithms/cellularautomata/ca_showcase/LineNetworkCA.tscn"
const LINE_BEFORE := "res://doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_Introduction/LineNetworkCA.gd.before.txt"
const DENDRITE_SCENE := "res://algorithms/cellularautomata/ca_showcase/dendrite_growth_ca.tscn"
const CRACK_SCENE := "res://algorithms/proceduralgeneration/growth_systems/crackpropagation_ca/crackpropagation_ca.tscn"
const CRACK_BEFORE := "res://doc/book/iterations/2026-09-24-claude-randomness-onwards/CA_EdgeOfChaos/crackpropagation_ca.gd.before.txt"

var _fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(label: String, ok: bool, detail: String) -> void:
	if not ok:
		_fails += 1
	print("%s %s — %s" % ["PASS" if ok else "FAIL", label, detail])

func _old(path: String) -> GDScript:
	var src := FileAccess.get_file_as_string(path).replace(char(0xFEFF), "")
	var lines := src.split("\n")
	var kept: PackedStringArray = []
	for l in lines:
		if not l.strip_edges().begins_with("class_name"):
			kept.append(l)
	var s := GDScript.new()
	s.source_code = "\n".join(kept)
	var err := s.reload()
	assert(err == OK)
	return s

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _line(script: GDScript, rng_seed: int, config: Dictionary, frames: int) -> Node3D:
	seed(rng_seed)
	var n: Node3D = load(LINE_SCENE).instantiate()
	if script != null:
		n.set_script(script)
	if not config.is_empty():
		n.call("apply_grid_config", config)
	root.add_child(n)
	await _frames(frames)
	return n

## Same as a placed network, but its frames are driven here, synchronously, exactly as
## BaseCA._process runs them: across real frames the autoloads draw from the same
## global RNG, and two runs from one seed then diverge for reasons outside this work.
func _line_sync(script: GDScript, rng_seed: int, steps: int) -> Node3D:
	seed(rng_seed)
	var n: Node3D = load(LINE_SCENE).instantiate()
	if script != null:
		n.set_script(script)
	root.add_child(n)
	n.set_process(false)
	for i in steps:
		if bool(n.get("is_running")):
			n.call("update_simulation", 1.0 / 60.0)
			n.call("update_visualization")
			n.set("iteration_count", int(n.get("iteration_count")) + 1)
	return n

func _ends(n: Node3D) -> Array:
	var lines: MeshInstance3D = n.get("mesh_instance_lines")
	var xf: Transform3D = lines.transform
	var out: Array = []
	for c in n.get("connections"):
		out.append(xf * (c[0] as Vector3))
		out.append(xf * (c[1] as Vector3))
	return out

## The crack mesh as drawn: its vertex array, or empty if there is no mesh yet.
func _crack_vertices(n: Node) -> PackedVector3Array:
	var mi: MeshInstance3D = n.get("crack_mesh")
	if mi == null or mi.mesh == null or mi.mesh.get_surface_count() == 0:
		return PackedVector3Array()
	return (mi.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func _cost(n: Node) -> int:
	var t0 := Time.get_ticks_usec()
	if n.has_method("_process") and n.is_processing():
		n.call("_process", 1.0 / 60.0)
	return Time.get_ticks_usec() - t0

func _run() -> void:
	var old_line := _old(LINE_BEFORE)
	var old_crack := _old(CRACK_BEFORE)

	# --- L1, L2, L3: default line network against the shipped script, three seeds
	var same := 0
	var stopped := 0
	var nothing_lost := 0
	var old_running := 0
	var cost_new := 0
	var cost_old := 0
	for s in [11, 22, 33]:
		var a: Node3D = _line_sync(null, s, 40)
		var ca: Array = (a.get("connections") as Array).duplicate(true)
		var xf_id: bool = (a.get("mesh_instance_lines") as MeshInstance3D).transform == Transform3D.IDENTITY
		if not bool(a.get("is_running")):
			stopped += 1
		a.set_process(true)
		cost_new += _cost(a)
		a.queue_free()
		await _frames(1)
		var b: Node3D = _line_sync(old_line, s, 40)
		var cb: Array = (b.get("connections") as Array).duplicate(true)
		if xf_id and str(ca) == str(cb):
			same += 1
		if bool(b.get("is_running")):
			old_running += 1
		b.set_process(true)
		cost_old += _cost(b)
		await _frames(60)
		if (b.get("connections") as Array).size() == ca.size():
			nothing_lost += 1
		b.queue_free()
		await _frames(1)
	_check("L1 default draws the shipped lines", same == 3, "%d of 3 seeds identical, lines untransformed" % same)
	var n1: Node3D = _line_sync(null, 11, 40)
	var n2: Node3D = _line_sync(old_line, 11, 19)
	var differs := str(n1.get("connections")) != str(n2.get("connections"))
	_check("L1 negative control: the comparison sees a network one generation short", differs,
		"seed 11: new after growth vs shipped after 19 steps differ=%s" % str(differs))
	n1.queue_free()
	n2.queue_free()
	await _frames(1)
	_check("L2 stops after growth", stopped == 3 and old_running == 3,
		"%d of 3 stopped; shipped still running in %d of 3" % [stopped, old_running])
	_check("L3 the shipped script draws nothing more", nothing_lost == 3,
		"%d of 3 seeds: shipped, 60 frames later, has the same number of lines" % nothing_lost)
	print("COST line_network_ca per frame after growth: new %d us, shipped %d us (mean of 3)" % [cost_new / 3, cost_old / 3])

	# --- L4: #size
	var inside := 0
	var largest_ok := 0
	var uniform := 0
	var below_old := 0
	var ends_old := 0
	for s in [11, 22, 33, 44, 55]:
		var f: Node3D = await _line(null, s, {"size": "2.0"}, 40)
		var e := _ends(f)
		var lo := Vector3(INF, INF, INF)
		var hi := Vector3(-INF, -INF, -INF)
		for p: Vector3 in e:
			lo = lo.min(p)
			hi = hi.max(p)
		var span := hi - lo
		if lo.y >= 0.3 - 0.001 and absf(lo.x + hi.x) < 0.001 and absf(lo.z + hi.z) < 0.001:
			inside += 1
		if absf(maxf(span.x, maxf(span.y, span.z)) - 2.0) < 0.001:
			largest_ok += 1
		var sc: Vector3 = (f.get("mesh_instance_lines") as MeshInstance3D).scale
		if is_equal_approx(sc.x, sc.y) and is_equal_approx(sc.y, sc.z):
			uniform += 1
		f.queue_free()
		await _frames(1)
		var g: Node3D = await _line(old_line, s, {}, 40)
		for p: Vector3 in _ends(g):
			ends_old += 1
			if p.y < 0.0:
				below_old += 1
		g.queue_free()
		await _frames(1)
	_check("L4 #size:2.0 (the shipped token) puts every line end in a 2.0 m box above the floor", inside == 5 and largest_ok == 5 and uniform == 5,
		"%d of 5 above 0.30 m and centred, %d of 5 with largest side 2.00 m, %d of 5 uniform scale; shipped: %.0f%% of line ends below the origin" % [inside, largest_ok, uniform, 100.0 * below_old / maxf(1, ends_old)])

	# --- L4b: the grid lane configures after _ready (deferred), here after growth
	var late_ok := 0
	var reset_ok := 0
	for s in [11, 22, 33]:
		var h: Node3D = _line_sync(null, s, 40)
		h.call("apply_grid_config", {"size": "2.4"})
		var lo2 := Vector3(INF, INF, INF)
		var hi2 := Vector3(-INF, -INF, -INF)
		for p: Vector3 in _ends(h):
			lo2 = lo2.min(p)
			hi2 = hi2.max(p)
		var sp2 := hi2 - lo2
		if lo2.y >= 0.3 - 0.001 and absf(maxf(sp2.x, maxf(sp2.y, sp2.z)) - 2.4) < 0.001:
			late_ok += 1
		h.call("apply_grid_config", {"emissive": false})
		if (h.get("mesh_instance_lines") as MeshInstance3D).transform == Transform3D.IDENTITY:
			reset_ok += 1
		h.queue_free()
		await _frames(1)
	var gic: Object = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var parsed: Dictionary = gic.call("_parse_config_token", "line_network_ca:0:0#size:2.4")
	var cfg: Dictionary = parsed.get("config_data", {})
	var tok_ok: bool = str(cfg.get("size", "")) == "2.4" and not cfg.has("size:2.4") and cfg.size() == 1 \
		and str(parsed.get("lookup_name")) == "line_network_ca"
	if gic is Node:
		(gic as Node).free()
	_check("L4b #size applied after growth, removed by a config without it, parsed by the grid tokenizer",
		late_ok == 3 and reset_ok == 3 and tok_ok,
		"%d of 3 fitted when configured late, %d of 3 back to the plain drawing, tokenizer config_data=%s" % [late_ok, reset_ok, str(cfg)])

	# --- L5: the subclass with its own growth rule keeps growing
	seed(7)
	var d: Node3D = load(DENDRITE_SCENE).instantiate()
	root.add_child(d)
	await _frames(25)
	var d25: int = (d.get("connections") as Array).size()
	await _frames(40)
	var d65: int = (d.get("connections") as Array).size()
	_check("L5 dendrite_growth_ca keeps growing past 20 generations", bool(d.get("is_running")) and d65 > d25,
		"running=%s, lines %d at frame 25 -> %d at frame 65" % [str(d.get("is_running")), d25, d65])
	d.queue_free()
	await _frames(1)

	# --- C1, C2, C3: crack plate against the shipped script
	var crack_ok := 0
	var crack_same := 0
	var crack_old_on := 0
	var stop_frames: Array = []
	var c_new := 0
	var c_old := 0
	var mesh_read := 0
	var mesh_same := 0
	var mesh_early_differs := 0
	for s in [101, 202, 303]:
		var c: Node3D = load(CRACK_SCENE).instantiate()
		c.set("SEED", s)
		root.add_child(c)
		var fr := 0
		while c.is_processing() and fr < 600:
			await process_frame
			fr += 1
		stop_frames.append(fr)
		if not c.is_processing():
			crack_ok += 1
		var g_new: Array = (c.get("grid") as Array).duplicate(true)
		var s_new: Array = (c.get("stress_grid") as Array).duplicate(true)
		var v_new := _crack_vertices(c)
		c_new += _cost(c)
		c.call("add_stress_point", Vector3.ZERO, 0.1)
		var resumed: bool = c.is_processing()
		c.queue_free()
		await _frames(1)
		var o: Node3D = load(CRACK_SCENE).instantiate()
		o.set_script(old_crack)
		o.set("SEED", s)
		root.add_child(o)
		await _frames(fr - 20)
		var v_early := _crack_vertices(o)
		await _frames(140)
		var v_old := _crack_vertices(o)
		if v_new.size() > 0:
			mesh_read += 1
			if v_new == v_old:
				mesh_same += 1
			if v_early != v_new:
				mesh_early_differs += 1
		if o.is_processing():
			crack_old_on += 1
		c_old += _cost(o)
		var g_old: Array = o.get("grid")
		var s_old: Array = o.get("stress_grid")
		var diff := 0
		var n_cr := 0
		for x in range(g_new.size()):
			for z in range(g_new.size()):
				var cn: bool = g_new[x][z] == 2
				var co: bool = g_old[x][z] == 2
				if cn:
					n_cr += 1
				if cn != co or (cn and not is_equal_approx(float(s_new[x][z]), float(s_old[x][z]))):
					diff += 1
		if diff == 0 and n_cr > 0:
			crack_same += 1
		print("  crack seed %d: stopped at frame %d, %d cracked cells, %d differ from the shipped script 120 frames later, resumed on add_stress_point=%s" % [s, fr, n_cr, diff, str(resumed)])
		o.queue_free()
		await _frames(1)
		if not resumed:
			crack_ok -= 1
	_check("C1 the crack plate stops once settled (and C3 resumes on add_stress_point)", crack_ok == 3 and crack_old_on == 3,
		"%d of 3 stopped at frames %s; the shipped script still stepping in %d of 3" % [crack_ok, str(stop_frames), crack_old_on])
	_check("C2 the shipped script draws nothing different 120 frames later", crack_same == 3 and mesh_read == 3 and mesh_same == 3,
		"%d of 3 seeds: same cracked set and same stress on every cracked cell; mesh vertices read back in %d of 3, identical in %d of 3" % [crack_same, mesh_read, mesh_same])
	_check("C2 negative control: 20 frames before the stop the shipped mesh is different", mesh_early_differs == 3,
		"%d of 3 seeds" % mesh_early_differs)
	print("COST crackpropagation_ca per frame after settling: new %d us, shipped %d us (mean of 3)" % [c_new / 3, c_old / 3])

	print("RESULT %s (%d failed)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)
