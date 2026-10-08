extends "res://commons/artifacts/spine_studies/study_forms.gd"
## A later geometry workbench: same saved path, three visible constructions.
const Surface = preload("res://commons/artifacts/spine_studies/tube_surface.gd")
const Network = preload("res://commons/primitives/pipes/run_network.gd")
const Parts = preload("res://commons/primitives/pipes/part_library.gd")
const PALETTE := [Color("d877a2"),Color("eeeae0"),Color("29272e")]
const VIEW_NAMES := ["PATH","RINGS","TUBE"]
const PAINT_BOUNDS := AABB(Vector3(-3.5,0.25,-3.2),Vector3(7.0,4.25,7.0))
const WALL_Z := -3.01
var strokes: Array[Dictionary] = []
var active := PackedVector3Array()
var pen: Node3D
var home := Transform3D.IDENTITY
var geometry: Node3D
var readout: Label3D
var feedback: Label3D
var ends: Array[Node3D] = []
var held_end: Node3D
var editing := -1
var active_style: Dictionary = {}
var history: Array[Array] = []
var gesture_before: Array = []
var wall_attached := false
var radius_index := 1
var sides_index := 1
var colour_index := 0
var view_mode := 2
var dirty := false
var rebuild_clock := 0.0
var return_message := ""
var blocked_until_release := false
var kind_index := 0
var sag_amount := 0.5
var join_enabled := true
var snap_preview: MeshInstance3D
var part_page := -1
var patch_application: Node3D
var ceiling_application: Node3D

func _ready() -> void:
	block(Vector3(0,2.7,-3.1),Vector3(9,5.4,0.16),Color("deded7"),true)
	inscription("A LINE TAKES UP ROOM",Vector3(0,5.06,-2.99),0.004)
	inscription("EXTEND AN END · DRAW FROM A RUN TO BRANCH · RELEASE NEAR A RUN TO JOIN",Vector3(0,4.65,-2.99),0.0019)
	readout = inscription("",Vector3(0,0.8,-2.98),0.0029,Color("783252"))
	feedback = inscription("",Vector3(0,0.4,-2.98),0.0021)
	block(Vector3(-2.5,0.6,2.8),Vector3(0.62,1.2,0.62),Color("edeae2"),true)
	pen = preload("res://commons/artifacts/spine_studies/tube_pen.gd").new()
	pen.name = "TubePen"; add_child(pen)
	pen.position = Vector3(-2.5,1.35,2.8); pen.rotation = Vector3(-0.5,0.35,0)
	home = pen.transform
	inscription("DRAW IN THE AIR",Vector3(-2.5,0.9,3.12),0.0016)
	for i in Surface.MAX_STROKES * 4:
		var handle = preload("res://commons/artifacts/spine_studies/tube_end.gd").new()
		var extra := i >= Surface.MAX_STROKES*2
		handle.stroke_index = (i % (Surface.MAX_STROKES*2))/2
		handle.port_index = i%2+(2 if extra else 0)
		handle.at_start = handle.port_index == 0
		add_child(handle); ends.append(handle)
	snap_preview = MeshInstance3D.new()
	var marker := SphereMesh.new(); marker.radius = 0.11; marker.height = 0.22
	snap_preview.mesh = marker; snap_preview.material_override = material(Color("fbb765"),true)
	add_child(snap_preview); snap_preview.hide()
	example()
	patch_application = preload("res://commons/artifacts/spine_studies/patch_and_motion.gd").new()
	patch_application.position = Vector3(6.1,0,-0.5)
	add_child(patch_application)
	ceiling_application = preload("res://commons/artifacts/spine_studies/pipe_ceiling.gd").new()
	add_child(ceiling_application)

func example() -> void:
	strokes.clear(); active.clear()
	for strand in 3:
		var path := PackedVector3Array()
		for i in 41:
			var t := float(i)/40.0
			path.append(Vector3(-1.85+strand*1.8+0.65*sin(TAU*t),3.6-2.1*t,-1.45+0.6*sin(PI*t+strand)))
		strokes.append({"points":path,"radius":Surface.RADII[radius_index],"sides":Surface.SIDE_COUNTS[sides_index],"colour":PALETTE[strand],"attached":false})
	dirty = true; rebuild()
	sync_ends()

func _physics_process(delta: float) -> void:
	if held_end:
		if held_end.held_by_visitor():
			capture_point(to_local(held_end.global_position))
		else:
			finish_stroke(); held_end = null; blocked_until_release = false; sync_ends()
	else:
		for handle in ends:
			if handle.visible and handle.held_by_visitor():
				if not active.is_empty(): finish_stroke()
				begin_extension(handle); break
		if not held_end:
			var pressed: bool = pen.painting and pen.held_by_visitor()
			if not pressed:
				finish_stroke(); blocked_until_release = false
			elif not blocked_until_release:
				capture_point(to_local(pen.get_node("WritingTip").global_position))
	rebuild_clock += delta
	if dirty and rebuild_clock >= 1.0/30.0:
		rebuild(); rebuild_clock = 0.0
	feedback.text = return_message
	if not held_end: sync_ends()

func begin_extension(handle: Node3D) -> void:
	var record: Dictionary = strokes[handle.stroke_index]
	if record.has("part"):
		if strokes.size() >= Surface.MAX_STROKES:
			return_message = "Eight pieces and runs kept. Undo or clear before extending a port."; return
		var socket: Dictionary = record.sockets[handle.port_index]
		if Network.connected(record,socket.point): return
		held_end=handle; editing=-1; gesture_before=strokes.duplicate(true)
		active=PackedVector3Array([socket.point])
		active_style={"radius":minf(socket.radius,0.2),"sides":Surface.SIDE_COUNTS[sides_index],"colour":PALETTE[colour_index],"kind":Network.KINDS[kind_index]}
		wall_attached=false; blocked_until_release=false
		return_message="Continue this port. The supplied part stays in place."
		sync_ends(); return
	var path: PackedVector3Array = strokes[handle.stroke_index].points
	if Network.connected(strokes[handle.stroke_index],path[0] if handle.at_start else path[-1]):
		return_message = "This end is joined. Start with the pen beside the joint to branch."; return
	held_end = handle; editing = handle.stroke_index
	gesture_before = strokes.duplicate(true)
	active_style = strokes[editing].duplicate(true)
	active = active_style.points.duplicate()
	if handle.at_start: active.reverse()
	wall_attached = false; blocked_until_release = active.size() >= Surface.MAX_POINTS
	return_message = "Extend; release at the amber marker to join. Cable ends reshape their span."
	sync_ends()

func sync_ends() -> void:
	for handle in ends:
		var exists: bool = handle.stroke_index < strokes.size()
		var record: Dictionary = strokes[handle.stroke_index] if exists else {}
		exists = exists and handle.port_index < (record.sockets.size() if record.has("part") else 2)
		handle.visible = exists and (held_end == null or handle == held_end) and active.is_empty()
		if handle == held_end: handle.visible = true
		handle.collision_layer = 4 if handle.visible else 0
		if exists and not handle.held_by_visitor():
			var points: PackedVector3Array = record.points
			handle.position = record.sockets[handle.port_index].point if record.has("part") else points[0] if handle.at_start else points[-1]
			if Network.connected(strokes[handle.stroke_index],handle.position):
				handle.visible = false; handle.collision_layer = 0

func remember(before: Array) -> void:
	history.append(before.duplicate(true))
	if history.size() > 16: history.pop_front()

func capture_point(point: Vector3) -> void:
	if blocked_until_release: return
	if not point.is_finite() or not PAINT_BOUNDS.has_point(point):
		return_message = "Stay inside the drawing area; release to keep this stroke."; return
	if active.is_empty():
		if strokes.size() >= Surface.MAX_STROKES:
			return_message = "Eight strokes kept. Undo or clear before drawing another."
			blocked_until_release = true; return
		gesture_before = strokes.duplicate(true)
		active_style = {"radius":Surface.RADII[radius_index],"sides":Surface.SIDE_COUNTS[sides_index],"colour":PALETTE[colour_index],"kind":Network.KINDS[kind_index]}
		wall_attached = false
		active.append(point); return_message = ""; return
	if point.z < -2.78:
		point.z = WALL_Z
		wall_attached = true
	var distance := active[-1].distance_to(point)
	if distance > 0.75:
		return_message = "A sudden jump ends the stroke. Release to begin again."
		blocked_until_release = true; return
	# Only retain an actual sampled nib position; do not invent sub-frame curves.
	if distance < Surface.SAMPLE_SPACING: return
	active.append(point); dirty = true
	var hit := Network.nearest(strokes,point,editing) if join_enabled else {}
	snap_preview.visible = not hit.is_empty()
	if not hit.is_empty():
		snap_preview.position = hit.point
		return_message = "Release at the amber marker to join this run."
	if wall_attached:
		blocked_until_release = true; return_message = "At the wall. Release to keep the attachment."; return
	if active.size() >= Surface.MAX_POINTS:
		blocked_until_release = true
		return_message = "Stroke kept at 256 points. Release before the next stroke."

func finish_stroke() -> void:
	if active.size() >= 2:
		var record := active_style.duplicate(true)
		record.points = active.duplicate(); record.attached = wall_attached
		if editing >= 0: strokes[editing] = record
		else: strokes.append(record)
		var index := editing if editing >= 0 else strokes.size()-1
		if join_enabled:
			Network.connect_end(strokes,index,true)
			Network.connect_end(strokes,index,false)
		if record.get("kind","tube") == "cable": Network.shape_cable(strokes[index],sag_amount,0.25+record.radius)
		remember(gesture_before)
		active.clear(); dirty = true
	elif not active.is_empty(): active.clear()
	editing = -1
	snap_preview.hide()

func rebuild() -> void:
	if geometry:
		remove_child(geometry); geometry.queue_free()
	geometry = Node3D.new(); add_child(geometry)
	var records := strokes.duplicate()
	if active.size() >= 2:
		if editing >= 0: records.remove_at(editing)
		var preview := active_style.duplicate(true); preview.points = active
		if preview.get("kind","tube") == "cable": Network.shape_cable(preview,sag_amount,0.25+preview.radius)
		records.append(preview)
	var last_points := 0; var triangles := 0; var part_count := 0
	var last_sides: int = Surface.SIDE_COUNTS[sides_index]
	var last_radius: float = Surface.RADII[radius_index]
	for record in records:
		if record.has("part"):
			part_count += 1
			for item in record.part_meshes:
				var piece := MeshInstance3D.new(); piece.mesh=item.mesh; piece.transform=item.pose
				var coat := material(record.colour); coat.metallic=0.15; coat.roughness=0.3
				coat.cull_mode=BaseMaterial3D.CULL_DISABLED
				piece.material_override=coat; geometry.add_child(piece)
			var caption := inscription(Parts.label(record.part),record.label_at,0.0022)
			caption.reparent(geometry)
			continue
		var kind: String = record.get("kind","tube")
		var built: Dictionary = Surface.build(record.points,record.radius,record.sides,record.radius*0.22 if kind == "pipe" else 0.0)
		if built.is_empty(): continue
		last_points = built.points.size(); triangles = built.indices.size()/3
		last_sides = record.sides; last_radius = record.radius
		if view_mode == 2:
			var skin := MeshInstance3D.new(); skin.mesh = built.mesh
			var coat := material(record.colour); coat.roughness = 0.32
			if kind == "pipe": coat.metallic = 0.55
			if kind == "cable": coat.roughness = 0.8
			coat.clearcoat_enabled = true; coat.clearcoat = 0.45
			skin.material_override = coat; geometry.add_child(skin)
			if kind == "pipe":
				for end in [0,built.points.size()-1]:
					var tip: Vector3 = built.points[end]
					var neighbour: Vector3 = built.points[1] if end == 0 else built.points[-2]
					var along := (neighbour-tip).normalized()*minf(0.18,tip.distance_to(neighbour)*0.8)
					var sleeve: Dictionary = Surface.build(PackedVector3Array([tip,tip+along]),record.radius*1.2,record.sides,record.radius*0.42)
					if sleeve.is_empty(): continue
					var fitting := MeshInstance3D.new(); fitting.mesh = sleeve.mesh
					fitting.material_override = coat; geometry.add_child(fitting)
		else:
			var path := stroke(built.points,Color("332d36"),0.011); path.reparent(geometry)
			if view_mode == 1:
				var lines := ImmediateMesh.new(); lines.surface_begin(Mesh.PRIMITIVE_LINES)
				for i in built.points.size():
					for j in built.sides:
						lines.surface_add_vertex(built.rings[i*built.sides+j])
						lines.surface_add_vertex(built.rings[i*built.sides+(j+1)%built.sides])
				lines.surface_end()
				var rings := MeshInstance3D.new(); rings.mesh = lines
				rings.material_override = material(record.colour,true); geometry.add_child(rings)
	var joints := Network.junctions(records)
	if view_mode == 2:
		for joint in joints.values():
			var socket := MeshInstance3D.new(); var shape := SphereMesh.new()
			shape.radius = joint.radius*1.28; shape.height = shape.radius*2.0
			socket.mesh = shape; socket.position = joint.point
			var metal := material(Color("aaa6a8")); metal.metallic = 0.75; metal.roughness = 0.24
			socket.material_override = metal; geometry.add_child(socket)
	readout.text = "%s · %d / 8 PIECES AND RUNS · %d JOINTS · NEXT: %s" % [VIEW_NAMES[view_mode],records.size(),joints.size(),Network.KINDS[kind_index].to_upper()]
	if last_points > 0:
		readout.text += "\nLAST RUN: %d RINGS × %d SIDES · RADIUS %.3f m · %d TRIANGLES" % [last_points,last_sides,last_radius,triangles]
	elif part_count > 0:
		readout.text += "\n%d SUPPLIED FORMS · CONTINUE FROM A PINK PORT" % part_count
	feedback.text = return_message
	dirty = false

func control(index: int) -> void:
	return_message = ""
	if pen.painting or not active.is_empty() or held_end:
		return_message = "Release the pen trigger or tube end before changing the work."; return
	for handle in ends:
		if handle.held_by_visitor():
			return_message = "Release the tube end first."; return
	if index in [7,8] and pen.held_by_visitor():
		return_message = "Put down the pen before returning it."; return
	if index in [0,1] and not strokes.is_empty() and strokes[-1].has("part"):
		return_message="Extend a free port first; thickness and sides edit the new run."; return
	if index in [0,1,2,5,6,8,9,10,11,12,13]: remember(strokes)
	match index:
		0: radius_index = (radius_index+1)%Surface.RADII.size()
		1: sides_index = (sides_index+1)%Surface.SIDE_COUNTS.size()
		2: colour_index = (colour_index+1)%PALETTE.size()
		3: view_mode = (view_mode+1)%3
		4:
			if not history.is_empty(): strokes.assign(history.pop_back())
		5: strokes.clear()
		6: example()
		7: pen.transform = home
		8:
			radius_index = 1; sides_index = 1; colour_index = 0; view_mode = 2
			kind_index = 0; sag_amount = 0.5
			part_page = -1
			pen.transform = home; blocked_until_release = false; example()
		9:
			kind_index = (kind_index+1)%Network.KINDS.size()
			if not strokes.is_empty() and not strokes[-1].has("part"):
				strokes[-1].kind = Network.KINDS[kind_index]
				if kind_index == 2: Network.shape_cable(strokes[-1],sag_amount,0.25+strokes[-1].radius)
		10:
			sag_amount = 0.9 if sag_amount < 0.7 else 0.2
			if not strokes.is_empty() and strokes[-1].get("kind","") == "cable": Network.shape_cable(strokes[-1],sag_amount,0.25+strokes[-1].radius)
			return_message = "Cable drape %.1f m. Endpoints and joined supports stay fixed." % sag_amount
		11: network_example()
		12:
			part_page=(part_page+1)%4
			parts_example(part_page)
		13: parts_example(4)
	if index in [0,1,2] and not strokes.is_empty():
		if index == 0: strokes[-1].radius = Surface.RADII[radius_index]
		if index == 1: strokes[-1].sides = Surface.SIDE_COUNTS[sides_index]
		if index == 2: strokes[-1].colour = PALETTE[colour_index]
	rebuild()
	sync_ends()

func network_example() -> void:
	strokes.clear(); active.clear()
	var pipe := PackedVector3Array([Vector3(-2.7,1.2,-1),Vector3(-2.7,3.3,-1)])
	# A rounded elbow into the upper rail, then down to an open mouth.
	for i in 13:
		var angle := PI-float(i)/12*PI/2
		pipe.append(Vector3(-2.3+0.4*cos(angle),3.3+0.4*sin(angle),-1))
	pipe.append(Vector3(2.2,3.7,-1))
	for i in 13:
		var angle := PI/2-float(i)/12*PI/2
		pipe.append(Vector3(2.2+0.4*cos(angle),3.3+0.4*sin(angle),-1))
	pipe.append(Vector3(2.6,2.5,-0.25))
	strokes.append({"points":pipe,"radius":0.14,"sides":24,"colour":PALETTE[1],"kind":"pipe"})
	var cable := Network.sag_path(Vector3(-2.7,2.9,-1),Vector3(2.6,3.3,-1),0.9)
	strokes.append({"points":cable,"radius":0.045,"sides":12,"colour":PALETTE[2],"kind":"cable"})
	Network.connect_end(strokes,1,true); Network.connect_end(strokes,1,false)
	var tube := PackedVector3Array()
	for i in 81:
		var t := float(i)/80
		tube.append(Vector3(-0.4+1.25*sin(TAU*t),3.7-2.4*t,-1+0.55*sin(PI*t)))
	strokes.append({"points":tube,"radius":0.085,"sides":24,"colour":PALETTE[0],"kind":"tube"})
	Network.connect_end(strokes,2,true)
	view_mode = 2
	return_message = "One pipe, one cable, one drawn tube. Grab a free end; draw from any run to branch."
	dirty = true

func parts_example(page: int) -> void:
	strokes.clear(); active.clear()
	var names: Array = Parts.GROUPS[page]
	for i in names.size():
		var at := Vector3(-2.6+(i%3)*2.6,3.55-(i/3)*1.6,-0.95)
		strokes.append(Parts.make_record(names[i],at,PALETTE[0] if page == 2 else PALETTE[2] if page == 4 else PALETTE[1]))
	view_mode=2
	return_message="%s · Grab any free pink port and draw onward. PARTS changes group; UNDO restores the work." % Parts.GROUP_NAMES[page]
	dirty=true
