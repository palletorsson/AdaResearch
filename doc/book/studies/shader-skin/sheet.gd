extends "res://supplied/sheet_tools.gd"
## The Shader skin kit's stills and measurements. It needs a window, so run it
## WITHOUT --headless, from this folder:
##   godot --path . --xr-mode off --script res://sheet.gd
## It writes
##   sheet.png    the argument: the rim's exponent at 0.5, 1, 3 and 8, each body
##                alone, from the side at 2 m. Top row: our skin. Bottom row: the
##                same four on a body that is dark all over
##   process.png  the strip: one still after each step of the lesson
##   place.png    the body through the walker's eyes from four sides
##   sheet.json   every number the lesson quotes: the pairs, how far the rim
##                reaches, the measure of "lit" tried on a body with no light,
##                the planted bug, the refused shader, the four sides
## and the single stills, in stills/. The stripes do not crawl here: drift is 0
## in every still, so that two stills show one moment.

const Member := preload("res://parts/member.gd")
const POWERS := [0.5, 1.0, 3.0, 8.0]
const BLACK := Color(0.0, 0.0, 0.0)

func run() -> void:
	await argument()
	await unlit()
	await process_strip()
	await planted_bug()
	await place()
	await seam()
	await clock()
	await room_argues()

## The kit's own body, made by the learner's script, with one exponent.
func skinned(power: float) -> Node3D:
	var body: Node3D = load("res://shader_skin.gd").new()
	body.rim_power = power
	body.drift = 0.0
	return body

## The member with any shader on it: for the steps that are not the last one.
func member_with(shader: Shader, values := {}) -> Node3D:
	var holder := Node3D.new()
	var member: MeshInstance3D = Member.make(64)
	holder.add_child(member)
	var material := ShaderMaterial.new()
	material.shader = shader
	for key: String in values:
		material.set_shader_parameter(key, values[key])
	member.material_override = material
	return holder

## The argument: four exponents, every pair, and what the rim does to the body.
func argument() -> void:
	var tiles: Array[Image] = []
	var captions := []
	var names := []
	for power: float in POWERS:
		names.append("p %s" % power)
	for row: String in ["our skin", "dark body"]:
		for distance: float in [2.0, 5.0]:
			var stills := []
			var pixels := []
			var rims := {}
			var sun_alone := 0.0
			for power: float in POWERS:
				var body := skinned(power)
				await stand(body)
				look("level", distance)
				if row == "dark body":
					body.material.set_shader_parameter("body_colour", Look.SHADE)
				var name := "%s_p%s_%sm" % [row.replace(" ", "_"), power, distance]
				var taken: Array = await portrait(body, name)
				body.material.set_shader_parameter("rim_colour", BLACK)
				var without := await shot("")
				stills.append(taken[0])
				pixels.append(taken[1])
				rims["p %s" % power] = rim_of(taken[0], without, taken[1])
				sun_alone = rim_of(without, without, taken[1])["left_to_right_brightness"]
				if distance == 2.0:
					tiles.append(small(taken[0]))
					captions.append("%s, p = %s" % [row, power])
			var key := "%s at %s m" % [row, distance]
			print("--- ", key)
			var record := compare_all(names, stills, pixels)
			record["body_pct_of_still"] = share(pixels[0])
			record["body_pixels"] = pixels[0].count(1)
			record["rim"] = rims
			record["left_to_right_brightness_with_the_rim_black"] = sun_alone
			print("with the rim black: left half %.2f times as bright as the right" % sun_alone)
			for name: String in rims:
				print("%s: the rim changes %5.2f%% of the body; it begins %.2f of the radius from the middle; left half %.2f times as bright as the right" % [
					name, rims[name]["reach_pct_of_body"], rims[name]["begins_at_of_radius"], rims[name]["left_to_right_brightness"]])
			report[key] = record
	report["sheet_png"] = await compose(tiles, POWERS.size(), captions, "res://sheet.png")
	# Between the closest pair: exponents 3 to 7, each against 8, our skin at 2 m.
	var last: Image
	var body := skinned(8.0)
	await stand(body)
	look("level")
	last = await shot("")
	var series := {}
	for power: float in [3.0, 4.0, 5.0, 6.0, 7.0]:
		body.material.set_shader_parameter("rim_power", power)
		series["p %s vs p 8.0" % power] = differ_pct(await shot(""), last)
	print("against 8: ", series)
	report["series_against_8"] = series

## The measure of "lit", tried on a body that is unlit by construction: the
## same skin with `render_mode unshaded;`, so that no light reaches it, and
## with the rim's colour black. A measure that is sound finds its left half
## and its right half equally bright.
func unlit() -> void:
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string("res://skin.gdshader").replace("shader_type spatial;", "shader_type spatial;\nrender_mode unshaded;")
	var record := {}
	for row: String in ["our skin", "dark body"]:
		var values := {"body_colour": Look.SHADE if row == "dark body" else Look.BODY, "band_colour": Look.SHADE, "rim_colour": BLACK}
		var taken: Array = await photograph(member_with(shader, values), "level", "unlit_" + row.replace(" ", "_"))
		record[row] = {
			"left_to_right_brightness": rim_of(taken[0], taken[0], taken[1])["left_to_right_brightness"],
			"mean_colour": mean_colour(taken[0], taken[1]),
		}
		print("unlit by construction, %s: left half %.2f times as bright as the right; the body is %s" % [row, record[row]["left_to_right_brightness"], record[row]["mean_colour"]])
	record["how"] = "skin.gdshader with render_mode unshaded added and rim_colour black, from the side at 2 m: no light reaches the body, so whatever the two halves differ by is the skin's own and the measure's"
	report["unlit_by_construction"] = record

## What the rim adds: `still` is the body with its rim, `without` the same body
## with the rim's colour set to black, `pixels` where the body is.
func rim_of(still: Image, without: Image, pixels: PackedByteArray) -> Dictionary:
	var changed := differs(still, without)
	var spot := disc(pixels)
	var data := still.get_data()
	var width := still.get_width()
	var body := 0
	var rim := 0
	var left := Vector2.ZERO    # brightness summed, pixels counted
	var right := Vector2.ZERO
	var radii := PackedFloat32Array()
	for i in pixels.size():
		if pixels[i] == 0:
			continue
		body += 1
		var at := Vector2(i % width, i / width)
		var bright := (0.2126 * data[i * 3] + 0.7152 * data[i * 3 + 1] + 0.0722 * data[i * 3 + 2]) / 255.0
		if at.x < spot["middle"].x:
			left += Vector2(bright, 1.0)
		else:
			right += Vector2(bright, 1.0)
		if changed[i] == 1:
			rim += 1
			radii.append((at - spot["middle"]).length() / spot["radius"])
	radii.sort()
	return {
		"reach_pct_of_body": snappedf(100.0 * rim / maxf(body, 1.0), 0.01),
		"begins_at_of_radius": snappedf(radii[int(radii.size() * 0.05)], 0.01) if radii.size() > 0 else 1.0,
		"band_px": snappedf(rim / (TAU * spot["radius"]), 0.01),
		"left_to_right_brightness": snappedf((left.x / maxf(left.y, 1.0)) / maxf(right.x / maxf(right.y, 1.0), 0.0001), 0.01),
		"mean_colour": mean_colour(still, pixels),
	}

## The middle of a body's pixels and the radius of a disc of the same area.
func disc(pixels: PackedByteArray) -> Dictionary:
	var width := crop.size.x
	var sum := Vector2.ZERO
	var count := 0
	for i in pixels.size():
		if pixels[i] == 1:
			sum += Vector2(i % width, i / width)
			count += 1
	return {"middle": sum / maxf(count, 1.0), "radius": sqrt(maxf(count, 1.0) / PI), "pixels": count}

func mean_colour(still: Image, pixels: PackedByteArray) -> String:
	var data := still.get_data()
	var sum := Vector3.ZERO
	var count := 0
	for i in pixels.size():
		if pixels[i] == 1:
			sum += Vector3(data[i * 3], data[i * 3 + 1], data[i * 3 + 2])
			count += 1
	sum /= maxf(count, 1.0) * 255.0
	return "#" + Color(sum.x, sum.y, sum.z).to_html(false)

## How much of a body is one exact colour, in percent of the body.
func exactly(still: Image, pixels: PackedByteArray, colour: Color) -> float:
	var data := still.get_data()
	var count := 0
	var hits := 0
	for i in pixels.size():
		if pixels[i] == 1:
			count += 1
			if data[i * 3] == colour.r8 and data[i * 3 + 1] == colour.g8 and data[i * 3 + 2] == colour.b8:
				hits += 1
	return snappedf(100.0 * hits / maxf(count, 1.0), 0.01)

## The CPU's noise as a picture: what the lesson binds to the sampler.
func cpu_noise() -> ImageTexture:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	return ImageTexture.create_from_image(noise.get_image(256, 128))

## The process strip: one still after each step, from one standpoint.
func process_strip() -> void:
	var names := ["1 the look's paint", "2 UV as colour", "3 step", "4 sin and smoothstep", "5 fBm grain",
		"6 a sampler nobody bound", "7 the CPU's noise bound", "8 the rim from the eye"]
	var two := {"body_colour": Look.BODY, "band_colour": Look.SHADE}
	var bodies := []
	var painted := Node3D.new()
	var plain: MeshInstance3D = Member.make(64)
	plain.material_override = Look.paint(Look.BODY)
	painted.add_child(plain)
	bodies.append(painted)
	bodies.append(member_with(load("res://steps/1_uv.gdshader")))
	bodies.append(member_with(load("res://steps/2_step.gdshader"), two))
	bodies.append(member_with(load("res://steps/3_bands.gdshader"), two))
	bodies.append(member_with(load("res://steps/4_grain.gdshader"), two))
	bodies.append(member_with(load("res://steps/5_picture.gdshader"), two))
	var bound := two.duplicate()
	bound["glow_map"] = cpu_noise()
	bodies.append(member_with(load("res://steps/5_picture.gdshader"), bound))
	bodies.append(skinned(3.0))
	var tiles: Array[Image] = []
	for i in bodies.size():
		await stand(bodies[i])
		look_from(Vector3(1.3, 1.25, 2.3), Vector3(0.0, 0.42, 0.0))
		tiles.append(small(await shot("strip_%d" % (i + 1))))
	var last: Array = await portrait(bodies[bodies.size() - 1])
	report["strip"] = await strip(tiles, names)
	report["strip"]["body_pct_of_still"] = share(last[1])
	print("from the strip's standpoint the body covers %.2f%% of the still" % report["strip"]["body_pct_of_still"])

## The planted bug and the refused shader, measured.
func planted_bug() -> void:
	var two := {"body_colour": Look.BODY, "band_colour": Look.SHADE}
	var before: int = _catcher.errors.size() + _catcher.warnings.size()
	var taken: Array = await photograph(member_with(load("res://steps/5_picture.gdshader"), two), "level", "bug_unbound")
	var record := {
		"unbound_mean_colour": mean_colour(taken[0], taken[1]),
		"unbound_white_pct_of_body": exactly(taken[0], taken[1], Color.WHITE),
		"unbound_errors_and_warnings": _catcher.errors.size() + _catcher.warnings.size() - before,
	}
	var clock := Time.get_ticks_usec()
	var picture := cpu_noise()
	record["cpu_noise_made_in_ms"] = snappedf((Time.get_ticks_usec() - clock) / 1000.0, 0.1)
	record["cpu_noise_size"] = [picture.get_width(), picture.get_height()]
	var bound := two.duplicate()
	bound["glow_map"] = picture
	taken = await photograph(member_with(load("res://steps/5_picture.gdshader"), bound), "level", "bug_bound")
	record["bound_mean_colour"] = mean_colour(taken[0], taken[1])
	record["bound_white_pct_of_body"] = exactly(taken[0], taken[1], Color.WHITE)
	print("planted bug: unbound, the body is %s, %.2f%% of it exactly white, %d errors and warnings; bound to the CPU's noise (%d x %d, made in %.1f ms) it is %s, %.2f%% white" % [
		record["unbound_mean_colour"], record["unbound_white_pct_of_body"], record["unbound_errors_and_warnings"],
		picture.get_width(), picture.get_height(), record["cpu_noise_made_in_ms"], record["bound_mean_colour"], record["bound_white_pct_of_body"]])
	report["planted_bug"] = record
	# Two uniforms nobody set: the step shader before the script hands it its colours.
	taken = await photograph(member_with(load("res://steps/2_step.gdshader")), "level", "unset")
	report["unset_uniforms"] = {"mean_colour": mean_colour(taken[0], taken[1]), "black_pct_of_body": exactly(taken[0], taken[1], Color.BLACK)}
	print("two colour uniforms nobody set: the body is %s, %.2f%% of it exactly black" % [report["unset_uniforms"]["mean_colour"], report["unset_uniforms"]["black_pct_of_body"]])
	# The shader the lesson writes with a whole number in it: 6 for 6.0.
	var refused := Shader.new()
	refused.code = "shader_type spatial;\n\nuniform vec3 body_colour : source_color;\nuniform vec3 band_colour : source_color;\n\nvoid fragment() {\n\tfloat wave = 0.5 + 0.5 * sin(UV.y * 6 * TAU);\n\tfloat band = step(0.5, wave);\n\tALBEDO = mix(band_colour, body_colour, band);\n}\n"
	var seen: int = _catcher.errors.size()
	taken = await photograph(member_with(refused, two), "level", "refused")
	report["refused_shader"] = {
		"errors": _catcher.errors.slice(seen),
		"mean_colour": mean_colour(taken[0], taken[1]),
		"body_pct_of_still": share(taken[1]),
	}
	print("refused shader: %s; the body is drawn %s" % [report["refused_shader"]["errors"], report["refused_shader"]["mean_colour"]])
	# The same shader with 6.0: how many light stripes does the middle column cross?
	var repaired := Shader.new()
	repaired.code = refused.code.replace("6 * TAU", "6.0 * TAU")
	seen = _catcher.errors.size()
	taken = await photograph(member_with(repaired, two), "level", "repaired")
	var still: Image = taken[0]
	var light := 0
	var was_light := false
	for y in still.get_height():
		var i := y * still.get_width() + still.get_width() / 2
		var is_light: bool = taken[1][i] == 1 and still.get_pixel(still.get_width() / 2, y).g > 0.4
		if is_light and not was_light:
			light += 1
		was_light = is_light
	report["repaired_shader"] = {"errors": _catcher.errors.slice(seen), "light_stripes_on_the_middle_column": light}
	print("repaired shader: %s; the middle column of the still crosses %d light stripes" % [report["repaired_shader"]["errors"], light])

## Place: the body through the walker's eyes from four sides, 2 m away.
func place() -> void:
	var sides := {"front": Vector3(0, 0, 2), "right": Vector3(2, 0, 0), "back": Vector3(0, 0, -2), "left": Vector3(-2, 0, 0)}
	var body := skinned(3.0)
	await stand(body)
	shadows(true)
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = sides["front"]
	walker.keys = false
	studio.add_child(walker)
	await process_frame
	var eyes: Camera3D = walker.get_node("Eyes")
	eyes.make_current()
	var tiles: Array[Image] = []
	var names := []
	var rims := {}
	var skins := {}
	var spots := {}
	var record := {}
	for side: String in sides:
		walker.stand_at(sides[side])
		walker.look_at(Vector3(0.0, 0.0, 0.0))
		eyes.look_at(Vector3(0.0, 0.5, 0.0))
		for i in 4:
			await physics_frame
		var taken: Array = await portrait(body, "place_" + side)
		body.material.set_shader_parameter("rim_colour", BLACK)
		var without := await shot("")
		body.material.set_shader_parameter("rim_colour", Look.SECOND)
		var changed := differs(taken[0], without)
		for i in changed.size():
			if taken[1][i] == 0:
				changed[i] = 0
		rims[side] = changed
		skins[side] = [without, taken[1]]
		spots[side] = disc(taken[1])
		record[side] = rim_of(taken[0], without, taken[1])
		record[side]["body_pct_of_still"] = share(taken[1])
		tiles.append(small(taken[0]))
		names.append("from the %s" % side)
		print("place, from the %-5s: the rim changes %5.2f%% of the body and begins %.2f of the radius from the middle; left half %.2f times as bright as the right" % [
			side, record[side]["reach_pct_of_body"], record[side]["begins_at_of_radius"], record[side]["left_to_right_brightness"]])
	# The rim in the still: is it in the same place from every side? And the skin under it?
	var pairs := {}
	for side: String in ["right", "back", "left"]:
		var both := 0
		var either := 0
		var skin_differs := 0
		var shared := 0
		var d := differs(skins["front"][0], skins[side][0])
		for i in rims["front"].size():
			var a: int = rims["front"][i]
			var b: int = rims[side][i]
			both += a & b
			either += a | b
			if skins["front"][1][i] == 1 and skins[side][1][i] == 1:
				shared += 1
				skin_differs += d[i]
		pairs["front vs " + side] = {
			"rim_pixels_shared_pct": snappedf(100.0 * both / maxf(either, 1.0), 0.01),
			"skin_without_rim_differs_pct_of_body": snappedf(100.0 * skin_differs / maxf(shared, 1.0), 0.01),
		}
		print("place, front vs %-5s: %5.2f%% of the rim's pixels are the same pixels; under the rim the skin differs on %5.2f%% of the body" % [
			side, pairs["front vs " + side]["rim_pixels_shared_pct"], pairs["front vs " + side]["skin_without_rim_differs_pct_of_body"]])
	record["pairs"] = pairs
	record["eye_height_m"] = snappedf(eyes.global_position.y, 0.01)
	record["how"] = "the walker stands 2 m from the body's middle on four sides and looks at it through its Eyes; rim pixels are the body's pixels that change when rim_colour is set to black"
	report["place"] = record
	report["place_png"] = await compose(tiles, 4, names, "res://place.png")
	walker.queue_free()
	await process_frame

## The seam: where UV.x runs out at 1 and starts again at 0, the grain breaks.
## The body from the back and from the front, 2 m away: how far apart are the
## pixels two to the left and two to the right of the body's middle line?
func seam() -> void:
	var record := {}
	var body := skinned(3.0)
	await stand(body)
	for side: String in ["back", "front"]:
		look_from(Vector3(0.0, 0.5, -2.0 if side == "back" else 2.0), Vector3(0.0, 0.5, 0.0))
		shadows(false)
		var taken: Array = await portrait(body, "seam_" + side)
		var spot := disc(taken[1])
		var data: PackedByteArray = taken[0].get_data()
		var width: int = taken[0].get_width()
		var column := int(spot["middle"].x)
		var sum := 0.0
		var rows := 0
		var largest := 0
		for y in taken[0].get_height():
			var a: int = (y * width + column - 2) * 3
			var b: int = (y * width + column + 2) * 3
			if taken[1][y * width + column - 2] == 1 and taken[1][y * width + column + 2] == 1:
				var apart: int = absi(data[a] - data[b]) + absi(data[a + 1] - data[b + 1]) + absi(data[a + 2] - data[b + 2])
				sum += apart
				largest = maxi(largest, apart)
				rows += 1
		record[side] = {"mean_step_across_the_middle_line_of_765": snappedf(sum / maxf(rows, 1.0), 0.1), "largest_of_765": largest, "rows": rows}
		print("seam, from the %-5s: across the body's middle line the colour steps by %.1f of 765 on average, %d at most, over %d rows" % [side, sum / maxf(rows, 1.0), largest, rows])
	record["how"] = "the body from behind and from in front at 2 m; for every row of the body, the pixel two to the left of its middle line against the pixel two to the right, red, green and blue added"
	report["seam"] = record

## The clock: nothing in the script runs after _ready(), and the stripes crawl.
func clock() -> void:
	var record := {}
	for drift: float in [0.1, 0.0]:
		var body := skinned(3.0)
		body.drift = drift
		await stand(body)
		look("level")
		var first := await shot("")
		var began := Time.get_ticks_msec()
		while Time.get_ticks_msec() - began < 1000:
			await process_frame
		var second := await shot("")
		var seconds := snappedf((Time.get_ticks_msec() - began) / 1000.0, 0.01)
		record["drift %s" % drift] = {"differ_pct": differ_pct(first, second), "seconds_apart": seconds, "stripes_moved_up_px": moved_up(first, second)}
		print("clock: with drift %s two stills %.2f s apart differ on %.2f%% of the still; on the middle column the stripes moved up by %d pixels" % [
			drift, seconds, record["drift %s" % drift]["differ_pct"], record["drift %s" % drift]["stripes_moved_up_px"]])
	record["how"] = "the body is held: stand() stops its own _process, so only the shader's TIME moved between the two stills. moved up: the shift, in pixels, at which the middle column of the first still fits the second best, over 200 rows about the middle; more than 0 is upward"
	report["clock"] = record

## How many pixels the middle of the picture moved up between two stills: the
## green of the middle column, 200 rows about the middle of the still, laid
## over the same column of the second still at every shift from 40 pixels down
## to 40 up; the shift where the two fit best. More than 0 is upward.
func moved_up(first: Image, second: Image) -> int:
	var x := first.get_width() / 2
	var middle := first.get_height() / 2
	var best := 0
	var least := INF
	for shift in range(-40, 41):
		var apart := 0.0
		for y in range(middle - 100, middle + 100):
			apart += absf(first.get_pixel(x, y).g - second.get_pixel(x, y - shift).g)
		if apart < least:
			least = apart
			best = shift
	return best

## The room's argument: a rim in the sky's colour against a rim in SECOND.
func room_argues() -> void:
	var record := {}
	for name: String in ["SECOND", "SKY"]:
		var body := skinned(1.0)
		await stand(body)
		look("level")
		body.material.set_shader_parameter("rim_colour", Look.SKY if name == "SKY" else Look.SECOND)
		var taken: Array = await portrait(body, "rim_in_" + name)
		# The body's outermost pixels: the last tenth of its radius.
		var spot := disc(taken[1])
		var data: PackedByteArray = taken[0].get_data()
		var width: int = taken[0].get_width()
		var sum := Vector3.ZERO
		var count := 0
		for i in taken[1].size():
			if taken[1][i] == 1 and (Vector2(i % width, i / width) - spot["middle"]).length() > 0.9 * spot["radius"]:
				sum += Vector3(data[i * 3], data[i * 3 + 1], data[i * 3 + 2])
				count += 1
		sum /= maxf(count, 1.0)
		var sky := Vector3(Look.SKY.r8, Look.SKY.g8, Look.SKY.b8)
		record["rim_in_" + name] = {
			"edge_mean_colour": "#" + Color(sum.x / 255.0, sum.y / 255.0, sum.z / 255.0).to_html(false),
			"edge_from_sky_of_441": snappedf((sum - sky).length(), 0.1),
		}
		print("rim in %-6s: the body's outer tenth is %s on average, %.1f from the sky's colour (of 441)" % [
			name, record["rim_in_" + name]["edge_mean_colour"], record["rim_in_" + name]["edge_from_sky_of_441"]])
	record["how"] = "p = 1, from the side at 2 m; the mean colour of the body's pixels in the last tenth of its radius, and its distance from SKY in red, green and blue together"
	report["room_argues"] = record
