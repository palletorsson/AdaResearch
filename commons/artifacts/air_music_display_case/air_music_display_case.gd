extends Node3D
class_name AirMusicDisplayCase
## Air Music Display Case
## A 0.5m glass display case with dark wood frame containing the Air Music system.
## Inspired by Ferm Living Miru - minimalist Scandinavian design.

## Overall case size in meters (0.5m cube default)

# @identity
# essence: display_case(air_music_instance, sliders[]) — framed exhibition of generative audio
# desire: Examine a generative air music system like a museum specimen with parameter controls
# critical_parameter: audio_volume_db — balances the sonic presence against the visual display
# triggers: slider adjustments modify the contained air music system parameters
# emerges: the museum-as-instrument — display cases that you play rather than observe
# needs: VR sliders [has], air music system [has]
# relationships: depends on air music generation; contrasts with SoundscapeRadioRack (curated display vs radio tuning); unlocks contemplative audio interaction
# truth: Framing sound as specimen transforms listening from passive reception to active examination.

@export_range(0.1, 2.0, 0.05) var case_scale: float = 0.5
## Dark walnut brown frame color
@export var frame_color: Color = Color(0.25, 0.15, 0.08, 1.0)
## Frame edge thickness in meters
@export_range(0.005, 0.1, 0.005) var frame_thickness: float = 0.02
## Height of the wooden platform base
@export_range(0.01, 0.2, 0.01) var base_height: float = 0.04
## Audio volume in decibels (negative = quieter)
@export_range(-40.0, 0.0, 0.5) var audio_volume_db: float = -12.0
## Scale of content inside the case relative to case size
@export_range(0.1, 1.0, 0.05) var inner_scale: float = 0.35

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `house` and `seal`
# ═══════════════════════════════════════════════════════════════════
#
# AXIS 1 — `house`. WHOSE CASE THIS IS. The word, and all six values, are taken
# unchanged from exhibit_furniture (1077 placements) and exhibit_podium, which
# already carry `house` for exactly this question: which institution's register
# a piece of display furniture belongs to. A display case is display furniture,
# so it joins the family rather than inventing a synonym. Here the register is
# carried by the only two surfaces this artifact owns — the twelve frame lines
# and the plinth it stands on — plus, for the houses that use one, a band around
# the plinth rim.
#
#   ONE DEPARTURE FROM THE FAMILY, and it is the important line: the legacy
#   default here is `wunderkammer`, NOT the family's `white_cube`. This case
#   shipped as dark walnut with a dark wood base and was never white. Defaulting
#   it to the family's default would repaint nine placements to prove a point
#   about vocabulary, which is a regression wearing a tidy-up's clothes. So
#   HOUSES["wunderkammer"] holds this artifact's shipped literals byte for byte
#   — frame_color, and the base's (0.3, 0.18, 0.1) at roughness 0.8, metallic 0
#   — and carries no band and no plate, because the shipped case has neither and
#   the default may not grow one.
#
# AXIS 2 — `seal`. HOW MUCH THE CASE ADMITS THAT WHAT IT HOLDS GETS OUT. The
# thing on the plinth is a generative audio system. It is already leaving: the
# phasing loops are in the room whatever the vitrine does. So the glazing is not
# a containment, it is a CLAIM about containment, and that claim is the one
# thing about this artifact a still photograph can actually witness.
#
#   open    twelve lines and nothing between them — the shipped build. Nothing
#           is built at this value; the case is a diagram of a case.
#   glazed  five tinted panes (four sides and a lid). The museum's standard
#           lie: you may look, you may not touch, and the thing you cannot
#           touch is a sound that is already touching you.
#   vented  the four sides louvred into three slats each, top and bottom left
#           open. The case that concedes. Barrier as gesture.
#   sealed  five opaque panels in the house's own body colour. The specimen
#           disappears; only the audio remains. A vitrine that hides what it
#           exhibits and exhibits what it cannot hide.
#
# NOT `guard` and NOT `disclosure`, both of which stand nearby. exhibit_*'s
# `guard` is one ordered ladder of apparatus between VISITOR and thing
# (none|label|fixture|frame|hood|cordon); only two of its six rungs are
# buildable here and a partial borrow is worse than a new word. cube_lines —
# which is literally this case's Frame node — carries `disclosure`
# (frame|visible|silhouette|plan|corner) for how much of a SOLID is shown; that
# list does not fit either, and neither word says the thing that matters here,
# which is that the contents are audible through every one of these values.
#
# WHAT NEITHER AXIS CAN TOUCH, stated so nobody measures it and believes the
# number: the audio. audio_volume_db, the @identity file's declared
# critical_parameter, is the honest centre of this artifact and is completely
# invisible to a still. It stays an export and a VR slider; it is not declared,
# because one PNG per value would render four identical frames of a silent
# photograph and call the result evidence.
@export_enum("white_cube", "wunderkammer", "depot", "forensic", "didactic", "derelict") var house: String = "wunderkammer"
@export_enum("open", "glazed", "vented", "sealed") var seal: String = "open"

## Allow-lists. An unknown word in a map token keeps the shipped case.
const HOUSES_ALLOWED: PackedStringArray = ["white_cube", "wunderkammer", "depot", "forensic", "didactic", "derelict"]
const SEALS_ALLOWED: PackedStringArray = ["open", "glazed", "vented", "sealed"]

## Per-house surfaces. A MISSING `frame` key means "use the frame_color export",
## which is how wunderkammer stays exactly what shipped even if someone overrode
## the colour in the editor. A missing `band` key means no band is built.
const HOUSES := {
	"wunderkammer": {
		"base": Color(0.3, 0.18, 0.1), "base_rough": 0.8, "base_metal": 0.0,
	},
	"white_cube": {
		"frame": Color(0.9, 0.89, 0.86), "base": Color(0.92, 0.9, 0.86),
		"base_rough": 0.55, "base_metal": 0.0,
	},
	"depot": {
		"frame": Color(0.72, 0.52, 0.28), "base": Color(0.68, 0.49, 0.26),
		"base_rough": 0.9, "base_metal": 0.0,
		"band": Color(0.88, 0.44, 0.09), "band_rough": 0.55, "band_metal": 0.1,
	},
	"forensic": {
		"frame": Color(0.46, 0.48, 0.52), "base": Color(0.2, 0.21, 0.23),
		"base_rough": 0.35, "base_metal": 0.6,
		"band": Color(0.86, 0.88, 0.9), "band_rough": 0.3, "band_metal": 0.7,
	},
	"didactic": {
		"frame": Color(0.16, 0.2, 0.28), "base": Color(0.82, 0.81, 0.78),
		"base_rough": 0.7, "base_metal": 0.0,
		"band": Color(0.15, 0.35, 0.62), "band_rough": 0.5, "band_metal": 0.0,
	},
	"derelict": {
		"frame": Color(0.34, 0.31, 0.27), "base": Color(0.36, 0.34, 0.3),
		"base_rough": 0.95, "base_metal": 0.05,
	},
}

const PANE_INSET: float = 0.97     # panes sit just inside the frame lines
const PANE_THICKNESS: float = 0.006
const LOUVRE_SLATS: int = 3        # slats per side face at `vented`
const BAND_HEIGHT: float = 0.014   # the plinth rim band, where a house has one

var air_music_instance: Node3D
var _volume_slider: Node3D

## True once _ready has built the case once. apply_grid_config must never
## re-dress a case that has not been dressed yet, and must never re-dress one
## whose values did not move — that is what keeps the nine placements still.
var _built: bool = false

func _ready():
	house = _normalised_house(house)
	seal = _normalised_seal(seal)
	_setup_frame()
	_setup_base()
	_setup_air_music()
	_adjust_audio()
	_setup_controls()
	_build_seal()
	_built = true

## Scales the frame and applies wood color/thickness to all 12 cube lines.
func _setup_frame():
	# Scale the frame down
	var frame = $Frame
	if frame:
		frame.scale = Vector3.ONE * case_scale
		
		# Configure cube_lines with the house's wood color and remove labels
		var line_color: Color = _house_frame_color()
		for i in range(1, 13):
			var line_name = "Line%d" % i
			var line_node = frame.get_node_or_null(line_name + "/lineContainer")
			if line_node and line_node.has_method("set_line_properties"):
				line_node.set_line_properties(frame_thickness, line_color)
			
			# Remove the length labels (deferred — they're created in line's _ready)
			if line_node:
				_remove_label_deferred(line_node)
		
		# Also hide the cube label
		var cube_label = frame.get_node_or_null("Label3D")
		if cube_label:
			cube_label.visible = false

## Waits one frame then removes the auto-generated length label from a line node.
func _remove_label_deferred(line_node: Node) -> void:
	# Wait a frame so the line's _ready() has created the label
	await get_tree().process_frame
	var label = line_node.get_node_or_null("LengthLabel")
	if label:
		label.queue_free()

## Creates and styles the wooden base platform beneath the display case.
func _setup_base():
	# Create wooden base platform
	var base = $Base
	if base:
		var mesh = base.mesh as BoxMesh
		if mesh:
			var base_size = case_scale * 1.1
			mesh.size = Vector3(base_size, base_height, base_size)
		base.position.y = (-0.5 * case_scale) - (base_height / 2)

		# Create the plinth material. At the default house these are the exact
		# three literals this artifact shipped with.
		var p: Dictionary = _house_palette()
		var mat = StandardMaterial3D.new()
		mat.albedo_color = _color_of(p, "base", Color(0.3, 0.18, 0.1))
		mat.roughness = float(p.get("base_rough", 0.8))
		mat.metallic = float(p.get("base_metal", 0.0))
		base.material_override = mat

	_build_band()

## Scales, positions, and cleans up the embedded air music system.
func _setup_air_music():
	# Scale and position the air music system inside the case
	air_music_instance = $AirMusicContent
	if air_music_instance:
		air_music_instance.scale = Vector3.ONE * inner_scale
		# Center it inside the scaled case
		air_music_instance.position = Vector3(0, -0.05 * case_scale, 0)
		
		# Hide the label - we're in a display case, not a standalone demo
		var label = air_music_instance.get_node_or_null("Visualizer/Label")
		if label:
			label.visible = false
		
		# Hide the camera - we don't need an internal camera
		var cam = air_music_instance.get_node_or_null("Camera3D")
		if cam:
			cam.queue_free()

## Reduces audio volume and slows the intensity cycle for ambient effect.
func _adjust_audio():
	# Tone down the audio volume
	if air_music_instance:
		var synth = air_music_instance.get_node_or_null("FMPianoSynth")
		if synth and synth is AudioStreamPlayer3D:
			synth.volume_db = audio_volume_db
		elif synth and synth is AudioStreamPlayer:
			synth.volume_db = audio_volume_db
		
		# Also reduce intensity for subtler ambient effect
		var intensity = air_music_instance.get_node_or_null("IntensityController")
		if intensity and intensity.has_method("set"):
			# Make the intensity cycle longer for more ambient feel
			intensity.set("period", 90.0)

## Adds a VR volume slider below the display case via RackTemplates.
func _setup_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("AIR MUSIC", [
		[{"type": "slider_h", "label": "VOLUME", "default": remap(audio_volume_db, -40.0, 0.0, 0.0, 1.0)}],
	])
	panel.position = Vector3(0, (-0.5 * case_scale) - base_height - 0.05, 0.3)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	_volume_slider = panel.find_child("Param_0", true, false)
	if _volume_slider:
		_volume_slider.slider_moved.connect(_on_volume_changed)

func _on_volume_changed():
	var val = _volume_slider.get_normalized_value()
	audio_volume_db = remap(val, 0.0, 1.0, -40.0, 0.0)
	if air_music_instance:
		var synth = air_music_instance.get_node_or_null("FMPianoSynth")
		if synth and (synth is AudioStreamPlayer3D or synth is AudioStreamPlayer):
			synth.volume_db = audio_volume_db

func apply_grid_config(config_data: Dictionary) -> void:
	# Only the two declared axes are read; every other key in a map token is
	# ignored. GUARDED on both sides: nothing is re-dressed unless a word
	# actually changed, and nothing is re-dressed before _ready has dressed the
	# case once. A placement that carries no #house:/#seal: token never reaches
	# a rebuild at all — which is what the nine shipped placements do.
	var changed: bool = false
	if config_data.has("house"):
		var want_house: String = _normalised_house(str(config_data["house"]))
		if want_house != house:
			house = want_house
			changed = true
	if config_data.has("seal"):
		var want_seal: String = _normalised_seal(str(config_data["seal"]))
		if want_seal != seal:
			seal = want_seal
			changed = true
	if not changed or not _built:
		return
	_redress_frame()
	_setup_base()
	_build_seal()


# ═══════════════════════════════════════════════════════════════════
# `house` and `seal` — APPENDED LAST. Above this line only three things moved:
# the frame's line colour and the plinth's three material literals now come
# from HOUSES (identical values at the default house), and _ready calls
# _build_seal(), which builds nothing at the default seal.
# ═══════════════════════════════════════════════════════════════════

func _normalised_house(raw: String) -> String:
	var want: String = String(raw).strip_edges().to_lower()
	if not HOUSES_ALLOWED.has(want):
		return "wunderkammer"   # an unknown word keeps the shipped walnut case
	return want


func _normalised_seal(raw: String) -> String:
	var want: String = String(raw).strip_edges().to_lower()
	if not SEALS_ALLOWED.has(want):
		return "open"           # an unknown word keeps the bare frame
	return want


func _house_palette() -> Dictionary:
	var p: Dictionary = HOUSES.get(house, HOUSES["wunderkammer"])
	return p


## Typed read out of a house entry. The tables are untyped Dictionaries, so
## every colour comes back Variant; this is the one place that is checked.
func _color_of(p: Dictionary, key: String, fallback: Color) -> Color:
	if not p.has(key):
		return fallback
	var c: Color = p[key]
	return c


## The twelve lines' colour. wunderkammer deliberately has no `frame` entry, so
## it falls through to the export — an editor override of frame_color still
## works at the shipped value, and the shipped value is what nine maps show.
func _house_frame_color() -> Color:
	var p: Dictionary = _house_palette()
	if p.has("frame"):
		var c: Color = p["frame"]
		return c
	return frame_color


## Re-colour the twelve lines in place. Deliberately NOT _setup_frame(): that
## one also re-scales the frame and fires twelve deferred label removals, and
## re-running those on a live case would chase labels that are already gone.
func _redress_frame() -> void:
	var frame = $Frame
	if not frame:
		return
	var line_color: Color = _house_frame_color()
	for i in range(1, 13):
		var line_node = frame.get_node_or_null("Line%d/lineContainer" % i)
		if line_node and line_node.has_method("set_line_properties"):
			line_node.set_line_properties(frame_thickness, line_color)


## The plinth rim band, for the houses that mark their furniture — the depot's
## safety strap, forensic's steel edge, didactic's colour code. wunderkammer,
## white_cube and derelict declare no band, so nothing is built and the default
## plinth is exactly the slab it always was.
func _build_band() -> void:
	var old = get_node_or_null("HouseBand")
	if old:
		remove_child(old)
		old.queue_free()
	var p: Dictionary = _house_palette()
	if not p.has("band"):
		return
	var span: float = case_scale * 1.1 * 1.04
	var band := MeshInstance3D.new()
	band.name = "HouseBand"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(span, BAND_HEIGHT, span)
	band.mesh = mesh
	band.position = Vector3(0, (-0.5 * case_scale) - (base_height * 0.5), 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _color_of(p, "band", Color(0.88, 0.44, 0.09))
	mat.roughness = float(p.get("band_rough", 0.6))
	mat.metallic = float(p.get("band_metal", 0.0))
	band.material_override = mat
	add_child(band)


## The glazing. Builds NOTHING at seal=open, which is the shipped case: twelve
## lines and air. Every pane is a child of one container so a value change is
## one free and one rebuild.
func _build_seal() -> void:
	var old = get_node_or_null("Glazing")
	if old:
		remove_child(old)
		old.queue_free()
	if seal == "open":
		return

	var glazing := Node3D.new()
	glazing.name = "Glazing"
	add_child(glazing)

	var span: float = case_scale * PANE_INSET
	var half: float = case_scale * 0.5
	var mat: StandardMaterial3D = _pane_material()

	if seal == "vented":
		# Four louvred sides; top and bottom left open, because a vent is the
		# case conceding that the thing gets out.
		var slat_h: float = span / float(LOUVRE_SLATS * 2 - 1)
		for face in range(4):
			for s in range(LOUVRE_SLATS):
				var y: float = -span * 0.5 + slat_h * float(s * 2) + slat_h * 0.5
				_add_pane(glazing, mat, face, Vector3(span, slat_h, PANE_THICKNESS), half, y)
		return

	# glazed and sealed: four sides and a lid, same geometry, different material.
	for face in range(4):
		_add_pane(glazing, mat, face, Vector3(span, span, PANE_THICKNESS), half, 0.0)
	var lid := MeshInstance3D.new()
	lid.name = "PaneTop"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(span, PANE_THICKNESS, span)
	lid.mesh = lid_mesh
	lid.position = Vector3(0, half, 0)
	lid.material_override = mat
	glazing.add_child(lid)


## One face panel. `face` counts 0..3 around the case: +Z, -Z, +X, -X.
func _add_pane(parent: Node3D, mat: StandardMaterial3D, face: int,
		size: Vector3, half: float, y: float) -> void:
	var pane := MeshInstance3D.new()
	pane.name = "Pane%d_%d" % [face, int(y * 1000.0)]
	var mesh := BoxMesh.new()
	mesh.size = size
	pane.mesh = mesh
	match face:
		0:
			pane.position = Vector3(0, y, half)
		1:
			pane.position = Vector3(0, y, -half)
		2:
			pane.position = Vector3(half, y, 0)
			pane.rotation.y = PI * 0.5
		_:
			pane.position = Vector3(-half, y, 0)
			pane.rotation.y = PI * 0.5
	pane.material_override = mat
	parent.add_child(pane)


## Glass for glazed/vented; the house's own body colour, opaque, for sealed —
## a case that hides what it exhibits still has to be made of something, and
## what it is made of is the institution.
func _pane_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	if seal == "sealed":
		var p: Dictionary = _house_palette()
		mat.albedo_color = _color_of(p, "base", Color(0.3, 0.18, 0.1))
		mat.roughness = float(p.get("base_rough", 0.8))
		mat.metallic = float(p.get("base_metal", 0.0))
		return mat
	mat.albedo_color = Color(0.8, 0.9, 0.95, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat