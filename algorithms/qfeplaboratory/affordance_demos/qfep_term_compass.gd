# QFEP Term Compass — retroactive recognition of where each formula term was first met
#
# The compass is a glass disc with five glowing nodes arranged radially. Each node represents
# one term of QFE = F − λE(S) + φΔE(S,t):
#   F      — origin: forces (sequence 5)
#   E(S)   — origin: randomness (sequence 7)
#   λ      — origin: cellularautomata (sequence 9)
#   Δ(S,t) — origin: change (sequence 4.5)
#   φ      — origin: wavefunctions (sequence 6)
#
# As the player approaches a node, it pulses and a label naming its origin lights up.
# Standing at the center, the entire formula glows — the curriculum's argument made visible.
#
# This is the dark-spot fix from the synthesis sieve: the player walks the *formula's parts*
# before meeting it whole, but the spine doesn't currently map each term back to its origin.
# The compass closes that loop.
#
# @identity: The retroactive map. Every prior sequence was secretly building a term.
# @qfep_term: All — this is the formula viewed from inside.

extends Node3D
class_name QFEPTermCompass

@export_category("Compass Settings")
@export var disc_color: Color = Color(0.12, 0.15, 0.22, 1.0)
@export var node_radius: float = 0.18
@export var ring_radius: float = 1.1
@export var center_height: float = 0.95
@export var label_height: float = 0.35

# Terms in QFE = F − λE(S) + φΔE(S,t).
# Each entry: name, color, origin sequence.
var _term_data := [
	{"name": "F", "color": Color(0.6, 0.85, 1.0, 1.0), "origin": "forces (5)"},
	{"name": "E(S)", "color": Color(1.0, 0.4, 0.45, 1.0), "origin": "randomness (7)"},
	{"name": "λ", "color": Color(1.0, 0.7, 0.25, 1.0), "origin": "cellularautomata (9)"},
	{"name": "Δ(S,t)", "color": Color(0.55, 0.9, 0.55, 1.0), "origin": "change (4.5)"},
	{"name": "φ", "color": Color(0.85, 0.6, 1.0, 1.0), "origin": "wavefunctions (6)"},
]

var _node_meshes: Array = []
var _disc: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_disc()
	_build_term_nodes()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("ring_radius"):
		ring_radius = float(config_data["ring_radius"])
	if config_data.has("center_height"):
		center_height = float(config_data["center_height"])


func _process(delta: float) -> void:
	_t += delta
	# Each node pulses at its own phase — different colors of the formula, breathing.
	for i in _node_meshes.size():
		var node: MeshInstance3D = _node_meshes[i]
		var mat := node.material_override as StandardMaterial3D
		if not mat:
			continue
		var phase: float = _t * 0.9 + float(i) * 0.6
		mat.emission_energy_multiplier = 1.4 + 0.6 * sin(phase)
	if is_instance_valid(_disc):
		_disc.rotation.y = _t * 0.15


func _build_disc() -> void:
	_disc = MeshInstance3D.new()
	_disc.name = "CompassDisc"
	var cyl := CylinderMesh.new()
	cyl.top_radius = ring_radius + 0.35
	cyl.bottom_radius = ring_radius + 0.35
	cyl.height = 0.08
	_disc.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = disc_color
	mat.metallic = 0.6
	mat.roughness = 0.25
	_disc.material_override = mat
	_disc.position.y = center_height
	add_child(_disc)


func _build_term_nodes() -> void:
	var n := _term_data.size()
	for i in n:
		var data: Dictionary = _term_data[i]
		var angle: float = TAU * float(i) / float(n) - PI * 0.5
		var pos := Vector3(cos(angle) * ring_radius, center_height + 0.1, sin(angle) * ring_radius)
		var sphere := MeshInstance3D.new()
		sphere.name = "Term_" + str(data["name"])
		var sm := SphereMesh.new()
		sm.radius = node_radius
		sm.height = node_radius * 2.0
		sphere.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = data["color"]
		mat.emission_enabled = true
		mat.emission = data["color"]
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.4
		mat.roughness = 0.2
		sphere.material_override = mat
		sphere.position = pos
		add_child(sphere)
		_node_meshes.append(sphere)
		# Float a Label3D above each node showing its name and origin.
		var label := Label3D.new()
		label.text = str(data["name"]) + "\n→ " + str(data["origin"])
		label.font_size = 24
		label.outline_size = 6
		label.modulate = data["color"]
		label.position = pos + Vector3(0, label_height, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
