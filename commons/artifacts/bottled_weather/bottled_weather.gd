extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BottledWeather

## @identity
## lineage: the Room hero — Environment colour (ambient, fog, sky) is the one colour
##   you cannot pick up, because you are standing in it. So here it is picked up: a
##   bell jar on a plinth holding a complete miniature weather — sky gradient painted
##   on the inner glass, a fog bank of layered translucent shells, a tiny park bench
##   at the bottom facing a tiny sunset it will never leave.
## essence: Environment is colour with no object — ambient light, fog density, sky.
##   The jar makes it graspable by scale: the bench is you; the amber layer is the
##   hour; the fog is the room deciding how far you may see. Three exhibits of the
##   same fact: the room colours everything before anything colours itself.
## truth: you never see a room's colour; you see everything else THROUGH it. The only
##   way to look AT weather is to bottle it.
##
## The 2026-08-27 category-heroes pass, color. A snow-globe of atmosphere.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 5
@export var jar_r: float = 0.55
@export var jar_h: float = 1.1
## The bottled hour, 0..1 = night..noon. 0.32 is a museum sunset: amber low, teal high.
@export_range(0.0, 1.0, 0.01) var hour: float = 0.32

func _ready() -> void:
	_rng.seed = seed
	_build_plinth()
	_build_weather()
	_build_jar()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "jar_r", "jar_h", "hour"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_plinth() -> void:
	var plinth := MeshInstance3D.new()
	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = jar_r + 0.14
	plinth_mesh.bottom_radius = jar_r + 0.2
	plinth_mesh.height = 0.9
	plinth.mesh = plinth_mesh
	plinth.position = Vector3(0.0, 0.45, 0.0)
	plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(plinth)
	var brass := MeshInstance3D.new()
	var brass_mesh := TorusMesh.new()
	brass_mesh.inner_radius = jar_r + 0.1
	brass_mesh.outer_radius = jar_r + 0.16
	brass.mesh = brass_mesh
	brass.position = Vector3(0.0, 0.9, 0.0)
	brass.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(brass)

func _build_weather() -> void:
	var base_y := 0.92
	# the ground inside: a disc of dusk park
	var ground := MeshInstance3D.new()
	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = jar_r - 0.05
	ground_mesh.bottom_radius = jar_r - 0.05
	ground_mesh.height = 0.03
	ground.mesh = ground_mesh
	ground.position = Vector3(0.0, base_y + 0.015, 0.0)
	ground.material_override = _matte_mat(Color(0.14, 0.18, 0.14).lerp(Color(0.25, 0.2, 0.12), hour), 0.95)
	add_child(ground)
	# THE SKY: painted on an inner shell, graded by stacked translucent bands —
	# horizon amber to zenith teal at the bottled hour
	var horizon := Color(0.95, 0.55, 0.25).lerp(Color(0.9, 0.85, 0.7), hour)
	var zenith := Color(0.10, 0.22, 0.38).lerp(Color(0.45, 0.7, 0.9), hour)
	var bands := 6
	for k in range(bands):
		var u := float(k) / float(bands - 1)
		var band := MeshInstance3D.new()
		var band_mesh := CylinderMesh.new()
		var r := (jar_r - 0.07) * (1.0 - 0.06 * u)
		band_mesh.top_radius = r * (1.0 - 0.35 * u)
		band_mesh.bottom_radius = r
		band_mesh.height = (jar_h - 0.2) / float(bands)
		band.mesh = band_mesh
		band.position = Vector3(0.0, base_y + 0.1 + (jar_h - 0.25) * (u * 0.85 + 0.07), 0.0)
		var bm := StandardMaterial3D.new()
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var col := horizon.lerp(zenith, u)
		bm.albedo_color = Color(col.r, col.g, col.b, 0.22)
		bm.emission_enabled = true
		bm.emission = col
		bm.emission_energy_multiplier = 0.5 if emissive else 0.15
		bm.cull_mode = BaseMaterial3D.CULL_FRONT   # paint the INSIDE: sky is seen from within
		band.material_override = bm
		add_child(band)
	# THE FOG BANK: two low translucent lenses hugging the ground
	for k in range(2):
		var fog := MeshInstance3D.new()
		var fog_mesh := SphereMesh.new()
		fog_mesh.radius = jar_r - 0.12 - 0.05 * float(k)
		fog_mesh.height = 0.16 - 0.04 * float(k)
		fog.mesh = fog_mesh
		fog.position = Vector3(0.05 * float(k), base_y + 0.08 + 0.05 * float(k), -0.04 * float(k))
		var fm := StandardMaterial3D.new()
		fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		fm.albedo_color = Color(0.85, 0.8, 0.75, 0.18)
		fog.material_override = fm
		add_child(fog)
	# THE BENCH, facing the sunset it will never leave — you, at 1:40 scale
	var bench_seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.14, 0.012, 0.05)
	bench_seat.mesh = seat_mesh
	bench_seat.position = Vector3(0.1, base_y + 0.06, 0.12)
	bench_seat.rotation.y = deg_to_rad(-30.0)
	bench_seat.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
	add_child(bench_seat)
	var bench_back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.14, 0.05, 0.01)
	bench_back.mesh = back_mesh
	bench_back.position = bench_seat.position + Vector3(sin(deg_to_rad(-30.0)) * -0.025, 0.03, cos(deg_to_rad(-30.0)) * 0.025)
	bench_back.rotation.y = deg_to_rad(-30.0)
	bench_back.material_override = _matte_mat(Color(0.35, 0.22, 0.12), 0.85)
	add_child(bench_back)
	for sx in [-0.055, 0.055]:
		var leg := MeshInstance3D.new()
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.012, 0.05, 0.045)
		leg.mesh = leg_mesh
		leg.position = bench_seat.position + Vector3(cos(deg_to_rad(-30.0)) * sx, -0.03, sin(deg_to_rad(30.0)) * sx)
		leg.rotation.y = deg_to_rad(-30.0)
		leg.material_override = _matte_mat(Color(0.2, 0.2, 0.22), 0.7)
		add_child(leg)
	# the sun itself: one amber pearl low on the west glass
	var sun := MeshInstance3D.new()
	var sun_mesh := SphereMesh.new()
	sun_mesh.radius = 0.045
	sun_mesh.height = 0.09
	sun.mesh = sun_mesh
	sun.position = Vector3(-jar_r + 0.16, base_y + 0.22, -0.1)
	sun.material_override = _glow_mat(Color(0.98, 0.62, 0.22), 2.4)
	add_child(sun)

func _build_jar() -> void:
	var jar := MeshInstance3D.new()
	var jar_mesh := CylinderMesh.new()
	jar_mesh.top_radius = jar_r * 0.55
	jar_mesh.bottom_radius = jar_r
	jar_mesh.height = jar_h
	jar.mesh = jar_mesh
	jar.position = Vector3(0.0, 0.92 + jar_h * 0.5, 0.0)
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.75, 0.85, 0.9, 0.10)
	gm.roughness = 0.03
	gm.metallic = 0.1
	jar.material_override = gm
	add_child(jar)
	var knob := MeshInstance3D.new()
	var knob_mesh := SphereMesh.new()
	knob_mesh.radius = 0.07
	knob_mesh.height = 0.14
	knob.mesh = knob_mesh
	knob.position = Vector3(0.0, 0.92 + jar_h + 0.05, 0.0)
	knob.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(knob)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "WeatherPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(jar_r + 0.5), 0.24, 0.6)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("BOTTLED WEATHER - Environment",
			"The room's colour is the one colour you cannot pick up - you stand in it.\nSo here it is, picked up: sky, fog and hour under glass, with a bench\nfor scale. You never see a room's colour; you see everything else through it.")
