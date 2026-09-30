extends "res://commons/primitives/cubes/pickups/pickup_wrapper.gd"
## The earlier wire cube, collected for a local celebration without scoring.
signal party_collected(world_position: Vector3)

func _ready() -> void:
	super._ready()
	$DetectionArea.collision_mask = 1 | (1 << 19)

func collect() -> void:
	if hold == "demo" or has_been_collected:
		return
	has_been_collected = true
	$DetectionArea.set_deferred("monitoring", false)
	$Visuals.hide()
	party_collected.emit(to_global(Vector3(0, 0.5, 0)))
	pickup_sound.stream = _generate_mario_pickup_sound()
	pickup_sound.play()
	# Keep the sound owned by this hall; leaving early frees it with the cube.
	await get_tree().create_timer(pickup_sound.stream.get_length() + 0.15).timeout
	queue_free()
