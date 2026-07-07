# Catalyst Sustain Demo — the `sustain` affordance
#
# Demonstrates the catalyst bracelet's `sustain` mode introduced in the change sequence (order 4.5).
# Sustain = "hold this state for a duration"; the bracelet holds a position, a color, a constraint
# while the rest of the system continues to change around it. The mathematics: an integral —
# you sustain the integrand and let dt run.
#
# Visual: a glowing torus floats above a pedestal. While the player holds the bracelet near
# the torus with sustain active, a trail of after-images shows the integral of the player's
# motion path. Each held position contributes to a sum.
#
# @identity: The first place the player meets "hold this while time passes."
# @qfep_term: F (deterministic accumulation) — but pointing at integration over time φΔE(S,t).

extends Node3D
class_name CatalystSustainDemo

@export_category("Sustain Demo Settings")
@export var torus_inner_radius: float = 0.15
@export var torus_outer_radius: float = 0.4
@export var glow_color: Color = Color(0.95, 0.85, 0.3, 1.0)  # warm gold
@export var trail_color: Color = Color(0.95, 0.85, 0.3, 0.35)
@export var trail_length: int = 24
@export var pedestal_height: float = 0.9

var _torus_mesh: MeshInstance3D
var _trail_anchors: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_pedestal()
	_build_torus()
	_build_trail_anchors()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("glow_color"):
		glow_color = config_data["glow_color"]
	if config_data.has("trail_length"):
		trail_length = int(config_data["trail_length"])
	if config_data.has("pedestal_height"):
		pedestal_height = float(config_data["pedestal_height"])


func _process(delta: float) -> void:
	_t += delta
	if is_instance_valid(_torus_mesh):
		_torus_mesh.rotation.y = _t * 0.45
		_torus_mesh.position.y = pedestal_height + 0.55 + sin(_t * 1.4) * 0.04
	_update_trail()


func _build_pedestal() -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.4
	cyl.height = pedestal_height
	pedestal.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.18, 0.22, 1.0)
	mat.roughness = 0.85
	pedestal.material_override = mat
	pedestal.position.y = pedestal_height * 0.5
	add_child(pedestal)


func _build_torus() -> void:
	_torus_mesh = MeshInstance3D.new()
	_torus_mesh.name = "SustainTorus"
	var torus := TorusMesh.new()
	torus.inner_radius = torus_inner_radius
	torus.outer_radius = torus_outer_radius
	_torus_mesh.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glow_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 1.6
	mat.metallic = 0.3
	mat.roughness = 0.25
	_torus_mesh.material_override = mat
	_torus_mesh.position.y = pedestal_height + 0.55
	add_child(_torus_mesh)


func _build_trail_anchors() -> void:
	# Pre-place trail anchor markers in a circle.
	# In a full implementation, these would be driven by the bracelet's sustain path.
	for i in trail_length:
		var anchor := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.04
		s.height = 0.08
		anchor.mesh = s
		var mat := StandardMaterial3D.new()
		mat.albedo_color = trail_color
		mat.emission_enabled = true
		mat.emission = trail_color
		mat.emission_energy_multiplier = 0.8
		anchor.material_override = mat
		anchor.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		add_child(anchor)
		_trail_anchors.append(anchor)


func _update_trail() -> void:
	# Trail forms a slowly drifting helix around the torus — visualizing
	# "the bracelet held position over time, the integral accumulated".
	var n := _trail_anchors.size()
	for i in n:
		var anchor: MeshInstance3D = _trail_anchors[i]
		var phase := _t * 0.7 + float(i) * TAU / float(n)
		var r := 0.55
		var height := pedestal_height + 0.55 + cos(phase * 1.6) * 0.18
		anchor.position = Vector3(cos(phase) * r, height, sin(phase) * r)
		# Older trail points (further around the ring) fade.
		var fade := 1.0 - float(i) / float(n)
		var mat := anchor.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = fade * 1.1
