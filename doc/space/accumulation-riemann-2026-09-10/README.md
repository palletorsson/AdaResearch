# Accumulation_Riemann - 2026-09-10

Completed the next hall after Change_Intro. Opt-in comparison:true preserves the default workbench while this map starts at four midpoint rectangles. Six pointer controls share the existing slider: RULE, CELL -, CELL +, HOLD, REFERENCE, RESET. Held rectangle arrays survive live rebuilds; HOLD flushes a pending slider redraw before copying geometry. The reference remains a separate 4096-midpoint estimate under all sampling rules.

The primary moved from (5,3) to (7,2), retaining rotation 270. The two mounted plots are 1.3 metres apart; screenshots verify both are fully visible. Existing walls and three secondary placements remain. The original wider placement and a trial reversed orientation were obstructed by museum geometry; visual inspection caught an issue that layer-1 collision rays alone missed. Neither the museum geometry nor camera-only hiding was used to remove the obstruction.

final.md, tutorial, critical, intent, blurb and artifact notes now follow the same primary. The old walked draft is explicitly historical. Guide and workshop show three actual Godot captures. Current route: Change_Intro -> Accumulation_Riemann -> Flow_Field. There are no role changes.

26 desktop checks pass, exit 0, no script errors. Existing unrecognized UID warning remains. The independent antiderivative agrees with the finite reference within 1e-6. At N=4 right-edge sampling is closer than midpoint, correcting the former tutorial claim that midpoint always wins. Actual headset legibility, stereo and tracked-hand use are deferred. The three secondary interactions were not audited here.

Source hashes are in source-files.json; original room files and original workbench source are in before/. Current publication: http://localhost:3003/research/possible-bodies/accumulation-riemann.html

Next: inspect Flow_Field's actual sampler and update rule, preserving the distinction between a direction field, a gradient and a force. Ask what changes when earlier updates determine the next sampling address.

Publication verified: all 13 published guide files match their source bytes over HTTP. compose-docs reports no stale blocks and exactly one book anchor, riemann_sum_workbench. Guide audit confirms current evidence and the same primary; generated JavaScript passes node --check. Scoped git diff --check passes. Route coverage remains 36 halls, 32 final texts, 4 missing texts and 12 existing role reviews.
