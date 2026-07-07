extends SceneTree

## ground_types_demo_lab.gd
##
## Render every ground type from commons/biome_layers/ground_types.json
## as a tile in a grid, plus a labelled overview shot. Output is one
## PNG per type for the encyclopedia's /ground-types page, and one
## combined overview PNG.
##
## Run:
##   godot --xr-mode off --no-window \
##     --script res://commons/testing/ground_types_demo_lab.gd

const GroundPatchClass = preload("res://commons/testing/ground_patch.gd")

const OUT_DIR := "C:/Users/palle/Documents/GitHub/ada_encyclopedia/public/ground-types"

var _camera: Camera3D = null
var _root_3d: Node3D = null
var _patch: Node3D = null  # currently rendered patch (so we can free it)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not DirAccess.dir_exists_absolute(OUT_DIR):
		DirAccess.make_dir_recursive_absolute(OUT_DIR)

	_setup_scene()
	await process_frame
	await process_frame

	# Render each type as a standalone close-up tile.
	var catalog: Dictionary = GroundPatchClass.get_ground_types()
	var type_ids: Array = catalog.keys()
	type_ids.sort()
	print("[ground_demo] %d types queued" % type_ids.size())

	var entries: Array = []
	for type_id in type_ids:
		var ok: bool = await _render_one(type_id, catalog[type_id])
		if ok:
			entries.append({
				"id": type_id,
				"label": catalog[type_id].get("label", type_id),
				"notes": catalog[type_id].get("notes", ""),
				"image": "/ground-types/%s.png" % type_id,
				"walkable": catalog[type_id].get("walkable", true),
			})

	# Render one OVERVIEW shot — all types arranged as a 4×2 grid.
	if _patch and is_instance_valid(_patch):
		_patch.queue_free()
		await process_frame
	await _render_overview(catalog, type_ids)

	# Write manifest for the Next.js page.
	var manifest := {
		"version": 1,
		"description": "Ground type catalog rendered for /ground-types page.",
		"entries": entries,
	}
	var f := FileAccess.open(OUT_DIR + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	print("[ground_demo] manifest.json written")
	print("[ground_demo] DONE: %d ground types captured + 1 overview"
		% entries.size())
	quit(0)


func _setup_scene() -> void:
	_root_3d = Node3D.new()
	get_root().add_child(_root_3d)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.92, 0.92, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.ambient_light_energy = 0.7
	env.ambient_light_color = Color(0.95, 0.95, 1.0)
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_root_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.4
	sun.shadow_enabled = false
	_root_3d.add_child(sun)

	_camera = Camera3D.new()
	_camera.fov = 35.0
	_camera.near = 0.05
	_camera.far = 50.0
	_root_3d.add_child(_camera)
	_camera.current = true


## Render one ground type as a 2x2m close-up tile.
func _render_one(type_id: String, type_def: Dictionary) -> bool:
	if _patch and is_instance_valid(_patch):
		_patch.queue_free()
		await process_frame

	var anchor := Node3D.new()
	_root_3d.add_child(anchor)
	_patch = anchor
	GroundPatchClass.attach_type(anchor, type_id, Vector2(2.0, 2.0))

	# Camera at 3/4 angle, slightly looking down.
	_camera.global_position = Vector3(1.6, 1.4, 1.6)
	_camera.look_at(Vector3.ZERO, Vector3.UP)

	await create_timer(0.4).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img == null:
		push_warning("[ground_demo] image null for %s" % type_id)
		return false
	var save_err := img.save_png(OUT_DIR + "/%s.png" % type_id)
	if save_err != OK:
		push_warning("[ground_demo] save failed for %s" % type_id)
		return false
	print("[ground_demo]   %s ✓" % type_id)
	return true


## Render an overview shot: all 8 types in a 4-wide grid, viewed at
## an oblique angle so each tile is recognisable.
func _render_overview(catalog: Dictionary, type_ids: Array) -> void:
	# Lay out tiles in a 4-wide grid spaced 2.5m apart.
	var per_row: int = 4
	var spacing: float = 2.5
	var x_offset: float = -(float(per_row) - 1) * 0.5 * spacing
	for i in type_ids.size():
		var col: int = i % per_row
		var row: int = i / per_row
		var anchor := Node3D.new()
		anchor.position = Vector3(
			x_offset + float(col) * spacing,
			0.0,
			float(row) * spacing - spacing * 0.5
		)
		_root_3d.add_child(anchor)
		GroundPatchClass.attach_type(anchor, type_ids[i],
			Vector2(2.0, 2.0))

	# Camera high + back, looking down at the grid centre.
	_camera.global_position = Vector3(0.0, 6.0, 5.0)
	_camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)

	await create_timer(0.5).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(OUT_DIR + "/_overview.png")
		print("[ground_demo] overview ✓")
