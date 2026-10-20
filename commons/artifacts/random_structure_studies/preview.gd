extends Node3D
const Study=preload("random_structure_study.gd")
var baseline: Node3D
var variant: Node3D
var camera: Camera3D
var status: Label
var range_slider: HSlider
var yaw:=0.0
var pitch:=0.28
var distance:=4.5

func _ready() -> void:
	var world:=WorldEnvironment.new();world.environment=Environment.new()
	world.environment.background_mode=Environment.BG_COLOR
	world.environment.background_color=Color("263137")
	world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color=Color("c5d9de");world.environment.ambient_light_energy=0.7
	add_child(world)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-35,0);light.light_energy=1.2;light.shadow_enabled=true;add_child(light)
	var floor:=MeshInstance3D.new();var mesh:=PlaneMesh.new();mesh.size=Vector2(30,30);floor.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("344046");mat.roughness=0.9;floor.material_override=mat;add_child(floor)
	baseline=Node3D.new();baseline.set_script(Study);baseline.name="Baseline";baseline.position.x=-1.08;baseline.show_controls=false;baseline.variation=0;add_child(baseline)
	variant=Node3D.new();variant.set_script(Study);variant.name="Variant";variant.position.x=1.08;add_child(variant)
	camera=Camera3D.new();camera.fov=52;camera.current=true;add_child(camera);place_camera()
	var ui:=CanvasLayer.new();add_child(ui)
	var panel:=VBoxContainer.new();panel.position=Vector2(24,18);ui.add_child(panel)
	var modes:=HBoxContainer.new();panel.add_child(modes)
	for kind in Study.Model.KINDS:
		var button:=Button.new();button.text=kind.capitalize();button.custom_minimum_size=Vector2(130,42)
		modes.add_child(button);button.pressed.connect(select.bind(kind))
	var controls:=HBoxContainer.new();panel.add_child(controls)
	for pair in [["Seed +1",variant.next_seed],["Target / links",variant.cycle_target],["KEEP",variant.keep],["REPLAY",variant.replay_saved]]:
		var button:=Button.new();button.text=pair[0];button.custom_minimum_size=Vector2(130,40);controls.add_child(button);button.pressed.connect(pair[1])
	range_slider=HSlider.new();range_slider.custom_minimum_size=Vector2(240,40);range_slider.min_value=0;range_slider.max_value=1;range_slider.step=0.05;range_slider.value=1
	controls.add_child(range_slider);range_slider.value_changed.connect(variant.set_variation)
	status=Label.new();status.add_theme_color_override("font_color",Color("e1eee9"));panel.add_child(status)
	variant.changed.connect(sync_baseline)
	sync_baseline()

func select(kind: String) -> void: variant.set_kind(kind)

func sync_baseline() -> void:
	baseline.structure_kind=variant.structure_kind
	var record: Dictionary=variant.capture();record.variation=0.0
	baseline.restore(record)
	baseline.note="Zero range | same retained draw record";baseline.redraw()
	range_slider.set_value_no_signal(variant.variation)
	status.text="LEFT: zero range    RIGHT: range %.2f    Seed %d    |    Drag empty space to orbit; wheel to zoom" % [variant.variation,variant.study_seed]

func place_camera() -> void:
	var target:=Vector3(0,1.24,0.05)
	camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		yaw-=event.relative.x*0.008;pitch=clampf(pitch+event.relative.y*0.006,0.08,1.2);place_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: distance=maxf(2.5,distance-0.3)
		elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: distance=minf(9,distance+0.3)
		place_camera()
