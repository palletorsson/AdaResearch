# A history you can inhabit — CA_GameOfLife

Palle authorised the next hall from the pedagogical ladder and asked for CA applications in museum space, interactions and beauty. The existing Rule 30 bridge is now an opt-in shared-history study. The desk record, support tiles and ornamental screen all read one history array and the inherited base solver.

## Delivered

- `algorithms/cellularautomata/ca_bridge/history_study.gd`, mounted only by `#study:history` in the existing bridge script.
- `commons/maps/CA_GameOfLife/map_data.json`: 15×37, a new front bay with a shallow basin and independent walking margin; the old gallery remains behind it, with an added east aisle to preserve the lab at full size. All five artifacts remain. ca_bridge is still the sole primary.
- Eight revised hall texts, including actual-source code excerpts in final.md. Old claims about six Conway Life stations are archived in before/.
- Only CA_GameOfLife's row regenerated in each museum plan. Active sequence order, all other plan rows and artifact roles unchanged.
- `doc/research/possible-bodies/ca-history-bridge.html`: real museum photographs, remote Rule 30 model, book text and future museum applications, linked from the updated ladder.

## Evidence

Final run: 29 checks, no failures. See runtime-receipt.json for exact source hashes and runtime-verification.json for observations. Covers all eight inherited Rule 30 cases, wrap, known first row, replay, one-bit intervention, bounded history, consistent mappings and collision, both ramp slopes, the legacy unconfigured mode, all six buttons through real desktop pointer events, a walked stretch of museum margin, and preservation of the lab's full scale.

The pointer uses the project's desktop rig inside the actual endless museum. Events are synthetic mouse input through the real pointer pipeline; this is distinct from the normal museum walker and a tracked headset. Collision support was measured with rays. The generated cells are not claimed to form a continuous traversable route. The margin test is a stretch, not an end-to-end walkthrough of every secondary encounter. Full headset performance and comfort remain unverified.

The first renders exposed a foreshortened readout, which was moved into an upright housing beside the desk. A geometry-only ramp looked plausible but failed runtime/collision checks; the final slopes use closed convex wedge collision. An existing startup `Unrecognized UID: uid://rwex60pqapc` diagnostic also occurs in the earlier CA_ElementaryRules capture. The final history run contains no SCRIPT ERROR or Parse Error; the startup UID issue is outside this hall change.

source hashes gate page generation. `content-verification.json` checks retained tokens, dimensions, roles and unrelated plan rows; `http-verification.json` checks all thirteen published files against source; `browser-verification.json` records the remote UI observations. Captures are actual Godot output, not generated mockups. The remote model deliberately offers two seed presets while Godot also offers a locally seeded random row.

Rebuild the review page with `python -X utf8 tools/build_ca_history_review.py` after a passing current-source runtime receipt. `ada_run/write_ca_history.py` applies the archived initial change once; `finish_ca_history_layout.py` adds the east aisle once. Do not rerun these application scripts over later user edits. The independent runtime runner is `ada_run/review_ca_history.py`; it preserves the user's hand and leaves other processes open, while refusing unidentified game/capture processes. Its muted, hidden child is the only process it may terminate.

Next: CA_BeyondBinary. Review the actual Life dish, make one fixed cell address explicit, then introduce a declared occupancy event that can affect another museum object. Travelling pattern and moving cell are different claims.
