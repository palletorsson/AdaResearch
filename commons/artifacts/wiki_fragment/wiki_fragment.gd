# wiki_fragment.gd
# Procedural artifact for postfoundationscrisis/SpeculativeComputation_Collective_Knowledge.
#
# A single reading panel that is DELIBERATELY INCOMPLETE. Each fragment
# ends in a cross-reference to another fragment elsewhere in the room.
# No one panel carries the thesis. Walking the four of them does.
#
# The point: the commons is what emerges from incomplete nodes that
# point at each other. Gödel showed single systems are incomplete;
# a wiki is not a system — it's a ledger of incompletenesses that route.
#
# Registry: commons/artifacts/registry/algorithms_misc.json (category=critical)

extends Node3D
class_name WikiFragment

# Four fragments, deliberately cycling — each one cross-references the
# next, so walking them never terminates in a complete picture.
const FRAGMENTS := {
	"NORTH": {
		"title": "On Gödel",
		"body": "Every formal system has an outside.\nBut the outside is where knowledge actually\nhappens — not as failure, as shape of the room.",
		"cf": "see EAST · On Margins",
		"editors": 47,
		"disagreements": 3,
		"color": Color(0.4, 0.7, 0.95),
	},
	"EAST": {
		"title": "On Margins",
		"body": "The margin is not the edge of the text.\nIt is where the editor tests the system.\nNot proof of failure but of where it's alive.",
		"cf": "see SOUTH · On the Commons",
		"editors": 62,
		"disagreements": 8,
		"color": Color(0.95, 0.75, 0.35),
	},
	"SOUTH": {
		"title": "On the Commons",
		"body": "What one editor cannot hold, the ledger can.\nNo node is true alone. A wiki is not consistent.\nIt is corrigible — which is more honest.",
		"cf": "see WEST · On Incompleteness",
		"editors": 84,
		"disagreements": 12,
		"color": Color(0.55, 0.90, 0.55),
	},
	"WEST": {
		"title": "On Incompleteness",
		"body": "The crisis was a pivot, not a collapse.\nWe build differently now — paraconsistent,\nsituated, collective. The edge is the ground.",
		"cf": "see NORTH · On Gödel",
		"editors": 103,
		"disagreements": 6,
		"color": Color(0.90, 0.55, 0.85),
	},
}

const PANEL_WIDTH := 1.4
const PANEL_HEIGHT := 1.1

var _title_label: Label3D
var _body_label: Label3D
var _cf_label: Label3D
var _footer_label: Label3D
var _panel_mesh: MeshInstance3D

# Explicit fragment identity from grid config (#fragment:NORTH|EAST|SOUTH|WEST).
var _fragment_key := ""


func _ready() -> void:
	_build_panel()
	_populate_from_fragment()


func _build_panel() -> void:
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "Panel"
	var box := BoxMesh.new()
	box.size = Vector3(PANEL_WIDTH, PANEL_HEIGHT, 0.04)
	_panel_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.06, 0.06, 0.08)
	mat.roughness = 0.9
	mat.metallic = 0.1
	_panel_mesh.material_override = mat
	_panel_mesh.position = Vector3(0, PANEL_HEIGHT * 0.5 + 0.45, 0)
	add_child(_panel_mesh)

	var base_y := _panel_mesh.position.y

	_title_label = _make_label("—", 0.10, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_CENTER)
	_title_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.36, 0.025)
	add_child(_title_label)

	_body_label = _make_label("—", 0.055, Color(0.90, 0.90, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	_body_label.position = Vector3(0, base_y + PANEL_HEIGHT * 0.05, 0.025)
	add_child(_body_label)

	_cf_label = _make_label("—", 0.050, Color(0.55, 0.80, 0.95), HORIZONTAL_ALIGNMENT_CENTER)
	_cf_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.28, 0.025)
	add_child(_cf_label)

	_footer_label = _make_label("—", 0.040, Color(0.50, 0.50, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	_footer_label.position = Vector3(0, base_y - PANEL_HEIGHT * 0.40, 0.025)
	add_child(_footer_label)


func _make_label(text: String, font_size: float, color: Color, alignment: int) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.pixel_size = font_size * 0.01
	lbl.modulate = color
	lbl.outline_size = 4
	lbl.double_sided = true
	lbl.horizontal_alignment = alignment
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	return lbl


# Resolve which fragment this instance represents. Authorial #fragment
# config wins; otherwise fall back to a cell-position hash so default
# placement still distributes fragments across a room.
func _populate_from_fragment() -> void:
	var key := _resolve_fragment_key()
	var frag: Dictionary = FRAGMENTS.get(key, FRAGMENTS["NORTH"])

	_title_label.text = String(frag.title)
	_title_label.modulate = frag.color
	_body_label.text = String(frag.body)
	_cf_label.text = "→ %s" % String(frag.cf)
	_footer_label.text = "%d editors · %d disagreements · revision %d" % [
		frag.editors, frag.disagreements, int(frag.editors * 2.3),
	]

	# Subtle tint on the panel so each fragment reads at a glance.
	var panel_mat: StandardMaterial3D = _panel_mesh.material_override as StandardMaterial3D
	if panel_mat:
		panel_mat.albedo_color = frag.color.lerp(Color(0.06, 0.06, 0.08), 0.85)


func _resolve_fragment_key() -> String:
	if _fragment_key != "" and FRAGMENTS.has(_fragment_key):
		return _fragment_key
	# Cell-hash fallback: same scheme as situated_readout.
	var pos := global_position
	var cell_x := int(floor(pos.x + 0.5))
	var cell_z := int(floor(pos.z + 0.5))
	var x_bit := (cell_x / 2) & 1
	var z_bit := (cell_z / 2) & 1
	var keys := ["NORTH", "EAST", "SOUTH", "WEST"]
	return keys[z_bit * 2 + x_bit]


# Grid system calls this when the artifact is placed. Accepts:
#   fragment: one of NORTH, EAST, SOUTH, WEST — authorial identity.
func apply_grid_config(config_data: Dictionary) -> void:
	var raw: Variant = config_data.get("fragment", "")
	if typeof(raw) == TYPE_STRING:
		_fragment_key = String(raw).strip_edges().to_upper()
	if _title_label != null:
		_populate_from_fragment()
