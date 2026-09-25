extends SceneTree
## probe_novelty_finite.gd — book_machinelearning.016, 2026-09-25.
##
## Prediction: non_teleological_evolution pays energy only for UNVISITED cells of a
## 20 x 20 grid, so fresh ground is finite (400 cells x 0.8) against a drain of 0.15 a
## second per body, and the population, having filled its ceiling, drains toward zero.
## The code does forget: one random cell is cleared every 120 DRAWN frames
## (`Engine.get_frames_drawn() % 120 == 0`), one cell every two seconds at 60 fps.
##
## THE FIRST VERSION OF THIS PROBE MEASURED ANOTHER GAME. It drove _process() by hand,
## headless; headless draws no frames, so frames_drawn stayed at 0 and the clearing
## rule fired on EVERY call - sixty cells a second instead of one every two - and the
## population sat at its ceiling for fifteen minutes. This version runs the artifact's
## own frame loop, WINDOWED, under --fixed-fps 60 (a fixed 1/60 s delta with real-time
## sync off), so frames are drawn and counted and the clearing rule runs at its live
## rate. It logs population, visited fraction and total energy every LOG_EVERY seconds
## of simulated time.
##
## Run (windowed on purpose):
##   python tools/godot_watchdog.py --expect=ada_run/probes/novelty_finite.json --grace=400 --stall=400 -- \
##     C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe --path . --xr-mode off --fixed-fps 60 \
##     --resolution 320x240 --script res://commons/testing/probe_novelty_finite.gd

const OUT := "res://ada_run/probes/novelty_finite.json"
const SCENE := "res://algorithms/machinelearning/non_teleological_evolution/non_teleological_evolution.tscn"
const SIM_SECONDS: float = 600.0
const LOG_EVERY: float = 5.0


func _init() -> void:
	var root: Node = get_root()
	var scene: PackedScene = load(SCENE)
	var node: Node = scene.instantiate()
	root.add_child(node)
	await process_frame
	var frames0: int = Engine.get_frames_drawn()
	print("[novelty] built: population %d, grid cells %d, visited %.3f, frames_drawn %d, fixed fps %s" % [_population(node), _grid_cells(node), _visited_fraction(node), frames0, str(Engine.get_frames_per_second())])
	var rows: Array = []
	var next_log: float = 0.0
	var peak_pop: int = 0
	var peak_t: float = 0.0
	var extinct_t: float = -1.0
	var min_after_peak: int = 999999
	var t: float = 0.0
	while t < SIM_SECONDS:
		await process_frame
		t = float(node.get("_time_elapsed"))
		var pop: int = _population(node)
		if pop > peak_pop:
			peak_pop = pop
			peak_t = t
		if peak_pop > 0 and t > peak_t:
			min_after_peak = mini(min_after_peak, pop)
		if pop == 0 and extinct_t < 0.0:
			extinct_t = t
		if t >= next_log:
			var row: Dictionary = {"t": snappedf(t, 0.1), "population": pop, "visited_fraction": _visited_fraction(node), "energy_total": snappedf(_energy(node), 0.01), "frames_drawn": Engine.get_frames_drawn() - frames0}
			rows.append(row)
			print("[novelty] t=%6.1f  pop=%3d  visited=%.3f  energy=%.2f  frames=%d" % [row["t"], pop, row["visited_fraction"], row["energy_total"], row["frames_drawn"]])
			next_log += LOG_EVERY
		if extinct_t >= 0.0 and t > extinct_t + 60.0:
			break
	var final_visited: float = _visited_fraction(node)
	var frames: int = Engine.get_frames_drawn() - frames0
	var report: Dictionary = {
		"probe": "novelty_finite", "date": "2026-09-25", "mode": "windowed, --fixed-fps 60, artifact's own _process",
		"sim_seconds": snappedf(t, 0.1), "frames_drawn": frames, "frames_per_sim_second": snappedf(float(frames) / maxf(t, 0.001), 0.1),
		"grid_cells": _grid_cells(node), "cells_cleared_per_second_by_rule": snappedf(float(frames) / maxf(t, 0.001) / 120.0, 0.001),
		"peak_population": peak_pop, "peak_at_s": snappedf(peak_t, 0.1), "min_population_after_peak": min_after_peak,
		"extinct_at_s": snappedf(extinct_t, 0.1), "final_population": _population(node), "final_visited_fraction": final_visited,
		"rows": rows,
	}
	if frames < 10:
		report["verdict"] = "INVALID: no frames drawn (%d) - the clearing rule did not run at its live rate; run windowed" % frames
	elif extinct_t >= 0.0:
		report["verdict"] = "extinct at t=%.0f s after a peak of %d at t=%.0f s; the ground clears about %.2f cells a second" % [extinct_t, peak_pop, peak_t, report["cells_cleared_per_second_by_rule"]]
	else:
		report["verdict"] = "not extinct within %.0f s: peak %d at t=%.0f s, lowest after the peak %d, final %d at visited %.3f; the ground clears about %.2f cells a second" % [t, peak_pop, peak_t, min_after_peak, report["final_population"], final_visited, report["cells_cleared_per_second_by_rule"]]
	print("[novelty] VERDICT: ", report["verdict"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/probes"))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("[novelty] wrote ", OUT)
	quit()


func _population(node: Node) -> int:
	var c: Array = node.get("_creatures")
	return c.size() if c != null else -1


func _energy(node: Node) -> float:
	var c: Array = node.get("_creatures")
	var e: float = 0.0
	for d in c:
		if d is Dictionary and d.has("energy"):
			e += float(d["energy"])
	return e


func _grid_cells(node: Node) -> int:
	var g: Array = node.get("_visited_grid")
	var n: int = 0
	for col in g:
		n += col.size()
	return n


func _visited_fraction(node: Node) -> float:
	var g: Array = node.get("_visited_grid")
	var n: int = 0
	var v: int = 0
	for col in g:
		for cell in col:
			n += 1
			if cell:
				v += 1
	return float(v) / maxf(1.0, float(n))
