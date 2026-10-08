extends Node3D
var viewing_environment:Environment
func _ready() -> void:
	viewing_environment=Environment.new();viewing_environment.background_mode=Environment.BG_COLOR;viewing_environment.background_color=Color("293a49")
	viewing_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;viewing_environment.ambient_light_color=Color("cfdae5");viewing_environment.ambient_light_energy=.8
	var world:=WorldEnvironment.new();world.name="WorldEnvironment";world.environment=viewing_environment;add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=1.2;sun.shadow_enabled=true;add_child(sun)
	for at:Vector3 in [Vector3(0,7,5),Vector3(-9,9,13),Vector3(9,9,13),Vector3(0,7,23)]:
		var light:=OmniLight3D.new();light.position=at;light.omni_range=24;light.light_energy=1.4;light.light_color=Color("f8dfd9");add_child(light)
	if "--capture" not in OS.get_cmdline_user_args():
		var player:Node3D=load("res://commons/scenes/desktop_player.tscn").instantiate();player.name="VolumeVisitor";configure_visitor(player);add_child(player)
		player.position=Vector3(0,.12,-4);player.rotation.y=PI;player.set("camera_rotation",Vector2(0,PI));player.get_node("Head/Camera3D").make_current();player.get_node("Head/Camera3D").environment=viewing_environment
func configure_visitor(player:Node3D) -> void:
	# This form-comparison gallery needs a view beyond the carried lamp's range.
	# Override this instance only; the museum's lighting behaviour remains intact.
	player.get_node("Head/PlayerHeldLight").darken_environment=false
	viewing_environment.fog_enabled=false;viewing_environment.ambient_light_energy=.8
