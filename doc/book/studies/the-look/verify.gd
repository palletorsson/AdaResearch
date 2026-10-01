extends "res://supplied/verify_tools.gd"
## Headless checks of the lesson The look. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json; the exit code is the number of checks that failed.
## No import step is needed: nothing here has a class_name. Headless draws no
## frames, so what the eye gets (every colour the lesson quotes) is measured by
## sheet.gd, with a window. Here: what look.gd builds, state by state, that it
## is the look supplied/look.gd gives, the place, and the guest.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const SCENE := "res://the_look.tscn"
const GUEST := "res://guests/the-look/"
const STEPS := ["0_engine_grey", "1_sky", "2_ambient_only", "3_sun_unturned", "4_sun_turned", "5_ground", "6_bodies", "7_energy", "8_palette"]
const ROLES := ["SKY", "GROUND", "BODY", "SECOND", "THIRD", "BONE", "LINE", "GHOST", "INK", "SHADE"]
const KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
	"pause": [KEY_SPACE], "drop": [KEY_M], "look": [KEY_V], "jump": [KEY_J], "switch_camera": [KEY_C],
}
const SUPPLIED := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd",
	"sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]
## The four pairs of the argument: [name, the body's colour, the ground's colour].
const PAIRS := [["lime on violet", "c6ff3d", "32188a"], ["hot pink on violet", "ff2e93", "32188a"], ["red on green", "ff0000", "009400"], ["grey on grey", "808080", "4d4d4d"]]

var scene: Node3D

func run() -> void:
	project()
	engine_defaults()
	await bare_scene()
	await states()
	await finished_look()
	await pairs()
	await switch()
	await place()
	await guest()
	records()
	check(errors.is_empty(), "Godot logged no error in the whole run: %s" % [errors])

# ---------------------------------------------------------------- helpers

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

## The scene, run with `source` as its script in place of look.gd.
func dress(source: String) -> Node3D:
	if scene != null and is_instance_valid(scene):
		scene.free()
	var script := GDScript.new()
	script.source_code = source
	var problem := script.reload()
	scene = load(SCENE).instantiate()
	if problem == OK:
		scene.set_script(script)
	else:
		scene.set_script(null)
		check(false, "a script made from the lesson's text compiles (error %d)" % problem)
	root.add_child(scene)
	await frames(2)
	return scene

func kinds(node: Node, kind: String) -> Array:
	return node.find_children("*", kind, true, false)

## What a state has built, read back from the scene.
func built(node: Node3D) -> Dictionary:
	var worlds := kinds(node, "WorldEnvironment")
	var suns := kinds(node, "DirectionalLight3D")
	var paints := []
	for body: String in ["Floor", "Box", "Sphere"]:
		var paint: Material = node.get_node(body).material_override
		if paint != null:
			paints.append(paint)
	return {"worlds": worlds.size(), "air": worlds[0].environment if not worlds.is_empty() else null,
		"suns": suns.size(), "sun": suns[0] if not suns.is_empty() else null, "paints": paints}

## The way a light travels, and how many degrees it stands above the horizon.
func travel(sun: DirectionalLight3D) -> Vector3:
	return -sun.global_basis.z

func degrees_up(sun: DirectionalLight3D) -> float:
	return rad_to_deg(asin(-travel(sun).y))

## The stored properties in which two objects of one kind are not alike.
func unlike(a: Object, b: Object, skip: Array = ["name", "script"]) -> Array:
	var out := []
	for property: Dictionary in a.get_property_list():
		if property["usage"] & PROPERTY_USAGE_STORAGE == 0 or skip.has(property["name"]):
			continue
		if a.get(property["name"]) != b.get(property["name"]):
			out.append(property["name"])
	return out

func stored(a: Object) -> int:
	var count := 0
	for property: Dictionary in a.get_property_list():
		if property["usage"] & PROPERTY_USAGE_STORAGE != 0:
			count += 1
	return count

func colour_is(paint: Material, colour: Color) -> bool:
	return paint is StandardMaterial3D and (paint as StandardMaterial3D).albedo_color.is_equal_approx(colour)

func luminance(c: Color) -> float:
	var linear := c.srgb_to_linear()
	return 0.2126 * linear.r + 0.7152 * linear.g + 0.0722 * linear.b

func contrast(a: Color, b: Color) -> float:
	var high := maxf(luminance(a), luminance(b))
	var low := minf(luminance(a), luminance(b))
	return snappedf((high + 0.05) / (low + 0.05), 0.01)

func hex(c: Color) -> String:
	return "#" + c.to_html(false)

## Whether something solid stands between a point and the sun, and what.
func shades(node: Node3D, sun: DirectionalLight3D, at: Vector3) -> String:
	var query := PhysicsRayQueryParameters3D.create(at, at - travel(sun) * 20.0)
	var hit := node.get_world_3d().direct_space_state.intersect_ray(query)
	return String((hit["collider"] as Node).name) if not hit.is_empty() else ""

func box_of(body: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var meshes := kinds(body, "MeshInstance3D")
	if body is MeshInstance3D:
		meshes.append(body)
	for part: MeshInstance3D in meshes:
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
	return box

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "The look" and ProjectSettings.get_setting("application/run/main_scene") == SCENE
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named The look, its main scene is the_look.tscn, its renderer Compatibility")
	var clear: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	check(clear.is_equal_approx(Color(0.3, 0.3, 0.3)) and not text_of("res://project.godot").contains("default_clear_color"),
		"project.godot sets no clear colour, so the background of an undressed scene is the engine's own grey: %s" % hex(clear))
	measured["the_engine's_clear_colour"] = hex(clear)
	var keys_ok := true
	for action: String in KEYS:
		var got := []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				got.append((event as InputEventKey).physical_keycode)
		keys_ok = keys_ok and got == KEYS[action]
	check(keys_ok, "the Input Map has the base's nine actions on their keys")
	var found := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):     # the editor writes one beside every script it has seen
			found.append(file)
	check(found == SUPPLIED, "supplied/ holds the base's 15 files: %s" % [found])
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://supplied/", GUEST]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	for step: String in STEPS:
		if RegEx.create_from_string("(?m)^ +\\S").search(text_of("res://steps/%s.gd" % step)) != null:
			spaced.append(step)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script declares a class_name, and the project lists no named class: nothing needs an import: %s" % [named])
	check(spaced.is_empty(), "every script, and every state of the lesson, is indented with tabs: %s" % [spaced])

## What Godot gives when nothing is said: the lesson's steps rest on these.
func engine_defaults() -> void:
	var air := Environment.new()
	check(air.background_mode == Environment.BG_CLEAR_COLOR and air.ambient_light_source == Environment.AMBIENT_SOURCE_BG and is_equal_approx(air.ambient_light_energy, 1.0),
		"a new Environment shows the clear colour as its background, takes its ambient light from the background, at energy 1")
	var sun := DirectionalLight3D.new()
	check(sun.rotation == Vector3.ZERO and (-sun.basis.z).is_equal_approx(Vector3(0, 0, -1)) and is_equal_approx(sun.light_energy, 1.0) and not sun.shadow_enabled,
		"a new DirectionalLight3D is not turned: it shines level, along (0, 0, -1), with energy 1 and no shadow")
	sun.free()
	var paint := StandardMaterial3D.new()
	check(is_equal_approx(paint.roughness, 1.0) and paint.metallic == 0.0 and paint.albedo_color == Color.WHITE, "a new StandardMaterial3D is white, with roughness 1 and no metal")
	check(Color("ff2e93").is_equal_approx(Color(1.0, 46 / 255.0, 147 / 255.0)), "Color(\"ff2e93\") is red 255, green 46, blue 147, each of 255")

# ---------------------------------------------------------------- the scene, undressed

func bare_scene() -> void:
	var file := text_of(SCENE)
	check(not file.contains("Material") and not file.contains("Light3D") and not file.contains("Environment") and not file.contains("Color("),
		"the_look.tscn holds no material, no light, no environment and no colour: the look is all in look.gd")
	var before := printed.size()
	var node := await dress(text_of("res://steps/0_engine_grey.gd"))
	var names := []
	for child in node.get_children():
		names.append(String(child.name))
	check(names == ["Floor", "Box", "Sphere", "Camera3D"] and printed.slice(before).has("ready, with 4 children"),
		"undressed, the scene has four children, %s, and prints `ready, with 4 children`" % [names])
	var solid := 0
	for body: String in ["Floor/FloorBody", "Box/BoxBody", "Sphere/SphereBody"]:
		if node.get_node_or_null(body) is StaticBody3D and node.get_node(body).get_child(0) is CollisionShape3D:
			solid += 1
	var unpainted := 0
	for body: String in ["Floor", "Box", "Sphere"]:
		var mesh: MeshInstance3D = node.get_node(body)
		if mesh.material_override == null and mesh.mesh.surface_get_material(0) == null:
			unpainted += 1
	check(solid == 3 and unpainted == 3, "the floor, the box and the sphere each have a collider and no material: %d solid, %d unpainted" % [solid, unpainted])
	var box := box_of(node.get_node("Box")).merge(box_of(node.get_node("Sphere")))
	check(is_zero_approx(box.position.y) and absf(box.size.x - 1.4) < 0.01 and is_equal_approx(box.size.z, 0.6) and is_equal_approx(box.size.y, 0.6),
		"the two bodies stand on the ground, 1.4 m wide, 0.6 m deep and 0.6 m high together: %s" % box.size.snappedf(0.01))

# ---------------------------------------------------------------- the lesson, state by state

func states() -> void:
	var before := errors.size()
	var seen := {}
	for step: String in STEPS:
		var node := await dress(text_of("res://steps/%s.gd" % step))
		seen[step] = built(node)
		# keep what the next state will free: copy the numbers out now
		var s: Dictionary = seen[step]
		s["sun_travel"] = travel(s["sun"]) if s["sun"] != null else Vector3.ZERO
		s["sun_up"] = degrees_up(s["sun"]) if s["sun"] != null else 0.0
		s["sun_energy"] = s["sun"].light_energy if s["sun"] != null else 0.0
		s["sun_shadow"] = s["sun"].shadow_enabled if s["sun"] != null else false
		s["air"] = (s["air"] as Environment).duplicate() if s["air"] != null else null
		var colours := []
		for paint: StandardMaterial3D in s["paints"]:
			colours.append(paint.albedo_color.to_html(false))
		s["colours"] = colours
	check(errors.size() == before, "the nine states of the lesson each ran with no error: %s" % [errors.slice(before)])
	var a: Dictionary = seen["0_engine_grey"]
	check(a["worlds"] == 0 and a["suns"] == 0 and a["paints"].is_empty(), "the engine's grey: no environment, no light, no material")
	a = seen["1_sky"]
	check(a["worlds"] == 1 and a["air"].background_mode == Environment.BG_COLOR and a["air"].background_color.is_equal_approx(Look.SKY)
		and a["air"].ambient_light_source == Environment.AMBIENT_SOURCE_BG and a["suns"] == 0,
		"a sky: one WorldEnvironment, its background SKY; nothing was said about the ambient light, so it comes from the background, in the sky's colour")
	a = seen["2_ambient_only"]
	check(a["air"].ambient_light_source == Environment.AMBIENT_SOURCE_COLOR and a["air"].ambient_light_color == Color.WHITE and is_equal_approx(a["air"].ambient_light_energy, 0.25) and a["suns"] == 0,
		"ambient only: the ambient light is white, of energy 0.25, and there is no sun")
	a = seen["3_sun_unturned"]
	check(a["suns"] == 1 and a["sun_travel"].is_equal_approx(Vector3(0, 0, -1)) and is_zero_approx(a["sun_up"]) and not a["sun_shadow"],
		"a sun, unturned: one DirectionalLight3D that travels along %s, %.1f degrees above the horizon: along the floor" % [a["sun_travel"].snappedf(0.001), a["sun_up"]])
	a = seen["4_sun_turned"]
	check(a["suns"] == 1 and a["sun_travel"].y < -0.6 and a["sun_shadow"] and is_equal_approx(a["sun_energy"], 1.0),
		"the sun turned: it travels along %s, %.1f degrees above the horizon, with shadows, its energy still 1" % [a["sun_travel"].snappedf(0.001), a["sun_up"]])
	measured["sun_travels_along"] = [snappedf(a["sun_travel"].x, 0.001), snappedf(a["sun_travel"].y, 0.001), snappedf(a["sun_travel"].z, 0.001)]
	measured["sun_degrees_above_the_horizon"] = snappedf(a["sun_up"], 0.1)
	a = seen["5_ground"]
	check(a["colours"] == ["32188a"] and seen["4_sun_turned"]["colours"].is_empty(), "the ground: one material, on the floor, in 32188a")
	a = seen["6_bodies"]
	check(a["colours"] == ["32188a", "c6ff3d", "22d9ff"] and is_equal_approx(a["sun_energy"], 1.0), "the bodies: three materials, the box c6ff3d, the sphere 22d9ff; the sun's energy still 1")
	a = seen["7_energy"]
	check(is_equal_approx(a["sun_energy"], 0.28) and a["colours"] == seen["6_bodies"]["colours"], "energy 0.28: the sun's energy is 0.28 and nothing else changed")
	var b: Dictionary = seen["8_palette"]
	check(b["colours"] == a["colours"] and unlike(a["air"], b["air"]).is_empty() and b["sun_travel"].is_equal_approx(a["sun_travel"]) and is_equal_approx(b["sun_energy"], a["sun_energy"]) and b["sun_shadow"] == a["sun_shadow"],
		"the palette by role: the script changed and the scene did not: same environment, same sun, same three colours")
	check(text_of("res://steps/8_palette.gd") == text_of("res://look.gd"), "the lesson's last state is look.gd, byte for byte")

# ---------------------------------------------------------------- the finished look

func finished_look() -> void:
	var own: Dictionary = (load("res://look.gd") as Script).get_script_constant_map()
	var theirs: Dictionary = (Look as Script).get_script_constant_map()
	var apart := []
	for role: String in ROLES:
		if not own.has(role) or own[role] != theirs[role]:
			apart.append(role)
	check(apart.is_empty(), "look.gd names the ten roles of supplied/look.gd with the same ten colours: %s" % [apart])
	var before := errors.size()
	var node: Node3D = load(SCENE).instantiate()     # the scene as the learner runs it, with look.gd
	root.add_child(node)
	await frames(180)
	check(errors.size() == before, "the_look.tscn ran 180 frames with look.gd and Godot logged no error: %s" % [errors.slice(before)])
	var state := built(node)
	var air: Environment = state["air"]
	var supplied_air := Look.studio_environment()
	check(state["worlds"] == 1 and air != null and unlike(air, supplied_air).is_empty(),
		"its environment is the supplied look's plain one, studio_environment(), in every stored property (%d compared): unlike in %s" % [stored(supplied_air), unlike(air, supplied_air) if air != null else ["no environment"]])
	var filter := unlike(Look.environment(), supplied_air)
	var fill := Look.fill()
	check(filter.size() > 0 and fill is DirectionalLight3D and not fill.shadow_enabled and fill.light_energy < 0.1 and Look.SHADOW_BLUR > 1.0,
		"over that the supplied look lays a filter for a scene that runs: environment() differs from the plain one in %d stored properties, %s; fill() is a second light of energy %.2f with no shadow; the sun's shadow edge is blurred by %.1f" % [filter.size(), filter, fill.light_energy, Look.SHADOW_BLUR])
	measured["the_filter_changes_of_the_environment"] = filter
	fill.free()
	var sun: DirectionalLight3D = state["sun"]
	var supplied_sun := Look.sun()
	check(state["suns"] == 1 and sun != null and unlike(sun, supplied_sun).is_empty(),
		"its sun is the supplied one in every stored property (%d compared): unlike in %s" % [stored(supplied_sun), unlike(sun, supplied_sun) if sun != null else ["no sun"]])
	check(sun != null and absf(degrees_up(sun) - 43.0) < 0.1 and travel(sun).x > 0.0 and travel(sun).z < 0.0,
		"the sun stands %.1f degrees above the horizon and its light travels to the right and away from the camera: %s" % [degrees_up(sun) if sun != null else 0.0, travel(sun).snappedf(0.001) if sun != null else Vector3.ZERO])
	supplied_sun.free()
	var paints: Array = state["paints"]
	var wrong := []
	var wanted := [Look.GROUND, Look.BODY, Look.SECOND]
	for i in paints.size():
		var same := unlike(paints[i], Look.paint(wanted[i]))
		if not same.is_empty():
			wrong.append([i, same])
	check(paints.size() == 3 and wrong.is_empty(), "the floor is painted as paint(GROUND), the box as paint(BODY), the sphere as paint(SECOND), in every stored property (%d compared): %s" % [stored(Look.paint(Look.BODY)), wrong])
	check(paints.size() == 3 and paints[0] != paints[1] and paints[1] != paints[2] and paints[0] != paints[2], "three bodies, three materials: none is shared")
	node.free()
	await frames(1)

# ---------------------------------------------------------------- the argument

## look.gd with two lines of its palette written again, as the lesson does it.
func with_pair(body: String, ground: String) -> String:
	var lines := text_of("res://look.gd").split("\n")
	for i in lines.size():
		if lines[i].begins_with("const GROUND :="):
			lines[i] = "const GROUND := Color(\"%s\")" % ground
		if lines[i].begins_with("const BODY :="):
			lines[i] = "const BODY := Color(\"%s\")" % body
	return "\n".join(lines)

func pairs() -> void:
	var carried := 0
	var table := {}
	for pair: Array in PAIRS:
		var node := await dress(with_pair(pair[1], pair[2]))
		var paints: Array = built(node)["paints"]
		if paints.size() == 3 and colour_is(paints[0], Color(pair[2])) and colour_is(paints[1], Color(pair[1])) and colour_is(paints[2], Look.SECOND):
			carried += 1
		table[pair[0]] = {"body_luminance": snappedf(luminance(Color(pair[1])), 0.0001), "ground_luminance": snappedf(luminance(Color(pair[2])), 0.0001)}
	check(carried == 4, "two lines of the palette changed, GROUND and BODY, and the floor and the box took the new colours while the sphere kept SECOND: %d of 4 pairs" % carried)
	measured["pairs"] = table
	# For the room: how two values stand against each other, as (L1 + 0.05) / (L2 + 0.05).
	measured["contrast_of_two_values"] = {
		"SHADE on GROUND": contrast(Look.SHADE, Look.GROUND), "SKY on GROUND": contrast(Look.SKY, Look.GROUND),
		"BODY on GROUND": contrast(Look.BODY, Look.GROUND), "BODY on SHADE": contrast(Look.BODY, Look.SHADE), "BODY on SKY": contrast(Look.BODY, Look.SKY),
	}
	var red := luminance(Color("ff0000"))
	var green := luminance(Color("009400"))
	check(absf(red - green) / red < 0.005, "the red ff0000 and the green 009400 have the same luminance within half a percent: %.4f and %.4f" % [red, green])
	check(luminance(Look.BODY) > 25.0 * luminance(Look.GROUND) and luminance(Color("808080")) < 3.0 * luminance(Color("4d4d4d")),
		"BODY has %.1f times the luminance of GROUND; the grey 808080 has %.1f times that of 4d4d4d" % [luminance(Look.BODY) / luminance(Look.GROUND), luminance(Color("808080")) / luminance(Color("4d4d4d"))])

# ---------------------------------------------------------------- the hall's switch

func switch() -> void:
	var lines := PackedStringArray()
	for line in text_of("res://look.gd").split("\n"):
		lines.append(line)
		if line.strip_edges() == "add_child(sun)":
			lines.append("\tsun.visible = false")
	var node := await dress("\n".join(lines))
	var state := built(node)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	node.add_child(marble)
	marble.drop(Vector3(-0.4, 1.5, 0.0))
	var rest := await settle(marble)
	check(state["suns"] == 1 and not state["sun"].visible and absf(rest.y - 0.7) < 0.01,
		"with `sun.visible = false` the sun is there and not shown, and a marble dropped on the box still rests on it, at %.2f m: the light went, the body stayed" % rest.y)
	marble.free()

# ---------------------------------------------------------------- the place

func place() -> void:
	if scene != null and is_instance_valid(scene):
		scene.free()
	var before := errors.size()
	var room: Node3D = load("res://place.tscn").instantiate()
	root.add_child(room)
	await frames(180)
	check(errors.size() == before, "place.tscn ran 180 frames and Godot logged no error: %s" % [errors.slice(before)])
	var walker: CharacterBody3D = room.get_node("Walker")
	var marble: RigidBody3D = room.get_node("Marble")
	var sun: DirectionalLight3D = kinds(room, "DirectionalLight3D")[0]
	var fixed: Camera3D = room.get_node("TheLook/Camera3D")
	check(fixed.current and not walker.get_node("Eyes").current, "the place opens on the scene's own camera, the walker in it")
	await press("switch_camera")
	check(walker.get_node("Eyes").current, "C: the view is the walker's eyes, 1.6 m up")
	await press("drop")
	var rest := await settle(marble)
	check(absf(rest.y - 0.7) < 0.01 and absf(rest.x + 0.4) < 0.05 and absf(rest.z) < 0.05, "M, from where the walker starts: the marble falls on the box and rests on its top, at %s" % rest.snappedf(0.01))
	measured["marble_on_the_box_m"] = snappedf(rest.y, 0.01)
	var how := await walk(walker, [Vector3(-1.4, 0, 1.2), Vector3(1.5, 0, 1.2), Vector3(1.5, 0, -1.2), Vector3(-1.4, 0, -1.2), Vector3(-1.4, 0, 0)])
	check(how == "arrived", "the walker walked once round the two bodies, 10.6 m: \"%s\"" % how)
	how = await walk(walker, [Vector3(-0.4, 0, 0)])
	var gap := -0.7 - walker.global_position.x
	check(how == "blocked" and absf(gap - 0.3) < 0.02, "it walked at the box and was stopped by it: \"%s\", its middle %.2f m from the box's face" % [how, gap])
	measured["walker_stopped_m_from_the_box"] = snappedf(gap, 0.01)
	how = await walk(walker, [Vector3(-1.4, 0, -1.2), Vector3(1.2, 0, -2.0), Vector3(0.1, 0, -0.6)])
	await physics_frames(2)
	var feet := shades(room, sun, walker.global_position + Vector3(0, 0.05, 0))
	var knees := shades(room, sun, walker.global_position + Vector3(0, 0.5, 0))
	var eyes := shades(room, sun, walker.get_node("Eyes").global_position)
	check(how == "arrived" and feet == "BoxBody" and knees == "" and eyes == "",
		"it stood where the box's shadow falls (\"%s\" at %s): the box is between its feet (0.05 m up) and the sun, and not between its knees (0.5 m up) or its eyes and the sun" % [how, walker.global_position.snappedf(0.01)])
	walker.stand_at(Vector3(-1.4, 0, 0))
	await physics_frames(3)      # the walker has left the spot before the marble is put there
	marble.drop(Vector3(0.05, 1.0, -0.45))
	rest = await settle(marble)
	check(absf(rest.y - 0.1) < 0.01 and shades(room, sun, rest) == "BoxBody" and shades(room, sun, rest + Vector3(0, 0.09, 0)) == "BoxBody",
		"a marble dropped there rests on the floor at %s, the whole of it in the box's shadow" % rest.snappedf(0.01))
	var low := Vector3.ZERO
	marble.drop(Vector3(1.3, 0.6, -1.0))
	low = await settle(marble)
	marble.drop(Vector3(1.3, 1.0, -1.0))
	rest = await settle(marble)
	check(low.y > 0.085 and low.y < rest.y and rest.y < 0.1, "on the floor a marble's middle rests a little under its radius of 0.1 m, and how much depends on the drop: %.3f m dropped from 0.6 m, %.3f m dropped from 1 m" % [low.y, rest.y])
	measured["marble_on_the_floor_m"] = {"dropped_from_0.6_m": snappedf(low.y, 0.001), "dropped_from_1_m": snappedf(rest.y, 0.001)}
	marble.drop(Vector3(0.4, 1.5, 0.0))
	rest = await settle(marble)
	var on_top := rest
	marble.drop(Vector3(0.45, 1.5, 0.0))
	rest = await settle(marble)
	check(absf(on_top.y - 0.7) < 0.01 and rest.y < 0.5, "a marble dropped exactly over the middle of the sphere stays on its top, at %.2f m; dropped 5 cm to the side it rolls off, and after ten seconds it is at %s" % [on_top.y, rest.snappedf(0.01)])
	measured["marble_dropped_5_cm_off_the_sphere's_middle_is_at"] = [snappedf(rest.x, 0.01), snappedf(rest.y, 0.01), snappedf(rest.z, 0.01)]
	room.free()
	await frames(1)

# ---------------------------------------------------------------- the guest

func guest() -> void:
	var needs := CheckGuest.outside(GUEST)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(GUEST).is_empty(), "the guest declares no class_name")
	var before := errors.size()
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var body: Node = load(GUEST + "the-look.tscn").instantiate()
	base.add_child(body)
	await frames(3)
	check(body is Node3D and errors.size() == before, "the guest's first node is a Node3D and it enters a room with no error")
	var box := box_of(body)
	check(is_zero_approx(box.position.y) and box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.get_center().x) < 0.01 and absf(box.get_center().z) < 0.01,
		"it stands on the ground at its own origin and fits the place: %.1f m wide, %.1f m deep, %.1f m high" % [box.size.x, box.size.z, box.size.y])
	var own: Dictionary = (load(GUEST + "the-look.gd") as Script).get_script_constant_map()
	check(own.get("BODY") == Look.BODY and own.get("SECOND") == Look.SECOND
		and unlike(body.get_node("Box").material_override, Look.paint(Look.BODY)).is_empty() and unlike(body.get_node("Sphere").material_override, Look.paint(Look.SECOND)).is_empty(),
		"it is the pair in the course's look: the box painted as paint(BODY), the sphere as paint(SECOND), the two colours written out in its own script")
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	base.add_child(marble)
	marble.drop(Vector3(-0.4, 1.5, 0.0))
	var rest := await settle(marble)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = Vector3(-0.4, 0, 2.0)
	base.add_child(walker)
	await physics_frames(20)
	var how := await walk(walker, [Vector3(-0.4, 0, 0)])
	check(absf(rest.y - 0.7) < 0.01 and how == "blocked", "a marble rests on the guest's box at %.2f m and a walker is stopped by it: \"%s\"" % [rest.y, how])
	base.free()
	await frames(1)

# ---------------------------------------------------------------- what was run once, elsewhere

## Two runs that need another project, the room. They were made once, in a
## scratch copy of my-room, and their results are kept in evidence/. These two
## checks read the records; they do not run the room again.
func records() -> void:
	var trial: Variant = JSON.parse_string(text_of("res://evidence/guest_trial.json"))
	var ok: bool = trial is Dictionary and trial.get("passed", false) and trial["measured"]["guest"] == "res://guests/the-look/the-look.tscn"
	check(ok, "as recorded in evidence/guest_trial.json: the room's own trial of this guest passed %d checks; the walk at the guest ended \"%s\", %.2f m from the middle of place %d" % [
		trial["checks_run"] if ok else 0, trial["measured"]["walk_ended"] if ok else "", trial["measured"]["metres_from_the_middle_of_the_place"] if ok else 0.0, trial["measured"]["place"] if ok else 0])
	if ok:
		measured["the_room's_trial_of_the_guest"] = trial["measured"]
	var look: Variant = JSON.parse_string(text_of("res://evidence/room_look_trial.json"))
	ok = look is Dictionary and look["read_back"]["sky_at_the_horizon"] == "#0d0620" and look["read_back"]["a_square"] == "#ff2e93" and look["read_back"]["its_edge"] == "#ff2e93" and look["read_back"]["errors"].is_empty()
	check(ok, "as recorded in evidence/room_look_trial.json: the room with SKY and SHADE exchanged in room_look.gd ran with no error; its sky read back 0d0620 at the horizon, a square ff2e93, and the edge of a number ff2e93")
	if ok:
		measured["the_room_with_two_roles_changed"] = look["read_back"]
