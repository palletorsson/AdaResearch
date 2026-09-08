extends Node3D
class_name SketchMonitor

# @identity
# essence: a monitor standing in the room that runs a 2D sketch — Processing's draw() loop, on a screen you can walk up to
# desire: the learner meets the flat world INSIDE the round one, and can see that a sketch is a rule running per frame rather than a picture
# critical_parameter: sketch — which one is running. The screen is the frame; the sketch is the argument
# triggers: nothing. It runs on its own, like a sketch does
# emerges: 2D in 3D — a plane of pixels with its own coordinate system, standing in a room with another
# needs: nothing outside itself; the SubViewport renders whether or not anyone is looking
# relationships: the flat twin of CoordinateSystem3M in Point_Lines — one coordinate system you stand in, one you stand in front of
# truth: a sketch is not an image. It is a rule that is run again every frame, and the image is what is left over
#
## 2026-09-08, Palle: "In the point line we can make an artifact that is a
## monitor, that can take processing like 2D sketches and reproduce these
## examples. 2d in 3d. The first example can be moving scan lines."
##
## SO THE SKETCH IS THE UNIT, NOT THE MONITOR. This is a host: a chassis, a
## screen, and a SubViewport whose 2D contents are drawn by a Sketch object. To
## add the next example you write a Sketch subclass and add one line to _make();
## you do not touch the monitor. That matters because the examples are a course —
## Palle's own Processing path runs coordinate → shape → colour → variable →
## motion → randomness → noise → oscillation, and every one of them is a draw()
## loop over a 2D canvas.
##
## WHY A SubViewport AND NOT A SHADER. A shader could draw scan lines in three
## lines and would be the wrong answer: it would make THIS example easy and every
## later one impossible, because a Processing sketch is imperative drawing over
## time (draw_line, draw_rect, a for loop, state between frames), not a function
## of uv. The viewport gives the sketch a real 2D canvas with its own origin,
## which is the whole "2D in 3D" claim. The oscilloscope artifact takes the same
## road (oscilloscope_artifact.gd:67).
##
## THE SCREEN IS UNSHADED AND EMISSIVE, so it reads as a thing that is lit from
## inside rather than a poster the hall's lights fall on. Same treatment the
## oscilloscope gives its own screen.

## Which sketch is on. Adding a value here and a branch in _make() is the whole
## cost of a new example.
@export_enum("scan_lines") var sketch: String = "scan_lines"
## The canvas, in pixels. This is the sketch's own coordinate system — its
## width/height, the numbers a Processing sketch calls width and height.
@export var canvas_px: Vector2i = Vector2i(480, 360)
## The screen, in metres. Aspect is taken from canvas_px, so a sketch is never
## stretched: set the width and the height follows.
@export var screen_w_m: float = 0.86
@export var lit: float = 1.35
@export var chassis_color: Color = Color(0.16, 0.16, 0.19)
## Sketches that run on a clock read this. 1.0 is real time.
@export var speed: float = 1.0

var _viewport: SubViewport
var _host: Node2D
var _screen: MeshInstance3D
var _sketch: Sketch


# ── the sketch surface ────────────────────────────────────────────────────────
## What a sketch IS, and the whole contract for adding one.
##
## Deliberately Processing-shaped: setup() runs once when the sketch is put on
## the screen, draw() runs every frame with the canvas size and the elapsed
## time. `t` is seconds (Processing's millis()/1000) and `frame` is frameCount,
## because those are the two clocks every example in that course reaches for.
##
## A sketch draws with the CanvasItem API — draw_line, draw_rect, draw_circle —
## which is the same imperative vocabulary as Processing's line(), rect(),
## ellipse(). It is handed the host so it can call them.
class Sketch:
	var w: float = 0.0
	var h: float = 0.0
	var t: float = 0.0
	var frame: int = 0

	func setup() -> void:
		pass

	func draw(_c: CanvasItem) -> void:
		pass


## MOVING SCAN LINES — the first example.
##
## A field of horizontal lines travelling down the canvas, and one brighter bar
## sweeping through them. It is the right first sketch for a monitor because it
## is the monitor's own native image: a raster is scan lines, and a CRT drew them
## one at a time. The screen is showing you what a screen is.
##
## Everything here is a Processing idiom on purpose — a background, a for loop
## over y, a modulo to wrap, a phase from the clock. Nothing is a shader trick.
class ScanLines extends Sketch:
	var spacing: float = 7.0
	var scroll_px_s: float = 34.0
	var sweep_px_s: float = 190.0
	var ink := Color(0.42, 0.86, 0.52)

	func draw(c: CanvasItem) -> void:
		c.draw_rect(Rect2(0, 0, w, h), Color(0.03, 0.05, 0.04), true)

		# the raster: a line every `spacing` px, the whole field sliding down and
		# wrapping — one modulo, exactly as a Processing sketch would write it
		var offset: float = fmod(t * scroll_px_s, spacing)
		var y: float = offset - spacing
		while y < h:
			c.draw_line(Vector2(0.0, y), Vector2(w, y), ink * Color(1, 1, 1, 0.30), 1.0)
			y += spacing

		# THE SWEEP: one brighter bar travelling down, with a short tail behind
		# it. This is what makes the image read as SCANNING rather than as a
		# static hatch — the difference between a picture of lines and a raster
		# being drawn.
		var sweep: float = fmod(t * sweep_px_s, h + 120.0) - 60.0
		for i in 14:
			var yy: float = sweep - float(i) * 3.0
			if yy < 0.0 or yy > h:
				continue
			var fade: float = 1.0 - float(i) / 14.0
			c.draw_line(Vector2(0.0, yy), Vector2(w, yy), ink * Color(1, 1, 1, fade * 0.85), 1.6)

		# the vignette edge, so the canvas has a boundary and reads as a screen
		c.draw_rect(Rect2(0, 0, w, h), ink * Color(1, 1, 1, 0.22), false, 2.0)


func _make(which: String) -> Sketch:
	match which:
		_:
			return ScanLines.new()


# ── the monitor ───────────────────────────────────────────────────────────────
func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("sketch"):
		sketch = str(config_data["sketch"])
	if config_data.has("width_m"):
		screen_w_m = float(config_data["width_m"])
	if config_data.has("speed"):
		speed = float(config_data["speed"])
	if config_data.has("lit"):
		lit = float(config_data["lit"])
	if is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()

	var px := Vector2(float(maxi(16, canvas_px.x)), float(maxi(16, canvas_px.y)))
	var h_m: float = screen_w_m * (px.y / px.x)

	# THE CANVAS. update_mode ALWAYS because the sketch is animated; a viewport
	# left on UPDATE_WHEN_VISIBLE renders once headless and the screen freezes,
	# which reads as a broken artifact rather than an idle one.
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(int(px.x), int(px.y))
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	_sketch = _make(sketch)
	_sketch.w = px.x
	_sketch.h = px.y
	_sketch.setup()

	_host = _SketchHost.new()
	_host.set("owner_monitor", self)
	_viewport.add_child(_host)

	# the chassis, a shallow box behind the picture
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(screen_w_m * 1.09, h_m * 1.12, 0.07)
	body.mesh = bm
	body.position = Vector3(0, h_m * 0.5 + 0.02, -0.038)
	body.material_override = _mat(chassis_color, 0.55, 0.0)
	add_child(body)

	# THE SCREEN — the viewport's own texture, unshaded so the hall's lighting
	# cannot dim a thing that is supposed to be emitting
	_screen = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(screen_w_m, h_m)
	_screen.mesh = qm
	_screen.position = Vector3(0, h_m * 0.5 + 0.02, 0.0)
	var m := StandardMaterial3D.new()
	var tex := _viewport.get_texture()
	m.albedo_texture = tex
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = lit
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_screen.material_override = m
	add_child(_screen)


func _process(delta: float) -> void:
	if _sketch == null:
		return
	_sketch.t += delta * speed
	_sketch.frame += 1
	if _host != null and is_instance_valid(_host):
		_host.queue_redraw()


## The Node2D the sketch draws through. It exists only to own a _draw() inside
## the viewport; every mark it makes comes from the Sketch.
class _SketchHost extends Node2D:
	var owner_monitor: Node = null

	func _draw() -> void:
		if owner_monitor == null or not is_instance_valid(owner_monitor):
			return
		var s = owner_monitor.get("_sketch")
		if s != null:
			s.draw(self)


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


## The sketch currently on the screen, for a probe.
func sketch_name() -> String:
	return sketch


func canvas_size() -> Vector2i:
	return _viewport.size if _viewport != null and is_instance_valid(_viewport) else Vector2i.ZERO


func elapsed() -> float:
	return _sketch.t if _sketch != null else 0.0
