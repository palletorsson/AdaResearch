extends "res://commons/artifacts/wall_health_station/wall_health_station.gd"
## Mains-powered body servicing. Reuses the museum's clamped transfer
## and real XRTools button; the Void owns charge, shutdown and sight recovery.
const Rack := preload("res://commons/audio/rack_templates/RackTemplates.gd")
const Supply := preload("res://commons/void/hardware_supply.gd")
const Ink := preload("res://commons/utils/baked_text_albedo.gd")
var world: Node3D
var charge_button: Area3D
var isolation_button: Area3D
var powered := true
var charging := false
var status_lamp: MeshInstance3D
var _tick := 0.0
var _displayed := ""

func _ready() -> void:
	var ancestor := get_parent()
	while ancestor != null:
		if "ready_for_play" in ancestor:
			world = ancestor
			break
		ancestor = ancestor.get_parent()
	rate_per_sec = 8.0
	reach_m = 1.5
	_build()
	Supply.connect_unit(self,Vector3(0,2.12,-0.16))
	_refresh()

func _build() -> void:
	var cream := _mat(Color("e5e0cf"),0.84)
	var dark := _mat(Color("30332f"),0.8)
	var steel := _mat(Color("777c72"),0.65)
	# A cabinet bolted to a wall plate, with a visible rear mounting gap.
	_box("WallPlate",Vector3(0,1.42,-0.12),Vector3(0.84,1.5,0.08),steel,true)
	for y in [0.85,1.98]:
		_box("WallBracket",Vector3(0,y,-0.02),Vector3(0.72,0.08,0.26),dark)
		for x in [-0.36,0.36]:
			_box("AnchorBolt",Vector3(x,y,-0.066),Vector3(0.045,0.045,0.02),dark)
	_box("Cabinet",Vector3(0,1.42,0.06),Vector3(0.74,1.26,0.32),cream,true)
	_box("Face",Vector3(0,1.42,0.226),Vector3(0.69,1.2,0.018),cream)
	_box("InputGland",Vector3(0,2.1,-0.16),Vector3(0.14,0.14,0.14),dark)
	for i in range(9):
		_box("Vent",Vector3(-0.23+i*0.058,0.94,0.24),Vector3(0.028,0.13,0.008),dark)
	_mark("CARE UNIT / MODEL B",Vector3(0,1.96,0.24),Vector2(0.62,0.07))
	_mark("BODY CHARGER  /  01",Vector3(0,1.87,0.24),Vector2(0.55,0.05))
	_readout = TextScreenScript.new()
	_readout.name = "BodyReadout"
	_readout.mode = 0
	_readout.width_m = 0.56
	_readout.title = "BODY CHARGE"
	_readout.title_color = Color("dcd4b5")
	_readout.body_color = Color("ebede1")
	_readout.frame_color = Color("393c36")
	_readout.bg_color = Color("181e18")
	_readout.position = Vector3(0,1.6,0.247)
	add_child(_readout)
	charge_button = _button("Charge",Vector3(-0.16,1.25,0.28),Color("d8c48d"))
	isolation_button = _button("Isolate",Vector3(0.17,1.25,0.28),Color("797e70"))
	isolation_button.button_pressed.connect(func(_button): powered = not powered; _refresh())
	charge_button.button_pressed.connect(func(_button): _refresh())
	charge_button.button_released.connect(func(_button): charging = false; _refresh())
	_mark("HOLD / CHARGE",Vector3(-0.16,1.12,0.24),Vector2(0.29,0.05))
	_mark("MAINS ON / OFF",Vector3(0.17,1.12,0.24),Vector2(0.29,0.05))
	status_lamp = _box("GridIndicator",Vector3(-0.28,2.02,0.241),Vector3(0.055,0.016,0.01),_mat(Color("99a67d"),0.7))
	_mark("GRID",Vector3(-0.18,2.02,0.241),Vector2(0.10,0.035))

func _box(title: String, at: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = mat
	add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		mesh.add_child(body)
		body.add_child(shape)
	return mesh

func _mark(words: String, at: Vector3, size: Vector2) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "SurfaceMark"
	var quad := QuadMesh.new()
	quad.size = size
	mesh.mesh = quad
	mesh.position = at
	var mat := _mat(Color.WHITE,1.0)
	var height := maxi(64,roundi(1024*size.y/size.x))
	var font_size := mini(roundi(height*0.78),roundi(1024.0/(words.length()*0.62)))
	mat.albedo_texture = Ink.generate_text_image(words,Color("30332f"),Vector2i(1024,height),font_size,"medium")
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)

func _button(title: String, at: Vector3, colour: Color) -> Area3D:
	var button: Node3D = preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name = title
	Rack.make_button_rectangular(button)
	# Scale the existing meshes and touch volume together, retaining their
	# press depth, release ownership and controller haptic callbacks.
	button.scale = Vector3.ONE*2.0
	button.position = at
	button.released_color = colour
	button.pressed_color = Color("d98b3f")
	button.released_emission_energy = 0.02
	button.pressed_emission_energy = 0.25
	button.get_node("ButtonBase/BaseMesh").hide()
	add_child(button)
	var cap: StandardMaterial3D = button.get_node("Button/ButtonMesh").get_active_material(0)
	cap.metallic = 0.0
	cap.roughness = 0.85
	return button.get_node("InteractableAreaButton") as Area3D

func _health_node() -> Node:
	return world.health if is_instance_valid(world) and is_instance_valid(world.health) else null

func in_reach() -> bool:
	if world == null or not world.ready_for_play or world.recovering or world.returning: return false
	if world.health.suspended or not is_visible_in_tree(): return false
	var local := to_local(world.camera.global_position)
	return local.z>0.22 and local.z<reach_m and absf(local.x)<0.85 and local.y>0.5 and local.y<2.7

func draw_from(want: float) -> float:
	if not powered or not charge_button.pressed or not in_reach(): return 0.0
	# Reuse the museum's actual-delivery/clamping logic, fed by mains.
	# The museum transfer contract addresses the one body-charge resource.
	charge = 100.0
	_spent = false
	return super(want)

func _process(delta: float) -> void:
	_tick += delta
	if _tick<0.25: return
	var elapsed := minf(_tick,0.3)
	_tick = 0.0
	var hp := _health_node()
	charging = hp != null and powered and charge_button.pressed and in_reach() and hp.get_health()<hp.max_player_health
	if charging: draw_from(rate_per_sec*elapsed)
	_refresh()

func _face() -> String:
	var hp := _health_node()
	var amount := "--" if hp == null else "%d%%"%roundi(hp.get_health()/hp.max_player_health*100)
	var state := "HOLD TO CHARGE"
	if not powered: state = "MAINS OFF"
	elif hp == null: state = "NO BODY CONNECTED"
	elif hp.get_health()>=hp.max_player_health: state = "FULL"
	elif not in_reach(): state = "STEP CLOSER"
	elif charging: state = "CHARGING"
	return amount+"\n"+state

func _refresh() -> void:
	if _readout == null: return
	var words := _face()
	if words != _displayed:
		_displayed = words
		_readout.body = words
	if status_lamp != null:
		status_lamp.material_override.albedo_color = Color("99ad79") if powered else Color("484b41")
