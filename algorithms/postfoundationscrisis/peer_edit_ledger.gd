# Peer Edit Ledger — diffs accumulate, never reduce to a final form
#
# A tall ledger book pulses with stacked layers of edits. Each layer is a different color
# representing a different editor. The ledger is *deep*: scrolling back through its layers
# reveals the history, but the surface always shows the most recent state. Crucially,
# no edit overwrites the prior layer — they remain visible as glow within the stack.
#
# Models distributed knowledge with memory. The current state is the accumulation, never
# the replacement. Foreshadows graph theory's understanding of edges-as-history.
#
# @identity: First map where edits accumulate without overwriting.
# @qfep_term: Edge — peer process, not single author.

extends Node3D
class_name PeerEditLedger

@export var ledger_base_color: Color = Color(0.45, 0.3, 0.22, 1.0)
@export var layer_colors: Array = [
	Color(0.55, 0.85, 1.0, 1.0),
	Color(0.95, 0.55, 0.4, 1.0),
	Color(0.6, 0.9, 0.55, 1.0),
	Color(1.0, 0.85, 0.4, 1.0),
	Color(0.85, 0.55, 0.95, 1.0),
]
@export var layer_count: int = 24
@export var layer_height: float = 0.04

var _layers: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_base()
	_build_layers()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * 0.8
	# Each layer pulses faintly, individually — many authors, each still present.
	for i in _layers.size():
		var layer: MeshInstance3D = _layers[i]
		var mat := layer.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.8 + 0.5 * sin(_t + float(i) * 0.45)


func _build_base() -> void:
	var base := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.1, 0.4)
	base.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ledger_base_color
	mat.roughness = 0.6
	base.material_override = mat
	base.position.y = 0.55
	add_child(base)
	# Stand.
	var stand := MeshInstance3D.new()
	var s_cyl := CylinderMesh.new()
	s_cyl.top_radius = 0.1
	s_cyl.bottom_radius = 0.2
	s_cyl.height = 0.5
	stand.mesh = s_cyl
	stand.material_override = mat
	stand.position.y = 0.25
	add_child(stand)


func _build_layers() -> void:
	for i in layer_count:
		var layer := MeshInstance3D.new()
		var box := BoxMesh.new()
		# Slightly varying width per layer.
		var w := 0.58 + randf_range(-0.04, 0.04)
		box.size = Vector3(w, layer_height, 0.38)
		layer.mesh = box
		var mat := StandardMaterial3D.new()
		var color: Color = layer_colors[i % layer_colors.size()]
		mat.albedo_color = color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.7
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.0
		layer.material_override = mat
		layer.position.y = 0.65 + float(i) * (layer_height + 0.005)
		add_child(layer)
		_layers.append(layer)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "edits accumulate"
	label.font_size = 24
	label.outline_size = 5
	label.modulate = Color(0.95, 0.85, 0.55, 1.0)
	label.position = Vector3(0, 0.65 + float(layer_count) * layer_height + 0.2, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
