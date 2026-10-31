extends Node3D
## PICTURES OF STACKED 6-BALLS (Palle, 2026-10-31: "show me pictures of stacked 6-balls"). The playground ball in
## the bench's first stage - contact snapping, no grid: each ball let go against another snaps hub to hub out of
## the socket that faces it. Four arrangements on one floor, each ball placed as the hand would (a drop near the
## last one, then settle()), the support graph deciding what holds: a column of four, a 2 x 2 x 2 cube, a row of
## five with two on top, and a 3-2-1 stair. Three pictures: front, three-quarter, close.
## Writes ada_run/inventory/stacked_balls_{front,quarter,close}.png and stacked_balls.json.
## Run: godot --path . --xr-mode off --resolution 1600x1000 res://commons/testing/probe_stacked_balls.tscn

const Ball = preload("res://commons/artifacts/playground_kit/playground_ball.tscn")

var out_dir := ""
var balls: Array[Node3D] = []

func _ready() -> void:
	out_dir = ProjectSettings.globalize_path("res://ada_run/inventory");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-45, 35, 0);sun.light_energy = 1.2;sun.shadow_enabled = true;add_child(sun)
	var fill := DirectionalLight3D.new();fill.rotation_degrees = Vector3(-20, -120, 0);fill.light_energy = .35;add_child(fill)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	# the lattice under them: a grid at two hubs, as the page draws it
	var probe_ball: Node3D = Ball.instantiate();add_child(probe_ball);var hub: float = probe_ball.hub();probe_ball.queue_free()
	var pitch: float = 2 * hub
	var grid := MeshInstance3D.new();var im := ImmediateMesh.new();grid.mesh = im;var gm := StandardMaterial3D.new();gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;gm.albedo_color = Color("38bdf8", .35);gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;grid.material_override = gm
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-12, 13):
		im.surface_add_vertex(Vector3(i * pitch, .003, -12 * pitch));im.surface_add_vertex(Vector3(i * pitch, .003, 12 * pitch))
		im.surface_add_vertex(Vector3(-12 * pitch, .003, i * pitch));im.surface_add_vertex(Vector3(12 * pitch, .003, i * pitch))
	im.surface_end();add_child(grid)
	var report := {"hub": hub, "pitch": pitch, "arrangements": {}}
	# 1 - a column of four at x = -1.2: each let go a little above the last
	var col := _place(Vector3(-1.2, .3, 0), "pink")
	for i in 3:
		_place(col.global_position + Vector3(.01, 2 * hub + .08, .01), "pink")
		col = balls[-1]
	report.arrangements["column"] = _describe(balls.slice(0, 4))
	# 2 - a 2 x 2 x 2 cube at x = -0.4: a square, then four on top
	var n0 := balls.size()
	var c0 := _place(Vector3(-.4, .3, 0), "cyan")
	_place(c0.global_position + Vector3(2 * hub + .05, .05, 0), "cyan")
	_place(c0.global_position + Vector3(0, .05, 2 * hub + .05), "cyan")
	_place(c0.global_position + Vector3(2 * hub, .05, 2 * hub + .05), "cyan")
	for b in balls.slice(n0, n0 + 4):_place(b.global_position + Vector3(0, 2 * hub + .08, 0), "cyan")
	report.arrangements["cube"] = _describe(balls.slice(n0, n0 + 8))
	# 3 - a row of five with two on top at x = 0.6
	n0 = balls.size()
	var r0 := _place(Vector3(.6, .3, 0), "pale")
	for i in 4:_place(balls[-1].global_position + Vector3(2 * hub + .05, .05, 0), "pale")
	_place(balls[n0 + 1].global_position + Vector3(0, 2 * hub + .08, 0), "pink")
	_place(balls[n0 + 3].global_position + Vector3(0, 2 * hub + .08, 0), "pink")
	report.arrangements["row"] = _describe(balls.slice(n0, n0 + 7))
	# 4 - a 3-2-1 stair at z = 1.2: three on the floor, two on them, one on top - each on the ball below
	n0 = balls.size()
	var s0 := _place(Vector3(-.6, .3, 1.2), "steel")
	_place(s0.global_position + Vector3(2 * hub + .05, .05, 0), "steel")
	_place(balls[-1].global_position + Vector3(2 * hub + .05, .05, 0), "steel")
	_place(balls[n0].global_position + Vector3(0, 2 * hub + .08, 0), "pink")
	_place(balls[n0 + 1].global_position + Vector3(0, 2 * hub + .08, 0), "pink")
	_place(balls[n0 + 3].global_position + Vector3(0, 2 * hub + .08, 0), "cyan")
	report.arrangements["stair"] = _describe(balls.slice(n0, n0 + 6))
	for i in 20:
		await get_tree().physics_frame
	# every ball held, every neighbour exactly two hubs apart
	var held := 0;var pairs := 0;var touching := 0
	for b in balls:
		if b.on_grid and b.supported and b.freeze:held += 1
	for i in balls.size():
		for j in range(i + 1, balls.size()):
			var d: float = balls[i].global_position.distance_to(balls[j].global_position)
			if d < 2 * hub + .03:pairs += 1;touching += 1 if absf(d - 2 * hub) < 1e-4 else 0
	report["balls"] = balls.size();report["held"] = held;report["near_pairs"] = pairs;report["exact_pairs"] = touching
	var cam := Camera3D.new();add_child(cam);cam.current = true;cam.fov = 45
	var shots := {"front": [Vector3(0, 1.0, 3.4), Vector3(0, .35, .4)], "quarter": [Vector3(2.6, 1.6, 2.8), Vector3(-.1, .3, .5)], "close": [Vector3(-.4, .75, 1.3), Vector3(-.55, .2, .2)]}
	for k in shots:
		cam.transform = Transform3D(Basis(), shots[k][0]).looking_at(shots[k][1])
		for i in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out_dir.path_join("stacked_balls_%s.png" % k))
	var o := FileAccess.open(out_dir.path_join("stacked_balls.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_stacked_balls] %d balls, %d held, %d/%d neighbour pairs exactly two hubs apart" % [balls.size(), held, touching, pairs])
	get_tree().quit(0 if held == balls.size() and touching == pairs else 1)

## A ball let go at `at` in the contact stage: made, configured, settled - as the hand does it.
func _place(at: Vector3, colour: String) -> Node3D:
	var b: Node3D = Ball.instantiate()
	for k in {"snap_to": "contact", "colour": colour}:b.set_meta("config_%s" % k, {"snap_to": "contact", "colour": colour}[k])
	add_child(b);b.apply_grid_config({"snap_to": "contact", "colour": colour});b.global_position = at
	b.settle();balls.append(b);return b

func _describe(group: Array) -> Array:
	var out := []
	for b in group:out.append([snappedf(b.global_position.x, .001), snappedf(b.global_position.y, .001), snappedf(b.global_position.z, .001), b.supported])
	return out
