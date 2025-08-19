# TimerHelper.gd
extends Node
class_name TimerHelper
# Creates a timer with the given wait_time (in seconds),
# connects its "timeout" signal to the provided callback,
# sets its one_shot property (default false), and adds it to the owner.
# Usage var timer = TimerHelper.set_timer(self, 20.0, Callable(self, "_on_Timer_timeout"))

static func set_timer(owner: Node, wait_time: float, callback: Callable, one_shot: bool = false) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	timer.autostart = true
	timer.connect("timeout", callback)
	owner.add_child(timer)
	return timer


static func create_timer(owner: Node, wait_time: float, callback: Callable, one_shot: bool = false) -> Timer:
	var timer = Timer.new()
	timer.wait_time = wait_time
	timer.one_shot = one_shot
	timer.autostart = true
	timer.connect("timeout", callback)
	owner.add_child(timer)
	return timer

# Restarts an existing timer with a new interval
static func restart_timer(timer: Timer, new_interval: float):
	if timer and not timer.is_stopped():
		timer.stop()
	timer.wait_time = new_interval
	timer.start()
