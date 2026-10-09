# Working memory — 4 October 2026

**Purpose / author decision.** Work inside the existing Endless Museum. Tutorial, critical-poetic writing and wider artifacts overlap; they need not teach identical things. Current work is summaries only. Preserve code, hall order and the existing counter. A supplied artifact is not evidence that a student has learned to build it.

**Position.** Point Zero → Lines → Trace → Grid → later Arrays. Question: what actually carries between halls, and what does that change in the teaching plan?

**Source findings.** Scoped to the thirteen frozen files in `manifest.json`; static inspection, no Godot run.

- Point Zero already places the frame counter. Its `_ready()` records arrival and `_process()` updates the count. Teach from that selected material.
- The pen saves its accepted position list on release. Acceptance can project/quantize/filter samples; these are not every raw hand position. The script defaults to keeping the list, so a released record can span pickups. Scene overrides outside this snapshot remain unverified.
- Grid centres and fits that record, then rounds the display positions in XYZ. It retains source data separately. Distinguish list index, accepted source position and fitted/rounded display address.
- Rounding is many-to-one and adjacent snapped duplicates can disappear. Later generating positions from indices does not recover arbitrary original positions.
- The selected `TraceData` autoload stores copies in memory. Grid reads existing records and subscribes to additions. This supports session retention; restart persistence is not established. No disk save/reload appears in the inspected store; other project mechanisms were not inspected.

**Carry upward.** Map: explain fitting before rounding and preserve the source. Sequence: retain segment → recorded list → lattice address; Arrays can reuse list traversal and generate positions. Global: supplied, encountered and learned are different states; source facts constrain summaries without prescribing artistic meaning or a new order.

**Documentary conflicts / proposed next action.** Reconcile the older subject register’s counter-building exercise and “reversing” Grid mapping with the current summaries. This authorizes no code change. First settle where the learner’s reduced code runs inside the museum; the current brief leaves that teaching choice open.

**Evidence pointers.** Frozen `frame_counter_display.gd:133–137,346–375`; `draw_dot.gd:27,458–490,631–642`; `grid_lines.gd:89–178,346–356`; `trace_data.gd:1–65`; `SUBJECT_REGISTER.md:42–46,64`. Full paths and hashes: manifest. Claim-by-claim reasoning: `SOURCE_REVIEW.md`.

**Unknown.** This does not establish actual headset transfer, beginner understanding, the best curriculum order, or quality across all 204 halls. Recheck affected evidence when its source changes; a changed hash means review is needed, not that the claim became false.
