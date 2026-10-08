# @identity
# essence: a divided-light window glazed in milky glass, with coloured lamps drifting and cycling hue BEHIND it — the glass never shows you what is back there, only what colour it is
# desire: the learner meets colour as something that arrives already mixed, from sources they cannot resolve — the opposite of a swatch, which is colour with its origin removed
# critical_parameter: frost — the scatter radius the pane reads the screen behind it with. Alpha only dims; frost is the one number that turns a lamp into a patch, and it is why this glass needed a shader
# triggers: _ready() builds frame, mullions, the shader-glazed pane and N lamp/field stacks; the pane's fragment averages twelve jittered taps of the screen behind it; _process() drifts each source on a Lissajous path and rotates its hue by cycle_seconds
# emerges: soft coloured patches sliding across a white pane, overlapping into hues that none of the lamps is — additive mixing performed by the room rather than stated on a chart
# needs: the lamps must stand BEHIND the pane [blur_depth > 0]; a dark-ish hall, because a milky pane in bright light is a white rectangle [the room provides it]; apply_grid_config [present, 2026-09-04]
# relationships: the color sequence's counter-argument to every swatch, wheel and picker in it — those name a colour and hand it to you; this one refuses to name it and makes you take the mix; kin to strobe_lasers (light as event) and to the stained-glass logic of a rose window, where the source is always outside
# truth: frosted glass is a device for destroying information and it is why the colour reads. A clear pane would show you four lamps; the milky one shows you their sum, and the sum is the only place the third colour exists. What you cannot see through, you can see WITH.

extends Node3D
class_name MilkyGlassWindow

@export_category("The window")
@export var width: float = 1.30
@export var height: float = 1.70
@export var frame_width: float = 0.055
@export var frame_depth: float = 0.10
@export var frame_color: Color = Color(0.14, 0.13, 0.13)
## Divided lights. 2 x 3 reads as a window; 1 x 1 reads as a shopfront.
@export_range(1, 6) var panes_x: int = 2
@export_range(1, 6) var panes_y: int = 3
@export var mullion_width: float = 0.026

@export_category("The glass")
## Not white. A white pane under room light is brighter than anything behind
## it and the colour never arrives; the milk has to sit below the lamps.
@export var glass_color: Color = Color(0.80, 0.81, 0.84)
## HOW MUCH MILK. 0 is a clear window onto the lamps, 1 is a painted one.
## Together with `frost` this is the whole artifact: frost decides how far a
## point spreads, milk decides how much of the glass is glass.
@export_range(0.0, 1.0) var glass_alpha: float = 0.42
## THE SCATTER, in screen widths. This is the frosting itself: the pane reads
## twelve samples from a disc of this radius behind it and averages them, so
## a point of light behind the glass arrives as a patch. 0 is polished glass;
## past ~0.03 the window stops being glass and becomes fog.
@export_range(0.0, 0.06, 0.001) var frost: float = 0.016
## The roll of the surface — a fine speckle, so the pane reads as a material
## and not as a value.
@export_range(0.0, 1.0) var grain: float = 0.30
## Lifts what comes through, so a dim lamp reads as colour and not as a grey
## patch. This is the backlit feeling, done to the sample rather than to the
## lighting.
@export_range(0.0, 3.0) var transmit: float = 1.25

@export_category("The disco")
@export_range(1, 10) var lamp_count: int = 5
## How far the lamps stand behind the pane. This distance IS the blur: a lamp on
## the glass is a bright dot, the same lamp 30 cm back is a soft field.
@export var blur_depth: float = 0.34
@export var lamp_energy: float = 3.2
## Radius of each lamp behind the glass. The frost spreads it well past this,
## so a small sphere still fills a pane.
@export var blob_radius: float = 0.11
## Seconds for one full turn of the hue wheel.
@export var cycle_seconds: float = 9.0
## How far apart in hue the lamps sit. 1.0 spreads them right around the wheel;
## 0.15 keeps them close and the mixes stay in one family.
@export_range(0.0, 1.0) var hue_spread: float = 1.0
@export var saturation: float = 0.95
@export var drift_speed: float = 0.17
@export var running: bool = true

const MilkyGlassShader: Shader = preload("res://commons/artifacts/milky_glass_window/milky_glass.gdshader")

var _lamps: Array[OmniLight3D] = []
var _sources: Array[Node3D] = []
var _shells: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_lamps.clear()
	_sources.clear()
	_shells.clear()

	_build_frame()
	_build_glass()
	_build_lamps()


func _frame_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = frame_color
	m.roughness = 0.65
	m.metallic = 0.1
	return m


func _bar(nm: String, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


func _build_frame() -> void:
	var mat := _frame_material()
	var w: float = width
	var h: float = height
	var fw: float = frame_width
	var fd: float = frame_depth

	_bar("FrameTop", Vector3(w, fw, fd), Vector3(0, h * 0.5 - fw * 0.5, 0), mat)
	_bar("FrameBottom", Vector3(w, fw, fd), Vector3(0, -h * 0.5 + fw * 0.5, 0), mat)
	_bar("FrameLeft", Vector3(fw, h - fw * 2.0, fd),
			Vector3(-w * 0.5 + fw * 0.5, 0, 0), mat)
	_bar("FrameRight", Vector3(fw, h - fw * 2.0, fd),
			Vector3(w * 0.5 - fw * 0.5, 0, 0), mat)

	# MULLIONS — the bars BETWEEN the lights, so panes_x of 2 gives one bar and
	# not two. A window divided into n lights has n-1 divisions.
	var inner_w: float = w - fw * 2.0
	var inner_h: float = h - fw * 2.0
	for i in range(1, maxi(1, panes_x)):
		var fx: float = -inner_w * 0.5 + inner_w * float(i) / float(panes_x)
		_bar("MullionV%d" % i, Vector3(mullion_width, inner_h, fd * 0.55),
				Vector3(fx, 0, 0), mat)
	for j in range(1, maxi(1, panes_y)):
		var fy: float = -inner_h * 0.5 + inner_h * float(j) / float(panes_y)
		_bar("MullionH%d" % j, Vector3(inner_w, mullion_width, fd * 0.55),
				Vector3(0, fy, 0), mat)


func _build_glass() -> void:
	var pane := MeshInstance3D.new()
	pane.name = "MilkyPane"
	var bm := BoxMesh.new()
	bm.size = Vector3(width - frame_width * 2.0, height - frame_width * 2.0, 0.010)
	pane.mesh = bm
	pane.position = Vector3(0, 0, 0)

	var g := ShaderMaterial.new()
	g.shader = MilkyGlassShader
	g.set_shader_parameter("milk_color", Color(glass_color.r, glass_color.g, glass_color.b, 1.0))
	# the old alpha export now says how much MILK is in the glass, which is what
	# it was always standing in for
	g.set_shader_parameter("milk", clampf(glass_alpha, 0.0, 1.0))
	g.set_shader_parameter("frost", frost)
	g.set_shader_parameter("grain", grain)
	g.set_shader_parameter("transmit", transmit)
	# the pane samples the screen, so it must be sorted AFTER everything it is
	# meant to show
	g.render_priority = 1
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pane.material_override = g
	add_child(pane)


func _build_lamps() -> void:
	var n: int = maxi(1, lamp_count)
	for i in range(n):
		var hue: float = fmod(float(i) / float(n) * hue_spread, 1.0)
		var col: Color = Color.from_hsv(hue, saturation, 1.0)

		var holder := Node3D.new()
		holder.name = "Source%d" % i
		holder.position = Vector3(0, 0, -blur_depth)
		add_child(holder)

		# WHAT YOU SEE THROUGH THE MILK — one OPAQUE sphere, and that word is the
		# whole fix. The first pass built a stack of additive shells to fake a soft
		# falloff, and the pane showed none of it: Godot captures the screen texture
		# BEFORE the transparent pass, so a transparent lamp is not in the screen a
		# transparent pane reads. Only the light spilling onto the frame got through.
		# The shader does the softening now, so the source has no reason to be soft.
		var blob := MeshInstance3D.new()
		blob.name = "Field"
		var sm := SphereMesh.new()
		sm.radius = blob_radius
		sm.height = blob_radius * 2.0
		sm.radial_segments = 24
		sm.rings = 12
		blob.mesh = sm
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = col
		bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bmat.emission_enabled = true
		bmat.emission = col
		bmat.emission_energy_multiplier = 1.4
		blob.material_override = bmat
		blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(blob)
		var stack: Array[MeshInstance3D] = [blob]

		# and the lamp: what makes the frame, the mullions and the room around
		# the window take the colour too. The shader composites what is BEHIND
		# the pane; only a real light puts colour on the wall in front of it.
		var lamp := OmniLight3D.new()
		lamp.name = "Lamp"
		lamp.light_color = col
		lamp.light_energy = lamp_energy
		lamp.omni_range = maxf(1.0, blur_depth * 6.0)
		lamp.shadow_enabled = false
		holder.add_child(lamp)

		_sources.append(holder)
		_shells.append(stack)
		_lamps.append(lamp)


func _process(delta: float) -> void:
	if _lamps.is_empty() or not running:
		return
	_t += delta
	var n: int = _lamps.size()
	# the lamp has to stay inside the frame — the first pass clamped on half the
	# radius and hung half of every lamp outside the window. The frost spreads it
	# further still, so leave the radius plus a margin.
	var edge: float = blob_radius * 1.6
	var half_w: float = maxf(0.0, (width - frame_width * 2.0) * 0.5 - edge)
	var half_h: float = maxf(0.0, (height - frame_width * 2.0) * 0.5 - edge)
	var hue_t: float = fmod(_t / maxf(0.05, cycle_seconds), 1.0)

	for i in range(n):
		var f: float = float(i)
		var phase: float = f * TAU / float(n)
		# LISSAJOUS, and deliberately incommensurate rates: 0.73 against 1.11
		# never closes, so the pattern does not repeat on a loop you can learn.
		var p: float = _t * drift_speed * TAU
		var x: float = half_w * sin(p * 0.73 + phase)
		var y: float = half_h * sin(p * 1.11 + phase * 1.7)
		_sources[i].position = Vector3(x, y, -blur_depth)

		var hue: float = fmod(hue_t + f / float(n) * hue_spread, 1.0)
		var col: Color = Color.from_hsv(hue, saturation, 1.0)
		_lamps[i].light_color = col
		var stack: Array = _shells[i]
		for k in range(stack.size()):
			var mat := (stack[k] as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				mat.albedo_color = col
				mat.emission = col


## Called by the grid system to apply per-cell configuration. Keys honoured:
##   "width" · "height" · "panes_x" · "panes_y" · "frame_color"
##   "glass_alpha" (how much milk) · "glass_color" · "frost" · "grain" · "transmit"
##   "lamps" · "blur_depth" · "lamp_energy" · "blob_radius"
##   "cycle_seconds" · "hue_spread" · "saturation" · "drift_speed" · "running"
## The motion keys never rebuild — a rebuild restarts the drift from centre and
## the whole point is that it is already going when you walk in.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false
	if config_data.has("width"):
		width = float(config_data["width"]); rebuild = true
	if config_data.has("height"):
		height = float(config_data["height"]); rebuild = true
	if config_data.has("panes_x"):
		panes_x = clampi(int(config_data["panes_x"]), 1, 6); rebuild = true
	if config_data.has("panes_y"):
		panes_y = clampi(int(config_data["panes_y"]), 1, 6); rebuild = true
	if config_data.has("frame_color"):
		frame_color = _as_color(config_data["frame_color"], frame_color); rebuild = true
	if config_data.has("glass_alpha"):
		glass_alpha = clampf(float(config_data["glass_alpha"]), 0.0, 1.0); rebuild = true
	if config_data.has("glass_color"):
		glass_color = _as_color(config_data["glass_color"], glass_color); rebuild = true
	if config_data.has("frost"):
		frost = clampf(float(config_data["frost"]), 0.0, 0.06); rebuild = true
	if config_data.has("grain"):
		grain = clampf(float(config_data["grain"]), 0.0, 1.0); rebuild = true
	if config_data.has("transmit"):
		transmit = clampf(float(config_data["transmit"]), 0.0, 3.0); rebuild = true
	if config_data.has("lamps"):
		lamp_count = clampi(int(config_data["lamps"]), 1, 10); rebuild = true
	if config_data.has("blur_depth"):
		blur_depth = float(config_data["blur_depth"]); rebuild = true
	if config_data.has("lamp_energy"):
		lamp_energy = float(config_data["lamp_energy"]); rebuild = true
	if config_data.has("blob_radius"):
		blob_radius = float(config_data["blob_radius"]); rebuild = true

	if config_data.has("cycle_seconds"):
		cycle_seconds = float(config_data["cycle_seconds"])
	if config_data.has("hue_spread"):
		hue_spread = clampf(float(config_data["hue_spread"]), 0.0, 1.0)
	if config_data.has("saturation"):
		saturation = clampf(float(config_data["saturation"]), 0.0, 1.0)
	if config_data.has("drift_speed"):
		drift_speed = float(config_data["drift_speed"])
	if config_data.has("running"):
		running = bool(config_data["running"])

	if rebuild and is_inside_tree():
		_build()


func _as_color(v, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]))
	if v is String and str(v) != "":
		return Color(str(v))
	return fallback
