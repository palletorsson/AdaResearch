extends RefCounted
## One controlled illumination setup for play and the exported editor preview.
static func apply(sky: Node3D) -> void:
	sky.animate_sky = false
	sky.set_sky_time(0.0)
	sky.set_meta("study_sky_seconds",0.0)
	sky.get_node("WarmSun").light_cull_mask &= ~2
	# The surrounding original gallery stacks share one neutral directional
	# light instead of adding two lamps for each of the nineteen compositions.
	sky.get_node("WarmSun").light_color = Color.WHITE
	sky.environment.ambient_light_color = Color.WHITE
	sky.environment.ambient_light_energy = .45
	sky.environment.fog_depth_begin = 18.0
