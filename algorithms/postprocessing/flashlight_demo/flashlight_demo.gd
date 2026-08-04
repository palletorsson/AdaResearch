extends Node3D
class_name FlashlightDemo

# @identity
# essence: four flashlights (red, green, blue, white) aimed across a dark room at one surface — what the beam falls on is what the beam can say
# desire: walk between the lamps and the wall and watch a colour appear or fail to appear depending on what is standing there to receive it
# critical_parameter: ground — the surface the four beams land on, which decides whether coloured light reads as colour, as shape, as a reflection, or as nothing
# triggers: _ready reads ground and stages the receiving surface once; no runtime changes
# emerges: red light on a blue panel is black — the demo's own stated lesson, which the shipped white wall makes impossible to see
# needs: SpotLight3D per lamp [has]; dark environment [has]; a surface with a colour of its own [was missing, now `ground`]
# relationships: synthesis artifact for Color_Flashlight; the lamps' own colours come from flashlight_color.gd on each instance
# truth: a flashlight does not add colour to the world — it reveals what was always there by choosing which wavelengths to offer, and it can only reveal what is standing in front of it

# ─── DNA · hand promotion 2026-08-04 ─────────────────────────────────────────
# Refused by the runner for NO TURNABLE KNOBS. Correctly: the .tscn root carried
# NO SCRIPT AT ALL. flashlight_color.gd sits on four ColorSetter CHILDREN, so
# even its two exports were unreachable from a map token — GridInteractables-
# Component stamps config metadata and calls apply_grid_config on the ROOT.
# (That child script's apply_grid_config is a bare `pass`, so every token a map
# ever wrote for this artifact was parsed, logged and discarded.) The registry
# description is the string "flashlight_demog", so the scene is the only source
# of truth about what this thing is.
#
# WHAT IT IS. Four pickable flashlights in a row at z=3 — red, green, blue and
# white — throwing 25-degree cones five metres across a nearly black room at one
# 6 x 4 white board. The cones are 2.3 m wide by the time they land and overlap
# heavily, so the additive result is already on the wall.
#
# THE HARD-CODED CONSTANT THAT CARRIES THE ARGUMENT is the board. It is white
# (0.95 grey, roughness 0.9), and a white surface returns every wavelength it is
# offered, so nothing this artifact says can ever be false on it. The file's own
# @identity promises "red light on a blue wall = black" and the scene makes that
# impossible to witness. The axis is therefore not the lamps but what they are
# given to fall on.
#
#   ground   white   (DEFAULT, the lineage) the shipped board, untouched.
#            swatch  the same board divided into red, green, blue and white
#                    quarters. Sixteen beam-on-surface pairs at once, and the
#                    demo's own promised lesson finally in the room: the red
#                    beam dies on the blue quarter.
#            relief  the white board kept, with seven standing ribs in front of
#                    it. shadow_enabled is already true on every lamp, so the
#                    beams now disclose SHAPE instead of hue, and the shadows
#                    come out coloured because each one is missing exactly one
#                    lamp.
#            mirror  the same board, specular and dark. A mirror discloses the
#                    SOURCE and not the beam: the pools vanish and four lamp
#                    reflections remain.
#            none    no board. Light with nothing to land on is not visible; the
#                    room stays dark and only the lamp bodies are in the frame.
#
# WHAT WAS DECLINED, and why it is not a fifth value: VOLUMETRIC FOG. Every lamp
# ships light_volumetric_fog_energy = 2.0 and the scene's WorldEnvironment never
# enables volumetric fog, so that setting is dead in every room — turning it on
# would make the beams visible in the AIR, which is a striking picture and a
# genuinely different claim (the medium, not the ground). One word cannot honestly
# cover both, and this artifact's own truth line is about the surface. Recorded
# here as the next promotion rather than smuggled in as a value.
#
# ALSO DECLINED: the four lamp COLOURS. Swapping red/green/blue for cyan/magenta/
# yellow photographs as a palette change, and this artifact is not about which
# hues are chosen but about whether choosing a hue reveals anything.
# ─────────────────────────────────────────────────────────────────────────────

## THE AXIS. white is the legacy lineage — the shipped board, not touched.
@export_enum("white", "swatch", "relief", "mirror", "none") var ground: String = "white"

## CAPTURE FIXTURE, not an axis, and OFF in every room. The lamp bodies are the
## only MeshInstance3D in this scene — the board is a CSGBox3D, which the
## capture AABB does not count — so a sweep frames four 4 cm cylinders and
## photographs none of the surface the axis is about. True adds an invisible
## (layers = 0) box spanning lamps and board, which both widens the frame and
## holds it FIXED while the board changes size. Untyped so a fixture string
## survives being assigned before _ready.
@export var capture_anchor = false

## The allow-list a map token is checked against. An unknown word falls back to
## the shipped board rather than stranding a placement in the dark.
const GROUNDS: PackedStringArray = ["white", "swatch", "relief", "mirror", "none"]

## The lamps' own colours, read off the ColorSetter nodes in the .tscn, so a
## swatch quarter is exactly one lamp's wavelength and the fourth is the shipped
## white kept as the control.
const SWATCH_TINTS: Array = [
	Color(0.72, 0.07, 0.07, 1.0),
	Color(0.07, 0.58, 0.13, 1.0),
	Color(0.07, 0.12, 0.68, 1.0),
	Color(0.95, 0.95, 0.95, 1.0),
]

const RIB_COUNT: int = 7
const RIB_STANDOFF: float = 0.45

var _built: bool = false
var _shipped_material: Material = null
var _staged: Array[Node] = []


func _ready() -> void:
	_read_ground()
	var canvas: CSGBox3D = get_node_or_null("Canvas") as CSGBox3D
	if canvas != null:
		_shipped_material = canvas.material
	_stage_ground()
	if _is_true(capture_anchor):
		_build_capture_anchor()
	_built = true


## A map token reaches here as metadata the grid stamps before add_child; the
## sweep sets the export directly, so the export is the fallback.
func _read_ground() -> void:
	var want: String = ground
	if has_meta("config_ground"):
		want = str(get_meta("config_ground"))
	elif has_meta("ground"):
		want = str(get_meta("ground"))
	ground = _normalise_ground(want)
	if has_meta("config_capture_anchor"):
		capture_anchor = get_meta("config_capture_anchor")


func _normalise_ground(raw: String) -> String:
	var word: String = raw.strip_edges().to_lower()
	if GROUNDS.has(word):
		return word
	return "white"


func _is_true(value) -> bool:
	if value is bool:
		return value
	var word: String = str(value).strip_edges().to_lower()
	return word == "true" or word == "1" or word == "yes"


## Rebuild ONLY when a map actually changed the word and _ready has already
## staged once. Both existing placements — a bare token in Corridor_Color_
## Flashlight and a curation_station collection in Curation_Bay_color_4 — carry
## no `ground` key, so this returns on its first line for them.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("ground"):
		return
	var want: String = _normalise_ground(str(config_data["ground"]))
	if want == ground:
		return
	ground = want
	if not _built:
		return
	_restage_ground()


func _restage_ground() -> void:
	for node in _staged:
		if is_instance_valid(node):
			node.queue_free()
	_staged.clear()
	var canvas: CSGBox3D = get_node_or_null("Canvas") as CSGBox3D
	if canvas != null:
		canvas.visible = true
		canvas.material = _shipped_material
	_stage_ground()


## `white` returns before touching anything, so the shipped board is the shipped
## board — same CSGBox3D, same authored material, same transform.
func _stage_ground() -> void:
	if ground == "white":
		return
	var canvas: CSGBox3D = get_node_or_null("Canvas") as CSGBox3D
	if canvas == null:
		return
	match ground:
		"none":
			canvas.visible = false
		"mirror":
			canvas.material = _mirror_material()
		"swatch":
			canvas.visible = false
			_build_swatch(canvas)
		"relief":
			_build_relief(canvas)
		_:
			pass


func _mirror_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.06, 1.0)
	mat.metallic = 1.0
	mat.metallic_specular = 1.0
	mat.roughness = 0.04
	return mat


func _matte(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.9
	return mat


func _panel(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = mat
	mi.mesh = box
	mi.position = pos
	add_child(mi)
	_staged.append(mi)
	return mi


## The board divided, not replaced: same total width, same height, same depth,
## same plane. Four quarters, three of them carrying one lamp's wavelength and
## the fourth still white.
func _build_swatch(canvas: CSGBox3D) -> void:
	var whole: Vector3 = canvas.size
	var quarter: float = whole.x / 4.0
	for i in range(4):
		var x: float = canvas.position.x - whole.x * 0.5 + quarter * (float(i) + 0.5)
		_panel(Vector3(quarter, whole.y, whole.z),
				Vector3(x, canvas.position.y, canvas.position.z),
				_matte(SWATCH_TINTS[i]))


## Ribs standing off the white board. Every lamp already has shadow_enabled, so
## each rib subtracts a different lamp from a different strip of wall.
func _build_relief(canvas: CSGBox3D) -> void:
	var whole: Vector3 = canvas.size
	var step: float = whole.x / float(RIB_COUNT + 1)
	var mat: StandardMaterial3D = _matte(Color(0.88, 0.88, 0.88, 1.0))
	for i in range(RIB_COUNT):
		var x: float = canvas.position.x - whole.x * 0.5 + step * (float(i) + 1.0)
		_panel(Vector3(0.14, whole.y * 0.8, 0.3),
				Vector3(x, canvas.position.y, canvas.position.z + RIB_STANDOFF),
				mat)


## Invisible to every camera (layers = 0), counted by the capture AABB, and
## built ONLY when a fixture asks — so grounding and framing in the two live
## rooms are exactly what they were.
func _build_capture_anchor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "CaptureAnchor"
	var box := BoxMesh.new()
	box.size = Vector3(6.4, 4.4, 5.8)
	mi.mesh = box
	mi.layers = 0
	mi.position = Vector3(0.0, 0.5, 0.6)
	add_child(mi)
	# deliberately NOT in _staged: the anchor must survive a ground change, or a
	# swept variant would be framed differently from the one before it.
