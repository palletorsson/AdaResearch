# Random_Gaussian — decisions

Sequence `randomness`, hall 8 of 14. 24 September 2026. Verdict: **Targeted revision.** Prose only; no repo file other than this folder was touched.

## Preserved

Voice, structure, the title question, all four code excerpts (verbatim, rechecked against `distribution_sampler.gd:508-515, 536-539, 1092-1093`), the `<!-- @distribution_sampler -->` / `<!-- @ -->` anchors, and every sentence on the audit's Preserve list. That includes "Their disagreement is available to examine; ...", which is kept word for word; it is qualified by a new sentence after it instead of being rewritten.

## Changes

1. **PAUSE step at "Return to GAUSS or UNIFORM" (false; audit and re-check agree).** PAUSE is a toggle: `Btn_1` calls `set_running(not auto_sample)` (`distribution_sampler.gd:937`, `1059-1060`). The reader has been paused since "Press PAUSE", so pressing it again restarts the 50/s draws (`467-472`), and "The landed count stays at three hundred" then fails. Now "stay paused (the plate's last line should read “paused”; press PAUSE only if it reads “running”)". That wording is the re-checker's. The cadence line is the readout's last line (`1147-1155`).
2. **EXPON (unsupported; both agree).** Choosing a law clears (`54-57`), and with `auto_sample` false nothing is issued (`467`). The display stays empty until BATCH is pressed. Now "Try EXPON, then press BATCH three times." (re-checker's wording).
3. **Ghost bars (overstated; both agree).** The bar is opaque (`361-366`, no transparency), 0.02 m deep and centred at z 0 (`340`). The ghost is 0.01 m deep at z -0.006 (`956`, `969`), so it sits inside or behind the bar. A shortfall shows. An excess hides the ghost's top, and only 2 mm slivers are left at the sides. "stand further from" became "fall further short of" (re-checker's wording). One sentence was added after the preserved sentence: where blue falls short the pale shows above it; a blue bar that exceeds its expected count hides the pale top.
4. **The cap (both agree it needs a caveat; neither calls the arrival sentence false).** `max_samples` is 1000 (`49`) at 50/s (`71`), which is about 20 s. After that nothing falls, but the cadence line still reads "running" (`1149`). CLEAR resets `_drawn` (`458`) while `auto_sample` stays on. One sentence was added after "GAUSS is running when you arrive". It draws on both suggestions, and without it the PAUSE demonstration has nothing to show a late visitor.
5. **Mushrooms handover (overstated).** Mushroom sizes come from uniform draws: `_rf()` is `randf` (`mushrooms.gd:160-161`) and the size is `0.7 + _rf() * 0.6` (`629`). Nothing Gaussian reaches the bodies. "values like these" became "sampled numbers" (auditor's wording). *Caveat: this claim had no formal re-check. The change rests on the audit, the sequence reader's independent note, and my own reading of the file.*
6. **Added: the paint splatter (placed work doing real work, ignored).** Four sentences under a new `<!-- @GaussianPaintSplatter -->` anchor, in the same pattern Random_Walk uses for its second work. The anchor name is the registry key and the map token (`randomness.json:386`, `map_data.json:535`, cell (2,7); the cabinet is at (5,6), `:525`). The museum plan places it (`ada_run/em_plan.json`). Facts:
   - The position draws use the same guarded Box-Muller as GAUSS (`GaussianPaintSplatter.gd:339-351`, guard at `347-348`).
   - `stddev` 80 = `safe_zone_radius` 80 (`17`, `19`).
   - The default `refusal` is `"void"` (`102`). A draw inside the radius hits the bare `return` (`246`, `261-262`), so no dot is drawn and nothing is shown or tallied.
   - For a 2-D normal, P(r < σ) = 1 - e^-0.5 ≈ 0.39, hence "about two draws in five".
   - Label text: "Gaussian Paint Splatter with Safe Zone" (`GaussianPaintSplatter.tscn:36`). A Label3D is not a museum chrome name (`endless_museum.gd:13495-13498`), so it survives staging.

   This gives the closing "We have met a centre..." a centre that is refused. It also sets up Mushrooms, whose rejected candidates *do* leave recorded positions (Random_Mushrooms/final.md:50-55).

## Left alone, and why

- **"The cabinet stands in the middle ... its controls facing you."** The re-check showed the auditor wrong. The console is built from the sampler's own panels and faces the approach (`museum_exhibit_stage.gd:95-113`). The left/right order also survives: DISTRIBUTIONS is created before the cabinet (`distribution_sampler.gd:269, 273`), so the console lays it out first, on the left.
- **"GAUSS is running when you arrive."** The re-check showed it true at arrival. The caveat was added (change 4) rather than rewriting it.
- **"The previous room's glass reflected an overshoot."** True (Random_Walk/final.md:42). The broken seam is on Walk's side: its handover is followed by the `random_draw_dot` section. The dot's `limit_length` and this clamp coincide in one dimension, so adding it here teaches little and could go stale if Walk is restructured.
- **galton_board and distribution_comparator.** Both do real work: the board fits its curve to the data, and the comparator shows three laws side by side at equal N but normalises each column to its own tallest bar. The added-sentence budget went to the splatter, which answers the closing directly. Both are good candidates for a later pass.
- **Opening paragraph.** Its colours may also describe the galton board. That is not false, so it was left alone.

## Limits

- **Encounter, not fixable in prose.** The audit computes that the `#controls:compact#control_front:1.05` console casing (`museum_exhibit_stage.gd:95-121`) stands between the marked standing position and the readout plate (`distribution_sampler.gd:892-898`). If so, the plate readings this chapter relies on (in flight, clipped, the binned mean and σ, and now the "paused" line) are hidden from that spot. This is PLAUSIBLE, with no capture and no re-check. The proposed map-local fix, for Astra: drop `#controls:compact#control_front:1.05` from the token at `map_data.json:525`, or add `#control_height:0.8`. Then capture from the StandingPosition.
- **Splatter geometry.** The outline drawn by the splatter's edge pass uses `2.0 / splatter_width` against a 3 m plane (`GaussianPaintSplatter.gd:321`, `.tscn:10`). It may therefore sit inside the white disc as a thin black loop. The chapter says "no dot lands near the middle", not "the middle is blank". Dots of radius 5 px centred just outside the radius can reach about 75 px.
- No Godot run and no capture. Every claim is read from source.

## Installed

`after.md` was installed to `commons/maps/Random_Gaussian/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: CRLF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `847f74319596…`, after `c31b41764113…`. No runtime or learner status changes, because the text changed and nothing new was walked.
