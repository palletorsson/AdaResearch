extends SceneTree

## HOW SHOULD A WALL HOLD A SENTENCE IT WAS NOT SIZED FOR?
##
## 2026-08-31, Palle: "Can we test to size the wall works after the text and see
## how that looks, Or can we have the beginning of the text in a bit smaller size
## and ... . And when we click the full text appears."
##
## The occasion: interactive_point_origin_force's wall line went from 71
## characters to 406. em_detail's landscape format holds 85 before the shrink
## loop hits its floor of 28 and the text starts running off the frame — so the
## museum would draw the new line at 3.8x the height of its field.
##
## This renders the three answers side by side, at the museum's own scale, so the
## choice is made by looking rather than by arguing:
##
##   A  TODAY        the sentence as the museum would draw it now — overflowing
##   B  SIZED        the frame grown until the sentence fits, format ratio kept
##   C  LEAD         as much as fits, smaller, ending in an ellipsis; the rest
##                   on click (the reader panel already shows text + note)
##
## It uses EmDetail.speak_fit for every panel, which is the museum's own fitting
## rule and not a copy of it — a second copy is how two surfaces come to disagree
## about whether a wall can hold a sentence.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_wall_fit.gd

const EmDetailRes := preload("res://commons/scenes/em/em_detail.gd")
const OUT := "user://wall_fit"
const ROBOTO := "res://commons/font/Roboto-VariableFont_wdth,wght.ttf"

# the museum's own numbers, read off em_detail so the picture is to scale
const MOUNT_W := 0.090
const FRAME_W := 0.075
const LANDSCAPE := Vector2(1.32, 0.86)

const SENTENCE := "Point One. The first point keeps escalating, inviting your hands. - “Show me what you can do with those hands” but really the hands are no different from the ball, they just code. It is us  that sit with the perspective from here to that dark shiny thing. - Grab the ball. This is the first point but it has already broken the promise of taking it wóne step at the time. We are already Alice in wonderland."

var _root: Window


func _initialize() -> void:
	_run()


func _run() -> void:
	_root = get_root()
	DirAccess.make_dir_recursive_absolute(OUT)

	var n: int = SENTENCE.length()
	var font: Font = load(ROBOTO) if ResourceLoader.exists(ROBOTO) else null
	var budget: int = EmDetailRes.speak_budget(LANDSCAPE.x, LANDSCAPE.y)
	var a_fit: Dictionary = EmDetailRes.speak_fit(n, LANDSCAPE.x, LANDSCAPE.y)

	# B — Palle's note 2: the same frame, but the text as big as it TRULY fits
	var b_fit: Dictionary = EmDetailRes.speak_fit_measured(font, SENTENCE, LANDSCAPE.x, LANDSCAPE.y)

	# C — Palle's note 1: a bigger canvas, measured, wrap following the field
	var big := Vector2(LANDSCAPE.x * 2.0, LANDSCAPE.y * 2.0)
	var c_fit: Dictionary = EmDetailRes.speak_fit_measured(font, SENTENCE, big.x, big.y)

	# D — the lead, for comparison
	var lead: String = _lead(SENTENCE, budget)
	var d_fit: Dictionary = EmDetailRes.speak_fit(lead.length(), LANDSCAPE.x, LANDSCAPE.y)

	print("")
	print("WALL FIT — a %d-character line, measured against the font" % n)
	print("")
	print("  A today (estimated)   font %2d  needs %.2f m of %.2f m   %s"
		% [int(a_fit["font_size"]), float(a_fit["needs"]), float(a_fit["have"]),
		   "fits" if bool(a_fit["fits"]) else "OVERFLOWS %.1fx" % (float(a_fit["needs"]) / float(a_fit["have"]))])
	print("  B same frame, MEASURED font %2d  needs %.2f m of %.2f m   %s"
		% [int(b_fit["font_size"]), float(b_fit["needs"]), float(b_fit["have"]),
		   "fits" if bool(b_fit["fits"]) else "OVERFLOWS"])
	print("  C bigger canvas x2    font %2d  needs %.2f m of %.2f m   %s   wrap %.0f px"
		% [int(c_fit["font_size"]), float(c_fit["needs"]), float(c_fit["have"]),
		   "fits" if bool(c_fit["fits"]) else "OVERFLOWS", float(c_fit["width_px"])])
	print("  D lead + ellipsis     font %2d  %d of %d characters"
		% [int(d_fit["font_size"]), lead.length(), n])
	print("")

	_scene(a_fit, b_fit, big, c_fit, lead, d_fit)
	await _settle()
	await _shot("wall_fit")
	print("  PNG in %s" % ProjectSettings.globalize_path(OUT))
	quit(0)


## As much of the sentence as the budget allows, cut at a word, with an ellipsis.
## The cut is at a SPACE and not at a character, because a label that ends
## mid-word reads as a rendering fault rather than as an invitation to click.
func _lead(s: String, budget: int) -> String:
	if s.length() <= budget:
		return s
	var cut: int = maxi(0, budget - 2)
	var slice: String = s.substr(0, cut)
	var sp: int = slice.rfind(" ")
	if sp > cut / 2:
		slice = slice.substr(0, sp)
	return slice.strip_edges() + " …"


func _scene(a_fit: Dictionary, b_fit: Dictionary, big: Vector2,
		c_fit: Dictionary, lead: String, d_fit: Dictionary) -> void:
	var root := Node3D.new()
	_root.add_child(root)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.80, 0.77, 0.73)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 1.1
	env.environment = e
	root.add_child(env)

	var step: float = big.x * 0.62 + 1.3
	_panel(root, Vector3(-step * 1.6, 0, 0), LANDSCAPE, SENTENCE, a_fit,
		"A  TODAY — font %d, %.1fx too tall" % [int(a_fit["font_size"]),
		float(a_fit["needs"]) / float(a_fit["have"])])
	_panel(root, Vector3(-step * 0.55, 0, 0), LANDSCAPE, SENTENCE, b_fit,
		"B  SAME FRAME, MEASURED — font %d, fits" % int(b_fit["font_size"]))
	_panel(root, Vector3(step * 0.62, 0, 0), big, SENTENCE, c_fit,
		"C  BIGGER CANVAS %.1f x %.1f m, MEASURED — font %d" % [big.x, big.y, int(c_fit["font_size"])])
	_panel(root, Vector3(step * 1.75, 0, 0), LANDSCAPE, lead, d_fit,
		"D  LEAD — %d of %d ch, font %d" % [lead.length(), SENTENCE.length(), int(d_fit["font_size"])])

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(-0.7, -0.5, 0.0)
	key.light_energy = 1.2
	root.add_child(key)

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0.0, 1.58, 7.6)
	cam.look_at_from_position(cam.position, Vector3(0.0, 1.58, 0.0), Vector3.UP)
	cam.current = true


## frame, mount, field and the sentence — the museum's four boxes, to scale.
func _panel(parent: Node3D, at: Vector3, fmt: Vector2, text: String,
		fit: Dictionary, caption: String) -> void:
	var bay := Node3D.new()
	bay.position = at + Vector3(0.0, 1.58, 0.0)
	parent.add_child(bay)

	_box(bay, Vector3(fmt.x + 2.0 * FRAME_W, fmt.y + 2.0 * FRAME_W, 0.02),
		Vector3(0, 0, 0.0), Color(0.95, 0.94, 0.92))          # frame
	_box(bay, Vector3(fmt.x, fmt.y, 0.02), Vector3(0, 0, 0.012), Color(0.88, 0.86, 0.83))   # mount
	var field: Vector2 = fit["field"]
	_box(bay, Vector3(field.x, field.y, 0.02), Vector3(0, 0, 0.024), Color(0.26, 0.24, 0.22))  # field

	var sl := Label3D.new()
	sl.text = text
	sl.pixel_size = float(fit["pixel_size"])
	sl.font_size = int(fit["font_size"])
	sl.width = float(fit["width_px"]) if fit.has("width_px") else 400.0
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sl.modulate = Color(0.93, 0.92, 0.9)
	var rf: Font = load(ROBOTO) if ResourceLoader.exists(ROBOTO) else null
	if rf != null:
		sl.font = rf
	sl.position = Vector3(0, 0, 0.04)
	bay.add_child(sl)

	var cap := Label3D.new()
	cap.text = caption
	cap.pixel_size = 0.0016
	cap.font_size = 40
	cap.modulate = Color(0.15, 0.14, 0.13)
	cap.position = Vector3(0, -(fmt.y * 0.5 + FRAME_W + 0.18), 0.05)
	bay.add_child(cap)


func _box(parent: Node3D, size: Vector3, at: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	mi.material_override = m
	parent.add_child(mi)


func _settle() -> void:
	for i in range(8):
		await process_frame


## RUN THIS WITHOUT --headless. With it, get_texture() comes back NULL: there is
## no rendering device, so there is no viewport texture to read and the save is a
## call on nothing. --no-window alone is the combination the project's own
## capture pipeline uses (see CLAUDE.md), and it is the one that returns a frame.
func _shot(name: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	var tex: ViewportTexture = _root.get_texture()
	if tex == null:
		print("  NO FRAME — get_texture() is null. Drop --headless; --no-window alone renders.")
		return
	var img: Image = tex.get_image()
	print("  save_png -> %d  (%dx%d)" % [img.save_png(OUT + "/" + name + ".png"), img.get_width(), img.get_height()])
