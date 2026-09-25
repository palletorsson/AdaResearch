# Noise_6_Wall: revision decisions (2026-09-24)

## Verdict
Targeted revision: three sentences reworded, nothing added, nothing removed. `before.md` was byte-identical to `commons/maps/Noise_6_Wall/final.md` when I started. That file was not edited.

## Preserved
- The title, all 77 lines' structure, both questions ("What would have to change...", "Can you follow one cloud around a corner?"), the three code excerpts (cloud_noise loop, the `bare` line, the dressed `cloud_pattern` lines), the dark_sphere pulse block, and the anchors `<!-- @shader_noise_space -->`, `<!-- @dark_sphere -->`, `<!-- @ -->`.
- The code excerpts are still verbatim: WallNoiseShader.gdshader:132-140 (loop) and :170 (`bare`), and commons/artifacts/dark_sphere/dark_sphere.gd:599 (pulse).
- The DO/SEE arc (FREEZE, DRESS, the four windows, abs, weights, gain, BASIS, dressed finish, UV seam, the orb's own clock) and the bridge to Noise Inside Noise. The audit marked all of these true, and I did not re-litigate them.

## Changes
1. Line 9. "The room holds the moment you arrived at." became "The room holds the moment of the press."
   Reason: the auditor and the re-checker agree this is overstated. The natural reading of "arrived at" is "entered the hall", and nothing records that moment. FREEZE stops the clock where it is at the press. Evidence: `set_frozen` sets `animation_enabled = not frozen` and broadcasts once (algorithms/randomness/shadernoisespace/noiseroom.gd:407-413). `_process` then returns early, so `base_time`, `color_cycle_time` and `density_cycle_time` stop advancing (noiseroom.gd:191-196). The room copies the panel's `base_time`/`animation_enabled` in `_receive_panel` (noiseroom.gd:594-601). I used the re-checker's rewording.
2. Line 15. "The fourth and sixth terms add finer disturbances." became "The four- and six-term windows add finer disturbances."
   Reason: both agree. The sentence mixes window counts with term indices. The panel prefixes are `PANEL_LAYERS = [1, 2, 4, 6]` (noiseroom.gd:64), so the step to the four-term window adds terms 3 and 4, and the step to the six-term window adds terms 5 and 6. The old wording dropped terms 3 and 5, which are the heavier ones (WallNoiseShader.gdshader:137-139 halves amplitude each term). I used the re-checker's rewording.
3. Line 43. "Values beyond the display range meet its limits. Two different sums can therefore become the same white." became "…, and the shader clamps anything above one. Any two sums of 0.5 or more would become the same white, although the measured windows stay well below that, near half-white."
   Reason: both agree the mechanism is real but the sentence reads as if it happens in the hall, which is not shown. The shader computes `clamp(cloud_noise(...) * term_gain, 0.0, 1.0)` (WallNoiseShader.gdshader:170), and the panel sets `term_gain` to `PANEL_GAIN = 2.0` on every patch (noiseroom.gd:68, 488), so any sum of 0.5 or more clamps to 1. The accepted GPU captures peak at red 135/255, roughly 0.53 of white on the re-checker's linearity check, with no pixel at white. I used the re-checker's rewording almost verbatim. The next sentence ("Grey is already an interpretation, with its own capacity to lose a difference") still holds as a statement of capacity, so it was left alone.

## Added
Nothing. The audit lists no placed work the chapter ignores: panel (9,2), room (6,6) and dark_sphere (10,10) are all anchored. The handover to Noise Inside Noise was confirmed. No handover repair was needed.

## Left alone, and why
- "Its colours and the small windows stop changing together." This is true inside a museum hall, and the re-checker confirmed it. The panel reaches the room only through `_hall_ancestor` (noiseroom.gd:604-610). A plain grid load leaves the room static. That limit belongs in technical.md, not the chapter.
- "Your feet meet the same floor." and the collider sentence. They are true because vertex() writes only varyings (WallNoiseShader.gdshader:161-164) and the colliders are built once.
- The audit's false claim ("bridges the map's existing central opening ... structure unchanged") and the overstated "supported" panel are not in final.md. They are in technical.md, artifacts.md, intent.md, field_notes.md and doc/space/wall-review-2026-09-13/README.md, which this task may not edit.

## Limits
- I did not start Godot or re-render anything. The "near half-white" figure comes from the re-checker's reading of the 2026-09-13 captures. The re-checker's CPU simulation shows that Perlin or Simplex could approach white at the patch corner at some phase, so the sentence claims only what was measured.
- The whole 13 September revision (code, shaders, map, texts) is still uncommitted, and the map's central pit was filled by cell edits on 2026-09-14, after the accepted walk run. None of this changes the three sentences above, but the walk check should be re-run on the current map before anything is committed.

## Installed

`after.md` was installed to `commons/maps/Noise_6_Wall/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `e7a08ec471f7…`, after `fc9bc18446af…`. No runtime or learner status changes, because the text changed and nothing new was walked.
