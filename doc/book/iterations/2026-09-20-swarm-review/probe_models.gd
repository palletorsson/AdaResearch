extends SceneTree

const OUT := "res://doc/book/iterations/2026-09-20-swarm-review/"
var checks: Array = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks.append({"ok": ok, "message": message})

func old_script(path: String, classname: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = FileAccess.get_file_as_string(OUT + "before/" + path).replace("class_name " + classname, "")
	check(script.reload() == OK, "baseline script compiles: " + classname)
	return script

func mount(script: Script) -> Node:
	var n: Node = script.new()
	root.add_child(n)
	n.set_process(false)
	return n

func ant_state(n: Node) -> Array:
	var result: Array = [n._food_sources.duplicate(true), n._pheromone_grid.duplicate(true)]
	for ant in n._ants:
		result.append([ant.pos, ant.vel, ant.wander_angle, ant.has_food, ant.path.duplicate()])
	return result

func run() -> void:
	var pso_path := "commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.gd"
	var abm_path := "algorithms/swarmintelligence/ant_colony_optimization/AntColonyOptimization.gd"
	var old_pso := mount(old_script(pso_path, "FitnessLandscapePolitics"))
	old_pso._switch_landscape(2)
	old_pso._novelty_archive.append(Vector3.ZERO)
	var old_best: Array = []
	for p in old_pso._particles: old_best.append(p.best_pos)
	for i in 120: old_pso._update_swarm(1.0 / 60.0)
	var frozen := true
	for i in old_best.size(): frozen = frozen and old_best[i] == old_pso._particles[i].best_pos
	evidence.old_novelty = {"stored_global_score": old_pso._global_best_fitness, "all_personal_positions_frozen": frozen}
	check(frozen and old_pso._global_best_fitness == 10.0, "reproduced old novelty memory freeze")
	old_pso.free()

	var pso := mount(load("res://" + pso_path))
	for mode in [0, 1, 2, 3]:
		var positions: Array = []
		for p in pso._particles: positions.append([p.pos, p.vel])
		pso._switch_landscape(mode)
		var kept := true
		for i in positions.size(): kept = kept and positions[i] == [pso._particles[i].pos, pso._particles[i].vel]
		check(kept, "objective switch keeps position/velocity: " + str(mode))
		pso._init_swarm()
		var initial: Array = pso._particles.duplicate(true)
		for i in 120: pso._update_swarm(1.0 / 60.0)
		pso._init_swarm()
		check(initial == pso._particles, "repeatable reset: " + str(mode))
	# Force a stale-score case. Correct handling needs rescoring after archive
	# changes, not merely replacing the old empty-archive constant.
	pso._switch_landscape(2)
	pso._novelty_archive.assign([Vector3.ZERO])
	pso._particles.assign([
		{"pos": Vector3(1, .15, 0), "vel": Vector3.ZERO, "best_pos": Vector3.ZERO, "best_fitness": 10.0},
		{"pos": Vector3(.2, .15, 0), "vel": Vector3.ZERO, "best_pos": Vector3(1.2, .15, 0), "best_fitness": 50.0}])
	pso._rescore_memories()
	check(is_equal_approx(pso._global_best_fitness, 1.2), "archive rescoring chooses current best score, not historical maximum")
	check(pso._particles[0].best_pos == pso._particles[0].pos, "current position can replace a stale remembered best")
	pso._novelty_archive.append(Vector3(1.2, .15, 0))
	pso._rescore_memories()
	check(pso._global_best_fitness < 1.0, "archive addition can reduce shared best score")
	pso._novelty_archive.clear()
	check(pso._evaluate_fitness(Vector3.ZERO) == 0.0, "empty archive has no unbeatable reward")
	pso._init_swarm()
	var started: Array = pso._particles.map(func(p): return p.best_pos)
	for i in 90: pso._update_swarm(1.0 / 60.0)
	var changed := 0
	for i in started.size():
		if pso._particles[i].best_pos != started[i]: changed += 1
	check(changed > 0, "novelty personal memory actually changes during motion")
	check(pso._novelty_archive.size() >= pso.particle_count + 2, "archive accumulates in headless simulation time")
	var coherent := true
	for p in pso._particles:
		coherent = coherent and is_equal_approx(p.best_fitness, pso._evaluate_fitness(p.best_pos))
	check(coherent, "personal scores agree with current archive")
	check(is_equal_approx(pso._global_best_fitness, pso._evaluate_fitness(pso._global_best_pos)), "shared score agrees with current archive")
	evidence.novelty = {"changed_memories": changed, "archive_size": pso._novelty_archive.size(), "best_score": pso._global_best_fitness}
	pso._novelty_archive.resize(200)
	for i in 200: pso._novelty_archive[i] = Vector3.ZERO
	pso._archive_elapsed = 0.5
	pso._update_swarm(0.001)
	check(pso._novelty_archive.size() == 200, "archive stays bounded")
	pso.free()

	var old_abm := mount(old_script(abm_path, "AntColonyOptimization"))
	old_abm._reset_colony()
	var old_start := ant_state(old_abm)
	old_abm._reset_colony()
	check(old_start != ant_state(old_abm), "reproduced old reset changing the starting problem")
	old_abm.free()
	var abm := mount(load("res://" + abm_path))
	abm.apply_grid_config({"lesson_display": "on"})
	var evaporate: Node = abm._control_panel.find_child("Param_0", true, false)
	check(is_equal_approx(evaporate.get_normalized_value(), .2), "slider begins at the actual evaporation setting")
	check(abm._control_panel.position.y > 1.0, "lesson controls are above the floor")
	abm._reset_colony()
	var baseline := ant_state(abm)
	for i in 60: abm._simulate_step(1.0 / 60.0)
	abm._on_reset_pressed()
	check(baseline == ant_state(abm), "RESET restores food, field, headings and positions")
	var rng_state: int = abm._rng.state
	abm.evaporation_rate = .08
	abm._reset_colony()
	check(baseline == ant_state(abm) and abm._rng.state == rng_state, "changing evaporation preserves reset problem and random stream")
	for hz in [30, 60, 90]:
		abm._reset_colony()
		for i in hz: abm._process(1.0 / hz)
		var state := ant_state(abm)
		if hz == 30: baseline = state
		else: check(state == baseline, "same one-second simulation at " + str(hz) + " Hz")
	abm._pheromone_grid[0][0] = 1.0
	var field: Array = abm._pheromone_grid.duplicate(true)
	abm.ant_count = 12
	abm._spawn_ants()
	check(abm._ants.size() == 12 and field == abm._pheromone_grid, "ANTS replaces bodies while preserving the old field")
	abm._on_mode_pressed()
	check(field == abm._pheromone_grid, "MODE keeps ongoing field")
	abm._reset_colony()
	abm.evaporation_rate = .02
	abm._pheromone_grid[0][0] = 1.0
	abm._evaporate_pheromones(1.0)
	var once: float = abm._pheromone_grid[0][0]
	abm._pheromone_grid[0][0] = 1.0
	for i in 90: abm._evaporate_pheromones(1.0 / 90.0)
	check(is_equal_approx(once, abm._pheromone_grid[0][0]), "decay depends on elapsed time")
	abm.free()

	var eco := mount(load("res://algorithms/emergentsystems/ecosystemsimulation/ecosystem.gd"))
	check(eco is Node3D, "ecosystem scene is eligible for museum placement")
	check(eco.prey_mm_instance.material_override.vertex_color_use_as_albedo, "population colours are rendered without emission")
	eco.apply_grid_config({"show_care_log": true})
	check(is_instance_valid(eco._care_label), "caretaker record appears through map configuration")
	for p in eco.prey_list: p.queue_free()
	eco.prey_list.clear()
	eco.balance_ecosystem()
	check(eco.care_counts.prey_added == 5 and eco.prey_list.size() == 5, "prey replenishment is recorded at source")
	check(eco.care_counts.pressure_steps == 1 and eco._pressure_active, "predator pressure is recorded")
	for p in eco.predator_list: p.queue_free()
	eco.predator_list.clear()
	for i in 21: eco.spawn_prey(Vector3.ZERO, eco._make_dna())
	eco.balance_ecosystem()
	check(eco.care_counts.predators_added == 2 and eco.predator_list.size() == 2, "predator replenishment is recorded at source")
	eco._record_care("food_added", 1)
	eco._update_label()
	check(eco._care_label.text.contains("Food supplied 1"), "outside food has its own visible count")
	eco.apply_grid_config({"quota": "fallow"})
	eco.balance_ecosystem()
	check(eco.predator_list.is_empty() and eco.care_counts.predators_added == 0, "fallow still prevents predator restock")
	evidence.care_label = eco._care_label.text
	eco.free()
	var failed: Array = checks.filter(func(c): return not c.ok)
	var f := FileAccess.open(OUT + "model-checks.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks": checks, "failures": failed, "evidence": evidence, "scope": "Controlled live-script tests; no headset acceptance"}, "  "))
	f.close()
	print("SWARM_MODELS ", checks.size(), " checks; failures=", failed)
	quit(0 if failed.is_empty() else 1)
