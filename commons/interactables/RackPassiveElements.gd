extends Node3D
class_name RackPassiveElements

## Procedural passive rack elements: speakers, meters, monitors.
## Dieter Rams / Braun aesthetic — cream panels, black patterns, copper accents.

const EL_S := 0.10  # Standard element size (meters)
const SPEAKER_S := 0.145  # Larger speaker face so it fills a one-slot frame better
const CREAM := Color(0.78, 0.75, 0.67)
const BLACK := Color(0.10, 0.10, 0.10)
const COPPER := Color(0.75, 0.38, 0.13)
const WARM_GRAY := Color(0.50, 0.47, 0.42)
const DARK := Color(0.14, 0.14, 0.14)


## Build a speaker with dot pattern (Braun circular)
static func build_speaker_dots(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerDotsBg"
	var box := BoxMesh.new()
	box.size = Vector3(SPEAKER_S, SPEAKER_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = BLACK
	dot_mat.metallic = 0.4
	dot_mat.roughness = 0.5

	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.0014
	dot_mesh.height = 0.0028
	dot_mesh.radial_segments = 6
	dot_mesh.rings = 3

	var r := SPEAKER_S * 0.42
	for ring in range(1, 10):
		var rr: float = (float(ring) / 9.0) * r
		var count: int = max(6, ring * 5)
		for i in count:
			var a: float = (float(i) / float(count)) * TAU
			var dx: float = cos(a) * rr
			var dy: float = sin(a) * rr
			if dx * dx + dy * dy > r * r:
				continue
			var dot := MeshInstance3D.new()
			dot.mesh = dot_mesh
			dot.material_override = dot_mat
			dot.transform.origin = Vector3(dx, dy, 0.003)
			parent.add_child(dot)


## Build a speaker with horizontal line pattern
static func build_speaker_lines(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerLinesBg"
	var box := BoxMesh.new()
	box.size = Vector3(SPEAKER_S, SPEAKER_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = BLACK

	var r_val := SPEAKER_S * 0.44
	for i in 20:
		var y: float = -r_val + (float(i) / 19.0) * r_val * 2.0
		var dy: float = y / r_val
		var line_w: float = 0.0
		if dy * dy < 1.0:
			line_w = sqrt(1.0 - dy * dy) * r_val * 2.0
		if line_w < 0.003:
			continue
		var line := MeshInstance3D.new()
		var line_box := BoxMesh.new()
		line_box.size = Vector3(line_w, 0.002, 0.001)
		line.mesh = line_box
		line.material_override = line_mat
		line.transform.origin = Vector3(0, y, 0.003)
		parent.add_child(line)


## Build a speaker with uniform dot grid
static func build_speaker_grid(parent: Node3D) -> void:
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = CREAM
	bg_mat.metallic = 0.15
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	bg.name = "SpeakerGridBg"
	var box := BoxMesh.new()
	box.size = Vector3(SPEAKER_S, SPEAKER_S, 0.004)
	bg.mesh = box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var dot_mat := StandardMaterial3D.new()
	dot_mat.albedo_color = BLACK

	var dot_mesh := SphereMesh.new()
	dot_mesh.radius = 0.0012
	dot_mesh.height = 0.0024
	dot_mesh.radial_segments = 4
	dot_mesh.rings = 2

	var grid_n := 13
	var area := SPEAKER_S * 0.85
	var step := area / float(grid_n)
	for row in grid_n:
		for col in grid_n:
			var dot := MeshInstance3D.new()
			dot.mesh = dot_mesh
			dot.material_override = dot_mat
			dot.transform.origin = Vector3(
				-area / 2.0 + step * 0.5 + float(col) * step,
				-area / 2.0 + step * 0.5 + float(row) * step,
				0.003
			)
			parent.add_child(dot)


## Build a vertical VU meter
static func build_vu_meter_v(parent: Node3D) -> void:
	var mw := 0.035
	var mh := EL_S

	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.14, 0.12)
	bg_mat.metallic = 0.3
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(mw + 0.008, mh + 0.008, 0.005)
	bg.mesh = bg_box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var bars := 16
	var bar_h := (mh - 0.008) / float(bars)
	for i in bars:
		var frac := float(i) / float(bars)
		var lit := frac < 0.7
		var col: Color
		if frac > 0.85:
			col = COPPER
		elif frac > 0.6:
			col = WARM_GRAY
		else:
			col = Color(0.38, 0.38, 0.38)

		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = col if lit else Color(0.10, 0.10, 0.10)
		if lit:
			bar_mat.emission_enabled = true
			bar_mat.emission = col
			bar_mat.emission_energy_multiplier = 0.5

		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(mw * 0.85, bar_h * 0.65, 0.002)
		bar.mesh = bar_box
		bar.material_override = bar_mat
		bar.transform.origin = Vector3(0, -mh / 2.0 + 0.004 + float(i) * bar_h + bar_h / 2.0, 0.005)
		parent.add_child(bar)


## Build a horizontal VU meter
static func build_vu_meter_h(parent: Node3D) -> void:
	var mw := EL_S
	var mh := 0.035

	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.15, 0.14, 0.12)
	bg_mat.metallic = 0.3
	bg_mat.roughness = 0.7

	var bg := MeshInstance3D.new()
	var bg_box := BoxMesh.new()
	bg_box.size = Vector3(mw + 0.008, mh + 0.008, 0.005)
	bg.mesh = bg_box
	bg.material_override = bg_mat
	parent.add_child(bg)

	var bars := 20
	var bar_w := (mw - 0.008) / float(bars)
	for i in bars:
		var frac := float(i) / float(bars)
		var lit := frac < 0.6
		var col: Color
		if frac > 0.85:
			col = COPPER
		elif frac > 0.6:
			col = WARM_GRAY
		else:
			col = Color(0.38, 0.38, 0.38)

		var bar_mat := StandardMaterial3D.new()
		bar_mat.albedo_color = col if lit else Color(0.10, 0.10, 0.10)
		if lit:
			bar_mat.emission_enabled = true
			bar_mat.emission = col
			bar_mat.emission_energy_multiplier = 0.5

		var bar := MeshInstance3D.new()
		var bar_box := BoxMesh.new()
		bar_box.size = Vector3(bar_w * 0.7, mh * 0.8, 0.002)
		bar.mesh = bar_box
		bar.material_override = bar_mat
		bar.transform.origin = Vector3(-mw / 2.0 + 0.004 + float(i) * bar_w + bar_w / 2.0, 0, 0.005)
		parent.add_child(bar)


## Build a Dieter Rams styled monitor — fits grid slots.
## slots: 1, 2, or 3 grid slots wide. Uses SubViewport for live waveform.
static func build_monitor_grid(parent: Node3D, slots: int, mode: String) -> void:
	var w: float = slots * 0.28 - 0.02  # match grid slot width
	var h: float = 0.18  # fits inside 0.28 height frame

	# Warm bezel (Rams cream surround)
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = CREAM
	bezel_mat.metallic = 0.15
	bezel_mat.roughness = 0.7

	var bezel := MeshInstance3D.new()
	bezel.name = "MonitorBezel"
	var bezel_box := BoxMesh.new()
	bezel_box.size = Vector3(w + 0.006, h + 0.006, 0.005)
	bezel.mesh = bezel_box
	bezel.material_override = bezel_mat
	parent.add_child(bezel)

	# Dark screen inset
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.06, 0.06, 0.06)
	screen_mat.metallic = 0.1
	screen_mat.roughness = 0.9

	var screen_bg := MeshInstance3D.new()
	screen_bg.name = "ScreenBg"
	var screen_box := BoxMesh.new()
	screen_box.size = Vector3(w, h, 0.001)
	screen_bg.mesh = screen_box
	screen_bg.material_override = screen_mat
	screen_bg.transform.origin = Vector3(0, 0, 0.004)
	parent.add_child(screen_bg)

	# SubViewport for live waveform
	var viewport := SubViewport.new()
	viewport.name = "WaveformViewport"
	viewport.disable_3d = true
	viewport.size = Vector2i(int(w * 2000), int(h * 2000))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	parent.add_child(viewport)

	# 2D waveform drawing inside viewport
	var wave_ctrl := Control.new()
	wave_ctrl.name = "WaveformDraw"
	wave_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	wave_ctrl.set_script(_create_waveform_script(mode))
	viewport.add_child(wave_ctrl)

	# Textured quad showing the viewport
	var quad := MeshInstance3D.new()
	quad.name = "ScreenQuad"
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(w, h)
	quad.mesh = quad_mesh

	# Defer texture assignment
	parent.add_child(quad)
	quad.transform.origin = Vector3(0, 0, 0.005)

	# Assign texture after viewport is ready
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	quad.material_override = mat

	# Corner label (Rams style — small copper text)
	var mode_label := Label3D.new()
	mode_label.text = mode.to_upper()
	mode_label.font_size = 14
	mode_label.pixel_size = 0.0004
	mode_label.modulate = COPPER
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mode_label.transform.origin = Vector3(-w / 2.0 + 0.005, h / 2.0 - 0.008, 0.006)
	parent.add_child(mode_label)


## Legacy compat
static func build_monitor(parent: Node3D, w: float, h: float) -> void:
	build_monitor_grid(parent, 1, "scope")


## Create a simple waveform drawing script
static func _create_waveform_script(mode: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = """extends Control

var _time: float = 0.0
var _mode: String = "%s"

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.06, 0.06))
	var grid_c: Color = Color(0.15, 0.12, 0.10, 0.3)
	for gi in 6:
		draw_line(Vector2(0, float(gi) / 5.0 * h), Vector2(w, float(gi) / 5.0 * h), grid_c, 0.5)
	for gi in 10:
		draw_line(Vector2(float(gi) / 9.0 * w, 0), Vector2(float(gi) / 9.0 * w, h), grid_c, 0.5)
	draw_line(Vector2(0, h / 2), Vector2(w, h / 2), Color(0.15, 0.12, 0.10, 0.5), 1.0)
	var copper: Color = Color(0.75, 0.38, 0.13)
	if _mode == "spectrum":
		var si: int = 0
		while si < int(w):
			var t: float = float(si) / w
			var bar_h: float = abs(sin(t * 8.0 + _time * 2.0) * 0.4 + sin(t * 13.0 - _time * 1.3) * 0.25)
			draw_rect(Rect2(Vector2(si, h - bar_h * h * 0.85), Vector2(3, bar_h * h * 0.85)), Color(copper, 0.4 + bar_h * 0.5))
			si += 4
	elif _mode == "lissajous":
		var prev: Vector2 = Vector2.ZERO
		for li in 200:
			var t: float = float(li) / 200.0
			var lx: float = sin(_time * 1.3 + t * PI * 4.0) * 0.4 + 0.5
			var ly: float = sin(_time * 2.1 + t * PI * 6.0) * 0.4 + 0.5
			var pt: Vector2 = Vector2(lx * w, ly * h)
			if li > 0:
				draw_line(prev, pt, copper, 1.5)
			prev = pt
	else:
		var cycles: float = 3.0 if _mode == "scope" else 2.0
		var prev: Vector2 = Vector2.ZERO
		for wi in int(w):
			var t: float = float(wi) / w
			var yy: float = h / 2.0 + sin(t * PI * 2.0 * cycles + _time * 3.0) * h * 0.35
			var pt: Vector2 = Vector2(wi, yy)
			if wi > 0:
				draw_line(prev, pt, copper, 1.5)
			prev = pt
""" % mode
	script.reload()
	return script


## Build a static text display — Rams style dark screen with copper text.
## slots: 1, 2, or 3 grid slots wide.
static func build_text_display_static(parent: Node3D, slots: int, text: String) -> void:
	var w: float = slots * 0.28 - 0.02
	var h: float = 0.06

	# Dark bezel
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.20, 0.18, 0.16)
	bezel_mat.metallic = 0.3
	bezel_mat.roughness = 0.6
	var bezel := MeshInstance3D.new()
	bezel.name = "TextBezel"
	bezel.mesh = BoxMesh.new()
	bezel.mesh.size = Vector3(w + 0.004, h + 0.004, 0.005)
	bezel.material_override = bezel_mat
	parent.add_child(bezel)

	# Screen background
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.04, 0.04, 0.04)
	var screen := MeshInstance3D.new()
	screen.name = "TextScreen"
	screen.mesh = BoxMesh.new()
	screen.mesh.size = Vector3(w, h, 0.001)
	screen.material_override = screen_mat
	screen.transform.origin.z = 0.004
	parent.add_child(screen)

	# Static text label
	var lbl := Label3D.new()
	lbl.name = "TextContent"
	lbl.text = text
	lbl.font_size = 28
	lbl.pixel_size = 0.0004
	lbl.modulate = COPPER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.transform.origin = Vector3(0, 0, 0.006)
	parent.add_child(lbl)


## Build a scrolling text display — SubViewport with animated 2D text.
## slots: 1, 2, or 3 grid slots wide.
static func build_text_display_scroll(parent: Node3D, slots: int, text: String) -> void:
	var w: float = slots * 0.28 - 0.02
	var h: float = 0.06

	# Dark bezel
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.20, 0.18, 0.16)
	bezel_mat.metallic = 0.3
	bezel_mat.roughness = 0.6
	var bezel := MeshInstance3D.new()
	bezel.name = "ScrollBezel"
	bezel.mesh = BoxMesh.new()
	bezel.mesh.size = Vector3(w + 0.004, h + 0.004, 0.005)
	bezel.material_override = bezel_mat
	parent.add_child(bezel)

	# SubViewport for scrolling text
	var viewport := SubViewport.new()
	viewport.name = "ScrollViewport"
	viewport.disable_3d = true
	viewport.size = Vector2i(int(w * 2000), int(h * 2000))
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	parent.add_child(viewport)

	# Scrolling text control
	var scroll_ctrl := Control.new()
	scroll_ctrl.name = "ScrollText"
	scroll_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll_ctrl.set_script(_create_scroll_text_script(text))
	viewport.add_child(scroll_ctrl)

	# Textured quad
	var quad := MeshInstance3D.new()
	quad.name = "ScrollQuad"
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(w, h)
	quad.mesh = quad_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	quad.material_override = mat
	quad.transform.origin.z = 0.005
	parent.add_child(quad)


static func _create_scroll_text_script(text: String) -> GDScript:
	var escaped_text := text.replace('"', '\\"')
	var script := GDScript.new()
	script.source_code = """extends Control

var _time: float = 0.0
var _text: String = "%s"

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.04, 0.04, 0.04))
	var font: Font = get_theme_default_font()
	var fs: int = int(h * 0.45)
	var text_w: float = font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var scroll_speed: float = 40.0
	var total_w: float = text_w + w
	var offset: float = fmod(_time * scroll_speed, total_w)
	var x: float = w - offset
	var copper: Color = Color(0.75, 0.38, 0.13)
	draw_string(font, Vector2(x, h * 0.65), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, copper)
""" % escaped_text
	script.reload()
	return script
