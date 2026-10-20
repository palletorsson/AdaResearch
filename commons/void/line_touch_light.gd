extends Node
## The real XRTools body carries its illumination. No proxy interaction.
var lamp: OmniLight3D
var finish: StandardMaterial3D
var was_emissive := false
var old_emission := Color.BLACK
var old_energy := 0.0

func _ready() -> void:
	var body := get_parent() as XRToolsPickable
	var surface := body.get_node("Skin") as MeshInstance3D
	finish = surface.material_override.duplicate() as StandardMaterial3D
	surface.material_override = finish
	was_emissive = finish.emission_enabled
	old_emission = finish.emission
	old_energy = finish.emission_energy_multiplier
	lamp = OmniLight3D.new()
	lamp.name = "InteractionLight"
	lamp.light_color = Color("ffd8c3") if body.skin != "light" else Color("ffc1e1")
	lamp.light_energy = 2.4 if body.skin == "light" else 1.8
	lamp.omni_range = 3.6 if body.skin == "light" else 2.8
	lamp.omni_attenuation = 1.2
	lamp.shadow_enabled = body.skin == "light"
	body.add_child(lamp)
	body.picked_up.connect(func(_object): _illuminate(true))
	body.dropped.connect(func(_object): _illuminate(false))
	_illuminate(body.is_picked_up())

func _illuminate(active: bool) -> void:
	lamp.visible = active
	finish.emission_enabled = active or was_emissive
	finish.emission = lamp.light_color if active else old_emission
	finish.emission_energy_multiplier = 1.1 if active else old_energy
