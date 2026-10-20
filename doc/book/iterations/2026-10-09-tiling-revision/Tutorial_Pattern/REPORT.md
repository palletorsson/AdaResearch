# Change the reading

Tiling · Tutorial Pattern · 9 October 2026

**The third lesson keeps Foundry’s source, cube display and held point.** It separates a changed reader from a changed record. The existing museum already makes this comparison with two panels and a source editor; the tutorial now gives the student a complete reduced construction.

## What changed

| Before | Now |
| --- | --- |
| An encounter guide to P1, PM, source flipping, quarter turns and undo. | One runnable comparison: reflect the lookup or reverse the stored row. The wider controls remain in the museum and reflection. |
| No complete learner script. | One new entry script; Palette, GridSurface and PointBody copied unchanged from Foundry and fully printed. |
| A general instruction to use asymmetry. | A predicted symmetric-source variation, executed separately, then an edit that makes the difference visible. |

The point still selects and paints a cube. Two nearby labelled regions give it named actions: READ RULE changes a Boolean; FLIP SOURCE reverses each row in place. Hovering does not act. Painting through a reflected copy finds its original source address. The new code does not rebuild the sphere, change the cube mesh, or require a new player.

The two-row, three-column source remains deliberately smaller than the five-by-five receiver. Under alternating reflection, the asymmetric pattern has a six-cell horizontal translation period. The preview cuts through the second tile; the text names that limit and asks the student to compare an address six cells away. The installed panels show complete paired copies.

## A diagnostic that can fail to show a difference

The independent edit replaces the second row with `[2,0,2]`. Both rows then read the same backwards. The Boolean and addresses can change without a visible colour change. Reversing the rows produces the same stored values. Painting through reflected preview (3,1) changes source column two and breaks that symmetry. Switching the reader becomes visible again.

This is the next capacity after Foundry: inspect data and operation alongside appearance. In Array Patterns the same source and reader will acquire a physical frame—an origin, axes and cell width.

## Evidence

- **69 Godot assertions:** 34 on files extracted from the printed tutorial; 35 on the separate symmetric-source program.
- **7 executable faults rejected:** alternating individual cells instead of tiles, mutating the source while changing the reader, reversing outer row order, missing repaint, painting without reflected lookup, using world coordinates for the control, and truncating negative tile coordinates.
- **62 native museum checks:** source data and rendered field comparisons, actual pointer callbacks, ordinary-controller entry and return through the bay, learner standing clearance, simulated XR Tools grip, selection, held action and release.

The first fault run found a weakness in the tests: a three-column source has a fixed middle cell, so a wrong alternate-cell rule can produce the same addresses. The test now also checks a four-column source against the explicit sequence `0,1,2,3 / 3,2,1,0 / 0,1,2,3`. The fault is caught. Earlier receipts remain in `attempts/`; passing results do not erase that correction. The printed program itself passed both runs.

The screenshots below are native museum captures. The small learner display is temporarily placed in the existing comparison bay; it is not a new permanent installation. The installed station retains its own four-by-four source and fixed panels. The reconstruction is author-informed, with simulated input—not a human-learning or physical-headset test. Audio was muted.

### Limits visible in the run

The existing museum log reports a blocked authored exit with a safe fallback, expensive builds of `rocaille` (150 ms) and `sea_forms` (1530 ms), an unresolved UID, viewport/renderer warnings, a panel-bridge look-at call before tree entry, and a resource still in use at exit. The local approach and bay walk passed; this is not a clean bill of health for the full route or Quest performance. There are no lesson script errors. No production artifact logic, map geometry or sequence order was changed by this revision.

## The two readings

The tutorial provides the operation and a way to disprove a mistaken explanation. The reflection asks where an apparent reversal happened, how an interruption becomes regular, and what a boundary around one tile leaves out. Its opening, museum image, artifact markers, later experiments and ending remain intact. Three code excerpts become a short account in prose.

Open the [facing pages](parallel.html), [exact changes](changes.html), [code results](tests.json), [fault results](mutations.json), [museum receipt](museum/report.json), or [review ZIP](tiling-pattern-review.zip). The [nine-hall route](../plan.html) records three completed revisions; this lesson remains a draft for review.

**Next: Array Patterns — give the reading a place and a scale.**
