extends "res://algorithms/machinelearning/carlsims/evolvedcreatures.gd"
## Preserve the original score in the arena frame when the editor moves/turns it.
## Evolution, bodies, joints, population and controls remain inherited.

func _evaluate_population() -> void:
	var gen_best: float = 0.0
	var gen_avg: float = 0.0
	for creature in _population:
		if creature.bodies.is_empty():
			creature.genome.fitness = 0.0
			continue
		var torso := creature.bodies[0]
		if not is_instance_valid(torso):
			creature.genome.fitness = 0.0
			continue
		var displacement := to_local(torso.global_position) - creature.start_position
		var forward := displacement.x
		var distance := displacement.length()
		var height_bonus: float = max(0.0, to_local(torso.global_position).y - 1.0)
		creature.genome.fitness = forward * 2.0 + distance * 0.5 + height_bonus * 0.3
		gen_best = max(gen_best, creature.genome.fitness)
		gen_avg += creature.genome.fitness

	gen_avg /= max(1, _population.size())
	_best_fitness_ever = max(_best_fitness_ever, gen_best)

	# Highlight the best creature with a gold flash
	for creature in _population:
		if creature.genome.fitness >= gen_best and creature.bodies.size() > 0:
			var torso = creature.bodies[0]
			if is_instance_valid(torso):
				var mesh_child = torso.get_child(1) if torso.get_child_count() > 1 else null
				if mesh_child is MeshInstance3D and mesh_child.material_override is StandardMaterial3D:
					var mat = mesh_child.material_override as StandardMaterial3D
					var orig_emission = mat.emission
					mat.emission = Color(1.0, 0.85, 0.2) * 0.6
					var tw = create_tween()
					tw.tween_property(mat, "emission", orig_emission, 1.5)
			break

	# Update HUD
	if _status_label:
		_status_label.text = "Gen %d | Best %.1f | Avg %.1f | Record %.1f" % [_generation, gen_best, gen_avg, _best_fitness_ever]

