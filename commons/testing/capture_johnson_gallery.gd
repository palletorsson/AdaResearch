## Capture sweep for the parametric-johnson-gallery — 12 Johnson solids
## across three operation families: pyramids (J1, J2, J12, J13), cupolas (J3,
## J4, J5, J6), and elongated/gyroelongated pyramids (J7..J11).
##
## Same picture-perfect pattern as capture_parametric_mesh_gallery.gd:
## 1024×1024 SubViewport with isolated World3D, MSAA 8x + FXAA + filmic
## tonemap, three-light rig, three-quarter camera at 28°yaw/35°pitch.
##
## Run:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/capture_johnson_gallery.gd \
##     -- --out=user://parametric_johnson_gallery
extends SceneTree

const Pyramids = preload("res://commons/primitives/johnsonsolids/johnson_factory_pyramids.gd")
const Cupolas  = preload("res://commons/primitives/johnsonsolids/johnson_factory_cupolas.gd")
const Elongated = preload("res://commons/primitives/johnsonsolids/johnson_factory_elongated.gd")

const CAPTURE_SIZE: Vector2i = Vector2i(1024, 1024)
const BG_COLOR: Color = Color(0.06, 0.07, 0.10)

# Camera distance per solid — scaled so each solid occupies similar viewport area
const SCALE: float = 0.55

var _output_dir: String = "user://parametric_johnson_gallery"
var _entries: Array = []
var _viewport: SubViewport
var _scene_holder: Node3D
var _camera: Camera3D


# (id, factory_func_name, family, johnson_number, faces, vertices, edges, color, notes)
# Each entry's factory is invoked as Pyramids.<func>(SCALE, color) etc.
const ENTRIES: Array = [
	# Pyramids & bipyramids — warm hues
	{"id": "j01_square_pyramid",      "family": "pyramids",  "n": 1,  "v": 5,  "e": 8,  "f": 5,
	 "factory": "pyramids", "func": "create_j1_square_pyramid",
	 "color": Color(0.95, 0.60, 0.25), "name": "Square pyramid",
	 "notes": "4 triangular sides + 1 square base. The simplest Johnson solid — and the base case for J8, J10 (elongated / gyroelongated)."},
	{"id": "j02_pentagonal_pyramid",  "family": "pyramids",  "n": 2,  "v": 6,  "e": 10, "f": 6,
	 "factory": "pyramids", "func": "create_pentagonal_pyramid",
	 "color": Color(0.95, 0.55, 0.45), "name": "Pentagonal pyramid",
	 "notes": "5 triangular sides + 1 pentagonal base. Base case for J9, J11."},
	{"id": "j12_triangular_bipyramid","family": "pyramids",  "n": 12, "v": 5,  "e": 9,  "f": 6,
	 "factory": "pyramids", "func": "create_triangular_bipyramid",
	 "color": Color(0.55, 0.35, 0.85), "name": "Triangular bipyramid",
	 "notes": "Two tetrahedra base-to-base. 6 triangular faces, 5 vertices — the smallest bipyramid."},
	{"id": "j13_pentagonal_bipyramid","family": "pyramids",  "n": 13, "v": 7,  "e": 15, "f": 10,
	 "factory": "pyramids", "func": "create_pentagonal_bipyramid",
	 "color": Color(0.75, 0.35, 0.85), "name": "Pentagonal bipyramid",
	 "notes": "Two J2 pyramids glued at the pentagon. The pentagon dissolves into the interior — only 10 triangular faces remain visible."},

	# Cupolas & rotunda — cool hues
	{"id": "j03_triangular_cupola",   "family": "cupolas",   "n": 3,  "v": 9,  "e": 15, "f": 8,
	 "factory": "cupolas",  "func": "create_j3_triangular_cupola",
	 "color": Color(0.70, 0.90, 1.00), "name": "Triangular cupola",
	 "notes": "Top triangle + bottom hexagon + 3 squares + 3 triangles in the belt. The smallest cupola."},
	{"id": "j04_square_cupola",       "family": "cupolas",   "n": 4,  "v": 12, "e": 20, "f": 10,
	 "factory": "cupolas",  "func": "create_square_cupola",
	 "color": Color(0.40, 0.85, 0.95), "name": "Square cupola",
	 "notes": "Top square + bottom octagon + 4 squares + 4 triangles in the belt."},
	{"id": "j05_pentagonal_cupola",   "family": "cupolas",   "n": 5,  "v": 15, "e": 25, "f": 12,
	 "factory": "cupolas",  "func": "create_pentagonal_cupola",
	 "color": Color(0.35, 0.85, 0.85), "name": "Pentagonal cupola",
	 "notes": "Top pentagon + bottom decagon + 5 squares + 5 triangles in the belt."},
	{"id": "j06_pentagonal_rotunda",  "family": "cupolas",   "n": 6,  "v": 20, "e": 35, "f": 17,
	 "factory": "cupolas",  "func": "create_pentagonal_rotunda",
	 "color": Color(0.40, 0.85, 0.65), "name": "Pentagonal rotunda",
	 "notes": "Half of an icosidodecahedron. Top pentagon + bottom decagon + 10 triangles + 5 pentagons. The most face-diverse Johnson solid in this gallery."},

	# Elongated + gyroelongated — coral/violet hues
	{"id": "j07_elongated_triangular_pyramid",   "family": "elongated", "n": 7,  "v": 7,  "e": 12, "f": 7,
	 "factory": "elongated", "func": "create_elongated_triangular_pyramid",
	 "color": Color(0.95, 0.70, 0.30), "name": "Elongated triangular pyramid",
	 "notes": "Tetrahedron stacked on a triangular prism. The shared triangle face dissolves into the interior."},
	{"id": "j08_elongated_square_pyramid",       "family": "elongated", "n": 8,  "v": 9,  "e": 16, "f": 9,
	 "factory": "elongated", "func": "create_elongated_square_pyramid",
	 "color": Color(0.95, 0.50, 0.35), "name": "Elongated square pyramid",
	 "notes": "J1 stacked on a cube. The square cap turns the base case into a turret."},
	{"id": "j09_elongated_pentagonal_pyramid",   "family": "elongated", "n": 9,  "v": 11, "e": 20, "f": 11,
	 "factory": "elongated", "func": "create_elongated_pentagonal_pyramid",
	 "color": Color(0.95, 0.45, 0.55), "name": "Elongated pentagonal pyramid",
	 "notes": "J2 stacked on a pentagonal prism."},
	{"id": "j10_gyroelongated_square_pyramid",   "family": "elongated", "n": 10, "v": 9,  "e": 20, "f": 13,
	 "factory": "elongated", "func": "create_gyroelongated_square_pyramid",
	 "color": Color(0.65, 0.45, 0.95), "name": "Gyroelongated square pyramid",
	 "notes": "J1 on top of a square antiprism. Same vertex count as J8 but 4 more faces — the antiprism's triangulation."},
	{"id": "j11_gyroelongated_pentagonal_pyramid","family": "elongated", "n": 11, "v": 11, "e": 25, "f": 16,
	 "factory": "elongated", "func": "create_gyroelongated_pentagonal_pyramid",
	 "color": Color(0.45, 0.50, 0.95), "name": "Gyroelongated pentagonal pyramid",
	 "notes": "J2 on top of a pentagonal antiprism."},
]


func _initialize() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--out="):
			_output_dir = arg.split("=")[1]
	_run.call_deferred()


func _run() -> void:
	# Picture-perfect viewport
	_viewport = SubViewport.new()
	_viewport.size = CAPTURE_SIZE
	_viewport.transparent_bg = false
	_viewport.own_world_3d = true
	var iso_world := World3D.new()

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.74, 0.80)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.tonemap_white = 1.2
	iso_world.environment = env

	_viewport.world_3d = iso_world
	_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_8X
	_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_viewport.use_taa = false
	_viewport.use_debanding = true
	get_root().add_child(_viewport)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-50, 35, 0)
	key_light.light_energy = 1.6
	key_light.light_color = Color(1.0, 0.96, 0.88)
	_viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-15, -110, 0)
	fill_light.light_energy = 0.55
	fill_light.light_color = Color(0.72, 0.82, 1.0)
	_viewport.add_child(fill_light)

	var rim_light := DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25, 170, 0)
	rim_light.light_energy = 1.1
	rim_light.light_color = Color(1.0, 0.88, 0.96)
	_viewport.add_child(rim_light)

	_camera = Camera3D.new()
	_camera.fov = 38.0
	_camera.near = 0.01
	_camera.far = 50.0
	_camera.current = true
	var focus := Vector3.ZERO
	var distance := 2.4
	var yaw := deg_to_rad(28.0)
	var pitch := deg_to_rad(35.0)
	_camera.position = focus + Vector3(
		distance * sin(yaw) * cos(pitch),
		distance * sin(pitch),
		distance * cos(yaw) * cos(pitch)
	)
	_viewport.add_child(_camera)
	_camera.look_at(focus, Vector3.UP)

	_scene_holder = Node3D.new()
	_viewport.add_child(_scene_holder)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))

	for entry in ENTRIES:
		var node = _build_solid(entry)
		if not node:
			push_error("Failed to build %s" % entry["id"])
			continue
		_scene_holder.add_child(node)
		await create_timer(0.15).timeout
		await _capture(entry)
		_clear_holder()
		await create_timer(0.05).timeout

	# Write manifest
	var manifest := {
		"version": 1,
		"description": "Johnson solids J1–J13 across three operation families: pyramids + bipyramids (warm), cupolas + rotunda (cool), elongated + gyroelongated pyramids (mixed). The pedagogical claim of the gallery: the SAME base solid becomes different Johnson solids when you change the cap operation — J1 alone, J8 with prism cap (elongation), J10 with antiprism cap (gyroelongation). One base, three operators, three distinct solids.",
		"entries": _entries,
	}
	var f := FileAccess.open("%s/manifest.json" % _output_dir, FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("DONE — %d Johnson solids captured to %s" % [_entries.size(), _output_dir])
	quit(0)


func _build_solid(entry: Dictionary) -> Node3D:
	var func_name: String = entry["func"]
	var color: Color = entry["color"]
	# Static method dispatch — Godot doesn't allow `.call(name, ...)` on a class
	# directly, so we route via explicit `match` to each factory function.
	match func_name:
		"create_j1_square_pyramid":           return Pyramids.create_j1_square_pyramid(SCALE, color)
		"create_pentagonal_pyramid":          return Pyramids.create_pentagonal_pyramid(SCALE, color)
		"create_triangular_bipyramid":        return Pyramids.create_triangular_bipyramid(SCALE, color)
		"create_pentagonal_bipyramid":        return Pyramids.create_pentagonal_bipyramid(SCALE, color)
		"create_j3_triangular_cupola":        return Cupolas.create_triangular_cupola(SCALE, color)
		"create_square_cupola":               return Cupolas.create_square_cupola(SCALE, color)
		"create_pentagonal_cupola":           return Cupolas.create_pentagonal_cupola(SCALE, color)
		"create_pentagonal_rotunda":          return Cupolas.create_pentagonal_rotunda(SCALE, color)
		"create_elongated_triangular_pyramid": return Elongated.create_elongated_triangular_pyramid(SCALE, color)
		"create_elongated_square_pyramid":    return Elongated.create_elongated_square_pyramid(SCALE, color)
		"create_elongated_pentagonal_pyramid": return Elongated.create_elongated_pentagonal_pyramid(SCALE, color)
		"create_gyroelongated_square_pyramid": return Elongated.create_gyroelongated_square_pyramid(SCALE, color)
		"create_gyroelongated_pentagonal_pyramid": return Elongated.create_gyroelongated_pentagonal_pyramid(SCALE, color)
	push_error("Unknown factory function: %s" % func_name)
	return null


func _capture(entry: Dictionary) -> void:
	await create_timer(0.1).timeout
	var image := _viewport.get_texture().get_image()
	var img_rel := "%s.png" % entry["id"]
	var img_abs := "%s/%s" % [_output_dir, img_rel]
	image.save_png(ProjectSettings.globalize_path(img_abs))

	var config := {
		"johnson_number": entry["n"],
		"family": entry["family"],
		"name": entry["name"],
		"vertices": entry["v"],
		"edges": entry["e"],
		"faces": entry["f"],
		"euler": entry["v"] - entry["e"] + entry["f"],
		"notes": entry["notes"],
	}
	var cfg_rel := "%s.json" % entry["id"]
	var cf := FileAccess.open("%s/%s" % [_output_dir, cfg_rel], FileAccess.WRITE)
	cf.store_string(JSON.stringify(config, "\t"))
	cf.close()

	_entries.append({
		"id": entry["id"],
		"notes": entry["notes"],
		"family": entry["family"],
		"johnson_number": entry["n"],
		"name": entry["name"],
		"image": "/parametric-johnson-gallery/%s" % img_rel,
		"config": "/parametric-johnson-gallery/%s" % cfg_rel,
		"params": config,
	})
	print("  saved: %s (J%d)" % [entry["id"], entry["n"]])


func _clear_holder() -> void:
	for c in _scene_holder.get_children():
		_scene_holder.remove_child(c)
		c.queue_free()
