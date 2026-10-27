extends SceneTree
## Actual controller signal routing; no world/saves or physical headset needed.
var checks: Array = []
func check(label: String, passed: bool) -> void: checks.append({"name":label,"passed":passed})
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var game = load("res://tools/probes/void_jump_game_spy.gd").new()
	var jump = load("res://commons/void/jump.gd").new()
	game.jump=jump
	var controller := XRController3D.new()
	controller.button_pressed.connect(game._right_button)
	for button in ["by_button","ax_button"]:
		jump.queued=false
		controller.button_pressed.emit(button)
		check(button+" queues jump without retry",jump.queued and game.retries==0)
	jump.queued=false
	game.recovering=true;controller.button_pressed.emit("by_button")
	check("recovery ignores jump",not jump.queued and game.retries==0)
	game.recovering=false;game.returning=true;controller.button_pressed.emit("by_button")
	check("menu transition ignores jump",not jump.queued and game.retries==0)
	game.returning=false
	var retry := InputEventKey.new();retry.keycode=KEY_R;retry.pressed=true
	game._unhandled_key_input(retry)
	check("desktop R still retries",game.retries==1)
	controller.free();jump.free();game.free()
	var result := {"passed":checks.all(func(c):return c.passed),"checks":checks,"scope":"Native controller signal routing and desktop retry. Jump physics unchanged; no physical-headset test."}
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):FileAccess.open(arg.trim_prefix("--out="),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("JUMP_BUTTON_RESULT ",JSON.stringify(result))
	quit(0 if result.passed else 1)
