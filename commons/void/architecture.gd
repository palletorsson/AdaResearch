extends Node3D
## Permanent frame and removable circulation studies. No curriculum or game rules.
const CONFIG := "res://commons/void/layout.json"
const Basin := preload("basin.gd")
const CliffLandings := preload("cliff_landings.gd")
var floor_records: Array = []
const Content := preload("res://commons/void/floor_content.gd")
var content: Node3D
var stream_content := false
var trial_id := ""
var floor_details: Dictionary = {}
var spec: Dictionary
var floors: Array[Node3D] = []
var temporary: Node3D
var partitions: Node3D
var mounts: Array[Marker3D] = []
var landing_pads: Array[StaticBody3D] = []
var concrete: StandardMaterial3D
var steel: StandardMaterial3D
var pink: StandardMaterial3D
var pipe_material: StandardMaterial3D
var timber: StandardMaterial3D

func abstract_floor(index: int) -> bool:
	return spec.get("floor_styles", {}).get(str(index), "") == "abstract"

func _ready() -> void:
	trial_id = Content.Source.selected(trial_id)
	spec = Content.Source.read_layout(trial_id)
	floor_records = Content.Source.read_rooms(trial_id).floors
	concrete = material(Color("c3bdb1"), 0.9)
	steel = material(Color("313b43"), 0.36, 0.65)
	pink = material(Color("d77894"), 0.45, 0.3)
	pipe_material = material(Color("718d98"), 0.4, 0.5)
	timber = material(Color("b78e59"), 0.85)
	for level in spec.levels.size():
		_build_floor(level)
	_build_columns()
	_build_services()
	temporary = Node3D.new()
	temporary.name = "TemporaryLandings"
	add_child(temporary)
	if spec.get("descent", {}).get("mode", "shaft_ledges") == "corner_pads":
		for level in range(1, spec.levels.size()):
			_build_corner_pad(level)
	elif spec.get("descent", {}).get("mode", "shaft_ledges") == "balcony":
		# A structural floor may intentionally have no authored descent yet.
		for level in range(1, mini(spec.levels.size(),spec.descent.balcony_sides.size()+1)):
			if float(level) not in spec.descent.get("shaft_corner_floors",[]):
				_build_balcony(level)
	else:
		for level in range(spec.levels.size() - 1):
			_build_landings(float(spec.levels[level]))
	if CliffLandings.enabled(spec):
		for level in range(1, spec.levels.size()):
			CliffLandings.build(self, level)
	partitions = Node3D.new()
	partitions.name = "OptionalPartitions"
	add_child(partitions)
	box(partitions, "SamplePartition", Vector3(0, -4.5, -5.4), Vector3(7, 3, 0.16), concrete)
	partitions.hide()
	set_partition_collision(false)
	_build_roof_details()
	content = Content.new()
	content.name = "FloorContent"
	content.lazy = stream_content
	content.trial_id = trial_id
	add_child(content)

## Detail follows its floor's visibility; slab collision is never removed.
func detail_root(index: int) -> Node3D:
	if floor_details.has(index): return floor_details[index]
	var detail := Node3D.new()
	detail.name = "StoreyDetails%d" % index
	add_child(detail)
	floor_details[index] = detail
	return detail

func show_floor_window(indices: Array[int]) -> void:
	for i in range(floors.size()):
		floors[i].visible = i in indices
		if floor_details.has(i): floor_details[i].visible = i in indices

func material(colour: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = roughness
	result.metallic = metallic
	return result

func box(parent: Node3D, title: String, at: Vector3, size: Vector3, mat: Material, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.name = title
	body.position = at
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	body.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		body.add_child(collider)
	return body

func pipe(parent: Node3D, title: String, from: Vector3, to: Vector3, radius: float, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 12
	mesh.mesh = cylinder
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = (from + to) * 0.5
	var direction := (to - from).normalized()
	mesh.quaternion = Quaternion(Vector3.UP, direction)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = radius
		capsule.height = cylinder.height
		collision.shape = capsule
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

func _build_floor(index: int) -> void:
	var floor_root := Node3D.new()
	floor_root.name = "Floor%d" % index
	floor_root.position.y = float(spec.levels[index])
	floor_root.set_meta("void_floor_index", index)
	floor_root.set_meta("basin", floor_records[index].get("basin", {}))
	add_child(floor_root)
	floors.append(floor_root)
	if index == 0 and floor_records[index].get("origin",false):
		floor_root.add_child(preload("res://commons/void/origin_floor_grid.gd").new())
	# Tile the slab around the holes. No invisible collision plane below the shafts.
	var half_w: float = spec.width / 2.0
	var half_d: float = spec.depth / 2.0
	var half_hole: float = spec.shaft_depth / 2.0
	var edge_z: float = (half_d + half_hole) / 2.0
	var depth_strip: float = half_d - half_hole
	for side in [-1, 1]:
		Basin.slab(self, floor_root, "SlabOuter%d" % side, Vector3(0, -spec.slab_thickness / 2.0, side * edge_z), Vector3(spec.width, spec.slab_thickness, depth_strip))
	var cursor := -half_w
	for shaft in spec.shafts:
		var left: float = shaft.x - spec.shaft_width / 2.0
		_add_slab_strip(floor_root, cursor, left)
		cursor = shaft.x + spec.shaft_width / 2.0
	_add_slab_strip(floor_root, cursor, half_w)
	Basin.build(self, floor_root)
	# A landing edge can be seen from above; these narrow strips do not bridge a hole.
	for shaft in spec.shafts:
		for side in [-1, 1]:
			box(floor_root, "ShaftLip", Vector3(shaft.x, 0.012, side * (half_hole + 0.065)), Vector3(spec.shaft_width, 0.024, 0.13), pink, false)
		var label := Label3D.new()
		label.name = "ShaftMarker"
		label.text = "%s  /  %02d" % [shaft.name, index]
		label.font_size = 96
		label.pixel_size = 0.006
		label.modulate = Color("dce0d9")
		label.outline_size = 0
		label.position = Vector3(shaft.x, -0.85, -3.05)
		floor_root.add_child(label)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/catalog.json"))
	for station in catalog.stations:
		var pair: Array = catalog.stations[station]
		var marker := Marker3D.new()
		marker.name = "ArtifactMount_" + station
		marker.position = Vector3(float(pair[0]), 0.0, float(pair[1]))
		marker.set_meta("role", "floor supply station")
		floor_root.add_child(marker)
		mounts.append(marker)

func _add_slab_strip(parent: Node3D, left: float, right: float) -> void:
	if right <= left: return
	Basin.slab(self, parent, "SlabBetweenShafts", Vector3((left + right) / 2.0, -spec.slab_thickness / 2.0, 0), Vector3(right - left, spec.slab_thickness, spec.shaft_depth))

func _build_columns() -> void:
	for index in range(spec.levels.size()):
		var frame := detail_root(index)
		var y := float(spec.levels[index])
		var high := y+2.0 if index==0 else float(spec.levels[index-1])-0.55
		var low := y-3.0 if index==spec.levels.size()-1 else y-0.55
		for x in spec.column_x:
			for z in spec.column_z:
				box(frame,"Column",Vector3(x,(high+low)/2,z),Vector3(spec.column_width,high-low,spec.column_width),concrete)
				if index==0:
					for dx in [-0.23,0.23]:
						for dz in [-0.23,0.23]: pipe(frame,"Rebar",Vector3(x+dx,high,z+dz),Vector3(x+dx,high+0.75,z+dz),0.022,steel)
		for z in spec.column_z:
			box(frame, "DownstandBeam", Vector3(0, y - 0.55, z), Vector3(spec.width, 0.45, 0.65), concrete)

func _build_services() -> void:
	for level in range(spec.levels.size()):
		if abstract_floor(level): continue
		var services := detail_root(level)
		var high := 1.0 if level==0 else float(spec.levels[level-1])
		var low := float(spec.levels[level]) - (2.0 if level==spec.levels.size()-1 else 0.0)
		for x in spec.service_x:
			pipe(services,"WaterRiser",Vector3(x,low,spec.service_z),Vector3(x,high,spec.service_z),0.14,pipe_material)
			# Point Zero keeps the main pipe/support structure without the
			# additional pink electrical lines rising through the roof.
			if level != 0:
				pipe(services,"ElectricalRiser",Vector3(x+0.42,low,spec.service_z),Vector3(x+0.42,high,spec.service_z),0.07,pink)
			if level==0: continue
			var ceiling: float = float(spec.levels[level - 1]) - 0.95
			pipe(services, "FloorBranch", Vector3(x, ceiling, spec.service_z), Vector3(x, ceiling, 7.0), 0.1, pipe_material)
			box(services, "CableTray", Vector3(x + 0.42, ceiling + 0.18, 1.5), Vector3(0.34, 0.08, 11.0), steel, false)
			for z in [-3, 0, 3, 6]:
				pipe(services, "TrayHanger", Vector3(x + 0.42, ceiling + 0.18, z), Vector3(x + 0.42, ceiling + 0.6, z), 0.018, steel)

func _build_corner_pad(index: int) -> void:
	if float(index) in spec.get("descent",{}).get("pad_disabled_floors",[]):
		return # A bounded flight encounter needs the entire shaft opening.
	# Two flush boards occupy one corner. Existing floors default to shaft B;
	# a trial can route arrival and departure through different named shafts.
	var side := 1.0 if index % 2 == 1 else -1.0
	var shaft_name: String = spec.get("descent",{}).get("pad_shafts",{}).get(str(index),spec.get("descent",{}).get("pad_shaft","B"))
	var shaft_x: float = float(spec.shafts[1].x)
	for shaft in spec.shafts:
		if shaft.name == shaft_name: shaft_x=float(shaft.x)
	var x_side: float = float(spec.descent.get("pad_x_sides",{}).get(str(index),1))
	var x := shaft_x + x_side * (float(spec.shaft_width) / 2.0 - 0.8)
	var z := side * (float(spec.shaft_depth) / 2.0 - 1.1)
	for board in range(2):
		var pad := box(floors[index], "CornerLanding%d" % board,
			Vector3(x - 0.39 + board * 0.78, -0.06, z),
			Vector3(0.76, 0.12, 2.2), timber) as StaticBody3D
		pad.set_meta("void_landing_pad", true)
		pad.set_meta("void_floor_index", index)
		pad.set_meta("floor_index", index)
		landing_pads.append(pad)
		box(pad, "SoftLandingStripe", Vector3(0, 0.063, -side * 0.9),
			Vector3(0.70, 0.006, 0.12), pink, false)
	var label := Label3D.new()
	label.name = "CornerLandingLabel"
	label.text = "SOFT LANDING / %02d" % index
	label.font_size = 48
	label.pixel_size = 0.0018
	label.outline_size = 0
	label.modulate = Color("28242b")
	label.position = Vector3(x, 0.012, z)
	label.rotation_degrees.x = -90
	floors[index].add_child(label)

func _build_balcony(index: int) -> void:
	var settings: Dictionary = spec.descent
	var side := 1.0 if settings.balcony_sides[index - 1] == "south" else -1.0
	var width := float(settings.balcony_width)
	var depth := float(settings.balcony_depth)
	var centre := Vector3(0, 0, side * (float(spec.depth) / 2.0 + depth / 2.0))
	var host: Node3D = floors[index]
	# Flush with the lower floor; the pad, not the whole floor, absorbs impact.
	box(host, "BalconySlab", centre - Vector3(0, 0.22, 0), Vector3(width, 0.28, depth), concrete)
	var finish := material(Color("b75c85"), 0.85)
	var pad := box(host, "LandingPad", centre - Vector3(0, 0.04, 0), Vector3(width, 0.08, depth), finish) as StaticBody3D
	pad.set_meta("void_landing_pad", true)
	pad.set_meta("floor_index", index)
	landing_pads.append(pad)
	for i in range(13):
		box(host, "CushionSeam", centre + Vector3(-width / 2.0 + i * width / 12.0, 0.006, 0), Vector3(0.025, 0.012, depth - 0.14), steel, false)
	for x in [-width / 2.0, width / 2.0]:
		box(host, "BalconyEdge", centre + Vector3(x, 0.025, 0), Vector3(0.10, 0.05, depth), pink, false)
	var label := Label3D.new()
	label.text = "LAND HERE / %02d" % index
	label.font_size = 80
	label.pixel_size = 0.004
	label.outline_size = 0
	label.modulate = Color("fff4e3")
	label.position = centre + Vector3(0, 0.025, 0)
	label.rotation_degrees = Vector3(-90, 180 if side > 0 else 0, 0)
	host.add_child(label)
	# A matching edge on the upper floor points to the balcony below.
	var launch := Vector3(0, 0.02, side * (float(spec.depth) / 2.0 - 0.12))
	box(floors[index - 1], "DescentLip", launch, Vector3(width, 0.04, 0.18), pink, false)
	var instruction := Label3D.new()
	instruction.text = "BALCONY BELOW"
	instruction.font_size = 72
	instruction.pixel_size = 0.004
	instruction.outline_size = 0
	instruction.modulate = Color("362c39")
	instruction.position = launch - Vector3(0, 0, side * 0.7)
	instruction.rotation_degrees = Vector3(-90, 180 if side > 0 else 0, 0)
	floors[index - 1].add_child(instruction)

func absorb_landing(pad: StaticBody3D) -> void:
	# Compress the visual skin only; the collider stays flush with the floor.
	var mesh := pad.get_child(0) as MeshInstance3D
	mesh.scale.y = 0.3
	create_tween().tween_property(mesh, "scale:y", 1.0, 0.35)

func _build_landings(top_y: float) -> void:
	# Route A alternates within the shaft without capping its centre.
	for row in [[-8.4, top_y - 2.0, -1.7], [-11.6, top_y - 4.0, 1.7]]:
		var at := Vector3(row[0], row[1], row[2])
		box(temporary, "ShaftALedge", at - Vector3(0, 0.12, 0), Vector3(1.8, 0.24, 2.6), timber)
		pipe(temporary, "LandingBrace", at - Vector3(0, 1.0, 0.9), at + Vector3(0.6, -0.15, 0.9), 0.055, steel)
	# B offers a contrasting, wider landing with space left around it to look down.
	var suspended := Vector3(10.0, top_y - 3.0, 1.9)
	box(temporary, "ShaftBPlatform", suspended - Vector3(0, 0.13, 0), Vector3(3.4, 0.26, 1.8), steel)
	box(temporary, "PlatformEdge", suspended + Vector3(0, 0.015, -0.82), Vector3(3.4, 0.03, 0.13), pink, false)
	for x in [8.4, 11.6]:
		pipe(temporary, "Suspension", Vector3(x, top_y - 3, 2.7), Vector3(x, top_y - 0.05, 3.1), 0.025, steel)

func _build_roof_details() -> void:
	var roof := floors[0]
	# Incomplete edge protection belongs to the construction site, not a full enclosure.
	var balcony_route: bool = spec.get("descent", {}).get("mode", "shaft_ledges") == "balcony"
	var cliff_route: bool = CliffLandings.enabled(spec)
	var rail_end: float = float(spec.width) / 2.0 - 1.0
	for side in [-1, 1]:
		var z: float = side * (float(spec.depth) / 2.0 - 0.1)
		var segments := [Vector2(-rail_end, rail_end)]
		var launch_side := 1 if spec.get("descent", {}).get("balcony_sides", ["south"])[0] == "south" else -1
		if balcony_route and side == launch_side:
			segments = [Vector2(-rail_end, -2.0), Vector2(2.0, rail_end)]
		if cliff_route and side == int(CliffLandings.landing(spec, 1).side):
			var launch_x: float = CliffLandings.landing(spec, 1).x
			segments = [Vector2(-rail_end, launch_x - 2.0), Vector2(launch_x + 2.0, rail_end)]
		for segment in segments:
			pipe(roof, "EdgeRail", Vector3(segment.x, 1.05, z), Vector3(segment.y, 1.05, z), 0.03, steel, true)
			var count := ceili((segment.y - segment.x) / 6.0)
			for i in range(count + 1):
				var x: float = lerpf(segment.x, segment.y, float(i) / count)
				pipe(roof, "EdgePost", Vector3(x, 0, z), Vector3(x, 1.05, z), 0.035, steel, true)
	if not balcony_route:
		for i in range(5):
			box(roof, "StoredBoard", Vector3(2.5, 0.05 + i * 0.09, -6.0), Vector3(3.7, 0.08, 0.65), timber)
	var title := Label3D.new()
	title.text = "THE VOID"
	title.font_size = 128
	title.pixel_size = 0.012
	title.outline_size = 0
	title.modulate = Color("272d34")
	title.position = Vector3(0, 0.025, 4.5)
	title.rotation.x = -PI / 2.0
	roof.add_child(title)

func set_partition_collision(enabled: bool) -> void:
	for shape in partitions.find_children("*", "CollisionShape3D", true, false):
		(shape as CollisionShape3D).set_deferred("disabled", not enabled)

func show_partitions(enabled: bool) -> void:
	partitions.visible = enabled
	set_partition_collision(enabled)
