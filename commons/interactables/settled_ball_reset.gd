extends Node
## Restore a take only after every test ball has rested for the full interval.
## A held ball or control pauses the wait; renewed motion starts it over.
signal countdown_changed(remaining: float)
@export_range(0,60,.5) var wait_seconds := 10.0
var balls: Callable
var take_started: Callable
var interaction_busy: Callable
var restore: Callable
var resting_seconds := 0.0
var restoring := false
func _physics_process(delta: float) -> void:
	if restoring or wait_seconds<=0 or not balls.is_valid() or not take_started.is_valid(): return
	if not take_started.call(): cancel();return
	if interaction_busy.is_valid() and interaction_busy.call(): cancel();return
	var live: Array = balls.call()
	if live.is_empty(): cancel();return
	for ball in live:
		if not is_instance_valid(ball) or not ball is RigidBody3D: cancel();return
		if ball.has_method("is_picked_up") and ball.is_picked_up(): cancel();return
		if ball.linear_velocity.length()>.03 or ball.angular_velocity.length()>.35: cancel();return
	resting_seconds += delta
	countdown_changed.emit(maxf(wait_seconds-resting_seconds,0))
	if resting_seconds>=wait_seconds:
		restoring = true
		_restore.call_deferred()
func cancel() -> void:
	if resting_seconds>0:
		resting_seconds=0
		countdown_changed.emit(-1)
func _restore() -> void:
	if is_inside_tree() and restore.is_valid(): restore.call()
	resting_seconds=0;restoring=false
	countdown_changed.emit(-1)
