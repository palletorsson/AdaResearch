## Capture pattern_maker_station configured to match web Pattern Studio settings.
## Usage: godot --path . --xr-mode off --no-window --script res://commons/testing/capture_pattern_compare.gd
extends SceneTree

const STATION_SCENE = "res://commons/artifacts/pattern_maker_station/pattern_maker_station.tscn"

# Greek Key / Meander — 8x8 PMM (matches web Pattern Studio)
const GREEK_KEY_DOMAIN: Array = [
	[1, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 0, 0, 0, 0, 1, 0],
	[0, 1, 1, 1, 1, 0, 1, 0],
	[0, 1, 0, 0, 1, 0, 1, 0],
	[0, 1, 0, 1, 1, 0, 1, 0],
	[0, 1, 0, 0, 0, 0, 1, 0],
	[0, 1, 1, 1, 1, 1, 1, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
]

# Web editor aging slider values (0-100 → 0.0-1.0)
const WEAR := 0.38
const DUST := 0.53
const FADE := 0.48
const CRACKS := 0.60
const STAINS := 0.30
const CHIPS := 0.25

var _frame := 0
var _station: Node3D
var _out_dir := "user://pattern_compare"
var _cam: Camera3D
var _shot_index := 0

func _initialize() -> void:
	print("pattern_compare: Starting...")

	# Create output directory
	DirAccess.make_dir_recursive_absolute(_out_dir)

	# Add environment
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.12, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.4
	env_node.environment = env
	root.add_child(env_node)

	# Add directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	root.add_child(light)

	# Camera
	_cam = Camera3D.new()
	_cam.current = true
	root.add_child(_cam)

	# Load station
	var scene := load(STATION_SCENE) as PackedScene
	if not scene:
		push_error("pattern_compare: Cannot load station scene")
		quit()
		return

	_station = scene.instantiate()

	# Configure to match web editor: PMM group (index 5), 8x8 domain, aging
	_station.apply_grid_config({
		"tile_size": 8,
		"wallpaper_group": 5,  # PMM
		"carpet_repeats": 6,
		"grout_width": 0.04,
		"use_gpu_tiling": true,
		"wear_amount": WEAR,
		"dust_amount": DUST,
		"fade_amount": FADE,
		"crack_density": CRACKS,
		"stain_amount": STAINS,
		"chip_amount": CHIPS,
	})

	root.add_child(_station)
	print("pattern_compare: Station configured — PMM 8x8 + aging")

func _process(_delta: float) -> bool:
	_frame += 1

	# Frame 60: write Greek Key domain into station
	if _frame == 60:
		_write_domain()
		return false

	# Frame 120: top-down shot
	if _frame == 120:
		_cam.position = Vector3(0, 5.0, 0.001)
		_cam.look_at(Vector3(0, 0, 0))
		_cam.fov = 50
		return false
	if _frame == 125:
		_save_shot("top_aged.png")
		return false

	# Frame 140: perspective front shot
	if _frame == 140:
		_cam.position = Vector3(3.5, 3.0, 4.5)
		_cam.look_at(Vector3(0, 0.2, 0))
		_cam.fov = 45
		return false
	if _frame == 145:
		_save_shot("front_aged.png")
		return false

	# Frame 160: close-up of carpet surface
	if _frame == 160:
		_cam.position = Vector3(0.8, 1.5, 1.0)
		_cam.look_at(Vector3(0.5, 0, 0.5))
		_cam.fov = 35
		return false
	if _frame == 165:
		_save_shot("closeup_aged.png")
		return false

	# Frame 170: done
	if _frame == 170:
		print("pattern_compare: Done — 3 shots saved to %s" % _out_dir)
		quit()
		return true

	return false

func _write_domain() -> void:
	# Directly set the station's internal grid to Greek Key pattern
	_station._grid_data.clear()
	for y in 8:
		var row: Array = []
		for x in 8:
			row.append(GREEK_KEY_DOMAIN[y][x])
		_station._grid_data.append(row)
	# Trigger carpet update
	_station._update_carpet()
	print("pattern_compare: Greek Key domain written, carpet updated")

func _save_shot(filename: String) -> void:
	var vp := root.get_viewport()
	var img := vp.get_texture().get_image()
	var path := _out_dir.path_join(filename)
	img.save_png(path)
	print("pattern_compare: ✅ %s -> %s" % [filename, path])
