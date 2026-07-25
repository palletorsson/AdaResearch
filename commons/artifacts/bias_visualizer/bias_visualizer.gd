# bias_visualizer.gd
extends Node3D
class_name BiasVisualizer

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# @identity
# essence: embedding_space(words, gender_axis) -> proximity_reveals_prejudice
# desire: see whose edge cases the training data forgot
# critical_parameter: analogy_type — switches between gender-profession, gender-trait, and algorithmic redlining
# triggers: push-button selection cycles analogy modes; word proximity to gendered anchors shifts meaning
# emerges: the uncomfortable recognition that "neutral" embeddings reproduce structural inequality
# needs: VR push buttons [has], rotation toggle [has], word grab interaction [missing]
# relationships: unlocks critical algorithmic thinking; depends on foundations crisis (incompleteness); contrasts ordered_grid (perfect pattern vs biased pattern)
# truth: classification systems do not describe the world — they encode whose categories get to count
## Visualizes bias in word embeddings using a 3D word cloud.
## Words are positioned in a simulated embedding space where proximity to
## gendered anchors (man/woman) reveals learned stereotypical associations.
## Three analogy modes show gender-profession, gender-trait, and algorithmic
## redlining patterns. VR-enabled with push-button analogy selection.

## Overall scale of the embedding space display (meters)
@export_range(0.5, 3.0, 0.1) var display_size: float = 1.0
## Radius of each word sphere in the cloud (meters)
@export_range(0.01, 0.2, 0.01) var word_scale: float = 0.05

# ── The taxonomy vitrine (cabinet grammar, vertical dialect) ─────────────────
## Housing finish — "rams" (light Braun default) or "terminal" (dark console).
## The whole case derives from HangarKit.finish_palette(), so one word re-skins
## every part instead of a dozen hand-typed colours.
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "BV-01"
## Pedestal height. The case is authored from y=0 up; the plinth hangs BELOW the
## origin and auto-grounding lifts the assembly, which puts the keypad and the
## caption in the VR reach band without moving a single authored coordinate.
@export var plinth_height: float = 0.72

## Color for male-gendered words (man, he, king)
@export var male_color: Color = Color(0.3, 0.5, 1.0)
## Color for female-gendered words (woman, she, queen)
@export var female_color: Color = Color(1.0, 0.4, 0.6)
## Category tints, kept for the connection lines and legend. The word spheres are
## NOT coloured by category any more — see the note in _create_word_cloud().
@export var neutral_color: Color = Color(0.5, 0.9, 0.4)
@export var profession_color: Color = Color(1.0, 0.8, 0.2)

## Current analogy
@export_enum("Gender-Profession", "Gender-Trait", "Algorithmic Redlining") var analogy_type: int = 0:
	set(value):
		analogy_type = clampi(value, 0, 2)
		if is_inside_tree():  # Only update if node is ready
			_show_analogy()

## Half-extent of the gender axis in authored units: man sits at -AXIS_HALF and
## woman at +AXIS_HALF, and every other word is placed between them by the
## embedding. This is the axis the cloud is coloured along.
const AXIS_HALF: float = 0.4

const WORD_DATA = {
	"man": {"pos": Vector3(-0.4, 0.0, 0.0), "category": "gender_m"},
	"woman": {"pos": Vector3(0.4, 0.0, 0.0), "category": "gender_f"},
	"he": {"pos": Vector3(-0.35, 0.1, 0.05), "category": "gender_m"},
	"she": {"pos": Vector3(0.35, 0.1, 0.05), "category": "gender_f"},
	"king": {"pos": Vector3(-0.3, 0.3, 0.1), "category": "gender_m"},
	"queen": {"pos": Vector3(0.3, 0.3, 0.1), "category": "gender_f"},
	"doctor": {"pos": Vector3(-0.2, 0.2, 0.3), "category": "profession"},
	"nurse": {"pos": Vector3(0.25, 0.15, 0.3), "category": "profession"},
	"engineer": {"pos": Vector3(-0.3, 0.1, 0.35), "category": "profession"},
	"teacher": {"pos": Vector3(0.15, 0.2, 0.25), "category": "profession"},
	"CEO": {"pos": Vector3(-0.35, 0.25, 0.4), "category": "profession"},
	"secretary": {"pos": Vector3(0.3, 0.1, 0.35), "category": "profession"},
	"programmer": {"pos": Vector3(-0.25, 0.05, 0.3), "category": "profession"},
	"homemaker": {"pos": Vector3(0.35, 0.0, 0.25), "category": "profession"},
	"strong": {"pos": Vector3(-0.2, -0.2, 0.2), "category": "trait"},
	"gentle": {"pos": Vector3(0.2, -0.2, 0.2), "category": "trait"},
	"logical": {"pos": Vector3(-0.25, -0.1, 0.25), "category": "trait"},
	"emotional": {"pos": Vector3(0.25, -0.15, 0.2), "category": "trait"},
	"aggressive": {"pos": Vector3(-0.3, -0.25, 0.15), "category": "trait"},
	"nurturing": {"pos": Vector3(0.3, -0.2, 0.15), "category": "trait"},
}

const ANALOGIES = {
	0: {
		"title": "GENDER → PROFESSION BIAS",
		"equation": "man - woman + nurse = ?",
		"words": ["man", "woman", "doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"],
		"explanation": "Professions cluster by gender.\nWho was in the training data?"
	},
	1: {
		"title": "GENDER → TRAIT BIAS",
		"equation": "he - she + emotional = ?",
		"words": ["man", "woman", "he", "she", "strong", "gentle", "logical", "emotional"],
		"explanation": "Traits encode stereotypes.\nThe model learned our prejudices."
	},
	2: {
		"title": "ALGORITHMIC REDLINING",
		"equation": "The ZIP code proxy",
		"words": ["man", "woman", "doctor", "nurse", "CEO", "secretary"],
		"explanation": "Bias isn't always explicit.\nProxies encode discrimination.\n(Safiya Noble, Ruha Benjamin)"
	},
}

var _word_nodes: Dictionary = {}
var _word_mm: MultiMesh
var _word_mmi: MultiMeshInstance3D
var _connection_lines: ImmediateMesh
var _connection_instance: MeshInstance3D
var _header_cache := ""
var _control_panel: Node3D
var _rotation_enabled: bool = false
var _created_nodes: Array[Node] = []

# The specimen turns, the case stays put. _process used to spin the artifact
# ROOT, which would have carried the cabinet around with the cloud — so the
# phenomenon lives under _spin (the powered deck) and the housing does not.
var _spin: Node3D
var _cloud: Node3D
# The body's two reading surfaces, rebuilt by _rebuild_header().
var _analogy_screen: Node3D
var _caption_anchor: Node3D
var _screen_size: Vector2 = Vector2(0.31, 0.30)
var _caption_size: Vector2 = Vector2(0.66, 0.135)

# ── Vitrine dimensions, derived in _derive_dims() from display_size/word_scale ─
var _r_spin: float = 0.0        # clear radius the turning cloud needs
var _iw: float = 0.0            # interior (window) width
var _idp: float = 0.0           # interior depth — square, because a turntable demands it
var _ih: float = 0.0            # interior height
var _apron_h: float = 0.26      # solid apron under the window sill
var _cap_h: float = 0.12        # sign band
var _cw: float = 0.40           # service column, sized to host a kit readout
var _fw: float = 0.12           # maroon flank
var _wall: float = 0.05         # back slab thickness
var _sill_y: float = 0.0
var _head_y: float = 0.0
var _top_y: float = 0.0
var _total_w: float = 0.0
var _colx: float = 0.0          # service column centre x
var _cx: float = 0.0            # body centre x (the window is centred on the origin)
var _face_z: float = 0.0        # the column's front plane
var _ledge_h: float = 0.19      # interpretive ledge: rise
var _ledge_db: float = 0.20     # ... depth at the bottom
var _ledge_dt: float = 0.025    # ... depth at the top
var _ledge_y: float = 0.0
var _ledge_z: float = 0.0
var _ledge_tilt: float = 0.0    # reading slope, computed from the wedge profile
var _mount_z: float = 0.0       # z of the ledge slope at its mid-height


func _ready():
	_derive_dims()
	_create_turntable()
	_create_base()
	_create_word_cloud()
	_create_connections()
	_create_vr_controls()
	# The case builds the screen anchors that _show_analogy() writes into, so it
	# is the last thing BUILT and the last thing before the first refresh.
	_create_cabinet()
	_show_analogy()

## Every dimension of the case comes from the artifact's own variables — the
## vitrine is sized by the cloud it has to enclose, never by typed-in numbers.
func _derive_dims() -> void:
	var ds: float = display_size
	var ws: float = word_scale
	# 0.45*ds is the worst plan-radius once the cloud is pulled onto the spin
	# axis; the max() term covers the billboarded tag half-widths, which do NOT
	# scale with display_size; then a finger of air.
	_r_spin = 0.45 * ds + maxf(ws, 0.10) + 0.04
	_iw = 2.0 * _r_spin
	_idp = _iw
	_ih = 0.55 * ds + ws * 3.4 + 0.16       # the cloud's y-span plus label headroom
	_sill_y = _apron_h
	_head_y = _apron_h + _ih
	_top_y = _head_y + _cap_h
	_total_w = _fw + _iw + _cw
	_colx = _iw / 2.0 + _cw / 2.0
	_cx = (_iw / 2.0 + _cw) - _total_w / 2.0
	_face_z = _idp / 2.0 + 0.03
	_ledge_y = _apron_h - 0.10
	_ledge_z = _idp / 2.0
	_ledge_tilt = -rad_to_deg(atan2(_ledge_db - _ledge_dt, _ledge_h))
	_mount_z = _ledge_z + (_ledge_db + _ledge_dt) * 0.5
	_screen_size = Vector2(_cw - 0.09, 0.30)
	_caption_size = Vector2(_iw * 0.56, 0.135)

## A point on the interpretive ledge's reading slope, `proud` metres out along
## the slope normal — so the caption and the keypad SIT on the shoulder instead
## of hovering a centimetre off it.
func _ledge_mount(x: float, proud: float) -> Vector3:
	var a: float = deg_to_rad(-_ledge_tilt)
	return Vector3(x, _ledge_y + sin(a) * proud, _mount_z + cos(a) * proud)

## The turntable: a spin node the phenomenon hangs under, so the specimen turns
## inside a case that does not.
func _create_turntable() -> void:
	_spin = Node3D.new()
	_spin.name = "Turntable"
	_spin.position = Vector3(0, _sill_y + 0.02, 0)   # deck top = the spin axis
	add_child(_spin)
	_created_nodes.append(_spin)

	_cloud = Node3D.new()
	_cloud.name = "EmbeddingCloud"
	# y lifts the lowest word (aggressive/nurturing at -0.25*ds) clear of the
	# deck; z pulls the cloud's plan-centroid onto the axis, which cuts the swept
	# radius from 0.53*ds to 0.45*ds and so shrinks the whole case.
	_cloud.position = Vector3(0, 0.25 * display_size + word_scale + 0.03, -0.20 * display_size)
	_spin.add_child(_cloud)
	_created_nodes.append(_cloud)

## The powered turntable deck the cloud stands on — with the gender axis inlaid
## FLAT into it as an instrument scale, where two tags used to hang in the air.
func _create_base():
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)

	var disc := MeshInstance3D.new()
	disc.name = "TurntableDeck"
	var cyl := CylinderMesh.new()
	cyl.top_radius = _r_spin - 0.03
	cyl.bottom_radius = _r_spin - 0.03
	cyl.height = 0.02
	cyl.radial_segments = 32
	disc.mesh = cyl
	disc.material_override = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	_spin.add_child(disc)

	var rim := MeshInstance3D.new()
	rim.name = "DeckRim"
	var tor := TorusMesh.new()
	tor.inner_radius = _r_spin - 0.05
	tor.outer_radius = _r_spin - 0.03
	rim.mesh = tor
	rim.material_override = HangarKit.emissive(col_accent, 1.8)
	rim.position = Vector3(0, 0.011, 0)
	_spin.add_child(rim)

	# the gender axis as a machined groove, masc -> fem
	_spin.add_child(HangarKit.box(Vector3(0, 0.010, 0),
		Vector3(2.0 * (_r_spin - 0.06), 0.002, 0.006), steel))

	var masc: MeshInstance3D = HangarKit.stencil("MASC", Vector2(0.14, 0.034), male_color)
	if masc:
		masc.name = "AxisInlayMasc"
		masc.position = Vector3(-(_r_spin - 0.10), 0.011, 0)
		masc.rotation_degrees = Vector3(-90, 0, 0)
		_spin.add_child(masc)

	var fem: MeshInstance3D = HangarKit.stencil("FEM", Vector2(0.14, 0.034), female_color)
	if fem:
		fem.name = "AxisInlayFem"
		fem.position = Vector3(_r_spin - 0.10, 0.011, 0)
		fem.rotation_degrees = Vector3(-90, 0, 0)
		_spin.add_child(fem)

## The body's two reading surfaces. Baked text is fixed at build time, so both
## are regenerated whenever the analogy changes:
##   * the LIT analogy screen inset in the service column (title + equation +
##     mode), where a framed plate used to float behind the cloud, occluded by
##     the very phenomenon it described;
##   * the MATTE PRINTED caption inlaid in the interpretive ledge, where a
##     second plate used to hang in the viewer's own standing space. The kit
##     switches the face material on background luminance (hangar_kit.gd:466),
##     so a light background gives a museum label rather than a glowing screen.
func _rebuild_header(title: String, equation: String, explanation: String) -> void:
	if not is_instance_valid(_analogy_screen) or not is_instance_valid(_caption_anchor):
		return   # the cabinet owns these anchors and is built before the first refresh
	var key := title + "|" + equation + "|" + explanation
	if key == _header_cache:
		return
	_header_cache = key

	for old in _analogy_screen.get_children():
		old.queue_free()
	for old_cap in _caption_anchor.get_children():
		if str(old_cap.name) != "CaptionPocket":
			old_cap.queue_free()

	var pal: Dictionary = HangarKit.finish_palette(finish)
	var analogy: Dictionary = ANALOGIES.get(analogy_type, ANALOGIES[0])
	var shown: Array = analogy.get("words", [])
	var screen: Node3D = HangarKit.readout(title, [
			equation,
			"MODE %d/3" % (analogy_type + 1),
			"WORDS %d" % shown.size(),
		], _screen_size, pal["screen"], pal["text"], pal["accent"], finish)
	if screen:
		_analogy_screen.add_child(screen)

	# Split on the authored newlines FIRST, then wrap each piece — handing an
	# embedded newline to a single-line bake is what made the redlining caption
	# (three authored lines) render wrong.
	var lines: Array = []
	for piece in explanation.split("\n"):
		var s: String = str(piece).strip_edges()
		if s == "":
			continue
		for part in _wrap2(s):
			lines.append(str(part))
	var caption: Node3D = HangarKit.readout("", lines, _caption_size,
		Color(0.88, 0.86, 0.80), Color(0.09, 0.09, 0.11), Color(0.09, 0.09, 0.11))
	if caption:
		_caption_anchor.add_child(caption)

func _wrap2(text: String) -> Array:
	if text.length() < 46:
		return [text]
	var mid := text.length() / 2
	var cut := text.find(" ", mid)
	if cut < 0:
		return [text]
	return [text.substr(0, cut), text.substr(cut + 1)]

func _create_word_cloud():
	var words = WORD_DATA.keys()
	var count = words.size()

	# Create MultiMesh for all word spheres
	var sphere := SphereMesh.new()
	sphere.radius = word_scale
	sphere.height = word_scale * 2

	_word_mm = MultiMesh.new()
	_word_mm.transform_format = MultiMesh.TRANSFORM_3D
	_word_mm.use_colors = true
	_word_mm.mesh = sphere
	_word_mm.instance_count = count

	# Shared material with per-instance color and subtle emission
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3

	_word_mmi = MultiMeshInstance3D.new()
	_word_mmi.name = "WordCloud"
	_word_mmi.multimesh = _word_mm
	_word_mmi.material_override = mat
	_cloud.add_child(_word_mmi)
	_created_nodes.append(_word_mmi)

	# Fill instances and create labels
	for i in count:
		var word = words[i]
		var data = WORD_DATA[word]
		var pos = data.pos * display_size

		# COLOUR BY POSITION ON THE GENDER AXIS — not by category.
		#
		# The whole finding lives in x: the embedding put engineer at -0.30 and nurse
		# at +0.25, CEO at -0.35 and homemaker at +0.35, with man/woman as the poles.
		# Colouring by category threw that away — all eight professions rendered the
		# same yellow, so nurse and CEO were indistinguishable, and the one axis that
		# carries the prejudice got no colour support at all. The viewer had to read
		# eight small labels and do the sorting in their head to see what the model
		# had already done. Category was decorated; the bias was hidden.
		#
		# Interpolating the two anchor colours across the axis reproduces them exactly
		# at the poles (man sits at -0.4 -> male_color, woman at +0.4 -> female_color),
		# so nothing is special-cased and nothing is invented: every word simply wears
		# the gender the model assigned it.
		var t: float = clampf((data.pos.x + AXIS_HALF) / (AXIS_HALF * 2.0), 0.0, 1.0)
		var color: Color = male_color.lerp(female_color, t)

		# Start hidden (zero scale)
		var xf := Transform3D()
		xf.origin = pos
		xf = xf.scaled_local(Vector3.ZERO)
		_word_mm.set_instance_transform(i, xf)
		_word_mm.set_instance_color(i, color)

		# Authored coordinates are untouched — the whole cloud shares one frame,
		# so re-parenting it under _cloud moves every word AND its label into the
		# case together, and _show_analogy/_draw_connections need no edit.
		var label: Node3D = BakedText.make_tag(word, color, 0.035)
		label.position = pos + Vector3(0, word_scale * 2.4, 0)
		label.visible = false
		_cloud.add_child(label)
		_created_nodes.append(label)

		_word_nodes[word] = {"index": i, "label": label, "data": data, "pos": pos}

func _create_connections():
	_connection_lines = ImmediateMesh.new()
	_connection_instance = MeshInstance3D.new()
	_connection_instance.name = "ConnectionLines"
	_connection_instance.mesh = _connection_lines
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_connection_instance.material_override = mat

	_cloud.add_child(_connection_instance)
	_created_nodes.append(_connection_instance)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("BIAS", [
		[
			{"type": "button", "label": "PROF"},
			{"type": "button", "label": "TRAIT"},
			{"type": "button", "label": "REDLN"},
			{"type": "button", "label": "ROT"},
		],
	])
	# Seated on the interpretive ledge's reading slope at the column end — a face
	# of the body, not a stand in front of it. Left FRAMED: create_panel's third
	# argument (frameless) is the horizontal dialect's flush milled recess and
	# does not transfer to a standing machine.
	_control_panel.position = _ledge_mount(_colx, 0.008)
	_control_panel.rotation_degrees = Vector3(_ledge_tilt, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	for i in range(3):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var idx := i
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): analogy_type = idx)

	var rot_btn: Node = _control_panel.find_child("Btn_3", true, false)
	if rot_btn:
		var rot_area: Node = rot_btn.get_node_or_null("InteractableAreaButton")
		if rot_area:
			rot_area.button_pressed.connect(func(_b): _rotation_enabled = not _rotation_enabled)


## THE TAXONOMY VITRINE — the artifact as ONE body (the 2026-07-20 interface
## ruling), vertical dialect: you FACE this standing, because the meaning lives
## in a left-right spread WITH a real vertical stratification (king/queen at
## +0.30, traits at -0.25) that looking down would collapse to nothing.
##
## A glazed case rather than a console, because the readout IS the twenty word
## tags: the cloud without its labels is coloured dots, and G1 says every baked
## tag sits inside the housing — so the housing must contain the whole volume.
## A vitrine is the only vertical body that encloses a volume and still lets you
## read into it. Its content is also its argument: an embedding space put on
## display as a museum taxonomy case, which is the truth line — classification
## systems encode whose categories get to count.
func _create_cabinet() -> void:
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	_created_nodes.append(cab)

	# ── one palette word drives every colour (kit finish system) ────────
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_panel: Color = pal["panel"]
	var col_accent: Color = pal["accent"]
	var ew: float = float(pal["wear"]) if finish.to_lower() == "terminal" else wear

	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, ew)
	var dark: StandardMaterial3D = HangarKit.painted_metal(Color(0.09, 0.09, 0.105), ew, 0.4, 0.5)
	var maroon: StandardMaterial3D = HangarKit.painted_metal(Color(0.30, 0.11, 0.09), ew)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_panel)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)
	# PALE window glass — the spheres must read THROUGH it. (The anthracite
	# screen glass is a different material and belongs only on readouts.)
	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.62, 0.72, 0.85, 0.055)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.1

	# ── shell: back slab, maroon flank, service column, apron ───────────
	# Flank and column stop at the head so the cap band spans the full width
	# without coplanar side faces fighting theirs.
	cab.add_child(HangarKit.box(Vector3(_cx, _top_y / 2.0, -_idp / 2.0 - _wall / 2.0),
		Vector3(_total_w, _top_y, _wall), shell))
	cab.add_child(HangarKit.box(Vector3(-_iw / 2.0 - _fw / 2.0, _head_y / 2.0, 0.0),
		Vector3(_fw, _head_y, _idp + 0.06), maroon))
	cab.add_child(HangarKit.box(Vector3(_colx, _head_y / 2.0, 0.0),
		Vector3(_cw, _head_y, _idp + 0.06), shell))
	cab.add_child(HangarKit.box(Vector3(0.0, _apron_h / 2.0, 0.0),
		Vector3(_iw, _apron_h, _idp + 0.06), shell))

	# ── the field: a dark liner is what makes the coloured spheres read, so
	#    it is part of the window, not decoration. Then the glass. ───────
	cab.add_child(HangarKit.box(Vector3(0.0, _sill_y + _ih / 2.0, -_idp / 2.0 + 0.006),
		Vector3(_iw, _ih, 0.012), dark))
	for sgn in [-1.0, 1.0]:
		var sx: float = float(sgn)
		cab.add_child(HangarKit.box(Vector3(sx * (_iw / 2.0 - 0.006), _sill_y + _ih / 2.0, 0.0),
			Vector3(0.012, _ih, _idp), dark))
	cab.add_child(HangarKit.box(Vector3(0.0, _head_y - 0.006, 0.0),
		Vector3(_iw, 0.012, _idp), dark))
	cab.add_child(HangarKit.box(Vector3(0.0, _sill_y + _ih / 2.0, _idp / 2.0 + 0.012),
		Vector3(_iw, _ih, 0.004), glass_mat))
	cab.add_child(HangarKit.box(Vector3(0.0, _sill_y + 0.012, _idp / 2.0 + 0.03),
		Vector3(_iw + 0.02, 0.025, 0.05), steel))
	# (no dust_streaks anywhere: over a window they read as smears on the
	#  phenomenon. Age goes on the solid faces below — grime_band.)

	# ── the analogy readout, INSET in the service column ────────────────
	var ft: float = maxf(_screen_size.x, _screen_size.y) * 0.06   # the kit's bezel bar
	var scr_y: float = _head_y - 0.30
	var anchor := Node3D.new()
	anchor.name = "AnalogyScreen"
	anchor.position = Vector3(_colx, scr_y, _face_z + 0.017)
	cab.add_child(anchor)
	_analogy_screen = anchor
	# dark pocket so the screen is seated, not taped on (G6)
	cab.add_child(HangarKit.box(Vector3(_colx, scr_y, _face_z + 0.003),
		Vector3(_screen_size.x + ft * 2.0 + 0.014, _screen_size.y + ft * 2.0 + 0.014, 0.024), dark))
	# ember lip over the screen
	cab.add_child(HangarKit.box(Vector3(_colx, scr_y + _screen_size.y / 2.0 + ft + 0.012, _face_z + 0.006),
		Vector3(_screen_size.x, 0.006, 0.005), accent))
	var bar: Node3D = HangarKit.three_color_bar(_cw - 0.08, 0.016)
	if bar:
		bar.position = Vector3(_colx, _head_y - 0.06, _face_z + 0.004)
		cab.add_child(bar)

	# ── the interpretive ledge: the keys and the caption as ONE belt of
	#    body running the full front width, at museum-label height ───────
	var ledge: MeshInstance3D = HangarKit.wedge(_total_w - 0.03, _ledge_h, _ledge_db, _ledge_dt,
		HangarKit.finish_body(finish, col_panel, ew))
	ledge.name = "InterpretiveLedge"
	ledge.position = Vector3(_cx, _ledge_y, _ledge_z)
	cab.add_child(ledge)

	var cap_anchor := Node3D.new()
	cap_anchor.name = "CaptionPlate"
	cap_anchor.position = _ledge_mount(-_iw * 0.14, 0.030)
	cap_anchor.rotation_degrees = Vector3(_ledge_tilt, 0, 0)
	cab.add_child(cap_anchor)
	_caption_anchor = cap_anchor
	var cft: float = maxf(_caption_size.x, _caption_size.y) * 0.06
	var pocket: MeshInstance3D = HangarKit.box(Vector3(0, 0, -0.022),
		Vector3(_caption_size.x + cft * 2.0 + 0.012, _caption_size.y + cft * 2.0 + 0.012, 0.014), dark)
	pocket.name = "CaptionPocket"      # survives the caption rebuild
	cap_anchor.add_child(pocket)

	# a machine carries an asset code, not only a title
	var fascia: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.13, 0.032),
		col_accent.lightened(0.25))
	if fascia:
		fascia.position = _ledge_mount(_cx - (_total_w - 0.03) / 2.0 + 0.08, 0.010)
		fascia.rotation_degrees = Vector3(_ledge_tilt, 0, 0)
		cab.add_child(fascia)

	# ── the cap: the constant name over a full-width ember line. The
	#    per-analogy title is live state and lives on the screen. ────────
	cab.add_child(HangarKit.box(Vector3(_cx, _head_y + _cap_h / 2.0, 0.0),
		Vector3(_total_w, _cap_h, _idp + 0.10), shell))
	cab.add_child(HangarKit.box(Vector3(_cx, _head_y + 0.005, _idp / 2.0 + 0.052),
		Vector3(_total_w, 0.007, 0.004), accent))
	cab.add_child(HangarKit.box(Vector3(_cx, _head_y + _cap_h / 2.0, _idp / 2.0 + 0.052),
		Vector3(_total_w - 0.10, 0.090, 0.012), dark))
	# billboard=false — the signage stays FLUSH in its pocket instead of
	# swivelling out of the cap.
	var sign_title: Node3D = BakedText.make_tag(
		"BIAS VISUALIZER", Color(0.93, 0.94, 0.97), 0.042,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_title:
		sign_title.position = Vector3(_cx, _head_y + _cap_h / 2.0 + 0.018, _idp / 2.0 + 0.060)
		cab.add_child(sign_title)
	var sign_sub: Node3D = BakedText.make_tag(
		"WORD EMBEDDING SPACE", Color(0.55, 0.58, 0.66), 0.020,
		Color(0.07, 0.075, 0.09), false, Color(0, 0, 0, 0))
	if sign_sub:
		sign_sub.position = Vector3(_cx, _head_y + _cap_h / 2.0 - 0.024, _idp / 2.0 + 0.060)
		cab.add_child(sign_sub)

	# ── service, fasteners, age ─────────────────────────────────────────
	# Vent slats sit mid-column: the lower face is taken by the ledge.
	for gi in range(6):
		cab.add_child(HangarKit.box(
			Vector3(_colx, _sill_y + 0.06 + float(gi) * 0.024, _face_z + 0.002),
			Vector3(_cw - 0.06, 0.010, 0.012), dark))
	cab.add_child(HangarKit.bolts(
		Vector3(-_iw / 2.0 - _fw / 2.0, _sill_y + 0.04, _idp / 2.0 + 0.032),
		Vector3(-_iw / 2.0 - _fw / 2.0, _head_y - 0.10, _idp / 2.0 + 0.032),
		7, 0.009, steel))
	cab.add_child(HangarKit.bolts(
		Vector3(_colx + _cw / 2.0 - 0.02, _sill_y + 0.04, _face_z + 0.002),
		Vector3(_colx + _cw / 2.0 - 0.02, _head_y - 0.10, _face_z + 0.002),
		7, 0.009, steel))
	# grime_band bakes its y and z into the call — only x may be reassigned.
	var gb: MeshInstance3D = HangarKit.grime_band(_total_w * 0.9, 0.055, _idp / 2.0 + 0.034, col_body)
	if gb:
		gb.position.x = _cx
		cab.add_child(gb)

	# ── footing: the pedestal solves the reach rule rather than redesigning
	#    the face — keypad and caption land ~0.88 m above floor contact. ─
	var ped: Node3D = HangarKit.plinth(_total_w, _idp + 0.12, plinth_height, finish, ew,
		col_accent, unit_code)
	if ped:
		ped.position = Vector3(_cx, 0, 0)
		cab.add_child(ped)
	# a 1.7 m case is not walk-through (colliders are ignored by mesh-AABB framing)
	cab.add_child(HangarKit.box_collider(Vector3(_total_w, _top_y, _idp + 0.10),
		Vector3(_cx, _top_y / 2.0, 0)))


func _show_analogy():
	# Hide all: zero-scale transform and hide labels
	for word in _word_nodes.keys():
		var info = _word_nodes[word]
		var xf := Transform3D()
		xf.origin = info.pos
		xf = xf.scaled_local(Vector3.ZERO)
		_word_mm.set_instance_transform(info.index, xf)
		info.label.visible = false

	var analogy = ANALOGIES.get(analogy_type, ANALOGIES[0])

	# Show selected: restore full-scale transform
	for word in analogy.words:
		if _word_nodes.has(word):
			var info = _word_nodes[word]
			var xf := Transform3D()
			xf.origin = info.pos
			_word_mm.set_instance_transform(info.index, xf)
			info.label.visible = true
	
	_rebuild_header(analogy.title, analogy.equation, analogy.explanation)
	
	_draw_connections(analogy.words)

func _draw_connections(words: Array):
	_connection_lines.clear_surfaces()
	_connection_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var pairs = [["man", "woman"], ["he", "she"], ["king", "queen"]]
	for pair in pairs:
		if pair[0] in words and pair[1] in words:
			var p1 = WORD_DATA[pair[0]].pos * display_size
			var p2 = WORD_DATA[pair[1]].pos * display_size
			_connection_lines.surface_set_color(Color(0.5, 0.5, 0.5, 0.3))
			_connection_lines.surface_add_vertex(p1)
			_connection_lines.surface_add_vertex(p2)
	
	var professions = ["doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"]
	for prof in professions:
		if prof in words and WORD_DATA.has(prof):
			var prof_pos = WORD_DATA[prof].pos * display_size
			var nearest = "man" if prof_pos.x < 0 else "woman"
			if nearest in words:
				var gender_pos = WORD_DATA[nearest].pos * display_size
				var color = male_color if nearest == "man" else female_color
				color.a = 0.4
				_connection_lines.surface_set_color(color)
				_connection_lines.surface_add_vertex(prof_pos)
				_connection_lines.surface_add_vertex(gender_pos)
	
	_connection_lines.surface_end()

func _process(delta):
	# The SPECIMEN turns, not the case. Spinning `self` here would carry the
	# cabinet around with the cloud.
	if _rotation_enabled and is_instance_valid(_spin):
		_spin.rotation.y = wrapf(_spin.rotation.y + delta * 0.3, 0.0, TAU)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				analogy_type = 0
			KEY_2:
				analogy_type = 1
			KEY_3:
				analogy_type = 2
			KEY_SPACE:
				_rotation_enabled = not _rotation_enabled

func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
