"""Exercise real button signals in the isolated museum and capture the held result."""
from pathlib import Path
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT/'ada_run/encounter_pilot/CA_AgentsCircuits'
base = (ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
# Keep the actual placement, rendering and node discovery from the existing probe.
# This local copy adds only bounded interaction checks before taking the pictures.
setup = '''
	var explorer: Node3D = nodes.get("ca_rule_explorer") as Node3D
	var outcomes: Array = []
	if explorer == null:
		failures.append("Rule explorer missing")
	else:
		var step_button: Node = explorer.get_node("NeighbourStudy/StudyControls/Btn_0/InteractableAreaButton")
		var run_button: Node = explorer.get_node("NeighbourStudy/StudyControls/Btn_1/InteractableAreaButton")
		var seed_button: Node = explorer.get_node("NeighbourStudy/StudyControls/Btn_2/InteractableAreaButton")
		outcomes.append({"check":"starts paused at Rule 90, single seed", "passed": explorer.rule == 90 and not explorer.auto_run and not explorer.seed_pair and explorer.generation == 0})
		for i in range(7): step_button.emit_signal("button_pressed", step_button)
		var expected := [9,11,13,15,17,19,21,23]
		var occupied: Array = []
		for i in explorer.cells_x:
			if explorer._current_row[i]: occupied.append(i)
		outcomes.append({"check":"STEP builds Rule 90 generation seven", "passed": explorer.generation == 7 and occupied == expected, "occupied":occupied})
		run_button.emit_signal("button_pressed", run_button)
		await create_timer(0.8).timeout
		run_button.emit_signal("button_pressed", run_button)
		outcomes.append({"check":"RUN advances then holds", "passed": explorer.generation > 7 and not explorer.auto_run, "generation":explorer.generation})
		seed_button.emit_signal("button_pressed", seed_button)
		outcomes.append({"check":"SEED resets to adjacent pair", "passed": explorer.seed_pair and explorer.generation == 0 and explorer._current_row.count(true) == 2 and not explorer.auto_run})
		step_button.emit_signal("button_pressed", step_button)
		outcomes.append({"check":"pair produces four cells after one step", "passed": explorer.generation == 1 and explorer._current_row.count(true) == 4})
		seed_button.emit_signal("button_pressed", seed_button)
		outcomes.append({"check":"SEED returns to central cell", "passed": not explorer.seed_pair and explorer.generation == 0 and explorer._current_row.count(true) == 1})
		for i in range(7): step_button.emit_signal("button_pressed", step_button)
		outcomes.append({"check":"desk feet meet floor and controls at standing height", "passed": absf(explorer.global_position.y-origin.y-1.04)<0.005 and step_button.global_position.y-origin.y>1.0 and step_button.global_position.y-origin.y<1.2})
	for outcome in outcomes:
		if not outcome.passed: failures.append(str(outcome.check))
	report["controls"] = outcomes
	report["interaction_scope"] = "Live button signals and actual process loop; no simulated hands or headset reach test. Captures show single-seed generation seven held via STEP."
	spec["walks"] = []
	spec["rays"] = []
'''
needle = '\tawait physics_frame\n\tvar space :='
assert base.count(needle)==1
source = base.replace(needle, setup+'\n'+needle).replace('folder + "report.json"', 'folder + "controls-report.json"')
(HERE/'probe_controls.gd').write_text(source, encoding='utf-8')
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path',str(ROOT),
           '--xr-mode','off','--no-window','--rendering-method','gl_compatibility',
           '--audio-driver','Dummy','--log-file',str(HERE/'controls-engine.log'),
           '--script','res://doc/book/iterations/2026-09-19-ca-restoration/probe_controls.gd',
           '--','res://ada_run/encounter_pilot/CA_AgentsCircuits/spec.json']
before = hashlib.sha256((ROOT/'commons/scenes/endless_museum.gd').read_bytes()).hexdigest()
with (HERE/'controls-process.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                            timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
assert before == hashlib.sha256((ROOT/'commons/scenes/endless_museum.gd').read_bytes()).hexdigest()
print('Controls exit:',result.returncode)
print((HERE/'controls-process.log').read_text(encoding='utf-8')[-800:])
raise SystemExit(result.returncode)
