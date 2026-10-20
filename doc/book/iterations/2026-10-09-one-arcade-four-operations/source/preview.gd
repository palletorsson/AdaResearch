extends Node3D
var work: Node3D

func _ready() -> void:
	var world:=WorldEnvironment.new();world.name="CourtyardEnvironment";var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("81949d")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("dce7ea");env.ambient_light_energy=.20
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=.60
	world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-38,-35,0);sun.light_color=Color("ffedca");sun.light_energy=.23;sun.shadow_enabled=true;sun.directional_shadow_max_distance=70;add_child(sun)
	work=preload("res://commons/artifacts/architecture_variations/architecture_variations.tscn").instantiate();add_child(work)
	var p=work.panel
	p.box(self,Vector3(0,-.2,-4),Vector3(48,.4,46),Color("bebcaf"),true)
	p.box(self,Vector3(0,6,-25),Vector3(48,12,.4),Color("dcd8c9"),true)
	for x in [-24,24]:p.box(self,Vector3(x,6,-4),Vector3(.4,12,46),Color("dad9cf"),true)
	for x in range(-24,25,2):p.box(self,Vector3(x,.005,-4),Vector3(.014,.01,46),Color("a5a89e"))
	for z in range(-26,19,2):p.box(self,Vector3(0,.005,z),Vector3(48,.01,.014),Color("a5a89e"))
	p.text(self,"ENDLESS MUSEUM",Vector3(0,10,-24.74),.012,Color("263337"))
	p.text(self,"always another room",Vector3(0,9.15,-24.73),.0045,Color("526063"))
	p.text(self,"BODIES / BUILDINGS / THEIR ATTACHMENTS",Vector3(0,7.5,-24.72),.005,Color("263337"))
	# Human-scale witnesses make height and repetition legible.
	for at in [Vector3(-8,0,4),Vector3(5,0,4),Vector3(12,0,-12)]:
		var trunk:=MeshInstance3D.new();var capsule:=CapsuleMesh.new();capsule.radius=.18;capsule.height=1.2;trunk.mesh=capsule;trunk.position=at+Vector3(0,1,0);trunk.material_override=p.material(Color("303a3d"));add_child(trunk)
		var head:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.12;ball.height=.24;head.mesh=ball;head.position=at+Vector3(0,1.73,0);head.material_override=trunk.material_override;add_child(head)
		for dx in [-.105,.105]:p.box(self,at+Vector3(dx,.33,0),Vector3(.12,.66,.15),Color("303a3d"))
	if not OS.get_cmdline_user_args().has("--capture-variations"):
		spawn_viewer()

func spawn_viewer() -> CharacterBody3D:
	var player=load("res://commons/scenes/desktop_player.tscn").instantiate()
	# Keep the authored daylight in this spatial review room. The shared rig's
	# carried light otherwise adds dense fog, concealing large architecture.
	var lamp=player.get_node("Head/PlayerHeldLight")
	lamp.darken_environment=false;lamp.light_energy=0;lamp.flicker_amount=0
	player.position=Vector3(0,.03,11);add_child(player)
	return player
