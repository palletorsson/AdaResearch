# Wiki Fragment Station — the commons as response to incompleteness
#
# A round table holds many small paper-thin fragments, each glowing faintly. Each fragment
# carries a partial claim: a half-sentence, a citation, a question without an answer.
# Above the table, the fragments slowly *suggest themselves into* a larger emergent text
# without ever fully resolving — a wiki's living quality, not its frozen page.
#
# The point: the commons does not solve incompleteness; it *holds* it. The encyclopedia
# is a verb, not a noun.
#
# @identity: First map where the player meets shared knowledge as ongoing co-authoring.
# @qfep_term: Edge — collective, not totalized.

extends Node3D
class_name WikiFragmentStation

@export var table_color: Color = Color(0.35, 0.38, 0.45, 1.0)
@export var fragment_color: Color = Color(0.85, 0.95, 0.7, 1.0)
@export var halo_color: Color = Color(0.7, 0.95, 0.85, 1.0)
@export var fragment_count: int = 14
@export var table_radius: float = 0.55

var _fragments: Array = []
var _halo: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_table()
	_build_fragments()
	_build_halo()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta
	# Fragments drift gently around the table center.
	for i in _fragments.size():
		var entry: Dictionary = _fragments[i]
		var frag: MeshInstance3D = entry["node"]
		var base_a: float = entry["angle"]
		var a := base_a + _t * 0.1
		frag.position.x = cos(a) * entry["r"]
		frag.position.z = sin(a) * entry["r"]
		frag.rotation.y = -a
	# Halo pulses.
	if is_instance_valid(_halo):
		var mat := _halo.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 0.6 + 0.4 * sin(_t * 1.2)


func _build_table() -> void:
	var table := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = table_radius
	cyl.bottom_radius = table_radius
	cyl.height = 0.05
	table.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = table_color
	mat.roughness = 0.7
	table.material_override = mat
	table.position.y = 0.85
	add_child(table)
	# Stand.
	var stand := MeshInstance3D.new()
	var s_cyl := CylinderMesh.new()
	s_cyl.top_radius = 0.06
	s_cyl.bottom_radius = 0.18
	s_cyl.height = 0.85
	stand.mesh = s_cyl
	stand.material_override = mat
	stand.position.y = 0.425
	add_child(stand)


func _build_fragments() -> void:
	for i in fragment_count:
		var a: float = TAU * float(i) / float(fragment_count) + randf() * 0.2
		var r: float = randf_range(0.18, table_radius - 0.08)
		var frag := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.003, 0.08)
		frag.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = fragment_color
		mat.emission_enabled = true
		mat.emission = fragment_color
		mat.emission_energy_multiplier = 1.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.85
		frag.material_override = mat
		frag.position = Vector3(cos(a) * r, 0.92 + randf() * 0.04, sin(a) * r)
		add_child(frag)
		_fragments.append({"node": frag, "angle": a, "r": r})


func _build_halo() -> void:
	_halo = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = table_radius * 0.7
	sphere.height = table_radius * 1.4
	_halo.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = halo_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.18
	mat.emission_enabled = true
	mat.emission = halo_color
	mat.emission_energy_multiplier = 0.6
	_halo.material_override = mat
	_halo.position.y = 1.2
	add_child(_halo)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "the commons"
	label.font_size = 28
	label.outline_size = 6
	label.modulate = halo_color
	label.position = Vector3(0, 1.7, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
