extends Node3D
class_name FlashlightDemo

# @identity
# essence: four pickable RGB/white lamps illuminate a receiving surface
# desire: move a light and compare an appearance while keeping a material fixed
# critical_parameter: ground — authored receiving geometry/material
# triggers: _ready stages mount and ground; apply_grid_config can restage ground
# emerges: overlap and shadows depend on the lamp/surface arrangement
# needs: SpotLight3D [has]; XRTools pickup [has]; visitor hue/on-off controls [absent]
# relationships: Color_Flashlight uses white ground and standing mount
# truth: this is RGB rendering, not a calculation of wavelength spectra

# Ground variants are authoring choices, not visitor controls. Swatches change
# albedo, relief adds ribs, mirror changes roughness/metallic, none hides the
# board. The mirror option does not install a reflection camera. Ambient light
# and other geometry can still contribute: none does not guarantee darkness.
# Volumetric-fog energy on the lights does not itself enable volumetric fog.

## THE AXIS. white is the legacy lineage — the shipped board, not touched.
@export_enum("white", "swatch", "relief", "mirror", "none") var ground: String = "white"

## Optional floor-level installation; legacy placements retain their authored heights.
@export_enum("legacy", "standing") var mount: String = "legacy"

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
	if str(get_meta("config_mount", mount)) == "standing":
		_mount_standing()
	var canvas: CSGBox3D = get_node_or_null("Canvas") as CSGBox3D
	if canvas != null:
		_shipped_material = canvas.material
	_stage_ground()
	if _is_true(capture_anchor):
		_build_capture_anchor()
	_built = true


func _mount_standing() -> void:
	# The map places the root at floor level. Keep the entire board above it.
	mount = "standing"
	var canvas: CSGBox3D = get_node("Canvas")
	canvas.position.y = canvas.size.y * 0.5
	canvas.use_collision = true
	for lamp_name in ["RedFlashlight", "GreenFlashlight", "BlueFlashlight", "WhiteFlashlight"]:
		var lamp: Node3D = get_node(lamp_name)
		lamp.position.y = 1.1
		lamp.get_node("SpotLight3D").light_energy = 2.5
	# White starts aimed aside so it does not wash out the first RGB comparison.
	get_node("WhiteFlashlight").rotation_degrees.y = -60.0


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
