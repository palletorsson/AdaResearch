# CAP Theorem Walk — pick two of three; the third stays dim
#
# Three pillars in a triangle, labeled "Consistency", "Availability", "Partition tolerance".
# A glowing line slowly cycles around the triangle, lighting two adjacent pillars at a time
# and dimming the third. At any moment, the lit pair tells you what the system has chosen;
# the dimmed pillar is what was given up.
#
# CAP is incompleteness for distributed systems: you cannot have all three. The walk makes
# the trade-off visible as a slow rotation, not a single fixed choice.
#
# @identity: First map where the player sees engineering live with a known limit.
# @qfep_term: Edge — the trade space, not the optimum.

extends Node3D
class_name CAPTheoremWalk

@export var pillar_color_off: Color = Color(0.3, 0.32, 0.4, 1.0)
@export var pillar_color_on: Color = Color(0.95, 0.85, 0.3, 1.0)
@export var triangle_radius: float = 0.9
@export var pillar_height: float = 1.5
@export var cycle_speed: float = 0.3

var _pillars: Array = []  # 3 pillars, ordered C, A, P
var _labels: Array = []
var _t: float = 0.0


func _ready() -> void:
	var names = ["Consistency", "Availability", "Partition\ntolerance"]
	for i in 3:
		var a: float = TAU * float(i) / 3.0 - PI * 0.5
		var pos := Vector3(cos(a) * triangle_radius, pillar_height * 0.5, sin(a) * triangle_radius)
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, pillar_height, 0.22)
		pillar.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = pillar_color_off
		mat.emission_enabled = true
		mat.emission = pillar_color_off
		mat.emission_energy_multiplier = 0.3
		pillar.material_override = mat
		pillar.position = pos
		add_child(pillar)
		_pillars.append(pillar)
		var label := Label3D.new()
		label.text = names[i]
		label.font_size = 22
		label.outline_size = 5
		label.modulate = pillar_color_on
		label.position = pos + Vector3(0, pillar_height * 0.5 + 0.25, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		_labels.append(label)


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * cycle_speed
	# Which two are lit?
	var phase: float = fmod(_t, 3.0)
	var dim_idx: int = int(phase)  # 0,1,2 cycles
	for i in 3:
		var pillar: MeshInstance3D = _pillars[i]
		var mat := pillar.material_override as StandardMaterial3D
		if not mat:
			continue
		if i == dim_idx:
			mat.albedo_color = pillar_color_off
			mat.emission = pillar_color_off
			mat.emission_energy_multiplier = 0.3
		else:
			mat.albedo_color = pillar_color_on
			mat.emission = pillar_color_on
			mat.emission_energy_multiplier = 2.0
