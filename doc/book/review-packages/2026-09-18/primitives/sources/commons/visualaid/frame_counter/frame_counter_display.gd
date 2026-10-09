extends Node3D

## Frame Counter Display — the panel that reports the machine's own tick.
##
## STAGE-2 DNA PROMOTION (2026-07-29). Before this the whole artifact was three
## lines: `label.text = "%d" % Engine.get_process_frames()`. Zero exports, so the
## auto-research runner refused it — nothing to turn.
##
## The hard-coded parameter space was hiding in that one format string. A cumulative
## frame count is only ONE of the things a frame counter can say, and it is the least
## honest one: a five-digit number ticking up too fast to read is exactly how time
## looks when you pretend it is continuous. The artifact's own truth line says the
## opposite — "there is no continuous time in real-time 3D, only discrete frame
## steps" — and its @identity has been asking for a rate readout since it was written.
##
## Two axes:
##
##   reading   WHAT the panel reports    count · rate · delta · budget
##   epoch     the WINDOW it summarises  boot · arrival
##
## reading=count, epoch=boot is the old behaviour to the character, and it is the
## default, so all existing placements read the same number they always did.
##
## The axes argue against each other on purpose. `count` says time is an odometer.
## `delta` says a frame is 11 milliseconds wide and you are living inside one.
## `budget` refuses to report a fact at all and reports a verdict against the 90 Hz
## contract the headset signed. And `epoch` asks whose clock this is: the machine has
## been running since before you arrived (boot), or the count started when you walked
## into this room (arrival). Same panel, four different claims about what a frame is.
##
## ── THE TERMINAL (2026-09-03) ─────────────────────────────────────────────────
##
## Palle: "make it bigger, add the label COUNTER as 2d in 3d as part of the counter
## body, make it look more like a hacking terminal, black body and green monitor
## text, like a wall console but simpler."
##
## It was a 1.00 x 0.20 x 0.10 m bar wearing a magenta wireframe shader — a strip
## of readout with no housing, which is why it read as a HUD element stuck to a
## wall rather than as a machine bolted to one. It is now a 1.24 x 0.86 x 0.18 m
## console: a black casing, a bezel, a recessed screen, and the word COUNTER cut
## across the housing under it.
##
## WHY THE GEOMETRY IS BUILT HERE AND NOT IN THE .tscn. The screen wants a painted
## phosphor texture — scanlines, a corner vignette, and the faint horizontal bloom
## a CRT has — and this corpus's rule is that a texture is painted in code rather
## than loaded from disk. Once the screen is procedural the rest may as well be,
## and the scene file becomes what it should be: a root, a script, and nothing to
## drift out of sync with either.
##
## THE COLLIDER IS PRESERVED DELIBERATELY, layer 1048577 (layers 1 and 21) and mask
## 0, exactly as the old scene declared it. 39 maps place this token, several at a
## y-offset of 3 with a 180-degree rotation — it is already used as a wall panel,
## and something in the interaction lanes is looking for that layer. Changing the
## housing is a look; changing the collider would be a behaviour.
##
## Usage in map_data.json:
##   "frame_counter_display"                                  (legacy: raw frame count)
##   "frame_counter_display#reading:delta"                    (ms per frame, session mean)
##   "frame_counter_display#reading:budget#epoch:arrival"     (live % of the VR budget)
##   "frame_counter_display#reading:count#epoch:arrival"      (frames since you got here)
##   "frame_counter_display#reading:delta#refresh_s:0"        (redrawn every rendered frame)

# @identity
# essence: label.text = Engine.get_process_frames() — a live counter of rendered frames since startup
# desire: learner understands that VR runs as a discrete sequence of frames, not a continuous flow
# critical_parameter: reading — whether the panel reports the running total, the rate, the width of one frame, or the overrun against the VR budget
# triggers: every rendered frame — the number ticks up continuously; pausing the game stops the counter
# emerges: the frame as the fundamental unit of VR time — everything the player experiences is discretised into frames
# needs: [has Label3D [has], has frame-rate and per-frame duration readouts [has]]
# relationships: utility display used alongside interactive scenes; reminds learner of the discrete substrate of 3D
# truth: there is no continuous time in real-time 3D — only discrete frame steps, typically 72 or 90 per second in VR

## What quantity the panel reports.
## count = frames accumulated (the legacy default); rate = frames per second;
## delta = the width of one frame in milliseconds; budget = that width as a
## percentage of the headset's frame budget, so 100% means exactly on time.
@export_enum("count", "rate", "delta", "budget") var reading: String = "count"
## The window the number summarises. boot = the whole session (a running total for
## count, a lifetime mean for the others); arrival = since this panel entered the
## map, which for the rate readings means the present moment rather than the average.
@export_enum("boot", "arrival") var epoch: String = "boot"
## The frame budget the `budget` reading judges against. 90 Hz is the Quest's contract.
@export var target_hz: float = 90.0

## Caption printed on the small side label, per reading and epoch. The panel is
## labelled "Frames"; if it starts reporting milliseconds and the caption still says
## Frames, the artifact is lying about its own units.
const CAPTIONS := {
	"count": {"boot": "Frames", "arrival": "Frames here"},
	"rate": {"boot": "FPS mean", "arrival": "FPS now"},
	"delta": {"boot": "ms mean", "arrival": "ms now"},
	"budget": {"boot": "budget mean", "arrival": "budget now"},
}
const SMOOTHING: float = 0.12
## HOW OFTEN THE RATE READINGS REDRAW (2026-09-04, from the Point_One final's
## artifact proposals). The count reading is rewritten every rendered frame and
## always was; rate, delta and budget settled five times a second behind a
## constant, so the one thing a map could not ask for was a panel that shows the
## frame as fast as the frame happens. 0.2 is the identical default, so every
## placement reads as it did; 0 means redraw on every _process tick.
## Map: `#refresh_s:0`.
@export var refresh_s: float = 0.2

# ── the console, in metres ───────────────────────────────────────────────────
# It hangs on a wall, so the depth is shallow and every number below is measured
# from the wall face outward.
const W: float = 1.24                  # casing width
const H: float = 0.86                  # casing height
const D: float = 0.18                  # casing depth
const BEZEL: float = 0.075             # frame around the screen
# THE GLASS SITS IN FRONT OF THE CASING FACE, NOT BEHIND IT. The casing is
# centred at z = -D/2 so its front face is exactly z = 0, and the first version
# put the screen at z = -0.030 — three centimetres INSIDE the box. It rendered
# a black console with a bezel and no display at all, which looks like a screen
# that failed to light rather than a screen that is not there. The bezel bars
# span z 0.000 to 0.035, so the glass goes just in front of the face and the
# bezel still overhangs it by 28 mm: recessed, without being buried.
const SCREEN_Z: float = 0.006          # the glass, just proud of the casing face
const TEXT_Z: float = 0.013            # the phosphor, just proud of the glass
const SCREEN_H: float = 0.46           # the glass is wider than tall, like a CRT
const PHOSPHOR := Color(0.32, 1.0, 0.44)
const CASING := Color(0.055, 0.058, 0.052)

var label: Label3D = null
var caption: Label3D = null

var _arrival_frame: int = 0
var _avg_delta: float = 0.0
var _since_refresh: float = 999.0
var _built: bool = false


func _ready() -> void:
	_build()
	_arrival_frame = int(Engine.get_process_frames())
	_built = true
	_refresh_caption()


# ── the housing ──────────────────────────────────────────────────────────────

func _build() -> void:
	for c in get_children():
		c.queue_free()

	var body := StaticBody3D.new()
	body.name = "Console"
	# PRESERVED FROM THE OLD SCENE, not chosen: layers 1 and 21, mask 0. Something
	# in the interaction lanes looks for layer 21 and would stop finding this panel
	# if the housing rebuild quietly changed it.
	body.collision_layer = 1048577
	body.collision_mask = 0
	add_child(body)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(W, H, D)
	cs.shape = box
	body.add_child(cs)

	var casing_mat := StandardMaterial3D.new()
	casing_mat.albedo_color = CASING
	casing_mat.roughness = 0.72
	casing_mat.metallic = 0.18
	casing_mat.albedo_texture = _brushed()
	casing_mat.uv1_triplanar = true
	casing_mat.uv1_scale = Vector3(1.4, 1.4, 1.4)

	# the casing itself
	_box(body, Vector3(W, H, D), Vector3(0, 0, -D * 0.5), casing_mat, "Casing")

	# THE BEZEL IS FOUR BARS, NOT A FRAME MESH. A ring of four boxes gives real
	# mitre-free corners and, more usefully, lets the bottom bar be deeper than the
	# other three — which is where the label goes, and why it reads as a housing
	# rather than as a picture frame.
	var sw: float = W - BEZEL * 2.0
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = CASING.lerp(Color(1, 1, 1), 0.06)
	bezel_mat.roughness = 0.55
	bezel_mat.metallic = 0.25
	var top_y: float = SCREEN_H * 0.5 + BEZEL * 0.5
	_box(body, Vector3(W, BEZEL, 0.035), Vector3(0, top_y, 0.017), bezel_mat, "BezelTop")
	_box(body, Vector3(W, BEZEL, 0.035), Vector3(0, -top_y, 0.017), bezel_mat, "BezelBottom")
	_box(body, Vector3(BEZEL, SCREEN_H, 0.035), Vector3(-(sw * 0.5 + BEZEL * 0.5), 0, 0.017), bezel_mat, "BezelLeft")
	_box(body, Vector3(BEZEL, SCREEN_H, 0.035), Vector3(sw * 0.5 + BEZEL * 0.5, 0, 0.017), bezel_mat, "BezelRight")

	# ── the glass ────────────────────────────────────────────────────────────
	#
	# Recessed, so the bezel casts a lip across it and the screen reads as being
	# BEHIND glass rather than printed on the front. Near-black with a green cast,
	# carrying a painted phosphor texture, and faintly emissive so it glows in a
	# dark room without lighting the room.
	var glass := StandardMaterial3D.new()
	# 0.05 GREEN STILL PHOTOGRAPHED AS A GREEN FIELD, and the materials were not
	# lying: a probe read the texture back at max (0.020, 0.106, 0.031) and the
	# emission at 0.13 — all correctly near-black. The brightness was the capture
	# rig KEY LIGHT on a 0.05 albedo, lifted by AgX. A screen has to stay black
	# under a lamp pointed straight at it, which means the albedo has to be dark
	# enough to survive one, not merely dark on paper.
	glass.albedo_color = Color(0.006, 0.014, 0.008)
	glass.albedo_texture = _phosphor()
	glass.roughness = 0.34
	glass.metallic = 0.0
	# THE GLASS DOES NOT EMIT. Measured off the render: with an emissive phosphor
	# texture the LEFT of the screen read (45, 133, 57) and the right (45, 51, 44)
	# — half the glass lit, which is not a CRT, it is a panel catching a lamp.
	# The scanline texture stays on the ALBEDO, where it costs nothing and reads
	# as tube structure, and every photon comes from the unshaded labels in front
	# of it. That is also how the thing actually works: a phosphor glows where a
	# character is struck and nowhere else.
	glass.emission_enabled = false
	_box(body, Vector3(sw, SCREEN_H, 0.006), Vector3(0, 0, SCREEN_Z), glass, "Screen")

	# ── THE READOUT ──────────────────────────────────────────────────────────
	label = Label3D.new()
	label.name = "Readout"
	label.text = "0"
	label.font_size = 130
	label.pixel_size = 0.0016
	label.modulate = PHOSPHOR
	label.outline_size = 0
	# unshaded, so the phosphor is the same brightness whatever lights the room —
	# a CRT is a source, not a surface
	label.shaded = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector3(0.0, 0.055, TEXT_Z)
	body.add_child(label)

	# the units, small, under the number
	caption = Label3D.new()
	caption.name = "Caption"
	caption.text = "Frames"
	caption.font_size = 48
	caption.pixel_size = 0.0016
	caption.modulate = PHOSPHOR * Color(1, 1, 1, 0.85)
	caption.outline_size = 0
	caption.shaded = false
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector3(0.0, -0.115, TEXT_Z)
	body.add_child(caption)

	# a prompt line, so the glass reads as a terminal waiting rather than a gauge
	var prompt := Label3D.new()
	prompt.name = "Prompt"
	prompt.text = "> _"
	prompt.font_size = 34
	prompt.pixel_size = 0.0016
	prompt.modulate = PHOSPHOR * Color(1, 1, 1, 0.55)
	prompt.outline_size = 0
	prompt.shaded = false
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	prompt.position = Vector3(-sw * 0.5 + 0.035, -SCREEN_H * 0.5 + 0.045, TEXT_Z)
	body.add_child(prompt)

	# ── COUNTER, ON THE BODY ─────────────────────────────────────────────────
	#
	# Part of the housing, not of the screen: it sits on the bottom bezel, under
	# the glass, where a machine carries its own name. Letter-spaced by hand
	# because Label3D has no tracking and a terminal's silkscreen is always wide.
	var name_plate := Label3D.new()
	name_plate.name = "NamePlate"
	name_plate.text = "C O U N T E R"
	name_plate.font_size = 44
	name_plate.pixel_size = 0.0016
	name_plate.modulate = PHOSPHOR * Color(1, 1, 1, 0.9)
	name_plate.outline_size = 0
	name_plate.shaded = false
	name_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_plate.position = Vector3(0.0, -top_y, 0.036)
	body.add_child(name_plate)

	# ── the few details that say "machine" ───────────────────────────────────
	#
	# Kept to three, because the brief asked for simpler than the reference: a vent
	# band, one power lamp, and two fixing bolts. Any more and it becomes a prop.
	var vent := StandardMaterial3D.new()
	vent.albedo_color = Color(0.02, 0.02, 0.02)
	vent.roughness = 0.9
	for i in range(9):
		var vx: float = -0.26 + float(i) * 0.065
		_box(body, Vector3(0.030, 0.012, 0.006), Vector3(vx, -H * 0.5 + 0.055, 0.012), vent, "Vent%d" % i)

	var lamp := StandardMaterial3D.new()
	lamp.albedo_color = PHOSPHOR
	lamp.emission_enabled = true
	lamp.emission = PHOSPHOR
	lamp.emission_energy_multiplier = 2.6
	_box(body, Vector3(0.020, 0.020, 0.008), Vector3(W * 0.5 - 0.065, -H * 0.5 + 0.055, 0.012), lamp, "Lamp")

	var bolt := StandardMaterial3D.new()
	bolt.albedo_color = Color(0.30, 0.31, 0.30)
	bolt.roughness = 0.35
	bolt.metallic = 0.85
	for sx in [-1.0, 1.0]:
		_box(body, Vector3(0.024, 0.024, 0.010), Vector3(sx * (W * 0.5 - 0.032), H * 0.5 - 0.032, 0.012), bolt, "Bolt%s" % str(sx))


func _box(parent: Node3D, size: Vector3, at: Vector3, mat: Material, nm: String) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = m
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi


## The phosphor: scanlines, a slow horizontal bloom, and a corner vignette. Painted
## rather than loaded, so the artifact still owns everything it draws.
func _phosphor() -> ImageTexture:
	var w: int = 256
	var h: int = 128
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		# every other line dark: the gap between scanlines is what makes a CRT
		# read as a CRT rather than as a lit rectangle
		var scan: float = 0.55 + 0.45 * (0.5 + 0.5 * cos(float(y) * PI))
		for x in range(w):
			var u: float = float(x) / float(w)
			var v: float = float(y) / float(h)
			# vignette: the corners of a curved tube never get as bright
			var r: float = Vector2(u - 0.5, v - 0.5).length() * 1.9
			var vig: float = clampf(1.0 - r * r * 0.55, 0.0, 1.0)
			var bloom: float = 0.85 + 0.15 * sin(v * PI)
			var g: float = clampf(scan * vig * bloom * 0.11, 0.0, 1.0)
			img.set_pixel(x, y, Color(g * 0.20, g, g * 0.32))
	return ImageTexture.create_from_image(img)


## Brushed metal for the casing — faint, because the housing is meant to be matte
## black and this is only here so a flat black box does not photograph as a hole.
func _brushed() -> ImageTexture:
	var w: int = 64
	var h: int = 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in range(h):
		for x in range(w):
			var n: float = 0.90 + 0.10 * sin(float(x) * 1.7 + sin(float(y) * 0.31) * 2.0)
			img.set_pixel(x, y, Color(n, n, n))
	return ImageTexture.create_from_image(img)


# ── the readout, unchanged in behaviour ──────────────────────────────────────

func _process(delta: float) -> void:
	if label == null:
		return
	if reading == "count":
		# LEGACY LINEAGE — untouched. Rewritten every frame, no smoothing, no refresh
		# gate, because the point of the running total is that it never stops moving.
		label.text = "%d" % _count()
		return

	if _avg_delta <= 0.0:
		_avg_delta = delta
	else:
		_avg_delta = _avg_delta + (delta - _avg_delta) * SMOOTHING

	# A number redrawn 90 times a second is unreadable, so the rate readings settle
	# five times a second by default. The count reading above deliberately does
	# not, and refresh_s = 0 lets a map ask the same of these.
	_since_refresh += delta
	if refresh_s > 0.0 and _since_refresh < refresh_s:
		return
	_since_refresh = 0.0
	label.text = _readout()


func _count() -> int:
	var frames: int = int(Engine.get_process_frames())
	if epoch == "arrival":
		var since: int = frames - _arrival_frame
		return since if since > 0 else 0
	return frames


## The span one frame occupies, in seconds — averaged over the whole session under
## epoch=boot, or as it is right now under epoch=arrival.
func _frame_seconds() -> float:
	if epoch == "boot":
		var uptime: float = float(Time.get_ticks_msec()) / 1000.0
		var frames: int = int(Engine.get_process_frames())
		if frames > 0 and uptime > 0.0:
			return uptime / float(frames)
	return _avg_delta


func _readout() -> String:
	var span: float = _frame_seconds()
	if span <= 0.0:
		return "--"
	match reading:
		"rate":
			return "%d fps" % int(round(1.0 / span))
		"delta":
			return "%.1f ms" % (span * 1000.0)
		"budget":
			var hz: float = target_hz if target_hz > 1.0 else 90.0
			return "%d%%" % int(round(span * hz * 100.0))
	return "%d" % _count()


func _refresh_caption() -> void:
	if caption == null:
		return
	var row: Dictionary = CAPTIONS.get(reading, CAPTIONS["count"])
	caption.text = str(row.get(epoch, row.get("boot", "Frames")))


func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: only touch the caption when a value actually changed and _ready has
	# already run once. An unconditional refresh here would repaint every shipped
	# placement for nothing.
	var changed: bool = false
	if config_data.has("reading"):
		var r: String = str(config_data["reading"])
		if CAPTIONS.has(r) and r != reading:
			reading = r
			changed = true
	if config_data.has("epoch"):
		var e: String = str(config_data["epoch"])
		if (e == "boot" or e == "arrival") and e != epoch:
			epoch = e
			changed = true
	if config_data.has("target_hz"):
		var hz: float = float(config_data["target_hz"])
		if hz > 1.0 and not is_equal_approx(hz, target_hz):
			target_hz = hz
			changed = true
	if config_data.has("refresh_s"):
		var rs: float = maxf(0.0, float(config_data["refresh_s"]))
		if not is_equal_approx(rs, refresh_s):
			refresh_s = rs
			changed = true
	if changed and _built:
		_since_refresh = 999.0
		_refresh_caption()
