# AirMusic review — 12 September 2026

Continue the Wavefunctions hall sequence after Effect Sound. Claude's table, eight bars, striker collision path, cradle return and room staging were reviewed and retained. The next hall is `WaveFunctions_Synthesis_Lab`.

## What changed

- The table now samples the bars' generated PCM near each separate audio playback position. Its fixed-scale ribbon sums 512 points over 12 ms, including player gain. The readout lists voices and their playback ages, and reports a display limit if the drawing clamps. The enlarged readout casing accommodates this table's eight voices.
- `ResonatingBar.get_audio_window()` reads existing samples. Audio generation, note tuning, collision response and cradle behavior remain unchanged. `CombinedWaveVisualizer.sample_audio` is opt-in; other placements retain their schematic mode.
- `final.md` and its supporting texts follow contact, same-bar restart, overlapping voices, the assigned length/pitch relationship and the finite ending of an exponential response. Fourteen production-code excerpts were checked; the final's two-line sine/envelope excerpt omits the intervening fade branch, which the prose describes later.
- The book pearl's hero was corrected from `RackAmbientDrone` to `resonating_metallophone`, matching the existing primary role and final anchor. All ten placements / eight types remain. Both museum plan rows were synchronized and derived indexes rebuilt.
- The review page contains actual desktop captures, the book passage and two constructed listening comparisons from the exact exported C4/A4 buffers. One separates them by 0.25 s; the other begins A4 one second into C4. Sources have unit gain, no spatial processing, no normalisation and no clipping. These are not recordings of the probe strikes.

## Evidence

Independent hidden desktop run: `ada_run/air-music-review-2026-09-12/run.json`, started 17:54:27 +02:00, finished 17:55:09, PID 37328, exit 0. The live probe passed 67 checks with zero failures and no engine script errors. The original hand file and Claude's dated evidence were preserved.

The source-window check observed note ages 3.1695 s and 0.2990 s. Independent PCM decoding error was below 1.49e-8, summation error below 3.42e-8, and ribbon-geometry error below 4.26e-9. Existing checks cover strike collisions, restart, overlap, return, routes, desktop approach, cleanup and rebuilding.

The recorded source fingerprints still match every changed production script and probe. After the run, `map_info` was edited for the chapter title and description. Therefore the complete map hash differs from the run receipt; all map layers and all other top-level map data remain identical to the saved pre-review map. The receipt has not been rewritten to conceal this difference.

The effective museum ledger accounts for ten matched/placed artifacts, zero extras and zero refusals in this hall. Its older engine-measured envelope and bake-candidate history remain diagnostic history. Global regeneration also reports pre-existing Tutorial_Disco ragged rows and stale/degraded ledgers in other halls; this review does not certify those halls.

The published files were compared byte-for-byte over HTTP: 57 matches. Browser verification found two loaded 1280-pixel images, two ready audio players (15.25 s and 8.5 s, no errors), no horizontal overflow, and an opening book disclosure. The primary page loaded one written artifact, `resonating_metallophone`, matching the book hero. Scoped `git diff --check` passed.

## Links and reproduction

- Review: http://localhost:3003/research/possible-bodies/air-music.html
- Primary/book: http://localhost:3003/necklace/thread?map=WaveFunctions_AirMusic&role=primary
- Independent runner: `ada_run/review_air_music.py`
- Source probe: `commons/testing/probe_wcn_air_music.gd` (live version generated with `tools.port_wcn_probes_live.port('air_music')`)
- Text helper: `ada_run/write_air_music_text.py`; revisions are based on the saved original, so rerunning does not duplicate paragraphs.
- Review builder: `tools/build_air_music_review.py`
- Before snapshots: `before/`
- Verification and exact publication targets: `verification.json`, `publish-targets.json`, `publication-manifest.json`, `publication-hashes.json`.

## Later visit

No headset or human listening observation is claimed. Test tracked-hand reach, label legibility with several voices, and the returning stick in the headset. Assess secondary caption clutter and ambient sources by standing and listening in the actual hall. The source scope excludes spatial attenuation, bus processing and the output device.

Continue to Synthesis Lab by reviewing Claude's existing implementation and evidence. The bridge is from independently starting voices to deliberately composing the terms of a sound.
