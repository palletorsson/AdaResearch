extends SceneTree
## Demo of the console's VISUALIZATION HOSTS — a row of desktop consoles, each
## hosting one canonical display type (monitor / cube space / 2D plan / specimen
## jar) with placeholder content, to show where the viz sits relative to the board.
##   godot --path . --xr-mode off --no-window --script res://commons/testing/test_console_viz.gd

const ConsoleScript = preload("res://commons/ui/control_console.gd")

var _root: Node3D
var _cam: Camera3D


func _initialize() -> void:
	_root = Node3D.new(); get_root().add_child(_root)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.40, 0.41, 0.44)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.73, 0.76); env.ambient_light_energy = 1.0
	var we := WorldEnvironment.new(); we.environment = env; _root.add_child(we)
	for r in [Vector3(-45, 30, 0), Vector3(-30, -45, 0)]:
		var l := DirectionalLight3D.new(); l.rotation_degrees = r
		l.light_energy = 1.0 if r.y == 30 else 0.5; _root.add_child(l)

	var specs := [
		["MONITOR", "monitor"], ["CUBE SPACE", "cube"],
		["2D PLAN", "plan"], ["SPECIMEN JAR", "jar"],
	]
	var x := -2.55
	for s in specs:
		_make_console(x, s[0], s[1])
		x += 1.7

	_cam = Camera3D.new(); _cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_root.add_child(_cam); _cam.current = true
	_run()


func _make_console(x: float, title: String, host: String) -> void:
	var c: Node3D = ConsoleScript.new()
	c.demo_title = title
	c.face_to_origin = true
	c.body_height = 0.40
	c.position = Vector3(x, 1.0, 0.0)
	_root.add_child(c)
	match host:
		"monitor": _fill_monitor(c.add_monitor(Vector2(0.8, 0.5)))
		"cube": _fill_cube(c.add_cube_space(0.8))
		"plan": _fill_plan(c.add_plan(Vector2(0.8, 0.6)))
		"jar": _fill_jar(c.add_specimen_jar(0.17, 0.5))


func _fill_monitor(content: Node3D) -> void:
	# Fake bar graph on the screen face (X-Y plane).
	var heights := [0.18, 0.30, 0.22, 0.36, 0.28, 0.40, 0.24]
	var x := -0.32
	for hgt in heights:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.06, hgt, 0.006)
		bar.mesh = bm
		bar.position = Vector3(x, -0.22 + hgt * 0.5, 0.0)
		bar.material_override = _emat(Color(0.30, 0.85, 1.0))
		content.add_child(bar)
		x += 0.095


func _fill_cube(content: Node3D) -> void:
	# A sphere + a few floating cubes inside the [-0.4, 0.4] volume.
	var sph := MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.13; sm.height = 0.26
	sph.mesh = sm
	sph.material_override = _emat(Color(1.0, 0.55, 0.2))
	content.add_child(sph)
	for p in [Vector3(0.28, 0.22, -0.2), Vector3(-0.25, -0.2, 0.24), Vector3(0.2, -0.28, 0.18)]:
		var cube := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(0.1, 0.1, 0.1)
		cube.mesh = bm; cube.position = p
		cube.material_override = _emat(Color(0.5, 0.9, 1.0))
		content.add_child(cube)


func _fill_plan(content: Node3D) -> void:
	# Dots + a path on the X-Z plane.
	var pts := [Vector3(-0.3, 0, -0.2), Vector3(-0.1, 0, 0.1), Vector3(0.15, 0, -0.05), Vector3(0.32, 0, 0.2)]
	for p in pts:
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new(); sm.radius = 0.025; sm.height = 0.05
		dot.mesh = sm; dot.position = p
		dot.material_override = _emat(Color(1.0, 0.8, 0.3))
		content.add_child(dot)
	for i in range(pts.size() - 1):
		var seg := MeshInstance3D.new()
		var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
		var bm := BoxMesh.new(); bm.size = Vector3((b - a).length(), 0.006, 0.012)
		seg.mesh = bm
		seg.position = (a + b) * 0.5
		seg.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
		seg.material_override = _emat(Color(0.4, 0.8, 1.0))
		content.add_child(seg)


func _fill_jar(content: Node3D) -> void:
	# A specimen — a small torus knot stand-in (torus) floating in the jar.
	var tor := MeshInstance3D.new()
	var tm := TorusMesh.new(); tm.inner_radius = 0.05; tm.outer_radius = 0.11
	tor.mesh = tm
	tor.rotation_degrees = Vector3(40, 0, 20)
	tor.material_override = _emat(Color(0.6, 1.0, 0.5))
	content.add_child(tor)


func _emat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 0.5
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _run() -> void:
	await process_frame
	await create_timer(1.0).timeout
	await process_frame
	var box := _aabb(_root)
	var focus := box.get_center(); var diag: float = maxf(0.5, box.size.length())
	_cam.size = diag * 0.62
	_cam.position = focus + Vector3(1.1, 0.5, 1.0).normalized() * diag * 1.5
	_cam.look_at(focus, Vector3.UP)
	await process_frame; await create_timer(0.2).timeout; await process_frame
	get_root().get_viewport().get_texture().get_image().save_png("user://console_viz.png")
	print("[viz] saved user://console_viz.png")
	quit()


func _aabb(node: Node) -> AABB:
	var box := AABB(); var first := true; var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			ab = (n as Node3D).global_transform * ab
			if first: box = ab; first = false
			else: box = box.merge(ab)
		for c in n.get_children(): stack.append(c)
	return box
