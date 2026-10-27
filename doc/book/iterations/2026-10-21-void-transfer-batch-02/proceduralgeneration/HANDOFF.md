# Procedural Generation / transfer before curation

Four original placements on two source-map floors. `source-inventory.json` retains
the original scene paths, token strings, grid cells, stable placement IDs and
source map/chapter hashes. Every placement remains a separate lab-editor object.
The original artifact scripts, chapter texts and curated main tower are unchanged.

## Floor 1: PG_Genetic_Evolution

The original GeneticProgramming scene receives `lesson:true`. Its existing
SelectionLesson keeps the six candidates, current score, held specimen and six
physical controls. TARGET changes the criterion, RING reveals the estimator's
omission, STEP advances a generation, HOLD keeps an independent copy, RESET
restores the candidates, RULE exposes the formula. The original Science Screen
retains `mode:grid`; its generic fallback is not a reader of candidate fitness.

## Floor 2: PG_Space_Colonization

The original SpaceColonizationAlgorithm scene receives `lesson:true`. STEP uses
the original growth kernel; FIELD changes the known point field; POLICY compares
tips and persistent sites; HOLD retains a geometric specimen; RESET and RULE keep
their original meanings. The branch-decision film is a separate original monitor
with its own private illustration viewport.

## Transfer fit and limits

- This isolated trial has seven-metre storeys to preserve the original request
  field (six metres plus its display origin and point radius) without clipping
  it against a slab. This is a transfer envelope to revisit during curation;
  the main tower is unchanged. The original unit step remains half a metre.
- Both large studies sit west of the default floor sign. Source controls move
  and rotate with their scene; the diagram is not a decorative substitute.
- The museum's observation ramps depend on its vestibule/grid structure and do
  not generate in Void. The Void floor provides support. Generated candidates
  and branches still do not supply collision. No replacement route was curated.
- The original estimator's volume approximation and ignored torus remain visible
  as part of the lesson. No algorithm correction is hidden in this transfer.
- Original scene lamps remain, while shared import handling suppresses standalone
  world cameras/suns. Lighting, spacing and scene performance await curation.

## Validation

`probe.gd` exercises actual desktop mouse and synthetic tracked-XR button input,
independent held specimens, full-height field clearance, kernel branching,
camera ownership, shaft descent, sleeping previous floor and checkpoint retry.
Repeated kernel stepping is identified separately from physical input. Results
and native screenshots are in `evidence/`. Physical headset play is not tested.

Coordinator commands:

```
python tools/audit_void_transfer.py proceduralgeneration
python tools/validate_void_rooms.py --trial=proceduralgeneration --editor
python tools/test_transfer_native.py proceduralgeneration
python tools/export_void_trial.py proceduralgeneration
node tools/test_void_transfer_editor.cjs proceduralgeneration
```

Editor saves use the same rooms/layout as desktop and VR and mirror to
`C:/Users/palle/Desktop/Ada Void/trials/proceduralgeneration/rooms.json`.
The browser models are native geometry snapshots; Godot runs the behaviour.
