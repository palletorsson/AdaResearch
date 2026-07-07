extends SceneTree

## ground_layer_test_lab.gd
##
## Render a sample ground_paint layer through GroundLayerComponent —
## a 12×8 grid that mixes all 8 ground types into recognisable patches
## (so we can see "moss meets sand", "stone island in a sea of soil",
## "void cells alongside ash", etc.).
##
## Output:
##   public/ground-types/_layer_demo.png            — top-down overview
##   public/ground-types/_layer_demo_oblique.png    — 3/4 angle
##
## Also prints draw-call count: should be ≤ 8 (one MultiMesh per type
## actually used).
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/ground_layer_test_lab.gd

const GroundLayerComponentClass = preload(
	"res://commons/biome_layers/ground_layer_component.gd"
)

const OUT_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/ground-types"

# A hand-painted demo layer — 12 columns × 8 rows. Types mix in
# recognisable patches so the per-cell rendering is obvious.
# Tokens use the SHORT form (so / mo / st / sd / sn / as / wd / vd).
const DEMO_LAYER := [
	# z=0 (back)
	"sn sn sn sn so so so so wd wd mo mo",
	# z=1
	"sn sn sn so so so so so wd wd mo mo",
	# z=2
	"sn sn so so st st st so wd mo mo mo",
	# z=3
	"so so so st st vd st so so mo mo mo",
	# z=4
	"so so so st vd vd st so as as as mo",
	# z=5
	"so sd sd st st st so as as as as as",
	# z=6
	"sd sd sd sd so so so as as as as as",
	# z=7 (front)
	"sd sd sd sd sd so so so as as as as",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(OUT_DIR):
		DirAccess.make_dir_recursive_absolute(OUT_DIR)

	var root_3d := Node3D.new()
	get_root().add_child(root_3d)

	# Environment + sun.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	root_3d.add_child(sun)

	var camera := Camera3D.new()
	camera.fov = 35.0
	camera.near = 0.05
	camera.far = 100.0
	root_3d.add_child(camera)
	camera.current = true

	# Build the ground layer.
	var layer_node = GroundLayerComponentClass.new()
	root_3d.add_child(layer_node)

	var ctx := {
		"grid_center": Vector3.ZERO,
		"grid_dims":   Vector3i(12, 1, 8),
		"cube_size":   1.0,
	}
	var stats: Dictionary = layer_node.apply(DEMO_LAYER, ctx)
	print("[ground_layer] stats: %s" % stats)
	print("[ground_layer]   %d draw calls for %d tiles → %.2f tiles/call"
		% [stats.draw_calls, stats.tiles,
		   float(stats.tiles) / maxf(float(stats.draw_calls), 1.0)])

	await create_timer(0.4).timeout
	await process_frame
	await process_frame

	# ── Top-down overview ──
	camera.global_position = Vector3(0.0, 9.5, 0.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.FORWARD)
	camera.fov = 50.0
	await process_frame
	await process_frame
	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT_DIR + "/_layer_demo.png")
		print("[ground_layer] top-down overview written")

	# ── Oblique 3/4 view ──
	camera.global_position = Vector3(7.0, 7.0, 7.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.fov = 45.0
	await process_frame
	await process_frame
	var img2: Image = root.get_viewport().get_texture().get_image()
	if img2 != null:
		img2.save_png(OUT_DIR + "/_layer_demo_oblique.png")
		print("[ground_layer] oblique view written")

	print("[ground_layer] DONE")
	quit(0)
