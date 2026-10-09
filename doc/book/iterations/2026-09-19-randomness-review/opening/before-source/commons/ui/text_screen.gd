@tool
extends Node3D
class_name TextScreen
## The canonical text display for Ada Research — ONE way to show text in 3D.
##
## THE RULE: all text is 2D, placed in 3D. A page, a screen, a plate, a placard
## — a flat surface with an edge, hanging or standing somewhere a body could
## walk up to and read. Never glyphs extruded into the world, never a bare
## floating Label3D billboarding at the camera. Text is something the museum
## HANGS, not something it grows.
##
## So it lives on a real object: a framed, softly-lit screen, optionally carried
## at reading height by a slim stand, or laid back at a comfortable angle as a
## pad on a surface. Built on BakedText (text baked into the albedo) so it
## renders headless and takes scene light.
##
## The component owns LEGIBILITY, not the caller. Pass a paragraph and it wraps;
## pass too much and it truncates rather than shrinking below MIN_GLYPH_M; pass
## your own newlines and it leaves them alone. A caller should never have to
## know how this screen sizes glyphs — that knowledge living only in callers'
## heads is what put an unreadable 655-character smear on a museum wall.
##
## Three modes, one component:
##   SCREEN — a framed panel alone (wall mount / console face / floating readout)
##   STAND  — the screen on a slim post at reading height ("text in the air")
##   PAD    — the screen reclined on a low base ("a nice text pad" on a table)
##
## API: set title/body/mode/width and it rebuilds. Use everywhere a label is
## tempted — signage, readouts, info panels, the bead captions, lab screens.

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

enum Mode { SCREEN, STAND, PAD }

@export var mode: Mode = Mode.STAND: set = _set_mode
@export var title: String = "TITLE": set = _set_title
@export_multiline var body: String = "": set = _set_body
@export var width_m: float = 0.46: set = _set_width
## Reading height for STAND (screen centre, metres). PAD ignores it.
@export var stand_height: float = 1.15: set = _set_stand_height

# Ada screen palette — dark glass, cool title, warm-white body. One look everywhere.
@export var bg_color: Color = Color(0.08, 0.10, 0.14)
@export var frame_color: Color = Color(0.16, 0.18, 0.23)
@export var title_color: Color = Color(0.55, 0.75, 1.0)
@export var body_color: Color = Color(0.90, 0.93, 0.98)
@export var post_color: Color = Color(0.20, 0.22, 0.27)

const ASPECT := 0.62          # screen height / width
const BEZEL := 0.018          # frame border thickness, metres
const TITLE_FRAC := 0.26      # top fraction of the screen given to the title bar
## The smallest body glyph that still reads from standing distance, in metres.
## Wrapping and line-count limits are both derived from it, so "will this be
## legible" is answered once, here, instead of by every caller guessing.
const MIN_GLYPH_M := 0.035

var _root: Node3D


func _ready() -> void:
	_rebuild()


func _set_mode(v: Mode) -> void:
	mode = v
	if is_inside_tree(): _rebuild()

func _set_title(v: String) -> void:
	title = v
	if is_inside_tree(): _rebuild()

func _set_body(v: String) -> void:
	body = v
	if is_inside_tree(): _rebuild()

func _set_width(v: float) -> void:
	width_m = maxf(0.08, v)
	if is_inside_tree(): _rebuild()

func _set_stand_height(v: float) -> void:
	stand_height = maxf(0.0, v)
	if is_inside_tree(): _rebuild()


## Public: set both lines at once (the common case).
func set_text(p_title: String, p_body: String = "") -> void:
	title = p_title
	body = p_body
	if is_inside_tree(): _rebuild()


func _rebuild() -> void:
	if _root and is_instance_valid(_root):
		_root.queue_free()
	_root = Node3D.new()
	_root.name = "TextScreenRoot"
	add_child(_root)

	var w := width_m
	var h := w * ASPECT
	var screen := _build_screen(w, h)

	match mode:
		Mode.SCREEN:
			_root.add_child(screen)
		Mode.STAND:
			screen.position = Vector3(0, stand_height, 0)
			_root.add_child(screen)
			_root.add_child(_build_post(stand_height - h * 0.5, w))
		Mode.PAD:
			# Reclined ~32° back, sitting just above a surface on a low wedge.
			var holder := Node3D.new()
			holder.rotation_degrees = Vector3(-58, 0, 0)   # lie back from vertical
			holder.position = Vector3(0, 0.03 + h * 0.32, 0)
			holder.add_child(screen)
			_root.add_child(holder)
			_root.add_child(_build_pad_base(w, h))


## The framed screen: a frame plate, an inset glass, a title strip, and the body.
func _build_screen(w: float, h: float) -> Node3D:
	var node := Node3D.new()
	node.name = "Screen"

	# Frame (slightly larger box behind the glass).
	var frame := MeshInstance3D.new()
	var fbox := BoxMesh.new()
	fbox.size = Vector3(w + BEZEL * 2.0, h + BEZEL * 2.0, 0.012)
	frame.mesh = fbox
	frame.material_override = _mat(frame_color, 0.5, 0.0)
	frame.position.z = -0.008
	node.add_child(frame)

	# Glass background (the dark panel the text sits on).
	var glass := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(w, h, 0.006)
	glass.mesh = gbox
	glass.material_override = _mat(bg_color, 0.15, 0.12)
	node.add_child(glass)

	var title_h := h * TITLE_FRAC
	var body_h := h - title_h

	# Title bar — an opaque tinted band with the title baked across it.
	if title != "":
		var tplate := BakedText.make_panel_mesh(
			title, bg_color.lightened(0.06), title_color,
			Vector2(w * 0.96, title_h * 0.8), 1400, true, {}, "medium")
		if tplate:
			tplate.position = Vector3(0, h * 0.5 - title_h * 0.5, 0.004)
			node.add_child(tplate)

	# Body — baked lines, self-lit so it reads like a screen.
	if body.strip_edges() != "":
		var usable_w := w * 0.92
		var avail_h := body_h * 0.9
		var gap := body_h * 0.04
		var lines := _lay_out(body, usable_w, avail_h)
		# LINE HEIGHT MUST ACCOUNT FOR THE GAP. make_text_block stacks at
		# pitch = line_height + gap and spans pitch * n, so passing
		# avail_h / n overflowed the panel by gap * n — invisible at one line,
		# 18% at seven, and the last line was clipped mid-word on the museum
		# wall. Solve for the pitch that actually fits instead.
		var n := maxf(1, lines.size())
		var line_h: float = maxf(0.004, (avail_h - gap * n) / n)
		# Medium for the title, Regular for the body — the weight split a real
		# wall label makes, now that there is a real typeface to make it with.
		var block := BakedText.make_text_block(
			lines, body_color, line_h, usable_w, gap, true, "regular")
		if block:
			block.position = Vector3(0, -title_h * 0.5, 0.004)
			node.add_child(block)
	return node


## Turn `body` into lines that FIT, so no caller has to know how.
##
## The wrap convention used to live in the caller's head and nowhere else: this
## screen sizes glyphs by line COUNT, so a caller that passed one unwrapped
## paragraph got it squeezed onto a single line at whatever size fit the width.
## A 655-character map blurb hung on a 1.8 m museum wall came out an unreadable
## grey smear for exactly that reason. Callers should not have to know; they
## pass text, they get text.
##
## An explicit newline is still respected — a caller that has laid out its own
## lines has taken control, and this leaves them alone.
func _lay_out(text: String, usable_w: float, avail_h: float) -> PackedStringArray:
	# The widest line that still renders glyphs tall enough to read. A baked
	# line fills its box, so characters-per-line IS the glyph size: a glyph is
	# roughly half as wide as it is tall, hence w / (MIN_GLYPH * 0.5).
	var cols := maxi(12, int(usable_w / maxf(0.001, MIN_GLYPH_M * 0.5)))

	# Existing newlines are RESPECTED but not obeyed blindly. A caller that
	# writes short lines meant them; a paragraph read out of a .md file has
	# newlines that are prose, not layout, and treating those as authored lines
	# is what left a map blurb as two hairline smears on a museum wall. So keep
	# every line that already fits, and reflow only the ones that do not.
	var out := PackedStringArray()
	for raw in text.split("\n"):
		var para := String(raw).strip_edges()
		if para == "":
			continue
		if para.length() <= cols:
			out.append(para)
			continue
		var line := ""
		for word in para.split(" ", false):
			var word_s := String(word)
			if line == "":
				line = word_s
			elif line.length() + 1 + word_s.length() <= cols:
				line += " " + word_s
			else:
				out.append(line)
				line = word_s
		if line != "":
			out.append(line)

	# And a panel can only hold so many lines before the glyphs shrink below
	# legibility again. Past that, say less rather than say it invisibly.
	var max_lines := maxi(1, int(avail_h / MIN_GLYPH_M))
	if out.size() > max_lines:
		out = out.slice(0, max_lines)
		out[max_lines - 1] = String(out[max_lines - 1]) + "…"
	return out


func _build_post(post_h: float, w: float) -> Node3D:
	var node := Node3D.new()
	var post := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.012
	cyl.bottom_radius = 0.012
	cyl.height = maxf(0.05, post_h)
	post.mesh = cyl
	post.material_override = _mat(post_color, 0.4, 0.0)
	post.position.y = post_h * 0.5
	node.add_child(post)
	# Foot.
	var foot := MeshInstance3D.new()
	var foot_cyl := CylinderMesh.new()
	foot_cyl.top_radius = w * 0.28
	foot_cyl.bottom_radius = w * 0.32
	foot_cyl.height = 0.02
	foot.mesh = foot_cyl
	foot.material_override = _mat(post_color, 0.4, 0.0)
	foot.position.y = 0.01
	node.add_child(foot)
	return node


func _build_pad_base(w: float, h: float) -> Node3D:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(w + BEZEL * 2.0, 0.03, h * 0.5)
	base.mesh = box
	base.material_override = _mat(post_color, 0.4, 0.0)
	base.position = Vector3(0, 0.015, h * 0.18)
	return base


func _mat(c: Color, rough: float, emission: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	return m


## Grid-config hook so maps/DNA can drive it.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("title"): title = str(config_data["title"])
	if config_data.has("body"): body = str(config_data["body"])
	if config_data.has("mode"):
		var m := str(config_data["mode"]).to_upper()
		mode = {"SCREEN": Mode.SCREEN, "STAND": Mode.STAND, "PAD": Mode.PAD}.get(m, mode)
	if config_data.has("width"): width_m = float(config_data["width"])
	_rebuild()
