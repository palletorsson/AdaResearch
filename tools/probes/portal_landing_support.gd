extends SceneTree
## Standalone physics regression: the doorway must support a body with no
## authored hall floor under it, at a raised elevation and either orientation.
var failures: Array[String] = []
var samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var builder := load("res://commons/scenes/em/em_portal_frame.gd")
	for direction: int in [-1,1]:
		var frame := Node3D.new()
		root.add_child(frame)
		frame.position = Vector3(500,4.05,0)
		builder.build(frame,"PHYSICS CHECK",direction)
		await physics_frame
		await process_frame
		for local: Vector3 in [Vector3(0,0,-0.6),Vector3(0,0,1.15),Vector3(0.65,0,1.5),Vector3(-0.65,0,1.5)]:
			var body := CharacterBody3D.new()
			var collision := CollisionShape3D.new()
			var shape := CapsuleShape3D.new()
			shape.radius = 0.3
			shape.height = 1.8
			collision.shape = shape
			collision.position.y = 0.9
			body.add_child(collision)
			root.add_child(body)
			body.global_position = frame.to_global(local) + Vector3(0,0.4,0)
			for i in range(35):
				await physics_frame
				body.velocity.y -= 9.8 / 60.0
				body.move_and_slide()
			if not body.is_on_floor() or absf(body.global_position.y-4.0) > 0.02:
				failures.append("Unsupported slab at %s direction %d: %s" % [local,direction,body.global_position])
			var collider_name := ""
			if body.get_slide_collision_count() > 0:
				collider_name = body.get_slide_collision(0).get_collider().name
			if collider_name != "LandingCollision": failures.append("Landing relies on another collider: " + collider_name)
			samples.append({"direction":direction,"local":str(local),"feet":str(body.global_position),"collider":collider_name})
			body.queue_free()
			await process_frame
		frame.queue_free()
		await process_frame
	var report := {"passed":failures.is_empty(),"failures":failures,"samples":samples}
	var output := FileAccess.open("res://ada_run/portal_landing_repair/slab-report.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print("PORTAL SLAB: ",JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
