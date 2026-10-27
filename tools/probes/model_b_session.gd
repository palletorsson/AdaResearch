extends SceneTree
## Isolated optional Model B session; ordinary game launches are unchanged.
var game: Node3D
var brain: Node
var folder := ""
var idle := 180.0

func _initialize() -> void:
	start.call_deferred()

func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model-b-dir="):folder=arg.trim_prefix("--model-b-dir=")
		if arg.begins_with("--model-b-idle="):idle=clampf(float(arg.trim_prefix("--model-b-idle=")),5,600)
	if folder.is_empty():push_error("Model B requires an explicit session directory");quit(2);return
	root.size=Vector2i(960,600)
	load("res://commons/void/room_source.gd").use_main_tower=true
	game=load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene=game
	# Loading a hidden developer instance must not consume the human's keys.
	game.body.scripted_input=true;game.body.set_process_unhandled_input(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	for i in 45:await physics_frame
	game.scene_loaded();game.scene_visible()
	for i in 45:await physics_frame
	for i in 180:
		var floor: Dictionary=game.building.content.data.floors[game.checkpoint]
		if floor.artifacts.all(func(a):return game.building.content.exhibits.has(str(game.checkpoint)+"/"+a.id)):break
		await physics_frame
	brain=load("res://tools/model_b/brain.gd").new();brain.name="ModelBBrain"
	game.add_child(brain);brain.closed.connect(finish)
	# The brain records and restores the ordinary human-controlled contract.
	game.body.scripted_input=false;game.body.set_process_unhandled_input(true)
	brain.configure(game,folder,idle)

func finish(reason: String) -> void:
	print("MODEL_B_SESSION_RESULT ",JSON.stringify({"closed":true,"reason":reason}))
	game.queue_free()
	for i in 5:await process_frame
	quit()
