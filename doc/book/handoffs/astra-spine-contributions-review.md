# Review of Claude's contribution-browser handoff

15 September 2026. Review by Codex/Astra (AI agent). This is a technical and editorial assessment, not a human acceptance event in the contribution overlay.

The implementation is useful as a Primitives pilot and matches the central brief: an artifact's contribution belongs to a particular hall, with visitor action, observation, technical principle and why it belongs there. Subjects, artifact knowledge and contextual contributions remain separate. Reviewing a proposal does not alter placement, primary status or the book.

## Independently checked

- Read the implementation brief and completed `claude-spine-contributions-report.md`.
- Confirmed content commit `52949da78` contains only the contribution overlay, export, suggestions and report; app commit `b40068dc` contains the feature and its tests.
- Re-ran the production-route/library suite with the installed local tsx runner: **220 passed, zero failed, zero skipped**. Log: `ada_run/claude-contributions-tests.log`.
- Re-ran the read-only evidence gate: **28 records; 283 current evidence items, 5 drifted, zero stale, zero unverifiable**. Drifted means the file changed outside its anchored value. Report: `ada_run/claude-contributions-evidence.json`.
- Read the live Point_Lines hall and Primitives queue APIs and inspected Claude's desktop screenshot. Did not repeat his interactive browser or type-check runs.
- Checked the grid parser's numeric-key shorthand branch and the missing `floating_point` configuration name. The reported grid/museum distinction is a credible source finding; this review does not certify runtime behavior.
- Confirmed the live queue flags `@two_point_ruler` in Point_Lines without a placement.

## What to do with it

Use Point_One, Point_Lines, Point_Trace and Point_Line_Grid as a small calibration set. For each proposed encounter, read **do → observe → principle → why here → what becomes possible next**, compare it with the book and current room, and record one specific revision or decision. Expand classification after this workflow is comfortable.

The software preserves a record of our reasoning; its existence is not evidence that the proposed interpretation is good. In particular, Point_One's proposed purpose quotes an older intent document about a first instantiated point. The current opening's running counter, arriving late and choosing what to attend to need a more present-tense hall summary. Keep the earlier source visible while revising the proposal.

The screenshot is information-dense. A useful next UI pass would foreground action, observation and why-here, with fingerprints, configuration details and provenance available on expansion. Preserve the evidence, but reduce the effort required to read an encounter.

## Clarifications and follow-ups

- **Astra is an AI agent here.** No new human-review authority is needed. Suggestions and technical reviews can be attributed to Codex/Astra; Palle's editorial decision remains separate. The pending-identity wording should be corrected without adding Astra to the human allowlist.
- `draw_dot` is the established resolution encounter in Point_Trace. Do not invent a resolution control for `player_trace`.
- `player_trace` records the moving player. Its recorder node need not be adjacent to the black walking line; the comparison is between the drawn route and the instruction in the room. Verify the visual result in game.
- `two_point_ruler` belongs to the requested measurement step. Treat its absent placement as implementation work to investigate, not permission to remove its book passage or role.
- A placement without book prose may still contribute orientation, beauty or a detour. Missing anchors and obsolete roles require examination, not automatic removal or promotion.
- Configuration parsing needs a separate bounded regression fix. Do not blindly add every numeric key: distinguish artifact parameters from genuine tutorial-rotation shorthand.
- Finish the known metadata editing gaps: subject/knowledge editing, subject-link adoption, and consistent pin-target eligibility between UI and server. Until then this is a usable pilot, not a complete curatorial editor.
- No need to commit all current game changes merely to make evidence green. Evidence can identify working-tree state; commits should represent reviewed changes.
- `doc/book/contributions/` is a reasonable home for this editorial overlay.

No contribution decisions, game placements, roles or prose were changed by this review. Claude's full browser acceptance results remain his reported evidence, not independently repeated results.
