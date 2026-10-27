# QFEP Laboratory transfer

Codex, batch 06. All 20 original placements: 11 in QFEP_Introduction and nine
in QFEP_F_Term. Separate Void trial, unchanged museum scenes and chapter sources.
Each placement is independently editable through the shared floor layout.

## Adjustments

- Explicit tutorial config resolves malformed numeric-prefix tt tokens to
  qfep_introduction and free_energy; raw tokens stay in the inventory.
- The original library contains neither text. These panels do not provide readable
  tutorial content. Writing is deferred.
- Small F/E/lambda pickup spheres and standalone sliders sit at hand height.
- Synthesis stand sits 1.7 m higher to clear its below-origin pylon geometry.
  Its generated subject is still the original tt specimen.

## Checks and controls

The shared probe measures all placements, checks config, shafts, arrival,
sleep/resume, camera ownership and retry in both rigs. The small local probe
checks KEEP and EXPECT 0/1 with real mouse events and synthetic tracked controller
input. Slider values use the source API, not a claimed hand drag. Physical headset
testing and curation remain pending.

- qfep_balance_workbench.gd: four rails and _keep_reading() preserve a reference
  outline and total while live values change. Phase names are authored references.
- shannon_workbench.gd: _set_prediction() changes the guess; prediction_reading()
  keeps source entropy and sampled bits. It is not a free-energy measurement.
- Original term spheres retain XR pickup and identities; complete pickup/throw
  interactions are outside this focused transfer acceptance.
- Orange/apple bench, snap puzzles, dark sphere, crystal, formula and film are
  retained. This pass does not claim exhaustive testing of their controls.
- Science screens retain wave/scatter modes; fallback imagery is not new live data.

## Coordinator acceptance

125 assertions now pass with clean process exit and no engine errors. Isolation
found that the original comparison workbench crashes on teardown when comparison
is enabled after its first build. The catalog now uses the loader's existing
configure_before_ready option for this artifact; KEEP is built once. The original
scene and interaction code are unchanged. Native geometry fits between slabs.
