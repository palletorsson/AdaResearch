from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]

def replace(s, old, new):
    assert old in s, old[:120]
    return s.replace(old, new)

p = ROOT / 'commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.gd'
s = p.read_text(encoding='utf-8')
s = replace(s, 'var _time: float = 0.0', 'var _time: float = 0.0\nvar _archive_elapsed: float = 0.0\nconst ARCHIVE_INTERVAL: float = 0.5\nconst ARCHIVE_CAPACITY: int = 200')
s = replace(s, '##   novelty   uniformly bright across the whole plate, no gradient anywhere.\n##             With the archive empty every point scores identically (see\n##             _evaluate_fitness, which returns a flat 10.0), so this is what\n##             artistic fitness looks like before anyone has been anywhere.', '##   novelty   distance from the nearest remembered position. The starting\n##             population seeds the archive; every addition changes the scoring\n##             surface and requires remembered positions to be scored again.')
a = s.index('\t\tLandscape.NOVELTY:', s.index('func _terrain_fitness'))
b = s.index('\t\tLandscape.RIDGE:', a)
s = s[:a] + '\t\tLandscape.NOVELTY:\n\t\t\treturn clampf(_evaluate_fitness(pos) / (arena_size * 0.5), 0.0, 1.0)\n' + s[b:]
s = replace(s, '\t\t\t\treturn 10.0', '\t\t\t\treturn 0.0')
s = replace(s, 'var d := pos.distance_to(archived)', 'var d := Vector2(pos.x - archived.x, pos.z - archived.z).length()')
a = s.index('\t# For novelty search, periodically archive positions')
b = s.index('\n\nfunc _update_multimesh', a)
s = s[:a] + '''\t# The archive is simulation time, not rendered-frame count.
\tif current_landscape == Landscape.NOVELTY:
\t\t_archive_elapsed += delta
\t\tif _archive_elapsed >= ARCHIVE_INTERVAL and not _particles.is_empty():
\t\t\t_archive_elapsed = fmod(_archive_elapsed, ARCHIVE_INTERVAL)
\t\t\tvar chosen: Dictionary = _particles[_rng.randi_range(0, _particles.size() - 1)]
\t\t\t_novelty_archive.append(chosen["pos"])
\t\t\tif _novelty_archive.size() > ARCHIVE_CAPACITY:
\t\t\t\t_novelty_archive.pop_front()
\t\t\t_rescore_memories()
\t\t\t_color_terrain()
\t\t\t_update_landscape_label()


func _rescore_memories() -> void:
\t# Old scores were earned against another archive. Compare the saved position
\t# and the current position against ONE current record before choosing best.
\t_global_best_fitness = -INF
\tfor p in _particles:
\t\tvar remembered: float = _evaluate_fitness(p["best_pos"])
\t\tvar present: float = _evaluate_fitness(p["pos"])
\t\tif present > remembered:
\t\t\tp["best_pos"] = p["pos"]
\t\t\tremembered = present
\t\tp["best_fitness"] = remembered
\t\tif remembered > _global_best_fitness:
\t\t\t_global_best_fitness = remembered
\t\t\t_global_best_pos = p["best_pos"]


func _reset_memories() -> void:
\t_novelty_archive.clear()
\t_archive_elapsed = 0.0
\tfor p in _particles:
\t\tp["best_pos"] = p["pos"]
\t\tif current_landscape == Landscape.NOVELTY:
\t\t\t_novelty_archive.append(p["pos"])
\t_rescore_memories()
''' + s[b:]
a = s.index('\t# Reset personal bests and global best for new landscape')
b = s.index('\t_color_terrain()', a)
s = s[:a] + '\t_reset_memories()\n' + s[b:]
a = s.index('\n\nfunc _evaluate_fitness')
s = s[:a] + '\n\t_reset_memories()\n' + s[a:]
s = replace(s, '\t_controls.add_slider("INERTIA", inertia, func(v: float):', '\t_controls.add_button("RESET", func():\n\t\t_init_swarm()\n\t\t_color_terrain()\n\t\t_update_landscape_label()\n\t)\n\t_controls.add_slider("INERTIA", inertia, func(v: float):')
s = replace(s, 'l2 = "Distance from the rest."', 'l2 = "Distance from the centre."')
s = replace(s, 'l2 = "Nowhere visited yet."', 'l2 = "Memory: %3d / 200 places." % _novelty_archive.size()')
p.write_text(s, encoding='utf-8')

p = ROOT / 'algorithms/swarmintelligence/ant_colony_optimization/AntColonyOptimization.gd'
s = p.read_text(encoding='utf-8')
s = replace(s, '@export var food_source_count: int = 4', '@export var food_source_count: int = 4\n@export var lesson_seed: int = 20260920\nconst SIMULATION_STEP: float = 1.0 / 60.0\nvar _step_remainder: float = 0.0\nvar _rng := RandomNumberGenerator.new()')
s = replace(s, 'func _init(start: Vector2) -> void:', 'func _init(start: Vector2, rng: RandomNumberGenerator) -> void:')
s = s.replace('randf()', '_rng.randf()')
s = replace(s, '\t\tvel = Vector2(_rng.randf() - 0.5, _rng.randf() - 0.5).normalized() * 0.5\n\t\twander_angle = _rng.randf() * TAU', '\t\tvel = Vector2(rng.randf() - 0.5, rng.randf() - 0.5).normalized() * 0.5\n\t\twander_angle = rng.randf() * TAU')
s = replace(s, '\t_init_pheromone_grid()\n\t_spawn_food_sources()\n\t_spawn_ants()\n\n\n#', '\t_reset_colony()\n\n\n#')
s = replace(s, 'AntState.new(_nest_pos)', 'AntState.new(_nest_pos, _rng)')
s = replace(s, 'func _reset_colony() -> void:\n', 'func _reset_colony() -> void:\n\t_rng.seed = lesson_seed\n\t_step_remainder = 0.0\n\t_stats_active_foragers = 0\n')
s = replace(s, 'func _evaporate_pheromones() -> void:\n\tvar decay := 1.0 - evaporation_rate', 'func _evaporate_pheromones(delta: float) -> void:\n\t# Retain the authored 60 Hz rate while expressing decay in elapsed time.\n\tvar decay := pow(clampf(1.0 - evaporation_rate, 0.0, 1.0), delta * 60.0)')
s = replace(s, '''func _process(delta: float) -> void:
\t_time += delta
\t_evaporate_pheromones()
\t_update_ants(delta)
\t_update_recruitment_signals(delta)
\tif _mode == Mode.COMMUNICATION:
\t\t_update_tandem_pairs(delta)
\t_update_labels()
\t_draw_all()''', '''func _process(delta: float) -> void:
\t# Fixed simulation steps keep random draws, deposits and decay comparable
\t# across normal display rates. Long stalls slow the model instead of
\t# demanding an unbounded catch-up on a headset.
\t_step_remainder += minf(delta, 0.25)
\tvar steps := 0
\twhile _step_remainder + 0.00000001 >= SIMULATION_STEP and steps < 15:
\t\t_step_remainder = maxf(0.0, _step_remainder - SIMULATION_STEP)
\t\t_simulate_step(SIMULATION_STEP)
\t\tsteps += 1
\t_update_labels()
\t_draw_all()


func _simulate_step(delta: float) -> void:
\t_time += delta
\t_evaporate_pheromones(delta)
\t_update_ants(delta)
\t_update_recruitment_signals(delta)
\tif _mode == Mode.COMMUNICATION:
\t\t_update_tandem_pairs(delta)''')
s = replace(s, 'func apply_grid_config(config: Dictionary) -> void:', 'func apply_grid_config(config: Dictionary) -> void:\n\tif config.has("lesson_seed"):\n\t\tlesson_seed = int(config["lesson_seed"])')
p.write_text(s, encoding='utf-8')
print('Repaired PSO archive scoring and ABM repeatable simulation baseline.')
