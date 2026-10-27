extends RefCounted
## The same controlled fill is used in native play and the web model export.
static func apply(sky: Node3D) -> void:
	sky.animate_sky = false
	sky.set_sky_time(0.0)
	sky.set_meta("study_sky_seconds", 0.0)
	var sun: DirectionalLight3D = sky.get_node("WarmSun")
	sun.light_cull_mask &= ~((1 << 17) | (1 << 18) | 0x1fffe)
	sun.light_color = Color.WHITE
	sun.light_energy = .08
	sky.environment.ambient_light_color = Color.WHITE
	sky.environment.ambient_light_energy = .08
	sky.environment.fog_depth_begin = 25.0
