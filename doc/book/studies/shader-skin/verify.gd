extends "res://supplied/verify_tools.gd"
## Headless checks of the Shader skin kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so no check here looks at a pixel: what the skin
## looks like is measured by sheet.gd, with a window. What a headless run CAN
## see: whether the shader language accepts a shader (Godot 4.6 reads the code
## without a graphics card and logs the same SHADER ERROR), which uniforms a
## shader declares, and what a material was handed, read back.

const Look := preload("res://supplied/look.gd")
const Member := preload("res://parts/member.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const UNIFORMS := ["body_colour", "band_colour", "bands", "softness", "drift", "grain", "rim_colour", "rim_power"]
const STEPS := {"1_uv": 0, "2_step": 2, "3_bands": 5, "4_grain": 6, "5_picture": 7}
const SUPPLIED := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd",
	"sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]

func run() -> void:
	project()
	await shaders()
	await member()
	await scene()
	await axis()
	await faults()
	await a_body()
	await guest()

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func same_colour(a: Variant, b: Color) -> bool:
	return a is Color and (a as Color).is_equal_approx(b)

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## The names of a shader's uniforms, in the order it declares them.
func uniforms_of(shader: Shader) -> Array:
	var names := []
	for entry: Dictionary in shader.get_shader_uniform_list():
		names.append(entry["name"])
	return names

## The sampler2D uniforms of a material's shader that nothing was bound to.
func unbound(material: ShaderMaterial) -> Array:
	var names := []
	for entry: Dictionary in material.shader.get_shader_uniform_list():
		if entry["hint_string"] == "Texture2D" and not material.get_shader_parameter(entry["name"]) is Texture2D:
			names.append(entry["name"])
	return names

## What Godot logs when a shader is put on a material: the shader is read then.
func refused(shader: Shader) -> Array:
	var before := errors.size()
	var material := ShaderMaterial.new()
	material.shader = shader
	await frames(2)
	return errors.slice(before)

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Shader skin" and ProjectSettings.get_setting("application/run/main_scene") == "res://shader_skin.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Shader skin, its main scene is shader_skin.tscn, its renderer Compatibility")
	check(InputMap.has_action("pause") and (InputMap.action_get_events("pause")[0] as InputEventKey).physical_keycode == KEY_SPACE, "the action pause is on Space: the key that steps the rim's exponent")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):
			supplied.append(file)
	check(supplied == SUPPLIED, "supplied/ holds the base's 15 files: %s" % [supplied])
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://parts/", "res://steps/", "res://guests/shader-skin/"]:
		for file in DirAccess.get_files_at(folder):
			if not (file.ends_with(".gd") or file.ends_with(".gdshader")):
				continue
			var text := text_of(folder + file)
			if file.ends_with(".gd") and RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text) != null or text.contains("\r"):
				spaced.append(file)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script of the kit declares a class_name, and the project lists no named class: nothing needs an import (%s)" % [named])
	check(spaced.is_empty(), "every script and every shader of the kit is indented with tabs and ends its lines with LF: %s" % [spaced])

func shaders() -> void:
	var skin: Shader = load("res://skin.gdshader")
	var said := await refused(skin)
	check(said.is_empty(), "skin.gdshader is accepted by the shader language: Godot logged nothing when it was put on a material (%s)" % [said])
	check(text_of("res://skin.gdshader").begins_with("shader_type spatial;"), "it begins with shader_type spatial;")
	check(uniforms_of(skin) == UNIFORMS, "it declares eight uniforms, in this order: %s" % [uniforms_of(skin)])
	var range_ok := false
	for entry: Dictionary in skin.get_shader_uniform_list():
		if entry["name"] == "rim_power":
			range_ok = entry["type"] == TYPE_FLOAT and entry["hint"] == PROPERTY_HINT_RANGE and str(entry["hint_string"]).begins_with("0.25,8.0")
	check(range_ok, "rim_power is a float with hint_range(0.25, 8.0)")
	var code := text_of("res://skin.gdshader")
	check(code.contains("dot(NORMAL, VIEW)") and code.contains("pow(1.0 - facing, rim_power)") and code.contains("EMISSION = rim_colour"), "its rim is pow(1.0 - dot(NORMAL, VIEW), rim_power), written into EMISSION")
	check(code.contains("smoothstep(") and code.contains("sin(") and code.contains("fbm(UV") and code.contains("TIME * drift"), "its fragment() uses sin and smoothstep over UV, fbm over UV, and TIME")
	check(not code.contains("sampler2D"), "it declares no sampler2D: the skin is computed and needs no picture")
	var counts := {}
	var quiet := true
	for step: String in STEPS:
		var shader: Shader = load("res://steps/%s.gdshader" % step)
		quiet = quiet and (await refused(shader)).is_empty()
		counts[step] = uniforms_of(shader).size()
	check(quiet and counts == STEPS, "the five earlier states of the shader in steps/ are accepted too, with 0, 2, 5, 6 and 7 uniforms: %s" % [counts])
	measured["uniforms"] = uniforms_of(skin)

func member() -> void:
	var body: MeshInstance3D = Member.make(64)
	root.add_child(body)
	await frames(2)
	var sphere := body.mesh as SphereMesh
	check(sphere != null and sphere.radial_segments == 64 and sphere.rings == 32 and is_equal_approx(sphere.radius, 0.5), "the borrowed member is a sphere of 1 m with 64 segments and 32 rings")
	var box: AABB = body.global_transform * body.get_aabb()
	check(absf(box.position.y) < 0.001 and absf(box.end.y - 1.0) < 0.001, "it stands on the ground: from %.2f m to %.2f m" % [box.position.y, box.end.y])
	check(body.material_override == null and body.get_node("Body/CollisionShape3D").shape is SphereShape3D, "it brings no material, and a collider: a sphere of the same size")
	check(is_equal_approx(body.rotation.y, PI), "it is turned half round: the seam of its UV is at the back")
	var least: MeshInstance3D = Member.make(2)
	var most: MeshInstance3D = Member.make(200)
	check((least.mesh as SphereMesh).radial_segments == 4 and (most.mesh as SphereMesh).radial_segments == 64, "make() keeps the segments between 4 and 64")
	least.free()
	most.free()
	body.free()
	await frames(1)

func scene() -> void:
	var before := errors.size()
	var warned := warnings.size()
	var study: Node3D = load("res://shader_skin.tscn").instantiate()
	root.add_child(study)
	await frames(180)
	check(errors.size() == before and warnings.size() == warned, "shader_skin.tscn ran 180 frames and Godot logged no error and no warning: %s %s" % [errors.slice(before), warnings.slice(warned)])
	check(printed.has("the member wears ShaderMaterial with 8 uniforms; rim_power 3.0"), "it printed: the member wears ShaderMaterial with 8 uniforms; rim_power 3.0")
	var skin: Node3D = study.get_node("Skin")
	var body := skin.get_node_or_null("Member") as MeshInstance3D
	check(body != null and body.material_override is ShaderMaterial and body.material_override == skin.material, "Skin holds the member, and the member wears Skin's one ShaderMaterial")
	var material: ShaderMaterial = skin.material
	check(material.shader != null and material.shader.resource_path == "res://skin.gdshader", "the material's shader is skin.gdshader")
	check(same_colour(material.get_shader_parameter("body_colour"), Look.BODY) and same_colour(material.get_shader_parameter("band_colour"), Look.SHADE) and same_colour(material.get_shader_parameter("rim_colour"), Look.SECOND),
		"the script handed the shader three colours of the palette, read back: body_colour BODY, band_colour SHADE, rim_colour SECOND (%s, %s, %s)" % [
		material.get_shader_parameter("body_colour"), material.get_shader_parameter("band_colour"), material.get_shader_parameter("rim_colour")])
	check(material.get_shader_parameter("rim_power") == 3.0 and material.get_shader_parameter("drift") == skin.drift, "and two numbers: rim_power 3.0 and drift %s" % [material.get_shader_parameter("drift")])
	check(material.get_shader_parameter("bands") == null and material.get_shader_parameter("grain") == null, "bands, softness and grain were not handed over: the shader uses its own defaults for them")
	check(unbound(material).is_empty(), "no sampler2D of the shader is left unbound: %s" % [unbound(material)])
	check(study.get_node("Walker") is CharacterBody3D and study.get_node("Readout") is Label3D, "the scene has the supplied walker and the readout beside the skin")
	check(str(study.get_node("Readout").text).begins_with("rim exponent 3.0"), "the readout says: rim exponent 3.0")
	# Space steps the exponent: 3, 8, 0.5, 1, 3.
	var walked := []
	for i in 4:
		await press("pause")
		walked.append(material.get_shader_parameter("rim_power"))
	check(walked == [8.0, 0.5, 1.0, 3.0] and skin.rim_power == 3.0, "Space steps the exponent through 8, 0.5, 1 and back to 3, and the material is handed each: %s" % [walked])
	check(printed.has("rim_power 8.0") and printed.has("rim_power 0.5"), "and each step is printed")
	study.free()
	await frames(1)

## The axis: one exported number, four values, each read back from the material.
func axis() -> void:
	var read := []
	for power: float in [0.5, 1.0, 3.0, 8.0]:
		var skin: Node3D = load("res://shader_skin.gd").new()
		skin.rim_power = power
		root.add_child(skin)
		await frames(1)
		read.append(skin.material.get_shader_parameter("rim_power"))
		skin.free()
	check(read == [0.5, 1.0, 3.0, 8.0], "four bodies made with rim_power 0.5, 1, 3 and 8 each handed that number to their own material: %s" % [read])
	var list: Array = load("res://shader_skin.gd").get_script_constant_map()["POWERS"]
	check(list == [0.5, 1.0, 3.0, 8.0], "POWERS is the axis: %s" % [list])
	# The arithmetic of the rim, for the lesson's table: where on the disc is the rim above one tenth?
	var reach := {}
	for power: float in [0.5, 1.0, 3.0, 8.0]:
		var facing := 1.0 - pow(0.1, 1.0 / power)       # pow(1 - facing, power) = 0.1
		reach["p %s" % power] = snappedf(sqrt(1.0 - facing * facing), 0.01)   # that far from the middle, of the radius
	measured["rim_is_a_tenth_at_of_radius"] = reach

## The faults the lesson names, each made here and seen.
func faults() -> void:
	# 6 for 6.0: the shader language multiplies a float by a float only.
	var whole := Shader.new()
	whole.code = "shader_type spatial;\n\nvoid fragment() {\n\tfloat wave = 0.5 + 0.5 * sin(UV.y * 6 * TAU);\n\tALBEDO = vec3(wave);\n}\n"
	var said := await refused(whole)
	check(said.size() == 2 and said[0].begins_with("SHADER ERROR: Invalid arguments to operator '*': 'float, int'.") and said[1] == "ERROR: Shader compilation failed.",
		"a 6 where the shader wants 6.0 is refused: %s" % [said])
	measured["a_whole_number_in_the_shader"] = said
	# A sampler nobody bound: silence, and nothing to read back.
	var before := errors.size() + warnings.size()
	var picture := ShaderMaterial.new()
	picture.shader = load("res://steps/5_picture.gdshader")
	await frames(2)
	check(unbound(picture) == ["glow_map"] and errors.size() + warnings.size() == before, "steps/5_picture.gdshader has a sampler2D, glow_map; left unbound it reads back null, and Godot logs nothing")
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	picture.set_shader_parameter("glow_map", ImageTexture.create_from_image(noise.get_image(256, 128)))
	check(unbound(picture).is_empty(), "bound to a picture of the CPU's noise, 256 by 128, it reads back a texture")
	# A name the shader does not have: kept by the material, used by nothing, in silence.
	before = errors.size() + warnings.size()
	var skin := ShaderMaterial.new()
	skin.shader = load("res://skin.gdshader")
	skin.set_shader_parameter("rim_colur", Look.SECOND)
	await frames(2)
	check(skin.get_shader_parameter("rim_colour") == null and same_colour(skin.get_shader_parameter("rim_colur"), Look.SECOND) and errors.size() + warnings.size() == before,
		"set_shader_parameter(\"rim_colur\", ...) is silent: the material keeps the misspelt name, rim_colour stays unset, nothing is logged")

## A body meets the body: the walker and the marble meet a sphere, whatever the skin says.
func a_body() -> void:
	var study: Node3D = load("res://shader_skin.tscn").instantiate()
	root.add_child(study)
	await physics_frames(20)
	var walker: CharacterBody3D = study.get_node("Walker")
	var skin: Node3D = study.get_node("Skin")
	var before := errors.size()
	var how := await walk(walker, [Vector3(-1.5, 0, 0), Vector3(0, 0, -1.5), Vector3(1.5, 0, 0), Vector3(0, 0, 1.5)])
	check(how == "arrived" and flat(walker.global_position).distance_to(Vector2(0.0, 1.5)) < 0.11, "the walker walked round the body, 1.5 m from its middle, by four points, and arrived")
	var gaps := []
	for side: Vector3 in [Vector3(0, 0, 1.5), Vector3(1.5, 0, 0), Vector3(0, 0, -1.5), Vector3(-1.5, 0, 0)]:
		walker.stand_at(side)
		await physics_frames(5)
		how = await walk(walker, [Vector3.ZERO])
		gaps.append([how, snappedf(flat(walker.global_position).length(), 0.01)])
	var stopped := true
	for gap: Array in gaps:
		stopped = stopped and gap[0] == "blocked" and absf(gap[1] - 0.8) < 0.03
	check(stopped, "walked at the body from four sides it was stopped each time, 0.80 m from the middle: %s" % [gaps])
	measured["walker_stopped_at_m_from_the_middle"] = gaps
	walker.stand_at(Vector3(-2.0, 0.0, 1.2))
	# The marble on the top of the body, with the grain at 0 and at 1.
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.0, 0.1, 2.0)
	study.add_child(marble)
	var rests := {}
	for grain: float in [0.0, 1.0]:
		skin.material.set_shader_parameter("grain", grain)
		marble.drop(Vector3(0.0, 1.5, 0.0))
		rests["grain %s" % grain] = snappedf((await settle(marble)).y, 0.001)
	check(rests["grain 0.0"] == rests["grain 1.0"] and absf(rests["grain 1.0"] - 1.1) < 0.02, "a marble dropped on the top rests at the same height, to the millimetre, with the grain at 0 and at 1: the skin is not a body (%s)" % [rests])
	measured["marble_rests_at_m"] = rests
	check(errors.size() == before, "and Godot logged no error while the bodies met: %s" % [errors.slice(before)])
	study.free()
	await frames(1)

func guest() -> void:
	var folder := "res://guests/shader-skin/"
	var needs := CheckGuest.outside(folder)
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names(folder).is_empty(), "the guest declares no class_name")
	var files := DirAccess.get_files_at(folder)
	check(Array(files) == ["shader-skin.gd", "shader-skin.tscn", "skin.gdshader"], "its folder holds three files: %s" % [files])
	check(text_of(folder + "skin.gdshader") == text_of("res://skin.gdshader"), "its skin.gdshader is the kit's skin.gdshader, byte for byte")
	var before := errors.size()
	var body: Node = load(folder + "shader-skin.tscn").instantiate()
	root.add_child(body)
	await frames(60)
	check(body is Node3D and errors.size() == before, "the guest's first node is a Node3D and it ran 60 frames with no error: %s" % [errors.slice(before)])
	var mesh := body.get_node_or_null("Member") as MeshInstance3D
	var box: AABB = mesh.global_transform * mesh.get_aabb() if mesh != null else AABB()
	check(mesh != null and absf(box.position.y) < 0.001 and box.size.x <= 1.6 and box.size.z <= 1.6 and absf(box.get_center().x) < 0.001 and absf(box.get_center().z) < 0.001,
		"it stands on the ground at its own origin and is %.2f m wide and deep: inside the 1.6 m of a place" % [box.size.x])
	var material: ShaderMaterial = mesh.material_override as ShaderMaterial if mesh != null else null
	check(material != null and material.shader.resource_path == folder + "skin.gdshader" and same_colour(material.get_shader_parameter("rim_colour"), Look.SECOND)
		and same_colour(material.get_shader_parameter("body_colour"), Look.BODY) and same_colour(material.get_shader_parameter("band_colour"), Look.SHADE) and material.get_shader_parameter("rim_power") == 3.0,
		"it wears the skin from its own folder, with the palette's three colours written out and rim_power 3.0")
	check(mesh != null and mesh.get_node_or_null("Body/CollisionShape3D") != null and unbound(material).is_empty(), "it has a collider, and no sampler left unbound")
	body.free()
	await frames(1)
	# The room is another project, so verify.gd cannot measure it. These numbers were
	# measured once, in scratch copies of ../my-room/, and are written down here so that
	# the lesson quotes nothing that is not in a file of the kit. They are NOT measured again.
	measured["room_trial_recorded"] = {
		"how": "a scratch copy of my-room with guests/shader-skin/ copied in and its line added to GUESTS: guest_trial.gd, 8 checks of 8. Then the lesson's room task in a second copy: rim_colour set to the sky's colour in the guest's script, and skin.gdshader copied into guests/example/ and put on the box; guest_trial.gd passed 8 of 8 for each. Then one windowed run of that room, through the walker's Eyes",
		"guest_trial": {"place": 2, "frames_with_no_error": 180, "walk_ended": "blocked", "metres_from_the_middle_of_the_place": 0.8, "feet_at_m": 0.0},
		"example_guest_in_the_skin_trial": {"place": 1, "walk_ended": "blocked", "metres_from_the_middle_of_the_place": 0.55},
		"the_sphere_through_the_eyes": {
			"how": "the room as it runs, with the look's filter; the walker 2 m in front of place 2, its Eyes at 1.60 m looking at the body's middle; the mean colour of the body's outer tenth against the mean colour of what is not body within 1.15 radii, red, green and blue together, of 441",
			"behind_mean_colour": "#170458",
			"rim_in_SECOND": {"edge_mean_colour": "#3e8876", "edge_from_behind_of_441": 140.9},
			"rim_in_SKY": {"edge_mean_colour": "#8c4e4a", "edge_from_behind_of_441": 138.6},
		},
		"the_box_through_the_eyes": {
			"how": "the walker in front of place 1, its Eyes at 1.60 m looking at the box's middle; the share of the box's pixels whose blue is above 150 of 255 and above their red: the rim's cyan",
			"cyan_pct_of_body": {"from 2 m": 0.0, "from 4 m": 0.0, "from 6 m": 13.81},
		},
	}
