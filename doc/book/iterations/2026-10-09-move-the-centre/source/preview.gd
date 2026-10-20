extends Node3D
## F6 review room using the real artifact and the project's desktop player.
## The registered artifact itself owns no world environment or camera.
var work: Node3D
func _ready() -> void:
	var world:=WorldEnvironment.new()
	var environment:=Environment.new()
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("738590")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("cad9e2");environment.ambient_light_energy=.25
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.tonemap_exposure=.65
	world.environment=environment;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0);sun.light_color=Color("fff0db");sun.light_energy=.28;sun.shadow_enabled=true;add_child(sun)
	work=load("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/omoss.tscn").instantiate();add_child(work)
	var panel=work.panel
	panel.box(self,Vector3(0,-.13,0),Vector3(10,.26,12),Color("d6d3cc"),true)
	panel.box(self,Vector3(-5,2.9,0),Vector3(.22,5.8,12),Color("deddd5"),true)
	panel.box(self,Vector3(5,2.9,0),Vector3(.22,5.8,12),Color("deddd5"),true)
	panel.box(self,Vector3(0,2.9,-5),Vector3(10,5.8,.25),Color("e8e4da"),true)
	for x in [-3.4,3.4]:
		panel.box(self,Vector3(x,2.9,-4.3),Vector3(.34,5.8,.45),Color("c7c8c2"),true)
		var lamp:=SpotLight3D.new();lamp.position=Vector3(x,4.6,1.5);lamp.look_at_from_position(lamp.position,Vector3(0,2,0));lamp.light_energy=.22;lamp.spot_range=10;lamp.spot_angle=40;lamp.shadow_enabled=true;add_child(lamp)
	panel.text(self,"A BODY / SEVERAL CENTRES",Vector3(0,3.8,-4.8),.0024,Color("38434a"))
	panel.text(self,"Move the point. Keep the operation.",Vector3(0,3.45,-4.8),.0011,Color("526069"))
	if not OS.get_cmdline_user_args().has("--capture-pivot"):
		var player=load("res://commons/scenes/desktop_player.tscn").instantiate()
		player.position=Vector3(0,.08,4.4);add_child(player)
