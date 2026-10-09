extends Node3D
## A desktop study using the production artifact's exact geometry and setter.
const Specimen = preload("res://commons/artifacts/bicho_hinge/bicho_hinge.gd")
const Score = preload("res://score.gd")
var specimen
var score = Score.new()
var camera: Camera3D
var panel: CanvasLayer
var slider: HSlider
var joint_select: OptionButton
var readout: Label
var policy_label: Label
var keep_button: Button
var return_button: Button
var trace_button: CheckButton
var trace_mesh: MeshInstance3D
var trace_points := PackedVector3Array()
var tracing := false
var selected := 0
var yaw := 0.52
var pitch := 0.20
var distance := 3.1
var orbiting := false
var dragging := false
var drag_plane: Plane
var witness: MeshInstance3D
var sheets: Array[MeshInstance3D] = []
var materials: Array[Material] = []
var pink: StandardMaterial3D
var tip_plate: Node3D
var initial_tip := Vector3.ZERO

class PointerSample extends RefCounted:
	var event_type := 0
	var position := Vector3.ZERO

func _ready() -> void:
	make_room()
	specimen = Specimen.new()
	specimen.show_caption = false
	specimen.plate_w = 0.50
	specimen.name = "Specimen"
	add_child(specimen)
	score.setup(specimen)
	for node in specimen.find_children("Sheet", "MeshInstance3D", true, false):
		sheets.append(node)
		# Neutral study finish: retain the canonical mesh, show its planes clearly.
		node.material_override = surface(Color(0.87,0.89,0.91), 0.44, 1.0)
		materials.append(node.material_override)
	pink = surface(Color(0.86,0.20,0.35), 0.64, 0.0)
	tip_plate = specimen.find_child("Plate_5", true, false)
	initial_tip = tip()
	witness = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.012
	sphere.height = 0.024
	witness.mesh = sphere
	witness.material_override = surface(Color(0.96,0.16,0.35))
	add_child(witness)
	witness.visible = false
	trace_mesh = MeshInstance3D.new()
	trace_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trace_mesh)
	var trace_mat := StandardMaterial3D.new()
	trace_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trace_mat.albedo_color = Color(0.96,0.16,0.35)
	trace_mesh.material_override = trace_mat
	camera = Camera3D.new()
	camera.fov = 43
	add_child(camera)
	camera.current = true
	update_camera()
	make_ui()
	select_joint(0)

func surface(colour: Color, roughness: float = 0.8, metal: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	material.metallic = metal
	return material

func box(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = material
	add_child(instance)

func make_room() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.40,0.49,0.62)
	sky_mat.sky_horizon_color = Color(0.93,0.91,0.87)
	sky_mat.ground_bottom_color = Color(0.65,0.62,0.57)
	sky_mat.ground_horizon_color = Color(0.81,0.79,0.75)
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.87,0.85,0.81)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_energy = 0.9
	world.environment = env
	add_child(world)
	box(Vector3(0,-0.08,0), Vector3(10,0.16,10), surface(Color(0.60,0.57,0.52)))
	box(Vector3(0,2,-2.3), Vector3(10,4,0.15), surface(Color(0.83,0.82,0.78)))
	box(Vector3(-3,2,0), Vector3(0.15,4,5), surface(Color(0.76,0.74,0.69)))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-46,-32,0)
	sun.light_color = Color(1.0,0.92,0.81)
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1.5,2.5,2)
	fill.light_color = Color(0.75,0.82,1.0)
	fill.light_energy = 0.8
	fill.omni_range = 5
	add_child(fill)

func make_ui() -> void:
	panel = CanvasLayer.new()
	add_child(panel)
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	base.offset_left = -395
	base.offset_right = -25
	base.offset_top = 25
	base.offset_bottom = 800
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.97,0.95,0.91,0.97)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	base.add_theme_stylebox_override("panel",style)
	base.add_theme_color_override("font_color",Color(0.12,0.13,0.14))
	panel.add_child(base)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation",16)
	base.add_child(v)
	label(v,"ADA / STUDY 01",14)
	label(v,"A pose left",32)
	label(v,"After Lygia Clark’s Bichos.\nSix plates. Five hinges.\nNo single finished shape.",19)
	label(v,"01 / TURN ONE JOINT",14)
	joint_select = OptionButton.new()
	for i in 5:
		joint_select.add_item("Joint %d" % (i+1))
	joint_select.item_selected.connect(select_joint)
	v.add_child(joint_select)
	slider = HSlider.new()
	slider.step = 0.1
	slider.custom_minimum_size.y = 35
	slider.value_changed.connect(turn_selected)
	slider.drag_started.connect(func(): score.returning = false)
	slider.drag_ended.connect(func(_changed: bool): score.release())
	v.add_child(slider)
	readout = label(v,"",16)
	label(v,"02 / AFTER YOU LET GO",14)
	keep_button = button(v,"Leave it",func(): set_policy(false))
	return_button = button(v,"Return it",func(): set_policy(true))
	policy_label = label(v,"",17)
	button(v,"Release",score.release)
	trace_button = CheckButton.new()
	trace_button.text = "Follow one corner"
	trace_button.add_theme_color_override("font_color",Color(0.12,0.13,0.14))
	trace_button.toggled.connect(set_trace)
	v.add_child(trace_button)
	button(v,"Clear the path",clear_trace)
	button(v,"Start again",reset)
	label(v,"Drag a plate or use the slider.\nRight-drag to look around. Scroll to zoom.\nH hides controls; V changes view.",14)
	label(v,"Desktop kinematics. Fixed base.\nContact and weight are not solved.",13)
	set_policy(false)

func label(parent: Node, text: String, size: int) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",size)
	node.add_theme_color_override("font_color",Color(0.15,0.16,0.17))
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 35
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func select_joint(index: int) -> void:
	selected = index
	joint_select.select(index)
	var limits: Array = specimen.get("_limits")
	var band: Vector2 = limits[index]
	slider.min_value = band.x
	slider.max_value = band.y
	slider.set_value_no_signal(float(specimen.hinge_angles()[index]))
	for i in sheets.size():
		sheets[i].material_override = pink if sheets[i].get_parent().name == "Plate_%d" % (index+1) else materials[i]
	update_readout()

func turn_selected(value: float) -> void:
	score.turn(selected,value)
	update_readout()
	record_tip()

func set_policy(restore: bool) -> void:
	score.return_on_release = restore
	score.returning = false
	policy_label.text = "Your last pose remains." if not restore else "Release restores the starting angles."
	keep_button.disabled = not restore
	return_button.disabled = restore

func update_readout() -> void:
	var angles: Array = specimen.hinge_angles()
	readout.text = "Joint %d  /  %.1f°\nStop: %.0f° to %.0f°" % [selected+1,float(angles[selected]),slider.min_value,slider.max_value]
	slider.set_value_no_signal(float(angles[selected]))

func _process(delta: float) -> void:
	var was_returning: bool = score.returning
	score.advance(delta)
	if was_returning:
		update_readout()
		record_tip()
	if witness:
		witness.position = tip()

func tip() -> Vector3:
	return tip_plate.to_global(Vector3(specimen.plate_w * 0.5,0,specimen.plate_w * specimen.DEPTH_RATIO))

func set_trace(enabled: bool) -> void:
	tracing = enabled
	witness.visible = enabled
	trace_mesh.visible = enabled
	record_tip()

func clear_trace() -> void:
	trace_points.clear()
	trace_mesh.mesh = null
	record_tip()

func record_tip() -> void:
	if witness:
		witness.position = tip()
	if not tracing:
		return
	var at := tip()
	if trace_points.size() and at.distance_to(trace_points[-1]) < 0.003:
		return
	trace_points.append(at)
	if trace_points.size() > 1200:
		trace_points.remove_at(0)
	if trace_points.size() < 2:
		return
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,trace_points.size()):
		var a := trace_points[i-1]
		var b := trace_points[i]
		var axis := (b-a).normalized()
		var u := axis.cross(Vector3.UP if absf(axis.y)<0.95 else Vector3.RIGHT).normalized()*0.0025
		var v := axis.cross(u)
		for side in 6:
			var q := u*cos(TAU*side/6)+v*sin(TAU*side/6)
			var r := u*cos(TAU*(side+1)/6)+v*sin(TAU*(side+1)/6)
			for vertex in [a+q,b+q,a+r,a+r,b+q,b+r]:
				mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	trace_mesh.mesh = mesh

func reset() -> void:
	score.reset()
	clear_trace()
	update_readout()

func update_camera() -> void:
	var target := Vector3(0,1.05,0)
	var offset := Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at_from_position(target+offset,target)

func sample(kind: int, point: Vector3) -> void:
	var event := PointerSample.new()
	event.event_type = kind
	event.position = point
	specimen.pointer_event(event)

func mouse_ray(at: Vector2) -> Dictionary:
	var origin := camera.project_ray_origin(at)
	var direction := camera.project_ray_normal(at)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*20,1)
	return get_world_3d().direct_space_state.intersect_ray(query)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H:
			panel.visible = not panel.visible
		elif event.keycode == KEY_V:
			yaw += PI/2
			update_camera()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			orbiting = event.pressed
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 0.15),1.4,5.0)
			update_camera()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var hit := mouse_ray(event.position)
				if not hit.is_empty() and specimen.is_ancestor_of(hit.collider) and str(hit.collider.get_parent().name).begins_with("Plate_"):
					score.returning = false
					sample(2,hit.position)
					selected = int(specimen.get("_drag"))
					if selected >= 0:
						select_joint(selected)
						var mount: Node3D = specimen.get("_mounts")[selected]
						drag_plane = Plane(mount.global_basis.x.normalized(),mount.global_position)
						dragging = true
			else:
				release_drag()
	if event is InputEventMouseMotion:
		if orbiting:
			yaw -= event.relative.x*0.006
			pitch = clampf(pitch+event.relative.y*0.006,-0.15,0.85)
			update_camera()
		elif dragging:
			var point = drag_plane.intersects_ray(camera.project_ray_origin(event.position),camera.project_ray_normal(event.position))
			if point != null:
				sample(4,point)
				update_readout()
				record_tip()

func _input(event: InputEvent) -> void:
	# GUI may consume release after a plate drag ends over the control panel.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and dragging:
		release_drag()

func release_drag() -> void:
	if dragging:
		sample(3,Vector3.ZERO)
		dragging = false
		score.release()
