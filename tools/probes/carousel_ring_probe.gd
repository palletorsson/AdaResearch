extends Node3D
## FLOOR 17 "CAROUSEL ROTATION" BENCH (2026-11-09): carousel_cake's white_edges look + facet keys, and the new
## carousel_ring (ball on a handrail ring, grabbable handle). A SCENE, not a --script probe, so the handle's XRTools
## pickable script compiles and the real pick_up / let_go path is exercised.
##   headless: godot --headless --path . --xr-mode off res://tools/probes/carousel_ring_probe.tscn
##   windowed: godot --path . --xr-mode off --resolution 1280x800 res://tools/probes/carousel_ring_probe.tscn -- --shot
##             (saves ada_run/carousel_ring/carousel_ring.png)
const CAKE := "res://algorithms/transformation/carousel_cake/carousel_cake.tscn"
const RING := "res://commons/artifacts/carousel_ring/carousel_ring.tscn"
const EdgeOutline = preload("res://commons/void/edge_outline.gd")

var fails := 0
var checks := 0

class FakeGrip extends Node3D:
	var picked_up_ranged := false

func _ready() -> void:
	await get_tree().process_frame
	if "--shot" in OS.get_cmdline_user_args():
		await _shot()
	else:
		await _run()
	print("CAROUSEL_RING_PROBE %s  %d/%d checks passed" % ["PASS" if fails == 0 else "FAIL", checks - fails, checks])
	get_tree().quit(1 if fails else 0)

func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok: fails += 1
	print(("  ok    " if ok else "  FAIL  ") + what)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func cake(config: Dictionary) -> Node3D:
	var c: Node3D = load(CAKE).instantiate()
	for k in config: c.set_meta("config_" + str(k), config[k])
	add_child(c)
	if not config.is_empty(): c.apply_grid_config(config)
	return c

func ring(config: Dictionary) -> Node3D:
	var r: Node3D = load(RING).instantiate()
	for k in config: r.set_meta("config_" + str(k), config[k])
	add_child(r)
	if not config.is_empty(): r.apply_grid_config(config)
	return r

func overlay(holder: MultiMeshInstance3D) -> MultiMeshInstance3D:
	return holder.get_node_or_null(EdgeOutline.NAME) as MultiMeshInstance3D

func basis_close(a: Transform3D, b: Transform3D, tol := 1e-3) -> bool:
	return a.origin.distance_to(b.origin) < tol and (a.basis.x - b.basis.x).length() < tol \
		and (a.basis.y - b.basis.y).length() < tol and (a.basis.z - b.basis.z).length() < tol

## Largest mismatch between a group's faces and its edges (edges = faces grown 0.3 %).
func edge_lag(holder: MultiMeshInstance3D) -> float:
	var o := overlay(holder)
	var worst := 0.0
	for k in holder.multimesh.instance_count:
		var f := holder.multimesh.get_instance_transform(k)
		var e := o.multimesh.get_instance_transform(k)
		var grown := Transform3D(f.basis.scaled(Vector3.ONE * 1.003), f.origin)
		worst = maxf(worst, (grown.basis.x - e.basis.x).length() + (grown.basis.z - e.basis.z).length() + grown.origin.distance_to(e.origin))
	return worst

func _run() -> void:
	# Headless keeps no MultiMesh buffer (every instance reads back identity), so the edge-follow checks need a renderer.
	check(RenderingServer.get_video_adapter_name() != "", "real renderer (run WITHOUT --headless; MultiMesh readback is blind headless)")
	print("-- carousel_cake defaults (no new keys)")
	var plain := cake({})
	await frames(30)
	check(plain._groups.size() == 1 and plain._groups[0] == plain.mm_inst, "default: one MultiMesh group, mm_inst")
	check((plain.mm_inst.multimesh.mesh as CylinderMesh).radial_segments == 32, "default: 32 sides")
	check(plain.mm_inst.multimesh.instance_count == 8, "default: 8 instances")
	check(overlay(plain.mm_inst) == null and plain.mm_inst.material_override == null, "default: no edge overlay, no override")
	var baked := 0
	for ch in plain.get_children(): if ch is MultiMeshInstance3D and ch != plain.mm_inst: baked += 1
	check(baked == 1, "default: baked twin stack still present (unchanged legacy look)")
	var round_shapes := 0
	for b in plain._collider_bodies: if b.get_child(0).shape is CylinderShape3D: round_shapes += 1
	check(round_shapes == 8, "default: 8 round colliders")
	var t: float = plain._rotation_angle
	var expect := Transform3D(Basis.IDENTITY.rotated(Vector3.UP, t * plain._layer_speed(7)).scaled(Vector3(5, .5, 5)), Vector3(0, 5.15 + .25, 0))
	check(basis_close(plain.mm_inst.multimesh.get_instance_transform(7), expect), "default: layer 7 transform = legacy formula")
	plain.queue_free()

	print("-- white_edges, radial_segments 6 (carousel-together config)")
	var w := cake({"profile": "cake", "gallery": "clean", "base_speed": 0.3, "speed_multiplier": 1.2, "look": "white_edges", "radial_segments": 6})
	await frames(2)
	var o := overlay(w.mm_inst)
	check((w.mm_inst.multimesh.mesh as CylinderMesh).radial_segments == 6, "radial_segments 6 takes effect")
	check(w.mm_inst.material_override is StandardMaterial3D, "white finish on the stack")
	check(o != null and o.multimesh.instance_count == 8, "edge overlay: 8 instances")
	var wire: ArrayMesh = o.multimesh.mesh
	var lines := (wire.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 2
	# Each seam is cut into rings + 1 pieces by the CylinderMesh's ring loops (which themselves stay hidden: coplanar).
	var rings: int = (w.mm_inst.multimesh.mesh as CylinderMesh).rings
	check(lines == 6 * (rings + 1) + 12, "6-sided drum: 6 seams (x%d pieces) + 12 rim edges, no ring loops (got %d)" % [rings + 1, lines])
	var e0 := o.multimesh.get_instance_transform(7)
	var f0: Transform3D = w.mm_inst.multimesh.get_instance_transform(7)
	await frames(90)
	var f1: Transform3D = w.mm_inst.multimesh.get_instance_transform(7)
	check(not basis_close(f0, f1), "layer 7 has turned after 90 frames")
	check(edge_lag(w.mm_inst) < 1e-4, "edge overlay follows every layer (lag %.6f)" % edge_lag(w.mm_inst))
	# NEGATIVE: the frame-0 copy (what EdgeOutline leaves without our loop) no longer matches the turned face.
	var stale := Transform3D(f1.basis.scaled(Vector3.ONE * 1.003), f1.origin)
	check(not basis_close(e0, stale), "negative: a dress-time copy would lag the turned layer (the check bites)")
	var baked_w := 0
	for ch in w.get_children(): if ch is MultiMeshInstance3D and ch != w.mm_inst: baked_w += 1
	check(baked_w == 0, "white_edges removes the 32-sided baked twin")
	var prisms := 0
	for b in w._collider_bodies: if b.get_child(0).shape is ConvexPolygonShape3D and (b.get_child(0).shape as ConvexPolygonShape3D).points.size() <= 14: prisms += 1
	check(prisms == 8, "colliders are 6-sided prisms (12 corners + 2 cap centres), not circles")
	w.queue_free()

	print("-- segments_step: 18 stepping -2 (round slow base, square fast top)")
	var s := cake({"profile": "flare", "gallery": "clean", "look": "white_edges", "radial_segments": 18, "segments_step": -2})
	await frames(30)
	var sides: Array = []
	for g in s._groups: sides.append((g.multimesh.mesh as CylinderMesh).radial_segments)
	check(sides == [18, 16, 14, 12, 10, 8, 6, 4], "per-layer sides %s" % str(sides))
	var lag := 0.0
	for g in s._groups: lag = maxf(lag, edge_lag(g))
	check(lag < 1e-4, "every group's edges follow its layer (lag %.6f)" % lag)
	s.queue_free()

	print("-- platonic:outline route (primitive_finish) on a default-sided carousel")
	var p := cake({"gallery": "clean"})
	EdgeOutline.outline(p, 25.0)
	await frames(60)
	check(overlay(p.mm_inst) != null and edge_lag(p.mm_inst) < 1e-4, "an outline attached from outside also follows the turn")
	p.queue_free()

	print("-- carousel_ring: own motion")
	var r := ring({"radius": 2.9})
	await frames(2)
	check(r.radius == 2.9 and r.height == 1.05 and r.speed == 0.12, "defaults: radius 2.9, height 1.05, speed 0.12")
	check(r.handle.has_method("pick_up") and r.handle.has_method("pointer_event"), "handle carries the pickable script")
	check(r.handle.collision_layer & 1 == 0 and r.rail.get_child_count() > 0, "handle off the body layer; rail has its edge overlay")
	var torus := r.rail.mesh as TorusMesh
	check(torus.ring_segments == 6, "rail tube has 6 facets")
	var a0: float = r.angle
	var b0: Vector3 = r.ball.global_transform.basis.y
	await frames(60)
	check(r.ball.global_transform.basis.y.distance_to(b0) > 0.1, "ball rolls (its own rotation changes)")
	await frames(60)
	var moved: float = r.angle - a0
	check(moved > 0.15 and moved < 0.35, "ball moves on its own: %.3f rad in 2 s (expect ~0.24)" % moved)
	check(r.off_ring(r.to_local(r.carriage.global_position)) < 1e-4, "ball centre on the ring")

	print("-- carousel_ring: XR-style grab (real pick_up / let_go with a stand-in hand)")
	var hand := FakeGrip.new()
	add_child(hand)
	hand.global_position = r.handle.global_position
	r.handle.pick_up(hand)
	await frames(2)
	check(r.handle.is_picked_up() and r.state == "held", "handle picked up -> ring state held")
	var start: float = r.angle
	var worst_off := 0.0
	var worst_y := 0.0
	var y0: float = r.carriage.position.y
	# The hand walks a wider, higher, wobbly circle: 1.6 rad ahead in 1 s. Only its angle may reach the ball.
	for i in 60:
		var a := start + 1.6 * float(i + 1) / 60.0
		hand.global_position = r.to_global(Vector3(sin(a) * 3.5, 1.5 + 0.2 * sin(i * 0.7), cos(a) * 3.5))
		await get_tree().physics_frame
		worst_off = maxf(worst_off, r.off_ring(r.carriage.position))
		worst_y = maxf(worst_y, absf(r.carriage.position.y - y0))
	await frames(2)
	var follow := absf(r.angle - (start + 1.6))
	check(follow < 0.06, "ball follows the hand's angle (miss %.3f rad)" % follow)
	check(worst_off < 1e-4 and worst_y < 1e-4, "ball stays ON the ring while dragged (off %.6f m, dy %.6f m)" % [worst_off, worst_y])
	r.handle.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await frames(1)
	check(r.state == "coast" and r.velocity > r.speed * 2.0, "release keeps momentum: %.2f rad/s > own %.2f" % [r.velocity, r.speed])
	await frames(900)
	check(r.state == "own" and is_equal_approx(r.velocity, r.speed), "after 15 s it is back to its own turn (%.3f)" % r.velocity)
	check(r.handle.global_position.distance_to(r.carriage.global_position) < 1e-3, "released handle returns to the ball")

	print("-- negative: a hand that has NOT grabbed moves nothing")
	var n0: float = r.angle
	for i in 60:
		hand.global_position = r.to_global(Vector3(sin(n0 + 3.0) * 3.5, 1.5, cos(n0 + 3.0) * 3.5))
		await get_tree().physics_frame
	check(absf((r.angle - n0) - 0.12) < 0.03, "ungrabbed: only own motion (%.3f rad in 1 s)" % (r.angle - n0))

	print("-- desktop left-drag path (hold_begin / hold_to / hold_end)")
	r.hold_begin(hand)
	var d0: float = r.angle
	for i in 30:
		var a := d0 - 0.9 * float(i + 1) / 30.0
		r.hold_to(r.to_global(Vector3(sin(a) * 2.0, 1.4, cos(a) * 2.0)))
		await get_tree().physics_frame
	check(absf(r.angle - (d0 - 0.9)) < 0.06, "drag backwards 0.9 rad: ball follows (miss %.3f)" % absf(r.angle - (d0 - 0.9)))
	r.hold_end(hand)
	check(r.velocity < 0.0, "thrown backwards: coasts backwards first (%.2f rad/s)" % r.velocity)
	r.queue_free()

func _shot() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.80, 0.82, 0.85)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.72)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new(); plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var fm := StandardMaterial3D.new(); fm.albedo_color = Color(0.55, 0.56, 0.58)
	floor_mesh.material_override = fm
	add_child(floor_mesh)
	var c := cake({"profile": "cake", "gallery": "clean", "base_speed": 0.3, "speed_multiplier": 1.0, "look": "white_edges", "radial_segments": 6, "motion_caption": "ALL EIGHT LAYERS / ONE SPEED"})
	c.scale = Vector3.ONE * 0.6
	var r := ring({"radius": 2.9, "start_angle": 35})
	var cam := Camera3D.new()
	add_child(cam)
	cam.position = Vector3(3.3, 2.0, 4.1)
	cam.look_at(Vector3(0.6, 1.25, 1.2))
	cam.current = true
	await frames(150)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/carousel_ring"))
	var path := ProjectSettings.globalize_path("res://ada_run/carousel_ring/carousel_ring.png")
	var err := get_viewport().get_texture().get_image().save_png(path)
	check(err == OK, "saved " + path)
