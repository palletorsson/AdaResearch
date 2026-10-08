extends "res://commons/artifacts/colour_assembly/study.gd"
## Reuses the companion's desktop walker; all wall arrangements are independent.
func _ready() -> void:
	_build_gallery()
	work = load("res://commons/artifacts/colour_wall_studies/colour_wall_studies.tscn").instantiate()
	add_child(work)
	camera = Camera3D.new()
	add_child(camera)
	set_view(0)
	_build_walker()
	_build_controls()
	_update_status()

func _build_gallery() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("e6e3dc")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f1eff3")
	env.ambient_light_energy = 0.48
	world.environment = env
	add_child(world)
	var wall := _material(Color("eeece7"),0.92)
	var floor_mat := _material(Color("aba59c"),0.65)
	_box("Floor",Vector3(20,0.2,14),Vector3(0,-0.1,2.5),floor_mat,true)
	_box("BackWall",Vector3(20,5.8,0.25),Vector3(0,2.9,-4.25),wall,true)
	for side in [-1,1]:
		_box("SideWall",Vector3(0.25,5.8,14),Vector3(side*9.9,2.9,2.5),wall,true)
	_box("Ceiling",Vector3(20,0.20,14),Vector3(0,5.8,2.5),wall,true)
	var lamp_mat := _material(Color("fff4df"),0.5)
	lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for x in [-5.8,0.0,5.8]:
		var spot := SpotLight3D.new()
		add_child(spot)
		spot.position = Vector3(x-1.45,4.95,0.2)
		spot.look_at(Vector3(x,2.35,-4.0))
		spot.light_color = Color("fff2e4")
		spot.light_energy = 0.70
		spot.spot_range = 13
		spot.spot_angle = 46
		spot.spot_attenuation = 0.45
		spot.shadow_enabled = true
		spot.shadow_bias = 0.15
		spot.shadow_normal_bias = 1.0
		var lamp := _box("CeilingLight",Vector3(0.6,0.05,0.22),Vector3(x-1.45,5.65,0.2),lamp_mat,false)
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bench := _material(Color("3d4247"),0.7)
	_box("Bench",Vector3(3.8,0.12,0.65),Vector3(0,0.48,3.1),bench,true)
	for x in [-1.55,1.55]: _box("BenchLeg",Vector3(0.12,0.42,0.5),Vector3(x,0.21,3.1),wall,true)

func _build_controls() -> void:
	overlay = CanvasLayer.new()
	add_child(overlay)
	var backing := PanelContainer.new()
	backing.position = Vector2(18,18)
	overlay.add_child(backing)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	backing.add_child(column)
	for row in [["Tight intervals","Open intervals"],["Shallow crossing","Deep crossing"],["Omit one rail","Restore rail"],["Sequence","Groups","All pink"],["Whole wall","Intervals","Crossings","Open line"],["Oblique","Walk","Reset"]]:
		var line := HBoxContainer.new()
		column.add_child(line)
		for title in row:
			var button := Button.new()
			button.text = title
			button.custom_minimum_size = Vector2(156,34)
			button.pressed.connect(choose.bind(title))
			line.add_child(button)
			buttons[title] = button
	status = Label.new()
	status.add_theme_font_size_override("font_size",14)
	column.add_child(status)

func choose(title: String) -> void:
	if walking and walker.position.z < -2.8 and title in ["Tight intervals","Open intervals","Shallow crossing","Deep crossing","Restore rail"]:
		status.text = "Step back from the wall before changing its structure."
		return
	match title:
		"Tight intervals": work.set_spacing(0.11)
		"Open intervals": work.set_spacing(0.21)
		"Shallow crossing": work.set_projection(0.18)
		"Deep crossing": work.set_projection(0.52)
		"Omit one rail": work.set_omitted(true)
		"Restore rail": work.set_omitted(false)
		"Sequence": work.set_colour_rule(0)
		"Groups": work.set_colour_rule(1)
		"All pink": work.set_colour_rule(2)
		"Whole wall": set_view(0)
		"Intervals": set_view(1)
		"Crossings": set_view(2)
		"Open line": set_view(3)
		"Oblique": set_view(4)
		"Walk": start_walk()
		"Reset":
			work.reset()
			set_view(0)
	_update_status()

func _update_status() -> void:
	status.text = "Spacing %.2f m  ·  crossing depth %.2f m\n%s" % [work.spacing,work.projection,
		"WASD + mouse · Esc releases pointer" if walking else "Change one rule; keep the view."]

func set_view(index: int) -> void:
	walking = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var views := [[Vector3(0,2.5,8.8),Vector3(0,2.25,-4)],
		[Vector3(-5.8,2.35,1.3),Vector3(-5.8,2.35,-3.85)],
		[Vector3(0,2.35,0.3),Vector3(0,2.35,-3.85)],
		[Vector3(5.8,2.35,0.9),Vector3(5.8,2.35,-3.85)],
		[Vector3(2.8,2.65,-0.6),Vector3(0,2.35,-3.65)]]
	camera.fov = 64 if index == 0 else 52
	camera.position = views[index][0]
	camera.look_at(views[index][1])
	camera.make_current()
