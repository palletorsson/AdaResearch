extends SceneTree
## WHERE DOES THE SNUG BALL ACTUALLY GO?
##
## snug/firm reads ESCAPED at -480 m while scant/firm rests on the same static
## body, so the catch floor under the washer is being missed, not tunnelled.
## This prints the ball's bounds centre and size every 30 ticks: whether it
## drifts sideways past the tray lips, whether the bounds inflate (one ejected
## vertex drags the AABB), and at what height contact is lost.

const SCENE := "res://commons/artifacts/droplet_cusp/droplet_cusp.tscn"


func _init() -> void:
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var n = load(SCENE).instantiate()
	n.set("flesh", "firm")
	n.set("waist", "snug")
	n.position = Vector3(3, 2, 3)   # away from whatever the autoloads park at the origin
	get_root().add_child(n)
	# _ready does not run until the tree's first iteration, so reading _ball
	# straight after add_child reads null and the error aborts _init silently
	await process_frame
	var ball: SoftBody3D = n.get("_ball")
	if ball == null:
		print("probe_droplet_trace: no ball after a frame - abort")
		quit(1)
		return
	for i in range(420):
		await physics_frame
		if i % 30 == 0:
			var bb: AABB = PhysicsServer3D.call("soft_body_get_bounds", ball.get_physics_rid())
			var c: Vector3 = bb.position + bb.size * 0.5 - (n as Node3D).global_position
			print("t=%3d  centre (%+.3f, %+.3f, %+.3f)  size (%.3f, %.3f, %.3f)"
				% [i, c.x, c.y, c.z, bb.size.x, bb.size.y, bb.size.z])
	print("probe_droplet_trace: done")
	quit(0)
