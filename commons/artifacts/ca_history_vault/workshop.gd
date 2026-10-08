extends Node3D
## Standalone, playable desktop form laboratory. Main museum route is unaffected.
var viewing_environment:Environment
func _ready() -> void:
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("233443")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("afc4dc");env.ambient_light_energy=0.55
	viewing_environment=env
	var world:=WorldEnvironment.new();world.environment=env;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-35,0);sun.light_energy=1.0;sun.shadow_enabled=true;add_child(sun)
	for z in [0.0,5.0,10.0,15.0]:
		var light:=OmniLight3D.new();light.position=Vector3(0,2.4,z);light.omni_range=5;light.light_energy=0.7;light.light_color=Color("f8d6ad");add_child(light)
	# Gallery fill lights reveal the outside as clearly as the inhabited hollow.
	for at:Vector3 in [Vector3(5,6,-2),Vector3(-6,5,4),Vector3(3,7,11)]:
		var fill:=OmniLight3D.new();fill.position=at;fill.omni_range=18;fill.light_energy=1.2;fill.light_color=Color("dce8f4");add_child(fill)
	if "--capture" not in OS.get_cmdline_user_args():
		var player:Node3D=load("res://commons/scenes/desktop_player.tscn").instantiate();player.name="WorkshopVisitor";add_child(player)
		player.position=Vector3(0,0.05,-4);player.rotation.y=PI;player.set("camera_rotation",Vector2(0,PI));player.get_node("Head/Camera3D").make_current()
		player.get_node("Head/Camera3D").environment=viewing_environment
