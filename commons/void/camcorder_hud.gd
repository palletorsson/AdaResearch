extends Control
## The same viewfinder artwork draws to the desktop or to a camera-mounted plane in XR.

const FONT := preload("res://commons/font/JetBrainsMono-Medium.ttf")
const INK := Color("f2f0d9")
const PLAIN_INK := Color("b8e6c9")
const PLAIN_DIVIDER := Color(0.72, 0.90, 0.79, 0.28)
const RECORD := Color("f17474")
const LOW := Color("ffc573")
const EMPTY := Color("ff837b")
const PLATE := Color(0.035, 0.036, 0.032, 0.79)
# Palle 2026-11-16: in the headset the symbols sat too near the middle; the frame is wider and taller now (corner
# symbols about 39 degrees out to the sides, 29 up, 36 down; they were 31 and 19), with more pixels so the letters
# keep the size they had. Was 1280 x 736 pixels on a frame 1.66 m wide.
const XR_PIXELS := Vector2i(2048, 1536)
const XR_DEPTH := 1.2
const XR_FRAME_WIDTH := 2.1
const XR_VERTICAL_OFFSET := -.095
const VIEWFINDER_LAYER := 1 << 18
const SEGMENTS := 5

var level := ""
var percent := 100
var battery_fill := 1.0
var flow := ""
## The line Model B's inner voice is singing now (commons/void/inner_opera.gd sets it); empty when silent.
var sung := ""
## Optional easy-to-understand plain breadcrumb paired with `sung` (from commons/data/tower_system_atlas.json).
var sung_plain := ""
# What `configure` last set (commons/void/hud_config.gd hands it the game's hud_config.json, and a file sent to a
# running game): the plane in a headset, the letters, the margins, where the sung line sits.
var _cfg_width := XR_FRAME_WIDTH
var _cfg_height := XR_FRAME_WIDTH * float(XR_PIXELS.y) / float(XR_PIXELS.x)
var _cfg_distance := XR_DEPTH
var _cfg_offset := XR_VERTICAL_OFFSET
var _cfg_pixels := XR_PIXELS.x
var _cfg_text := 1.0
var _cfg_margin := 1.0
var _cfg_sung_at := -1.0
var _cfg_sung_width := -1.0
var _cfg_elements := {}
var _flow_timer: Timer
var _target: SubViewport
var _xr_frame: MeshInstance3D
var _world_scale := 0.0
var _desktop := false

func mount(camera: Camera3D, vr: bool) -> void:
	name = "CamcorderHUD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desktop = not vr
	if vr:
		_mount_xr(camera)
	else:
		var layer := CanvasLayer.new()
		layer.name = "CamcorderOverlay"
		layer.layer = 4
		camera.add_child(layer)
		layer.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_refresh)
	_flow_timer = Timer.new()
	_flow_timer.one_shot = true
	_flow_timer.wait_time = 1.15
	_flow_timer.timeout.connect(func():
		flow = ""
		_refresh())
	add_child(_flow_timer)
	set_process(vr)
	_refresh()

func _mount_xr(camera: Camera3D) -> void:
	_target = SubViewport.new()
	_target.name = "ViewfinderTexture"
	_target.size = XR_PIXELS
	_target.transparent_bg = true
	_target.disable_3d = true
	_target.render_target_update_mode = SubViewport.UPDATE_DISABLED
	camera.add_child(_target)
	_target.add_child(self)

	_xr_frame = MeshInstance3D.new()
	_xr_frame.name = "Viewfinder"
	_xr_frame.layers = VIEWFINDER_LAYER
	# Keep the whole HUD in the common field of view, at a comfortable stereo depth.
	_xr_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = Vector2(XR_FRAME_WIDTH, XR_FRAME_WIDTH * float(XR_PIXELS.y) / float(XR_PIXELS.x))
	_xr_frame.mesh = quad
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ink.no_depth_test = true
	ink.render_priority = 20
	ink.albedo_texture = _target.get_texture()
	_xr_frame.material_override = ink
	camera.add_child(_xr_frame)
	_sync_xr_scale()
	visibility_changed.connect(func():
		_xr_frame.visible = visible
		if visible:
			_refresh())

func _process(_delta: float) -> void:
	if _xr_frame != null:
		_sync_xr_scale()

func _sync_xr_scale() -> void:
	var current_scale := XRServer.world_scale
	if not is_equal_approx(current_scale, _world_scale):
		_world_scale = current_scale
		_xr_frame.position = Vector3(0, _cfg_offset, -_cfg_distance) * current_scale
		_xr_frame.scale = Vector3.ONE * current_scale

func set_level(caption: String) -> void:
	if level != caption:
		level = caption
		_refresh()

## Set the viewfinder from a config ({"vr": {...}, "desktop": {...}}); what is missing keeps its usual value, what is
## out of range is brought into it. Takes effect at once. Returns the values now in use.
func configure(config: Dictionary) -> Dictionary:
	var found: Variant = config.get("desktop" if _desktop else "vr")
	var section: Dictionary = found if found is Dictionary else {}
	_cfg_text = clampf(float(section.get("text_scale", 1.0)), 0.4, 3.0)
	_cfg_margin = clampf(float(section.get("margin_scale", 1.0)), 0.0, 8.0)
	_cfg_sung_at = clampf(float(section.get("sung_line_at", 0.0 if _desktop else 0.74)), 0.0, 1.0)
	_cfg_sung_width = clampf(float(section.get("sung_line_width", 0.62 if _desktop else 0.45)), 0.1, 1.0)
	var placed: Variant = section.get("elements")
	_cfg_elements = (placed as Dictionary).duplicate(true) if placed is Dictionary else {}
	var used := {"section": "desktop" if _desktop else "vr", "elements": _cfg_elements, "text_scale": _cfg_text, "margin_scale": _cfg_margin, "sung_line_at": _cfg_sung_at, "sung_line_width": _cfg_sung_width}
	if not _desktop:
		_cfg_width = clampf(float(section.get("frame_width_m", XR_FRAME_WIDTH)), 0.3, 6.0)
		_cfg_height = clampf(float(section.get("frame_height_m", XR_FRAME_WIDTH * float(XR_PIXELS.y) / float(XR_PIXELS.x))), 0.2, 6.0)
		_cfg_distance = clampf(float(section.get("distance_m", XR_DEPTH)), 0.3, 5.0)
		_cfg_offset = clampf(float(section.get("vertical_offset_m", XR_VERTICAL_OFFSET)), -2.0, 2.0)
		_cfg_pixels = clampi(int(section.get("pixels_wide", XR_PIXELS.x)), 512, 4096)
		used.merge({"frame_width_m": _cfg_width, "frame_height_m": _cfg_height, "distance_m": _cfg_distance, "vertical_offset_m": _cfg_offset, "pixels_wide": _cfg_pixels,
			"degrees_out_to_the_side": snappedf(rad_to_deg(atan(_cfg_width * .5 / _cfg_distance)), .1)})
		if _xr_frame != null:
			(_xr_frame.mesh as QuadMesh).size = Vector2(_cfg_width, _cfg_height)
			_target.size = Vector2i(_cfg_pixels, maxi(64, roundi(_cfg_pixels * _cfg_height / _cfg_width)))
			_world_scale = 0.0
			_sync_xr_scale()
	_refresh()
	return used

func set_sung(text: String, plain: String = "") -> void:
	var next_plain := "" if text.is_empty() else plain.strip_edges()
	if sung != text or sung_plain != next_plain:
		sung = text
		sung_plain = next_plain
		_refresh()

func set_charge(value: float, difference: float = 0.0) -> void:
	var next_percent := ceili(clampf(value, 0.0, 100.0))
	var next_fill := snappedf(clampf(value / 100.0, 0.0, 1.0), .005)
	var next_flow := "DRAIN" if difference < 0.0 else ("CHG" if difference > 0.0 else "")
	if next_flow.is_empty():
		_flow_timer.stop()
	else:
		_flow_timer.start()
	if percent != next_percent or not is_equal_approx(battery_fill, next_fill) or flow != next_flow:
		percent = next_percent
		battery_fill = next_fill
		flow = next_flow
		_refresh()

func _refresh() -> void:
	queue_redraw()
	if _target != null:
		_target.render_target_update_mode = SubViewport.UPDATE_ONCE

func _draw() -> void:
	var font_size := maxi(8, roundi(float(clampi(roundi(size.y * .026), 13, 24)) * _cfg_text))
	if not _cfg_elements.is_empty():
		# Leave horizontal room for the battery plate beside the wrapped lyrics on narrow windows.
		var placed_size := mini(font_size, maxi(8, floori(size.x * .019)))
		_draw_placed(placed_size, float(placed_size) / 18.0)
		return
	var unit := float(font_size) / 18.0
	var inset := clampf(size.y * .052, 17, 48) * _cfg_margin
	var left := inset + 10.0 * unit
	var right := size.x - left
	var top := inset + 10.0 * unit
	var bottom := size.y - top
	var row_height := 31.0 * unit
	var brackets := Rect2(Vector2(inset, inset), size - Vector2.ONE * inset * 2.0)
	_draw_brackets(brackets, 19.0 * unit)

	var id_size := FONT.get_string_size("REC   MODEL B", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_rect(Rect2(left, top, id_size.x + 32.0 * unit, row_height), PLATE)
	draw_circle(Vector2(left + 11.0 * unit, top + row_height * .5), 3.5 * unit, RECORD)
	_write("REC   MODEL B", Vector2(left + 22.0 * unit, top + 21.0 * unit), font_size, INK)
	_draw_battery(right, top, row_height, font_size, unit)

	var caption_y := bottom - row_height
	var caption_width := right - left
	if not sung.is_empty():
		# the sung line: in the middle, one row above the bottom row, wrapped if it is long
		var line := TextParagraph.new()
		line.alignment = HORIZONTAL_ALIGNMENT_CENTER
		# in the headset the frame's bottom row is far down (36 degrees): the line is kept where it can be read without
		# looking away from the room, about 18 degrees below the middle, and narrower
		var share := _cfg_sung_width if _cfg_sung_width > 0.0 else (.62 if _desktop else .45)
		var max_w := (right - left) * share
		line.width = minf(max_w, FONT.get_string_size(sung, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2.0)
		line.add_string(sung, FONT, font_size)
		var block := line.get_size()
		var plain_line: TextParagraph = null
		var plain_block := Vector2.ZERO
		var gap := 0.0
		if not sung_plain.is_empty():
			var plain_size := maxi(10, font_size - 4)
			plain_line = TextParagraph.new()
			plain_line.alignment = HORIZONTAL_ALIGNMENT_CENTER
			plain_line.width = minf(max_w, FONT.get_string_size(sung_plain, HORIZONTAL_ALIGNMENT_LEFT, -1, plain_size).x + 2.0)
			plain_line.add_string(sung_plain, FONT, plain_size)
			plain_block = plain_line.get_size()
			gap = 9.0 * unit
		var total_w := maxf(block.x, plain_block.x)
		var total_h := block.y + gap + plain_block.y
		var sung_at := _cfg_sung_at if _cfg_sung_at >= 0.0 else (0.0 if _desktop else .74)
		var foot := caption_y - 22.0 * unit if sung_at <= 0.0 else size.y * sung_at
		var top_y := foot - total_h
		var plate_x := (size.x - total_w) * .5
		draw_rect(Rect2(Vector2(plate_x, top_y) - Vector2(14.0, 6.0) * unit, Vector2(total_w, total_h) + Vector2(28.0, 12.0) * unit), PLATE)
		line.draw(get_canvas_item(), Vector2((size.x - block.x) * .5, top_y), INK)
		if plain_line != null:
			var div_y := top_y + block.y + 4.0 * unit
			draw_line(Vector2(plate_x, div_y), Vector2(plate_x + total_w, div_y), PLAIN_DIVIDER, maxf(1.0, unit))
			plain_line.draw(get_canvas_item(), Vector2((size.x - plain_block.x) * .5, top_y + block.y + gap), PLAIN_INK)
	if _desktop:
		var help_font := maxi(12, font_size - 4)
		var help := "F1  CONTROLS"
		var help_width := FONT.get_string_size(help, HORIZONTAL_ALIGNMENT_LEFT, -1, help_font).x + 18.0 * unit
		if caption_width > help_width * 2.0:
			var help_x := right - help_width
			draw_rect(Rect2(help_x, caption_y, help_width, row_height), PLATE)
			_write(help, Vector2(help_x + 9.0 * unit, caption_y + 21.0 * unit), help_font, INK)
			caption_width -= help_width + 8.0 * unit
	if not level.is_empty():
		var level_width := FONT.get_string_size(level, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var limit := maxf(1.0, caption_width - 20.0 * unit)
		var caption := TextLine.new()
		caption.add_string(level, FONT, font_size)
		caption.width = minf(level_width, limit)
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		draw_rect(Rect2(left, caption_y, caption.width + 20.0 * unit, row_height), PLATE)
		var baseline := caption_y + 21.0 * unit
		caption.draw(get_canvas_item(), Vector2(left + 10.0 * unit, baseline - caption.get_line_ascent()), INK)

# ---- items placed from the config ("elements"): each has "at" [x, y] as shares of the picture (0 0 top left, 1 1
# bottom right; y is the middle of its row), "align" left / center / right (which edge of the item sits at x), "show",
# and for the texts "width" (the share of the picture's width they may take). Palle 2026-11-16: in a headset all of it
# in one row at the bottom, nearer the middle: the map's name left, the charge right, the sung line between.
func _element(key: String) -> Dictionary:
	var found: Variant = _cfg_elements.get(key)
	return found if found is Dictionary else {}

func _place(e: Dictionary, width: float, fallback: Vector2) -> Vector2:
	var at: Variant = e.get("at")
	var share := Vector2(float(at[0]), float(at[1])) if at is Array and (at as Array).size() >= 2 else fallback
	var align := str(e.get("align", "center"))
	var x := share.x * size.x
	if align == "right": x -= width
	elif align != "left": x -= width * .5
	return Vector2(x, share.y * size.y)

func _draw_placed(font_size: int, unit: float) -> void:
	var row_height := 31.0 * unit
	var e := _element("brackets")
	if bool(e.get("show", false)):
		var inset := clampf(size.y * .052, 17, 48) * _cfg_margin
		_draw_brackets(Rect2(Vector2(inset, inset), size - Vector2.ONE * inset * 2.0), 19.0 * unit)
	e = _element("rec")
	if bool(e.get("show", false)):
		var id_width := FONT.get_string_size("REC   MODEL B", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 32.0 * unit
		var at := _place(e, id_width, Vector2(.5, .1))
		var top := at.y - row_height * .5
		draw_rect(Rect2(at.x, top, id_width, row_height), PLATE)
		draw_circle(Vector2(at.x + 11.0 * unit, top + row_height * .5), 3.5 * unit, RECORD)
		_write("REC   MODEL B", Vector2(at.x + 22.0 * unit, top + 21.0 * unit), font_size, INK)
	e = _element("charge")
	if bool(e.get("show", true)):
		var at := _place(e, 166.0 * unit, Vector2(.85, .86))
		_draw_battery(at.x + 166.0 * unit, at.y - row_height * .5, row_height, font_size, unit)
	e = _element("level")
	if bool(e.get("show", true)) and not level.is_empty():
		var caption := TextLine.new()
		caption.add_string(level, FONT, font_size)
		caption.width = minf(FONT.get_string_size(level, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x, maxf(1.0, float(e.get("width", .2)) * size.x - 20.0 * unit))
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var at := _place(e, caption.width + 20.0 * unit, Vector2(.15, .86))
		var top := at.y - row_height * .5
		draw_rect(Rect2(at.x, top, caption.width + 20.0 * unit, row_height), PLATE)
		caption.draw(get_canvas_item(), Vector2(at.x + 10.0 * unit, top + 21.0 * unit - caption.get_line_ascent()), INK)
	e = _element("sung")
	if bool(e.get("show", true)) and not sung.is_empty():
		var max_w := maxf(40.0, float(e.get("width", .28)) * size.x - 20.0 * unit)
		var line := TextParagraph.new()
		line.alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.width = minf(max_w, FONT.get_string_size(sung, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2.0)
		line.add_string(sung, FONT, font_size)
		var block := line.get_size()
		var plain_line: TextParagraph = null
		var plain_block := Vector2.ZERO
		var gap := 0.0
		if not sung_plain.is_empty():
			var plain_size := maxi(10, font_size - 4)
			plain_line = TextParagraph.new()
			plain_line.alignment = HORIZONTAL_ALIGNMENT_CENTER
			plain_line.width = minf(max_w, FONT.get_string_size(sung_plain, HORIZONTAL_ALIGNMENT_LEFT, -1, plain_size).x + 2.0)
			plain_line.add_string(sung_plain, FONT, plain_size)
			plain_block = plain_line.get_size()
			gap = 8.0 * unit
		var total_w := maxf(block.x, plain_block.x)
		var total_h := block.y + gap + plain_block.y
		var at := _place(e, total_w + 20.0 * unit, Vector2(.5, .86))
		var top := at.y - row_height * .5
		if line.get_line_count() <= 1 and plain_line == null:
			# one line: a plate like the others, on the same row
			draw_rect(Rect2(at.x, top, block.x + 20.0 * unit, row_height), PLATE)
			line.draw(get_canvas_item(), Vector2(at.x + 10.0 * unit, top + 21.0 * unit - line.get_line_ascent(0)), INK)
		else:
			# multi-line or paired poetic + plain grows upward cleanly from the row's foot
			var plate_top := top + row_height - total_h - 12.0 * unit
			draw_rect(Rect2(at.x, plate_top, total_w + 20.0 * unit, total_h + 12.0 * unit), PLATE)
			var text_top := plate_top + 6.0 * unit
			line.draw(get_canvas_item(), Vector2(at.x + 10.0 * unit + (total_w - block.x) * .5, text_top), INK)
			if plain_line != null:
				var div_y := text_top + block.y + 4.0 * unit
				draw_line(Vector2(at.x + 10.0 * unit, div_y), Vector2(at.x + 10.0 * unit + total_w, div_y), PLAIN_DIVIDER, maxf(1.0, unit))
				plain_line.draw(get_canvas_item(), Vector2(at.x + 10.0 * unit + (total_w - plain_block.x) * .5, text_top + block.y + gap), PLAIN_INK)

func _draw_brackets(bounds: Rect2, length: float) -> void:
	for sign_x in [1, -1]:
		for sign_y in [1, -1]:
			var corner := Vector2(bounds.position.x if sign_x == 1 else bounds.end.x, bounds.position.y if sign_y == 1 else bounds.end.y)
			var horizontal := corner + Vector2(sign_x * length, 0)
			var vertical := corner + Vector2(0, sign_y * length)
			draw_line(corner + Vector2.ONE, horizontal + Vector2.ONE, PLATE, 2.0)
			draw_line(corner + Vector2.ONE, vertical + Vector2.ONE, PLATE, 2.0)
			draw_line(corner, horizontal, INK, 1.0)
			draw_line(corner, vertical, INK, 1.0)

func _draw_battery(right: float, top: float, height: float, font_size: int, unit: float) -> void:
	var left := right - 166.0 * unit
	var color := EMPTY if percent <= 8 else (LOW if percent <= 20 else INK)
	draw_rect(Rect2(left, top, right - left, height), PLATE)
	if not flow.is_empty():
		_write(flow, Vector2(left + 9.0 * unit, top + 20.0 * unit), maxi(11, font_size - 5), color)
	var bounds := Rect2(Vector2(left + 57.0 * unit, top + 8.0 * unit), Vector2(49.0, 15.0) * unit)
	draw_rect(bounds, color, false, maxf(1.0, unit))
	draw_rect(Rect2(bounds.end.x, bounds.position.y + 4.0 * unit, 3.0 * unit, 7.0 * unit), color)
	for segment in SEGMENTS:
		var bar := Rect2(bounds.position + Vector2(3.0 + 9.0 * segment, 3.0) * unit, Vector2(7.0, 9.0) * unit)
		draw_rect(bar, Color(color, .22))
		bar.size.x *= clampf(battery_fill * SEGMENTS - segment, 0.0, 1.0)
		if bar.size.x > 0.0:
			draw_rect(bar, color)
	_write("%3d%%" % percent, Vector2(left + 114.0 * unit, top + 21.0 * unit), font_size, color)

func _write(text: String, at: Vector2, font_size: int, color: Color) -> void:
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
