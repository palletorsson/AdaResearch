extends SceneTree
var checks: Array = []
var failures: Array = []
var artifact: Node3D
var pointer: Node3D
var event_script
func _initialize() -> void: call_deferred("run")
func check(title: String, good: bool) -> void:
	checks.append({"name":title,"passed":good})
	if not good: failures.append(title)
func event(target: Node3D, kind: int, pos: Vector3) -> void:
	target.pointer_event(event_script.new(kind,pointer,target,pos,pos))
func pull(side: int, release: bool = true) -> void:
	var lever: Node3D = artifact.levers[side]
	var frame: Node3D = lever.get_node("Frame")
	event(frame,2,lever.to_global(Vector3(0,0.07,0.015)))
	event(frame,4,lever.to_global(Vector3(0,-0.03,0.015)))
	if release: event(frame,3,lever.to_global(Vector3(0,-0.03,0.015)))
func settle() -> void:
	for i in range(400):
		if not artifact.busy[0] and not artifact.busy[1]: break
		await process_frame
	check("animation completes",not artifact.busy[0] and not artifact.busy[1])
func replay_button() -> void:
	var target: Node3D = artifact.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	event(target,2,target.global_position)
	event(target,3,target.global_position)
func run() -> void:
	event_script = load("res://addons/godot-xr-tools/events/pointer_event.gd")
	artifact = load("res://commons/artifacts/sampling_hoppers/sampling_hoppers.tscn").instantiate()
	artifact.position = Vector3(14,0,-12)
	artifact.rotation.y = PI
	root.add_child(artifact)
	pointer = Node3D.new()
	root.add_child(pointer)
	await process_frame
	check("eight matching members, no initial draws",artifact.pools[0]==range(1,9) and artifact.pools[1]==range(1,9) and artifact.totals==[0,0])
	check("eight visible blocks per hopper",artifact.blocks[0].size()==8 and artifact.blocks[1].size()==8)
	check("real reusable grab lever",artifact.levers[0].get_node("LeverOrigin/InteractableLever/HandleOrigin/InteractableHandle").get_script().resource_path.ends_with("angular_handle.gd"))
	pull(0,false)
	check("pointer drag starts one draw",artifact.busy[0])
	check("busy hopper refuses a second draw",not artifact.draw(0))
	await settle()
	var lever: Node3D = artifact.levers[0]
	event(lever.get_node("Frame"),4,lever.to_global(Vector3(0,-0.08,0.015)))
	check("holding past threshold cannot draw again",artifact.totals[0]==1 and not artifact.busy[0])
	event(lever.get_node("Frame"),3,lever.to_global(Vector3(0,-0.08,0.015)))
	check("release returns and rearms lever",is_zero_approx(lever.get_angle_degrees()) and artifact.armed[0])
	var first: int = artifact.histories[0][0]
	check("replacement restores original numbered block",artifact.pools[0].size()==8 and artifact.blocks[0][first-1].position.distance_to(artifact._slot(0,first))<0.001)
	pull(1)
	await settle()
	check("matched seed and first bound yield same first member",artifact.histories[1][0]==first)
	check("without replacement leaves candidate pool",artifact.pools[1].size()==7 and not artifact.pools[1].has(first))
	check("removed member rests in record",artifact.blocks[1][first-1].position.distance_to(artifact._record_slot(1,0))<0.001)
	for i in range(7):
		pull(0);pull(1)
		await settle()
	var removed: Array = artifact.histories[1].duplicate()
	var unique: Dictionary = {}
	for id in removed: unique[id]=true
	check("eight draws exhaust every unique member",artifact.pools[1].is_empty() and unique.size()==8 and artifact.totals[1]==8)
	pull(1)
	check("empty lever cannot invent ninth member",artifact.totals[1]==8 and not artifact.busy[1])
	check("replacement never shrinks pool",artifact.pools[0]==range(1,9) and artifact.totals[0]==8)
	for i in range(5):
		pull(0)
		await settle()
	unique.clear()
	for id in artifact.histories[0]:unique[id]=true
	check("replacement permits repeated members",unique.size()<artifact.histories[0].size())
	check("replacement record bounded while total continues",artifact.histories[0].size()==12 and artifact.records[0].get_child_count()==12 and artifact.totals[0]==13)
	var before: Dictionary = artifact.get_state()
	replay_button()
	check("real replay button restores sets and clears records",artifact.totals==[0,0] and artifact.pools[0].size()==8 and artifact.pools[1].size()==8 and artifact.records[0].get_child_count()==0)
	for i in range(8):
		pull(1)
		await settle()
	check("replay repeats removal order",artifact.histories[1]==removed)
	replay_button()
	pull(0);pull(1)
	await create_timer(0.1).timeout
	replay_button()
	await create_timer(2).timeout
	check("replay cancels in-flight draws and stale callbacks",artifact.totals==[0,0] and artifact.pools[1].size()==8 and not artifact.busy[0] and not artifact.busy[1])
	check("all source blocks restore their local slots",artifact.blocks[1][first-1].position.distance_to(artifact._slot(1,first))<0.001)
	check("invalid indices rejected",not artifact.draw(-1) and not artifact.draw(2))
	var output := {"checks":checks,"failures":failures,"scope":"Supplied native pointer events through the production lever Frame and replay button, with completed tweens at a translated and rotated host. No tracked headset or physical-randomness claim.","after_thirteen_and_eight":before,"state":artifact.get_state()}
	FileAccess.open("res://doc/book/iterations/2026-09-24-sampling-hoppers/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("HOPPER CHECKS ",checks.size()," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
