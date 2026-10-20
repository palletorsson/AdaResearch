extends Node
## Point Coordinates experiment: the existing black point lights its surroundings
## only while held. Parent it to the actual pickable, so editor placement and
## XRTools movement carry the same light without a second position calculation.

const ENERGY := 2.0
const RANGE := 3.8
var light: OmniLight3D

func _ready() -> void:
	var point := get_parent() as RigidBody3D
	var surface := point.get_node("MeshInstance3D") as MeshInstance3D
	var finish := surface.material_override.duplicate() as StandardMaterial3D
	finish.albedo_color = Color(0.008, 0.008, 0.012)
	finish.emission_enabled = false
	finish.roughness = 0.10
	finish.clearcoat_enabled = true
	finish.clearcoat = 0.8
	finish.clearcoat_roughness = 0.06
	# material_override remains above the inherited pickup surface highlight.
	surface.material_override = finish
	light = OmniLight3D.new()
	light.name = "CarriedLight"
	light.light_color = Color("ffe6d1")
	light.light_energy = ENERGY
	light.omni_range = RANGE
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	light.visible = point.is_picked_up()
	point.add_child(light)
	point.picked_up.connect(_picked_up)
	point.dropped.connect(_dropped)

func _picked_up(_point: Node3D) -> void:
	light.show()

func _dropped(_point: Node3D) -> void:
	light.hide()
