extends "res://commons/artifacts/colour_light_rooms/colour_light_rooms.gd"
## Original museum rooms, separated into two independently editable assemblies.
## Layer 20 belongs to the player's hidden head in the Void rig.
const ROOM_LAYER := 1 << 17
const SHAFT_SIZE := Vector2(5, 6)
const FLASHLIGHT := preload("res://algorithms/postprocessing/flashlight_demo/flashlight.tscn")
const FLASHLIGHT_COLOUR := preload("res://algorithms/postprocessing/flashlight_demo/flashlight_color.gd")
const CloseLamps := preload("close_lamps.gd")
var part_defaults: Dictionary = {}
var white_room: Node3D
var light_well: Node3D

func _ready() -> void:
	super._ready()
	_wall_flashlights(white_room, 4.1, 5.3)
	_wall_flashlights(light_well, 5.1, 6.9)
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = ROOM_LAYER
	for light in find_children("*", "Light3D", true, false):
		light.light_cull_mask = ROOM_LAYER
	var game := get_tree().get_first_node_in_group("void_game")
	if game != null and is_instance_valid(game.atmosphere):
		# The main spine has a shared sun; retain this study's isolated receiver
		# layer just as the separate trial did, without dimming neighbouring floors.
		game.atmosphere.get_node("WarmSun").light_cull_mask &= ~ROOM_LAYER
	for part in [white_room, light_well]:
		var bounds := _bounds(part, part)
		part_defaults[str(part.name)] = {
			"position": [part.position.x, part.position.y, part.position.z],
			"rotation": [0, 0, 0],
			"bounds": [bounds.position.x, bounds.position.y, bounds.position.z,
				bounds.size.x, bounds.size.y, bounds.size.z]
		}
	for floor_name in ["WhiteFloor*", "ApertureFloor*", "SlowRamp", "UpperLanding"]:
		for surface in find_children(floor_name, "MeshInstance3D", true, false):
			for body in surface.find_children("*", "StaticBody3D", true, false):
				body.set_meta("void_floor_surface", true)
	set_meta("em_visibility_bounds", _bounds(self, self))

func _wall_flashlights(room: Node3D, stand_z: float, wall_z: float) -> void:
	# Reuse the museum's pickable handles and lens colours. These live with
	# their room so editor moves/copies carry the complete light experiment.
	var names := ["Red", "Green", "Blue", "White"]
	var colours := [Color.RED, Color.GREEN, Color.BLUE, Color.WHITE]
	for i in names.size():
		var lamp := FLASHLIGHT.instantiate() as RigidBody3D
		lamp.name = names[i] + "Flashlight"
		CloseLamps.arrange(lamp,i,stand_z,wall_z)
		var colour := Node3D.new()
		colour.name = "ColorSetter"
		colour.set_script(FLASHLIGHT_COLOUR)
		colour.set("light_color", colours[i])
		lamp.add_child(colour)
		room.add_child(lamp)

func _build_white_room() -> void:
	var previous := get_children()
	super._build_white_room()
	white_room = _group_new("WhiteRoom", previous, Vector3.ZERO)
	white_room.position = Vector3(-.6, 0, -4.2)

func box(label: String, at: Vector3, size: Vector3, solid := true, mat: Material = null, obstacle := false) -> MeshInstance3D:
	# Filter the builder's semantic name before Godot assigns duplicate names.
	# Both old tunnel cheeks must go; the tower slab joins the offset doors.
	if label.begins_with("Connecting"): return null
	# Keep the tower's full shaft aperture. Four real slabs, with matching
	# colliders, replace each solid museum floor; there is no invisible lid.
	if label == "WhiteFloor": return _walkway(label, at, Vector2(8.8, 10.8))
	if label == "ApertureFloor": return _walkway(label, at, Vector2(11.2, 14))
	if label == "WhiteCeiling": size.z = 10.8
	if label == "WhiteWall": at.z = signf(at.z) * 5.4
	if label == "WhiteBench": at.z += 1.0
	# A ground-level lane remains between the shaft and the original ramp.
	if label in ["ApertureEast", "SlowRamp", "RampInnerRail"]: at.x += 1.0
	if label == "ApertureEnd": size.x = 11.2
	if label in ["UpperLanding", "LandingParapet"]: size.x += 2.0
	return super.box(label, at, size, solid, mat, obstacle)

func _walkway(label: String, at: Vector3, outer: Vector2) -> MeshInstance3D:
	var side_width := (outer.x - SHAFT_SIZE.x) * 0.5
	var end_depth := (outer.y - SHAFT_SIZE.y) * 0.5
	var first: MeshInstance3D
	for side in [-1, 1]:
		var strip := super.box(label + ("West" if side < 0 else "East"), at + Vector3(side * (SHAFT_SIZE.x + side_width) * 0.5, 0, 0), Vector3(side_width, 0.20, outer.y))
		if first == null: first = strip
		strip = super.box(label + ("North" if side < 0 else "South"), at + Vector3(0, 0, side * (SHAFT_SIZE.y + end_depth) * 0.5), Vector3(SHAFT_SIZE.x, 0.20, end_depth))
	return first

func portal_wall(label: String, x: float, height: float, depth: float) -> void:
	if label.begins_with("White"): depth = 10.8
	if label == "ApertureEntry": x -= 1.0
	super.portal_wall(label, x, height, depth)

func roof_ring(label: String, centre: Vector3, outer: Vector2, hole: Vector2, mat: Material = null, thickness := 0.20) -> void:
	if label.begins_with("CeilingLevel"): outer.x = 11.2
	super.roof_ring(label, centre, outer, hole, mat, thickness)

func _build_pink_threshold() -> void:
	var previous := get_children()
	super._build_pink_threshold()
	for part in get_children():
		if not previous.has(part):
			remove_child(part)
			white_room.add_child(part)
			part.position.z -= 1.0

func _build_aperture_room() -> void:
	var previous := get_children()
	super._build_aperture_room()
	light_well = _group_new("LightWell", previous, SECOND)
	light_well.position = Vector3(10, 0, 0)

func _group_new(label: String, previous: Array, origin: Vector3) -> Node3D:
	var added := get_children().filter(func(n): return not previous.has(n))
	var group := Node3D.new()
	group.name = label
	add_child(group)
	for part in added:
		remove_child(part)
		group.add_child(part)
		part.position -= origin
	return group

func apply_grid_config(config: Dictionary) -> void:
	if config.has("only_parts"):
		for key in part_defaults.keys():
			if not config.only_parts.has(key):
				var part := get_node_or_null(NodePath(key))
				if part: part.free()
				part_defaults.erase(key)
		walls = walls.filter(func(n): return is_instance_valid(n))
		receiving_meshes = receiving_meshes.filter(func(n): return is_instance_valid(n))
	for key in config.get("parts", {}):
		var part := get_node_or_null(NodePath(key)) as Node3D
		if part == null: continue
		var pose: Dictionary = config.parts[key]
		if pose.has("position"):
			var p: Array = pose.position
			part.position = Vector3(p[0], p[1], p[2])
		if pose.has("rotation"):
			var r: Array = pose.rotation
			part.rotation_degrees = Vector3(r[0], r[1], r[2])
	set_meta("em_visibility_bounds", _bounds(self, self))

func set_phase(phase: float) -> void:
	# An editor copy may contain just one room. Keep the original colour score
	# while allowing the other room's nodes to be absent.
	elapsed = fposmod(phase, 1.0) * cycle_seconds
	var c := palette_at(phase)
	if is_instance_valid(central_light): central_light.light_color = c
	if lamp_material:
		lamp_material.albedo_color = c
		lamp_material.emission = c
	for level in rim_materials.size():
		var colour := palette_at(phase + level * 0.055)
		rim_materials[level].albedo_color = colour
		rim_materials[level].emission = colour
		for i in [level * 2, level * 2 + 1]:
			if i < ring_lights.size() and is_instance_valid(ring_lights[i]):
				ring_lights[i].light_color = colour

func _bounds(node: Node3D, relative: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var bounds: AABB = relative.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = bounds if first else result.merge(bounds)
		first = false
	return result
