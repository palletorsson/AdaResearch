extends SceneTree

## Native 16:9 evidence capture for the museum wall AAA acceptance matrix.
##
## This runner deliberately does not use capture_config_sweep.gd: that bench is a
## stable 760px DNA-comparison instrument. C27 is a different contract: nine
## entities, three untouched 1920x1080 views, complete revision/camera/lookdev
## manifests, and a renderer that must be Forward+ or Mobile.

const WIDTH := 1920
const HEIGHT := 1080
const OUT_DIR := "res://ada_run/museum_aaa_pass/c27_round5"
const MANIFEST_PATH := "res://ada_run/museum_aaa_pass/round5_c27_capture_manifest.json"
const CONTEXT_SCENE := "res://commons/artifacts/museum/museum_wall_piece_ideal_context.tscn"

const ENTITIES: Array[Dictionary] = [
	{"id":"atlas","scene":"res://commons/artifacts/museum/museum_wall_kit_atlas.tscn","params":{},"seed":4067,"lod":0},
	{"id":"full_build","scene":"res://commons/artifacts/museum/museum_wall_aaa_showcase.tscn","params":{"enable_lights":true},"seed":13249,"lod":0},
	{"id":"solid","scene":CONTEXT_SCENE,"params":{"kind":"solid","width_cells":4},"seed":13249,"lod":0},
	{"id":"feature","scene":CONTEXT_SCENE,"params":{"kind":"feature","width_cells":4},"seed":13357,"lod":0},
	{"id":"window","scene":CONTEXT_SCENE,"params":{"kind":"window","width_cells":4},"seed":13463,"lod":0},
	{"id":"vitrine","scene":CONTEXT_SCENE,"params":{"kind":"vitrine","width_cells":4},"seed":13567,"lod":0},
	{"id":"service","scene":CONTEXT_SCENE,"params":{"kind":"service","width_cells":4},"seed":13669,"lod":0},
	{"id":"portal","scene":CONTEXT_SCENE,"params":{"kind":"portal","width_cells":4},"seed":13781,"lod":0},
	{"id":"endcap","scene":CONTEXT_SCENE,"params":{"kind":"endcap","width_cells":2},"seed":13883,"lod":0}
]

const SOURCE_PATHS: Array[String] = [
	"res://commons/artifacts/museum/museum_wall_piece.gd",
	"res://commons/artifacts/museum/museum_wall_piece.tscn",
	"res://commons/artifacts/museum/museum_wall_piece_ideal_context.gd",
	"res://commons/artifacts/museum/museum_wall_piece_ideal_context.tscn",
	"res://commons/artifacts/museum/museum_wall_architectural_spans.gd",
	"res://commons/artifacts/museum/museum_wall_opening_spans.gd",
	"res://commons/artifacts/museum/museum_wall_run.gd",
	"res://commons/artifacts/museum/museum_wall_run.tscn",
	"res://commons/artifacts/museum/museum_wall_kit_atlas.gd",
	"res://commons/artifacts/museum/museum_wall_kit_atlas.tscn",
	"res://commons/artifacts/museum/museum_wall_aaa_showcase.gd",
	"res://commons/artifacts/museum/museum_wall_aaa_showcase.tscn",
	"res://commons/testing/capture_museum_wall_c27.gd"
]

const VIEW_IDS: Array[String] = ["hero", "grazing_detail", "worst_seam"]

var _frames: Array[Dictionary] = []
var _errors: Array[String] = []
var _source_hashes: Dictionary = {}
var _renderer := ""
var _environment_config := {
	"ecosystem_bridges":"disabled_by_user_arg",
	"background":"color",
	"background_color":"#343b49",
	"background_energy":0.5,
	"ambient_color":"#d1d6e0",
	"ambient_energy":0.65,
	"reflected_light":"background",
	"tonemap":"aces",
	"exposure_multiplier":0.95,
	"glow":true,
	"msaa":"4x",
	"taa":true
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_renderer = RenderingServer.get_current_rendering_method()
	if "--no-bridges" not in OS.get_cmdline_user_args() and "--no-bridges" not in OS.get_cmdline_args():
		_fail("C27 requires --no-bridges so NatureRenderer cannot mutate the matched environment")
		_finish()
		return
	if _renderer != "gl_compatibility" and _renderer != "mobile" and _renderer != "forward_plus":
		_fail("unsupported rendering method: %s" % _renderer)
	if _renderer == "gl_compatibility":
		_fail("C27 refuses Compatibility/OpenGL evidence; run with Mobile or Forward+")
		_finish()
		return
	_hash_sources()
	var absolute_out := ProjectSettings.globalize_path(OUT_DIR)
	var err := DirAccess.make_dir_recursive_absolute(absolute_out)
	if err != OK:
		_fail("cannot create C27 output directory: %s" % error_string(err))
		_finish()
		return

	var viewport := _make_viewport()
	root.add_child(viewport)
	await process_frame
	for entity in ENTITIES:
		await _capture_entity(viewport, entity)
	viewport.queue_free()
	await process_frame
	_finish()


func _make_viewport() -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = "MuseumWallC27"
	viewport.size = Vector2i(WIDTH, HEIGHT)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.use_taa = true
	viewport.use_debanding = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	# Use explicit linear values rather than named-string parsing: invalid HTML-like
	# strings silently fall back to the project clear colour and poison the entire
	# matched corpus with a green cast.
	environment.background_color = Color(0.034, 0.043, 0.061, 1.0)
	environment.background_energy_multiplier = 0.5
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.82, 0.84, 0.88, 1.0)
	environment.ambient_light_energy = 0.65
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	if _renderer == "forward_plus":
		environment.ssao_enabled = true
		environment.ssao_radius = 0.75
		environment.ssao_intensity = 1.35
		environment.ssil_enabled = true
		environment.ssil_radius = 2.0
		environment.ssil_intensity = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.name = "C27_WorldEnvironment"
	world_environment.environment = environment
	viewport.add_child(world_environment)

	var camera := Camera3D.new()
	camera.name = "C27_Camera"
	camera.current = true
	camera.near = 0.05
	camera.far = 180.0
	var attrs := CameraAttributesPractical.new()
	attrs.auto_exposure_enabled = false
	attrs.exposure_multiplier = 0.95
	camera.attributes = attrs
	viewport.add_child(camera)

	var key := DirectionalLight3D.new()
	key.name = "C27_ArchitecturalKey"
	key.light_color = Color(1.0, 0.88, 0.74, 1.0)
	key.light_energy = 1.65
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 50.0
	viewport.add_child(key)
	key.rotation_degrees = Vector3(-37.0, -28.0, 0.0)

	var fill := DirectionalLight3D.new()
	fill.name = "C27_CoolFill"
	fill.light_color = Color(0.64, 0.75, 0.92, 1.0)
	fill.light_energy = 0.55
	fill.shadow_enabled = false
	viewport.add_child(fill)
	fill.rotation_degrees = Vector3(-18.0, 142.0, 0.0)
	return viewport


func _capture_entity(viewport: SubViewport, entity: Dictionary) -> void:
	var scene_path := str(entity.scene)
	if not ResourceLoader.exists(scene_path):
		_fail("missing scene for %s: %s" % [entity.id, scene_path])
		return
	var packed := load(scene_path) as PackedScene
	if packed == null:
		_fail("failed to load scene for %s" % entity.id)
		return
	var subject := packed.instantiate()
	subject.name = "C27_Subject_%s" % entity.id
	var params: Dictionary = entity.params
	for key in params:
		if _has_property(subject, str(key)):
			subject.set(key, params[key])
		else:
			_fail("%s scene does not expose %s" % [entity.id, key])
	if _has_property(subject, "detail_seed"):
		subject.set("detail_seed", int(entity.seed))
	if _has_property(subject, "lod_level"):
		subject.set("lod_level", int(entity.lod))
	viewport.add_child(subject)
	_suppress_embedded_cameras(subject)
	await create_timer(0.55).timeout
	var box := _subtree_aabb(subject)
	if box.size.length() < 0.01:
		_fail("%s has no measurable render geometry" % entity.id)
		subject.queue_free()
		await process_frame
		return

	for view_id in VIEW_IDS:
		await _capture_view(viewport, subject, box, entity, view_id)
	subject.queue_free()
	await process_frame
	await process_frame


func _capture_view(viewport: SubViewport, subject: Node, box: AABB, entity: Dictionary, view_id: String) -> void:
	var camera := viewport.get_node("C27_Camera") as Camera3D
	var setup := _view_setup(box, entity, view_id)
	camera.fov = float(setup.fov)
	camera.global_position = setup.position
	camera.look_at(setup.target, Vector3.UP)
	for _i in range(12):
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("%s/%s produced an empty image" % [entity.id, view_id])
		return
	if image.get_width() != WIDTH or image.get_height() != HEIGHT:
		_fail("%s/%s wrong dimensions %dx%d" % [entity.id, view_id, image.get_width(), image.get_height()])
		return
	var file_path := "%s/%s_%s.png" % [OUT_DIR, entity.id, view_id]
	var save_error := image.save_png(file_path)
	if save_error != OK:
		_fail("%s/%s save failed: %s" % [entity.id, view_id, error_string(save_error)])
		return
	var config := {
		"entity":entity.id,"scene":entity.scene,"params":entity.params,
		"seed":entity.seed,"lod":entity.lod,"view":view_id,
		"resolution":[WIDTH,HEIGHT],"camera":_camera_manifest(camera),
		"environment":_environment_config,"animation_time_s":0.0
	}
	var config_json := JSON.stringify(config)
	var source_json := JSON.stringify(_source_hashes)
	var environment_json := JSON.stringify(_environment_config)
	var frame := {
		"id":"%s_%s" % [entity.id, view_id],
		"entity":entity.id,"view":view_id,"path":file_path,
		"image_sha256":FileAccess.get_sha256(file_path),
		"source_sha256":_source_hashes,"source_json":source_json,
		"source_set_sha256":_sha256_text(source_json),
		"config":config,"config_json":config_json,"config_sha256":_sha256_text(config_json),
		"scene":entity.scene,"scene_sha256":FileAccess.get_sha256(str(entity.scene)),
		"params":entity.params,"seed":entity.seed,"lod":entity.lod,
		"engine":Engine.get_version_info(),
		"renderer":_renderer,
		"adapter":RenderingServer.get_video_adapter_name(),
		"driver_info":OS.get_video_adapter_driver_info(),
		"resolution":[WIDTH,HEIGHT],"aspect":"16:9","native_pixels":true,
		"camera":_camera_manifest(camera),
		"environment":_environment_config,"environment_json":environment_json,
		"environment_sha256":_sha256_text(environment_json),
		"animation_time_s":0.0,
		"color_transform":"Godot ACES to sRGB PNG",
		"captured_utc":Time.get_datetime_string_from_system(true)
	}
	_frames.append(frame)
	print("C27_CAPTURE ", frame.id, " ", frame.image_sha256)


func _view_setup(box: AABB, entity: Dictionary, view_id: String) -> Dictionary:
	var center := box.get_center()
	var id := str(entity.id)
	var family_context := id != "atlas" and id != "full_build"
	if view_id == "grazing_detail" and family_context:
		var owned_width := float(entity.params.get("width_cells", maxi(1, int(round(box.size.x - 2.0)))))
		var target := Vector3(0.0, minf(2.25, box.end.y * 0.56), 0.02)
		var side := -1.0 if id in ["feature", "window", "service", "endcap"] else 1.0
		return {"fov":39.0,"target":target,"position":target + Vector3(side * (owned_width * 0.68 + 0.75), 0.16, 1.28)}
	if view_id == "worst_seam" and family_context:
		var width_cells := float(entity.params.get("width_cells", 2))
		var seam_x := width_cells * 0.5
		if id == "endcap":
			seam_x = -width_cells * 0.5
		var target := Vector3(seam_x, minf(2.05, box.end.y * 0.52), 0.02)
		return {"fov":43.0,"target":target,"position":target + Vector3(0.72 if seam_x >= 0.0 else -0.72, 0.12, 1.62)}
	var yaw := 0.20
	var pitch := 0.055
	if view_id == "grazing_detail":
		yaw = 1.08
		pitch = 0.02
	elif view_id == "worst_seam":
		yaw = -0.55
		pitch = 0.08
	var fov := 50.0 if view_id == "hero" else 42.0
	var target := center + Vector3(0.0, box.size.y * 0.02, 0.0)
	var distance := _fit_distance(box.size, fov, yaw, pitch, 1.13 if view_id == "hero" else 0.90)
	var direction := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	return {"fov":fov,"target":target,"position":target + direction * distance}


func _fit_distance(size: Vector3, fov: float, yaw: float, pitch: float, margin: float) -> float:
	var vfov := deg_to_rad(fov)
	var hfov := 2.0 * atan(tan(vfov * 0.5) * (float(WIDTH) / float(HEIGHT)))
	var projected_width := absf(cos(yaw)) * size.x + absf(sin(yaw)) * size.z
	var projected_height := size.y + absf(sin(pitch)) * size.z
	var by_width := projected_width * 0.5 / tan(hfov * 0.5)
	var by_height := projected_height * 0.5 / tan(vfov * 0.5)
	return maxf(by_width, by_height) * margin


func _camera_manifest(camera: Camera3D) -> Dictionary:
	var transform := camera.global_transform
	return {
		"position":_vec3(transform.origin),
		"basis_x":_vec3(transform.basis.x),"basis_y":_vec3(transform.basis.y),"basis_z":_vec3(transform.basis.z),
		"fov_deg":camera.fov,"near_m":camera.near,"far_m":camera.far,
		"projection":"perspective","keep_aspect":"height",
		"exposure_multiplier":0.95,"auto_exposure":false
	}


func _subtree_aabb(root_node: Node) -> AABB:
	var merged := AABB()
	var have := false
	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null or not mesh_instance.visible:
			continue
		var local_box := mesh_instance.get_aabb()
		var world_box := _transform_aabb(mesh_instance.global_transform, local_box)
		merged = world_box if not have else merged.merge(world_box)
		have = true
	return merged if have else AABB()


func _transform_aabb(transform: Transform3D, box: AABB) -> AABB:
	var result := AABB(transform * box.position, Vector3.ZERO)
	for x in [0.0, box.size.x]:
		for y in [0.0, box.size.y]:
			for z in [0.0, box.size.z]:
				result = result.expand(transform * (box.position + Vector3(x, y, z)))
	return result


func _suppress_embedded_cameras(node: Node) -> void:
	if node is Camera3D:
		(node as Camera3D).current = false
	for child in node.get_children():
		_suppress_embedded_cameras(child)


func _has_property(object: Object, property_name: String) -> bool:
	for property in object.get_property_list():
		if str(property.name) == property_name:
			return true
	return false


func _hash_sources() -> void:
	for path in SOURCE_PATHS:
		_source_hashes[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
		if _source_hashes[path] == "MISSING":
			_fail("missing declared source: %s" % path)


func _sha256_json(value: Variant) -> String:
	return _sha256_text(JSON.stringify(value))


func _sha256_text(value: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_utf8_buffer())
	return context.finish().hex_encode()


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _fail(message: String) -> void:
	_errors.append(message)
	push_error("C27: " + message)


func _finish() -> void:
	var entity_counts := {}
	for frame in _frames:
		entity_counts[frame.entity] = int(entity_counts.get(frame.entity, 0)) + 1
	var complete := _errors.is_empty() and _frames.size() == 27
	for entity in ENTITIES:
		if int(entity_counts.get(entity.id, 0)) != 3:
			complete = false
	var manifest := {
		"schema":"ada-museum-wall-c27-v1","round":5,
		"complete":complete,"missing_is_failure":true,
		"renderer_required":["mobile","forward_plus"],"renderer_actual":_renderer,
		"resolution":[WIDTH,HEIGHT],"view_ids":VIEW_IDS,
		"entity_counts":entity_counts,"frame_count":_frames.size(),
		"source_sha256":_source_hashes,"source_json":JSON.stringify(_source_hashes),
		"source_set_sha256":_sha256_json(_source_hashes),
		"environment":_environment_config,"environment_json":JSON.stringify(_environment_config),
		"environment_sha256":_sha256_json(_environment_config),
		"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),
		"driver_info":OS.get_video_adapter_driver_info(),"errors":_errors,"frames":_frames
	}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		push_error("C27: cannot write manifest")
		quit(1)
		return
	file.store_string(JSON.stringify(manifest))
	file.close()
	var done := FileAccess.open(OUT_DIR + "/_done.txt", FileAccess.WRITE)
	if done != null:
		done.store_string("C27 %d/27 complete=%s renderer=%s" % [_frames.size(), complete, _renderer])
		done.close()
	print("C27_RESULT complete=", complete, " frames=", _frames.size(), " errors=", _errors.size())
	quit(0 if complete else 1)
