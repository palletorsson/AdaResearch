extends SceneTree
## Headless proof: ground paint texture = shader paint (teal square) + plant bleed
## (pink flower clumps) composed together. Saves to the ENCYCLOPEDIA folder (never
## the godot repo). Run:
##   godot --headless --path . --script res://commons/testing/test_shader_paint_bleed.gd

const Sub = preload("res://commons/biome_layers/biome_ground_substrate.gd")

func _make_brush_rows(gw: int, gd: int, cx: int, cz: int, rad: int) -> Array:
	# A filled disc of 1.0 around (cx,cz) — like a brush stamp.
	var rows: Array = []
	for z in gd:
		var row: Array = []
		for x in gw:
			var d := sqrt(float((x - cx) * (x - cx) + (z - cz) * (z - cz)))
			row.append(1.0 if d <= float(rad) else 0.0)
		rows.append(row)
	return rows

func _initialize() -> void:
	var gw := 16
	var gd := 16
	var sub = Sub.new()
	sub.configure(gw, gd, 1.0, Vector3(8, 0, 8))
	# Flat height field (we only care about the colour texture here).
	var field := PackedFloat32Array()
	field.resize(gw * gd)
	sub.set_field(field, gw, gd, 0.0)

	var layers: Array = [
		# Shader paint: a teal disc, lower-left.
		{"element": "shader", "mode": "brush", "color": [0.18, 0.62, 0.55],
		 "brush": _make_brush_rows(gw, gd, 4, 11, 3)},
		# Plant bleed: pink flowers as a noise field, upper-right.
		{"element": "flower", "mode": "noise", "density": 0.7, "scale": 0.35, "threshold": 0.45},
	]
	sub.set_paint_layers(layers, 12345)

	var tex: ImageTexture = sub._compose_paint_texture()
	var img := tex.get_image()

	# Probe: shader disc centre should be teal-ish; a flower region pinkish.
	var c_shader: Color = img.get_pixel(int(4.0 / gw * img.get_width()), int(11.0 / gd * img.get_height()))
	print("shader-centre px = ", c_shader)
	var teal_ok := c_shader.a > 0.3 and c_shader.b > c_shader.r and c_shader.g > c_shader.r
	print("shader teal-ish: ", teal_ok)

	# Save for visual confirmation — ENCYCLOPEDIA folder, NOT the godot repo.
	var out_dir := "user://"
	img.save_png(out_dir + "shader_bleed_proof.png")
	print("SAVED ", ProjectSettings.globalize_path(out_dir + "shader_bleed_proof.png"))
	quit()
