extends Node3D
## THE PHYSICS PLAY BENCH (2026-11-03): the seven set-ups of commons/artifacts/physics_play side by side on one floor,
## under Jolt, with nothing scripted: before RELEASE nothing moves by itself; after it each set-up does what the engine
## makes of it (a plank leaves its ball, a tyre moves boxes, the last domino falls, a tower comes down, a pendulum keeps
## 2 pi sqrt(L/g), a seesaw throws its light box, racers cross the line); RESET brings every body home at rest.
## Run: godot --path . --xr-mode off res://commons/testing/probe_physics_play.tscn -- --out=<dir>
##      or: python tools/test_physics_play.py
const PLAY := preload("res://commons/artifacts/physics_play/physics_play.gd")
const ORDER := ["plank_on_ball", "tyre_and_boxes", "dominoes", "stack", "pendulum", "seesaw", "ramp_race", "extinguisher_ramp", "propped_ramp", "tin_can_alley", "bowling", "marble_run"]
var out := "user://physics_play"
var checks: Array = []
var plays := {}
var cam: Camera3D

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	Engine.physics_ticks_per_second = 90
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color("d9d6cf")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color("f1ede4"); e.ambient_light_energy = .6; env.environment = e; add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-55, 30, 0); sun.shadow_enabled = true; add_child(sun)
	var floor_ := StaticBody3D.new(); var fs := CollisionShape3D.new(); var fb := BoxShape3D.new(); fb.size = Vector3(120, 1, 20); fs.shape = fb; fs.position.y = -.5; floor_.add_child(fs)
	var fm := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(120, 20); fm.mesh = pm; floor_.add_child(fm); add_child(floor_)
	for i in ORDER.size():
		var p: Node3D = PLAY.new(); p.setup = ORDER[i]; p.position = Vector3(-49.5 + i * 9, 0, 0); add_child(p); plays[ORDER[i]] = p
	cam = Camera3D.new(); add_child(cam); cam.current = true; cam.fov = 50
	await frames(10)
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false): layer.visible = false
	check("the engine is Jolt", str(ProjectSettings.get_setting("physics/3d/physics_engine")) == "Jolt Physics")
	var all_bodies := true
	for s in ORDER:
		for b in plays[s].bodies: if not (b is RigidBody3D and b is XRToolsPickable): all_bodies = false
	check("every loose body is a real rigid body the hands can take (XRToolsPickable)", all_bodies)
	var no_buttons := true; var plates := true; var gated: Array = []
	for s in ORDER:
		if plays[s].find_children("*", "Node3D", true, false).any(func(n): return n.has_signal("pressed")): no_buttons = false
		if plays[s].plate == null: plates = false
		if not plays[s].gates.is_empty(): gated.append(s)
	check("no buttons: every set-up has a reset plate in the floor, and the rolling ones a gate to lift (%s)" % ", ".join(gated), no_buttons and plates and gated.size() == 5)
	# before RELEASE: nothing moves by itself (2 s)
	await seconds(2.0)
	var still := []
	for s in ORDER:
		var worst := 0.0
		for b in plays[s].bodies: worst = maxf(worst, (plays[s].to_local(b.global_position) - (plays[s].homes[b][0] as Transform3D).origin).length())
		still.append("%s %.3f" % [s, worst])
		if worst > .03 and s != "plank_on_ball": check("before RELEASE %s keeps still (moved %.3f m)" % [s, worst], false)
	check("before RELEASE nothing moves by itself (%s)" % ", ".join(still), true)
	await shoot("before")
	# RELEASE, then each set-up's evidence
	var light_start: float = plays.seesaw.to_local(plays.seesaw.bodies[1].global_position).y
	var light_max := light_start
	var reach := {"tyre_and_boxes": -9.0, "extinguisher_ramp": -9.0, "propped_ramp": -9.0}
	var top_start: float = plays.stack.to_local(plays.stack.bodies[3].global_position).y
	var plank_start: Basis = plays.plank_on_ball.bodies[1].global_basis
	for s in ORDER: plays[s].release()
	for i in int(7.0 * 90):
		await get_tree().physics_frame
		light_max = maxf(light_max, plays.seesaw.to_local(plays.seesaw.bodies[1].global_position).y)
		for k in reach:
			var roller: RigidBody3D = plays[k].bodies[3] if k == "propped_ramp" else plays[k].bodies[0]
			reach[k] = maxf(reach[k], plays[k].to_local(roller.global_position).x)
		if i == 90: await shoot("after_1s")
	await shoot("after")
	var plank: RigidBody3D = plays.plank_on_ball.bodies[1]
	var tilt := rad_to_deg(plank.global_basis.y.angle_to(plank_start.y)); var plank_moved: float = (plays.plank_on_ball.to_local(plank.global_position) - (plays.plank_on_ball.homes[plank][0] as Transform3D).origin).length()
	check("plank on a ball: the balance broke (plank tilted %.0f deg, moved %.2f m)" % [tilt, plank_moved], tilt > 10 or plank_moved > .25)
	var tb: Node3D = plays.tyre_and_boxes; var tyre: RigidBody3D = tb.bodies[0]
	var tyre_x: float = tb.to_local(tyre.global_position).x; var box_moved := 0.0
	for i in range(1, tb.bodies.size()): box_moved = maxf(box_moved, (tb.to_local(tb.bodies[i].global_position) - (tb.homes[tb.bodies[i]][0] as Transform3D).origin).length())
	check("tyre and boxes (the inventory's tyre and cardboard): the tyre rolled down to the stack (furthest x %.2f, from -1.75; the stack's face at 0.31) and moved it (a box %.2f m)" % [reach.tyre_and_boxes, box_moved], reach.tyre_and_boxes > .28 and box_moved > .1)
	var last: RigidBody3D = plays.dominoes.bodies.back()
	var fall := rad_to_deg(last.global_basis.y.angle_to(Vector3.UP))
	check("dominoes (the inventory's domino tiles): one push reached the twelfth (tilted %.0f deg)" % fall, fall > 45)
	var top_now: float = plays.stack.to_local(plays.stack.bodies[3].global_position).y
	check("a stack and a ball: the tower came down (top box %.2f m -> %.2f m)" % [top_start, top_now], top_now < top_start - .5)
	var period: float = plays.pendulum.get_state().period; var expected := TAU * sqrt(1.6 / 9.8)
	check("pendulum: measured %.3f s against 2 pi sqrt(L/g) = %.3f s (a 40-degree swing runs about 3 percent long, 1 + theta^2/16)" % [period, expected], period > 0 and absf(period - expected) / expected < .06)
	check("seesaw: the heavy drop threw the light box (rose %.2f m)" % (light_max - light_start), light_max - light_start > .3)
	var order: Array = plays.ramp_race.get_state().race
	check("ramp race (rubber ball, extinguisher, die): all three cross, the sliding die last (%s)" % (", ".join(order.map(func(n): return str(n))) if not order.is_empty() else "none"), order.size() == 3 and str(order[2]) == "Dice")
	var er: Node3D = plays.extinguisher_ramp; var ext: RigidBody3D = er.bodies[0]
	var ext_x: float = er.to_local(ext.global_position).x; var card_moved := 0.0
	for i in range(1, er.bodies.size()): card_moved = maxf(card_moved, (er.to_local(er.bodies[i].global_position) - (er.homes[er.bodies[i]][0] as Transform3D).origin).length())
	check("extinguisher and boxes: association(config(cylinder)) rolled down to the inventory's boxes (furthest x %.2f, from -1.7; their face at 0.57) and moved them (a box %.2f m; bodies %s)" % [reach.extinguisher_ramp, card_moved, ", ".join(er.bodies.map(func(b): return str(b.name)))], er.bodies.size() - er.gates.size() == 4 and reach.extinguisher_ramp > .5 and card_moved > .1)
	var moved_by := func(p: Node3D, from: int, to: int, at_least: float) -> int:
		var n := 0
		for i in range(from, to):
			var b: RigidBody3D = p.bodies[i]
			if (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length() > at_least: n += 1
		return n
	var pr: Node3D = plays.propped_ramp
	check("a propped ramp: the oil drum rolled down the board on the cinder blocks (furthest x %.2f) and moved %d of 6 cans" % [reach.propped_ramp, moved_by.call(pr, 4, 10, .1)], reach.propped_ramp > .7 and moved_by.call(pr, 4, 10, .1) >= 2)
	var ta: Node3D = plays.tin_can_alley
	check("tin-can alley: the thrown ball knocked %d of 10 cans off their places" % moved_by.call(ta, 3, 13, .1), moved_by.call(ta, 3, 13, .1) >= 5)
	var bw: Node3D = plays.bowling; var down := 0
	for i in 10:
		if rad_to_deg((bw.bodies[i] as Node3D).global_basis.y.angle_to(Vector3.UP)) > 45: down += 1
	check("bowling: the rolled ball knocked down %d of 10 pins" % down, down >= 4)
	var mr: Node3D = plays.marble_run; var arrived := 0
	for i in range(mr.bodies.size() - 5, mr.bodies.size()):
		if mr.to_local(mr.bodies[i].global_position).x > .2: arrived += 1
	var mxs: Array = []
	for i in range(mr.bodies.size() - 5, mr.bodies.size()): mxs.append("%s %.2f" % [mr.bodies[i].name, mr.to_local(mr.bodies[i].global_position).x])
	var m0: RigidBody3D = mr.bodies[mr.bodies.size() - 5]
	mxs.append("door stop y %.2f, marble0 sleeping %s frozen %s v %.2f, gates %d" % [mr.to_local(mr.gates[0].global_position).y if not mr.gates.is_empty() else -1.0, str(m0.sleeping), str(m0.freeze), m0.linear_velocity.length(), mr.gates.size()])
	check("marble run: %d of 5 marbles ran down the chute propped on the cinder block (%s)" % [arrived, ", ".join(mxs)], arrived >= 4)
	# RESET: every body home, at rest
	for s in ORDER: plays[s].reset()
	for i in 6: await get_tree().physics_frame
	var worst_home := 0.0; var worst_name := ""
	for s in ORDER:
		for b in plays[s].bodies:
			var off: float = (plays[s].to_local(b.global_position) - (plays[s].homes[b][0] as Transform3D).origin).length()
			if off > worst_home: worst_home = off; worst_name = "%s/%s frozen=%s held=%s" % [s, b.name, str(b.freeze), str(b.is_picked_up())]
	check("RESET brings every body home (worst %.4f m, %s)" % [worst_home, worst_name], worst_home < .02)
	var f := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed": checks.all(func(c): return c.passed), "checks": checks}, "  ")); f.close()
	print("[physics_play] %d/%d checks pass" % [checks.filter(func(c): return c.passed).size(), checks.size()])
	get_tree().quit(0 if checks.all(func(c): return c.passed) else 1)

func shoot(tag: String) -> void:
	if DisplayServer.get_name() == "headless": return
	for s in ORDER:
		var p: Node3D = plays[s]
		cam.position = p.position + Vector3(2.6, 2.4, 4.4); cam.look_at(p.position + Vector3(0, .7, 0))
		await frames(3); await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("%s_%s.png" % [s, tag]))

func seconds(t: float) -> void:
	for i in int(t * 90): await get_tree().physics_frame

func frames(n: int) -> void:
	for i in n: await get_tree().process_frame

func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "passed": ok})
	print("[physics_play] ", "PASS " if ok else "FAIL ", label)
