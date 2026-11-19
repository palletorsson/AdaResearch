extends Node3D
## Museum adapters for the reviewed studies. The main player owns input/camera.
## Pointer buttons use the same pressed-event contract as other museum artifacts.
@export var study := "assembly"
var specimen: Node3D
var status: Label3D
var controls: Array[StaticBody3D] = []
var occupancy: Area3D
var guard_rect := Rect2(-6,-6,12,12)
var release_score: RefCounted
var phase := 0.0
var selected_joint := 0
var alternate := false
var tracing := false
var trace_points := PackedVector3Array()
var trace_mesh: MeshInstance3D
var start_pose: Array = []
var console_z := 7.0

class StudyButton extends StaticBody3D:
	var action: Callable
	func pointer_event(event) -> void:
		if event.event_type == 2: action.call()

func _ready() -> void:
	var sources := {
		"tube":"spine_studies/tube_painting",
		"paired_time":"spine_studies/paired_time",
		"assembly":"colour_assembly/colour_assembly", "wall":"colour_wall_studies/colour_wall_studies",
		"suspension":"reference_studies/suspension", "passage":"reference_studies/passage",
		"landscape":"reference_studies/landscape", "garden":"reference_studies/pattern_garden",
		"body":"reference_studies/plural_body", "cut":"conical_sightline/conical_sightline",
		"signal":"signal_room/signal_room", "hinge":"bicho_hinge/bicho_hinge",
		"network":"spine_studies/evidence_network", "sentence":"spine_studies/sentence_authority", "witness":"spine_studies/museum_witnesses", "tension":"spine_studies/tension_membrane",
		"open":"spine_studies/open_rules", "pink":"spine_studies/pink_sphere", "void":"spine_studies/void_museum"}
	specimen = load("res://commons/artifacts/"+sources[study]+".gd").new()
	specimen.name = "Study"
	var wall_gallery_bay := study == "wall" and bool(get_meta("config_gallery_bay", false))
	if wall_gallery_bay:
		specimen.set("gallery_bay", true)
	if study == "signal":
		specimen.pill_envelope=bool(get_meta("config_pill_envelope",false))
		specimen.initial_pattern=clampi(int(get_meta("config_initial_pattern",0)),0,2)
		var bay:Variant=get_meta("config_side_bay",{})
		if bay is Dictionary:specimen.side_bay=bay.duplicate(true)
	if study == "signal" and has_meta("config_void_room_height"):
		specimen.room_height=clampf(float(get_meta("config_void_room_height")),3.0,7.15)
	if study == "hinge":
		specimen.set("plate_w",0.50)
		specimen.set("show_caption",false)
	add_child(specimen)
	match study:
		"tube": console_z = 5.4; guard_rect = Rect2(-4.6,-3.3,9.2,0.5)
		"paired_time": console_z = 3.5; guard_rect = Rect2(-4.2,-3.7,8.4,1.0)
		"tension": console_z = 4.4; guard_rect = Rect2(-3.1,-1.3,6.2,3.8)
		"network", "sentence": console_z = 5.0; guard_rect = Rect2(-7,-4.5,14,6)
		"witness": console_z = 6.2; guard_rect = Rect2(-7,-4.5,14,8)
		"assembly":
			for z in [-2.65,0.0,2.65]: box(Vector3(0,6.25,z),Vector3(11.5,0.12,0.12))
			console_z = 7.0
		"wall":
			if wall_gallery_bay:
				_build_three_wall_gallery()
				guard_rect = Rect2(-6.7, -2.9, 13.4, 4.4); console_z = 2.65
			else:
				box(Vector3(0,2.9,-4.13),Vector3(18,5.8,0.24))
				for x in [-5.8,0.0,5.8]:
					var lamp := SpotLight3D.new()
					add_child(lamp); lamp.position = Vector3(x-1.45,4.95,0.2)
					lamp.look_at(to_global(Vector3(x,2.35,-4)))
					lamp.light_energy = 0.7; lamp.spot_range = 13; lamp.spot_angle = 46
					lamp.shadow_enabled = true; lamp.shadow_bias = 0.15; lamp.shadow_normal_bias = 1.0
				guard_rect = Rect2(-9,-4.8,18,3.5); console_z = 3.0
		"signal":
			console_z = 13.0; guard_rect = Rect2(-7,-11,14,24)
		"cut":
			console_z = 7.5; guard_rect = Rect2(-4.5,-5.6,19,11.2)
		"void": console_z = 6.0
		"hinge":
			console_z = 2.3; guard_rect = Rect2(-1.8,-1.8,3.6,3.6)
			release_score = load("res://commons/artifacts/spine_studies/hinge_score.gd").new()
			release_score.call("setup",specimen)
			start_pose = specimen.call("hinge_angles")
			trace_mesh = MeshInstance3D.new(); add_child(trace_mesh)
		"open":
			specimen.set("mode",1); specimen.call("rebuild")
			# A fixed low enclosure keeps feet off the display while modes change.
			for side in [-1,1]: box(Vector3(side*5.9,0.12,0),Vector3(0.08,0.24,10.8))
			for side in [-1,1]: box(Vector3(0,0.12,side*5.4),Vector3(11.8,0.24,0.08))
		"landscape", "garden", "body", "suspension":
			# These are surface/pose displays, with the walkable museum floor beneath.
			# A perimeter marks their footprint without pretending every leaf is solid.
			for side in [-1,1]: box(Vector3(side*6.1,0.10,0),Vector3(0.05,0.20,11.0))
		"pink": console_z = 5.4
		"passage": console_z = 5.5; guard_rect = Rect2(-3,-1,6,2)
	# Neutral receiving surfaces belong to the installation. They let the repeated
	# parts read against the museum's existing grid rather than competing with it.
	if study in ["assembly","wall","suspension","open","hinge","passage","body","void","network","sentence","witness","tension","paired_time","tube"] and not (study == "hinge" and bool(get_meta("config_tower_floor", false))) and not wall_gallery_bay:
		var width := 19.0 if study in ["wall","void"] else 14.0
		box(Vector3(0,0.004,0),Vector3(width,0.008,12.5))
		if study in ["open","suspension","body"]:
			box(Vector3(0,3,-5.5),Vector3(width,6,0.16))
		var light := OmniLight3D.new(); add_child(light)
		light.position = Vector3(0,5,1); light.omni_range = 14; light.light_energy = 1.2
		light.omni_attenuation = 0.5
	if study == "assembly":
		for x in [-5.7,5.7]:
			for z in [-2.65,2.65]: box(Vector3(x,3.1,z),Vector3(0.10,6.2,0.10))
	_build_guard()
	_build_controls()
	set_meta("study_id",study)
	set_meta("em_visibility_bounds",AABB(Vector3(-7.2,0,-3.2),Vector3(14.4,5.4,6.4)) if wall_gallery_bay else AABB(Vector3(-10,0,-11),Vector3(25,9,25)))

func _build_three_wall_gallery() -> void:
	# Three museum walls tucked flush between the four West Bay concrete columns
	# (x in [-20, -14], z in [-7, +7], height 5.20 m seated cleanly into the concrete drop-beam soffits).
	var wall_h := 5.20
	var wall_t := 0.26
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("efeee8")
	wall_mat.roughness = 0.92
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color("3a3842")
	trim_mat.roughness = 0.65
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color("dcdad2")
	floor_mat.roughness = 0.86

	# Gallery Wall 1: West Back Wall (spans cleanly between NW & SW columns: 13.10 m)
	_named_box("GalleryWall_West", Vector3(0.0, wall_h * 0.5, -3.0), Vector3(13.10, wall_h, wall_t), wall_mat, true)
	_named_box("Baseboard_West", Vector3(0.0, 0.04, -2.86), Vector3(13.06, 0.08, 0.03), trim_mat, false)

	# Gallery Wall 2: North Return Wall (spans cleanly between NW & NE columns: 5.10 m)
	_named_box("GalleryWall_North", Vector3(7.0, wall_h * 0.5, 0.0), Vector3(wall_t, wall_h, 5.10), wall_mat, true)
	_named_box("Baseboard_North", Vector3(6.86, 0.04, 0.0), Vector3(0.03, 0.08, 5.06), trim_mat, false)

	# Gallery Wall 3: South Return Wall (spans cleanly between SW & SE columns: 5.10 m)
	_named_box("GalleryWall_South", Vector3(-7.0, wall_h * 0.5, 0.0), Vector3(wall_t, wall_h, 5.10), wall_mat, true)
	_named_box("Baseboard_South", Vector3(-6.86, 0.04, 0.0), Vector3(0.03, 0.08, 5.06), trim_mat, false)

	# Crisp column-fitted gallery floor finish (stays strictly inside the 4-column alcove!)
	_named_box("GalleryFloor", Vector3(0.0, 0.004, 0.0), Vector3(13.80, 0.008, 6.00), floor_mat, false)

	# Architectural ceiling track rail + 7 warm gallery spotlights lighting all 3 walls
	_named_box("TrackRail_West", Vector3(0.0, 4.95, -0.65), Vector3(11.6, 0.05, 0.06), trim_mat, false)
	for side in [-1.0, 1.0]:
		_named_box("TrackRail_Side_%d" % int(side + 2), Vector3(side * 4.65, 4.95, 0.0), Vector3(0.06, 0.05, 4.4), trim_mat, false)

	var spot_specs: Array = [
		[Vector3(-4.8, 4.88, -0.65), Vector3(-4.95, 2.40, -2.84)],
		[Vector3(-2.4, 4.88, -0.65), Vector3(-2.50, 2.40, -2.84)],
		[Vector3(0.0, 4.88, -0.65), Vector3(0.0, 2.40, -2.84)],
		[Vector3(2.4, 4.88, -0.65), Vector3(2.50, 2.40, -2.84)],
		[Vector3(4.8, 4.88, -0.65), Vector3(4.95, 2.40, -2.84)],
		[Vector3(4.65, 4.88, 0.0), Vector3(6.84, 2.40, 0.0)],
		[Vector3(-4.65, 4.88, 0.0), Vector3(-6.84, 2.40, 0.0)],
	]
	for s_idx in spot_specs.size():
		var sp: Array = spot_specs[s_idx]
		var lamp := SpotLight3D.new()
		lamp.name = "GallerySpot_%d" % s_idx
		add_child(lamp)
		lamp.position = sp[0]
		lamp.look_at(to_global(sp[1]))
		lamp.light_color = Color("fff5e8")
		lamp.light_energy = 1.05
		lamp.spot_range = 10.0
		lamp.spot_angle = 52.0
		lamp.shadow_enabled = (s_idx in [0, 2, 4])
		lamp.shadow_bias = 0.15
		lamp.shadow_normal_bias = 1.0

	# Soft museum ambient fill inside the alcove
	var fill := OmniLight3D.new()
	fill.name = "GalleryFillLight"
	fill.position = Vector3(0.0, 4.6, 0.3)
	fill.light_color = Color("fff8f0")
	fill.omni_range = 13.0
	fill.light_energy = 1.15
	fill.omni_attenuation = 0.5
	add_child(fill)

	# Sculptural gallery viewing bench in the center of the 3-wall alcove
	_named_box("GalleryBenchSeat", Vector3(0.0, 0.44, 0.35), Vector3(3.2, 0.10, 0.62), trim_mat, true)
	for bx in [-1.30, 1.30]:
		_named_box("GalleryBenchLeg_%d" % int(bx * 10), Vector3(bx, 0.20, 0.35), Vector3(0.10, 0.40, 0.50), wall_mat, true)

func _named_box(label: String, at: Vector3, size: Vector3, mat: Material, solid: bool) -> void:
	var host := Node3D.new()
	host.name = label
	host.position = at
	add_child(host)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = mat
	host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		host.add_child(body)

func box(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new(); body.position = at
	var shape := BoxShape3D.new(); shape.size = size
	var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
	var mesh := MeshInstance3D.new(); var cube := BoxMesh.new(); cube.size = size; mesh.mesh = cube
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("dddcd6"); mat.roughness = 0.9
	mesh.material_override = mat; body.add_child(mesh); add_child(body)

func _build_guard() -> void:
	occupancy = Area3D.new(); occupancy.collision_layer = 0; occupancy.collision_mask = 0xFFFFFFFF
	var shape := BoxShape3D.new(); shape.size = Vector3(guard_rect.size.x,5,guard_rect.size.y)
	var collision := CollisionShape3D.new(); collision.shape = shape; occupancy.add_child(collision)
	occupancy.position = Vector3(guard_rect.get_center().x,2.5,guard_rect.get_center().y); add_child(occupancy)

func can_change() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera:
		var eye := to_local(camera.global_position)
		if guard_rect.has_point(Vector2(eye.x,eye.z)) and eye.y < 5.0:
			status.text = "Step back to the controls before changing the arrangement."
			return false
	for body in occupancy.get_overlapping_bodies():
		if not is_ancestor_of(body) and (body is CharacterBody3D or body is RigidBody3D):
			status.text = "Clear the display before changing its shape."
			return false
	return true

func _build_controls() -> void:
	var names: Array = []
	match study:
		"tube": names = ["THICKNESS","SIDES","COLOUR","VIEW","UNDO","CLEAR","EXAMPLE","PEN HOME"]
		"paired_time": names = ["DRIFT RIGHT","SAME RATE","OFFSET +45°","ALIGN","HOLD / RUN","READING"]
		"tension": names = ["HOLD A PULL","RELEASE","LOAD","MORE / LESS GIVE"]
		"network": names = ["LAYOUT","FILTER","RECORD","NODE"]
		"sentence": names = ["SENTENCE","PACE","HOLD / RUN","WORD / WHOLE"]
		"witness": names = ["VIEWPOINT","DELAY","HOLD / RELEASE","RETURN CAMERAS"]
		"assembly": names = ["CANOPY","SCREENS","GATHER","COLOUR"]
		"wall": names = ["SPACING","DEPTH","OMIT / RESTORE","COLOUR"]
		"signal": names = ["ORDERED","ROWS","CELLS","NEXT SEED","SHIFT ROW","4 × 4 PATCH"]
		"cut": names = ["BEFORE / CUT","SHIFT CUT"]
		"open": names = ["FIVE FORMS","ARRAY","STACKS","RULE","122"]   # 122: LeWitt's incomplete open cubes, enumerated
		"hinge": names = ["JOINT","TURN −","TURN +","KEEP / RETURN","RELEASE","TRACE"]
		"pink": names = ["TOP","LEFT","RIGHT","FRONT","BACK","LIGHT / MATERIAL"]
		"void": names = ["BLACK / CHALK"]
		"passage": names = ["NARROWER","WIDER"]
		"suspension": names = ["SMOOTHER","ROUGHER"]
		"landscape": names = ["SHORTER","TALLER"]
		"garden": names = ["PHASE −","PHASE +"]
		"body": names = ["FOLD","UNFOLD"]
	names.append("RESET")
	if study == "tube": names.append_array(["FORM","SAG","NETWORK","PARTS","CABLES"])
	box(Vector3(0,0.52,console_z),Vector3(3.9,1.04,0.42))
	for i in names.size():
		var button := StudyButton.new(); button.name = "Control"+str(i)
		button.position = Vector3((i%4-1.5)*0.92,1.18-float(i/4)*0.23,console_z+0.24)
		button.collision_layer = (1 << 20) | (1 << 22); button.collision_mask = 0
		var shape := BoxShape3D.new(); shape.size = Vector3(0.86,0.19,0.08)
		var collision := CollisionShape3D.new(); collision.shape = shape; button.add_child(collision)
		var mesh := MeshInstance3D.new(); var cube := BoxMesh.new(); cube.size = shape.size; mesh.mesh = cube
		var mat := StandardMaterial3D.new(); mat.albedo_color = Color("b95981"); mesh.material_override = mat; button.add_child(mesh)
		var text := Label3D.new(); text.text = names[i]; text.font_size = 32; text.pixel_size = 0.0015
		text.position.z = 0.047; text.outline_size = 0; button.add_child(text)
		button.action = activate.bind(i); add_child(button); controls.append(button)
	status = Label3D.new(); status.font_size = 28; status.pixel_size = 0.002; status.outline_size = 0
	status.position = Vector3(0,1.62,console_z+0.24); status.modulate = Color("36333b"); add_child(status)
	status.text = "Change one relation. Keep the others."

func activate(index: int) -> void:
	var reset := index == controls.size()-1
	var changes_geometry := study in ["assembly","wall","passage","cut","open","landscape","garden","body","suspension"]
	if (study == "assembly" or study == "wall") and index == 3: changes_geometry = false
	if changes_geometry and not can_change(): return
	status.text = "Change one relation. Keep the others."
	match study:
		"tube":
			specimen.call("control",index)
			status.text = "Grab an end to continue. Pen trigger adds a new stroke. VIEW reveals the rings."
			if not specimen.return_message.is_empty(): status.text = specimen.return_message
		"paired_time":
			specimen.call("control",index)
			status.text = "Same rate keeps the gap. ALIGN keeps the rates."
		"tension":
			specimen.call("control",index)
			status.text = "Pull the pink handle. Release and watch what returns."
			if not specimen.return_message.is_empty(): status.text = specimen.return_message
		"network", "sentence", "witness":
			if study == "witness": specimen.return_message = ""
			specimen.call("control",index)
			status.text = {"network":"Read the highlighted record. Count only the selected relations.","sentence":"Keep the words. Change their duration.","witness":"Three museum cameras / one delayed frame / one held frame."}[study]
			if study == "witness" and not specimen.return_message.is_empty(): status.text = specimen.return_message
		"assembly":
			if reset: specimen.call("set_arrangement",0); specimen.call("set_colour_rule",0)
			elif index < 3: specimen.call("set_arrangement",index)
			else: specimen.call("set_colour_rule",(int(specimen.get("colour_rule"))+1)%3)
			status.text = "%s / %s" % [specimen.ARRANGEMENTS[specimen.arrangement],specimen.COLOUR_RULES[specimen.colour_rule]]
		"wall":
			if reset: specimen.call("reset")
			elif index == 0: specimen.call("set_spacing",0.21 if specimen.spacing < 0.2 else 0.11)
			elif index == 1: specimen.call("set_projection",0.52 if specimen.projection < 0.5 else 0.18)
			elif index == 2: specimen.call("set_omitted",not specimen.omitted)
			else: specimen.call("set_colour_rule",(int(specimen.colour_rule)+1)%3)
			var work_n := 9 if bool(specimen.get("gallery_bay")) else 3
			status.text = "%d studies / spacing %.2f m / depth %.2f m" % [work_n, specimen.spacing, specimen.projection]
		"signal":
			if reset: specimen.call("set_pattern",0,2026); specimen.call("inspect_rows",0)
			elif index < 3: specimen.call("set_pattern",index,int(specimen.seed_value))
			elif index == 3: specimen.call("set_pattern",int(specimen.mode),int(specimen.seed_value)+1)
			elif index == 4: specimen.call("step_rows",1)
			else: specimen.call("inspect_rows",(int(specimen.sample_row)+4)%253)
		"cut":
			if reset: specimen.call("set_cut_enabled",true); specimen.call("set_cut_x",0)
			elif index == 0: specimen.call("set_cut_enabled",not specimen.cut_enabled)
			else: specimen.call("set_cut_x",0.75 if specimen.cut_x < 0.5 else 0)
		"open":
			if reset: specimen.mode = 1; specimen.alternative = false
			elif index < 3: specimen.mode = index
			elif index == 3: specimen.alternative = not specimen.alternative
			else: specimen.mode = 4
			specimen.call("rebuild")
		"hinge":
			if reset:
				release_score.call("reset"); release_score.return_on_release = false
				tracing = false; trace_points.clear(); trace_mesh.mesh = null
			elif index == 0: selected_joint = (selected_joint+1)%start_pose.size()
			elif index in [1,2]:
				var angles: Array = specimen.call("hinge_angles")
				release_score.call("turn",selected_joint,float(angles[selected_joint])+(-12.0 if index == 1 else 12.0))
			elif index == 3: release_score.return_on_release = not release_score.return_on_release
			elif index == 4: release_score.call("release")
			else: tracing = not tracing
			status.text = "Joint %d / %s / trace %s" % [selected_joint+1,"RETURN" if release_score.return_on_release else "KEEP", "ON" if tracing else "OFF"]
		"pink":
			if reset: specimen.call("set_lights",1); specimen.call("set_pink_material",false)
			elif index < 5: specimen.call("set_lights",int(specimen.mask) ^ (1 << index))
			else: specimen.call("set_pink_material",not specimen.pink_material)
			status.text = "Mask %d / %s" % [specimen.mask,"pink surface" if specimen.pink_material else "pink light"]
		"void":
			specimen.call("set_black_surface",true if reset else not specimen._black_surface)
			status.text = "Unlit black cavity" if specimen._black_surface else "Lit chalk cavity / same geometry"
		_:
			specimen.call("set_amount",1.0 if reset else clampf(float(specimen.amount)+(-0.25 if index == 0 else 0.25),0,1))
			status.text = "Amount %.2f" % specimen.amount

func _process(delta: float) -> void:
	phase += delta
	if release_score:
		release_score.call("advance",delta)
		if tracing:
			var plate: Node3D = specimen.find_child("Plate_5",true,false)
			if plate:
				var at := to_local(plate.to_global(Vector3(0.25,0,0.17)))
				if trace_points.is_empty() or at.distance_to(trace_points[-1]) > 0.008:
					trace_points.append(at)
					if trace_points.size() > 512: trace_points.remove_at(0)
					if trace_points.size() > 1:
						var mesh := ImmediateMesh.new(); mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
						for point in trace_points: mesh.surface_add_vertex(point)
						mesh.surface_end(); trace_mesh.mesh = mesh
						var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
						mat.albedo_color = Color("f15d9b"); trace_mesh.material_override = mat
