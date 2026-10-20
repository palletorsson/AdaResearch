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
	var floor_root := Node3D.new()
	floor_root.name = "Content%d" % index
	floor_root.position.y = float(building.spec.levels[index])
	floor_root.set_meta("map", record.map)
	floor_root.set_meta("em_map", record.map) # Scope the sampling monitor to this hall.
	floor_root.set_meta("void_content_floor", index)
	add_child(floor_root)
	roots[index] = floor_root
	if trial_id.is_empty() and str(record.map).begins_with("Trans_"):
		var score := LessonScore.new()
		score.name = "LessonScore"
		floor_root.add_child(score)
	if not trial_id.is_empty() or str(record.map).begins_with("Trans_"):
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
	host.add_child(mount)
	var artifact := packed.instantiate() as Node3D
	artifact.name = "Artifact"
	var lines_floor: bool = data.floors[index].map == "Point_Lines"
	var transformation: bool = str(data.floors[index].map).begins_with("Trans_")
	if data.floors[index].map in ["Point_Lines", "Point_Trace"] and item.artifact == "player_trace":
		# Keep the original recorder, with the same floor-aware adapter as the
		# line assembly. One recorder owns this floor, even when both are placed.
		artifact.set_script(LinesTrace)
		artifact.preferred_recorder = true
		# Grid's walking comparison keeps its original grid, unrounded ghost
		# and colour settings, while tracking the actual body on this floor.
		artifact.preserve_museum_style = not lines_floor
	if (not trial_id.is_empty() or lines_floor or transformation) and "health_provider" in artifact:
		artifact.health_provider = get_tree().get_first_node_in_group("void_health")
	if not trial_id.is_empty() and "score_provider" in artifact:
		artifact.score_provider = get_tree().get_first_node_in_group("void_trial_score")
	elif transformation and "score_provider" in artifact:
		artifact.score_provider = host.get_node("LessonScore")
	artifact.scale = Vector3.ONE * float(item.scale)
	var museum_import := bool(definition.get("museum_import", false)) or not trial_id.is_empty() or transformation
	if museum_import:
		Identity.stamp(artifact, str(item.artifact), definition)
		artifact.set_meta("void_source", definition.scene)
		artifact.rotation_degrees.y = float(item.get("config", {}).get("museum_yaw", 0))
		for key in item.get("config", {}):
			artifact.set_meta("config_" + str(key), item.config[key])
	var before_ready := bool(definition.get("configure_before_ready", false))
	if before_ready and artifact.has_method("apply_grid_config"):
		artifact.scale = Vector3.ONE
		artifact.call("apply_grid_config", item.get("config", {}))
	mount.add_child(artifact)
	# A scene may rename its own root in _ready (geometry_noise does); the mount's
	# child keeps the name every reader of this layer looks up.
	if artifact.name != "Artifact": artifact.name = "Artifact"
	if before_ready:
		artifact.scale *= float(item.scale)
	if not before_ready and artifact.has_method("apply_grid_config") and not item.get("config", {}).is_empty():
		artifact.call("apply_grid_config", item.config)
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
	# These cables and support rods are decorative, not interaction dependencies.
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
