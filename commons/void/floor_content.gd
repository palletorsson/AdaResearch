extends Node3D
## The Void placement layer. Authored content is separate from its permanent frame.
const ROOMS := "res://commons/void/rooms.json"
const Source := preload("room_source.gd")
const SUPPLY_Y := 4.8
const CATALOG := "res://commons/void/catalog.json"
const OriginScene := preload("res://commons/primitives/origin/origin.tscn")
const SetDressing := preload("res://commons/void/set_dressing.gd")
const CarriedPointLight := preload("res://commons/void/carried_point_light.gd")
const RodLight := preload("res://commons/void/point_rod_light.gd")
const Identity := preload("res://commons/grid/artifact_identity.gd")
const Reactions := preload("res://commons/interactables/artifact_reactions/router.gd")
const LinesTrace := preload("lines_trace.gd")
const Construction := preload("construction_grid.gd")
const AbstractFinish := preload("abstract_finish.gd")
const LessonScore := preload("lesson_score.gd")
var building: Node3D
var data: Dictionary
var catalog: Dictionary
var exhibits: Dictionary = {}
var cells: Dictionary = {}
var props: Dictionary = {}
var impact_count := 0
## Editor/export views build everything; the playable tower opts into lazy floors.
var lazy := false
var trial_id := ""
var roots: Dictionary = {}
var pending: Array[Dictionary] = []
var last_build_ms := 0.0
var max_build_ms := 0.0
var build_indices: Array = []
var warming: Dictionary = {}
var warm_resources: Dictionary = {}
signal floor_changed(index: int)
signal panel_activated(world_position: Vector3)

func _ready() -> void:
	building = get_parent()
	data = Source.read_rooms(trial_id)
	catalog = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	add_to_group("biome_grid") # Existing catalyst projectiles call react_at_world.
	if not lazy:
		for index in range(data.floors.size()): load_floor(index)

## Prepare the floor shell immediately; optionally spread artifact factories over frames.
func load_floor(index: int, immediate := true) -> Node3D:
	# A retry can overtake I/O. Join before loading the shared script tree.
	if immediate:
		for path in warming:
			var resource := ResourceLoader.load_threaded_get(path)
			if resource!=null: warm_resources[path]=resource
		warming.clear()
	if not roots.has(index): _build_content(index, data.floors[index], not immediate)
	if immediate:
		var jobs := pending.filter(func(job): return int(job.index)==index)
		pending=pending.filter(func(job): return int(job.index)!=index)
		for job in jobs: _build_artifact(roots[index],index,job.item)
		floor_changed.emit(index)
	return roots[index]

## Restart one lesson without clearing the earlier floors or their carried objects.
func reset_floor(index: int) -> void:
	pending = pending.filter(func(job): return int(job.index) != index)
	if roots.has(index):
		roots[index].free()
		roots.erase(index)
	for collection in [exhibits, props, cells]:
		for key in collection.keys():
			if str(key).begins_with("%d/" % index) or str(key).begins_with("%d:" % index):
				collection.erase(key)

func _process(_delta: float) -> void:
	if pending.is_empty(): return
	var selected := -1
	for i in range(pending.size()):
		if build_indices.is_empty() or pending[i].index in build_indices:
			var definition := _definition(str(pending[i].item.artifact))
			# Older composers can synchronously load registry children in _ready.
			# Keep these imports on one thread, still one factory per queued frame.
			if definition.get("museum_import",false):
				selected=i;break
			var path := str(definition.get("scene",""))
			if not path.is_empty() and not warming.has(path) and not warm_resources.has(path):
				if ResourceLoader.load_threaded_request(path,"PackedScene")==OK: warming[path]=true
			if warming.has(path):
				var status := ResourceLoader.load_threaded_get_status(path)
				if status==ResourceLoader.THREAD_LOAD_IN_PROGRESS: return
				if status==ResourceLoader.THREAD_LOAD_LOADED: warm_resources[path]=ResourceLoader.load_threaded_get(path)
				warming.erase(path)
			selected=i;break
	if selected<0: return
	var job: Dictionary = pending.pop_at(selected)
	var start := Time.get_ticks_usec()
	_build_artifact(roots[job.index],job.index,job.item)
	last_build_ms = (Time.get_ticks_usec()-start)/1000.0
	max_build_ms = maxf(max_build_ms,last_build_ms)
	floor_changed.emit(job.index)

func _queue_artifact(index: int, item: Dictionary) -> void:
	pending.append({"index":index,"item":item})

func _build_content(index: int, record: Dictionary, defer_artifacts := false) -> void:
	var content_trial := Source.floor_trial(building.spec, index, trial_id)
	var contexts: Array = [content_trial]
	for item in record.get("copies", []):
		contexts.append(Source.artifact_trial(building.spec, index, item, trial_id))
	var floor_root := Node3D.new()
	if contexts.any(func(context):return context in ["proceduralgeneration_02", "isosurfaces_02", "isosurfaces_03"]):
		floor_root.set_script(preload("res://commons/void/trials/proceduralgeneration_02/museum_context.gd"))
	floor_root.name = "Content%d" % index
	floor_root.position.y = float(building.spec.levels[index])
	floor_root.set_meta("map", record.map)
	floor_root.set_meta("em_map", record.map) # Scope the sampling monitor to this hall.
	floor_root.set_meta("void_content_floor", index)
	add_child(floor_root)
	roots[index] = floor_root
	if trial_id.is_empty() and (contexts.any(func(context):return not str(context).is_empty()) or str(record.map).begins_with("Trans_")):
		var score := LessonScore.new()
		score.name = "LessonScore"
		floor_root.add_child(score)
	if not content_trial.is_empty() or str(record.map).begins_with("Trans_"):
		for waypoint in record.get("route", []):
			var caption := _text(floor_root, waypoint.label, Vector3(waypoint.position[0], float(waypoint.get("height",0))+.025, waypoint.position[1]), .002)
			caption.rotation_degrees.x = -90
			caption.modulate = Color("efc5dd")
	var abstract: bool = building.abstract_floor(index)
	if not abstract: _build_feed(floor_root,index != 0)
	for wall in record.walls:
		var centre_y := float(wall.get("base", 0.0)) + float(wall.height) / 2.0
		var a := Vector3(float(wall.from[0]), centre_y, float(wall.from[1]))
		var b := Vector3(float(wall.to[0]), centre_y, float(wall.to[1]))
		var size := Vector3(absf(a.x - b.x) + 0.18, float(wall.height), absf(a.z - b.z) + 0.18)
		var built_wall: Node3D = building.box(floor_root, "Wall_" + str(wall.id), (a + b) / 2.0, size, building.concrete)
		if abstract: AbstractFinish.blocks(built_wall, Color("dce0e2"))
		if wall.get("finish", "concrete") == "unfinished":
			_unfinished_wall(built_wall, size)
	for item in record.get("props", []):
		props["%d/%s" % [index, item.id]] = SetDressing.build(building, floor_root, item, catalog.props[item.kind])
		if str(record.map).begins_with("CA_") and item.kind=="work_light" and str(item.id).begins_with("ca-stage-light-"):
			var ca_lamp: Node3D = props["%d/%s"%[index,item.id]].get_node("Prefab")
			ca_lamp.beam_energy = 3.0;ca_lamp.get_node("WorkBeam").shadow_enabled = false
		if record.map in ["Point_One", "Point_Coordinates", "Point_Lines", "Point_Trace", "Point_Triangle_Context"] and item.kind == "work_light":
			# Work lamps provide orientation; interactive objects and retained
			# traces supply close light. Editor copies retain this floor profile.
			props["%d/%s" % [index, item.id]].get_node("Prefab").beam_energy = 1.2
	if not record.get("construction", []).is_empty():
		var construction := Construction.new()
		construction.name = "Construction"
		construction.items = record.construction
		floor_root.add_child(construction)
	for item in record.artifacts:
		if defer_artifacts: _queue_artifact(index,item)
		else: _build_artifact(floor_root, index, item)
	# Pasted instances share the original factory and overhead supply stations.
	for item in record.get("copies", []):
		if defer_artifacts: _queue_artifact(index,item)
		else: _build_artifact(floor_root, index, item)
	for pair in record.impact_cells:
		var x := int(pair[0])
		var z := int(pair[1])
		var tile: Node3D = building.box(floor_root, "CatalystCell_%d_%d" % [x, z], Vector3(x + 0.5, 0.015, z + 0.5), Vector3(0.96, 0.03, 0.96), building.steel)
		(tile as StaticBody3D).collision_layer = 1 | (1 << 23)
		cells[_key(index, x, z)] = {"node": tile, "height": 0.03, "floor": index}
	if record.origin:
		var origin := OriginScene.instantiate()
		origin.name = "WorldZero"
		origin.beam_height = 1.0
		origin.beam_label = "Point zero / (0, 0, 0)"
		# Keep the existing origin exactly at world zero. Raise only its wire
		# cage above the slab, rather than moving zero to a decorative plinth.
		origin.get_node("CubeLines").position.y = 0.5
		origin.get_node("CubeCollider").position = Vector3(0, 0.5, 0)
		floor_root.add_child(origin)
		if record.get("props",[]).any(func(item): return item.kind == "arrival_crate"):
			# The packing must occlude the roof's annotations until opened.
			for label in origin.find_children("*","Label3D",true,false):
				label.no_depth_test = false
		_text(floor_root, "You arrive late.\nThe room is already running.", Vector3(-5, 0.4, -6.29), 0.0014)
		_text(floor_root, "THE ENDLESS MUSEUM\nalways another room", Vector3(-5, 2.45, -6.29), 0.0022)
	if record.map == "Point_One":
		_text(floor_root, "THE ENDLESS MUSEUM\nalways another room", Vector3(0, 2.9, -6.89), 0.0022)
		_text(floor_root, "POINT ONE\nA body in the light", Vector3(-3.0, 2.1, -6.89), 0.0020)

	if record.map == "Point_Coordinates":
		var title := _text(floor_root, "THE ENDLESS MUSEUM\nalways another room", Vector3(0, 2.95, 6.69), 0.0022)
		title.rotation_degrees.y = 180
		var instruction := _text(floor_root, "POINT COORDINATES\nHold grip to carry the point. Release to leave it.\nOne point. Two frames of reference.", Vector3(0, 0.025, -6.2), 0.0018)
		instruction.rotation_degrees = Vector3(-90, 180, 0)

func _build_feed(host: Node3D, show_cables := true) -> void:
	# Keep service infrastructure overhead so lines on the slab belong to artifacts.
	var points: Array[Vector3] = []
	for station in ["NW", "NE", "SE", "SW"]:
		var pair: Array = catalog.stations[station]
		points.append(Vector3(float(pair[0]), SUPPLY_Y, float(pair[1])))
	for i in range(4):
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % 4]
		building.box(host, "CeilingConduit", (a+b)/2.0, Vector3(absf(a.x-b.x)+0.14,0.08,absf(a.z-b.z)+0.14),building.steel,false)
		if show_cables: building.pipe(host, "SupplyCable", a-Vector3.UP*0.055,b-Vector3.UP*0.055,0.025,building.pink)
	var riser := Vector3(float(building.spec.service_x[0])+0.42,SUPPLY_Y,float(building.spec.service_z))
	var elbow := Vector3(points[0].x,SUPPLY_Y,riser.z)
	if show_cables:
		building.pipe(host,"SupplyFromRiser",riser,elbow,0.025,building.pink)
		building.pipe(host,"SupplyToRing",elbow,points[0],0.025,building.pink)
	for station in catalog.stations:
		var pair: Array = catalog.stations[station]
		var at := Vector3(float(pair[0]),SUPPLY_Y,float(pair[1]))
		building.box(host,"Socket_"+station,at,Vector3(0.34,0.12,0.34),building.steel,false)
		# Roof sockets sit on service masts; lower floors hang below the slab.
		if is_zero_approx(host.position.y):
			building.pipe(host,"RoofServiceMast",Vector3(at.x,0,at.z),at,0.045,building.steel)
		else:
			building.pipe(host,"ConduitHanger",at,at+Vector3.UP*0.8,0.015,building.steel)

func _unfinished_wall(body: Node3D, size: Vector3) -> void:
	# Plaster stops short of the full stud frame. The actual lower panel blocks.
	var panel_height := maxf(0.5,size.y-0.7)
	var panel: MeshInstance3D = body.get_child(0)
	panel.mesh.size.y=panel_height; panel.position.y=-(size.y-panel_height)/2
	var collision: CollisionShape3D = body.get_child(1)
	collision.shape.size.y=panel_height;collision.position.y=panel.position.y
	var along_x := size.x>size.z
	var length: float = size.x if along_x else size.z
	var count := maxi(1,ceili(length/0.6))
	for i in range(count+1):
		var at := Vector3.ZERO
		if along_x: at.x=-length/2+length*i/count
		else: at.z=-length/2+length*i/count
		building.box(body,"ExposedStud",at,Vector3(0.045,size.y,0.045),building.steel)

func _build_artifact(host: Node3D, index: int, item: Dictionary) -> void:
	var artifact_trial := Source.artifact_trial(building.spec, index, item, trial_id)
	if OS.get_environment("VOID_TRACE_ARTIFACTS") == "1": print("VOID_LOAD_BEGIN ", artifact_trial, " / ", item.id)
	var definition := _definition(str(item.artifact))
	if definition.is_empty():
		push_error("Void artifact is not registered: " + str(item.artifact))
		return
	var packed := warm_resources.get(str(definition.scene)) as PackedScene
	if packed==null: packed=load(str(definition.scene)) as PackedScene
	if packed == null:
		push_error("Void artifact could not load: " + str(item.artifact))
		return
	var pair: Array = catalog.stations[item.station]
	var at: Array = item.get("position", pair)
	var mount := Node3D.new()
	mount.name = str(item.id)
	mount.position = Vector3(float(at[0]), float(item.height), float(at[1]))
	mount.rotation_degrees.y = float(item.facing)
	mount.set_meta("supply", "ceiling_bus")
	mount.set_meta("station", item.station)
	# A preview floor is disabled, but Jolt soft bodies need a live space while
	# their initial transforms are submitted. Residency pauses them afterwards.
	mount.process_mode = Node.PROCESS_MODE_ALWAYS
	host.add_child(mount)
	var artifact: Node3D
	if item.artifact == "gridcolorizer" and item.get("config", {}).get("lesson", "") == "addresses":
		artifact = preload("res://commons/void/colour_address_floor.gd").new()
	else:
		artifact = packed.instantiate() as Node3D
	artifact.name = "Artifact"
	if item.artifact == "entropy_door_dynamics" and bool(item.get("config",{}).get("void_door_frames",false)):
		artifact.set_script(preload("res://commons/void/entropy_door_walkthrough.gd"))
	if artifact_trial == "color_flashlight" and item.artifact == "flashlight_demo":
		artifact.set_script(preload("res://commons/void/trials/color_flashlight/close_station.gd"))
	if artifact_trial == "wavefunctions_04" and item.artifact == "math_objects":
		artifact.set_script(preload("res://commons/void/math_gallery_local.gd"))
	if artifact_trial == "wavefunctions_04" and item.artifact == "resonating_metallophone":
		artifact.set_script(preload("res://commons/void/metallophone_local.gd"))
	if artifact_trial in ["wavefunctions_03", "wavefunctions_04", "wavefunctions_05"] and item.artifact == "GlassRack" and item.get("config", {}).has("config"):
		# Old map tokens call this key "config"; the source loader expects
		# config_file. Select the authored apparatus before the original _ready.
		artifact.config_file = str(item.config.config)
	if artifact_trial in ["wavefunctions_04", "wavefunctions_05"] and item.artifact == "air_music_display_case":
		artifact.set_script(preload("res://commons/void/air_music_case_local.gd"))
	if artifact_trial in ["randomness_03", "randomness_05"] and item.artifact == "random_removal_arena":
		artifact.set_script(preload("res://commons/void/removal_arena_local.gd"))
	if artifact_trial == "randomness_04" and item.artifact in ["random_object_spawner", "Random_Rotate_Random_XYZ", "galton_board", "dice_throw", "random_walk_leash"]:
		var random_settings: Dictionary = {}
		for property in artifact.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
				random_settings[property.name] = artifact.get(property.name)
		var random_adapters: Dictionary = {
			"random_object_spawner": "random_object_spawner_local",
			"Random_Rotate_Random_XYZ": "rotate_no_grid_preview",
			"galton_board": "galton_board_local",
			"dice_throw": "dice_throw_local",
			"random_walk_leash": "random_walk_leash_local",
		}
		artifact.set_script(load("res://commons/void/trials/randomness_04/" + str(random_adapters[item.artifact]) + ".gd"))
		for key in random_settings: artifact.set(key, random_settings[key])
	if artifact_trial == "randomness_05" and item.artifact in ["cube_projectile_spawner", "env_one", "sculpt_one"]:
		# Keep scene-authored settings while adapting only the Void host seams:
		# falling-field headroom and standalone suns recreated by seed changes.
		var transfer_settings: Dictionary = {}
		for property in artifact.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
				transfer_settings[property.name] = artifact.get(property.name)
		var transfer_adapters: Dictionary = {
			"cube_projectile_spawner": "cube_field_local",
			"env_one": "env_one_local",
			"sculpt_one": "sculpt_one_local",
		}
		artifact.set_script(load("res://commons/void/trials/randomness_05/" + str(transfer_adapters[item.artifact]) + ".gd"))
		for key in transfer_settings: artifact.set(key, transfer_settings[key])
	if artifact_trial == "randomness_03" and item.artifact == "nature_system_demo":
		# Retain scene-authored grid/LOD settings across the script swap. The
		# adapter maps source local spawn positions into this editable mount.
		var nature_settings: Dictionary = {}
		for property in artifact.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
				nature_settings[property.name] = artifact.get(property.name)
		artifact.set_script(preload("res://commons/void/trials/randomness_03/nature_demo_local.gd"))
		for key in nature_settings: artifact.set(key, nature_settings[key])
	if artifact_trial == "randomness_03" and item.artifact == "remove_random" and not item.get("config", {}).has("local_grid"):
		artifact.set_script(preload("res://commons/void/trials/randomness_03/remover_unbound_preview.gd"))
	if artifact_trial == "randomness_03" and item.artifact == "pickup_cube_placer":
		artifact.set_script(preload("res://commons/void/trials/randomness_03/placer_no_grid_preview.gd"))
	if artifact_trial == "wavefunctions_05" and item.artifact == "TrigWalkingPath":
		# The standalone demonstration's camera and 100 m reference floor are
		# hosting scenery; retain both original moving step lanes and platforms.
		for host_name in ["Camera3D", "FloorReference"]:
			var host_node := artifact.get_node_or_null(host_name)
			if host_node != null:
				artifact.remove_child(host_node); host_node.free()
	if artifact_trial == "wavefunctions_03" and item.artifact == "DualBallFMController":
		artifact.set_script(preload("res://commons/void/fm_controller_local.gd"))
		for mapper_name in ["Ball1_Carrier", "Ball2_Modulator"]:
			var mapper: Node = artifact.get_node(mapper_name)
			var mapper_settings: Dictionary = {}
			for property in mapper.get_property_list():
				if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
					mapper_settings[property.name] = mapper.get(property.name)
			mapper.set_script(preload("res://commons/void/mapper_3d_physics.gd"))
			for key in mapper_settings: mapper.set(key, mapper_settings[key])
	if (artifact_trial == "wavefunctions_02" and item.artifact in ["PendulumWave","OscillationCurve","WavePaintings","BigPipeSystem"]) or (artifact_trial in ["wavefunctions_03","wavefunctions_04"] and item.artifact == "BigPipeSystem"):
		var settings:Dictionary={}
		for property in artifact.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
				settings[property.name]=artifact.get(property.name)
		var adapters:Dictionary={"PendulumWave":"pendulum_wave_local","OscillationCurve":"oscillation_curve_local","WavePaintings":"wave_paintings_local","BigPipeSystem":"pipe_empty_preview"}
		artifact.set_script(load("res://commons/void/"+adapters[item.artifact]+".gd"))
		for key in settings:artifact.set(key,settings[key])
	if item.artifact in ["shelf", "shelf_with_stickers", "grabcolorcollection"]:
		# These original standalone cameras have no script consumers. Remove
		# them before tree entry so Godot cannot auto-select one on residency.
		for view in artifact.find_children("*", "Camera3D", true, false):
			view.get_parent().remove_child(view);view.free()
	if artifact is PatternTilePuzzle:
		# These source aliases share a scene; their museum registry selects
		# simple, mirror, brick or herringbone before the preview is built.
		for key in definition.get("config", {}):
			if key in artifact: artifact.set(key, definition.config[key])
	if item.artifact == "pattern_architecture":
		artifact.set_script(preload("res://commons/void/pattern_architecture_receiver.gd"))
	if item.artifact == "grid_model":
		artifact.set_script(load("res://commons/void/floor_grid_model.gd"))
	if item.artifact == "panel_bridge_loom":
		artifact.set_script(load("res://commons/void/pattern_loom_panels.gd"))
	if item.artifact == "wall_pattern_gallery":
		artifact.set_script(load("res://commons/void/pattern_gallery_local.gd"))
	if item.artifact == "pattern_temple":
		artifact.set_script(load("res://commons/void/pattern_temple_lifecycle.gd"))
	if item.artifact == "pattern_artifact":
		artifact.set_script(load("res://commons/void/pattern_empty_preview.gd"))
	if item.artifact == "SpringSuspension" and str(item.get("config",{}).get("lesson","")) == "museum_spring":
		artifact.set_script(load("res://commons/void/spring_suspension_local.gd"))
	if str(item.artifact).begins_with("force_hall_"):
		var original_hall: int = artifact.hall_number
		var original_map: String = artifact.map_id
		artifact.set_script(load("res://commons/void/force_hall_local.gd"))
		artifact.hall_number = original_hall
		artifact.map_id = original_map
	if item.artifact == "force_capability_lab":
		artifact.set_script(load("res://commons/void/force_court_local.gd"))
	if item.artifact == "force_field_zone":
		artifact.set_script(load("res://commons/void/force_zone_local.gd"))
	if item.artifact == "force_field":
		artifact.set_script(load("res://commons/void/force_hazard_local.gd"))
	if item.artifact == "endless_racer":
		artifact.set_script(load("res://commons/void/endless_racer_local.gd"))
	if item.artifact == "science_screen" and str(data.floors[index].map).begins_with("FormFinding_") and artifact_trial == "formfinding_02":
		artifact.set_script(load("res://commons/void/formfinding_screen_local.gd"))
	if item.artifact in ["force_play_vortex","force_play_liquids","force_play_friction","force_play_springs","force_play_swings","force_play_constraints","force_play_mutual","force_play_magnet","force_play_tower","force_play_gravity","force_play_support","force_play_bowling","force_play_recoil","force_play_flight"]:
		var original_kind: String = artifact.kind
		artifact.set_script(load("res://commons/void/force_play_local.gd"))
		artifact.kind = original_kind
	if item.artifact == "gravity_oval":
		artifact.set_script(load("res://commons/void/gravity_oval_local.gd"))
	if item.artifact == "colortrails":
		artifact.set_script(load("res://commons/void/color_trails_local.gd"))
	if item.artifact == "strobe_lasers":
		var settings: Dictionary = {}
		for property in ["beam_count","beam_length","beam_thickness","spread_angle_deg","rotation_speed","strobe_frequency","pulse_speed","laser_color","rainbow_mode","rainbow_speed"]:
			settings[property] = artifact.get(property)
		artifact.set_script(load("res://commons/void/strobe_laser_local.gd"))
		for property in settings: artifact.set(property,settings[property])
	if item.artifact == "colorballs" and (item.get("config", {}).get("case", "") == "salon" or (artifact_trial == "wavefunctions_02" and not item.get("config", {}).has("case"))):
		var ball_count: int = artifact.ball_count
		var spawn_area: Vector3 = artifact.spawn_area_size
		artifact.set_script(preload("res://commons/void/salon_colorballs.gd"))
		artifact.ball_count = ball_count
		artifact.spawn_area_size = spawn_area
	if item.artifact in ["hand_color_controller", "nail_color_controller"] and item.get("config", {}).get("mount", "") == "salon":
		var surface: int = artifact.target_surface
		artifact.set_script(preload("res://commons/void/salon_color_controller.gd"))
		artifact.target_surface = surface
	var lines_floor: bool = data.floors[index].map == "Point_Lines"
	if artifact_trial == "isosurfaces_03" and item.artifact == "iso_specimen_stage":
		artifact.set_script(preload("res://commons/void/trials/isosurfaces_03/setup_marker.gd"))
	if artifact_trial == "shaders_02" and item.artifact == "shader_state_chamber":
		artifact.set_script(preload("res://commons/void/trials/shaders_02/chamber_mobile.gd"))
	if artifact_trial == "qfeplaboratory_03" and item.artifact == "chaos_particles":
		artifact.set_script(preload("res://commons/void/trials/qfeplaboratory_03/chaos_image_preview.gd"))
	if artifact_trial == "qfeplaboratory_02" and item.artifact == "particle_chaos":
		artifact.set_script(preload("res://commons/void/trials/qfeplaboratory_02/particle_image_preview.gd"))
	if artifact_trial == "machinelearning_02" and item.artifact == "computer_vision_vr":
		var authored: Dictionary = {}
		for property in artifact.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
				authored[property.name] = artifact.get(property.name)
		artifact.set_script(preload("res://commons/void/trials/machinelearning_02/vision_rails_local.gd"))
		for property in authored: artifact.set(property, authored[property])
	if artifact_trial == "softbodies_03" and item.artifact == "reaction_diffusion":
		artifact.set_script(preload("res://commons/void/trials/softbodies_03/reaction_sprite_preview.gd"))
	if artifact_trial == "softbodies_02" and item.artifact == "rounded_softbody_test":
		var specimen := artifact.get_node("RoundedSoftBody")
		var authored: Dictionary = {}
		for property in specimen.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
				authored[property.name] = specimen.get(property.name)
		specimen.set_script(preload("res://commons/void/trials/softbodies_02/rounded_rest_local.gd"))
		for property in authored: specimen.set(property, authored[property])
	if artifact_trial == "lsystems_02" and item.artifact == "grid_substrate_runner":
		artifact.set_script(preload("res://commons/void/trials/lsystems_02/grid_runner_local.gd"))
	if artifact_trial == "fractals_02" and item.artifact == "box_counting_dimension":
		artifact.set_script(preload("res://commons/void/trials/fractals_02/box_counting_local.gd"))
	if artifact_trial == "cellularautomata_03" and item.artifact == "crossway_ca":
		artifact.set_script(preload("res://commons/void/trials/cellularautomata_03/crossway_preview.gd"))
	if artifact_trial == "cellularautomata_03" and item.artifact == "ca_chair_test":
		artifact.get_node("CAGrid").set_script(preload("res://commons/void/trials/cellularautomata_03/chair_grid.gd"))
	if artifact_trial == "cellularautomata_03" and item.artifact == "disease_spread_ca":
		artifact.set_script(preload("res://commons/void/trials/cellularautomata_03/disease_preview.gd"))
	if artifact_trial == "cellularautomata_03" and item.artifact == "volumetric_fog_ca":
		var fog_grid: Vector3i = artifact.grid_size
		var fog_interval: float = artifact.update_interval
		artifact.set_script(preload("res://commons/void/trials/cellularautomata_03/fog_preview.gd"))
		artifact.grid_size = fog_grid
		artifact.update_interval = fog_interval
	if bool(item.get("config",{}).get("ca_live",false)):
		if item.artifact=="disease_spread_ca":artifact.set_script(preload("res://commons/void/ca_sir_live.gd"))
		elif item.artifact=="crack_propagation_ca":artifact.set_script(preload("res://commons/void/ca_crack_live.gd"))
	if item.artifact=="lattice_gas_pump" and bool(item.get("config",{}).get("wind_tunnel_study",false)):
		artifact.set_script(preload("res://commons/artifacts/lattice_gas_pump/wind_tunnel_study.gd"))
	var transformation: bool = str(data.floors[index].map).begins_with("Trans_")
	if data.floors[index].map in ["Point_Lines", "Point_Trace"] and item.artifact == "player_trace":
		# Keep the original recorder, with the same floor-aware adapter as the
		# line assembly. One recorder owns this floor, even when both are placed.
		artifact.set_script(LinesTrace)
		artifact.preferred_recorder = true
		# Grid's walking comparison keeps its original grid, unrounded ghost
		# and colour settings, while tracking the actual body on this floor.
		artifact.preserve_museum_style = not lines_floor
	if (not artifact_trial.is_empty() or lines_floor or transformation) and "health_provider" in artifact:
		artifact.health_provider = get_tree().get_first_node_in_group("void_health")
	if not artifact_trial.is_empty() and "score_provider" in artifact:
		artifact.score_provider = host.get_node_or_null("LessonScore") if trial_id.is_empty() else get_tree().get_first_node_in_group("void_trial_score")
	elif transformation and "score_provider" in artifact:
		artifact.score_provider = host.get_node("LessonScore")
	artifact.scale = Vector3.ONE * float(item.scale)
	var source_config: Dictionary = item.get("config", {}).duplicate(true)
	if definition.has("delegate_to"):
		# Named museum variants are scenes plus their declared presets. Token
		# overrides still win; do not collapse all looms/mills to the host default.
		source_config = definition.get("default_params", {}).duplicate(true)
		source_config.merge(definition.get("delegate_params", {}), true)
		source_config.merge(item.get("config", {}), true)
	var museum_import := bool(definition.get("museum_import", false)) or not artifact_trial.is_empty() or transformation
	if museum_import:
		Identity.stamp(artifact, str(item.artifact), definition)
		artifact.set_meta("void_source", definition.scene)
		artifact.rotation_degrees.y = float(item.get("config", {}).get("museum_yaw", 0))
		for key in source_config:
			artifact.set_meta("config_" + str(key), source_config[key])
	var before_ready := bool(definition.get("configure_before_ready", false))
	if not item.get("interface", {}).is_empty() and "finish" in artifact:
		# Use the existing kit palette before the original builds its controls.
		artifact.finish = "rams"
		if "wear" in artifact: artifact.wear = 0.035
	var runtime_config: Dictionary = source_config
	if artifact_trial in ["cellularautomata_03", "fractals_02", "lsystems_02", "swarmintelligence_02"] and item.artifact in ["catalyst_vent", "catalyst_prompter_box"] and str(source_config.get("sequence", "")) == "auto":
		# The museum scene manager supplies this context. Separate Void trials
		# resolve it locally, without changing global progression or source tokens.
		runtime_config = source_config.duplicate(true)
		runtime_config.sequence = {"fractals_02":"fractals", "lsystems_02":"lsystems", "cellularautomata_03":"cellularautomata", "swarmintelligence_02":"swarmintelligence"}[artifact_trial]
	if artifact_trial in ["randomness_03", "randomness_05"] and item.artifact == "random_removal_arena":
		before_ready = true
	if artifact_trial == "noise_02" and item.artifact in ["perlin_terrain_sculptor", "shader_noise_space", "cellular_womb_space", "cellular_atrium_space"]:
		before_ready = true
	if artifact_trial == "noise_03" and item.artifact in ["simplex_noise", "perlin_noise", "box_shell_space", "box_atrium_space"]:
		before_ready = true
	if artifact_trial == "cellularautomata_03" and item.artifact in ["self_organization_ca", "rd_artifact", "volumetric_fog_ca", "disease_spread_ca"]:
		# Source studies must replace standalone builds before the first frame;
		# the authored fog preview_grid must cap allocation before _ready.
		before_ready = true
	if artifact_trial == "softbodies_02" and item.artifact in ["cloth_straps", "softbody_gallery_part2"]:
		# Match the museum's pre-ready token config. Avoid building/discarding
		# live Jolt cloth or an unwanted gallery part during initial loading.
		before_ready = true
	if before_ready and artifact.has_method("apply_grid_config"):
		artifact.scale = Vector3.ONE
		artifact.call("apply_grid_config", runtime_config)
	if item.artifact == "standalone_disco" and artifact.has_node("DiscoFloor"):
		# The original wrapper is unscripted. Configure its grid before _ready
		# so it builds source spacing/collision once, without a deferred rebuild.
		artifact.get_node("DiscoFloor").call("apply_grid_config", item.get("config", {}))
	if item.artifact == "force_cube" and source_config.get("lesson","") == "force_as_place":
		# The museum grounds centred pickables. Keep the source token height,
		# with the 40 cm probe resting above the slab instead of intersecting it.
		artifact.position.y = 0.22 * float(item.scale)
	if artifact_trial == "noise_03" and item.artifact == "perlin_noise_terrain":
		# The original pair study finds its terrain support by scene-root name.
		# Keep the required Artifact root name and supply an equivalent local anchor.
		var terrain_anchor := Node3D.new()
		terrain_anchor.name = "PerlinNoiseTerrain"
		artifact.add_child(terrain_anchor)
	mount.add_child(artifact)
	if artifact_trial == "cellularautomata_03" and item.artifact == "ca_chair_test":
		var chair_controls := Node3D.new()
		chair_controls.set_script(preload("res://commons/void/trials/cellularautomata_03/chair_controls.gd"))
		chair_controls.name = "VoidChairControls"
		artifact.add_child(chair_controls)
	if artifact_trial == "randomness_04" and item.artifact in ["hardware_entropy_decay", "random_decay_multimesh", "distribution_sampler", "galton_board", "pixel_cloud"]:
		# Locomotion keys must not trigger source-demo keyboard fallbacks.
		# Original pointer panels remain active.
		artifact.set_process_input(false)
	if (item.artifact == "viscosity_layers" or (data.floors[index].map == "VFM_08_Arena" and item.artifact in ["sentry_turret","queer_cylinder_target","newton_cradle"])) and float(item.get("height",0)) > 0:
		# Reattach the original hall's pedestal to this independently editable exhibit.
		preload("res://commons/artifacts/rotation_studies/parts.gd").box(artifact,"OriginalHallPedestal",Vector3(1.9,0.82,1.4),Vector3(0,0.41-float(item.height),0),Color("e9e4d8"))
	if artifact is PatternTilePuzzle:
		preload("res://commons/void/pattern_tile_desktop_hook.gd").attach(artifact)
	if artifact is VRTileEditor and artifact._puzzle is PatternTilePuzzle:
		preload("res://commons/void/pattern_tile_desktop_hook.gd").attach(artifact._puzzle)
	if item.artifact == "ball_painting_demo" and str(item.get("config", {}).get("tools", "")) == "spray":
		# The source cans use bitmask 3 (world layers 1/2). Both Void hands
		# select pickables on layer 3 (bit 4). Keep the original tool and dock;
		# add that layer and retain it when XRTools restores a dropped can.
		for can in artifact.get_node("PaintBalls").get_children():
			if can is RigidBody3D and can.has_method("on_desktop_grab"):
				can.set_collision_layer_value(3, true)
				can.original_collision_layer = can.collision_layer
	if item.artifact == "standalone_disco":
		# Same readable receiver finish as the existing Void tiling trial:
		# constant white emission would wash the black/white values to pale grey.
		var receiver: Node3D = artifact.get_node("DiscoFloor")
		var finish: StandardMaterial3D = receiver.multimesh_instance.material_override
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.emission_enabled = false
	for soft in artifact.find_children("*", "SoftBody3D", true, false):
		soft.force_update_transform()
	if artifact is SoftBody3D: artifact.force_update_transform()
	mount.process_mode = Node.PROCESS_MODE_INHERIT
	# A scene may rename its own root in _ready (geometry_noise does); the mount's
	# child keeps the name every reader of this layer looks up.
	if artifact.name != "Artifact": artifact.name = "Artifact"
	if before_ready:
		artifact.scale *= float(item.scale)
	if not before_ready and artifact.has_method("apply_grid_config") and not source_config.is_empty():
		artifact.call("apply_grid_config", runtime_config)
	if artifact_trial in ["randomness_02", "randomness_04", "randomness_05"]:
		# These source tokens include their museum glass enclosure/compact
		# console. Reuse the original furnishing adapter, not just its metadata.
		preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd").install(artifact, source_config)
	if artifact_trial == "cellularautomata_03" and item.artifact == "sierpinski_pyramid":
		# Endless Museum seats the built mesh on its authored plinth (+3 cm).
		# Preserve that support for this centred recursive construction rather
		# than burying its lower calls in the slab. Layout height/scale stay intact.
		var lower_y: float = INF
		for mesh in artifact.find_children("*", "MeshInstance3D", true, false):
			if mesh.mesh != null: lower_y = minf(lower_y, (mesh.global_transform * mesh.get_aabb()).position.y)
		var ground_y: float = mount.global_position.y
		if lower_y < INF: artifact.position.y += ground_y + .28 - lower_y
		var plinth: Node3D = preload("res://commons/artifacts/station/station_plinth.tscn").instantiate()
		plinth.name = "OriginalMuseumPlinth"
		plinth.top_height = .25
		plinth.width_cells = 4
		plinth.depth_cells = 4
		plinth.scale = Vector3.ONE / float(item.scale)
		artifact.add_child(plinth)
		plinth.global_position = Vector3(mount.global_position.x, ground_y, mount.global_position.z)
	if item.artifact == "panel_bridge_loom":
		# Keep its original 3D panels; the standalone demo HUD and R reload
		# shortcut must not cover other floors or intercept Void's retry.
		artifact.set_process_unhandled_input(false)
		if artifact.has_node("InfoOverlay"): artifact.get_node("InfoOverlay").hide()
	if item.get("config", {}).get("interface_style", "") == "architectural":
		preload("res://commons/void/opening_interface_hardware.gd").attach(artifact, str(item.artifact))
		# Imported monitors can rebuild once on deferred configuration. Fit the
		# original final screen, not the just-retired viewport from _ready.
		if str(item.artifact) in ["line_black_box","two_point_ruler","sketch_monitor","science_screen","line_space_workshop"]:
			artifact.set_meta("mounted_interface",true)
			preload("res://commons/void/lines_interface_hardware.gd").attach.call_deferred(artifact,str(item.artifact))
		if str(item.artifact) in ["hand_telemetry_diptych","trace_paint_box"]:
			artifact.set_meta("mounted_interface",true)
			preload("res://commons/void/trace_interface_hardware.gd").attach_later(artifact,str(item.artifact))
	if bool(item.get("config", {}).get("entropies_staging", false)):
		preload("res://commons/void/entropies_staging.gd").attach(artifact,str(item.artifact))
	if bool(item.get("config", {}).get("entropy_workshop_hardware", false)):
		artifact.set_meta("mounted_interface",true)
		preload("res://commons/void/entropy_workshop_hardware.gd").attach_later(artifact,str(item.artifact))
	if item.artifact=="lab_room" and bool(source_config.get("void_auto_door",false)):
		var ca_door := Node.new();ca_door.name = "CuratedDoorConnection"
		ca_door.set_script(preload("res://commons/void/ca_curated_door.gd"));artifact.add_child(ca_door)
	if item.artifact=="game_of_life_petri" and source_config.has("curated_console"):
		var ca_console := Node.new();ca_console.name = "CuratedOperatingRim"
		ca_console.set_script(preload("res://commons/void/ca_life_controls.gd"));artifact.add_child(ca_console)
	if item.artifact=="structure_growth" and source_config.has("curated_console"):
		var state_console := Node.new();state_console.name = "CuratedOperatingRim"
		state_console.set_script(preload("res://commons/void/ca_state_controls.gd"));artifact.add_child(state_console)
	if item.artifact=="ca_bridge" and source_config.has("curated_console"):
		var history_console := Node.new();history_console.name = "CuratedHistoryDesk"
		history_console.set_script(preload("res://commons/void/ca_history_controls.gd"));artifact.add_child(history_console)
	var interface_specification: Dictionary = item.get("interface", {})
	if str(interface_specification.get("style", "")) in ["ceiling_instrument", "pillar_instrument"]:
		# The adapter fits the completed museum apparatus and never replaces its
		# controls. Mark it now so the generic floor lead is not built while the
		# measured ceiling carrier waits for its two settling frames.
		artifact.set_meta("mounted_interface", true)
		preload("res://commons/void/randomness_interface_hardware.gd").attach_later(artifact, interface_specification)
	if museum_import:
		# Original standalone viewpoints/suns must not replace the visitor or sky.
		for camera in artifact.find_children("*", "Camera3D", true, false):
			if camera.get_viewport()==get_viewport(): camera.current = false
		for sun in artifact.find_children("*", "DirectionalLight3D", true, false):
			if sun.get_viewport()==get_viewport(): sun.hide()
		for environment in artifact.find_children("*", "WorldEnvironment", true, false):
			if environment.get_viewport()==get_viewport(): environment.environment = null
		if item.get("config", {}).has("reactive"):
			Reactions.attach.call_deferred(artifact, item.config)
	if data.floors[index].map == "Point_Coordinates" and item.artifact == "point_held":
		var illumination := CarriedPointLight.new()
		illumination.name = "PickupIllumination"
		artifact.point.add_child(illumination)
	for body in artifact.find_children("*","CollisionObject3D",true,false):
		if body.get_meta("void_floor_surface",false): body.set_meta("void_floor_index",index)
	if item.artifact == "CoordinateSystem3M":
		var point: Node3D = artifact._find_point()
		if point != null: point.origin_point = artifact.global_position
	exhibits["%d/%s" % [index, item.id]] = mount
	if OS.get_environment("VOID_TRACE_ARTIFACTS") == "1": print("VOID_LOAD_END ", artifact_trial, " / ", item.id)
	# Retrofitted instruments carry their own rigid supply and structural mount.
	if artifact.has_node("ArchitecturalHardware/HardwareSupply") or artifact.get_meta("mounted_interface",false): return
	# These cables and support rods are decorative, not interaction dependencies.
	# Passive construction solids (including copied Polyhedra shaft barriers)
	# need no electrical feed or instrument support rods.
	if artifact.has_meta("construction_definition"): return
	if index == 0 or building.abstract_floor(index): return
	if bool(data.floors[index].get("supply_leads",true)):
		var lead := Node3D.new()
		lead.name = "Lead_" + str(item.id)
		lead.set_meta("station",item.station)
		host.add_child(lead)
		var socket := Vector3(float(pair[0]),SUPPLY_Y,float(pair[1]))
		var elbow := Vector3(float(at[0]),SUPPLY_Y,float(pair[1]))
		var end := Vector3(float(at[0]),SUPPLY_Y,float(at[1]))
		if socket.distance_to(elbow)>0.01: building.pipe(lead,"Across",socket,elbow,0.018,building.pink)
		if elbow.distance_to(end)>0.01: building.pipe(lead,"Along",elbow,end,0.018,building.pink)
		# Groups share a ceiling distribution box; there is no decorative cord to the floor.
		if not definition.get("group",false):
			var terminal := Vector3(end.x,maxf(1.9,float(item.height)+0.5),end.z)
			if item.artifact == "point_pedestal":
				terminal.y = maxf(terminal.y,float(item.height)+2.55*float(item.scale))
			elif item.artifact == "frame_counter_display":
				terminal.y = maxf(terminal.y,float(item.height)+.43*float(item.scale)+.12)
			building.pipe(lead,"ArtifactFeed",end,terminal,0.02,building.pink)
			if data.floors[index].map == "Point_One" and item.artifact in ["point_absent", "point_visible", "point_solid", "point_pedestal"]:
				var lamp := RodLight.new()
				lamp.name = "RodTerminalLamp"
				# It belongs to this artifact, so copies and editor moves keep the lamp.
				artifact.add_child(lamp)
				lamp.global_position = host.to_global(terminal)
				lamp.set_lit(bool(host.get_meta("point_lights_enabled",true)))
	if float(item.height)>0.08:
		var back := mount.position+Vector3(0,0,-0.22*float(item.scale)).rotated(Vector3.UP,deg_to_rad(float(item.facing)))
		building.pipe(host,"ArtifactSupport",Vector3(back.x,0.04,back.z)+Vector3(0.16,0,0),back+Vector3(0.16,0,0),0.06,building.steel)

func _definition(key: String) -> Dictionary:
	if catalog.artifacts.has(key): return catalog.artifacts[key]
	var directory := "res://commons/artifacts/registry"
	var files := DirAccess.get_files_at(directory)
	files.sort()
	# Same deterministic precedence as the editor's registry reader.
	var found: Dictionary = {}
	for file in files:
		if not file.ends_with(".json"): continue
		var registry: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join(file)))
		var entry: Dictionary = registry.get("artifacts", {}).get(key, {})
		if not entry.is_empty() and entry.has("scene") and ResourceLoader.exists(str(entry.scene)):
			found = entry
	if not found.is_empty(): catalog.artifacts[key] = found
	return found

func _text(host: Node3D, words: String, at: Vector3, pixels: float) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = 64
	label.pixel_size = pixels
	label.outline_size = 0
	label.modulate = Color("262b32")
	host.add_child(label)
	return label

func _key(index: int, x: int, z: int) -> String:
	return "%d:%d:%d" % [index, x, z]

func react_at_world(world_position: Vector3, trigger: String) -> bool:
	if not trigger.begins_with("catalyst."): return false
	var local := to_local(world_position)
	for index in range(building.spec.levels.size()):
		var key := _key(index, floori(local.x), floori(local.z))
		if not cells.has(key): continue
		var cell: Dictionary = cells[key]
		var base_y := float(building.spec.levels[index])
		if local.y < base_y - 0.15 or local.y > base_y + float(cell.height) + 0.25: continue
		# Only the impacted panel changes; no timer or neighbour propagation.
		cell.height = 0.03 if float(cell.height) >= 0.9 else float(cell.height) + 0.3
		var tile: StaticBody3D = cell.node
		tile.position.y = float(cell.height) / 2.0
		(tile.get_child(0) as MeshInstance3D).mesh.size.y = float(cell.height)
		(tile.get_child(0) as MeshInstance3D).material_override = building.pink
		(tile.get_child(1) as CollisionShape3D).shape.size.y = float(cell.height)
		impact_count += 1
		panel_activated.emit(tile.global_position)
		return true
	return false
