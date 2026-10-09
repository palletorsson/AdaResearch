extends Node3D
## Production ramp and XR Tools pickup/release with a synthetic hand.
## No controller-button, headset or full museum playthrough claim.

class TestHand extends Node3D:
	var picked_up_ranged := false

var checks := 0
var failures: Array[String] = []
var ramp: Node3D
var hand: TestHand

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("[trace-ball] ", "PASS " if ok else "FAIL ", message)

func frames(count: int = 6) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func carry(body: Node3D, at: Vector3) -> void:
	hand.global_transform = body.global_transform
	body.pick_up(hand)
	hand.global_position = ramp.to_global(at)
	await frames(12)

func release(body: Node3D) -> void:
	body.let_go(hand, Vector3.ZERO, Vector3.ZERO)

func _ready() -> void:
	run.call_deferred()

func run() -> void:
	ramp = load("res://commons/artifacts/trace_ball_ramp/trace_ball_ramp.tscn").instantiate()
	ramp.position = Vector3(3, 0, -2)
	ramp.rotation.y = 0.45
	add_child(ramp)
	hand = TestHand.new()
	add_child(hand)
	await frames()
	check(ramp.traces.size() == 1, "One initial ball, no automatic stream of extras")
	var first: Node3D = ramp.ball
	var first_trace = ramp.traces[0]
	check(first.position.is_equal_approx(ramp.HOME) and first.freeze, "Initial ball waits on the stand")
	check(first_trace.samples.is_empty() and first_trace.segment_count == 0, "Waiting ball leaves no ink")
	await carry(first, Vector3(0, 1.14, 0.88))
	check(first.is_picked_up() and first_trace.held and not first_trace.recording, "Real pickup pauses this ball's recording")
	check(ramp.traces.size() == 1, "Pickup alone does not supply another ball")
	var released_y: float = first.global_position.y
	release(first)
	check(not first.freeze and first_trace.recording, "Release enables real gravity and records this ball")
	await frames(12)
	check(ramp.traces.size() == 2, "Release supplies exactly one fresh ball")
	var second: Node3D = ramp.ball
	check(is_instance_valid(first) and second != first, "The released ball is retained, not recycled")
	check(second.position.is_equal_approx(ramp.HOME) and second.freeze, "Replacement waits at HOME even in a rotated station")
	check(ramp.traces[1].samples.is_empty(), "The waiting replacement does not record the first ball's motion")
	await get_tree().create_timer(1.5).timeout
	check(ramp.to_local(first.global_position).z > 1.4 and first.global_position.y < released_y, "First ball rolls down the actual plank under gravity")
	check(first_trace.segment_count > 15, "First ball draws its measured path while another waits")
	var first_sample: Vector3 = first_trace.samples[0]
	var first_ink: Transform3D = first_trace.ink.multimesh.get_instance_transform(0)
	var first_count: int = first_trace.segment_count
	await carry(second, Vector3(0, 1.14, 0.88))
	release(second)
	await frames(12)
	check(ramp.traces.size() == 3, "Second release supplies a third ball")
	check(is_instance_valid(first) and is_instance_valid(second) and first != ramp.ball and second != ramp.ball, "Both previously released balls remain")
	check(first_trace.segment_count >= first_count and first_trace.samples[0] == first_sample, "A later release does not clear the first ball's record")
	check(first_trace.ink != ramp.traces[1].ink and first_trace.ink.multimesh != ramp.traces[1].ink.multimesh, "Each ball owns an independent trace buffer")
	await get_tree().create_timer(6.5).timeout
	check(first_trace.segment_count > first_count and ramp.traces[1].segment_count > 15, "Multiple moving balls record concurrently")
	check(ramp.to_local(first.global_position).z > 3.75 and ramp.to_local(second.global_position).z > 3.75, "Both released balls reach the physical landing tray")
	check(first.global_position.distance_to(second.global_position) >= ramp.RADIUS * 2.0 - 0.03, "Retained balls collide instead of occupying the same space")
	check(ramp.traces.size() == 3 and ramp.ball.freeze, "Rest does not keep spawning balls")
	check(first_trace.ink.multimesh.get_instance_transform(0) == first_ink, "Earlier ink remains unchanged")
	var count_before: int = first_trace.segment_count
	await carry(first, Vector3(0.35, 1.6, 2.0))
	check(first_trace.segment_count == count_before, "Carrying an old ball preserves and pauses its trace")
	release(first)
	check(first_trace.segment_count == count_before and first_trace.samples[-1].distance_to(ramp.to_local(first.global_position)) < 0.001, "Another drop begins a separate stroke, not a bridge across the carried movement")
	await frames(8)
	check(ramp.traces.size() == 3, "Releasing an older ball leaves the existing stand supply alone")
	check(first_trace.ink.multimesh.get_instance_transform(0) == first_ink, "Reusing an old ball keeps its earlier ink")

	var third: Node3D = ramp.ball
	await carry(third, ramp.HOME)
	release(third)
	await frames(20)
	check(ramp.traces.size() == 3 and not is_instance_valid(ramp.ball), "Dropping onto HOME delays refill while the place is occupied")
	await carry(third, Vector3(2, 1.8, 0))
	check(ramp.traces.size() == 4 and ramp.ball != third, "Clearing the occupied stand completes its pending refill")
	check(ramp.ball.position.is_equal_approx(ramp.HOME), "Delayed replacement occupies the stand")
	release(third)
	await frames(10)
	check(ramp.traces.size() == 4, "Releasing the removed occupant cannot duplicate a completed refill")

	var fourth: Node3D = ramp.ball
	await carry(fourth, Vector3(18, 1.5, 0))
	check(ramp.traces.size() == 4, "Carrying the new supply waits for its release")
	release(fourth)
	await frames(10)
	check(ramp.traces.size() == 5, "The next interaction supplies another point")
	check(is_instance_valid(fourth) and fourth.freeze and ramp.to_local(fourth.global_position).x > 17, "An escaped ball is parked in place, never recycled onto the stand")
	check(is_instance_valid(first) and is_instance_valid(second) and is_instance_valid(third), "All earlier balls survive further interactions")
	check(first_trace.ink.multimesh.get_instance_transform(0) == first_ink, "The first path survives all later releases")
	finish()

func finish() -> void:
	var report_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--report="):
			report_path = argument.trim_prefix("--report=")
	var output := FileAccess.open(report_path, FileAccess.WRITE)
	if output == null:
		get_tree().quit(2)
		return
	output.store_string(JSON.stringify({"checks":checks, "failures":failures,
		"scope":"Actual ramp geometry and Godot physics; production XR Tools pickup/release with a synthetic hand. No headset or full-hall playthrough."}, "  "))
	output.close()
	get_tree().quit(0 if failures.is_empty() else 1)
