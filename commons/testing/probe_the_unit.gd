extends Node3D
## THE UNIT (Palle, 2026-11-03): three actions per unit; what two and three identical units joined by rods become. The
## model (unit_sim.gd) is checked first, then the scene (the_unit.gd). The evidence is for MECHANICAL coupling (Palle's
## level 2): the rule is a force-yield, what a back-drivable motor does; nothing here shows units adapting (level 3).
##   A port      the GDScript model reproduces the Python study (scratchpad unit_sims/compliance, setting S4) at 10 and
##               90 s to 1e-5 m / rad
##   B local     the rule is one static function of (params, own hub angle, own pin force along and across) - nothing
##               else reaches it; each unit's output is exactly three rates inside their limits
##   C one       one unit's pen closes its rosette every 2 pi / w0 s (the epitrochoid of its own two rotations)
##   D control   two units with the pair's starts and NO rod draw two congruent rosettes at exactly the programmed rates
##   E relation  joined, from three different starts the pair settles into ONE relation - the same distance and angle
##               between headings - with both units turning at a shared rate and hub rate that neither rule contains
##   F not a sum the pen on the rod is not the midpoint of the two free motions (the superposition) - it is far from it
##   G second    the mirror-symmetric start (facing) falls into a different mode: the units dance, the pen barely moves
##   H kick      a 40-degree turn of one unit's body under its pin is forgotten: the pair returns to its relation; with
##               the hub on the axle (a_hub 0) the same kick is remembered (negative - the offset is what makes it an
##               attractor)
##   I rate      the scene's model reaches the same state after 20 s at 60 and at 90 physics ticks per second
##   L triangle  three units, a rigid rod between every two hubs (w0 0.8): three different starts end in one relation -
##               the same mean turn and hub rates - and a mirror-symmetric start (tangent) in another, its hubs stopped
##   J scene     each setup builds its units, rods and pens; the ink grows; the button steps to the next start and
##               clears the paper
##   K tower     floor 210's hall builds the four stations from its sidecar, under the biome court
## Pictures: the_unit_quartet.png, the_unit_pair.png, the_unit_triangle.png, the_unit_close.png,
## the_unit_undercroft.png. Report ada_run/workstation/the_unit.json.
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_the_unit.tscn

const Sim = preload("res://commons/artifacts/the_unit/unit_sim.gd")
const UNIT_SCENE = preload("res://commons/artifacts/the_unit/the_unit.tscn")
var report := {"checks": []}
var out_dir := ""

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/workstation");DirAccess.make_dir_recursive_absolute(out_dir)
	_model_checks()
	await _scene_checks()
	_finish()

func _model_checks() -> void:
	# A - the port
	var ref := {10.0: [[0.5167925309755108, 0.5482081532756936, 1.1705415699723896, 9.092925910745715], [0.23123877591775935, 1.321503838031485, 2.751436572562089, 6.284542184223907]],
		90.0: [[0.9083171620768399, 0.6241976939934918, 8.459371556466907, 59.82176648882181], [0.07844652503886083, 0.7012090488531005, 8.647371211319706, 55.76417134686615]]}
	var solo_ref := [-0.29201199701491215, 1.1240588796690314, 22.499999999989807, 89.99999999995923]
	var pair = Sim.make("pair", "c", {}, .5, false)
	var solo = Sim.make("one", "c", {}, .5, false)   # the study started its single unit at the origin
	var worst := 0.0
	for T in [10.0, 90.0]:
		while pair.time < T - 1e-9:pair.tick()
		for i in 2:
			var u: Dictionary = pair.units[i]
			var got := [float(u.x), float(u.z), float(u.th), float(u.ph)]
			for k in 4:worst = maxf(worst, absf(got[k] - float(ref[T][i][k])))
	while solo.time < 90.0 - 1e-9:solo.tick()
	var s: Dictionary = solo.units[0]
	var got_solo := [float(s.x), float(s.z), float(s.th), float(s.ph)]
	for k in 4:worst = maxf(worst, absf(got_solo[k] - float(solo_ref[k])))
	_check("A port: the GDScript model matches the Python study at 10 and 90 s - largest difference %s" % str(worst), worst < 1e-5, {"worst": worst})
	# B - local: the rule's inputs, and three bounded outputs
	var args := []
	for m in Sim.new().get_script().get_script_method_list():
		if m.name == "rule":args = (m.args as Array).map(func(a): return a.name)
	var bounded := true
	for u in pair.units:
		var c: Vector3 = u.cmd
		bounded = bounded and absf(c.x) <= float(pair.P.vmax) + 1e-9 and absf(c.y) <= float(pair.P.wmax) + 1e-9 and absf(c.z) <= float(pair.P.hmax) + 1e-9
	_check("B local: the rule reads %s - its own hub angle and the force at its own pin - and each unit acts through three bounded rates" % str(args), args == ["p", "phi", "f_par", "f_lat"] and bounded, {"args": args})
	# C - one unit's rosette closes
	var one = Sim.make("one", "c")
	var period := TAU / float(one.P.w0)
	var p0: Vector2 = one.pen_point(0)
	var lo := p0;var hi := p0
	while one.time < period - 1e-9:
		one.tick();var q: Vector2 = one.pen_point(0);lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y));hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var closure: float = one.pen_point(0).distance_to(p0)
	# the oracle: the hub circles at sqrt(R^2 + a^2) round the turning centre (R = v0 / w0), the pin r_pin beyond it
	var expect: float = 2.0 * (sqrt(pow(float(one.P.v0) / float(one.P.w0), 2) + pow(float(one.P.a_hub), 2)) + float(one.P.r_pin))
	_check("C one: one unit's pen closes its rosette after %.1f s (gap %.1f mm), %.3f x %.3f m against %.3f m from its geometry" % [period, closure * 1000.0, hi.x - lo.x, hi.y - lo.y, expect], closure < .01 and absf((hi.x - lo.x) - expect) < .02 and absf((hi.y - lo.y) - expect) < .02, {"gap_m": closure, "extent": [hi.x - lo.x, hi.y - lo.y], "expect": expect})
	# D - control: no rod
	var apart = Sim.make("apart", "c")
	var lengths := [0.0, 0.0];var prev := [apart.pen_point(0), apart.pen_point(1)];var rates_ok := true
	while apart.time < 2.0 * period - 1e-9:   # two whole rosettes, so the phase along the curve does not count
		apart.tick()
		for j in 2:
			var q: Vector2 = apart.pen_point(j);lengths[j] += q.distance_to(prev[j]);prev[j] = q
		for u in apart.units:
			var c: Vector3 = u.cmd
			rates_ok = rates_ok and is_equal_approx(c.x, float(apart.P.v0)) and is_equal_approx(c.y, float(apart.P.w0)) and is_equal_approx(c.z, float(apart.P.h0))
	_check("D control: without the rod the two units draw congruent rosettes (%.3f and %.3f m of ink in two turns) at exactly the programmed rates" % [lengths[0], lengths[1]], absf(lengths[0] - lengths[1]) < .005 * lengths[0] and rates_ok, {"lengths": lengths})
	# E - the relation, from three starts
	# within a minute the three starts fall onto one relation (compared over 60-120 s); then all three slide together,
	# breathing, from about -27 deg toward about -77 deg as the orbit spirals in - compared again over 480-540 s
	var rel := {}
	var late := {}
	for arr in ["c", "parallel", "crossed"]:
		var sim = Sim.make("pair", arr)
		rel[arr] = _relation(sim, 60.0, 120.0)
		late[arr] = _relation(sim, 480.0, 540.0)
	var hl: Array = late.values().map(func(r): return float(r.heading_deg))
	var ds: Array = rel.values().map(func(r): return float(r.distance))
	var hs: Array = rel.values().map(func(r): return float(r.heading_deg))
	var ws: Array = rel.values().map(func(r): return [float(r.w[0]), float(r.w[1])])
	var shared := true
	for w in ws:shared = shared and absf(float(w[0]) - float(w[1])) < .02 and maxf(float(w[0]), float(w[1])) < .15   # the relation breathes: within a minute the roles swap a little
	var spread_d: float = ds.max() - ds.min()
	var spread_h: float = hs.max() - hs.min()
	var stretch_ok: bool = rel.values().all(func(r): return float(r.max_stretch_mm) < 10.0)
	var spread_late: float = hl.max() - hl.min()
	_check("E relation: a minute in, three starts hold one relation - %.3f-%.3f m apart at %.1f to %.1f deg, both units turning at %s rad/s (programmed %.2f); eight minutes in they are still together at %.1f to %.1f deg; the rod held to %.1f mm" % [ds.min(), ds.max(), hs.min(), hs.max(), str(ws.map(func(w): return [snappedf(float(w[0]), .001), snappedf(float(w[1]), .001)])), float(Sim.defaults().w0), hl.min(), hl.max(), rel.values().map(func(r): return float(r.max_stretch_mm)).max()], spread_d < .015 and spread_h < 3.0 and spread_late < 6.0 and shared and stretch_ok, {"early": rel, "late": late})
	# F - not the sum
	var joined = Sim.make("pair", "c")
	var free = Sim.make("apart", "c")
	var gap := 0.0;var n := 0
	while joined.time < 120.0 - 1e-9:
		joined.tick();free.tick()
		if joined.time >= 60.0:
			var sup: Vector2 = (free.pin(0) + free.pin(1)) * .5
			gap += joined.pen_point(0).distance_to(sup);n += 1
	gap /= maxf(n, 1)
	_check("F not a sum: the pen on the rod runs on average %.2f m from where the midpoint of the two free motions would be" % gap, gap > .3, {"mean_gap_m": gap})
	# G - the second mode
	var face = Sim.make("pair", "facing")
	var pen_pts := [];var unit_path := 0.0;var last: Vector2 = Vector2(float(face.units[0].x), float(face.units[0].z))
	while face.time < 120.0 - 1e-9:
		face.tick()
		var here := Vector2(float(face.units[0].x), float(face.units[0].z));unit_path += here.distance_to(last);last = here
		if face.time >= 60.0:pen_pts.append(face.pen_point(0))
	var c := Vector2.ZERO
	for q in pen_pts:c += q
	c /= maxf(pen_pts.size(), 1)
	var wander := 0.0
	for q in pen_pts:wander = maxf(wander, (q as Vector2).distance_to(c))
	_check("G second mode: from the mirrored start the units travel %.1f m in 120 s while the pen stays within %.2f m of one spot" % [unit_path, wander], unit_path > 5.0 and wander < .2, {"unit_path_m": unit_path, "pen_wander_m": wander})
	# H - a kick is forgotten (offset hub); remembered with the hub on the axle
	var base := _relation(_pair_at({}), 240.0, 300.0)
	var kicked := _relation(_pair_at({}), 240.0, 300.0, 120.0)
	var base0 := _relation(_pair_at({"a_hub": 0.0}), 240.0, 300.0)
	var kicked0 := _relation(_pair_at({"a_hub": 0.0}), 240.0, 300.0, 120.0)
	var back := absf(wrapf(float(kicked.heading_deg) - float(base.heading_deg), -180.0, 180.0))
	var kept := absf(wrapf(float(kicked0.heading_deg) - float(base0.heading_deg), -180.0, 180.0))
	_check("H kick: turned 40 deg at 120 s, the pair returns to within %.1f deg of its relation; with the hub on the axle the kick stays (%.1f deg off)" % [back, kept], back < 4.0 and kept > 8.0, {"offset_hub": [base, kicked], "axle_hub": [base0, kicked0]})
	# L - the triangle: one relation from three starts, another from the symmetric one
	var tri := {}
	for arr in ["c", "scattered", "drifted", "tangent"]:
		tri[arr] = _triangle_rates(Sim.make("triangle", arr), 150.0, 300.0)
	var tw: Array = ["c", "scattered", "drifted"].map(func(k): return float(tri[k].w))
	var th_: Array = ["c", "scattered", "drifted"].map(func(k): return float(tri[k].h))
	var one_relation: bool = tw.max() - tw.min() < .02 and th_.max() - th_.min() < .02 and tw.min() > .40 and tw.max() < .56
	var other_mode: bool = absf(float(tri.tangent.h)) < .05 and absf(float(tri.tangent.w) - float(tw[0])) > .2
	var held: bool = tri.values().all(func(r): return float(r.max_stretch_mm) < 15.0)
	_check("L triangle: three starts end in one relation - turning %s rad/s on average (programmed 0.8), hubs %s (programmed 1.0); the symmetric start in another, hubs %.3f, turning %.3f; rods held to %.1f mm" % [str(tw.map(func(v): return snappedf(v, .001))), str(th_.map(func(v): return snappedf(v, .001))), float(tri.tangent.h), float(tri.tangent.w), tri.values().map(func(r): return float(r.max_stretch_mm)).max()], one_relation and other_mode and held, tri)

## The triangle's mean turn and hub rate over all three units, [t0, t1].
func _triangle_rates(sim, t0: float, t1: float) -> Dictionary:
	var w := 0.0;var h := 0.0;var n := 0;var max_stretch := 0.0
	while sim.time < t1 - 1e-9:
		sim.tick()
		for j in sim.rods.size():max_stretch = maxf(max_stretch, absf(float(sim.stretch(j))) * 1000.0)
		if sim.time >= t0:
			for u in sim.units:
				w += float(u.cmd.y) / 3.0;h += float(u.cmd.z) / 3.0
			n += 1
	n = maxi(n, 1)
	return {"w": w / n, "h": h / n, "max_stretch_mm": max_stretch}

## The study's start C for any hub placement: unit 1 at (-0.5, -0.3) heading 0, hub at 90 deg; unit 2's pin one rod
## length away along 0.3 rad, heading 2.1, hub -0.4.
func _pair_at(params: Dictionary):
	var sim = Sim.new(params)
	sim.add_unit(-0.5, -0.3, 0.0, PI / 2.0)
	var q2: Vector2 = sim.pin(0) + float(sim.P.L) * Vector2(cos(0.3), sin(0.3))
	var th2 := 2.1;var al2 := th2 - 0.4
	sim.add_unit(q2.x - float(sim.P.r_pin) * cos(al2) - float(sim.P.a_hub) * cos(th2), q2.y - float(sim.P.r_pin) * sin(al2) - float(sim.P.a_hub) * sin(th2), th2, -0.4)
	sim.add_pen_on_rod(sim.add_rod(0, 1), .5)
	return sim

## Run `sim` to t1 and describe the relation over [t0, t1]; optionally kick unit 2 by 40 degrees at `kick_at`.
func _relation(sim, t0: float, t1: float, kick_at := -1.0) -> Dictionary:
	var dist := 0.0;var sx := 0.0;var sy := 0.0;var w := [0.0, 0.0];var h := [0.0, 0.0];var n := 0;var max_stretch := 0.0;var kicked := false
	while sim.time < t1 - 1e-9:
		if kick_at >= 0.0 and not kicked and sim.time >= kick_at:
			kicked = true
			var u: Dictionary = sim.units[1]
			var pin: Vector2 = sim.pin(1)
			var al: float = float(u.th) + float(u.ph)
			u.th = float(u.th) + deg_to_rad(40.0);u.ph = al - float(u.th)
			u.x = pin.x - float(sim.P.a_hub) * cos(float(u.th)) - float(sim.P.r_pin) * cos(al)
			u.z = pin.y - float(sim.P.a_hub) * sin(float(u.th)) - float(sim.P.r_pin) * sin(al)
		sim.tick()
		if sim.rods.size() > 0:max_stretch = maxf(max_stretch, absf(float(sim.stretch(0))) * 1000.0)
		if sim.time >= t0:
			var a: Dictionary = sim.units[0];var b: Dictionary = sim.units[1]
			dist += Vector2(float(a.x), float(a.z)).distance_to(Vector2(float(b.x), float(b.z)))
			var dh := float(a.th) - float(b.th);sx += cos(dh);sy += sin(dh)
			for i in 2:
				w[i] += float(sim.units[i].cmd.y);h[i] += float(sim.units[i].cmd.z)
			n += 1
	n = maxi(n, 1)
	return {"distance": dist / n, "heading_deg": rad_to_deg(atan2(sy, sx)), "w": [w[0] / n, w[1] / n], "h": [h[0] / n, h[1] / n], "max_stretch_mm": max_stretch}

func _scene_checks() -> void:
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("50565e")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .7;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-60, 30, 0);sun.light_energy = .9;add_child(sun)
	var floor_mesh := MeshInstance3D.new();var fm := PlaneMesh.new();fm.size = Vector2(30, 30);floor_mesh.mesh = fm
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8a8f94");floor_mesh.material_override = fmat;floor_mesh.position.y = -.01;add_child(floor_mesh)
	var cam := Camera3D.new();cam.fov = 55;add_child(cam);cam.current = true
	# I - frame rate: the scene's model after 20 s at 60 and at 90 ticks
	var states := []
	for hz in [60.0, 90.0]:
		var u: Node3D = UNIT_SCENE.instantiate();u.set_meta("config_setup", "pair");u.set_meta("config_running", false);add_child(u)
		for i in int(20.0 * hz):u.sim.advance(1.0 / hz)
		states.append([float(u.sim.units[0].x), float(u.sim.units[0].z), float(u.sim.time)])
		u.queue_free()
	await get_tree().process_frame
	_check("I rate: after 20 s the model stands at the same place stepped at 60 and at 90 ticks per second (%s vs %s)" % [str(states[0]), str(states[1])], states[0] == states[1], {"states": states})
	# J - the scenes: the pair, the triangle, the control and the single unit, laid out as under the court
	var layout := {"pair": Vector3(-2.0, 0, -1.9), "triangle": Vector3(2.0, 0, -1.9), "apart": Vector3(-2.0, 0, 2.1), "one": Vector3(2.0, 0, 2.1)}
	var views := {}
	for setup in layout:
		var u: Node3D = UNIT_SCENE.instantiate();u.name = "Unit_" + setup;u.position = layout[setup];u.set_meta("config_setup", setup)
		if setup == "pair":u.set_meta("config_paper", 3.4)
		add_child(u)
		views[setup] = u
	await get_tree().physics_frame
	var built := {}
	for setup in views:
		var u: Node3D = views[setup]
		var units := u.get_node("Field").get_children().filter(func(c): return str(c.name).begins_with("Unit")).size()
		var rods := u.get_node("Field").get_children().filter(func(c): return str(c.name).begins_with("Rod")).size()
		var pens := u.get_node("Field").get_children().filter(func(c): return str(c.name).begins_with("Ink")).size()
		built[setup] = [units, rods, pens]
		u.run_for(150.0)
	var ink: Dictionary = {}
	for setup in views:ink[setup] = (views[setup] as Node3D).get_state().ink
	var shape_ok: bool = built.pair == [2, 1, 1] and built.triangle == [3, 3, 4] and built.apart == [2, 0, 2] and built.one == [1, 0, 1]
	var inked: bool = int(ink.pair[0]) > 1000 and int(ink.triangle[1]) > 1000 and int(ink.apart[0]) > 1000 and int(ink.one[0]) > 1000
	var pair_node: Node3D = views.pair
	pair_node.button.pressed.emit()
	await get_tree().physics_frame
	var stepped: bool = pair_node.arrangement == "parallel" and int(pair_node.get_state().ink[0]) < 5
	pair_node.restart()   # back to a fresh drawing of 'parallel' for the picture
	pair_node.arrangement = "c";pair_node.restart();pair_node.run_for(150.0)
	_check("J scene: pair %s, triangle %s, apart %s, one %s (units, rods, pens); after 150 s the ink holds %s marks; the button steps to the next start and clears the paper" % [str(built.pair), str(built.triangle), str(built.apart), str(built.one), str(ink)], shape_ok and inked and stepped, {"built": built, "ink": ink, "stepped": stepped})
	var shots := {"the_unit_quartet": [Vector3(0.0, 7.5, -8.5), Vector3(0.0, 0, -0.4)], "the_unit_pair": [Vector3(-2.0, 4.0, -4.6), Vector3(-2.0, 0, -2.1)], "the_unit_triangle": [Vector3(2.0, 2.7, -3.9), Vector3(2.0, 0, -1.9)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		await _shoot(k)
	# close on the two units and their rod, wherever they are now
	var a: Vector2 = pair_node.sim.hub(0) * pair_node.scale_used()
	var b: Vector2 = pair_node.sim.hub(1) * pair_node.scale_used()
	var mid := pair_node.position + Vector3((a.x + b.x) * .5, 0, (a.y + b.y) * .5)
	cam.transform = Transform3D(Basis(), mid + Vector3(.2, .75, .95)).looking_at(mid + Vector3(0, .05, 0))
	await _shoot("the_unit_close")
	for c in views.values():(c as Node).queue_free()
	# K - in the tower: floor 210's hall builds the four stations from its sidecar, under the court
	floor_mesh.position.y = -.09   # the hall stands its stations on the tower slab, 8 cm under its own datum
	var hall: Node3D = load("res://commons/void/trials/principal_places/places.tscn").instantiate();add_child(hall)
	for i in 6:
		await get_tree().physics_frame
	var found := {}
	for c in hall.get_children():
		if c.get_meta("activity_artifact", "") == "the_unit":
			found[str(c.get_meta("activity_id", c.name))] = {"setup": c.setup, "at": [snappedf(c.position.x, .01), snappedf(c.position.y, .01), snappedf(c.position.z, .01)], "yaw": snappedf(c.rotation_degrees.y, 1.0), "units": c.sim.units.size()}
	var want := {"pair": [-2.0, -0.08, -1.9], "triangle": [2.0, -0.08, -1.9], "apart": [-2.0, -0.08, 2.1], "one": [2.0, -0.08, 2.1]}
	var placed := found.size() == 4
	for v in found.values():
		placed = placed and want.has(v.setup) and Vector3(float(v.at[0]), float(v.at[1]), float(v.at[2])).distance_to(Vector3(float(want[v.setup][0]), float(want[v.setup][1]), float(want[v.setup][2]))) < .01 and absf(absf(float(v.yaw)) - 180.0) < 1.0
	_check("K tower: floor 210's hall builds %d Unit stations from its sidecar, under the court: %s" % [found.size(), str(found.values().map(func(v): return "%s at %s" % [v.setup, str(v.at)]))], placed, {"found": found})
	cam.transform = Transform3D(Basis(), hall.global_position + Vector3(0.0, 1.7, -6.4)).looking_at(hall.global_position + Vector3(0.0, 0.2, -0.6))
	for c in hall.get_children():
		if c.get_meta("activity_artifact", "") == "the_unit":c.run_for(120.0)
	await _shoot("the_unit_undercroft")

func _shoot(n: String) -> void:
	for t in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("%s.png" % n))

func _finish() -> void:
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	_write()
	print("[probe_the_unit] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)

func _write() -> void:
	var f := FileAccess.open(out_dir.path_join("the_unit.json"), FileAccess.WRITE);f.store_string(JSON.stringify(report, "  "));f.close()

func _check(what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_the_unit] %s  %s" % ["ok  " if ok else "FAIL", what])
	_write()   # progress for the watchdog
