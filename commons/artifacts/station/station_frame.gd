extends Node3D
class_name StationFrame

const HangarKit := preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: the GRID-MODULAR portal frame a curated item stands INSIDE — four corner posts and a top rectangle of beams that draw a doorway-without-a-door around a footprint, frame_width × frame_depth metres on the floor, rising to frame_height. Origin at the floor centre; the top beam ring sits at frame_height. An open accent-lit threshold that says "look here, through this" without enclosing.
# desire: to ring one thing (or one platform) with a clean upright threshold so the eye reads it as framed, addressed, presented through an opening — architecture that points without walling in. To turn an open patch of floor into a stated aperture.
# critical_parameter: frame_width × frame_height + bar_style — how wide and tall the opening reads, and whether the ring is bare structure (open), filled cells (paneled), or detailed with greebles (greebled); the composer sizes width/depth to the item's footprint + a margin.
# triggers: _ready/_read_metadata_overrides/_build from DNA; apply_grid_config rebuilds at a new size/style.
# emerges: bare posts + top ring reads "threshold, pass through"; lit joints read "powered, active gate"; paneled bars read "screen / billboard frame"; greebled bars read "serviced industrial portal". Tall + narrow = a doorway for a specimen; low + wide = a proscenium over a stage.
# needs: four corner posts [present]; a top beam rectangle [present]; optional lit corner joints [optional]; optional bar fill (panels or greebles) [optional]; a wear pass [present].
# relationships: the open-air cousin of [[station_wall]] (frame an aperture vs. back a wall) and [[station_pillar]] (a single upright vs. a ring of four); rings a [[station_plinth]] or a [[station_stage]]; promoted from curation_station._build_frame; shares the HangarKit family look.
# truth: a frame is a claim made by absence — it presents a thing by drawing the edge of an opening around it and leaving the middle empty. The most honest pedestal for the eye is a door you do not close.

@export_group("Dimensions")
## Aperture width (X) in metres — the clear span between the side posts' centres + post.
@export var frame_width: float = 2.0
## Aperture height (Y) in metres — floor to top beam ring.
@export var frame_height: float = 2.2
## Aperture depth (Z) in metres — front-to-back span between the post ring.
@export var frame_depth: float = 2.0

@export_group("Structure")
## Corner post side (square section).
@export var post_size: float = 0.16
## Top beam side (square section).
@export var beam_size: float = 0.14
## "open" (bare structure) | "paneled" (filled cells) | "greebled" (detailed industrial).
@export var bar_style: String = "open"
## Emissive accent blocks at the four top corners.
@export var lit_joints: bool = true

@export_group("Surface")
@export var wear: float = 0.08

@export_group("Color")
@export var body_color: Color = Color(0.81, 0.79, 0.75)
@export var accent_color: Color = Color(0.86, 0.34, 0.11)

var _built := false

func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_frame_width"): frame_width = float(str(get_meta("config_frame_width")))
	if has_meta("config_frame_height"): frame_height = float(str(get_meta("config_frame_height")))
	if has_meta("config_frame_depth"): frame_depth = float(str(get_meta("config_frame_depth")))
	if has_meta("config_post_size"): post_size = float(str(get_meta("config_post_size")))
	if has_meta("config_beam_size"): beam_size = float(str(get_meta("config_beam_size")))
	if has_meta("config_bar_style"): bar_style = str(get_meta("config_bar_style")).to_lower()
	if has_meta("config_lit_joints"): lit_joints = _b(get_meta("config_lit_joints"))
	if has_meta("config_wear"): wear = float(str(get_meta("config_wear")))
	if has_meta("config_body_color"): body_color = _pc(str(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"): accent_color = _pc(str(get_meta("config_accent_color")), accent_color)


func _build() -> void:
	_built = true
	var hw: float = maxf(frame_width, 0.4) * 0.5
	var hd: float = maxf(frame_depth, 0.4) * 0.5
	var h: float = maxf(frame_height, 0.6)
	var post: float = clampf(post_size, 0.06, 0.5)
	var beam: float = clampf(beam_size, 0.05, 0.5)
	var body_mat := _mat(body_color)

	# Four corner posts — one square upright at each footprint corner.
	for ix in [-1.0, 1.0]:
		for iz in [-1.0, 1.0]:
			add_child(_box(Vector3(ix * hw, h * 0.5, iz * hd), Vector3(post, h, post), body_mat))

	# Top beam rectangle — a closed ring of four beams at frame_height.
	var top: float = h
	add_child(_box(Vector3(0, top, -hd), Vector3(hw * 2.0 + post, beam, beam), body_mat))
	add_child(_box(Vector3(0, top, hd), Vector3(hw * 2.0 + post, beam, beam), body_mat))
	add_child(_box(Vector3(-hw, top, 0), Vector3(beam, beam, hd * 2.0 + post), body_mat))
	add_child(_box(Vector3(hw, top, 0), Vector3(beam, beam, hd * 2.0 + post), body_mat))

	# Bar fill — what the threshold reads as between the posts.
	match bar_style:
		"paneled": _build_paneled(hw, hd, h, post)
		"greebled": _build_greebled(hw, hd, h, post, beam)
		_: pass

	# Lit corner joints — a small emissive cube where each post meets the top ring.
	if lit_joints:
		var lit := _emi(accent_color, 0.7)
		var js: float = maxf(post, beam) * 1.18
		for ix in [-1.0, 1.0]:
			for iz in [-1.0, 1.0]:
				add_child(_box(Vector3(ix * hw, top - beam * 0.5, iz * hd), Vector3(js, beam * 1.4, js), lit))

	# A wear / grime band low on the front-left post (the built, used read).
	add_child(HangarKit.grime_band(post * 1.4, 0.05, hd + post * 0.5 + 0.004, body_color))


# PANELED — fill the front + back apertures with a thin inset panel divided into
# vertical cells, so the frame reads as a screen / billboard threshold.
func _build_paneled(hw: float, hd: float, h: float, post: float) -> void:
	var pmat := _mat(body_color.darkened(0.06))
	var span: float = hw * 2.0 - post
	var ph: float = h - post
	var cells: int = maxi(int(span / 0.7), 1)
	var cell_w: float = span / float(cells)
	var t := 0.03
	# A faint emissive backing so the "screen" reads lit.
	var glow := _emi(accent_color.darkened(0.35), 0.25)
	for sz in [1.0, -1.0]:
		var pz: float = sz * (hd - t * 0.5)
		add_child(_box(Vector3(0, post + ph * 0.5, pz), Vector3(span, ph, t * 0.6), glow))
		for i in range(cells):
			var px: float = -span * 0.5 + (float(i) + 0.5) * cell_w
			add_child(_box(Vector3(px, post + ph * 0.5, pz + sz * t * 0.5), Vector3(cell_w * 0.82, ph * 0.9, t), pmat))


# GREEBLED — hang industrial detail off the top ring: a row of conduit stubs and
# a three-colour service bar, so the frame reads as a serviced machine portal.
func _build_greebled(hw: float, hd: float, h: float, post: float, beam: float) -> void:
	var gmat := HangarKit.worn_metal(body_color.darkened(0.1))
	var span: float = hw * 2.0 - post
	var stubs: int = maxi(int(span / 0.4), 2)
	for i in range(stubs):
		var px: float = lerpf(-span * 0.46, span * 0.46, float(i) / float(maxi(stubs - 1, 1)))
		for sz in [1.0, -1.0]:
			add_child(_box(Vector3(px, h - beam - 0.07, sz * hd), Vector3(0.06, 0.14, 0.06), gmat))
	# Service bar on the front-top beam.
	var bar: Node3D = HangarKit.three_color_bar(minf(span * 0.5, 1.0), 0.04, [accent_color, HangarKit.DISPLAY_DARK, body_color])
	if bar != null:
		bar.position = Vector3(0, h - beam * 0.5, hd + beam * 0.5 + 0.01)
		add_child(bar)
	# Corner gusset plates where posts meet the top ring.
	for ix in [-1.0, 1.0]:
		for iz in [-1.0, 1.0]:
			add_child(_box(Vector3(ix * (hw - 0.12), h - 0.16, iz * hd), Vector3(0.24, 0.24, 0.02), gmat))


func _mat(c: Color) -> StandardMaterial3D:
	return HangarKit.rams_body(c, wear)


func _emi(c: Color, energy: float) -> StandardMaterial3D:
	return HangarKit.emissive(c, energy)


func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _b(v) -> bool:
	return str(v).to_lower() in ["true", "1", "yes", "on"]


func _pc(s: String, fallback: Color) -> Color:
	var p := s.split(",")
	if p.size() < 3:
		return fallback
	return Color(float(p[0]), float(p[1]), float(p[2]), 1.0 if p.size() < 4 else float(p[3]))
