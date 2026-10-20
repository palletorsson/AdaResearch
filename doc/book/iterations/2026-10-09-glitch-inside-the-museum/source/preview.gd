extends Node3D
var work:Node3D

func _ready() -> void:
	var world:=WorldEnvironment.new();world.name="CourtyardEnvironment";var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("879ba2")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e1e6dc");env.ambient_light_energy=.20
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=.60
	world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-32,0);sun.light_color=Color("ffeddb");sun.light_energy=.26;sun.shadow_enabled=true;sun.directional_shadow_max_distance=100;add_child(sun)
	work=preload("res://commons/artifacts/model_disagreement/model_disagreement.tscn").instantiate();add_child(work)
	var p=work.panel
	p.box(self,Vector3(0,-.2,-4),Vector3(64,.4,60),Color("c5c0ae"),true)
	p.box(self,Vector3(0,7,-32),Vector3(64,14,.4),Color("ded8c8"),true)
	for x in [-32,32]:p.box(self,Vector3(x,7,-4),Vector3(.4,14,60),Color("ddd8cb"),true)
	for x in range(-32,33,2):p.box(self,Vector3(x,.005,-4),Vector3(.016,.01,60),Color("a4aaa0"))
	for z in range(-32,27,2):p.box(self,Vector3(0,.005,z),Vector3(64,.01,.016),Color("a4aaa0"))
	p.text(self,"ENDLESS MUSEUM",Vector3(0,11,-31.7),.012,Color("253538"))
	p.text(self,"always another room",Vector3(0,10,-31.69),.005,Color("58696a"))
	p.text(self,"WHEN PARTS STOP AGREEING",Vector3(0,7.8,-31.68),.007,Color("253538"))
	p.text(self,"PREVIEW STUDY / NO MUSEUM ROUTE PLACEMENT",Vector3(0,6.4,-31.68),.003,Color("58696a"))
	# A 1.75m witness retains a bodily measure as the model grows.
	var witness:=MeshInstance3D.new();var shape:=CapsuleMesh.new();shape.radius=.18;shape.height=1.75;witness.mesh=shape;witness.position=Vector3(-7,.875,5);witness.material_override=p.material(Color("28393b"));add_child(witness)
	if not OS.get_cmdline_user_args().has("--capture-disagreement"):spawn_viewer()

func spawn_viewer() -> CharacterBody3D:
	var player=load("res://commons/scenes/desktop_player.tscn").instantiate()
	var lamp=player.get_node("Head/PlayerHeldLight");lamp.darken_environment=false;lamp.light_energy=0;lamp.flicker_amount=0
	player.position=Vector3(0,.03,13);add_child(player);return player
