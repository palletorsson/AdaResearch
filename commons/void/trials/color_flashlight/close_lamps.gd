extends RefCounted
## A reachable four-lamp fan. Soft cone edges overlap without repainting the wall.
const OFFSETS := [-0.45, -0.15, 0.15, 0.45]
const TARGETS := [-0.65, 0.0, 0.65, 2.6]
const STANDING_DISTANCE := 0.45

static func arrange(lamp: Node3D, index: int, stand_z: float, wall_z: float) -> void:
	lamp.position = Vector3(OFFSETS[index], 1.20, stand_z)
	lamp.basis = Basis.looking_at(Vector3(TARGETS[index], 2.05, wall_z)-lamp.position)
	var spot := lamp.get_node("SpotLight3D") as SpotLight3D
	spot.spot_range = 6.0
	spot.spot_angle = 40.0 if index < 3 else 28.0
	spot.spot_angle_attenuation = 2.2
	spot.spot_attenuation = 0.75
	spot.light_energy = 3.0 if index < 3 else 1.5
	# Three's penumbra is a preview approximation of Godot's angular curve.
	spot.set_meta("editor_beam_feather", 0.85)
	lamp.set_meta("void_lamp_standing_point", Vector3(0,0,stand_z-signf(wall_z-stand_z)*STANDING_DISTANCE))
