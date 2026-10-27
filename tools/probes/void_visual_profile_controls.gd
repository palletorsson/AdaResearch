extends SceneTree
## Narrow check of the actual opt-in launch hook and F8 input dispatch.
var failures: Array[String]=[]
var checks: Array[Dictionary]=[]
func _initialize() -> void:run.call_deferred()
func check(label:String,passed:bool)->void:
	checks.append({"name":label,"passed":passed})
	if not passed:failures.append(label)
func frames(n:int)->void:
	for i in n:await process_frame
func run()->void:
	root.unfocusable=true
	root.size=Vector2i(640,400)
	preload("res://commons/void/room_source.gd").use_main_tower=true
	var game:Node3D=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	await frames(20)
	game.body.scripted_input=true
	var look:Node=game.get_node_or_null("VisualProfileStudy")
	check("launch flag creates exactly one scene-local profile",look!=null and game.find_children("VisualProfileStudy","",true,false).size()==1)
	if look!=null:
		check("requested finish is selected",look.selected=="finish")
		check("architecture source material has no new texture",game.building.concrete.albedo_texture==null and not game.building.concrete.normal_enabled)
		var key:=InputEventKey.new();key.keycode=KEY_F8;key.pressed=true
		Input.parse_input_event(key);await frames(3)
		check("actual F8 dispatch restores baseline",look.selected=="baseline" and not look.fill.visible)
		check("baseline restores tonemapping",game.atmosphere.environment.tonemap_mode==look.env_before.tonemap_mode)
		check("baseline restores all registered materials",look.bindings.all(func(b):return not is_instance_valid(b.node) or b.node.material_override==b.source))
		key=InputEventKey.new();key.keycode=KEY_F8;key.pressed=true
		Input.parse_input_event(key);await frames(3)
		check("second F8 selects light only",look.selected=="light")
		look.set_profile("finish")
		check("finish remains available after cycling",look.bindings.all(func(b):return not is_instance_valid(b.node) or b.node.material_override==look.finishes[b.source]))
	var out:="user://visual-controls.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--receipt="):out=arg.trim_prefix("--receipt=")
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures},"  "))
	print("VOID_VISUAL_CONTROLS ",failures)
	quit(0 if failures.is_empty() else 1)
