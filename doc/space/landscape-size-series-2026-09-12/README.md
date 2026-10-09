# Landscape size series and working article — 12 September 2026

User approved developing the landscape thread as an article. Recorded a protocol before the run, executed the complete 18-trial series in a hidden standalone Godot workshop, retained all records/captures, and wrote a roughly 1,600-word illustrated working article. No hall geometry, primary assignments, artifact behaviour or final.md changed in this pass. No commit.

Read locally: http://localhost:3003/research/possible-bodies/landscape-article.html

## Evidence

- Runner: `commons/testing/run_landscape_size_series.gd`.
- Protocol: `doc/research/possible-bodies/landscape-size-protocol.md` (written before collecting results).
- Raw record: `ada_run/landscape-size-series/results.json`; exact published copy `landscape-size-results.json`.
- Godot process 6972 completed: 18 trials, zero reported failures. Log `ada_run/landscape-size-series.log`. Compatibility shader-cache write warnings are not trial failures; no script errors reported.
- Godot 4.6 stable, GodotPhysics3D, 60 Hz, time scale 1. Radii 45/75/105 mm, seeds 1729/1730/1731, two repeats, four simultaneous trays, 32 bodies per tray, 720-tick deadline.
- Source hashes match before/after run and at analysis. Same sampled terrain within each seed; sine samples identical across all seeds. All initial centres identical across all 18 trials.
- Outlet counts: sine 8 at radius 45 mm, 5 at 75 mm, 5–6 at 105 mm; random heights 0–1 / 0 / 0; Perlin and Worley F1 32 at every tested size. All other exits zero.
- 35/36 paired tray repeats have matching final counts. Sine, seed block 1731, radius 105 mm: 6 then 5. Cause not isolated. Preserve discrepancy; do not claim fully deterministic contact trajectories.
- Sine uses one underlying geometry, not three independent landscapes. Bodies collide; releases are not independent replicates. Ordered selected-seed pilot, no significance tests. Mass fixed at 0.1 kg, so this is not constant-density scaling.
- Counts concern the declared deadline, not permanent trapping. No concealment, player traversal, entropy, free energy or general freedom threshold measured. Historical Unity results have different/partially unspecified conditions and are not numerically replicated.

## Files and rebuilding

`tools/analyze_landscape_size_series.py` validates the data and generates exact raw copy, analysis JSON, 72-row tray CSV, 48-row paired-contrast CSV and two plots (SVG/PNG). 311 integrity checks passed. Run only when raw results or analysis/plot code change.

`doc/research/possible-bodies/landscape-article.template.md` is the authored draft. `tools/build_landscape_article.py` renders its generated table/method, copies the three preselected captures, creates a source extract ZIP and adds an article link to the landscape thread. The older `ada_run/build_landscape_thread.py` also preserves that link on rebuild.

Publication manifest: 17 files. All copies in `ada_encyclopedia/public/research/possible-bodies` match source bytes over HTTP. All 16 unique local article links/assets return 200. Desktop browser checked at 1280 px: no page overflow, all three figures loaded, method disclosure opens with all 18 individual trials. Main layout, plot and actual Godot capture visually inspected. Browser connection now works through the installed Browser runtime.

## Continue

The article remains a working draft, with sources and complete evidence available. The controlled apparatus remains a standalone prototype, not placed in the museum. Next concrete curriculum action remains fitting and verifying a sine-only physical tray beside the existing Sine Space encounter while preserving its corridor as primary. A future full-size walking/occlusion experiment needs its own declared bodies, starts, destinations and observer settings. Headset evaluation remains deferred while the user is remote.
