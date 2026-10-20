extends RefCounted
## Opt-in Quest diagnosis. No poses or persistent user data; last 120 seconds only.
## Enable with user://museum-runner/input-debug.on; remove that file to disable.
var game: Node3D
var path: String
var display := "INPUT LOG ON"
var history: Array[Dictionary] = []
var elapsed := 0.0
var peaks := Vector2.ZERO
var last_button := ""
var buttons := 0

func _init(owner_game: Node3D, output := "user://museum-runner/input-debug.json") -> void:
	game = owner_game
	path = output
	print("[museum-runner] Input diagnostics enabled: ",path)

func button(action: String, hand: XRController3D) -> void:
	buttons += 1
	last_button = str(hand.tracker) + ":" + action if is_instance_valid(hand) else action

func snapshot() -> Dictionary:
	var hands: Array[Dictionary] = []
	for name in ["LeftHand","RightHand"]:
		var hand: XRController3D = game.get_node("XROrigin3D/"+name)
		var tracker := XRServer.get_tracker(hand.tracker) as XRControllerTracker
		var value: Vector2 = hand.get_vector2("primary")
		var raw: Variant = tracker.get_input("primary") if tracker != null else null
		hands.append({"tracker":str(hand.tracker),"present":tracker!=null,
			"controller":[value.x,value.y],
			"raw":[raw.x,raw.y] if raw is Vector2 else null})
	return {"ms":Time.get_ticks_msec(),"state":["READY","RUNNING","PAUSED","OVER","WON","COMPLETE","SAVE_FAILED"][game.state],
		"vr":game.vr,"origin_current":game.get_node("XROrigin3D").current,
		"distance":game.distance,"lane":game.lane,"ball_x":game.runner.position.x,
		"hands":hands,"peak_x":[peaks.x,peaks.y],"selected":game._steering_input(),
		"buttons":buttons,"last_button":last_button}

func tick(delta: float) -> void:
	var left: float = game.get_node("XROrigin3D/LeftHand").get_vector2("primary").x
	var right: float = game.get_node("XROrigin3D/RightHand").get_vector2("primary").x
	peaks.x = maxf(peaks.x,absf(left))
	peaks.y = maxf(peaks.y,absf(right))
	elapsed += delta
	if elapsed < 1.0: return
	elapsed = 0.0
	var row := snapshot()
	display = "Stick L %.2f / R %.2f · ball lane %d" % [left,right,game.lane]
	history.append(row)
	if history.size()>120: history.pop_front()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"revision":game.INPUT_REVISION,"samples":history}))
	else: push_warning("Museum Runner input log: cannot write "+path)
	print("[museum-runner-input] ",JSON.stringify(row))
	peaks = Vector2.ZERO
