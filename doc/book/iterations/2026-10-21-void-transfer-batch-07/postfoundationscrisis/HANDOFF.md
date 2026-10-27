# Post-Crisis: Applied Limits — transfer record

Two original maps, 11 original placements. Codex owns Algorithmic Bias (5);
Claude Opus delivered Applied Ethics (6) in floor-2.json; Codex reviewed the source
handlers, IDs and config, then merged it into rooms.json.
Every original ID/token/scene is recorded in source-inventory.json. Independent
editable placements share the same rooms/layout in desktop and VR. No curation,
main-tower integration or chapter rewriting. Transfer acceptance is complete.

## Algorithmic Bias — actual source behaviour

- bias_visualizer.gd::_create_vr_controls connects PROF, TRAIT, REDLN to
  analogy_type and ROT to _rotation_enabled. _process spins the specimen only.
  These are authored example positions, not an inference from a trained model.
  Original global keyboard 1/2/3/Space shortcuts are retained; word grab is absent.
- bias_from_inside.gd::_create_controls connects COMPRESSION to
  _on_perspective_changed and READ/CLOSE to _reading.visible. _apply_perspective
  interpolates two seeded arrangements, retaining all 24 terms and their sizes.
  It never moves the visitor. The source stand reaches 1.085 m below its origin;
  placing its origin 1.085 m above the slab puts the rail at hand height.
- filled_pocket.gd::_rebuild computes a flood fill, route and unreachable cells;
  it has no player control. Wall/door are authored config axes. Original small
  scale and 0.95 m mounting height are preserved.
- situated_readout.gd::_populate_from_position selects a fixed example from a
  position hash when no verdict override is supplied. Relocation can change the
  selected example; the numbers are authored, not a classification of the player.
  This original placement is not interactive (the default remains false).
- science_screen uses its original scatter mode; without a source instrument
  connection, the screen uses its original generic fallback illustration.

BiasVisualizer's below-origin plinth is raised 0.72 m. The floor is an inventory
arrangement with clear shafts and arrival, not a finalized educational path.
All source scales are one. Chapter and map source hashes are checked separately.

## Acceptance scope

Shared native checks plus pointer controls and compression API assertions are
in probe.gd. Slider API checks are not a physical drag. Physical headset review,
full interaction playtesting and curation remain pending.

## Coordinator review of Applied Ethics

See HANDOFF-floor-2.md for Claude's original, frozen record. Its six placement IDs
and source config matched the inventory. The source miniature-room controls call
real plan/palette rebuilds; configure_before_ready now initializes HEAD/NEUTRAL
once. The native probe tests CIRCLE, COLOUR and restoration with both pointers.

The plaque's advance_statement() is real, but the old Area3D mouse picking and
unconnected grab callback do not provide the Void control route. The local
godel_plaque_void adapter subclasses the original script and adds NEXT using the
same rack-button interface as other artifacts. The original plaque geometry,
statements, signals and glow remain. No other placed Void artifact used this
catalog key at integration time. Original source script/scene are untouched.

The malformed five-field tt token is retained verbatim in inventory. Its tutorial
identifier is not passed by the original parser. Native screenshots correct the
handoff's word "blank": both panels display the bundled generic TextUIControl
content, not the requested qfep_critical tutorial. Writing or selecting replacement
text is deferred. The synthesis stand likewise contains the source tt hero.
Neither is claimed to show the intended map tutorial.
Source crowding around the floor-2 instruments remains for later curation.

Native bounds found the synthesis stand extended 1.6755 m below its origin.
Its height is now 1.7 m; this correction supersedes the floor-2 fragment's height
zero. The probe verifies the complete stand sits above the slab. floor-2.json is
the frozen worker delivery; rooms.json is the accepted editable layout.

## Completed acceptance

- 68 source preservation checks: all 11 original placements, config and source
  map/chapter hashes retained. Schema passes, with original floor-2 access overlap.
- 97 shared/focused native checks: desktop mouse and synthetic tracked XR pointer,
  real geometry, source configuration, safe arrival, both open shafts, descent,
  floor sleep/resume and retry. Process exit 0, no engine errors. No measured
  slab/ceiling fit conflicts after the stand correction.
- 46 native model exports, including reusable props/structure. No export failures.
  Original Viewport2Din3D content is captured; web models are static snapshots.
- 14 editor checks: all 11 artifact models move/copy/turn independently; actual
  save reaches project and Desktop backup; stale revision rejected; layout restored.

Physical headset, the ROT button, manual slider dragging, all possible room plans
and exhaustive interactions have not been playtested. Curation remains pending.
The native source retains its original codeDisplay fallback lookup log messages;
the fallback succeeds in showing the generic scene content, as screenshots show.
