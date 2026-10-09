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
func pull(release: bool = true) -> void:
	var lever: Node3D = artifact.lever
	var frame: Node3D = lever.get_node("Frame")
	event(frame,2,lever.to_global(Vector3(0,0.07,0.015)))
	event(frame,4,lever.to_global(Vector3(0,-0.03,0.015)))
	if release: event(frame,3,lever.to_global(Vector3(0,-0.03,0.015)))
func button(index: int) -> void:
	var target: Node3D = artifact.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	event(target,2,target.global_position)
	event(target,3,target.global_position)
func settle() -> void:
	for i in range(400):
		if not artifact.busy: break
		await process_frame
	check("move completes",not artifact.busy)
func run() -> void:
	event_script = load("res://addons/godot-xr-tools/events/pointer_event.gd")
	artifact = load("res://commons/artifacts/random_position_rails/random_position_rails.tscn").instantiate()
	artifact.position = Vector3(14,0,-12)
	artifact.rotation.y = PI
	root.add_child(artifact)
	pointer = Node3D.new()
	root.add_child(pointer)
	await process_frame
	check("starts at centre without invented history",artifact.tick==0 and artifact.committed==Vector2.ZERO and artifact.history.is_empty() and not artifact.running)
	check("real grab proxy on prediction marker",artifact.prediction.get_node("SliderOrigin/InteractableSlider/HandleOrigin/InteractableHandle").get_script().resource_path.ends_with("angular_handle.gd"))
	var slider: Node3D = artifact.prediction
	var target: Node3D = slider.get_node("Frame")
	event(target,2,slider.to_global(Vector3.ZERO))
	event(target,4,slider.to_global(Vector3(1.1,0,0)))
	event(target,3,slider.to_global(Vector3(1.1,0,0)))
	var before: Dictionary = artifact.get_state()
	check("world-space pointer moves marker 1.1m at rotated host",absf(before.prediction-1.1)<0.001)
	check("prediction does not change RNG or carriage positions",artifact.tick==0 and artifact.committed==Vector2.ZERO)
	pull(false)
	check("real NEXT lever starts a paired move",artifact.busy)
	check("both targets share one random draw",absf(artifact.targets.x/2.2-artifact.targets.y/0.4)<0.0001)
	check("busy lever cannot consume another draw",not artifact.advance())
	var first_target: Vector2 = artifact.targets
	await create_timer(0.2).timeout
	check("targets visible before carriage motion",artifact.target_marks[0].visible and artifact.carriages[0].position.x==0 and artifact.carriages[1].position.x==0)
	await create_timer(0.75).timeout
	var weight_a: float = artifact.carriages[0].position.x/first_target.x
	var weight_b: float = artifact.carriages[1].position.x/first_target.y
	check("both rails use same intermediate easing weight",weight_a>0 and weight_a<1 and absf(weight_a-weight_b)<0.001)
	await settle()
	event(artifact.lever.get_node("Frame"),4,artifact.lever.to_global(Vector3(0,-0.08,0.015)))
	check("held lever cannot repeat a draw",artifact.tick==1 and not artifact.busy)
	event(artifact.lever.get_node("Frame"),3,artifact.lever.to_global(Vector3(0,-0.08,0.015)))
	check("release rearms NEXT",artifact.armed)
	var stream: Array = [artifact.get_state().committed]
	for i in range(14):
		var old: Vector2 = artifact.committed
		pull()
		check("fresh target ignores old position",absf(artifact.targets.x-artifact.sample*2.2)<0.0001)
		check("step adds draw to previous committed position",absf(artifact.raw_step_target-old.y-artifact.sample*0.4)<0.0001)
		await settle()
		stream.append(artifact.get_state().committed)
		check("both land inside rails and step stays local",absf(artifact.committed.x)<=2.20001 and absf(artifact.committed.y)<=2.20001 and absf(artifact.committed.y-old.y)<=0.40001)
	check("record bounded but count continues",artifact.history.size()==12 and artifact.record.get_child_count()==24 and artifact.tick==15)
	check("positive overshoot folds",absf(artifact.reflect_position(2.3)-2.1)<0.0001)
	check("negative overshoot folds",absf(artifact.reflect_position(-2.3)+2.1)<0.0001)
	check("exact boundaries retained",absf(artifact.reflect_position(2.2)-2.2)<0.0001 and absf(artifact.reflect_position(-2.2)+2.2)<0.0001)
	button(1)
	check("real REPLAY restores seed positions history and marker",artifact.tick==0 and artifact.history.is_empty() and artifact.committed==Vector2.ZERO and absf(artifact.get_state().prediction)<0.001)
	for i in range(3):
		pull()
		await settle()
		check("replay recovers same landing pair",artifact.get_state().committed==stream[i])
	button(1)
	button(0)
	check("RUN starts automatic movement",artifact.running and artifact.busy)
	button(0)
	await settle()
	check("HOLD finishes revealed move",not artifact.running and artifact.tick==1 and artifact.committed==first_target)
	await create_timer(3.0).timeout
	check("HOLD prevents subsequent draws",artifact.tick==1 and not artifact.busy)
	pull()
	await create_timer(0.85).timeout
	button(1)
	await create_timer(2.0).timeout
	check("REPLAY cancels motion without late commits",artifact.tick==0 and artifact.history.is_empty() and artifact.committed==Vector2.ZERO and artifact.carriages[0].position.x==0 and not artifact.busy)
	# Two snapshots differing only in retained record must give the same next pair.
	pull();await settle()
	pull();await settle()
	var expected: Vector2 = artifact.committed
	button(1)
	pull();await settle()
	artifact.history.clear()
	pull();await settle()
	check("drawing history is not input to next move",artifact.committed==expected)
	FileAccess.open("res://doc/book/iterations/2026-09-24-random-walk-rails/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"landing_pairs":stream,"scope":"Production native Godot scene; supplied pointer events through actual controls at translated, rotated host. Headset grip and comfort not tested."},"  "))
	print("RAIL CHECKS ",checks.size()," FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
