extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var P = load("res://commons/scenes/em/em_plinths.gd")
	var sizes = load("res://commons/scenes/endless_museum.gd")
	var d: Dictionary = P.plan("origin", {"x": 12, "y": 8, "rank": 2, "top": 0.0})
	print("PLINTH origin: needs=%s why=%s h=%.2f b=%.2f" % [d.needs, d.why, d.height_m, d.base_m])
	quit(0)
