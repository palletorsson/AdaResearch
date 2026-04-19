# situated_readout.gd
# Procedural artifact for postfoundationscrisis/SpeculativeComputation_Situated_Computation.
#
# A flat display panel that shows a "classification result" for an identical
# subject ID. The verdict is determined by the panel's OWN world position,
# not by any query or input. Place four of these in the four quadrants of
# a room and the player sees four different "objective" answers to the same
# question — which is the point. Haraway's situated knowledge, enacted
# spatially: the view always comes from somewhere.
#
# Registry: commons/artifacts/registry/algorithms_misc.json (category=critical)

extends Node3D
class_name SituatedReadout

# Shared subject ID — every instance shows the SAME input, different output.
const SUBJECT_ID := "#4729"

# Quadrant → (label, confidence, color). Tuned so that no quadrant agrees
# with any other: same subject, four incompatible "objective" verdicts.
const QUADRANT_VERDICTS := {
	"NW": { "label": "ORDERLY",     "confidence": 0.87, "color": Color(0.35, 0.75, 0.95) },
	"NE": { "label": "CREATIVE",    "confidence": 0.64, "color": Color(0.95, 0.75, 0.35) },
	"SW": { "label": "DANGEROUS",   "confidence": 0.92, "color": Color(0.95, 0.35, 0.35) },
	"SE": { "label": "IRRELEVANT",  "confidence": 0.22, "color": Color(0.55, 0.55, 0.60) },
}

const PANEL_WIDTH := 1.2
const PANEL_HEIGHT := 0.9

var _subject_label: Label3D
var _verdict_label: Label3D
var _confidence_label: Label3D
var _footer_label: Label3D
var _panel_mesh: MeshInstance3D

# Explicit quadrant override from grid config (#verdict:NW|NE|SW|SE). When
# the grid places multiple instances, this removes any ambiguity about
# which verdict belongs to which position. Empty = fall back to a
# position-hash.
var _verdict_override := ""


func _ready() -> void:
	_build_panel()
	_populate_from_position()


func _build_panel() -> void:
	# Backing panel — a thin box so it has visible presence from both sides.
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(PANEL_WIDTH, PANEL_HEIGHT, 0.04)
	_panel_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.10)
	mat.roughness = 0.85
	mat.metallic = 0.15
	_panel_mesh.material_override = mat
	_panel_mesh.position = Vector3(0, PANEL_HEIGHT * 0.5 + 0.4, 0)
	add_child(_panel_mesh)

	var base_y := _panel_mesh.position.y

	# "SUBJECT #4729" — top line, identical across every instance.
	_subject_label = _make_label("SUBJECT %s" % SUBJECT_ID, 0.065, Color(0.7, 0.7, 0.75))
	_subject_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.35, 0.025)
	add_child(_subject_label)

	# Verdict (big, center) — varies by position.
	_verdict_label = _make_label("—", 0.14, Color(1, 1, 1))
	_verdict_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.05, 0.025)
	add_child(_verdict_label)

	# Confidence — lower third.
	_confidence_label = _make_label("confidence —", 0.055, Color(0.75, 0.75, 0.78))
	_confidence_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.2, 0.025)
	add_child(_confidence_label)

	# Footer — identifies the viewpoint origin.
	_footer_label = _make_label("view from —", 0.045, Color(0.5, 0.5, 0.55))
	_footer_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.35, 0.025)
	add_child(_footer_label)


func _make_label(text: String, font_size: float, color: Color) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = font_size * 0.01
	lbl.modulate = color
	lbl.outline_size = 4
	lbl.double_sided = true
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return lbl


# Determine which quadrant THIS instance represents. Resolution order:
#   1. Explicit override from grid config (e.g. #verdict:NW) — authorial.
#   2. Cell-position hash — deterministic, for default placement.
# In both cases the verdict is a function of LOCATION, never of input.
# That's the point: identical subject, different answer per location.
func _populate_from_position() -> void:
	var pos := global_position
	var key := _resolve_quadrant_key(pos)
	var verdict: Dictionary = QUADRANT_VERDICTS.get(key, QUADRANT_VERDICTS["NW"])

	_verdict_label.text = verdict.label
	_verdict_label.modulate = verdict.color
	_confidence_label.text = "confidence %d%%" % int(verdict.confidence * 100.0)
	_footer_label.text = "view from %s (%.1f, %.1f)" % [key, pos.x, pos.z]

	# Tint the panel subtly so the verdict reads at a glance.
	var panel_mat: StandardMaterial3D = _panel_mesh.material_override as StandardMaterial3D
	if panel_mat:
		panel_mat.albedo_color = verdict.color.lerp(Color(0.08, 0.08, 0.10), 0.82)


func _resolve_quadrant_key(pos: Vector3) -> String:
	# Authorial override wins.
	if _verdict_override != "" and QUADRANT_VERDICTS.has(_verdict_override):
		return _verdict_override
	# Fallback: cell-position hash. Every 2 cells in X and Z flips a bit.
	# This gives stable NW/NE/SW/SE assignment across standard grid layouts
	# without requiring a centered origin.
	var cell_x := int(floor(pos.x + 0.5))
	var cell_z := int(floor(pos.z + 0.5))
	var x_bit := (cell_x / 2) & 1
	var z_bit := (cell_z / 2) & 1
	var keys := ["NW", "NE", "SW", "SE"]
	return keys[z_bit * 2 + x_bit]


# Grid system calls this when the artifact is placed. Accepts:
#   verdict: one of NW, NE, SW, SE — explicit quadrant override.
func apply_grid_config(config_data: Dictionary) -> void:
	var raw: Variant = config_data.get("verdict", "")
	if typeof(raw) == TYPE_STRING:
		_verdict_override = String(raw).strip_edges().to_upper()
	# Re-populate if config arrives after _ready() already ran.
	if _verdict_label != null:
		_populate_from_position()
