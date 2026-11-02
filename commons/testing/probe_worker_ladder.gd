extends Node3D
## THE WORKER LADDER BENCH (2026-11-02): one seed of the humanoid worker being (commons/artifacts/worker_being) stood
## at a series of stages side by side, checked for the ladder's rules and photographed mid-dance - a tile per stage.
## The rules: Point_One is the heart alone; along the walk the parts only grow, except the ones a later word retires
## (the lines, plates and cord when the slabs come, the flower when the coral grows); the seed's plan is the same at
## every stage; the moves grow too (still at Point_One, a sway with self_move, turning with rotate, a bounce with
## springs on planted feet); a dancing body's joints really turn and a still one's do not; under gravity at least
## one foot stands on the floor at every moment of the dance and none sinks into it; walking, the feet alternate.
## Run: godot --path . --xr-mode off res://commons/testing/probe_worker_ladder.tscn -- --out=<dir> [--seed=7]
##      [--stages=Point_One,...] [--live]  (live: no checks, no quit - watch the row dance, the camera drifting)
##      or: python tools/worker_ladder_gallery.py (publishes /worker-ladder)

const BEING := preload("res://commons/artifacts/worker_being/worker_being.tscn")
const RETIRES := {"lines": "slabs", "plates": "slabs", "cord": "slabs", "flower": "coral", "painted_skin": "tesserae", "tesserae": "made_finish"}
const SPACING := 1.9
var out := "user://worker_ladder"
var seed := 7
var stages := ["Point_One", "Point_Lines", "Point_Line_Grid", "Primitives_Polythedra", "primitives", "transformation", "color", "forces", "lsystems", "full"]
var checks: Array = []
var beings: Array = []
var live := false
var cam: Camera3D
var _t := 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
		if a.begins_with("--seed="): seed = int(a.trim_prefix("--seed="))
		if a.begins_with("--stages="): stages = Array(a.trim_prefix("--stages=").split(",", false))
		if a == "--live": live = true
	DirAccess.make_dir_recursive_absolute(out)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR
	e.background_color = Color("e9e6df"); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("f1ede4"); e.ambient_light_energy = 0.55; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-52, 32, 0); sun.light_energy = 1.1; sun.shadow_enabled = true; add_child(sun)
	var floor_ := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(stages.size() * SPACING + 8, 14); floor_.mesh = pm
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color("dedad2"); fm.roughness = 0.9; floor_.material_override = fm
	floor_.position = Vector3((stages.size() - 1) * SPACING * 0.5, -0.001, 0); add_child(floor_)
	for i in stages.size():
		var b: Node3D = BEING.instantiate()
		b.set_meta("config_stage", stages[i]); b.set_meta("config_seed", seed); b.set_meta("config_motion", "dance")
		b.position = Vector3(i * SPACING, 0, 0); add_child(b); beings.append(b)
		var l := Label3D.new(); l.text = "%d  %s" % [i, stages[i]]; l.font_size = 48; l.pixel_size = 0.0022
		l.modulate = Color("2a2a2a"); l.rotation_degrees.x = -90; l.position = Vector3(i * SPACING, 0.002, 0.8); add_child(l)
	cam = Camera3D.new(); add_child(cam); cam.current = true; cam.fov = 34
	for i in 4: await get_tree().process_frame
	# the project's autoload HUDs (the mushroom counter) draw over a capture: hide every canvas layer
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false): layer.visible = false
	if live:
		return
	for b in beings: b.set_process(false)   # the bench sets the moments itself
	await _check()
	await _photograph()
	get_tree().quit(0 if checks.all(func(c): return c.passed) else 1)

func _process(delta: float) -> void:
	if not live or cam == null: return
	_t += delta
	var mid := (stages.size() - 1) * SPACING * 0.5
	var x := mid + sin(_t * 0.08) * mid
	cam.position = Vector3(x + 1.2, 1.5, 3.4); cam.look_at(Vector3(x, 0.95, 0))

func _check() -> void:
	var states: Array = beings.map(func(b): return b.get_state())
	check("every stage is known to the grammar (%s)" % ", ".join(states.filter(func(s): return not s.known).map(func(s): return s.stage)), states.all(func(s): return s.known))
	var first: Dictionary = states[0]
	if str(first.stage) == "Point_One":
		check("Point_One is the heart alone, still: %s %s" % [str(first.parts), str(first.moves)], first.parts == ["heart"] and first.moves.is_empty())
	var grows := true; var lost: Array = []
	for i in range(1, states.size()):
		for p in states[i - 1].parts:
			if p in states[i].parts: continue
			if RETIRES.has(p) and RETIRES[p] in states[i].parts: continue
			grows = false; lost.append("%s lost %s" % [states[i].stage, p])
		for m in states[i - 1].moves:
			if not (m in states[i].moves): grows = false; lost.append("%s lost the move %s" % [states[i].stage, m])
	check("along the walk the parts and the moves only grow, but for what a later word retires (%s)" % (", ".join(lost) if not lost.is_empty() else " -> ".join(states.map(func(s): return "%d/%d" % [s.parts.size(), s.moves.size()]))), grows)
	check("one seed, one plan at every stage", states.all(func(s): return s.plan == first.plan))
	for s in states:
		match str(s.stage):
			"primitives": check("at Primitives it sways (self_move) in slabs with ball joints and beads: %s" % str(s.moves), "sway" in s.moves and "slabs" in s.parts and "ball_joints" in s.parts and "beads" in s.parts)
			"transformation": check("at Transformation every joint turns and it steps, in floating panels: %s" % str(s.moves), "turn" in s.moves and "step" in s.moves and "panels" in s.parts)
			"forces": check("at Forces it bounces on springs over planted feet: %s" % str(s.moves), "bounce" in s.moves and "springs" in s.parts and "planted" in s.parts)
			"full": check("at the end of the walk: a wave in the arms, varied phrases, the fused skin and the made finish", "wave" in s.moves and "vary" in s.moves and "fused_skin" in s.parts and "made_finish" in s.parts)
	# the dance moves the joints; a body with no moves stays still
	var moving_ok := true; var notes: Array = []
	for i in beings.size():
		var b: Node3D = beings[i]
		b.pose_at(0.4); var a := _joint_snapshot(b)
		b.pose_at(1.3); var c := _joint_snapshot(b)
		var turned := 0.0
		for n in a: turned = maxf(turned, rad_to_deg(a[n].get_rotation_quaternion().angle_to(c[n].get_rotation_quaternion())))
		var should: bool = not states[i].moves.is_empty()
		if should != (turned > 2.0): moving_ok = false
		notes.append("%s %.0f deg" % [states[i].stage, turned])
	check("a dancing body's joints turn, a still one's do not (%s)" % ", ".join(notes), moving_ok)
	# under gravity: at every moment one foot stands on the floor, none sinks into it
	var planted_ok := true; var worst := 0.0
	for i in beings.size():
		if not ("planted" in states[i].parts): continue
		var b: Node3D = beings[i]
		for k in 40:
			b.pose_at(k * 0.137)
			var yl: float = b.ankle_in_skeleton("l").y; var yr: float = b.ankle_in_skeleton("r").y
			var low := minf(yl, yr)
			worst = maxf(worst, absf(low - 0.045))
			if absf(low - 0.045) > 0.012 or minf(yl, yr) < 0.03: planted_ok = false
	check("under gravity one foot always stands on the floor and none sinks (worst %.1f mm)" % (worst * 1000.0), planted_ok)
	# walking, the feet alternate
	var walker: Node3D = beings[beings.size() - 1]
	walker.apply_grid_config({"motion": "walk"}); walker.set_process(false)
	walker.pose_at(0.0); var z0: float = walker.ankle_in_skeleton("l").z - walker.ankle_in_skeleton("r").z
	walker.pose_at(60.0 / walker.tempo)   # one beat = half a gait cycle
	var z1: float = walker.ankle_in_skeleton("l").z - walker.ankle_in_skeleton("r").z
	check("walking, the feet alternate (left minus right %.2f m, then %.2f m a step later)" % [z0, z1], absf(z0) > 0.15 and absf(z1) > 0.15 and signf(z0) != signf(z1))
	walker.apply_grid_config({"motion": "dance"}); walker.set_process(false)

func _joint_snapshot(b: Node3D) -> Dictionary:
	var out_ := {}
	for n in ["pelvis", "chest", "shoulder_l", "shoulder_r", "elbow_l", "head", "hip_l", "knee_l"]:
		out_[n] = (b.joint(n) as Node3D).global_basis.orthonormalized()
	return out_

func _photograph() -> void:
	var entries: Array = []
	for i in beings.size():
		var b: Node3D = beings[i]
		for other in beings: other.pose_at(1.7)
		cam.position = b.position + Vector3(1.55, 1.45, 2.7); cam.look_at(b.position + Vector3(0, 0.92, 0))
		await _shot(out.path_join("%02d_%s.png" % [i, stages[i]]))
		var s: Dictionary = b.get_state()
		var f := FileAccess.open(out.path_join("%02d_%s.json" % [i, stages[i]]), FileAccess.WRITE)
		f.store_string(JSON.stringify({"id": "%02d_%s" % [i, stages[i]], "stage": s.stage, "seed": seed, "index": i, "parts": s.parts,
			"moves": s.moves, "words": s.words, "token": "worker_being:0#stage:%s#seed:%d#motion:dance" % [s.stage, seed]}, "  ")); f.close()
		entries.append({"index": i, "stage": s.stage, "parts": s.parts, "moves": s.moves})
	# the dance, six moments of the last stage
	var last: Node3D = beings[beings.size() - 1]
	cam.position = last.position + Vector3(1.55, 1.45, 2.7); cam.look_at(last.position + Vector3(0, 0.92, 0))
	for k in 6:
		last.pose_at(k * 0.29)
		await _shot(out.path_join("dance_%d.png" % k))
	var failed := checks.filter(func(c): return not c.passed)
	var r := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	r.store_string(JSON.stringify({"passed": failed.is_empty(), "seed": seed, "stages": stages, "checks": checks, "entries": entries}, "  ")); r.close()
	print("[probe_worker_ladder] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])

func _shot(path: String) -> void:
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "passed": ok})
	print("[worker_ladder] ", "PASS " if ok else "FAIL ", label)
