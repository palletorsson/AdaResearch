extends WorldEnvironment

# Sky Shader Controller
# Controls the parameters of the sky.gdshader for different environments

enum SkyStyle {
	LAB_WHITE_BLUE,      # White/blue sci-fi lab style
	GRID_QUEER_JOYFUL    # Queer joyful scientific style
}

@export var sky_style: SkyStyle = SkyStyle.LAB_WHITE_BLUE
@export var auto_apply: bool = true

# Lab White/Blue Sci-Fi Parameters
var lab_params = {
	"day_top_color": Vector3(0.9, 0.95, 1.0),      # Bright white-blue
	"day_bottom_color": Vector3(0.7, 0.8, 1.0),    # Lighter blue
	"sunset_top_color": Vector3(0.8, 0.85, 1.0),   # Cool white
	"sunset_bottom_color": Vector3(0.6, 0.7, 1.0), # Soft blue
	"night_top_color": Vector3(0.1, 0.15, 0.3),    # Dark blue
	"night_bottom_color": Vector3(0.2, 0.25, 0.4), # Medium blue
	"horizon_color": Vector3(0.4, 0.6, 0.9),       # Blue horizon
	"sun_color": Vector3(8.0, 9.0, 12.0),          # Bright white sun
	"sun_sunset_color": Vector3(6.0, 7.0, 10.0),   # Cool white sunset
	"clouds_edge_color": Vector3(0.9, 0.95, 1.0),  # White cloud edges
	"clouds_top_color": Vector3(1.0, 1.0, 1.0),    # Pure white clouds
	"clouds_middle_color": Vector3(0.95, 0.97, 1.0), # Off-white clouds
	"clouds_bottom_color": Vector3(0.85, 0.9, 1.0), # Light blue clouds
	"clouds_speed": 0.5,                            # Slow, steady movement
	"clouds_scale": 0.8,                            # Smaller cloud patterns
	"clouds_cutoff": 0.4,                           # More defined clouds
	"clouds_fuzziness": 0.3,                        # Clean edges
	"clouds_weight": 0.1,                           # Light cloud coverage
	"clouds_blur": 0.2                              # Sharp cloud definition
}

# Grid Queer Joyful Scientific Parameters
var grid_params = {
	"day_top_color": Vector3(1.0, 0.8, 0.9),       # Pink-white
	"day_bottom_color": Vector3(0.9, 0.6, 0.8),    # Pink
	"sunset_top_color": Vector3(1.0, 0.7, 0.8),    # Bright pink
	"sunset_bottom_color": Vector3(0.8, 0.4, 0.6), # Deep pink
	"night_top_color": Vector3(0.3, 0.1, 0.2),     # Dark purple
	"night_bottom_color": Vector3(0.5, 0.2, 0.3),  # Purple
	"horizon_color": Vector3(0.8, 0.4, 0.6),       # Pink horizon
	"sun_color": Vector3(12.0, 8.0, 10.0),         # Pink-white sun
	"sun_sunset_color": Vector3(10.0, 6.0, 8.0),   # Pink sunset
	"clouds_edge_color": Vector3(1.0, 0.9, 0.95),  # Pink-white edges
	"clouds_top_color": Vector3(1.0, 0.8, 0.9),    # Pink-white clouds
	"clouds_middle_color": Vector3(0.95, 0.7, 0.85), # Pink clouds
	"clouds_bottom_color": Vector3(0.9, 0.6, 0.8), # Deeper pink clouds
	"clouds_speed": 2.0,                            # Energetic movement
	"clouds_scale": 1.2,                            # Larger, more dynamic patterns
	"clouds_cutoff": 0.2,                           # Fluffy, soft clouds
	"clouds_fuzziness": 0.7,                        # Soft, dreamy edges
	"clouds_weight": 0.3,                           # More cloud coverage
	"clouds_blur": 0.4                              # Soft cloud definition
}

func _ready():
	if auto_apply:
		apply_sky_style()

func _process(_delta):
	if auto_apply:
		apply_sky_style()

func apply_sky_style():
	if not environment or not environment.sky:
		return
	
	var params = get_current_params()
	apply_parameters_to_material(params)

func get_current_params() -> Dictionary:
	match sky_style:
		SkyStyle.LAB_WHITE_BLUE:
			return lab_params
		SkyStyle.GRID_QUEER_JOYFUL:
			return grid_params
		_:
			return lab_params

func apply_parameters_to_material(params: Dictionary):
	if not environment or not environment.sky:
		return
	
	var sky_material = environment.sky.sky_material
	if not sky_material:
		return
	
	# Apply sky colors
	sky_material.set_shader_parameter("day_top_color", params["day_top_color"])
	sky_material.set_shader_parameter("day_bottom_color", params["day_bottom_color"])
	sky_material.set_shader_parameter("sunset_top_color", params["sunset_top_color"])
	sky_material.set_shader_parameter("sunset_bottom_color", params["sunset_bottom_color"])
	sky_material.set_shader_parameter("night_top_color", params["night_top_color"])
	sky_material.set_shader_parameter("night_bottom_color", params["night_bottom_color"])
	
	# Apply horizon
	sky_material.set_shader_parameter("horizon_color", params["horizon_color"])
	
	# Apply sun
	sky_material.set_shader_parameter("sun_color", params["sun_color"])
	sky_material.set_shader_parameter("sun_sunset_color", params["sun_sunset_color"])
	
	# Apply clouds
	sky_material.set_shader_parameter("clouds_edge_color", params["clouds_edge_color"])
	sky_material.set_shader_parameter("clouds_top_color", params["clouds_top_color"])
	sky_material.set_shader_parameter("clouds_middle_color", params["clouds_middle_color"])
	sky_material.set_shader_parameter("clouds_bottom_color", params["clouds_bottom_color"])
	sky_material.set_shader_parameter("clouds_speed", params["clouds_speed"])
	sky_material.set_shader_parameter("clouds_scale", params["clouds_scale"])
	sky_material.set_shader_parameter("clouds_cutoff", params["clouds_cutoff"])
	sky_material.set_shader_parameter("clouds_fuzziness", params["clouds_fuzziness"])
	sky_material.set_shader_parameter("clouds_weight", params["clouds_weight"])
	sky_material.set_shader_parameter("clouds_blur", params["clouds_blur"])

# Public methods for runtime control
func set_sky_style(style: SkyStyle):
	sky_style = style
	apply_sky_style()

func set_lab_style():
	set_sky_style(SkyStyle.LAB_WHITE_BLUE)

func set_grid_style():
	set_sky_style(SkyStyle.GRID_QUEER_JOYFUL)

func set_sky_environment(env: Environment):
	environment = env
	apply_sky_style()

# Method to manually refresh parameters
func refresh_sky():
	apply_sky_style()

# Method to get current style name
func get_style_name() -> String:
	match sky_style:
		SkyStyle.LAB_WHITE_BLUE:
			return "Lab White/Blue Sci-Fi"
		SkyStyle.GRID_QUEER_JOYFUL:
			return "Grid Queer Joyful"
		_:
			return "Unknown"
