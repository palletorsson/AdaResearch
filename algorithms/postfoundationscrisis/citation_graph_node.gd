# Citation Graph Node — a single claim, its supporters, its detractors
#
# A central glowing sphere (the claim) surrounded by smaller satellites at different
# orbits. Some satellites pulse green (supporting citations); some pulse red
# (refutations). Lines connect the central sphere to each satellite, colored by stance.
#
# A claim doesn't stand alone. It is held up — or pulled down — by the network of
# other claims it is in conversation with. The point of the citation graph is that the
# claim's *truth* lives in the relations, not in the lone sphere.
#
# @identity: First map where the player sees a claim's social fabric.
# @qfep_term: Edge — relational truth.

extends Node3D
class_name CitationGraphNode

@export var central_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var support_color: Color = Color(0.5, 0.95, 0.55, 1.0)
@export var refute_color: Color = Color(1.0, 0.45, 0.4, 1.0)
@export var support_count: int = 7
@export var refute_count: int = 4
@export var orbit_radius_supports: float = 0.7
@export var orbit_radius_refutes: float = 1.1
@export var rotation_speed: float = 0.25

var _central: MeshInstance3D
var _supports: Array = []
var _refutes: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_central()
	_build_satellites()
	_build_connections()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	# Orbits.
	for i in _supports.size():
		var sat: MeshInstance3D = _supports[i]
		var a: float = TAU * float(i) / float(_supports.size()) + _t
		sat.position = Vector3(cos(a) * orbit_radius_supports, 1.0, sin(a) * orbit_radius_supports)
	for i in _refutes.size():
		var sat: MeshInstance3D = _refutes[i]
		var a: float = TAU * float(i) / float(_refutes.size()) - _t * 0.7
		sat.position = Vector3(cos(a) * orbit_radius_refutes, 1.0 + 0.15, sin(a) * orbit_radius_refutes)
	# Redraw the connection lines (cheap and clear).
	for child in get_children():
		if child.name.begins_with("_conn_"):
			child.queue_free()
	_build_connections()


func _build_central() -> void:
	_central = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.16
	s.height = 0.32
	_central.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = central_color
	mat.emission_enabled = true
	mat.emission = central_color
	mat.emission_energy_multiplier = 2.2
	_central.material_override = mat
	_central.position.y = 1.0
	add_child(_central)


func _build_satellites() -> void:
	for i in support_count:
		var node := _make_sat(support_color)
		add_child(node)
		_supports.append(node)
	for i in refute_count:
		var node := _make_sat(refute_color)
		add_child(node)
		_refutes.append(node)


func _make_sat(color: Color) -> MeshInstance3D:
	var sat := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.07
	s.height = 0.14
	sat.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.3
	sat.material_override = mat
	return sat


func _build_connections() -> void:
	var center := Vector3(0, 1.0, 0)
	for i in _supports.size():
		_draw_line("_conn_s_" + str(i), center, (_supports[i] as MeshInstance3D).position, support_color)
	for i in _refutes.size():
		_draw_line("_conn_r_" + str(i), center, (_refutes[i] as MeshInstance3D).position, refute_color)


func _draw_line(line_name: String, a: Vector3, b: Vector3, color: Color) -> void:
	var line := MeshInstance3D.new()
	line.name = line_name
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	imm.surface_add_vertex(a)
	imm.surface_add_vertex(b)
	imm.surface_end()
	line.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line.material_override = mat
	add_child(line)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "the claim, and what argues with it"
	label.font_size = 22
	label.outline_size = 5
	label.modulate = Color(0.95, 0.95, 0.7, 1.0)
	label.position = Vector3(0, 1.55, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
