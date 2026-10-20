extends Node3D
## Shared by the playable tower and the architectural viewer.
## Slowly shifting rose/violet cloud sea; nearby jump edges stay clear on Mobile.
const CloudSky := preload("res://commons/void/cloud_sky.gdshader")
const CityHorizon := preload("res://commons/void/city_horizon.gd")
var city: MultiMeshInstance3D
## One rose → violet → rose cycle, in seconds. Clouds follow a seamless drift.
@export_range(120.0, 3600.0, 1.0) var cycle_seconds := 720.0
## A still-sky option for captures or installations.
@export var animate_sky := true
## Retain daylight for comparison; the tower now opens at evening.
@export_enum("Daylight", "Evening") var lighting_mode := 1
const UPDATE_INTERVAL := 1.0
var environment: Environment
var sky_material: ShaderMaterial
var elapsed := 0.0
var update_elapsed := 0.0

func _ready() -> void:
	name = "SkyAtmosphere"
	var noise := FastNoiseLite.new()
	noise.seed = 418
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.fractal_octaves = 4
	var cloud_image := noise.get_seamless_image(512, 512)
	cloud_image.generate_mipmaps()
	sky_material = ShaderMaterial.new()
	sky_material.shader = CloudSky
	sky_material.set_shader_parameter("cloud_noise", ImageTexture.create_from_image(cloud_image))
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	# One tiny phase update per second. Do not use shader TIME: that would
	# invalidate sky reflections every frame. Spread cubemap work across frames.
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	environment = Environment.new()
	# NatureRenderer discovers WorldEnvironments at boot. This authored sky
	# owns its fog/ambient cycle; ecosystem weather belongs to biome scenes.
	environment.set_meta("scene_owned_atmosphere", true)
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_sky_contribution = 0.0
	environment.ambient_light_color = Color("c4add7")
	environment.ambient_light_energy = 0.55
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_density = 0.75
	environment.fog_light_color = Color("d4b5cf")
	environment.fog_light_energy = 0.8
	environment.fog_depth_begin = 6.0
	environment.fog_depth_end = 60.0
	environment.fog_depth_curve = 1.2
	environment.fog_sky_affect = 0.0
	# Standard depth fog works on Quest's Mobile renderer; no volumetric pass.
	var world := WorldEnvironment.new()
	world.name = "SkyAndFog"
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "WarmSun"
	sun.rotation_degrees = Vector3(-24, -32, 0)
	sun.light_color = Color("ffe3d1")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	city = CityHorizon.new()
	add_child(city)
	set_lighting_mode(lighting_mode)
	set_sky_time(0.0)

func set_lighting_mode(mode: int) -> void:
	lighting_mode = clampi(mode, 0, 1)
	if environment == null: return
	var evening := lighting_mode == 1
	var sun := get_node("WarmSun") as DirectionalLight3D
	sun.rotation_degrees.x = -8.0 if evening else -24.0
	sun.light_color = Color("ecb6c4") if evening else Color("ffe3d1")
	sun.light_energy = 0.18 if evening else 1.1
	environment.ambient_light_energy = 0.24 if evening else 0.55
	environment.fog_light_energy = 0.45 if evening else 0.8
	var colours := {
		"rose_zenith": [Color("8e58b4"), Color("211c3d")],
		"violet_zenith": [Color("5d46a4"), Color("171b37")],
		"rose_horizon": [Color("f4b8d6"), Color("835570")],
		"violet_horizon": [Color("c49ae6"), Color("565178")],
		"rose_shadow": [Color("9d78af"), Color("302c48")],
		"violet_shadow": [Color("6f69aa"), Color("252b4a")],
		"rose_light": [Color("fff0ef"), Color("926b87")],
		"violet_light": [Color("eadffc"), Color("746990")]
	}
	for key in colours: sky_material.set_shader_parameter(key,colours[key][lighting_mode])
	sky_material.set_shader_parameter("sun_direction",sun.global_basis.z.normalized())
	sky_material.set_shader_parameter("sun_strength",0.18 if evening else 1.0)
	set_sky_time(elapsed)

func _process(delta: float) -> void:
	if not animate_sky: return
	elapsed = fposmod(elapsed + delta, maxf(cycle_seconds, 120.0))
	update_elapsed += delta
	if update_elapsed < UPDATE_INTERVAL: return
	update_elapsed = fmod(update_elapsed, UPDATE_INTERVAL)
	set_sky_time(elapsed)

## Sample the same procedural cycle at a known time, also used by render checks.
func set_sky_time(seconds: float) -> void:
	elapsed = fposmod(seconds, maxf(cycle_seconds, 120.0))
	var phase := elapsed / maxf(cycle_seconds, 120.0) * TAU
	sky_material.set_shader_parameter("cycle_phase", phase)
	var violet := 0.5 - 0.5 * cos(phase)
	if lighting_mode == 1:
		environment.fog_light_color = Color("62516d").lerp(Color("4b4b6b"), violet)
		environment.ambient_light_color = Color("b6a9c9").lerp(Color("a5afd0"), violet)
	else:
		environment.fog_light_color = Color("d4b5cf").lerp(Color("bcb0de"), violet)
		environment.ambient_light_color = Color("c4add7").lerp(Color("b4b1db"), violet)
	city.set_haze(environment.fog_light_color)
