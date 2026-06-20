# Velocity Arrow — velocity as the derivative of position
#
# A small puck moves around a closed track. An arrow rides on the puck pointing in its
# direction of motion, with length proportional to speed. When the track curves tightly,
# the arrow rotates fast; when straight, it stays steady.
#
# Bridges the calculus introduced in change → the physics introduced in forces. The
# arrow IS the derivative of position. The next sequence (forces) will say "force changes
# velocity" — and the player will already know what velocity is.
#
# @identity
# essence: a puck circles a closed track with an arrow riding on it, pointing along motion, its length proportional to speed — velocity as the derivative of position
# desire: to let the player meet velocity before forces names it, so "force changes velocity" lands on something already understood
# critical_parameter: speed — how fast the puck circulates, and therefore how long and how quickly-rotating the arrow becomes
# triggers: the puck advances along the ellipse every frame; the arrow re-aims to the instantaneous direction of travel
# emerges: on tight curves the arrow swings fast, on straights it holds steady — the player sees that changing direction is itself a change in velocity
# needs: animated puck + direction arrow [has]; numeric speed readout [missing]; grabbable speed control so the player drives the puck [missing]
# relationships: the bridge artifact from change into forces — velocity = derivative of position here, force = change of velocity next; pairs with slope_tangent_demo
# truth: velocity is the derivative of position — motion is the visible rate at which where-you-are becomes where-you-are-next
# @qfep_term: F (deterministic motion) → ΔF/Δt = velocity.

extends Node3D
class_name VelocityArrow

@export_category("Track Settings")
@export var puck_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var arrow_color: Color = Color(1.0, 0.6, 0.25, 1.0)
@export var track_color: Color = Color(0.3, 0.35, 0.45, 1.0)
@export var track_radius_x: float = 1.4
@export var track_radius_z: float = 0.9
@export var puck_radius: float = 0.12
@export var speed: float = 0.6

var _puck: MeshInstance3D
var _arrow: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_build_track()
	_build_puck()
	_build_arrow()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("track_radius_x"):
		track_radius_x = float(config_data["track_radius_x"])
	if config_data.has("track_radius_z"):
		track_radius_z = float(config_data["track_radius_z"])
	if config_data.has("speed"):
		speed = float(config_data["speed"])


func _process(delta: float) -> void:
	_t += delta * speed
	_update_puck_and_arrow()


func _build_track() -> void:
	var track := MeshInstance3D.new()
	track.name = "Track"
	var imm := ImmediateMesh.new()
	imm.clear_surfaces()
	# Godot 4 removed PRIMITIVE_LINE_LOOP; use a LINE_STRIP and repeat the first
	# point to close the ring.
	imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var n := 96
	for i in n:
		var a: float = TAU * float(i) / float(n)
		var pos := _track_point(a)
		imm.surface_add_vertex(pos)
	imm.surface_add_vertex(_track_point(0.0))
	imm.surface_end()
	track.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = track_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	track.material_override = mat
	add_child(track)


func _track_point(angle: float) -> Vector3:
	# Asymmetric ellipse with a bulge to vary curvature.
	var x: float = cos(angle) * track_radius_x + sin(angle * 2.0) * 0.15
	var z: float = sin(angle) * track_radius_z
	return Vector3(x, 0.05, z)


func _build_puck() -> void:
	_puck = MeshInstance3D.new()
	_puck.name = "Puck"
	var s := SphereMesh.new()
	s.radius = puck_radius
	s.height = puck_radius * 2.0
	_puck.mesh = s
	var mat := StandardMaterial3D.new()
	mat.albedo_color = puck_color
	mat.emission_enabled = true
	mat.emission = puck_color
	mat.emission_energy_multiplier = 1.0
	_puck.material_override = mat
	add_child(_puck)


func _build_arrow() -> void:
	_arrow = MeshInstance3D.new()
	_arrow.name = "VelocityArrow"
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 0.04, 0.7)
	_arrow.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = arrow_color
	mat.emission_enabled = true
	mat.emission = arrow_color
	mat.emission_energy_multiplier = 1.6
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_arrow.material_override = mat
	add_child(_arrow)


func _update_puck_and_arrow() -> void:
	var a: float = fmod(_t, TAU)
	var p := _track_point(a)
	# Finite-difference velocity: tangent via a small angular step.
	var p_ahead := _track_point(a + 0.05)
	var v := (p_ahead - p) / 0.05  # approximate dP/da
	_puck.position = p + Vector3(0, 0.15, 0)
	var speed_mag := v.length()
	# Place the arrow at the puck, point along velocity, scale length by speed.
	_arrow.position = _puck.position + v.normalized() * 0.35
	var basis := Basis.looking_at(v.normalized(), Vector3.UP)
	_arrow.transform.basis = basis
	_arrow.scale.z = clamp(speed_mag * 0.7, 0.6, 2.2)
