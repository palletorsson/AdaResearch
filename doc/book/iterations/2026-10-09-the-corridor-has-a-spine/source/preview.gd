extends Node3D
## A separate research room; existing game halls and player movement are unchanged.
var work:Node3D

func _ready() -> void:
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("667b87")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("d2dce4");env.ambient_light_energy=.25
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=.65
	world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-25,0);sun.light_color=Color("fff2da");sun.light_energy=.28;sun.shadow_enabled=true;add_child(sun)
	work=preload("res://commons/artifacts/architecture_spine/architecture_spine.tscn").instantiate();add_child(work)
	var p=work.panel
	p.box(self,Vector3(0,-.15,0),Vector3(24,.30,23),Color("cfcdc5"),true)
	p.box(self,Vector3(0,8,-8),Vector3(24,16,.30),Color("e6e0d3"),true)
	for x in [-12,12]:p.box(self,Vector3(x,8,0),Vector3(.3,16,23),Color("deddd6"),true)
	for x in [-8,-4,0,4,8]:p.box(self,Vector3(x,8,-7.75),Vector3(.2,16,.40),Color("bfbdb5"))
	p.text(self,"ENDLESS MUSEUM",Vector3(0,14.15,-7.5),.0080,Color("293840"))
	p.text(self,"always another room",Vector3(0,13.6,-7.49),.0030,Color("536069"))
	p.text(self,"THE CORRIDOR HAS A SPINE",Vector3(0,12.6,-7.47),.0048,Color("293840"))
	p.text(self,"Move the centre. What still joins?",Vector3(0,12.0,-7.46),.0025,Color("536069"))
	# A fixed low rail distinguishes this study from a tested walkable route.
	for x in [-6.5,6.5]:p.box(self,Vector3(x,.66,2.48),Vector3(.05,.95,.05),Color("3e484e"),true)
	p.box(self,Vector3(0,1.12,2.48),Vector3(13,.045,.045),Color("3e484e"),true)
	if not OS.get_cmdline_user_args().has("--capture-architecture"):
		var player=load("res://commons/scenes/desktop_player.tscn").instantiate();player.position=Vector3(0,.03,5.9);add_child(player)
