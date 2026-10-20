from pathlib import Path
import json, hashlib, datetime, re

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
def load(name): return json.loads((HERE/name).read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
freeze=load('freeze_manifest.json')
followup=load('followup_02_frozen.json')
pred=load('predictions.json')
attempts=[]
for number in [1,2]:
    prefix=f'attempt_{number:02d}'
    outcome=load(prefix+'_engine.json')
    run=load(prefix+'_run.json')
    stderr=(HERE/(prefix+'_stderr.log')).read_text(encoding='utf-8')
    attempts.append(dict(number=number,run=run,outcome=outcome,script_error_lines=stderr.count('SCRIPT ERROR:'),error_lines=len(re.findall(r'^ERROR:',stderr,re.M)),warning_lines=len(re.findall(r'^WARNING:',stderr,re.M)),stderr_clean=not stderr.strip(),sha256={suffix:sha(HERE/(prefix+suffix)) for suffix in ['_run.json','_engine.json','_stdout.log','_stderr.log']}))
source_hashes={name:sha(HERE/name) for name in ['surface_triangle.gd','surface_study.gd','triangle_record.gd','point_body.gd','line_skin.gd']}
unchanged={name:value==freeze['student_file_sha256'][name] for name,value in source_hashes.items()}
assert all(unchanged.values())
assert sha(HERE/'probe.gd')==freeze['student_file_sha256']['probe.gd']
assert sha(HERE/'predictions.json')==freeze['student_file_sha256']['predictions.json']
assert sha(HERE/'probe_delayed.gd')==followup['probe_sha256']

results={
 'created_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'scope':'NonEuclidean_Spaces frozen tutorial/reflection reconstruction; source listings copied verbatim; prepared declared infrastructure only',
 'status':'Reconstruction and all asserted lesson behavior passed; first-run harness preload compilation failures preserved and resolved by independently predicted delayed-load follow-up; remaining prepared-project startup diagnostics disclosed.',
 'frozen_manifest_sha256':sha(HERE/'freeze_manifest.json'),
 'freeze':freeze,
 'followup_freeze':followup,
 'predictions':pred,
 'source_sha256':source_hashes,
 'source_unchanged_after_freeze':unchanged,
 'input_hashes_still_match':{name:sha(ROOT/name)==value for name,value in freeze['input_sha256'].items()},
 'attempts':attempts,
 'counts':{'engine_runs':2,'attempt_01_passed':103,'attempt_01_failed':0,'attempt_02_passed':109,'attempt_02_failed':0,'total_assertion_executions':212,'distinct_assertion_intentions':109,'numerical_assertions_per_run':32,'host_assertions_attempt_01':71,'host_assertions_attempt_02':77,'repeated_release_frame_assertions_per_run':12,'new_dependency_health_assertions_attempt_02':6},
 'lesson_defects_observed':[],
 'environment_and_harness_findings':[
  {'finding':'Early preload from a --script SceneTree main led to unresolved XRToolsUserSettings/XRToolsRumbleManager and cascading dependency compilation errors despite exit 0 and passing synthetic interaction assertions.','followup':'After three startup frames, dynamically load exact unchanged scene. All 103 original checks and 6 added component-health checks pass; no script errors.','interpretation':'Strong evidence for harness startup loading order; not established as a defect in tutorial scene lifecycle. Original first attempt remains non-clean.'},
  {'finding':'Both runs retain ERROR Unrecognized UID uid://rwex60pqapc and a Jolt custom solver-bias warning.','interpretation':'No evidence these invalidated measured lesson behavior; not investigated outside permitted dependency scope. Whole-run stderr is not clean.'},
  {'finding':'Minimal host has no supplied player, so StuckDetector prints player-not-found notice.','interpretation':'The test scene intentionally reconstructs the declared Node3D attachment; museum/player behavior is untested.'}
 ],
 'tutorial_reflection_consistency':[
  'Both distinguish coordinate-record continuity from equality of world position, length or angle; tested preservation of pairs and point IDs across modes.',
  'Both distinguish recorded surface corner from held body; tested off-surface hold, chart inversion, refusal and release.',
  'Both limit constructed exercise to plane/sphere, distinguish existing disk encounter and separate sketch slider, and avoid claiming room/player metric changes. Museum claims not independently inspected.',
  'Both present angle excess as a measured relation rather than a proof or independent curvature integration. Numerical checks support stated reference triangle and tangent construction.'
 ],
 'dependency_assessment':{'missing_student_listings':[],'five_complete_listings':True,'declared_external_infrastructure':['prepared project XRToolsPickable and transitive global classes/autoloads','commons/interactables/push_button.tscn and transitive scripts/resources'],'setup_limit':'A blank project is insufficient, as the tutorial explicitly says. --script probe should defer scene load until startup to avoid early singleton symbol failures. No import/editor repair performed.','uninspected':['canonical study/museum launcher','installed hall artifacts','author tests/results','other reports/prior assessments','external linked mathematical sources']},
 'reading_assistance_trail':freeze['reading_assistance_trail']+followup['new_reading_trail']+['Read only own generated logs/results after engine runs; project autoload startup notices are incidental execution output, not source inspection.','No outside advice or expected-results files used; parent received freeze/defect updates but supplied no solution material.'],
 'limits':pred['limits']+['Mesh visibility and label strings checked as live engine state, not screenshot legibility or visual quality.','The actual supplied button callback chain ran, but ray intersection and physical hand poke were not exercised.','Desktop held()/on_desktop_grab/on_desktop_drop path was exercised with sustained synthetic transforms; XRTools physical pickup/grab-driver behavior and headset performance were not established.','Assertions include repeated per-frame stability checks; 109 is not a count of independent learner trials.']
}
(HERE/'results.json').write_text(json.dumps(results,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

final=attempts[1]['outcome']
report=f'''# NonEuclidean_Spaces: independent ghost-student reconstruction

The five printed listings reconstructed successfully without changes. The completed follow-up ran the actual initialized study in Godot 4.6 and passed **109/109 assertions**. The original attempt passed its 103 assertions but also had XRTools dependency compilation errors, so it is preserved as qualified evidence. A separately frozen loading-order hypothesis removed those script errors without modifying the lesson or infrastructure. Both runs still contain the startup diagnostics described below.

This is an **experienced AI programmer reconstructing printed listings**, not a novice learner study. It establishes reproducibility and the tested behaviors within a prepared project; it does not measure instructional success for a beginner.

## Evidence and freeze

- Initial prediction/source freeze: `{freeze['frozen_utc']}`, before any Godot execution.
- Initial manifest SHA-256: `{sha(HERE/'freeze_manifest.json')}`.
- Five script files match the tutorial's marked fenced blocks byte for byte. They remain unchanged after both runs.
- Initial probe, initial predictions and all first-run output remain unchanged. Follow-up has separate source, prediction manifest, stdout, stderr and run metadata.
- First attempt: exact engine exit **0**, 103 passed / 0 failed, {attempts[0]['script_error_lines']} `SCRIPT ERROR` lines.
- Follow-up: exact engine exit **0**, 109 passed / 0 failed, {attempts[1]['script_error_lines']} `SCRIPT ERROR` lines; six added supplied-component script-health checks all passed.
- Counts are 32 numerical and 71 original host assertions, plus six follow-up dependency checks. These include 12 repeated release-frame checks per run and repeated button transition checks. There were two engine runs and 212 assertion executions, not 212 independent experiments.

Machine-readable assertions, values, command arrays, exact exits, input/source hashes and reading trail are in `results.json`. Immutable evidence includes `freeze_manifest.json`, `predictions.json`, `attempt_01_*`, `followup_02_frozen.json`, and `attempt_02_*`.

## What I reconstructed

`surface_triangle.gd`, `surface_study.gd`, `triangle_record.gd`, `point_body.gd`, and `line_skin.gd` came only from the frozen tutorial. `reconstructed.tscn` attaches the host script to a unit-scale Node3D named SurfaceStudy, as directed. The test applies translation `(2.3, -0.4, 1.7)` and rotation `(0.23, 0.61, -0.17)` radians without scale changes.

Declared infrastructure was used in place: XRTools and `commons/interactables/push_button.tscn` with its needed dependencies. No canonical study code, museum launcher, author tests, author expected results, previous assessments or other reports were read. No source repair, import or editor regeneration was performed.

## Predictions compared with results

The numerical predictions used an independent Python double-precision spherical cosine law from central arc lengths. They did not reuse the tutorial's tangent-angle implementation as their oracle.

| Construction | Frozen prediction | Engine observation |
|---|---:|---:|
| Reference plane, `(0,0),(1,0),(0,1)` | angles 90°, 45°, 45°; sum 180° | 90°, 45°, 45°; sum 180° |
| Reference sphere | sum 199.471220634491° | {final['observations']['reference_sphere']['sum']:.12f}° |
| Own variation: halve reference chart coordinates | sphere sum 186.379370208443° | {final['observations']['variation_half_sphere']['sum']:.12f}° |
| Own variation plane | same three angles; AB length 0.5 | same angles; length 0.5 |
| Own variation sphere AB arc | 0.463647609001 rad, not half of π/4 | 0.463647632948 rad |
| Default sphere | sum 213.456909662684° | 213.456907191725° |

The independent variation contracts the chart toward its north-pole centre. It preserves planar angle shape while changing the spherical triangle's angular excess, reducing the excess from about 19.47122° to 6.37937°. Its spherical arc length does not scale by the same factor. The host's final live readout was `Sum 186.38° / difference from 180°: +6.38°`; the sphere was visible and the flat face absent. This is checked engine state, not a human visual inspection.

Geometry checks covered all 75 default spherical edge samples: endpoints, unit radius and containment in the appropriate great-circle plane. Maximum unit-radius error was about 1.19e-7 and plane-dot error 2.98e-8. Tangents were unit and normal-perpendicular. Direct north-pole/equator directions yielded three 90° angles, explicitly outside the hand chart. Chord-sum refinement at 1/24/96 segments approached the π/4 central arc from below while leaving analytical measurement unchanged. Degenerate/coincident/near-collinear inputs refused readings in both modes and recovered on separation; nonpositive segment counts clamped; zero-length line rendering recovered after hiding.

## Full initialized host and actual callback chain

The live scene contained three initialized frozen point bodies with mesh/collision shapes, 72 cylinder edges, all labels/readout, the plane/sphere meshes, face and three supplied buttons. Host positions matched the transformed local frame within 3.43e-7 metres. All final cylinder endpoints agreed with their intended samples within 1.20e-7 metres.

Button tests executed `XRToolsPointerEvent.report → interactable_area_button_pointer.pointer_event → XRTools area enter/exit → button_pressed/button_released → push_button.gd → host callback`. The real supplied callback chain and its pressed/released states ran. The event source was synthetic: no mouse, ray hit, hand collision or physical pointer was used. Keyboard tests used `Input.parse_input_event` for P, S and R, through the engine input pipeline.

The hand fixture called the tutorial's desktop grab/drop hooks and continuously wrote a target world transform in both render and physics processing. It moved the actual rigid-body point repeatedly across frames; this was not a single teleport. In the follow-up it executed {final['observations']['synthetic_driver']['render_ticks']} render ticks and {final['observations']['synthetic_driver']['physics_ticks']} physics ticks. The host's own `_process` and `_physics_process` ran normally.

Tests verified transformed spherical inversion, bounds clamping, off-surface held body versus recorded corner, mode and reset refusal while held, and lower-chart refusal retaining the last record with a visible readout string. Both sides of the 0.02 guard were tested, plus the exact local boundary. A valid position recovered the readout. Every one of six later physics observations in each mode matched the released record. Mode changes preserved coordinate pairs and PointBody instance IDs. Reset retained the mode. Plane degeneracy removed the face/angle reading and recovered correctly on separation.

These tests do **not** establish real desktop pointing, XRTools grab-driver tracking, hand poke, headset interaction, visual legibility, comfort or frame rate. The declared player/museum was not loaded or inspected; a separate museum visit must supply that evidence.

## First-attempt failure and independent follow-up

The initial `--script` SceneTree harness preloaded the attached host scene at script load time. Although all 103 assertions passed and the process returned zero, stderr reported unresolved `XRToolsUserSettings` and `XRToolsRumbleManager`, cascading into dependency compilation failures, including HandPoseArea and Rumbler. Exit zero was not treated as proof of healthy dependencies.

After seeing those diagnostics, I read only the named XRTools transitive code: `rumbler.gd` and lines 501–540 of `player_body.gd`. I froze a new hypothesis at `{followup['frozen_utc']}`: scene loading after three startup frames should let the singleton symbols resolve. `probe_delayed.gd` changes only the harness loading time and adds six checks that each supplied HandPoseArea/Rumbler script is attached and can instantiate. The five lesson files are unchanged. The follow-up met all original behavioral predictions and all six new checks, with no script compilation errors. This supports a harness startup-order explanation; it does not establish a defect in the tutorial's normal scene lifecycle.

Both stderr logs retain `ERROR: Unrecognized UID: "uid://rwex60pqapc"` and a Jolt warning about custom shape solver bias. Both stdout logs include unrelated prepared-project startup notices, including StuckDetector finding no player in the minimal test scene. I did not investigate or modify unrelated project configuration. Neither whole-run stderr is clean.

## Tutorial/reflection consistency and dependencies

The tutorial and final reflection agree on the tested distinctions: the coordinate record persists while world positions/angles can change; held bodies may leave the recorded surface; release restores the record; chart refusal is an interface limit; straight spherical edges use tangent/great-circle geometry rather than chords. The reflection's account of changing the rule is supported by the reference and contraction examples.

Both texts distinguish the reconstructed plane/sphere study from the installed bench's three examples, separate the disk encounter and surface slider, and avoid claiming that the player's museum floor adopts a different metric. Those installed-hall claims were not checked in this reconstruction. Linked external mathematical sources were not read; the report does not treat a numerical example as a Gauss–Bonnet proof or curvature integration.

No missing student-code listing was found. XRTools, the push-button scene and their prepared-project dependencies are explicitly declared, so the packet correctly warns that a blank project is insufficient. The observed early-preload issue matters for writing a `--script` test harness; delayed scene loading is sufficient in this environment. No corrective change to the tutorial's five files was required. Physical XR functionality remains an untested dependency capability.

The evidence supports successful reconstruction by this experienced AI within the declared environment. It does not by itself establish that a novice can understand, type, navigate, or use the lesson unaided.

## Exact runs

Both commands ran via `python -X utf8 run_engine.py`, `subprocess.run(..., creationflags=CREATE_NO_WINDOW, timeout=60)`, UTF-8 logs, and no editor/import repair. The exact command arrays and timestamps are saved in each `attempt_*_run.json`.

```text
{attempts[0]['run']['windows_command_line']}
{attempts[1]['run']['windows_command_line']}
```

The reading/assistance trail and all input/dependency/source hashes are preserved in `results.json`. Original predictions were not revised after either execution.
'''
(HERE/'REPORT.md').write_text(report,encoding='utf-8',newline='\n')
print(json.dumps({'report':str(HERE/'REPORT.md'),'results':str(HERE/'results.json'),'hashes_preserved':all(unchanged.values()),'attempt_counts':[(a['number'],a['outcome']['assertion_count'],a['outcome']['fail_count'],a['script_error_lines']) for a in attempts]},indent=2))
