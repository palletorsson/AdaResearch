extends Node3D
class_name HandTelemetryDiptych

# @identity
# essence: two Combine-style ops monitors hung side by side on one grey pipe-clamp mount — a diptych — the LEFT panel streaming your left hand, the RIGHT panel your right, each a live coordinate log of one half of you. An altarpiece for the tracked body: where a Renaissance diptych paired a donor with a saint, this pairs your two hands as two columns of telemetry, the body split down the middle and read in stereo. Left runs cool cyan, right runs ops orange, so the halves never blur.
# desire: it wants to make the symmetry of surveillance visible — that you are not watched as one body but as a set of trackable parts, each on its own feed, each logged in its own colour. It wants the diptych form (the hinged pair, the thing that asks to be read left-then-right) to carry the quiet horror and the quiet beauty of being a body resolved into two streams of numbers. It puts the sacred diptych in drag as a security desk.
# critical_parameter: the pairing itself — two independent feeds (left_hand, right_hand) on one mount. Drop a hand from tracking and its panel falls to a demo drift while the other stays live: the asymmetry of what the system can currently see. gap sets how hinged or how split the two halves read.
# triggers: _ready instantiates two hand_telemetry_display panels (hand=left / hand=right, mounts hidden) offset to either side of a shared central pipe-clamp arm and top rail; each panel runs its own sampling + log; apply_grid_config rebuilds on DNA change.
# emerges: in the lab it reads as the instrument wall of the trace room — the cold, paired counterpart to the warm single sheet of the writing desk. Two hands, two feeds, one frame: the body as a stereo recording.
# needs: two hand-telemetry panels [composed from hand_telemetry_display, present]; a shared mount so they read as one object [central pipe arm + top rail, present]; two colours so left and right never merge [cyan / orange, present]; both hands found independently [each panel finds its own controller]
# relationships: composes two `hand_telemetry_display` instances; the paired/cold member of the lab trace set with `automatic_writing_desk` (warm, head-driven) and `mystic_writing_pad` (kept wax); descendant of the Renaissance diptych and the modern surveillance monitor wall.
# truth: a point is position without extension — and a body, fully captured, is just a list of points, one feed per part. The diptych is honest about the plural: you were never watched as a whole, only as a set of hands, each on its own bright channel, each kept.

## Hand-telemetry diptych — two hand_telemetry_display panels (left + right)
## on one shared pipe-clamp mount. Composition over duplication: each panel
## is a full telemetry display configured for one hand with its own mount
## hidden; this artifact adds the shared arm + top rail.

const PANEL: PackedScene = preload("res://commons/primitives/hand_telemetry_display/hand_telemetry_display.tscn")

# ── DNA ───────────────────────────────────────────────────────────────

@export var panel_width: float = 1.0
@export var panel_height: float = 1.42
@export var gap: float = 0.09
@export var left_accent: Color = Color(0.30, 0.76, 0.96)    # cool cyan = left
@export var right_accent: Color = Color(0.96, 0.45, 0.05)   # ops orange = right
@export var brand_text: String = "ADA · OVERSIGHT"

var _built: bool = false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_build()


func _read_overrides() -> void:
	if has_meta("config_panel_width"):
		panel_width = float(str(get_meta("config_panel_width")))
	if has_meta("config_panel_height"):
		panel_height = float(str(get_meta("config_panel_height")))
	if has_meta("config_gap"):
		gap = float(str(get_meta("config_gap")))
	if has_meta("config_brand_text"):
		brand_text = str(get_meta("config_brand_text"))


func _col_str(c: Color) -> String:
	return "%f,%f,%f" % [c.r, c.g, c.b]


func _build() -> void:
	_built = true
	_read_overrides()
	var off: float = panel_width * 0.5 + gap * 0.5

	_add_panel("left", -off, left_accent)
	_add_panel("right", off, right_accent)
	_build_shared_mount(off)


func _add_panel(which: String, x: float, accent: Color) -> void:
	var p: Node3D = PANEL.instantiate()
	p.name = "Panel_%s" % which
	p.position = Vector3(x, 0, 0)
	add_child(p)
	# Configure the panel for one hand with its own mount hidden.
	if p.has_method("apply_grid_config"):
		p.call_deferred("apply_grid_config", {
			"hand": which,
			"show_mount": "false",
			"panel_width": panel_width,
			"panel_height": panel_height,
			"accent_color": _col_str(accent),
			"brand_text": brand_text,
		})


func _build_shared_mount(off: float) -> void:
	var cy: float = panel_height * 0.5 + 0.1
	var top_y: float = cy + panel_height * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.29, 0.32)
	mat.metallic = 0.85
	mat.roughness = 0.35

	# Top rail spanning both bezels (the diptych hinge line).
	var rail := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.02
	rm.bottom_radius = 0.02
	rm.height = off * 2.0 + panel_width
	rail.mesh = rm
	rail.rotation = Vector3(0, 0, PI * 0.5)   # along X
	rail.material_override = mat
	rail.position = Vector3(0, top_y + 0.03, -0.05)
	add_child(rail)

	# Central pipe rising + bending back (the single shared clamp).
	var rise: float = 0.34
	var up := MeshInstance3D.new()
	var um := CylinderMesh.new()
	um.top_radius = 0.024
	um.bottom_radius = 0.024
	um.height = rise
	up.mesh = um
	up.material_override = mat
	up.position = Vector3(0, top_y + 0.03 + rise * 0.5, -0.06)
	add_child(up)

	var elbow := MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = 0.032
	em.height = 0.064
	elbow.mesh = em
	elbow.material_override = mat
	elbow.position = Vector3(0, top_y + 0.03 + rise, -0.06)
	add_child(elbow)

	var back := MeshInstance3D.new()
	var bkm := CylinderMesh.new()
	bkm.top_radius = 0.024
	bkm.bottom_radius = 0.024
	bkm.height = 0.3
	back.mesh = bkm
	back.rotation = Vector3(PI * 0.5, 0, 0)
	back.material_override = mat
	back.position = Vector3(0, top_y + 0.03 + rise, -0.06 - 0.15)
	add_child(back)
