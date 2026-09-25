# Random_Game — decisions (targeted revision)

**Verdict:** targeted revision. The audit's verdict stands. Ten paragraphs were touched: nine sentences reworded, five sentences added. Structure, title, questions, all four code excerpts, every `<!-- @token -->` anchor and the closing handover to Noise are unchanged. The word count went from 1440 to about 1650.

## Preserved
Every sentence on the audit's Preserve list: the stored deadline, the tablet as an account of a wait, the ring/beacon/number triad, the collider sequence, "Pressing a button reveals an existing choice", the guarantee written before the index, STOP/CLEAR, the floor lines as initial centres, "The crossing drew a duration…", "The places are dependable while the rhythm is not", and the whole closing paragraph. The close hands Noise a question it takes up (Random_Noise_Types opens on "The stones behind us could disappear…"), so it was left alone.

## Changes (audit + second-agent re-check agree)
1. **Prism → plinth (two sentences).** "a prism carries a five-digit number" → "a lit prism stands on a plinth whose face carries a five-digit number". "The prism names…" → "The plinth names…". Evidence: random_cycle_cube.gd:957 (plinth 0.54×0.80×0.54), 963-968 (PrismMesh "Form" at y 0.98), 977-990 (Label3D "SeedCut" at y 0.52, z −0.28, on the plinth face), 1126 (text "SEED\n%d").
2. **Gold rings → one ring at arrival.** "Watch the gold rings. They light during the final 1.2 seconds of a standing wait. Press CUE and try observing without them." → singular, middle stone, "without it". Evidence: _spawn_stones never builds a crown (random_cycle_cube.gd:1030-1050). Only _apply_stand builds one, on self (718-722, reached only under stand:chasm, 216-218). The cue branch of apply_grid_config needs _built (584-588), and the museum configures before the tree (endless_museum.gd:13097-13102). toggle_cue builds crowns on all stones (1162-1170). Window and 1.2 s: 670, 1092. Added "Press CUE again and all three stones carry a ring." so a visitor who presses twice is not contradicted.
3. **REPLAY does not restore the arrival rhythm.** "…whose first waits have been restored." → re-checker's wording: "…whose seeded waits have restarted: every REPLAY deals the same first waits, though the middle stone's differ from the ones it drew when you arrived." Evidence: config before the tree → apply_grid_config:645-648 → _restart_cycle_loop:395 queues _begin_cycle_loop. _ready:209 queues a second one. The first loop's draw is discarded by the ticket check (377-380, 397-403). replay_crossing reseeds and queues only one loop (1131-1145, 382-395).
4. **Arena in a headset.** "Entering selects one; walking farther asks for more." → re-checker's wording, scoped to the desktop walk, with the headset case stated. Evidence: removal_arena.gd:60-76 (the whole trigger is gated on is_player, which compares to museum._player). endless_museum.gd:3450 returns on the VR branch before _player is assigned at 3455. The 81 cells: removal_arena.gd:17-19 and map_data.json:2660 (#columns:9#rows:9).
5. **Front profile is the delays.** "These heights are a separate experiment, not a graph of the cube delays." → re-checker's wording (nearest panel shares the seed; its 15 interior heights trace the first 15 drawn delays until PROFILE; the back panels and later contours are separate draws). Added one reading sentence: from the podium end, "a point above the level of the fixed ends stands for a wait longer than 0.8 seconds". Evidence: podium rng.seed = 1955 (waiting_profile.gd:29), one randf_range(0.3,1.3) per arrival (84), reseeded on REPLAY (92). Front layer profile_seed 1955 + 0 (36) → ProfileRandom.gd:113, one randf_range(−0.6,0.6) per interior index, ends fixed, taper > 0 (162-177). So h − 1 has the sign of d − 0.8. PROFILE only increments the seeds (waiting_profile.gd:97-98). Direction: the layer sits at x 1.4 (48) with points from −1.3 to +1.3 (ProfileRandom.gd:136), and the podium is at x −1.7 (30), so index 0 is the podium end. The auditor's scratch run matched to 1e-7.

## Changes the second agent did not re-check (I re-checked them in code)
The re-check covered 5 of the audit's 8 flagged claims. I verified these three myself before touching them. The auditor's headless probes also support them.
6. **"At the housed panel" → "At the console in front of the field".** The panel is built on the east plinth (CubeSpawner.gd:716-722). The token carries #controls:compact#control_front:-5.0 (map_data.json:3080), so museum_exhibit_stage.gd:7-8, 23 and 89-114 reparent every node with panel_w/panel_h (set by RackTemplates.gd:97-98) to a ReachConsole at z −5. The near floor line is at z −4 (CubeSpawner.gd:701, field_center_offset 0 at :24). Only the readout stays on the housing (706-714).
7. **Podium hold, VR only.** "Arrivals wait while either cube is held." → "In a headset, arrivals wait while either cube is held; a desktop carry does not pause them." _held() uses is_picked_up (waiting_profile.gd:65-68), which reads the XR grab driver (pickable.gd:171-172). The desktop carry freezes the cube and zeroes its layers (DesktopInteractionPointer.gd:510-521). It calls a hook only if the target has on_desktop_grab (522-525), and grab_cube.gd has none.
8. **Arena back-reference.** "the rule you inspected there now participates in a crossing" → "the floor you walked there, smaller now, stands between the crossing and the doors". In Random Remove the visitor already walked the same script's floor over fire: Random_Remove/final.md:65-80 and Random_Remove/map_data.json:1429 (9×11 = 99 cells). The audit flagged this sentence and so did the sequence reader. The second agent called it out of scope.

## Additions (placed work doing real work, or handover)
- **Opening, handover from Random_Space:** "In the last room it shifted the layers of a texture." Random_Space closes on "timing instead of texture", and the old opening skipped that hall. Evidence: noise_mixer.gd:60-66 and 75-80 (the seeded draw picks per-octave offsets).
- **Field cap made visible:** kept the true cap sentence and added "Each cube lasts ten seconds, so about twenty are alive at any moment and that limit never binds here; the readout on the dark case beside the field shows the count." Evidence: spawn_interval 0.5 and max 24 (map_data.json:3080), cap test (CubeSpawner.gd:270-272), lifetime 10 s (ProjectileCube.gd:6, 56-58). The impact destroy needs body_entered, and projectile_cube.tscn has no contact_monitor. RUN restarts the timer with no immediate spawn (CubeSpawner.gd:202-206). The readout prints "live N / 24" (752). The auditor's probe plateaued at 20 (max 21).
- **Doors repeat for everyone:** "The doors begin from the same seed each time the hall is built, so until someone presses NEW SEED the passage is the same door for every visitor." Evidence: random_doors.gd:6 (run_seed 39017), 54 (replay at the end of _ready uses it), 60-61. The script has no apply_grid_config and the token sets no seed (map_data.json:2912).

## Left alone, and why
- The beacon, LEAVES/RETURNS, REPLAY-cancels-motion and NEW SEED sentences are true against the working tree. The audit notes they rest on an uncommitted diff to random_cycle_cube.gd, and that is a repo matter, not a prose one.
- "The basin below burns" and the door-jet sentences describe what is seen. In a headset their lethality also keys on museum._player, but the chapter claims no lethality, so nothing is overstated.
- "At the podium you had to wait through it." The LAST DRAW plate tells the running wait (waiting_profile.gd:86), but you still wait through the sequence. The audit raised this only as an ignored work.
- "Watch from the edge before entering" was kept. The falling cubes cannot register the walker, but the sentence invites observation and claims no danger.
- Not taken up: the stele's "ONLY THE WAITS ARE DRAWN", the "FIRE WAS HERE" labels, the 64-entry waits history, the walk-around bypasses, and the optional closing link from the profile landscape back to Random_Space. These were left out to stay within "a few sentences".

## Limits
- I ran no probe and did not start Godot. The claims about runtime order (the double deferred loop, the 20-cube plateau) rest on reading the code plus the auditor's recorded probes.
- The headset sentence ("does not yet recognise your body") describes a code defect. If removal_arena.is_player is fixed, that clause must go. Two other sentences are also coincidences of the current code: the front-ridge identity (seed 1955 on both sides) and the one-ring-at-arrival fact. A later seed edit or the proposed `_build_crown` fix in _spawn_stones would each silently falsify one of them.
- The companions (summary, tutorial, technical, critical, intent) are stale against this map. They were not in scope.

## Installed

`after.md` was installed to `commons/maps/Random_Game/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `a076c53d5357…`, after `7ebe94c86cb4…`. No runtime or learner status changes, because the text changed and nothing new was walked.

## Headset arena repaired; the caveat withdrawn (added at the end of the block)

Change 4 scoped the arena sentence to the desktop and stated the headset defect. Under "Left alone", this record said the clause must go once `removal_arena.is_player` was fixed. It has been fixed:

- In the museum's headset branch `_player` stays null. The arena now recognises the XR Tools PlayerBody by its group, `player_body`.
- `commons/testing/probe_removal_arena_vr.gd` checks three cases:
  - a headset body starts the removals (the shipped script: no);
  - the desktop walker still does;
  - with a walker present, another body does not.
- The source change is recorded in `Random_Remove/` (`removal_arena.diff`).

The sentence is back to the original, "Entering selects one; walking farther asks for more," which is now true on both platforms. `text.diff` and `HASHES.txt` are regenerated. Not walked in a headset.
