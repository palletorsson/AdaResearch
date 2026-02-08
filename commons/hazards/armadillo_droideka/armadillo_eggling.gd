extends "res://commons/hazards/armadillo_droideka/armadillo_droideka.gd"
class_name ArmadilloEggling

func _ready() -> void:
	max_health = 26.0
	roll_speed = 4.3
	strafe_speed = 0.0
	turn_speed = 8.5
	detection_radius = 0.0
	disengage_radius = 0.0
	can_deploy_fire = false
	shots_per_burst = 0
	fire_interval = 0.8
	fire_speed = 0.0
	fire_damage = 0.0
	contact_damage = 9.0
	contact_damage_cooldown = 0.45

	scute_count = 10
	shell_radius = 0.5
	shell_height = 0.86
	shell_thickness = 0.07
	scute_open_degrees = 35.0
	scute_wave_degrees = 4.0
	ring_open_degrees = 16.0
	core_raise_height = 0.16
	leg_upper_length = 0.3
	leg_lower_length = 0.26

	scale = Vector3.ONE * 0.74
	super._ready()
	add_to_group("eggling")
