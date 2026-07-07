# Situated Sensor — knowledge with a body, a place, a time
#
# A small instrument on a tripod, with a glowing readout that displays its own location
# coordinates. As the player moves around it, the readout updates — the sensor is aware
# of its position and reports its measurements *as relative to* that position. There is
# no view from nowhere; this knower is always located.
#
# Counters the universalist fantasy that computation is placeless. The sensor knows what
# it sees only from where it stands.
#
# @identity: First map where computation has coordinates.
# @qfep_term: Edge — situated, not abstract.

extends Node3D
class_name SituatedSensor

@export var tripod_color: Color = Color(0.4, 0.42, 0.48, 1.0)
@export var lens_color: Color = Color(0.6, 0.95, 0.65, 1.0)
@export var readout_color: Color = Color(0.95, 0.85, 0.3, 1.0)

var _readout: Label3D
var _lens: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_tripod()
	_build_sensor_head()
	_build_readout()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_lens):
		var mat := _lens.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 1.4 + 0.4 * sin(_t * 2.0)
	# Update the readout to reflect the sensor's own world position.
	var gp := global_position
	if is_instance_valid(_readout):
		_readout.text = "I am here:\n  x = %.2f\n  y = %.2f\n  z = %.2f" % [gp.x, gp.y, gp.z]


func _build_tripod() -> void:
	for i in 3:
		var a: float = TAU * float(i) / 3.0
		var leg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.04, 0.9, 0.04)
		leg.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tripod_color
		mat.metallic = 0.6
		mat.roughness = 0.4
		leg.material_override = mat
		leg.position = Vector3(cos(a) * 0.18, 0.45, sin(a) * 0.18)
		leg.rotation = Vector3(sin(a) * 0.15, 0, -cos(a) * 0.15)
		add_child(leg)


func _build_sensor_head() -> void:
	var head := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.18, 0.25)
	head.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.27, 0.32, 1.0)
	mat.metallic = 0.5
	head.material_override = mat
	head.position = Vector3(0, 1.0, 0)
	add_child(head)
	# Lens.
	_lens = MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.08
	s.height = 0.16
	_lens.mesh = s
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = lens_color
	lmat.emission_enabled = true
	lmat.emission = lens_color
	lmat.emission_energy_multiplier = 1.6
	_lens.material_override = lmat
	_lens.position = Vector3(0, 1.0, 0.18)
	add_child(_lens)


func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.text = "I am here:\n  x = 0.00\n  y = 0.00\n  z = 0.00"
	_readout.font_size = 18
	_readout.outline_size = 4
	_readout.modulate = readout_color
	_readout.position = Vector3(0, 1.35, 0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_readout)
