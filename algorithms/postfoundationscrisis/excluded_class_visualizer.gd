# Excluded Class Visualizer — algorithmic bias as structural incompleteness
#
# A scatter of points on a plane, separated by a thick straight classification boundary.
# Most points fall cleanly on one side or the other. But a third cluster — pulsing red,
# placed by the boundary — represents the *excluded class*: points the model never had
# enough examples of, points it cannot classify, points outside the training data.
#
# The visualization makes Gödel's claim physical: every formal classifier has a class
# it cannot decide. Bias is not a bug. Bias is the *shape* of the model's outside.
#
# @identity: First map where the player sees what the classifier cannot see.
# @qfep_term: Edge — incompleteness as constitutive.

extends Node3D
class_name ExcludedClassVisualizer

@export var class_a_color: Color = Color(0.45, 0.85, 1.0, 1.0)
@export var class_b_color: Color = Color(1.0, 0.85, 0.4, 1.0)
@export var excluded_color: Color = Color(1.0, 0.35, 0.4, 1.0)
@export var boundary_color: Color = Color(0.7, 0.7, 0.8, 1.0)
@export var domain_size: float = 1.8
@export var class_count_each: int = 30
@export var excluded_count: int = 10

var _t: float = 0.0
var _excluded_nodes: Array = []


func _ready() -> void:
	_build_floor()
	_build_classes()
	_build_excluded()
	_build_boundary()
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * 0.9
	for node in _excluded_nodes:
		var mat := (node as MeshInstance3D).material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.6 + 0.8 * sin(_t + node.position.x * 5.0)


func _build_floor() -> void:
	var floor := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(domain_size, 0.02, domain_size)
	floor.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.16, 0.2, 1.0)
	floor.material_override = mat
	add_child(floor)


func _build_classes() -> void:
	# Class A on the left of the boundary; Class B on the right.
	for class_data in [
		{"side": -1.0, "color": class_a_color},
		{"side": 1.0, "color": class_b_color},
	]:
		for i in class_count_each:
			var sphere := MeshInstance3D.new()
			var s := SphereMesh.new()
			s.radius = 0.04
			s.height = 0.08
			sphere.mesh = s
			var mat := StandardMaterial3D.new()
			mat.albedo_color = class_data["color"]
			mat.emission_enabled = true
			mat.emission = class_data["color"]
			mat.emission_energy_multiplier = 1.0
			sphere.material_override = mat
			# Side scatter.
			var x: float = class_data["side"] * randf_range(0.15, domain_size * 0.45)
			var z: float = randf_range(-domain_size * 0.4, domain_size * 0.4)
			sphere.position = Vector3(x, 0.06, z)
			add_child(sphere)


func _build_excluded() -> void:
	# Excluded class sits ON the boundary — undecidable.
	for i in excluded_count:
		var sphere := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.05
		s.height = 0.1
		sphere.mesh = s
		var mat := StandardMaterial3D.new()
		mat.albedo_color = excluded_color
		mat.emission_enabled = true
		mat.emission = excluded_color
		mat.emission_energy_multiplier = 1.8
		sphere.material_override = mat
		var x: float = randf_range(-0.08, 0.08)
		var z: float = randf_range(-domain_size * 0.4, domain_size * 0.4)
		sphere.position = Vector3(x, 0.08, z)
		add_child(sphere)
		_excluded_nodes.append(sphere)


func _build_boundary() -> void:
	var line := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.02, 0.05, domain_size)
	line.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = boundary_color
	mat.emission_enabled = true
	mat.emission = boundary_color
	mat.emission_energy_multiplier = 1.2
	line.material_override = mat
	line.position.y = 0.04
	add_child(line)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "the class the classifier cannot see"
	label.font_size = 24
	label.outline_size = 5
	label.modulate = excluded_color
	label.position = Vector3(0, 0.95, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
