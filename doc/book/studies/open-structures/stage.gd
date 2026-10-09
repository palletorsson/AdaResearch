extends Node3D
## Borrowed apparatus: lighting, orbit camera and controls. No XR player.
@onready var structures: Node3D=$Structures
var camera: Camera3D
var panel: CanvasLayer
var description: Label
var rule_button: Button
var yaw := .45
var pitch := .45
var distance := 13.0
var target := Vector3(0,.3,0)
var orbiting := false

func _ready() -> void:
	var world:=WorldEnvironment.new();var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color(.87,.88,.86)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(.85,.88,.94);environment.ambient_light_energy=.23
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=environment;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_color=Color(1,.985,.95);sun.light_energy=.75;sun.shadow_enabled=true
	sun.directional_shadow_max_distance=40;add_child(sun)
	room_box(Vector3(0,-.12,0),Vector3(36,.2,28),Color(.27,.26,.23))
	room_box(Vector3(0,3.5,-7),Vector3(36,7,.2),Color(.91,.9,.86))
	room_box(Vector3(-12,3.5,0),Vector3(.2,7,28),Color(.91,.9,.86))
	# Floor seams make scale and shadow easier to follow without mimicking the photo.
	for x in range(-18,19,2):room_box(Vector3(x,-.015,0),Vector3(.007,.002,28),Color(.28,.28,.25))
	for z in range(-14,15,2):room_box(Vector3(0,-.015,z),Vector3(36,.002,.007),Color(.28,.28,.25))
	camera=Camera3D.new();camera.fov=48;add_child(camera);camera.current=true;update_camera()
	make_controls();select_mode(0)

func room_box(at: Vector3,size: Vector3,colour: Color) -> void:
	var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size
	mesh.mesh=box;mesh.position=at;var material:=StandardMaterial3D.new()
	material.albedo_color=colour;material.roughness=.85;mesh.material_override=material;add_child(mesh)

func update_camera() -> void:
	camera.look_at_from_position(target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance,target)

func make_controls() -> void:
	panel=CanvasLayer.new();add_child(panel)
	var base:=PanelContainer.new();base.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	base.offset_top=-135;base.offset_left=28;base.offset_right=-28;base.offset_bottom=-20;panel.add_child(base)
	var box:=VBoxContainer.new();base.add_child(box)
	var row:=HBoxContainer.new();box.add_child(row)
	for i in 4:
		var button:=Button.new();button.text=["1  Five forms","2  Twenty-five places","3  Stacked modules","4  Between the forms"][i]
		button.pressed.connect(select_mode.bind(i));row.add_child(button)
	rule_button=Button.new();rule_button.text="Change array rule";rule_button.pressed.connect(change_rule);row.add_child(rule_button)
	var reset:=Button.new();reset.text="Reset view";reset.pressed.connect(select_mode.bind(-1));row.add_child(reset)
	description=Label.new();description.add_theme_font_size_override("font_size",17);box.add_child(description)
	var reveal:=HSlider.new();reveal.min_value=0;reveal.max_value=1;reveal.step=.01;reveal.value=1
	reveal.value_changed.connect(structures.set_reveal);reveal.tooltip_text="Reveal the bars in construction order";box.add_child(reveal)
	var hint:=Label.new();hint.text="Right-drag: orbit   Wheel: distance   Slider: reveal bars   These are Ada studies after LeWitt, not certified replicas."
	hint.add_theme_font_size_override("font_size",14);box.add_child(hint)

func select_mode(which: int) -> void:
	if which>=0:structures.mode=which
	structures.rebuild();yaw=.2;pitch=.28;distance=10.5;target=Vector3(0,.45,0)
	if structures.mode==1:yaw=.45;pitch=.64;distance=13.5
	if structures.mode==2:yaw=.42;pitch=.58;distance=11.8
	if structures.mode==3:pitch=.36;distance=14
	update_camera();update_description()

func change_rule() -> void:
	structures.alternative=not structures.alternative
	structures.rebuild();update_description()

func update_description() -> void:
	rule_button.disabled=structures.mode not in [1,2]
	description.text=["Eight addresses, twelve connections; collapse the top and some become the same point.",
		"form = column" if structures.alternative else "form = (column + row) % 5",
		"Full square footprint; same five height rules" if structures.alternative else "Cross footprint; five height rules, all bounded by five",
		"Only the top fraction changes: 0, 1/6, 2/6, 3/6, 4/6, 5/6, 1. The names were a selection."][structures.mode]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_RIGHT:orbiting=event.pressed
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance=clampf(distance+(-.6 if event.button_index==MOUSE_BUTTON_WHEEL_UP else .6),3,25);update_camera()
	if event is InputEventMouseMotion and orbiting:
		yaw-=event.relative.x*.006;pitch=clampf(pitch+event.relative.y*.004,.08,1.4);update_camera()
