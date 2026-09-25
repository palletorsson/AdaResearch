extends SceneTree

const DIE := "res://algorithms/randomness/dice_throw/dice_throw.gd"

func _initialize() -> void:
	_run.call_deferred()

func _variant(label: String, tweak: Callable, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at
	root.add_child(holder)
	var d: Node3D = load(DIE).new()
	d.set("balls_per_pip", 0)
	holder.add_child(d)
	for i in 10:
		await physics_frame
	var body: RigidBody3D = d.get("_dice_body")
	tweak.call(body)
	var th: float = float(d.get("table_height"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var read_n := 0
	var asleep := 0
	var still := 0
	var t_sum := 0.0
	var trials := 16
	for t in trials:
		var before: int = int(d.get("_total_rolls"))
		d.call("_on_dice_picked_up", null)
		body.freeze = true
		var b := Basis.from_euler(Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI)))
		body.global_transform = Transform3D(b, holder.global_position + Vector3(rng.randf_range(-0.15, 0.15), th + 0.25, 0.1))
		await physics_frame
		await physics_frame
		body.freeze = false
		body.linear_velocity = Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.0, 1.0), rng.randf_range(-1.0, -0.3))
		body.angular_velocity = Vector3(rng.randf_range(-12, 12), rng.randf_range(-12, 12), rng.randf_range(-12, 12))
		d.call("_on_dice_dropped", null)
		var tr := -1.0
		for f in 360:
			await physics_frame
			if tr < 0.0 and int(d.get("_total_rolls")) > before:
				tr = float(f) / 60.0
		if tr >= 0.0:
			read_n += 1
			t_sum += tr
		if body.sleeping:
			asleep += 1
		if body.angular_velocity.length() < 0.2:
			still += 1
	print("SWEEP %-22s read %2d/%d (mean %.2f s)  asleep at 6 s %2d  spin<0.2 %2d" % [label, read_n, trials, t_sum / maxf(1.0, float(read_n)), asleep, still])
	holder.queue_free()

func _run() -> void:
	var fl := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(400, 0.2, 400)
	cs.shape = bx
	fl.add_child(cs)
	fl.position = Vector3(0, -0.1, 0)
	root.add_child(fl)
	await _variant("shipped", func(b): pass, Vector3(0, 0, 0))
	await _variant("bounce0.2", func(b): b.physics_material_override.bounce = 0.2, Vector3(5, 0, 0))
	await _variant("bounce0", func(b): b.physics_material_override.bounce = 0.0, Vector3(10, 0, 0))
	await _variant("grav1", func(b): b.gravity_scale = 1.0, Vector3(15, 0, 0))
	await _variant("angdamp1.5", func(b): b.angular_damp = 1.5, Vector3(20, 0, 0))
	await _variant("bounce0.2+grav1", func(b): b.physics_material_override.bounce = 0.2; b.gravity_scale = 1.0, Vector3(25, 0, 0))
	await _variant("bounce0.2+angdamp1.5", func(b): b.physics_material_override.bounce = 0.2; b.angular_damp = 1.5, Vector3(30, 0, 0))
	quit(0)
