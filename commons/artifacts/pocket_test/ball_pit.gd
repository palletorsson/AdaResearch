extends "res://commons/artifacts/pocket_test/pocket_test.gd"
class_name BallPit
## THE BALL PIT (Palle, 2026-11-02): the pocket test's pit mode with a pit's defaults - full when you arrive, a few
## hundred hollow balls the size of a beach ball, rained in over eight ticks, quiet enough to stay, pushed by the person who wades in. The
## readout is off; the rim button refills. A receiving place sizes it to its pool (place_builder: activity
## {"artifact": "ball_pit", "config": {"count": 250}}). The count is the knob the headset pays for.

func _init() -> void:
	pit = true;push_player = true;show_readout = false
	count = 320;diameter = .4;radius_min = diameter * .44;radius_max = diameter * .56;fill_per_tick = 40
	bounce = .15;friction = .4;density = 25.0;drop_height = .5;settle_seconds = 12.0
	damping = 2.0;max_speed = 2.0   # quiet (Palle, 2026-11-02): a pushed ball gives up within a second and never flies
