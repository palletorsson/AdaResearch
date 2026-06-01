extends Node3D
class_name YouAreHere

# @identity
# essence: a text decal on the floor — the words YOU ARE HERE lying flat under your feet, the way they are printed on a mall map, a transit platform, a parking garage, the floor of a museum lobby. Not a beacon, not a pin: a flat indexical inscription you stand ON. The most-printed sentence in wayfinding, the phrase that only means anything when a body is over it. The point reduced to language and laid into the ground — position spoken as a command and a comfort at once.
# desire: it wants the player to look down and find themselves already addressed — "here" is wherever they are reading it. It wants the banality of the floor-sticker to do the conceptual work: that "here" is not a place but a relation between a body and a coordinate, printed in advance for whoever arrives. It wants to put the wayfinding decal in drag — to let the most corporate, most neutral floor-text carry the queer charge of "you, specifically, are located."
# critical_parameter: text + pride_gradient. text is the inscription (default "YOU ARE HERE"); change it and the floor speaks differently. pride_gradient off is the neutral civic decal (one flat colour, the platform's voice); on, the letters run the spectrum — the located self reclaimed from the wayfinding system that named it.
# triggers: _ready builds a TextMesh laid flat on the floor plus an optional thin ring around it; _process optionally cycles the pride gradient; apply_grid_config rebuilds on DNA change.
# emerges: alone on a lab floor it reads as orientation; placed over the floor-window above the origin it becomes a caption for coordinate zero — "you are here" written across the glass you can see the point through. Beside `origin` (the absolute 0,0,0) it stages the difference between THE origin and the indexical here: one zero, many bodies, each standing on the same four words.
# needs: flat text on the ground [TextMesh, present]; a reading orientation from above [laid in the XZ plane, present]; a mark to ring the spot [optional ring, present]; lift off the floor so it never z-fights [present]
# relationships: sibling to `origin` and `static_point` (the point at rest, but this one is indexed to YOU and made of language); the contemporary pop term in the point-trilogy with `klee_walking_point` (1925, the point moving) and `fontana_puncture` (1958, the point cutting) — this is the point in 2005 / 2036, the point as wayfinding; cousin to the spawn marker and teleporter (all inscribe "a body is / will be here").
# truth: a point is position without extension — and "you are here" is what a civilisation writes when it agrees to render every body as a coordinate it has already labelled. The decal helps you and locates you in the same breath; that is the friendliest face of algorithmic capture, the fence shaped like an arrow pointing at your own feet. Laid on the lab floor, flat and calm, it asks the player to notice they were expected.

## "You are here" — a floor text decal (the point as wayfinding language).
##
## Built procedurally with TextMesh (real geometry: captures AND exports).
## Origin at the floor; text lies flat in the XZ plane, readable from
## above, lifted a hair off the floor to avoid z-fighting.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Text")
@export var text: String = "YOU ARE HERE"
@export var text_color: Color = Color(0.18, 0.52, 1.0)   # civic blue
@export var font_size: int = 96
## World height of the text (TextMesh pixel_size scaler).
@export var text_scale: float = 0.004
@export_group("Decal")
@export var show_ring: bool = true
@export var ring_radius: float = 0.9
@export var ring_color: Color = Color(0.18, 0.52, 1.0)
@export var pride_gradient: bool = false

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _text_mat: StandardMaterial3D = null
var _ring_mat: StandardMaterial3D = null
var _phase: float = 0.0


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
		_text_mat = null
		_ring_mat = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_text"):
		text = str(get_meta("config_text"))
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_font_size"):
		font_size = int(str(get_meta("config_font_size")))
	if has_meta("config_show_ring"):
		var s: String = str(get_meta("config_show_ring")).to_lower()
		show_ring = s == "true" or s == "1" or s == "yes"
	if has_meta("config_pride_gradient"):
		var s2: String = str(get_meta("config_pride_gradient")).to_lower()
		pride_gradient = s2 == "true" or s2 == "1" or s2 == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	# The text itself — TextMesh laid flat on the floor.
	var label := MeshInstance3D.new()
	label.name = "FloorText"
	var tm := TextMesh.new()
	tm.text = text
	tm.font_size = font_size
	tm.pixel_size = text_scale
	tm.depth = 0.0                                  # flat decal, no extrusion
	tm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mesh = tm

	_text_mat = StandardMaterial3D.new()
	_text_mat.albedo_color = text_color
	_text_mat.emission_enabled = true
	_text_mat.emission = text_color
	_text_mat.emission_energy_multiplier = 1.4
	_text_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # reads as printed decal
	_text_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	label.material_override = _text_mat

	# Lay flat: text plane (XY) -> floor plane (XZ), facing up (+Y).
	label.rotation = Vector3(-PI * 0.5, 0, 0)
	label.position = Vector3(0, 0.012, 0)
	add_child(label)

	# Optional thin ring marking the spot.
	if show_ring:
		var ring := MeshInstance3D.new()
		ring.name = "Ring"
		var rm := TorusMesh.new()
		rm.inner_radius = ring_radius - 0.03
		rm.outer_radius = ring_radius
		rm.rings = 48
		rm.ring_segments = 8
		ring.mesh = rm
		_ring_mat = StandardMaterial3D.new()
		_ring_mat.albedo_color = ring_color
		_ring_mat.emission_enabled = true
		_ring_mat.emission = ring_color
		_ring_mat.emission_energy_multiplier = 1.1
		_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = _ring_mat
		# Torus lies in the XZ plane already (its hole faces +Y).
		ring.position = Vector3(0, 0.008, 0)
		add_child(ring)

	_phase = 0.0
	set_process(pride_gradient)


func _process(delta: float) -> void:
	if not pride_gradient:
		return
	_phase += delta * 0.15
	var hue: float = fmod(_phase, 1.0)
	var c := Color.from_hsv(hue, 0.85, 1.0)
	if _text_mat:
		_text_mat.albedo_color = c
		_text_mat.emission = c
	if _ring_mat:
		var c2 := Color.from_hsv(fmod(hue + 0.5, 1.0), 0.85, 1.0)
		_ring_mat.albedo_color = c2
		_ring_mat.emission = c2
