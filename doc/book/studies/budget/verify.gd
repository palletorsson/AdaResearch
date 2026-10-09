extends "res://supplied/verify_tools.gd"
## Headless checks of the kit base: every supplied part, the example guest and
## the demonstration. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.
## A kit replaces this file with its own, built on the same first line.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const WALKER := "res://supplied/walker.tscn"
const KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
	"pause": [KEY_SPACE], "drop": [KEY_M], "look": [KEY_V], "jump": [KEY_J], "switch_camera": [KEY_C],
}

## A fresh base with nothing in it but what a check adds.
func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

func walker_in(base: Node3D, at: Vector3) -> CharacterBody3D:
	var walker: CharacterBody3D = load(WALKER).instantiate()
	walker.position = at      # before add_child: a body is in the room from the step it is added
	base.add_child(walker)
	await physics_frames(20)
	return walker

## A box: `solid` gives it a collider, without one it is a mesh only.
func box(base: Node3D, size: Vector3, at: Vector3, solid: bool) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	body.mesh = mesh
	body.material_override = Look.paint(Look.THIRD) if solid else Look.ghost()
	base.add_child(body)
	body.position = at
	if solid:
		var wall := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		wall.add_child(collider)
		body.add_child(wall)
	return body

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func same_colour(a: Color, b: Color) -> bool:
	return a.is_equal_approx(b)

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## A file is whole on the disk once it is closed: close it before reading it back.
func write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func run() -> void:
	project()
	look()
	await base_scene()
	await marble()
	await mover()
	await segment_and_strip()
	await sweep_sheet()
	await walker_stands_and_walks()
	await walker_meets_bodies()
	await walker_keys()
	await guests()
	await demonstration()
	harness()

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Kit base" and ProjectSettings.get_setting("application/run/main_scene") == "res://base_demo.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Kit base, its main scene is base_demo.tscn, its renderer Compatibility")
	var keys_ok := true
	for action: String in KEYS:
		var got := []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				got.append((event as InputEventKey).physical_keycode)
		keys_ok = keys_ok and got == KEYS[action]
	check(keys_ok, "the Input Map has nine actions on their keys: the four moves on WASD and the arrows, pause on Space, drop on M, look on V, jump on J, switch_camera on C")
	var named := []
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			supplied.append(file)
		if file.ends_with(".gd") and RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of("res://supplied/" + file)) != null:
			named.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds 15 files: %s" % [supplied])
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script in supplied/ declares a class_name, and the project lists no named class: nothing needs an import")
	var spaced := []
	for folder: String in ["res://", "res://supplied/", "res://guests/example/"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".gd") and RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])

func look() -> void:
	var hexes := {"SKY": "ff2e93", "GROUND": "32188a", "BODY": "c6ff3d", "SECOND": "22d9ff", "THIRD": "ff8b1f", "BONE": "f4efe6", "LINE": "ffffff", "GHOST": "9b7bff", "INK": "ffffff", "SHADE": "0d0620"}
	var palette_ok := true
	var named: Dictionary = (Look as Script).get_script_constant_map()
	for role: String in hexes:
		palette_ok = palette_ok and (named[role] as Color).to_html(false) == hexes[role]
	check(palette_ok and Look.BODIES == [Look.BODY, Look.SECOND, Look.THIRD, Look.BONE], "look.gd names ten colours by role, with the values of the brief, and BODIES is BODY, SECOND, THIRD, BONE")
	var paint := Look.paint(Look.BODY)
	check(paint is StandardMaterial3D and same_colour(paint.albedo_color, Look.BODY) and is_equal_approx(paint.roughness, 0.8) and paint.metallic == 0.0 and Look.paint(Look.BODY) != paint,
		"paint(BODY) returns a new StandardMaterial3D with BODY as its albedo, roughness 0.8, no metal")
	var ghost := Look.ghost()
	check(same_colour(Color(ghost.albedo_color, 1.0), Look.GHOST) and ghost.albedo_color.a < 0.6 and ghost.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "ghost() returns GHOST, seen through: alpha %.2f" % ghost.albedo_color.a)
	var sky := Look.studio_environment()
	check(sky.background_mode == Environment.BG_COLOR and same_colour(sky.background_color, Look.SKY) and sky.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR
		and sky.tonemap_mode == Environment.TONE_MAPPER_LINEAR and not sky.glow_enabled and not sky.fog_enabled and not sky.adjustment_enabled,
		"studio_environment() has SKY as its flat background, a plain ambient light of energy %.2f, the linear tonemap, no glow, no fog, no adjustment" % sky.ambient_light_energy)
	var show := Look.environment()
	var gradient := show.sky.sky_material as ProceduralSkyMaterial if show.sky != null else null
	check(show.background_mode == Environment.BG_SKY and gradient != null and same_colour(gradient.sky_horizon_color, Look.SKY) and same_colour(gradient.sky_top_color, Look.SKY_TOP)
		and same_colour(gradient.ground_bottom_color, Look.GROUND) and show.tonemap_mode == Environment.TONE_MAPPER_LINEAR and not show.glow_enabled and not show.fog_enabled,
		"environment() is the sky of a running scene: SKY_TOP above, SKY at the horizon, GROUND below it, the linear tonemap, no glow and no fog")
	var fill := Look.fill()
	check(fill is DirectionalLight3D and not fill.shadow_enabled and fill.light_energy < Look.SUN_ENERGY, "fill() returns a weaker light than the sun, with no shadow")
	fill.free()
	var sun := Look.sun()
	check(sun is DirectionalLight3D and sun.shadow_enabled and is_equal_approx(sun.light_energy, Look.SUN_ENERGY) and sun.rotation.is_equal_approx(Look.SUN_TURN),
		"sun() returns a new DirectionalLight3D with shadows on, energy %.2f, %d degrees above the horizon" % [sun.light_energy, roundi(rad_to_deg(-Look.SUN_TURN.x))])
	sun.free()
	var label := Look.label("a")
	check(label.modulate == Look.INK and label.outline_modulate == Look.SHADE and label.text == "a", "label(text) returns a Label3D in INK with a SHADE edge")
	label.free()

func base_scene() -> void:
	var base := await world()
	var sky: WorldEnvironment = base.get_node_or_null("Look/Sky")
	var sun: DirectionalLight3D = base.get_node_or_null("Look/Sun")
	var ground: MeshInstance3D = base.get_node("Floor")
	check(sky != null and same_colour(sky.environment.background_color, Look.SKY), "base.tscn: when it runs, the node Look has made Sky, and the environment's background is SKY")
	check(ground.material_override is StandardMaterial3D and same_colour(ground.material_override.albedo_color, Look.GROUND), "base.tscn: the floor's material is GROUND")
	check(sun != null and sun.shadow_enabled and base.get_node("Camera3D").current and root.get_camera_3d() == base.get_node("Camera3D"),
		"base.tscn: Look has made Sun, with shadows; the fixed camera Camera3D is the current one")
	check(not text_of("res://supplied/base.tscn").contains("Color("), "base.tscn itself holds no colour: look.gd is the one place they are written")
	await close(base)

func marble() -> void:
	var base := await world()
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.position = Vector3(2.0, 0.1, 1.0)
	await physics_frames(30)
	check(marble.freeze and near(marble.position, Vector3(2.0, 0.1, 1.0)) and same_colour(marble.get_node("MeshInstance3D").material_override.albedo_color, Look.BONE),
		"marble.tscn waits, frozen, where it is put, painted BONE")
	marble.drop(Vector3(0.0, 1.5, 0.0))
	var on_floor := await settle(marble)
	check(absf(on_floor.y - 0.1) < 0.01, "drop(at) over the bare floor: the marble comes to rest with its middle at %.3f m" % on_floor.y)
	var guest: Node3D = load("res://guests/example/example.tscn").instantiate()
	base.add_child(guest)
	guest.position = Vector3(-1.0, 0.0, 0.0)
	var ghost := box(base, Vector3(0.5, 0.5, 0.5), Vector3(1.0, 0.25, 0.0), false)
	await frames(2)
	marble.drop(guest.global_position + Vector3(0.0, 1.5, 0.0))
	var on_box := await settle(marble)
	check(absf(on_box.y - 0.6) < 0.01 and flat(on_box - guest.global_position).length() < 0.25, "dropped over the example guest, a box of 0.5 m with a collider, it rests on top, at %.3f m" % on_box.y)
	marble.drop(ghost.global_position + Vector3(0.0, 1.5, 0.0))
	var through := await settle(marble)
	check(absf(through.y - 0.1) < 0.01 and flat(through - ghost.global_position).length() < 0.2, "dropped over a box of the same size with no collider, it falls through the mesh to the floor: %.3f m" % through.y)
	measured["marble"] = {"on_the_floor_m": snappedf(on_floor.y, 0.001), "on_the_example_guest_m": snappedf(on_box.y, 0.001), "through_a_mesh_with_no_collider_m": snappedf(through.y, 0.001)}
	await close(base)

func mover() -> void:
	var base := await world()
	var hand := Node3D.new()
	hand.set_script(load("res://supplied/mover.gd"))
	base.add_child(hand)
	hand.position = Vector3(0.0, 1.0, 0.0)
	await frames(2)
	await hold("move_right", 30)
	var by_key := hand.position
	check(by_key.x > 0.3 and by_key.x < 0.9 and is_equal_approx(by_key.y, 1.0) and absf(by_key.z) < 0.001, "mover.gd: move_right held for half a second moves the hand %.2f m to the right, at its own height (speed 1.2 m/s)" % by_key.x)
	hand.speed = 40.0
	await hold("move_right", 30)
	await hold("move_backward", 30)
	check(is_equal_approx(hand.position.x, hand.area.x) and is_equal_approx(hand.position.z, hand.area.y), "it goes no further than `area` from the middle: it stops at %s" % [flat(hand.position)])
	hand.position = Vector3(0.0, 1.0, 0.0)
	hand.autopilot = true
	var furthest := 0.0
	for i in 120:
		await process_frame
		furthest = maxf(furthest, flat(hand.position).length())
	await hold("move_right", 10)
	check(furthest > 0.05 and is_equal_approx(hand.position.y, 1.0), "with autopilot ticked it moves by itself and does not listen to the keys: %.2f m from its start within 120 frames" % furthest)
	await close(base)

func segment_and_strip() -> void:
	var base := await world()
	var first: MeshInstance3D = load("res://supplied/segment.gd").new()
	var second: MeshInstance3D = load("res://supplied/segment.gd").new()
	base.add_child(first)
	base.add_child(second)
	var a := Vector3(-1.0, 1.0, 0.0)
	var b := Vector3(1.0, 2.0, 0.5)
	first.show_between(a, b)
	second.show_between(Vector3.ZERO, Vector3(0.0, 0.3, 0.0))
	var along: Vector3 = first.quaternion * Vector3.UP
	check(first.visible and near(first.position, (a + b) / 2.0) and is_equal_approx((first.mesh as CylinderMesh).height, (b - a).length()) and near(along, (b - a).normalized(), 0.001),
		"segment.gd: show_between(a, b) lays a cylinder from a to b: its middle between them, %.3f m long, turned along b - a" % (first.mesh as CylinderMesh).height)
	check(first.mesh != second.mesh and is_equal_approx((second.mesh as CylinderMesh).height, 0.3) and same_colour(first.mesh.material.albedo_color, Look.LINE),
		"two segments made in code have a cylinder each, in LINE: the second is 0.3 m long and the first kept its length")
	first.show_between(a, a)
	check(not first.visible, "two points in one place hide the segment")
	var strip: MeshInstance3D = load("res://supplied/trace_strip.gd").new()
	base.add_child(strip)
	await frames(1)
	var route: Array[Vector3] = [a, b, Vector3(1.0, 1.0, 1.0)]
	strip.draw(route)
	var drawn: int = strip.mesh.get_surface_count()
	var one: Array[Vector3] = [a]
	strip.draw(one)
	check(drawn == 1 and strip.mesh.get_surface_count() == 0 and same_colour(strip.material_override.albedo_color, Look.LINE), "trace_strip.gd: draw() of three positions draws one line strip in LINE; of one position, nothing")
	await close(base)

func sweep_sheet() -> void:
	var base := await world()
	var sheet: Node3D = load("res://supplied/sweep_sheet.tscn").instantiate()
	base.add_child(sheet)
	sheet.position = Vector3(-1.0, 0.0, 0.0)
	var balls := []
	for radius: float in [0.2, 0.3]:
		var ball := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		ball.mesh = mesh
		sheet.hang(ball, "%.1f m" % radius)
		balls.append(ball)
	var guest: Node3D = load("res://guests/example/example.tscn").instantiate()
	sheet.hang(guest, "a guest")
	await frames(1)
	check(near(balls[0].global_position, Vector3(-1.0, 0.2, 0.0)) and near(balls[1].global_position, Vector3(0.2, 0.3, 0.0)) and near(guest.global_position, Vector3(1.4, 0.0, 0.0)),
		"sweep_sheet: hang() stands members 1.2 m apart; a mesh is lifted until its lowest point is on the ground, another body stands where its origin is")
	check(sheet.hung.size() == 3 and sheet.plates[1].text == "0.3 m" and sheet.plates[1].modulate == Look.INK and balls[0].material_override == sheet.paint
		and same_colour(sheet.paint.albedo_color, Look.BODY) and same_colour(sheet.get_node("Paper").material_override.albedo_color, Look.SHADE),
		"it keeps what it hung and writes a plate for each in INK; a mesh with no material gets the sheet's paint, BODY; the paper is SHADE")
	await close(base)

func walker_stands_and_walks() -> void:
	var lines := text_of("res://supplied/walker.gd").split("\n").size() - 1
	var base := await world()
	var walker := await walker_in(base, Vector3(-3.0, 0.0, 1.5))
	var shape: CapsuleShape3D = walker.get_node("Shape").shape
	check(lines <= 150 and walker is CharacterBody3D and is_equal_approx(shape.height, 1.8) and is_equal_approx(shape.radius, 0.3) and is_equal_approx(walker.get_node("Eyes").position.y, 1.6)
		and same_colour(walker.get_node("Skin").material_override.albedo_color, Look.SECOND),
		"walker.tscn is a CharacterBody3D with a capsule 1.8 m high and 0.6 m wide, Eyes at 1.6 m and a Skin in SECOND; walker.gd has %d lines" % lines)
	check(walker.is_on_floor() and absf(walker.global_position.y) < 0.01, "put down on the floor it stands on it: its feet at %.3f m, is_on_floor() true" % walker.global_position.y)
	var start := Time.get_ticks_msec()
	var steps_before := Engine.get_physics_frames()
	var how := await walk(walker, [Vector3(3.0, 0.0, 1.5)])
	var steps := Engine.get_physics_frames() - steps_before
	check(how == "arrived" and flat(walker.global_position - Vector3(3.0, 0.0, 1.5)).length() < 0.1 and not walker.walking and walker.ended == "arrived",
		"walk_to() of a point 6 m across the floor: the walk ended \"%s\", %.2f m from the point, after %d steps of the physics (%.1f s at 2 m/s)" % [how, flat(walker.global_position - Vector3(3.0, 0.0, 1.5)).length(), steps, steps / 60.0])
	measured["walker_six_metres"] = {"ended": how, "physics_steps": steps, "milliseconds_of_this_run": Time.get_ticks_msec() - start}
	how = await walk(walker, [Vector3(3.0, 0.0, -1.5), Vector3(-3.0, 0.0, -1.5)])
	check(how == "arrived" and flat(walker.global_position - Vector3(-3.0, 0.0, -1.5)).length() < 0.1, "walk_to() of two points walks to the first, then to the second, and ends \"%s\" at the second" % how)
	walker.walk_to([Vector3(3.0, 0.0, -1.5)])
	await physics_frames(30)
	var moving: bool = walker.walking
	var told := []
	walker.walk_ended.connect(func(why: String) -> void: told.append(why), CONNECT_ONE_SHOT)
	walker.stop()
	await frames(2)
	check(moving and told == ["stopped"] and not walker.walking and walker.ended == "stopped", "stop() ends a walk on the way: walk_ended says \"stopped\"")
	walker.stand_at(Vector3(2.0, 0.0, 0.0))
	await physics_frames(10)
	how = await walk(walker, [Vector3(6.0, 0.0, 0.0)])
	check(how == "fell" and near(walker.global_position, Vector3(2.0, 0.0, 0.0), 0.05), "walk_to() of a point beyond the edge of the floor: it walks off, falls below -10 m, and the walk ends \"%s\" with the walker back where stand_at() put it" % how)
	how = await walk(walker, [])
	check(how == "arrived", "walk_to() of an empty list ends \"arrived\" at the next step, where it stands")
	await close(base)

func walker_meets_bodies() -> void:
	# A wall with a collider, and the same wall without one.
	var base := await world()
	box(base, Vector3(0.2, 1.0, 2.0), Vector3(0.0, 0.5, -1.0), true)
	box(base, Vector3(0.2, 1.0, 2.0), Vector3(0.0, 0.5, 1.2), false)
	var walker := await walker_in(base, Vector3(-2.0, 0.0, -1.0))
	var how := await walk(walker, [Vector3(2.0, 0.0, -1.0)])
	var stopped_at: float = walker.global_position.x
	check(how == "blocked" and absf(stopped_at - (-0.4)) < 0.05, "a wall that is a StaticBody3D stops it: the walk ended \"%s\" with its middle at x = %.3f, 0.3 m (its radius) before the wall's face at -0.1" % [how, stopped_at])
	walker.stand_at(Vector3(-2.0, 0.0, 1.2))
	await physics_frames(10)
	how = await walk(walker, [Vector3(2.0, 0.0, 1.2)])
	check(how == "arrived" and walker.global_position.x > 1.9, "the same wall as a mesh with no collider does not: the walk ended \"%s\" on the far side" % how)
	measured["walker_wall"] = {"with_a_collider": "blocked", "stopped_at_x_m": snappedf(stopped_at, 0.001), "with_no_collider": how}
	await close(base)
	# A step to stand on, and a platform that is only a mesh.
	base = await world()
	box(base, Vector3(1.0, 0.3, 1.0), Vector3(-1.5, 0.15, 0.0), true)
	box(base, Vector3(1.0, 0.3, 1.0), Vector3(1.5, 0.15, 0.0), false)
	walker = await walker_in(base, Vector3(-1.5, 0.8, 0.0))
	await physics_frames(60)
	var on_step: float = walker.global_position.y
	check(walker.is_on_floor() and absf(on_step - 0.3) < 0.01, "put down above a step that is a StaticBody3D, 0.3 m high, it lands and stands on it: feet at %.3f m" % on_step)
	walker.stand_at(Vector3(1.5, 0.8, 0.0))
	await physics_frames(60)
	var through: float = walker.global_position.y
	check(walker.is_on_floor() and absf(through) < 0.01, "put down above the same step as a mesh with no collider, it falls through it and stands on the floor: feet at %.3f m" % through)
	measured["walker_step"] = {"stands_on_a_static_body_at_m": snappedf(on_step, 0.001), "falls_through_a_mesh_to_m": snappedf(through, 0.001)}
	await close(base)
	# How high a step does it walk up? Measured, so that a later chapter can quote it.
	var climbed := {}
	for rise: float in [0.1, 0.18, 0.3, 0.6]:
		base = await world()
		box(base, Vector3(2.0, rise, 1.0), Vector3(1.0, rise / 2.0, 0.0), true)
		walker = await walker_in(base, Vector3(-1.5, 0.0, 0.0))
		how = await walk(walker, [Vector3(1.0, 0.0, 0.0)])
		climbed["%.2f m" % rise] = "%s, feet at %.2f m" % [how, walker.global_position.y]
		await close(base)
	check(climbed["0.10 m"] == "arrived, feet at 0.10 m" and climbed["0.18 m"] == "arrived, feet at 0.18 m" and climbed["0.30 m"] == "arrived, feet at 0.30 m" and climbed["0.60 m"] == "blocked, feet at 0.00 m",
		"it steps onto a StaticBody3D no higher than step_height, 0.35 m, and is stopped by a higher one: %s" % [climbed])
	var bare := {}
	for rise: float in [0.05, 0.1]:
		base = await world()
		box(base, Vector3(2.0, rise, 1.0), Vector3(1.0, rise / 2.0, 0.0), true)
		walker = await walker_in(base, Vector3(-1.5, 0.0, 0.0))
		walker.step_height = 0.0
		how = await walk(walker, [Vector3(1.0, 0.0, 0.0)])
		bare["%.2f m" % rise] = "%s, feet at %.2f m" % [how, walker.global_position.y]
		await close(base)
	check(bare["0.05 m"] == "arrived, feet at 0.05 m" and bare["0.10 m"] == "blocked, feet at 0.00 m", "with step_height at 0 the capsule alone rolls up 5 cm and is stopped by 10 cm: %s" % [bare])
	measured["walker_walks_up_a_step_of"] = {"step_height_0.35": climbed, "step_height_0": bare}
	# A stair of three steps, 0.18 m each, 0.4 m deep.
	base = await world()
	for i in 3:
		box(base, Vector3(0.4, 0.18 * (i + 1), 1.0), Vector3(0.2 + 0.4 * i, 0.09 * (i + 1), 0.0), true)
	box(base, Vector3(1.0, 0.54, 1.0), Vector3(1.7, 0.27, 0.0), true)
	walker = await walker_in(base, Vector3(-1.5, 0.0, 0.0))
	how = await walk(walker, [Vector3(1.7, 0.0, 0.0)])
	check(how == "arrived" and absf(walker.global_position.y - 0.54) < 0.01, "a stair of three steps of 0.18 m, each 0.4 m deep: the walk ended \"%s\" on top, feet at %.2f m" % [how, walker.global_position.y])
	measured["walker_stair_of_three"] = {"ended": how, "feet_at_m": snappedf(walker.global_position.y, 0.001)}
	await close(base)
	# The example guest, 0.5 m high, and the marble in its way.
	base = await world()
	var guest: Node3D = load("res://guests/example/example.tscn").instantiate()
	base.add_child(guest)
	guest.position = Vector3(0.0, 0.0, -1.0)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.drop(Vector3(0.0, 0.5, 1.0))
	await settle(marble)
	walker = await walker_in(base, Vector3(-2.0, 0.0, -1.0))
	how = await walk(walker, [guest.global_position])
	var gap: float = flat(walker.global_position - guest.global_position).length()
	check(how == "blocked" and absf(gap - 0.55) < 0.05 and absf(walker.global_position.y) < 0.01, "walked at the example guest, a box 0.5 m high, it is stopped by the box's collider: \"%s\", its middle %.2f m from the guest's (0.25 m of box and 0.3 m of walker)" % [how, gap])
	walker.stand_at(Vector3(-2.0, 0.0, 1.0))
	await physics_frames(10)
	how = await walk(walker, [Vector3(2.0, 0.0, 1.0)])
	var marble_at: Vector3 = marble.global_position
	measured["walker_meets_marble"] = {"ended": how, "marble_went_from": [0.0, 0.1, 1.0], "marble_went_to": [snappedf(marble_at.x, 0.01), snappedf(marble_at.y, 0.01), snappedf(marble_at.z, 0.01)]}
	check(how == "arrived" and flat(marble_at - Vector3(0.0, 0.0, 1.0)).length() > 0.5, "a marble lying in its way does not stop it: the walk ended \"%s\" and the marble, kicked along, lies at %s" % [how, measured["walker_meets_marble"]["marble_went_to"]])
	await close(base)
	# A place with no gravity: the walker asks the place for its gravity, and a walk still ends.
	base = await world()
	var region := Area3D.new()
	region.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	region.gravity = 0.0
	var extent := CollisionShape3D.new()
	var room := BoxShape3D.new()
	room.size = Vector3(8.0, 6.0, 5.0)
	extent.shape = room
	region.add_child(extent)
	base.add_child(region)
	walker = await walker_in(base, Vector3(-1.0, 1.0, 0.0))
	walker.stand_at(Vector3(-1.0, 1.0, 0.0))   # again, still: the region took a step to find it, and it fell meanwhile
	await physics_frames(60)
	var hovers: float = walker.global_position.y
	how = await walk(walker, [Vector3(1.0, 0.0, 0.0)])
	check(absf(hovers - 1.0) < 0.01 and how == "blocked" and absf(walker.global_position.x - 1.0) < 0.1 and absf(walker.global_position.y - 1.0) < 0.01,
		"in an Area3D that sets gravity to zero it does not fall: put down 1 m up it stays at %.2f m, and a walk to a point ends \"%s\" over the point, never having landed" % [hovers, how])
	measured["walker_in_zero_gravity"] = {"height_after_one_second_m": snappedf(hovers, 0.001), "walk_ended": how}
	await close(base)

func walker_keys() -> void:
	var base := await world()
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.0))
	await hold("move_forward", 60)
	var forward: Vector3 = walker.global_position
	check(absf(forward.z - 0.0) < 0.15 and absf(forward.x) < 0.01, "move_forward held for 60 steps walks it 2 m the way it faces, towards -z: from z = 2 to z = %.2f" % forward.z)
	await press("jump")
	var top := 0.0
	for i in 60:
		await physics_frame
		top = maxf(top, walker.global_position.y)
	check(top > 0.5 and walker.is_on_floor(), "jump lifts it %.2f m and it lands again" % top)
	measured["walker_jump_height_m"] = snappedf(top, 0.01)
	var fixed: Camera3D = base.get_node("Camera3D")
	var eyes: Camera3D = walker.get_node("Eyes")
	var first := root.get_camera_3d()
	await press("switch_camera")
	var second := root.get_camera_3d()
	await press("switch_camera")
	check(first == fixed and second == eyes and root.get_camera_3d() == fixed, "switch_camera changes the view from the fixed camera to the walker's Eyes, and back")
	var turn_before: float = walker.rotation.y
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100.0, 50.0)
	Input.parse_input_event(motion)
	await frames(3)
	var unheld: float = walker.rotation.y
	Input.action_press("look")
	Input.parse_input_event(motion.duplicate())
	await frames(3)
	Input.action_release("look")
	check(is_equal_approx(unheld, turn_before) and absf(walker.rotation.y - (turn_before - 0.3)) < 0.001 and absf(eyes.rotation.x - (-0.15)) < 0.001 and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,
		"the mouse turns it only while look is held: 100 pixels to the right turn the body %.2f rad, 50 down tilt the Eyes %.2f rad; the mouse is not captured" % [walker.rotation.y - turn_before, eyes.rotation.x])
	walker.keys = false
	var before: Vector3 = walker.global_position
	await hold("move_forward", 30)
	check(near(walker.global_position, before, 0.001), "with `keys` unticked it does not listen to the keys")
	var how := await walk(walker, [Vector3(1.0, 0.0, 1.0)])
	check(how == "arrived", "and walk_to() still walks it: \"%s\"" % how)
	await close(base)
	base = await world()
	walker = load(WALKER).instantiate()
	walker.through_eyes = true
	base.add_child(walker)
	await frames(2)
	check(root.get_camera_3d() == walker.get_node("Eyes"), "with `through_eyes` ticked the scene starts looking through the walker's Eyes")
	await close(base)

func guests() -> void:
	var example := "res://guests/example/"
	var needs := CheckGuest.outside(example)
	check(needs.is_empty() and CheckGuest.class_names(example).is_empty(), "check_guest: outside(\"res://guests/example/\") is empty and the folder declares no class_name: %s" % [needs])
	var base := await world()
	var guest: Node3D = load(example + "example.tscn").instantiate()
	base.add_child(guest)
	await frames(2)
	var meshes := guest.find_children("*", "MeshInstance3D", true, false)
	var bodies := guest.find_children("*", "StaticBody3D", true, false)
	var size: AABB = meshes[0].global_transform * meshes[0].get_aabb()
	check(guest is Node3D and meshes.size() == 1 and bodies.size() == 1 and absf(size.position.y) < 0.001 and size.size.x <= 1.6 and size.size.z <= 1.6 and same_colour(meshes[0].material_override.albedo_color, Look.BODY),
		"the example guest loads: one mesh in BODY, %s m, its lowest point on the ground at its own origin, one StaticBody3D" % [size.size])
	await close(base)
	# A guest that reaches outside its folder, made in user://.
	var leaky := "user://guests/leaky/"
	DirAccess.make_dir_recursive_absolute(leaky)
	write(leaky + "leaky.gd", "class_name Leaky\nextends Node3D\n\nconst Marble := preload(\"res://supplied/marble.gd\")\n\nfunc _ready() -> void:\n\tvar probe := Marble.new()\n\tprint(\"leaky: made a \", probe.get_class())\n\tprobe.free()\n")
	write(leaky + "leaky.tscn", "[gd_scene load_steps=2 format=3]\n\n[ext_resource type=\"Script\" path=\"user://guests/leaky/leaky.gd\" id=\"Guest\"]\n\n[node name=\"Leaky\" type=\"Node3D\"]\nscript = ExtResource(\"Guest\")\n")
	needs = CheckGuest.outside(leaky)
	var declared := CheckGuest.class_names(leaky)
	var errors_before := errors.size()
	var loaded: Node = load(leaky + "leaky.tscn").instantiate()
	root.add_child(loaded)
	await frames(2)
	check(needs == ["res://supplied/marble.gd"], "a guest whose script preloads res://supplied/marble.gd: outside() returns %s" % [needs])
	check(printed.has("leaky: made a RigidBody3D") and errors.size() == errors_before, "that guest loads and runs here all the same, with no error, because this project has supplied/: the check sees what a run does not")
	check(declared == ["Leaky"], "class_names() lists the class_name it declares: %s" % [declared])
	loaded.free()
	errors_before = errors.size()
	var missing := CheckGuest.outside("res://guests/nobody/")
	check(missing == ["no scene at res://guests/nobody/nobody.tscn"] and errors.size() == errors_before, "a folder that is not there, or has no scene of its own name, gives one line and no error: %s" % [missing])
	DirAccess.remove_absolute(leaky + "leaky.gd")
	DirAccess.remove_absolute(leaky + "leaky.tscn")
	DirAccess.remove_absolute(leaky)
	DirAccess.remove_absolute("user://guests")

func demonstration() -> void:
	var errors_before := errors.size()
	var demo: Node3D = load("res://base_demo.tscn").instantiate()
	root.add_child(demo)
	await frames(180)
	var walker: CharacterBody3D = demo.get_node("Walker")
	if walker.walking:
		await walker.walk_ended
	var marble_at := await settle(demo.get_node("Marble"))
	check(errors.size() == errors_before, "base_demo.tscn runs 180 frames and Godot logs no error: %s" % [errors.slice(errors_before)])
	check(demo.walk == "arrived" and flat(walker.global_position - Vector3(3.0, 0.0, -1.5)).length() < 0.1, "in it the walker walks along the front of the floor and to the back on its autopilot, three points, and arrives")
	check(absf(marble_at.y - 0.6) < 0.01, "the marble lies on the example guest, at %.2f m" % marble_at.y)
	check(demo.get_node("Segment").visible and demo.trace.size() > 2 and demo.get_node("Strip").mesh.get_surface_count() == 1 and demo.get_node("Sheet").hung.size() == 2,
		"the segment joins A and the Hand, the Hand's trace has %d positions, two balls hang on the sheet" % demo.trace.size())
	await press("drop")
	check(not demo.get_node("Marble").sleeping and demo.get_node("Marble").global_position.y > 1.0, "M drops the marble again, from 1.5 m above the guest")
	await close(demo)

func harness() -> void:
	var errors_before := errors.size()
	var warnings_before := warnings.size()
	push_error("an error made on purpose")
	push_warning("a warning made on purpose")
	print("a line printed on purpose")
	check(errors.size() == errors_before + 1 and errors[-1] == "ERROR: an error made on purpose" and warnings.size() == warnings_before + 1 and printed.has("a line printed on purpose"),
		"verify_tools: `errors`, `warnings` and `printed` hold what Godot logged: an error, a warning and a line made on purpose are there")
	var failed := write_result("user://verification_try.json")
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://verification_try.json"))
	check(record.has("passed") and record["passed"] is bool and record["checks"] is Array and record["checks"].size() == checks.size() and record["checks"][0].has("name") and record["checks"][0].has("passed") and int(record["checks_failed"]) == failed,
		"write_result() writes a file with a top-level `passed`, and `checks`, a list of %d with `name` and `passed`; finish() writes verification.json the same way" % checks.size())
	DirAccess.remove_absolute("user://verification_try.json")
